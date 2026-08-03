import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../settings/settings_controller.dart';
import '../account/account_controller.dart';
import '../../domain/models/video.dart';
import '../../core/settings.dart';

class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.genre = '',
    this.sort = '',
    this.date = '',
    this.duration = '',
    this.tags = const [],
    this.broad = false,
    this.type = '',
    this.page = 1,
  });

  final String text;
  final String genre;
  final String sort;
  final String date;
  final String duration;
  final List<String> tags;
  final bool broad;
  final String type;
  final int page;

  SearchQuery copyWith({
    String? text,
    String? genre,
    String? sort,
    String? date,
    String? duration,
    List<String>? tags,
    bool? broad,
    String? type,
    int? page,
  }) => SearchQuery(
        text: text ?? this.text,
        genre: genre ?? this.genre,
        sort: sort ?? this.sort,
        date: date ?? this.date,
        duration: duration ?? this.duration,
        tags: tags ?? this.tags,
        broad: broad ?? this.broad,
        type: type ?? this.type,
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
        date: params['date'] ?? '',
        duration: params['duration'] ?? '',
        tags: params['tags[]'] == null ? const [] : uri.queryParametersAll['tags[]']!,
        broad: params['broad'] == 'on',
        type: params['type'] ?? '',
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
  void date(String value) => state = state.copyWith(date: value, page: 1);
  void duration(String value) => state = state.copyWith(duration: value, page: 1);
  void tags(List<String> value, bool broad) => state = state.copyWith(tags: value, broad: broad, page: 1);
  void type(String value) => state = state.copyWith(type: value, page: 1);
  void artist(String value) => state = state.copyWith(text: value, type: '', page: 1);
  void page(int value) => state = state.copyWith(page: value);
  void reset() => state = const SearchQuery();
}

final searchResultsProvider = FutureProvider.autoDispose<SearchResult>((ref) async {
  ref.watch(accountProvider);
  final settings = await ref.watch(settingsProvider.future);
  final query = ref.watch(searchQueryProvider);
  final result = await ref.watch(han1meRepositoryProvider).search(
        baseUrl: settings.resolvedBaseUrl,
        query: query.text,
        genre: query.genre,
        sort: query.sort,
        date: query.date,
        duration: query.duration,
        tags: query.tags,
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
