import 'dart:convert';
import 'dart:io';

class WindowsConnectionFactory {
  static var _nextAddress = 0;

  static const _addresses = {
    'hanime1.com': ['172.67.167.30', '104.21.42.221'],
    'hanime1.me': ['172.67.74.156', '104.26.8.104', '104.26.9.104'],
    'hanimeone.me': ['104.21.43.14', '172.67.215.214'],
    'javchu.com': ['104.21.7.70', '172.67.187.141'],
  };

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

  Future<ConnectionTask<Socket>> call(Uri uri, String? proxyHost, int? proxyPort) async {
    if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort ?? uri.port);
    if (useBuiltInHosts && _addresses.containsKey(uri.host)) return _connect([..._addresses[uri.host]!, uri.host], uri.port);
    if (!useDoh) return Socket.startConnect(uri.host, uri.port);
    try {
      final addresses = await _DohResolver(
        preset: dohPreset,
        customUrl: dohCustomUrl,
        bootstrapIps: dohBootstrapIps,
        timeout: Duration(seconds: dohTimeoutSeconds),
      ).resolve(uri.host);
      if (addresses.isNotEmpty) return _connect([...addresses, uri.host], uri.port);
    } catch (_) {}
    return _connect([uri.host], uri.port);
  }

  Future<ConnectionTask<Socket>> _connect(List<String> addresses, int port) async {
    final start = _nextAddress++ % addresses.length;
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var offset = 0; offset < addresses.length; offset++) {
      final address = addresses[(start + offset) % addresses.length];
      ConnectionTask<Socket>? task;
      try {
        task = await Socket.startConnect(address, port);
        await task.socket.timeout(Duration(seconds: dohTimeoutSeconds));
        return task;
      } catch (error, stackTrace) {
        task?.cancel();
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }
    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }
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
      client.connectionFactory = (uri, proxyHost, proxyPort) => Socket.startConnect(
            proxyHost ?? (uri.host == endpoint.host ? bootstrap.first : uri.host),
            proxyPort ?? uri.port,
          );
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
