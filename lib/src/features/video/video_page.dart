import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/local/library_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/video.dart';
import '../account/account_controller.dart';
import 'video_actions.dart';
import 'video_comments.dart';
import 'video_controller.dart';
import 'video_detail_content.dart';
import 'video_player_panel.dart';

VideoCard? nextEpisode(VideoDetail video) {
  final episodes = video.playlist;
  final index = episodes.indexWhere((episode) => episode.id == video.id);
  if (index >= 0 && index + 1 < episodes.length) return episodes[index + 1];
  return episodes.firstWhere((episode) => episode.id != video.id, orElse: () => const VideoCard(id: '', title: '', coverUrl: ''));
}

void _playNext(BuildContext context, VideoDetail video) {
  final next = nextEpisode(video);
  if (next == null || next.id.isEmpty) return;
  context.pushReplacement('/video/${next.id}');
}

void _playEpisode(BuildContext context, VideoCard episode) {
  if (episode.id.isEmpty) return;
  context.pushReplacement('/video/${episode.id}');
}

class VideoPage extends ConsumerWidget {
  const VideoPage({super.key, required this.id, this.localVideo});

  final String id;
  final VideoDetail? localVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget withBackButton(Widget child) => Stack(children: [child, const SafeArea(child: Padding(padding: EdgeInsets.all(8), child: BackButton()))]);
    final content = localVideo == null
        ? ref.watch(videoDetailProvider(id)).when(
              loading: () => withBackButton(const Center(child: M3EContainedLoadingIndicator())),
              error: (error, stackTrace) => withBackButton(_VideoError(id: id, error: error)),
              data: (video) {
                ref.read(libraryProvider.notifier).addSubscriptionVideo(video);
                return _DetailBody(video: video);
              },
            )
        : _DetailBody(video: localVideo!);
    return Scaffold(backgroundColor: Theme.of(context).colorScheme.surface, body: content);
  }
}

class _VideoError extends ConsumerWidget {
  const _VideoError({required this.id, required this.error});

  final String id;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => ref.invalidate(videoDetailProvider(id)), child: Text(AppLocalizations.of(context)!.retry)),
              if (error is CloudflareChallengeException)
                TextButton(
                  onPressed: () async {
                    final url = (error as CloudflareChallengeException).url;
                    if (await context.push<bool>('/cloudflare', extra: url) == true) ref.invalidate(videoDetailProvider(id));
                  },
                  child: Text(AppLocalizations.of(context)!.completeCloudflareVerification),
                ),
            ],
          ),
        ),
      );
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.video});

  final VideoDetail video;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  late final M3EFloatingToolbarScrollBehavior _scrollBehavior = M3EFloatingToolbarScrollBehavior.exitAlways(exitDirection: M3EFloatingToolbarExitDirection.bottom);

  @override
  void initState() {
    super.initState();
    _scrollBehavior.state.offsetLimit = -144;
  }

  @override
  void dispose() {
    _scrollBehavior.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          if (isTablet) _TabletVideoLayout(video: video, scrollBehavior: _scrollBehavior) else _CompactVideoLayout(video: video, scrollBehavior: _scrollBehavior),
          Positioned(left: 0, right: isTablet ? MediaQuery.sizeOf(context).width * .3 : 0, bottom: 16, child: _FloatingControls(video: video, scrollBehavior: _scrollBehavior)),
        ],
      ),
    );
  }
}

class _CompactVideoLayout extends StatelessWidget {
  const _CompactVideoLayout({required this.video, required this.scrollBehavior});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: _VideoTabsView(video: video, scrollBehavior: scrollBehavior, showPlayer: true)),
      );
}

class _TabletVideoLayout extends StatelessWidget {
  const _TabletVideoLayout({required this.video, required this.scrollBehavior});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(flex: 7, child: ColoredBox(color: Colors.black, child: Center(child: VideoPlayerPanel(video: video, onBack: () => Navigator.maybePop(context), onNext: () => _playNext(context, video), onEpisodeSelected: (episode) => _playEpisode(context, episode))))),
          const VerticalDivider(width: 1),
          Expanded(flex: 3, child: _VideoTabsView(video: video, scrollBehavior: scrollBehavior, showPlayer: false)),
        ],
      );
}

