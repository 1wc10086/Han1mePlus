import 'package:card_settings_ui/list/settings_list.dart';
import 'package:card_settings_ui/section/settings_section.dart';
import 'package:card_settings_ui/tile/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import 'settings_controller.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(settingsProvider).valueOrNull?.language ?? AppLanguage.system;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettings)),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.languageSettings, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            tiles: [
              _languageTile(l10n.systemDefault, AppLanguage.system, current, ref),
              _languageTile(l10n.simplifiedChinese, AppLanguage.simplifiedChinese, current, ref),
              _languageTile(l10n.traditionalChinese, AppLanguage.traditionalChinese, current, ref),
              _languageTile(l10n.english, AppLanguage.english, current, ref),
            ],
          ),
        ],
      ),
    );
  }

  SettingsTile<AppLanguage> _languageTile(String title, AppLanguage value, AppLanguage current, WidgetRef ref) => SettingsTile<AppLanguage>.radioTile(
        radioValue: value,
        groupValue: current,
        title: Text(title),
        onChanged: (next) {
          if (next != null) ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(language: next));
        },
      );
}
