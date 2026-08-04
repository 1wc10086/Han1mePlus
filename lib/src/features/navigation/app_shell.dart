import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_shell.dart';
import '../../core/platform_service.dart';
import '../../domain/models/account.dart';
import '../account/account_controller.dart';
import '../comics/comic_pages.dart';
import '../settings/settings_controller.dart';
import 'exit_coordinator.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell, required this.exitCoordinator});

  final StatefulNavigationShell navigationShell;
  final AppExitCoordinator exitCoordinator;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with SingleTickerProviderStateMixin {
  late final AnimationController _pageTransitionController;
  late int _currentIndex;
  late final List<int> _branchHistory;
  var _isBackNavigation = false;
  var _pageTransitionOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
    _branchHistory = <int>[widget.navigationShell.currentIndex];
    _pageTransitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.navigationShell.currentIndex;
    if (nextIndex == _currentIndex) return;
    _pageTransitionOffset = Offset(nextIndex > _currentIndex ? 1 : -1, 0);
    if (_isBackNavigation) {
      if (_branchHistory.isNotEmpty) _branchHistory.removeLast();
      _isBackNavigation = false;
      widget.exitCoordinator.clearBranchBackHandled();
    } else {
      _branchHistory.remove(nextIndex);
      _branchHistory.add(nextIndex);
      if (_branchHistory.length > 4) _branchHistory.removeAt(0);
    }
    _currentIndex = nextIndex;
    _pageTransitionController.forward(from: 0);
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final comicMode = settings?.comicMode ?? false;
    final drawerMode = settings?.useNavigationDrawer ?? false;
    final useRail = !drawerMode && MediaQuery.sizeOf(context).shortestSide >= 600;
    final useLiquidGlassBottomBar = !drawerMode && !useRail && (settings?.useLiquidGlassBottomBar ?? true);
    final destinations = [
      (icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: AppLocalizations.of(context)!.explore),
      (icon: Icons.bookmark_outline, selectedIcon: Icons.bookmark, label: AppLocalizations.of(context)!.library),
      (icon: Icons.download_outlined, selectedIcon: Icons.download, label: AppLocalizations.of(context)!.cache),
      (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: AppLocalizations.of(context)!.settings),
    ];
    void select(int index) => widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
    final content = comicMode
        ? switch (widget.navigationShell.currentIndex) {
            0 => const ComicExplorePage(),
            1 => ComicLibraryPage(initialTab: _libraryTab(GoRouterState.of(context).pathParameters['tab']), drawerMode: drawerMode),
            2 => const ComicCachePage(),
            _ => widget.navigationShell,
          }
        : widget.navigationShell;
    final animatedContent = useLiquidGlassBottomBar
        ? RepaintBoundary(
            child: SlideTransition(
              position: Tween(begin: _pageTransitionOffset, end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_pageTransitionController),
              child: content,
            ),
          )
        : content;
    final mediaQuery = MediaQuery.of(context);
    final contentMediaQuery = useLiquidGlassBottomBar
        ? mediaQuery.copyWith(padding: mediaQuery.padding.copyWith(bottom: mediaQuery.padding.bottom + 104))
        : mediaQuery;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleRootBack(context);
      },
      child: Scaffold(
        key: drawerMode ? appShellScaffoldKey : null,
        extendBody: useLiquidGlassBottomBar,
        drawer: drawerMode ? _AppDrawer(navigationShell: widget.navigationShell) : null,
        body: useRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: widget.navigationShell.currentIndex,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: select,
                    destinations: destinations.map((destination) => NavigationRailDestination(icon: Icon(destination.icon), selectedIcon: Icon(destination.selectedIcon), label: Text(destination.label))).toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : MediaQuery(data: contentMediaQuery, child: animatedContent),
        bottomNavigationBar: drawerMode || useRail
            ? null
            : useLiquidGlassBottomBar
                ? GlassTabBar.bottom(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onTabSelected: select,
                    tabs: destinations.map((destination) => GlassTab(icon: Icon(destination.icon), activeIcon: Icon(destination.selectedIcon), label: destination.label)).toList(),
                  )
                : NavigationBar(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: select,
                    destinations: destinations.map((destination) => NavigationDestination(icon: Icon(destination.icon), selectedIcon: Icon(destination.selectedIcon), label: destination.label)).toList(),
                  ),
      ),
    );
  }

  Future<void> _handleRootBack(BuildContext context) async {
    if (_branchHistory.length > 1) {
      _isBackNavigation = true;
      widget.exitCoordinator.markBranchBackHandled();
      widget.navigationShell.goBranch(_branchHistory[_branchHistory.length - 2]);
      return;
    }
    if (!await widget.exitCoordinator.confirmExit(context)) return;
    if (PlatformService.isDesktop) {
      try {
        await SystemNavigator.pop();
      } catch (_) {}
      return;
    }
    await PlatformService.minimizeApp();
  }
}

