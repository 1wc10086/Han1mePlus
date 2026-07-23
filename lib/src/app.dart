import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../l10n/app_localizations.dart';

import 'core/settings.dart';
import 'features/explore/explore_page.dart';
import 'features/library/library_page.dart';
import 'features/previews/previews_page.dart';
import 'features/search/search_page.dart';
import 'features/shared/comments_page.dart';
import 'features/settings/settings_controller.dart';
import 'features/settings/settings_page.dart';
import 'features/settings/about_page.dart';
import 'features/settings/cloudflare_page.dart';
import 'features/settings/license_page.dart';
import 'features/settings/keyframes_page.dart';
import 'features/settings/download_settings_page.dart';
import 'features/settings/playback_settings_page.dart';
import 'features/settings/privacy_settings_page.dart';
import 'features/settings/comment_settings_page.dart';
import 'features/settings/deep_link_settings_page.dart';
import 'features/settings/danmaku_settings_page.dart';
import 'features/video/video_page.dart';
import 'features/stats/stats_page.dart';
import 'features/cache/cache_page.dart';
import 'features/comics/comic_pages.dart';
import 'data/remote/update_checker.dart';
import 'data/local/update_installer.dart';
import 'domain/models/comic.dart';
import 'features/account/account_controller.dart';
import 'core/platform_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(navigatorKey: _rootNavigatorKey, routes: [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const ExplorePage())]),
      StatefulShellBranch(routes: [GoRoute(path: '/library', builder: (context, state) => const LibraryPage())]),
      StatefulShellBranch(routes: [GoRoute(path: '/cache', builder: (context, state) => const CachePage())]),
      StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsPage())]),
    ],
  ),
  GoRoute(path: '/search', builder: (context, state) => SearchPage(initialUrl: state.extra as String?)),
  GoRoute(path: '/settings/about', builder: (context, state) => const AboutPage()),
  GoRoute(path: '/settings/license', builder: (context, state) => const AppLicensePage()),
  GoRoute(path: '/settings/keyframes', builder: (context, state) => const KeyframesPage()),
  GoRoute(path: '/settings/downloads', builder: (context, state) => const DownloadSettingsPage()),
  GoRoute(path: '/settings/playback', builder: (context, state) => const PlaybackSettingsPage()),
  GoRoute(path: '/settings/privacy', builder: (context, state) => const PrivacySettingsPage()),
  GoRoute(path: '/settings/comments', builder: (context, state) => const CommentSettingsPage()),
  GoRoute(path: '/settings/deep-links', builder: (context, state) => const DeepLinkSettingsPage()),
  GoRoute(path: '/settings/danmaku', builder: (context, state) => const DanmakuSettingsPage()),
  GoRoute(path: '/cloudflare', builder: (context, state) => CloudflarePage(initialUrl: state.extra as String?)),
  GoRoute(path: '/previews/:month', builder: (context, state) => PreviewsPage(month: state.pathParameters['month']!)),
  GoRoute(path: '/comments/:type/:id', builder: (context, state) => CommentsPage(id: state.pathParameters['id']!, type: state.pathParameters['type']!, title: state.extra as String? ?? '')),
  GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
  GoRoute(path: '/video/:id', builder: (context, state) => VideoPage(id: state.pathParameters['id']!)),
  GoRoute(path: '/comics/browse', builder: (context, state) => ComicBrowsePage(target: state.extra as ComicBrowseTarget? ?? const ComicBrowseTarget('/comics'))),
  GoRoute(path: '/comics/:id/read', builder: (context, state) => ComicReaderPage(comic: state.extra! as ComicDetail)),
  GoRoute(path: '/comics/:id', builder: (context, state) => ComicDetailPage(id: state.pathParameters['id']!)),
]);

class Han1meApp extends ConsumerStatefulWidget {
  const Han1meApp({super.key});

  @override
  ConsumerState<Han1meApp> createState() => _Han1meAppState();
}

