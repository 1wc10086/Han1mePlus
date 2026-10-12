import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';

final playerControlsVisibilityProvider = NotifierProvider<PlayerControlsVisibility, bool>(PlayerControlsVisibility.new);

class PlayerControlsVisibility extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state == value) return;
    state = value;
  }
}

bool landscapeFloatingBarVisible(WidgetRef ref, {required bool landscape}) {
  if (!landscape) return true;
  final enabled = ref.watch(settingsProvider).valueOrNull?.landscapeFloatingBar ?? false;
  return enabled && ref.watch(playerControlsVisibilityProvider);
}