class _FloatingControls extends ConsumerWidget {
  const _FloatingControls({required this.video, required this.scrollBehavior});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showComment = ref.watch(videoTabProvider(video.id)) == 1 && ref.watch(accountProvider).valueOrNull != null;
    return ListenableBuilder(
      listenable: scrollBehavior.state,
      builder: (context, child) {
        final state = scrollBehavior.state;
        return Transform.translate(
          offset: Offset(0, -state.offset),
          child: ExcludeFocus(
            excluding: state.collapsedFraction >= 1,
            child: IgnorePointer(
              ignoring: state.collapsedFraction >= 1,
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showComment) ...[
              FloatingActionButton(onPressed: () => writeSelectedVideoComment(context, ref, video.id), child: const Icon(Icons.add_comment_outlined)),
              const SizedBox(height: 8),
            ],
            VideoActionBar(video: video),
          ],
        ),
      ),
    );
  }
}

class _VideoTabsView extends ConsumerStatefulWidget {
  const _VideoTabsView({required this.video, required this.scrollBehavior, required this.showPlayer});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;
  final bool showPlayer;

  @override
  ConsumerState<_VideoTabsView> createState() => _VideoTabsViewState();
}

class _VideoTabsViewState extends ConsumerState<_VideoTabsView> with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final _playerCollapse = ValueNotifier(0.0);
  var _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this, initialIndex: ref.read(videoTabProvider(widget.video.id)));
    _controller.addListener(_syncTab);
  }

  @override
  void didUpdateWidget(_VideoTabsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _controller.index = ref.read(videoTabProvider(widget.video.id));
      _playerCollapse.value = 0;
      _isPlaying = false;
    }
  }

  void _syncTab() {
    if (_controller.indexIsChanging) return;
    ref.read(videoTabProvider(widget.video.id).notifier).state = _controller.index;
    widget.scrollBehavior.state
      ..contentOffset = 0
      ..offset = 0;
  }

  bool _handleScroll(ScrollNotification notification) {
    if (!widget.showPlayer || _isPlaying || notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollUpdateNotification && notification.scrollDelta != null) {
      final next = (_playerCollapse.value + notification.scrollDelta! / 240).clamp(0.0, 1.0).toDouble();
      if (next != _playerCollapse.value) _playerCollapse.value = next;
    }
    return false;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncTab);
    _controller.dispose();
    _playerCollapse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(videoTabProvider(widget.video.id));
    if (_controller.index != selected && !_controller.indexIsChanging) _controller.index = selected;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (widget.showPlayer)
          ValueListenableBuilder<double>(
            valueListenable: _playerCollapse,
            child: RepaintBoundary(child: VideoPlayerPanel(key: ValueKey(widget.video.id), video: widget.video, onBack: () => Navigator.maybePop(context), onNext: () => _playNext(context, widget.video), onEpisodeSelected: (episode) => _playEpisode(context, episode), onPlayingChanged: _setPlaying)),
            builder: (context, collapse, player) => Column(children: [ClipRect(child: Align(heightFactor: 1 - collapse, alignment: Alignment.topCenter, child: player)), if (collapse >= .99) SizedBox(height: 40, width: double.infinity, child: TextButton.icon(onPressed: () => _playerCollapse.value = 0, icon: const Icon(Icons.play_arrow), label: Text(l10n.play)))]),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.showPlayer ? 12 : 8, 16, 4),
          child: TabBar(
            controller: _controller,
            isScrollable: !widget.showPlayer,
            tabAlignment: !widget.showPlayer ? TabAlignment.start : null,
            tabs: [
              Tab(text: l10n.description),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l10n.comments), if (widget.video.commentCount case final count?) ...[const SizedBox(width: 5), Badge(label: Text('$count'))]])),
              Tab(text: l10n.relatedVideos),
            ],
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: TabBarView(
              controller: _controller,
              children: [
                M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: VideoDescriptionView(video: widget.video)),
                M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: VideoCommentsView(video: widget.video)),
                M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: RelatedVideosView(videos: widget.video.related)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _setPlaying(bool value) {
    if (_isPlaying == value) return;
    setState(() => _isPlaying = value);
  }
}
