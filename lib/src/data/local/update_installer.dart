import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform_paths.dart';

class UpdateInstaller {
  UpdateInstaller(this._dio);
  final Dio _dio;

  Future<void> removeStaleApk() async {
    if (!Platform.isAndroid) return;
    final directory = await getExternalStorageDirectory();
    if (directory == null) return;
    final file = File('${directory.path}/updates/han1me-plus-update.apk');
    if (await file.exists()) await file.delete();
  }

  Future<void> downloadAndInstall(String url, ValueChanged<double?> onProgress) async {
    if (Platform.isIOS) {
      await installOnIos(url);
      return;
    }
    final directory = await getExternalStorageDirectory();
    if (directory == null) throw StateError('Update directory is unavailable');
    final updateDirectory = Directory('${directory.path}/updates');
    await updateDirectory.create(recursive: true);
    final apk = File('${updateDirectory.path}/han1me-plus-update.apk');
    await _dio.download(url, apk.path, deleteOnError: true, onReceiveProgress: (received, total) => onProgress(total <= 0 ? null : received / total));
    final result = await OpenFilex.open(apk.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) throw StateError(result.message);
  }

  Future<void> installOnIos(String url) async {
    final target = url.trim().isEmpty ? Uri.parse('https://github.com/1wc10086/Han1mePlus/releases/latest') : Uri.parse(url);
    if (!await launchUrl(target, mode: LaunchMode.externalApplication)) {
      throw StateError('Unable to open update URL');
    }
  }
}
