import 'package:flutter/material.dart';

import '../data/local/json_store.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeColor { rose, blue, teal, amber, green, orange, indigo, pink, purple }

enum AppLanguage { system, simplifiedChinese, traditionalChinese }

enum PlayerEngine { exoPlayer }

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.baseUrl = 'https://hanime1.com',
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
    this.defaultPlaybackSpeed = 1,
    this.longPressPlaybackSpeed = 2,
    this.playerControlsTimeoutSeconds = 4,
    this.appLockEnabled = false,
    this.emergencyExitEnabled = false,
    this.hideFromRecents = false,
    this.commentsEnabled = true,
    this.blockedCommentKeywords = const [],
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
  final double defaultPlaybackSpeed;
  final double longPressPlaybackSpeed;
  final int playerControlsTimeoutSeconds;
  final bool appLockEnabled;
  final bool emergencyExitEnabled;
  final bool hideFromRecents;
  final bool commentsEnabled;
  final List<String> blockedCommentKeywords;

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
        'defaultPlaybackSpeed': defaultPlaybackSpeed,
        'longPressPlaybackSpeed': longPressPlaybackSpeed,
        'playerControlsTimeoutSeconds': playerControlsTimeoutSeconds,
        'appLockEnabled': appLockEnabled,
        'emergencyExitEnabled': emergencyExitEnabled,
        'hideFromRecents': hideFromRecents,
        'commentsEnabled': commentsEnabled,
        'blockedCommentKeywords': blockedCommentKeywords,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: _themeMode(json['themeMode'] as String?),
        baseUrl: json['baseUrl'] as String? ?? 'https://hanime1.com',
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
        defaultPlaybackSpeed: ((json['defaultPlaybackSpeed'] as num?)?.toDouble() ?? 1).clamp(.25, 3).toDouble(),
        longPressPlaybackSpeed: ((json['longPressPlaybackSpeed'] as num?)?.toDouble() ?? 2).clamp(1, 3).toDouble(),
        playerControlsTimeoutSeconds: (json['playerControlsTimeoutSeconds'] as int? ?? 4).clamp(1, 15) as int,
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        emergencyExitEnabled: json['emergencyExitEnabled'] as bool? ?? false,
        hideFromRecents: json['hideFromRecents'] as bool? ?? false,
        commentsEnabled: json['commentsEnabled'] as bool? ?? true,
        blockedCommentKeywords: (json['blockedCommentKeywords'] as List? ?? const []).whereType<String>().toList(),
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
    double? defaultPlaybackSpeed,
    double? longPressPlaybackSpeed,
    int? playerControlsTimeoutSeconds,
    bool? appLockEnabled,
    bool? emergencyExitEnabled,
    bool? hideFromRecents,
    bool? commentsEnabled,
    List<String>? blockedCommentKeywords,
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
        defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
        longPressPlaybackSpeed: longPressPlaybackSpeed ?? this.longPressPlaybackSpeed,
        playerControlsTimeoutSeconds: playerControlsTimeoutSeconds ?? this.playerControlsTimeoutSeconds,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        emergencyExitEnabled: emergencyExitEnabled ?? this.emergencyExitEnabled,
        hideFromRecents: hideFromRecents ?? this.hideFromRecents,
        commentsEnabled: commentsEnabled ?? this.commentsEnabled,
        blockedCommentKeywords: blockedCommentKeywords ?? this.blockedCommentKeywords,
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
