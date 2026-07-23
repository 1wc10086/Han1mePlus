import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import '../../data/local/download_repository.dart';
import '../account/account_controller.dart';
import '../explore/explore_controller.dart';
import 'settings_controller.dart';

class NetworkSettingsPage extends ConsumerWidget {
  const NetworkSettingsPage({super.key});
  static const _hosts = ['https://hanime1.com', 'https://hanimeone.me', 'https://hanime1.me', 'https://javchu.com'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.networkSettings)), body: ListView(children: [
      _SectionLabel(l10n.general),
      ListTile(leading: const Icon(Icons.language_outlined), title: Text(l10n.site), subtitle: Text(settings.comicMode ? 'https://hanimeone.me' : settings.baseUrl), trailing: const Icon(Icons.chevron_right), onTap: () => _showSitePicker(context, ref, settings, controller)),
      SwitchListTile(secondary: const Icon(Icons.dns_outlined), title: Text(l10n.useBuiltInHosts), subtitle: Text(l10n.useBuiltInHostsDescription), value: settings.useBuiltInHosts, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useBuiltInHosts: value, useDoh: value ? false : current.useDoh))),
       ListTile(leading: const Icon(Icons.security_outlined), title: Text(l10n.doh), subtitle: Text(_dohSummary(l10n, settings)), trailing: const Icon(Icons.chevron_right), onTap: () => _showDohSettings(context, settings, controller)),
       _SectionLabel(l10n.downloadSettings),
       ListTile(leading: const Icon(Icons.folder_outlined), title: Text(l10n.downloadPath), subtitle: Text(settings.downloadPath), trailing: const Icon(Icons.chevron_right), onTap: () => _editDownloadPath(context, settings, controller)),
       ListTile(leading: const Icon(Icons.drive_folder_upload_outlined), title: Text(l10n.exportDownloads), subtitle: Text(l10n.exportDownloadsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => _exportDownloads(context, ref)),
       _SliderTile(icon: Icons.speed_outlined, title: l10n.downloadSpeedLimit, value: settings.downloadSpeedLimitMbps, min: 0, max: 20, divisions: 40, label: settings.downloadSpeedLimitMbps == 0 ? l10n.unlimited : '${settings.downloadSpeedLimitMbps.toStringAsFixed(1)} MB/s', onChanged: (value) => controller.saveChanges((current) => current.copyWith(downloadSpeedLimitMbps: value))),
      _SliderTile(icon: Icons.download_for_offline_outlined, title: l10n.concurrentDownloads, subtitle: l10n.concurrentDownloadsDescription(settings.concurrentDownloads), value: settings.concurrentDownloads.toDouble(), min: 1, max: 5, divisions: 4, label: '${settings.concurrentDownloads}', onChanged: (value) => controller.saveChanges((current) => current.copyWith(concurrentDownloads: value.round()))),
    ]));
  }

  Future<void> _editDownloadPath(BuildContext context, AppSettings settings, SettingsController controller) async {
    final path = await showDialog<String>(context: context, builder: (_) => _PathDialog(title: AppLocalizations.of(context)!.downloadPath, initialPath: settings.downloadPath));
    if (path == null) return;
    await controller.saveChanges((current) => current.copyWith(downloadPath: path));
  }

  Future<void> _exportDownloads(BuildContext context, WidgetRef ref) async {
    final path = await showDialog<String>(context: context, builder: (_) => _PathDialog(title: AppLocalizations.of(context)!.exportDownloads, initialPath: ''));
    if (path == null || path.isEmpty) return;
    await ref.read(downloadProvider.notifier).exportCompleted(path);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.exportCompleted)));
  }

  Future<void> _showSitePicker(BuildContext context, WidgetRef ref, AppSettings settings, SettingsController controller) async {
    final current = settings.comicMode ? 'https://hanimeone.me' : settings.baseUrl;
    final selected = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final host in settings.comicMode ? const ['https://hanimeone.me'] : _hosts) RadioListTile(value: host, groupValue: current, title: Text(host), onChanged: (value) => Navigator.pop(context, value))])));
    if (selected == null) return;
    await controller.saveChanges((current) => current.copyWith(baseUrl: selected, videoBaseUrl: current.comicMode ? current.videoBaseUrl : selected));
    ref.invalidate(accountProvider);
    ref.invalidate(homeSectionsProvider);
  }

  String _dohSummary(AppLocalizations l10n, AppSettings settings) => !settings.useDoh ? l10n.dohDisabled : settings.dohPreset == 'custom' ? settings.dohCustomUrl.ifEmpty(l10n.custom) : _dohPresets[settings.dohPreset]!;

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

class _PathDialog extends StatefulWidget { const _PathDialog({required this.title, required this.initialPath}); final String title; final String initialPath; @override State<_PathDialog> createState() => _PathDialogState(); }
class _PathDialogState extends State<_PathDialog> { late final _controller = TextEditingController(text: widget.initialPath); @override void dispose() { _controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!; return AlertDialog(title: Text(widget.title), content: TextField(controller: _controller, autofocus: true, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.downloadPath, hintText: l10n.defaultDownloadPath)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(l10n.save))]); } }

class _SliderTile extends StatelessWidget { const _SliderTile({required this.icon, required this.title, this.subtitle, required this.value, required this.min, required this.max, required this.divisions, required this.label, required this.onChanged}); final IconData icon; final String title; final String? subtitle; final double value; final double min; final double max; final int divisions; final String label; final ValueChanged<double> onChanged; @override Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(title), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (subtitle != null) Text(subtitle!), Slider(value: value, min: min, max: max, divisions: divisions, label: label, onChanged: onChanged)]), trailing: Text(label)); }

class _SectionLabel extends StatelessWidget { const _SectionLabel(this.text); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary))); }

extension on String { String ifEmpty(String fallback) => isEmpty ? fallback : this; }
