import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import 'settings_controller.dart';

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacySettings)),
      body: ListView(children: [
        SwitchListTile(title: Text(l10n.appLock), subtitle: Text(l10n.appLockDescription), value: settings.appLockEnabled, onChanged: (value) async { if (!value || await PlatformService.authenticate()) await controller.saveChanges((current) => current.copyWith(appLockEnabled: value)); }),
        SwitchListTile(title: Text(l10n.emergencyExit), subtitle: Text(l10n.emergencyExitDescription), value: settings.emergencyExitEnabled, onChanged: (value) async { await PlatformService.setEmergencyExit(value); await controller.saveChanges((current) => current.copyWith(emergencyExitEnabled: value)); }),
        SwitchListTile(title: Text(l10n.hideFromRecents), subtitle: Text(l10n.hideFromRecentsDescription), value: settings.hideFromRecents, onChanged: (value) async { await PlatformService.setHideFromRecents(value); await controller.saveChanges((current) => current.copyWith(hideFromRecents: value)); }),
      ]),
    );
  }
}
