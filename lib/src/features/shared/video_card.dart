import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/video.dart';

class VideoCardTile extends StatelessWidget {
  const VideoCardTile({super.key, required this.video});

  final VideoCard video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = ((MediaQuery.sizeOf(context).width - 34) / 2 * MediaQuery.devicePixelRatioOf(context)).round();
    final cacheWidth = width < 240 ? 240 : width > 480 ? 480 : width;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: video.id.isEmpty ? null : () => context.push('/video/${video.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.coverUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: cacheWidth,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                      errorWidget: (context, url, error) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.broken_image_outlined))),
                    ),
                    const _GradientOverlay(),
                    if (video.duration != null)
                      Positioned(right: 6, bottom: 6, child: _Badge(text: video.duration!)),
                    if (video.rating != null || video.views != null)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (video.rating != null) _StatPill(text: video.rating!),
                            if (video.rating != null && video.views != null) const SizedBox(width: 4),
                            if (video.views != null) _StatPill(icon: Icons.visibility_outlined, text: video.views!),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (video.artist != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  video.artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
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
