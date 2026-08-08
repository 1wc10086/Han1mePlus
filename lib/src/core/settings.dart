import 'dart:io';

import 'package:flutter/material.dart';

import '../data/local/json_store.dart';
import 'platform_paths.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeColor { rose, blue, teal, amber, green, orange, indigo, pink, purple, custom }

enum AppLanguage { system, simplifiedChinese, traditionalChinese, english }

enum PlayerEngine { exoPlayer, avPlayer, libMpv }

enum VideoRenderer { auto, gpu, gpuNext, mediacodecEmbed }

enum VideoView { platformView, surfaceView }

enum SuperResolutionMode { off, efficiency, quality }

enum VideoAspectRatio { auto, crop, stretch, ratio4x3 }

extension PlayerEngineX on PlayerEngine {
  static List<PlayerEngine> get available {
    if (Platform.isWindows || Platform.isMacOS) return const [PlayerEngine.libMpv];
    if (Platform.isIOS) return const [PlayerEngine.avPlayer, PlayerEngine.libMpv];
    if (Platform.isAndroid) return const [PlayerEngine.exoPlayer, PlayerEngine.libMpv];
    return const [PlayerEngine.libMpv];
  }

  static PlayerEngine get defaultEngine => PlayerEngine.libMpv;
}

extension VideoRendererX on VideoRenderer {
  String? get mpvValue => switch (this) {
        VideoRenderer.auto => null,
        VideoRenderer.gpu => 'gpu',
        VideoRenderer.gpuNext => 'gpu-next',
        VideoRenderer.mediacodecEmbed => 'mediacodec_embed',
      };
}

