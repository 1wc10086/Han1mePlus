import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/desktop_platform.dart';
import '../../data/local/library_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/video.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';
import 'player_controls_visibility.dart';
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

void _playNext(ValueChanged<VideoCard> onEpisodeSelected, VideoDetail video) {
  final next = nextEpisode(video);
  if (next == null || next.id.isEmpty) return;
  onEpisodeSelected(next);
}

String _homeQuery(String homeTarget) => homeTarget == '/' ? '' : '?home=$homeTarget';

class VideoPage extends ConsumerStatefulWidget {
  const VideoPage({super.key, required this.id, this.localVideo, this.homeTarget = '/'});

  final String id;
  final VideoDetail? localVideo;
  final String homeTarget;

  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  late String _id = widget.id;
  var _offlinePromptShown = false;

  @override
  void didUpdateWidget(VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id == widget.id || widget.localVideo != null) return;
    _id = widget.id;
    _offlinePromptShown = false;
  }

  void _switchEpisode(VideoCard episode) {
    if (episode.id.isEmpty || episode.id == _id) return;
    if (widget.localVideo != null) {
      context.pushReplacement('/video/${episode.id}${_homeQuery(widget.homeTarget)}');
      return;
    }
    setState(() {
      _id = episode.id;
      _offlinePromptShown = false;
    });
  }

  VideoDetail _withLocalSources(VideoDetail online, VideoDetail local) => VideoDetail(
        id: online.id,
        title: online.title,
        coverUrl: online.coverUrl,
        duration: online.duration,
        artist: online.artist,
        artistId: online.artistId,
        artistAvatarUrl: online.artistAvatarUrl,
        uploader: online.uploader,
        uploaderAvatarUrl: online.uploaderAvatarUrl,
        genre: online.genre,
        views: online.views,
        rating: online.rating,
        uploadDate: online.uploadDate,
        captionTitle: online.captionTitle,
        description: online.description,
        downloadUrl: online.downloadUrl,
        csrfToken: online.csrfToken,
        currentUserId: online.currentUserId,
        subscriptionUserId: online.subscriptionUserId,
        commentCount: online.commentCount,
        tags: online.tags,
        sources: local.sources,
        playlist: online.playlist,
        related: online.related,
      );

  @override
  Widget build(BuildContext context) {
    final localVideo = widget.localVideo;
    Widget withBackButton(Widget child) => Stack(
          children: [
            child,
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const BackButton(),
                  IconButton(tooltip: AppLocalizations.of(context)!.home, onPressed: () => context.go('/'), icon: const Icon(Icons.home_outlined)),
                ]),
              ),
            ),
          ],
        );
    Widget content;
    if (localVideo == null) {
      content = ref.watch(videoDetailProvider(_id)).when(
            loading: () => withBackButton(const Center(child: M3EContainedLoadingIndicator())),
            error: (error, stackTrace) => withBackButton(_VideoError(id: _id, error: error)),
            data: (video) {
              ref.read(libraryProvider.notifier).addSubscriptionVideo(video);
              return _DetailBody(video: video, homeTarget: widget.homeTarget, onEpisodeSelected: _switchEpisode);
            },
          );
    } else {
      final online = ref.watch(videoDetailProvider(_id)).valueOrNull;
      ref.listen(videoDetailProvider(_id), (previous, next) {
        if (_offlinePromptShown || !next.hasError) return;
        _offlinePromptShown = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.videoInfoOffline)));
      });
      content = _DetailBody(video: online == null ? localVideo : _withLocalSources(online, localVideo), homeTarget: widget.homeTarget, onEpisodeSelected: _switchEpisode);
    }
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
  const _DetailBody({required this.video, this.homeTarget = '/', required this.onEpisodeSelected});

  final VideoDetail video;
  final String homeTarget;
  final ValueChanged<VideoCard> onEpisodeSelected;

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
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final vertical = isTablet || landscape;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          if (isTablet)
            _TabletVideoLayout(video: video, scrollBehavior: _scrollBehavior, homeTarget: widget.homeTarget, onEpisodeSelected: widget.onEpisodeSelected)
          else
            _CompactVideoLayout(video: video, scrollBehavior: _scrollBehavior, homeTarget: widget.homeTarget, onEpisodeSelected: widget.onEpisodeSelected),
          Positioned(
            left: vertical ? null : 0,
            right: vertical ? 16 : 0,
            bottom: 16,
            child: _FloatingControls(video: video, scrollBehavior: _scrollBehavior, vertical: vertical, landscape: landscape),
          ),
        ],
      ),
    );
  }
}

class _CompactVideoLayout extends StatelessWidget {
  const _CompactVideoLayout({required this.video, required this.scrollBehavior, required this.homeTarget, required this.onEpisodeSelected});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;
  final String homeTarget;
  final ValueChanged<VideoCard> onEpisodeSelected;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: _VideoTabsView(video: video, scrollBehavior: scrollBehavior, showPlayer: true, homeTarget: homeTarget, onEpisodeSelected: onEpisodeSelected)),
      );
}

