import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';

import '../../core/settings.dart';
import '../../data/remote/update_checker.dart';
import '../../data/local/update_installer.dart';
import '../account/account_controller.dart';
import '../explore/explore_controller.dart';
import 'settings_controller.dart';
import 'cloudflare_page.dart';
import 'keyframes_page.dart';
import 'playback_settings_page.dart';
import 'privacy_settings_page.dart';
import 'comment_settings_page.dart';
import 'danmaku_settings_page.dart';
import 'deep_link_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  static const _hosts = ['https://hanime1.com', 'https://hanimeone.me', 'https://hanime1.me', 'https://javchu.com'];
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
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.themeColor),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemePalette(context, settings.themeColor, (value) => controller.saveChanges((current) => current.copyWith(themeColor: value))),
        ),
         ListTile(leading: const Icon(Icons.wallpaper_outlined), title: Text(l10n.monetColors), subtitle: Text(l10n.monetColorsDescription), onTap: () => controller.saveChanges((current) => current.copyWith(useMonetColors: !current.useMonetColors)), trailing: Switch(value: settings.useMonetColors, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useMonetColors: value)))),
         ListTile(leading: const Icon(Icons.contrast_outlined), title: Text(l10n.amoledMode), subtitle: Text(l10n.amoledModeDescription), onTap: () => controller.saveChanges((current) => current.copyWith(amoledMode: !current.amoledMode)), trailing: Switch(value: settings.amoledMode, onChanged: (value) => controller.saveChanges((current) => current.copyWith(amoledMode: value)))),
         _SectionLabel(l10n.playback),
         ListTile(leading: const Icon(Icons.tune_outlined), title: Text(l10n.playbackSettings), subtitle: Text(l10n.playbackSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlaybackSettingsPage()))),
        ListTile(leading: const Icon(Icons.smart_display_outlined), title: Text(l10n.playerEngine), subtitle: const Text('ExoPlayer')),
        _PickerTile<int>(icon: Icons.hd_outlined, title: l10n.preferredQuality, value: settings.preferredQuality, items: const {480: '480P', 720: '720P', 1080: '1080P'}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(preferredQuality: value))),
        ListTile(leading: const Icon(Icons.play_circle_outline), title: Text(l10n.resumePlayback), subtitle: Text(l10n.resumePlaybackDescription), onTap: () => controller.saveChanges((current) => current.copyWith(resumePlayback: !current.resumePlayback)), trailing: Switch(value: settings.resumePlayback, onChanged: (value) => controller.saveChanges((current) => current.copyWith(resumePlayback: value)))),
         ListTile(leading: const Icon(Icons.key_outlined), title: Text(l10n.keyframeSettings), subtitle: Text(l10n.keyframeSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KeyframesPage()))),
         _SectionLabel(l10n.network),
         ListTile(leading: const Icon(Icons.dns_outlined), title: Text(l10n.useBuiltInHosts), subtitle: Text(l10n.useBuiltInHostsDescription), onTap: () => controller.saveChanges((current) => current.copyWith(useBuiltInHosts: !current.useBuiltInHosts, useDoh: current.useBuiltInHosts ? current.useDoh : false)), trailing: Switch(value: settings.useBuiltInHosts, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useBuiltInHosts: value, useDoh: value ? false : current.useDoh)))),
         ListTile(leading: const Icon(Icons.security_outlined), title: Text(l10n.doh), subtitle: Text(_dohSummary(l10n, settings)), trailing: const Icon(Icons.chevron_right), onTap: () => _showDohSettings(context, settings, controller)),
          _SectionLabel(l10n.content),
          ListTile(leading: const Icon(Icons.menu_book_outlined), title: Text(l10n.comicMode), subtitle: Text(l10n.comicModeDescription), onTap: () => _switchComicMode(ref, controller, !settings.comicMode), trailing: Switch(value: settings.comicMode, onChanged: (value) => _switchComicMode(ref, controller, value))),
          ListTile(leading: const Icon(Icons.view_stream_outlined), title: Text(l10n.horizontalSearchCards), subtitle: Text(l10n.horizontalSearchCardsDescription), onTap: () => controller.saveChanges((current) => current.copyWith(useHorizontalSearchCards: !current.useHorizontalSearchCards)), trailing: Switch(value: settings.useHorizontalSearchCards, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useHorizontalSearchCards: value)))),
          _PickerTile<int>(icon: Icons.grid_view_outlined, title: l10n.searchCardsPerRow, value: settings.searchCardsPerRow, items: {for (final count in [1, 2, 3]) count: l10n.searchCardsPerRowValue(count)}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(searchCardsPerRow: value))),
            ListTile(leading: const Icon(Icons.forum_outlined), title: Text(l10n.commentSettings), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CommentSettingsPage()))),
          ListTile(leading: const Icon(Icons.subtitles_outlined), title: Text(l10n.danmakuSettings), subtitle: Text(l10n.danmakuSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DanmakuSettingsPage()))),
         ListTile(leading: const Icon(Icons.download_outlined), title: Text(l10n.downloadSettings), subtitle: Text(l10n.downloadSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/downloads')),
        _PickerTile<AppLanguage>(icon: Icons.language_outlined, title: l10n.languageSettings, value: settings.language, items: {AppLanguage.system: l10n.systemDefault, AppLanguage.simplifiedChinese: l10n.simplifiedChinese, AppLanguage.traditionalChinese: l10n.traditionalChinese}, onChanged: (value) => controller.saveChanges((current) => current.copyWith(language: value))),
         _PickerTile<String>(icon: Icons.language_outlined, title: l10n.site, value: settings.comicMode ? 'https://hanimeone.me' : settings.baseUrl, items: {for (final host in settings.comicMode ? const ['https://hanimeone.me'] : _hosts) host: host}, onChanged: (value) => _switchSite(ref, controller, value)),
        ListTile(leading: const Icon(Icons.security_outlined), title: Text(l10n.cloudflareVerification), subtitle: Text(l10n.cloudflareVerificationDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CloudflarePage()))),
        ListTile(leading: const Icon(Icons.autorenew_outlined), title: Text(l10n.autoCheckUpdates), onTap: () => controller.saveChanges((current) => current.copyWith(autoUpdate: !current.autoUpdate)), trailing: Switch(value: settings.autoUpdate, onChanged: (value) => controller.saveChanges((current) => current.copyWith(autoUpdate: value)))),
        ListTile(leading: const Icon(Icons.system_update_outlined), title: Text(l10n.checkUpdates), trailing: const Icon(Icons.chevron_right), onTap: () => _checkUpdate(context)),
         _SectionLabel(l10n.application),
         ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: Text(l10n.privacySettings), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrivacySettingsPage()))),
         ListTile(leading: const Icon(Icons.link_outlined), title: Text(l10n.deepLinkSettings), subtitle: Text(l10n.deepLinkSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DeepLinkSettingsPage()))),
        ListTile(leading: const Icon(Icons.info_outline), title: Text(l10n.about), subtitle: Text(l10n.aboutDescription), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/about')),
      ]),
    );
  }

  Future<void> _switchSite(WidgetRef ref, SettingsController controller, String baseUrl) async {
    await controller.saveChanges((current) => current.copyWith(baseUrl: baseUrl, videoBaseUrl: current.comicMode ? current.videoBaseUrl : baseUrl));
    ref.invalidate(accountProvider);
    ref.invalidate(homeSectionsProvider);
  }

  String _dohSummary(AppLocalizations l10n, AppSettings settings) {
    if (!settings.useDoh) return l10n.dohDisabled;
    return settings.dohPreset == 'custom' ? settings.dohCustomUrl.ifEmpty(l10n.custom) : _dohPresets[settings.dohPreset]!;
  }

  Future<void> _showDohSettings(BuildContext context, AppSettings settings, SettingsController controller) async {
    final result = await showDialog<_DohSettings>(context: context, builder: (_) => _DohSettingsDialog(settings: settings));
    if (result == null) return;
    await controller.saveChanges((current) => current.copyWith(useDoh: result.enabled, useBuiltInHosts: result.enabled ? false : current.useBuiltInHosts, dohPreset: result.preset, dohCustomUrl: result.customUrl, dohBootstrapIps: result.bootstrapIps, dohTimeoutSeconds: result.timeoutSeconds));
  }

  Future<void> _switchComicMode(WidgetRef ref, SettingsController controller, bool enabled) async {
    await controller.saveChanges((current) => current.copyWith(comicMode: enabled, baseUrl: enabled ? 'https://hanimeone.me' : current.videoBaseUrl, videoBaseUrl: enabled ? current.baseUrl : current.videoBaseUrl));
    ref.invalidate(homeSectionsProvider);
  }

  Future<void> _showThemePalette(BuildContext context, AppThemeColor selected, ValueChanged<AppThemeColor> onChanged) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _ThemePalette(
            value: selected,
            onChanged: (value) {
              onChanged(value);
              Navigator.of(sheetContext).pop();
            },
          ),
        ),
      ),
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

