import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../data/local/json_store.dart';

final settingsStoreProvider = Provider((_) => SettingsStore(JsonStore()));

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(settingsStoreProvider).load();

  AppSettings get _current => state.value ?? const AppSettings();

  Future<void> saveChanges(AppSettings Function(AppSettings current) transform) async {
    final next = transform(_current);
    state = AsyncData(next);
    await ref.read(settingsStoreProvider).save(next);
  }

  Future<void> setPreferredQuality(String quality) async {
    await saveChanges((current) => current.copyWith(preferredQuality: _qualityInt(quality)));
  }

  int _qualityInt(String quality) {
    final numeric = int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), ''));
    return numeric ?? 720;
  }
}