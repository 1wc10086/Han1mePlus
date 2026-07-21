import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/local/watch_repository.dart';
import '../../data/local/keyframe_repository.dart';
import '../../core/settings.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

class VideoPlayerPanel extends ConsumerStatefulWidget {
  const VideoPlayerPanel({super.key, required this.video});
  final VideoDetail video;

  @override
  ConsumerState<VideoPlayerPanel> createState() => _VideoPlayerPanelState();
}

class _VideoPlayerPanelState extends ConsumerState<VideoPlayerPanel> {
  VideoPlayerController? _controller;
  DateTime? _playingSince;
  var _playedMs = 0;
  var _persistedPlayedMs = 0;
  DateTime _lastStatisticsFlush = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);
  bool _showControls = true;
  bool _isLongPressing = false;
  bool _hasRestoredPosition = false;
  bool _isRestoringPosition = false;
  int? _dragStartPositionMs;
  double _dragDelta = 0;
  String? _loadedQuality;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSource());
  }

  @override
  void didUpdateWidget(VideoPlayerPanel oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (oldWidget.video.id != widget.video.id) {
        _loadedQuality = null;
        _hasRestoredPosition = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncSource());
      }
  }

  void _syncSource() {
    if (widget.video.sources.isEmpty) return;
    final settings = ref.read(settingsProvider).valueOrNull;
    final preferredQuality = settings?.preferredQuality ?? 720;
    final source = _preferredSource(preferredQuality);
    if (source.quality != _loadedQuality) _load(source);
  }

  VideoSource _preferredSource(int quality) {
    return widget.video.sources.reduce((best, candidate) {
      final bestDistance = (_qualityValue(best) - quality).abs();
      final candidateDistance = (_qualityValue(candidate) - quality).abs();
      return candidateDistance < bestDistance ? candidate : best;
    });
  }

  int _qualityValue(VideoSource source) => int.tryParse(RegExp(r'\d+').firstMatch(source.quality)?.group(0) ?? '') ?? 720;

  Future<void> _load(VideoSource? source) async {
    await _controller?.dispose();
    _controller = null;
    _loadedQuality = null;
    if (source == null || source.url.isEmpty) return;
    final controller = source.url.startsWith('/')
        ? VideoPlayerController.file(File(source.url))
        : VideoPlayerController.networkUrl(Uri.parse(source.url));
    _loadedQuality = source.quality;
    setState(() => _controller = controller);
    try {
      _isRestoringPosition = true;
      final resumePosition = await _resumePosition();
      if (controller != _controller) return;
      controller.addListener(_onTick);
      await controller.initialize();
      if (resumePosition != null && controller == _controller) {
        await controller.seekTo(resumePosition);
      }
      _hasRestoredPosition = true;
      _isRestoringPosition = false;
      _lastSaved = DateTime.now();
      if (mounted) setState(() {});
    } catch (_) {
      _isRestoringPosition = false;
      if (mounted) setState(() {});
    }
  }

  Future<Duration?> _resumePosition() async {
    if (_hasRestoredPosition || !(ref.read(settingsProvider).valueOrNull?.resumePlayback ?? true)) return null;
    final watch = await ref.read(watchProvider.future);
    if (!mounted) return null;
    final progress = watch.continueItems.where((item) => item.videoCode == widget.video.id).firstOrNull;
    if (progress == null || progress.positionMs <= 0 || progress.durationMs <= 0 || progress.positionMs >= progress.durationMs - 3000) return null;
    return Duration(milliseconds: progress.positionMs);
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isRestoringPosition) return;
    if (controller.value.isPlaying) {
      _playingSince ??= DateTime.now();
      if (DateTime.now().difference(_lastStatisticsFlush).inSeconds >= 15) {
        _savePlayedTime();
        _lastStatisticsFlush = DateTime.now();
        unawaited(_persistPlayedTime());
      }
    } else {
      _savePlayedTime();
      unawaited(_persistPlayedTime());
    }
    final now = DateTime.now();
    if (now.difference(_lastSaved).inSeconds >= 5) {
      _lastSaved = now;
      ref.read(watchProvider.notifier).progress(
            id: widget.video.id,
            title: widget.video.title,
            coverUrl: widget.video.coverUrl,
            positionMs: controller.value.position.inMilliseconds,
            durationMs: controller.value.duration.inMilliseconds,
      );
    }
  }

  void _savePlayedTime() {
    final started = _playingSince;
    if (started == null) return;
    _playedMs += DateTime.now().difference(started).inMilliseconds;
    _playingSince = null;
  }

  Future<void> _persistPlayedTime() async {
    final unpersisted = _playedMs - _persistedPlayedMs;
    if (unpersisted < 2000) return;
    _persistedPlayedMs = _playedMs;
    await ref.read(watchProvider.notifier).addTime(widget.video.id, widget.video.title, unpersisted);
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _toggleLongPress(bool active) {
    setState(() => _isLongPressing = active);
    _controller?.setPlaybackSpeed(active ? 2.0 : 1.0);
  }

  void _startSeekDrag(DragStartDetails details) {
    _dragStartPositionMs = _controller?.value.position.inMilliseconds;
    _dragDelta = 0;
  }

  void _seekFromDrag(DragUpdateDetails details, double width) {
    final controller = _controller;
    final startPositionMs = _dragStartPositionMs;
    if (controller == null || startPositionMs == null || width <= 0) return;
    _dragDelta += details.delta.dx;
    final durationMs = controller.value.duration.inMilliseconds;
    final targetMs = (startPositionMs + _dragDelta / width * durationMs).round().clamp(0, durationMs).toInt();
    controller.seekTo(Duration(milliseconds: targetMs));
  }

  void _endSeekDrag(DragEndDetails details) => _dragStartPositionMs = null;

  Future<void> _enterFullscreen() async {
    final controller = _controller;
    if (controller == null) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _FullscreenPlayer(controller: controller, video: widget.video)));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      ref.read(watchProvider.notifier).progress(
            id: widget.video.id,
            title: widget.video.title,
            coverUrl: widget.video.coverUrl,
            positionMs: controller.value.position.inMilliseconds,
            durationMs: controller.value.duration.inMilliseconds,
          );
    }
    _savePlayedTime();
    unawaited(_persistPlayedTime());
    controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(settingsProvider.select((value) => value.valueOrNull?.preferredQuality ?? 720), (_, __) => _syncSource());
    final controller = _controller;
    if (controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    if (!controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      onLongPressStart: (_) => _toggleLongPress(true),
      onLongPressEnd: (_) => _toggleLongPress(false),
      onHorizontalDragStart: _startSeekDrag,
      onHorizontalDragUpdate: (details) => _seekFromDrag(details, MediaQuery.sizeOf(context).width),
      onHorizontalDragEnd: _endSeekDrag,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black, child: VideoPlayer(controller)),
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Controls(
                  key: const ValueKey('controls'),
                  controller: controller,
                  onFullscreen: _enterFullscreen,
                  isFullscreen: false,
                ),
              ),
            if (_isLongPressing)
              const Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(child: _SpeedBadge()),
              ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({super.key, required this.controller, required this.onFullscreen, required this.isFullscreen});

  final VideoPlayerController controller;
  final Future<void> Function() onFullscreen;
  final bool isFullscreen;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final progress = value.duration.inMilliseconds == 0
          ? 0.0
          : (value.position.inMilliseconds / value.duration.inMilliseconds).clamp(0.0, 1.0);
      return Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(color: Colors.white, tooltip: value.isPlaying ? AppLocalizations.of(context)!.pause : AppLocalizations.of(context)!.play, onPressed: () => value.isPlaying ? controller.pause() : controller.play(), icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(_format(value.position), style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (next) async {
                        final target = Duration(milliseconds: (next * value.duration.inMilliseconds).toInt());
                        await controller.seekTo(target);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(_format(value.duration), style: const TextStyle(color: Colors.white)),
                IconButton(color: Colors.white, tooltip: isFullscreen ? AppLocalizations.of(context)!.exitFullscreen : AppLocalizations.of(context)!.fullscreenPlayback, onPressed: onFullscreen, icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen)),
              ],
            ),
          ),
        ],
        );
    },
  );

  static String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _FullscreenPlayer extends ConsumerStatefulWidget {
  const _FullscreenPlayer({required this.controller, required this.video});
  final VideoPlayerController controller;
  final VideoDetail video;

  @override
  ConsumerState<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends ConsumerState<_FullscreenPlayer> {
  var _showControls = true;
  var _accelerating = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _dragStartPositionMs;
  double _dragDelta = 0;

  void _longPress(bool active) {
    setState(() => _accelerating = active);
    widget.controller.setPlaybackSpeed(active ? 2 : 1);
  }

  void _startSeekDrag(DragStartDetails details) {
    _dragStartPositionMs = widget.controller.value.position.inMilliseconds;
    _dragDelta = 0;
  }

  void _seekFromDrag(DragUpdateDetails details, double width) {
    final startPositionMs = _dragStartPositionMs;
    if (startPositionMs == null || width <= 0) return;
    _dragDelta += details.delta.dx;
    final durationMs = widget.controller.value.duration.inMilliseconds;
    final targetMs = (startPositionMs + _dragDelta / width * durationMs).round().clamp(0, durationMs).toInt();
    widget.controller.seekTo(Duration(milliseconds: targetMs));
  }

  void _endSeekDrag(DragEndDetails details) => _dragStartPositionMs = null;

  Future<void> _addKeyframe() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.controller.value.isPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pauseBeforeAddingKeyframe)));
      return;
    }
    if (!mounted) return;
    final positionMs = widget.controller.value.position.inMilliseconds;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.addKeyframe), content: Text(l10n.addKeyframeConfirmation(positionMs)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.add))]));
    if (confirmed != true || !mounted) return;
    await ref.read(keyframesProvider(widget.video.id).future);
    if (!mounted) return;
    final added = await ref.read(keyframesProvider(widget.video.id).notifier).add(positionMs, title: widget.video.title);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? l10n.keyframeAdded : l10n.keyframeTooClose)));
  }

  @override
  Widget build(BuildContext context) {
    final keyframes = ref.watch(keyframesProvider(widget.video.id)).value ?? const <int>[];
    final enabled = ref.watch(settingsProvider).valueOrNull?.keyframesEnabled ?? true;
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        endDrawer: _KeyframeDrawer(video: widget.video, controller: widget.controller),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showControls = !_showControls),
                onLongPressStart: (_) => _longPress(true),
                onLongPressEnd: (_) => _longPress(false),
                onHorizontalDragStart: _startSeekDrag,
                onHorizontalDragUpdate: (details) => _seekFromDrag(details, MediaQuery.sizeOf(context).width),
                onHorizontalDragEnd: _endSeekDrag,
                child: Center(child: AspectRatio(aspectRatio: widget.controller.value.aspectRatio == 0 ? 16 / 9 : widget.controller.value.aspectRatio, child: VideoPlayer(widget.controller))),
              ),
              if (enabled) _KeyframeCountdown(controller: widget.controller, keyframes: keyframes),
              if (_showControls) Positioned(left: 0, right: 0, bottom: 0, child: _Controls(controller: widget.controller, onFullscreen: () async => Navigator.of(context).pop(), isFullscreen: true)),
              if (_accelerating) const Positioned(top: 16, left: 0, right: 0, child: Center(child: _SpeedBadge())),
              if (enabled)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _KeyframeButton(
                    onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    onLongPress: _addKeyframe,
                  ),
                ),
            ],
          ),
        ),
      );
  }
}

