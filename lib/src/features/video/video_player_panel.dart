import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import '../../data/local/keyframe_repository.dart';
import '../../data/local/watch_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

class VideoPlayerPanel extends ConsumerStatefulWidget {
  const VideoPlayerPanel({super.key, required this.video, required this.playbackSession});
  final VideoDetail video;
  final VideoPlaybackSession playbackSession;

  @override
  ConsumerState<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends ConsumerState<VideoPlayerPanel> {
  VideoPlayerController? _controller;
  String? _loadedQuality;
  Object? _loadError;
  var _loadVersion = 0;
  bool _restored = false;
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _syncSource()); }

  @override
  void didUpdateWidget(VideoPlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) { _loadedQuality = null; _restored = false; _syncSource(); }
  }

  void _syncSource() {
    if (widget.video.sources.isEmpty) return;
    final quality = ref.read(settingsProvider).valueOrNull?.preferredQuality ?? 720;
    final source = widget.video.sources.reduce((best, item) => (_quality(item) - quality).abs() < (_quality(best) - quality).abs() ? item : best);
    if (source.quality != _loadedQuality) _load(source);
  }

  int _quality(VideoSource source) => int.tryParse(RegExp(r'\d+').firstMatch(source.quality)?.group(0) ?? '') ?? 720;

  Future<void> _load(VideoSource source) async {
    final version = ++_loadVersion;
    widget.playbackSession.detach(_controller);
    await _controller?.dispose();
    _controller = null;
    _loadedQuality = null;
    if (!mounted || version != _loadVersion) return;
    final controller = source.url.startsWith('/') ? VideoPlayerController.file(File(source.url)) : VideoPlayerController.networkUrl(Uri.parse(source.url));
    _loadedQuality = source.quality;
    setState(() {
      _controller = controller;
      _loadError = null;
    });
    widget.playbackSession.attach(controller);
    try {
      controller.addListener(_saveProgress);
      await controller.initialize();
      if (!mounted || version != _loadVersion) {
        await controller.dispose();
        return;
      }
      if (mounted && version == _loadVersion) setState(() {});
      unawaited(_applyPlaybackPreferences(controller, version));
    } catch (error) {
      await controller.dispose();
      if (mounted && version == _loadVersion) {
        setState(() {
          _loadedQuality = null;
          _loadError = error;
        });
      }
    }
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
    if (controller == null) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _FullscreenPlayer(controller: controller, video: widget.video)));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    _saveProgress();
    widget.playbackSession.detach(_controller);
    unawaited(_controller?.pause() ?? Future<void>.value());
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsProvider.select((value) => value.valueOrNull?.preferredQuality ?? 720), (_, __) => _syncSource());
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: _loadError == null
                ? const CircularProgressIndicator(color: Colors.white)
                : IconButton(color: Colors.white, onPressed: _syncSource, icon: const Icon(Icons.refresh)),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
       child: _PlayerSurface(controller: controller, videoId: widget.video.id, fullscreen: false, onFullscreen: _fullscreen),
    );
  }
}

class VideoPlaybackSession {
  VideoPlayerController? _controller;

  void attach(VideoPlayerController controller) => _controller = controller;

  void detach(VideoPlayerController? controller) {
    if (_controller == controller) _controller = null;
  }

  Future<void> stop() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized && controller.value.isPlaying) {
      await controller.pause();
    }
  }
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
  const _PlayerSurface({required this.controller, required this.videoId, required this.fullscreen, required this.onFullscreen, this.keyframes = const [], this.onKeyframes, this.onAddKeyframe});
  final VideoPlayerController controller;
  final String videoId;
  final bool fullscreen;
  final Future<void> Function() onFullscreen;
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
    final size = MediaQuery.sizeOf(context);
    final direction = _dragDirection ??= details.delta.dx.abs() > details.delta.dy.abs() ? _DragDirection.horizontal : _DragDirection.vertical;
    if (direction == _DragDirection.horizontal) {
      final duration = widget.controller.value.duration;
      if (duration != Duration.zero) widget.controller.seekTo(Duration(milliseconds: (widget.controller.value.position.inMilliseconds + details.delta.dx / size.width * duration.inMilliseconds).round().clamp(0, duration.inMilliseconds).toInt()));
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SliderTheme(
            data: const SliderThemeData(year2023: true),
            child: Slider(
              value: progress.clamp(0, 1).toDouble(),
              onChanged: (next) {
                controller.seekTo(
                  Duration(
                    milliseconds: (next * value.duration.inMilliseconds).round(),
                  ),
                );
                onInteraction();
              },
            ),
          ),
        ),
        SizedBox(height: 40, child: Row(children: [IconButton(color: Colors.white, tooltip: value.isPlaying ? l10n.pause : l10n.play, visualDensity: VisualDensity.compact, onPressed: () { value.isPlaying ? controller.pause() : controller.play(); onInteraction(); }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)), const Spacer(), _SpeedMenu(controller: controller, onInteraction: onInteraction), IconButton(color: Colors.white, tooltip: fullscreen ? l10n.exitFullscreen : l10n.fullscreenPlayback, visualDensity: VisualDensity.compact, onPressed: onFullscreen, icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen))])),
          ]);
        },
      ),
    ),
  );
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
