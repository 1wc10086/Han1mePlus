import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:han1me_plus/src/domain/models/video.dart';
import 'package:han1me_plus/src/features/shared/video_card.dart';

void main() {
  testWidgets('横向卡片元信息区无多余留白且不溢出', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final video = VideoCard(
      id: 'v1',
      title: '很长的标题很长的标题很长的标题很长的标题很长的标题很长的标题',
      coverUrl: 'https://example.invalid/cover.jpg',
      artist: '某作者',
      rating: '92%',
      uploadTime: '2026-09-01',
    );
    const cardWidth = 220.0;
    // 与 video_card.dart 中 _horizontalCardMetaHeight 保持一致。
    const metaHeight = 84.0;
    final cardHeight = cardWidth * 9 / 16 + metaHeight;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: VideoCardTile(video: video, horizontal: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tileBottom = tester.getTopRight(find.byType(VideoCardTile)).dy;
    final ratingRowBottom = tester.getBottomRight(find.text('92%')).dy;
    // 点赞行应贴近卡片底部, 剩余空隙不超过 2 个逻辑像素。
    expect(tileBottom - ratingRowBottom, lessThanOrEqualTo(2.0));
    expect(tester.takeException(), isNull);
  });

  test('videoCardMetrics 横向卡片高度使用紧凑元信息高度', () {
    final metrics = videoCardMetrics(viewportWidth: 800, horizontal: true, cardsPerRow: 2, expanded: true);
    expect(metrics.cardHeight, closeTo(metrics.cardWidth * 9 / 16 + 84, 0.01));
  });
}
