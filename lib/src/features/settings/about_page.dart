import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.about)),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/logo.png', width: 72, height: 72))),
            const SizedBox(height: 12),
            Center(child: Text('Han1me+', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
            Center(child: Text(AppLocalizations.of(context)!.thirdPartyClient, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline))),
            const SizedBox(height: 28),
            ListTile(leading: const Icon(Icons.code_outlined), title: Text(AppLocalizations.of(context)!.version), subtitle: const Text('1.0.4')),
            ListTile(leading: const Icon(Icons.language_outlined), title: Text(AppLocalizations.of(context)!.dataSource), subtitle: Text(AppLocalizations.of(context)!.dataSourceDescription)),
            ListTile(leading: const Icon(Icons.code_outlined), title: Text(AppLocalizations.of(context)!.githubRepository), subtitle: const Text('github.com/1wc10086/Han1mePlus'), trailing: const Icon(Icons.open_in_new), onTap: () => launchUrl(Uri.parse('https://github.com/1wc10086/Han1mePlus'), mode: LaunchMode.externalApplication)),
            ListTile(leading: const Icon(Icons.bug_report_outlined), title: Text(AppLocalizations.of(context)!.reportIssue), subtitle: Text(AppLocalizations.of(context)!.submitGitHubIssue), trailing: const Icon(Icons.open_in_new), onTap: () => launchUrl(Uri.parse('https://github.com/1wc10086/Han1mePlus/issues/new/choose'), mode: LaunchMode.externalApplication)),
            ListTile(leading: const Icon(Icons.gavel_outlined), title: Text(AppLocalizations.of(context)!.openSourceLicense), subtitle: const Text('AGPL-3.0'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/license')),
          ],
        ),
      );
}
