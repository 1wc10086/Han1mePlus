import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
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
        if (locked) const AppLockScreen(),
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

class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(appLockProvider);
    final busy = status != AppLockStatus.locked;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                child: Icon(Icons.lock_outline, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(l10n.appLocked, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.appLockDescription, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: busy ? null : () => ref.read(appLockProvider.notifier).retry(),
                icon: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.fingerprint),
                label: Text(busy ? l10n.unlocking : l10n.unlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
