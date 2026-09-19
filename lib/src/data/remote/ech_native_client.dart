import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'ech_network_settings.dart';

class EchNativeResponse {
  const EchNativeResponse({required this.statusCode, required this.body, required this.url, required this.headers, required this.status, required this.logs});

  factory EchNativeResponse.fromJson(Map<String, dynamic> json) {
    final headers = <String, List<String>>{};
    for (final line in (json['headers'] as List<dynamic>? ?? const [])) {
      final value = line.toString();
      final separator = value.indexOf('\t');
      if (separator <= 0) continue;
      headers.putIfAbsent(value.substring(0, separator), () => []).add(value.substring(separator + 1));
    }
    return EchNativeResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      body: base64Decode(json['body'] as String? ?? ''),
      url: json['url'] as String? ?? '',
      headers: headers,
      status: json['echStatus'] as String? ?? 'unavailable',
      logs: List<String>.from(json['echLogs'] as List<dynamic>? ?? const []),
    );
  }

  final int statusCode;
  final Uint8List body;
  final String url;
  final Map<String, List<String>> headers;
  final String status;
  final List<String> logs;
}

class EchNativeClient {
  static final _logs = <String>[];

  static bool get supportsCurrentPlatform => Platform.isIOS || Platform.isMacOS || Platform.isWindows;

  static Future<bool> isAvailable() async {
    if (!supportsCurrentPlatform) return false;
    return Isolate.run(() {
      try {
        return _EchBindings.open().isSupported() == 1;
      } catch (_) {
        return false;
      }
    });
  }

  static List<String> logs() => List.unmodifiable(_logs.reversed);

  static void clearLogs() => _logs.clear();

  static Future<EchNativeResponse?> request({required String method, required String url, required Map<String, String> headers, required Uint8List body, required EchNetworkSettings settings}) async {
    if (!settings.enabled || !supportsCurrentPlatform) return null;
    try {
      final response = await Isolate.run(() => _execute(method, url, headers, body, settings));
      _appendLogs(response.logs);
      if (response.statusCode == 0) throw HttpException(response.logs.lastOrNull ?? 'ECH request failed', uri: Uri.tryParse(url));
      return response;
    } catch (error) {
      _appendLogs(['Native ECH unavailable: $error']);
      return null;
    }
  }

  static EchNativeResponse _execute(String method, String url, Map<String, String> headers, Uint8List body, EchNetworkSettings settings) {
    final bindings = _EchBindings.open();
    final methodPointer = method.toNativeUtf8();
    final urlPointer = url.toNativeUtf8();
    final dohPointer = settings.dohUrl.toNativeUtf8();
    final resolvePointer = settings.dohResolve.toNativeUtf8();
    final headerValues = headers.entries.map((entry) => '${entry.key}: ${entry.value}'.toNativeUtf8()).toList();
    final headerPointers = calloc<Pointer<Utf8>>(headerValues.length);
    final bodyPointer = body.isEmpty ? nullptr : calloc<Uint8>(body.length);
    try {
      for (var index = 0; index < headerValues.length; index++) headerPointers[index] = headerValues[index];
      if (body.isNotEmpty) bodyPointer.asTypedList(body.length).setAll(0, body);
      final result = bindings.request(methodPointer, urlPointer, headerPointers, headerValues.length, bodyPointer, body.length, dohPointer, resolvePointer);
      if (result == nullptr) throw const FormatException('ECH returned no response');
      try {
        return EchNativeResponse.fromJson(jsonDecode(result.cast<Utf8>().toDartString()) as Map<String, dynamic>);
      } finally {
        bindings.free(result.cast());
      }
    } finally {
      calloc.free(methodPointer);
      calloc.free(urlPointer);
      calloc.free(dohPointer);
      calloc.free(resolvePointer);
      for (final value in headerValues) calloc.free(value);
      calloc.free(headerPointers);
      if (bodyPointer != nullptr) calloc.free(bodyPointer);
    }
  }

  static void _appendLogs(List<String> logs) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.addAll(logs.map((log) => '$timestamp  $log'));
    if (_logs.length > 100) _logs.removeRange(0, _logs.length - 100);
  }
}

typedef _RequestNative = Pointer<Char> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Pointer<Utf8>>, Size, Pointer<Uint8>, Size, Pointer<Utf8>, Pointer<Utf8>);
typedef _RequestDart = Pointer<Char> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Pointer<Utf8>>, int, Pointer<Uint8>, int, Pointer<Utf8>, Pointer<Utf8>);

class _EchBindings {
  _EchBindings(this.library)
      : request = library.lookupFunction<_RequestNative, _RequestDart>('ech_request'),
        free = library.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('ech_free'),
        isSupported = library.lookupFunction<Int32 Function(), int Function()>('ech_is_supported');

  factory _EchBindings.open() => _EchBindings(_openLibrary());

  final DynamicLibrary library;
  final _RequestDart request;
  final void Function(Pointer<Void>) free;
  final int Function() isSupported;

  static DynamicLibrary _openLibrary() {
    if (Platform.isIOS) return DynamicLibrary.process();
    if (Platform.isWindows) return DynamicLibrary.open('ech.dll');
    final executableDirectory = path.dirname(Platform.resolvedExecutable);
    final bundled = path.normalize(path.join(executableDirectory, '..', 'Frameworks', 'libech.dylib'));
    try {
      return DynamicLibrary.open(bundled);
    } catch (_) {
      return DynamicLibrary.open('libech.dylib');
    }
  }
}
