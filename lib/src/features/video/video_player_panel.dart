import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import '../../core/route_observer.dart';
import '../../core/settings.dart';
import '../../core/video_player_shutdown.dart';
import '../../data/local/keyframe_repository.dart';
import '../../data/local/watch_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import 'android_cast_button.dart';

class VideoPlayerPanel extends ConsumerStatefulWidget {
  const VideoPlayerPanel({super.key, required this.video, required this.onBack, this.onNext, this.onEpisodeSelected, this.onPlayingChanged});
  final VideoDetail video;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final ValueChanged<VideoCard>? onEpisodeSelected;
  final ValueChanged<bool>? onPlayingChanged;

  @override
  ConsumerState<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends ConsumerState<VideoPlayerPanel> with RouteAware, WidgetsBindingObserver {
  final ValueNotifier<VideoPlayerController?> _controllerNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _qualityNotifier = ValueNotifier(null);
  String? _selectedQuality;
  String? _loadedQuality;
  Object? _loadError;
  var _loadVersion = 0;
  bool _restored = false;
  bool _fullscreenOpen = false;
  bool _disposed = false;
  bool _routeSubscribed = false;
  Future<void> _controllerDisposal = Future<void>.value();
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);
  var _autoNextTriggered = false;
  bool? _wasPlaying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controllerNotifier.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSource();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive && state != AppLifecycleState.paused) return;
    final settings = ref.read(settingsProvider).valueOrNull;
    final playing = _controllerNotifier.value?.value.isPlaying ?? false;
    if (settings?.autoPictureInPicture == true && playing) unawaited(PlatformService.enterPictureInPicture());
  }

  void _handleControllerChanged() {
    if (mounted && !_disposed) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeSubscribed) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      _routeSubscribed = true;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    if (_fullscreenOpen) return;
    unawaited(_pausePlayback());
  }

  Future<void> _pausePlayback() async {
    final controller = _controllerNotifier.value;
    if (controller == null || !controller.value.isInitialized || !controller.value.isPlaying) return;
    try {
      await controller.pause();
    } catch (_) {}
  }

  @override
  void didUpdateWidget(VideoPlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id ||
        !_sameSources(oldWidget.video.sources, widget.video.sources)) {
      _loadedQuality = null;
      if (oldWidget.video.id != widget.video.id) {
        _restored = false;
        _autoNextTriggered = false;
      }
      _syncSource();
    }
  }

  void _syncSource() {
    if (_fullscreenOpen) return;
    if (widget.video.sources.isEmpty) {
      unawaited(_clearSource());
      return;
    }
    final preferred = ref.read(settingsProvider).valueOrNull?.preferredQuality ?? 720;
    final quality = _qualityValue(_selectedQuality) ?? preferred;
    final source = widget.video.sources.reduce((best, item) => (_quality(item) - quality).abs() < (_quality(best) - quality).abs() ? item : best);
    if (source.quality != _loadedQuality) _load(source);
  }

  int? _qualityValue(String? label) {
    if (label == null) return null;
    return int.tryParse(RegExp(r'\d+').firstMatch(label)?.group(0) ?? '');
  }

  int _quality(VideoSource source) => _qualityValue(source.quality) ?? 720;

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
    final controller = _controllerNotifier.value;
    _controllerNotifier.value = null;
    _qualityNotifier.value = null;
    _loadedQuality = null;
    if (mounted) setState(() => _loadError = const _NoVideoSource());
    if (controller != null) await _queueDisposal(controller);
  }

  Future<void> _changeQuality(VideoSource source) async {
    final current = _controllerNotifier.value;
    final position = current?.value.isInitialized == true ? current!.value.position : null;
    _selectedQuality = source.quality;
    await _load(source, startAt: position);
  }

  Future<void> _changeSuperResolution(SuperResolutionMode mode) async {
    final settings = await ref.read(settingsProvider.future);
    if (settings.superResolutionMode == mode) return;
    final current = _controllerNotifier.value;
    final position = current?.value.isInitialized == true ? current!.value.position : null;
    final source = widget.video.sources.where((source) => source.quality == _loadedQuality).firstOrNull;
    await ref.read(settingsProvider.notifier).saveChanges(
          (current) => current.copyWith(superResolutionMode: mode),
        );
    if (source != null) await _load(source, startAt: position);
  }

  Future<void> _load(VideoSource source, {Duration? startAt}) async {
    final version = ++_loadVersion;
    final previous = _controllerNotifier.value;
    _controllerNotifier.value = null;
    _qualityNotifier.value = null;
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
              'Referer': '${settings.resolvedBaseUrl}/watch?v=${widget.video.id}',
            },
          );
    _loadedQuality = source.quality;
    _qualityNotifier.value = source.quality;
    VideoPlayerShutdown.track(controller);
    setState(() {
      _controllerNotifier.value = controller;
      _loadError = null;
    });
    try {
      await controller.initialize();
      if (!mounted || version != _loadVersion) {
        return;
      }
      if (mounted && version == _loadVersion) setState(() {});
      await _applyPlaybackPreferences(controller, version, startAt);
      if (!mounted || version != _loadVersion || controller != _controllerNotifier.value) return;
       controller.addListener(_saveProgress);
    } catch (error) {
      if (controller == _controllerNotifier.value) {
        _controllerNotifier.value = null;
        _qualityNotifier.value = null;
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

  Future<void> _applyPlaybackPreferences(VideoPlayerController controller, int version, Duration? startAt) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!mounted || version != _loadVersion || controller != _controllerNotifier.value) return;
      await controller.setPlaybackSpeed(settings.defaultPlaybackSpeed);
      if (startAt != null) {
        await controller.seekTo(startAt);
      } else if (!_restored && settings.resumePlayback) {
        final watch = await ref.read(watchProvider.future);
        if (!mounted || version != _loadVersion || controller != _controllerNotifier.value) return;
        final item = watch.continueItems.where((item) => item.videoCode == widget.video.id).firstOrNull;
        if (item != null && item.positionMs > 0 && item.positionMs < item.durationMs - 3000) {
          await controller.seekTo(Duration(milliseconds: item.positionMs));
        }
      }
      _restored = true;
    } catch (_) {}
  }

  void _saveProgress() {
    final value = _controllerNotifier.value?.value;
    if (value == null || !value.isInitialized) return;
    if (_wasPlaying != value.isPlaying) {
      _wasPlaying = value.isPlaying;
      widget.onPlayingChanged?.call(value.isPlaying);
    }
    if (!_autoNextTriggered && ref.read(settingsProvider).valueOrNull?.autoPlayNext == true && value.duration > Duration.zero && value.position >= value.duration && widget.onNext != null) {
      _autoNextTriggered = true;
      widget.onNext!();
      return;
    }
    if (ref.read(settingsProvider).valueOrNull?.incognitoPlayback == true) return;
    if (DateTime.now().difference(_lastSaved).inSeconds < 5) return;
    _lastSaved = DateTime.now();
    ref.read(watchProvider.notifier).progress(id: widget.video.id, title: widget.video.title, coverUrl: widget.video.coverUrl, positionMs: value.position.inMilliseconds, durationMs: value.duration.inMilliseconds);
  }

  Future<void> _fullscreen() async {
    final controller = _controllerNotifier.value;
    if (controller == null || _fullscreenOpen) return;
    _fullscreenOpen = true;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _FullscreenPlayer(controller: _controllerNotifier, quality: _qualityNotifier, video: widget.video, onQualitySelected: _changeQuality, onSuperResolutionSelected: _changeSuperResolution, onEpisodeSelected: widget.onEpisodeSelected == null ? null : (episode) { Navigator.of(context).pop(); widget.onEpisodeSelected!(episode); }, onNext: widget.onNext)));
    } finally {
      _fullscreenOpen = false;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      if (mounted) {
        _syncSource();
      } else if (_disposed) {
        final active = _controllerNotifier.value;
        if (active != null) await _queueDisposal(active);
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _loadVersion++;
    _saveProgress();
    _wasPlaying = false;
    widget.onPlayingChanged?.call(false);
    final controller = _controllerNotifier.value;
    _controllerNotifier.value = null;
    if (controller != null && !_fullscreenOpen) unawaited(_queueDisposal(controller));
    _controllerNotifier.removeListener(_handleControllerChanged);
    if (!_fullscreenOpen) {
      _controllerNotifier.dispose();
      _qualityNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsProvider.select((value) => value.valueOrNull?.preferredQuality ?? 720), (_, __) => _syncSource());
    final controller = _controllerNotifier.value;
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
       child: _PlayerSurface(controller: _controllerNotifier, quality: _qualityNotifier, video: widget.video, onQualitySelected: _changeQuality, onSuperResolutionSelected: _changeSuperResolution, fullscreen: false, onFullscreen: _fullscreen, onBack: widget.onBack, onNext: widget.onNext, onEpisodeSelected: widget.onEpisodeSelected),
    );
  }
}

