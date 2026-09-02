import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/comic_repository.dart';
import '../../data/local/comic_store.dart';
import '../../data/local/home_cache.dart';
import '../../domain/models/comic.dart';
import '../../core/app_shell.dart';
import '../settings/settings_controller.dart';

final comicHomeCacheProvider = Provider((_) => HomeCache());
final comicHomeProvider = AsyncNotifierProvider<ComicHomeController, ComicHome>(ComicHomeController.new);

class ComicHomeController extends AsyncNotifier<ComicHome> {
  @override
  Future<ComicHome> build() async {
    final cache = ref.read(comicHomeCacheProvider);
    final saved = await cache.readComics();
    if (saved != null) {
      unawaited(refresh());
      return saved;
    }
    return refresh();
  }

  Future<ComicHome> refresh() async {
    final feed = await ref.read(comicRepositoryProvider).home();
    await ref.read(comicHomeCacheProvider).writeComics(feed);
    state = AsyncData(feed);
    return feed;
  }
}
final comicDetailProvider = FutureProvider.autoDispose.family((ref, String id) => ref.watch(comicRepositoryProvider).detail(id));
final _browseProvider = FutureProvider.autoDispose.family<ComicSearchResult, (String, int)>((ref, value) => ref.watch(comicRepositoryProvider).browse(value.$1, value.$2));

