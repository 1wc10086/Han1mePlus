import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'configured_media_kit_video_player.dart';
import 'settings.dart';

class MediaPlayerInitializer {
  MediaPlayerInitializer._();

  static VideoPlayerPlatform? _native;
  static var _mediaKitInitialized = false;
  static var _mediaKitActive = false;

  static void bootstrap(AppSettings settings) {
    ConfiguredMediaKitVideoPlayer.settings = settings;
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isMacOS) {
      _useMediaKit();
      return;
    }
    _native ??= VideoPlayerPlatform.instance;
    _sync(settings);
  }

  static void apply(AppSettings settings) {
    ConfiguredMediaKitVideoPlayer.settings = settings;
    if (kIsWeb || Platform.isWindows || Platform.isMacOS) return;
    _sync(settings);
  }

  static void _sync(AppSettings settings) {
    if (settings.playerEngine == PlayerEngine.libMpv) {
      _useMediaKit();
    } else if (_mediaKitActive) {
      _mediaKitActive = false;
      VideoPlayerPlatform.instance = _native ?? VideoPlayerPlatform.instance;
    }
  }

  static void _useMediaKit() {
    if (!_mediaKitInitialized) {
      MediaKit.ensureInitialized();
      _mediaKitInitialized = true;
    }
    if (!_mediaKitActive) {
      _mediaKitActive = true;
      ConfiguredMediaKitVideoPlayer.registerWith();
    }
  }
}
