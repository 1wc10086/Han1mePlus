import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/video.dart';
import '../domain/models/video_translation.dart';
import 'remote/google_translate_api.dart';

final videoTranslationRepositoryProvider = Provider((ref) => VideoTranslationRepository(GoogleTranslateApi(Dio())));

class VideoTranslationRepository {
  const VideoTranslationRepository(this._api);

  final GoogleTranslateApi _api;

  Future<VideoTranslation> translate(VideoDetail video, String targetLanguage) async {
    final values = await Future.wait([
      _api.translate(video.title, targetLanguage),
      if (_hasText(video.captionTitle)) _api.translate(video.captionTitle!, targetLanguage),
      if (_hasText(video.description)) _api.translate(video.description!, targetLanguage),
    ]);
    var index = 1;
    return VideoTranslation(
      title: values.first,
      captionTitle: _hasText(video.captionTitle) ? values[index++] : null,
      description: _hasText(video.description) ? values[index] : null,
    );
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty == true;
}
