import 'dart:async';

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

  String get timestampLabel {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(timestamp.month)}-${two(timestamp.day)} '
        '${two(timestamp.hour)}:${two(timestamp.minute)}:${two(timestamp.second)}';
  }

  String get displayLine {
    final request = method == null ? message : '$method $url';
    final status = statusCode == null ? '' : ' -> $statusCode';
    final elapsed = durationMs == null ? '' : ' (${durationMs}ms)';
    final detail = method == null ? '' : ' [$message]';
    return '$timestampLabel $request$status$elapsed$detail';
  }
}

class AppLog {
  AppLog._();

  static const int _capacity = 800;
  static final List<AppLogEntry> _entries = <AppLogEntry>[];
  static final StreamController<AppLogEntry?> _changes = StreamController<AppLogEntry?>.broadcast();

  static Stream<AppLogEntry?> get changes => _changes.stream;

  static List<AppLogEntry> get entries => List<AppLogEntry>.unmodifiable(_entries);

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
    if (_entries.length > _capacity) {
      _entries.removeRange(0, _entries.length - _capacity);
    }
    if (_changes.hasListener) _changes.add(entry);
  }

  static void clear() {
    _entries.clear();
    if (_changes.hasListener) _changes.add(null);
  }

  static String export({List<String>? engineLogs}) {
    final buffer = StringBuffer()
      ..writeln('Han1me+ diagnostics')
      ..writeln('exported: ${DateTime.now().toIso8601String()}')
      ..writeln('entries: ${_entries.length}')
      ..writeln('--- requests ---');
    for (final entry in _entries) {
      buffer.writeln(entry.displayLine);
    }
    final logs = engineLogs ?? const <String>[];
    if (logs.isNotEmpty) {
      buffer.writeln('--- ech engine ---');
      for (final line in logs.take(200)) {
        buffer.writeln(line);
      }
    }
    return buffer.toString();
  }
}
