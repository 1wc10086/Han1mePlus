import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_api.dart';
import '../account/account_controller.dart';
import '../settings/settings_controller.dart';

enum TagEditorMode { add, remove }

class TagEditorPage extends ConsumerStatefulWidget {
  const TagEditorPage({super.key, required this.videoId, required this.mode});

  final String videoId;
  final TagEditorMode mode;

  @override
  ConsumerState<TagEditorPage> createState() => _TagEditorPageState();
}

class _TagEditorPageState extends ConsumerState<TagEditorPage> {
  String? _url;
  var _opened = false;
  var _allowPop = false;
  var _closing = false;

  Future<void> _prepare(InAppWebViewController controller) async {
    if (_opened) return;
    final selector = widget.mode == TagEditorMode.add ? '#add-tags-modal' : '#remove-tags-modal';
    final result = await controller.evaluateJavascript(source: '''
      (() => {
        const modal = document.querySelector('$selector');
        if (!modal) return false;
        const trigger = document.querySelector('[data-target="$selector"], [data-bs-target="$selector"], [href="$selector"]');
        if (trigger) trigger.click();
        if (!modal.classList.contains('show')) {
          modal.style.display = 'block';
          modal.classList.add('show');
          modal.setAttribute('aria-modal', 'true');
          modal.removeAttribute('aria-hidden');
        }
        document.querySelectorAll('body > *').forEach((element) => {
          if (element !== modal && !element.contains(modal) && !element.classList.contains('modal-backdrop')) element.style.display = 'none';
        });
        document.body.style.background = 'transparent';
        document.body.style.overflow = 'auto';
        modal.style.position = 'relative';
        modal.style.inset = 'auto';
        modal.style.padding = '0';
        modal.querySelector('.modal-dialog')?.style.setProperty('margin', '0 auto');
        return true;
      })()
    ''');
    if (result == true || result == 'true') _opened = true;
  }

  Future<void> _syncCookies() async {
    final url = _url;
    if (url == null) return;
    final cookies = await ref.read(han1meHttpClientProvider).webViewCookies(url);
    if (cookies.isEmpty) return;
    try {
      await ref.read(accountProvider.notifier).saveCookie(cookies);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final title = widget.mode == TagEditorMode.add ? l10n.addTags : l10n.removeTags;
    if (settings == null) return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    _url ??= '${settings.resolvedBaseUrl}/watch?v=${Uri.encodeQueryComponent(widget.videoId)}';
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _closing) return;
        _closing = true;
        await _syncCookies();
        if (!mounted) return;
        setState(() => _allowPop = true);
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_url!)),
          initialSettings: InAppWebViewSettings(javaScriptEnabled: true, domStorageEnabled: true, thirdPartyCookiesEnabled: true, userAgent: Han1meApi.userAgent),
          onLoadStart: (controller, url) {
            _opened = false;
            _url = url?.toString() ?? _url;
          },
          onLoadStop: (controller, url) async {
            _url = url?.toString() ?? _url;
            await _prepare(controller);
          },
        ),
      ),
    );
  }
}
