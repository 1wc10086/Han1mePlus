import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/getchu_preview.dart';
import 'han1me_repository.dart';
import 'remote/getchu_api.dart';

final getchuRepositoryProvider = Provider((ref) => GetchuRepository(GetchuApi(ref.read(han1meHttpClientProvider))));

class GetchuRepository {
  GetchuRepository(this._api);

  final GetchuApi _api;

  Future<GetchuPreviewFeed> previews(String month) => _api.previews(month);
  Future<GetchuPreviewDetail> detail(String id) => _api.detail(id);
}
