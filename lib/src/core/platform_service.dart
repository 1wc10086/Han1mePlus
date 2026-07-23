import 'package:flutter/services.dart';

class PlatformService {
  static const _channel = MethodChannel('com.liar.han1meplus/platform');

  static Future<void> setScreenBrightness(double value) => _channel.invokeMethod<void>('setScreenBrightness', {'value': value});
  static Future<double> screenBrightness() async => await _channel.invokeMethod<double>('screenBrightness') ?? 1;
  static Future<double> volume() async => await _channel.invokeMethod<double>('volume') ?? 1;
  static Future<void> setVolume(double value) => _channel.invokeMethod<void>('setVolume', {'value': value});
  static Future<void> setHideFromRecents(bool value) => _channel.invokeMethod<void>('setHideFromRecents', {'value': value});
  static Future<void> setEmergencyExit(bool value) => _channel.invokeMethod<void>('setEmergencyExit', {'value': value});
  static Future<void> openAppLinksSettings() => _channel.invokeMethod<void>('openAppLinksSettings');
  static Future<bool> authenticate() async => await _channel.invokeMethod<bool>('authenticate') ?? false;
}