class _PlayerFrame extends StatelessWidget {
  const _PlayerFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
      );
}

class _NoVideoSource {
  const _NoVideoSource();
}

class _FullscreenPlayer extends ConsumerWidget {
  const _FullscreenPlayer({required this.controller, required this.quality, required this.video, required this.onQualitySelected, required this.onSuperResolutionSelected, this.onEpisodeSelected, this.onNext});
  final ValueListenable<VideoPlayerController?> controller;
  final ValueListenable<String?> quality;
  final VideoDetail video;
  final ValueChanged<VideoSource> onQualitySelected;
  final ValueChanged<SuperResolutionMode> onSuperResolutionSelected;
  final ValueChanged<VideoCard>? onEpisodeSelected;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyframes = ref.watch(keyframesProvider(video.id)).valueOrNull ?? const <int>[];
    final enabled = ref.watch(settingsProvider).valueOrNull?.keyframesEnabled ?? true;
    return Scaffold(
      backgroundColor: Colors.black,
      endDrawer: _KeyframeDrawer(video: video, controller: controller),
       body: SafeArea(child: Builder(builder: (scaffoldContext) => _PlayerSurface(controller: controller, quality: quality, video: video, onQualitySelected: onQualitySelected, onSuperResolutionSelected: onSuperResolutionSelected, fullscreen: true, onFullscreen: () async => Navigator.of(context).pop(), onBack: () => Navigator.of(context).pop(), onEpisodeSelected: onEpisodeSelected, onNext: onNext, keyframes: enabled ? keyframes : const [], onKeyframes: enabled ? () => Scaffold.of(scaffoldContext).openEndDrawer() : null, onAddKeyframe: enabled ? () => _addKeyframe(context, ref) : null))),
    );
  }

  Future<void> _addKeyframe(BuildContext context, WidgetRef ref) async {
    final controller = this.controller.value;
    if (controller == null) return;
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
  const _PlayerSurface({required this.controller, required this.quality, required this.video, required this.fullscreen, required this.onFullscreen, required this.onQualitySelected, required this.onSuperResolutionSelected, this.onBack, this.onNext, this.onEpisodeSelected, this.keyframes = const [], this.onKeyframes, this.onAddKeyframe});
  final ValueListenable<VideoPlayerController?> controller;
  final ValueListenable<String?> quality;
  final VideoDetail video;
  final bool fullscreen;
  final Future<void> Function() onFullscreen;
  final ValueChanged<VideoSource> onQualitySelected;
  final ValueChanged<SuperResolutionMode> onSuperResolutionSelected;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<VideoCard>? onEpisodeSelected;
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
  Duration? _seekStartPosition;
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
  void _togglePlayback() {
    final controller = widget.controller.value;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    _restartTimer();
  }

  void _longPress(bool active) {
    final controller = widget.controller.value;
    if (controller == null) return;
    final speed = ref.read(settingsProvider).valueOrNull?.longPressPlaybackSpeed ?? 2;
    controller.setPlaybackSpeed(active ? speed : (ref.read(settingsProvider).valueOrNull?.defaultPlaybackSpeed ?? 1));
    setState(() => _adjustment = active ? _Adjustment.speed(speed) : null);
  }

  void _dragStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _dragStartY = details.localPosition.dy;
    _dragDirection = null;
    _seekStartPosition = widget.controller.value?.value.position;
  }

  void _dragUpdate(DragUpdateDetails details) {
    final startX = _dragStartX;
    if (startX == null || _locked) return;
    final controller = widget.controller.value;
    if (controller == null) return;
    final size = context.size ?? MediaQuery.sizeOf(context);
    final direction = _dragDirection ??= details.delta.dx.abs() > details.delta.dy.abs() ? _DragDirection.horizontal : _DragDirection.vertical;
    if (direction == _DragDirection.horizontal) {
      final duration = controller.value.duration;
      final sensitivity = ref.read(settingsProvider).valueOrNull?.seekSensitivity ?? .35;
      if (duration != Duration.zero) {
        final position = (controller.value.position.inMilliseconds + details.delta.dx / size.width * duration.inMilliseconds * sensitivity).round().clamp(0, duration.inMilliseconds).toInt();
        controller.seekTo(Duration(milliseconds: position));
        final startMs = _seekStartPosition?.inMilliseconds ?? position;
        setState(() => _adjustment = _Adjustment.seek(position - startMs, Duration(milliseconds: position), duration));
      }
      return;
    }
    final value = (startX < size.width / 2 ? _brightness : _volume) - details.delta.dy / size.height;
    if (startX < size.width / 2) { _brightness = value.clamp(0.01, 1).toDouble(); PlatformService.setScreenBrightness(_brightness); setState(() => _adjustment = _Adjustment.brightness(_brightness)); }
    else { _volume = value.clamp(0, 1).toDouble(); PlatformService.setVolume(_volume); setState(() => _adjustment = _Adjustment.volume(_volume)); }
  }
  void _dragEnd(DragEndDetails details) { _dragStartX = null; _dragStartY = null; _dragDirection = null; _seekStartPosition = null; Future<void>.delayed(const Duration(milliseconds: 700), () { if (mounted) setState(() => _adjustment = null); }); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: widget.controller,
      builder: (context, activeController, _) {
        final controller = activeController;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: M3ELoadingIndicator(color: Colors.white));
        }
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
            _VideoViewport(controller: controller),
            ValueListenableBuilder<VideoPlayerValue>(valueListenable: controller, builder: (context, value, _) => value.isBuffering ? const Center(child: M3ELoadingIndicator(color: Colors.white)) : const SizedBox.shrink()),
            ValueListenableBuilder<VideoPlayerValue>(valueListenable: controller, builder: (context, value, _) => _showControls && !_locked ? _Controls(controller: controller, fullscreen: widget.fullscreen, onFullscreen: widget.onFullscreen, onInteraction: _restartTimer, video: widget.video, quality: widget.quality, onQualitySelected: widget.onQualitySelected, onSuperResolutionSelected: widget.onSuperResolutionSelected, onNext: widget.onNext, onEpisodeSelected: widget.onEpisodeSelected) : const SizedBox.shrink()),
            if (_locked) Align(alignment: Alignment.centerRight, child: IconButton(color: Colors.white, tooltip: l10n.unlockControls, onPressed: () { setState(() => _locked = false); _restartTimer(); }, icon: const Icon(Icons.lock))),
            if (_showControls && !_locked && widget.onBack != null) Positioned(top: 8, left: 8, child: BackButton(color: Colors.white, onPressed: widget.onBack)),
            if (_showControls && widget.fullscreen && !_locked) Align(alignment: Alignment.centerRight, child: IconButton(color: Colors.white, tooltip: l10n.lockControls, onPressed: () => setState(() => _locked = true), icon: const Icon(Icons.lock_open_outlined))),
            if (widget.fullscreen && widget.keyframes.isNotEmpty) _KeyframeCountdown(controller: controller, keyframes: widget.keyframes),
            if (_showControls && widget.fullscreen && !_locked) Positioned(top: 8, left: 48, right: 212, child: _MarqueeTitle(title: widget.video.title)),
            if (_showControls && !_locked)
              Positioned(
                top: 4,
                right: widget.fullscreen && widget.onKeyframes != null ? 56 : 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SkipButton(controller: controller, onInteraction: _restartTimer),
                    if (Platform.isAndroid) IconButton(color: Colors.white, tooltip: l10n.pictureInPicture, visualDensity: VisualDensity.compact, onPressed: PlatformService.enterPictureInPicture, icon: const Icon(Icons.picture_in_picture_alt_outlined)),
                    widget.fullscreen
                        ? _FullscreenMoreMenu(sources: widget.video.sources, quality: widget.quality)
                        : _PortraitMoreMenu(controller: controller, video: widget.video, quality: widget.quality, onQualitySelected: widget.onQualitySelected, onSuperResolutionSelected: widget.onSuperResolutionSelected),
                  ],
                ),
              ),
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
            if (_adjustment != null)
              switch (_adjustment!.kind) {
                _AdjustmentKind.brightness => Positioned(top: 24, left: 16, child: _AdjustmentHud(adjustment: _adjustment!)),
                _AdjustmentKind.volume => Positioned(top: 24, right: 16, child: _AdjustmentHud(adjustment: _adjustment!)),
                _ => Positioned(top: 24, left: 0, right: 0, child: Center(child: _AdjustmentHud(adjustment: _adjustment!))),
              },
          ]),
        );
      },
    );
  }
}

