import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import '../../core/video_player_shutdown.dart';
import '../../data/local/keyframe_repository.dart';
import '../../data/local/watch_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

class VideoPlayerPanel extends ConsumerStatefulWidget {
  const VideoPlayerPanel({super.key, required this.video, required this.onBack});
  final VideoDetail video;
  final VoidCallback onBack;

  @override
  ConsumerState<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends ConsumerState<VideoPlayerPanel> {
  VideoPlayerController? _controller;
  String? _loadedQuality;
  Object? _loadError;
  var _loadVersion = 0;
  bool _restored = false;
  bool _fullscreenOpen = false;
  bool _disposed = false;
  Future<void> _controllerDisposal = Future<void>.value();
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSource();
    });
  }

  @override
  void didUpdateWidget(VideoPlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id ||
        !_sameSources(oldWidget.video.sources, widget.video.sources)) {
      _loadedQuality = null;
      if (oldWidget.video.id != widget.video.id) _restored = false;
      _syncSource();
    }
  }

  void _syncSource() {
    if (_fullscreenOpen) return;
    if (widget.video.sources.isEmpty) {
      unawaited(_clearSource());
      return;
    }
    final quality = ref.read(settingsProvider).valueOrNull?.preferredQuality ?? 720;
    final source = widget.video.sources.reduce((best, item) => (_quality(item) - quality).abs() < (_quality(best) - quality).abs() ? item : best);
    if (source.quality != _loadedQuality) _load(source);
  }

  int _quality(VideoSource source) => int.tryParse(RegExp(r'\d+').firstMatch(source.quality)?.group(0) ?? '') ?? 720;

  bool _sameSources(List<VideoSource> left, List<VideoSource> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].quality != right[index].quality ||
          left[index].url != right[index].url ||
          left[index].type != right[index].type) {
        return false;
      }
    }
    return true;
  }

  Future<void> _clearSource() async {
    _loadVersion++;
    final controller = _controller;
    _controller = null;
    _loadedQuality = null;
    if (mounted) setState(() => _loadError = const _NoVideoSource());
    if (controller != null) await _queueDisposal(controller);
  }

  Future<void> _load(VideoSource source) async {
    final version = ++_loadVersion;
    final previous = _controller;
    _controller = null;
    _loadedQuality = null;
    if (mounted) setState(() {});
    if (previous != null) await _queueDisposal(previous);
    if (!mounted || version != _loadVersion) return;
    final settings = await ref.read(settingsProvider.future);
    if (!mounted || version != _loadVersion) return;
    final controller = source.url.startsWith('/')
        ? VideoPlayerController.file(File(source.url))
        : VideoPlayerController.networkUrl(
            Uri.parse(source.url),
            httpHeaders: {
              'User-Agent': Han1meApi.userAgent,
              'Referer': '${settings.baseUrl}/watch?v=${widget.video.id}',
            },
          );
    _loadedQuality = source.quality;
    VideoPlayerShutdown.track(controller);
    setState(() {
      _controller = controller;
      _loadError = null;
    });
    try {
      await controller.initialize();
      if (!mounted || version != _loadVersion) {
        return;
      }
      if (mounted && version == _loadVersion) setState(() {});
      await _applyPlaybackPreferences(controller, version);
      if (!mounted || version != _loadVersion || controller != _controller) return;
      controller.addListener(_saveProgress);
    } catch (error) {
      if (controller == _controller) {
        _controller = null;
        await _queueDisposal(controller);
      }
      if (mounted && version == _loadVersion) {
        setState(() {
          _loadedQuality = null;
          _loadError = error;
        });
      }
    }
  }

  Future<void> _disposeController(VideoPlayerController controller) async {
    VideoPlayerShutdown.untrack(controller);
    try {
      controller.removeListener(_saveProgress);
      if (controller.value.isInitialized && controller.value.isPlaying) {
        await controller.pause();
        await Future<void>.delayed(const Duration(milliseconds: 64));
      }
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _queueDisposal(VideoPlayerController controller) {
    final disposal = _controllerDisposal.then((_) => _disposeController(controller));
    _controllerDisposal = disposal;
    return disposal;
  }

  Future<void> _applyPlaybackPreferences(VideoPlayerController controller, int version) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!mounted || version != _loadVersion || controller != _controller) return;
      await controller.setPlaybackSpeed(settings.defaultPlaybackSpeed);
      if (!_restored && settings.resumePlayback) {
        final watch = await ref.read(watchProvider.future);
        if (!mounted || version != _loadVersion || controller != _controller) return;
        final item = watch.continueItems.where((item) => item.videoCode == widget.video.id).firstOrNull;
        if (item != null && item.positionMs > 0 && item.positionMs < item.durationMs - 3000) {
          await controller.seekTo(Duration(milliseconds: item.positionMs));
        }
      }
      _restored = true;
    } catch (_) {}
  }

  void _saveProgress() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    if (DateTime.now().difference(_lastSaved).inSeconds < 5) return;
    _lastSaved = DateTime.now();
    ref.read(watchProvider.notifier).progress(id: widget.video.id, title: widget.video.title, coverUrl: widget.video.coverUrl, positionMs: value.position.inMilliseconds, durationMs: value.duration.inMilliseconds);
  }

  Future<void> _fullscreen() async {
    final controller = _controller;
    if (controller == null || _fullscreenOpen) return;
    _fullscreenOpen = true;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _FullscreenPlayer(controller: controller, video: widget.video)));
    } finally {
      _fullscreenOpen = false;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      if (mounted) {
        _syncSource();
      } else if (_disposed) {
        await _queueDisposal(controller);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    _saveProgress();
    final controller = _controller;
    _controller = null;
    if (controller != null && !_fullscreenOpen) unawaited(_queueDisposal(controller));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsProvider.select((value) => value.valueOrNull?.preferredQuality ?? 720), (_, __) => _syncSource());
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _PlayerFrame(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            Center(
              child: _loadError == null
                  ? const M3EContainedLoadingIndicator(indicatorColor: Colors.white, containerColor: Colors.black54)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError is _NoVideoSource
                              ? AppLocalizations.of(context)!.videoSourceUnavailable
                              : AppLocalizations.of(context)!.videoPlaybackFailed,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        if (_loadError is! _NoVideoSource)
                          IconButton(
                            color: Colors.white,
                            tooltip: AppLocalizations.of(context)!.retry,
                            onPressed: _syncSource,
                            icon: const Icon(Icons.refresh),
                          ),
                      ],
                    ),
            ),
            Positioned(top: 8, left: 8, child: BackButton(color: Colors.white, onPressed: widget.onBack)),
          ],
        ),
      );
    }
    return _PlayerFrame(
      aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
      child: _PlayerSurface(controller: controller, videoId: widget.video.id, fullscreen: false, onFullscreen: _fullscreen, onBack: widget.onBack),
    );
  }
}

