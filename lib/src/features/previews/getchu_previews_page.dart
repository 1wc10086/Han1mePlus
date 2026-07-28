import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/getchu_repository.dart';
import '../../data/remote/getchu_api.dart';
import '../../domain/models/getchu_preview.dart';

final getchuPreviewsProvider = FutureProvider.autoDispose.family<GetchuPreview, String>((ref, month) => ref.watch(getchuRepositoryProvider).previews(month));

class GetchuPreviewsPage extends ConsumerWidget {
  const GetchuPreviewsPage({super.key, required this.month});

  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMonth = _GetchuMonth.parse(month);
    final result = ref.watch(getchuPreviewsProvider(selectedMonth.value));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.getchu)),
      body: Column(
        children: [
          _MonthNavigation(
            month: selectedMonth,
            onPrevious: () => _replaceMonth(context, selectedMonth.previous),
            onNext: selectedMonth.isCurrentOrFuture ? null : () => _replaceMonth(context, selectedMonth.next),
            onSelect: () async {
              final selected = await showDatePicker(context: context, initialDate: selectedMonth.date, firstDate: DateTime(1990), lastDate: _GetchuMonth.current.date, initialDatePickerMode: DatePickerMode.year);
              if (selected != null && context.mounted) _replaceMonth(context, _GetchuMonth(selected.year, selected.month));
            },
          ),
          Expanded(
            child: result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _Unavailable(message: l10n.getchuPreviewUnavailableDescription, onPrevious: () => _replaceMonth(context, selectedMonth.previous), onRetry: () => ref.invalidate(getchuPreviewsProvider(selectedMonth.value))),
              data: (preview) => preview.groups.isEmpty
                  ? _Unavailable(message: l10n.getchuPreviewUnavailableDescription, onPrevious: () => _replaceMonth(context, selectedMonth.previous), onRetry: () => ref.invalidate(getchuPreviewsProvider(selectedMonth.value)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                      itemCount: preview.groups.length,
                      itemBuilder: (context, index) => _Group(group: preview.groups[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _replaceMonth(BuildContext context, _GetchuMonth month) => context.replace('/getchu-previews/${month.value}');
}

class _GetchuMonth {
  const _GetchuMonth(this.year, this.month);

  final int year;
  final int month;

  static _GetchuMonth get current {
    final now = DateTime.now();
    return _GetchuMonth(now.year, now.month);
  }

  factory _GetchuMonth.parse(String value) {
    final match = RegExp(r'^(\d{4})(\d{2})$').firstMatch(value);
    final year = int.tryParse(match?.group(1) ?? '');
    final month = int.tryParse(match?.group(2) ?? '');
    return year == null || month == null || month < 1 || month > 12 ? current : _GetchuMonth(year, month);
  }

  DateTime get date => DateTime(year, month);
  String get value => '$year${month.toString().padLeft(2, '0')}';
  String get label => '$year/${month.toString().padLeft(2, '0')}';
  _GetchuMonth get previous => _fromDate(DateTime(year, month - 1));
  _GetchuMonth get next => _fromDate(DateTime(year, month + 1));
  bool get isCurrentOrFuture => date.compareTo(current.date) >= 0;

  static _GetchuMonth _fromDate(DateTime value) => _GetchuMonth(value.year, value.month);
}

class _MonthNavigation extends StatelessWidget {
  const _MonthNavigation({required this.month, required this.onPrevious, required this.onNext, required this.onSelect});

  final _GetchuMonth month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [IconButton(tooltip: l10n.previousMonth, onPressed: onPrevious, icon: const Icon(Icons.chevron_left)), Expanded(child: TextButton.icon(onPressed: onSelect, icon: const Icon(Icons.calendar_month_outlined, size: 18), label: Text(l10n.getchuPreviewMonth(month.label)))), IconButton(tooltip: l10n.nextMonth, onPressed: onNext, icon: const Icon(Icons.chevron_right))]),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.message, required this.onPrevious, required this.onRetry});

  final String? message;
  final VoidCallback onPrevious;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.event_busy_outlined, size: 56), const SizedBox(height: 16), Text(l10n.getchuPreviewUnavailable, style: Theme.of(context).textTheme.titleMedium), if (message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(message!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),), const SizedBox(height: 20), Wrap(spacing: 8, children: [FilledButton.tonalIcon(onPressed: onPrevious, icon: const Icon(Icons.chevron_left), label: Text(l10n.previousMonth)), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.reload))])])));
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final GetchuPreviewGroup group;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 8), child: Text(group.releaseDate, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), ...group.items.map((item) => _Item(item: item)), const SizedBox(height: 16)]);
}

class _Item extends StatelessWidget {
  const _Item({required this.item});

  final GetchuPreviewItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(item.detailUrl), mode: LaunchMode.externalApplication),
          child: SizedBox(
            height: 128,
            child: Row(children: [
              AspectRatio(aspectRatio: 0.72, child: item.coverUrl == null ? ColoredBox(color: theme.colorScheme.surfaceContainerHighest) : CachedNetworkImage(imageUrl: item.coverUrl!, httpHeaders: GetchuApi.imageHeaders, fit: BoxFit.cover, memCacheWidth: 240, fadeInDuration: Duration.zero, errorWidget: (context, url, error) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest))),
              Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const Spacer(), if (item.brand != null) Text(item.brand!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)), if (item.price != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.price!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)))]))),
              const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.open_in_new, size: 18)),
            ]),
          ),
        ),
      ),
    );
  }
}