class _VideoViewport extends ConsumerWidget {
  const _VideoViewport({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspect = ref.watch(settingsProvider).valueOrNull?.videoAspectRatio ?? VideoAspectRatio.auto;
    final ratio = controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio;
    return switch (aspect) {
      VideoAspectRatio.auto => Center(child: AspectRatio(aspectRatio: ratio, child: VideoPlayer(controller))),
      VideoAspectRatio.ratio4x3 => Center(child: AspectRatio(aspectRatio: 4 / 3, child: FittedBox(fit: BoxFit.contain, child: SizedBox(width: ratio * 1000, height: 1000, child: VideoPlayer(controller))))),
      VideoAspectRatio.crop => Positioned.fill(child: FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: ratio * 1000, height: 1000, child: VideoPlayer(controller)))),
      VideoAspectRatio.stretch => Positioned.fill(child: FittedBox(fit: BoxFit.fill, child: SizedBox(width: ratio * 1000, height: 1000, child: VideoPlayer(controller)))),
    };
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.fullscreen, required this.onFullscreen, required this.onInteraction, required this.video, required this.quality, required this.onQualitySelected, required this.onSuperResolutionSelected, this.onNext, this.onEpisodeSelected});
  final VideoPlayerController controller;
  final bool fullscreen;
  final Future<void> Function() onFullscreen;
  final VoidCallback onInteraction;
  final VideoDetail video;
  final ValueListenable<String?> quality;
  final ValueChanged<VideoSource> onQualitySelected;
  final ValueChanged<SuperResolutionMode> onSuperResolutionSelected;
  final VoidCallback? onNext;
  final ValueChanged<VideoCard>? onEpisodeSelected;

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
          if (!fullscreen) return SizedBox(height: 48, child: Row(children: [IconButton(color: Colors.white, tooltip: value.isPlaying ? l10n.pause : l10n.play, visualDensity: VisualDensity.compact, onPressed: () { value.isPlaying ? controller.pause() : controller.play(); onInteraction(); }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)), Expanded(child: SliderTheme(data: const SliderThemeData(year2023: true), child: Slider(value: progress.clamp(0, 1).toDouble(), onChanged: (next) { controller.seekTo(Duration(milliseconds: (next * value.duration.inMilliseconds).round())); onInteraction(); }))), SizedBox(width: 48, child: Text(_formatDuration(value.position), textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))), IconButton(color: Colors.white, tooltip: l10n.fullscreenPlayback, visualDensity: VisualDensity.compact, onPressed: onFullscreen, icon: const Icon(Icons.fullscreen))]));
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [SizedBox(width: 48, child: Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))), Expanded(child: SliderTheme(data: const SliderThemeData(year2023: true), child: Slider(value: progress.clamp(0, 1).toDouble(), onChanged: (next) { controller.seekTo(Duration(milliseconds: (next * value.duration.inMilliseconds).round())); onInteraction(); }))), SizedBox(width: 48, child: Text(_formatDuration(value.duration), textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])))]),
            SizedBox(height: 40, child: Row(children: [IconButton(color: Colors.white, tooltip: value.isPlaying ? l10n.pause : l10n.play, visualDensity: VisualDensity.compact, onPressed: () { value.isPlaying ? controller.pause() : controller.play(); onInteraction(); }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)), if (onNext != null) IconButton(color: Colors.white, tooltip: l10n.autoPlayNext, visualDensity: VisualDensity.compact, onPressed: onNext, icon: const Icon(Icons.skip_next)), const Spacer(), _AspectMenu(), if (onEpisodeSelected != null && video.playlist.isNotEmpty) _EpisodeMenu(video: video, onSelected: onEpisodeSelected!), _Anime4KMenu(onSelected: onSuperResolutionSelected), if (video.sources.isNotEmpty) _QualityMenu(sources: video.sources, quality: quality, onSelected: onQualitySelected), _SpeedMenu(controller: controller, onInteraction: onInteraction), AndroidCastButton(sources: video.sources, quality: quality), IconButton(color: Colors.white, tooltip: l10n.exitFullscreen, visualDensity: VisualDensity.compact, onPressed: onFullscreen, icon: const Icon(Icons.fullscreen_exit))])),
          ]);
        },
      ),
    ),
  );
}