const _dohPresets = {'alidns': 'AliDNS', 'dnspod': 'DNSPod', 'cloudflare': 'Cloudflare'};

class _DohSettings {
  const _DohSettings({required this.enabled, required this.preset, required this.customUrl, required this.bootstrapIps, required this.timeoutSeconds});
  final bool enabled;
  final String preset;
  final String customUrl;
  final String bootstrapIps;
  final int timeoutSeconds;
}

class _DohSettingsDialog extends StatefulWidget {
  const _DohSettingsDialog({required this.settings});
  final AppSettings settings;

  @override
  State<_DohSettingsDialog> createState() => _DohSettingsDialogState();
}

class _DohSettingsDialogState extends State<_DohSettingsDialog> {
  late var _enabled = widget.settings.useDoh;
  late var _preset = widget.settings.dohPreset;
  late final _customUrl = TextEditingController(text: widget.settings.dohCustomUrl);
  late final _bootstrapIps = TextEditingController(text: widget.settings.dohBootstrapIps);
  late final _timeout = TextEditingController(text: widget.settings.dohTimeoutSeconds.toString());

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
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(l10n.useDoh), value: _enabled, onChanged: (value) => setState(() => _enabled = value)),
            DropdownButtonFormField<String>(value: _preset, decoration: InputDecoration(labelText: l10n.dohPreset), items: [..._dohPresets.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))), DropdownMenuItem(value: 'custom', child: Text(l10n.custom))], onChanged: (value) => setState(() => _preset = value!)),
            const SizedBox(height: 12),
            TextField(controller: _customUrl, enabled: _preset == 'custom', keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.dohCustomUrl), maxLines: 1),
            const SizedBox(height: 12),
            TextField(controller: _bootstrapIps, decoration: InputDecoration(labelText: l10n.dohBootstrapIps, helperText: l10n.dohBootstrapIpsDescription)),
            const SizedBox(height: 12),
            TextField(controller: _timeout, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.dohTimeoutSeconds, helperText: l10n.dohTimeoutSecondsDescription), maxLines: 1),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _DohSettings(enabled: _enabled, preset: _preset, customUrl: _customUrl.text.trim(), bootstrapIps: _bootstrapIps.text.trim(), timeoutSeconds: (int.tryParse(_timeout.text) ?? 10).clamp(1, 60) as int)), child: Text(l10n.save)),
      ],
    );
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _ThemePalette extends StatelessWidget {
  const _ThemePalette({required this.value, required this.onChanged});
  final AppThemeColor value;
  final ValueChanged<AppThemeColor> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: AppThemeColor.values.map((color) => _MiniPalette(selected: color == value, colors: color.palette, onTap: () => onChanged(color))).toList(),
      );
}

