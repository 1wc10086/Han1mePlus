import 'dart:convert';
import 'dart:typed_data';

import '../../core/ech_domain_config.dart';
import '../../core/site_hosts.dart';
import 'ech_ffi_bindings.dart';

/// 跨域重定向到 ECH 域之外：ECH 通道必须停手，交回原生通道重发
/// （重定向目标多为媒体 CDN / 短链 / 图床，非 CF 域名，不能拿 CF 共享 ECH 去打）。
class EchRedirectOutsideException implements Exception {
  EchRedirectOutsideException(this.target);

  final Uri target;

  @override
  String toString() => 'ECH redirect outside ech domain: ${target.host}';
}

/// 静态 ECH 请求结果。
class EchStaticResponse {
  const EchStaticResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.url,
    required this.echAccepted,
    required this.echRetries,
  });

  final int statusCode;
  final List<int> body;
  final Map<String, String> headers;
  final String url;
  final bool echAccepted;
  final int echRetries;

  bool get isRedirect =>
      statusCode == 301 || statusCode == 302 || statusCode == 303 || statusCode == 307 || statusCode == 308;
}

/// 基于 ech_http（libcurl + BoringSSL）原生引擎的静态 ECH 请求执行器。
///
/// 设计要点：
/// - ECH 配置静态喂入（`ecl:<base64>`），物理 IP 直连（`connect_ip`），
///   全程零 DNS / 零 DoH；
/// - `followRedirects=false`（手动处理 301/302）：**保留中间响应的
///   Set-Cookie**（remember_web 登录态正是在 302 下发的，丢失会导致登录掉线）；
/// - 仅 2xx / 3xx 响应回写 cookie，403 挑战响应不回写，防止 CF 挑战 cookie
///   覆盖有效 cf_clearance；
/// - Fail-Closed：ECH 握手失败返回 errorMessage，由调用方回退普通通道。
class EchStaticClient {
  EchStaticClient._(this._client);

  final EchFfiClient _client;
  final List<String> _logs = [];

  /// host -> cookie 串（Dart 层维护的 ECH 通道 cookie 池）。
  final Map<String, String> cookiePool = {};

  static EchStaticClient? _instance;
  static bool _initTried = false;

  /// 惰性初始化：原生库不可用时返回 null（调用方回退普通通道）。
  static EchStaticClient? get instance {
    if (!_initTried) {
      _initTried = true;
      try {
        final native = EchFfiClient.tryCreate();
        if (native != null) _instance = EchStaticClient._(native);
      } catch (_) {
        _instance = null;
      }
    }
    return _instance;
  }

  List<String> get logs => List.unmodifiable(_logs.reversed.take(100));

  void _log(String message) {
    _logs.add(message);
    if (_logs.length > 200) _logs.removeRange(0, _logs.length - 200);
  }

  String cookiesFor(Uri uri) => cookiePool.entries
      .where((e) => uri.host == e.key || uri.host.endsWith('.${e.key}'))
      .map((e) => e.value)
      .join('; ');

