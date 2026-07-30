import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_localizations.dart';

import '../../domain/models/video.dart';
import '../../data/remote/han1me_api.dart';
import '../../core/app_shell.dart';
import '../account/account_page.dart';
import '../settings/settings_controller.dart';
import '../shared/video_card.dart';
import 'explore_controller.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(homeSectionsProvider);
    final drawerMode = ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false;
    return Scaffold(
      endDrawer: drawerMode ? null : const AccountDrawer(),
      appBar: AppBar(leading: drawerMode ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null, title: Text(AppLocalizations.of(context)!.appTitle), actions: [
        IconButton(onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
        IconButton(onPressed: () => context.push('/previews/${_currentPreviewMonth()}'), icon: const Icon(Icons.live_tv_outlined)),
        if (!drawerMode) Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openEndDrawer(), icon: const Icon(Icons.account_circle_outlined))),
      ]),
      body: sections.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: M3EContainedLoadingIndicator()),
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
          child: LayoutBuilder(
            builder: (context, constraints) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              cacheExtent: 720,
              itemCount: feed.sections.length + (feed.featured == null ? 0 : 1),
              itemBuilder: (_, index) => Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: index == 0 && feed.featured != null
                      ? _FeaturedVideo(video: feed.featured!)
                      : _Section(
                          section: feed.sections[
                              index - (feed.featured == null ? 0 : 1)],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _currentPreviewMonth() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}';
}

class _Section extends StatelessWidget {
  const _Section({required this.section});
  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    _prefetch(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [Expanded(child: Text(section.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))), if (section.moreUrl != null) TextButton.icon(onPressed: () => context.push('/search', extra: section.moreUrl), iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward_ios, size: 14), label: Text(AppLocalizations.of(context)!.more))])),
    VideoCardCollection(videos: section.videos),
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 700;
          return Padding(
            padding: EdgeInsets.fromLTRB(desktop ? 24 : 16, 4, desktop ? 24 : 16, 16),
            child: desktop
                ? SizedBox(
                    width: double.infinity,
                    height: 320,
                    child: _FeaturedVideoSurface(video: video),
                  )
                : AspectRatio(
                    aspectRatio: 16 / 8,
                    child: _FeaturedVideoSurface(video: video),
                  ),
          );
        },
      );
}

class _FeaturedVideoSurface extends StatelessWidget {
  const _FeaturedVideoSurface({required this.video});

  final VideoCard video;

  @override
  Widget build(BuildContext context) => Material(
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
