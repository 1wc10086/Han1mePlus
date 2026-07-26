import 'package:flutter/material.dart';

import '../data/local/json_store.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeColor { rose, blue, teal, amber, green, orange, indigo, pink, purple, custom }

enum AppLanguage { system, simplifiedChinese, traditionalChinese }

enum PlayerEngine { exoPlayer }

const defaultDownloadPath = '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

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
    this.customThemeColor = '62539F',
    this.useMonetColors = false,
    this.amoledMode = false,
    this.downloadSpeedLimitMbps = 0,
    this.concurrentDownloads = 2,
    this.downloadPath = defaultDownloadPath,
    this.defaultPlaybackSpeed = 1,
    this.longPressPlaybackSpeed = 2,
    this.playerControlsTimeoutSeconds = 4,
    this.appLockEnabled = false,
    this.emergencyExitEnabled = false,
    this.hideFromRecents = false,
    this.commentsEnabled = true,
    this.blockedCommentKeywords = const [],
    this.comicMode = false,
    this.videoBaseUrl = 'https://hanime1.com',
    this.useBuiltInHosts = false,
    this.useDoh = false,
    this.dohPreset = 'alidns',
    this.dohCustomUrl = '',
    this.dohBootstrapIps = '',
    this.dohTimeoutSeconds = 10,
    this.useHorizontalSearchCards = true,
    this.searchCardsPerRow = 2,
    this.expandHomeVideoCards = false,
    this.useNavigationDrawer = false,
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
  final String customThemeColor;
  final bool useMonetColors;
  final bool amoledMode;
  final double downloadSpeedLimitMbps;
  final int concurrentDownloads;
  final String downloadPath;
  final double defaultPlaybackSpeed;
  final double longPressPlaybackSpeed;
  final int playerControlsTimeoutSeconds;
  final bool appLockEnabled;
  final bool emergencyExitEnabled;
  final bool hideFromRecents;
  final bool commentsEnabled;
  final List<String> blockedCommentKeywords;
  final bool comicMode;
  final String videoBaseUrl;
  final bool useBuiltInHosts;
  final bool useDoh;
  final String dohPreset;
  final String dohCustomUrl;
  final String dohBootstrapIps;
  final int dohTimeoutSeconds;
  final bool useHorizontalSearchCards;
  final int searchCardsPerRow;
  final bool expandHomeVideoCards;
  final bool useNavigationDrawer;

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
        'customThemeColor': customThemeColor,
        'useMonetColors': useMonetColors,
        'amoledMode': amoledMode,
        'downloadSpeedLimitMbps': downloadSpeedLimitMbps,
        'concurrentDownloads': concurrentDownloads,
        'downloadPath': downloadPath,
        'defaultPlaybackSpeed': defaultPlaybackSpeed,
        'longPressPlaybackSpeed': longPressPlaybackSpeed,
        'playerControlsTimeoutSeconds': playerControlsTimeoutSeconds,
        'appLockEnabled': appLockEnabled,
        'emergencyExitEnabled': emergencyExitEnabled,
        'hideFromRecents': hideFromRecents,
        'commentsEnabled': commentsEnabled,
        'blockedCommentKeywords': blockedCommentKeywords,
        'comicMode': comicMode,
        'videoBaseUrl': videoBaseUrl,
        'useBuiltInHosts': useBuiltInHosts,
        'useDoh': useDoh,
        'dohPreset': dohPreset,
        'dohCustomUrl': dohCustomUrl,
        'dohBootstrapIps': dohBootstrapIps,
        'dohTimeoutSeconds': dohTimeoutSeconds,
        'useHorizontalSearchCards': useHorizontalSearchCards,
        'searchCardsPerRow': searchCardsPerRow,
        'expandHomeVideoCards': expandHomeVideoCards,
        'useNavigationDrawer': useNavigationDrawer,
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
        customThemeColor: _hexColor(json['customThemeColor'] as String?),
        useMonetColors: json['useMonetColors'] as bool? ?? false,
        amoledMode: json['amoledMode'] as bool? ?? false,
        downloadSpeedLimitMbps: (json['downloadSpeedLimitMbps'] as num?)?.toDouble() ?? 0,
        concurrentDownloads: (json['concurrentDownloads'] as int? ?? 2).clamp(1, 5) as int,
        downloadPath: json['downloadPath'] as String? ?? defaultDownloadPath,
        defaultPlaybackSpeed: ((json['defaultPlaybackSpeed'] as num?)?.toDouble() ?? 1).clamp(.25, 3).toDouble(),
        longPressPlaybackSpeed: ((json['longPressPlaybackSpeed'] as num?)?.toDouble() ?? 2).clamp(1, 3).toDouble(),
        playerControlsTimeoutSeconds: (json['playerControlsTimeoutSeconds'] as int? ?? 4).clamp(1, 15) as int,
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        emergencyExitEnabled: json['emergencyExitEnabled'] as bool? ?? false,
        hideFromRecents: json['hideFromRecents'] as bool? ?? false,
        commentsEnabled: json['commentsEnabled'] as bool? ?? true,
        blockedCommentKeywords: (json['blockedCommentKeywords'] as List? ?? const []).whereType<String>().toList(),
        comicMode: json['comicMode'] as bool? ?? false,
        videoBaseUrl: json['videoBaseUrl'] as String? ?? (json['baseUrl'] == 'https://hanimeone.me' ? 'https://hanime1.com' : json['baseUrl'] as String? ?? 'https://hanime1.com'),
        useBuiltInHosts: json['useBuiltInHosts'] as bool? ?? false,
        useDoh: json['useDoh'] as bool? ?? false,
        dohPreset: _dohPreset(json['dohPreset'] as String?),
        dohCustomUrl: json['dohCustomUrl'] as String? ?? '',
        dohBootstrapIps: json['dohBootstrapIps'] as String? ?? '',
        dohTimeoutSeconds: (json['dohTimeoutSeconds'] as int? ?? 10).clamp(1, 60) as int,
        useHorizontalSearchCards: json['useHorizontalSearchCards'] as bool? ?? true,
        searchCardsPerRow: (json['searchCardsPerRow'] as int? ?? 2).clamp(1, 3) as int,
        expandHomeVideoCards: json['expandHomeVideoCards'] as bool? ?? false,
        useNavigationDrawer: json['useNavigationDrawer'] as bool? ?? false,
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

  static String _hexColor(String? value) {
    final normalized = value?.replaceFirst('#', '').toUpperCase() ?? '';
    return RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized) ? normalized : '62539F';
  }

  static String _dohPreset(String? value) => switch (value) {
        'alidns' || 'dnspod' || 'cloudflare' || 'custom' => value!,
        _ => 'alidns',
      };

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
    String? customThemeColor,
    bool? useMonetColors,
    bool? amoledMode,
    double? downloadSpeedLimitMbps,
    int? concurrentDownloads,
    String? downloadPath,
    double? defaultPlaybackSpeed,
    double? longPressPlaybackSpeed,
    int? playerControlsTimeoutSeconds,
    bool? appLockEnabled,
    bool? emergencyExitEnabled,
    bool? hideFromRecents,
    bool? commentsEnabled,
    List<String>? blockedCommentKeywords,
    bool? comicMode,
    String? videoBaseUrl,
    bool? useBuiltInHosts,
    bool? useDoh,
    String? dohPreset,
    String? dohCustomUrl,
    String? dohBootstrapIps,
    int? dohTimeoutSeconds,
    bool? useHorizontalSearchCards,
    int? searchCardsPerRow,
    bool? expandHomeVideoCards,
    bool? useNavigationDrawer,
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
        customThemeColor: customThemeColor ?? this.customThemeColor,
        useMonetColors: useMonetColors ?? this.useMonetColors,
        amoledMode: amoledMode ?? this.amoledMode,
        downloadSpeedLimitMbps: downloadSpeedLimitMbps ?? this.downloadSpeedLimitMbps,
        concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
        downloadPath: downloadPath ?? this.downloadPath,
        defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
        longPressPlaybackSpeed: longPressPlaybackSpeed ?? this.longPressPlaybackSpeed,
        playerControlsTimeoutSeconds: playerControlsTimeoutSeconds ?? this.playerControlsTimeoutSeconds,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        emergencyExitEnabled: emergencyExitEnabled ?? this.emergencyExitEnabled,
        hideFromRecents: hideFromRecents ?? this.hideFromRecents,
        commentsEnabled: commentsEnabled ?? this.commentsEnabled,
        blockedCommentKeywords: blockedCommentKeywords ?? this.blockedCommentKeywords,
        comicMode: comicMode ?? this.comicMode,
        videoBaseUrl: videoBaseUrl ?? this.videoBaseUrl,
        useBuiltInHosts: useBuiltInHosts ?? this.useBuiltInHosts,
        useDoh: useDoh ?? this.useDoh,
        dohPreset: dohPreset ?? this.dohPreset,
        dohCustomUrl: dohCustomUrl ?? this.dohCustomUrl,
        dohBootstrapIps: dohBootstrapIps ?? this.dohBootstrapIps,
        dohTimeoutSeconds: dohTimeoutSeconds ?? this.dohTimeoutSeconds,
        useHorizontalSearchCards: useHorizontalSearchCards ?? this.useHorizontalSearchCards,
        searchCardsPerRow: searchCardsPerRow ?? this.searchCardsPerRow,
        expandHomeVideoCards: expandHomeVideoCards ?? this.expandHomeVideoCards,
        useNavigationDrawer: useNavigationDrawer ?? this.useNavigationDrawer,
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
