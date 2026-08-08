import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../explore/explore_controller.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class LayoutSettingsPage extends ConsumerWidget {
  const LayoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.interfaceLayout)), body: ListView(children: [
      SettingsCardList(title: l10n.general, children: [
        SettingsCardItem(title: l10n.navigationDrawer, subtitle: l10n.navigationDrawerDescription, leading: const Icon(Icons.menu_open_outlined), trailing: Switch(value: settings.useNavigationDrawer, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useNavigationDrawer: value)))),
        SettingsCardItem(title: l10n.liquidGlassBottomBar, subtitle: l10n.liquidGlassBottomBarDescription, leading: const Icon(Icons.water_drop_outlined), trailing: Switch(value: settings.useLiquidGlassBottomBar, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useLiquidGlassBottomBar: value)))),
        SettingsCardItem(title: l10n.comicMode, subtitle: l10n.comicModeDescription, leading: const Icon(Icons.menu_book_outlined), trailing: Switch(value: settings.comicMode, onChanged: (value) async { await controller.saveChanges((current) => current.copyWith(comicMode: value, baseUrl: value ? 'https://hanimeone.me' : current.videoBaseUrl, videoBaseUrl: value ? current.baseUrl : current.videoBaseUrl)); ref.invalidate(homeSectionsProvider); })),
        SettingsCardItem(title: l10n.horizontalSearchCards, subtitle: l10n.horizontalSearchCardsDescription, leading: const Icon(Icons.view_stream_outlined), trailing: Switch(value: settings.useHorizontalSearchCards, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useHorizontalSearchCards: value)))),
        SettingsCardItem(title: l10n.compactSearchCards, subtitle: l10n.compactSearchCardsDescription, leading: const Icon(Icons.view_comfy_outlined), trailing: Switch(value: settings.useCompactSearchCards, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useCompactSearchCards: value)))),
        SettingsCardItem(title: l10n.expandHomeVideoCards, subtitle: l10n.expandHomeVideoCardsDescription, leading: const Icon(Icons.unfold_more_outlined), trailing: Switch(value: settings.expandHomeVideoCards, onChanged: (value) => controller.saveChanges((current) => current.copyWith(expandHomeVideoCards: value)))),
        SettingsCardItem(title: l10n.homeCategoryTabs, subtitle: l10n.homeCategoryTabsDescription, leading: const Icon(Icons.tab_outlined), trailing: Switch(value: settings.useHomeCategoryTabs, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useHomeCategoryTabs: value)))),
        SettingsCardItem(title: l10n.recommendationFilters, leading: const Icon(Icons.filter_alt_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/recommendations')),
        SettingsMenuItem(title: l10n.searchCardsPerRow, subtitle: l10n.searchCardsPerRowValue(settings.searchCardsPerRow), leading: const Icon(Icons.grid_view_outlined), value: settings.searchCardsPerRow, options: const [1, 2, 3], label: l10n.searchCardsPerRowValue, onSelected: (value) => controller.saveChanges((current) => current.copyWith(searchCardsPerRow: value))),
      ]),
    ]));
  }
}
