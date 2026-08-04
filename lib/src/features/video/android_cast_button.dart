import 'dart:async';

import 'dart:io';

import 'package:dlna_dart/dlna.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/models/video.dart';

class AndroidCastButton extends ConsumerWidget {
  const AndroidCastButton({super.key, required this.sources, required this.quality});

  final List<VideoSource> sources;
  final ValueListenable<String?> quality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid || sources.isEmpty) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(
      valueListenable: quality,
      builder: (context, selected, _) {
        final source = sources.where((source) => source.quality == selected).firstOrNull ?? sources.first;
        return IconButton(
          color: Colors.white,
          tooltip: AppLocalizations.of(context)!.castToDevice,
          onPressed: () => _showDevices(context, source.url),
          icon: const Icon(Icons.cast),
        );
      },
    );
  }

  Future<void> _showDevices(BuildContext context, String url) async {
    final manager = DLNAManager();
    StreamSubscription? subscription;
    try {
      final session = await manager.start();
      var devices = <dynamic>[];
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            subscription ??= session.devices.stream.listen((items) {
              devices = items.values.toList();
              setState(() {});
            });
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.castToDevice),
              content: SizedBox(
                width: 360,
                child: devices.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return ListTile(
                            leading: const Icon(Icons.cast_connected),
                            title: Text(device.info.friendlyName),
                            subtitle: Text(device.info.deviceType.split(':').last),
                            onTap: () async {
                              DLNADevice(device.info).setUrl(url);
                              DLNADevice(device.info).play();
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel))],
            );
          },
        ),
      );
    } finally {
      await subscription?.cancel();
      manager.stop();
    }
  }
}
