import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../data/remote/ech/ech_static_client.dart';

Future<void> showEchStatusDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final ech = EchStaticClient.instance;
  final logs = ech?.logs ?? const <String>[];
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.echDirectStatus),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ech == null ? l10n.echNotLoaded : l10n.echEnabledHint),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Text(l10n.echNoLogs)
            else ...[
              Text(l10n.echEngineLogs, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final line in logs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
      ],
    ),
  );
}
