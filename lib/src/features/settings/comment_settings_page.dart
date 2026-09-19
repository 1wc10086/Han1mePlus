import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class CommentSettingsPage extends ConsumerWidget {
  const CommentSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.commentSettings)), body: ListView(children: [
       SettingsCardList(title: l10n.comments, children: [
         SettingsCardItem(title: l10n.enableComments, leading: const Icon(Icons.forum_outlined), trailing: Switch(value: settings.commentsEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(commentsEnabled: value)))),
          SettingsCardItem(title: l10n.commentKeywordFilter, subtitle: l10n.commentKeywordFilterDescription, leading: const Icon(Icons.block_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CommentKeywordsPage()))),
          SettingsCardItem(title: l10n.commentUserFilter, subtitle: l10n.commentUserFilterDescription, leading: const Icon(Icons.person_off_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/comments/users')),
       ]),
    ]));
  }
}

class CommentUserFilterPage extends ConsumerWidget {
  const CommentUserFilterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _CommentFilterEditor(title: AppLocalizations.of(context)!.commentUserFilter, label: AppLocalizations.of(context)!.username, values: ref.watch(settingsProvider).valueOrNull?.blockedCommentUsers ?? const [], onChanged: (values) => ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedCommentUsers: values)));
}

class _CommentFilterEditor extends StatefulWidget {
  const _CommentFilterEditor({required this.title, required this.label, required this.values, required this.onChanged});
  final String title;
  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_CommentFilterEditor> createState() => _CommentFilterEditorState();
}

class _CommentFilterEditorState extends State<_CommentFilterEditor> {
  final _input = TextEditingController();

  @override
  void dispose() { _input.dispose(); super.dispose(); }

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
  void _add() { final value = _input.text.trim(); if (value.isEmpty || widget.values.contains(value)) return; widget.onChanged([...widget.values, value]); _input.clear(); }
}


class CommentKeywordsPage extends ConsumerStatefulWidget {
  const CommentKeywordsPage({super.key});

  @override
  ConsumerState<CommentKeywordsPage> createState() => _CommentKeywordsPageState();
}

class _CommentKeywordsPageState extends ConsumerState<CommentKeywordsPage> {
  final _input = TextEditingController();

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.commentKeywordFilter)), body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _input, textInputAction: TextInputAction.done, onSubmitted: (_) => _add(settings.blockedCommentKeywords), decoration: InputDecoration(labelText: l10n.keyword)),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => _add(settings.blockedCommentKeywords), child: Text(l10n.add)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: settings.blockedCommentKeywords.map((keyword) => InputChip(label: Text(keyword), onDeleted: () => ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedCommentKeywords: current.blockedCommentKeywords.where((item) => item != keyword).toList())))).toList()),
      ]),
    ));
  }

  void _add(List<String> keywords) {
    final value = _input.text.trim();
    if (value.isEmpty || keywords.contains(value)) return;
    ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedCommentKeywords: [...current.blockedCommentKeywords, value]));
    _input.clear();
  }
}