class _SkipButton extends ConsumerWidget {
  const _SkipButton({required this.controller, required this.onInteraction});
  final VideoPlayerController controller;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(settingsProvider).valueOrNull?.skipSeconds ?? 80;
    return GestureDetector(
      onLongPress: () => _configure(context, ref, seconds),
      child: IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.seconds(seconds), visualDensity: VisualDensity.compact, onPressed: () { final value = controller.value; final target = (value.position.inSeconds + seconds).clamp(0, value.duration.inSeconds); controller.seekTo(Duration(seconds: target)); onInteraction(); }, icon: const Icon(Icons.forward_10)),
    );
  }

  Future<void> _configure(BuildContext context, WidgetRef ref, int current) async {
    final result = await showDialog<int>(context: context, builder: (_) => _SkipSecondsDialog(initialValue: '$current'));
    if (result != null && result > 0) await ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(skipSeconds: result));
  }
}

class _SkipSecondsDialog extends StatefulWidget {
  const _SkipSecondsDialog({required this.initialValue});
  final String initialValue;

  @override
  State<_SkipSecondsDialog> createState() => _SkipSecondsDialogState();
}

class _SkipSecondsDialogState extends State<_SkipSecondsDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.seconds(int.tryParse(widget.initialValue) ?? 0)),
      content: TextField(controller: _controller, autofocus: true, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(_controller.text.trim())), child: Text(l10n.save)),
      ],
    );
  }
}

