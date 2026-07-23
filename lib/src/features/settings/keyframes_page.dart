import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../l10n/app_localizations.dart';

import '../../core/settings.dart';
import '../../data/keyframe_repository.dart';
import '../../data/local/keyframe_repository.dart';
import '../../data/remote/keyframe_api.dart';
import 'settings_controller.dart';

class KeyframesPage extends ConsumerWidget {
  const KeyframesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(settingsProvider).valueOrNull?.keyframesEnabled ?? true;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.keyframeSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.keyframesEnabled),
            subtitle: Text(enabled ? l10n.keyframesEnabledDescription : l10n.keyframesDisabledDescription),
            onTap: () => ref.read(settingsProvider.notifier).saveChanges(
                  (current) => current.copyWith(keyframesEnabled: !current.keyframesEnabled),
                ),
            trailing: Switch(
              value: enabled,
              onChanged: (value) => ref.read(settingsProvider.notifier).saveChanges(
                    (current) => current.copyWith(keyframesEnabled: value),
                  ),
            ),
          ),
          if (enabled) const Divider(height: 1),
          if (enabled)
            SwitchListTile(
              secondary: const Icon(Icons.upload_outlined),
              title: Text(l10n.shareKeyframes),
              subtitle: Text(l10n.shareKeyframesDescription),
              value: settings?.shareKeyframes ?? false,
              onChanged: (value) => _setSharing(context, ref, value),
            ),
          if (enabled) const Divider(height: 1),
          if (enabled)
            SwitchListTile(
              secondary: const Icon(Icons.volunteer_activism_outlined),
              title: Text(l10n.useSharedKeyframes),
              subtitle: Text(l10n.useSharedKeyframesDescription),
              value: settings?.useSharedKeyframes ?? true,
              onChanged: (value) => _saveAndRefresh(ref, (current) => current.copyWith(useSharedKeyframes: value)),
            ),
          if (enabled) const Divider(height: 1),
          if (enabled)
            SwitchListTile(
              secondary: const Icon(Icons.priority_high_outlined),
              title: Text(l10n.preferSharedKeyframes),
              subtitle: Text(l10n.preferSharedKeyframesDescription),
              value: settings?.preferSharedKeyframes ?? false,
              onChanged: settings?.useSharedKeyframes ?? true
                  ? (value) => _saveAndRefresh(ref, (current) => current.copyWith(preferSharedKeyframes: value))
                  : null,
            ),
          if (enabled) const Divider(height: 1),
          if (enabled) Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(l10n.manage, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (enabled) const _KeyframeVideoList(),
        ],
      ),
    );
  }

  Future<void> _setSharing(BuildContext context, WidgetRef ref, bool value) async {
    if (!value) {
      await _saveAndRefresh(ref, (current) => current.copyWith(shareKeyframes: false));
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.shareKeyframes),
        content: Text(AppLocalizations.of(context)!.shareKeyframesConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.upload)),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    await _saveAndRefresh(ref, (current) => current.copyWith(shareKeyframes: true));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _KeyframeUploadDialog(),
    );
  }

  Future<void> _saveAndRefresh(WidgetRef ref, AppSettings Function(AppSettings) change) async {
    await ref.read(settingsProvider.notifier).saveChanges(change);
    ref.invalidate(keyframesProvider);
  }
}

class _KeyframeUploadDialog extends ConsumerStatefulWidget {
  const _KeyframeUploadDialog();

  @override
  ConsumerState<_KeyframeUploadDialog> createState() => _KeyframeUploadDialogState();
}

class _KeyframeUploadDialogState extends ConsumerState<_KeyframeUploadDialog> {
  var _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _upload();
  }

  Future<void> _upload() async {
    try {
      final videos = await ref.read(keyframeVideosProvider.future);
      final repository = ref.read(sharedKeyframeRepositoryProvider);
      for (final video in videos) {
        await repository.upload(SharedKeyframeVideo(id: video.id, title: video.title, positions: video.positions));
      }
      if (mounted) setState(() => _finished = true);
    } on DioException catch (error) {
      if (mounted) setState(() => _error = error.response?.statusCode?.toString() ?? error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_finished ? l10n.uploadComplete : l10n.uploadingKeyframes),
      content: _error == null ? (_finished ? Text(l10n.keyframesUploadDescription) : const LinearProgressIndicator()) : Text(l10n.keyframesUploadFailed(_error!)),
      actions: _finished || _error != null ? [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))] : null,
    );
  }
}

class _KeyframeVideoList extends ConsumerWidget {
  const _KeyframeVideoList();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(keyframeVideosProvider).when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
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
