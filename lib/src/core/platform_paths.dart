import 'dart:io';

import 'package:path_provider/path_provider.dart';

const androidDefaultDownloadPath = '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

bool isAndroidDownloadPath(String path) => path.startsWith('/storage/emulated/0/');

Future<Directory> appStorageDirectory() => getApplicationSupportDirectory();

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

String platformDownloadPathHint(String fallbackHint) =>
    Platform.isIOS ? '~/Documents/Download/' : fallbackHint;
