import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/local/library_repository.dart';
import '../../data/local/watch_repository.dart';
import '../../core/app_shell.dart';
import '../../data/han1me_repository.dart';
import '../../domain/models/library.dart';
import '../../domain/models/search_query.dart';
import '../../domain/models/video.dart';
import '../shared/video_card.dart';
import 'playlists/local_playlist_page.dart';
import 'playlists/playlist_shared.dart';
import 'playlists/remote_playlist_page.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';
import 'remote_library_controller.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String? _artistId;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider).valueOrNull;
    final drawerMode = ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false;
    if (account?.id != null) return _RemoteLibrary(initialTab: widget.initialTab, drawerMode: drawerMode);
    final value = ref.watch(libraryProvider);
    final l10n = AppLocalizations.of(context)!;
    if (drawerMode) {
      return Scaffold(
        appBar: AppBar(leading: Navigator.of(context).canPop() || permanentNavigationDrawer(context) ? null : IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)), title: Text(_tabTitle(l10n, widget.initialTab)), actions: widget.initialTab == 4 ? [IconButton(onPressed: () => context.push('/stats'), icon: const Icon(Icons.bar_chart_outlined))] : null),
        body: value.when(loading: () => const Center(child: M3EContainedLoadingIndicator()), error: (error, stackTrace) => Center(child: Text('$error')), data: (library) => _tabContent(library, widget.initialTab)),
      );
    }
    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? (permanentNavigationDrawer(context) ? null : IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu))) : null,
          title: Text(l10n.myLibrary),
          actions: [IconButton(onPressed: () => context.push('/stats'), icon: const Icon(Icons.bar_chart_outlined))],
          bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: _tabs(l10n)),
        ),
        body: value.when(
          loading: () => const Center(child: M3EContainedLoadingIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: _content,
        ),
      ),
    );
  }

  Widget _content(LibraryState library) {
    return TabBarView(
      children: [
        for (var index = 0; index < 5; index++) _tabContent(library, index),
      ],
    );
  }

  Widget _tabContent(LibraryState library, int index) {
    final l10n = AppLocalizations.of(context)!;
    return switch (index) {
      0 => _SelectableVideos(videos: library.watchLater, emptyMessage: l10n.noWatchLater, remover: (ref, ids) => ref.read(libraryProvider.notifier).removeWatchLater(ids)),
      1 => _SelectableVideos(videos: library.favorites, emptyMessage: l10n.noFavoriteVideos, remover: (ref, ids) => ref.read(libraryProvider.notifier).removeFavorites(ids)),
      2 => _LocalPlaylists(playlists: library.playlists),
      3 => _LocalSubscriptions(artists: library.artists, videos: library.subscriptionVideos, selectedArtist: _artistId, onSelected: (artist) => setState(() => _artistId = artist)),
      _ => const _LocalHistory(),
    };
  }
}

class _RemoteLibrary extends ConsumerWidget {
  const _RemoteLibrary({required this.initialTab, required this.drawerMode});

  final int initialTab;
  final bool drawerMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(accountProvider).valueOrNull;
    if (drawerMode) {
      return Scaffold(
        appBar: AppBar(leading: permanentNavigationDrawer(context) ? null : IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)), title: Text(_tabTitle(l10n, initialTab))),
        body: ref.watch(remoteLibraryProvider).when(
          loading: () => const Center(child: M3EContainedLoadingIndicator()),
          error: (error, stackTrace) => Center(child: FilledButton(onPressed: () => ref.invalidate(remoteLibraryProvider), child: Text(l10n.reload))),
          data: (library) => _remoteTabContent(context, library, initialTab, account?.csrfToken),
        ),
      );
    }
    return DefaultTabController(
      length: 5,
      initialIndex: initialTab,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? (permanentNavigationDrawer(context) ? null : IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu))) : null, title: Text(l10n.myLibrary), bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: _tabs(l10n))),
          body: ref.watch(remoteLibraryProvider).when(
                loading: () => const Center(child: M3EContainedLoadingIndicator()),
                error: (error, stackTrace) => Center(child: FilledButton(onPressed: () => ref.invalidate(remoteLibraryProvider), child: Text(l10n.reload))),
                data: (library) => TabBarView(children: [for (var index = 0; index < 5; index++) _remoteTabContent(context, library, index, account?.csrfToken)]),
              ),
        ),
      ),
    );
  }
}

