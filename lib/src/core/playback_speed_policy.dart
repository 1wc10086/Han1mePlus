import 'dart:io';

import 'package:flutter/foundation.dart';

import 'platform_service.dart';
import 'settings.dart';

class PlaybackSpeedPolicy {
  const PlaybackSpeedPolicy._();

  static bool get isHarmonyOs => !kIsWeb && Platform.isAndroid && _harmonyOs;

  static bool _harmonyOs = false;
  static Future<void>? _initialization;

  static Future<void> initialize() => _initialization ??= _detect();

  static Future<void> _detect() async {
    if (kIsWeb || !Platform.isAndroid) return;
    _harmonyOs = await PlatformService.isHarmonyOs();
  }

  static void setHarmonyOs(bool value) => _harmonyOs = value;

  static double longPressSpeed(AppSettings settings, {required bool isThreeDimensional}) {
    final requested = settings.longPressPlaybackSpeed;
    if (isHarmonyOs && isThreeDimensional) return requested.clamp(1, 1.5).toDouble();
    return requested;
  }

  static bool isThreeDimensional(String? genre, String title) {
    final normalized = '${genre ?? ''} $title'.toLowerCase();
    return normalized.contains('3dcg') ||
        normalized.contains('3d') ||
        normalized.contains('三维') ||
        normalized.contains('3d动画') ||
        normalized.contains('3d動畫');
  }
}
