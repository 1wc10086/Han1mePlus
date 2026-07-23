import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/danmaku.dart';
import 'remote/danmaku_api.dart';

final danmakuRepositoryProvider = Provider((ref) => DanmakuRepository(DanmakuApi(Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10))))));

class DanmakuRepository {
  DanmakuRepository(this._api);

  final DanmakuApi _api;

  Future<List<Danmaku>> list(String videoId) => _api.list(videoId);

  Future<void> submit({required String videoId, required int positionMs, required String content, String? accountId, String? accountName}) async {
    final preferences = await SharedPreferences.getInstance();
    const key = 'danmaku_installation_id';
    final installationId = preferences.getString(key) ?? const Uuid().v4();
    if (!preferences.containsKey(key)) await preferences.setString(key, installationId);
    await _api.submit(DanmakuSubmission(videoId: videoId, positionMs: positionMs, content: content, installationId: installationId, accountId: accountId, accountName: accountName));
  }
}
