import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/han1me_repository.dart';
import '../../data/local/download_repository.dart';
import '../../data/local/library_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/video.dart';
import '../../domain/models/library.dart';
import '../shared/video_card.dart';
import '../shared/comments_page.dart' show CommentCard, CommentSort, CommentEditor;
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';
import '../library/remote_library_controller.dart';
import 'comments_controller.dart';
import 'video_controller.dart';
import 'video_player_panel.dart';

final videoTabProvider = StateProvider.autoDispose.family<int, String>((ref, id) => 0);
final videoCommentSortProvider = StateProvider.autoDispose.family<CommentSort, String>((ref, id) => CommentSort.latest);
final favoriteOverrideProvider = StateProvider.autoDispose.family<bool?, String>((ref, id) => null);
final subscriptionOverrideProvider = StateProvider.autoDispose.family<bool?, String>((ref, id) => null);

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
    Widget withBackButton(Widget child) => Stack(
          children: [
            child,
            const SafeArea(child: Padding(padding: EdgeInsets.all(8), child: BackButton())),
          ],
        );

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: ref.watch(videoTabProvider(id)) == 1 && ref.watch(accountProvider).valueOrNull != null
          ? FloatingActionButton(onPressed: () => _writeComment(context, ref), child: const Icon(Icons.add_comment_outlined))
          : null,
      body: content,
    );
  }

  Future<void> _writeComment(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(context: context, builder: (_) => CommentEditor(title: AppLocalizations.of(context)!.writeComment));
    final page = ref.read(commentsProvider(id)).valueOrNull;
    if (text == null || text.isEmpty || page?.csrfToken == null || page?.currentUserId == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).postComment(settings.resolvedBaseUrl, page!.csrfToken!, page.currentUserId!, 'video', id, text);
    ref.invalidate(commentsProvider(id));
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
              FilledButton(
                onPressed: () => ref.invalidate(videoDetailProvider(id)),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
              if (error is CloudflareChallengeException)
                TextButton(
                  onPressed: () async {
                    final url = (error as CloudflareChallengeException).url;
                    if (await context.push<bool>('/cloudflare', extra: url) == true) {
                      ref.invalidate(videoDetailProvider(id));
                    }
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
  Widget build(BuildContext context) {
    final video = widget.video;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SafeArea(
      bottom: false,
      child: isTablet
          ? _TabletVideoLayout(video: video, scrollBehavior: _scrollBehavior)
          : _CompactVideoLayout(video: video, scrollBehavior: _scrollBehavior),
    );
  }
}

class _CompactVideoLayout extends ConsumerWidget {
  const _CompactVideoLayout({required this.video, required this.scrollBehavior});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(videoTabProvider(video.id));
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: _VideoTabsView(video: video, scrollBehavior: scrollBehavior, showPlayer: true),
          ),
        ),
        Positioned(
          left: 16,
          right: selected == 1 ? 88 : 16,
          bottom: 16,
          child: _ActionBar(video: video, scrollBehavior: scrollBehavior),
        ),
      ],
    );
  }
}

