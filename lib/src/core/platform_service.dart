import 'dart:io';

import 'package:flutter/services.dart';

import 'desktop_platform.dart';

class PlatformService {
  static const _channel = MethodChannel('com.liar.han1meplus/platform');
  static bool get _isDesktop => isDesktopPlatformService;

  static Future<void> setScreenBrightness(double value) => _isDesktop ? Future.value() : _channel.invokeMethod<void>('setScreenBrightness', {'value': value});
  static Future<double> screenBrightness() async => _isDesktop ? 1 : await _channel.invokeMethod<double>('screenBrightness') ?? 1;
  static Future<double> volume() async => _isDesktop ? 1 : await _channel.invokeMethod<double>('volume') ?? 1;
  static Future<void> setVolume(double value) => _isDesktop ? Future.value() : _channel.invokeMethod<void>('setVolume', {'value': value});
  static Future<void> setHideFromRecents(bool value) => _isDesktop ? Future.value() : _channel.invokeMethod<void>('setHideFromRecents', {'value': value});
  static Future<void> setEmergencyExit(bool value) => _isDesktop ? Future.value() : _channel.invokeMethod<void>('setEmergencyExit', {'value': value});
  static Future<void> openAppLinksSettings() => _isDesktop ? Future.value() : _channel.invokeMethod<void>('openAppLinksSettings');
  static Future<bool> authenticate() async => _isDesktop ? false : await _channel.invokeMethod<bool>('authenticate') ?? false;
}
