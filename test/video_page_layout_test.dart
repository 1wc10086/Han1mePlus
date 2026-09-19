import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:han1me_plus/l10n/app_localizations.dart';
import 'package:han1me_plus/src/core/settings.dart';
import 'package:han1me_plus/src/domain/models/account.dart';
import 'package:han1me_plus/src/domain/models/video.dart';
import 'package:han1me_plus/src/features/account/account_controller.dart';
import 'package:han1me_plus/src/features/library/remote_library_controller.dart';
import 'package:han1me_plus/src/features/settings/settings_controller.dart';
import 'package:han1me_plus/src/features/video/comments_controller.dart';
import 'package:han1me_plus/src/features/video/video_controller.dart';
import 'package:han1me_plus/src/features/video/video_page.dart';

class _TestSettingsController extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings(resumePlayback: false, autoPlayOnOpen: false);
}

class _TestAccountController extends AccountController {
  @override
  Future<Account?> build() async => null;
}

VideoDetail _localVideo() => const VideoDetail(
      id: 'v1',
      title: 'Cached Video',
      coverUrl: 'https://example.invalid/cover.jpg',
      sources: [],
      tags: [],
      playlist: [VideoCard(id: 'v1', title: 'EP1', coverUrl: 'https://example.invalid/1.jpg'), VideoCard(id: 'v2', title: 'EP2', coverUrl: 'https://example.invalid/2.jpg')],
      related: [],
    );

Future<void> _pumpVideoPage(WidgetTester tester, {required List<Override> overrides}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_TestSettingsController.new),
        accountProvider.overrideWith(_TestAccountController.new),
        commentsProvider('v1').overrideWith((ref) async => throw StateError('offline test')),
        remoteLibraryProvider.overrideWith((ref) async => throw StateError('offline test')),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VideoPage(id: 'v1', localVideo: _localVideo()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('video page lays out tablet info panel without flex errors', (tester) async {
    await _pumpVideoPage(tester, overrides: [
      videoDetailProvider('v1').overrideWith((ref) async => throw StateError('offline test')),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('EP1'), findsWidgets);
    expect(find.text('EP2'), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('cached video merges online info when network fetch succeeds', (tester) async {
    const online = VideoDetail(
      id: 'v1',
      title: 'Cached Video',
      description: 'Online description text',
      sources: [VideoSource(quality: '1080P', url: 'https://example.invalid/stream.m3u8')],
      tags: [],
      playlist: [VideoCard(id: 'v1', title: 'EP1', coverUrl: 'https://example.invalid/1.jpg'), VideoCard(id: 'v2', title: 'EP2', coverUrl: 'https://example.invalid/2.jpg')],
      related: [],
    );
    await _pumpVideoPage(tester, overrides: [
      videoDetailProvider('v1').overrideWith((ref) async => online),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Online description text'), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
  });
}
