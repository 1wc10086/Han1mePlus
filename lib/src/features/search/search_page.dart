import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/assets/search_option_catalog.dart';
import '../../data/remote/han1me_api.dart' show SearchResult;
import '../settings/settings_controller.dart';
import '../shared/compact_video_card.dart';
import '../shared/video_card.dart';
import 'search_controller.dart';

const _compactSearchGenres = {'裏番', '泡麵番'};

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchInitProvider.notifier).state = widget.initialUrl;
      });
    }
    final query = ref.read(searchQueryProvider);
    if (query.text.isNotEmpty) _textController.text = query.text;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final options = ref.watch(searchOptionCatalogProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final useCompactCards = (ref.watch(settingsProvider).valueOrNull?.useCompactSearchCards ?? true) &&
        _compactSearchGenres.contains(options?.genres.canonical(query.genre) ?? query.genre);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: TextField(
          controller: _textController,
          autofocus: widget.initialUrl == null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: l10n.clear,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _textController.clear();
                        ref.read(searchQueryProvider.notifier).text('');
                      },
                    ),
            ),
          ),
          onSubmitted: ref.read(searchQueryProvider.notifier).text,
        ),
      ),
      body: Column(
        children: [
          _Filters(options: options, query: query, notifier: ref.read(searchQueryProvider.notifier)),
          Expanded(
            child: result.when(
              loading: () => const Center(child: M3EContainedLoadingIndicator()),
              error: (error, stackTrace) => _ErrorView(error: error, onRetry: () => ref.invalidate(searchResultsProvider)),
              data: (page) => page.items.isEmpty
                  ? _EmptyState(message: l10n.noSearchResults)
                  : useCompactCards
                      ? CompactVideoCardGrid(
                          videos: page.items,
                          itemBuilder: (context, index, video) => CompactVideoCard(
                            video: video,
                            onTap: query.type == 'artist' ? () => ref.read(searchQueryProvider.notifier).artist(video.uploadTime ?? video.title) : null,
                          ),
                        )
                      : VideoCardGrid(
                          videos: page.items,
                          itemBuilder: (context, index, video, horizontal) => VideoCardTile(
                            video: video,
                            horizontal: horizontal,
                            onTap: query.type == 'artist' ? () => ref.read(searchQueryProvider.notifier).artist(video.uploadTime ?? video.title) : null,
                          ),
                        ),
            ),
          ),
          _PaginationBar(
            result: result.valueOrNull,
            onChanged: ref.read(searchQueryProvider.notifier).page,
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.options, required this.query, required this.notifier});

  final SearchOptionCatalog? options;
  final SearchQuery query;
  final SearchQueryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (options == null) return const SizedBox(height: 56);
    final locale = searchOptionLocaleKey(Localizations.localeOf(context));
    final genres = options!.genres;
    final sorts = options!.sorts;
    final durations = options!.durations;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _MenuFilterButton(
            label: l10n.category(query.genre.isEmpty ? l10n.all : genres.localize(query.genre, locale) ?? query.genre),
            icon: Icons.category_outlined,
            values: genres.options.map((item) => item.searchKey ?? '').toList(),
            onSelected: notifier.genre,
            formatter: (value) => value.isEmpty ? l10n.all : genres.localize(value, locale) ?? value,
          ),
          _MenuFilterButton(
            label: l10n.sort(query.sort.isEmpty ? l10n.defaultValue : sorts.localize(query.sort, locale) ?? query.sort),
            icon: Icons.sort,
            values: sorts.options.map((item) => item.searchKey ?? '').toList(),
            onSelected: notifier.sort,
            formatter: (value) => value.isEmpty ? l10n.defaultValue : sorts.localize(value, locale) ?? value,
          ),
          _ActionFilterButton(
            label: l10n.releaseDate(query.date.isEmpty ? l10n.all : options!.releaseDates.localize(query.date, locale) ?? query.date),
            icon: Icons.calendar_month_outlined,
            onPressed: () async {
              final date = await _showDateFilter(context, query.date, options!.releaseDates.options, locale);
              if (date != null) notifier.date(date);
            },
          ),
          _ActionFilterButton(
            label: query.tags.isEmpty ? l10n.tags : l10n.tagsSelected(query.tags.length),
            icon: Icons.sell_outlined,
            onPressed: () async {
              final selection = await _showTagFilter(context, query.tags, query.broad, options!, locale);
              if (selection != null) notifier.tags(selection.tags, selection.broad);
            },
          ),
          _MenuFilterButton(
            label: l10n.duration(query.duration.isEmpty ? l10n.all : durations.localize(query.duration, locale) ?? query.duration),
            icon: Icons.schedule_outlined,
            values: durations.options.map((item) => item.searchKey ?? '').toList(),
            onSelected: notifier.duration,
            formatter: (value) => value.isEmpty ? l10n.all : durations.localize(value, locale) ?? value,
          ),
          _ActionFilterButton(
            label: l10n.searchAuthors,
            icon: Icons.person_search_outlined,
            selected: query.type == 'artist',
            onPressed: () => notifier.type(query.type == 'artist' ? '' : 'artist'),
          ),
        ].map((child) => Padding(padding: const EdgeInsets.only(right: 8), child: child)).toList(),
      ),
    );
  }
}

