import 'dart:convert';
import 'dart:io';

import '../../core/platform_paths.dart';

class JsonStore {
  Future<Map<String, dynamic>> read(String fileName) async {
    try {
      final file = await _file(fileName);
      if (!await file.exists()) return {};
      final value = jsonDecode(await file.readAsString());
      return value is Map<String, dynamic> ? value : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> write(String fileName, Map<String, dynamic> value) async =>
      (await _file(fileName)).writeAsString(jsonEncode(value), flush: true);

  Future<File> _file(String fileName) async {
    final directory = await appStorageDirectory();
    return File('${directory.path}/$fileName');
  }
}