class _TabletVideoLayout extends StatelessWidget {
  const _TabletVideoLayout({required this.video, required this.scrollBehavior});

  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 7,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                children: [
                  Center(child: VideoPlayerPanel(video: video, onBack: () => Navigator.maybePop(context), onNext: () => _playNext(context, video), onEpisodeSelected: (episode) => _playEpisode(context, episode))),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _ActionBar(video: video, scrollBehavior: scrollBehavior),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: _VideoTabsView(video: video, scrollBehavior: scrollBehavior, showPlayer: false),
          ),
        ],
      );
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
    _controller = TabController(length: 2, vsync: this, initialIndex: ref.read(videoTabProvider(widget.video.id)));
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
        if (widget.showPlayer) ...[
          ValueListenableBuilder<double>(
            valueListenable: _playerCollapse,
            child: RepaintBoundary(child: VideoPlayerPanel(key: ValueKey(widget.video.id), video: widget.video, onBack: () => Navigator.maybePop(context), onNext: () => _playNext(context, widget.video), onEpisodeSelected: (episode) => _playEpisode(context, episode), onPlayingChanged: _setPlaying)),
            builder: (context, collapse, player) => Column(children: [
              ClipRect(child: Align(heightFactor: 1 - collapse, alignment: Alignment.topCenter, child: player)),
              if (collapse >= .99) SizedBox(height: 40, width: double.infinity, child: TextButton.icon(onPressed: () => _playerCollapse.value = 0, icon: const Icon(Icons.play_arrow), label: Text(AppLocalizations.of(context)!.play))),
            ]),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.showPlayer ? 12 : 8, 16, 4),
          child: TabBar(controller: _controller, tabs: [Tab(text: l10n.description), Tab(text: l10n.comments)]),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(onNotification: _handleScroll, child: TabBarView(controller: _controller, children: [M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: _DescriptionView(video: widget.video)), M3EFloatingToolbarScrollWrapper(behavior: widget.scrollBehavior, child: _CommentsView(video: widget.video))])),
        ),
      ],
    );
  }

  void _setPlaying(bool value) {
    if (_isPlaying == value) return;
    setState(() => _isPlaying = value);
  }
}

class _DescriptionView extends StatefulWidget {
  const _DescriptionView({required this.video});
  final VideoDetail video;

  @override
  State<_DescriptionView> createState() => _DescriptionViewState();
}

class _DescriptionViewState extends State<_DescriptionView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final video = widget.video;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TitleBlock(video: video),
              _ArtistRow(video: video),
              _Description(video: video),
              _TagList(tags: video.tags),
              if (video.playlist.isNotEmpty) _SeriesVideos(videos: video.playlist, currentVideoId: video.id),
              if (video.related.isNotEmpty) ...[
                _SectionHeader(title: AppLocalizations.of(context)!.relatedVideos),
                _RelatedVideos(videos: video.related),
              ],
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

class _CommentsView extends ConsumerStatefulWidget {
  const _CommentsView({required this.video});
  final VideoDetail video;

  @override
  ConsumerState<_CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends ConsumerState<_CommentsView> with AutomaticKeepAliveClientMixin {
  late String _commentVideoId;

  @override
  void initState() {
    super.initState();
    _commentVideoId = widget.video.id;
  }

  @override
  void didUpdateWidget(_CommentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) _commentVideoId = widget.video.id;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _CommentEpisodeBar(video: widget.video, commentVideoId: _commentVideoId, onSelected: (id) => setState(() => _commentVideoId = id))),
        _CommentsSliver(id: _commentVideoId),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

class _CommentEpisodeBar extends ConsumerWidget {
  const _CommentEpisodeBar({required this.video, required this.commentVideoId, required this.onSelected});
  final VideoDetail video;
  final String commentVideoId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = video.playlist.where((episode) => episode.id == commentVideoId).firstOrNull;
    final title = selected?.title ?? video.title;
    final sort = ref.watch(videoCommentSortProvider(commentVideoId));
    return Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Row(children: [Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)), MenuAnchor(builder: (context, controller, child) => IconButton(tooltip: AppLocalizations.of(context)!.episodeList, onPressed: controller.open, icon: const Icon(Icons.switch_video_outlined)), menuChildren: [for (final episode in video.playlist) MenuItemButton(onPressed: () => onSelected(episode.id), child: Text(episode.title, maxLines: 1, overflow: TextOverflow.ellipsis))]), MenuAnchor(builder: (context, controller, child) => IconButton(tooltip: AppLocalizations.of(context)!.sort(AppLocalizations.of(context)!.defaultValue), onPressed: controller.open, icon: const Icon(Icons.sort)), menuChildren: CommentSort.values.map((item) => MenuItemButton(onPressed: () => ref.read(videoCommentSortProvider(commentVideoId).notifier).state = item, child: Text(_sortLabel(context, item), style: item == sort ? TextStyle(color: Theme.of(context).colorScheme.primary) : null))).toList())]));
  }
}

