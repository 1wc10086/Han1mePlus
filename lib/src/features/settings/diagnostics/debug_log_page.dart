import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import 'debug_log_controller.dart';

class DebugLogPage extends ConsumerWidget {
  const DebugLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(debugLogProvider);
    final controller = ref.read(debugLogProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagnosticLog),
        actions: [
          IconButton(tooltip: l10n.refresh, onPressed: controller.refresh, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: l10n.clear,
            onPressed: () {
              controller.clear();
              _notify(context, l10n.logsCleared);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.logSummary(state.entries.length, state.engineLogs.length), style: Theme.of(context).textTheme.bodySmall)),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: controller.export()));
                    if (context.mounted) _notify(context, l10n.logsCopied);
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.copy),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => Share.share(controller.export(), subject: l10n.diagnosticLog),
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(l10n.share),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final entry in state.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SelectableText(entry.displayLine, style: _monospace(context)),
                  ),
                if (state.engineLogs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(l10n.echEngineLogs, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final line in state.engineLogs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SelectableText(line, style: _monospace(context)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _monospace(BuildContext context) => Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace');

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
