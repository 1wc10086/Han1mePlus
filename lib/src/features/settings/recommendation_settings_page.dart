import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_card_list.dart';
import 'settings_controller.dart';

class RecommendationSettingsPage extends ConsumerWidget {
  const RecommendationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recommendationFilters)),
      body: ListView(
        children: [
          SettingsCardList(
            title: l10n.filters,
            children: [
              SettingsCardItem(title: l10n.videoTitleKeywordFilter, subtitle: l10n.videoTitleKeywordFilterDescription, leading: const Icon(Icons.title_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/recommendations/titles')),
              SettingsMenuItem(title: l10n.minimumVideoDuration, leading: const Icon(Icons.timer_outlined), value: settings.minimumVideoDurationSeconds, options: const [0, 30, 60, 90, 120, -1], label: (value) => value == -1 ? l10n.custom : value == 0 ? l10n.noFilter : l10n.seconds(value), onSelected: (value) => _selectCustom(context, value, settings.minimumVideoDurationSeconds, (result) => controller.saveChanges((current) => current.copyWith(minimumVideoDurationSeconds: result)))),
              SettingsMenuItem(title: l10n.minimumVideoViews, leading: const Icon(Icons.visibility_outlined), value: settings.minimumVideoViews, options: const [0, 50, 100, 500, 1000, -1], label: (value) => value == -1 ? l10n.custom : value == 0 ? l10n.noFilter : '$value', onSelected: (value) => _selectCustom(context, value, settings.minimumVideoViews, (result) => controller.saveChanges((current) => current.copyWith(minimumVideoViews: result)))),
              SettingsCardItem(title: l10n.authorFilter, subtitle: l10n.authorFilterDescription, leading: const Icon(Icons.person_off_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/recommendations/authors')),
              SettingsCardItem(title: l10n.exemptSubscribedAuthors, subtitle: l10n.exemptSubscribedAuthorsDescription, leading: const Icon(Icons.person_add_alt_1_outlined), trailing: Switch(value: settings.exemptSubscribedAuthors, onChanged: (value) => controller.saveChanges((current) => current.copyWith(exemptSubscribedAuthors: value)))),
              SettingsCardItem(title: l10n.applyFiltersToRelated, subtitle: l10n.applyFiltersToRelatedDescription, leading: const Icon(Icons.video_library_outlined), trailing: Switch(value: settings.applyRecommendationFiltersToRelated, onChanged: (value) => controller.saveChanges((current) => current.copyWith(applyRecommendationFiltersToRelated: value)))),
              SettingsCardItem(title: l10n.applyFiltersToSearch, subtitle: l10n.applyFiltersToSearchDescription, leading: const Icon(Icons.manage_search_outlined), trailing: Switch(value: settings.applyRecommendationFiltersToSearch, onChanged: (value) => controller.saveChanges((current) => current.copyWith(applyRecommendationFiltersToSearch: value)))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustom(BuildContext context, int value, int current, ValueChanged<int> onSelected) async {
    if (value != -1) {
      onSelected(value);
      return;
    }
    final result = await showDialog<int>(context: context, builder: (_) => _CustomValueDialog(initialValue: current == 0 ? '' : '$current'));
    if (result != null && result >= 0) onSelected(result);
  }
}

class _CustomValueDialog extends StatefulWidget {
  const _CustomValueDialog({required this.initialValue});
  final String initialValue;

  @override
  State<_CustomValueDialog> createState() => _CustomValueDialogState();
}

class _CustomValueDialogState extends State<_CustomValueDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.custom),
      content: TextField(controller: _controller, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.value)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(_controller.text.trim())), child: Text(l10n.save)),
      ],
    );
  }
}

class VideoTitleFilterPage extends ConsumerWidget {
  const VideoTitleFilterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _StringFilterPage(title: AppLocalizations.of(context)!.videoTitleKeywordFilter, label: AppLocalizations.of(context)!.keyword, values: ref.watch(settingsProvider).valueOrNull?.blockedVideoTitleKeywords ?? const [], onChanged: (values) => ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedVideoTitleKeywords: values)));
}

class AuthorFilterPage extends ConsumerWidget {
  const AuthorFilterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _StringFilterPage(title: AppLocalizations.of(context)!.authorFilter, label: AppLocalizations.of(context)!.author, values: ref.watch(settingsProvider).valueOrNull?.blockedAuthors ?? const [], onChanged: (values) => ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedAuthors: values)));
}

class _StringFilterPage extends StatefulWidget {
  const _StringFilterPage({required this.title, required this.label, required this.values, required this.onChanged});
  final String title;
  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_StringFilterPage> createState() => _StringFilterPageState();
}

class _StringFilterPageState extends State<_StringFilterPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _input, textInputAction: TextInputAction.done, onSubmitted: (_) => _add(), decoration: InputDecoration(labelText: widget.label)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _add, child: Text(AppLocalizations.of(context)!.add)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: widget.values.map((value) => InputChip(label: Text(value), onDeleted: () => widget.onChanged(widget.values.where((item) => item != value).toList()))).toList()),
            ],
          ),
        ),
      );

  void _add() {
    final value = _input.text.trim();
    if (value.isEmpty || widget.values.contains(value)) return;
    widget.onChanged([...widget.values, value]);
    _input.clear();
  }
}
