import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/comic.dart';
import 'remote/comic_api.dart';
import 'han1me_repository.dart';

final comicRepositoryProvider = Provider((ref) => ComicRepository(ComicApi(ref.read(han1meHttpClientProvider))));

class ComicRepository {
  ComicRepository(this._api);
  final ComicApi _api;
  final _requests = <String, Future<dynamic>>{};
  Future<T> _merge<T>(String key, Future<T> Function() request) { final existing = _requests[key]; if (existing != null) return existing as Future<T>; final future = request(); _requests[key] = future; future.whenComplete(() => _requests.remove(key)); return future; }
  Future<ComicHome> home() => _merge('home', _api.home);
  Future<ComicSearchResult> browse(String path, int page) => _merge('browse:$path:$page', () => _api.browse(path, page));
  Future<ComicDetail> detail(String id) => _merge('detail:$id', () => _api.detail(id));
}
