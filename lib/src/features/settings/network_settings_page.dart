import 'dart:io';

import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import '../../core/platform_paths.dart';
import '../../data/local/download_repository.dart';
import '../../data/remote/han1me_http_client.dart';
import '../account/account_controller.dart';
import '../explore/explore_controller.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class NetworkSettingsPage extends ConsumerWidget {
  const NetworkSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.networkSettings)), body: ListView(children: [
       SettingsCardList(title: l10n.general, children: [
        SettingsCardItem(title: l10n.site, subtitle: settings.comicMode ? 'https://hanimeone.me' : settings.baseUrl, leading: const Icon(Icons.language_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/site')),
       SettingsCardItem(title: l10n.customMirrorSite, subtitle: settings.mirrorActive ? settings.customMirrorSite : l10n.customMirrorSiteHint, leading: const Icon(Icons.link_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _showMirrorSettings(context, ref, settings, controller)),
       SettingsCardItem(title: l10n.useBuiltInHosts, subtitle: l10n.useBuiltInHostsDescription, leading: const Icon(Icons.dns_outlined), trailing: Switch(value: settings.useBuiltInHosts, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useBuiltInHosts: value, useDoh: value ? false : current.useDoh)))),
       SettingsCardItem(title: l10n.doh, subtitle: _dohSummary(l10n, settings), leading: const Icon(Icons.security_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _showDohSettings(context, settings, controller)),
      ]),
       SettingsCardList(title: l10n.downloadSettings, children: [
       SettingsCardItem(title: l10n.downloadPath, subtitle: settings.downloadPath, leading: const Icon(Icons.folder_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _editDownloadPath(context, settings, controller)),
       SettingsCardItem(title: l10n.exportDownloads, subtitle: l10n.exportDownloadsDescription, leading: const Icon(Icons.drive_folder_upload_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _exportDownloads(context, ref)),
       _SliderTile(icon: Icons.speed_outlined, title: l10n.downloadSpeedLimit, value: settings.downloadSpeedLimitMbps, min: 0, max: 20, divisions: 40, label: settings.downloadSpeedLimitMbps == 0 ? l10n.unlimited : '${settings.downloadSpeedLimitMbps.toStringAsFixed(1)} MB/s', onChanged: (value) => controller.saveChanges((current) => current.copyWith(downloadSpeedLimitMbps: value))),
       _SliderTile(icon: Icons.download_for_offline_outlined, title: l10n.concurrentDownloads, subtitle: l10n.concurrentDownloadsDescription(settings.concurrentDownloads), value: settings.concurrentDownloads.toDouble(), min: 1, max: 5, divisions: 4, label: '${settings.concurrentDownloads}', onChanged: (value) => controller.saveChanges((current) => current.copyWith(concurrentDownloads: value.round()))),
      ]),
    ]));
  }

  Future<void> _editDownloadPath(BuildContext context, AppSettings settings, SettingsController controller) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final path = await resolveDefaultDownloadPath();
      await controller.saveChanges((current) => current.copyWith(downloadPath: path));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privateDownloadPath)));
      return;
    }
    final path = await showDialog<String>(context: context, builder: (_) => _PathDialog(title: AppLocalizations.of(context)!.downloadPath, initialPath: settings.downloadPath));
    if (path == null) return;
    await controller.saveChanges((current) => current.copyWith(downloadPath: path));
  }

  Future<void> _exportDownloads(BuildContext context, WidgetRef ref) async {
    if (Platform.isAndroid) {
      final exported = await ref.read(downloadProvider.notifier).exportCompletedWithPicker();
      if (!exported) return;
    } else {
      final path = await FilePicker.platform.getDirectoryPath(dialogTitle: AppLocalizations.of(context)!.exportDownloads);
      if (path == null || path.isEmpty) return;
      await ref.read(downloadProvider.notifier).exportCompleted(path);
    }
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.exportCompleted)));
  }

  String _dohSummary(AppLocalizations l10n, AppSettings settings) => !settings.useDoh ? l10n.dohDisabled : settings.dohPreset == 'custom' ? settings.dohCustomUrl.ifEmpty(l10n.custom) : _dohPresets[settings.dohPreset]!;

  Future<void> _showMirrorSettings(BuildContext context, WidgetRef ref, AppSettings settings, SettingsController controller) async {
    final result = await showDialog<_MirrorSettings>(context: context, builder: (_) => _MirrorSettingsDialog(settings: settings));
    if (result == null || result.enabled == settings.useCustomMirrorSite && result.url == settings.customMirrorSite && result.appendPath == settings.appendCustomMirrorPath) return;
    await controller.saveChanges((current) => current.copyWith(useCustomMirrorSite: result.enabled, customMirrorSite: result.url, appendCustomMirrorPath: result.appendPath));
    ref.invalidate(accountProvider);
    ref.invalidate(homeSectionsProvider);
  }

  Future<void> _showDohSettings(BuildContext context, AppSettings settings, SettingsController controller) async {
    final result = await showDialog<_DohSettings>(context: context, builder: (_) => _DohSettingsDialog(settings: settings));
    if (result != null) await controller.saveChanges((current) => current.copyWith(useDoh: result.enabled, useBuiltInHosts: result.enabled ? false : current.useBuiltInHosts, dohPreset: result.preset, dohCustomUrl: result.customUrl, dohBootstrapIps: result.bootstrapIps, dohTimeoutSeconds: result.timeoutSeconds));
  }

}

