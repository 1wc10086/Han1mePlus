import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/remote/update_checker.dart';
import '../../data/local/update_installer.dart';
import 'settings_controller.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.about)),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/logo.png', width: 72, height: 72))),
            const SizedBox(height: 12),
            Center(child: Text('Han1me+', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
            Center(child: Text(AppLocalizations.of(context)!.thirdPartyClient, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline))),
            const SizedBox(height: 28),
            ListTile(leading: const Icon(Icons.code_outlined), title: Text(AppLocalizations.of(context)!.version), subtitle: const Text('1.1.1')),
            ListTile(leading: const Icon(Icons.language_outlined), title: Text(AppLocalizations.of(context)!.dataSource), subtitle: Text(AppLocalizations.of(context)!.dataSourceDescription)),
            ListTile(leading: const Icon(Icons.code_outlined), title: Text(AppLocalizations.of(context)!.githubRepository), subtitle: const Text('github.com/1wc10086/Han1mePlus'), trailing: const Icon(Icons.open_in_new), onTap: () => launchUrl(Uri.parse('https://github.com/1wc10086/Han1mePlus'), mode: LaunchMode.externalApplication)),
            ListTile(leading: const Icon(Icons.bug_report_outlined), title: Text(AppLocalizations.of(context)!.reportIssue), subtitle: Text(AppLocalizations.of(context)!.submitGitHubIssue), trailing: const Icon(Icons.open_in_new), onTap: () => launchUrl(Uri.parse('https://github.com/1wc10086/Han1mePlus/issues/new/choose'), mode: LaunchMode.externalApplication)),
             ListTile(leading: const Icon(Icons.gavel_outlined), title: Text(AppLocalizations.of(context)!.openSourceLicense), trailing: const Icon(Icons.chevron_right), onTap: () => showLicensePage(context: context, applicationName: 'Han1me+', applicationVersion: '1.1.1')),
            const Divider(),
            SwitchListTile(secondary: const Icon(Icons.autorenew_outlined), title: Text(AppLocalizations.of(context)!.autoCheckUpdates), value: ref.watch(settingsProvider).valueOrNull?.autoUpdate ?? true, onChanged: (value) => ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(autoUpdate: value))),
            ListTile(leading: const Icon(Icons.system_update_outlined), title: Text(AppLocalizations.of(context)!.checkUpdates), trailing: const Icon(Icons.chevron_right), onTap: () => _checkUpdate(context)),
          ],
        ),
      );

  Future<void> _checkUpdate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final update = await UpdateChecker(Dio()).check();
    if (!context.mounted) return;
    if (update == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.latestVersion)));
      return;
    }
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.newVersionAvailable(update.tagName)), content: Text(update.body.isEmpty ? l10n.newVersionReleased : update.body), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.later)), FilledButton(onPressed: () async { Navigator.pop(dialogContext); if (update.downloadUrl.isNotEmpty) await UpdateInstaller(Dio()).downloadAndInstall(update.downloadUrl, (_) {}); }, child: Text(l10n.updateNow))]));
  }
}
