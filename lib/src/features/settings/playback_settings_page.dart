import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';
import 'keyframes_page.dart';
import 'player_settings_page.dart';
import 'settings_card_list.dart';

class PlaybackSettingsPage extends ConsumerWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playbackSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
           SettingsCardList(title: l10n.general, children: [
             SettingsCardItem(title: l10n.playerSettings, subtitle: l10n.playerSettingsDescription, leading: const Icon(Icons.tune_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/player')),
              SettingsMenuItem(title: l10n.preferredQuality, subtitle: '${settings.preferredQuality}p', leading: const Icon(Icons.hd_outlined), value: settings.preferredQuality, options: const [480, 720, 1080], label: (value) => '${value}p', onSelected: (value) => controller.saveChanges((current) => current.copyWith(preferredQuality: value))),
              SettingsCardItem(title: l10n.resumePlayback, subtitle: l10n.resumePlaybackDescription, leading: const Icon(Icons.play_circle_outline), trailing: Switch(value: settings.resumePlayback, onChanged: (value) => controller.saveChanges((current) => current.copyWith(resumePlayback: value)))),
              SettingsCardItem(title: l10n.autoPlayOnOpen, subtitle: l10n.autoPlayOnOpenDescription, leading: const Icon(Icons.play_arrow_outlined), trailing: Switch(value: settings.autoPlayOnOpen, onChanged: (value) => controller.saveChanges((current) => current.copyWith(autoPlayOnOpen: value)))),
              SettingsCardItem(title: l10n.incognitoPlayback, subtitle: l10n.incognitoPlaybackDescription, leading: const Icon(Icons.visibility_off_outlined), trailing: Switch(value: settings.incognitoPlayback, onChanged: (value) => controller.saveChanges((current) => current.copyWith(incognitoPlayback: value)))),
              SettingsCardItem(title: l10n.autoPlayNext, subtitle: l10n.autoPlayNextDescription, leading: const Icon(Icons.skip_next_outlined), trailing: Switch(value: settings.autoPlayNext, onChanged: (value) => controller.saveChanges((current) => current.copyWith(autoPlayNext: value)))),
              SettingsCardItem(title: l10n.loopPlayback, subtitle: l10n.loopPlaybackDescription, leading: const Icon(Icons.repeat_outlined), trailing: Switch(value: settings.loopPlayback, onChanged: (value) => controller.saveChanges((current) => current.copyWith(loopPlayback: value)))),
              SettingsCardItem(title: l10n.autoPictureInPicture, subtitle: l10n.autoPictureInPictureDescription, leading: const Icon(Icons.picture_in_picture_alt_outlined), trailing: Switch(value: settings.autoPictureInPicture, onChanged: (value) => controller.saveChanges((current) => current.copyWith(autoPictureInPicture: value)))),
           ]),
           SettingsCardList(title: l10n.keyframes, children: [
             SettingsCardItem(title: l10n.keyframesEnabled, subtitle: l10n.keyframesEnabledDescription, leading: const Icon(Icons.key_outlined), trailing: Switch(value: settings.keyframesEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(keyframesEnabled: value)))),
             SettingsCardItem(title: l10n.keyframeManagement, subtitle: l10n.keyframeSettingsDescription, leading: const Icon(Icons.key_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KeyframesPage()))),
           ]),
           SettingsCardList(title: l10n.playback, children: [
             SettingsSliderItem(title: l10n.defaultPlaybackSpeed, value: settings.defaultPlaybackSpeed, min: .25, max: 3, divisions: 11, label: '${settings.defaultPlaybackSpeed.toStringAsFixed(settings.defaultPlaybackSpeed == settings.defaultPlaybackSpeed.roundToDouble() ? 0 : 2)}x', onChanged: (value) => controller.saveChanges((current) => current.copyWith(defaultPlaybackSpeed: value))),
             SettingsSliderItem(title: l10n.longPressPlaybackSpeed, value: settings.longPressPlaybackSpeed, min: 1, max: 3, divisions: 8, label: '${settings.longPressPlaybackSpeed.toStringAsFixed(settings.longPressPlaybackSpeed == settings.longPressPlaybackSpeed.roundToDouble() ? 0 : 2)}x', onChanged: (value) => controller.saveChanges((current) => current.copyWith(longPressPlaybackSpeed: value))),
             SettingsSliderItem(title: l10n.playerControlsTimeout, subtitle: l10n.playerControlsTimeoutDescription, value: settings.playerControlsTimeoutSeconds.toDouble(), min: 1, max: 15, divisions: 14, label: l10n.seconds(settings.playerControlsTimeoutSeconds), onChanged: (value) => controller.saveChanges((current) => current.copyWith(playerControlsTimeoutSeconds: value.round()))),
             SettingsSliderItem(title: l10n.seekSensitivity, subtitle: l10n.seekSensitivityDescription, value: settings.seekSensitivity, min: .1, max: 1, divisions: 9, label: l10n.seekSensitivityValue((settings.seekSensitivity * 100).round()), onChanged: (value) => controller.saveChanges((current) => current.copyWith(seekSensitivity: value))),
           ]),
        ],
      ),
    );
  }
}
