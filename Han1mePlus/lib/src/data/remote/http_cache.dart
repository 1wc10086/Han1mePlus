import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpCacheInterceptor extends Interceptor {
  HttpCacheInterceptor() : _preferences = SharedPreferencesAsync();

  static const _prefix = 'http_cache_v1:';
  static const _maxMemoryEntries = 48;
  final SharedPreferencesAsync _preferences;
  final LinkedHashMap<String, _CachedResponse> _memory = LinkedHashMap();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final duration = options.extra['cacheDuration'] as Duration?;
    if (options.method != 'GET' || duration == null || options.extra['skipCache'] == true) return handler.next(options);
    final key = _key(options);
    final cached = _memory[key] ?? await _read(key);
    if (cached == null || cached.isExpired(duration)) return handler.next(options);
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
      unawaited(_preferences.setString('$_prefix${base64Url.encode(utf8.encode(key))}', jsonEncode(cached.toJson())));
    }
    handler.next(response);
  }

  Future<_CachedResponse?> _read(String key) async {
    final value = await _preferences.getString('$_prefix${base64Url.encode(utf8.encode(key))}');
    if (value == null) return null;
    try {
      return _CachedResponse.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
    } catch (_) {
      return null;
    }
  }

  void _put(String key, _CachedResponse value) {
    _memory.remove(key);
    _memory[key] = value;
    if (_memory.length > _maxMemoryEntries) _memory.remove(_memory.keys.first);
  }

  String _key(RequestOptions options) => '${options.uri}|${options.headers['Cookie'] ?? ''}';
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
