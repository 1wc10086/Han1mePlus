import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/han1me_repository.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import '../account/account_controller.dart';

enum CommentSort { latest, earliest, mostReplies, mostLikes, mostDislikes }

final contentCommentSortProvider = StateProvider.autoDispose.family<CommentSort, ({String id, String type})>((ref, target) => CommentSort.latest);

final contentCommentsProvider = FutureProvider.autoDispose.family<CommentPage, ({String id, String type})>((ref, target) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 10), link.close);
  ref.onDispose(timer.cancel);
  ref.watch(accountProvider);
  final settings = await ref.watch(settingsProvider.future);
  return ref.watch(han1meRepositoryProvider).comments(settings.resolvedBaseUrl, target.id, type: target.type);
});

class CommentsPage extends ConsumerWidget {
  const CommentsPage({super.key, required this.id, required this.type, required this.title});
  final String id;
  final String type;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = (id: id, type: type);
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(accountProvider).valueOrNull;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final sort = ref.watch(contentCommentSortProvider(target));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commentsTitle(title))),
      body: settings?.commentsEnabled != true
          ? Center(child: Text(l10n.commentsDisabled))
          : ref.watch(contentCommentsProvider(target)).when(
            loading: () => const Center(child: M3EContainedLoadingIndicator()),
            error: (error, _) => Center(child: FilledButton(onPressed: () => ref.invalidate(contentCommentsProvider(target)), child: Text(l10n.reload))),
            data: (page) => page.comments.isEmpty
                ? Center(child: Text(l10n.noComments))
                : _commentList(page, settings!.blockedCommentKeywords, sort, target, ref),
          ),
      floatingActionButton: account == null || settings?.commentsEnabled != true ? null : FloatingActionButton(onPressed: () => _writeComment(context, ref, target), child: const Icon(Icons.add_comment_outlined)),
    );
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

  List<Comment> _visibleComments(List<Comment> comments, List<String> keywords) => comments.where((comment) => !keywords.any((keyword) => comment.content.toLowerCase().contains(keyword.toLowerCase()))).toList();

  Widget _commentList(CommentPage page, List<String> keywords, CommentSort sort, ({String id, String type}) target, WidgetRef ref) {
    final comments = _sort(_visibleComments(page.comments, keywords), sort);
    return ListView.builder(
      itemCount: comments.length + 1,
      itemBuilder: (context, index) => index == 0
          ? _SortButton(value: sort, onSelected: (value) => ref.read(contentCommentSortProvider(target).notifier).state = value)
          : CommentCard(comment: comments[index - 1], token: page.csrfToken, onChanged: () => ref.invalidate(contentCommentsProvider(target))),
    );
  }

  Future<void> _writeComment(BuildContext context, WidgetRef ref, ({String id, String type}) target) async {
    final l10n = AppLocalizations.of(context)!;
    final text = await showDialog<String>(context: context, builder: (_) => CommentEditor(title: l10n.writeComment, hint: l10n.commentHint));
    if (text == null || text.isEmpty) return;
    final page = ref.read(contentCommentsProvider(target)).valueOrNull;
    if (page?.csrfToken == null || page?.currentUserId == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).postComment(settings.resolvedBaseUrl, page!.csrfToken!, page.currentUserId!, target.type, target.id, text);
    ref.invalidate(contentCommentsProvider(target));
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onSelected});
  final CommentSort value;
  final ValueChanged<CommentSort> onSelected;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        child: MenuAnchor(
          builder: (context, controller, child) => OutlinedButton.icon(onPressed: controller.open, icon: const Icon(Icons.sort), label: Text(_label(context, value))),
          menuChildren: CommentSort.values.map((item) => MenuItemButton(onPressed: () => onSelected(item), child: Text(_label(context, item)))).toList(),
        ),
      );

  String _label(BuildContext context, CommentSort value) {
    final l10n = AppLocalizations.of(context)!;
    return switch (value) { CommentSort.latest => l10n.latest, CommentSort.earliest => l10n.earliest, CommentSort.mostReplies => l10n.mostReplies, CommentSort.mostLikes => l10n.mostLikes, CommentSort.mostDislikes => l10n.mostDislikes };
  }
}

class CommentCard extends ConsumerWidget {
  const CommentCard({super.key, required this.comment, required this.token, required this.onChanged});
  final Comment comment;
  final String? token;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [CircleAvatar(backgroundImage: comment.avatarUrl?.isNotEmpty == true ? NetworkImage(comment.avatarUrl!) : null, child: comment.avatarUrl?.isNotEmpty == true ? null : Text(comment.username.characters.first)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(comment.username, style: Theme.of(context).textTheme.titleSmall), if (comment.timeAgo != null) Text(comment.timeAgo!, style: Theme.of(context).textTheme.bodySmall)]))]),
            const SizedBox(height: 10),
            Text(comment.content),
            const SizedBox(height: 6),
            Row(children: [
              IconButton(onPressed: token == null ? null : () => _vote(ref, true), icon: Icon(comment.liked ? Icons.thumb_up : Icons.thumb_up_outlined), visualDensity: VisualDensity.compact),
              Text(comment.likesSum?.toString() ?? comment.likeCount ?? '0'),
              IconButton(onPressed: token == null ? null : () => _vote(ref, false), icon: Icon(comment.disliked ? Icons.thumb_down : Icons.thumb_down_outlined), visualDensity: VisualDensity.compact),
              if (comment.hasMoreReplies) TextButton(onPressed: () => _showReplies(context, ref), child: Text(comment.replyCount == null ? AppLocalizations.of(context)!.viewReplies : AppLocalizations.of(context)!.viewRepliesCount(comment.replyCount!))),
              if (comment.id.isNotEmpty) TextButton(onPressed: token == null ? null : () => _reply(context, ref), child: Text(AppLocalizations.of(context)!.reply)),
            ]),
          ]),
        ),
      );

  Future<void> _vote(WidgetRef ref, bool positive) async {
    if (token == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).voteComment(settings.resolvedBaseUrl, token!, comment, positive);
    onChanged();
  }

  Future<void> _reply(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(context: context, builder: (_) => CommentEditor(title: AppLocalizations.of(context)!.replyComment));
    if (text == null || text.isEmpty || token == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref.read(han1meRepositoryProvider).replyComment(settings.resolvedBaseUrl, token!, comment.id, text);
    onChanged();
  }

  Future<void> _showReplies(BuildContext context, WidgetRef ref) async {
    final settings = await ref.read(settingsProvider.future);
    final page = await ref.read(han1meRepositoryProvider).replies(settings.resolvedBaseUrl, comment.id);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: ListView.builder(itemCount: page.comments.length, itemBuilder: (context, index) => CommentCard(comment: page.comments[index], token: token, onChanged: onChanged))));
  }
}

class CommentEditor extends StatefulWidget {
  const CommentEditor({super.key, required this.title, this.hint});
  final String title;
  final String? hint;
  @override
  State<CommentEditor> createState() => _CommentEditorState();
}

class _CommentEditorState extends State<CommentEditor> {
  final _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(controller: _controller, autofocus: true, minLines: 3, maxLines: 6, decoration: InputDecoration(hintText: widget.hint)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)), FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(AppLocalizations.of(context)!.send))],
      );
}
