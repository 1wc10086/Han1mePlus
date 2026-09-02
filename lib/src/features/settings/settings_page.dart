import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:card_settings_ui/list/settings_list.dart';
import 'package:card_settings_ui/section/settings_section.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_shell.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Text sectionTitle(String value) => Text(value, style: TextStyle(color: Theme.of(context).colorScheme.primary));
    return Scaffold(
        appBar: AppBar(leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? (permanentNavigationDrawer(context) ? null : IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu))) : null, title: Text(l10n.settings)),
      body: SettingsList(
        contentPadding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        sections: [
          SettingsSection(title: sectionTitle(l10n.appearance), tiles: [
            _NavigationTile(icon: Icons.palette_outlined, title: l10n.themeAndColor, onTap: () => context.push('/settings/theme')).tile,
            _NavigationTile(icon: Icons.dashboard_customize_outlined, title: l10n.interfaceLayout, onTap: () => context.push('/settings/layout')).tile,
          ]),
          SettingsSection(title: sectionTitle(l10n.playback), tiles: [
            _NavigationTile(icon: Icons.smart_display_outlined, title: l10n.playbackSettings, onTap: () => context.push('/settings/playback')).tile,
          ]),
          SettingsSection(title: sectionTitle(l10n.network), tiles: [
            _NavigationTile(icon: Icons.language_outlined, title: l10n.networkSettings, onTap: () => context.push('/settings/network')).tile,
            _NavigationTile(icon: Icons.cloud_sync_outlined, title: l10n.webDavSettings, onTap: () => context.push('/settings/webdav')).tile,
          ]),
          SettingsSection(title: sectionTitle(l10n.content), tiles: [
            _NavigationTile(icon: Icons.forum_outlined, title: l10n.commentSettings, onTap: () => context.push('/settings/comments')).tile,
            _NavigationTile(icon: Icons.language_outlined, title: l10n.languageSettings, onTap: () => context.push('/settings/language')).tile,
          ]),
          SettingsSection(title: sectionTitle(l10n.application), tiles: [
            _NavigationTile(icon: Icons.apps_outlined, title: l10n.applicationSettings, onTap: () => context.push('/settings/application')).tile,
          ]),
          SettingsSection(title: sectionTitle(l10n.other), tiles: [
            _NavigationTile(icon: Icons.info_outline, title: l10n.about, onTap: () => context.push('/settings/about')).tile,
          ]),
        ],
      ),
    );
  }

}

class _NavigationTile extends SettingsCardItem {
  _NavigationTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap})
      : super(title: title, subtitle: subtitle, leading: Icon(icon), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}