class _PlayerFrame extends StatelessWidget {
  const _PlayerFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final heightBound = MediaQuery.sizeOf(context).height * .62 * aspectRatio;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth >= 900
                    ? heightBound.clamp(640, 960).toDouble()
                    : constraints.maxWidth,
              ),
              child: AspectRatio(aspectRatio: aspectRatio, child: child),
            ),
          );
        },
      );
}

class _NoVideoSource {
  const _NoVideoSource();
}

class _FullscreenPlayer extends ConsumerWidget {
  const _FullscreenPlayer({required this.controller, required this.video});
  final VideoPlayerController controller;
  final VideoDetail video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyframes = ref.watch(keyframesProvider(video.id)).valueOrNull ?? const <int>[];
    final enabled = ref.watch(settingsProvider).valueOrNull?.keyframesEnabled ?? true;
    return Scaffold(
      backgroundColor: Colors.black,
      endDrawer: _KeyframeDrawer(video: video, controller: controller),
      body: SafeArea(child: Builder(builder: (scaffoldContext) => _PlayerSurface(controller: controller, videoId: video.id, fullscreen: true, onFullscreen: () async => Navigator.of(context).pop(), keyframes: enabled ? keyframes : const [], onKeyframes: enabled ? () => Scaffold.of(scaffoldContext).openEndDrawer() : null, onAddKeyframe: enabled ? () => _addKeyframe(context, ref) : null))),
    );
  }

  Future<void> _addKeyframe(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (controller.value.isPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pauseBeforeAddingKeyframe)));
      return;
    }
    final position = controller.value.position.inMilliseconds;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addKeyframe),
        content: Text(l10n.addKeyframeConfirmation(position)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.add)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final added = await ref.read(keyframesProvider(video.id).notifier).add(position, title: video.title);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? l10n.keyframeAdded : l10n.keyframeTooClose)));
  }
}

