import 'dart:ui' show AppExitResponse;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../l10n/app_localizations.dart';
import '../core/platform_service.dart';
import '../data/local/update_installer.dart';
import '../data/remote/update_checker.dart';
import '../features/navigation/exit_coordinator.dart';
import '../features/settings/settings_controller.dart';

class AppStartupEffects extends ConsumerStatefulWidget {
  const AppStartupEffects({super.key, required this.navigatorKey, required this.exitCoordinator, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final AppExitCoordinator exitCoordinator;
  final Widget child;

  @override
  ConsumerState<AppStartupEffects> createState() => _AppStartupEffectsState();
}

class _AppStartupEffectsState extends ConsumerState<AppStartupEffects> {
  var _checkedForUpdate = false;
  var _appliedPrivacySettings = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onExitRequested: _handleExitRequest);
    ref.listenManual(settingsProvider, (previous, next) {
      final settings = next.valueOrNull;
      if (settings == null) return;
      if (settings.autoUpdate && !_checkedForUpdate) {
        _checkedForUpdate = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate(settings.useUpdateMirror));
      }
      if (!_appliedPrivacySettings) {
        _appliedPrivacySettings = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await PlatformService.setHideFromRecents(settings.hideFromRecents);
          await PlatformService.setEmergencyExit(settings.emergencyExitEnabled);
        });
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<AppExitResponse> _handleExitRequest() async {
    if (widget.exitCoordinator.consumeBranchBackHandled()) return AppExitResponse.cancel;
    final context = widget.navigatorKey.currentContext;
    if (context == null) return AppExitResponse.cancel;
    if (!await widget.exitCoordinator.confirmExit(context)) return AppExitResponse.cancel;
    if (PlatformService.isDesktop) return AppExitResponse.exit;
    await PlatformService.minimizeApp();
    return AppExitResponse.cancel;
  }

  Future<void> _checkForUpdate(bool useUpdateMirror) async {
    final update = await UpdateChecker(Dio()).check();
    if (!mounted || update == null) return;
    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.newVersionAvailable(update.tagName)),
        content: Text(
          update.downloadUrl.isEmpty
              ? l10n.noInstallableApk
              : update.body.isEmpty
                  ? l10n.newVersionReleased
                  : update.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.later)),
          FilledButton(
            onPressed: update.downloadUrl.isEmpty
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _installUpdate(context, update.downloadUrl, useUpdateMirror);
                  },
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }

  Future<void> _installUpdate(BuildContext context, String url, bool useMirror) async {
    if (url.isEmpty) return;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => _StartupUpdateDownload(url: url, useMirror: useMirror));
  }
}

class _StartupUpdateDownload extends StatefulWidget {
  const _StartupUpdateDownload({required this.url, required this.useMirror});

  final String url;
  final bool useMirror;

  @override
  State<_StartupUpdateDownload> createState() => _StartupUpdateDownloadState();
}

class _StartupUpdateDownloadState extends State<_StartupUpdateDownload> {
  double? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      await UpdateInstaller(Dio()).downloadAndInstall(widget.url, (value) {
        if (mounted) setState(() => _progress = value);
      }, useMirror: widget.useMirror);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.downloadingUpdate),
        content: _error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  M3ELinearProgressIndicator(value: _progress),
                  const SizedBox(height: 12),
                  Text(_progress == null ? AppLocalizations.of(context)!.connecting : '${(_progress! * 100).toStringAsFixed(0)}%'),
                ],
              )
            : Text(AppLocalizations.of(context)!.updateFailed(_error.toString())),
        actions: _error == null ? null : [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.close))],
      );
}
