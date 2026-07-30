import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/han1me_repository.dart';
import '../../data/local/home_cache.dart';
import '../../domain/models/video.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';

final homeCacheProvider = Provider((_) => HomeCache());
final homeSectionsProvider = AsyncNotifierProvider<HomeSectionsController, HomeFeed>(HomeSectionsController.new);

class HomeSectionsController extends AsyncNotifier<HomeFeed> {
  @override
  Future<HomeFeed> build() async {
    ref.listen(accountProvider, (previous, next) {
      if (previous?.valueOrNull?.id != next.valueOrNull?.id) ref.invalidateSelf();
    });
    final account = await ref.watch(accountProvider.future);
    final settings = await ref.read(settingsProvider.future);
    final cached = await ref.read(homeCacheProvider).read(settings.baseUrl, account?.id);
    if (cached != null) {
      unawaited(refresh());
      return cached;
    }
    return refresh();
  }

  Future<HomeFeed> refresh() async {
    final account = await ref.read(accountProvider.future);
    final settings = await ref.read(settingsProvider.future);
    final feed = await ref.read(han1meRepositoryProvider).home(settings.baseUrl);
    await ref.read(homeCacheProvider).write(settings.baseUrl, account?.id, feed);
    state = AsyncData(feed);
    return feed;
  }
}
