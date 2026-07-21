import 'package:flutter/material.dart';

import '../data/local/json_store.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeColor { rose, blue, teal, amber, green, orange, indigo, pink, purple }

enum AppLanguage { system, simplifiedChinese, traditionalChinese }

enum PlayerEngine { exoPlayer }

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.baseUrl = 'https://hanimeone.me',
    this.preferredQuality = 720,
    this.resumePlayback = true,
    this.keyframesEnabled = true,
    this.language = AppLanguage.system,
    this.playerEngine = PlayerEngine.exoPlayer,
    this.autoUpdate = true,
    this.themeColor = AppThemeColor.purple,
    this.useMonetColors = false,
    this.amoledMode = false,
    this.downloadSpeedLimitMbps = 0,
    this.concurrentDownloads = 2,
  });

  final AppThemeMode themeMode;
  final String baseUrl;
  final int preferredQuality;
  final bool resumePlayback;
  final bool keyframesEnabled;
  final AppLanguage language;
  final PlayerEngine playerEngine;
  final bool autoUpdate;
  final AppThemeColor themeColor;
  final bool useMonetColors;
  final bool amoledMode;
  final double downloadSpeedLimitMbps;
  final int concurrentDownloads;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'baseUrl': baseUrl,
        'preferredQuality': preferredQuality,
        'resumePlayback': resumePlayback,
        'keyframesEnabled': keyframesEnabled,
        'language': language.name,
        'playerEngine': playerEngine.name,
        'autoUpdate': autoUpdate,
        'themeColor': themeColor.name,
        'useMonetColors': useMonetColors,
        'amoledMode': amoledMode,
        'downloadSpeedLimitMbps': downloadSpeedLimitMbps,
        'concurrentDownloads': concurrentDownloads,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: _themeMode(json['themeMode'] as String?),
        baseUrl: json['baseUrl'] as String? ?? 'https://hanimeone.me',
        preferredQuality: json['preferredQuality'] as int? ?? 720,
        resumePlayback: json['resumePlayback'] as bool? ?? true,
        keyframesEnabled: json['keyframesEnabled'] as bool? ?? true,
        language: _language(json['language'] as String?),
        playerEngine: PlayerEngine.exoPlayer,
        autoUpdate: json['autoUpdate'] as bool? ?? true,
        themeColor: _themeColor(json['themeColor'] as String?),
        useMonetColors: json['useMonetColors'] as bool? ?? false,
        amoledMode: json['amoledMode'] as bool? ?? false,
        downloadSpeedLimitMbps: (json['downloadSpeedLimitMbps'] as num?)?.toDouble() ?? 0,
        concurrentDownloads: (json['concurrentDownloads'] as int? ?? 2).clamp(1, 5) as int,
      );

  static AppThemeMode _themeMode(String? name) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return AppThemeMode.system;
  }

  static AppThemeColor _themeColor(String? name) => AppThemeColor.values
      .where((value) => value.name == name)
      .firstOrNull ?? AppThemeColor.purple;

  static AppLanguage _language(String? name) => AppLanguage.values
      .where((value) => value.name == name)
      .firstOrNull ?? AppLanguage.system;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? baseUrl,
    int? preferredQuality,
    bool? resumePlayback,
    bool? keyframesEnabled,
    AppLanguage? language,
    PlayerEngine? playerEngine,
    bool? autoUpdate,
    AppThemeColor? themeColor,
    bool? useMonetColors,
    bool? amoledMode,
    double? downloadSpeedLimitMbps,
    int? concurrentDownloads,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        baseUrl: baseUrl ?? this.baseUrl,
        preferredQuality: preferredQuality ?? this.preferredQuality,
        resumePlayback: resumePlayback ?? this.resumePlayback,
        keyframesEnabled: keyframesEnabled ?? this.keyframesEnabled,
        language: language ?? this.language,
        playerEngine: playerEngine ?? this.playerEngine,
        autoUpdate: autoUpdate ?? this.autoUpdate,
        themeColor: themeColor ?? this.themeColor,
        useMonetColors: useMonetColors ?? this.useMonetColors,
        amoledMode: amoledMode ?? this.amoledMode,
        downloadSpeedLimitMbps: downloadSpeedLimitMbps ?? this.downloadSpeedLimitMbps,
        concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class SettingsStore {
  SettingsStore(this._store);
  final JsonStore _store;
  static const _fileName = 'setting.json';

  Future<AppSettings> load() async => AppSettings.fromJson(await _store.read(_fileName));
  Future<void> save(AppSettings value) async => _store.write(_fileName, value.toJson());
}
