import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import '../../data/local/keyframe_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import 'android_cast_button.dart';

class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({required this.controller, required this.fullscreen, required this.onFullscreen, required this.onInteraction, required this.video, required this.quality, required this.onQualitySelected, required this.onSuperResolutionSelected, this.onNext, this.onEpisodeSelected, super.key});
  final VideoPlayerController controller;
  final bool fullscreen;
  final Future<void> Function() onFullscreen;
  final VoidCallback onInteraction;
  final VideoDetail video;
  final ValueListenable<String?> quality;
  final ValueChanged<VideoSource> onQualitySelected;
  final ValueChanged<SuperResolutionMode> onSuperResolutionSelected;
  final VoidCallback? onNext;
  final ValueChanged<VideoCard>? onEpisodeSelected;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final l10n = AppLocalizations.of(context)!;
          final progress = value.duration == Duration.zero ? 0.0 : value.position.inMilliseconds / value.duration.inMilliseconds;
          if (!fullscreen) return SizedBox(height: 48, child: Row(children: [IconButton(color: Colors.white, tooltip: value.isPlaying ? l10n.pause : l10n.play, visualDensity: VisualDensity.compact, onPressed: () { value.isPlaying ? controller.pause() : controller.play(); onInteraction(); }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)), Expanded(child: SliderTheme(data: const SliderThemeData(year2023: true), child: Slider(value: progress.clamp(0, 1).toDouble(), onChanged: (next) { controller.seekTo(Duration(milliseconds: (next * value.duration.inMilliseconds).round())); onInteraction(); }))), SizedBox(width: 112, child: Text('${_formatDuration(value.position)}/${_formatDuration(value.duration)}', maxLines: 1, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))), IconButton(color: Colors.white, tooltip: l10n.fullscreenPlayback, visualDensity: VisualDensity.compact, onPressed: onFullscreen, icon: const Icon(Icons.fullscreen))]));
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [SizedBox(width: 48, child: Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))), Expanded(child: SliderTheme(data: const SliderThemeData(year2023: true), child: Slider(value: progress.clamp(0, 1).toDouble(), onChanged: (next) { controller.seekTo(Duration(milliseconds: (next * value.duration.inMilliseconds).round())); onInteraction(); }))), SizedBox(width: 48, child: Text(_formatDuration(value.duration), textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])))]),
            SizedBox(height: 40, child: Row(children: [IconButton(color: Colors.white, tooltip: value.isPlaying ? l10n.pause : l10n.play, visualDensity: VisualDensity.compact, onPressed: () { value.isPlaying ? controller.pause() : controller.play(); onInteraction(); }, icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)), if (onNext != null) IconButton(color: Colors.white, tooltip: l10n.autoPlayNext, visualDensity: VisualDensity.compact, onPressed: onNext, icon: const Icon(Icons.skip_next)), const Spacer(), _AspectMenu(), if (onEpisodeSelected != null && video.playlist.isNotEmpty) _EpisodeMenu(video: video, onSelected: onEpisodeSelected!), _Anime4KMenu(onSelected: onSuperResolutionSelected), if (video.sources.isNotEmpty) _QualityMenu(sources: video.sources, quality: quality, onSelected: onQualitySelected), _SpeedMenu(controller: controller, onInteraction: onInteraction), AndroidCastButton(sources: video.sources, quality: quality), IconButton(color: Colors.white, tooltip: l10n.exitFullscreen, visualDensity: VisualDensity.compact, onPressed: onFullscreen, icon: const Icon(Icons.fullscreen_exit))])),
          ]);
        },
      ),
    ),
  );
}

class VideoPlayerSkipButton extends ConsumerWidget {
  const VideoPlayerSkipButton({required this.controller, required this.onInteraction, super.key});
  final VideoPlayerController controller;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(settingsProvider).valueOrNull?.skipSeconds ?? 80;
    return GestureDetector(
      onLongPress: () => _configure(context, ref, seconds),
      child: IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.seconds(seconds), visualDensity: VisualDensity.compact, onPressed: () { final value = controller.value; final target = (value.position.inSeconds + seconds).clamp(0, value.duration.inSeconds); controller.seekTo(Duration(seconds: target)); onInteraction(); }, icon: const Icon(Icons.forward_10)),
    );
  }

  Future<void> _configure(BuildContext context, WidgetRef ref, int current) async {
    final result = await showDialog<int>(context: context, builder: (_) => _SkipSecondsDialog(initialValue: '$current'));
    if (result != null && result > 0) await ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(skipSeconds: result));
  }
}

class _SkipSecondsDialog extends StatefulWidget {
  const _SkipSecondsDialog({required this.initialValue});
  final String initialValue;

