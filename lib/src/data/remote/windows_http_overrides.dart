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
    if (Platform.isMacOS) return _macosSystemProxy();
    if (Platform.isLinux) return _linuxSystemProxy();
    if (!Platform.isWindows) return 'DIRECT';
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
      ..idleTimeout = const Duration(seconds: 30);
    if (useBuiltInHosts || useDoh) {
      client.connectionFactory = WindowsConnectionFactory(
        useBuiltInHosts: useBuiltInHosts,
        useDoh: useDoh,
        dohPreset: dohPreset,
        dohCustomUrl: dohCustomUrl,
        dohBootstrapIps: dohBootstrapIps,
        dohTimeoutSeconds: dohTimeoutSeconds,
      ).call;
    }
    client.findProxy = (_) => proxy;
    if (useBuiltInHosts) {
      client.badCertificateCallback = (cert, host, port) => WindowsConnectionFactory.hanimeHosts.contains(host);
    }
    return client;
  }

  static Future<String> _linuxSystemProxy() async {
    try {
      Future<String?> setting(String schema, String key) async {
        final result = await Process.run('gsettings', ['get', schema, key]);
        if (result.exitCode != 0) return null;
        final value = result.stdout.toString().trim();
        if (value.isEmpty || value == "''") return null;
        return value.replaceAll(RegExp(r"^'|'$"), '');
      }

      final mode = await setting('org.gnome.system.proxy', 'mode');
      if (mode == null || mode == 'none' || mode == 'auto') return 'DIRECT';
      Future<String?> pair(String prefix) async {
        final host = await setting('org.gnome.system.proxy.$prefix', 'host');
        if (host == null || host.isEmpty) return null;
        final port = await setting('org.gnome.system.proxy.$prefix', 'port');
        return WindowsProxy.rule('$host:$port');
      }

      final https = await pair('https');
      if (https != null) return https;
      final http = await pair('http');
      if (http != null) return http;
      return await pair('socks') ?? 'DIRECT';
    } catch (_) {
      return 'DIRECT';
    }
  }

  static Future<String> _macosSystemProxy() async {
    try {
      final result = await Process.run('scutil', ['--proxy']);
      if (result.exitCode != 0) return 'DIRECT';
      final output = result.stdout.toString();
      String? proxyRule(String enableKey, String hostKey, String portKey) {
        if (!RegExp('$enableKey\\s*:\\s*1').hasMatch(output)) return null;
        final host = RegExp('$hostKey\\s*:\\s*(\\S+)').firstMatch(output)?.group(1);
        final port = RegExp('$portKey\\s*:\\s*(\\d+)').firstMatch(output)?.group(1);
        if (host == null || port == null) return null;
        return WindowsProxy.rule('$host:$port');
      }
      return proxyRule('HTTPSEnable', 'HTTPSProxy', 'HTTPSPort') ??
          proxyRule('HTTPEnable', 'HTTPProxy', 'HTTPPort') ??
          proxyRule('SOCKSEnable', 'SOCKSProxy', 'SOCKSPort') ??
          'DIRECT';
    } catch (_) {
      return 'DIRECT';
    }
  }
}
