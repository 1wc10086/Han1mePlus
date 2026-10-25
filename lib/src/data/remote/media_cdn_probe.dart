import 'dart:io';

import '../../core/network/network_policy.dart';

class MediaCdnProbe {
  MediaCdnProbe._();

  static const Duration _timeout = Duration(seconds: 4);

  static Future<int?> measure(String ip) async {
    final target = ip.trim();
    if (target.isEmpty) return null;
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(target, 443, timeout: _timeout);
      final secure = await SecureSocket.secure(
        socket,
        host: kMediaBackupHost,
        onBadCertificate: (_) => true,
      ).timeout(_timeout);
      secure.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }
}