Widget _remoteTabContent(BuildContext context, RemoteLibrary library, int index, String? accountToken) {
  final l10n = AppLocalizations.of(context)!;
  return switch (index) {
    0 => _SelectableVideos(
        videos: library.watchLater,
        emptyMessage: l10n.noWatchLater,
        remover: (ref, ids) async {
          final account = ref.read(accountProvider).valueOrNull;
          final userId = account?.id;
          final token = library.csrfToken ?? accountToken;
          if (userId == null || token == null) return;
          final settings = await ref.read(settingsProvider.future);
          final repository = ref.read(han1meRepositoryProvider);
          for (final id in ids) {
            await repository.saveToPlaylist(settings.resolvedBaseUrl, token, 'save', id, false);
          }
          ref.invalidate(remoteLibraryProvider);
        },
      ),
    1 => _SelectableVideos(
        videos: library.favorites,
        emptyMessage: l10n.noFavoriteVideos,
        remover: (ref, ids) async {
          final account = ref.read(accountProvider).valueOrNull;
          final userId = account?.id;
          final token = library.csrfToken ?? accountToken;
          if (userId == null || token == null) return;
          final settings = await ref.read(settingsProvider.future);
          final repository = ref.read(han1meRepositoryProvider);
          for (final id in ids) {
            await repository.setFavorite(settings.resolvedBaseUrl, token, userId, id, false);
          }
          ref.invalidate(remoteLibraryProvider);
        },
      ),
    2 => _Playlists(playlists: library.playlists, token: library.csrfToken ?? accountToken),
    3 => _RemoteSubscriptions(artists: library.subscriptionArtists, videos: library.subscriptions),
    _ => _RemoteHistory(videos: library.history, token: accountToken ?? library.csrfToken),
  };
}

String _tabTitle(AppLocalizations l10n, int index) => switch (index) {
  0 => l10n.watchLater,
  1 => l10n.favoriteVideos,
  2 => l10n.playlists,
  3 => l10n.subscriptions,
  _ => l10n.watchHistory,
};

class _LocalHistory extends ConsumerStatefulWidget {
  const _LocalHistory();

  @override
  ConsumerState<_LocalHistory> createState() => _LocalHistoryState();
}

class _LocalHistoryState extends ConsumerState<_LocalHistory> {
  final _selected = <String>{};
  var _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(watchProvider).valueOrNull?.histories ?? const [];
    final items = history.reversed.toList(growable: false);
    return Stack(
      children: [
        items.isEmpty
            ? Center(child: Text(l10n.noWatchHistory))
            : VideoCardGrid(
                videos: items.map((item) => VideoCard(id: item.videoCode, title: item.title, coverUrl: '')).toList(growable: false),
                itemBuilder: (context, index, video, horizontal) {
                  final item = items[index];
                  final selected = _selected.contains(item.id);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: selected ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)) : const BoxDecoration(),
                        child: VideoCardTile(video: video, horizontal: horizontal, onTap: _selectionMode ? () => _toggle(item.id) : null, onLongPress: () => _startSelection(item.id)),
                      ),
                      if (selected) const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, color: Colors.white)),
                    ],
                  );
                },
              ),
        Positioned(right: 16, bottom: 16 + MediaQuery.paddingOf(context).bottom, child: FloatingActionButton(tooltip: _selectionMode ? l10n.delete : l10n.select, onPressed: _selectionMode ? (_selected.isEmpty ? _exitSelection : _deleteSelected) : _enterSelection, child: Icon(_selectionMode ? Icons.delete_outline : Icons.checklist_outlined))),
      ],
    );
  }

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  void _enterSelection() => setState(() => _selectionMode = true);
  void _startSelection(String id) => setState(() { _selectionMode = true; _selected.add(id); });
  void _exitSelection() => setState(() { _selectionMode = false; _selected.clear(); });

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(AppLocalizations.of(context)!.delete), content: Text(AppLocalizations.of(context)!.selectedItems(_selected.length)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete))]));
    if (confirmed != true) return;
    await ref.read(watchProvider.notifier).deleteHistories(_selected);
    if (mounted) setState(() { _selectionMode = false; _selected.clear(); });
  }
}

