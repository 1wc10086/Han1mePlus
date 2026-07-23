import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';
import 'danmaku_settings_page.dart';

class CommentSettingsPage extends ConsumerWidget {
  const CommentSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.commentSettings)), body: ListView(children: [
      _SectionLabel(l10n.comments),
      SwitchListTile(secondary: const Icon(Icons.forum_outlined), title: Text(l10n.enableComments), value: settings.commentsEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(commentsEnabled: value))),
      ListTile(leading: const Icon(Icons.block_outlined), title: Text(l10n.commentKeywordFilter), subtitle: Text(l10n.commentKeywordFilterDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CommentKeywordsPage()))),
      _SectionLabel(l10n.danmakuSettings),
      SwitchListTile(secondary: const Icon(Icons.subtitles_outlined), title: Text(l10n.enableDanmaku), subtitle: Text(l10n.enableDanmakuDescription), value: settings.danmakuEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(danmakuEnabled: value))),
      ListTile(leading: const Icon(Icons.block_outlined), title: Text(l10n.danmakuKeywordFilter), subtitle: Text(l10n.danmakuKeywordFilterDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DanmakuKeywordsPage()))),
      SwitchListTile(secondary: const Icon(Icons.speed_outlined), title: Text(l10n.danmakuFollowsPlaybackSpeed), subtitle: Text(l10n.danmakuFollowsPlaybackSpeedDescription), value: settings.danmakuFollowsPlaybackSpeed, onChanged: (value) => controller.saveChanges((current) => current.copyWith(danmakuFollowsPlaybackSpeed: value))),
    ]));
  }
}

class _SectionLabel extends StatelessWidget { const _SectionLabel(this.text); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary))); }

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
