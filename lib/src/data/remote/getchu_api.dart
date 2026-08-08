import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../domain/models/getchu_preview.dart';
import 'han1me_http_client.dart';

class GetchuApi {
  GetchuApi(this._http);

  static const _baseUrl = 'https://www.getchu.com/';
  static const _headers = {'Cookie': 'getchu_adalt_flag=getchu.com; gc=gc', 'Referer': _baseUrl};
  final Han1meHttpClient _http;

  Future<GetchuPreviewFeed> previews(String month) async {
    final uri = Uri.parse('${_baseUrl}all/month_title.html').replace(queryParameters: {
      'genre': 'anime_dvd',
      'gage': 'adult',
      'year': month.substring(0, 4),
      'month': month.substring(4, 6),
      'gc': 'gc',
    });
    final page = await _page(uri.toString());
    final groups = <GetchuPreviewGroup>[];
    for (final header in page.document.querySelectorAll('div.category_anime_t2')) {
      final container = _nextCategoryBody(header);
      if (container == null) continue;
      final items = container.querySelectorAll('div.div_product').map(_previewItem).whereType<GetchuPreviewItem>();
      final uniqueItems = {for (final item in items) item.id: item}.values.toList(growable: false);
      if (uniqueItems.isNotEmpty) groups.add(GetchuPreviewGroup(releaseDate: _clean(header.text.replaceAll('発売タイトル', '')), items: uniqueItems));
    }
    return GetchuPreviewFeed(month: month, groups: groups);
  }

  Future<GetchuPreviewDetail> detail(String id) async {
    final page = await _page('${_baseUrl}item/$id/?gc=gc');
    final document = page.document;
    final body = page.body.replaceAll(r'\/', '/');
    final jsonLd = _productJsonLd(document, body);
    final specifications = _specifications(document, body);
    String? specification(String key) => specifications.entries.where((entry) => entry.key.contains(key)).firstOrNull?.value;
    final title = _clean(
      _jsonString(jsonLd, 'name') ??
          document.querySelector('#soft-title')?.text ??
          document.querySelector('meta[property="og:title"]')?.attributes['content'] ??
          document.querySelector('title')?.text.split(' | ').first ??
          '',
    );
    final jsonImages = _jsonImages(jsonLd);
    final cover = _absolute(
      jsonImages.firstOrNull ??
          document.querySelector('meta[property="og:image"]')?.attributes['content'] ??
          _metaContent(body, 'og:image') ??
          _metaContent(body, 'twitter:image:src') ??
          document.querySelector('#soft_table img[src*="package"]')?.attributes['src'] ??
          RegExp('href=["\']([^"\']*?/brandnew/$id/[^"\']*?package\\.jpg)["\']', caseSensitive: false).firstMatch(body)?.group(1),
    );
    final sections = _sections(document, body);
    final description = sections
        .where((section) => section.title.contains('商品紹介') || section.title.contains('ストーリー'))
        .map((section) => section.body)
        .join('\n\n');
    final samples = {
      ...document.querySelectorAll('div.item-Samplecard a[href]').map((element) => _absolute(element.attributes['href'])).whereType<String>(),
      ...RegExp('["\']([^"\']*?/brandnew/$id/c${id}sample\\d+\\.jpg)["\']', caseSensitive: false).allMatches(body).map((match) => _absolute(match.group(1))).whereType<String>(),
      ...jsonImages.skip(1).map(_absolute).whereType<String>(),
    }.map(_withGc).toList(growable: false);
    final videoUrls = _videoUrls(document, body);
    final inlineSeries = document.querySelectorAll('div.item-series-content, div[class*="item-series"], section.related-products li.product-item').map(_relatedItem).whereType<GetchuPreviewItem>();
    final parentId = RegExp('["\']parent_id_array["\']\\s*:\\s*["\']([^"\']+)["\']', caseSensitive: false).firstMatch(body)?.group(1);
    final ajaxSeries = parentId == null ? const <GetchuPreviewItem>[] : await _seriesItems(parentId);
    final seriesItems = {for (final item in [...inlineSeries, ...ajaxSeries]) if (item.id != id) item.id: item}.values.toList(growable: false);
    final offer = jsonLd?['offers'];
    final jsonPrice = offer is Map ? offer['price']?.toString() : null;
    final releaseDate = RegExp(r'''["']?_crelease_date["']?\s*:\s*["']?(\d{4}-\d{2}-\d{2})''').firstMatch(body)?.group(1) ??
        document.querySelector('a[href*="start_date"]')?.text.trim() ??
        specification('発売日') ??
        RegExp(r'start_date=(\d{4}(?:/|%2F)\d{2}(?:/|%2F)\d{2})', caseSensitive: false).firstMatch(body)?.group(1)?.replaceAll(RegExp('%2F', caseSensitive: false), '/');
    return GetchuPreviewDetail(
      id: id,
      title: title,
      brand: _nullable(_clean(_jsonBrand(jsonLd) ?? document.querySelector('#brandsite')?.text ?? specification('ブランド') ?? '')),
      coverUrl: cover == null ? null : _withGc(cover),
      description: _nullable(description) ?? _nullable(_clean(_jsonString(jsonLd, 'description') ?? document.querySelector('meta[name="description"]')?.attributes['content'] ?? '')),
      releaseDate: releaseDate,
      price: _nullable(jsonPrice == null ? _clean(document.querySelector('span.redb2')?.text ?? specification('価格') ?? '') : '¥$jsonPrice'),
      productUrl: _absolute(offer is Map && offer['url'] is String ? offer['url'] as String : null) ?? '${_baseUrl}item/$id/?gc=gc',
      videoUrls: videoUrls,
      sections: sections,
      sampleImages: samples,
      seriesItems: seriesItems,
    );
  }

