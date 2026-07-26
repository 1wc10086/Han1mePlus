import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/local/library_repository.dart';
import '../../data/local/watch_repository.dart';
import '../../core/app_shell.dart';
import '../../data/han1me_repository.dart';
import '../../domain/models/library.dart';
import '../../domain/models/video.dart';
import '../shared/video_card.dart';
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
    if (account?.id != null) return _RemoteLibrary(initialTab: widget.initialTab);
    final value = ref.watch(libraryProvider);
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null,
          title: Text(l10n.myLibrary),
          actions: [IconButton(onPressed: () => context.push('/stats'), icon: const Icon(Icons.bar_chart_outlined))],
          bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: _tabs(l10n)),
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
        _LocalPlaylists(playlists: library.playlists),
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
        const _LocalHistory(),
      ],
    );
  }
}

class _RemoteLibrary extends ConsumerWidget {
  const _RemoteLibrary({required this.initialTab});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(accountProvider).valueOrNull;
    return DefaultTabController(
      length: 5,
      initialIndex: initialTab,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null, title: Text(l10n.myLibrary), bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: _tabs(l10n))),
          body: ref.watch(remoteLibraryProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: FilledButton(onPressed: () => ref.invalidate(remoteLibraryProvider), child: Text(l10n.reload))),
                data: (library) => TabBarView(children: [
                  _Videos(videos: library.watchLater, message: l10n.noWatchLater),
                  _Videos(videos: library.favorites, message: l10n.noFavoriteVideos),
                  _Playlists(playlists: library.playlists, token: library.csrfToken ?? account?.csrfToken),
                  _RemoteSubscriptions(artists: library.subscriptionArtists, videos: library.subscriptions),
                  _RemoteHistory(videos: library.history, token: account?.csrfToken ?? library.csrfToken),
                ]),
              ),
        ),
      ),
    );
  }
}

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
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(tooltip: _selectionMode ? l10n.delete : l10n.select, onPressed: _selectionMode ? (_selected.isEmpty ? _exitSelection : _deleteSelected) : _enterSelection, child: Icon(_selectionMode ? Icons.delete_outline : Icons.checklist_outlined))),
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
    final selected = widget.artists.any((artist) => artist.name == _artist) ? _artist : (widget.artists.isEmpty ? null : widget.artists.first.name);
    final videos = selected == null ? const <FollowingVideo>[] : widget.videos.where((video) => video.artistName == selected).toList(growable: false);
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
                  onTap: () => setState(() => _artist = artist.name),
                  onLongPress: () => context.push('/search', extra: Uri(path: '/search', queryParameters: {'query': artist.name}).toString()),
                );
              },
            ),
          ),
        Expanded(child: _Videos(videos: videos, message: AppLocalizations.of(context)!.noSubscriptionVideos)),
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

class _LocalPlaylists extends StatelessWidget {
  const _LocalPlaylists({required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) => _LocalPlaylistList(playlists: playlists);
}

class _LocalPlaylistList extends StatelessWidget {
  const _LocalPlaylistList({required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noPlaylists));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _LocalPlaylistCard(playlist: playlists[index]),
    );
  }
}

