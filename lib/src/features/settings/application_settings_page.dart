import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import 'settings_controller.dart';

class ApplicationSettingsPage extends ConsumerWidget {
  const ApplicationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.applicationSettings)), body: ListView(children: [
      SwitchListTile(secondary: const Icon(Icons.lock_outline), title: Text(l10n.appLock), subtitle: Text(l10n.appLockDescription), value: settings.appLockEnabled, onChanged: (value) async { if (!value || await PlatformService.authenticate()) await controller.saveChanges((current) => current.copyWith(appLockEnabled: value)); }),
      SwitchListTile(secondary: const Icon(Icons.warning_amber_outlined), title: Text(l10n.emergencyExit), subtitle: Text(l10n.emergencyExitDescription), value: settings.emergencyExitEnabled, onChanged: (value) async { await PlatformService.setEmergencyExit(value); await controller.saveChanges((current) => current.copyWith(emergencyExitEnabled: value)); }),
      SwitchListTile(secondary: const Icon(Icons.visibility_off_outlined), title: Text(l10n.hideFromRecents), subtitle: Text(l10n.hideFromRecentsDescription), value: settings.hideFromRecents, onChanged: (value) async { await PlatformService.setHideFromRecents(value); await controller.saveChanges((current) => current.copyWith(hideFromRecents: value)); }),
      ListTile(leading: const Icon(Icons.open_in_new_outlined), title: Text(l10n.openAppLinkSettings), subtitle: Text(l10n.openAppLinkSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: PlatformService.openAppLinksSettings),
    ]));
  }
}
