import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_controller.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlockIfLocked());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockProvider, (previous, next) {
      if (next == AppLockStatus.locked) _unlockIfLocked();
    });
    final locked = ref.watch(appLockProvider) != AppLockStatus.unlocked;
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !locked,
          child: IgnorePointer(
            ignoring: locked,
            child: ExcludeSemantics(excluding: locked, child: widget.child),
          ),
        ),
        if (locked) const _LockLayer(),
      ],
    );
  }

  void _unlockIfLocked() {
    if (!mounted) return;
    if (ref.read(appLockProvider) == AppLockStatus.locked) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }
}

class _LockLayer extends ConsumerWidget {
  const _LockLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(appLockProvider.notifier).unlock(),
        child: ColoredBox(color: Theme.of(context).colorScheme.surface),
      );
}
