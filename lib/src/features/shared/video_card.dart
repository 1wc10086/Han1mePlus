import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

class VideoCardTile extends StatelessWidget {
  const VideoCardTile({super.key, required this.video, this.horizontal = false, this.selected = false, this.onTap, this.onLongPress, this.coverImage});

  final VideoCard video;
  final bool horizontal;
  final bool selected;
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
          color: selected ? theme.colorScheme.secondaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
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
            if (video.duration != null) Positioned(right: 6, bottom: 6, child: _OverlayText(text: video.duration!)),
            if (video.views != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: _OverlayText(icon: Icons.visibility_outlined, text: video.views!),
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
          if (video.artist != null)
            Text(video.artist!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: video.rating == null ? const SizedBox.shrink() : Row(children: [Icon(Icons.thumb_up_outlined, size: 14, color: theme.colorScheme.outline), const SizedBox(width: 4), Flexible(child: Text(video.rating!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)))])),
              if (video.uploadTime != null) Text(video.uploadTime!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
            ],
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
        final effectiveCardsPerRow = constraints.maxWidth >= 1200
            ? (constraints.maxWidth / 300).floor().clamp(cardsPerRow, 6).toInt()
            : cardsPerRow;
        final cardWidth = (constraints.maxWidth - horizontalPadding - crossAxisSpacing * (effectiveCardsPerRow - 1)) / effectiveCardsPerRow;
        final cardHeight = horizontal ? cardWidth * 9 / 16 + 96 : cardWidth / .58;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          cacheExtent: 720,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCardsPerRow,
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
          final effectiveCardsPerRow = constraints.maxWidth >= 1200
              ? (constraints.maxWidth / 300).floor().clamp(cardsPerRow, 6).toInt()
              : cardsPerRow;
          final cardWidth = (constraints.maxWidth - padding - spacing * (effectiveCardsPerRow - 1)) / effectiveCardsPerRow;
          final cardHeight = horizontal ? cardWidth * 9 / 16 + 96 : cardWidth / .58;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: effectiveCardsPerRow,
              mainAxisSpacing: 12,
              crossAxisSpacing: spacing,
              mainAxisExtent: cardHeight,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) => VideoCardTile(video: videos[index], horizontal: horizontal),
          );
        },
      );
    }
    final desktop = MediaQuery.sizeOf(context).width >= 700;
    final cardWidth = horizontal ? (desktop ? 220.0 : 154.0) : (desktop ? 170.0 : 132.0);
    final cardHeight = horizontal ? cardWidth * 9 / 16 + 96 : cardWidth / .58;
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: cardWidth,
          child: VideoCardTile(video: videos[index], horizontal: horizontal),
        ),
      ),
    );
  }
}

class _OverlayText extends StatelessWidget {
  const _OverlayText({this.icon, required this.text});
  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 3),
            ],
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        );
}
