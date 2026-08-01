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
  Timer? _verificationTimer;
  String? _initialClearance;
  var _saving = false;

  Future<void> _completeVerification(String requestUrl) async {
    if (_saving) return;
    final cookies = await ref.read(han1meHttpClientProvider).webViewCookies(requestUrl);
    final clearance = _clearanceCookie(cookies);
    if (clearance == null || clearance == _initialClearance || !mounted) return;
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

  String? _clearanceCookie(String cookies) {
    for (final cookie in cookies.split(';')) {
      if (cookie.trim().toLowerCase().startsWith('cf_clearance=')) return cookie.trim();
    }
    return null;
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.resolvedBaseUrl ?? 'https://hanime1.com';
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
            _initialClearance = _clearanceCookie(await ref.read(han1meHttpClientProvider).webViewCookies(initialUrl));
            final url = WebUri(initialUrl);
            await controller.loadUrl(urlRequest: URLRequest(url: url));
            _startVerification(initialUrl);
          },
        ),
      ]),
    );
  }
}
