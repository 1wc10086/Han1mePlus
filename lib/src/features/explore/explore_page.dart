import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_localizations.dart';

import '../../domain/models/video.dart';
import '../../data/remote/han1me_api.dart';
import '../account/account_page.dart';
import '../shared/video_card.dart';
import 'explore_controller.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(homeSectionsProvider);
    return Scaffold(
      endDrawer: const AccountDrawer(),
      appBar: AppBar(title: const Text('Han1me+'), actions: [
        IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
        IconButton(onPressed: () => context.push('/previews/202607'), icon: const Icon(Icons.live_tv_outlined)),
        Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openEndDrawer(), icon: const Icon(Icons.account_circle_outlined))),
      ]),
      body: sections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error,
          onRetry: () => ref.read(homeSectionsProvider.notifier).refresh(),
          onCloudflareVerified: () async {
            final url = error is CloudflareChallengeException ? error.url : null;
            if (await context.push<bool>('/cloudflare', extra: url) == true) {
              await Future<void>.delayed(const Duration(milliseconds: 250));
              await ref.read(homeSectionsProvider.notifier).refresh();
            }
          },
        ),
        data: (feed) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(homeSectionsProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            cacheExtent: 720,
            itemCount: feed.sections.length + (feed.featured == null ? 0 : 1),
            itemBuilder: (_, index) => index == 0 && feed.featured != null
                ? _FeaturedVideo(video: feed.featured!)
                : _Section(section: feed.sections[index - (feed.featured == null ? 0 : 1)]),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section});
  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    _prefetch(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [Expanded(child: Text(section.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))), if (section.moreUrl != null) TextButton.icon(onPressed: () => context.push('/search', extra: section.moreUrl), iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward_ios, size: 14), label: Text(AppLocalizations.of(context)!.more))])),
    SizedBox(
      height: 218,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: section.videos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(width: 154, child: VideoCardTile(video: section.videos[index])),
      ),
    ),
    ]);
  }

  void _prefetch(BuildContext context) {
    final width = (154 * MediaQuery.devicePixelRatioOf(context)).round();
    for (final video in section.videos.take(4)) {
      if (video.coverUrl.isNotEmpty) unawaited(precacheImage(CachedNetworkImageProvider(video.coverUrl, maxWidth: width), context));
    }
  }
}

class _FeaturedVideo extends StatelessWidget {
  const _FeaturedVideo({required this.video});
  final VideoCard video;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: AspectRatio(
          aspectRatio: 16 / 8,
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: video.id.isEmpty ? null : () => context.push('/video/${video.id}'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.coverUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 960,
                    fadeInDuration: Duration.zero,
                    errorWidget: (_, __, ___) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                DecoratedBox(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                       Text(AppLocalizations.of(context)!.featured, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      if (video.artist != null) Text(video.artist!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry, required this.onCloudflareVerified});
  final Object error;
  final VoidCallback onRetry;
  final Future<void> Function() onCloudflareVerified;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$error', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.retry)), if ('$error'.contains('Cloudflare')) TextButton(onPressed: onCloudflareVerified, child: Text(AppLocalizations.of(context)!.completeCloudflareVerification))]),
  ));
}
