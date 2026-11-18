import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../core/network/cloudflare_session.dart';
import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../../data/remote/han1me_http_client.dart';
import '../../data/remote/webview_cookie_bridge.dart';
import '../../data/remote/webview_environment.dart';
import '../account/account_controller.dart';
import 'settings_controller.dart';

class CloudflarePage extends ConsumerStatefulWidget {
  const CloudflarePage({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  ConsumerState<CloudflarePage> createState() => _CloudflarePageState();
}

class _CloudflarePageState extends ConsumerState<CloudflarePage> {
  static const _pollInterval = Duration(milliseconds: 700);

  Timer? _timer;
  String? _initialClearance;
  var _saving = false;
  var _completed = false;
  var _reloadToken = 0;

  String? _clearance(String cookies) {
    for (final cookie in cookies.split(';')) {
      final value = cookie.trim();
      if (value.toLowerCase().startsWith('cf_clearance=')) return value;
    }
    return null;
  }

  Future<String> _readCookies(String url) async {
    final base = ref.read(settingsProvider).valueOrNull?.resolvedBaseUrl ?? '';
    final urls = <String>[if (url.startsWith('http')) '${Uri.parse(url).scheme}://${Uri.parse(url).host}/', if (base.isNotEmpty) base, ...WebViewCookieBridge.urls];
    return WebViewCookieBridge.read(urls);
  }

  Future<void> _completeVerification(String requestUrl) async {
    if (_saving || _completed) return;
    _saving = true;
    try {
      final cookies = await _readCookies(requestUrl);
      final clearance = _clearance(cookies);
      if (clearance == null || !mounted) return;
      if (clearance == _initialClearance && !await _probeVerified(requestUrl)) return;
      await ref.read(accountProvider.notifier).saveCloudflareCookie(cookies);
      await WebViewCookieBridge.syncToWebView(cookies, requestUrl);
      CloudflareSession.markVerified();
      if (!mounted) return;
      _completed = true;
      _timer?.cancel();
      Navigator.pop(context, true);
    } catch (_) {
    } finally {
      _saving = false;
    }
  }

  Future<bool> _probeVerified(String requestUrl) async {
    if (!requestUrl.startsWith('http')) return false;
    try {
      final response = await ref.read(han1meHttpClientProvider).get(requestUrl);
      return !Han1meApi.isCloudflareResponse(response.statusCode, response.headers, response.body);
    } catch (_) {
      return false;
    }
  }

  void _startPolling(String requestUrl) {
    if (_timer != null) return;
    _timer = Timer.periodic(_pollInterval, (_) {
      if (!_saving && !_completed) unawaited(_completeVerification(requestUrl));
    });
  }

  Future<void> _finishManually(String requestUrl) async {
    if (_saving || _completed) return;
    _saving = true;
    try {
      final cookies = await _readCookies(requestUrl);
      if (cookies.isNotEmpty) {
        await ref.read(accountProvider.notifier).saveCloudflareCookie(cookies);
        await WebViewCookieBridge.syncToWebView(cookies, requestUrl);
        CloudflareSession.markVerified();
      }
      if (!mounted) return;
      _completed = true;
      _timer?.cancel();
      Navigator.pop(context, true);
    } catch (_) {
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.resolvedBaseUrl ?? 'https://hanime1.me';
    final initialUrl = widget.initialUrl ?? baseUrl;
    final webViewEnvironment = ref.watch(webViewEnvironmentProvider).valueOrNull;
    WebViewCookieBridge.environment = webViewEnvironment;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cloudflareVerification),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: _completed ? null : () {
              _timer?.cancel();
              _timer = null;
              setState(() => _reloadToken++);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: ValueKey(_reloadToken),
            webViewEnvironment: webViewEnvironment,
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              thirdPartyCookiesEnabled: true,
              cacheEnabled: true,
            ),
            onWebViewCreated: (controller) async {
              _initialClearance = _clearance(await _readCookies(initialUrl));
              _startPolling(initialUrl);
              await controller.loadUrl(urlRequest: URLRequest(url: WebUri(initialUrl)));
            },
            onLoadStop: (controller, url) {
              final current = url?.toString();
              if (current == null || current.isEmpty) return;
              unawaited(_completeVerification(current));
            },
            onReceivedHttpError: (controller, request, response) {
              final current = request.url.toString();
              if (current.isEmpty) return;
              unawaited(_completeVerification(current));
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.cloudflareVerificationDescription, style: Theme.of(context).textTheme.bodySmall)),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _completed || _saving ? null : () => unawaited(_finishManually(initialUrl)),
                      child: Text(l10n.finishedVerification),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