class _RemoteSubscriptions extends StatefulWidget {
  const _RemoteSubscriptions({required this.artists, required this.videos});

  final List<SubscribedArtist> artists;
  final List<FollowingVideo> videos;

  @override
  State<_RemoteSubscriptions> createState() => _RemoteSubscriptionsState();
}

class _RemoteSubscriptionsState extends State<_RemoteSubscriptions> {
  String? _artist;

  @override
  Widget build(BuildContext context) {
    final selected = widget.artists.any((artist) => artist.name == _artist) ? _artist : null;
    final videos = selected == null ? widget.videos : widget.videos.where((video) => video.artistName == selected).toList(growable: false);
    return Column(
      children: [
        if (widget.artists.isNotEmpty)
          SizedBox(
            height: 252,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 72),
              itemCount: widget.artists.length,
              itemBuilder: (context, index) {
                final artist = widget.artists[index];
                final isSelected = artist.name == selected;
                return _SubscribedArtistCard(
                  artist: artist,
                  selected: isSelected,
                  onTap: () => setState(() => _artist = artist.name == selected ? null : artist.name),
                  onLongPress: () => context.push('/search', extra: SearchRouteRequest(initialUrl: Uri(path: '/search', queryParameters: {'query': artist.name}).toString())),
                );
              },
            ),
          ),
        Expanded(child: _Videos(videos: videos, message: AppLocalizations.of(context)!.noSubscriptionVideos)),
      ],
    );
  }
}

class _LocalSubscriptions extends StatelessWidget {
  const _LocalSubscriptions({required this.artists, required this.videos, required this.selectedArtist, required this.onSelected});

  final List<SubscribedArtist> artists;
  final Map<String, List<FollowingVideo>> videos;
  final String? selectedArtist;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = artists.any((artist) => artist.id == selectedArtist) ? selectedArtist : null;
    final allVideos = videos.values.expand((items) => items).fold(<String, FollowingVideo>{}, (items, video) => items..putIfAbsent(video.videoCode, () => video)).values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final visible = selected == null ? allVideos : videos[selected] ?? const <FollowingVideo>[];
    return Column(
      children: [
        if (artists.isNotEmpty)
          SizedBox(
            height: 252,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 72),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return _SubscribedArtistCard(artist: artist, selected: artist.id == selected, onTap: () => onSelected(artist.id == selected ? null : artist.id), onLongPress: () => context.push('/search', extra: SearchRouteRequest(initialUrl: Uri(path: '/search', queryParameters: {'query': artist.name}).toString())));
              },
            ),
          ),
        Expanded(child: _Videos(videos: visible, message: AppLocalizations.of(context)!.noSubscriptionVideos)),
      ],
    );
  }
}

class _SubscribedArtistCard extends StatelessWidget {
  const _SubscribedArtistCard({required this.artist, required this.selected, required this.onTap, required this.onLongPress});

