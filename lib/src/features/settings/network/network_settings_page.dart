import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/platform_paths.dart';
import '../../../core/settings.dart';
import '../../../data/local/download_repository.dart';
import '../../../data/remote/ech/ech_static_client.dart';
import '../../account/account_controller.dart';
import '../../explore/explore_controller.dart';
import '../settings_card_list.dart';
import '../settings_controller.dart';
import 'doh_settings_dialog.dart';
import 'download_path_dialog.dart';
import 'ech_status_dialog.dart';
import 'media_cdn_settings_dialog.dart';
import 'mirror_settings_dialog.dart';

class NetworkSettingsPage extends ConsumerWidget {
  const NetworkSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: M3EContainedLoadingIndicator()));
    final controller = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.networkSettings)),
      body: ListView(
        children: [
          SettingsCardList(
            title: l10n.general,
            children: [
              SettingsCardItem(title: l10n.site, subtitle: settings.comicMode ? 'https://hanimeone.me' : settings.baseUrl, leading: const Icon(Icons.language_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/site')),
              SettingsCardItem(title: l10n.customMirrorSite, subtitle: settings.mirrorActive ? settings.customMirrorSite : l10n.customMirrorSiteHint, leading: const Icon(Icons.link_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _editMirror(context, ref, settings, controller)),
              SettingsCardItem(title: l10n.useBuiltInHosts, subtitle: l10n.useBuiltInHostsDescription, leading: const Icon(Icons.dns_outlined), trailing: Switch(value: settings.useBuiltInHosts, onChanged: (value) => controller.saveChanges((current) => current.copyWith(useBuiltInHosts: value, useDoh: value ? false : current.useDoh)))),
              SettingsCardItem(title: l10n.doh, subtitle: _dohSummary(l10n, settings), leading: const Icon(Icons.security_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _editDoh(context, settings, controller)),
            ],
          ),
          SettingsCardList(
            title: l10n.network,
            children: [
              SettingsCardItem(title: l10n.mediaCdnRegionNode, subtitle: _mediaCdnSummary(l10n, settings), leading: const Icon(Icons.storage_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _editMediaCdn(context, settings, controller)),
              SettingsCardItem(title: l10n.echDirect, subtitle: _echSummary(l10n), leading: const Icon(Icons.enhanced_encryption_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => showEchStatusDialog(context)),
            ],
          ),
          SettingsCardList(
            title: l10n.downloadSettings,
            children: [
              SettingsCardItem(title: l10n.downloadPath, subtitle: settings.downloadPath, leading: const Icon(Icons.folder_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _editDownloadPath(context, settings, controller)),
              SettingsCardItem(title: l10n.exportDownloads, subtitle: l10n.exportDownloadsDescription, leading: const Icon(Icons.drive_folder_upload_outlined), trailing: const Icon(Icons.chevron_right), onTap: () => _exportDownloads(context, ref)),
              _SliderTile(icon: Icons.speed_outlined, title: l10n.downloadSpeedLimit, value: settings.downloadSpeedLimitMbps, min: 0, max: 20, divisions: 40, label: settings.downloadSpeedLimitMbps == 0 ? l10n.unlimited : '${settings.downloadSpeedLimitMbps.toStringAsFixed(1)} MB/s', onChanged: (value) => controller.saveChanges((current) => current.copyWith(downloadSpeedLimitMbps: value)), labelBuilder: (value) => value == 0 ? l10n.unlimited : '${value.toStringAsFixed(1)} MB/s'),
              _SliderTile(icon: Icons.download_for_offline_outlined, title: l10n.concurrentDownloads, subtitle: l10n.concurrentDownloadsDescription(settings.concurrentDownloads), value: settings.concurrentDownloads.toDouble(), min: 1, max: 5, divisions: 4, label: '${settings.concurrentDownloads}', onChanged: (value) => controller.saveChanges((current) => current.copyWith(concurrentDownloads: value.round())), labelBuilder: (value) => '${value.round()}'),
            ],
          ),
        ],
      ),
    );
  }

  String _dohSummary(AppLocalizations l10n, AppSettings settings) => !settings.useDoh
      ? l10n.dohDisabled
      : settings.dohPreset == 'custom'
          ? (settings.dohCustomUrl.isEmpty ? l10n.custom : settings.dohCustomUrl)
          : dohPresets[settings.dohPreset] ?? settings.dohPreset;

  String _mediaCdnSummary(AppLocalizations l10n, AppSettings settings) {
    if (settings.mediaCdnCustomIp.trim().isNotEmpty) return '${l10n.mediaCdnCustomIp}: ${settings.mediaCdnCustomIp.trim()}';
    if (settings.mediaCdnRegion.isNotEmpty) return mediaCdnRegionLabel(l10n, settings.mediaCdnRegion);
    return l10n.mediaCdnAuto;
  }

  String _echSummary(AppLocalizations l10n) {
    final ech = EchStaticClient.instance;
    if (ech == null) return l10n.echUnavailable;
    return ech.logs.firstOrNull ?? l10n.echEnabledHint;
  }

  Future<void> _editMirror(BuildContext context, WidgetRef ref, AppSettings settings, SettingsController controller) async {
    final result = await showMirrorSettingsDialog(context, settings: settings);
    if (result == null) return;
    if (result.enabled == settings.useCustomMirrorSite && result.url == settings.customMirrorSite && result.appendPath == settings.appendCustomMirrorPath) return;
    await controller.saveChanges((current) => current.copyWith(useCustomMirrorSite: result.enabled, customMirrorSite: result.url, appendCustomMirrorPath: result.appendPath));
    ref.invalidate(accountProvider);
    ref.invalidate(homeSectionsProvider);
  }

  Future<void> _editDoh(BuildContext context, AppSettings settings, SettingsController controller) async {
    final result = await showDohSettingsDialog(context, settings: settings);
    if (result == null) return;
    await controller.saveChanges((current) => current.copyWith(useDoh: result.enabled, useBuiltInHosts: result.enabled ? false : current.useBuiltInHosts, dohPreset: result.preset, dohCustomUrl: result.customUrl, dohBootstrapIps: result.bootstrapIps, dohTimeoutSeconds: result.timeoutSeconds));
  }

  Future<void> _editMediaCdn(BuildContext context, AppSettings settings, SettingsController controller) async {
    final result = await showMediaCdnSettingsDialog(context, settings: settings);
    if (result == null) return;
    await controller.saveChanges((current) => current.copyWith(mediaCdnRegion: result.region, mediaCdnCustomIp: result.customIp));
  }

  Future<void> _editDownloadPath(BuildContext context, AppSettings settings, SettingsController controller) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final path = await resolveDefaultDownloadPath();
      await controller.saveChanges((current) => current.copyWith(downloadPath: path));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privateDownloadPath)));
      return;
    }
    final path = await showDownloadPathDialog(context, initialPath: settings.downloadPath);
    if (path == null) return;
    await controller.saveChanges((current) => current.copyWith(downloadPath: path));
  }

  Future<void> _exportDownloads(BuildContext context, WidgetRef ref) async {
    if (Platform.isAndroid) {
      final exported = await ref.read(downloadProvider.notifier).exportCompletedWithPicker();
      if (!exported) return;
    } else {
      final path = await FilePicker.platform.getDirectoryPath(dialogTitle: AppLocalizations.of(context)!.exportDownloads);
      if (path == null || path.isEmpty) return;
      await ref.read(downloadProvider.notifier).exportCompleted(path);
    }
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.exportCompleted)));
  }
}

class _SliderTile extends SettingsSliderItem {
  _SliderTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    String Function(double value)? labelBuilder,
  }) : super(leading: Icon(icon), title: title, subtitle: subtitle, value: value, min: min, max: max, divisions: divisions, label: label, onChanged: onChanged, labelBuilder: labelBuilder);
}