String _sortLabel(BuildContext context, CommentSort value) {
  final l10n = AppLocalizations.of(context)!;
  return switch (value) { CommentSort.latest => l10n.latest, CommentSort.earliest => l10n.earliest, CommentSort.mostReplies => l10n.mostReplies, CommentSort.mostLikes => l10n.mostLikes, CommentSort.mostDislikes => l10n.mostDislikes };
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.video});
  final VideoDetail video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(video.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (video.views != null) _MetaText(icon: Icons.visibility_outlined, label: video.views!),
              if (video.uploadDate != null) _MetaText(icon: Icons.calendar_today_outlined, label: video.uploadDate!),
              if (video.genre != null) _MetaText(icon: Icons.local_offer_outlined, label: video.genre!),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtistRow extends ConsumerWidget {
  const _ArtistRow({required this.video});
  final VideoDetail video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if ((video.artist ?? '').isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final account = ref.watch(accountProvider).valueOrNull;
    final remote = account == null ? null : ref.watch(remoteLibraryProvider).valueOrNull;
    final library = ref.watch(libraryProvider).value ?? const LibraryState();
    final persistedSubscription = (remote?.subscriptionArtists ?? library.artists).any((item) => item.name == video.artist);
    final subscribed = ref.watch(subscriptionOverrideProvider(video.id)) ?? persistedSubscription;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('/search', extra: _artistSearch(video.artist!)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: video.artistAvatarUrl == null ? null : NetworkImage(video.artistAvatarUrl!),
            child: video.artistAvatarUrl == null
                ? Text(video.artist!.characters.first, style: theme.textTheme.titleMedium)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.artist!, style: theme.textTheme.titleMedium),
                Text(AppLocalizations.of(context)!.studio, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: account == null
                ? () => ref.read(libraryProvider.notifier).setSubscription(video, !subscribed)
                : video.artistId == null || (video.csrfToken ?? account.csrfToken) == null || (video.subscriptionUserId ?? video.currentUserId ?? account.id) == null
                    ? null
                    : () => _setSubscription(ref, video.csrfToken ?? account.csrfToken!, video.subscriptionUserId ?? video.currentUserId ?? account.id!, video.artistId!, !subscribed),
            child: Text(subscribed ? AppLocalizations.of(context)!.subscribed : AppLocalizations.of(context)!.subscribe),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setSubscription(WidgetRef ref, String token, String userId, String artistId, bool enabled) async {
    ref.read(subscriptionOverrideProvider(video.id).notifier).state = enabled;
    try {
      final settings = await ref.read(settingsProvider.future);
      await ref.read(han1meRepositoryProvider).setSubscription(settings.resolvedBaseUrl, token, userId, artistId, enabled);
      ref.invalidate(remoteLibraryProvider);
    } catch (_) {
      ref.read(subscriptionOverrideProvider(video.id).notifier).state = !enabled;
    }
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.video, required this.scrollBehavior});
  final VideoDetail video;
  final M3EFloatingToolbarScrollBehavior scrollBehavior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider).value ?? const LibraryState();
    final account = ref.watch(accountProvider).valueOrNull;
    final remote = account == null ? null : ref.watch(remoteLibraryProvider).valueOrNull;
    final inWatchLater = (remote?.watchLater ?? library.watchLater).any((item) => item.videoCode == video.id);
    final persistedFavorite = (remote?.favorites ?? library.favorites).any((item) => item.videoCode == video.id);
    final inFavorites = ref.watch(favoriteOverrideProvider(video.id)) ?? persistedFavorite;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: M3EHorizontalFloatingToolbar(
        expanded: true,
        scrollBehavior: scrollBehavior,
        content: Row(
          mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.addToPlaylist,
            icon: Icon(inWatchLater ? Icons.playlist_add_check : Icons.playlist_add),
            onPressed: () => account == null ? _pickLocalPlaylist(context, ref, library) : _pickPlaylist(context, ref, video.csrfToken ?? remote?.csrfToken ?? account.csrfToken, remote),
          ),
          IconButton(
            tooltip: l10n.favorite,
            icon: Icon(inFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: () => _toggleFavorite(ref, account == null ? null : video.csrfToken ?? account.csrfToken, account == null ? null : video.currentUserId ?? account.id, !inFavorites),
          ),
          IconButton(
            tooltip: l10n.download,
            icon: const Icon(Icons.download_outlined),
            onPressed: video.sources.isEmpty ? null : () => _showDownloadPicker(context, ref),
          ),
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, String? token, String? userId, bool enabled) async {
    ref.read(favoriteOverrideProvider(video.id).notifier).state = enabled;
    try {
      if (token == null || userId == null) {
        await ref.read(libraryProvider.notifier).setFavorite(video, enabled);
        return;
      }
      final settings = await ref.read(settingsProvider.future);
      await ref.read(han1meRepositoryProvider).setFavorite(settings.resolvedBaseUrl, token, userId, video.id, enabled);
      ref.invalidate(remoteLibraryProvider);
    } catch (_) {
      ref.read(favoriteOverrideProvider(video.id).notifier).state = !enabled;
    }
  }

  Future<void> _pickLocalPlaylist(BuildContext context, WidgetRef ref, LibraryState library) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(AppLocalizations.of(context)!.addToPlaylist)),
            ListTile(leading: const Icon(Icons.watch_later_outlined), title: Text(AppLocalizations.of(context)!.watchLater), onTap: () => Navigator.pop(context, '__watch_later__')),
            ...library.playlists.map((item) => ListTile(leading: const Icon(Icons.playlist_play), title: Text(item.title), subtitle: Text(AppLocalizations.of(context)!.videoCount(item.count)), onTap: () => Navigator.pop(context, item.id))),
            ListTile(leading: const Icon(Icons.add), title: Text(AppLocalizations.of(context)!.newPlaylist), onTap: () => Navigator.pop(context, '__create__')),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final controller = ref.read(libraryProvider.notifier);
    if (selected == '__watch_later__') {
      await controller.setWatchLater(video, true);
      return;
    }
    if (selected != '__create__') {
      await controller.saveToPlaylist(video, selected);
      return;
    }
    final result = await showDialog<String>(context: context, builder: (_) => const _PlaylistNameDialog());
    if (result?.isEmpty != false) return;
    await controller.createPlaylist(video, result!);
  }

  Future<void> _pickPlaylist(BuildContext context, WidgetRef ref, String? token, RemoteLibrary? library) async {
    if (token == null) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(AppLocalizations.of(context)!.addToPlaylist)),
            ListTile(
              leading: const Icon(Icons.watch_later_outlined),
              title: Text(AppLocalizations.of(context)!.watchLater),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            ...(library?.playlists ?? const <Playlist>[]).map(
              (item) => ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(item.title),
                subtitle: Text(AppLocalizations.of(context)!.videoCount(item.count)),
                onTap: () => Navigator.pop(context, item.id),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(AppLocalizations.of(context)!.newPlaylist),
              onTap: () => Navigator.pop(context, '__create__'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final settings = await ref.read(settingsProvider.future);
    if (selected == '__create__') {
      final result = await showDialog<(String, String)>(context: context, builder: (_) => const _PlaylistEditorDialog());
      if (result == null || result.$1.isEmpty) return;
      await ref.read(han1meRepositoryProvider).createPlaylist(settings.resolvedBaseUrl, token, video.id, result.$1, result.$2);
    } else {
      await ref.read(han1meRepositoryProvider).saveToPlaylist(settings.resolvedBaseUrl, token, selected, video.id, true);
    }
    ref.invalidate(remoteLibraryProvider);
  }

  Future<void> _showDownloadPicker(BuildContext context, WidgetRef ref) async {
    if (video.sources.isEmpty) return;
    var source = video.sources.first;
    final picked = await showModalBottomSheet<VideoSource>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(AppLocalizations.of(context)!.selectDownloadQuality, style: const TextStyle(fontWeight: FontWeight.w600))),
              ...video.sources.map(
                (item) => RadioListTile<VideoSource>(
                  value: item,
                  groupValue: source,
                  onChanged: (value) => setSheet(() => source = value!),
                  title: Text(item.quality),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, source),
                child: Text(AppLocalizations.of(context)!.startDownload),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(downloadProvider.notifier).create(video, picked, 'default');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addedToDownloadQueue)));
    }
  }

  Future<void> _share(BuildContext context) async {
    await Share.share('${video.title} (${video.id})', subject: video.title);
  }
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog();

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(title: Text(l10n.newPlaylist), content: TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.name)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, _title.text.trim()), child: Text(l10n.create))]);
  }
}

