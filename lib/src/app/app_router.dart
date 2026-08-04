import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../core/route_observer.dart';
import '../domain/models/comic.dart';
import '../features/account/account_web_page.dart';
import '../features/account/login_page.dart';
import '../features/cache/cache_page.dart';
import '../features/comics/comic_pages.dart';
import '../features/explore/explore_page.dart';
import '../features/library/library_page.dart';
import '../features/navigation/app_shell.dart';
import '../features/navigation/exit_coordinator.dart';
import '../features/previews/previews_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/about_page.dart';
import '../features/settings/application_settings_page.dart';
import '../features/settings/cloudflare_page.dart';
import '../features/settings/comment_settings_page.dart';
import '../features/settings/deep_link_settings_page.dart';
import '../features/settings/keyframes_page.dart';
import '../features/settings/language_settings_page.dart';
import '../features/settings/layout_settings_page.dart';
import '../features/settings/license_page.dart';
import '../features/settings/network_settings_page.dart';
import '../features/settings/playback_settings_page.dart';
import '../features/settings/player_settings_page.dart';
import '../features/settings/privacy_settings_page.dart';
import '../features/settings/recommendation_settings_page.dart';
import '../features/settings/selection_settings_pages.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/theme_settings_page.dart';
import '../features/settings/webdav_settings_page.dart';
import '../features/shared/comments_page.dart';
import '../features/stats/stats_page.dart';
import '../features/video/video_page.dart';
import '../features/video/tag_editor_page.dart';

class AppRouter {
  AppRouter(AppExitCoordinator exitCoordinator) {
    router = GoRouter(
      navigatorKey: navigatorKey,
      observers: [routeObserver],
      redirect: (context, state) => _deepLinkRedirect(state),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell, exitCoordinator: exitCoordinator),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const ExplorePage())]),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (context, state) => const LibraryPage(),
                  routes: [
                    GoRoute(
                      path: ':tab',
                      builder: (context, state) {
                        final tab = _libraryTab(state.pathParameters['tab']);
                        return LibraryPage(key: ValueKey(tab), initialTab: tab);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(routes: [GoRoute(path: '/cache', builder: (context, state) => const CachePage())]),
            StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsPage())]),
          ],
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/account/profile/:id',
          builder: (context, state) => AccountWebPage(
            path: '/user/${state.pathParameters['id']!}/edit',
            title: AppLocalizations.of(context)!.accountProfile,
          ),
        ),
        GoRoute(path: '/search', builder: (context, state) => SearchPage(initialUrl: state.extra as String?)),
        GoRoute(path: '/settings/about', builder: (context, state) => const AboutPage()),
        GoRoute(path: '/settings/license', builder: (context, state) => const AppLicensePage()),
        GoRoute(path: '/settings/keyframes', builder: (context, state) => const KeyframesPage()),
        GoRoute(path: '/settings/playback', builder: (context, state) => const PlaybackSettingsPage()),
        GoRoute(path: '/settings/player', builder: (context, state) => const PlayerSettingsPage()),
        GoRoute(path: '/settings/privacy', builder: (context, state) => const PrivacySettingsPage()),
        GoRoute(path: '/settings/comments', builder: (context, state) => const CommentSettingsPage()),
        GoRoute(path: '/settings/comments/users', builder: (context, state) => const CommentUserFilterPage()),
        GoRoute(path: '/settings/deep-links', builder: (context, state) => const DeepLinkSettingsPage()),
        GoRoute(path: '/settings/theme', builder: (context, state) => const ThemeSettingsPage()),
        GoRoute(path: '/settings/layout', builder: (context, state) => const LayoutSettingsPage()),
        GoRoute(path: '/settings/network', builder: (context, state) => const NetworkSettingsPage()),
        GoRoute(path: '/settings/recommendations', builder: (context, state) => const RecommendationSettingsPage()),
        GoRoute(path: '/settings/recommendations/titles', builder: (context, state) => const VideoTitleFilterPage()),
        GoRoute(path: '/settings/recommendations/authors', builder: (context, state) => const AuthorFilterPage()),
        GoRoute(path: '/settings/webdav', builder: (context, state) => const WebDavSettingsPage()),
        GoRoute(path: '/settings/webdav/configuration', builder: (context, state) => const WebDavConfigurationPage()),
        GoRoute(path: '/settings/application', builder: (context, state) => const ApplicationSettingsPage()),
        GoRoute(path: '/settings/language', builder: (context, state) => const LanguageSettingsPage()),
        GoRoute(path: '/settings/site', builder: (context, state) => const SiteSettingsPage()),
        GoRoute(path: '/settings/player/decoder', builder: (context, state) => const DecoderSettingsPage()),
        GoRoute(path: '/settings/player/renderer', builder: (context, state) => const RendererSettingsPage()),
        GoRoute(path: '/settings/player/super-resolution', builder: (context, state) => const SuperResolutionSettingsPage()),
        GoRoute(path: '/cloudflare', builder: (context, state) => CloudflarePage(initialUrl: state.extra as String?)),
        GoRoute(path: '/previews/:month', builder: (context, state) => PreviewsPage(month: state.pathParameters['month']!)),
        GoRoute(path: '/comments/:type/:id', builder: (context, state) => CommentsPage(id: state.pathParameters['id']!, type: state.pathParameters['type']!, title: state.extra as String? ?? '')),
        GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
        GoRoute(path: '/video/:id/tags/:mode', builder: (context, state) => TagEditorPage(videoId: state.pathParameters['id']!, mode: state.pathParameters['mode'] == 'remove' ? TagEditorMode.remove : TagEditorMode.add)),
        GoRoute(path: '/video/:id', builder: (context, state) => VideoPage(id: state.pathParameters['id']!)),
        GoRoute(path: '/comics/browse', builder: (context, state) => ComicBrowsePage(target: state.extra as ComicBrowseTarget? ?? const ComicBrowseTarget('/comics'))),
        GoRoute(path: '/comics/:id/read', builder: (context, state) => ComicReaderPage(comic: state.extra! as ComicDetail)),
        GoRoute(path: '/comics/:id', builder: (context, state) => ComicDetailPage(id: state.pathParameters['id']!)),
      ],
    );
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter router;

  void dispose() {
    router.dispose();
  }
}

String? _deepLinkRedirect(GoRouterState state) {
  final uri = state.uri;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  const hosts = {'hanime1.com', 'hanimeone.me', 'hanime1.me', 'javchu.com'};
  if (!hosts.contains(uri.host)) return null;
  final videoId = uri.queryParameters['v'];
  if (videoId != null && uri.path.contains('watch')) return '/video/$videoId';
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.length >= 3 && segments[0] == 'videos' && segments[1] == 'hentai') return '/video/${segments[2]}';
  if (uri.path.contains('search')) return '/search';
  return null;
}

int _libraryTab(String? tab) => switch (tab) {
      'watch-later' => 0,
      'favorites' => 1,
      'playlists' => 2,
      'subscriptions' => 3,
      'history' => 4,
      _ => 0,
    };
