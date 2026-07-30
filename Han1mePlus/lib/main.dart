import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import 'src/app.dart';
import 'src/data/local/update_installer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(windows: true);
  await UpdateInstaller(Dio()).removeStaleUpdate();
  runApp(const ProviderScope(child: Han1meApp()));
}
