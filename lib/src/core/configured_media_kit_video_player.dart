import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'settings.dart';
import 'shader_assets.dart';
import 'shader_service.dart';
import 'logging/app_log.dart';

class ConfiguredMediaKitVideoPlayer extends VideoPlayerPlatform {
  static AppSettings settings = const AppSettings();
  static final ConfiguredMediaKitVideoPlayer _instance = ConfiguredMediaKitVideoPlayer();

  final _players = HashMap<int, Player>();
  final _completers = HashMap<int, Completer<void>>();
  final _videoControllers = HashMap<int, VideoController>();
  final _streamControllers = HashMap<int, StreamController<VideoEvent>>();
  final _streamSubscriptions = HashMap<int, List<StreamSubscription>>();
  final _initializationTimers = HashMap<int, Timer>();
  final _bufferingTimers = HashMap<int, Timer>();
  final _bufferingActive = HashMap<int, bool>();
  int _nextTextureId = 0;

  static void registerWith() {
    VideoPlayerPlatform.instance = _instance;
  }

  @override
  Future<void> init() async {
    final textureIds = _players.keys.toList(growable: false);
    for (final textureId in textureIds) {
      await dispose(textureId);
    }
    _players.clear();
    _completers.clear();
    _videoControllers.clear();
    _streamControllers.clear();
    _streamSubscriptions.clear();
    _initializationTimers.clear();
    _bufferingTimers.clear();
    _bufferingActive.clear();
  }

