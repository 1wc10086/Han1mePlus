import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';

class CommentSettingsPage extends ConsumerWidget {
  const CommentSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.commentSettings)), body: ListView(children: [
      SwitchListTile(title: Text(l10n.enableComments), value: settings.commentsEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(commentsEnabled: value))),
      ListTile(leading: const Icon(Icons.block_outlined), title: Text(l10n.commentKeywordFilter), subtitle: Text(l10n.commentKeywordFilterDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CommentKeywordsPage()))),
    ]));
  }
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
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