  @override
  State<_SkipSecondsDialog> createState() => _SkipSecondsDialogState();
}

class _SkipSecondsDialogState extends State<_SkipSecondsDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.seconds(int.tryParse(widget.initialValue) ?? 0)),
      content: TextField(controller: _controller, autofocus: true, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(_controller.text.trim())), child: Text(l10n.save)),
      ],
    );
  }
}

class _AspectMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aspect = ref.watch(settingsProvider).valueOrNull?.videoAspectRatio ?? VideoAspectRatio.auto;
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.videoAspectRatio, onPressed: controller.open, icon: const Icon(Icons.aspect_ratio)),
      menuChildren: VideoAspectRatio.values.map((item) => MenuItemButton(onPressed: () => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(videoAspectRatio: item)), leadingIcon: item == aspect ? const Icon(Icons.check, size: 18) : null, child: Text(_aspectLabel(AppLocalizations.of(context)!, item)))).toList(),
    );
  }
}

class _EpisodeMenu extends StatelessWidget {
  const _EpisodeMenu({required this.video, required this.onSelected});
  final VideoDetail video;
  final ValueChanged<VideoCard> onSelected;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        builder: (context, controller, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.episodeList, onPressed: controller.open, icon: const Icon(Icons.view_list_outlined)),
        menuChildren: video.playlist.map((episode) => MenuItemButton(onPressed: episode.id == video.id ? null : () => onSelected(episode), leadingIcon: episode.id == video.id ? const Icon(Icons.play_arrow) : null, child: SizedBox(width: 280, child: Text(episode.title, maxLines: 1, overflow: TextOverflow.ellipsis)))).toList(),
      );
}

class VideoPlayerPortraitMoreMenu extends ConsumerWidget {
  const VideoPlayerPortraitMoreMenu({required this.controller, required this.video, required this.quality, required this.onQualitySelected, required this.onSuperResolutionSelected, super.key});
  final VideoPlayerController controller;
  final VideoDetail video;
  final ValueListenable<String?> quality;
  final ValueChanged<VideoSource> onQualitySelected;
  final ValueChanged<SuperResolutionMode> onSuperResolutionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MenuAnchor(
        builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.more, onPressed: menu.open, icon: const Icon(Icons.more_vert)),
        menuChildren: [
          SubmenuButton(menuChildren: VideoAspectRatio.values.map((aspect) => MenuItemButton(onPressed: () => ref.read(settingsProvider.notifier).saveChanges((settings) => settings.copyWith(videoAspectRatio: aspect)), child: Text(_aspectLabel(AppLocalizations.of(context)!, aspect)))).toList(), child: Text(AppLocalizations.of(context)!.videoAspectRatio)),
          SubmenuButton(menuChildren: <double>[.5, .75, 1, 1.25, 1.5, 2, 3].map((speed) => MenuItemButton(onPressed: () => controller.setPlaybackSpeed(speed), child: Text('${speed}x'))).toList(), child: Text(AppLocalizations.of(context)!.playbackSpeed)),
          SubmenuButton(menuChildren: SuperResolutionMode.values.map((mode) => MenuItemButton(onPressed: () => onSuperResolutionSelected(mode), child: Text(_superResolutionLabel(AppLocalizations.of(context)!, mode)))).toList(), child: Text(AppLocalizations.of(context)!.superResolution)),
          if (video.sources.isNotEmpty) SubmenuButton(menuChildren: video.sources.map((source) => MenuItemButton(onPressed: () => onQualitySelected(source), child: Text(source.quality))).toList(), child: Text(AppLocalizations.of(context)!.quality)),
          if (video.sources.isNotEmpty) MenuItemButton(onPressed: () => _openExternal(video.sources, quality.value), leadingIcon: const Icon(Icons.open_in_new), child: Text(AppLocalizations.of(context)!.externalPlayback)),
        ],
      );

  Future<void> _openExternal(List<VideoSource> sources, String? current) async {
    final source = sources.where((source) => source.quality == current).firstOrNull ?? sources.first;
    await launchUrl(Uri.parse(source.url), mode: LaunchMode.externalApplication);
  }
}

class VideoPlayerFullscreenMoreMenu extends StatelessWidget {
  const VideoPlayerFullscreenMoreMenu({required this.sources, required this.quality, super.key});
  final List<VideoSource> sources;
  final ValueListenable<String?> quality;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.more, onPressed: menu.open, icon: const Icon(Icons.more_vert)),
        menuChildren: [
          if (sources.isNotEmpty) MenuItemButton(onPressed: () => _openExternal(), leadingIcon: const Icon(Icons.open_in_new), child: Text(AppLocalizations.of(context)!.externalPlayback)),
        ],
      );

  Future<void> _openExternal() async {
    final source = sources.where((source) => source.quality == quality.value).firstOrNull ?? sources.first;
    await launchUrl(Uri.parse(source.url), mode: LaunchMode.externalApplication);
  }
}

