import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/getchu_preview.dart';
import 'han1me_repository.dart';
import 'remote/getchu_api.dart';

final getchuRepositoryProvider = Provider((ref) => GetchuRepository(GetchuApi(ref.read(han1meHttpClientProvider))));

class GetchuRepository {
  GetchuRepository(this._api);

  final GetchuApi _api;
  final _requests = <String, Future<GetchuPreview>>{};

  Future<GetchuPreview> previews(String month) => _requests[month] ??= _api.previews(month).whenComplete(() => _requests.remove(month));
}
