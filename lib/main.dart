import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import 'src/app.dart';
import 'src/data/local/update_installer.dart';
import 'src/data/remote/desktop_network_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(windows: true, macOS: true);
  await bootstrapDesktopNetwork();
  await UpdateInstaller(Dio()).removeStaleUpdate();
  runApp(const ProviderScope(child: Han1meApp()));
}