  final SubscribedArtist artist;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 20, backgroundImage: artist.avatarUrl?.isNotEmpty == true ? NetworkImage(artist.avatarUrl!) : null, child: artist.avatarUrl?.isNotEmpty == true ? null : Text(artist.name.characters.first)),
              const SizedBox(height: 4),
              Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalPlaylists extends ConsumerWidget {
  const _LocalPlaylists({required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        playlists.isEmpty
            ? Center(child: Text(l10n.noPlaylists))
            : GridView.builder(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.paddingOf(context).bottom),
                itemCount: playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.45),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return PlaylistCoverCard(
                    playlist: playlist,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LocalPlaylistPage(playlistId: playlist.id))),
                    onLongPress: () => _delete(context, ref, playlist),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: FloatingActionButton(tooltip: l10n.newPlaylist, onPressed: () => _create(context, ref), child: const Icon(Icons.playlist_add)),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<PlaylistEditorResult>(context: context, builder: (_) => const PlaylistEditorDialog());
    if (result == null || result.title.isEmpty) return;
    await ref.read(libraryProvider.notifier).createPlaylist(result.title, description: result.description);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Playlist playlist) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text(l10n.deletePlaylistConfirmation(playlist.title)),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete))],
      ),
    );
    if (confirmed != true) return;
    await ref.read(libraryProvider.notifier).deletePlaylist(playlist.id);
  }
}

class _Playlists extends ConsumerWidget {
  const _Playlists({required this.playlists, required this.token});
  final List<Playlist> playlists;
  final String? token;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        playlists.isEmpty
            ? Center(child: Text(l10n.noPlaylists))
            : GridView.builder(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.paddingOf(context).bottom),
                itemCount: playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.45),
                itemBuilder: (context, index) => _PlaylistCard(playlist: playlists[index]),
              ),
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: FloatingActionButton(
            tooltip: l10n.newPlaylist,
            onPressed: token == null ? null : () => _createPlaylist(context, ref, token!),
            child: const Icon(Icons.playlist_add),
          ),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref, String token) async {
    final result = await showDialog<(String, String)>(context: context, builder: (_) => const _CreatePlaylistDialog());
    if (result == null || result.$1.isEmpty) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).createPlaylist(settings.resolvedBaseUrl, token, '', result.$1, result.$2);
    ref.invalidate(remoteLibraryProvider);
  }
}

class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
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
    return AlertDialog(
      title: Text(l10n.newPlaylist),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.name)), TextField(controller: _description, decoration: InputDecoration(labelText: l10n.description))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, (_title.text.trim(), _description.text.trim())), child: Text(l10n.create))],
    );
  }
}

class _RemoteHistory extends ConsumerStatefulWidget {
  const _RemoteHistory({required this.videos, required this.token});

  final List<FollowingVideo> videos;
  final String? token;

  @override
  ConsumerState<_RemoteHistory> createState() => _RemoteHistoryState();
}

class _RemoteHistoryState extends ConsumerState<_RemoteHistory> {
  final _selected = <String>{};
  var _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        widget.videos.isEmpty
            ? Center(child: Text(l10n.noWatchHistory))
            : VideoCardGrid(
                videos: widget.videos.map(_videoCard).toList(growable: false),
                itemBuilder: (context, index, video, horizontal) {
                  final selected = _selected.contains(video.id);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: selected ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)) : const BoxDecoration(),
                        child: VideoCardTile(video: video, horizontal: horizontal, onTap: _selectionMode ? () => _toggle(video.id) : null, onLongPress: () => _startSelection(video.id)),
                      ),
                      if (selected) const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, color: Colors.white)),
                    ],
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: FloatingActionButton(tooltip: _selectionMode ? l10n.delete : l10n.select, onPressed: widget.token == null ? null : (_selectionMode ? (_selected.isEmpty ? _exitSelection : _deleteSelected) : _enterSelection), child: Icon(_selectionMode ? Icons.delete_outline : Icons.checklist_outlined)),
        ),
      ],
    );
  }

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  void _enterSelection() => setState(() => _selectionMode = true);
  void _startSelection(String id) => setState(() { _selectionMode = true; _selected.add(id); });
  void _exitSelection() => setState(() { _selectionMode = false; _selected.clear(); });

  Future<void> _deleteSelected() async {
    final token = widget.token;
    if (token == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(AppLocalizations.of(context)!.delete), content: Text(AppLocalizations.of(context)!.selectedItems(_selected.length)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete))]));
    if (confirmed != true) return;
    final settings = await ref.read(settingsProvider.future);
    for (final id in _selected) {
      await ref.read(han1meRepositoryProvider).deleteHistory(settings.resolvedBaseUrl, token, id);
    }
    if (!mounted) return;
    setState(() { _selectionMode = false; _selected.clear(); });
    ref.invalidate(remoteLibraryProvider);
  }
}

