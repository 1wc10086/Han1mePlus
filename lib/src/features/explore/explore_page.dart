import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_shell.dart';
import '../../data/assets/search_option_catalog.dart';
import '../../data/remote/han1me_api.dart';
import '../../domain/models/search_query.dart';
import '../../domain/models/video.dart';
import '../../data/local/library_repository.dart';
import '../../core/settings.dart';
import '../settings/settings_controller.dart';
import '../shared/video_card.dart';
import 'explore_controller.dart';

const _maxContentWidth = 1440.0;

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(homeSectionsProvider);
    final drawerMode = ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: drawerMode && !permanentNavigationDrawer(context) ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null,
        title: Text(l10n.appTitle),
        actions: [
          IconButton(onPressed: () => context.push('/search', extra: SearchRouteRequest()), icon: const Icon(Icons.search)),
          IconButton(onPressed: () => context.push('/previews/${_currentPreviewMonth()}'), icon: const Icon(Icons.live_tv_outlined)),
          IconButton(tooltip: l10n.mine, onPressed: () => context.push('/mine'), icon: const Icon(Icons.account_circle_outlined)),
        ],
      ),
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
        data: (feed) => _HomeFeedBody(feed: feed),
      ),
    );
  }
}

class _HomeFeedBody extends ConsumerWidget {
  const _HomeFeedBody({required this.feed});
  final HomeFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final catalog = ref.watch(searchOptionCatalogProvider).valueOrNull;
    final locale = searchOptionLocaleKey(Localizations.localeOf(context));
    final subscribed = ref.watch(libraryProvider).valueOrNull?.artists.map((artist) => artist.name.toLowerCase()).toSet() ?? <String>{};
    final sections = feed.sections
        .map((section) => HomeSection(
              title: _localizedSectionTitle(section, catalog, locale),
              videos: section.videos.where((video) => _visible(video, settings, subscribed)).toList(),
              moreUrl: section.moreUrl,
              isFeatured: section.isFeatured,
            ))
        .where((section) => section.videos.isNotEmpty)
        .toList();
    Future<void> refresh() => ref.read(homeSectionsProvider.notifier).refresh();
    if (settings?.useHomeCategoryTabs != true || sections.isEmpty) return M3EPullToRefreshIndicator(onRefresh: refresh, child: _HomeScroll(featured: feed.featured, sections: sections));
    return DefaultTabController(length: sections.length, child: Column(children: [
      TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: sections.map((section) => Tab(text: section.title)).toList()),
      Expanded(child: TabBarView(children: sections.map((section) => M3EPullToRefreshIndicator(onRefresh: refresh, child: _HomeScroll(featured: feed.featured, sections: [section], forceExpanded: true))).toList())),
    ]));
  }

  bool _visible(VideoCard video, AppSettings? settings, Set<String> subscribed) {
    if (settings == null) return true;
    final subscribedAuthor = video.artist != null && subscribed.contains(video.artist!.toLowerCase());
    if (!(settings.exemptSubscribedAuthors && subscribedAuthor)) {
      if (settings.blockedVideoTitleKeywords.any((keyword) => video.title.toLowerCase().contains(keyword.toLowerCase()))) return false;
      if (settings.blockedAuthors.any((author) => (video.artist ?? '').toLowerCase().contains(author.toLowerCase()))) return false;
      if (_duration(video.duration) < settings.minimumVideoDurationSeconds || _views(video.views) < settings.minimumVideoViews) return false;
    }
    return true;
  }

  int _duration(String? text) => (text?.split(':').map(int.tryParse).toList() ?? const <int?>[]).fold<int>(0, (total, unit) => unit == null ? total : total * 60 + unit);
  int _views(String? text) => int.tryParse(RegExp(r'[\d,.]+').firstMatch(text ?? '')?.group(0)?.replaceAll(',', '') ?? '') ?? 0;
}

String _localizedSectionTitle(HomeSection section, SearchOptionCatalog? catalog, String locale) {
  if (catalog == null) return section.title;
  final uri = Uri.tryParse(section.moreUrl ?? '');
  final genre = uri?.queryParameters['genre'];
  final sort = uri?.queryParameters['sort'];
  return (genre == null ? null : catalog.genres.localize(genre, locale)) ??
      (sort == null ? null : catalog.sorts.localize(sort, locale)) ??
      catalog.genres.localize(section.title, locale) ??
      catalog.sorts.localize(section.title, locale) ??
      section.title;
}

