import 'package:card_settings_ui/list/settings_list.dart';
import 'package:card_settings_ui/section/settings_section.dart';
import 'package:card_settings_ui/tile/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/playback_speed_policy.dart';
import '../../core/settings.dart';
import '../account/account_controller.dart';
import '../explore/explore_controller.dart';
import 'settings_controller.dart';

class SiteSettingsPage extends ConsumerWidget {
  const SiteSettingsPage({super.key});

  static const _hosts = ['https://hanime1.com', 'https://hanimeone.me', 'https://hanime1.me', 'https://javchu.com'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final current = settings.comicMode ? 'https://hanimeone.me' : settings.baseUrl;
    final hosts = settings.comicMode ? const ['https://hanimeone.me'] : _hosts;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.site)),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.site, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            tiles: [
              for (final host in hosts)
                SettingsTile<String>.radioTile(
                  radioValue: host,
                  groupValue: current,
                  title: Text(host),
                  onChanged: (value) async {
                    if (value == null || value == current) return;
                    await ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(baseUrl: value, videoBaseUrl: settings.comicMode ? settings.videoBaseUrl : value, useCustomMirrorSite: false, customMirrorSite: ''));
                    ref.invalidate(accountProvider);
                    ref.invalidate(homeSectionsProvider);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DecoderSettingsPage extends ConsumerWidget {
  const DecoderSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(settingsProvider).valueOrNull?.playerEngine ?? PlayerEngine.libMpv;
    return _RadioSettingsPage<PlayerEngine>(
      title: l10n.decoder,
      current: current,
      options: PlaybackSpeedPolicy.isHarmonyOs ? const [PlayerEngine.libMpv] : PlayerEngineX.available,
      label: (value) => switch (value) { PlayerEngine.exoPlayer => l10n.exoPlayer, PlayerEngine.avPlayer => l10n.avPlayer, PlayerEngine.libMpv => l10n.libMpv },
      onChanged: (value) => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(playerEngine: value)),
    );
  }
}

class RendererSettingsPage extends ConsumerWidget {
  const RendererSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(settingsProvider).valueOrNull?.videoRenderer ?? VideoRenderer.auto;
    return _RadioSettingsPage<VideoRenderer>(
      title: l10n.videoRenderer,
      current: current,
      options: VideoRenderer.values,
      label: (value) => switch (value) { VideoRenderer.auto => l10n.rendererAuto, VideoRenderer.gpu => l10n.rendererGpu, VideoRenderer.gpuNext => l10n.rendererGpuNext, VideoRenderer.mediacodecEmbed => l10n.rendererMediacodecEmbed },
      onChanged: (value) => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(videoRenderer: value)),
    );
  }
}

class SuperResolutionSettingsPage extends ConsumerWidget {
  const SuperResolutionSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(settingsProvider).valueOrNull?.superResolutionMode ?? SuperResolutionMode.off;
    return _RadioSettingsPage<SuperResolutionMode>(
      title: l10n.superResolution,
      current: current,
      options: SuperResolutionMode.values,
      label: (value) => switch (value) { SuperResolutionMode.off => l10n.superResolutionOff, SuperResolutionMode.efficiency => l10n.superResolutionEfficiency, SuperResolutionMode.quality => l10n.superResolutionQuality },
      onChanged: (value) => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(superResolutionMode: value)),
    );
  }
}

class _RadioSettingsPage<T> extends StatelessWidget {
  const _RadioSettingsPage({required this.title, required this.current, required this.options, required this.label, required this.onChanged});

  final String title;
  final T current;
  final List<T> options;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              tiles: [
                for (final option in options)
                  SettingsTile<T>.radioTile(radioValue: option, groupValue: current, title: Text(label(option)), onChanged: (value) { if (value != null) onChanged(value); }),
              ],
            ),
          ],
        ),
      );
}
