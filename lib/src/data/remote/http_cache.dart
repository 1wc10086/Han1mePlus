import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpCacheInterceptor extends Interceptor {
  HttpCacheInterceptor() : _preferences = SharedPreferencesAsync();

  static const _prefix = 'http_cache_v1:';
  static const _maxMemoryEntries = 48;
  static const _maxPersistedEntries = 96;
  final SharedPreferencesAsync _preferences;
  final LinkedHashMap<String, _CachedResponse> _memory = LinkedHashMap();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final duration = options.extra['cacheDuration'] as Duration?;
    if (options.method != 'GET' || duration == null || options.extra['skipCache'] == true) return handler.next(options);
    final key = _key(options);
    final cached = _memory[key] ?? await _read(key);
    if (cached == null) return handler.next(options);
    if (cached.isExpired(duration)) {
      _memory.remove(key);
      unawaited(_preferences.remove(_storageKey(key)));
      return handler.next(options);
    }
    _put(key, cached);
    return handler.resolve(Response<String>(
      requestOptions: options,
      data: cached.body,
      statusCode: cached.statusCode,
    ));
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    final duration = response.requestOptions.extra['cacheDuration'] as Duration?;
    if (response.requestOptions.method == 'GET' && duration != null && response.statusCode != null && response.statusCode! < 400 && response.data is String) {
      final cached = _CachedResponse(DateTime.now().millisecondsSinceEpoch, response.statusCode!, response.data as String);
      final key = _key(response.requestOptions);
      _put(key, cached);
      unawaited(_persist(key, cached));
    }
    handler.next(response);
  }

  Future<_CachedResponse?> _read(String key) async {
    final storageKey = _storageKey(key);
    final value = await _preferences.getString(storageKey);
    if (value == null) return null;
    try {
      return _CachedResponse.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      unawaited(_preferences.remove(storageKey));
      return null;
    }
  }

  Future<void> _persist(String key, _CachedResponse value) async {
    await _preferences.setString(_storageKey(key), jsonEncode(value.toJson()));
    final keys = (await _preferences.getKeys()).where((item) => item.startsWith(_prefix)).toList();
    if (keys.length <= _maxPersistedEntries) return;
    final entries = <(String, int)>[];
    for (final storageKey in keys) {
      final saved = await _preferences.getString(storageKey);
      try {
        final json = Map<String, dynamic>.from(jsonDecode(saved!) as Map);
        entries.add((storageKey, json['createdAt'] as int));
      } catch (_) {
        await _preferences.remove(storageKey);
      }
    }
    entries.sort((a, b) => a.$2.compareTo(b.$2));
    final overflow = entries.length - _maxPersistedEntries;
    if (overflow <= 0) return;
    for (final entry in entries.take(overflow)) {
      await _preferences.remove(entry.$1);
    }
  }

  void _put(String key, _CachedResponse value) {
    _memory.remove(key);
    _memory[key] = value;
    if (_memory.length > _maxMemoryEntries) _memory.remove(_memory.keys.first);
  }

  String _key(RequestOptions options) => '${options.uri}|${options.headers['Cookie'] ?? ''}';
  String _storageKey(String key) => '$_prefix${base64Url.encode(utf8.encode(key))}';
}

class _CachedResponse {
  const _CachedResponse(this.createdAt, this.statusCode, this.body);
  final int createdAt;
  final int statusCode;
  final String body;

  bool isExpired(Duration duration) => DateTime.now().millisecondsSinceEpoch - createdAt > duration.inMilliseconds;
  Map<String, Object> toJson() => {'createdAt': createdAt, 'statusCode': statusCode, 'body': body};
  factory _CachedResponse.fromJson(Map<String, dynamic> json) => _CachedResponse(json['createdAt'] as int, json['statusCode'] as int, json['body'] as String);
}
