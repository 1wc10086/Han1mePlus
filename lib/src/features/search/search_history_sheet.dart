import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/assets/search_option_catalog.dart';
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
    final catalog = ref.watch(searchOptionCatalogProvider).valueOrNull;
    final localeKey = searchOptionLocaleKey(Localizations.localeOf(context));
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
                        title: Text(_title(l10n, query, catalog, localeKey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_summary(l10n, query, catalog, localeKey), maxLines: 2, overflow: TextOverflow.ellipsis),
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

  String _title(AppLocalizations l10n, SearchQuery query, SearchOptionCatalog? catalog, String localeKey) {
    if (query.text.isNotEmpty) return query.text;
    final filters = _filters(l10n, query, catalog, localeKey);
    if (filters.isNotEmpty) return filters.first;
    return l10n.searchHistoryAll;
  }

  String _summary(AppLocalizations l10n, SearchQuery query, SearchOptionCatalog? catalog, String localeKey) {
    final filters = _filters(l10n, query, catalog, localeKey);
    return filters.isEmpty ? l10n.searchHistoryAll : filters.join(' · ');
  }

  List<String> _filters(AppLocalizations l10n, SearchQuery query, SearchOptionCatalog? catalog, String localeKey) => [
        if (query.genre.isNotEmpty) catalog?.genres.localize(query.genre, localeKey) ?? query.genre,
        if (query.sort.isNotEmpty) catalog?.sorts.localize(query.sort, localeKey) ?? query.sort,
        if (query.date.isNotEmpty) catalog?.releaseDates.localize(query.date, localeKey) ?? query.date,
        if (query.duration.isNotEmpty) catalog?.durations.localize(query.duration, localeKey) ?? query.duration,
        if (query.tags.isNotEmpty) _tags(query, catalog, localeKey),
        if (query.type.isNotEmpty) l10n.searchAuthors,
      ];

  String _tags(SearchQuery query, SearchOptionCatalog? catalog, String localeKey) => query.tags.map((tag) => catalog?.localizeTag(tag, localeKey) ?? tag).join(' · ');
}
