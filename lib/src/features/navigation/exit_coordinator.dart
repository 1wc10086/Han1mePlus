import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class AppExitCoordinator {
  var _dialogOpen = false;
  var _branchBackHandled = false;

  bool consumeBranchBackHandled() {
    if (!_branchBackHandled) return false;
    _branchBackHandled = false;
    return true;
  }

  void markBranchBackHandled() {
    _branchBackHandled = true;
  }

  void clearBranchBackHandled() {
    _branchBackHandled = false;
  }

  Future<bool> confirmExit(BuildContext context) async {
    if (_dialogOpen) return false;
    _dialogOpen = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.confirmExitTitle),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.confirm)),
          ],
        ),
      );
      return confirmed ?? false;
    } finally {
      _dialogOpen = false;
    }
  }
}
