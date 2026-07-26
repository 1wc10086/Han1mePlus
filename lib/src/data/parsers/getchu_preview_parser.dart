import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../domain/models/getchu_preview.dart';

class GetchuPreviewParser {
  const GetchuPreviewParser();

  static const _baseUrl = 'https://www.getchu.com/';

  GetchuPreview parse(String body, String month) {
    final document = html_parser.parse(
      body,
      generateSpans: false,
      sourceUrl: _baseUrl,
    );
    final groups = document
        .querySelectorAll('div.category_anime_t2')
        .map(_group)
        .whereType<GetchuPreviewGroup>()
        .toList(growable: false);
    return GetchuPreview(month: month, groups: groups);
  }

  GetchuPreviewGroup? _group(Element header) {
    final container = _nextCategoryBody(header);
    if (container == null) return null;
    final items = <String, GetchuPreviewItem>{};
    for (final product in container.querySelectorAll('div.div_product')) {
      final item = _item(product);
      if (item != null) items[item.id] = item;
    }
    if (items.isEmpty) return null;
    return GetchuPreviewGroup(
      releaseDate: _text(header).replaceFirst('発売タイトル', '').trim(),
      items: items.values.toList(growable: false),
    );
  }

  Element? _nextCategoryBody(Element header) {
    var element = header.parent?.nextElementSibling;
    while (element != null && !element.classes.contains('category_anime_b')) {
      element = element.nextElementSibling;
    }
    return element;
  }

  GetchuPreviewItem? _item(Element product) {
    final links = product.querySelectorAll(
      'a[href*="/soft.phtml"], a[href*="/item/"]',
    );
    final link = links.where((element) => _text(element).isNotEmpty).firstOrNull ??
        links.firstOrNull;
    final href = link?.attributes['href']?.trim();
    if (link == null || href == null || href.isEmpty) return null;
    final id = RegExp(r'(?:[?&]id=|/item/)(\d+)').firstMatch(href)?.group(1);
    if (id == null) return null;
    final titleAndBrand = _text(link);
    final brand = RegExp(r'\(([^()]*)\)\s*$').firstMatch(titleAndBrand)?.group(1)?.trim().nonBlank;
    final image = product.querySelector('img[src*="package"]');
    final coverPath = image?.attributes['src']?.trim();
    final imageTitle = image?.attributes['alt']?.clean;
    return GetchuPreviewItem(
      id: id,
      title: titleAndBrand
          .replaceFirst(RegExp(r'\s*\([^()]+\)\s*$'), '')
          .trim()
          .ifBlank(imageTitle?.nonBlank ?? 'Getchu #$id'),
      detailUrl: Uri.parse(
        '${_baseUrl}item/$id/',
      ).replace(queryParameters: {'gc': 'gc'}).toString(),
      brand: brand,
      coverUrl: coverPath == null || coverPath.isEmpty
          ? null
          : Uri.parse(
              _baseUrl,
            ).resolve(coverPath).toString().replaceFirst('package_s.', 'package.'),
      price: _text(product.querySelector('span.redb')).nonBlank,
    );
  }

  String _text(Element? element) => element?.text.clean ?? '';
}

extension on String {
  String get clean =>
      replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  String ifBlank(String fallback) => isEmpty ? fallback : this;
  String? get nonBlank => isEmpty ? null : this;
}
