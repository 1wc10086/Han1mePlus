import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';

class DanmakuSettingsPage extends ConsumerWidget {
  const DanmakuSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.danmakuSettings)),
      body: ListView(
        children: [
          SwitchListTile(title: Text(l10n.enableDanmaku), subtitle: Text(l10n.enableDanmakuDescription), value: settings.danmakuEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(danmakuEnabled: value))),
          ListTile(leading: const Icon(Icons.block_outlined), title: Text(l10n.danmakuKeywordFilter), subtitle: Text(l10n.danmakuKeywordFilterDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DanmakuKeywordsPage()))),
          SwitchListTile(title: Text(l10n.danmakuFollowsPlaybackSpeed), subtitle: Text(l10n.danmakuFollowsPlaybackSpeedDescription), value: settings.danmakuFollowsPlaybackSpeed, onChanged: (value) => controller.saveChanges((current) => current.copyWith(danmakuFollowsPlaybackSpeed: value))),
        ],
      ),
    );
  }
}

class DanmakuKeywordsPage extends ConsumerStatefulWidget {
  const DanmakuKeywordsPage({super.key});

  @override
  ConsumerState<DanmakuKeywordsPage> createState() => _DanmakuKeywordsPageState();
}

class _DanmakuKeywordsPageState extends ConsumerState<DanmakuKeywordsPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.danmakuKeywordFilter)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _input, textInputAction: TextInputAction.done, onSubmitted: (_) => _add(settings.blockedDanmakuKeywords), decoration: InputDecoration(labelText: l10n.keyword)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => _add(settings.blockedDanmakuKeywords), child: Text(l10n.add)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: settings.blockedDanmakuKeywords.map((keyword) => InputChip(label: Text(keyword), onDeleted: () => ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedDanmakuKeywords: current.blockedDanmakuKeywords.where((item) => item != keyword).toList())))).toList()),
          ],
        ),
      ),
    );
  }

  void _add(List<String> keywords) {
    final value = _input.text.trim();
    if (value.isEmpty || keywords.contains(value)) return;
    ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(blockedDanmakuKeywords: [...current.blockedDanmakuKeywords, value]));
    _input.clear();
  }
}