  Future<List<GetchuPreviewItem>> _seriesItems(String parentId) async {
    try {
      final response = await _http.post(
        '${_baseUrl}util/GetchuSearch/GetchuSearchAjax.php',
        {
          'product_id_array': '',
          'parent_id_array': parentId,
          'genre': 'anime_dvd',
          'sub_genre_array': '',
          'NA_sub_genre_array': '',
          'sub_genre_perfect_matching': '',
          'brand_id_array': '',
          'age': '',
          'stock_flag': '',
          'sort_condition': 'release_date',
          'sort_order': 'asc',
          'limit_count': '30',
          'limit_count_lower': '1',
          'image_exist': '',
          'start_date': '',
          'end_date': '',
          'novelty_flag': '',
          'template_html': 'item-series/item-series.html',
          'paging': '',
          'page_size': '',
          'javascript_id': '',
          'search_word': '',
          'limitless': '1',
          'lower_limit': '',
          'upper_limit': '',
          'image_size': 's',
          'add_query': '',
        },
        headers: _headers,
        responseCharset: 'EUC-JP',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return const [];
      final document = html_parser.parse(response.body, sourceUrl: _baseUrl);
      return document.querySelectorAll('div.item-series-content, div[class*="item-series"], li.product-item').map(_relatedItem).whereType<GetchuPreviewItem>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<_GetchuPage> _page(String url) async {
    final response = await _http.get(url, responseCharset: 'EUC-JP', headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('Getchu request failed: HTTP ${response.statusCode}');
    return _GetchuPage(response.body, html_parser.parse(response.body, sourceUrl: url));
  }

  Map<String, dynamic>? _productJsonLd(dom.Document document, String body) {
    final values = <String>[];
    values.addAll(document.querySelectorAll('script[type*="ld+json"]').map((element) => element.text.trim()).where((value) => value.isNotEmpty));
    values.addAll(RegExp(r'''<script[^>]*type=["'][^"']*ld\+json[^"']*["'][^>]*>([\s\S]*?)</script>''', caseSensitive: false).allMatches(body).map((match) => match.group(1)!.trim()));
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        final candidates = decoded is Map && decoded['@graph'] is List ? decoded['@graph'] as List : [decoded];
        for (final candidate in candidates.whereType<Map>()) {
          if (candidate['@type'] == 'Product') return Map<String, dynamic>.from(candidate);
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, String> _specifications(dom.Document document, String body) {
    final result = <String, String>{};
    for (final row in document.querySelectorAll('#soft_table tr')) {
      final cells = row.children.where((element) => element.localName == 'td' || element.localName == 'th').toList();
      if (cells.length >= 2) result[_clean(cells[0].text).replaceAll(RegExp(r'[：:\s]+'), '')] = _clean(cells[1].text);
    }
    for (final entry in {'ブランド': 'ブランド', '定価': '定価', '発売日': '発売日'}.entries) {
      final match = RegExp('<td[^>]*>\\s*${entry.value}[:：]?\\s*</td>\\s*<td[^>]*>([\\s\\S]*?)</td>', caseSensitive: false).firstMatch(body);
      if (match != null) result.putIfAbsent(entry.key, () => _htmlText(match.group(1)!));
    }
    return result;
  }

  List<GetchuPreviewSection> _sections(dom.Document document, String body) {
    final sections = <GetchuPreviewSection>[];
    for (final entry in const {'tabletitle_1': '商品紹介', 'tabletitle_2': 'ストーリー', 'tabletitle_3': 'スタッフ'}.entries) {
      for (final heading in document.querySelectorAll('h3.${entry.key}')) {
        final content = _nextTableBody(heading);
        if (content == null || content.querySelector('video, source') != null) continue;
        final text = _clean(content.text);
        if (text.isNotEmpty) sections.add(GetchuPreviewSection(title: entry.value, body: text));
      }
    }
    for (final entry in const {'tabletitle_1': '商品紹介', 'tabletitle_2': 'ストーリー', 'tabletitle_3': 'スタッフ'}.entries) {
      final matches = RegExp(
        '<h3[^>]*class=["\'][^"\']*${entry.key}[^"\']*["\'][^>]*>[\\s\\S]*?</h3>\\s*<div[^>]*class=["\'][^"\']*tablebody[^"\']*["\'][^>]*>([\\s\\S]*?)</div>',
        caseSensitive: false,
      ).allMatches(body);
      for (final match in matches) {
        final content = match.group(1)!;
        if (RegExp(r'<(?:video|source)\b', caseSensitive: false).hasMatch(content)) continue;
        final text = _htmlText(content);
        if (text.isNotEmpty) sections.add(GetchuPreviewSection(title: entry.value, body: text));
      }
    }
    final result = <GetchuPreviewSection>[];
    for (final title in const ['商品紹介', 'ストーリー', 'スタッフ']) {
      final candidates = sections.where((section) => section.title == title).toList();
      if (candidates.isEmpty) continue;
      candidates.sort((left, right) => right.body.length.compareTo(left.body.length));
      result.add(candidates.first);
    }
    result.sort((left, right) => _sectionOrder(left.title).compareTo(_sectionOrder(right.title)));
    return result;
  }

  List<String> _videoUrls(dom.Document document, String body) {
    final urls = <String>{};
    for (final element in document.querySelectorAll('video[src], video source[src], source[src]')) {
      final url = _absolute(element.attributes['src']);
      if (url != null && _isVideoUrl(url)) urls.add(url);
    }
    final videoBlocks = RegExp(r'''<video\b[^>]*>[\s\S]*?</video>|<video\b[^>]*/?>''', caseSensitive: false).allMatches(body);
    for (final block in videoBlocks) {
      for (final source in RegExp(r'''(?:src|data-src)\s*=\s*["']([^"']+)["']''', caseSensitive: false).allMatches(block.group(0)!)) {
        final url = _absolute(source.group(1)?.replaceAll('&amp;', '&'));
        if (url != null && _isVideoUrl(url)) urls.add(url);
      }
    }
    for (final match in RegExp(r'''(?:https?:)?//[^"'<>\s\\]+?\.mp4(?:\?[^"'<>\s\\]*)?''', caseSensitive: false).allMatches(body.replaceAll(r'\/', '/'))) {
      final url = _absolute(match.group(0)?.replaceAll('&amp;', '&'));
      if (url != null) urls.add(url);
    }
    return urls.toList(growable: false);
  }

  GetchuPreviewItem? _previewItem(dom.Element product) {
    final link = product.querySelector('td.dd > a[href*="/soft.phtml"], td.dd > a[href*="/item/"], a[href*="/soft.phtml"], a[href*="/item/"]');
    if (link == null) return null;
    final id = _getId(link.attributes['href']);
    if (id == null) return null;
    final titleAndBrand = _clean(link.text);
    final brandMatch = RegExp(r'\(([^()]*)\)\s*$').firstMatch(titleAndBrand);
    final image = product.querySelector('img[src*="package"]');
    final title = titleAndBrand.replaceFirst(RegExp(r'\s*\([^()]+\)\s*$'), '').trim();
    final cover = _absolute(image?.attributes['src']?.replaceFirst('package_s.', 'package.'));
    return GetchuPreviewItem(id: id, title: title.isEmpty ? _clean(image?.attributes['alt'] ?? '') : title, brand: _nullable(brandMatch?.group(1)), coverUrl: cover == null ? null : _withGc(cover), detailUrl: '${_baseUrl}item/$id/', price: _nullable(_clean(product.querySelector('span.redb')?.text ?? '')));
  }

  GetchuPreviewItem? _relatedItem(dom.Element element) {
    final link = element.querySelector('a[href]');
    final id = _getId(link?.attributes['href']);
    if (link == null || id == null) return null;
    final image = element.querySelector('img');
    final title = _clean(image?.attributes['alt']?.replaceAll('パッケージ画像', '') ?? link.text);
    final cover = _absolute(image?.attributes['src']);
    return GetchuPreviewItem(
      id: id,
      title: title,
      brand: _nullable(_clean(element.querySelector('.table-003-brand')?.text.replaceAll(RegExp(r'^\(|\)$'), '') ?? element.querySelector('.table-003-releasedate')?.text ?? '')),
      coverUrl: cover == null ? null : _withGc(cover),
      detailUrl: '${_baseUrl}item/$id/',
      price: _nullable(_clean(element.querySelector('span.redb, span.gr_soft_carousel_price_num')?.text ?? '')),
    );
  }

  dom.Element? _nextCategoryBody(dom.Element header) {
    var element = header.parent?.nextElementSibling;
    while (element != null && !element.classes.contains('category_anime_b')) {
      element = element.nextElementSibling;
    }
    return element;
  }

  dom.Element? _nextTableBody(dom.Element heading) {
    var element = heading.nextElementSibling;
    while (element != null && element.localName != 'h3') {
      if (element.classes.contains('tablebody')) return element;
      element = element.nextElementSibling;
    }
    element = heading.parent?.children.skipWhile((child) => child != heading).skip(1).firstOrNull;
    while (element != null && element.localName != 'h3') {
      if (element.classes.contains('tablebody')) return element;
      element = element.nextElementSibling;
    }
    return null;
  }

  int _sectionOrder(String value) => value.contains('商品紹介') ? 0 : value.contains('ストーリー') ? 1 : 2;
  bool _isVideoUrl(String value) => RegExp(r'\.(?:mp4|m3u8)(?:$|\?)', caseSensitive: false).hasMatch(value);
  String _htmlText(String value) => _clean(html_parser.parseFragment(value.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')).text ?? '');
  String _clean(String value) => value.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'[ \t\r\f\v]+'), ' ').replaceAll(RegExp(r' *\n *'), '\n').trim();
  String? _nullable(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
  String? _absolute(String? value) => switch (value?.trim()) {
        null || '' => null,
        final url when url.startsWith('//') => 'https:$url',
        final url when url.startsWith('http') => url,
        final url => Uri.parse(_baseUrl).resolve(url).toString(),
      };
  String _withGc(String url) => !url.startsWith(_baseUrl) || url.contains('gc=gc') ? url : '$url${url.contains('?') ? '&' : '?'}gc=gc';
  String? _getId(String? value) => RegExp(r'(?:id=|/item/)(\d+)').firstMatch(value ?? '')?.group(1);
  String? _metaContent(String body, String name) => RegExp('<meta[^>]*(?:property|name)=["\']${RegExp.escape(name)}["\'][^>]*content=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(body)?.group(1) ?? RegExp('<meta[^>]*content=["\']([^"\']+)["\'][^>]*(?:property|name)=["\']${RegExp.escape(name)}["\']', caseSensitive: false).firstMatch(body)?.group(1);
  String? _jsonString(Map<String, dynamic>? json, String key) => json?[key] is String ? json![key] as String : null;
  String? _jsonBrand(Map<String, dynamic>? json) => json?['brand'] is Map && (json!['brand'] as Map)['name'] is String ? (json['brand'] as Map)['name'] as String : null;
  List<String> _jsonImages(Map<String, dynamic>? json) => switch (json?['image']) { final String image => [image], final List images => images.whereType<String>().toList(), _ => const [] };
}

class _GetchuPage {
  const _GetchuPage(this.body, this.document);

  final String body;
  final dom.Document document;
}
