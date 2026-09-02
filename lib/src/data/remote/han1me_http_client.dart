import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;

import '../../core/desktop_platform.dart';
import 'windows_http_overrides.dart';

class Han1meHttpResponse {
  const Han1meHttpResponse({required this.statusCode, required this.body, required this.headers, required this.url});

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
  final String url;
}

class Han1meHttpClient {
  static const _channel = MethodChannel('com.liar.han1meplus/http');
  static final _desktopCookies = <String, String>{};
  static bool get _isDesktop => isDesktopHttpPlatform;

  static const userAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36';

  Future<void> saveCookies(String cookies, {String? url}) async {
    if (!_isDesktop) {
      await _channel.invokeMethod<void>('saveCookies', {'cookies': cookies, if (url != null) 'url': url});
      return;
    }
    final host = Uri.tryParse(url ?? '')?.host;
    if (host != null && host.isNotEmpty) _desktopCookies[host] = _mergeCookies(_desktopCookies[host], cookies);
  }

  Future<void> clearCookies({String? url}) async {
    if (!_isDesktop) {
      await _channel.invokeMethod<void>('clearCookies', {if (url != null) 'url': url});
      return;
    }
    final host = Uri.tryParse(url ?? '')?.host;
    if (host == null || host.isEmpty) _desktopCookies.clear(); else _desktopCookies.remove(host);
  }

  Future<String> webViewCookies(String url) async {
    if (!_isDesktop) return await _channel.invokeMethod<String>('webViewCookies', {'url': url}) ?? '';
    final cookies = await webview.CookieManager.instance().getCookies(url: webview.WebUri(url));
    final value = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    if (value.isNotEmpty) await saveCookies(value, url: url);
    return value;
  }

  Future<void> clearWebViewCookies() async {
    if (!_isDesktop) {
      await _channel.invokeMethod<void>('clearWebViewCookies');
      return;
    }
    await webview.CookieManager.instance().deleteAllCookies();
    await clearCookies();
  }

  Future<void> setNetworkSettings({required bool useBuiltInHosts, required bool useDoh, required String dohPreset, required String dohCustomUrl, required String dohBootstrapIps, required int dohTimeoutSeconds}) async {
    if (_isDesktop) {
      HttpOverrides.global = WindowsHttpOverrides(
        proxy: await WindowsHttpOverrides.systemProxy(),
        useBuiltInHosts: useBuiltInHosts,
        useDoh: useDoh,
        dohPreset: dohPreset,
        dohCustomUrl: dohCustomUrl,
        dohBootstrapIps: dohBootstrapIps,
        dohTimeoutSeconds: dohTimeoutSeconds,
      );
      return;
    }
    await _channel.invokeMethod<void>('setNetworkSettings', {'useBuiltInHosts': useBuiltInHosts, 'useDoh': useDoh, 'dohPreset': dohPreset, 'dohCustomUrl': dohCustomUrl, 'dohBootstrapIps': dohBootstrapIps, 'dohTimeoutSeconds': dohTimeoutSeconds});
  }

  Future<bool> hasCookie(String url, String name) async => _isDesktop ? _cookiesFor(Uri.parse(url)).split(';').any((cookie) => cookie.trim().split('=').first.toLowerCase() == name.toLowerCase()) : await _channel.invokeMethod<bool>('hasCookie', {'url': url, 'name': name}) ?? false;

  Future<Han1meHttpResponse> get(String url, {String? responseCharset, Map<String, String>? headers}) => _request(url, responseCharset: responseCharset, headers: headers);