class _AspectMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspect = ref.watch(settingsProvider).valueOrNull?.videoAspectRatio ?? VideoAspectRatio.auto;
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.videoAspectRatio, onPressed: controller.open, icon: const Icon(Icons.aspect_ratio)),
      menuChildren: VideoAspectRatio.values.map((item) => MenuItemButton(onPressed: () => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(videoAspectRatio: item)), leadingIcon: item == aspect ? const Icon(Icons.check, size: 18) : null, child: Text(_label(AppLocalizations.of(context)!, item)))).toList(),
    );
  }

  String _label(AppLocalizations l10n, VideoAspectRatio aspect) => switch (aspect) { VideoAspectRatio.auto => l10n.aspectAuto, VideoAspectRatio.crop => l10n.aspectCrop, VideoAspectRatio.stretch => l10n.aspectStretch, VideoAspectRatio.ratio4x3 => l10n.aspectFourThree };
}

class _EpisodeMenu extends StatelessWidget {
  const _EpisodeMenu({required this.video, required this.onSelected});
  final VideoDetail video;
  final ValueChanged<VideoCard> onSelected;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        builder: (context, controller, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.episodeList, onPressed: controller.open, icon: const Icon(Icons.view_list_outlined)),
        menuChildren: video.playlist.map((episode) => MenuItemButton(onPressed: episode.id == video.id ? null : () => onSelected(episode), leadingIcon: episode.id == video.id ? const Icon(Icons.play_arrow) : null, child: SizedBox(width: 280, child: Text(episode.title, maxLines: 1, overflow: TextOverflow.ellipsis)))).toList(),
      );
}

