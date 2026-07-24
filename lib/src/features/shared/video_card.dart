import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

class VideoCardTile extends StatelessWidget {
  const VideoCardTile({super.key, required this.video, this.horizontal = false, this.onTap, this.onLongPress, this.coverImage});

  final VideoCard video;
  final bool horizontal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ImageProvider? coverImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final cacheWidth = (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(240, 480) as int;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap ?? (video.id.isEmpty ? null : () => context.push('/video/${video.id}')),
            onLongPress: onLongPress,
            child: horizontal
                ? _horizontalContent(theme, cacheWidth)
                : _verticalContent(theme, cacheWidth),
          ),
        );
      },
    );
  }

  Widget _verticalContent(ThemeData theme, int cacheWidth) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _cover(theme, cacheWidth)),
          const SizedBox(height: 8),
          _details(theme),
        ],
      );

  Widget _horizontalContent(ThemeData theme, int cacheWidth) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: _cover(theme, cacheWidth)),
          const SizedBox(height: 8),
          _details(theme),
        ],
      );

  Widget _cover(ThemeData theme, int cacheWidth) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverImage != null)
              Image(image: coverImage!, fit: BoxFit.cover)
            else
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
            const _GradientOverlay(),
            if (video.duration != null) Positioned(right: 6, bottom: 6, child: _Badge(text: video.duration!)),
            if (video.rating != null || video.views != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (video.rating != null) _StatPill(text: video.rating!),
                    if (video.rating != null && video.views != null)
                      const SizedBox(width: 4),
                    if (video.views != null)
                      _StatPill(
                        icon: Icons.visibility_outlined,
                        text: video.views!,
                      ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _details(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: video.artist == null
                ? null
                : Text(
                    video.artist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
            ),
        ],
      );
}

class VideoCardGrid extends ConsumerWidget {
  const VideoCardGrid({super.key, required this.videos, this.itemBuilder});

  final List<VideoCard> videos;
  final Widget Function(BuildContext context, int index, VideoCard video, bool horizontal)? itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final horizontal = settings?.useHorizontalSearchCards ?? true;
    final cardsPerRow = settings?.searchCardsPerRow ?? 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        const crossAxisSpacing = 10.0;
        const mainAxisSpacing = 12.0;
        final cardWidth = (constraints.maxWidth - horizontalPadding - crossAxisSpacing * (cardsPerRow - 1)) / cardsPerRow;
        final cardHeight = horizontal ? cardWidth * 9 / 16 + 70 : cardWidth / .62;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          cacheExtent: 720,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cardsPerRow,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisExtent: cardHeight,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) => itemBuilder?.call(context, index, videos[index], horizontal) ?? VideoCardTile(video: videos[index], horizontal: horizontal),
        );
      },
    );
  }
}

class VideoCardCollection extends ConsumerWidget {
  const VideoCardCollection({super.key, required this.videos});

  final List<VideoCard> videos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final horizontal = settings?.useHorizontalSearchCards ?? true;
    final cardsPerRow = settings?.searchCardsPerRow ?? 2;
    final expanded = settings?.expandHomeVideoCards ?? false;
    if (expanded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const padding = 32.0;
          const spacing = 10.0;
          final cardWidth = (constraints.maxWidth - padding - spacing * (cardsPerRow - 1)) / cardsPerRow;
          final cardHeight = horizontal ? cardWidth * 9 / 16 + 70 : cardWidth / .62;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cardsPerRow,
              mainAxisSpacing: 12,
              crossAxisSpacing: spacing,
              mainAxisExtent: cardHeight,
            ),
            itemCount: videos.length,
            itemBuilder: (_, index) => VideoCardTile(video: videos[index], horizontal: horizontal),
          );
        },
      );
    }
    final cardWidth = horizontal ? 154.0 : 132.0;
    final cardHeight = horizontal ? cardWidth * 9 / 16 + 70 : cardWidth / .62;
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(
          width: cardWidth,
          child: VideoCardTile(video: videos[index], horizontal: horizontal),
        ),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
              stops: const [0.55, 1],
            ),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _StatPill extends StatelessWidget {
  const _StatPill({this.icon, required this.text});
  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (icon != null) ...[
               Icon(icon, size: 11, color: Colors.white70),
               const SizedBox(width: 3),
             ],
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      );
}
