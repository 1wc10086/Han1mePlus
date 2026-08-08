import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/local/download_repository.dart';
import '../../domain/models/download.dart';
import '../settings/settings_card_list.dart';

class DownloadGroupPage extends ConsumerStatefulWidget {
  const DownloadGroupPage({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<DownloadGroupPage> createState() => _DownloadGroupPageState();
}

class _DownloadGroupPageState extends ConsumerState<DownloadGroupPage> {
  final nameController = TextEditingController();
  var sort = DownloadGroupSort.defaultOrder;
  var initialized = false;
  var saving = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final group = widget.groupId == null ? null : state?.groups.where((item) => item.id == widget.groupId).firstOrNull;
    if (!initialized && state != null) {
      nameController.text = group == null ? '' : group.id == 'default' && (group.name == 'Default' || group.name == 'Cached') ? l10n.cachedDownloads : group.name;
      sort = group?.sort ?? DownloadGroupSort.defaultOrder;
      initialized = true;
    }
    return Scaffold(
      appBar: AppBar(title: Text(group == null ? l10n.createGroup : l10n.bookshelfSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(controller: nameController, autofocus: group == null, decoration: InputDecoration(labelText: l10n.groupName)),
          ),
          const SizedBox(height: 16),
          SettingsCardList(
            children: [
              SettingsMenuItem<DownloadGroupSort>(
                title: l10n.sortOrder,
                subtitle: switch (sort) {
                  DownloadGroupSort.defaultOrder => l10n.defaultValue,
                  DownloadGroupSort.recentlyUpdated => l10n.recentlyUpdated,
                  DownloadGroupSort.name => l10n.name,
                },
                leading: const Icon(Icons.sort),
                value: sort,
                options: DownloadGroupSort.values,
                label: (value) => switch (value) {
                  DownloadGroupSort.defaultOrder => l10n.defaultValue,
                  DownloadGroupSort.recentlyUpdated => l10n.recentlyUpdated,
                  DownloadGroupSort.name => l10n.name,
                },
                onSelected: (value) => setState(() => sort = value),
              ),
              if (group != null && group.id != 'default')
                SettingsCardItem(title: l10n.deleteBookshelf, subtitle: l10n.deleteBookshelfDescription, leading: const Icon(Icons.delete_outline), onTap: () => _delete(group)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(onPressed: saving ? null : _save, child: Text(l10n.save)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => saving = true);
    if (widget.groupId == null) {
      await ref.read(downloadProvider.notifier).addGroup(name, sort);
    } else {
      await ref.read(downloadProvider.notifier).updateGroup(widget.groupId!, name, sort);
    }
    if (mounted) context.pop();
  }

  Future<void> _delete(DownloadGroup group) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBookshelf),
        content: Text(l10n.deleteBookshelfConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(downloadProvider.notifier).deleteGroup(group.id);
    if (mounted) context.go('/cache');
  }
}
