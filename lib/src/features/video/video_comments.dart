import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/han1me_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import '../shared/comments_page.dart' show CommentCard, CommentEditor, CommentSort;
import 'comment_episode_dialog.dart';
import 'comments_controller.dart';
import 'video_controller.dart';

Future<void> writeSelectedVideoComment(BuildContext context, WidgetRef ref, String parentVideoId) async {
  final id = ref.read(selectedCommentVideoIdProvider(parentVideoId));
  final text = await showDialog<String>(context: context, builder: (_) => CommentEditor(title: AppLocalizations.of(context)!.writeComment));
  final page = ref.read(commentsProvider(id)).valueOrNull;
  if (text == null || text.isEmpty || page?.csrfToken == null || page?.currentUserId == null) return;
  final settings = await ref.read(settingsProvider.future);
  await ref.read(han1meRepositoryProvider).postComment(settings.resolvedBaseUrl, page!.csrfToken!, page.currentUserId!, 'video', id, text);
  ref.invalidate(commentsProvider(id));
}

class VideoCommentsView extends ConsumerStatefulWidget {
  const VideoCommentsView({super.key, required this.video});

  final VideoDetail video;

  @override
  ConsumerState<VideoCommentsView> createState() => _VideoCommentsViewState();
}

class _VideoCommentsViewState extends ConsumerState<VideoCommentsView> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(selectedCommentVideoIdProvider(widget.video.id).notifier).state = widget.video.id);
  }

  @override
  void didUpdateWidget(VideoCommentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) Future.microtask(() => ref.read(selectedCommentVideoIdProvider(widget.video.id).notifier).state = widget.video.id);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final id = ref.watch(selectedCommentVideoIdProvider(widget.video.id));
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _CommentEpisodeBar(video: widget.video, commentVideoId: id, onSelected: (value) => ref.read(selectedCommentVideoIdProvider(widget.video.id).notifier).state = value)),
        _CommentsSliver(id: id),
        const SliverToBoxAdapter(child: SizedBox(height: 144)),
      ],
    );
  }
}

class _CommentEpisodeBar extends ConsumerWidget {
  const _CommentEpisodeBar({required this.video, required this.commentVideoId, required this.onSelected});

  final VideoDetail video;
  final String commentVideoId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = video.playlist.where((episode) => episode.id == commentVideoId).firstOrNull;
    final title = selected?.title ?? video.title;
    final sort = ref.watch(videoCommentSortProvider(commentVideoId));
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
          IconButton(
            tooltip: l10n.episodeList,
            onPressed: () async {
              final episode = await showCommentEpisodeDialog(context, episodes: video.playlist, selectedId: commentVideoId);
              if (episode != null) onSelected(episode.id);
            },
            icon: const Icon(Icons.switch_video_outlined),
          ),
          MenuAnchor(
            builder: (context, controller, child) => IconButton(tooltip: l10n.sort(l10n.defaultValue), onPressed: controller.open, icon: const Icon(Icons.sort)),
            menuChildren: CommentSort.values.map((item) => MenuItemButton(onPressed: () => ref.read(videoCommentSortProvider(commentVideoId).notifier).state = item, child: Text(_sortLabel(context, item), style: item == sort ? TextStyle(color: Theme.of(context).colorScheme.primary) : null))).toList(),
          ),
        ],
      ),
    );
  }
}

String _sortLabel(BuildContext context, CommentSort value) {
  final l10n = AppLocalizations.of(context)!;
  return switch (value) {
    CommentSort.latest => l10n.latest,
    CommentSort.earliest => l10n.earliest,
    CommentSort.mostReplies => l10n.mostReplies,
    CommentSort.mostLikes => l10n.mostLikes,
    CommentSort.mostDislikes => l10n.mostDislikes,
  };
}

class _CommentsSliver extends ConsumerWidget {
  const _CommentsSliver({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(videoCommentSortProvider(id));
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings?.commentsEnabled != true) return SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context)!.commentsDisabled)));
    return ref.watch(commentsProvider(id)).when(
      loading: () => const SliverFillRemaining(child: Center(child: M3EContainedLoadingIndicator())),
      error: (error, stackTrace) => SliverFillRemaining(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context)!.commentsLoadFailed), Text('$error', style: Theme.of(context).textTheme.bodySmall), FilledButton(onPressed: () => ref.invalidate(commentsProvider(id)), child: Text(AppLocalizations.of(context)!.retry))]))),
      data: (page) => page.comments.isEmpty ? SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context)!.noComments))) : _commentList(page, settings!.blockedCommentKeywords, settings.blockedCommentUsers, sort, ref),
    );
  }

  Widget _commentList(CommentPage page, List<String> keywords, List<String> users, CommentSort sort, WidgetRef ref) {
    final comments = _sort(_visibleComments(page.comments, keywords, users), sort);
    return SliverList.builder(itemCount: comments.length, itemBuilder: (context, index) => CommentCard(comment: comments[index], token: page.csrfToken, onChanged: () => ref.invalidate(commentsProvider(id))));
  }

  List<Comment> _sort(List<Comment> comments, CommentSort sort) {
    final result = [...comments];
    result.sort((left, right) => switch (sort) {
      CommentSort.latest => right.id.compareTo(left.id),
      CommentSort.earliest => left.id.compareTo(right.id),
      CommentSort.mostReplies => (right.replyCount ?? 0).compareTo(left.replyCount ?? 0),
      CommentSort.mostLikes => (right.likesSum ?? 0).compareTo(left.likesSum ?? 0),
      CommentSort.mostDislikes => ((right.likesCount ?? 0) - (right.likesSum ?? 0)).compareTo((left.likesCount ?? 0) - (left.likesSum ?? 0)),
    });
    return result;
  }

  List<Comment> _visibleComments(List<Comment> comments, List<String> keywords, List<String> users) => comments.where((comment) => !keywords.any((keyword) => comment.content.toLowerCase().contains(keyword.toLowerCase())) && !users.any((user) => comment.username.toLowerCase().contains(user.toLowerCase()))).toList();
}
