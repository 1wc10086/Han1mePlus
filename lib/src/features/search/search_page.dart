import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/remote/han1me_api.dart' show SearchResult;
import '../shared/video_card.dart';
import 'search_controller.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
            suffixIcon: _textController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _textController.clear();
                      ref.read(searchQueryProvider.notifier).text('');
                    },
                  ),
          ),
          onSubmitted: (value) => ref.read(searchQueryProvider.notifier).text(value),
        ),
      ),
      body: Column(
        children: [
          _Filters(query: query, notifier: ref.read(searchQueryProvider.notifier)),
          Expanded(
            child: result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorView(
                error: error,
                onRetry: () => ref.invalidate(searchResultsProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? _EmptyState(message: l10n.noSearchResults)
                    : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      cacheExtent: 720,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: .62,
                      ),
                      itemCount: page.items.length,
                      itemBuilder: (context, index) => VideoCardTile(video: page.items[index]),
                    ),
            ),
          ),
          _PaginationBar(
            result: ref.watch(searchResultsProvider).valueOrNull,
            onChanged: (page) => ref.read(searchQueryProvider.notifier).page(page),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.query, required this.notifier});
  final SearchQuery query;
  final SearchQueryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final genres = ['', l10n.genreAdultAnimation, l10n.genreShortAnimation, 'Motion Anime', '3DCG', '2.5D', l10n.genre2dAnimation, l10n.genreAiGenerated, 'MMD', 'Cosplay'];
    final sorts = ['', l10n.sortLatestRelease, l10n.sortLatestUpload, l10n.sortTrending];
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _FilterButton(
              label: AppLocalizations.of(context)!.category(query.genre.isEmpty ? AppLocalizations.of(context)!.all : query.genre),
               values: genres,
               onSelected: notifier.genre,
               formatter: (value) => value.isEmpty ? l10n.all : value,
            ),
            _FilterButton(
              label: AppLocalizations.of(context)!.sort(query.sort.isEmpty ? AppLocalizations.of(context)!.defaultValue : query.sort),
               values: sorts,
              onSelected: notifier.sort,
              formatter: (value) => value.isEmpty ? AppLocalizations.of(context)!.defaultValue : value,
            ),
          ],
        ),
       );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.values, required this.onSelected, this.formatter});
  final String label;
  final List<String> values;
  final ValueChanged<String> onSelected;
  final String Function(String)? formatter;

  @override
  Widget build(BuildContext context) {
    MenuController? menuController;
    return MenuAnchor(
      builder: (context, controller, child) {
        menuController = controller;
        return FilledButton.tonalIcon(
          onPressed: controller.open,
          icon: const Icon(Icons.tune, size: 18),
          label: Text(label),
        );
      },
      menuChildren: values
          .map((value) => MenuItemButton(
                onPressed: () {
                  menuController?.close();
                  onSelected(value);
                },
                child: Text(formatter == null ? value : formatter!(value)),
              ))
          .toList(),
    );
  }
}

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
          IconButton(
            onPressed: value.page > 1 ? () => onChanged(value.page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${value.page} / ${value.totalPages}', style: Theme.of(context).textTheme.labelLarge),
          IconButton(
            onPressed: value.page < value.totalPages ? () => onChanged(value.page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
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
