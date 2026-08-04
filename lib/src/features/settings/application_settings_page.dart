import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import '../auth/app_lock_controller.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class ApplicationSettingsPage extends ConsumerWidget {
  const ApplicationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.applicationSettings)), body: ListView(children: [
       SettingsCardList(children: [
         SettingsCardItem(title: l10n.appLock, subtitle: l10n.appLockDescription, leading: const Icon(Icons.lock_outline), trailing: Switch(value: settings.appLockEnabled, onChanged: (value) async { if (!value || await PlatformService.authenticate()) { if (value) ref.read(appLockProvider.notifier).markUnlocked(); await controller.saveChanges((current) => current.copyWith(appLockEnabled: value)); } })),
         SettingsCardItem(title: l10n.emergencyExit, subtitle: l10n.emergencyExitDescription, leading: const Icon(Icons.warning_amber_outlined), trailing: Switch(value: settings.emergencyExitEnabled, onChanged: (value) async { await PlatformService.setEmergencyExit(value); await controller.saveChanges((current) => current.copyWith(emergencyExitEnabled: value)); })),
          SettingsCardItem(title: l10n.hideFromRecents, subtitle: l10n.hideFromRecentsDescription, leading: const Icon(Icons.visibility_off_outlined), trailing: Switch(value: settings.hideFromRecents, onChanged: (value) async { await PlatformService.setHideFromRecents(value); await controller.saveChanges((current) => current.copyWith(hideFromRecents: value)); })),
          SettingsCardItem(title: l10n.openAppLinkSettings, subtitle: l10n.openAppLinkSettingsDescription, leading: const Icon(Icons.open_in_new_outlined), trailing: const Icon(Icons.chevron_right), onTap: PlatformService.openAppLinksSettings),
       ]),
    ]));
  }
}