class _PlayerSurface extends ConsumerStatefulWidget {
  const _PlayerSurface({required this.controller, required this.videoId, required this.fullscreen, required this.onFullscreen, this.onBack, this.keyframes = const [], this.onKeyframes, this.onAddKeyframe});
  final VideoPlayerController controller;
  final String videoId;
  final bool fullscreen;
  final Future<void> Function() onFullscreen;
  final VoidCallback? onBack;
  final List<int> keyframes;
  final VoidCallback? onKeyframes;
  final VoidCallback? onAddKeyframe;

  @override
  ConsumerState<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends ConsumerState<_PlayerSurface> {
  bool _showControls = true;
  bool _locked = false;
  double? _dragStartX;
  double? _dragStartY;
  _DragDirection? _dragDirection;
  double _brightness = 1;
  double _volume = 1;
  _Adjustment? _adjustment;
  Timer? _hideTimer;

  @override
  void initState() { super.initState(); _readLevels(); WidgetsBinding.instance.addPostFrameCallback((_) => _restartTimer()); }
  @override
  void dispose() { _hideTimer?.cancel(); super.dispose(); }

  Future<void> _readLevels() async {
    final levels = await Future.wait([PlatformService.screenBrightness(), PlatformService.volume()]);
    if (mounted) setState(() { _brightness = levels[0]; _volume = levels[1]; });
  }

  void _restartTimer() {
    _hideTimer?.cancel();
    if (!_showControls || _locked) return;
    final seconds = ref.read(settingsProvider).valueOrNull?.playerControlsTimeoutSeconds ?? 4;
    _hideTimer = Timer(Duration(seconds: seconds), () { if (mounted) setState(() => _showControls = false); });
  }

  void _toggleControls() { if (_locked) return; setState(() => _showControls = !_showControls); _restartTimer(); }
  void _togglePlayback() { final controller = widget.controller; controller.value.isPlaying ? controller.pause() : controller.play(); _restartTimer(); }

  void _longPress(bool active) {
    final speed = ref.read(settingsProvider).valueOrNull?.longPressPlaybackSpeed ?? 2;
    widget.controller.setPlaybackSpeed(active ? speed : (ref.read(settingsProvider).valueOrNull?.defaultPlaybackSpeed ?? 1));
    setState(() => _adjustment = active ? _Adjustment.speed(speed) : null);
  }

  void _dragStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _dragStartY = details.localPosition.dy;
    _dragDirection = null;
  }

