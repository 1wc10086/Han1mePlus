import 'dart:convert';

import 'package:flutter/services.dart';

class SearchOption {
  const SearchOption({required this.labels, required this.searchKey});

  final Map<String, String> labels;
  final String? searchKey;

  factory SearchOption.fromJson(Map<String, dynamic> json) => SearchOption(
        labels: Map<String, String>.from((json['lang'] as Map?) ?? const {}),
        searchKey: json['search_key'] as String?,
      );

  String labelFor(String locale) => labels[locale] ?? labels['zh-rCN'] ?? searchKey ?? '';
}

class SearchOptions {
  const SearchOptions({required this.genres, required this.sorts, required this.durations, required this.releaseDates, required this.tags});

  final List<SearchOption> genres;
  final List<SearchOption> sorts;
  final List<SearchOption> durations;
  final List<SearchOption> releaseDates;
  final Map<String, List<SearchOption>> tags;

  static Future<SearchOptions> load() async {
    Future<List<SearchOption>> list(String name) async {
      final json = jsonDecode(await rootBundle.loadString('assets/search_options/$name.json')) as List;
      return json.whereType<Map>().map((item) => SearchOption.fromJson(Map<String, dynamic>.from(item))).toList(growable: false);
    }

    final tagsJson = jsonDecode(await rootBundle.loadString('assets/search_options/tags.json')) as Map;
    final tags = <String, List<SearchOption>>{
      for (final entry in tagsJson.entries)
        entry.key: (entry.value as List).whereType<Map>().map((item) => SearchOption.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
    };
    return SearchOptions(
      genres: await list('genre'),
      sorts: await list('sort_option'),
      durations: await list('duration'),
      releaseDates: await list('release_date'),
      tags: tags,
    );
  }
}
