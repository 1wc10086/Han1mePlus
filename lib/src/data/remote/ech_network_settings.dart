import 'dart:io';

class EchNetworkSettings {
  const EchNetworkSettings({
    required this.enabled,
    required this.dohPreset,
    required this.dohCustomUrl,
    required this.dohBootstrapIps,
  });

  const EchNetworkSettings.disabled()
      : enabled = false,
        dohPreset = 'cloudflare',
        dohCustomUrl = '',
        dohBootstrapIps = '';

  final bool enabled;
  final String dohPreset;
  final String dohCustomUrl;
  final String dohBootstrapIps;

  String get dohUrl => switch (dohPreset) {
        'alidns' => 'https://dns.alidns.com/dns-query',
        'dnspod' => 'https://doh.pub/dns-query',
        'custom' when dohCustomUrl.trim().isNotEmpty => dohCustomUrl.trim(),
        _ => 'https://cloudflare-dns.com/dns-query',
      };

  String get dohResolve {
    final uri = Uri.parse(dohUrl);
    final addresses = dohBootstrapIps
        .split(RegExp(r'[,;\s]+'))
        .map((value) => value.trim())
        .where((value) => InternetAddress.tryParse(value) != null)
        .map((value) => value.contains(':') ? '[$value]' : value)
        .toList();
    if (addresses.isEmpty) return '';
    return '${uri.host}:${uri.hasPort ? uri.port : 443}:${addresses.join(',')}';
  }
}
