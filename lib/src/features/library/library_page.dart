import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/local/library_repository.dart';
import '../../data/local/watch_repository.dart';
import '../../data/han1me_repository.dart';
import '../../domain/models/library.dart';
import '../../domain/models/video.dart';
import '../shared/video_card.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';
import 'remote_library_controller.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String? _artistId;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider).valueOrNull;
    if (account?.id != null) return _RemoteLibrary(accountId: account!.id!);
    final value = ref.watch(libraryProvider);
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myLibrary),
          actions: [IconButton(onPressed: () => context.push('/stats'), icon: const Icon(Icons.bar_chart_outlined))],
          bottom: TabBar(tabs: [Tab(text: l10n.watchLater), Tab(text: l10n.favoriteVideos), Tab(text: l10n.subscriptions)]),
        ),
        body: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: _content,
        ),
      ),
    );
  }

  Widget _content(LibraryState library) {
    final l10n = AppLocalizations.of(context)!;
    final selected = library.artists.any((artist) => artist.id == _artistId)
        ? _artistId
        : (library.artists.isEmpty ? null : library.artists.first.id);
    return TabBarView(
      children: [
        _Videos(videos: library.watchLater, message: l10n.noWatchLater),
        _Videos(videos: library.favorites, message: l10n.noFavoriteVideos),
        Column(
          children: [
            if (library.artists.isNotEmpty)
              SizedBox(
                height: 66,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  children: library.artists.map((artist) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(artist.name),
                      selected: artist.id == selected,
                      onSelected: (selected) => setState(() => _artistId = artist.id),
                    ),
                  )).toList(),
                ),
              ),
            Expanded(
              child: _Videos(
                videos: selected == null ? const [] : library.subscriptionVideos[selected] ?? const [],
                message: l10n.noSubscriptionVideos,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RemoteLibrary extends ConsumerWidget {
  const _RemoteLibrary({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.myLibrary), bottom: TabBar(tabs: [Tab(text: l10n.watchLater), Tab(text: l10n.favoriteVideos), Tab(text: l10n.watchHistory), Tab(text: l10n.playlists)])),
          body: ref.watch(remoteLibraryProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: FilledButton(onPressed: () => ref.invalidate(remoteLibraryProvider), child: Text(l10n.reload))),
                data: (library) => TabBarView(children: [
                  _Videos(videos: library.watchLater, message: l10n.noWatchLater),
                  _Videos(videos: library.favorites, message: l10n.noFavoriteVideos),
                  _LocalHistory(),
                  _Playlists(playlists: library.playlists),
                ]),
              ),
        ),
      );
  }
}

class _LocalHistory extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchProvider).valueOrNull?.histories ?? const [];
    final videos = <String, FollowingVideo>{
      for (final item in history.reversed) item.videoCode: FollowingVideo(videoCode: item.videoCode, title: item.title, addedAt: item.createdAt),
    }.values.toList();
    return _Videos(videos: videos, message: AppLocalizations.of(context)!.noWatchHistory);
  }
}

class _Playlists extends ConsumerWidget {
  const _Playlists({required this.playlists});
  final List<Playlist> playlists;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (playlists.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noPlaylists));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _PlaylistCard(playlist: playlists[index]),
    );
  }
}

class _PlaylistCard extends ConsumerStatefulWidget {
  const _PlaylistCard({required this.playlist});
  final Playlist playlist;
  @override
  ConsumerState<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends ConsumerState<_PlaylistCard> {
  Future<List<FollowingVideo>>? _items;
  var _expanded = false;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) _items ??= _load();
    });
  }

  Future<List<FollowingVideo>> _load() async {
    final settings = await ref.read(settingsProvider.future);
    return ref.read(han1meRepositoryProvider).playlistItems(settings.baseUrl, widget.playlist.id);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.deletePlaylist), content: Text(l10n.deletePlaylistConfirmation(widget.playlist.title)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete))]));
    final account = ref.read(accountProvider).valueOrNull;
    if (confirmed != true || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).deletePlaylist(settings.baseUrl, account!.csrfToken!, widget.playlist.id);
    ref.invalidate(remoteLibraryProvider);
  }

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggle,
          onLongPress: _delete,
          child: Column(
            children: [
              ListTile(
                leading: widget.playlist.coverUrl?.isNotEmpty == true ? Image.network(widget.playlist.coverUrl!, width: 72, fit: BoxFit.cover) : const Icon(Icons.playlist_play),
                title: Text(widget.playlist.title),
                subtitle: Text(AppLocalizations.of(context)!.videoCount(widget.playlist.count)),
                trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ),
              if (_expanded)
                FutureBuilder<List<FollowingVideo>>(
                  future: _items,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text(AppLocalizations.of(context)!.loadFailed('${snapshot.error}')));
                    if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                    if (snapshot.data!.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text(AppLocalizations.of(context)!.playlistEmpty));
                    return Column(children: snapshot.data!.map((video) => ListTile(leading: video.coverUrl?.isNotEmpty == true ? Image.network(video.coverUrl!, width: 64, height: 40, fit: BoxFit.cover) : const Icon(Icons.play_arrow), title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: video.artistName == null ? null : Text(video.artistName!, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => context.push('/video/${video.videoCode}'))).toList());
                  },
                ),
            ],
          ),
        ),
      );
}

class _Videos extends StatelessWidget {
  const _Videos({required this.videos, required this.message});

  final List<FollowingVideo> videos;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return Center(child: Text(message, style: Theme.of(context).textTheme.bodyLarge));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: .59,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoCardTile(video: VideoCard(id: video.videoCode, title: video.title, coverUrl: video.coverUrl ?? '', artist: video.artistName));
      },
    );
  }
}
