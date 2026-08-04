import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/han1me_repository.dart';
import '../../data/local/download_repository.dart';
import '../../data/local/library_repository.dart';
import '../../domain/models/library.dart';
import '../../domain/models/video.dart';
import '../account/account_controller.dart';
import '../library/remote_library_controller.dart';
import '../settings/settings_controller.dart';
import 'video_controller.dart';

class VideoActionBar extends ConsumerWidget {
  const VideoActionBar({super.key, required this.video});

  final VideoDetail video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider).value ?? const LibraryState();
    final account = ref.watch(accountProvider).valueOrNull;
    final remote = account == null ? null : ref.watch(remoteLibraryProvider).valueOrNull;
    final inWatchLater = (remote?.watchLater ?? library.watchLater).any((item) => item.videoCode == video.id);
    final persistedFavorite = (remote?.favorites ?? library.favorites).any((item) => item.videoCode == video.id);
    final inFavorites = ref.watch(favoriteOverrideProvider(video.id)) ?? persistedFavorite;
    final l10n = AppLocalizations.of(context)!;
    return M3EHorizontalFloatingToolbar(
      expanded: true,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(tooltip: l10n.addToPlaylist, icon: Icon(inWatchLater ? Icons.playlist_add_check : Icons.playlist_add), onPressed: () => account == null ? _pickLocalPlaylist(context, ref, library) : _pickPlaylist(context, ref, video.csrfToken ?? remote?.csrfToken ?? account.csrfToken, remote)),
          IconButton(tooltip: l10n.favorite, icon: Icon(inFavorites ? Icons.favorite : Icons.favorite_border), onPressed: () => _toggleFavorite(ref, account == null ? null : video.csrfToken ?? account.csrfToken, account == null ? null : video.currentUserId ?? account.id, !inFavorites)),
          IconButton(tooltip: l10n.download, icon: const Icon(Icons.download_outlined), onPressed: video.sources.isEmpty ? null : () => _showDownloadPicker(context, ref)),
          IconButton(tooltip: l10n.share, icon: const Icon(Icons.share_outlined), onPressed: () => Share.share('${video.title} (${video.id})', subject: video.title)),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, String? token, String? userId, bool enabled) async {
    ref.read(favoriteOverrideProvider(video.id).notifier).state = enabled;
    try {
      if (token == null || userId == null) {
        await ref.read(libraryProvider.notifier).setFavorite(video, enabled);
        return;
      }
      final settings = await ref.read(settingsProvider.future);
      await ref.read(han1meRepositoryProvider).setFavorite(settings.resolvedBaseUrl, token, userId, video.id, enabled);
      ref.invalidate(remoteLibraryProvider);
    } catch (_) {
      ref.read(favoriteOverrideProvider(video.id).notifier).state = !enabled;
    }
  }

  Future<void> _pickLocalPlaylist(BuildContext context, WidgetRef ref, LibraryState library) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(AppLocalizations.of(context)!.addToPlaylist)),
            ListTile(leading: const Icon(Icons.watch_later_outlined), title: Text(AppLocalizations.of(context)!.watchLater), onTap: () => Navigator.pop(context, '__watch_later__')),
            ...library.playlists.map((item) => ListTile(leading: const Icon(Icons.playlist_play), title: Text(item.title), subtitle: Text(AppLocalizations.of(context)!.videoCount(item.count)), onTap: () => Navigator.pop(context, item.id))),
            ListTile(leading: const Icon(Icons.add), title: Text(AppLocalizations.of(context)!.newPlaylist), onTap: () => Navigator.pop(context, '__create__')),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final controller = ref.read(libraryProvider.notifier);
    if (selected == '__watch_later__') {
      await controller.setWatchLater(video, true);
      return;
    }
    if (selected != '__create__') {
      await controller.saveToPlaylist(video, selected);
      return;
    }
    final result = await showDialog<String>(context: context, builder: (_) => const _PlaylistNameDialog());
    if (result?.isEmpty != false) return;
    await controller.createPlaylist(video, result!);
  }

  Future<void> _pickPlaylist(BuildContext context, WidgetRef ref, String? token, RemoteLibrary? library) async {
    if (token == null) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(AppLocalizations.of(context)!.addToPlaylist)),
            ListTile(leading: const Icon(Icons.watch_later_outlined), title: Text(AppLocalizations.of(context)!.watchLater), onTap: () => Navigator.pop(context, 'save')),
            ...(library?.playlists ?? const <Playlist>[]).map((item) => ListTile(leading: const Icon(Icons.playlist_play), title: Text(item.title), subtitle: Text(AppLocalizations.of(context)!.videoCount(item.count)), onTap: () => Navigator.pop(context, item.id))),
            ListTile(leading: const Icon(Icons.add), title: Text(AppLocalizations.of(context)!.newPlaylist), onTap: () => Navigator.pop(context, '__create__')),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final settings = await ref.read(settingsProvider.future);
    if (selected == '__create__') {
      final result = await showDialog<(String, String)>(context: context, builder: (_) => const _PlaylistEditorDialog());
      if (result == null || result.$1.isEmpty) return;
      await ref.read(han1meRepositoryProvider).createPlaylist(settings.resolvedBaseUrl, token, video.id, result.$1, result.$2);
    } else {
      await ref.read(han1meRepositoryProvider).saveToPlaylist(settings.resolvedBaseUrl, token, selected, video.id, true);
    }
    ref.invalidate(remoteLibraryProvider);
  }

  Future<void> _showDownloadPicker(BuildContext context, WidgetRef ref) async {
    var source = video.sources.first;
    final picked = await showModalBottomSheet<VideoSource>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(AppLocalizations.of(context)!.selectDownloadQuality, style: const TextStyle(fontWeight: FontWeight.w600))),
              ...video.sources.map((item) => RadioListTile<VideoSource>(value: item, groupValue: source, onChanged: (value) => setSheet(() => source = value!), title: Text(item.quality))),
              const SizedBox(height: 8),
              FilledButton(onPressed: () => Navigator.pop(sheetContext, source), child: Text(AppLocalizations.of(context)!.startDownload)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(downloadProvider.notifier).create(video, picked, 'default');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addedToDownloadQueue)));
    }
  }
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog();

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(title: Text(l10n.newPlaylist), content: TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.name)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, _title.text.trim()), child: Text(l10n.create))]);
  }
}

class _PlaylistEditorDialog extends StatefulWidget {
  const _PlaylistEditorDialog();

  @override
  State<_PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends State<_PlaylistEditorDialog> {
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
    return AlertDialog(title: Text(l10n.newPlaylist), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.name)), TextField(controller: _description, decoration: InputDecoration(labelText: l10n.description))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, (_title.text.trim(), _description.text.trim())), child: Text(l10n.create))]);
  }
}
