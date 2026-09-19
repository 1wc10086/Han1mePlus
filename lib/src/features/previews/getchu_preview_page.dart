import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/models/getchu_preview.dart';
import 'getchu_preview_controller.dart';

class GetchuPreviewPage extends ConsumerWidget {
  const GetchuPreviewPage({super.key, required this.month});

  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMonth = GetchuPreviewMonth.parse(month);
    final result = ref.watch(getchuPreviewsProvider(selectedMonth.value));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.getchuPreviews)),
      body: Column(
        children: [
          _MonthNavigation(
            month: selectedMonth,
            onPrevious: () => _replaceMonth(context, selectedMonth.previous),
            onNext: () => _replaceMonth(context, selectedMonth.next),
            onSelect: () => _selectMonth(context, selectedMonth),
          ),
          Expanded(
            child: result.when(
              loading: () => const Center(child: M3EContainedLoadingIndicator()),
              error: (error, _) => _Unavailable(error: error, onRetry: () => ref.invalidate(getchuPreviewsProvider(selectedMonth.value))),
              data: (feed) => feed.groups.isEmpty
                  ? _Unavailable(onRetry: () => ref.invalidate(getchuPreviewsProvider(selectedMonth.value)))
                  : CustomScrollView(
                      slivers: [
                        for (final group in feed.groups) ...[
                          SliverToBoxAdapter(child: _GroupHeader(title: group.releaseDate)),
                          SliverList.builder(itemCount: group.items.length, itemBuilder: (context, index) => _PreviewTile(item: group.items[index])),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context, GetchuPreviewMonth month) async {
    final selected = await showDatePicker(context: context, initialDate: month.date, firstDate: DateTime(1990), lastDate: DateTime(DateTime.now().year + 2, 12), initialDatePickerMode: DatePickerMode.year);
    if (selected != null && context.mounted) _replaceMonth(context, GetchuPreviewMonth(selected.year, selected.month));
  }

  void _replaceMonth(BuildContext context, GetchuPreviewMonth month) => context.replace('/previews/getchu/${month.value}');
}

class GetchuPreviewMonth {
  const GetchuPreviewMonth(this.year, this.month);

  final int year;
  final int month;

  factory GetchuPreviewMonth.parse(String value) {
    final now = DateTime.now();
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return GetchuPreviewMonth(now.year, now.month);
    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4));
    return year == null || month == null || month < 1 || month > 12 ? GetchuPreviewMonth(now.year, now.month) : GetchuPreviewMonth(year, month);
  }

  DateTime get date => DateTime(year, month);
  String get value => '$year${month.toString().padLeft(2, '0')}';
  GetchuPreviewMonth get previous => _fromDate(DateTime(year, month - 1));
  GetchuPreviewMonth get next => _fromDate(DateTime(year, month + 1));

  static GetchuPreviewMonth _fromDate(DateTime value) => GetchuPreviewMonth(value.year, value.month);
}

class _MonthNavigation extends StatelessWidget {
  const _MonthNavigation({required this.month, required this.onPrevious, required this.onNext, required this.onSelect});

  final GetchuPreviewMonth month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(tooltip: l10n.previousMonth, onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
            Expanded(child: TextButton.icon(onPressed: onSelect, icon: const Icon(Icons.calendar_month_outlined, size: 18), label: Text(l10n.getchuPreviewMonth(month.value)))),
            IconButton(tooltip: l10n.nextMonth, onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.item});

  final GetchuPreviewItem item;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push('/previews/getchu/detail/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: item.coverUrl == null
                      ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_not_supported_outlined))
                      : CachedNetworkImage(
                          imageUrl: item.coverUrl!,
                          httpHeaders: const {'Referer': 'https://www.getchu.com/', 'Cookie': 'getchu_adalt_flag=getchu.com; gc=gc'},
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    if ([item.brand, item.price].whereType<String>().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text([item.brand, item.price].whereType<String>().join('\n'), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 36), child: Icon(Icons.chevron_right)),
            ],
          ),
        ),
      );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 56),
            const SizedBox(height: 16),
            Text(error == null ? l10n.noGetchuPreviews : l10n.getchuPreviewUnavailable, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.reload)),
          ],
        ),
      ),
    );
  }
}