class _PlaylistCard extends ConsumerStatefulWidget {
  const _PlaylistCard({required this.playlist});
  final Playlist playlist;
  @override
  ConsumerState<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends ConsumerState<_PlaylistCard> {
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.deletePlaylist), content: Text(l10n.deletePlaylistConfirmation(widget.playlist.title)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete))]));
    final account = ref.read(accountProvider).valueOrNull;
    if (confirmed != true || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).deletePlaylist(settings.resolvedBaseUrl, account!.csrfToken!, widget.playlist.id);
    ref.invalidate(remoteLibraryProvider);
  }

  @override
  Widget build(BuildContext context) => PlaylistCoverCard(playlist: widget.playlist, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RemotePlaylistPage(playlist: widget.playlist))), onLongPress: _delete);
}

class _Videos extends StatelessWidget {
  const _Videos({required this.videos, required this.message});

  final List<FollowingVideo> videos;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return Center(child: Text(message, style: Theme.of(context).textTheme.bodyLarge));
    return VideoCardGrid(videos: videos.map(_videoCard).toList(growable: false));
  }
}

class _SelectableVideos extends ConsumerStatefulWidget {
  const _SelectableVideos({required this.videos, required this.emptyMessage, required this.remover});

  final List<FollowingVideo> videos;
  final String emptyMessage;
  final Future<void> Function(WidgetRef ref, Set<String> videoCodes) remover;

  @override
  ConsumerState<_SelectableVideos> createState() => _SelectableVideosState();
}

class _SelectableVideosState extends ConsumerState<_SelectableVideos> {
  final _selected = <String>{};
  var _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        widget.videos.isEmpty
            ? Center(child: Text(widget.emptyMessage, style: Theme.of(context).textTheme.bodyLarge))
            : VideoCardGrid(
                videos: widget.videos.map(_videoCard).toList(growable: false),
                itemBuilder: (context, index, video, horizontal) {
                  final selected = _selected.contains(video.id);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: selected ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)) : const BoxDecoration(),
                        child: VideoCardTile(video: video, horizontal: horizontal, onTap: _selectionMode ? () => _toggle(video.id) : null, onLongPress: () => _startSelection(video.id)),
                      ),
                      if (selected) const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, color: Colors.white)),
                    ],
                  );
                },
              ),
        Positioned(right: 16, bottom: 16 + MediaQuery.paddingOf(context).bottom, child: FloatingActionButton(tooltip: _selectionMode ? l10n.delete : l10n.select, onPressed: _selectionMode ? (_selected.isEmpty ? _exitSelection : _deleteSelected) : _enterSelection, child: Icon(_selectionMode ? Icons.delete_outline : Icons.checklist_outlined))),
      ],
    );
  }

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  void _enterSelection() => setState(() => _selectionMode = true);
  void _startSelection(String id) => setState(() { _selectionMode = true; _selected.add(id); });
  void _exitSelection() => setState(() { _selectionMode = false; _selected.clear(); });

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.delete), content: Text(l10n.selectedItems(_selected.length)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete))]));
    if (confirmed != true || !mounted) return;
    await widget.remover(ref, _selected);
    if (mounted) setState(() { _selectionMode = false; _selected.clear(); });
  }
}

VideoCard _videoCard(FollowingVideo video) => VideoCard(id: video.videoCode, title: video.title, coverUrl: video.coverUrl ?? '', artist: video.artistName, duration: video.duration, views: video.views, rating: video.rating, uploadTime: video.uploadTime);

List<Tab> _tabs(AppLocalizations l10n) => [
      Tab(text: l10n.watchLater),
      Tab(text: l10n.favoriteVideos),
      Tab(text: l10n.playlists),
      Tab(text: l10n.subscriptions),
      Tab(text: l10n.watchHistory),
    ];
