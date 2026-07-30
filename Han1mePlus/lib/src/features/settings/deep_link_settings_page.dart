import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/platform_service.dart';

class DeepLinkSettingsPage extends StatelessWidget {
  const DeepLinkSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(appBar: AppBar(title: Text(l10n.deepLinkSettings)), body: ListView(children: [ListTile(leading: const Icon(Icons.open_in_new_outlined), title: Text(l10n.openAppLinkSettings), subtitle: Text(l10n.openAppLinkSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: PlatformService.openAppLinksSettings)]));
  }
}
