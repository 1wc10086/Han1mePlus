import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/settings.dart';
import '../../data/assets/search_option_catalog.dart';
import '../../data/han1me_repository.dart';
import '../../data/local/library_repository.dart';
import '../../domain/models/library.dart';
import '../../domain/models/search_query.dart';
import '../../domain/models/video.dart';
import '../account/account_controller.dart';
import '../library/remote_library_controller.dart';
import '../settings/settings_controller.dart';
import '../shared/video_card.dart';
import 'video_controller.dart';

class VideoDescriptionView extends ConsumerStatefulWidget {
  const VideoDescriptionView({super.key, required this.video});

  final VideoDetail video;

  @override
  ConsumerState<VideoDescriptionView> createState() => _VideoDescriptionViewState();
}

class _VideoDescriptionViewState extends ConsumerState<VideoDescriptionView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final video = widget.video;
    final translation = ref.watch(videoTranslationProvider(video.id)).valueOrNull;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TitleBlock(video: video, title: translation?.title),
              _ArtistRow(video: video),
              _Description(video: video, captionTitle: translation?.captionTitle, description: translation?.description),
              _TagList(video: video),
              if (video.playlist.isNotEmpty) _SeriesVideos(videos: video.playlist, currentVideoId: video.id),
              _TranslateButton(video: video),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class RelatedVideosView extends ConsumerWidget {
  const RelatedVideosView({super.key, required this.videos});

  final List<VideoCard> videos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final authors = settings?.blockedAuthors ?? const <String>[];
    final titles = settings?.blockedVideoTitleKeywords ?? const <String>[];
    final visible = settings?.applyRecommendationFiltersToRelated != true ? videos : videos.where((video) => !titles.any((keyword) => video.title.toLowerCase().contains(keyword.toLowerCase())) && !authors.any((author) => (video.artist ?? '').toLowerCase().contains(author.toLowerCase()))).toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: visible.length,
      itemBuilder: (context, index) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _RelatedVideoTile(video: visible[index])),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.video, this.title});

  final VideoDetail video;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title ?? video.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (video.views != null) _MetaText(icon: Icons.visibility_outlined, label: video.views!),
              if (video.uploadDate != null) _MetaText(icon: Icons.calendar_today_outlined, label: video.uploadDate!),
              if (video.genre != null) _MetaText(icon: Icons.local_offer_outlined, label: video.genre!),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtistRow extends ConsumerWidget {
  const _ArtistRow({required this.video});

  final VideoDetail video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if ((video.artist ?? '').isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final account = ref.watch(accountProvider).valueOrNull;
    final remote = account == null ? null : ref.watch(remoteLibraryProvider).valueOrNull;
    final library = ref.watch(libraryProvider).value ?? const LibraryState();
    final persisted = (remote?.subscriptionArtists ?? library.artists).any((item) => item.name == video.artist);
    final subscribed = ref.watch(subscriptionOverrideProvider(video.id)) ?? persisted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('/search', extra: SearchRouteRequest(initialUrl: Uri(path: '/search', queryParameters: {'query': video.artist!}).toString())),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: theme.colorScheme.surfaceContainerHighest, backgroundImage: video.artistAvatarUrl == null ? null : NetworkImage(video.artistAvatarUrl!), child: video.artistAvatarUrl == null ? Text(video.artist!.characters.first, style: theme.textTheme.titleMedium) : null),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(video.artist!, style: theme.textTheme.titleMedium), Text(AppLocalizations.of(context)!.studio, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))])),
                FilledButton.tonal(
                  onPressed: account == null
                      ? () => ref.read(libraryProvider.notifier).setSubscription(video, !subscribed)
                      : video.artistId == null || (video.csrfToken ?? account.csrfToken) == null || (video.subscriptionUserId ?? video.currentUserId ?? account.id) == null
                          ? null
                          : () => _setSubscription(ref, video.csrfToken ?? account.csrfToken!, video.subscriptionUserId ?? video.currentUserId ?? account.id!, video.artistId!, !subscribed),
                  child: Text(subscribed ? AppLocalizations.of(context)!.subscribed : AppLocalizations.of(context)!.subscribe),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setSubscription(WidgetRef ref, String token, String userId, String artistId, bool enabled) async {
    ref.read(subscriptionOverrideProvider(video.id).notifier).state = enabled;
    try {
      final settings = await ref.read(settingsProvider.future);
      await ref.read(han1meRepositoryProvider).setSubscription(settings.resolvedBaseUrl, token, userId, artistId, enabled);
      ref.invalidate(remoteLibraryProvider);
    } catch (_) {
      ref.read(subscriptionOverrideProvider(video.id).notifier).state = !enabled;
    }
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.video, this.captionTitle, this.description});

  final VideoDetail video;
  final String? captionTitle;
  final String? description;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.description ?? widget.video.description ?? '';
    final l10n = AppLocalizations.of(context)!;
    if (description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.video.uploader case final uploader?) ...[Text('${l10n.uploader}: $uploader', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)), const SizedBox(height: 8)],
                  if (widget.captionTitle ?? widget.video.captionTitle case final title?) ...[Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 8)],
                  Text(description, maxLines: _expanded ? null : 4, overflow: _expanded ? null : TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagList extends ConsumerStatefulWidget {
  const _TagList({required this.video});

  final VideoDetail video;

  @override
  ConsumerState<_TagList> createState() => _TagListState();
}

class _TagListState extends ConsumerState<_TagList> {
  final _wrapKey = GlobalKey();
  final _firstChipKey = GlobalKey();
  var _expanded = false;
  var _canExpand = false;
  double? _collapsedHeight;

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wrap = _wrapKey.currentContext?.size;
      final chip = _firstChipKey.currentContext?.size;
      if (wrap == null || chip == null) return;
       final height = (chip.height < 40.0 ? 40.0 : chip.height) * 2.0 + 6.0;
      final canExpand = wrap.height > height + .5;
      if (_collapsedHeight != height || _canExpand != canExpand) setState(() {
        _collapsedHeight = height;
        _canExpand = canExpand;
      });
    });
  }

  Future<void> _editTags(String mode) async {
    await context.push('/video/${widget.video.id}/tags/$mode');
    ref.invalidate(videoDetailProvider(widget.video.id));
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.video.tags;
    final account = ref.watch(accountProvider).valueOrNull;
    final enabled = account != null && (widget.video.csrfToken ?? account.csrfToken) != null;
    final catalog = ref.watch(searchOptionCatalogProvider).valueOrNull;
    final localeKey = searchOptionLocaleKey(Localizations.localeOf(context));
    final l10n = AppLocalizations.of(context)!;
    if (tags.isEmpty && !enabled) return const SizedBox.shrink();
    final children = <Widget>[
      for (var index = 0; index < tags.length; index++)
        ActionChip(
          key: index == 0 ? _firstChipKey : null,
          label: Text('${catalog?.localizeTag(tags[index].name, localeKey) ?? tags[index].name}${tags[index].count == null ? '' : ' (${tags[index].count})'}'),
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/search', extra: SearchRouteRequest(initialUrl: tags[index].href ?? Uri(path: '/search', queryParameters: {'tags[]': tags[index].name}).toString())),
        ),
      IconButton(tooltip: l10n.addTags, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 40, height: 40), icon: const Icon(Icons.add), onPressed: enabled ? () => _editTags('add') : null),
      IconButton(tooltip: l10n.removeTags, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 40, height: 40), icon: const Icon(Icons.remove), onPressed: enabled ? () => _editTags('remove') : null),
    ];
    if (tags.isEmpty) children.first = SizedBox(key: _firstChipKey, width: 40, height: 40, child: children.first);
    _measure();
    final wrap = Wrap(key: _wrapKey, spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: children);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_expanded || _collapsedHeight == null)
              wrap
            else
              LayoutBuilder(
                builder: (context, constraints) => ClipRect(
                  child: SizedBox(
                    height: _collapsedHeight,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: wrap,
                    ),
                  ),
                ),
              ),
            if (_canExpand) IconButton(tooltip: _expanded ? l10n.collapse : l10n.expand, onPressed: () => setState(() => _expanded = !_expanded), icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more)),
          ],
        ),
      ),
    );
  }
}

