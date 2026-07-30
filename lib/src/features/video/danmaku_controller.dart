import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/danmaku_repository.dart';
import '../../domain/models/danmaku.dart';

final danmakuProvider = FutureProvider.autoDispose.family<List<Danmaku>, String>((ref, videoId) => ref.watch(danmakuRepositoryProvider).list(videoId));
final playbackPositionProvider = StateProvider.family<int, String>((ref, videoId) => 0);
final danmakuVisibilityProvider = StateProvider.autoDispose.family<bool, String>((ref, videoId) => true);