String _superResolutionLabel(AppLocalizations l10n, SuperResolutionMode mode) => switch (mode) { SuperResolutionMode.off => l10n.superResolutionOff, SuperResolutionMode.efficiency => l10n.superResolutionEfficiency, SuperResolutionMode.quality => l10n.superResolutionQuality };

String _aspectLabel(AppLocalizations l10n, VideoAspectRatio aspect) => switch (aspect) { VideoAspectRatio.auto => l10n.aspectAuto, VideoAspectRatio.crop => l10n.aspectCrop, VideoAspectRatio.stretch => l10n.aspectStretch, VideoAspectRatio.ratio4x3 => l10n.aspectFourThree };

class _Anime4KMenu extends ConsumerWidget {
  const _Anime4KMenu({required this.onSelected});

  final ValueChanged<SuperResolutionMode> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider).valueOrNull?.superResolutionMode ?? SuperResolutionMode.off;
    final l10n = AppLocalizations.of(context)!;
    return MenuAnchor(
      builder: (context, menu, child) => IconButton(
        color: Colors.white,
        tooltip: l10n.anime4k,
        onPressed: menu.open,
        icon: Icon(mode == SuperResolutionMode.off ? Icons.auto_awesome_outlined : Icons.auto_awesome),
      ),
      menuChildren: SuperResolutionMode.values.map((option) {
        final selected = option == mode;
        return MenuItemButton(
          onPressed: () => onSelected(option),
          leadingIcon: selected ? const Icon(Icons.check, size: 18) : null,
          child: Text(
            _superResolutionLabel(l10n, option),
            style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700) : null,
          ),
        );
      }).toList(),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

class _QualityMenu extends StatelessWidget {
  const _QualityMenu({required this.sources, required this.quality, required this.onSelected});
  final List<VideoSource> sources;
  final ValueListenable<String?> quality;
  final ValueChanged<VideoSource> onSelected;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: quality,
        builder: (context, current, _) => MenuAnchor(
          builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.quality, onPressed: menu.open, icon: const Icon(Icons.high_quality_outlined)),
          menuChildren: sources.map((source) {
            final selected = source.quality == current;
            return MenuItemButton(
              onPressed: () => onSelected(source),
              leadingIcon: selected ? const Icon(Icons.check, size: 18) : null,
              child: Text(source.quality, style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700) : null),
            );
          }).toList(),
        ),
      );
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.controller, required this.onInteraction});
  final VideoPlayerController controller;
  final VoidCallback onInteraction;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) => MenuAnchor(
          builder: (context, menu, child) => IconButton(color: Colors.white, tooltip: AppLocalizations.of(context)!.playbackSpeed, onPressed: menu.open, icon: const Icon(Icons.speed)),
          menuChildren: <double>[.5, .75, 1, 1.25, 1.5, 2, 3].map((speed) {
            final selected = value.playbackSpeed == speed;
            return MenuItemButton(
              onPressed: () { controller.setPlaybackSpeed(speed); onInteraction(); },
              leadingIcon: selected ? const Icon(Icons.check, size: 18) : null,
              child: Text('${speed}x', style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700) : null),
            );
          }).toList(),
        ),
      );
}

class VideoKeyframeDrawer extends ConsumerWidget {
  const VideoKeyframeDrawer({required this.video, required this.controller, super.key});
  final VideoDetail video;
  final ValueListenable<VideoPlayerController?> controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyframes = ref.watch(keyframesProvider(video.id)).valueOrNull ?? const <int>[];
    return Drawer(child: SafeArea(child: Column(children: [
      ListTile(title: Text(AppLocalizations.of(context)!.keyframes), subtitle: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
      const Divider(height: 1),
      Expanded(child: keyframes.isEmpty ? Center(child: Text(AppLocalizations.of(context)!.noKeyframes)) : ListView.separated(itemCount: keyframes.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) {
        final position = keyframes[index];
        return ListTile(title: Text(_formatKeyframe(position)), subtitle: Text('$position ms'), onTap: () { controller.value?.seekTo(Duration(milliseconds: position)); Navigator.of(context).pop(); }, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(keyframesProvider(video.id).notifier).remove(position)));
      })),
    ])));
  }

  String _formatKeyframe(int positionMs) {
    final position = Duration(milliseconds: positionMs);
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return position.inHours > 0 ? '${position.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}