const _dohPresets = {'alidns': 'AliDNS', 'dnspod': 'DNSPod', 'cloudflare': 'Cloudflare'};

class _DohSettings { const _DohSettings({required this.enabled, required this.preset, required this.customUrl, required this.bootstrapIps, required this.timeoutSeconds}); final bool enabled; final String preset; final String customUrl; final String bootstrapIps; final int timeoutSeconds; }

class _DohSettingsDialog extends StatefulWidget { const _DohSettingsDialog({required this.settings}); final AppSettings settings; @override State<_DohSettingsDialog> createState() => _DohSettingsDialogState(); }

class _DohSettingsDialogState extends State<_DohSettingsDialog> {
  late var _enabled = widget.settings.useDoh;
  late var _preset = widget.settings.dohPreset;
  late final _customUrl = TextEditingController(text: widget.settings.dohCustomUrl);
  late final _bootstrapIps = TextEditingController(text: widget.settings.dohBootstrapIps);
  late final _timeout = TextEditingController(text: widget.settings.dohTimeoutSeconds.toString());
  @override void dispose() { _customUrl.dispose(); _bootstrapIps.dispose(); _timeout.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!; return AlertDialog(title: Text(l10n.dohSettings), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(l10n.useDoh), value: _enabled, onChanged: (value) => setState(() => _enabled = value)), DropdownButtonFormField(value: _preset, decoration: InputDecoration(labelText: l10n.dohPreset), items: [..._dohPresets.entries.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value))), DropdownMenuItem(value: 'custom', child: Text(l10n.custom))], onChanged: (value) => setState(() => _preset = value!)), const SizedBox(height: 12), TextField(controller: _customUrl, enabled: _preset == 'custom', keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.dohCustomUrl)), const SizedBox(height: 12), TextField(controller: _bootstrapIps, decoration: InputDecoration(labelText: l10n.dohBootstrapIps, helperText: l10n.dohBootstrapIpsDescription)), const SizedBox(height: 12), TextField(controller: _timeout, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.dohTimeoutSeconds, helperText: l10n.dohTimeoutSecondsDescription))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, _DohSettings(enabled: _enabled, preset: _preset, customUrl: _customUrl.text.trim(), bootstrapIps: _bootstrapIps.text.trim(), timeoutSeconds: (int.tryParse(_timeout.text) ?? 10).clamp(1, 60) as int)), child: Text(l10n.save))]); }
}

class _MirrorSettings { const _MirrorSettings({required this.enabled, required this.url, required this.appendPath}); final bool enabled; final String url; final bool appendPath; }

class _MirrorSettingsDialog extends StatefulWidget { const _MirrorSettingsDialog({required this.settings}); final AppSettings settings; @override State<_MirrorSettingsDialog> createState() => _MirrorSettingsDialogState(); }

class _MirrorSettingsDialogState extends State<_MirrorSettingsDialog> {
  late var _enabled = widget.settings.useCustomMirrorSite;
  late final _url = TextEditingController(text: widget.settings.customMirrorSite);
  late var _appendPath = widget.settings.appendCustomMirrorPath;
  var _testing = false;
  String? _testResult;
  @override void dispose() { _url.dispose(); super.dispose(); }

