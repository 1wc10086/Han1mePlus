import 'dart:io';

import 'windows_connection_factory.dart';
import 'windows_proxy.dart';

class WindowsHttpOverrides extends HttpOverrides {
  WindowsHttpOverrides({
    required this.proxy,
    required this.useBuiltInHosts,
    required this.useDoh,
    required this.dohPreset,
    required this.dohCustomUrl,
    required this.dohBootstrapIps,
    required this.dohTimeoutSeconds,
  });

  final String proxy;
  final bool useBuiltInHosts;
  final bool useDoh;
  final String dohPreset;
  final String dohCustomUrl;
  final String dohBootstrapIps;
  final int dohTimeoutSeconds;

  static Future<String> systemProxy() async {
    final environmentProxy = Platform.environment['HTTPS_PROXY'] ??
        Platform.environment['https_proxy'] ??
        Platform.environment['HTTP_PROXY'] ??
        Platform.environment['http_proxy'];
    final environmentRule = WindowsProxy.rule(environmentProxy);
    if (environmentRule != null) return environmentRule;
    try {
      final enabledResult = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyEnable',
      ]);
      final enabled = enabledResult.exitCode == 0 &&
          RegExp(r'ProxyEnable\s+REG_DWORD\s+0x1', caseSensitive: false)
              .hasMatch(enabledResult.stdout.toString());
      if (!enabled) return 'DIRECT';
      final serverResult = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        'ProxyServer',
      ]);
      final value = RegExp(r'ProxyServer\s+REG_SZ\s+(.+)', caseSensitive: false)
          .firstMatch(serverResult.stdout.toString())
          ?.group(1)
          ?.trim();
      return WindowsProxy.rule(value) ?? 'DIRECT';
    } catch (_) {
      return 'DIRECT';
    }
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 30)
      ..connectionFactory = WindowsConnectionFactory(
        useBuiltInHosts: useBuiltInHosts,
        useDoh: useDoh,
        dohPreset: dohPreset,
        dohCustomUrl: dohCustomUrl,
        dohBootstrapIps: dohBootstrapIps,
        dohTimeoutSeconds: dohTimeoutSeconds,
      ).call;
    client.findProxy = (_) => proxy;
    return client;
  }
}