  void _dragUpdate(DragUpdateDetails details) {
    final startX = _dragStartX;
    if (startX == null || _locked) return;
    final size = context.size ?? MediaQuery.sizeOf(context);
    final direction = _dragDirection ??= details.delta.dx.abs() > details.delta.dy.abs() ? _DragDirection.horizontal : _DragDirection.vertical;
    if (direction == _DragDirection.horizontal) {
      final duration = widget.controller.value.duration;
      final sensitivity = ref.read(settingsProvider).valueOrNull?.seekSensitivity ?? .35;
      if (duration != Duration.zero) widget.controller.seekTo(Duration(milliseconds: (widget.controller.value.position.inMilliseconds + details.delta.dx / size.width * duration.inMilliseconds * sensitivity).round().clamp(0, duration.inMilliseconds).toInt()));
      return;
    }
    final value = (startX < size.width / 2 ? _brightness : _volume) - details.delta.dy / size.height;
    if (startX < size.width / 2) { _brightness = value.clamp(0.01, 1).toDouble(); PlatformService.setScreenBrightness(_brightness); setState(() => _adjustment = _Adjustment.brightness(_brightness)); }
    else { _volume = value.clamp(0, 1).toDouble(); PlatformService.setVolume(_volume); setState(() => _adjustment = _Adjustment.volume(_volume)); }
  }
  void _dragEnd(DragEndDetails details) { _dragStartX = null; _dragStartY = null; _dragDirection = null; Future<void>.delayed(const Duration(milliseconds: 700), () { if (mounted) setState(() => _adjustment = null); }); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      onDoubleTap: _togglePlayback,
      onLongPressStart: (_) => _longPress(true),
      onLongPressEnd: (_) => _longPress(false),
      onPanStart: _dragStart,
      onPanUpdate: _dragUpdate,
      onPanEnd: _dragEnd,
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Colors.black),
         Center(child: AspectRatio(aspectRatio: widget.controller.value.aspectRatio == 0 ? 16 / 9 : widget.controller.value.aspectRatio, child: VideoPlayer(widget.controller))),
          ValueListenableBuilder<VideoPlayerValue>(valueListenable: widget.controller, builder: (context, value, _) => _showControls && !_locked && !(value.position == Duration.zero && !value.isPlaying) ? _Controls(controller: widget.controller, fullscreen: widget.fullscreen, onFullscreen: widget.onFullscreen, onInteraction: _restartTimer) : const SizedBox.shrink()),
        if (_locked) Align(alignment: Alignment.centerRight, child: IconButton(color: Colors.white, tooltip: l10n.unlockControls, onPressed: () { setState(() => _locked = false); _restartTimer(); }, icon: const Icon(Icons.lock))),
        if (_showControls && !_locked && widget.onBack != null) Positioned(top: 8, left: 8, child: BackButton(color: Colors.white, onPressed: widget.onBack)),
        if (_showControls && widget.fullscreen && !_locked) Align(alignment: Alignment.centerRight, child: IconButton(color: Colors.white, tooltip: l10n.lockControls, onPressed: () => setState(() => _locked = true), icon: const Icon(Icons.lock_open_outlined))),
        if (widget.fullscreen && widget.keyframes.isNotEmpty) _KeyframeCountdown(controller: widget.controller, keyframes: widget.keyframes),
        if (_showControls && widget.fullscreen && !_locked && widget.onKeyframes != null)
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: l10n.longPressAddKeyframe,
              child: GestureDetector(
                onTap: widget.onKeyframes,
                onLongPress: widget.onAddKeyframe,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('🥵', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
        if (_adjustment != null) Positioned(top: 24, left: 0, right: 0, child: Center(child: _AdjustmentHud(adjustment: _adjustment!, brightnessLabel: l10n.brightness, volumeLabel: l10n.volume))),
        ValueListenableBuilder<VideoPlayerValue>(valueListenable: widget.controller, builder: (context, value, _) => !value.isPlaying && value.position == Duration.zero ? Center(child: IconButton.filledTonal(iconSize: 36, onPressed: _togglePlayback, icon: const Icon(Icons.play_arrow))) : const SizedBox.shrink()),
      ]),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.fullscreen, required this.onFullscreen, required this.onInteraction});
  final VideoPlayerController controller;
  final bool fullscreen;
  final Future<void> Function() onFullscreen;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
    final l10n = AppLocalizations.of(context)!;
    final progress = value.duration == Duration.zero ? 0.0 : value.position.inMilliseconds / value.duration.inMilliseconds;
          return Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          SizedBox(width: 48, child: Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))),
          Expanded(child: SliderTheme(data: const SliderThemeData(year2023: true), child: Slider(value: progress.clamp(0, 1).toDouble(), onChanged: (next) { controller.seekTo(Duration(milliseconds: (next * value.duration.inMilliseconds).round())); onInteraction(); }))),
          SizedBox(width: 48, child: Text(_formatDuration(value.duration), textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))),
        ]),
        SizedBox(height: 40, child: Row(children: [IconButton(color: Colors.white, tooltip: value.isPlaying ? l10n.pause : l10n.play, visualDensity: VisualDensity.compact, onPressed: () { value.isPlaying ? controller.pause() : controller.play(); onInteraction(); }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)), const Spacer(), _SpeedMenu(controller: controller, onInteraction: onInteraction), IconButton(color: Colors.white, tooltip: fullscreen ? l10n.exitFullscreen : l10n.fullscreenPlayback, visualDensity: VisualDensity.compact, onPressed: onFullscreen, icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen))])),
          ]);
        },
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.controller, required this.onInteraction});
  final VideoPlayerController controller;
  final VoidCallback onInteraction;
  @override
  Widget build(BuildContext context) => MenuAnchor(builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.playbackSpeed, onPressed: menu.open, icon: const Icon(Icons.speed)), menuChildren: <double>[.5, .75, 1, 1.25, 1.5, 2, 3].map((speed) => MenuItemButton(onPressed: () { controller.setPlaybackSpeed(speed); onInteraction(); }, child: Text('${speed}x'))).toList());
}