  Future<void> download(String url, String path) async {
    if (!_isDesktop) {
      await _channel.invokeMethod<void>('download', {'url': url, 'path': path});
      return;
    }
    final client = _desktopClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      final cookie = _cookiesFor(request.uri);
      if (cookie.isNotEmpty) request.headers.set(HttpHeaders.cookieHeader, cookie);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) throw HttpException('Download failed: HTTP ${response.statusCode}', uri: request.uri);
      final output = File(path);
      await output.parent.create(recursive: true);
      await response.pipe(output.openWrite());
      _saveResponseCookies(request.uri, response.cookies);
    } finally {
      client.close(force: true);
    }
  }

  Future<Han1meHttpResponse> post(String url, Map<String, String> data, {Map<String, String>? headers, String? responseCharset}) =>
      _request(url, method: 'POST', data: data, headers: headers, responseCharset: responseCharset);

  Future<Han1meHttpResponse> delete(String url, Map<String, String> data, {Map<String, String>? headers, bool json = false}) =>
      _request(url, method: 'DELETE', data: data, headers: headers, json: json);

  Future<Han1meHttpResponse> _request(String url, {String methodName = 'request', String method = 'GET', Map<String, String>? data, Map<String, String>? headers, String? responseCharset, bool json = false}) async {
    if (_isDesktop) return _desktopRequest(url, method: method, data: data, headers: headers, responseCharset: responseCharset, json: json);
    final response = await _channel.invokeMethod<dynamic>(methodName, {
      'url': url,
      'method': method,
      if (data != null) 'data': data,
        if (headers != null) 'headers': headers,
        if (responseCharset != null) 'responseCharset': responseCharset,
      if (json) 'json': true,
    });
    final result = Map<Object?, Object?>.from(response as Map);
    return Han1meHttpResponse(
      statusCode: result['statusCode']! as int,
      body: result['body']! as String,
      url: result['url']! as String,
      headers: Map<String, List<String>>.fromEntries(
        Map<Object?, Object?>.from(result['headers']! as Map).entries.map(
          (entry) => MapEntry(entry.key! as String, List<String>.from(entry.value! as List)),
        ),
      ),
    );
  }

  Future<Han1meHttpResponse> _desktopRequest(String url, {required String method, Map<String, String>? data, Map<String, String>? headers, String? responseCharset, required bool json}) async {
    final client = _desktopClient();
    try {
      final request = await client.openUrl(method, Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      final cookie = _cookiesFor(request.uri);
      if (cookie.isNotEmpty) request.headers.set(HttpHeaders.cookieHeader, cookie);
      headers?.forEach(request.headers.set);
      if (data != null) {
        if (json) {
          request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
          request.write(jsonEncode(data));
        } else {
          request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
          request.write(data.entries.map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}').join('&'));
        }
      }
      final response = await request.close();
      final bytes = await response.fold<List<int>>([], (value, chunk) => value..addAll(chunk));
      _saveResponseCookies(request.uri, response.cookies);
      final responseHeaders = <String, List<String>>{};
      response.headers.forEach((name, values) => responseHeaders[name] = values);
      return Han1meHttpResponse(statusCode: response.statusCode, body: _decode(bytes, responseCharset), headers: responseHeaders, url: response.redirects.isEmpty ? request.uri.toString() : response.redirects.last.location.toString());
    } finally {
      client.close(force: true);
    }
  }

  String _decode(List<int> bytes, String? charset) {
    if (charset?.toLowerCase() case 'euc-jp' || 'euc_jp') return eucJp.decode(bytes);
    return Encoding.getByName(charset ?? 'utf-8')?.decode(bytes) ?? utf8.decode(bytes, allowMalformed: true);
  }

  HttpClient _desktopClient() => HttpClient();

  String _cookiesFor(Uri uri) => _desktopCookies.entries.where((entry) => uri.host == entry.key || uri.host.endsWith('.${entry.key}')).map((entry) => entry.value).join('; ');

  void _saveResponseCookies(Uri uri, List<Cookie> cookies) {
    if (cookies.isEmpty) return;
    saveCookies(cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; '), url: uri.toString());
  }

  String _mergeCookies(String? current, String next) {
    final cookies = <String, String>{};
    for (final cookie in [...(current ?? '').split(';'), ...next.split(';')]) {
      final separator = cookie.indexOf('=');
      if (separator > 0) cookies[cookie.substring(0, separator).trim()] = cookie.substring(separator + 1).trim();
    }
    return cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }
}
