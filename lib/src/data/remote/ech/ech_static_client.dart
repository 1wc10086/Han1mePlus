import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/network_policy.dart';
import '../../../core/site_hosts.dart';
import 'ech_ffi_bindings.dart';

class EchRedirectOutsideException implements Exception {
  EchRedirectOutsideException(this.target);

  final Uri target;

  @override
  String toString() => 'ECH redirect outside site domain: ${target.host}';
}

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
}

class EchStaticClient {
  EchStaticClient._(this._client);

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36';

  final EchFfiClient _client;
  final List<String> _logs = <String>[];
  final Map<String, String> _cookies = <String, String>{};
  final Map<String, int> _addressCursors = <String, int>{};

  static EchStaticClient? _instance;
  static bool _initialized = false;

  static EchStaticClient? get instance {
    if (_initialized) return _instance;
    _initialized = true;
    final native = EchFfiClient.tryCreate();
    if (native != null) _instance = EchStaticClient._(native);
    return _instance;
  }

  List<String> get logs => List<String>.unmodifiable(_logs.reversed.take(100));

  String cookiesFor(Uri uri) {
    final matches = _cookies.keys
        .where((host) => uri.host == host || uri.host.endsWith('.$host'))
        .toList()
      ..sort((left, right) => right.length.compareTo(left.length));
    final host = matches.firstOrNull;
    return host == null ? '' : _cookies[host] ?? '';
  }

  void mergeCookies(Uri uri, String cookies) {
    if (cookies.trim().isEmpty) return;
    final targets = hanimeSiteHosts.contains(uri.host) ? hanimeSiteHosts : {uri.host};
    for (final host in targets) {
      _mergeForHost(host, cookies);
    }
  }

  void _mergeForHost(String host, String cookies) {
    final merged = <String, String>{};
    for (final part in [...(_cookies[host] ?? '').split(RegExp(r'[;\n]')), ...cookies.split(RegExp(r'[;\n]'))]) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      final name = part.substring(0, index).trim();
      if (_cookieAttributes.contains(name.toLowerCase())) continue;
      merged[name] = part.substring(index + 1).trim();
    }
    _cookies[host] = merged.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }

  static const Set<String> _cookieAttributes = {
    'domain',
    'expires',
    'httponly',
    'max-age',
    'partitioned',
    'path',
    'priority',
    'samesite',
    'secure',
  };

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
        'User-Agent': _userAgent,
        ...?headers,
      };
      final cookie = cookiesFor(uri);
      if (cookie.isNotEmpty) requestHeaders['Cookie'] = cookie;

      Uint8List? body;
      if (currentData != null) {
        if (currentJson) {
          requestHeaders['Content-Type'] = 'application/json';
          body = Uint8List.fromList(utf8.encode(jsonEncode(currentData)));
        } else {
          requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded; charset=utf-8';
          body = Uint8List.fromList(
            utf8.encode(
              currentData.entries.map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}').join('&'),
            ),
          );
        }
      }

      final native = await _client.request(
        uri.toString(),
        currentMethod,
        requestHeaders,
        body: body,
        echConfig: isEchDomain(uri.host) ? kCfSharedEchConfig : '',
        connectIp: isEchDomain(uri.host) ? _pickAddress(uri.host) : '',
      );

      if (native.errorMessage != null && native.statusCode == 0) {
        _log('${uri.host} failed: ${native.errorMessage} (${native.nativeCode})');
        throw StateError('ECH failed (${native.nativeCode}): ${native.errorMessage}');
      }

      final setCookie = native.headers['set-cookie'];
      if (native.statusCode >= 200 && native.statusCode < 400 && setCookie != null && setCookie.isNotEmpty) {
        mergeCookies(uri, setCookie);
      }

      final location = native.headers['location'];
      if (native.isRedirect && location != null) {
        final next = Uri.parse(rewriteMediaUrl(uri.resolve(location).toString()));
        if (!isSiteDomain(next.host)) throw EchRedirectOutsideException(next);
        uri = next;
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
    throw StateError('ECH redirect limit reached: $url');
  }

  String _pickAddress(String host) {
    var key = host.toLowerCase();
    if (key.startsWith('www.')) key = key.substring(4);
    final addresses = kEchDomainAddresses[key];
    if (addresses == null || addresses.isEmpty) return '';
    final cursor = _addressCursors[key] = (_addressCursors[key] ?? 0) + 1;
    return addresses[cursor % addresses.length];
  }

  void _log(String message) {
    _logs.add(message);
    if (_logs.length > 200) _logs.removeRange(0, _logs.length - 200);
  }

  void close() => _client.close();
}
