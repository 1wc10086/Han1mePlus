import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_log.dart';
import '../../core/site_hosts.dart';
import '../../core/site_url.dart';
import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../data/remote/webview_environment.dart';
import '../settings/settings_controller.dart';
import 'account_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _pollInterval = Duration(milliseconds: 700);
  static const _captureCooldown = Duration(seconds: 2);
  static const _loginMarkerScript = r"""
(function () {
  var trigger = document.querySelector('#user-modal-trigger');
  if (trigger) {
    if (/\/user\/\d+/.test(trigger.getAttribute('href') || '')) return true;
    if (trigger.querySelector('a[href*="/user/"]')) return true;
  }
  return document.querySelector('.profile-sub-stats-id') !== null;
})()
""";

  InAppWebViewController? _controller;
  Timer? _timer;
  DateTime? _lastAttempt;
  var _saving = false;
  Object? _error;

  Future<void> _capture({bool manual = false}) async {
    if (_saving || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      if (manual) _error = null;
    });
    var popped = false;
    try {
      final settings = await ref.read(settingsProvider.future);
      final current = await _controller?.getUrl();
      if (!mounted) return;
      final cookie = await ref.read(han1meHttpClientProvider).webViewCookiesFor(_candidates(current, settings.resolvedBaseUrl));
      if (!mounted) return;
      if (_withoutClearance(cookie).isEmpty) {
        // 抓到的 cookie 里没有登录态（remember_web 等），记录 cookie 名供排查
        final names = cookie.split(';').map((part) => part.trim().split('=').first).where((name) => name.isNotEmpty).toList();
        AppLog.log('登录抓取失败: 无登录 cookie（抓到: ${names.isEmpty ? '空' : names.join(',')}）');
        if (manual) setState(() => _error = l10n.failed);
        return;
      }
      await ref.read(accountProvider.notifier).saveCookie(cookie);
      if (!mounted) return;
      _timer?.cancel();
      _timer = null;
      if (_pop()) {
        popped = true;
        return;
      }
      _startPolling();
    } catch (error) {
      AppLog.log('登录保存失败: $error');
      if (mounted && manual) setState(() => _error = error);
    } finally {
      if (mounted && !popped) setState(() => _saving = false);
    }
  }

  bool _pop() {
    try {
      context.pop();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) {
      if (mounted && !_saving) unawaited(_poll());
    });
  }

  Future<void> _poll() async {
    final last = _lastAttempt;
    if (last != null && DateTime.now().difference(last) < _captureCooldown) return;
    final controller = _controller;
    if (controller == null || !mounted) return;
    // 方式一：直接检测登录 cookie（最可靠，不依赖页面元素结构）
    try {
      final settings = await ref.read(settingsProvider.future);
      final current = await controller.getUrl();
      if (mounted) {
        final cookie = await ref.read(han1meHttpClientProvider).webViewCookiesFor(_candidates(current, settings.resolvedBaseUrl));
        if (_withoutClearance(cookie).isNotEmpty) {
          if (!mounted) return;
          _lastAttempt = DateTime.now();
          AppLog.log('登录自动识别: 检测到登录 cookie，自动同步');
          await _capture();
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    // 方式二：页面元素判定（WebView 已登录跳转）
    final loggedIn = await _loggedIn(controller);
    if (!mounted) return;
    if (!loggedIn && !await _leftLoginPage(controller)) return;
    if (!mounted) return;
    _lastAttempt = DateTime.now();
    await _capture();
  }

  Future<bool> _loggedIn(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(source: _loginMarkerScript);
      return result == true || result == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<bool> _leftLoginPage(InAppWebViewController controller) async {
    try {
      final url = await controller.getUrl();
      return url != null && url.host.isNotEmpty && url.path != '/login';
    } catch (_) {
      return false;
    }
  }

  Iterable<String> _candidates(Uri? current, String baseUrl) {
    final urls = <String>{};
    if (current != null && current.host.isNotEmpty) urls.add('${current.scheme}://${current.authority}/');
    final base = Uri.tryParse(baseUrl);
    if (base != null && base.host.isNotEmpty) urls.add('${base.scheme}://${base.authority}/');
    for (final host in hanimeSiteHosts) {
      urls.add('https://$host/');
    }
    return urls;
  }

  String _withoutClearance(String cookies) =>
      cookies.split(';').where((cookie) => cookie.trim().toLowerCase().split('=').first != 'cf_clearance').join(';').trim();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.resolvedBaseUrl ?? 'https://hanime1.me';
    final webViewEnvironment = ref.watch(webViewEnvironmentProvider).valueOrNull;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.login),
        actions: [
          TextButton(
            onPressed: () => unawaited(_capture(manual: true)),
            child: Text(l10n.finishLogin),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.manualCookieLogin,
        onPressed: () => context.push('/login/cookies'),
        child: const Icon(Icons.cookie_outlined),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InAppWebView(
            webViewEnvironment: webViewEnvironment,
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              thirdPartyCookiesEnabled: true,
              userAgent: Han1meApi.userAgent,
            ),
            onWebViewCreated: (controller) async {
              _controller = controller;
              await ref.read(han1meHttpClientProvider).clearWebViewCookies();
              if (!mounted) return;
              await controller.loadUrl(urlRequest: URLRequest(url: WebUri(siteEndpointUrl(baseUrl, 'login'))));
              if (!mounted) return;
              _startPolling();
            },
          ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: MaterialBanner(
                content: Text('$_error'),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
          if (_saving) const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}