int _libraryTab(String? tab) => switch (tab) {
      'watch-later' => 0,
      'favorites' => 1,
      'playlists' => 2,
      'subscriptions' => 3,
      'history' => 4,
      _ => 0,
    };

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(accountProvider).valueOrNull;
    final path = GoRouterState.of(context).uri.path;
    final comicMode = ref.watch(settingsProvider).valueOrNull?.comicMode ?? false;
    final destinations = [
      _DrawerItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.home, location: '/'),
      _DrawerItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: l10n.settings, location: '/settings'),
      _DrawerItem(icon: Icons.watch_later_outlined, selectedIcon: Icons.watch_later, label: l10n.watchLater, location: '/library/watch-later'),
      _DrawerItem(icon: Icons.favorite_outline, selectedIcon: Icons.favorite, label: l10n.favoriteVideos, location: '/library/favorites'),
      if (!comicMode) ...[
        _DrawerItem(icon: Icons.playlist_play_outlined, selectedIcon: Icons.playlist_play, label: l10n.playlists, location: '/library/playlists'),
        _DrawerItem(icon: Icons.subscriptions_outlined, selectedIcon: Icons.subscriptions, label: l10n.subscriptions, location: '/library/subscriptions'),
        _DrawerItem(icon: Icons.history_outlined, selectedIcon: Icons.history, label: l10n.watchHistory, location: '/library/history'),
      ],
      _DrawerItem(icon: Icons.download_outlined, selectedIcon: Icons.download, label: l10n.download, location: '/cache'),
    ];
    final selectedIndex = destinations.indexWhere((destination) => destination.location == path);
    return NavigationDrawer(
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      onDestinationSelected: (index) => _go(context, destinations[index].location),
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(28, 12, 28, 20), child: Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineSmall)),
        _DrawerAccountCard(account: account),
        const SizedBox(height: 12),
        NavigationDrawerDestination(icon: Icon(destinations[0].icon), selectedIcon: Icon(destinations[0].selectedIcon), label: Text(destinations[0].label)),
        NavigationDrawerDestination(icon: Icon(destinations[1].icon), selectedIcon: Icon(destinations[1].selectedIcon), label: Text(destinations[1].label)),
        const Padding(padding: EdgeInsets.fromLTRB(28, 12, 28, 8), child: Divider()),
        for (final destination in destinations.skip(2)) NavigationDrawerDestination(icon: Icon(destination.icon), selectedIcon: Icon(destination.selectedIcon), label: Text(destination.label)),
      ],
    );
  }

  void _go(BuildContext context, String location) {
    if (GoRouterState.of(context).uri.path == location) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context);
    switch (location) {
      case '/':
        navigationShell.goBranch(0, initialLocation: navigationShell.currentIndex == 0);
      case '/settings':
        navigationShell.goBranch(3, initialLocation: navigationShell.currentIndex == 3);
      case '/cache':
        navigationShell.goBranch(2, initialLocation: navigationShell.currentIndex == 2);
      default:
        context.push(location);
    }
  }
}

class _DrawerItem {
  const _DrawerItem({required this.icon, required this.selectedIcon, required this.label, required this.location});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String location;
}

class _DrawerAccountCard extends StatelessWidget {
  const _DrawerAccountCard({this.account});

  final Account? account;

  @override
  Widget build(BuildContext context) {
    final loggedIn = account != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push(loggedIn ? '/account/profile/${account!.id}' : '/login');
                },
                child: CircleAvatar(radius: 28, backgroundImage: account?.avatarUrl?.isNotEmpty == true ? NetworkImage(account!.avatarUrl!) : null, child: account?.avatarUrl?.isNotEmpty == true ? null : Icon(loggedIn ? Icons.person : Icons.person_outline, size: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account?.name?.isNotEmpty == true ? account!.name! : loggedIn ? AppLocalizations.of(context)!.signedIn : AppLocalizations.of(context)!.signedOut, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(loggedIn ? '@${account!.id}' : AppLocalizations.of(context)!.tapToLogin, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