class _MiniPalette extends StatelessWidget {
  const _MiniPalette({required this.selected, required this.colors, required this.onTap});
  final bool selected;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: colors.first.value.toRadixString(16),
        child: InkResponse(
          onTap: onTap,
          radius: 38,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors[0]),
                    Align(alignment: Alignment.bottomLeft, child: FractionallySizedBox(widthFactor: .55, heightFactor: .48, child: ColoredBox(color: colors[1]))),
                    Align(alignment: Alignment.bottomRight, child: FractionallySizedBox(widthFactor: .55, heightFactor: .48, child: ColoredBox(color: colors[2]))),
                    if (selected) Center(child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.check, size: 20, color: Theme.of(context).colorScheme.onPrimary)))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

extension on AppThemeColor {
  List<Color> get palette => switch (this) {
    AppThemeColor.rose => const [Color(0xffd35c87), Color(0xffffd9e4), Color(0xffffb0c7)],
    AppThemeColor.blue => const [Color(0xff2775b5), Color(0xffd5e7ff), Color(0xff9ccaff)],
    AppThemeColor.teal => const [Color(0xff1e8073), Color(0xffb9f1e5), Color(0xff7ed6c7)],
    AppThemeColor.amber => const [Color(0xffae7500), Color(0xffffe9b5), Color(0xffffce6e)],
    AppThemeColor.green => const [Color(0xff4c8529), Color(0xffd0f6b4), Color(0xffa5de82)],
    AppThemeColor.orange => const [Color(0xffbc5700), Color(0xffffddb9), Color(0xffffb77c)],
    AppThemeColor.indigo => const [Color(0xff687cbf), Color(0xffdce2ff), Color(0xffbdc7ff)],
    AppThemeColor.pink => const [Color(0xffc04d80), Color(0xffffd9e6), Color(0xffffaec9)],
    AppThemeColor.purple => const [Color(0xff8c5ab0), Color(0xfff0d8ff), Color(0xffdfb5ff)],
  };
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