const defaultDownloadPath = '';

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.baseUrl = 'https://hanime1.com',
    this.preferredQuality = 720,
    this.resumePlayback = true,
    this.keyframesEnabled = true,
    this.language = AppLanguage.system,
    this.playerEngine = PlayerEngine.libMpv,
    this.hardwareAcceleration = true,
    this.videoRenderer = VideoRenderer.auto,
    this.videoView = VideoView.platformView,
    this.customParameters = const [],
    this.superResolutionMode = SuperResolutionMode.off,
    this.autoUpdate = true,
    this.useUpdateMirror = true,
    this.themeColor = AppThemeColor.purple,
    this.customThemeColor = '62539F',
    this.useMonetColors = false,
    this.amoledMode = false,
    this.textScale = 1,
    this.downloadSpeedLimitMbps = 0,
    this.concurrentDownloads = 2,
    this.downloadPath = defaultDownloadPath,
    this.defaultPlaybackSpeed = 1,
    this.longPressPlaybackSpeed = 2,
    this.playerControlsTimeoutSeconds = 4,
    this.seekSensitivity = .35,
    this.appLockEnabled = false,
    this.emergencyExitEnabled = false,
    this.hideFromRecents = false,
    this.commentsEnabled = true,
    this.blockedCommentKeywords = const [],
    this.comicMode = false,
    this.videoBaseUrl = 'https://hanime1.com',
    this.useBuiltInHosts = false,
    this.useCustomMirrorSite = false,
    this.customMirrorSite = '',
    this.appendCustomMirrorPath = true,
    this.useDoh = false,
    this.dohPreset = 'alidns',
    this.dohCustomUrl = '',
    this.dohBootstrapIps = '',
    this.dohTimeoutSeconds = 10,
    this.useEch = false,
    this.useHorizontalSearchCards = true,
    this.searchCardsPerRow = 2,
    this.useCompactSearchCards = true,
    this.expandHomeVideoCards = false,
    this.useNavigationDrawer = false,
    this.useLiquidGlassBottomBar = true,
    this.useHomeCategoryTabs = false,
    this.blockedVideoTitleKeywords = const [],
    this.blockedAuthors = const [],
    this.minimumVideoDurationSeconds = 0,
    this.minimumVideoViews = 0,
    this.exemptSubscribedAuthors = true,
    this.applyRecommendationFiltersToRelated = true,
    this.applyRecommendationFiltersToSearch = true,
    this.blockedCommentUsers = const [],
    this.incognitoPlayback = false,
    this.autoPlayNext = false,
    this.autoPictureInPicture = false,
    this.videoAspectRatio = VideoAspectRatio.auto,
    this.skipSeconds = 80,
    this.webDavEnabled = false,
    this.webDavHistorySync = false,
    this.webDavFavoriteSync = false,
    this.webDavUrl = '',
    this.webDavUsername = '',
    this.webDavPassword = '',
  });

  final AppThemeMode themeMode;
  final String baseUrl;
  final int preferredQuality;
  final bool resumePlayback;
  final bool keyframesEnabled;
  final AppLanguage language;
  final PlayerEngine playerEngine;
  final bool hardwareAcceleration;
  final VideoRenderer videoRenderer;
  final VideoView videoView;
  final List<String> customParameters;
  final SuperResolutionMode superResolutionMode;
  final bool autoUpdate;
  final bool useUpdateMirror;
  final AppThemeColor themeColor;
  final String customThemeColor;
  final bool useMonetColors;
  final bool amoledMode;
  final double textScale;
  final double downloadSpeedLimitMbps;
  final int concurrentDownloads;
  final String downloadPath;
  final double defaultPlaybackSpeed;
  final double longPressPlaybackSpeed;
  final int playerControlsTimeoutSeconds;
  final double seekSensitivity;
  final bool appLockEnabled;
  final bool emergencyExitEnabled;
  final bool hideFromRecents;
  final bool commentsEnabled;
  final List<String> blockedCommentKeywords;
  final bool comicMode;
  final String videoBaseUrl;
  final bool useBuiltInHosts;
  final bool useCustomMirrorSite;
  final String customMirrorSite;
  final bool appendCustomMirrorPath;
  final bool useDoh;
  final String dohPreset;
  final String dohCustomUrl;
  final String dohBootstrapIps;
  final int dohTimeoutSeconds;
  final bool useEch;
  final bool useHorizontalSearchCards;
  final int searchCardsPerRow;
  final bool useCompactSearchCards;
  final bool expandHomeVideoCards;
  final bool useNavigationDrawer;
  final bool useLiquidGlassBottomBar;
  final bool useHomeCategoryTabs;
  final List<String> blockedVideoTitleKeywords;
  final List<String> blockedAuthors;
  final int minimumVideoDurationSeconds;
  final int minimumVideoViews;
  final bool exemptSubscribedAuthors;
  final bool applyRecommendationFiltersToRelated;
  final bool applyRecommendationFiltersToSearch;
  final List<String> blockedCommentUsers;
  final bool incognitoPlayback;
  final bool autoPlayNext;
  final bool autoPictureInPicture;
  final VideoAspectRatio videoAspectRatio;
  final int skipSeconds;
  final bool webDavEnabled;
  final bool webDavHistorySync;
  final bool webDavFavoriteSync;
  final String webDavUrl;
  final String webDavUsername;
  final String webDavPassword;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  bool get mirrorActive => useCustomMirrorSite && customMirrorSite.isNotEmpty;

  String get homeBaseUrl => mirrorActive ? customMirrorSite : baseUrl;

  String get resolvedBaseUrl {
    if (!mirrorActive) return baseUrl;
    return appendCustomMirrorPath ? customMirrorSite : _rootUrl(customMirrorSite);
  }

  static String _rootUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.authority}';
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'baseUrl': baseUrl,
        'preferredQuality': preferredQuality,
        'resumePlayback': resumePlayback,
        'keyframesEnabled': keyframesEnabled,
        'language': language.name,
        'playerEngine': playerEngine.name,
        'hardwareAcceleration': hardwareAcceleration,
        'videoRenderer': videoRenderer.name,
        'videoView': videoView.name,
        'customParameters': customParameters,
        'superResolutionMode': superResolutionMode.name,
        'autoUpdate': autoUpdate,
        'useUpdateMirror': useUpdateMirror,
        'themeColor': themeColor.name,
        'customThemeColor': customThemeColor,
        'useMonetColors': useMonetColors,
        'amoledMode': amoledMode,
        'textScale': textScale,
        'downloadSpeedLimitMbps': downloadSpeedLimitMbps,
        'concurrentDownloads': concurrentDownloads,
        'downloadPath': downloadPath,
        'defaultPlaybackSpeed': defaultPlaybackSpeed,
        'longPressPlaybackSpeed': longPressPlaybackSpeed,
        'playerControlsTimeoutSeconds': playerControlsTimeoutSeconds,
        'seekSensitivity': seekSensitivity,
        'appLockEnabled': appLockEnabled,
        'emergencyExitEnabled': emergencyExitEnabled,
        'hideFromRecents': hideFromRecents,
        'commentsEnabled': commentsEnabled,
        'blockedCommentKeywords': blockedCommentKeywords,
        'comicMode': comicMode,
        'videoBaseUrl': videoBaseUrl,
        'useBuiltInHosts': useBuiltInHosts,
        'useCustomMirrorSite': useCustomMirrorSite,
        'customMirrorSite': customMirrorSite,
        'appendCustomMirrorPath': appendCustomMirrorPath,
        'useDoh': useDoh,
        'dohPreset': dohPreset,
        'dohCustomUrl': dohCustomUrl,
        'dohBootstrapIps': dohBootstrapIps,
        'dohTimeoutSeconds': dohTimeoutSeconds,
        'useEch': useEch,
        'useHorizontalSearchCards': useHorizontalSearchCards,
        'searchCardsPerRow': searchCardsPerRow,
        'useCompactSearchCards': useCompactSearchCards,
        'expandHomeVideoCards': expandHomeVideoCards,
        'useNavigationDrawer': useNavigationDrawer,
        'useLiquidGlassBottomBar': useLiquidGlassBottomBar,
        'useHomeCategoryTabs': useHomeCategoryTabs,
        'blockedVideoTitleKeywords': blockedVideoTitleKeywords,
        'blockedAuthors': blockedAuthors,
        'minimumVideoDurationSeconds': minimumVideoDurationSeconds,
        'minimumVideoViews': minimumVideoViews,
        'exemptSubscribedAuthors': exemptSubscribedAuthors,
        'applyRecommendationFiltersToRelated': applyRecommendationFiltersToRelated,
        'applyRecommendationFiltersToSearch': applyRecommendationFiltersToSearch,
        'blockedCommentUsers': blockedCommentUsers,
        'incognitoPlayback': incognitoPlayback,
        'autoPlayNext': autoPlayNext,
        'autoPictureInPicture': autoPictureInPicture,
        'videoAspectRatio': videoAspectRatio.name,
        'skipSeconds': skipSeconds,
        'webDavEnabled': webDavEnabled,
        'webDavHistorySync': webDavHistorySync,
        'webDavFavoriteSync': webDavFavoriteSync,
        'webDavUrl': webDavUrl,
        'webDavUsername': webDavUsername,
        'webDavPassword': webDavPassword,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: _themeMode(json['themeMode'] as String?),
        baseUrl: json['baseUrl'] as String? ?? 'https://hanime1.com',
        preferredQuality: json['preferredQuality'] as int? ?? 720,
        resumePlayback: json['resumePlayback'] as bool? ?? true,
        keyframesEnabled: json['keyframesEnabled'] as bool? ?? true,
        language: _language(json['language'] as String?),
        playerEngine: _playerEngine(json['playerEngine'] as String?),
        hardwareAcceleration: json['hardwareAcceleration'] as bool? ?? true,
        videoRenderer: _enumByName(VideoRenderer.values, json['videoRenderer'] as String?) ?? VideoRenderer.auto,
        videoView: _enumByName(VideoView.values, json['videoView'] as String?) ?? VideoView.platformView,
        customParameters: (json['customParameters'] as List? ?? const []).whereType<String>().toList(),
        superResolutionMode: _enumByName(SuperResolutionMode.values, json['superResolutionMode'] as String?) ?? SuperResolutionMode.off,
        autoUpdate: json['autoUpdate'] as bool? ?? true,
        useUpdateMirror: json['useUpdateMirror'] as bool? ?? true,
        themeColor: _themeColor(json['themeColor'] as String?),
        customThemeColor: _hexColor(json['customThemeColor'] as String?),
        useMonetColors: json['useMonetColors'] as bool? ?? false,
        amoledMode: json['amoledMode'] as bool? ?? false,
        textScale: ((json['textScale'] as num?)?.toDouble() ?? 1).clamp(.8, 1.4).toDouble(),
        downloadSpeedLimitMbps: (json['downloadSpeedLimitMbps'] as num?)?.toDouble() ?? 0,
        concurrentDownloads: (json['concurrentDownloads'] as int? ?? 2).clamp(1, 5) as int,
        downloadPath: json['downloadPath'] as String? ?? defaultDownloadPath,
        defaultPlaybackSpeed: ((json['defaultPlaybackSpeed'] as num?)?.toDouble() ?? 1).clamp(.25, 3).toDouble(),
        longPressPlaybackSpeed: ((json['longPressPlaybackSpeed'] as num?)?.toDouble() ?? 2).clamp(1, 3).toDouble(),
        playerControlsTimeoutSeconds: (json['playerControlsTimeoutSeconds'] as int? ?? 4).clamp(1, 15) as int,
        seekSensitivity: ((json['seekSensitivity'] as num?)?.toDouble() ?? .35).clamp(.1, 1).toDouble(),
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        emergencyExitEnabled: json['emergencyExitEnabled'] as bool? ?? false,
        hideFromRecents: json['hideFromRecents'] as bool? ?? false,
        commentsEnabled: json['commentsEnabled'] as bool? ?? true,
        blockedCommentKeywords: (json['blockedCommentKeywords'] as List? ?? const []).whereType<String>().toList(),
        comicMode: json['comicMode'] as bool? ?? false,
        videoBaseUrl: json['videoBaseUrl'] as String? ?? (json['baseUrl'] == 'https://hanimeone.me' ? 'https://hanime1.com' : json['baseUrl'] as String? ?? 'https://hanime1.com'),
        useBuiltInHosts: json['useBuiltInHosts'] as bool? ?? Platform.isWindows || Platform.isMacOS,
        useCustomMirrorSite: json['useCustomMirrorSite'] as bool? ?? false,
        customMirrorSite: _mirrorUrl(json['customMirrorSite'] as String?),
        appendCustomMirrorPath: json['appendCustomMirrorPath'] as bool? ?? true,
        useDoh: json['useDoh'] as bool? ?? false,
        dohPreset: _dohPreset(json['dohPreset'] as String?),
        dohCustomUrl: json['dohCustomUrl'] as String? ?? '',
        dohBootstrapIps: json['dohBootstrapIps'] as String? ?? '',
        dohTimeoutSeconds: (json['dohTimeoutSeconds'] as int? ?? 10).clamp(1, 60) as int,
        useEch: json['useEch'] as bool? ?? false,
        useHorizontalSearchCards: json['useHorizontalSearchCards'] as bool? ?? true,
        searchCardsPerRow: (json['searchCardsPerRow'] as int? ?? 2).clamp(1, 3) as int,
        useCompactSearchCards: json['useCompactSearchCards'] as bool? ?? true,
        expandHomeVideoCards: json['expandHomeVideoCards'] as bool? ?? false,
        useNavigationDrawer: json['useNavigationDrawer'] as bool? ?? false,
        useLiquidGlassBottomBar: json['useLiquidGlassBottomBar'] as bool? ?? true,
        useHomeCategoryTabs: json['useHomeCategoryTabs'] as bool? ?? false,
        blockedVideoTitleKeywords: (json['blockedVideoTitleKeywords'] as List? ?? const []).whereType<String>().toList(),
        blockedAuthors: (json['blockedAuthors'] as List? ?? const []).whereType<String>().toList(),
        minimumVideoDurationSeconds: (json['minimumVideoDurationSeconds'] as int? ?? 0).clamp(0, 86400) as int,
        minimumVideoViews: (json['minimumVideoViews'] as int? ?? 0).clamp(0, 1000000000) as int,
        exemptSubscribedAuthors: json['exemptSubscribedAuthors'] as bool? ?? true,
        applyRecommendationFiltersToRelated: json['applyRecommendationFiltersToRelated'] as bool? ?? true,
        applyRecommendationFiltersToSearch: json['applyRecommendationFiltersToSearch'] as bool? ?? true,
        blockedCommentUsers: (json['blockedCommentUsers'] as List? ?? const []).whereType<String>().toList(),
        incognitoPlayback: json['incognitoPlayback'] as bool? ?? false,
        autoPlayNext: json['autoPlayNext'] as bool? ?? false,
        autoPictureInPicture: json['autoPictureInPicture'] as bool? ?? false,
        videoAspectRatio: _enumByName(VideoAspectRatio.values, json['videoAspectRatio'] as String?) ?? VideoAspectRatio.auto,
        skipSeconds: (json['skipSeconds'] as int? ?? 80).clamp(1, 3600) as int,
        webDavEnabled: json['webDavEnabled'] as bool? ?? false,
        webDavHistorySync: json['webDavHistorySync'] as bool? ?? false,
        webDavFavoriteSync: json['webDavFavoriteSync'] as bool? ?? false,
        webDavUrl: json['webDavUrl'] as String? ?? '',
        webDavUsername: json['webDavUsername'] as String? ?? '',
        webDavPassword: json['webDavPassword'] as String? ?? '',
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

  static PlayerEngine _playerEngine(String? name) {
    final parsed = _enumByName(PlayerEngine.values, name);
    if (parsed != null) return parsed;
    return PlayerEngineX.defaultEngine;
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static String _hexColor(String? value) {
    final normalized = value?.replaceFirst('#', '').toUpperCase() ?? '';
    return RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized) ? normalized : '62539F';
  }

  static String _dohPreset(String? value) => switch (value) {
        'alidns' || 'dnspod' || 'cloudflare' || 'custom' => value!,
        _ => 'alidns',
      };

  static String _mirrorUrl(String? value) {
    final normalized = value?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.hasQuery || uri.hasFragment) return '';
    return normalized;
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? baseUrl,
    int? preferredQuality,
    bool? resumePlayback,
    bool? keyframesEnabled,
    AppLanguage? language,
    PlayerEngine? playerEngine,
    bool? hardwareAcceleration,
    VideoRenderer? videoRenderer,
    VideoView? videoView,
    List<String>? customParameters,
    SuperResolutionMode? superResolutionMode,
    bool? autoUpdate,
    bool? useUpdateMirror,
    AppThemeColor? themeColor,
    String? customThemeColor,
    bool? useMonetColors,
    bool? amoledMode,
    double? textScale,
    double? downloadSpeedLimitMbps,
    int? concurrentDownloads,
    String? downloadPath,
    double? defaultPlaybackSpeed,
    double? longPressPlaybackSpeed,
    int? playerControlsTimeoutSeconds,
    double? seekSensitivity,
    bool? appLockEnabled,
    bool? emergencyExitEnabled,
    bool? hideFromRecents,
    bool? commentsEnabled,
    List<String>? blockedCommentKeywords,
    bool? comicMode,
    String? videoBaseUrl,
    bool? useBuiltInHosts,
    bool? useCustomMirrorSite,
    String? customMirrorSite,
    bool? appendCustomMirrorPath,
    bool? useDoh,
    String? dohPreset,
    String? dohCustomUrl,
    String? dohBootstrapIps,
    int? dohTimeoutSeconds,
    bool? useEch,
    bool? useHorizontalSearchCards,
    int? searchCardsPerRow,
    bool? useCompactSearchCards,
    bool? expandHomeVideoCards,
    bool? useNavigationDrawer,
    bool? useLiquidGlassBottomBar,
    bool? useHomeCategoryTabs,
    List<String>? blockedVideoTitleKeywords,
    List<String>? blockedAuthors,
    int? minimumVideoDurationSeconds,
    int? minimumVideoViews,
    bool? exemptSubscribedAuthors,
    bool? applyRecommendationFiltersToRelated,
    bool? applyRecommendationFiltersToSearch,
    List<String>? blockedCommentUsers,
    bool? incognitoPlayback,
    bool? autoPlayNext,
    bool? autoPictureInPicture,
    VideoAspectRatio? videoAspectRatio,
    int? skipSeconds,
    bool? webDavEnabled,
    bool? webDavHistorySync,
    bool? webDavFavoriteSync,
    String? webDavUrl,
    String? webDavUsername,
    String? webDavPassword,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        baseUrl: baseUrl ?? this.baseUrl,
        preferredQuality: preferredQuality ?? this.preferredQuality,
        resumePlayback: resumePlayback ?? this.resumePlayback,
        keyframesEnabled: keyframesEnabled ?? this.keyframesEnabled,
        language: language ?? this.language,
        playerEngine: playerEngine ?? this.playerEngine,
        hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
        videoRenderer: videoRenderer ?? this.videoRenderer,
        videoView: videoView ?? this.videoView,
        customParameters: customParameters ?? this.customParameters,
        superResolutionMode: superResolutionMode ?? this.superResolutionMode,
        autoUpdate: autoUpdate ?? this.autoUpdate,
        useUpdateMirror: useUpdateMirror ?? this.useUpdateMirror,
        themeColor: themeColor ?? this.themeColor,
        customThemeColor: customThemeColor ?? this.customThemeColor,
        useMonetColors: useMonetColors ?? this.useMonetColors,
        amoledMode: amoledMode ?? this.amoledMode,
        textScale: textScale ?? this.textScale,
        downloadSpeedLimitMbps: downloadSpeedLimitMbps ?? this.downloadSpeedLimitMbps,
        concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
        downloadPath: downloadPath ?? this.downloadPath,
        defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
        longPressPlaybackSpeed: longPressPlaybackSpeed ?? this.longPressPlaybackSpeed,
        playerControlsTimeoutSeconds: playerControlsTimeoutSeconds ?? this.playerControlsTimeoutSeconds,
        seekSensitivity: seekSensitivity ?? this.seekSensitivity,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        emergencyExitEnabled: emergencyExitEnabled ?? this.emergencyExitEnabled,
        hideFromRecents: hideFromRecents ?? this.hideFromRecents,
        commentsEnabled: commentsEnabled ?? this.commentsEnabled,
        blockedCommentKeywords: blockedCommentKeywords ?? this.blockedCommentKeywords,
        comicMode: comicMode ?? this.comicMode,
        videoBaseUrl: videoBaseUrl ?? this.videoBaseUrl,
        useBuiltInHosts: useBuiltInHosts ?? this.useBuiltInHosts,
        useCustomMirrorSite: useCustomMirrorSite ?? this.useCustomMirrorSite,
        customMirrorSite: customMirrorSite ?? this.customMirrorSite,
        appendCustomMirrorPath: appendCustomMirrorPath ?? this.appendCustomMirrorPath,
        useDoh: useDoh ?? this.useDoh,
        dohPreset: dohPreset ?? this.dohPreset,
        dohCustomUrl: dohCustomUrl ?? this.dohCustomUrl,
        dohBootstrapIps: dohBootstrapIps ?? this.dohBootstrapIps,
        dohTimeoutSeconds: dohTimeoutSeconds ?? this.dohTimeoutSeconds,
        useEch: useEch ?? this.useEch,
        useHorizontalSearchCards: useHorizontalSearchCards ?? this.useHorizontalSearchCards,
        searchCardsPerRow: searchCardsPerRow ?? this.searchCardsPerRow,
        useCompactSearchCards: useCompactSearchCards ?? this.useCompactSearchCards,
        expandHomeVideoCards: expandHomeVideoCards ?? this.expandHomeVideoCards,
        useNavigationDrawer: useNavigationDrawer ?? this.useNavigationDrawer,
        useLiquidGlassBottomBar: useLiquidGlassBottomBar ?? this.useLiquidGlassBottomBar,
        useHomeCategoryTabs: useHomeCategoryTabs ?? this.useHomeCategoryTabs,
        blockedVideoTitleKeywords: blockedVideoTitleKeywords ?? this.blockedVideoTitleKeywords,
        blockedAuthors: blockedAuthors ?? this.blockedAuthors,
        minimumVideoDurationSeconds: minimumVideoDurationSeconds ?? this.minimumVideoDurationSeconds,
        minimumVideoViews: minimumVideoViews ?? this.minimumVideoViews,
        exemptSubscribedAuthors: exemptSubscribedAuthors ?? this.exemptSubscribedAuthors,
        applyRecommendationFiltersToRelated: applyRecommendationFiltersToRelated ?? this.applyRecommendationFiltersToRelated,
        applyRecommendationFiltersToSearch: applyRecommendationFiltersToSearch ?? this.applyRecommendationFiltersToSearch,
        blockedCommentUsers: blockedCommentUsers ?? this.blockedCommentUsers,
        incognitoPlayback: incognitoPlayback ?? this.incognitoPlayback,
        autoPlayNext: autoPlayNext ?? this.autoPlayNext,
        autoPictureInPicture: autoPictureInPicture ?? this.autoPictureInPicture,
        videoAspectRatio: videoAspectRatio ?? this.videoAspectRatio,
        skipSeconds: skipSeconds ?? this.skipSeconds,
        webDavEnabled: webDavEnabled ?? this.webDavEnabled,
        webDavHistorySync: webDavHistorySync ?? this.webDavHistorySync,
        webDavFavoriteSync: webDavFavoriteSync ?? this.webDavFavoriteSync,
        webDavUrl: webDavUrl ?? this.webDavUrl,
        webDavUsername: webDavUsername ?? this.webDavUsername,
        webDavPassword: webDavPassword ?? this.webDavPassword,
      );
}


class SettingsStore {
  SettingsStore(this._store);
  final JsonStore _store;
  static const _fileName = 'setting.json';

  Future<AppSettings> load() async {
    final settings = AppSettings.fromJson(await _store.read(_fileName));
    final downloadPath = await normalizeDownloadPath(settings.downloadPath);
    if (downloadPath == settings.downloadPath) return settings;
    final normalized = settings.copyWith(downloadPath: downloadPath);
    await save(normalized);
    return normalized;
  }
  Future<void> save(AppSettings value) async => _store.write(_fileName, value.toJson());
}