class _PlaylistEditorDialog extends StatefulWidget {
  const _PlaylistEditorDialog();

  @override
  State<_PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends State<_PlaylistEditorDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(title: Text(l10n.newPlaylist), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.name)), TextField(controller: _description, decoration: InputDecoration(labelText: l10n.description))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, (_title.text.trim(), _description.text.trim())), child: Text(l10n.create))]);
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.video});
  final VideoDetail video;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.video.description ?? '';
    final l10n = AppLocalizations.of(context)!;
    if (description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.video.uploader case final uploader?) ...[
                    Text('${l10n.uploader}: $uploader', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(height: 8),
                  ],
                  if (widget.video.captionTitle case final title?) ...[
                    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                  ],
                  Text(description, maxLines: _expanded ? null : 4, overflow: _expanded ? null : TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagList extends StatefulWidget {
  const _TagList({required this.tags});
  final List<VideoTag> tags;

  @override
  State<_TagList> createState() => _TagListState();
}

class _TagListState extends State<_TagList> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(builder: (context, constraints) {
        final items = widget.tags.map((tag) => (label: tag.count == null ? tag.name : '${tag.name} (${tag.count})', name: tag.name)).toList();
        final rows = <List<(String, String)>>[[]];
        var width = 0.0;
        for (final item in items) {
          final estimatedWidth = (item.label.length * 14.0 + 42).clamp(56.0, constraints.maxWidth).toDouble();
          if (rows.last.isNotEmpty && width + estimatedWidth + 8 > constraints.maxWidth) {
            rows.add([]);
            width = 0;
          }
          rows.last.add((item.label, item.name));
          width += estimatedWidth + 8;
        }
        final visibleRows = _expanded ? rows : rows.take(2);
        final canExpand = rows.length > 2;
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in visibleRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    runSpacing: 6,
                    children: row.map((item) => ActionChip(label: Text(item.$1), visualDensity: VisualDensity.compact, onPressed: () => context.push('/search', extra: _tagSearch(item.$2)))).toList(),
                  ),
                ),
              if (canExpand) TextButton.icon(onPressed: () => setState(() => _expanded = !_expanded), icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more), label: Text(_expanded ? AppLocalizations.of(context)!.collapse : AppLocalizations.of(context)!.expand)),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
      );
}

