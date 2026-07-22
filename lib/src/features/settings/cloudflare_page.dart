import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../account/account_controller.dart';
import 'settings_controller.dart';

class CloudflarePage extends ConsumerStatefulWidget {
  const CloudflarePage({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  ConsumerState<CloudflarePage> createState() => _CloudflarePageState();
}

class _CloudflarePageState extends ConsumerState<CloudflarePage> {
  InAppWebViewController? _controller;
  Timer? _verificationTimer;
  var _saving = false;

  Future<void> _completeVerification(String requestUrl) async {
    if (_saving) return;
    final head = await _controller?.evaluateJavascript(source: 'document.head.innerHTML');
    if (head == null || head.contains('#challenge-form') || head.contains('#challenge-success-text') || head.contains('#challenge-error-text')) return;
    final cookies = await ref.read(han1meHttpClientProvider).webViewCookies(requestUrl);
    if (!RegExp(r'(^|;)\s*cf_clearance=', caseSensitive: false).hasMatch(cookies) || !mounted) return;
    _saving = true;
    try {
      await ref
          .read(accountProvider.notifier)
          .saveCloudflareCookie(cookies);
    } catch (_) {
      _saving = false;
      return;
    }
    if (!mounted) return;
    _verificationTimer?.cancel();
    Navigator.pop(context, true);
  }

  void _startVerification(String requestUrl) {
    if (_verificationTimer != null) return;
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _completeVerification(requestUrl));
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.baseUrl ?? 'https://hanime1.com';
    final initialUrl = widget.initialUrl ?? baseUrl;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.cloudflareVerification)),
      body: Stack(children: [
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            thirdPartyCookiesEnabled: true,
            userAgent: Han1meApi.userAgent,
          ),
          onWebViewCreated: (controller) async {
            _controller = controller;
            final url = WebUri(initialUrl);
            await controller.loadUrl(urlRequest: URLRequest(url: url));
          },
          onProgressChanged: (_, progress) async {
            if (progress < 90) return;
            _startVerification(initialUrl);
          },
        ),
      ]),
    );
  }
}
