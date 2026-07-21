import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class AppLicensePage extends StatelessWidget {
  const AppLicensePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.openSourceLicense)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('GNU Affero General Public License v3.0', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Copyright (c) 2026 Han1mePlus contributors'),
            const SizedBox(height: 16),
            const Text('This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.'),
            const SizedBox(height: 16),
            const Text('This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. See the GNU Affero General Public License for details. The complete license text is available at https://www.gnu.org/licenses/agpl-3.0.html.'),
          ],
        ),
      );
}
