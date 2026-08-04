import 'dart:io';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ShaderService {
  ShaderService._();

  static Directory? directory;

  static Future<void> copyToStorage() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest
          .listAssets()
          .where((asset) => asset.startsWith('assets/shaders/') && asset.endsWith('.glsl'));
      final target = Directory(p.join((await getApplicationSupportDirectory()).path, 'shaders'));
      await target.create(recursive: true);
      for (final asset in assets) {
        final file = File(p.join(target.path, p.basename(asset)));
        if (await file.exists()) continue;
        final data = await rootBundle.load(asset);
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      directory = target;
    } catch (_) {}
  }
}
