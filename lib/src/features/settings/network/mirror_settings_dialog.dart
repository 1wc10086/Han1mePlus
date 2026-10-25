import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/settings.dart';
import '../../../data/remote/mirror_probe.dart';

class MirrorSettings {
  const MirrorSettings({required this.enabled, required this.url, required this.appendPath});

  final bool enabled;
  final String url;
  final bool appendPath;
}

Future<MirrorSettings?> showMirrorSettingsDialog(BuildContext context, {required AppSettings settings}) =>
    showDialog<MirrorSettings>(context: context, builder: (_) => _MirrorSettingsDialog(settings: settings));

class _MirrorSettingsDialog extends StatefulWidget {
  const _MirrorSettingsDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_MirrorSettingsDialog> createState() => _MirrorSettingsDialogState();
}

class _MirrorSettingsDialogState extends State<_MirrorSettingsDialog> {
  late bool _enabled = widget.settings.useCustomMirrorSite;
  late bool _appendPath = widget.settings.appendCustomMirrorPath;
  late final TextEditingController _url = TextEditingController(text: widget.settings.customMirrorSite);
  bool _testing = false;
  String? _testResult;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _testConnection(AppLocalizations l10n) async {
    final url = _url.text.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.hasQuery || uri.hasFragment) {
      setState(() => _testResult = l10n.customMirrorSiteInvalid);
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await MirrorProbe.test(homeUrl: url, appendPath: _appendPath);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = _describe(l10n, result);
    });
  }

  String _describe(AppLocalizations l10n, MirrorProbeResult result) => switch (result.kind) {
        MirrorProbeKind.success => l10n.customMirrorTestSuccess(result.homeUrl ?? '', result.apiBase ?? ''),
        MirrorProbeKind.partialSuccess => l10n.customMirrorTestPartialSuccess(result.apiBase ?? '', result.statusCode ?? 0),
        MirrorProbeKind.httpError => l10n.customMirrorTestFailedHttp(result.statusCode ?? 0, result.homeUrl ?? ''),
        MirrorProbeKind.challenge => l10n.customMirrorTestChallenge,
        MirrorProbeKind.parseFailure => l10n.customMirrorTestParseFailed,
        MirrorProbeKind.failure => l10n.customMirrorTestFailed(result.error ?? ''),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.customMirrorSite),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.enableCustomMirrorSite),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.customMirrorSite, hintText: l10n.customMirrorSiteHint),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.customMirrorApiPathMode),
              subtitle: Text(_appendPath ? l10n.customMirrorPathFollowHomeSummary : l10n.customMirrorPathRootSummary),
              value: _appendPath,
              onChanged: (value) => setState(() => _appendPath = value),
            ),
            if (_testResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_testResult!, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : () => _testConnection(l10n),
          child: _testing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.testConnection),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            MirrorSettings(
              enabled: _enabled,
              url: _url.text.trim().replaceAll(RegExp(r'/+$'), ''),
              appendPath: _appendPath,
            ),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
