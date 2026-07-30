class WindowsProxy {
  const WindowsProxy._();

  static String? rule(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();
    final proxy = raw.contains('=')
        ? raw
            .split(';')
            .map((entry) => entry.split('='))
            .where((entry) => entry.length == 2 && entry.first.toLowerCase() == 'https')
            .map((entry) => entry.last.trim())
            .firstOrNull ??
          raw.split(';').first.trim()
        : raw;
    final uri = Uri.tryParse(proxy.contains('://') ? proxy : 'http://$proxy');
    if (uri == null || uri.host.isEmpty || !uri.hasPort) return null;
    return 'PROXY ${uri.host}:${uri.port}; DIRECT';
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
