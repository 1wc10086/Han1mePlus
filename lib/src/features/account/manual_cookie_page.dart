import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import 'account_controller.dart';

class ManualCookiePage extends ConsumerStatefulWidget {
  const ManualCookiePage({super.key});

  @override
  ConsumerState<ManualCookiePage> createState() => _ManualCookiePageState();
}

class _ManualCookiePageState extends ConsumerState<ManualCookiePage> {
  final controller = TextEditingController();
  var saving = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manualCookieLogin)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 5,
            maxLines: 12,
            decoration: InputDecoration(labelText: l10n.cookies, errorText: error),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: saving ? null : _submit, child: Text(l10n.confirm)),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final value = controller.text.trim();
    if (value.isEmpty || !value.contains('=')) {
      setState(() => error = AppLocalizations.of(context)!.invalidCookies);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(accountProvider.notifier).saveCookie(value);
      if (mounted) context.go('/settings');
    } catch (exception) {
      if (mounted) setState(() => error = '$exception');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
