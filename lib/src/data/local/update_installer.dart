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

  Future<void> downloadAndInstall(String url, ValueChanged<double?> onProgress) async {
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
    await _dio.download(url, update.path, deleteOnError: true, onReceiveProgress: (received, total) => onProgress(total <= 0 ? null : received / total));
    if (Platform.isWindows) {
      await Process.start(update.path, const ['/CLOSEAPPLICATIONS'], mode: ProcessStartMode.detached);
      exit(0);
    }
    final result = await OpenFilex.open(update.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) throw StateError(result.message);
  }

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
