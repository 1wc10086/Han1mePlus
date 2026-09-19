import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/getchu_repository.dart';
import '../../domain/models/getchu_preview.dart';

final getchuPreviewsProvider = FutureProvider.autoDispose.family<GetchuPreviewFeed, String>((ref, month) {
  return ref.watch(getchuRepositoryProvider).previews(month);
});

final getchuPreviewDetailProvider = FutureProvider.autoDispose.family<GetchuPreviewDetail, String>((ref, id) {
  return ref.watch(getchuRepositoryProvider).detail(id);
});