class _MenuFilterButton extends StatelessWidget {
  const _MenuFilterButton({required this.label, required this.icon, required this.values, required this.onSelected, required this.formatter});

  final String label;
  final IconData icon;
  final List<String> values;
  final ValueChanged<String> onSelected;
  final String Function(String) formatter;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        menuChildren: values
            .map((value) => MenuItemButton(onPressed: () => onSelected(value), child: Text(formatter(value))))
            .toList(growable: false),
        builder: (context, controller, child) => FilledButton.tonalIcon(
          onPressed: controller.open,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
}

class _ActionFilterButton extends StatelessWidget {
  const _ActionFilterButton({required this.label, required this.icon, required this.onPressed, this.selected = false});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => selected
      ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label))
      : FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
}

enum _DateMode { range, month }

Future<String?> _showDateFilter(BuildContext context, String currentDate, List<SearchOption> options, String locale) => showDialog<String>(
      context: context,
      builder: (context) => _DateFilterDialog(currentDate: currentDate, options: options, locale: locale),
    );

class _DateFilterDialog extends StatefulWidget {
  const _DateFilterDialog({required this.currentDate, required this.options, required this.locale});

  final String currentDate;
  final List<SearchOption> options;
  final String locale;

  @override
  State<_DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<_DateFilterDialog> {
  _DateMode _mode = _DateMode.range;
  String _range = '';
  String _year = '';
  String _month = '';

  @override
  void initState() {
    super.initState();
    if (widget.options.map((item) => item.searchKey).contains(widget.currentDate)) {
      _range = widget.currentDate;
    } else if (widget.currentDate.isNotEmpty) {
      final values = widget.currentDate.split(' ');
      _year = values.take(2).join(' ');
      _month = values.length > 2 ? values.skip(2).take(2).join(' ') : '';
      _mode = _DateMode.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final years = [for (var year = DateTime.now().year; year >= 1990; year--) '$year 年'];
    return AlertDialog(
      title: Text(l10n.releaseDateTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<_DateMode>(
              segments: [
                ButtonSegment(value: _DateMode.range, label: Text(l10n.dateRange)),
                ButtonSegment(value: _DateMode.month, label: Text(l10n.specificYearMonth)),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => setState(() => _mode = value.first),
            ),
            const SizedBox(height: 16),
            if (_mode == _DateMode.range)
              DropdownButtonFormField<String>(
                value: _range,
                decoration: InputDecoration(labelText: l10n.releaseDateTitle),
                 items: widget.options.map((item) => DropdownMenuItem(value: item.searchKey ?? '', child: Text((item.searchKey?.isEmpty ?? true) ? l10n.all : item.labelFor(widget.locale)))).toList(),
                onChanged: (value) => setState(() => _range = value ?? ''),
              )
            else
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField(value: _year, decoration: InputDecoration(labelText: l10n.year), items: ['', ...years].map((value) => DropdownMenuItem(value: value, child: Text(value.isEmpty ? l10n.allYears : value))).toList(), onChanged: (value) => setState(() => _year = value ?? ''))),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: _month, decoration: InputDecoration(labelText: l10n.month), items: [for (var month = 1; month <= 12; month++) '$month 月', ''].map((value) => DropdownMenuItem(value: value, child: Text(value.isEmpty ? l10n.allMonths : value))).toList(), onChanged: (value) => setState(() => _month = value ?? ''))),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _mode == _DateMode.range ? _range : [_year, _month].where((value) => value.isNotEmpty).join(' ')), child: Text(l10n.apply)),
      ],
    );
  }
}