class _Han1meAppState extends ConsumerState<Han1meApp> {
  var _checkedForUpdate = false;
  var _appliedPrivacySettings = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(accountProvider);
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.value ?? AppSettings();
    if (settingsState.hasValue && settings.autoUpdate && !_checkedForUpdate) {
      _checkedForUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    }
    if (settingsState.hasValue && !_appliedPrivacySettings) {
      _appliedPrivacySettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await PlatformService.setHideFromRecents(settings.hideFromRecents);
        await PlatformService.setEmergencyExit(settings.emergencyExitEnabled);
        if (settings.appLockEnabled) await PlatformService.authenticate();
      });
    }
    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) => MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle, debugShowCheckedModeBanner: false, routerConfig: _router,
      locale: switch (settings.language) {
        AppLanguage.system => null,
        AppLanguage.simplifiedChinese => const Locale('zh', 'CN'),
        AppLanguage.traditionalChinese => const Locale('zh', 'TW'),
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: settings.materialThemeMode,
       theme: _theme(settings.useMonetColors ? lightDynamic : null, settings.themeColor.seedColor),
       darkTheme: _theme(settings.useMonetColors ? darkDynamic : null, settings.themeColor.seedColor, brightness: Brightness.dark, amoled: settings.amoledMode),
     ));
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateChecker(Dio()).check();
    if (!mounted || update == null) return;
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.newVersionAvailable(update.tagName)), content: Text(update.body.isEmpty ? l10n.newVersionReleased : update.body), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.later)), FilledButton(onPressed: () async { Navigator.pop(dialogContext); await _installUpdate(context, update.downloadUrl); }, child: Text(l10n.updateNow))]));
  }

  Future<void> _installUpdate(BuildContext context, String url) async {
    if (url.isEmpty) return;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => _StartupUpdateDownload(url: url));
  }
}

class _StartupUpdateDownload extends StatefulWidget {
  const _StartupUpdateDownload({required this.url});
  final String url;

  @override
  State<_StartupUpdateDownload> createState() => _StartupUpdateDownloadState();
}

class _StartupUpdateDownloadState extends State<_StartupUpdateDownload> {
  double? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      await UpdateInstaller(Dio()).downloadAndInstall(widget.url, (value) { if (mounted) setState(() => _progress = value); });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(AppLocalizations.of(context)!.downloadingUpdate), content: _error == null ? Column(mainAxisSize: MainAxisSize.min, children: [LinearProgressIndicator(value: _progress), const SizedBox(height: 12), Text(_progress == null ? AppLocalizations.of(context)!.connecting : '${(_progress! * 100).toStringAsFixed(0)}%')]) : Text(AppLocalizations.of(context)!.updateFailed(_error.toString())), actions: _error == null ? null : [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.close))]);
}

ThemeData _theme(ColorScheme? dynamicScheme, Color seedColor, {Brightness brightness = Brightness.light, bool amoled = false}) {
  var scheme = dynamicScheme ?? ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  if (amoled) {
    scheme = scheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: Colors.black,
      surfaceContainer: Colors.black,
      surfaceContainerHigh: Colors.black,
      surfaceContainerHighest: Colors.black,
    );
  }
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: amoled ? Colors.black : null,
    canvasColor: amoled ? Colors.black : null,
    sliderTheme: const SliderThemeData(year2023: false),
  );
}

extension on AppThemeColor {
  Color get seedColor => switch (this) {
        AppThemeColor.rose => const Color(0xffb3265a),
        AppThemeColor.blue => const Color(0xff00639b),
        AppThemeColor.teal => const Color(0xff006b5f),
        AppThemeColor.amber => const Color(0xff875400),
        AppThemeColor.green => const Color(0xff386a20),
        AppThemeColor.orange => const Color(0xff9b4400),
        AppThemeColor.indigo => const Color(0xff4a5f9e),
        AppThemeColor.pink => const Color(0xff9c3c66),
        AppThemeColor.purple => const Color(0xff6d3f90),
      };
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comicMode = ref.watch(settingsProvider).valueOrNull?.comicMode ?? false;
    return Scaffold(body: comicMode ? switch (navigationShell.currentIndex) { 0 => const ComicExplorePage(), 1 => const ComicLibraryPage(), 2 => const ComicCachePage(), _ => navigationShell } : navigationShell, bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      destinations: [NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: AppLocalizations.of(context)!.explore), NavigationDestination(icon: const Icon(Icons.bookmark_outline), selectedIcon: const Icon(Icons.bookmark), label: AppLocalizations.of(context)!.library), NavigationDestination(icon: const Icon(Icons.download_outlined), selectedIcon: const Icon(Icons.download), label: AppLocalizations.of(context)!.cache), NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: AppLocalizations.of(context)!.settings)],
    ));
  }
}
