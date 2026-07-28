import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import '../../core/app_shell.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null, title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionLabel(l10n.appearance),
          _NavigationTile(icon: Icons.palette_outlined, title: l10n.themeAndColor, onTap: () => context.push('/settings/theme')),
          _NavigationTile(icon: Icons.dashboard_customize_outlined, title: l10n.interfaceLayout, onTap: () => context.push('/settings/layout')),
          _SectionLabel(l10n.playback),
          _NavigationTile(icon: Icons.smart_display_outlined, title: l10n.playbackSettings, subtitle: l10n.playbackSettingsDescription, onTap: () => context.push('/settings/playback')),
          _SectionLabel(l10n.network),
          _NavigationTile(icon: Icons.language_outlined, title: l10n.networkSettings, onTap: () => context.push('/settings/network')),
          _SectionLabel(l10n.content),
          _NavigationTile(icon: Icons.forum_outlined, title: l10n.commentSettings, onTap: () => context.push('/settings/comments')),
          _NavigationTile(icon: Icons.language_outlined, title: l10n.languageSettings, onTap: () => _showLanguagePicker(context, ref)),
          _SectionLabel(l10n.application),
          _NavigationTile(icon: Icons.apps_outlined, title: l10n.applicationSettings, subtitle: l10n.applicationSettingsDescription, onTap: () => context.push('/settings/application')),
          _SectionLabel(l10n.other),
          _NavigationTile(icon: Icons.info_outline, title: l10n.about, subtitle: l10n.aboutDescription, onTap: () => context.push('/settings/about')),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(settingsProvider).valueOrNull?.language ?? AppLanguage.system;
    final selected = await showModalBottomSheet<AppLanguage>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [RadioListTile(value: AppLanguage.system, groupValue: current, title: Text(l10n.systemDefault), onChanged: (value) => Navigator.pop(context, value)), RadioListTile(value: AppLanguage.simplifiedChinese, groupValue: current, title: Text(l10n.simplifiedChinese), onChanged: (value) => Navigator.pop(context, value)), RadioListTile(value: AppLanguage.traditionalChinese, groupValue: current, title: Text(l10n.traditionalChinese), onChanged: (value) => Navigator.pop(context, value))])));
    if (selected != null) await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(language: selected));
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(title), subtitle: subtitle == null ? null : Text(subtitle!), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)));
}
