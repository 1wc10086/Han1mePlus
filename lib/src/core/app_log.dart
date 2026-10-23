import 'dart:async';

/// 全局诊断日志收集器（内存环形缓冲）。
///
/// 供调试日志页使用：点击“关于”页版本号 5 次进入，可复制 / 分享 / 清空。
/// 日志条目轻量：只记时间、通道、请求行、状态码、耗时与关键备注，
/// 不缓存响应体，避免内存与隐私问题。
class AppLog {
  AppLog._();

  static const int _maxEntries = 800;
  static final List<AppLogEntry> _entries = [];
  static final List<StreamController<AppLogEntry>> _listeners = [];

  /// 记录一条日志（线程安全：同步追加，UI 侧定时快照）。
  static void log(
    String message, {
    String? method,
    String? url,
    int? statusCode,
    int? durationMs,
  }) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      message: message,
      method: method,
      url: url,
      statusCode: statusCode,
      durationMs: durationMs,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    for (final controller in _listeners) {
      if (controller.hasListener) controller.add(entry);
    }
  }

  static void clear() {
    _entries.clear();
    for (final controller in _listeners) {
      if (controller.hasListener) controller.addError(StateError('cleared'));
    }
  }

  static List<AppLogEntry> get entries => List.unmodifiable(_entries);

  /// 导出为可分享的纯文本（含 ECH 引擎侧日志）。
  static String export({List<String>? echLogs}) {
    final buffer = StringBuffer();
    buffer.writeln('=== Han1me+ 诊断日志 ===');
    buffer.writeln('导出时间: ${_fmt(DateTime.now())}');
    buffer.writeln('条目数: ${_entries.length}');
    buffer.writeln('--- 请求日志 ---');
    for (final entry in _entries) {
      buffer.writeln(_fmt(entry.timestamp) +
          ' ${entry.method ?? ''} ${entry.url ?? entry.message}'
          '${entry.statusCode != null ? ' -> ${entry.statusCode}' : ''}'
          '${entry.durationMs != null ? ' (${entry.durationMs}ms)' : ''}'
          '${entry.message.startsWith('[') ? '' : ' [${entry.message}]'}');
    }
    final logs = echLogs ?? const <String>[];
    if (logs.isNotEmpty) {
      buffer.writeln('--- ECH 引擎日志 ---');
      for (final line in logs.take(200)) {
        buffer.writeln(line);
      }
    }
    return buffer.toString();
  }

  static String _fmt(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.message,
    this.method,
    this.url,
    this.statusCode,
    this.durationMs,
  });

  final DateTime timestamp;
  final String message;
  final String? method;
  final String? url;
  final int? statusCode;
  final int? durationMs;
}
