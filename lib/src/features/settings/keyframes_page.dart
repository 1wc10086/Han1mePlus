import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../data/local/keyframe_repository.dart';

class KeyframesPage extends ConsumerWidget {
  const KeyframesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.keyframeManagement)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              l10n.manage,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const _KeyframeVideoList(),
        ],
      ),
    );
  }
}

class _KeyframeVideoList extends ConsumerWidget {
  const _KeyframeVideoList();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(keyframeVideosProvider).when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: M3EContainedLoadingIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$error'),
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(AppLocalizations.of(context)!.noKeyframes)),
            );
          }
          return Column(
            children: videos
                .map((video) => _KeyframeVideoTile(video: video))
                .toList(growable: false),
          );
        },
      );
}

class _KeyframeVideoTile extends ConsumerWidget {
  const _KeyframeVideoTile({required this.video});
  final KeyframeVideo video;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExpansionTile(
        leading: const Icon(Icons.movie_outlined),
        title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${video.id}  ·  ${AppLocalizations.of(context)!.keyframeCount(video.positions.length)}'),
        trailing: PopupMenuButton<_VideoAction>(
          onSelected: (action) => switch (action) {
            _VideoAction.editTitle => _editTitle(context, ref),
            _VideoAction.delete => _confirmDeleteVideo(context, ref),
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: _VideoAction.editTitle, child: Text(AppLocalizations.of(context)!.editVideoTitle)),
            PopupMenuItem(value: _VideoAction.delete, child: Text(AppLocalizations.of(context)!.deleteVideoKeyframes)),
          ],
        ),
        children: [
          for (final position in video.positions)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 8),
              title: Text(_format(position)),
              subtitle: Text('$position ms'),
              trailing: PopupMenuButton<_KeyframeAction>(
                onSelected: (action) => switch (action) {
                  _KeyframeAction.edit => _editPosition(context, ref, position),
                  _KeyframeAction.delete => ref.read(keyframesProvider(video.id).notifier).remove(position),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: _KeyframeAction.edit, child: Text(AppLocalizations.of(context)!.editPosition)),
                  PopupMenuItem(value: _KeyframeAction.delete, child: Text(AppLocalizations.of(context)!.deleteKeyframe)),
                ],
              ),
            ),
        ],
      );

  Future<void> _confirmDeleteVideo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteKeyframeTitle),
        content: Text(l10n.deleteVideoKeyframesConfirmation(video.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed == true) await ref.read(keyframesProvider(video.id).notifier).deleteVideo();
  }

  Future<void> _editTitle(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: video.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editVideoTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.videoTitle),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(l10n.save)),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      await ref.read(keyframesProvider(video.id).notifier).setTitle(title);
    }
  }

  Future<void> _editPosition(BuildContext context, WidgetRef ref, int position) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: position.toString());
    final next = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editKeyframe),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.positionMilliseconds),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: Text(l10n.save)),
        ],
      ),
    );
    if (next == null || next == position) return;
    final updated = await ref.read(keyframesProvider(video.id).notifier).updatePosition(position, next);
    if (context.mounted && !updated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidKeyframe)));
    }
  }

  static String _format(int positionMs) {
    final duration = Duration(milliseconds: positionMs);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}

enum _VideoAction { editTitle, delete }

enum _KeyframeAction { edit, delete }