class ComicExplorePage extends ConsumerWidget {
  const ComicExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final home = ref.watch(comicHomeProvider);
    final drawerMode = ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false;
    return Scaffold(
      appBar: AppBar(
        leading: drawerMode && !permanentNavigationDrawer(context) ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null,
        title: const Text('Hanime1.me'),
        actions: [IconButton(tooltip: l10n.comicBrowse, onPressed: () => context.push('/comics/browse'), icon: const Icon(Icons.tune))],
      ),
      body: home.when(
        loading: () => const Center(child: M3EContainedLoadingIndicator()),
        error: (error, _) => _Retry(error: error, onRetry: () => ref.invalidate(comicHomeProvider)),
        data: (feed) => M3EPullToRefreshIndicator(
          onRefresh: () async {
            await ref.read(comicHomeProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Heading(title: l10n.trendingComics)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 246,
                  child: CarouselView(
                    itemExtent: 160,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: feed.trending.map((comic) => ComicTile(comic: comic)).toList(),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _Heading(title: l10n.latestComics, action: () => context.push('/comics/browse'))),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .52, mainAxisSpacing: 12, crossAxisSpacing: 10),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ComicTile(comic: feed.latest[index]),
                    childCount: feed.latest.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComicBrowseTarget {
  const ComicBrowseTarget(this.path, {this.type, this.label});
  final String path;
  final String? type;
  final String? label;
}

class ComicBrowsePage extends ConsumerStatefulWidget {
  const ComicBrowsePage({super.key, this.target = const ComicBrowseTarget('/comics')});
  final ComicBrowseTarget target;

  @override
  ConsumerState<ComicBrowsePage> createState() => _ComicBrowsePageState();
}

class _ComicBrowsePageState extends ConsumerState<ComicBrowsePage> {
  static const _filters = <String, List<String>>{
    'sort': ['最新', '本日熱門', '本週熱門', '所有熱門'],
    '社團': [],
    '分類': [],
    '語言': [],
    '作者': [],
    '標籤': [],
    '角色': [],
    '同人': [],
  };

  late String _path = widget.target.path;
  var _page = 1;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = ref.watch(_browseProvider((_path, _page)));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.comicBrowse)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              readOnly: true,
              decoration: InputDecoration(hintText: l10n.comicSearchUnavailable, prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters.entries.map((entry) {
                final selected = entry.key == 'sort' ? _path != widget.target.path : entry.key == widget.target.type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(selected && entry.key != 'sort' ? '${entry.key}: ${widget.target.label}' : entry.key),
                    selected: selected,
                    onSelected: (_) => _chooseFilter(entry.key, entry.value),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: result.when(
              loading: () => const Center(child: M3EContainedLoadingIndicator()),
              error: (error, _) => _Retry(error: error, onRetry: () => ref.invalidate(_browseProvider((_path, _page)))),
              data: (value) => Column(
                children: [
                  Expanded(child: _ComicGrid(comics: value.items)),
                  _Pager(page: value.page, total: value.totalPages, onChanged: (page) => setState(() => _page = page)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseFilter(String name, List<String> values) async {
    final l10n = AppLocalizations.of(context)!;
    final choices = name == 'sort' ? values : [l10n.all, ...values];
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: choices.map((choice) => ListTile(title: Text(choice), onTap: () => Navigator.pop(context, choice))).toList())),
    );
    if (selected == null) return;
    setState(() {
      _path = switch (selected) {
        '本日熱門' => '${widget.target.path}/popular-today',
        '本週熱門' => '${widget.target.path}/popular-week',
        '所有熱門' => '${widget.target.path}/popular',
        _ => widget.target.path,
      };
      _page = 1;
    });
  }
}

class ComicDetailPage extends ConsumerWidget {
  const ComicDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(comicDetailProvider(id)).when(
      loading: () => const Scaffold(body: Center(child: M3EContainedLoadingIndicator())),
      error: (error, _) => Scaffold(appBar: AppBar(), body: _Retry(error: error, onRetry: () => ref.invalidate(comicDetailProvider(id)))),
      data: (comic) => _ComicDetail(comic: comic),
    );
  }
}

class _ComicDetail extends ConsumerStatefulWidget {
  const _ComicDetail({required this.comic});
  final ComicDetail comic;

  @override
  ConsumerState<_ComicDetail> createState() => _ComicDetailState();
}

class _ComicDetailState extends ConsumerState<_ComicDetail> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final comic = widget.comic;
    final l10n = AppLocalizations.of(context)!;
    final card = ComicCard(id: comic.id, title: comic.title, coverUrl: comic.coverUrl);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.comicDetails)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/comics/${comic.id}/read', extra: comic), icon: const Icon(Icons.menu_book), label: Text(l10n.read)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: comic.coverUrl, width: 118, height: 172, fit: BoxFit.cover)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(comic.title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text('#${comic.id}'), if (comic.artist != null) Text(comic.artist!), Text('${l10n.pageCount(comic.pageCount)}  ${comic.uploadTime ?? ''}')])),
            ],
          ),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: FilledButton.tonalIcon(onPressed: () => _save(card), icon: const Icon(Icons.bookmark_add_outlined), label: Text(l10n.library))), const SizedBox(width: 8), Expanded(child: FilledButton.tonalIcon(onPressed: () => _cache(comic), icon: const Icon(Icons.download_outlined), label: Text(l10n.cache))), const SizedBox(width: 8), IconButton(tooltip: l10n.info, onPressed: () => _info(comic), icon: const Icon(Icons.info_outline))]))),
          const SizedBox(height: 18),
          Text(l10n.tags, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: comic.tags.take(_expanded ? comic.tags.length : 12).map((tag) => ActionChip(label: Text(tag.name), onPressed: () => context.push('/comics/browse', extra: ComicBrowseTarget(tag.path, type: tag.type, label: tag.name)))).toList()),
          if (comic.tags.length > 12) Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => setState(() => _expanded = !_expanded), icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more))),
          const SizedBox(height: 18),
          Text(l10n.chapter, style: Theme.of(context).textTheme.titleMedium),
          ListTile(leading: const Icon(Icons.article_outlined), title: Text(l10n.chapterOne), trailing: Text(l10n.pageCount(comic.pageCount)), onTap: () => context.push('/comics/${comic.id}/read', extra: comic)),
        ],
      ),
    );
  }

  Future<void> _save(ComicCard card) async {
    final l10n = AppLocalizations.of(context)!;
    final favorite = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.addToLibrary), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.watchLater)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.favoriteVideos))]));
    if (favorite == null) return;
    if (favorite) await ref.read(comicLibraryProvider.notifier).setFavorite(card, true);
    if (!favorite) await ref.read(comicLibraryProvider.notifier).setWatchLater(card, true);
  }

  Future<void> _cache(ComicDetail comic) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(l10n.cache), content: Text(l10n.cacheComicConfirmation), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm))]));
    if (confirmed != true) return;
    final category = await _chooseCategory();
    if (category == null) return;
    try {
      await ref.read(comicCacheProvider.notifier).cache(comic, category: category);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.completed)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<String?> _chooseCategory() async {
    final existing = await ref.read(comicCacheProvider.notifier).categories();
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(l10n.cacheCategory), content: Wrap(spacing: 8, runSpacing: 8, children: existing.map((category) => ActionChip(label: Text(category), onPressed: () => Navigator.pop(context, category))).toList()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel))]));
  }

  void _info(ComicDetail comic) => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [ListTile(title: Text(comic.title), onTap: () => Clipboard.setData(ClipboardData(text: comic.title))), ListTile(title: Text(comic.description ?? ''), onTap: () => Clipboard.setData(ClipboardData(text: comic.description ?? '')))])));
}

