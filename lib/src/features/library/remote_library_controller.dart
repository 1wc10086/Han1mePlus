import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/han1me_repository.dart';
import '../../domain/models/library.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';
import '../../data/local/library_repository.dart';

final remoteLibraryProvider = FutureProvider.autoDispose<RemoteLibrary>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);
  final account = await ref.watch(accountProvider.future);
  if (account?.id == null) throw StateError('Not logged in');
  final settings = await ref.watch(settingsProvider.future);
  final library = await ref.watch(han1meRepositoryProvider).library(settings.resolvedBaseUrl, account!.id!);
  await ref.read(libraryProvider.notifier).cacheRemote(library);
  return library;
});
