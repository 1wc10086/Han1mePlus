import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'remote/keyframe_api.dart';

class SharedKeyframeRepository {
  SharedKeyframeRepository(this._api);

  final SharedKeyframeApi _api;

  factory SharedKeyframeRepository.create() => SharedKeyframeRepository(
        SharedKeyframeApi(
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          ),
        ),
      );

  Future<SharedKeyframeVideo?> get(String videoId) => _api.get(videoId);

  Future<void> upload(SharedKeyframeVideo video) async => _api.upload(video, await _installationId());

  Future<String> _installationId() async {
    final preferences = await SharedPreferences.getInstance();
    const key = 'keyframe_installation_id';
    final value = preferences.getString(key) ?? const Uuid().v4();
    if (!preferences.containsKey(key)) await preferences.setString(key, value);
    return value;
  }
}
