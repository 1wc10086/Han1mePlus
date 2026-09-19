import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchOptionCatalogProvider = FutureProvider<SearchOptionCatalog>((ref) => SearchOptionCatalog.load());

String searchOptionLocaleKey(Locale locale) {
  if (locale.languageCode == 'zh') {
    final traditional = locale.scriptCode == 'Hant' || const {'HK', 'MO', 'TW'}.contains(locale.countryCode);
    return traditional ? 'zh-rTW' : 'zh-rCN';
  }
  return locale.languageCode;
}

class SearchOption {
  const SearchOption({required this.labels, required this.searchKey});

  final Map<String, String> labels;
  final String? searchKey;

  factory SearchOption.fromJson(Map<String, dynamic> json) => SearchOption(
        labels: Map<String, String>.from((json['lang'] as Map?) ?? const {}),
        searchKey: json['search_key'] as String?,
      );

  String labelFor(String localeKey) => labels[localeKey] ?? labels['zh-rCN'] ?? searchKey ?? '';
}

class SearchOptionGroup {
  SearchOptionGroup(this.options, {Map<String, String> aliases = const {}})
      : _aliases = {
          for (final option in options)
            for (final alias in [option.searchKey, ...option.labels.values])
              if (alias != null && alias.isNotEmpty) alias: option,
        } {
    for (final alias in aliases.entries) {
      final option = _aliases[alias.value];
      if (option != null) _aliases[alias.key] = option;
    }
  }

  final List<SearchOption> options;
  final Map<String, SearchOption> _aliases;

  SearchOption? lookup(String value) => _aliases[value];

  String canonical(String value) => lookup(value)?.searchKey ?? value;

  String? localize(String value, String localeKey) => lookup(value)?.labelFor(localeKey);
}

class SearchOptionCatalog {
  const SearchOptionCatalog({
    required this.genres,
    required this.sorts,
    required this.durations,
    required this.releaseDates,
    required this.tags,
  });

  final SearchOptionGroup genres;
  final SearchOptionGroup sorts;
  final SearchOptionGroup durations;
  final SearchOptionGroup releaseDates;
  final Map<String, SearchOptionGroup> tags;

  SearchOption? lookupTag(String value) {
    for (final group in tags.values) {
      final option = group.lookup(value);
      if (option != null) return option;
    }
    return null;
  }

  String canonicalTag(String value) => lookupTag(value)?.searchKey ?? value;

  String? localizeTag(String value, String localeKey) => lookupTag(value)?.labelFor(localeKey);

  static Future<SearchOptionCatalog> load() async {
    Future<List<SearchOption>> loadList(String name) async {
      final json = jsonDecode(await rootBundle.loadString('assets/search_options/$name.json')) as List;
      return json.whereType<Map>().map((item) => SearchOption.fromJson(Map<String, dynamic>.from(item))).toList(growable: false);
    }

    final tagsJson = jsonDecode(await rootBundle.loadString('assets/search_options/tags.json')) as Map;
    return SearchOptionCatalog(
      genres: SearchOptionGroup(await loadList('genre'), aliases: const {'2D動画': '2D動畫'}),
      sorts: SearchOptionGroup(await loadList('sort_option')),
      durations: SearchOptionGroup(await loadList('duration')),
      releaseDates: SearchOptionGroup(await loadList('release_date')),
      tags: {
        for (final entry in tagsJson.entries)
          entry.key as String: SearchOptionGroup(
            (entry.value as List).whereType<Map>().map((item) => SearchOption.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
          ),
      },
    );
  }
}