class _MarqueeTitle extends StatefulWidget {
  const _MarqueeTitle({required this.title});
  final String title;

  @override
  State<_MarqueeTitle> createState() => _MarqueeTitleState();
}

class _MarqueeTitleState extends State<_MarqueeTitle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: (widget.title.length * 85).clamp(4000, 16000).toInt()))..repeat();
  }

  @override
  void didUpdateWidget(_MarqueeTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title == widget.title) return;
    _controller
      ..duration = Duration(milliseconds: (widget.title.length * 85).clamp(4000, 16000).toInt())
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final style = const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
        final painter = TextPainter(text: TextSpan(text: widget.title, style: style), maxLines: 1, textDirection: TextDirection.ltr)..layout();
        final width = painter.width;
        if (width <= constraints.maxWidth) return Text(widget.title, maxLines: 1, style: style);
        final distance = width - constraints.maxWidth + 24;
        return ClipRect(child: AnimatedBuilder(animation: _controller, builder: (context, child) => Transform.translate(offset: Offset(-distance * _controller.value, 0), child: child), child: Text(widget.title, maxLines: 1, style: style)));
      });
}

class _PortraitMoreMenu extends ConsumerWidget {
  const _PortraitMoreMenu({required this.controller, required this.video, required this.quality, required this.onQualitySelected, required this.onSuperResolutionSelected});
  final VideoPlayerController controller;
  final VideoDetail video;
  final ValueListenable<String?> quality;
  final ValueChanged<VideoSource> onQualitySelected;
  final ValueChanged<SuperResolutionMode> onSuperResolutionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MenuAnchor(
        builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.more, onPressed: menu.open, icon: const Icon(Icons.more_vert)),
        menuChildren: [
          SubmenuButton(menuChildren: VideoAspectRatio.values.map((aspect) => MenuItemButton(onPressed: () => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(videoAspectRatio: aspect)), child: Text(_aspectLabel(AppLocalizations.of(context)!, aspect)))).toList(), child: Text(AppLocalizations.of(context)!.videoAspectRatio)),
          SubmenuButton(menuChildren: <double>[.5, .75, 1, 1.25, 1.5, 2, 3].map((speed) => MenuItemButton(onPressed: () => controller.setPlaybackSpeed(speed), child: Text('${speed}x'))).toList(), child: Text(AppLocalizations.of(context)!.playbackSpeed)),
          SubmenuButton(menuChildren: SuperResolutionMode.values.map((mode) => MenuItemButton(onPressed: () => onSuperResolutionSelected(mode), child: Text(_superResolutionLabel(AppLocalizations.of(context)!, mode)))).toList(), child: Text(AppLocalizations.of(context)!.superResolution)),
          if (video.sources.isNotEmpty) SubmenuButton(menuChildren: video.sources.map((source) => MenuItemButton(onPressed: () => onQualitySelected(source), child: Text(source.quality))).toList(), child: Text(AppLocalizations.of(context)!.quality)),
          if (video.sources.isNotEmpty) MenuItemButton(onPressed: () => _openExternal(video.sources, quality.value), leadingIcon: const Icon(Icons.open_in_new), child: Text(AppLocalizations.of(context)!.externalPlayback)),
        ],
      );

  Future<void> _openExternal(List<VideoSource> sources, String? current) async {
    final source = sources.where((source) => source.quality == current).firstOrNull ?? sources.first;
    await launchUrl(Uri.parse(source.url), mode: LaunchMode.externalApplication);
  }
}

