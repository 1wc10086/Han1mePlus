import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'windows_http_overrides.dart';

final webViewEnvironmentProvider = FutureProvider<WebViewEnvironment?>((ref) async {
  if (!Platform.isWindows) return null;
  final supportDirectory = await getApplicationSupportDirectory();
  final proxy = await WindowsHttpOverrides.systemProxy();
  final environment = await WebViewEnvironment.create(
    settings: WebViewEnvironmentSettings(
      userDataFolder: path.join(supportDirectory.path, 'webview2'),
      additionalBrowserArguments: _browserProxyArgument(proxy),
    ),
  );
  ref.onDispose(() => environment.dispose());
  return environment;
});

String _browserProxyArgument(String rule) {
  final proxy = RegExp(r'^PROXY\s+([^;]+)', caseSensitive: false).firstMatch(rule)?.group(1);
  return proxy == null ? '--no-proxy-server' : '--proxy-server=http://$proxy';
}
