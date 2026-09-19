import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'desktop_platform.dart';

class PlatformService {
  static const _channel = MethodChannel('com.liar.han1meplus/platform');
  static bool get isDesktop => isDesktopPlatformService;

  static Future<void> setScreenBrightness(double value) => isDesktop ? Future.value() : _channel.invokeMethod<void>('setScreenBrightness', {'value': value});
  static Future<double> screenBrightness() async => isDesktop ? 1 : await _channel.invokeMethod<double>('screenBrightness') ?? 1;
  static Future<double> volume() async => isDesktop ? 1 : await _channel.invokeMethod<double>('volume') ?? 1;
  static Future<void> setVolume(double value) => isDesktop ? Future.value() : _channel.invokeMethod<void>('setVolume', {'value': value});
  static Future<void> setHideFromRecents(bool value) => isDesktop ? Future.value() : _channel.invokeMethod<void>('setHideFromRecents', {'value': value});
  static Future<void> setEmergencyExit(bool value) => isDesktop ? Future.value() : _channel.invokeMethod<void>('setEmergencyExit', {'value': value});
  static Future<void> minimizeApp() => isDesktop ? Future.value() : _channel.invokeMethod<void>('minimizeApp');
  static Future<bool> enterPictureInPicture() async => !Platform.isAndroid ? false : await _channel.invokeMethod<bool>('enterPictureInPicture') ?? false;
  static Future<bool> isHarmonyOs() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isHarmonyOs') ?? false;
    } on PlatformException {
      return false;
    }
  }
  static Future<String?> androidUpdateAbi() async => !Platform.isAndroid ? null : await _channel.invokeMethod<String>('androidUpdateAbi');
  static Future<void> openAppLinksSettings() => isDesktop ? Future.value() : _channel.invokeMethod<void>('openAppLinksSettings');
  static Future<bool> authenticate() async => isDesktop ? false : await _channel.invokeMethod<bool>('authenticate') ?? false;
  static Future<String?> selectDirectory() async => Platform.isAndroid ? _channel.invokeMethod<String>('selectDirectory') : null;
  static Future<void> exportDirectory(String sourcePath, String destination) => Platform.isAndroid ? _channel.invokeMethod<void>('exportDirectory', {'sourcePath': sourcePath, 'destination': destination}) : Future.value();
  static Future<bool> saveDocument(String name, Uint8List bytes) async => Platform.isAndroid ? await _channel.invokeMethod<bool>('saveDocument', {'name': name, 'bytes': bytes}) ?? false : false;
}
