import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:han1me_plus/src/core/settings.dart';
import 'package:han1me_plus/src/domain/models/download.dart';
import 'package:han1me_plus/src/data/local/download_repository.dart';
import 'package:han1me_plus/src/domain/models/video.dart';
import 'package:han1me_plus/src/features/settings/settings_controller.dart';

class _TestSettingsController extends SettingsController {
  _TestSettingsController(this.downloadPath);

  final String downloadPath;

  @override
  Future<AppSettings> build() async => AppSettings(downloadPath: downloadPath);
}

void main() {
  test('download create adds task to state and persists store file', () async {
    final temp = await Directory.systemTemp.createTemp('han1me_download_test');
    addTearDown(() => temp.delete(recursive: true));
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(() => _TestSettingsController(temp.path)),
    ]);
    addTearDown(container.dispose);

    await container.read(downloadProvider.future);
    final video = VideoDetail(id: 'v1', title: 'Test', sources: const [], tags: const [], playlist: const [], related: const []);
    await container.read(downloadProvider.notifier).create(video, const VideoSource(quality: '720P', url: 'https://example.invalid/video.mp4'), 'default');

    final state = container.read(downloadProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state!.tasks, hasLength(1));
    expect(state.tasks.first.videoCode, 'v1');
    expect(state.tasks.first.status, isNot(DownloadStatus.completed));
    expect(File('${temp.path}/download_store.json').existsSync(), isTrue);
  });
}
