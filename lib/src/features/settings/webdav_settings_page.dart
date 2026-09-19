import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/local/watch_repository.dart';
import '../../data/local/webdav_sync_service.dart';
import '../../data/local/library_repository.dart';
import '../../core/settings.dart';
import 'settings_card_list.dart';
import 'settings_controller.dart';

class WebDavSettingsPage extends ConsumerWidget {
  const WebDavSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.webDavSettings)), body: ListView(children: [SettingsCardList(title: l10n.webDav, children: [
      SettingsCardItem(title: l10n.webDavSync, leading: const Icon(Icons.cloud_sync_outlined), trailing: Switch(value: settings.webDavEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(webDavEnabled: value, webDavHistorySync: value ? current.webDavHistorySync : false, webDavFavoriteSync: value ? current.webDavFavoriteSync : false)))),
      SettingsCardItem(title: l10n.watchHistorySync, leading: const Icon(Icons.history_outlined), trailing: Switch(value: settings.webDavHistorySync, onChanged: settings.webDavEnabled ? (value) => controller.saveChanges((current) => current.copyWith(webDavHistorySync: value)) : null)),
      SettingsCardItem(title: l10n.favoriteSync, leading: const Icon(Icons.favorite_outline), trailing: Switch(value: settings.webDavFavoriteSync, onChanged: settings.webDavEnabled ? (value) => controller.saveChanges((current) => current.copyWith(webDavFavoriteSync: value)) : null)),
      SettingsCardItem(title: l10n.webDavConfiguration, leading: const Icon(Icons.settings_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/webdav/configuration')),
      SettingsCardItem(title: l10n.syncWatchHistoryNow, leading: const Icon(Icons.sync_outlined), onTap: () => _sync(context, ref, settings)),
    ])]));
  }

  Future<void> _sync(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final l10n = AppLocalizations.of(context)!;
    if (!settings.webDavEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.webDavDisabled)));
      return;
    }
    try {
      final service = WebDavSyncService(Dio());
      final local = await ref.read(watchProvider.future);
      final merged = await service.syncWatchState(settings, local);
      await ref.read(watchProvider.notifier).replace(merged);
      if (settings.webDavFavoriteSync) {
        final local = await ref.read(libraryProvider.future);
        final merged = await service.syncFavorites(settings, local.favorites);
        await ref.read(libraryProvider.notifier).replaceFavorites(merged);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.syncQueued)));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loadFailed(l10n.webDav))));
    }
  }
}

class WebDavConfigurationPage extends ConsumerStatefulWidget {
  const WebDavConfigurationPage({super.key});

  @override
  ConsumerState<WebDavConfigurationPage> createState() => _WebDavConfigurationPageState();
}

class _WebDavConfigurationPageState extends ConsumerState<WebDavConfigurationPage> {
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    _url = TextEditingController(text: settings?.webDavUrl);
    _username = TextEditingController(text: settings?.webDavUsername);
    _password = TextEditingController(text: settings?.webDavPassword);
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.webDavConfiguration)), body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: _url, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l10n.webDavUrl)), const SizedBox(height: 12), TextField(controller: _username, decoration: InputDecoration(labelText: l10n.username)), const SizedBox(height: 12), TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: l10n.password)), const Spacer(), FilledButton(onPressed: _save, child: Text(l10n.save))])));
  }

  Future<void> _save() async {
    await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(webDavUrl: _url.text.trim(), webDavUsername: _username.text.trim(), webDavPassword: _password.text));
    if (mounted) Navigator.pop(context);
  }
}