class _FullscreenMoreMenu extends StatelessWidget {
  const _FullscreenMoreMenu({required this.sources, required this.quality});
  final List<VideoSource> sources;
  final ValueListenable<String?> quality;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.more, onPressed: menu.open, icon: const Icon(Icons.more_vert)),
        menuChildren: [
          if (sources.isNotEmpty) MenuItemButton(onPressed: () => _openExternal(), leadingIcon: const Icon(Icons.open_in_new), child: Text(AppLocalizations.of(context)!.externalPlayback)),
        ],
      );

  Future<void> _openExternal() async {
    final source = sources.where((source) => source.quality == quality.value).firstOrNull ?? sources.first;
    await launchUrl(Uri.parse(source.url), mode: LaunchMode.externalApplication);
  }
}

String _superResolutionLabel(AppLocalizations l10n, SuperResolutionMode mode) => switch (mode) { SuperResolutionMode.off => l10n.superResolutionOff, SuperResolutionMode.efficiency => l10n.superResolutionEfficiency, SuperResolutionMode.quality => l10n.superResolutionQuality };

String _aspectLabel(AppLocalizations l10n, VideoAspectRatio aspect) => switch (aspect) { VideoAspectRatio.auto => l10n.aspectAuto, VideoAspectRatio.crop => l10n.aspectCrop, VideoAspectRatio.stretch => l10n.aspectStretch, VideoAspectRatio.ratio4x3 => l10n.aspectFourThree };

class _Anime4KMenu extends ConsumerWidget {
  const _Anime4KMenu({required this.onSelected});

  final ValueChanged<SuperResolutionMode> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider).valueOrNull?.superResolutionMode ?? SuperResolutionMode.off;
    final l10n = AppLocalizations.of(context)!;
    return MenuAnchor(
      builder: (context, menu, child) => IconButton(
        color: Colors.white,
        tooltip: l10n.anime4k,
        onPressed: menu.open,
        icon: Icon(mode == SuperResolutionMode.off ? Icons.auto_awesome_outlined : Icons.auto_awesome),
      ),
      menuChildren: SuperResolutionMode.values.map((option) {
        final selected = option == mode;
        return MenuItemButton(
          onPressed: () => onSelected(option),
          leadingIcon: selected ? const Icon(Icons.check, size: 18) : null,
          child: Text(
            _label(l10n, option),
            style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700) : null,
          ),
        );
      }).toList(),
    );
  }

  String _label(AppLocalizations l10n, SuperResolutionMode mode) => switch (mode) {
        SuperResolutionMode.off => l10n.superResolutionOff,
        SuperResolutionMode.efficiency => l10n.superResolutionEfficiency,
        SuperResolutionMode.quality => l10n.superResolutionQuality,
      };
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

class _QualityMenu extends StatelessWidget {
  const _QualityMenu({required this.sources, required this.quality, required this.onSelected});
  final List<VideoSource> sources;
  final ValueListenable<String?> quality;
  final ValueChanged<VideoSource> onSelected;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: quality,
        builder: (context, current, _) => MenuAnchor(
          builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.quality, onPressed: menu.open, icon: const Icon(Icons.high_quality_outlined)),
          menuChildren: sources.map((source) {
            final selected = source.quality == current;
            return MenuItemButton(
              onPressed: () => onSelected(source),
              leadingIcon: selected ? const Icon(Icons.check, size: 18) : null,
              child: Text(source.quality, style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700) : null),
            );
          }).toList(),
        ),
      );
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.controller, required this.onInteraction});
  final VideoPlayerController controller;
  final VoidCallback onInteraction;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) => MenuAnchor(
          builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.playbackSpeed, onPressed: menu.open, icon: const Icon(Icons.speed)),
          menuChildren: <double>[.5, .75, 1, 1.25, 1.5, 2, 3].map((speed) {
            final selected = value.playbackSpeed == speed;
            return MenuItemButton(
              onPressed: () { controller.setPlaybackSpeed(speed); onInteraction(); },
              leadingIcon: selected ? const Icon(Icons.check, size: 18) : null,
              child: Text('${speed}x', style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700) : null),
            );
          }).toList(),
        ),
      );
}

