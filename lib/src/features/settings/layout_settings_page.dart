import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../explore/explore_controller.dart';
import 'settings_controller.dart';

class LayoutSettingsPage extends ConsumerWidget {
  const LayoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.interfaceLayout)), body: ListView(children: [
      _SectionLabel(l10n.general),
      SwitchListTile(secondary: const Icon(Icons.menu_book_outlined), title: Text(l10n.comicMode), subtitle: Text(l10n.comicModeDescription), value: settings.comicMode, onChanged: (value) async { await controller.saveChanges((current) => current.copyWith(comicMode: value, baseUrl: value ? 'https://hanimeone.me' : current.videoBaseUrl, videoBaseUrl: value ? current.baseUrl : current.videoBaseUrl)); ref.invalidate(homeSectionsProvider); }),
      SwitchListTile(secondary: const Icon(Icons.view_stream_outlined), title: Text(l10n.horizontalSearchCards), subtitle: Text(l10n.horizontalSearchCardsDescription), value: settings.useHorizontalSearchCards, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useHorizontalSearchCards: value))),
      SwitchListTile(secondary: const Icon(Icons.unfold_more_outlined), title: Text(l10n.expandHomeVideoCards), subtitle: Text(l10n.expandHomeVideoCardsDescription), value: settings.expandHomeVideoCards, onChanged: (value) => controller.saveChanges((current) => current.copyWith(expandHomeVideoCards: value))),
      ListTile(leading: const Icon(Icons.grid_view_outlined), title: Text(l10n.searchCardsPerRow), subtitle: Text(l10n.searchCardsPerRowValue(settings.searchCardsPerRow)), trailing: const Icon(Icons.chevron_right), onTap: () => _showCountPicker(context, settings.searchCardsPerRow, controller)),
    ]));
  }

  Future<void> _showCountPicker(BuildContext context, int count, SettingsController controller) async {
    final selected = await showModalBottomSheet<int>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final value in [1, 2, 3]) RadioListTile(value: value, groupValue: count, title: Text(AppLocalizations.of(context)!.searchCardsPerRowValue(value)), onChanged: (value) => Navigator.pop(context, value))])));
    if (selected != null) await controller.saveChanges((current) => current.copyWith(searchCardsPerRow: selected));
  }
}

class _SectionLabel extends StatelessWidget { const _SectionLabel(this.text); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary))); }
