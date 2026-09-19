import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../data/local/library_repository.dart';
import '../../../domain/models/library.dart';
import 'playlist_shared.dart';

class LocalPlaylistPage extends ConsumerStatefulWidget {
  const LocalPlaylistPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<LocalPlaylistPage> createState() => _LocalPlaylistPageState();
}

class _LocalPlaylistPageState extends ConsumerState<LocalPlaylistPage> {
  final _selected = <String>{};
  var _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final library = ref.watch(libraryProvider).valueOrNull;
    final playlist = library?.playlists.where((item) => item.id == widget.playlistId).firstOrNull;
    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.playlists)),
        body: library == null ? const Center(child: M3EContainedLoadingIndicator()) : Center(child: Text(l10n.playlistEmpty)),
      );
    }
    final videos = playlist.sort.apply(playlist.videos);
    return Scaffold(
      appBar: AppBar(
        leading: _editing ? IconButton(tooltip: l10n.cancel, onPressed: _exitSelection, icon: const Icon(Icons.close)) : null,
        title: Text(_editing ? l10n.selectedItems(_selected.length) : playlist.title),
        actions: _editing
            ? [IconButton(tooltip: l10n.delete, onPressed: _selected.isEmpty ? _exitSelection : () => _removeSelected(playlist.id), icon: const Icon(Icons.delete_outline))]
            : [
                IconButton(tooltip: l10n.sortOrder, onPressed: () => _changeSort(playlist), icon: const Icon(Icons.sort)),
                PopupMenuButton<_PlaylistMenuAction>(
                  tooltip: l10n.more,
                  onSelected: (action) => switch (action) {
                    _PlaylistMenuAction.edit => _edit(playlist),
                    _PlaylistMenuAction.delete => _delete(playlist),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: _PlaylistMenuAction.edit, child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_outlined), title: Text(l10n.edit))),
                    PopupMenuItem(value: _PlaylistMenuAction.delete, child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delete_outline), title: Text(l10n.deletePlaylist))),
                  ],
                ),
              ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          if (playlist.coverUrl?.isNotEmpty == true)
            ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(playlist.coverUrl!, fit: BoxFit.cover, cacheWidth: 960))),
          const SizedBox(height: 16),
          Text(playlist.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (playlist.description?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text(playlist.description!)),
          const SizedBox(height: 4),
          Text('${l10n.videoCount(playlist.count)} · ${playlistSortLabel(l10n, playlist.sort)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: videos.isEmpty ? null : () => context.push('/video/${videos.first.videoCode}'), icon: const Icon(Icons.play_arrow), label: Text(l10n.playAll))),
            const SizedBox(width: 8),
            IconButton.filledTonal(tooltip: l10n.select, onPressed: videos.isEmpty ? null : _enterSelection, icon: const Icon(Icons.checklist_outlined)),
          ]),
          const SizedBox(height: 16),
          if (videos.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Center(child: Text(l10n.playlistEmpty)))
          else
            PlaylistVideoGrid(videos: videos, editing: _editing, selected: _selected, onToggle: _toggle),
        ],
      ),
    );
  }

  void _toggle(FollowingVideo video) => setState(() {
        _editing = true;
        _selected.contains(video.videoCode) ? _selected.remove(video.videoCode) : _selected.add(video.videoCode);
      });

  void _enterSelection() => setState(() => _editing = true);

  void _exitSelection() => setState(() {
        _editing = false;
        _selected.clear();
      });

  Future<void> _changeSort(Playlist playlist) async {
    final selected = await showPlaylistSortSheet(context, playlist.sort);
    if (selected == null) return;
    await ref.read(libraryProvider.notifier).setPlaylistSort(playlist.id, selected);
  }

  Future<void> _edit(Playlist playlist) async {
    final result = await showDialog<PlaylistEditorResult>(context: context, builder: (_) => PlaylistEditorDialog(title: playlist.title, description: playlist.description));
    if (result == null || result.title.isEmpty) return;
    await ref.read(libraryProvider.notifier).updatePlaylist(playlist.id, title: result.title, description: result.description);
  }

  Future<void> _delete(Playlist playlist) async {
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
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _removeSelected(String playlistId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.selectedItems(_selected.length)),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete))],
      ),
    );
    if (confirmed != true) return;
    await ref.read(libraryProvider.notifier).removePlaylistVideos(playlistId, {..._selected});
    if (mounted) _exitSelection();
  }
}

enum _PlaylistMenuAction { edit, delete }
