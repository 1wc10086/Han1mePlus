import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

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
import 'video_player_controls.dart';
import 'video_player_surface.dart';

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
  static const _watchThresholdMs = 5000;
  final ValueNotifier<VideoPlayerController?> _controllerNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _qualityNotifier = ValueNotifier(null);
  String? _selectedQuality;
  String? _loadedQuality;
  Object? _loadError;
  var _loadVersion = 0;
  bool _restored = false;
  bool _fullscreenOpen = false;
  bool _disposed = false;
  bool _notifiersDisposed = false;
  bool _routeSubscribed = false;
  VideoPlayerController? _pendingDispose;
  final _disposing = <VideoPlayerController>{};
  final _pendingInitialize = <VideoPlayerController, Future<void>>{};
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);
  var _autoNextTriggered = false;
  bool? _wasPlaying;
  Duration _watched = Duration.zero;
  DateTime? _lastWatchedAt;
  late final WatchController _watchController;

  @override
  void initState() {
    super.initState();
    _watchController = ref.read(watchProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    _controllerNotifier.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSource();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controllerNotifier.value;
    if (controller == null || !controller.value.isInitialized || !controller.value.isPlaying) return;
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings?.autoPictureInPicture == true) {
      if (state == AppLifecycleState.inactive) {
        unawaited(_tryEnterPictureInPicture(controller));
      } else if (state == AppLifecycleState.paused) {
        unawaited(_pauseIfNotPip(controller));
      } else if (state == AppLifecycleState.resumed) {
        if (identical(VideoPlayerShutdown.pipActive, controller)) VideoPlayerShutdown.pipActive = null;
      }
      return;
    }
    if (state == AppLifecycleState.paused) unawaited(controller.pause());
  }

  Future<void> _tryEnterPictureInPicture(VideoPlayerController controller) async {
    var entered = false;
    try {
      entered = await PlatformService.enterPictureInPicture();
    } catch (_) {}
    if (entered) VideoPlayerShutdown.pipActive = controller;
  }

  Future<void> _pauseIfNotPip(VideoPlayerController controller) async {
    if (identical(VideoPlayerShutdown.pipActive, controller)) return;
    try {
      await controller.pause();
    } catch (_) {}
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
    _recordWatch();
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
        _watched = Duration.zero;
        _lastWatchedAt = null;
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
    final wasPlaying = current?.value.isInitialized == true && current!.value.isPlaying;
    _selectedQuality = source.quality;
    await _load(source, startAt: position, resumePlaying: wasPlaying);
  }

  Future<void> _changeSuperResolution(SuperResolutionMode mode) async {
    final settings = await ref.read(settingsProvider.future);
    if (settings.superResolutionMode == mode) return;
    final current = _controllerNotifier.value;
    final position = current?.value.isInitialized == true ? current!.value.position : null;
    final wasPlaying = current?.value.isInitialized == true && current!.value.isPlaying;
    final source = widget.video.sources.where((source) => source.quality == _loadedQuality).firstOrNull;
    await ref.read(settingsProvider.notifier).saveChanges(
          (current) => current.copyWith(superResolutionMode: mode),
        );
    if (source != null) await _load(source, startAt: position, resumePlaying: wasPlaying);
  }

  Future<void> _load(VideoSource source, {Duration? startAt, bool resumePlaying = false}) async {
    final version = ++_loadVersion;
    final previous = _controllerNotifier.value;
    _controllerNotifier.value = null;
    _qualityNotifier.value = null;
    _loadedQuality = null;
    if (mounted) setState(() {});
    if (previous != null) {
      if (previous.value.isInitialized && previous.value.isPlaying) {
        unawaited(previous.pause().catchError((_) {}));
      }
      unawaited(_queueDisposal(previous));
    }
    if (!mounted || version != _loadVersion) return;
    final settings = await ref.read(settingsProvider.future);
    if (!mounted || version != _loadVersion) return;
    final getchuTrailer = widget.video.id.startsWith('getchu-');
    final controller = source.url.startsWith('/')
        ? VideoPlayerController.file(File(source.url))
        : VideoPlayerController.networkUrl(
            Uri.parse(source.url),
            httpHeaders: {
              'User-Agent': Han1meApi.userAgent,
              'Referer': getchuTrailer ? 'https://www.getchu.com/' : '${settings.resolvedBaseUrl}/watch?v=${widget.video.id}',
              if (getchuTrailer) 'Cookie': 'getchu_adalt_flag=getchu.com; gc=gc',
            },
          );
    _loadedQuality = source.quality;
    _qualityNotifier.value = source.quality;
    _wasPlaying = null;
    VideoPlayerShutdown.track(controller);
    setState(() {
      _controllerNotifier.value = controller;
      _loadError = null;
    });
    try {
      final initializing = controller.initialize();
      _pendingInitialize[controller] = initializing;
      await initializing;
      _pendingInitialize.remove(controller);
      if (!mounted || version != _loadVersion || !identical(controller, _controllerNotifier.value)) {
        unawaited(_queueDisposal(controller));
        return;
      }
      if (mounted && version == _loadVersion) setState(() {});
      controller.addListener(_saveProgress);
      await _applyPlaybackPreferences(controller, version, startAt, resumePlaying: resumePlaying);
      if (!mounted || version != _loadVersion || !identical(controller, _controllerNotifier.value)) return;
      _saveProgress(controller);
    } catch (error) {
      _pendingInitialize.remove(controller);
      unawaited(_queueDisposal(controller));
      if (identical(controller, _controllerNotifier.value)) {
        _controllerNotifier.value = null;
        _qualityNotifier.value = null;
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
    try {
      controller.removeListener(_saveProgress);
    } catch (_) {}
    final pending = _pendingInitialize.remove(controller);
    if (pending != null) {
      try {
        await pending.timeout(const Duration(seconds: 20));
      } catch (_) {}
    }
    try {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        await controller.pause().timeout(const Duration(milliseconds: 500));
      }
    } catch (_) {}
    try {
      await controller.dispose().timeout(const Duration(seconds: 3));
    } catch (_) {}
    VideoPlayerShutdown.untrack(controller);
  }

  Future<void> _queueDisposal(VideoPlayerController controller) {
    if (!_disposing.add(controller)) return Future<void>.value();
    return _disposeController(controller).whenComplete(() => _disposing.remove(controller));
  }

  Future<void> _applyPlaybackPreferences(VideoPlayerController controller, int version, Duration? startAt, {bool resumePlaying = false}) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      if (!mounted || version != _loadVersion || controller != _controllerNotifier.value) return;
      await controller.setPlaybackSpeed(settings.defaultPlaybackSpeed);
      await controller.setLooping(settings.loopPlayback);
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
      if (resumePlaying || (startAt == null && settings.autoPlayOnOpen)) await controller.play();
    } catch (_) {}
  }

  void _saveProgress([VideoPlayerController? triggering]) {
    final controller = triggering ?? _controllerNotifier.value;
    if (!identical(controller, _controllerNotifier.value)) return;
    final value = controller?.value;
    if (controller == null || value == null || !value.isInitialized) {
      _lastWatchedAt = null;
      return;
    }
    final now = DateTime.now();
    final lastWatchedAt = _lastWatchedAt;
    if (value.isPlaying && lastWatchedAt != null) _watched += now.difference(lastWatchedAt);
    _lastWatchedAt = value.isPlaying ? now : null;
    if (_wasPlaying != value.isPlaying) {
      _wasPlaying = value.isPlaying;
      if (value.isPlaying) unawaited(VideoPlayerShutdown.pauseAllExcept(controller));
      widget.onPlayingChanged?.call(value.isPlaying);
    }
    if (value.duration > Duration.zero && value.position >= value.duration) {
      if (ref.read(settingsProvider).valueOrNull?.loopPlayback == true) {
        unawaited(controller.seekTo(Duration.zero));
        if (!value.isPlaying) unawaited(controller.play());
        return;
      }
      if (!_autoNextTriggered && ref.read(settingsProvider).valueOrNull?.autoPlayNext == true && widget.onNext != null) {
        _autoNextTriggered = true;
        widget.onNext!();
        return;
      }
    }
    if (ref.read(settingsProvider).valueOrNull?.incognitoPlayback == true) return;
    if (DateTime.now().difference(_lastSaved).inSeconds < 5) return;
    _lastSaved = DateTime.now();
    ref.read(watchProvider.notifier).progress(id: widget.video.id, title: widget.video.title, coverUrl: widget.video.coverUrl, positionMs: value.position.inMilliseconds, durationMs: value.duration.inMilliseconds);
  }

  void _recordWatch() {
    final watchedMs = _watched.inMilliseconds;
    if (watchedMs < _watchThresholdMs) return;
    _watched = Duration.zero;
    if (ref.read(settingsProvider).valueOrNull?.incognitoPlayback == true) return;
    unawaited(_watchController.addTime(widget.video.id, widget.video.title, watchedMs).catchError((_) {}));
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
      try {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      } finally {
        if (mounted) {
          _syncSource();
        } else if (_disposed) {
          final active = _pendingDispose ?? _controllerNotifier.value;
          _pendingDispose = null;
          try {
            if (active != null) await _queueDisposal(active);
          } finally {
            _disposeNotifiers();
          }
        }
      }
    }
  }

  void _disposeNotifiers() {
    if (_notifiersDisposed) return;
    _notifiersDisposed = true;
    _controllerNotifier.dispose();
    _qualityNotifier.dispose();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _loadVersion++;
    try {
      _saveProgress();
    } catch (_) {}
    _recordWatch();
    _wasPlaying = false;
    widget.onPlayingChanged?.call(false);
    final controller = _controllerNotifier.value;
    _controllerNotifier.value = null;
    if (identical(VideoPlayerShutdown.pipActive, controller)) VideoPlayerShutdown.pipActive = null;
    if (controller != null) {
      if (_fullscreenOpen) {
        _pendingDispose = controller;
      } else {
        if (controller.value.isInitialized) {
          unawaited(controller.pause().catchError((_) {}));
        }
        unawaited(_queueDisposal(controller));
      }
    }
    _controllerNotifier.removeListener(_handleControllerChanged);
    if (!_fullscreenOpen) {
      _disposeNotifiers();
    }
    super.dispose();
  }

  void _handleRoutePop(bool didPop, Object? result) {
    if (!didPop) return;
    _recordWatch();
    unawaited(_pausePlayback());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsProvider.select((value) => value.valueOrNull?.preferredQuality ?? 720), (_, __) => _syncSource());
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: _handleRoutePop,
      child: _buildPlayer(context),
    );
  }

  Widget _buildPlayer(BuildContext context) {
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
       child: VideoPlayerSurface(controller: _controllerNotifier, quality: _qualityNotifier, video: widget.video, onQualitySelected: _changeQuality, onSuperResolutionSelected: _changeSuperResolution, fullscreen: false, onFullscreen: _fullscreen, onBack: widget.onBack, onNext: widget.onNext, onEpisodeSelected: widget.onEpisodeSelected),
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
      endDrawer: VideoKeyframeDrawer(video: video, controller: controller),
       body: SafeArea(child: Builder(builder: (scaffoldContext) => VideoPlayerSurface(controller: controller, quality: quality, video: video, onQualitySelected: onQualitySelected, onSuperResolutionSelected: onSuperResolutionSelected, fullscreen: true, onFullscreen: () async => Navigator.of(context).pop(), onBack: () => Navigator.of(context).pop(), onEpisodeSelected: onEpisodeSelected, onNext: onNext, keyframes: enabled ? keyframes : const [], onKeyframes: enabled ? () => Scaffold.of(scaffoldContext).openEndDrawer() : null, onAddKeyframe: enabled ? () => _addKeyframe(context, ref) : null))),
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
