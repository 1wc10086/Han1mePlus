import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/settings.dart';

class DohSettings {
  const DohSettings({
    required this.enabled,
    required this.preset,
    required this.customUrl,
    required this.bootstrapIps,
    required this.timeoutSeconds,
  });

  final bool enabled;
  final String preset;
  final String customUrl;
  final String bootstrapIps;
  final int timeoutSeconds;
}

const Map<String, String> dohPresets = {
  'alidns': 'AliDNS',
  'dnspod': 'DNSPod',
  'cloudflare': 'Cloudflare',
};

Future<DohSettings?> showDohSettingsDialog(BuildContext context, {required AppSettings settings}) =>
    showDialog<DohSettings>(context: context, builder: (_) => _DohSettingsDialog(settings: settings));

class _DohSettingsDialog extends StatefulWidget {
  const _DohSettingsDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_DohSettingsDialog> createState() => _DohSettingsDialogState();
}

class _DohSettingsDialogState extends State<_DohSettingsDialog> {
  late bool _enabled = widget.settings.useDoh;
  late String _preset = widget.settings.dohPreset;
  late final TextEditingController _customUrl = TextEditingController(text: widget.settings.dohCustomUrl);
  late final TextEditingController _bootstrapIps = TextEditingController(text: widget.settings.dohBootstrapIps);
  late final TextEditingController _timeout = TextEditingController(text: widget.settings.dohTimeoutSeconds.toString());

  @override
  void dispose() {
    _customUrl.dispose();
    _bootstrapIps.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.dohSettings),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.useDoh),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            DropdownButtonFormField<String>(
              value: _preset,
              decoration: InputDecoration(labelText: l10n.dohPreset),
              items: [
                ...dohPresets.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))),
                DropdownMenuItem(value: 'custom', child: Text(l10n.custom)),
              ],
              onChanged: (value) => setState(() => _preset = value ?? _preset),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customUrl,
              enabled: _preset == 'custom',
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.dohCustomUrl),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bootstrapIps,
              decoration: InputDecoration(labelText: l10n.dohBootstrapIps, helperText: l10n.dohBootstrapIpsDescription),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeout,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.dohTimeoutSeconds, helperText: l10n.dohTimeoutSecondsDescription),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            DohSettings(
              enabled: _enabled,
              preset: _preset,
              customUrl: _customUrl.text.trim(),
              bootstrapIps: _bootstrapIps.text.trim(),
              timeoutSeconds: (int.tryParse(_timeout.text) ?? 10).clamp(1, 60) as int,
            ),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
