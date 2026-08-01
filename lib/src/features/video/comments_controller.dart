import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/han1me_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import '../account/account_controller.dart';
final commentsProvider = FutureProvider.autoDispose.family<CommentPage, String>((ref, id) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 10), link.close);
  ref.onDispose(timer.cancel);
  ref.watch(accountProvider);
  return ref.read(han1meRepositoryProvider).comments((await ref.watch(settingsProvider.future)).resolvedBaseUrl, id);
});
