import 'package:flutter/services.dart';

class NativeHttpResponse {
  const NativeHttpResponse({required this.statusCode, required this.body, required this.headers});

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
}

class NativeHttpClient {
  static const _channel = MethodChannel('com.liar.han1meplus/http');

  Future<void> saveCookies(String cookies) => _channel.invokeMethod<void>('saveCookies', {'cookies': cookies});

  Future<void> clearCookies() => _channel.invokeMethod<void>('clearCookies');

  Future<NativeHttpResponse> get(String url) => request(url);

  Future<NativeHttpResponse> post(String url, Map<String, String> data) => request(url, method: 'POST', data: data);

  Future<NativeHttpResponse> request(String url, {String method = 'GET', Map<String, String>? data}) async {
    final response = await _channel.invokeMethod<dynamic>('request', {'url': url, 'method': method, if (data != null) 'data': data});
    final result = Map<Object?, Object?>.from(response as Map);
    return NativeHttpResponse(
      statusCode: result['statusCode']! as int,
      body: result['body']! as String,
      headers: Map<String, List<String>>.fromEntries(
        Map<Object?, Object?>.from(result['headers']! as Map).entries.map(
          (entry) => MapEntry(entry.key! as String, List<String>.from(entry.value! as List)),
        ),
      ),
    );
  }
}