class _LocalPlaylistCard extends StatelessWidget {
  const _LocalPlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: playlist.coverUrl?.isNotEmpty == true ? Image.network(playlist.coverUrl!, width: 72, fit: BoxFit.cover) : const Icon(Icons.playlist_play),
          title: Text(playlist.title),
          subtitle: Text(AppLocalizations.of(context)!.videoCount(playlist.count)),
          children: playlist.videos.isEmpty
              ? [Padding(padding: const EdgeInsets.all(16), child: Text(AppLocalizations.of(context)!.playlistEmpty))]
              : playlist.videos.map((video) => ListTile(leading: video.coverUrl?.isNotEmpty == true ? Image.network(video.coverUrl!, width: 64, height: 40, fit: BoxFit.cover) : const Icon(Icons.play_arrow), title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: video.artistName == null ? null : Text(video.artistName!, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => context.push('/video/${video.videoCode}'))).toList(),
        ),
      );
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
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: playlists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _PlaylistCard(playlist: playlists[index]),
              ),
        Positioned(
          right: 16,
          bottom: 16,
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
    await ref.read(han1meRepositoryProvider).createPlaylist(settings.baseUrl, token, '', result.$1, result.$2);
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
          bottom: 16,
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
      await ref.read(han1meRepositoryProvider).deleteHistory(settings.baseUrl, token, id);
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
    await ref.read(han1meRepositoryProvider).deletePlaylist(settings.baseUrl, account!.csrfToken!, widget.playlist.id);
    ref.invalidate(remoteLibraryProvider);
  }

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _PlaylistItemsPage(playlist: widget.playlist))),
          onLongPress: _delete,
          child: Column(
            children: [
              ListTile(
                leading: widget.playlist.coverUrl?.isNotEmpty == true ? Image.network(widget.playlist.coverUrl!, width: 72, fit: BoxFit.cover) : const Icon(Icons.playlist_play),
                title: Text(widget.playlist.title),
                subtitle: Text(AppLocalizations.of(context)!.videoCount(widget.playlist.count)),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      );
}

class _PlaylistItemsPage extends ConsumerStatefulWidget {
  const _PlaylistItemsPage({required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<_PlaylistItemsPage> createState() => _PlaylistItemsPageState();
}

class _PlaylistItemsPageState extends ConsumerState<_PlaylistItemsPage> {
  var _sort = 'latest';
  var _editing = false;
  final _selectedItems = <String>{};
  late Future<PlaylistDetail> _playlist = _load();

  Future<PlaylistDetail> _load() async {
    final settings = await ref.read(settingsProvider.future);
    return ref.read(han1meRepositoryProvider).playlist(settings.baseUrl, widget.playlist.id, _sort);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(accountProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.title)),
      body: FutureBuilder<PlaylistDetail>(
        future: _playlist,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(l10n.loadFailed('${snapshot.error}')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final playlist = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (playlist.playlist.coverUrl?.isNotEmpty == true) ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(playlist.playlist.coverUrl!, fit: BoxFit.cover))),
              const SizedBox(height: 16),
              Text(playlist.playlist.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (playlist.author?.isNotEmpty == true) Text(l10n.playlistCreatedBy(playlist.author!), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(l10n.playlistStats(playlist.playlist.count, playlist.viewCount ?? 0), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
              if (playlist.description?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text(playlist.description!)),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: FilledButton.icon(onPressed: playlist.videos.isEmpty ? null : () => context.push('/video/${playlist.videos.first.videoCode}'), icon: const Icon(Icons.play_arrow), label: Text(l10n.playAll))), const SizedBox(width: 8), IconButton.filledTonal(onPressed: account?.csrfToken == null ? null : () => _edit(playlist), icon: const Icon(Icons.edit_outlined)), const SizedBox(width: 8), IconButton.filledTonal(onPressed: () => Share.share('https://hanimeone.me/playlist?list=${playlist.playlist.id}', subject: playlist.playlist.title), icon: const Icon(Icons.share_outlined))]),
              const SizedBox(height: 20),
              Row(children: [for (final value in ['latest', 'popular', 'oldest']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(_sortLabel(l10n, value)), selected: _sort == value, onSelected: _editing ? null : (_) => _changeSort(value))), const Spacer(), TextButton.icon(onPressed: _editing ? _removeSelected : () => setState(() => _editing = true), icon: Icon(_editing ? Icons.delete_outline : Icons.edit_outlined), label: Text(_editing ? l10n.delete : l10n.edit))]),
              const SizedBox(height: 4),
              if (playlist.videos.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(l10n.playlistEmpty))) else _PlaylistVideoGrid(videos: playlist.videos, editing: _editing, selected: _selectedItems, onToggle: _toggleItem),
            ],
          );
        },
      ),
    );
  }

  String _sortLabel(AppLocalizations l10n, String value) => switch (value) {'latest' => l10n.latest, 'popular' => l10n.popular, _ => l10n.oldest};

  void _changeSort(String value) => setState(() { _sort = value; _playlist = _load(); });

  Future<void> _edit(PlaylistDetail playlist) async {
    final result = await showDialog<(String, String, bool)>(context: context, builder: (_) => _PlaylistEditDialog(playlist: playlist));
    if (result == null) return;
    final account = ref.read(accountProvider).valueOrNull;
    if (account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).updatePlaylist(settings.baseUrl, account!.csrfToken!, playlist.playlist.id, result.$1, result.$2, result.$3);
    if (!mounted) return;
    if (result.$3) {
      Navigator.pop(context);
      ref.invalidate(remoteLibraryProvider);
      return;
    }
    setState(() => _playlist = _load());
    ref.invalidate(remoteLibraryProvider);
  }

  void _toggleItem(FollowingVideo video) {
    final id = video.playlistItemId;
    if (id == null) return;
    setState(() => _selectedItems.contains(id) ? _selectedItems.remove(id) : _selectedItems.add(id));
  }

  Future<void> _removeSelected() async {
    if (_selectedItems.isEmpty) {
      setState(() => _editing = false);
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(AppLocalizations.of(context)!.delete), content: Text(AppLocalizations.of(context)!.selectedItems(_selectedItems.length)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete))]));
    final account = ref.read(accountProvider).valueOrNull;
    if (confirmed != true || account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await Future.wait(_selectedItems.map((id) => ref.read(han1meRepositoryProvider).removePlaylistItem(settings.baseUrl, account!.csrfToken!, id)));
    if (mounted) setState(() { _editing = false; _selectedItems.clear(); _playlist = _load(); });
  }
}

