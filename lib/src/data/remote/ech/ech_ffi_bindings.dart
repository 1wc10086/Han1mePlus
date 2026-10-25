import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

const int kEchEventHeaders = 1;
const int kEchEventBody = 2;
const int kEchEventComplete = 3;
const int kEchEventError = 4;

final class _NativeClient extends Opaque {}

final class _NativeRequest extends Opaque {}

final class _NativeOptions extends Struct {
  external Pointer<Utf8> url;
  external Pointer<Utf8> method;
  external Pointer<Utf8> headers;
  external Pointer<Utf8> proxy;
  external Pointer<Utf8> echConfig;
  external Pointer<Utf8> connectIp;
  external Pointer<Utf8> caPem;
  external Pointer<Uint8> body;
  @Size()
  external int bodyLength;
  @Int64()
  external int timeoutMs;
  @Int64()
  external int connectTimeoutMs;
  @Int64()
  external int maxResponseBytes;
}

final class _NativeEvent extends Struct {
  @Int32()
  external int type;
  @Int32()
  external int code;
  @Int32()
  external int echAccepted;
  @Int32()
  external int echRetries;
  @Size()
  external int length;
  external Pointer<Uint8> data;
}

class EchNativeResponse {
  const EchNativeResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.echAccepted,
    required this.echRetries,
    required this.errorMessage,
    required this.nativeCode,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Uint8List body;
  final bool echAccepted;
  final int echRetries;
  final String? errorMessage;
  final int? nativeCode;

  bool get isRedirect => const {301, 302, 303, 307, 308}.contains(statusCode);
}

class EchFfiClient {
  EchFfiClient._(this._client);

  final Pointer<_NativeClient> _client;
  bool _closed = false;

  static DynamicLibrary? _lib;
  static bool _loadAttempted = false;
  static bool _available = false;

  static DynamicLibrary? _load() {
    if (_loadAttempted) return _lib;
    _loadAttempted = true;
    final candidates = Platform.isAndroid
        ? const ['libech_http.so']
        : const ['libech_http.so', 'ech_http.dll', 'libech_http.dylib'];
    for (final name in candidates) {
      try {
        _lib = DynamicLibrary.open(name);
        return _lib;
      } catch (_) {}
    }
    return null;
  }

