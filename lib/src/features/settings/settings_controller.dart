import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../data/local/json_store.dart';
import '../../data/remote/han1me_http_client.dart';

final settingsStoreProvider = Provider((_) => SettingsStore(JsonStore()));

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final settings = await ref.read(settingsStoreProvider).load();
    await _syncNetworkSettings(settings);
    return settings;
  }

  AppSettings get _current => state.value ?? const AppSettings();

  Future<void> saveChanges(AppSettings Function(AppSettings current) transform) async {
    final next = transform(_current);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).save(next);
    await _syncNetworkSettings(next);
  }

  Future<void> _syncNetworkSettings(AppSettings settings) => Han1meHttpClient().setNetworkSettings(useBuiltInHosts: settings.useBuiltInHosts, useDoh: settings.useDoh, dohPreset: settings.dohPreset, dohCustomUrl: settings.dohCustomUrl, dohBootstrapIps: settings.dohBootstrapIps, dohTimeoutSeconds: settings.dohTimeoutSeconds);

  Future<void> setPreferredQuality(String quality) async {
    await saveChanges((current) => current.copyWith(preferredQuality: _qualityInt(quality)));
  }

  int _qualityInt(String quality) {
    final numeric = int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), ''));
    return numeric ?? 720;
  }
}