class _SeriesVideos extends StatelessWidget {
  const _SeriesVideos({required this.videos, required this.currentVideoId});

  final List<VideoCard> videos;
  final String currentVideoId;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 8, 8), child: Row(children: [Expanded(child: Text(AppLocalizations.of(context)!.seriesVideos, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), TextButton(onPressed: () => _showAll(context), child: Text(AppLocalizations.of(context)!.more))])),
          SizedBox(height: 190, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: videos.length, separatorBuilder: (context, index) => const SizedBox(width: 12), itemBuilder: (context, index) => SizedBox(width: 180, child: VideoCardTile(video: videos[index], horizontal: true, selected: videos[index].id == currentVideoId)))),
        ],
      );

  Future<void> _showAll(BuildContext context) => showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true, builder: (context) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .78, child: Column(children: [Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 12), child: Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(context)!.seriesVideos, style: Theme.of(context).textTheme.titleLarge))), Expanded(child: VideoCardGrid(videos: videos, itemBuilder: (context, index, video, horizontal) => VideoCardTile(video: video, horizontal: horizontal, selected: video.id == currentVideoId)))]))));
}

class _TranslateButton extends ConsumerWidget {
  const _TranslateButton({required this.video});

  final VideoDetail video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoTranslationProvider(video.id));
    ref.listen(videoTranslationProvider(video.id), (previous, next) {
      if (next.hasError && previous?.hasError != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translationFailed)));
      }
    });
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: TextButton(
          onPressed: state.isLoading
              ? null
              : () {
                  final language = ref.read(settingsProvider).valueOrNull?.language ?? AppLanguage.system;
                  final locale = Localizations.localeOf(context);
                  ref.read(videoTranslationProvider(video.id).notifier).translate(video, language, locale.toLanguageTag());
                },
          child: Text(state.isLoading ? AppLocalizations.of(context)!.translating : AppLocalizations.of(context)!.translate),
        ),
      ),
    );
  }
}

class _RelatedVideoTile extends StatelessWidget {
  const _RelatedVideoTile({required this.video});

  final VideoCard video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: video.id.isEmpty ? null : () => context.push('/video/${video.id}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 144, height: 81, child: CachedNetworkImage(imageUrl: video.coverUrl, fit: BoxFit.cover, placeholder: (context, url) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest), errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image_outlined))))),
              const SizedBox(width: 12),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 6), if (video.artist != null) Text(video.artist!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)), if (video.views != null) Text(video.views!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))])),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.bodySmall)]);
}
