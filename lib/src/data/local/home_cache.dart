import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/video.dart';
import '../../domain/models/comic.dart';

class HomeCache {
  static const _prefix = 'home_feed_v2:';
  final _preferences = SharedPreferencesAsync();

  Future<HomeFeed?> read(String baseUrl, String? accountId) async {
    final value = await _preferences.getString(_key(baseUrl, accountId));
    if (value == null) return null;
    try {
      return HomeFeed.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String baseUrl, String? accountId, HomeFeed feed) => _preferences.setString(_key(baseUrl, accountId), jsonEncode(feed.toJson()));

  String _key(String baseUrl, String? accountId) => '$_prefix$baseUrl:${accountId ?? 'anonymous'}';

  Future<ComicHome?> readComics() async {
    final value = await _preferences.getString('${_prefix}comics');
    if (value == null) return null;
    try {
      return ComicHome.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> writeComics(ComicHome feed) => _preferences.setString('${_prefix}comics', jsonEncode(feed.toJson()));
}