class _HomeScroll extends StatelessWidget {
  const _HomeScroll({this.featured, required this.sections, this.forceExpanded = false});
  final VideoCard? featured;
  final List<HomeSection> sections;
  final bool forceExpanded;

  @override
  Widget build(BuildContext context) => CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), cacheExtent: 720, slivers: [
    if (featured != null) SliverToBoxAdapter(child: RepaintBoundary(child: _MaxWidth(child: _FeaturedVideo(video: featured!)))),
    for (final section in sections) _HomeSection(section: section, forceExpanded: forceExpanded),
    SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom)),
  ]);
}

class _HomeSection extends ConsumerStatefulWidget {
  const _HomeSection({required this.section, this.forceExpanded = false});

  final HomeSection section;
  final bool forceExpanded;

  @override
  ConsumerState<_HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends ConsumerState<_HomeSection> {
  String _prefetchKey = '';

  @override
  void didUpdateWidget(_HomeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) _schedulePrefetch();
  }

  void _schedulePrefetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prefetch());
    });
  }

  Future<void> _prefetch() async {
    if (!mounted) return;
    final context = this.context;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width.clamp(0.0, _maxContentWidth).toDouble();
    final settings = ref.read(settingsProvider).valueOrNull;
    final metrics = videoCardMetrics(
      viewportWidth: screenWidth,
      horizontal: settings?.useHorizontalSearchCards ?? true,
      cardsPerRow: settings?.searchCardsPerRow ?? 2,
      expanded: widget.forceExpanded || (settings?.expandHomeVideoCards ?? false),
    );
    final cacheWidth = videoCardCacheWidth(metrics.cardWidth, pixelRatio);
    final count = metrics.cardsPerRow > 1 ? metrics.cardsPerRow * 2 : (screenWidth / metrics.cardWidth).ceil() + 2;
    for (final video in widget.section.videos.take(count)) {
      if (video.coverUrl.isNotEmpty) {
        unawaited(precacheImage(CachedNetworkImageProvider(video.coverUrl, maxWidth: cacheWidth), context).catchError((_) {}));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final horizontal = settings?.useHorizontalSearchCards ?? true;
    final expanded = widget.forceExpanded || (settings?.expandHomeVideoCards ?? false);
    final cardsPerRow = settings?.searchCardsPerRow ?? 2;
    final prefetchKey = '${widget.section.videos.length}-$expanded-$horizontal-$cardsPerRow';
    if (prefetchKey != _prefetchKey) {
      _prefetchKey = prefetchKey;
      _schedulePrefetch();
    }
    final viewportWidth = MediaQuery.sizeOf(context).width.clamp(0.0, _maxContentWidth).toDouble();
    final metrics = videoCardMetrics(
      viewportWidth: viewportWidth,
      horizontal: horizontal,
      cardsPerRow: cardsPerRow,
      expanded: expanded,
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _MaxWidth(child: _SectionHeader(section: widget.section, showMore: !widget.forceExpanded))),
        if (expanded)
          SliverConstrainedCrossAxis(
            maxExtent: _maxContentWidth,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: metrics.cardsPerRow,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  mainAxisExtent: metrics.cardHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => VideoCardTile(video: widget.section.videos[index], horizontal: horizontal),
                  childCount: widget.section.videos.length,
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: _VideoRow(videos: widget.section.videos, horizontal: horizontal, cardWidth: metrics.cardWidth, cardHeight: metrics.cardHeight),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.videos, required this.horizontal, required this.cardWidth, required this.cardHeight});

  final List<VideoCard> videos;
  final bool horizontal;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: cardHeight,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          scrollDirection: Axis.horizontal,
          cacheExtent: 480,
          itemCount: videos.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(width: cardWidth, child: VideoCardTile(video: videos[index], horizontal: horizontal)),
        ),
      );
}

class _MaxWidth extends StatelessWidget {
  const _MaxWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _maxContentWidth), child: child),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section, this.showMore = true});

  final HomeSection section;
  final bool showMore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Row(children: [
          Expanded(child: Text(section.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          if (section.moreUrl != null && showMore)
            TextButton.icon(onPressed: () => context.push('/search', extra: SearchRouteRequest(initialUrl: section.moreUrl)),  iconAlignment: IconAlignment.end, icon: const Icon(Icons.arrow_forward_ios, size: 14), label: Text(AppLocalizations.of(context)!.more)),
        ]),
      );
}

String _currentPreviewMonth() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}';
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