  @override
  Future<void> dispose(int textureId) async {
    _initializationTimers.remove(textureId)?.cancel();
    _bufferingTimers.remove(textureId)?.cancel();
    _bufferingActive.remove(textureId);
    final player = _players.remove(textureId);
    final streamController = _streamControllers.remove(textureId);
    final subscriptions = _streamSubscriptions.remove(textureId);
    _videoControllers.remove(textureId);
    final completer = _completers.remove(textureId);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    for (final subscription in subscriptions ?? const <StreamSubscription>[]) {
      try {
        await subscription.cancel();
      } catch (_) {}
    }
    if (streamController != null) {
      try {
        await streamController.close();
      } catch (_) {}
    }
    if (player != null) {
      try {
        await player.dispose().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    final player = Player();
    int? textureId;
    try {
      final native = player.platform as NativePlayer;
      await native.waitForPlayerInitialization;
      await _applyCustomParameters(native, settings);
      final videoController = VideoController(
        player,
        configuration: _videoConfiguration(settings),
      );
      await _applyShaders(native, settings);
      final completer = Completer<void>();
      final streamController = StreamController<VideoEvent>();
      final streamSubscriptions = <StreamSubscription>[];
      textureId = ++_nextTextureId;

      _players[textureId] = player;
      _completers[textureId] = completer;
      _videoControllers[textureId] = videoController;
      _streamControllers[textureId] = streamController;
      _streamSubscriptions[textureId] = streamSubscriptions;

      _initialize(textureId);

      final resource = switch (dataSource.sourceType) {
        DataSourceType.asset => dataSource.package == null
            ? 'asset:///${dataSource.asset}'
            : 'asset:///packages/${dataSource.package}/${dataSource.asset}',
        DataSourceType.network || DataSourceType.file || DataSourceType.contentUri => dataSource.uri!,
      };

      await player.open(
        Media(resource, httpHeaders: dataSource.httpHeaders),
        play: false,
      );
      AppLog.log('play $resource');
      return textureId;
    } catch (_) {
      if (textureId != null && identical(_players[textureId], player)) {
        await dispose(textureId);
      } else {
        try {
          await player.dispose().timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> _applyCustomParameters(NativePlayer native, AppSettings settings) async {
    for (final parameter in settings.customParameters) {
      final separator = parameter.indexOf('=');
      if (separator <= 0) continue;
      try {
        await native.setProperty(
          parameter.substring(0, separator).trim(),
          parameter.substring(separator + 1).trim(),
        );
      } catch (_) {}
    }
  }

  Future<void> _applyShaders(NativePlayer native, AppSettings settings) async {
    final embed = settings.videoRenderer == VideoRenderer.mediacodecEmbed;
    if (embed || settings.superResolutionMode == SuperResolutionMode.off) return;
    final shaders = settings.superResolutionMode == SuperResolutionMode.efficiency
        ? mpvAnime4KShadersLite
        : mpvAnime4KShaders;
    final directory = ShaderService.directory?.path;
    if (directory == null) return;
    try {
      await native.waitForVideoControllerInitializationIfAttached;
      await native.command([
        'change-list',
        'glsl-shaders',
        'set',
        buildShadersAbsolutePath(directory, shaders),
      ]);
    } catch (_) {}
  }

  VideoControllerConfiguration _videoConfiguration(AppSettings settings) {
    final embed = settings.videoRenderer == VideoRenderer.mediacodecEmbed;
    final acceleration = embed || settings.hardwareAcceleration;
    final hwdec = embed && Platform.isAndroid
        ? 'mediacodec'
        : acceleration && (Platform.isIOS || Platform.isMacOS)
            ? 'videotoolbox'
            : acceleration
                ? 'auto'
                : 'no';
    final vo = embed && !Platform.isAndroid ? null : settings.videoRenderer.mpvValue;
    return VideoControllerConfiguration(
      vo: vo,
      enableHardwareAcceleration: acceleration,
      hwdec: hwdec,
    );
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    if (_streamControllers[textureId] == null) {
      throw StateError('VideoPlayer for textureId $textureId is not found, Check if its disposed.');
    }
    return _streamControllers[textureId]!.stream;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {
    final playlistMode = looping ? PlaylistMode.single : PlaylistMode.none;
    return _players[textureId]?.setPlaylistMode(playlistMode);
  }

  @override
  Future<void> play(int textureId) async {
    return _players[textureId]?.play();
  }

  @override
  Future<void> pause(int textureId) async {
    return _players[textureId]?.pause();
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    return _players[textureId]?.setVolume(volume * 100);
  }

  @override
  Future<void> seekTo(int textureId, Duration position) async {
    return _players[textureId]?.seek(position);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    final player = _players[textureId];
    if (player == null) return;
    try {
      await player.setRate(speed);
    } catch (_) {}
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    return _players[textureId]?.platform?.state.position ?? Duration.zero;
  }

  @override
  Widget buildView(int textureId) {
    if (_videoControllers[textureId] == null) {
      throw StateError('VideoPlayer for textureId $textureId is not found, Check if its disposed.');
    }
    return Video(
      key: ValueKey(_videoControllers[textureId]!),
      controller: _videoControllers[textureId]!,
      wakelock: false,
      controls: NoVideoControls,
      fill: const Color(0x00000000),
      pauseUponEnteringBackgroundMode: false,
      resumeUponEnteringForegroundMode: false,
    );
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) => Future.value();

  @override
  Future<void> setWebOptions(int textureId, VideoPlayerWebOptions options) => Future.value();

  void _initialize(int textureId) {
    if (_streamSubscriptions[textureId]?.isNotEmpty ?? false) return;

    final player = _players[textureId];
    final completer = _completers[textureId];
    final streamController = _streamControllers[textureId];
    final streamSubscriptions = _streamSubscriptions[textureId];

    if (player == null ||
        completer == null ||
        streamController == null ||
        streamSubscriptions == null) {
      return;
    }

    int? width;
    int? height;
    Duration? duration;
    Size? lastSize;
    Duration? lastDuration;

    bool isActive() => identical(_streamControllers[textureId], streamController) &&
        !streamController.isClosed;

    void emitInitialized({bool force = false}) {
      if (!isActive()) return;
      final size = _resolvedVideoSize(width, height);
      final value = duration ?? player.state.duration;
      if (!force) {
        if (lastSize == size && lastDuration == value) return;
        if (!completer.isCompleted && (duration == null || width == null || height == null)) return;
        if (completer.isCompleted && kDebugMode) return;
      }
      lastSize = size;
      lastDuration = value;
      streamController.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: size,
          duration: value,
        ),
      );
      if (!completer.isCompleted) {
        completer.complete();
        _initializationTimers.remove(textureId)?.cancel();
      }
    }

    _initializationTimers[textureId] = Timer(const Duration(seconds: 8), () => emitInitialized(force: true));

    streamSubscriptions.add(
      player.stream.duration.listen((event) {
        if (event > Duration.zero) {
          duration = event;
          emitInitialized();
        }
      }),
    );
    streamSubscriptions.add(
      player.stream.videoParams.listen((event) {
        final displayWidth = event.dw ?? 0;
        final displayHeight = event.dh ?? 0;
        final codedWidth = event.w ?? 0;
        final codedHeight = event.h ?? 0;
        if (codedWidth <= 0 || codedHeight <= 0) return;
        if (displayWidth > 0 && displayHeight > 0) {
          width = displayWidth;
          height = displayHeight;
        } else {
          width = codedWidth;
          height = codedHeight;
        }
        emitInitialized();
      }),
    );
    streamSubscriptions.add(
      player.stream.playing.listen((event) async {
        await completer.future;
        if (isActive()) {
          streamController.add(VideoEvent(eventType: VideoEventType.isPlayingStateUpdate, isPlaying: event));
        }
      }),
    );
    streamSubscriptions.add(
      player.stream.completed.listen((event) async {
        await completer.future;
        if (event && isActive()) {
          streamController.add(VideoEvent(eventType: VideoEventType.completed));
        }
      }),
    );
    streamSubscriptions.add(
      player.stream.buffering.listen((event) async {
        if (event) {
          await completer.future;
          if (!isActive()) return;
          _bufferingTimers.remove(textureId)?.cancel();
          _bufferingActive[textureId] = true;
          streamController.add(VideoEvent(eventType: VideoEventType.bufferingStart));
          final watchdog = Timer(const Duration(seconds: 8), () {
            _bufferingTimers.remove(textureId);
            if (!isActive()) return;
            if (!(_bufferingActive[textureId] ?? false)) return;
            _bufferingActive.remove(textureId);
            streamController.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
          });
          _bufferingTimers[textureId] = watchdog;
        } else {
          _bufferingTimers.remove(textureId)?.cancel();
          await completer.future;
          if (!isActive()) return;
          _bufferingActive.remove(textureId);
          streamController.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
        }
      }),
    );
    streamSubscriptions.add(
      player.stream.buffer.listen((event) async {
        await completer.future;
        if (isActive()) {
          streamController.add(
            VideoEvent(
              eventType: VideoEventType.bufferingUpdate,
              buffered: [DurationRange(Duration.zero, event)],
            ),
          );
        }
      }),
    );
    streamSubscriptions.add(
      player.stream.error.listen((event) async {
        AppLog.log('player error: $event');
        await completer.future;
        if (isActive()) {
          streamController.addError(PlatformException(code: '', message: event));
        }
      }),
    );
  }
}

Size _resolvedVideoSize(int? width, int? height) {
  final resolvedWidth = width ?? 0;
  final resolvedHeight = height ?? 0;
  if (resolvedWidth <= 0 || resolvedHeight <= 0) return const Size(1920, 1080);
  final ratio = resolvedWidth / resolvedHeight;
  if (ratio < 0.1 || ratio > 10) return const Size(1920, 1080);
  return Size(resolvedWidth.toDouble(), resolvedHeight.toDouble());
}
