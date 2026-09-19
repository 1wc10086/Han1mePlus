import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../data/han1me_repository.dart';
import '../../../domain/models/library.dart';
import '../../account/account_controller.dart';
import '../../settings/settings_controller.dart';
import '../../shared/video_card.dart';
import '../remote_library_controller.dart';
import 'playlist_shared.dart';

class RemotePlaylistPage extends ConsumerStatefulWidget {
  const RemotePlaylistPage({super.key, required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<RemotePlaylistPage> createState() => _RemotePlaylistPageState();
}

class _RemotePlaylistPageState extends ConsumerState<RemotePlaylistPage> {
  var _sort = 'latest';
  var _editing = false;
  final _selectedItems = <String>{};
  late Future<PlaylistDetail> _playlist = _load();

  Future<PlaylistDetail> _load() async {
    final settings = await ref.read(settingsProvider.future);
    return ref.read(han1meRepositoryProvider).playlist(settings.resolvedBaseUrl, widget.playlist.id, _sort);
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
          if (!snapshot.hasData) return const Center(child: M3EContainedLoadingIndicator());
          final playlist = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (playlist.playlist.coverUrl?.isNotEmpty == true) ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(playlist.playlist.coverUrl!, fit: BoxFit.cover, cacheWidth: 960))),
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
              if (playlist.videos.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(l10n.playlistEmpty))) else _RemotePlaylistVideoGrid(videos: playlist.videos, editing: _editing, selected: _selectedItems, onToggle: _toggleItem),
            ],
          );
        },
      ),
    );
  }

  String _sortLabel(AppLocalizations l10n, String value) => switch (value) {'latest' => l10n.latest, 'popular' => l10n.popular, _ => l10n.oldest};

  void _changeSort(String value) => setState(() { _sort = value; _playlist = _load(); });

  Future<void> _edit(PlaylistDetail playlist) async {
    final result = await showDialog<(String, String, bool)>(context: context, builder: (_) => _RemotePlaylistEditDialog(playlist: playlist));
    if (result == null) return;
    final account = ref.read(accountProvider).valueOrNull;
    if (account?.csrfToken == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).updatePlaylist(settings.resolvedBaseUrl, account!.csrfToken!, playlist.playlist.id, result.$1, result.$2, result.$3);
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
    await Future.wait(_selectedItems.map((id) => ref.read(han1meRepositoryProvider).removePlaylistItem(settings.resolvedBaseUrl, account!.csrfToken!, id)));
    if (mounted) setState(() { _editing = false; _selectedItems.clear(); _playlist = _load(); });
  }
}

class _RemotePlaylistVideoGrid extends StatelessWidget {
  const _RemotePlaylistVideoGrid({required this.videos, required this.editing, required this.selected, required this.onToggle});

  final List<FollowingVideo> videos;
  final bool editing;
  final Set<String> selected;
  final ValueChanged<FollowingVideo> onToggle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;
          final cardHeight = cardWidth * 9 / 16 + videoCardMetaHeight(context) + 36;
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
                  VideoCardTile(video: followingVideoCard(video), horizontal: true, onTap: editing ? () => onToggle(video) : null),
                  if (editing) Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: (value) => onToggle(video))),
                ],
              );
            },
          );
        },
      );
}

class _RemotePlaylistEditDialog extends StatefulWidget {
  const _RemotePlaylistEditDialog({required this.playlist});

  final PlaylistDetail playlist;

  @override
  State<_RemotePlaylistEditDialog> createState() => _RemotePlaylistEditDialogState();
}

class _RemotePlaylistEditDialogState extends State<_RemotePlaylistEditDialog> {
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

