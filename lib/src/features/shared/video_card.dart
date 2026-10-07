import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

int videoCardCacheWidth(double cardWidth, double devicePixelRatio) => (cardWidth * devicePixelRatio).round().clamp(240, 480).toInt();

const videoCardTitleLines = 2;

final Map<(TextStyle?, TextScaler), double> _lineHeightCache = {};

double _measuredLineHeight(TextStyle? style, TextScaler scaler) {
  final key = (style, scaler);
  final cached = _lineHeightCache[key];
  if (cached != null) return cached;
  final painter = TextPainter(
    text: TextSpan(text: 'Ag中', style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final height = painter.height;
  painter.dispose();
  _lineHeightCache[key] = height;
  return height;
}

class VideoCardTextMetrics {
  const VideoCardTextMetrics({
    required this.titleLineHeight,
    required this.metaLineHeight,
    this.gap = 8,
    this.lineGap = 2,
  });

  factory VideoCardTextMetrics.of(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return VideoCardTextMetrics(
      titleLineHeight: _measuredLineHeight(theme.textTheme.bodyMedium, scaler),
      metaLineHeight: _measuredLineHeight(theme.textTheme.bodySmall, scaler),
    );
  }

  final double titleLineHeight;
  final double metaLineHeight;
  final double gap;
  final double lineGap;

  double get titleBoxHeight => titleLineHeight * videoCardTitleLines + 1;
  double get detailsHeight => titleBoxHeight + lineGap + metaLineHeight + lineGap + metaLineHeight;
  double get metaHeight => gap + detailsHeight + 2;
}

double videoCardMetaHeightFor(BuildContext context) => VideoCardTextMetrics.of(context).metaHeight;

double videoCardMetaHeight(BuildContext context) => videoCardMetaHeightFor(context);

double videoCardCardHeight({required BuildContext context, required double cardWidth, required bool horizontal}) =>
    horizontal ? cardWidth * 9 / 16 + videoCardMetaHeight(context) : cardWidth / .58;

class VideoCardMetrics {
  const VideoCardMetrics({required this.horizontal, required this.cardsPerRow, required this.cardWidth, required this.cardHeight});

  final bool horizontal;
  final int cardsPerRow;
  final double cardWidth;
  final double cardHeight;
}

VideoCardMetrics videoCardMetrics({
  required BuildContext context,
  required double viewportWidth,
  required bool horizontal,
  required int cardsPerRow,
  required bool expanded,
}) {
  const spacing = 10.0;
  const padding = 32.0;
  final metaHeight = videoCardMetaHeight(context);
  if (expanded) {
    final effective = viewportWidth >= 1200 ? (viewportWidth / 300).floor().clamp(cardsPerRow, 6).toInt() : cardsPerRow;
    final cardWidth = (viewportWidth - padding - spacing * (effective - 1)) / effective;
    final cardHeight = horizontal ? cardWidth * 9 / 16 + metaHeight : cardWidth / .58;
    return VideoCardMetrics(horizontal: horizontal, cardsPerRow: effective, cardWidth: cardWidth, cardHeight: cardHeight);
  }
  final desktop = viewportWidth >= 700;
  final cardWidth = horizontal ? (desktop ? 220.0 : 154.0) : (desktop ? 170.0 : 132.0);
  final cardHeight = horizontal ? cardWidth * 9 / 16 + metaHeight : cardWidth / .58;
  return VideoCardMetrics(horizontal: horizontal, cardsPerRow: 1, cardWidth: cardWidth, cardHeight: cardHeight);
}

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
        final metrics = VideoCardTextMetrics.of(context);
        final cacheWidth = videoCardCacheWidth(constraints.maxWidth, MediaQuery.devicePixelRatioOf(context));
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
                ? _horizontalContent(theme, metrics, cacheWidth)
                : _verticalContent(theme, metrics, cacheWidth),
          ),
        );
      },
    );
  }

  Widget _verticalContent(ThemeData theme, VideoCardTextMetrics metrics, int cacheWidth) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _cover(theme, cacheWidth)),
          SizedBox(height: metrics.gap),
          _details(theme, metrics, shrinkable: false),
        ],
      );

  Widget _horizontalContent(ThemeData theme, VideoCardTextMetrics metrics, int cacheWidth) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: _cover(theme, cacheWidth)),
          SizedBox(height: metrics.gap),
          Flexible(fit: FlexFit.loose, child: _details(theme, metrics, shrinkable: true)),
        ],
      );

  Widget _cover(ThemeData theme, int cacheWidth) => RepaintBoundary(
        child: ClipRRect(
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
        ),
      );

  Widget _details(ThemeData theme, VideoCardTextMetrics metrics, {required bool shrinkable}) {
    Widget line(Widget child) => shrinkable ? Flexible(fit: FlexFit.loose, child: child) : child;
    final rating = video.rating;
    final uploadTime = video.uploadTime;
    final artist = video.artist;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: metrics.titleBoxHeight,
          child: Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: metrics.lineGap),
        if (artist != null && artist.isNotEmpty)
          line(Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
        SizedBox(height: metrics.lineGap),
        Row(
          children: [
            Expanded(child: rating == null || rating.isEmpty ? const SizedBox.shrink() : Row(children: [Icon(Icons.thumb_up_outlined, size: 14, color: theme.colorScheme.outline), const SizedBox(width: 4), Flexible(child: Text(rating, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)))])),
            if (uploadTime != null && uploadTime.isNotEmpty) Text(uploadTime, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ],
    );
  }
}

class VideoCardGrid extends ConsumerWidget {
  const VideoCardGrid({super.key, required this.videos, this.itemBuilder, this.keyboardDismissBehavior});

  final List<VideoCard> videos;
  final Widget Function(BuildContext context, int index, VideoCard video, bool horizontal)? itemBuilder;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

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
        final cardHeight = videoCardCardHeight(context: context, cardWidth: cardWidth, horizontal: horizontal);
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + MediaQuery.paddingOf(context).bottom),
          cacheExtent: 720,
          keyboardDismissBehavior: keyboardDismissBehavior,
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