class _TabletVideoLayout extends StatelessWidget {
  const _TabletVideoLayout({required this.video, required this.scrollBehavior, required this.homeTarget, required this.onEpisodeSelected});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;
  final String homeTarget;
  final ValueChanged<VideoCard> onEpisodeSelected;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(flex: 7, child: ColoredBox(color: Colors.black, child: Center(child: VideoPlayerPanel(video: video, onBack: () => Navigator.maybePop(context), onHome: () => context.go(homeTarget), onNext: () => _playNext(onEpisodeSelected, video), onEpisodeSelected: onEpisodeSelected)))),
          const VerticalDivider(width: 1),
          Expanded(flex: 3, child: ExcludeFocus(excluding: isDesktopPlatformService, child: _VideoTabsView(video: video, scrollBehavior: scrollBehavior, showPlayer: false, homeTarget: homeTarget, onEpisodeSelected: onEpisodeSelected))),
        ],
      );
}

class _FloatingControls extends ConsumerWidget {
  const _FloatingControls({required this.video, required this.scrollBehavior, this.vertical = false, this.landscape = false});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;
  final bool vertical;
  final bool landscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final followScroll = landscape ? landscapeFloatingBarVisible(ref, landscape: true) : (settings?.hideActionsOnScroll ?? true);
    if (landscape && !followScroll) return const SizedBox.shrink();
    final showComment = (settings?.commentsEnabled ?? false) && ref.watch(videoTabProvider(video.id)) == 1 && ref.watch(accountProvider).valueOrNull != null;
    final actionColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showComment) ...[
          FloatingActionButton(onPressed: () => writeSelectedVideoComment(context, ref, video.id), child: const Icon(Icons.add_comment_outlined)),
          const SizedBox(height: 8),
        ],
        VideoActionBar(video: video, vertical: vertical),
      ],
    );
    final aligned = vertical ? Align(alignment: Alignment.bottomRight, child: actionColumn) : Center(child: actionColumn);
    if (!followScroll) return ExcludeFocus(excluding: isDesktopPlatformService, child: aligned);
    return ListenableBuilder(
      listenable: scrollBehavior.state,
      builder: (context, child) {
        final state = scrollBehavior.state;
        return Transform.translate(
          offset: vertical ? Offset(-state.offset, 0) : Offset(0, -state.offset),
          child: ExcludeFocus(
            excluding: state.collapsedFraction >= 1 || isDesktopPlatformService,
            child: IgnorePointer(
              ignoring: state.collapsedFraction >= 1,
              child: child,
            ),
          ),
        );
      },
      child: aligned,
    );
  }
}

class _VideoTabsView extends ConsumerStatefulWidget {
  const _VideoTabsView({required this.video, required this.scrollBehavior, required this.showPlayer, required this.homeTarget, required this.onEpisodeSelected});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;
  final bool showPlayer;
  final String homeTarget;
  final ValueChanged<VideoCard> onEpisodeSelected;

  @override
  ConsumerState<_VideoTabsView> createState() => _VideoTabsViewState();
}

class _VideoTabsViewState extends ConsumerState<_VideoTabsView> with TickerProviderStateMixin {
  static const _settleDuration = Duration(milliseconds: 140);
  static const _fallbackExtent = 240.0;
  static const _expandBarHeight = 40.0;
  static const _barRevealStart = .86;
  TabController? _controller;
  int _tabCount = 0;
  final _playerKey = GlobalKey();
  late final AnimationController _collapse = AnimationController(vsync: this, duration: _settleDuration, value: 0);
  var _expandedExtent = _fallbackExtent;

  bool get _commentsEnabled => ref.read(settingsProvider).valueOrNull?.commentsEnabled ?? false;

  int _clampIndex(int value, int count) => value < 0 ? 0 : (value >= count ? count - 1 : value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureController();
  }