enum _DragDirection { horizontal, vertical }
enum _AdjustmentKind { brightness, volume, speed }
class _Adjustment { const _Adjustment(this.kind, this.value); factory _Adjustment.brightness(double value) => _Adjustment(_AdjustmentKind.brightness, value); factory _Adjustment.volume(double value) => _Adjustment(_AdjustmentKind.volume, value); factory _Adjustment.speed(double value) => _Adjustment(_AdjustmentKind.speed, value); final _AdjustmentKind kind; final double value; }
class _AdjustmentHud extends StatelessWidget { const _AdjustmentHud({required this.adjustment, required this.brightnessLabel, required this.volumeLabel}); final _Adjustment adjustment; final String brightnessLabel; final String volumeLabel; @override Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: adjustment.kind == _AdjustmentKind.speed ? Text('${adjustment.value}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : SizedBox(width: 180, child: Column(mainAxisSize: MainAxisSize.min, children: [Text(adjustment.kind == _AdjustmentKind.brightness ? brightnessLabel : volumeLabel, style: const TextStyle(color: Colors.white)), SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: Colors.white, inactiveTrackColor: Colors.white38, disabledActiveTrackColor: Colors.white, disabledInactiveTrackColor: Colors.white38, thumbColor: Colors.white, disabledThumbColor: Colors.white), child: Slider(value: adjustment.value, onChanged: null))])))); }

class _KeyframeCountdown extends StatelessWidget {
  const _KeyframeCountdown({required this.controller, required this.keyframes});
  final VideoPlayerController controller;
  final List<int> keyframes;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final next = keyframes.where((item) => item >= value.position.inMilliseconds).firstOrNull;
          final remaining = next == null ? null : next - value.position.inMilliseconds;
          if (remaining == null || remaining > 10000) return const SizedBox.shrink();
          return Positioned(left: 16, top: 16, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text(AppLocalizations.of(context)!.keyframeCountdown((remaining / 1000).toStringAsFixed(1)), style: const TextStyle(color: Colors.white)))));
        },
      );
}

class _KeyframeDrawer extends ConsumerWidget {
  const _KeyframeDrawer({required this.video, required this.controller});
  final VideoDetail video;
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyframes = ref.watch(keyframesProvider(video.id)).valueOrNull ?? const <int>[];
    return Drawer(child: SafeArea(child: Column(children: [
      ListTile(title: Text(AppLocalizations.of(context)!.keyframes), subtitle: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
      const Divider(height: 1),
      Expanded(child: keyframes.isEmpty ? Center(child: Text(AppLocalizations.of(context)!.noKeyframes)) : ListView.separated(itemCount: keyframes.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) {
        final position = keyframes[index];
        return ListTile(title: Text(_formatKeyframe(position)), subtitle: Text('$position ms'), onTap: () { controller.seekTo(Duration(milliseconds: position)); Navigator.of(context).pop(); }, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(keyframesProvider(video.id).notifier).remove(position)));
      })),
    ])));
  }

  String _formatKeyframe(int positionMs) {
    final position = Duration(milliseconds: positionMs);
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return position.inHours > 0 ? '${position.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}
extension<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
