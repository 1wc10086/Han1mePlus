import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/local/download_repository.dart';
import '../../core/app_shell.dart';
import '../../domain/models/download.dart';
import '../../domain/models/video.dart';
import '../shared/video_card.dart';
import '../video/video_page.dart';
import '../settings/settings_controller.dart';

class CachePage extends ConsumerStatefulWidget {
  const CachePage({super.key});

  @override
  ConsumerState<CachePage> createState() => _CachePageState();
}

class _CachePageState extends ConsumerState<CachePage> {
  var _groupId = 'default';
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(downloadProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null,
        title: Text(_selected.isEmpty ? l10n.cache : l10n.selectedItems(_selected.length)),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: l10n.deleteSelectedCache,
              onPressed: () async {
                await ref.read(downloadProvider.notifier).deleteTasks(_selected);
                if (mounted) setState(_selected.clear);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(tooltip: l10n.createGroup, onPressed: _addGroup, icon: const Icon(Icons.create_new_folder_outlined)),
        ],
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (state) {
          final selectedGroup = state.groups.any((group) => group.id == _groupId) ? _groupId : 'default';
          final tasks = state.tasks.where((task) => task.groupId == selectedGroup).toList(growable: false);
          return Column(children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: state.groups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return InputChip(label: Text(group.name), selected: group.id == selectedGroup, onPressed: () => setState(() => _groupId = group.id), onDeleted: group.id == 'default' ? null : () => _deleteGroup(group));
                },
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text(l10n.noCache))
                   : VideoCardGrid(
                        videos: tasks.map((task) => VideoCard(id: task.videoCode, title: task.title, coverUrl: task.coverUrl ?? '', duration: task.duration, views: task.views, rating: task.rating, uploadTime: task.uploadTime)).toList(growable: false),
                        itemBuilder: (context, index, video, horizontal) {
                         final task = tasks[index];
                         return _TaskCard(
                           task: task,
                           horizontal: horizontal,
                          selected: _selected.contains(task.id),
                          onSelect: () => setState(() => _selected.contains(task.id) ? _selected.remove(task.id) : _selected.add(task.id)),
                           onOpen: () => _openCachedVideo(task),
                           onDelete: () => _deleteTask(task),
                           onRetry: () => ref.read(downloadProvider.notifier).retry(task.id),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _openCachedVideo(DownloadTask task) async {
    if (task.status != DownloadStatus.completed || task.localVideoPath == null) return;
    if (!await File(task.localVideoPath!).exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.localVideoMissing)));
      return;
    }
    final localVideo = VideoDetail(
      id: task.videoCode,
      title: task.title,
      coverUrl: task.coverUrl,
      sources: [VideoSource(quality: task.quality, url: task.localVideoPath!)],
      tags: const [],
      playlist: const [],
      related: const [],
    );
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => VideoPage(id: task.videoCode, localVideo: localVideo)));
  }

  Future<void> _deleteTask(DownloadTask task) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.deleteCache), content: Text(l10n.deleteCacheConfirmation(task.title)), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.delete))]));
    if (confirmed == true && mounted) await ref.read(downloadProvider.notifier).deleteTasks({task.id});
  }

  Future<void> _deleteGroup(DownloadGroup group) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.deleteGroupTitle(group.name)), content: Text(l10n.moveGroupCacheToDefault), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.delete))]));
    if (confirmed != true || !mounted) return;
    await ref.read(downloadProvider.notifier).deleteGroup(group.id);
    if (mounted) setState(() => _groupId = 'default');
  }

  Future<void> _addGroup() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _GroupNameDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await ref.read(downloadProvider.notifier).addGroup(name);
  }
}

class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog();

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  var _name = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createGroup),
        content: TextField(autofocus: true, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.groupName), onChanged: (value) => setState(() => _name = value)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton(onPressed: _name.trim().isEmpty ? null : () => Navigator.pop(context, _name), child: Text(AppLocalizations.of(context)!.confirm)),
        ],
      );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.horizontal, required this.selected, required this.onSelect, required this.onOpen, required this.onDelete, required this.onRetry});
  final DownloadTask task;
  final bool horizontal;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (task.status) { DownloadStatus.queued => l10n.queued, DownloadStatus.downloading => l10n.downloading, DownloadStatus.completed => l10n.completed, DownloadStatus.failed => l10n.failed };
    final localCover = task.localCoverPath;
    final cover = localCover != null && File(localCover).existsSync() ? FileImage(File(localCover)) : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: selected ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)) : const BoxDecoration(),
          child: VideoCardTile(
            video: VideoCard(id: task.videoCode, title: task.title, coverUrl: task.coverUrl ?? '', duration: task.duration, views: task.views, rating: task.rating, uploadTime: task.uploadTime),
            horizontal: horizontal,
            coverImage: cover,
            onTap: task.status == DownloadStatus.completed ? onOpen : task.status == DownloadStatus.failed ? onRetry : onSelect,
            onLongPress: onDelete,
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued) LinearProgressIndicator(value: task.status == DownloadStatus.downloading ? task.progress : null),
              if (task.errorMessage != null) Text(task.errorMessage!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),
        if (selected) const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, color: Colors.white)),
        if (task.status == DownloadStatus.failed) Positioned(top: 2, right: 2, child: IconButton(tooltip: l10n.retry, onPressed: onRetry, icon: const Icon(Icons.refresh, color: Colors.white))),
      ],
    );
  }
}
