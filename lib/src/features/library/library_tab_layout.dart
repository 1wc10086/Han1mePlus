import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';

Future<void> showLibraryTabOrderDialog(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider).valueOrNull;
  if (settings == null) return;
  final initial = List<String>.from(settings.resolvedLibraryTabOrder);
  final order = await showDialog<List<String>>(
    context: context,
    builder: (_) => _LibraryTabOrderDialog(initial: initial),
  );
  if (order == null) return;
  await ref.read(settingsProvider.notifier).saveChanges(
        (current) => current.copyWith(libraryTabOrder: order),
      );
}

class _LibraryTabOrderDialog extends ConsumerStatefulWidget {
  const _LibraryTabOrderDialog({required this.initial});

  final List<String> initial;

  @override
  ConsumerState<_LibraryTabOrderDialog> createState() => _LibraryTabOrderDialogState();
}

class _LibraryTabOrderDialogState extends ConsumerState<_LibraryTabOrderDialog> {
  late List<String> _order = List<String>.from(widget.initial);
  final _scrollController = ScrollController();

  String _labelFor(AppLocalizations l10n, String key) => switch (key) {
        'watch-later' => l10n.watchLater,
        'favorites' => l10n.favoriteVideos,
        'playlists' => l10n.playlists,
        'subscriptions' => l10n.subscriptions,
        'history' => l10n.watchHistory,
        _ => l10n.watchLater,
      };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.libraryTabOrder),
      content: SizedBox(
        width: 420,
        height: MediaQuery.sizeOf(context).height * .5,
        child: ReorderableListView.builder(
          scrollController: _scrollController,
          buildDefaultDragHandles: false,
          itemCount: _order.length,
          onReorder: (oldIndex, newIndex) => setState(() {
            final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
            final key = _order.removeAt(oldIndex);
            _order.insert(target, key);
          }),
          itemBuilder: (context, index) {
            final key = _order[index];
            return ListTile(
              key: ValueKey(key),
              contentPadding: EdgeInsets.zero,
              title: Text(_labelFor(l10n, key)),
              leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator)),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(settingsProvider.notifier).saveChanges(
                  (current) => current.copyWith(libraryTabOrder: const []),
                );
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          child: Text(l10n.restoreDefaultOrder),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(_order), child: Text(l10n.save)),
      ],
    );
  }
}
