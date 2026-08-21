import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/models/search_query.dart';
import 'search_controller.dart';

Future<SearchQuery?> showSearchHistorySheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<SearchQuery>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _SearchHistorySheet(),
    );

class _SearchHistorySheet extends ConsumerWidget {
  const _SearchHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(searchHistoryProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.searchHistoryEmpty)),
          data: (items) => items.isEmpty
              ? Center(child: Text(l10n.searchHistoryEmpty))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) return Text(l10n.searchHistory, style: Theme.of(context).textTheme.titleLarge);
                    final query = items[index - 1];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text(query.text.isEmpty ? l10n.searchHistoryAll : query.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_summary(l10n, query), maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.of(context).pop(query),
                        trailing: IconButton(
                          tooltip: l10n.deleteSearchHistory,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(searchHistoryProvider.notifier).remove(query),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _summary(AppLocalizations l10n, SearchQuery query) {
    final filters = <String>[
      if (query.genre.isNotEmpty) query.genre,
      if (query.sort.isNotEmpty) query.sort,
      if (query.date.isNotEmpty) query.date,
      if (query.duration.isNotEmpty) query.duration,
      if (query.tags.isNotEmpty) l10n.searchHistoryTags(query.tags.length),
      if (query.type.isNotEmpty) l10n.searchAuthors,
    ];
    return filters.isEmpty ? l10n.searchHistoryAll : filters.join(' · ');
  }
}
