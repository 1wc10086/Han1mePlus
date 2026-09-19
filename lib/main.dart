import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'src/app.dart';
import 'src/core/media_player_initializer.dart';
import 'src/core/playback_speed_policy.dart';
import 'src/core/settings.dart';
import 'src/core/shader_service.dart';
import 'src/data/local/json_store.dart';
import 'src/data/local/update_installer.dart';
import 'src/features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (loadedSettings, _) = await (
    SettingsStore(JsonStore()).load(),
    LiquidGlassWidgets.initialize(),
  ).wait;
  await PlaybackSpeedPolicy.initialize();
  final settings = PlaybackSpeedPolicy.isHarmonyOs && loadedSettings.playerEngine != PlayerEngine.libMpv
      ? loadedSettings.copyWith(playerEngine: PlayerEngine.libMpv)
      : loadedSettings;
  if (!identical(settings, loadedSettings)) await SettingsStore(JsonStore()).save(settings);
  MediaPlayerInitializer.bootstrap(settings);
  runApp(
    LiquidGlassWidgets.wrap(
      child: ProviderScope(
        overrides: [settingsProvider.overrideWith(() => SettingsController(settings))],
        child: const Han1meApp(),
      ),
    ),
  );
  unawaited(_postLaunch());
}

Future<void> _postLaunch() async {
  try {
    await Future.wait([
      ShaderService.copyToStorage(),
      UpdateInstaller(Dio()).removeStaleUpdate(),
    ]);
  } catch (_) {}
}
