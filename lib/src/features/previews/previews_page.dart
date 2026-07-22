import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/han1me_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';

final previewsProvider = FutureProvider.autoDispose.family<PreviewFeed, String>((ref, month) async {
  final settings = await ref.watch(settingsProvider.future);
  return ref.watch(han1meRepositoryProvider).previews(settings.baseUrl, month);
});

class PreviewsPage extends ConsumerWidget {
  const PreviewsPage({super.key, required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.previews), actions: [IconButton(tooltip: AppLocalizations.of(context)!.comments, onPressed: () => context.push('/comments/preview/$month', extra: AppLocalizations.of(context)!.previews), icon: const Icon(Icons.forum_outlined))]),
        body: ref.watch(previewsProvider(month)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: FilledButton(onPressed: () => ref.invalidate(previewsProvider(month)), child: Text(AppLocalizations.of(context)!.reload))),
              data: (feed) => CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _PreviewHeader(feed: feed)),
                SliverList.builder(itemCount: feed.items.length, itemBuilder: (context, index) => _PreviewTile(item: feed.items[index])),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ]),
            ),
      );
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.feed});
  final PreviewFeed feed;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (feed.coverUrl != null && feed.coverUrl!.isNotEmpty)
          AspectRatio(aspectRatio: 16 / 8, child: CachedNetworkImage(imageUrl: feed.coverUrl!, fit: BoxFit.cover, memCacheWidth: 960, fadeInDuration: Duration.zero)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(feed.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (feed.description.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(feed.description)),
      ]);
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.item});
  final PreviewItem item;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 104, height: 148, child: CachedNetworkImage(imageUrl: item.coverUrl, fit: BoxFit.cover, memCacheWidth: 240, fadeInDuration: Duration.zero))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (item.videoTitle != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.videoTitle!, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (item.brand != null || item.releaseDate != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text([item.brand, item.releaseDate].whereType<String>().join('  '), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline))),
            if (item.description != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.description!, maxLines: 3, overflow: TextOverflow.ellipsis)),
          ])),
        ]),
      );
}