class ComicReaderPage extends StatefulWidget {
  const ComicReaderPage({super.key, required this.comic});
  final ComicDetail comic;

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage> {
  var _page = 0;
  var _controls = true;
  var _mode = 0;
  var _background = Colors.black;
  var _forward = true;
  var _ready = false;
  Offset? _pointerStart;
  var _pointers = 0;
  final _readerStore = ComicReaderStore();
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final state = await _readerStore.load();
    if (!mounted) return;
    setState(() {
      _mode = state.mode;
      _background = _backgroundFromName(state.background);
      _page = (state.progress[widget.comic.id] ?? 0).clamp(0, widget.comic.pageCount - 1) as int;
      _ready = true;
    });
    _prefetch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(_page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comic = widget.comic;
    final long = _mode >= 4;
    if (!_ready) return Scaffold(backgroundColor: _background, body: const Center(child: M3EContainedLoadingIndicator()));
    return Scaffold(
      backgroundColor: _background,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _pointerDown,
        onPointerUp: (event) => _pointerUp(event, long),
        onPointerCancel: (_) => _pointerStart = null,
        child: Stack(
          children: [
            if (long)
              ListView.separated(itemCount: comic.pageCount, separatorBuilder: (_, __) => SizedBox(height: _mode == 5 ? 8 : 0), itemBuilder: (_, index) => InteractiveViewer(child: _Image(url: comic.imageUrls[index])))
            else
              Center(
                child: PageView.builder(
                  key: ValueKey(_mode),
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: _mode == 3 ? Axis.vertical : Axis.horizontal,
                  reverse: _mode == 0 || _mode == 2,
                  itemCount: comic.pageCount,
                  itemBuilder: (_, index) => InteractiveViewer(
                    key: ValueKey(index),
                    maxScale: 5,
                    child: Center(child: _Image(url: comic.imageUrls[index])),
                  ),
                ),
              ),
            if (_controls) Positioned(top: 0, left: 0, right: 0, child: AppBar(title: Text('${_page + 1}/${comic.pageCount}'), leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)))),
            if (_controls) Positioned(bottom: 0, left: 0, right: 0, child: BottomAppBar(child: Row(children: [IconButton(onPressed: long || _page == 0 ? null : () => _change(-1), icon: const Icon(Icons.chevron_left)), const Spacer(), IconButton(onPressed: _selectPage, icon: const Icon(Icons.format_list_numbered)), IconButton(onPressed: _settings, icon: const Icon(Icons.tune)), const Spacer(), IconButton(onPressed: long || _page == comic.pageCount - 1 ? null : () => _change(1), icon: const Icon(Icons.chevron_right))]))),
          ],
        ),
      ),
    );
  }

  void _pointerDown(PointerDownEvent event) {
    _pointers += 1;
    if (_pointers == 1) _pointerStart = event.position;
    if (_pointers > 1) _pointerStart = null;
  }

  void _pointerUp(PointerUpEvent event, bool long) {
    _pointers = (_pointers - 1).clamp(0, 10) as int;
    final start = _pointerStart;
    _pointerStart = null;
    if (start == null || _pointers > 0) return;
    final delta = event.position - start;
    if (delta.distance < 12) {
      setState(() => _controls = !_controls);
      return;
    }
    if (long) return;
    if (_mode == 3 && delta.dy.abs() > delta.dx.abs() && delta.dy.abs() > 48) {
      _change(delta.dy < 0 ? 1 : -1);
      return;
    }
    if (_mode != 3 && delta.dx.abs() > delta.dy.abs() && delta.dx.abs() > 48) {
      final forward = _mode == 1 ? delta.dx < 0 : delta.dx > 0;
      _change(forward ? 1 : -1);
    }
  }

  void _change(int delta) {
    final next = (_page + delta).clamp(0, widget.comic.pageCount - 1) as int;
    if (next == _page) return;
    setState(() {
      _forward = delta > 0;
      _page = next;
    });
    _pageController.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    _save();
    _prefetch();
  }

  void _selectPage() {
    var value = (_page + 1).toDouble();
    final controller = TextEditingController(text: '${_page + 1}');
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [Slider(value: value, min: 1, max: widget.comic.pageCount.toDouble(), divisions: widget.comic.pageCount > 1 ? widget.comic.pageCount - 1 : null, onChanged: (next) => setSheet(() => value = next.roundToDouble()), onChangeEnd: (next) { _jump(next.round()); Navigator.pop(context); }), TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.pageNumber), onSubmitted: (text) { final page = int.tryParse(text); if (page != null) _jump(page); Navigator.pop(context); })]),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _settings() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: 290,
          child: Column(
            children: [
              TabBar(tabs: [Tab(text: l10n.readingMode), Tab(text: l10n.general)]),
              Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          6,
                          (index) => ChoiceChip(
                            label: Text([l10n.defaultValue, l10n.leftToRight, l10n.rightToLeft, l10n.topToBottom, l10n.scroll, l10n.scrollGap][index]),
                            selected: _mode == index,
                            onSelected: (_) => _setMode(index, context),
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 8, children: [Colors.black, Colors.grey, Colors.white].map((color) => ChoiceChip(label: Text(color == Colors.black ? l10n.black : color == Colors.grey ? l10n.gray : l10n.white), selected: _background == color, onSelected: (_) { setState(() => _background = color); _save(); Navigator.pop(context); })).toList())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _jump(int page) {
    final next = (page - 1).clamp(0, widget.comic.pageCount - 1) as int;
    _change(next - _page);
  }

  void _setMode(int mode, BuildContext sheetContext) {
    setState(() => _mode = mode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(_page);
    });
    _save();
    Navigator.pop(sheetContext);
  }

  Future<void> _save() async {
    final saved = await _readerStore.load();
    final progress = {...saved.progress, widget.comic.id: _page};
    await _readerStore.save(ComicReaderState(mode: _mode, background: _backgroundName(_background), progress: progress));
  }

  void _prefetch() {
    for (final index in [_page - 1, _page + 1, _page + 2]) {
      if (index >= 0 && index < widget.comic.imageUrls.length) {
        final url = widget.comic.imageUrls[index];
        if (!url.startsWith('/')) precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  Color _backgroundFromName(String name) => switch (name) { 'gray' => Colors.grey, 'white' => Colors.white, _ => Colors.black };
  String _backgroundName(Color color) => color == Colors.grey ? 'gray' : color == Colors.white ? 'white' : 'black';
}

class ComicLibraryPage extends ConsumerWidget {
  const ComicLibraryPage({super.key, this.initialTab = 0, this.drawerMode = false});

  final int initialTab;
  final bool drawerMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTab = initialTab.clamp(0, 1).toInt();
    final library = ref.watch(comicLibraryProvider);
    if (drawerMode) {
      final title = selectedTab == 0 ? l10n.watchLater : l10n.favoriteVideos;
      return Scaffold(appBar: AppBar(leading: permanentNavigationDrawer(context) ? null : IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)), title: Text(title)), body: library.when(loading: () => const Center(child: M3EContainedLoadingIndicator()), error: (error, _) => Text('$error'), data: (value) => _ComicGrid(comics: selectedTab == 0 ? value.watchLater : value.favorites)));
    }
    return DefaultTabController(initialIndex: selectedTab, length: 2, child: Scaffold(appBar: AppBar(title: Text(l10n.myLibrary), bottom: TabBar(tabs: [Tab(text: l10n.watchLater), Tab(text: l10n.favoriteVideos)])), body: library.when(loading: () => const Center(child: M3EContainedLoadingIndicator()), error: (error, _) => Text('$error'), data: (value) => TabBarView(children: [_ComicGrid(comics: value.watchLater), _ComicGrid(comics: value.favorites)]))));
  }
}

