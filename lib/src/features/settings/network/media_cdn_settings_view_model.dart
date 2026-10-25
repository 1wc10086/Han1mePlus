import 'package:flutter/foundation.dart';

import '../../../core/network/media_cdn.dart';
import '../../../data/remote/media_cdn_probe.dart';

enum MediaCdnProbeStatus { idle, running, reachable, unreachable }

class MediaCdnSettings {
  const MediaCdnSettings({required this.region, required this.customIp});

  final String region;
  final String customIp;
}

class MediaCdnSettingsViewModel extends ChangeNotifier {
  MediaCdnSettingsViewModel({
    required String region,
    required String customIp,
  })  : _region = region,
        _customIp = customIp;

  String _region;
  String _customIp;
  final Map<String, int?> _latencies = <String, int?>{};
  bool _measuring = false;
  bool _disposed = false;
  MediaCdnProbeStatus _customStatus = MediaCdnProbeStatus.idle;
  int? _customLatency;

  String get region => _region;
  String get customIp => _customIp;
  bool get measuring => _measuring;
  MediaCdnProbeStatus get customStatus => _customStatus;
  int? get customLatency => _customLatency;
  int? latencyFor(String regionId) => _latencies[regionId];

  void selectRegion(String value) {
    if (_region == value) return;
    _region = value;
    _notify();
  }

  void updateCustomIp(String value) {
    if (_customIp == value) return;
    _customIp = value;
    _notify();
  }

  Future<void> measureAll() async {
    if (_measuring) return;
    _measuring = true;
    _notify();
    await Future.wait(
      mediaCdnRegions.map((region) async {
        final node = region.nodes.firstOrNull;
        if (node == null) return;
        _latencies[region.id] = await MediaCdnProbe.measure(node);
      }),
    );
    if (_disposed) return;
    _measuring = false;
    _notify();
  }

  Future<void> measureCustom() async {
    final target = _firstIp(_customIp);
    if (target == null || _customStatus == MediaCdnProbeStatus.running) return;
    _customStatus = MediaCdnProbeStatus.running;
    _notify();
    final latency = await MediaCdnProbe.measure(target);
    if (_disposed) return;
    _customLatency = latency;
    _customStatus = latency == null ? MediaCdnProbeStatus.unreachable : MediaCdnProbeStatus.reachable;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  MediaCdnSettings toSettings() => MediaCdnSettings(region: _region, customIp: _customIp.trim());

  String? _firstIp(String value) => value
      .split(RegExp(r'[,;\s]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .firstOrNull;
}
