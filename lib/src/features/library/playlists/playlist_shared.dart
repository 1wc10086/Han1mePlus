import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../domain/models/library.dart';
import '../../../domain/models/video.dart';
import '../../shared/video_card.dart';

VideoCard followingVideoCard(FollowingVideo video) => VideoCard(id: video.videoCode, title: video.title, coverUrl: video.coverUrl ?? '', artist: video.artistName, duration: video.duration, views: video.views, rating: video.rating, uploadTime: video.uploadTime);

String playlistSortLabel(AppLocalizations l10n, PlaylistSortOrder sort) => switch (sort) {
      PlaylistSortOrder.recentlyAdded => l10n.playlistSortRecentlyAdded,
      PlaylistSortOrder.oldestAdded => l10n.playlistSortOldestAdded,
      PlaylistSortOrder.title => l10n.playlistSortByName,
    };

class PlaylistCoverCard extends StatelessWidget {
  const PlaylistCoverCard({super.key, required this.playlist, required this.onTap, this.onLongPress});

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: SizedBox(width: double.infinity, child: playlist.coverUrl?.isNotEmpty == true ? Image.network(playlist.coverUrl!, fit: BoxFit.cover, cacheWidth: 480) : ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.playlist_play, size: 40)))),
            Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 2), child: Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
            Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 8), child: Text(AppLocalizations.of(context)!.videoCount(playlist.count), style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ),
      );
}

class PlaylistVideoGrid extends StatelessWidget {
  const PlaylistVideoGrid({super.key, required this.videos, required this.editing, required this.selected, required this.onToggle});

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
              final isSelected = selected.contains(video.videoCode);
              return Stack(
                fit: StackFit.expand,
                children: [
                  VideoCardTile(video: followingVideoCard(video), horizontal: true, onTap: editing ? () => onToggle(video) : null, onLongPress: editing ? null : () => onToggle(video)),
                  if (editing) Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: (value) => onToggle(video))),
                ],
              );
            },
          );
        },
      );
}

class PlaylistEditorDialog extends StatefulWidget {
  const PlaylistEditorDialog({super.key, this.title, this.description});

  final String? title;
  final String? description;

  @override
  State<PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class PlaylistEditorResult {
  const PlaylistEditorResult({required this.title, required this.description});

  final String title;
  final String description;
}

class _PlaylistEditorDialogState extends State<PlaylistEditorDialog> {
  late final _title = TextEditingController(text: widget.title ?? '');
  late final _description = TextEditingController(text: widget.description ?? '');

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
      title: Text(widget.title == null ? l10n.newPlaylist : l10n.edit),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.name)),
        TextField(controller: _description, minLines: 1, maxLines: 3, decoration: InputDecoration(labelText: l10n.description)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, PlaylistEditorResult(title: _title.text.trim(), description: _description.text.trim())), child: Text(l10n.confirm)),
      ],
    );
  }
}

Future<PlaylistSortOrder?> showPlaylistSortSheet(BuildContext context, PlaylistSortOrder current) => showModalBottomSheet<PlaylistSortOrder>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(l10n.sortOrder)),
              for (final sort in PlaylistSortOrder.values)
                RadioListTile<PlaylistSortOrder>(
                  value: sort,
                  groupValue: current,
                  onChanged: (value) => Navigator.pop(context, value),
                  title: Text(playlistSortLabel(l10n, sort)),
                ),
            ],
          ),
        );
      },
    );
