import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';

import '../../core/settings.dart';
import '../../data/remote/update_checker.dart';
import '../../data/local/update_installer.dart';
import 'settings_controller.dart';
import 'cloudflare_page.dart';
import 'keyframes_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  static const _hosts = ['https://hanimeone.me', 'https://hanime1.com', 'https://hanime1.me', 'https://javchu.com'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(children: [
        _SectionLabel(l10n.appearance),
        _PickerTile<AppThemeMode>(icon: Icons.brightness_6_outlined, title: l10n.themeMode, value: settings.themeMode, items: {AppThemeMode.system: l10n.followSystem, AppThemeMode.light: l10n.light, AppThemeMode.dark: l10n.dark}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(themeMode: value))),
         _PickerTile<AppThemeColor>(icon: Icons.palette_outlined, title: l10n.themeColor, value: settings.themeColor, items: {AppThemeColor.rose: l10n.rose, AppThemeColor.blue: l10n.blue, AppThemeColor.teal: l10n.teal, AppThemeColor.amber: l10n.amber, AppThemeColor.green: l10n.forestGreen, AppThemeColor.orange: l10n.orange, AppThemeColor.indigo: l10n.indigo, AppThemeColor.pink: l10n.pink, AppThemeColor.purple: l10n.purple}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(themeColor: value))),
         ListTile(leading: const Icon(Icons.wallpaper_outlined), title: Text(l10n.monetColors), subtitle: Text(l10n.monetColorsDescription), onTap: () => controller.saveChanges((current) => current.copyWith(useMonetColors: !current.useMonetColors)), trailing: Switch(value: settings.useMonetColors, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useMonetColors: value)))),
         ListTile(leading: const Icon(Icons.contrast_outlined), title: Text(l10n.amoledMode), subtitle: Text(l10n.amoledModeDescription), onTap: () => controller.saveChanges((current) => current.copyWith(amoledMode: !current.amoledMode)), trailing: Switch(value: settings.amoledMode, onChanged: (value) => controller.saveChanges((current) => current.copyWith(amoledMode: value)))),
        _SectionLabel(l10n.playback),
        ListTile(leading: const Icon(Icons.smart_display_outlined), title: Text(l10n.playerEngine), subtitle: const Text('ExoPlayer')),
        _PickerTile<int>(icon: Icons.hd_outlined, title: l10n.preferredQuality, value: settings.preferredQuality, items: const {480: '480P', 720: '720P', 1080: '1080P'}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(preferredQuality: value))),
        ListTile(leading: const Icon(Icons.play_circle_outline), title: Text(l10n.resumePlayback), subtitle: Text(l10n.resumePlaybackDescription), onTap: () => controller.saveChanges((current) => current.copyWith(resumePlayback: !current.resumePlayback)), trailing: Switch(value: settings.resumePlayback, onChanged: (value) => controller.saveChanges((current) => current.copyWith(resumePlayback: value)))),
        ListTile(leading: const Icon(Icons.key_outlined), title: Text(l10n.keyframeSettings), subtitle: Text(l10n.keyframeSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KeyframesPage()))),
         _SectionLabel(l10n.content),
         ListTile(leading: const Icon(Icons.download_outlined), title: Text(l10n.downloadSettings), subtitle: Text(l10n.downloadSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/downloads')),
        _PickerTile<AppLanguage>(icon: Icons.language_outlined, title: l10n.languageSettings, value: settings.language, items: {AppLanguage.system: l10n.systemDefault, AppLanguage.simplifiedChinese: l10n.simplifiedChinese, AppLanguage.traditionalChinese: l10n.traditionalChinese}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(language: value))),
        _PickerTile<String>(icon: Icons.language_outlined, title: l10n.site, value: settings.baseUrl, items: {for (final host in _hosts) host: host}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(baseUrl: value))),
        ListTile(leading: const Icon(Icons.security_outlined), title: Text(l10n.cloudflareVerification), subtitle: Text(l10n.cloudflareVerificationDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CloudflarePage()))),
        ListTile(leading: const Icon(Icons.autorenew_outlined), title: Text(l10n.autoCheckUpdates), onTap: () => controller.saveChanges((current) => current.copyWith(autoUpdate: !current.autoUpdate)), trailing: Switch(value: settings.autoUpdate, onChanged: (value) => controller.saveChanges((current) => current.copyWith(autoUpdate: value)))),
        ListTile(leading: const Icon(Icons.system_update_outlined), title: Text(l10n.checkUpdates), trailing: const Icon(Icons.chevron_right), onTap: () => _checkUpdate(context)),
        _SectionLabel(l10n.application),
        ListTile(leading: const Icon(Icons.info_outline), title: Text(l10n.about), subtitle: Text(l10n.aboutDescription), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/about')),
      ]),
    );
  }

  Future<void> _checkUpdate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final update = await UpdateChecker(Dio()).check();
    if (!context.mounted) return;
    if (update == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.latestVersion)));
      return;
    }
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.newVersionAvailable(update.tagName)), content: Text(update.body.isEmpty ? l10n.newVersionReleased : update.body), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.later)), FilledButton(onPressed: () async { Navigator.pop(dialogContext); await _installUpdate(context, update.downloadUrl); }, child: Text(l10n.updateNow))]));
  }

  Future<void> _installUpdate(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noInstallableApk)));
      return;
    }
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDownloadDialog(url: url),
    );
    if (completed == false && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.updateIncomplete)));
  }
}

class _PickerTile<T> extends StatelessWidget {
  const _PickerTile({required this.icon, required this.title, required this.value, required this.items, required this.onChanged});
  final IconData icon;
  final String title;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(items[value]!),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final selected = await showModalBottomSheet<T>(context: context, showDragHandle: true, constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7), builder: (sheetContext) => SafeArea(child: ListView(shrinkWrap: true, children: items.entries.map((item) => RadioListTile<T>(value: item.key, groupValue: value, title: Text(item.value), onChanged: (next) => Navigator.pop(sheetContext, next))).toList())));
          if (selected != null) onChanged(selected);
        },
      );
}

class _UpdateDownloadDialog extends StatefulWidget {
  const _UpdateDownloadDialog({required this.url});
  final String url;

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  double? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      await UpdateInstaller(Dio()).downloadAndInstall(widget.url, (value) {
        if (mounted) setState(() => _progress = value);
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.downloadingUpdate),
        content: _error == null
            ? Column(mainAxisSize: MainAxisSize.min, children: [LinearProgressIndicator(value: _progress), const SizedBox(height: 12), Text(_progress == null ? AppLocalizations.of(context)!.connecting : '${(_progress! * 100).toStringAsFixed(0)}%')])
            : Text(AppLocalizations.of(context)!.updateFailed(_error.toString())),
        actions: _error == null ? null : [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.close))],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)));
}
