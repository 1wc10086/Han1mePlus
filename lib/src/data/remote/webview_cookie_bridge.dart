import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewCookieBridge {
  WebViewCookieBridge._();

  static WebViewEnvironment? environment;

  static CookieManager get _manager => CookieManager.instance(webViewEnvironment: environment);

  static Future<void> syncToWebView(String cookies, String url) async {
    if (!_supported || cookies.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return;
    final origin = '${uri.scheme}://${uri.host}/';
    for (final part in cookies.split(';')) {
      final pair = part.trim();
      final index = pair.indexOf('=');
      if (index <= 0) continue;
      final name = pair.substring(0, index).trim();
      final value = pair.substring(index + 1).trim();
      if (name.isEmpty || value.isEmpty) continue;
      try {
        await _manager.setCookie(url: WebUri(origin), name: name, value: value);
      } catch (_) {}
    }
  }

  static Future<String> read(Iterable<String> targets) async {
    final merged = <String, String>{};
    for (final target in targets.toList(growable: false)) {
      for (final cookie in await _cookies(target)) {
        merged[cookie.name] = cookie.value;
      }
    }
    return merged.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }

  static Future<String> readAll() => read(urls);

  static Future<void> clear() async {
    if (!_supported) return;
    try {
      await _manager.deleteAllCookies();
    } catch (_) {}
  }

  static List<String> get urls => [
        for (final host in const ['hanime1.me', 'hanime1.com', 'hanimeone.me', 'javchu.com']) 'https://$host/',
      ];

  static bool get _supported => Platform.isWindows || Platform.isMacOS || Platform.isAndroid || Platform.isIOS;

  static Future<List<Cookie>> _cookies(String url) async {
    if (!_supported || url.isEmpty) return const [];
    try {
      return await _manager.getCookies(url: WebUri(url));
    } catch (_) {
      return const [];
    }
  }
}