class _SeriesVideos extends StatelessWidget {
  const _SeriesVideos({required this.videos, required this.currentVideoId});
  final List<VideoCard> videos;
  final String currentVideoId;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text(AppLocalizations.of(context)!.seriesVideos, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                TextButton(onPressed: () => _showAll(context), child: Text(AppLocalizations.of(context)!.more)),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(width: 180, child: VideoCardTile(video: videos[index], horizontal: true, selected: videos[index].id == currentVideoId)),
            ),
          ),
        ],
      );

  Future<void> _showAll(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 12), child: Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(context)!.seriesVideos, style: Theme.of(context).textTheme.titleLarge))),
                Expanded(child: VideoCardGrid(videos: videos, itemBuilder: (context, index, video, horizontal) => VideoCardTile(video: video, horizontal: horizontal, selected: video.id == currentVideoId))),
              ],
            ),
          ),
        ),
      );
}

class _RelatedVideos extends StatelessWidget {
  const _RelatedVideos({required this.videos});
  final List<VideoCard> videos;

  @override
  Widget build(BuildContext context) => Consumer(builder: (context, ref, _) {
        final settings = ref.watch(settingsProvider).valueOrNull;
        final authors = settings?.blockedAuthors ?? const <String>[];
        final titles = settings?.blockedVideoTitleKeywords ?? const <String>[];
        final visible = settings?.applyRecommendationFiltersToRelated != true ? videos : videos.where((video) => !titles.any((keyword) => video.title.toLowerCase().contains(keyword.toLowerCase())) && !authors.any((author) => (video.artist ?? '').toLowerCase().contains(author.toLowerCase()))).toList();
        return Column(children: visible
            .map((video) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _RelatedVideoTile(video: video),
                ))
            .toList(growable: false));
      });
}

