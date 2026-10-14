import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;

import '../../core/desktop_platform.dart';
import '../../core/site_hosts.dart';
import '../../core/app_log.dart';
import 'ech_static_client.dart';
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

  /// 静态 ECH 通道的每主机连续失败计数（>=3 时本进程内熔断回退原通道）。
  static final Map<String, int> _echFailures = {};
  static const int _echFailureThreshold = 3;

  static const userAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36';

  Future<void> saveCookies(String cookies, {String? url}) async {
    // 同步 ECH 静态通道 cookie 池（hanime 站点）
    final ech = EchStaticClient.instance;
    final host = Uri.tryParse(url ?? '')?.host;
    if (ech != null && host != null && hanimeSiteHosts.contains(host)) {
      ech.mergeCookies(Uri.parse(url!), cookies);
    }
    if (!_isDesktop) {
      await _channel.invokeMethod<void>('saveCookies', {'cookies': cookies, if (url != null) 'url': url});
      return;
    }
    final parsedHost = host;
    if (parsedHost == null || parsedHost.isEmpty) return;
    for (final target in _cookieHosts(parsedHost)) {
      _desktopCookies[target] = _mergeCookies(_desktopCookies[target], cookies);
    }
  }

  Future<void> clearCookies({String? url}) async {
    if (!_isDesktop) {
      await _channel.invokeMethod<void>('clearCookies', {if (url != null) 'url': url});
      return;
    }
    final host = Uri.tryParse(url ?? '')?.host;
    if (host == null || host.isEmpty) {
      _desktopCookies.clear();
    } else {
      for (final target in _cookieHosts(host)) {
        _desktopCookies.remove(target);
      }
    }
  }

  Future<String> webViewCookies(String url) async {
    if (!_isDesktop) return await _channel.invokeMethod<String>('webViewCookies', {'url': url}) ?? '';
    final cookies = await webview.CookieManager.instance().getCookies(url: webview.WebUri(url));
    final value = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    if (value.isNotEmpty) await saveCookies(value, url: url);
    return value;
  }

  Future<String> webViewCookiesFor(Iterable<String> urls) async {
    var merged = '';
    for (final url in urls) {
      merged = _mergeCookies(merged, await webViewCookies(url));
    }
    return merged;
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
    final start = DateTime.now();
    // 静态 ECH 直连优先（仅 hanime 站点，零 DNS / 零 DoH；失败自动回退原通道）
    final echResponse = await _tryEchRequest(url, method: method, data: data, headers: headers, responseCharset: responseCharset, json: json);
    if (echResponse != null) {
      _logRequest(method, url, echResponse.statusCode, DateTime.now().difference(start).inMilliseconds, 'ECH');
      return echResponse;
    }
    if (_isDesktop) {
      try {
        final response = await _desktopRequest(url, method: method, data: data, headers: headers, responseCharset: responseCharset, json: json);
        _logRequest(method, url, response.statusCode, DateTime.now().difference(start).inMilliseconds, '原生');
        return response;
      } catch (error) {
        _logRequest(method, url, null, DateTime.now().difference(start).inMilliseconds, '原生异常 $error');
        rethrow;
      }
    }
    try {
      final response = await _channel.invokeMethod<dynamic>(methodName, {
        'url': url,
        'method': method,
        if (data != null) 'data': data,
          if (headers != null) 'headers': headers,
          if (responseCharset != null) 'responseCharset': responseCharset,
        if (json) 'json': true,
      });
      final result = Map<Object?, Object?>.from(response as Map);
      final statusCode = result['statusCode']! as int;
      _logRequest(method, url, statusCode, DateTime.now().difference(start).inMilliseconds, '原生');
      return Han1meHttpResponse(
        statusCode: statusCode,
        body: result['body']! as String,
        url: result['url']! as String,
        headers: Map<String, List<String>>.fromEntries(
          Map<Object?, Object?>.from(result['headers']! as Map).entries.map(
            (entry) => MapEntry(entry.key! as String, List<String>.from(entry.value! as List)),
          ),
        ),
      );
    } catch (error) {
      _logRequest(method, url, null, DateTime.now().difference(start).inMilliseconds, '原生异常 $error');
      rethrow;
    }
  }

  void _logRequest(String method, String url, int? statusCode, int durationMs, String channel) {
    final uri = Uri.tryParse(url);
    var cookie = '';
    if (uri != null) {
      cookie = _cookiesFor(uri);
      final echCookie = EchStaticClient.instance?.cookiesFor(uri) ?? '';
      if (echCookie.isNotEmpty) cookie = cookie.isEmpty ? echCookie : '$cookie; $echCookie';
    }
    final hasAuth = cookie.split(';').where((part) => part.trim().toLowerCase().startsWith('remember_web=')).isNotEmpty;
    final hasCf = cookie.split(';').where((part) => part.trim().toLowerCase().startsWith('cf_clearance=')).isNotEmpty;
    final cookieInfo = [if (hasAuth) 'remember_web', if (hasCf) 'cf_clearance', if (!hasAuth && !hasCf && cookie.trim().isNotEmpty) 'other'].join('+');
    AppLog.log('$channel $method ${_short(url)} -> ${statusCode ?? '失败'} (${durationMs}ms)${cookieInfo.isEmpty ? '' : ' cookie=$cookieInfo'}');
  }

  String _short(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    var path = uri.path;
    if (path.length > 60) path = '${path.substring(0, 60)}…';
    return '${uri.scheme}://${uri.host}$path';
  }

  /// 用 ech_http 原生引擎 + 静态 CF 共享 ECH 配置直连 hanime 站点。
  /// 失败时返回 null（由调用方回退普通通道），并做每主机熔断。
  Future<Han1meHttpResponse?> _tryEchRequest(String url, {required String method, Map<String, String>? data, Map<String, String>? headers, String? responseCharset, bool json = false}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    // hanime 站点（含 www 子域）走静态 ECH
    final host = uri.host;
    final baseHost = host.startsWith('www.') ? host.substring(4) : host;
    if (!hanimeSiteHosts.contains(host) && !hanimeSiteHosts.contains(baseHost)) {
      return null;
    }
    final ech = EchStaticClient.instance;
    if (ech == null) return null;
    if ((_echFailures[host] ?? 0) >= _echFailureThreshold) {
      AppLog.log('ECH 熔断跳过 $method ${_short(url)} 连续失败=${_echFailures[host]}');
      return null;
    }
    try {
      final response = await ech.request(url, method: method, data: data, headers: headers, json: json);
      // 4xx/5xx 计入熔断（403 CF 挑战等）：ECH 通道不再对该域名无限重试；
      // 2xx/3xx 才清零。
      if (response.statusCode >= 400) {
        _echFailures[host] = (_echFailures[host] ?? 0) + 1;
        AppLog.log('ECH ${response.statusCode} ${_short(url)} ech=${response.echAccepted} retries=${response.echRetries} 熔断=${_echFailures[host]}');
      } else {
        _echFailures.remove(host);
      }
      // 回写 Set-Cookie 到原通道（Android 持久化 / 桌面池），保持会话同步
      final setCookie = response.headers['set-cookie'];
      if (response.statusCode >= 200 && response.statusCode < 400 && setCookie != null && setCookie.isNotEmpty) {
        await saveCookies(setCookie, url: response.url);
      }
      return Han1meHttpResponse(
        statusCode: response.statusCode,
        body: _decode(response.body, responseCharset),
        url: response.url,
        headers: response.headers.map((key, value) => MapEntry(key, [value])),
      );
    } on EchRedirectOutsideException catch (e) {
      // 跨域重定向到非站点域（媒体 CDN / 短链 / 图床）：ECH 通道停手，
      // 交回原生通道重发原 URL（原生跟随重定向，走系统解析直连）。
      // 不计数熔断 —— ECH 域本身是好的，只是目标不在 CF。
      AppLog.log('ECH 跨域重定向停手 $method ${_short(url)} -> ${e.target.host}');
      return null;
    } catch (e) {
      _echFailures[host] = (_echFailures[host] ?? 0) + 1;
      AppLog.log('ECH 异常 $method ${_short(url)} $e 熔断=${_echFailures[host]}');
      return null;
    }
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

  Iterable<String> _cookieHosts(String host) => hanimeSiteHosts.contains(host) ? hanimeSiteHosts : [host];

  String _mergeCookies(String? current, String next) {
    final cookies = <String, String>{};
    for (final cookie in [...(current ?? '').split(';'), ...next.split(';')]) {
      final separator = cookie.indexOf('=');
      if (separator > 0) cookies[cookie.substring(0, separator).trim()] = cookie.substring(separator + 1).trim();
    }
    return cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }
}