  static bool get isAvailable {
    if (_available) return true;
    final library = _load();
    if (library == null) return false;
    try {
      final version = library.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('eh_version')();
      if (version == nullptr) return false;
      _available = true;
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  static EchFfiClient? tryCreate() {
    if (!isAvailable) return null;
    final library = _lib;
    if (library == null) return null;
    try {
      final create = library.lookupFunction<Pointer<_NativeClient> Function(), Pointer<_NativeClient> Function()>('eh_client_create');
      final client = create();
      if (client == nullptr) return null;
      return EchFfiClient._(client);
    } catch (_) {
      return null;
    }
  }

  Future<EchNativeResponse> request(
    String url,
    String method,
    Map<String, String> headers, {
    Uint8List? body,
    String? echConfig,
    String? connectIp,
    Duration timeout = const Duration(seconds: 30),
    Duration connectTimeout = const Duration(seconds: 10),
  }) async {
    if (_closed) throw StateError('ech client is closed');
    final library = _load();
    if (library == null) throw StateError('ech native library is unavailable');

    final start = library.lookupFunction<Pointer<_NativeRequest> Function(Pointer<_NativeClient>, Pointer<_NativeOptions>),
        Pointer<_NativeRequest> Function(Pointer<_NativeClient>, Pointer<_NativeOptions>)>('eh_request_start');
    final poll = library.lookupFunction<Pointer<_NativeEvent> Function(Pointer<_NativeRequest>),
        Pointer<_NativeEvent> Function(Pointer<_NativeRequest>)>('eh_request_poll');
    final destroy = library.lookupFunction<Void Function(Pointer<_NativeRequest>), void Function(Pointer<_NativeRequest>)>('eh_request_destroy');
    final destroyEvent = library.lookupFunction<Void Function(Pointer<_NativeEvent>), void Function(Pointer<_NativeEvent>)>('eh_event_destroy');

    final options = calloc<_NativeOptions>();
    Pointer<Utf8>? urlPointer;
    Pointer<Utf8>? methodPointer;
    Pointer<Utf8>? headersPointer;
    Pointer<Utf8>? echPointer;
    Pointer<Utf8>? ipPointer;
    Pointer<Uint8>? bodyPointer;
    Pointer<_NativeRequest>? request;
    try {
      urlPointer = url.toNativeUtf8();
      methodPointer = method.toNativeUtf8();
      headersPointer = headers.entries.map((entry) => '${entry.key}: ${entry.value}').join('\r\n').toNativeUtf8();
      echPointer = echConfig == null || echConfig.isEmpty ? nullptr : echConfig.toNativeUtf8();
      ipPointer = connectIp == null || connectIp.isEmpty ? nullptr : connectIp.toNativeUtf8();
      bodyPointer = body == null || body.isEmpty ? nullptr : calloc<Uint8>(body.length);
      if (bodyPointer != nullptr && body != null) {
        bodyPointer.asTypedList(body.length).setAll(0, body);
      }

      options.ref
        ..url = urlPointer
        ..method = methodPointer
        ..headers = headersPointer
        ..proxy = nullptr
        ..echConfig = echPointer ?? nullptr
        ..connectIp = ipPointer ?? nullptr
        ..caPem = nullptr
        ..body = bodyPointer ?? nullptr
        ..bodyLength = body?.length ?? 0
        ..timeoutMs = timeout.inMilliseconds
        ..connectTimeoutMs = connectTimeout.inMilliseconds
        ..maxResponseBytes = 32 * 1024 * 1024;

      request = start(_client, options);
      if (request == nullptr) throw StateError('eh_request_start failed');

      final deadline = DateTime.now().add(timeout);
      Map<String, String>? headerMap;
      final chunks = <Uint8List>[];
      var statusCode = 0;
      var echAccepted = false;
      var echRetries = 0;

      while (true) {
        if (DateTime.now().isAfter(deadline)) throw StateError('ech request timed out');
        final event = poll(request);
        if (event == nullptr) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          continue;
        }
        try {
          final value = event.ref;
          final data = value.length == 0 ? Uint8List(0) : Uint8List.fromList(value.data.asTypedList(value.length));
          switch (value.type) {
            case kEchEventHeaders:
              statusCode = value.code;
              echAccepted = value.echAccepted != 0;
              echRetries = value.echRetries;
              headerMap = _parseHeaders(latin1.decode(data));
            case kEchEventBody:
              chunks.add(data);
            case kEchEventComplete:
              return EchNativeResponse(
                statusCode: statusCode,
                headers: headerMap ?? const {},
                body: _join(chunks),
                echAccepted: echAccepted,
                echRetries: echRetries,
                errorMessage: null,
                nativeCode: null,
              );
            case kEchEventError:
              return EchNativeResponse(
                statusCode: statusCode,
                headers: headerMap ?? const {},
                body: _join(chunks),
                echAccepted: echAccepted,
                echRetries: echRetries,
                errorMessage: utf8.decode(data, allowMalformed: true),
                nativeCode: value.code,
              );
          }
        } finally {
          destroyEvent(event);
        }
      }
    } finally {
      if (request != null) destroy(request);
      if (bodyPointer != null) calloc.free(bodyPointer);
      if (ipPointer != null) malloc.free(ipPointer);
      if (echPointer != null) malloc.free(echPointer);
      if (headersPointer != null) malloc.free(headersPointer);
      if (methodPointer != null) malloc.free(methodPointer);
      if (urlPointer != null) malloc.free(urlPointer);
      calloc.free(options);
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    final library = _load();
    if (library == null) return;
    final destroy = library.lookupFunction<Void Function(Pointer<_NativeClient>), void Function(Pointer<_NativeClient>)>('eh_client_destroy');
    destroy(_client);
  }

  static Map<String, String> _parseHeaders(String raw) {
    final headers = <String, String>{};
    for (final line in raw.split(RegExp(r'\r?\n')).skip(1)) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final key = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      headers.update(key, (previous) => '$previous\n$value', ifAbsent: () => value);
    }
    return headers;
  }

  static Uint8List _join(List<Uint8List> chunks) {
    if (chunks.isEmpty) return Uint8List(0);
    final length = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(length);
    var offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }
}
