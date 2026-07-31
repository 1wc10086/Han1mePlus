import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/han1me_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import '../account/account_controller.dart';

final videoDetailProvider = FutureProvider.autoDispose.family<VideoDetail, String>((ref, id) async {
  ref.watch(accountProvider);
  final settings = await ref.watch(settingsProvider.future);
  return ref.watch(han1meRepositoryProvider).video(settings.resolvedBaseUrl, id);
});
