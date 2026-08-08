import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_shell.dart';
import '../../data/local/download_repository.dart';
import '../../domain/models/download.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import '../shared/video_card.dart';
import '../video/video_page.dart';
import 'cache_controller.dart';

class CachePage extends ConsumerStatefulWidget {
  const CachePage({super.key});

  @override
  ConsumerState<CachePage> createState() => _CachePageState();
}

class _CachePageState extends ConsumerState<CachePage> with TickerProviderStateMixin {
  TabController? tabController;
  List<String> groupIds = const [];

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadProvider);
    final view = ref.watch(cacheViewProvider);
    final l10n = AppLocalizations.of(context)!;
    return downloads.when(
      loading: () => const Scaffold(body: Center(child: M3EContainedLoadingIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (state) {
        final groupId = state.groups.any((group) => group.id == view.groupId) ? view.groupId : 'default';
        _syncTabController(state.groups, groupId);
        final selectedGroup = state.groups[tabController!.index];
        final tasks = _tasksForGroup(state, selectedGroup);
        return Scaffold(
          appBar: AppBar(
            leading: view.selecting
                ? IconButton(tooltip: l10n.cancel, onPressed: ref.read(cacheViewProvider.notifier).clearSelection, icon: const Icon(Icons.close))
                : ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false
                    ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu))
                    : null,
            title: Text(view.selecting ? l10n.selectedItems(view.selected.length) : l10n.cache),
            actions: view.selecting
                ? _selectionActions(context, ref, state, tasks)
                : [
                    IconButton(tooltip: l10n.createGroup, onPressed: () => context.push('/cache/groups/new'), icon: const Icon(Icons.create_new_folder_outlined)),
                    PopupMenuButton<_CacheMenuAction>(
                      tooltip: l10n.more,
                      onSelected: (action) {
                        if (action == _CacheMenuAction.groupSettings) context.push('/cache/groups/${selectedGroup.id}');
                      },
                      itemBuilder: (context) => [PopupMenuItem(value: _CacheMenuAction.groupSettings, child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.tune), title: Text(l10n.bookshelfSettings)))],
                    ),
                  ],
            bottom: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final group in state.groups) Tab(text: _groupName(group, l10n))],
            ),
          ),
          body: TabBarView(
            controller: tabController,
            children: [
              for (final group in state.groups) _CacheBody(key: PageStorageKey(group.id), tasks: _tasksForGroup(state, group)),
            ],
          ),
        );
      },
    );
  }

  void _syncTabController(List<DownloadGroup> groups, String selectedGroupId) {
    final nextIds = groups.map((group) => group.id).toList(growable: false);
    final selectedIndex = nextIds.indexOf(selectedGroupId).clamp(0, nextIds.length - 1).toInt();
    if (!_sameIds(groupIds, nextIds)) {
      tabController?.dispose();
      groupIds = nextIds;
      tabController = TabController(length: groups.length, initialIndex: selectedIndex, vsync: this)..addListener(_onTabChanged);
      return;
    }
    if (tabController!.index != selectedIndex && !tabController!.indexIsChanging) tabController!.animateTo(selectedIndex);
  }

  void _onTabChanged() {
    final controller = tabController;
    if (controller == null || controller.indexIsChanging || controller.index < 0 || controller.index >= groupIds.length) return;
    final animation = controller.animation;
    if (animation != null && (animation.value - controller.index).abs() > .001) return;
    final groupId = groupIds[controller.index];
    if (ref.read(cacheViewProvider).groupId != groupId) ref.read(cacheViewProvider.notifier).selectGroup(groupId);
  }

  List<DownloadTask> _tasksForGroup(DownloadState state, DownloadGroup group) => _sortTasks(
        state.tasks.where((task) => group.id == 'default' || task.groupIds.contains(group.id)),
        group.sort,
      );

  List<Widget> _selectionActions(BuildContext context, WidgetRef ref, DownloadState state, List<DownloadTask> tasks) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.read(cacheViewProvider).selected;
    return [
      IconButton(tooltip: l10n.selectAll, onPressed: () => ref.read(cacheViewProvider.notifier).selectAll(tasks.map((task) => task.id)), icon: const Icon(Icons.select_all)),
      IconButton(
        tooltip: l10n.pin,
        onPressed: () async {
          await ref.read(downloadProvider.notifier).togglePinned(selected);
          ref.read(cacheViewProvider.notifier).clearSelection();
        },
        icon: const Icon(Icons.push_pin_outlined),
      ),
      IconButton(
        tooltip: l10n.deleteSelectedCache,
        onPressed: () async {
          await ref.read(downloadProvider.notifier).deleteTasks(selected);
          ref.read(cacheViewProvider.notifier).clearSelection();
        },
        icon: const Icon(Icons.delete_outline),
      ),
      IconButton(tooltip: l10n.switchGroup, onPressed: () => _switchGroups(context, ref, state, selected), icon: const Icon(Icons.drive_file_move_outline)),
    ];
  }

  Future<void> _switchGroups(BuildContext context, WidgetRef ref, DownloadState state, Set<String> selectedIds) async {
    final selectedTasks = state.tasks.where((task) => selectedIds.contains(task.id)).toList();
    final initial = state.groups.where((group) => group.id != 'default' && selectedTasks.every((task) => task.groupIds.contains(group.id))).map((group) => group.id).toSet();
    final groups = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _GroupSelectionDialog(groups: state.groups, selected: initial),
    );
    if (groups == null) return;
    await ref.read(downloadProvider.notifier).setTaskGroups(selectedIds, groups);
    ref.read(cacheViewProvider.notifier).clearSelection();
  }
}

