import '../../domain/models/search_query.dart';
import 'json_store.dart';

class SearchHistoryRepository {
  SearchHistoryRepository(this._store);

  static const _fileName = 'search_history.json';
  final JsonStore _store;

  Future<List<SearchQuery>> load() async {
    final data = await _store.read(_fileName);
    return ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => SearchQuery.fromJson(Map<String, dynamic>.from(item)))
        .where((query) => query.hasSearchCriteria)
        .toList(growable: false);
  }

  Future<void> save(List<SearchQuery> items) => _store.write(
        _fileName,
        {'items': items.map((item) => item.toJson()).toList(growable: false)},
      );
}
