import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/network/media_cdn.dart';
import '../../../core/settings.dart';
import 'media_cdn_settings_view_model.dart';

Future<MediaCdnSettings?> showMediaCdnSettingsDialog(BuildContext context, {required AppSettings settings}) =>
    showDialog<MediaCdnSettings>(context: context, builder: (_) => _MediaCdnSettingsDialog(settings: settings));

class _MediaCdnSettingsDialog extends StatefulWidget {
  const _MediaCdnSettingsDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_MediaCdnSettingsDialog> createState() => _MediaCdnSettingsDialogState();
}

class _MediaCdnSettingsDialogState extends State<_MediaCdnSettingsDialog> {
  late final MediaCdnSettingsViewModel _viewModel = MediaCdnSettingsViewModel(
    region: widget.settings.mediaCdnRegion,
    customIp: widget.settings.mediaCdnCustomIp,
  );
  late final TextEditingController _customIp = TextEditingController(text: widget.settings.mediaCdnCustomIp);

  @override
  void initState() {
    super.initState();
    _viewModel.measureAll();
  }

  @override
  void dispose() {
    _customIp.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => AlertDialog(
        title: Text(l10n.mediaCdnRegionNode),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: '',
                groupValue: _viewModel.region,
                title: Text(l10n.mediaCdnAuto),
                subtitle: Text(l10n.mediaCdnAutoDescription),
                onChanged: (value) => _viewModel.selectRegion(value ?? ''),
              ),
              const Divider(height: 1),
              for (final region in mediaCdnRegions)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: region.id,
                  groupValue: _viewModel.region,
                  title: Text(mediaCdnRegionLabel(l10n, region.id)),
                  subtitle: Text(_latencyLabel(l10n, _viewModel.latencyFor(region.id))),
                  onChanged: (value) => _viewModel.selectRegion(value ?? ''),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _customIp,
                keyboardType: TextInputType.url,
                onChanged: _viewModel.updateCustomIp,
                decoration: InputDecoration(
                  labelText: l10n.mediaCdnCustomIp,
                  hintText: l10n.mediaCdnCustomIpHint,
                  helperText: l10n.mediaCdnCustomIpPriority,
                  suffixIcon: IconButton(
                    tooltip: l10n.mediaCdnMeasure,
                    onPressed: _viewModel.customStatus == MediaCdnProbeStatus.running ? null : _viewModel.measureCustom,
                    icon: const Icon(Icons.speed_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerLeft, child: Text(_customStatusLabel(l10n), style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: Text(l10n.mediaCdnNodesHint, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, _viewModel.toSettings()), child: Text(l10n.save)),
        ],
      ),
    );
  }

  String _latencyLabel(AppLocalizations l10n, int? latency) {
    if (_viewModel.measuring) return l10n.mediaCdnMeasuring;
    if (latency == null) return l10n.mediaCdnUnreachable;
    return l10n.mediaCdnLatencyMs(latency);
  }

  String _customStatusLabel(AppLocalizations l10n) => switch (_viewModel.customStatus) {
        MediaCdnProbeStatus.idle => '',
        MediaCdnProbeStatus.running => l10n.mediaCdnMeasuring,
        MediaCdnProbeStatus.reachable => l10n.mediaCdnLatencyMs(_viewModel.customLatency ?? 0),
        MediaCdnProbeStatus.unreachable => l10n.mediaCdnUnreachable,
      };
}

String mediaCdnRegionLabel(AppLocalizations l10n, String id) => switch (id) {
      'japan' => l10n.regionJapan,
      'hongKong' => l10n.regionHongKong,
      'taiwan' => l10n.regionTaiwan,
      'russia' => l10n.regionRussia,
      'unitedStates' => l10n.regionUnitedStates,
      'europe' => l10n.regionEurope,
      'singapore' => l10n.regionSingapore,
      _ => l10n.custom,
    };