class _RelatedVideoTile extends StatelessWidget {
  const _RelatedVideoTile({required this.video});
  final VideoCard video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: video.id.isEmpty ? null : () => context.push('/video/${video.id}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 144,
                  height: 81,
                  child: CachedNetworkImage(
                    imageUrl: video.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (video.artist != null) Text(video.artist!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    if (video.views != null) Text(video.views!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _artistSearch(String artist) => Uri(path: '/search', queryParameters: {'query': artist}).toString();

String _tagSearch(String tag) => Uri(path: '/search', queryParameters: {'tags[]': tag}).toString();

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _CommentsSliver extends ConsumerWidget {
  const _CommentsSliver({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(videoCommentSortProvider(id));
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings?.commentsEnabled != true) return SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context)!.commentsDisabled)));
    return ref.watch(commentsProvider(id)).when(
                loading: () => const SliverFillRemaining(child: Center(child: M3EContainedLoadingIndicator())),
        error: (error, stackTrace) => SliverFillRemaining(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context)!.commentsLoadFailed), Text('$error', style: Theme.of(context).textTheme.bodySmall), FilledButton(onPressed: () => ref.invalidate(commentsProvider(id)), child: Text(AppLocalizations.of(context)!.retry))]))),
        data: (page) => page.comments.isEmpty
            ? SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context)!.noComments)))
            : _commentList(page, settings!.blockedCommentKeywords, settings.blockedCommentUsers, sort, ref),
      );
  }

  Widget _commentList(CommentPage page, List<String> keywords, List<String> users, CommentSort sort, WidgetRef ref) {
    final comments = _sort(_visibleComments(page.comments, keywords, users), sort);
    return SliverList.builder(itemCount: comments.length, itemBuilder: (context, index) => CommentCard(comment: comments[index], token: page.csrfToken, onChanged: () => ref.invalidate(commentsProvider(id))));
  }

  List<Comment> _sort(List<Comment> comments, CommentSort sort) {
    final result = [...comments];
    result.sort((left, right) => switch (sort) {
      CommentSort.latest => right.id.compareTo(left.id),
      CommentSort.earliest => left.id.compareTo(right.id),
      CommentSort.mostReplies => (right.replyCount ?? 0).compareTo(left.replyCount ?? 0),
      CommentSort.mostLikes => (right.likesSum ?? 0).compareTo(left.likesSum ?? 0),
      CommentSort.mostDislikes => ((right.likesCount ?? 0) - (right.likesSum ?? 0)).compareTo((left.likesCount ?? 0) - (left.likesSum ?? 0)),
    });
    return result;
  }

  List<Comment> _visibleComments(List<Comment> comments, List<String> keywords, List<String> users) => comments.where((comment) => !keywords.any((keyword) => comment.content.toLowerCase().contains(keyword.toLowerCase())) && !users.any((user) => comment.username.toLowerCase().contains(user.toLowerCase()))).toList();

}
