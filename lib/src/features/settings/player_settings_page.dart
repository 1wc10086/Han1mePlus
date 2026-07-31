import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import 'settings_controller.dart';

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
          _SectionLabel(l10n.hardwareDecode),
          SwitchListTile(
            secondary: const Icon(Icons.settings_input_hdmi_outlined),
            title: Text(l10n.hardwareDecode),
            subtitle: Text(l10n.hardwareDecodeDescription),
            value: settings.hardwareAcceleration,
            onChanged: libmpv
                ? (value) => controller.saveChanges((current) => current.copyWith(hardwareAcceleration: value))
                : null,
          ),
          _SectionLabel(l10n.decoderSettings),
          _OptionTile(
            icon: Icons.memory_outlined,
            title: l10n.decoder,
            value: _engineLabel(l10n, settings.playerEngine),
            enabled: true,
            onTap: () => _pickEngine(context, ref, settings),
          ),
          _SectionLabel(l10n.videoRenderer),
          _OptionTile(
            icon: Icons.video_settings_outlined,
            title: l10n.videoRenderer,
            value: _rendererLabel(l10n, settings.videoRenderer),
            enabled: libmpv,
            onTap: libmpv ? () => _pickRenderer(context, ref, settings) : null,
          ),
          _SectionLabel(l10n.viewSettings),
          _OptionTile(
            icon: Icons.layers_outlined,
            title: l10n.viewSettings,
            value: _viewLabel(l10n, settings.videoView),
            enabled: libmpv,
            onTap: libmpv ? () => _pickView(context, ref, settings) : null,
          ),
          _SectionLabel(l10n.customParameters),
          _OptionTile(
            icon: Icons.tune_outlined,
            title: l10n.customParameters,
            value: settings.customParameters.isEmpty ? l10n.none : '${settings.customParameters.length}',
            enabled: libmpv,
            onTap: libmpv ? () => _editCustomParameters(context, ref, settings) : null,
          ),
          _SectionLabel(l10n.superResolution),
          _OptionTile(
            icon: Icons.auto_awesome_outlined,
            title: l10n.superResolution,
            value: _superResolutionLabel(l10n, settings.superResolutionMode),
            enabled: libmpv,
            onTap: libmpv ? () => _pickSuperResolution(context, ref, settings) : null,
          ),
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

  Future<void> _pickEngine(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await _showPicker<PlayerEngine>(
      context,
      options: PlayerEngineX.available,
      selected: settings.playerEngine,
      label: (engine) => _engineLabel(l10n, engine),
    );
    if (selected != null) {
      await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(playerEngine: selected));
    }
  }

  Future<void> _pickRenderer(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await _showPicker<VideoRenderer>(
      context,
      options: VideoRenderer.values,
      selected: settings.videoRenderer,
      label: (renderer) => _rendererLabel(l10n, renderer),
    );
    if (selected != null) {
      await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(videoRenderer: selected));
    }
  }

  Future<void> _pickView(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await _showPicker<VideoView>(
      context,
      options: VideoView.values,
      selected: settings.videoView,
      label: (view) => _viewLabel(l10n, view),
    );
    if (selected != null) {
      await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(videoView: selected));
    }
  }

  Future<void> _pickSuperResolution(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await _showPicker<SuperResolutionMode>(
      context,
      options: SuperResolutionMode.values,
      selected: settings.superResolutionMode,
      label: (mode) => _superResolutionLabel(l10n, mode),
    );
    if (selected != null) {
      await ref.read(settingsProvider.notifier).saveChanges((current) => current.copyWith(superResolutionMode: selected));
    }
  }

  Future<T?> _showPicker<T>(
    BuildContext context, {
    required List<T> options,
    required T selected,
    required String Function(T) label,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                RadioListTile<T>(
                  value: option,
                  groupValue: selected,
                  title: Text(label(option)),
                  onChanged: (value) => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      );

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

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.title, required this.value, required this.enabled, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(enabled ? value : l10n.availableOnlyForLibmpv),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
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
