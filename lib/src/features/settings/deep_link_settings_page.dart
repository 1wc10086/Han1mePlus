import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';
import 'settings_card_list.dart';

class DeepLinkSettingsPage extends StatelessWidget {
  const DeepLinkSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
     return Scaffold(appBar: AppBar(title: Text(l10n.deepLinkSettings)), body: ListView(children: [SettingsCardList(children: [SettingsCardItem(title: l10n.openAppLinkSettings, subtitle: l10n.openAppLinkSettingsDescription, leading: const Icon(Icons.open_in_new_outlined), trailing: const Icon(Icons.chevron_right), onTap: PlatformService.openAppLinksSettings)])]));
  }
}
