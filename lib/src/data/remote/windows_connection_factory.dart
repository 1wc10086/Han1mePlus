import 'dart:convert';
import 'dart:io';

class WindowsConnectionFactory {
  static var _nextAddress = 0;

  static const hanimeHosts = {'hanime1.me', 'hanime1.com', 'hanimeone.me', 'javchu.com'};

  /// 与 iOS / Android 原生层一致的内置 Cloudflare 边缘地址。
  static const builtInAddresses = [
    '172.64.229.154',
    '162.159.0.1',
    '108.162.192.1',
    '172.64.33.1',
    '104.19.0.1',
    '2606:4700:3035::ac43:bb8d',
    '2606:4700:3030::6815:746',
    '2606:4700:3030::6815:714',
  ];

  WindowsConnectionFactory({
    required this.useBuiltInHosts,
    required this.useDoh,
    required this.dohPreset,
    required this.dohCustomUrl,
    required this.dohBootstrapIps,
    required this.dohTimeoutSeconds,
  });

  final bool useBuiltInHosts;
  final bool useDoh;
  final String dohPreset;
  final String dohCustomUrl;
  final String dohBootstrapIps;
  final int dohTimeoutSeconds;

  Duration get _timeout => Duration(seconds: dohTimeoutSeconds);

  Future<ConnectionTask<Socket>> call(Uri uri, String? proxyHost, int? proxyPort) async {
    if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort ?? uri.port);
    final port = uri.hasPort ? uri.port : (uri.isScheme('https') ? 443 : 80);
    if (useBuiltInHosts && hanimeHosts.contains(uri.host)) {
      return _connect(uri, [...builtInAddresses, uri.host], port);
    }
    if (!useDoh) return _startConnect(uri.host, port);
    try {
      final addresses = await _DohResolver(
        preset: dohPreset,
        customUrl: dohCustomUrl,
        bootstrapIps: dohBootstrapIps,
        timeout: _timeout,
      ).resolve(uri.host);
      if (addresses.isNotEmpty) return _connect(uri, [...addresses, uri.host], port);
    } catch (_) {}
    return _connect(uri, [uri.host], port);
  }

  /// Dart 的 [HttpClient.connectionFactory] 只建立 TCP，不会自动 TLS。
  /// HTTPS 必须在此手动 [SecureSocket.secure]，否则会向 443 端口发送明文 HTTP 并收到 400。
  Future<ConnectionTask<Socket>> _connect(Uri uri, List<String> addresses, int port) async {
    final allowBadCertificate = useBuiltInHosts && hanimeHosts.contains(uri.host);
    final start = _nextAddress++ % addresses.length;
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var offset = 0; offset < addresses.length; offset++) {
      final address = addresses[(start + offset) % addresses.length];
      Socket? plain;
      try {
        if (address == uri.host) return _startConnect(uri.host, port);
        plain = await Socket.connect(address, port, timeout: _timeout);
        final secure = await SecureSocket.secure(
          plain,
          host: uri.host,
          onBadCertificate: allowBadCertificate ? (_) => true : null,
        );
        return ConnectionTask.fromSocket(Future.value(secure), secure.destroy);
      } catch (error, stackTrace) {
        plain?.destroy();
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }
    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  Future<ConnectionTask<Socket>> _startConnect(String host, int port) => SecureSocket.startConnect(host, port);
}

class _DohResolver {
  static final _cache = <String, _CachedAddresses>{};

  const _DohResolver({
    required this.preset,
    required this.customUrl,
    required this.bootstrapIps,
    required this.timeout,
  });

  final String preset;
  final String customUrl;
  final String bootstrapIps;
  final Duration timeout;

  Future<List<String>> resolve(String host) async {
    final endpoint = _endpoint;
    if (endpoint == null) return const [];
    final key = '$endpoint:$host';
    final cached = _cache[key];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) return cached.addresses;
    final answers = await Future.wait([_query(endpoint, host, 'A'), _query(endpoint, host, 'AAAA')]);
    final addresses = answers.expand((answer) => answer).toSet().toList(growable: false);
    if (addresses.isNotEmpty) _cache[key] = _CachedAddresses(addresses, DateTime.now().add(const Duration(minutes: 5)));
    return addresses;
  }

  Uri? get _endpoint => switch (preset) {
        'alidns' => Uri.parse('https://dns.alidns.com/dns-query'),
        'dnspod' => Uri.parse('https://doh.pub/dns-query'),
        'cloudflare' => Uri.parse('https://cloudflare-dns.com/dns-query'),
        'custom' => Uri.tryParse(customUrl.trim()),
        _ => null,
      };

  Future<List<String>> _query(Uri endpoint, String host, String type) async {
    final client = HttpClient()..connectionTimeout = timeout;
    final bootstrap = _bootstrapIps;
    if (bootstrap.isNotEmpty) {
      client.connectionFactory = (uri, proxyHost, proxyPort) async {
        if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort ?? uri.port);
        if (uri.host != endpoint.host) return SecureSocket.startConnect(uri.host, uri.port);
        final plain = await Socket.connect(bootstrap.first, uri.port, timeout: timeout);
        try {
          final secure = await SecureSocket.secure(plain, host: uri.host);
          return ConnectionTask.fromSocket(Future.value(secure), secure.destroy);
        } catch (error) {
          plain.destroy();
          rethrow;
        }
      };
    }
    try {
      final request = await client.getUrl(endpoint.replace(queryParameters: {'name': host, 'type': type}));
      request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) return const [];
      final json = jsonDecode(await utf8.decoder.bind(response).join());
      if (json is! Map) return const [];
      return (json['Answer'] as List? ?? const [])
          .whereType<Map>()
          .map((answer) => answer['data'])
          .whereType<String>()
          .where((address) => InternetAddress.tryParse(address) != null)
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  List<String> get _bootstrapIps {
    final values = bootstrapIps.split(RegExp(r'[,;\s]+')).where((value) => InternetAddress.tryParse(value) != null).toList();
    if (values.isNotEmpty) return values;
    return switch (preset) {
      'alidns' => const ['223.5.5.5', '223.6.6.6'],
      'dnspod' => const ['1.12.12.12', '120.53.53.53'],
      'cloudflare' => const ['1.1.1.1', '1.0.0.1'],
      _ => const [],
    };
  }
}

class _CachedAddresses {
  const _CachedAddresses(this.addresses, this.expiresAt);

  final List<String> addresses;
  final DateTime expiresAt;
}