  void mergeCookies(Uri uri, String cookies) {
    if (cookies.trim().isEmpty) return;
    final host = uri.host;
    final merged = <String, String>{};
    for (final part in [...(cookiePool[host] ?? '').split(';'), ...cookies.split(';')]) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      merged[part.substring(0, index).trim()] = part.substring(index + 1).trim();
    }
    cookiePool[host] = merged.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// 执行一次请求。ECH 失败（Fail-Closed）时抛异常，由调用方决定回退。
  Future<EchStaticResponse> request(
    String url, {
    required String method,
    Map<String, String>? data,
    Map<String, String>? headers,
    bool json = false,
  }) async {
    var uri = Uri.parse(rewriteMediaUrl(url));
    var currentMethod = method;
    var currentData = data;
    var currentJson = json;

    for (var redirects = 0; redirects < 6; redirects++) {
      final requestHeaders = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36',
        if (headers != null) ...headers,
      };
      final cookie = cookiesFor(uri);
      if (cookie.isNotEmpty) requestHeaders['Cookie'] = cookie;

      Uint8List? bodyBytes;
      if (currentData != null) {
        if (currentJson) {
          requestHeaders['Content-Type'] = 'application/json';
          bodyBytes = Uint8List.fromList(utf8.encode(jsonEncode(currentData)));
        } else {
          requestHeaders['Content-Type'] =
              'application/x-www-form-urlencoded; charset=utf-8';
          bodyBytes = Uint8List.fromList(
            utf8.encode(
              currentData.entries
                  .map((e) =>
                      '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
                  .join('&'),
            ),
          );
        }
      }

      final native = await _client.request(
        uri.toString(),
        currentMethod,
        requestHeaders,
        body: bodyBytes,
        // 域名适配：CF 主域 → 共享 ECH 强制；其他域名 → 普通 TLS（空配置）。
        echConfig: isEchDomain(uri.host) ? kCfSharedEchConfigList : '',
        // 物理直连：CF 主域 → 静态真实 IP（探针实测）；其他 → 系统解析。
        connectIp: isEchDomain(uri.host) ? _pickAddress(uri.host) : '',
      );

      // ECH 握手失败（Fail-Closed）：抛回调用方做回退
      if (native.errorMessage != null && native.statusCode == 0) {
        _log('${uri.host} ECH 失败: ${native.errorMessage} (native ${native.nativeCode})');
        throw StateError(
          'ECH 失败 (${native.nativeCode}): ${native.errorMessage}',
        );
      }

      // 保存 Set-Cookie：仅成功（2xx）与重定向（3xx）响应；4xx/5xx 不回写，
      // 防止 CF 挑战 cookie 覆盖有效 cf_clearance / remember_web。
      final setCookie = native.headers['set-cookie'];
      if (native.statusCode >= 200 &&
          native.statusCode < 400 &&
          setCookie != null &&
          setCookie.isNotEmpty) {
        mergeCookies(uri, setCookie);
      }

      final location = native.headers['location'];
      if (native.isRedirect && location != null) {
        var nextUri = uri.resolve(location);
        nextUri = Uri.parse(rewriteMediaUrl(nextUri.toString()));
        // 跨域重定向到非站点域（媒体 CDN / 短链 / 图床）：
        // ECH 通道停手，交回原生通道（它们不是 CF，不能拿 CF 共享 ECH 去打）。
        if (!isSiteDomain(nextUri.host)) {
          throw EchRedirectOutsideException(nextUri);
        }
        // 跨域重定向剥离 Cookie（沿用 ech_http 的安全策略）
        if (nextUri.host != uri.host) {
          requestHeaders.remove('Cookie');
        }
        uri = nextUri;
        currentData = null;
        currentJson = false;
        if (currentMethod != 'HEAD') currentMethod = 'GET';
        continue;
      }

      _log('${uri.host} ${native.statusCode} ech=${native.echAccepted} retries=${native.echRetries}');
      return EchStaticResponse(
        statusCode: native.statusCode,
        body: native.body,
        headers: native.headers,
        url: uri.toString(),
        echAccepted: native.echAccepted,
        echRetries: native.echRetries,
      );
    }
    throw StateError('ECH 重定向次数过多: $url');
  }

  /// 物理直连地址：按域名取静态真实 IP（轮询），非 ECH 域返回空（系统解析）。
  static final Map<String, int> _addressCursors = {};

  String _pickAddress(String host) {
    var key = host.toLowerCase();
    if (key.startsWith('www.')) key = key.substring(4);
    final addresses = kEchDomainAddresses[key];
    if (addresses == null || addresses.isEmpty) return '';
    final cursor = _addressCursors[key] = (_addressCursors[key] ?? 0) + 1;
    return addresses[cursor % addresses.length];
  }

  void close() => _client.close();
}