  @override
  void didUpdateWidget(_VideoTabsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _collapse.value = 0;
      _expandedExtent = _fallbackExtent;
    }
  }

  void _ensureController() {
    final count = _commentsEnabled ? 3 : 2;
    if (_controller != null && _tabCount == count) return;
    final previous = _controller;
    final stored = ref.read(videoTabProvider(widget.video.id));
    _tabCount = count;
    _controller = TabController(length: count, vsync: this, initialIndex: _clampIndex(stored, count));
    _controller!.addListener(_syncTab);
    if (previous != null) {
      previous.removeListener(_syncTab);
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _syncTab() {
    final controller = _controller;
    if (controller == null || controller.indexIsChanging) return;
    ref.read(videoTabProvider(widget.video.id).notifier).state = controller.index;
    widget.scrollBehavior.state
      ..contentOffset = 0
      ..offset = 0;
  }

  void _setCollapsed(bool collapsed) {
    _collapse.animateTo(collapsed ? 1 : 0, duration: _settleDuration, curve: Curves.easeOut);
  }

  bool _handleScroll(ScrollNotification notification) {
    if (!widget.showPlayer) return false;
    if (notification is ScrollEndNotification) _settleCollapse();
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      if (_collapse.value > 0) _collapseBy(-notification.overscroll);
    }
    return false;
  }

  void _settleCollapse() {
    final value = _collapse.value;
    if (value <= 0 || value >= 1) return;
    _collapse.animateTo(value >= .5 ? 1 : 0, duration: _settleDuration, curve: Curves.easeOut);
  }

  double _collapseBy(double delta) {
    if (delta == 0 || !widget.showPlayer) return 0;
    _measureExpandedExtent();
    if (delta > 0) {
      if (_collapse.value >= 1) return 0;
      final remaining = (1 - _collapse.value) * _expandedExtent;
      final take = delta < remaining ? delta : remaining;
      _applyCollapse(_collapse.value + take / _expandedExtent);
      return take;
    }
    if (_collapse.value <= 0) return 0;
    final available = _collapse.value * _expandedExtent;
    final take = -delta < available ? -delta : available;
    _applyCollapse(_collapse.value - take / _expandedExtent);
    return take;
  }

  void _measureExpandedExtent() {
    final size = _playerKey.currentContext?.size;
    if (size != null && size.height > 80) _expandedExtent = size.height;
  }

  void _applyCollapse(double value) {
    _collapse.value = value < 0 ? 0.0 : (value > 1 ? 1.0 : value);
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncTab);
    _controller?.dispose();
    _collapse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((value) => value.valueOrNull?.commentsEnabled ?? false));
    _ensureController();
    final controller = _controller!;
    final selected = ref.watch(videoTabProvider(widget.video.id));
    final target = _clampIndex(selected, controller.length);
    if (!controller.indexIsChanging && controller.index != target) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final active = _controller;
        if (active == null || active.index == target || active.indexIsChanging) return;
        active.index = target;
      });
    }
    final l10n = AppLocalizations.of(context)!;
    final commentsEnabled = _commentsEnabled;
    return Column(
      children: [
        if (widget.showPlayer)
          Column(
            children: [
              AnimatedBuilder(
                animation: _collapse,
                child: RepaintBoundary(
                  key: _playerKey,
                  child: VideoPlayerPanel(
                    key: ValueKey(widget.video.id),
                    video: widget.video,
                    onBack: () => Navigator.maybePop(context),
                    onHome: () => context.go(widget.homeTarget),
                    onNext: () => _playNext(widget.onEpisodeSelected, widget.video),
                    onEpisodeSelected: widget.onEpisodeSelected,
                  ),
                ),
                builder: (context, player) {
                  final progress = _collapse.value;
                  final playerFactor = progress >= .99 ? 0.0 : 1 - progress;
                  final barFactor = progress <= _barRevealStart ? 0.0 : ((progress - _barRevealStart) / (1 - _barRevealStart)).clamp(0.0, 1.0).toDouble();
                  return Column(
                    children: [
                      ClipRect(child: Align(heightFactor: playerFactor, alignment: Alignment.topCenter, child: player)),
                      ClipRect(
                        child: Align(
                          heightFactor: barFactor,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            height: _expandBarHeight,
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => _setCollapsed(false),
                              icon: const Icon(Icons.expand_more),
                              label: Text(l10n.play),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ExcludeFocus(
          excluding: isDesktopPlatformService,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, widget.showPlayer ? 12 : 8, 16, 4),
            child: TabBar(
              controller: controller,
              isScrollable: !widget.showPlayer,
              tabAlignment: !widget.showPlayer ? TabAlignment.start : null,
              tabs: [
                Tab(text: l10n.description),
                if (commentsEnabled)
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l10n.comments), if (widget.video.commentCount case final count?) ...[const SizedBox(width: 5), Badge(label: Text('$count'))]])),
                Tab(text: l10n.relatedVideos),
              ],
            ),
          ),
        ),
        Expanded(
          child: ExcludeFocus(
            excluding: isDesktopPlatformService,
            child: AnimatedBuilder(
              animation: _collapse,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: TabBarView(
                  controller: controller,
                  children: [
                    M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: VideoDescriptionView(video: widget.video, onEpisodeSelected: widget.onEpisodeSelected)),
                    if (commentsEnabled) M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: VideoCommentsView(video: widget.video)),
                    M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: RelatedVideosView(videos: widget.video.related)),
                  ],
                ),
              ),
              builder: (context, child) {
                if (!widget.showPlayer || _collapse.value >= 1) return child!;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(physics: const NeverScrollableScrollPhysics()),
                        child: child!,
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: _dragCollapse,
                        onVerticalDragEnd: _endCollapseDrag,
                        onVerticalDragCancel: () => _settleCollapse(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _dragCollapse(DragUpdateDetails details) => _collapseBy(-details.delta.dy);

  void _endCollapseDrag(DragEndDetails details) => _settleCollapse();
}
