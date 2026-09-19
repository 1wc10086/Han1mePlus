import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../data/assets/search_option_catalog.dart';
import '../../data/han1me_repository.dart';
import '../../data/local/json_store.dart';
import '../../data/local/search_history_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/search_query.dart';
import '../../domain/models/video.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';

final searchQueryProvider = StateNotifierProvider.family<SearchQueryNotifier, SearchQuery, SearchRouteRequest>(
  (_, request) => SearchQueryNotifier(SearchQuery.fromUri(request.initialUrl)),
);

final searchHistoryProvider = AsyncNotifierProvider<SearchHistoryController, List<SearchQuery>>(SearchHistoryController.new);

class SearchQueryNotifier extends StateNotifier<SearchQuery> {
  SearchQueryNotifier(super.state);

  void text(String value) => _update(state.copyWith(text: value, page: 1));
  void genre(String value) => _update(state.copyWith(genre: value, page: 1));
  void sort(String value) => _update(state.copyWith(sort: value, page: 1));
  void date(String value) => _update(state.copyWith(date: value, page: 1));
  void duration(String value) => _update(state.copyWith(duration: value, page: 1));
  void tags(List<String> value, bool broad) => _update(state.copyWith(tags: List.unmodifiable(value), broad: broad, page: 1));
  void type(String value) => _update(state.copyWith(type: value, page: 1));
  void artist(String value) => _update(state.copyWith(text: value, type: '', page: 1));
  void page(int value) => state = state.copyWith(page: value);
  void replace(SearchQuery value) => _update(value.copyWith(page: 1));
  void reset() => _update(const SearchQuery());

  void _update(SearchQuery next) {
    if (next == state) return;
    state = next;
  }
}

class SearchHistoryController extends AsyncNotifier<List<SearchQuery>> {
  final _repository = SearchHistoryRepository(JsonStore());
  Future<void> _write = Future<void>.value();

  @override
  Future<List<SearchQuery>> build() => _repository.load();

  Future<void> record(SearchQuery query) async {
    if (!query.hasSearchCriteria) return;
    final current = state.valueOrNull ?? await future;
    final next = [query, ...current.where((item) => item != query)].take(30).toList(growable: false);
    state = AsyncData(next);
    _write = _write.catchError((_) {}).then((_) => _repository.save(next));
    await _write;
  }

  Future<void> remove(SearchQuery query) async {
    final current = state.valueOrNull ?? await future;
    final next = current.where((item) => item != query).toList(growable: false);
    state = AsyncData(next);
    _write = _write.catchError((_) {}).then((_) => _repository.save(next));
    await _write;
  }
}

final searchResultsProvider = FutureProvider.autoDispose.family<SearchResult, SearchRouteRequest>((ref, request) async {
  ref.watch(accountProvider);
  final settings = await ref.watch(settingsProvider.future);
  final catalog = await ref.watch(searchOptionCatalogProvider.future);
  final query = ref.watch(searchQueryProvider(request));
  final result = await ref.watch(han1meRepositoryProvider).search(
        baseUrl: settings.resolvedBaseUrl,
        query: query.text,
        genre: catalog.genres.canonical(query.genre),
        sort: catalog.sorts.canonical(query.sort),
        date: catalog.releaseDates.canonical(query.date),
        duration: catalog.durations.canonical(query.duration),
        tags: query.tags.map(catalog.canonicalTag).toList(growable: false),
        broad: query.broad,
        type: query.type,
        page: query.page,
      );
  if (!settings.applyRecommendationFiltersToSearch) return result;
  return SearchResult(items: result.items.where((video) => _visible(video, settings)).toList(), page: result.page, totalPages: result.totalPages);
});

bool _visible(VideoCard video, AppSettings settings) {
  if (settings.blockedVideoTitleKeywords.any((keyword) => video.title.toLowerCase().contains(keyword.toLowerCase()))) return false;
  if (settings.blockedAuthors.any((author) => (video.artist ?? '').toLowerCase().contains(author.toLowerCase()))) return false;
  final seconds = (video.duration?.split(':').map(int.tryParse).toList() ?? const <int?>[]).fold<int>(0, (total, part) => part == null ? total : total * 60 + part);
  final views = int.tryParse(RegExp(r'[\d,.]+').firstMatch(video.views ?? '')?.group(0)?.replaceAll(',', '') ?? '') ?? 0;
  return seconds >= settings.minimumVideoDurationSeconds && views >= settings.minimumVideoViews;
}
