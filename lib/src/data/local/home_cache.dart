import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/video.dart';
import '../../domain/models/comic.dart';

class HomeCache {
  static const _prefix = 'home_feed_v2:';
  final _preferences = SharedPreferencesAsync();

  Future<HomeFeed?> read(String baseUrl) async {
    final value = await _preferences.getString('$_prefix$baseUrl');
    if (value == null) return null;
    try {
      return HomeFeed.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String baseUrl, HomeFeed feed) => _preferences.setString('$_prefix$baseUrl', jsonEncode(feed.toJson()));

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