class _PlaylistVideoGrid extends StatelessWidget {
  const _PlaylistVideoGrid({required this.videos, required this.editing, required this.selected, required this.onToggle});

  final List<FollowingVideo> videos;
  final bool editing;
  final Set<String> selected;
  final ValueChanged<FollowingVideo> onToggle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;
          final cardHeight = cardWidth * 9 / 16 + 96;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: spacing, mainAxisExtent: cardHeight),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final isSelected = selected.contains(video.playlistItemId);
              return Stack(
                fit: StackFit.expand,
                children: [
                  VideoCardTile(video: _videoCard(video), horizontal: true, onTap: editing ? () => onToggle(video) : null),
                  if (editing) Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: (value) => onToggle(video))),
                ],
              );
            },
          );
        },
      );
}

class _PlaylistEditDialog extends StatefulWidget {
  const _PlaylistEditDialog({required this.playlist});

  final PlaylistDetail playlist;

  @override
  State<_PlaylistEditDialog> createState() => _PlaylistEditDialogState();
}

class _PlaylistEditDialogState extends State<_PlaylistEditDialog> {
  late final _title = TextEditingController(text: widget.playlist.playlist.title);
  late final _description = TextEditingController(text: widget.playlist.description ?? '');
  var _delete = false;

  @override
  void dispose() { _title.dispose(); _description.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(title: Text(l10n.edit), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _title, decoration: InputDecoration(labelText: l10n.name)), TextField(controller: _description, minLines: 3, maxLines: 5, decoration: InputDecoration(labelText: l10n.description)), CheckboxListTile(contentPadding: EdgeInsets.zero, value: _delete, onChanged: (value) => setState(() => _delete = value ?? false), title: Text(l10n.deletePlaylist))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: _title.text.trim().isEmpty ? null : () => Navigator.pop(context, (_title.text.trim(), _description.text.trim(), _delete)), child: Text(l10n.confirm))]);
  }
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

VideoCard _videoCard(FollowingVideo video) => VideoCard(id: video.videoCode, title: video.title, coverUrl: video.coverUrl ?? '', artist: video.artistName, duration: video.duration, views: video.views, rating: video.rating, uploadTime: video.uploadTime);

List<Tab> _tabs(AppLocalizations l10n) => [
      Tab(text: l10n.watchLater),
      Tab(text: l10n.favoriteVideos),
      Tab(text: l10n.playlists),
      Tab(text: l10n.subscriptions),
      Tab(text: l10n.watchHistory),
    ];
