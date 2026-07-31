import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_service.dart';
import '../settings/settings_controller.dart';

enum AppLockStatus { unlocking, locked, unlocked }

final appLockProvider = NotifierProvider<AppLockController, AppLockStatus>(AppLockController.new);

class AppLockController extends Notifier<AppLockStatus> {
  var _everUnlocked = false;
  var _requestPending = false;

  @override
  AppLockStatus build() {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return AppLockStatus.unlocking;
    if (_everUnlocked || !settings.appLockEnabled || PlatformService.isDesktop) {
      _everUnlocked = true;
      return AppLockStatus.unlocked;
    }
    return AppLockStatus.locked;
  }

  Future<void> unlock() async {
    if (_requestPending) return;
    _requestPending = true;
    state = AppLockStatus.unlocking;
    final ok = await PlatformService.authenticate();
    if (ok) _everUnlocked = true;
    state = ok ? AppLockStatus.unlocked : AppLockStatus.locked;
  }

  Future<void> retry() async {
    _requestPending = false;
    await unlock();
  }
}
