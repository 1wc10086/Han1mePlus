import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../domain/models/comic.dart';
import 'han1me_api.dart';
import 'han1me_http_client.dart';

class ComicApi {
  ComicApi(this._http);
  final Han1meHttpClient _http;
  static const baseUrl = 'https://hanimeone.me';

  Future<ComicHome> home() async {
    final document = await _document('$baseUrl/comics');
    final sections = document.querySelectorAll('.comic-rows-wrapper');
    final trending = sections.where((section) => section.querySelector('h3')?.text.contains('發燒') == true).expand(_cards).toList();
    final latest = sections.where((section) => section.querySelector('h3')?.text.contains('最新') == true).expand(_cards).toList();
    return ComicHome(trending: trending, latest: latest);
  }

  Future<ComicSearchResult> browse(String path, int page) async {
    final uri = Uri.parse(_url(path)).replace(queryParameters: {'page': '$page'});
    final document = await _document(uri.toString());
    final numbers = document.querySelectorAll('.pagination .page-link').map((item) => int.tryParse(item.text.trim()) ?? 0).where((item) => item > 0).toList();
    final current = int.tryParse(document.querySelector('.pagination .active .page-link')?.text.trim() ?? '') ?? page;
    return ComicSearchResult(items: document.querySelectorAll('.comic-rows-wrapper').expand(_cards).toList(), page: current, totalPages: numbers.isEmpty ? current : numbers.reduce((a, b) => a > b ? a : b));
  }

  Future<ComicDetail> detail(String id) async {
    final documents = await Future.wait([_document('$baseUrl/comic/$id'), _document('$baseUrl/comic/$id/1')]);
    final detail = documents.first;
    final document = documents.last;
    final image = document.querySelector('#current-page-image');
    final nav = document.querySelector('.comic-show-content-nav');
    final count = int.tryParse(nav?.attributes['data-pages'] ?? '') ?? 1;
    final prefix = image?.attributes['data-prefix'] ?? '';
    final fallbackExtension = image?.attributes['data-extension'] ?? 'jpg';
    final extensions = _extensions(document, count, fallbackExtension);
    final tags = <ComicTag>[];
    for (final header in detail.querySelectorAll('.comics-metadata-margin-top h5')) {
      for (final link in header.querySelectorAll('a[href*="hanimeone.me/"]')) {
        final name = link.text.trim();
        final path = link.attributes['href'] ?? '';
        final type = _tagType(path);
        if (name.isNotEmpty && type != null) tags.add(ComicTag(type: type, name: name, path: path));
      }
    }
    final title = detail.querySelector('h3.title')?.text.trim() ?? document.querySelector('meta[property="og:title"]')?.attributes['content']?.replaceFirst(RegExp(r'^第\d+頁\s*-\s*'), '') ?? '';
    final labels = detail.querySelectorAll('.comics-metadata-margin-top h5').map((item) => item.text.trim()).toList();
    return ComicDetail(id: id, title: title, coverUrl: _absolute(detail.querySelector('.col-md-4 img')?.attributes['data-srcset'] ?? image?.attributes['src']), pageCount: count, tags: tags, imageUrls: List.generate(count, (index) => '$prefix${index + 1}.${extensions[index]}'), artist: tags.where((tag) => tag.type == '作者').map((tag) => tag.name).firstOrNull ?? RegExp(r'^\[([^\]]+)]').firstMatch(title)?.group(1), uploadTime: labels.where((label) => label.startsWith('上傳')).map((label) => label.replaceFirst(RegExp(r'^上傳：?'), '').trim()).firstOrNull, description: detail.querySelector('meta[name="description"]')?.attributes['content']);
  }

  Future<dom.Document> _document(String url) async {
    final response = await _http.get(url);
    if (Han1meApi.isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException(url);
    if ((response.statusCode ?? 500) >= 400) throw StateError('Request failed: HTTP ${response.statusCode}');
    return html_parser.parse(response.body);
  }

  Iterable<ComicCard> _cards(dom.Element section) sync* {
    for (final anchor in section.querySelectorAll('a[href*="/comic/"]')) {
      final match = RegExp(r'/comic/(\d+)').firstMatch(anchor.attributes['href'] ?? '');
      final image = anchor.querySelector('img');
      final title = anchor.querySelector('.comic-rows-videos-title')?.text.trim() ?? '';
      if (match != null && title.isNotEmpty) yield ComicCard(id: match.group(1)!, title: title, coverUrl: _absolute(image?.attributes['data-srcset'] ?? image?.attributes['data-src'] ?? image?.attributes['src']));
    }
  }

  List<String> _extensions(dom.Document document, int count, String fallback) {
    final script = document.querySelectorAll('script').map((script) => script.text).firstWhere((text) => text.contains('window.extensions'), orElse: () => '');
    final match = RegExp(r"extensions\.innerHTML\s*=\s*'([^']+)'").firstMatch(script);
    final values = match == null ? const <dynamic>[] : jsonDecode(match.group(1)!.replaceAll('&quot;', '"')) as List;
    return List.generate(count, (index) { final value = index < values.length ? '${values[index]}' : fallback; return value == 'w' ? 'webp' : value == 'j' ? 'jpg' : value; });
  }

  String _url(String path) => path.startsWith('http') ? path : '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  String _absolute(String? path) => path == null || path.isEmpty ? '' : Uri.parse(baseUrl).resolve(path).toString();
  String? _tagType(String path) {
    final segment = Uri.tryParse(path)?.pathSegments.firstOrNull;
    return switch (segment) {
      'artists' => '作者',
      'tags' => '標籤',
      'languages' => '語言',
      'categories' => '分類',
      'groups' => '社團',
      'characters' => '角色',
      'parodies' => '同人',
      _ => null,
    };
  }
}

