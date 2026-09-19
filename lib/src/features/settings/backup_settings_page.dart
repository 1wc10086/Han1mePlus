import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/local/backup_service.dart';
import '../../data/local/download_repository.dart';
import '../../data/local/json_store.dart';
import '../../data/local/keyframe_repository.dart';
import '../../data/local/library_repository.dart';
import '../../data/local/watch_repository.dart';
import 'settings_card_list.dart';
import 'settings_controller.dart';

final backupServiceProvider = Provider((_) => BackupService(JsonStore()));

class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  ConsumerState<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  var busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          SettingsCardList(
            children: [
              SettingsCardItem(title: l10n.exportDataBackup, subtitle: l10n.exportDataBackupDescription, leading: const Icon(Icons.archive_outlined), enabled: !busy, onTap: _export),
              SettingsCardItem(title: l10n.importDataBackup, subtitle: l10n.importDataBackupDescription, leading: const Icon(Icons.unarchive_outlined), enabled: !busy, onTap: _import),
            ],
          ),
          if (busy) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => busy = true);
    try {
      final service = ref.read(backupServiceProvider);
      final saved = await service.export(BackupBundle(
        settings: await ref.read(settingsProvider.future),
        watch: await ref.read(watchProvider.future),
        library: await ref.read(libraryProvider.future),
        downloads: await ref.read(downloadProvider.future),
        keyframes: await service.readKeyframes(),
        checkIns: await service.readCheckIns(),
      ));
      if (mounted && saved) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.backupExported)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => busy = true);
    try {
      final service = ref.read(backupServiceProvider);
      final bundle = await service.import();
      if (bundle == null) return;
      final currentSettings = await ref.read(settingsProvider.future);
      await ref.read(settingsProvider.notifier).replace(bundle.settings.copyWith(downloadPath: currentSettings.downloadPath));
      await ref.read(watchProvider.notifier).replace(bundle.watch);
      await ref.read(libraryProvider.notifier).replace(bundle.library);
      await ref.read(downloadProvider.notifier).replace(bundle.downloads);
      await service.writeAuxiliary(bundle);
      ref.invalidate(keyframeVideosProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.backupImported)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
