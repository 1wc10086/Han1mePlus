import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class DownloadSettingsPage extends ConsumerWidget {
  const DownloadSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final speed = settings.downloadSpeedLimitMbps;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
            SettingsCardList(children: [
              SettingsSliderItem(title: l10n.downloadSpeedLimit, subtitle: speed == 0 ? l10n.unlimited : '${speed.toStringAsFixed(1)} MB/s', value: speed, min: 0, max: 20, divisions: 40, label: speed == 0 ? l10n.unlimited : '${speed.toStringAsFixed(1)} MB/s', onChanged: (value) => controller.saveChanges((current) => current.copyWith(downloadSpeedLimitMbps: value))),
              SettingsSliderItem(title: l10n.concurrentDownloads, subtitle: l10n.concurrentDownloadsDescription(settings.concurrentDownloads), value: settings.concurrentDownloads.toDouble(), min: 1, max: 5, divisions: 4, label: '${settings.concurrentDownloads}', onChanged: (value) => controller.saveChanges((current) => current.copyWith(concurrentDownloads: value.round()))),
           ]),
        ],
      ),
    );
  }
}