class _KeyframeButton extends StatelessWidget {
  const _KeyframeButton({required this.onTap, required this.onLongPress});
  final VoidCallback onTap;
  final Future<void> Function() onLongPress;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: AppLocalizations.of(context)!.longPressAddKeyframe,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('🥵', style: TextStyle(fontSize: 24)),
          ),
        ),
      );
}

class _KeyframeDrawer extends ConsumerWidget {
  const _KeyframeDrawer({required this.video, required this.controller});

  final VideoDetail video;
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyframes = ref.watch(keyframesProvider(video.id)).value ?? const <int>[];
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.keyframes),
              subtitle: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            Expanded(
              child: keyframes.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.noKeyframes))
                  : ListView.separated(
                      itemCount: keyframes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final position = keyframes[index];
                        return ListTile(
                          title: Text(_format(position)),
                          subtitle: Text('$position ms'),
                          onTap: () => controller.seekTo(Duration(milliseconds: position)),
                          trailing: PopupMenuButton<_KeyframeAction>(
                            onSelected: (action) => switch (action) {
                              _KeyframeAction.edit => _editPosition(context, ref, position),
                              _KeyframeAction.delete => ref.read(keyframesProvider(video.id).notifier).remove(position),
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: _KeyframeAction.edit, child: Text(AppLocalizations.of(context)!.editPosition)),
                              PopupMenuItem(value: _KeyframeAction.delete, child: Text(AppLocalizations.of(context)!.deleteKeyframe)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(AppLocalizations.of(context)!.deleteCurrentVideoKeyframes),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.deleteKeyframeTitle),
                    content: Text(AppLocalizations.of(context)!.deleteCurrentVideoKeyframesConfirmation),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete)),
                    ],
                  ),
                );
                if (confirmed == true) await ref.read(keyframesProvider(video.id).notifier).deleteVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPosition(BuildContext context, WidgetRef ref, int position) async {
    final l10n = AppLocalizations.of(context)!;
    final input = TextEditingController(text: position.toString());
    final next = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editKeyframe),
        content: TextField(
          controller: input,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.positionMilliseconds),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(input.text)), child: Text(l10n.save)),
        ],
      ),
    );
    if (next == null || next == position) return;
    final updated = await ref.read(keyframesProvider(video.id).notifier).updatePosition(position, next);
    if (context.mounted && !updated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidKeyframe)));
    }
  }

  static String _format(int positionMs) {
    final duration = Duration(milliseconds: positionMs);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}

enum _KeyframeAction { edit, delete }

class _KeyframeCountdown extends StatelessWidget {
  const _KeyframeCountdown({required this.controller, required this.keyframes});
  final VideoPlayerController controller;
  final List<int> keyframes;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final next = keyframes.where((item) => item >= value.position.inMilliseconds).firstOrNull;
          final remaining = next == null ? null : next - value.position.inMilliseconds;
          if (remaining == null || remaining > 10000) return const SizedBox.shrink();
          return Positioned(left: 16, top: 16, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text(AppLocalizations.of(context)!.keyframeCountdown((remaining / 1000).toStringAsFixed(1)), style: const TextStyle(color: Colors.white)))));
        },
      );
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge();
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('2x', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}

extension on Iterable<int> {
  int? get firstOrNull => isEmpty ? null : first;
}
