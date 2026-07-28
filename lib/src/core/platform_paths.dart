import 'dart:io';

import 'package:path_provider/path_provider.dart';

const androidDefaultDownloadPath = '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

@Deprecated('Use androidDefaultDownloadPath or resolveDefaultDownloadPath()')
const defaultDownloadPath = androidDefaultDownloadPath;

bool get supportsApkUpdates => Platform.isAndroid;

bool get supportsInAppUpdateInstall => Platform.isAndroid;

bool isAndroidDownloadPath(String path) => path.startsWith('/storage/emulated/0/');

/// 程序内部数据：设置、账号、缓存索引等（Application Support）。
Future<Directory> appStorageDirectory() async {
  return getApplicationSupportDirectory();
}

/// 用户下载内容目录（Documents/Download）。
Future<Directory> downloadStorageDirectory() async {
  if (Platform.isAndroid) {
    final external = await getExternalStorageDirectory();
    if (external != null) return Directory('${external.path}/Download');
  }
  return Directory('${(await getApplicationDocumentsDirectory()).path}/Download');
}

Future<String> resolveDefaultDownloadPath() async {
  final directory = await downloadStorageDirectory();
  await directory.create(recursive: true);
  return '${directory.path}/';
}

Future<String> normalizeDownloadPath(String path) async {
  if (path.isEmpty || (Platform.isIOS && isAndroidDownloadPath(path))) {
    return resolveDefaultDownloadPath();
  }
  return path;
}

String platformDownloadPathHint(String fallbackHint) {
  if (Platform.isIOS) return '~/Documents/Download/';
  return fallbackHint;
}