class _TagSelection {
  const _TagSelection(this.tags, this.broad);

  final List<String> tags;
  final bool broad;
}

Future<_TagSelection?> _showTagFilter(BuildContext context, List<String> selectedTags, bool broad, SearchOptionCatalog catalog, String locale) => showDialog<_TagSelection>(
      context: context,
      builder: (context) => _TagFilterDialog(selectedTags: selectedTags, broad: broad, catalog: catalog, locale: locale),
    );

class _TagFilterDialog extends StatefulWidget {
  const _TagFilterDialog({required this.selectedTags, required this.broad, required this.catalog, required this.locale});

  final List<String> selectedTags;
  final bool broad;
  final SearchOptionCatalog catalog;
  final String locale;

  @override
  State<_TagFilterDialog> createState() => _TagFilterDialogState();
}

class _TagFilterDialogState extends State<_TagFilterDialog> with SingleTickerProviderStateMixin {
  late final Set<String> _selected;
  late final TabController _tabController;
  late bool _broad;
  late String _group;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedTags.map(widget.catalog.canonicalTag).toSet();
    _broad = widget.broad;
    _group = widget.catalog.tags.keys.first;
    _tabController = TabController(length: widget.catalog.tags.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tags),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.broadMatch),
              subtitle: Text(l10n.broadMatchDescription),
              value: _broad,
              onChanged: (value) => setState(() => _broad = value),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: widget.catalog.tags.keys.map((group) => Tab(text: _tagGroupLabel(l10n, group))).toList(growable: false),
              onTap: (index) => setState(() => _group = widget.catalog.tags.keys.elementAt(index)),
            ),
            Expanded(
              child: ListView(
                children: [
                  _TagGroup(
                    tags: widget.catalog.tags[_group]!.options,
                    locale: widget.locale,
                    selected: _selected,
                    onChanged: (tag, selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(tag);
                        } else {
                          _selected.remove(tag);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _TagSelection(_selected.toList()..sort(), _broad)), child: Text(l10n.apply)),
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({required this.tags, required this.locale, required this.selected, required this.onChanged});

  final List<SearchOption> tags;
  final String locale;
  final Set<String> selected;
  final void Function(String tag, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => FilterChip(label: Text(tag.labelFor(locale)), selected: selected.contains(tag.searchKey), onSelected: (value) => onChanged(tag.searchKey ?? '', value))).toList(),
            ),
          ],
        ),
      );
}

String _tagGroupLabel(AppLocalizations l10n, String group) => switch (group) {
  'video_attributes' => l10n.tagVideoAttributes,
  'character_relationships' => l10n.tagRelationships,
  'characteristics' => l10n.tagCharacterSettings,
  'appearance_and_figure' => l10n.tagAppearance,
  'story_location' => l10n.tagSettings,
  'story_plot' => l10n.tagStory,
  'sex_positions' => l10n.tagPositions,
  _ => group,
};

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.result, required this.onChanged});

  final SearchResult? result;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = result;
    if (value == null || value.totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: value.page > 1 ? () => onChanged(value.page - 1) : null, icon: const Icon(Icons.chevron_left)),
          Text('${value.page} / ${value.totalPages}', style: Theme.of(context).textTheme.labelLarge),
          IconButton(onPressed: value.page < value.totalPages ? () => onChanged(value.page + 1) : null, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 56),
              const SizedBox(height: 12),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.retry)),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}
