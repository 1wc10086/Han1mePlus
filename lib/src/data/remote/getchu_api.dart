import '../../domain/models/getchu_preview.dart';
import '../parsers/getchu_preview_parser.dart';
import 'han1me_http_client.dart';

class GetchuApi {
  GetchuApi(
    this._http, {
    GetchuPreviewParser parser = const GetchuPreviewParser(),
  }) : _parser = parser;

  static const _baseUrl = 'https://www.getchu.com/';
  static const imageHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
    'Referer': _baseUrl,
    'Cookie': 'getchu_adalt_flag=getchu.com; gc=gc',
  };
  final Han1meHttpClient _http;
  final GetchuPreviewParser _parser;

  Future<GetchuPreview> previews(String month) async {
    final match = RegExp(r'^(\d{4})(\d{2})$').firstMatch(month);
    if (match == null) throw ArgumentError.value(month, 'month');
    final uri = Uri.parse('${_baseUrl}all/month_title.html').replace(
      queryParameters: {
        'genre': 'anime_dvd',
        'gage': 'adult',
        'year': match.group(1)!,
        'month': match.group(2)!,
        'gc': 'gc',
      },
    );
    final response = await _http
        .getGetchu(
          uri.toString(),
          headers: {
            ...imageHeaders,
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'ja,en-US;q=0.9,en;q=0.8',
            'Cache-Control': 'no-cache',
          },
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode >= 400) {
      throw StateError('Request failed: HTTP ${response.statusCode}');
    }
    return _parser.parse(response.body, month);
  }
}