class ComicCachePage extends ConsumerStatefulWidget {
  const ComicCachePage({super.key});

  @override
  ConsumerState<ComicCachePage> createState() => _ComicCachePageState();
}

class _ComicCachePageState extends ConsumerState<ComicCachePage> {
  var _category = '';
  var _categories = const <String>[defaultComicCategory];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await ref.read(comicCacheProvider.notifier).categories();
    if (mounted) setState(() => _categories = categories);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final drawerMode = ref.watch(settingsProvider).valueOrNull?.useNavigationDrawer ?? false;
    return Scaffold(
      appBar: AppBar(leading: drawerMode && !permanentNavigationDrawer(context) ? IconButton(onPressed: openAppDrawer, icon: const Icon(Icons.menu)) : null, title: Text(l10n.cache), actions: [IconButton(tooltip: l10n.cacheCategory, onPressed: _manageCategories, icon: const Icon(Icons.folder_outlined))]),
      body: ref.watch(comicCacheProvider).when(
        loading: () => const Center(child: M3EContainedLoadingIndicator()),
        error: (error, _) => Text('$error'),
        data: (items) => _cacheList(items, l10n),
      ),
    );
  }

  Widget _cacheList(List<ComicCacheEntry> items, AppLocalizations l10n) {
    final categories = ['', ...{..._categories, ...items.map((item) => item.category)}];
    if (!categories.contains(_category)) _category = '';
    final visible = _category.isEmpty ? items : items.where((item) => item.category == _category).toList();
    final all = AppLocalizations.of(context)!.all;
    String label(String category) => category.isEmpty ? all : (category == defaultComicCategory ? l10n.defaultCategory : category);
    return Column(children: [SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: categories.map((category) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label(category)), selected: _category == category, onSelected: (_) => setState(() => _category = category)))).toList())), Expanded(child: visible.isEmpty ? Center(child: Text(l10n.noCache)) : ListView(children: visible.map((item) => ListTile(onTap: () => _open(item), leading: CachedNetworkImage(imageUrl: item.coverUrl, width: 52, fit: BoxFit.cover), title: Text(item.title), subtitle: Text('${label(item.category)}  ${l10n.pageCount(item.pageCount)}'), trailing: IconButton(onPressed: () => ref.read(comicCacheProvider.notifier).delete(item), icon: const Icon(Icons.delete_outline)))).toList()))]);
  }

  Future<void> _open(ComicCacheEntry entry) async {
    try {
      final images = await ref.read(comicCacheProvider.notifier).extract(entry);
      if (!mounted) return;
      final comic = ComicDetail(id: entry.id, title: entry.title, coverUrl: entry.coverUrl, pageCount: entry.pageCount, tags: const [], imageUrls: images);
      context.push('/comics/${entry.id}/read', extra: comic);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _manageCategories() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.newCategory))),
                    IconButton(
                      onPressed: () async {
                        await ref.read(comicCacheProvider.notifier).addCategory(controller.text);
                        controller.clear();
                        await _loadCategories();
                        setSheet(() {});
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                ..._categories.map(
                  (category) => ListTile(
                    title: Text(category == defaultComicCategory ? l10n.defaultCategory : category),
                    trailing: category == defaultComicCategory
                        ? null
                        : IconButton(
                            onPressed: () async {
                              await ref.read(comicCacheProvider.notifier).deleteCategory(category);
                              await _loadCategories();
                              setSheet(() {});
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class ComicTile extends StatelessWidget {
  const ComicTile({super.key, required this.comic});
  final ComicCard comic;

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => context.push('/comics/${comic.id}'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: comic.coverUrl, fit: BoxFit.cover, width: double.infinity))), const SizedBox(height: 6), Text(comic.title, maxLines: 2, overflow: TextOverflow.ellipsis)]));
}

class _ComicGrid extends StatelessWidget {
  const _ComicGrid({required this.comics});

  final List<ComicCard> comics;

  @override
  Widget build(BuildContext context) => comics.isEmpty
      ? Center(child: Text(AppLocalizations.of(context)!.noComics))
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .52, mainAxisSpacing: 12, crossAxisSpacing: 10),
          itemCount: comics.length,
          itemBuilder: (_, index) => ComicTile(comic: comics[index]),
        );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.action});
  final String title;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 16, 8, 8), child: Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (action != null) TextButton(onPressed: action, child: Text(AppLocalizations.of(context)!.more))]));
}

class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.total, required this.onChanged});
  final int page;
  final int total;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: page > 1 ? () => onChanged(page - 1) : null, icon: const Icon(Icons.chevron_left)), TextButton(onPressed: () => _showPages(context), child: Text('$page/$total')), IconButton(onPressed: page < total ? () => onChanged(page + 1) : null, icon: const Icon(Icons.chevron_right))]));

  Future<void> _showPages(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: GridView.builder(shrinkWrap: true, padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), itemCount: total, itemBuilder: (_, index) => TextButton(onPressed: () => Navigator.pop(context, index + 1), child: Text('${index + 1}')))));
    if (selected != null) onChanged(selected);
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => url.startsWith('/') ? Image.file(File(url), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white)) : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, placeholder: (_, __) => const SizedBox(height: 180, child: Center(child: M3EContainedLoadingIndicator())), errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white));
}

class _Retry extends StatelessWidget {
  const _Retry({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$error', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.retry))]));
}
