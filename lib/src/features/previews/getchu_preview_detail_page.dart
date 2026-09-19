import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/models/getchu_preview.dart';
import '../../domain/models/video.dart';
import 'getchu_preview_controller.dart';

const _getchuImageHeaders = {'Referer': 'https://www.getchu.com/', 'Cookie': 'getchu_adalt_flag=getchu.com; gc=gc'};

class GetchuPreviewDetailPage extends ConsumerWidget {
  const GetchuPreviewDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final result = ref.watch(getchuPreviewDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.getchuPreviewDetail)),
      body: result.when(
        loading: () => const Center(child: M3EContainedLoadingIndicator()),
        error: (error, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(getchuPreviewDetailProvider(id)), icon: const Icon(Icons.refresh), label: Text(l10n.reload))),
        data: (detail) => _DetailContent(detail: detail),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final GetchuPreviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final sections = detail.sections.isEmpty && detail.description != null
        ? [GetchuPreviewSection(title: '商品紹介', body: detail.description!)]
        : detail.sections;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _ProductSummary(detail: detail),
        for (final section in sections) ...[
          const SizedBox(height: 24),
          _TextSection(section: section),
        ],
        if (detail.sampleImages.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SampleImages(images: detail.sampleImages),
        ],
        if (detail.seriesItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SeriesItems(items: detail.seriesItems),
        ],
      ],
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.detail});

  final GetchuPreviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metadata = [detail.brand, detail.releaseDate, detail.price].whereType<String>().toList();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final cover = detail.coverUrl == null
              ? null
              : CachedNetworkImage(imageUrl: detail.coverUrl!, httpHeaders: _getchuImageHeaders, fit: BoxFit.cover, alignment: Alignment.topCenter, fadeInDuration: Duration.zero);
          final information = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (metadata.isNotEmpty) ...[const SizedBox(height: 12), Text(metadata.join('\n'))],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (detail.videoUrls.isNotEmpty)
                      FilledButton.icon(onPressed: () => _play(context, 0), icon: const Icon(Icons.play_arrow), label: Text(l10n.playTrailer)),
                    OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(detail.productUrl), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: Text(l10n.openGetchu)),
                  ],
                ),
                if (detail.videoUrls.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var index = 1; index < detail.videoUrls.length; index++)
                        TextButton.icon(onPressed: () => _play(context, index), icon: const Icon(Icons.play_circle_outline), label: Text(l10n.trailerNumber(index + 1))),
                    ],
                  ),
                ],
              ],
            ),
          );
          if (compact) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (cover != null) AspectRatio(aspectRatio: 4 / 3, child: cover), information]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [if (cover != null) SizedBox(width: 220, child: cover), Expanded(child: information)],
            ),
          );
        },
      ),
    );
  }

  void _play(BuildContext context, int index) {
    final video = VideoDetail(
      id: 'getchu-${detail.id}-$index',
      title: detail.videoUrls.length == 1 ? detail.title : '${detail.title} ${index + 1}',
      coverUrl: detail.coverUrl,
      artist: detail.brand,
      uploadDate: detail.releaseDate,
      description: detail.description,
      sources: [VideoSource(quality: 'Trailer', url: detail.videoUrls[index], type: 'video/mp4')],
      tags: const [],
      playlist: const [],
      related: const [],
    );
    context.push('/video/${video.id}', extra: video);
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.section});

  final GetchuPreviewSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (section.title) {
      final value when value.contains('商品紹介') => l10n.productIntroduction,
      final value when value.contains('ストーリー') => l10n.story,
      final value when value.contains('スタッフ') => l10n.staff,
      final value => value,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SelectionArea(child: Text(section.body, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}

class _SampleImages extends StatelessWidget {
  const _SampleImages({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.previewImages(images.length), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => showDialog<void>(context: context, barrierColor: Colors.black87, builder: (_) => _ImageViewer(images: images, initialIndex: index)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(imageUrl: images[index], httpHeaders: _getchuImageHeaders, width: 200, fit: BoxFit.cover, fadeInDuration: Duration.zero),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeriesItems extends StatelessWidget {
  const _SeriesItems({required this.items});

  final List<GetchuPreviewItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.getchuSeries, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _SeriesCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.item});

  final GetchuPreviewItem item;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/previews/getchu/detail/${item.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.coverUrl == null
                      ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_not_supported_outlined))
                      : CachedNetworkImage(imageUrl: item.coverUrl!, httpHeaders: _getchuImageHeaders, fit: BoxFit.cover, fadeInDuration: Duration.zero),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
                      if (item.price != null) ...[const SizedBox(height: 4), Text(item.price!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late var _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => InteractiveViewer(child: Center(child: CachedNetworkImage(imageUrl: widget.images[index], httpHeaders: _getchuImageHeaders, fit: BoxFit.contain, fadeInDuration: Duration.zero))),
            ),
            SafeArea(child: IconButton(onPressed: () => Navigator.pop(context), color: Colors.white, icon: const Icon(Icons.close))),
            Positioned(left: 0, right: 0, bottom: 24, child: Text('${_index + 1} / ${widget.images.length}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))),
          ],
        ),
      );
}
