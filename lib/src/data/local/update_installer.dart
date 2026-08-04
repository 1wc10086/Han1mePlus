import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInstaller {
  UpdateInstaller(this._dio);
  final Dio _dio;

  Future<void> removeStaleUpdate() async {
    if (!Platform.isAndroid && !Platform.isWindows) return;
    try {
      final file = await _updateFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> downloadAndInstall(String url, ValueChanged<double?> onProgress, {bool useMirror = true}) async {
    final uri = Uri.tryParse(url.trim());
    final supportedAsset = Platform.isAndroid && path.extension(uri?.path ?? '').toLowerCase() == '.apk' ||
        Platform.isWindows && path.extension(uri?.path ?? '').toLowerCase() == '.exe';
    if (!supportedAsset) {
      final target = Uri.parse(url.trim().isEmpty ? 'https://github.com/1wc10086/Han1mePlus/releases/latest' : url);
      if (!await launchUrl(target, mode: LaunchMode.externalApplication)) {
        throw StateError('Unable to open update URL');
      }
      return;
    }
    final update = await _updateFile();
    await update.parent.create(recursive: true);
    final sources = [url, if (useMirror) ..._updateMirrors.map((mirror) => '$mirror$url')];
    Object? lastError;
    for (final source in sources) {
      try {
        await _dio.download(source, update.path, deleteOnError: true, options: Options(validateStatus: (status) => status != null && status >= 200 && status < 300), onReceiveProgress: (received, total) => onProgress(total <= 0 ? null : received / total));
        lastError = null;
        break;
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) throw lastError;
    if (Platform.isWindows) {
      await Process.start(update.path, const ['/CLOSEAPPLICATIONS'], mode: ProcessStartMode.detached);
      exit(0);
    }
    final result = await OpenFilex.open(update.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) throw StateError(result.message);
  }

  static const _updateMirrors = [
    'https://gh-proxy.org/',
    'https://v4.gh-proxy.org/',
    'https://v6.gh-proxy.org/',
    'https://cdn.gh-proxy.org/',
  ];

  Future<File> _updateFile() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw StateError('Update directory is unavailable');
      return File(path.join(directory.path, 'updates', 'han1me-plus-update.apk'));
    }
    final directory = await getTemporaryDirectory();
    return File(path.join(directory.path, 'Han1mePlus', 'updates', 'Han1mePlus-Setup.exe'));
  }
}
