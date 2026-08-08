import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/platform_service.dart';
import '../../core/settings.dart';
import '../../domain/models/download.dart';
import 'download_repository.dart';
import 'json_store.dart';
import 'library_repository.dart';
import 'watch_repository.dart';

class BackupBundle {
  const BackupBundle({required this.settings, required this.watch, required this.library, required this.downloads, required this.keyframes, required this.checkIns});

  final AppSettings settings;
  final WatchState watch;
  final LibraryState library;
  final DownloadState downloads;
  final Map<String, dynamic> keyframes;
  final Map<String, dynamic> checkIns;
}

class BackupService {
  BackupService(this._store);

  final JsonStore _store;

  Future<bool> export(BackupBundle bundle) async {
    final archive = Archive()
      ..addFile(_jsonFile('manifest.json', {'version': 1, 'createdAt': DateTime.now().toIso8601String()}))
      ..addFile(_jsonFile('settings.json', bundle.settings.toJson()))
      ..addFile(_jsonFile('watch.json', bundle.watch.toJson()))
      ..addFile(_jsonFile('library.json', bundle.library.toJson()))
      ..addFile(_jsonFile('downloads.json', _portableDownloads(bundle.downloads)))
      ..addFile(_jsonFile('keyframes.json', bundle.keyframes))
      ..addFile(_jsonFile('check_ins.json', bundle.checkIns));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final name = 'han1me-plus-${DateTime.now().toIso8601String().substring(0, 10)}.zip';
    if (Platform.isAndroid) return PlatformService.saveDocument(name, bytes);
    final destination = await FilePicker.platform.saveFile(dialogTitle: name, fileName: name, type: FileType.custom, allowedExtensions: const ['zip'], bytes: Platform.isIOS ? bytes : null);
    if (destination == null) return false;
    if (!Platform.isIOS) await File(destination).writeAsBytes(bytes, flush: true);
    return true;
  }

  Future<BackupBundle?> import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['zip'], withData: Platform.isIOS);
    if (result == null) return null;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await File(picked.path!).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    Map<String, dynamic> json(String name) {
      final file = archive.files.where((item) => item.name == name).firstOrNull;
      if (file == null) return {};
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(file.content as List<int>)) as Map);
    }
    final manifest = json('manifest.json');
    if (manifest['version'] != 1) throw const FormatException('Unsupported backup format');
    return BackupBundle(
      settings: AppSettings.fromJson(json('settings.json')),
      watch: WatchState.fromJson(json('watch.json')),
      library: LibraryState.fromJson(json('library.json')),
      downloads: DownloadState.fromJson(json('downloads.json')),
      keyframes: json('keyframes.json'),
      checkIns: json('check_ins.json'),
    );
  }

  Future<Map<String, dynamic>> readKeyframes() => _store.read('keyframes.json');

  Future<Map<String, dynamic>> readCheckIns() async {
    final primary = await _store.read('check_ins.json');
    return primary.isNotEmpty ? primary : _store.read('checkin_store.json');
  }

  Future<void> writeAuxiliary(BackupBundle bundle) async {
    await _store.write('keyframes.json', bundle.keyframes);
    await _store.write('check_ins.json', bundle.checkIns);
  }

  ArchiveFile _jsonFile(String name, Map<String, dynamic> value) {
    final bytes = utf8.encode(jsonEncode(value));
    return ArchiveFile(name, bytes.length, bytes);
  }

  Map<String, dynamic> _portableDownloads(DownloadState state) => {
        'groups': state.groups.map((group) => group.toJson()).toList(),
        'tasks': state.tasks.map((task) {
          final json = task.toJson()
            ..remove('sourceUrl')
            ..remove('localVideoPath')
            ..remove('localCoverPath')
            ..remove('localMetaPath')
            ..remove('localCommentPath');
          json['status'] = DownloadStatus.failed.name;
          json['errorMessage'] = 'Media files are not included in data backups';
          return json;
        }).toList(),
      };
}
