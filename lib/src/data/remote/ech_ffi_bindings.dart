// 直接绑定 ech_http 原生引擎（libcurl + BoringSSL）的 C ABI。
// 不依赖 Dart build hooks / code_assets：.so 由 jniLibs（Android）或系统库路径提供，
// 这里用 DynamicLibrary.open + lookupFunction 手动绑定，构建链路最稳。
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// 原生事件类型。
const int _kEventHeaders = 1;
const int _kEventBody = 2;
const int _kEventComplete = 3;
const int _kEventError = 4;

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

final class EchNativeResponse {
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
}

/// 原生引擎句柄（EchClient 等价物）。
class EchFfiClient {
  EchFfiClient._(this._client);

  final Pointer<_NativeClient> _client;
  bool _closed = false;

  static bool _libReady = false;

  static final DynamicLibrary _lib = () {
    // Android：Flutter 会从 jniLibs 打包 libech_http.so
    // 桌面：尝试同目录 / 系统路径
    if (Platform.isAndroid) return DynamicLibrary.open('libech_http.so');
    final candidates = [
      'libech_http.so',
      'ech_http.dll',
      'libech_http.dylib',
    ];
    for (final name in candidates) {
      try {
        return DynamicLibrary.open(name);
      } catch (_) {}
    }
    throw StateError('ech_http native library not found');
  }();

  static bool get isAvailable {
    if (!_libReady) {
      try {
        // 触发一次符号解析，确认库可用
        final fn = _lib
            .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
          'eh_version',
        );
        final version = fn();
        if (version == nullptr) return false;
        _libReady = true;
      } catch (_) {
        return false;
      }
    }
    return _libReady;
  }

  static EchFfiClient? tryCreate() {
    if (!isAvailable) return null;
    try {
      final create = _lib.lookupFunction<
        Pointer<_NativeClient> Function(),
        Pointer<_NativeClient> Function()
      >('eh_client_create');
      final client = create();
      if (client == nullptr) return null;
      return EchFfiClient._(client);
    } catch (_) {
      return null;
    }
  }

  /// 执行一次请求（内部轮询原生事件直到完成或超时）。
  /// 异步实现：FFI 单次 poll 很快返回，空队列时让出事件循环，不阻塞 UI。
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
    if (_closed) throw StateError('ech_http client is closed');
    final startFn = _lib.lookupFunction<
      Pointer<_NativeRequest> Function(Pointer<_NativeClient>, Pointer<_NativeOptions>),
      Pointer<_NativeRequest> Function(Pointer<_NativeClient>, Pointer<_NativeOptions>)
    >('eh_request_start');
    final pollFn = _lib.lookupFunction<
      Pointer<_NativeEvent> Function(Pointer<_NativeRequest>),
      Pointer<_NativeEvent> Function(Pointer<_NativeRequest>)
    >('eh_request_poll');
    final destroyFn = _lib.lookupFunction<
      Void Function(Pointer<_NativeRequest>),
      Void Function(Pointer<_NativeRequest>)
    >('eh_request_destroy');
    final eventDestroyFn = _lib.lookupFunction<
      Void Function(Pointer<_NativeEvent>),
      Void Function(Pointer<_NativeEvent>)
    >('eh_event_destroy');

    final options = calloc<_NativeOptions>();
    Pointer<Utf8>? urlPtr, methodPtr, headersPtr, echPtr, ipPtr;
    Pointer<Uint8>? bodyPtr;
    Pointer<_NativeRequest>? request;
    try {
      urlPtr = url.toNativeUtf8();
      methodPtr = method.toNativeUtf8();
      final headerLines = headers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\r\n');
      headersPtr = headerLines.toNativeUtf8();
      echPtr = (echConfig != null && echConfig.isNotEmpty)
          ? echConfig.toNativeUtf8()
          : nullptr;
      ipPtr = (connectIp != null && connectIp.isNotEmpty)
          ? connectIp.toNativeUtf8()
          : nullptr;
      bodyPtr = (body != null && body.isNotEmpty)
          ? calloc<Uint8>(body.length)
          : nullptr;
      if (bodyPtr != nullptr && body != null) {
        bodyPtr.asTypedList(body.length).setAll(0, body);
      }

      options.ref
        ..url = urlPtr
        ..method = methodPtr
        ..headers = headersPtr
        ..proxy = nullptr
        ..echConfig = echPtr
        ..connectIp = ipPtr
        ..caPem = nullptr
        ..body = bodyPtr
        ..bodyLength = body?.length ?? 0
        ..timeoutMs = timeout.inMilliseconds
        ..connectTimeoutMs = connectTimeout.inMilliseconds
        ..maxResponseBytes = 32 * 1024 * 1024;

      request = startFn(_client, options);
      if (request == nullptr) {
        throw StateError('eh_request_start failed');
      }

      final deadline = DateTime.now().add(timeout);
      Map<String, String>? headersMap;
      final bodyChunks = <Uint8List>[];
      var statusCode = 0;
      var echAccepted = false;
      var echRetries = 0;
      String? errorMessage;
      int? nativeCode;

      while (true) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('ech_http request timed out');
        }
        final event = pollFn(request);
        if (event == nullptr) {
          // 原生 worker 线程仍在工作，让出事件循环（不阻塞 UI isolate）
          await Future<void>.delayed(const Duration(milliseconds: 5));
          continue;
        }
        try {
          final value = event.ref;
          final data = value.length == 0
              ? Uint8List(0)
              : Uint8List.fromList(value.data.asTypedList(value.length));
          switch (value.type) {
            case _kEventHeaders:
              statusCode = value.code;
              echAccepted = value.echAccepted != 0;
              echRetries = value.echRetries;
              headersMap = _parseHeaders(latin1.decode(data));
            case _kEventBody:
              bodyChunks.add(data);
            case _kEventComplete:
              return EchNativeResponse(
                statusCode: statusCode,
                headers: headersMap ?? const {},
                body: _join(bodyChunks),
                echAccepted: echAccepted,
                echRetries: echRetries,
                errorMessage: null,
                nativeCode: null,
              );
            case _kEventError:
              errorMessage = utf8.decode(data, allowMalformed: true);
              nativeCode = value.code;
              return EchNativeResponse(
                statusCode: statusCode,
                headers: headersMap ?? const {},
                body: _join(bodyChunks),
                echAccepted: echAccepted,
                echRetries: echRetries,
                errorMessage: errorMessage,
                nativeCode: nativeCode,
              );
          }
        } finally {
          eventDestroyFn(event);
        }
      }
    } finally {
      if (request != nullptr) destroyFn(request);
      if (bodyPtr != nullptr) calloc.free(bodyPtr);
      if (ipPtr != nullptr) malloc.free(ipPtr);
      if (echPtr != nullptr) malloc.free(echPtr);
      if (headersPtr != nullptr) malloc.free(headersPtr);
      if (methodPtr != nullptr) malloc.free(methodPtr);
      if (urlPtr != nullptr) malloc.free(urlPtr);
      calloc.free(options);
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    final destroy = _lib.lookupFunction<
      Void Function(Pointer<_NativeClient>),
      Void Function(Pointer<_NativeClient>)
    >('eh_client_destroy');
    destroy(_client);
  }

  static Map<String, String> _parseHeaders(String raw) {
    final lines = raw.split('\r\n');
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final key = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      headers.update(
        key,
        (previous) => '$previous, $value',
        ifAbsent: () => value,
      );
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
