import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../settings/settings_controller.dart';

class SearchQuery {
  const SearchQuery({this.text = '', this.genre = '', this.sort = '', this.page = 1});

  final String text;
  final String genre;
  final String sort;
  final int page;

  SearchQuery copyWith({String? text, String? genre, String? sort, int? page}) => SearchQuery(
        text: text ?? this.text,
        genre: genre ?? this.genre,
        sort: sort ?? this.sort,
        page: page ?? this.page,
      );
}

final searchInitProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateNotifierProvider<SearchQueryNotifier, SearchQuery>((ref) {
  final init = ref.watch(searchInitProvider);
  var query = const SearchQuery();
  if (init != null) {
    final uri = Uri.tryParse(init);
    if (uri != null) {
      final params = uri.queryParameters;
      query = SearchQuery(
        text: params['query'] ?? '',
        genre: params['genre'] ?? '',
        sort: params['sort'] ?? '',
        page: 1,
      );
    }
  }
  return SearchQueryNotifier(query);
});

class SearchQueryNotifier extends StateNotifier<SearchQuery> {
  SearchQueryNotifier(super.state);

  void text(String value) => state = state.copyWith(text: value, page: 1);
  void genre(String value) => state = state.copyWith(genre: value, page: 1);
  void sort(String value) => state = state.copyWith(sort: value, page: 1);
  void page(int value) => state = state.copyWith(page: value);
  void reset() => state = const SearchQuery();
}

final searchResultsProvider = FutureProvider.autoDispose<SearchResult>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final query = ref.watch(searchQueryProvider);
  return ref.watch(han1meRepositoryProvider).search(
        baseUrl: settings.baseUrl,
        query: query.text,
        genre: query.genre,
        sort: query.sort,
        page: query.page,
      );
});
