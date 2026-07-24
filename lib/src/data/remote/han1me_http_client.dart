import 'package:flutter/services.dart';

class Han1meHttpResponse {
  const Han1meHttpResponse({required this.statusCode, required this.body, required this.headers});

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
}

class Han1meHttpClient {
  static const _channel = MethodChannel('com.liar.han1meplus/http');

  static const userAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36';

  Future<void> saveCookies(String cookies, {String? url}) => _channel.invokeMethod<void>('saveCookies', {'cookies': cookies, if (url != null) 'url': url});

  Future<void> clearCookies({String? url}) => _channel.invokeMethod<void>('clearCookies', {if (url != null) 'url': url});

  Future<String> webViewCookies(String url) async => await _channel.invokeMethod<String>('webViewCookies', {'url': url}) ?? '';

  Future<void> clearWebViewCookies() => _channel.invokeMethod<void>('clearWebViewCookies');

  Future<void> setNetworkSettings({required bool useBuiltInHosts, required bool useDoh, required String dohPreset, required String dohCustomUrl, required String dohBootstrapIps, required int dohTimeoutSeconds}) => _channel.invokeMethod<void>('setNetworkSettings', {'useBuiltInHosts': useBuiltInHosts, 'useDoh': useDoh, 'dohPreset': dohPreset, 'dohCustomUrl': dohCustomUrl, 'dohBootstrapIps': dohBootstrapIps, 'dohTimeoutSeconds': dohTimeoutSeconds});

  Future<bool> hasCookie(String url, String name) async => await _channel.invokeMethod<bool>('hasCookie', {'url': url, 'name': name}) ?? false;

  Future<Han1meHttpResponse> get(String url) => _request(url);

  Future<void> download(String url, String path) => _channel.invokeMethod<void>('download', {'url': url, 'path': path});

  Future<Han1meHttpResponse> post(String url, Map<String, String> data, {Map<String, String>? headers}) =>
      _request(url, method: 'POST', data: data, headers: headers);

  Future<Han1meHttpResponse> delete(String url, Map<String, String> data, {Map<String, String>? headers, bool json = false}) =>
      _request(url, method: 'DELETE', data: data, headers: headers, json: json);

  Future<Han1meHttpResponse> _request(String url, {String method = 'GET', Map<String, String>? data, Map<String, String>? headers, bool json = false}) async {
    final response = await _channel.invokeMethod<dynamic>('request', {
      'url': url,
      'method': method,
      if (data != null) 'data': data,
      if (headers != null) 'headers': headers,
      if (json) 'json': true,
    });
    final result = Map<Object?, Object?>.from(response as Map);
    return Han1meHttpResponse(
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
