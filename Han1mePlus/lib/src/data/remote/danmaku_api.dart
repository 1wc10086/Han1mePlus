import 'package:dio/dio.dart';

import '../../domain/models/danmaku.dart';

class DanmakuApi {
  DanmakuApi(this._dio);

  static const baseUrl = 'http://hhhhhh114514.imga.top/api';

  final Dio _dio;

  Future<List<Danmaku>> list(String videoId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/danmaku.php',
      queryParameters: {'video_id': videoId},
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Invalid danmaku response');
    return data.map((item) => Danmaku.fromJson(Map<String, dynamic>.from(item as Map))).toList(growable: false);
  }

  Future<void> submit(DanmakuSubmission submission) async {
    await _dio.post<void>(
      '$baseUrl/danmaku.php',
      data: submission.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );
  }
}
