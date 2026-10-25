import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import '../../../data/remote/ech/ech_static_client.dart';

class DebugLogState {
  const DebugLogState({this.entries = const [], this.engineLogs = const []});

  final List<AppLogEntry> entries;
  final List<String> engineLogs;
}

final debugLogProvider = NotifierProvider<DebugLogController, DebugLogState>(DebugLogController.new);

class DebugLogController extends Notifier<DebugLogState> {
  StreamSubscription<AppLogEntry?>? _subscription;

  @override
  DebugLogState build() {
    _subscription = AppLog.changes.listen((_) => state = _snapshot());
    ref.onDispose(() => _subscription?.cancel());
    return _snapshot();
  }

  DebugLogState _snapshot() => DebugLogState(
        entries: AppLog.entries,
        engineLogs: EchStaticClient.instance?.logs ?? const [],
      );

  void refresh() => state = _snapshot();

  void clear() {
    AppLog.clear();
    refresh();
  }

  String export() => AppLog.export(engineLogs: EchStaticClient.instance?.logs);
}
