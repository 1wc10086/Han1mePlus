import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'settings_controller.dart';
import 'keyframes_page.dart';

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
          _SectionLabel(l10n.general),
          ListTile(leading: const Icon(Icons.smart_display_outlined), title: Text(l10n.playerEngine), subtitle: const Text('ExoPlayer'), trailing: const Icon(Icons.chevron_right), onTap: () => _showPicker(context, 'ExoPlayer', const ['ExoPlayer'])),
          ListTile(leading: const Icon(Icons.hd_outlined), title: Text(l10n.preferredQuality), subtitle: Text('${settings.preferredQuality}p'), trailing: const Icon(Icons.chevron_right), onTap: () => _showQualityPicker(context, settings.preferredQuality, controller)),
          SwitchListTile(secondary: const Icon(Icons.play_circle_outline), title: Text(l10n.resumePlayback), subtitle: Text(l10n.resumePlaybackDescription), value: settings.resumePlayback, onChanged: (value) => controller.saveChanges((current) => current.copyWith(resumePlayback: value))),
          _SectionLabel(l10n.keyframes),
          SwitchListTile(secondary: const Icon(Icons.key_outlined), title: Text(l10n.keyframesEnabled), subtitle: Text(l10n.keyframesEnabledDescription), value: settings.keyframesEnabled, onChanged: (value) => controller.saveChanges((current) => current.copyWith(keyframesEnabled: value))),
          SwitchListTile(secondary: const Icon(Icons.upload_outlined), title: Text(l10n.shareKeyframes), subtitle: Text(l10n.shareKeyframesDescription), value: settings.shareKeyframes, onChanged: (value) => controller.saveChanges((current) => current.copyWith(shareKeyframes: value))),
          SwitchListTile(secondary: const Icon(Icons.volunteer_activism_outlined), title: Text(l10n.useSharedKeyframes), subtitle: Text(l10n.useSharedKeyframesDescription), value: settings.useSharedKeyframes, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useSharedKeyframes: value))),
          SwitchListTile(secondary: const Icon(Icons.priority_high_outlined), title: Text(l10n.preferSharedKeyframes), subtitle: Text(l10n.preferSharedKeyframesDescription), value: settings.preferSharedKeyframes, onChanged: (value) => controller.saveChanges((current) => current.copyWith(preferSharedKeyframes: value))),
          ListTile(leading: const Icon(Icons.key_outlined), title: Text(l10n.keyframeManagement), subtitle: Text(l10n.keyframeSettingsDescription), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KeyframesPage()))),
          _SectionLabel(l10n.playback),
          _SliderTile(title: l10n.defaultPlaybackSpeed, value: settings.defaultPlaybackSpeed, min: .25, max: 3, divisions: 11, label: '${settings.defaultPlaybackSpeed.toStringAsFixed(settings.defaultPlaybackSpeed == settings.defaultPlaybackSpeed.roundToDouble() ? 0 : 2)}x', onChanged: (value) => controller.saveChanges((current) => current.copyWith(defaultPlaybackSpeed: value))),
          _SliderTile(title: l10n.longPressPlaybackSpeed, value: settings.longPressPlaybackSpeed, min: 1, max: 3, divisions: 8, label: '${settings.longPressPlaybackSpeed.toStringAsFixed(settings.longPressPlaybackSpeed == settings.longPressPlaybackSpeed.roundToDouble() ? 0 : 2)}x', onChanged: (value) => controller.saveChanges((current) => current.copyWith(longPressPlaybackSpeed: value))),
          _SliderTile(title: l10n.playerControlsTimeout, subtitle: l10n.playerControlsTimeoutDescription, value: settings.playerControlsTimeoutSeconds.toDouble(), min: 1, max: 15, divisions: 14, label: l10n.seconds(settings.playerControlsTimeoutSeconds), onChanged: (value) => controller.saveChanges((current) => current.copyWith(playerControlsTimeoutSeconds: value.round()))),
        ],
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, String value, List<String> options) async => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final option in options) RadioListTile(value: option, groupValue: value, title: Text(option), onChanged: (_) => Navigator.pop(context))])));

  Future<void> _showQualityPicker(BuildContext context, int quality, SettingsController controller) async {
    final selected = await showModalBottomSheet<int>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final option in [480, 720, 1080]) RadioListTile(value: option, groupValue: quality, title: Text('${option}p'), onChanged: (value) => Navigator.pop(context, value))])));
    if (selected != null) await controller.saveChanges((current) => current.copyWith(preferredQuality: selected));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
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