enum _DragDirection { horizontal, vertical }
enum _AdjustmentKind { brightness, volume, speed, seek }
class _Adjustment {
  const _Adjustment(this.kind, this.value, {this.delta, this.position, this.duration});
  factory _Adjustment.brightness(double value) => _Adjustment(_AdjustmentKind.brightness, value);
  factory _Adjustment.volume(double value) => _Adjustment(_AdjustmentKind.volume, value);
  factory _Adjustment.speed(double value) => _Adjustment(_AdjustmentKind.speed, value);
  factory _Adjustment.seek(int delta, Duration position, Duration duration) => _Adjustment(_AdjustmentKind.seek, 0, delta: delta, position: position, duration: duration);
  final _AdjustmentKind kind;
  final double value;
  final int? delta;
  final Duration? position;
  final Duration? duration;
}

class _AdjustmentHud extends StatelessWidget {
  const _AdjustmentHud({required this.adjustment});
  final _Adjustment adjustment;

  @override
  Widget build(BuildContext context) => switch (adjustment.kind) {
        _AdjustmentKind.seek => _seekCard(),
        _AdjustmentKind.speed => _pill(Text('${adjustment.value}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        _ => _levelCard(),
      };

  Widget _pill(Widget child) => DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(999)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: child),
      );

  Widget _seekCard() {
    final delta = adjustment.delta ?? 0;
    final position = adjustment.position ?? Duration.zero;
    final duration = adjustment.duration ?? Duration.zero;
    return _pill(Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(delta >= 0 ? Icons.fast_forward : Icons.fast_rewind, color: Colors.white, size: 28),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('${delta >= 0 ? '+' : '-'}${_formatDuration(Duration(milliseconds: delta.abs()))}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${_formatDuration(position)}/${_formatDuration(duration)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    ]));
  }

  Widget _levelCard() {
    final brightness = adjustment.kind == _AdjustmentKind.brightness;
    final level = adjustment.value.clamp(0, 1).toDouble();
    return _pill(Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 180,
        height: 56,
        child: IgnorePointer(
          child: M3ESlider(
            value: level,
            onChanged: (_) {},
            icon: Icon(brightness ? Icons.brightness_6 : Icons.volume_up, size: 20),
            trailingIcon: false,
            decoration: M3ESliderDecoration(
              trackHeight: 44,
              trackCornerRadius: 22,
              thumbWidth: 6,
              thumbHeight: 56,
              trackIconSize: 20,
              trackIconActiveColor: Colors.white,
              trackIconInactiveColor: Colors.white70,
              colors: M3ESliderColors(
                thumbColor: Colors.white,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                disabledThumbColor: Colors.white,
                disabledActiveTrackColor: Colors.white,
                disabledInactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                activeTickColor: Colors.transparent,
                inactiveTickColor: Colors.transparent,
                disabledActiveTickColor: Colors.transparent,
                disabledInactiveTickColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text('${(level * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]));
  }
}

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
          return Positioned(left: 16, top: 60, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text(AppLocalizations.of(context)!.keyframeCountdown((remaining / 1000).toStringAsFixed(1)), style: const TextStyle(color: Colors.white)))));
        },
      );
}

class _KeyframeDrawer extends ConsumerWidget {
  const _KeyframeDrawer({required this.video, required this.controller});
  final VideoDetail video;
  final ValueListenable<VideoPlayerController?> controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyframes = ref.watch(keyframesProvider(video.id)).valueOrNull ?? const <int>[];
    return Drawer(child: SafeArea(child: Column(children: [
      ListTile(title: Text(AppLocalizations.of(context)!.keyframes), subtitle: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
      const Divider(height: 1),
      Expanded(child: keyframes.isEmpty ? Center(child: Text(AppLocalizations.of(context)!.noKeyframes)) : ListView.separated(itemCount: keyframes.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) {
        final position = keyframes[index];
        return ListTile(title: Text(_formatKeyframe(position)), subtitle: Text('$position ms'), onTap: () { controller.value?.seekTo(Duration(milliseconds: position)); Navigator.of(context).pop(); }, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(keyframesProvider(video.id).notifier).remove(position)));
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