class _CacheBody extends ConsumerWidget {
  const _CacheBody({super.key, required this.tasks});

  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(cacheViewProvider);
    final pinned = tasks.where((task) => task.pinned).toList();
    if (tasks.isEmpty) return Center(child: Text(l10n.noCache));
    return ListView(
      padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        if (pinned.isNotEmpty) ...[
          _SectionHeader(title: l10n.pinned, count: pinned.length, expanded: view.pinnedExpanded, onTap: ref.read(cacheViewProvider.notifier).togglePinnedExpanded),
          if (view.pinnedExpanded) _TaskGrid(tasks: pinned),
        ],
        _SectionHeader(title: l10n.all, count: tasks.length, expanded: view.allExpanded, onTap: ref.read(cacheViewProvider.notifier).toggleAllExpanded),
        if (view.allExpanded) _TaskGrid(tasks: tasks),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count, required this.expanded, required this.onTap});

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(expanded ? Icons.expand_more : Icons.chevron_right),
        title: Text(title),
        trailing: Text('$count'),
        onTap: onTap,
      );
}

class _TaskGrid extends ConsumerWidget {
  const _TaskGrid({required this.tasks});

  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final horizontal = settings?.useHorizontalSearchCards ?? true;
    final preferredCards = settings?.searchCardsPerRow ?? 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = videoCardMetrics(viewportWidth: constraints.maxWidth, horizontal: horizontal, cardsPerRow: preferredCards, expanded: true);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: metrics.cardsPerRow, mainAxisSpacing: 12, crossAxisSpacing: 10, mainAxisExtent: metrics.cardHeight + 36),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _TaskCard(task: tasks[index], horizontal: horizontal),
        );
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.horizontal});

  final DownloadTask task;
  final bool horizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(cacheViewProvider);
    final selected = view.selected.contains(task.id);
    final label = switch (task.status) {
      DownloadStatus.queued => l10n.queued,
      DownloadStatus.downloading => l10n.downloading,
      DownloadStatus.completed => l10n.completed,
      DownloadStatus.failed => l10n.failed,
    };
    final localCover = task.localCoverPath;
    final cover = localCover != null && File(localCover).existsSync() ? FileImage(File(localCover)) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoCardTile(
                video: VideoCard(id: task.videoCode, title: task.title, coverUrl: task.coverUrl ?? '', duration: task.duration, views: task.views, rating: task.rating, uploadTime: task.uploadTime),
                horizontal: horizontal,
                selected: selected,
                coverImage: cover,
                onTap: view.selecting
                    ? () => ref.read(cacheViewProvider.notifier).toggleSelection(task.id)
                    : task.status == DownloadStatus.completed
                        ? () => _openCachedVideo(context, task)
                        : task.status == DownloadStatus.failed
                            ? () => ref.read(downloadProvider.notifier).retry(task.id)
                            : null,
                onLongPress: () => ref.read(cacheViewProvider.notifier).toggleSelection(task.id),
              ),
              if (task.pinned) const Positioned(top: 6, left: 6, child: Icon(Icons.push_pin, color: Colors.white, size: 20)),
              if (selected) const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued) ...[
                const SizedBox(height: 3),
                M3ELinearProgressIndicator(value: task.status == DownloadStatus.downloading ? task.progress : null),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openCachedVideo(BuildContext context, DownloadTask task) async {
    if (task.localVideoPath == null || !await File(task.localVideoPath!).exists()) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.localVideoMissing)));
      return;
    }
    final localVideo = VideoDetail(id: task.videoCode, title: task.title, coverUrl: task.coverUrl, sources: [VideoSource(quality: task.quality, url: task.localVideoPath!)], tags: const [], playlist: const [], related: const []);
    if (context.mounted) await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => VideoPage(id: task.videoCode, localVideo: localVideo)));
  }
}

class _GroupSelectionDialog extends StatefulWidget {
  const _GroupSelectionDialog({required this.groups, required this.selected});

  final List<DownloadGroup> groups;
  final Set<String> selected;

  @override
  State<_GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<_GroupSelectionDialog> {
  late final selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.switchGroup),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final group in widget.groups)
              CheckboxListTile(
                value: group.id == 'default' || selected.contains(group.id),
                onChanged: group.id == 'default'
                    ? null
                    : (value) => setState(() => value == true ? selected.add(group.id) : selected.remove(group.id)),
                title: Text(_groupName(group, l10n)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, selected), child: Text(l10n.confirm)),
      ],
    );
  }
}

List<DownloadTask> _sortTasks(Iterable<DownloadTask> source, DownloadGroupSort sort) {
  final tasks = source.toList();
  if (sort == DownloadGroupSort.recentlyUpdated) tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  if (sort == DownloadGroupSort.name) tasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return tasks;
}

String _groupName(DownloadGroup group, AppLocalizations l10n) => group.id == 'default' && (group.name == 'Default' || group.name == 'Cached') ? l10n.cachedDownloads : group.name;

enum _CacheMenuAction { groupSettings }

bool _sameIds(List<String> current, List<String> next) {
  if (current.length != next.length) return false;
  for (var index = 0; index < current.length; index++) {
    if (current[index] != next[index]) return false;
  }
  return true;
}
