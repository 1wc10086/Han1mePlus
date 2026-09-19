import 'package:dio/dio.dart';

class GoogleTranslateApi {
  GoogleTranslateApi(this._dio);

  final Dio _dio;

  Future<String> translate(String text, String targetLanguage) async {
    final response = await _dio.get<List<dynamic>>(
      'https://translate.googleapis.com/translate_a/single',
      queryParameters: {'client': 'gtx', 'dt': 't', 'sl': 'auto', 'tl': targetLanguage, 'q': text},
      options: Options(responseType: ResponseType.json),
    );
    final segments = response.data?.firstOrNull;
    if (segments is! List) throw const FormatException('Invalid Google Translate response');
    final translation = segments.whereType<List>().map((segment) => segment.firstOrNull).whereType<String>().join();
    if (translation.isEmpty) throw const FormatException('Empty Google Translate response');
    return translation;
  }
}
