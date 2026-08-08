import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/video.dart';
import 'video_card.dart';

const compactVideoCardsPerRow = 3;

class CompactVideoCard extends StatelessWidget {
  const CompactVideoCard({super.key, required this.video, this.onTap});

  final VideoCard video;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth = videoCardCacheWidth(constraints.maxWidth, MediaQuery.devicePixelRatioOf(context));
        return Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? (video.id.isEmpty ? null : () => context.push('/video/${video.id}')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _cover(theme, cacheWidth),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cover(ThemeData theme, int cacheWidth) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: video.coverUrl,
              fit: BoxFit.cover,
              memCacheWidth: cacheWidth,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (context, url, error) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
            if (video.duration != null)
              Positioned(right: 6, bottom: 6, child: _OverlayText(text: video.duration!)),
          ],
        ),
      );
}

class CompactVideoCardGrid extends StatelessWidget {
  const CompactVideoCardGrid({super.key, required this.videos, this.itemBuilder});

  final List<VideoCard> videos;
  final Widget Function(BuildContext context, int index, VideoCard video)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        const crossAxisSpacing = 10.0;
        const mainAxisSpacing = 12.0;
        final cardWidth = (constraints.maxWidth - horizontalPadding - crossAxisSpacing * (compactVideoCardsPerRow - 1)) / compactVideoCardsPerRow;
        final cardHeight = cardWidth * 4 / 3 + 46;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + MediaQuery.paddingOf(context).bottom),
          cacheExtent: 720,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compactVideoCardsPerRow,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisExtent: cardHeight,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) =>
              itemBuilder?.call(context, index, videos[index]) ?? CompactVideoCard(video: videos[index]),
        );
      },
    );
  }
}

class _OverlayText extends StatelessWidget {
  const _OverlayText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      );
}
