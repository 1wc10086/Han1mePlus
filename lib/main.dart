import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'src/app.dart';
import 'src/core/media_player_initializer.dart';
import 'src/core/settings.dart';
import 'src/core/shader_service.dart';
import 'src/data/local/json_store.dart';
import 'src/data/local/update_installer.dart';
import 'src/data/remote/desktop_network_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  final settings = await SettingsStore(JsonStore()).load();
  MediaPlayerInitializer.bootstrap(settings);
  await ShaderService.copyToStorage();
  await bootstrapDesktopNetwork();
  await UpdateInstaller(Dio()).removeStaleUpdate();
  runApp(LiquidGlassWidgets.wrap(child: const ProviderScope(child: Han1meApp())));
}
