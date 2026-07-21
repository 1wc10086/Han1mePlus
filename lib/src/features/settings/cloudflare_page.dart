import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/han1me_repository.dart';
import '../account/account_controller.dart';
import 'settings_controller.dart';

class CloudflarePage extends ConsumerStatefulWidget {
  const CloudflarePage({super.key});

  @override
  ConsumerState<CloudflarePage> createState() => _CloudflarePageState();
}

class _CloudflarePageState extends ConsumerState<CloudflarePage> {
  var _verifying = true;

  Future<void> _readCookie(WebUri uri) async {
    final cookies = await CookieManager.instance().getCookies(url: uri);
    final clearance = cookies.where((cookie) => cookie.name == 'cf_clearance').firstOrNull;
    if (clearance == null || !mounted) return;
    await ref.read(accountProvider.notifier).saveCloudflareCookie('${clearance.name}=${clearance.value}');
    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.baseUrl ?? 'https://hanimeone.me';
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.cloudflareVerification)),
      body: Stack(children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(baseUrl)),
          initialSettings: InAppWebViewSettings(javaScriptEnabled: true, thirdPartyCookiesEnabled: true),
          onLoadStop: (_, url) async {
            if (url != null) await _readCookie(url);
          },
        ),
        if (_verifying) const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator()),
        if (!_verifying) Align(alignment: Alignment.bottomCenter, child: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.verificationComplete))))),
      ]),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
