import 'package:dio/dio.dart';

class SharedKeyframeApi {
  SharedKeyframeApi(this._dio);

  static const baseUrl = 'http://hhhhhh114514.imga.top/api';

  final Dio _dio;

  Future<SharedKeyframeVideo?> get(String videoId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/keyframes.php',
      queryParameters: {'video_id': videoId},
    );
    final data = response.data?['data'];
    return data is Map ? SharedKeyframeVideo.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  Future<void> upload(SharedKeyframeVideo video, String installationId) => _dio.post<void>(
        '$baseUrl/keyframes.php',
        data: {
          'video_id': video.id,
          'title': video.title,
          'keyframes': video.positions,
          'installation_id': installationId,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
}

class SharedKeyframeVideo {
  const SharedKeyframeVideo({required this.id, required this.title, required this.positions});

  factory SharedKeyframeVideo.fromJson(Map<String, dynamic> json) => SharedKeyframeVideo(
        id: json['video_id'] as String,
        title: json['title'] as String? ?? json['video_id'] as String,
        positions: (json['keyframes'] as List? ?? const []).whereType<num>().map((value) => value.toInt()).toList()..sort(),
      );

  final String id;
  final String title;
  final List<int> positions;
}
