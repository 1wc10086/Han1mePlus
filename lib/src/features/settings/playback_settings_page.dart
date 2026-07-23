import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';

class PlaybackSettingsPage extends ConsumerWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playbackSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SliderTile(title: l10n.defaultPlaybackSpeed, value: settings.defaultPlaybackSpeed, min: .25, max: 3, divisions: 11, label: '${settings.defaultPlaybackSpeed.toStringAsFixed(settings.defaultPlaybackSpeed == settings.defaultPlaybackSpeed.roundToDouble() ? 0 : 2)}x', onChanged: (value) => controller.saveChanges((current) => current.copyWith(defaultPlaybackSpeed: value))),
          _SliderTile(title: l10n.longPressPlaybackSpeed, value: settings.longPressPlaybackSpeed, min: 1, max: 3, divisions: 8, label: '${settings.longPressPlaybackSpeed.toStringAsFixed(settings.longPressPlaybackSpeed == settings.longPressPlaybackSpeed.roundToDouble() ? 0 : 2)}x', onChanged: (value) => controller.saveChanges((current) => current.copyWith(longPressPlaybackSpeed: value))),
          _SliderTile(title: l10n.playerControlsTimeout, subtitle: l10n.playerControlsTimeoutDescription, value: settings.playerControlsTimeoutSeconds.toDouble(), min: 1, max: 15, divisions: 14, label: l10n.seconds(settings.playerControlsTimeoutSeconds), onChanged: (value) => controller.saveChanges((current) => current.copyWith(playerControlsTimeoutSeconds: value.round()))),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({required this.title, this.subtitle, required this.value, required this.min, required this.max, required this.divisions, required this.label, required this.onChanged});
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (subtitle != null) Text(subtitle!), Slider(value: value, min: min, max: max, divisions: divisions, label: label, onChanged: onChanged)]),
        trailing: Text(label),
      );
}
