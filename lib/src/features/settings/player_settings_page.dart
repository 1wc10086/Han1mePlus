import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import 'settings_controller.dart';
import 'settings_card_list.dart';

class PlayerSettingsPage extends ConsumerWidget {
  const PlayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(settingsProvider.notifier);
    final libmpv = settings.playerEngine == PlayerEngine.libMpv;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playerSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SettingsCardList(children: [
            SettingsCardItem(title: l10n.hardwareDecode, subtitle: l10n.hardwareDecodeDescription, leading: const Icon(Icons.settings_input_hdmi_outlined), trailing: Switch(value: settings.hardwareAcceleration, onChanged: libmpv ? (value) => controller.saveChanges((current) => current.copyWith(hardwareAcceleration: value)) : null)),
            _OptionTile(icon: Icons.memory_outlined, title: l10n.decoder, value: _engineLabel(l10n, settings.playerEngine), enabled: true, onTap: () => context.push('/settings/player/decoder')),
            _OptionTile(icon: Icons.video_settings_outlined, title: l10n.videoRenderer, value: _rendererLabel(l10n, settings.videoRenderer), enabled: libmpv, onTap: libmpv ? () => context.push('/settings/player/renderer') : null),
            _ViewMenuTile(icon: Icons.layers_outlined, title: l10n.viewSettings, value: settings.videoView, enabled: libmpv, label: (value) => _viewLabel(l10n, value), onSelected: (value) => controller.saveChanges((current) => current.copyWith(videoView: value))),
            _OptionTile(icon: Icons.tune_outlined, title: l10n.customParameters, value: settings.customParameters.isEmpty ? l10n.none : '${settings.customParameters.length}', enabled: libmpv, onTap: libmpv ? () => _editCustomParameters(context, ref, settings) : null),
            _OptionTile(icon: Icons.auto_awesome_outlined, title: l10n.superResolution, value: _superResolutionLabel(l10n, settings.superResolutionMode), enabled: libmpv, onTap: libmpv ? () => context.push('/settings/player/super-resolution') : null),
          ]),
        ],
      ),
    );
  }

  String _engineLabel(AppLocalizations l10n, PlayerEngine engine) => switch (engine) {
        PlayerEngine.exoPlayer => l10n.exoPlayer,
        PlayerEngine.avPlayer => l10n.avPlayer,
        PlayerEngine.libMpv => l10n.libMpv,
      };

  String _rendererLabel(AppLocalizations l10n, VideoRenderer renderer) => switch (renderer) {
        VideoRenderer.auto => l10n.rendererAuto,
        VideoRenderer.gpu => l10n.rendererGpu,
        VideoRenderer.gpuNext => l10n.rendererGpuNext,
        VideoRenderer.mediacodecEmbed => l10n.rendererMediacodecEmbed,
      };

  String _viewLabel(AppLocalizations l10n, VideoView view) => switch (view) {
        VideoView.platformView => l10n.viewPlatformView,
        VideoView.surfaceView => l10n.viewSurfaceView,
      };

  String _superResolutionLabel(AppLocalizations l10n, SuperResolutionMode mode) => switch (mode) {
        SuperResolutionMode.off => l10n.superResolutionOff,
        SuperResolutionMode.efficiency => l10n.superResolutionEfficiency,
        SuperResolutionMode.quality => l10n.superResolutionQuality,
      };

  Future<void> _editCustomParameters(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CustomParametersDialog(initial: settings.customParameters.join('\n')),
    );
    if (result == null) return;
    final parameters = result
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    await ref
        .read(settingsProvider.notifier)
        .saveChanges((current) => current.copyWith(customParameters: parameters));
  }
}

class _CustomParametersDialog extends StatefulWidget {
  const _CustomParametersDialog({required this.initial});
  final String initial;

  @override
  State<_CustomParametersDialog> createState() => _CustomParametersDialogState();
}

class _CustomParametersDialogState extends State<_CustomParametersDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.customParameters),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 8,
        decoration: InputDecoration(hintText: l10n.customParametersHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(l10n.save)),
      ],
    );
  }
}

class _OptionTile extends SettingsCardItem {
  _OptionTile({required IconData icon, required String title, required String value, required bool enabled, required VoidCallback? onTap, Widget? trailing})
      : super(title: title, subtitle: value, leading: Icon(icon), trailing: trailing ?? const Icon(Icons.chevron_right), onTap: onTap, enabled: enabled);
}

class _ViewMenuTile extends SettingsMenuItem<VideoView> {
  _ViewMenuTile({required IconData icon, required String title, required VideoView value, required bool enabled, required String Function(VideoView) label, required ValueChanged<VideoView> onSelected})
      : super(title: title, subtitle: label(value), leading: Icon(icon), value: value, options: VideoView.values, label: label, onSelected: onSelected, enabled: enabled);
}