  Future<void> _testConnection(AppLocalizations l10n) async {
    final url = _url.text.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.hasQuery || uri.hasFragment) {
      setState(() => _testResult = l10n.customMirrorSiteInvalid);
      return;
    }
    setState(() { _testing = true; _testResult = null; });
    final result = await _testMirror(url, l10n);
    if (!mounted) return;
    setState(() { _testing = false; _testResult = result; });
  }

  Future<String> _testMirror(String homeUrl, AppLocalizations l10n) async {
    final apiBase = _appendPath ? homeUrl : Uri.parse(homeUrl).origin;
    final http = Han1meHttpClient();
    try {
      final home = await http.get('$homeUrl/');
      if (home.statusCode >= 400) return l10n.customMirrorTestFailedHttp(home.statusCode, home.url);
      if (home.statusCode == 403 || home.body.contains('cf-chl-')) return l10n.customMirrorTestChallenge;
      if (!home.body.contains('home-rows-wrapper')) return l10n.customMirrorTestParseFailed;
      final search = await http.get('$apiBase/search');
      if (search.statusCode >= 400) return l10n.customMirrorTestPartialSuccess(apiBase, search.statusCode);
      return l10n.customMirrorTestSuccess(home.url, apiBase);
    } catch (error) {
      return l10n.customMirrorTestFailed(error.toString());
    }
  }

  void _save(AppLocalizations l10n) {
    final url = _url.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (_enabled && !_validMirrorUrl(url)) {
      setState(() => _testResult = l10n.customMirrorSiteInvalid);
      return;
    }
    Navigator.pop(context, _MirrorSettings(enabled: _enabled, url: url, appendPath: _appendPath));
  }

  bool _validMirrorUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && !uri.hasQuery && !uri.hasFragment;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.customMirrorSite),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(l10n.enableCustomMirrorSite), value: _enabled, onChanged: (value) => setState(() => _enabled = value)),
        TextField(controller: _url, enabled: _enabled, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.customMirrorSite, helperText: l10n.customMirrorSiteHint)),
        const SizedBox(height: 12),
        if (_enabled) ...[
          Text(l10n.customMirrorApiPathMode, style: Theme.of(context).textTheme.titleSmall),
          RadioListTile<bool>(contentPadding: EdgeInsets.zero, dense: true, value: true, groupValue: _appendPath, title: Text(l10n.customMirrorPathFollowHome), subtitle: Text(l10n.customMirrorPathFollowHomeSummary), onChanged: (value) => setState(() => _appendPath = value!)),
          RadioListTile<bool>(contentPadding: EdgeInsets.zero, dense: true, value: false, groupValue: _appendPath, title: Text(l10n.customMirrorPathRoot), subtitle: Text(l10n.customMirrorPathRootSummary), onChanged: (value) => setState(() => _appendPath = value!)),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _testing ? null : () => _testConnection(l10n), icon: _testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check_outlined), label: Text(l10n.testConnection))),
          if (_testResult != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_testResult!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => _save(l10n), child: Text(l10n.save))],
    );
  }
}

class _PathDialog extends StatefulWidget { const _PathDialog({required this.title, required this.initialPath}); final String title; final String initialPath; @override State<_PathDialog> createState() => _PathDialogState(); }
class _PathDialogState extends State<_PathDialog> { late final _controller = TextEditingController(text: widget.initialPath); @override void dispose() { _controller.dispose(); super.dispose(); } Future<void> _browse() async { final selected = await FilePicker.platform.getDirectoryPath(dialogTitle: widget.title, initialDirectory: _controller.text.trim().isEmpty ? null : _controller.text.trim()); if (selected != null) setState(() => _controller.text = selected); } @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!; return AlertDialog(title: Text(widget.title), content: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: _controller, autofocus: true, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.downloadPath, hintText: platformDownloadPathHint(l10n.defaultDownloadPath)))), const SizedBox(width: 8), IconButton(tooltip: l10n.chooseFolder, onPressed: _browse, icon: const Icon(Icons.folder_open_outlined))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(l10n.save))]); } }

class _SliderTile extends SettingsSliderItem {
  _SliderTile({required IconData icon, required String title, String? subtitle, required double value, required double min, required double max, required int divisions, required String label, required ValueChanged<double> onChanged})
      : super(leading: Icon(icon), title: title, subtitle: subtitle, value: value, min: min, max: max, divisions: divisions, label: label, onChanged: onChanged);
}


extension on String { String ifEmpty(String fallback) => isEmpty ? fallback : this; }
