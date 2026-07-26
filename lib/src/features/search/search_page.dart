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
    _textController.addListener(_onTextChanged);
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchInitProvider.notifier).state = widget.initialUrl;
      });
    }
    final query = ref.read(searchQueryProvider);
    if (query.text.isNotEmpty) _textController.text = query.text;
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _textController
      ..removeListener(_onTextChanged)
      ..dispose();
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
                    tooltip: l10n.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _textController.clear();
                      ref.read(searchQueryProvider.notifier).text('');
                    },
                  ),
          ),
          onSubmitted: ref.read(searchQueryProvider.notifier).text,
        ),
      ),
      body: Column(
        children: [
          _Filters(query: query, notifier: ref.read(searchQueryProvider.notifier)),
          Expanded(
            child: result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorView(error: error, onRetry: () => ref.invalidate(searchResultsProvider)),
              data: (page) => page.items.isEmpty
                  ? _EmptyState(message: l10n.noSearchResults)
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
  const _Filters({required this.query, required this.notifier});

  final SearchQuery query;
  final SearchQueryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final genres = ['', l10n.genreAdultAnimation, l10n.genreShortAnimation, 'Motion Anime', '3DCG', '2.5D', l10n.genre2dAnimation, l10n.genreAiGenerated, 'MMD', 'Cosplay'];
    final sorts = ['', l10n.sortLatestRelease, l10n.sortLatestUpload, l10n.sortTrending];
    final durations = ['', '1 分鐘 +', '5 分鐘 +', '10 分鐘 +', '20 分鐘 +', '30 分鐘 +', '60 分鐘 +', '0 - 10 分鐘', '0 - 20 分鐘'];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _MenuFilterButton(
            label: l10n.category(query.genre.isEmpty ? l10n.all : query.genre),
            icon: Icons.category_outlined,
            values: genres,
            onSelected: notifier.genre,
            formatter: (value) => value.isEmpty ? l10n.all : value,
          ),
          _MenuFilterButton(
            label: l10n.sort(query.sort.isEmpty ? l10n.defaultValue : query.sort),
            icon: Icons.sort,
            values: sorts,
            onSelected: notifier.sort,
            formatter: (value) => value.isEmpty ? l10n.defaultValue : value,
          ),
          _ActionFilterButton(
            label: l10n.releaseDate(query.date.isEmpty ? l10n.all : query.date),
            icon: Icons.calendar_month_outlined,
            onPressed: () async {
              final date = await _showDateFilter(context, query.date);
              if (date != null) notifier.date(date);
            },
          ),
          _ActionFilterButton(
            label: query.tags.isEmpty ? l10n.tags : l10n.tagsSelected(query.tags.length),
            icon: Icons.sell_outlined,
            onPressed: () async {
              final selection = await _showTagFilter(context, query.tags, query.broad);
              if (selection != null) notifier.tags(selection.tags, selection.broad);
            },
          ),
          _MenuFilterButton(
            label: l10n.duration(query.duration.isEmpty ? l10n.all : query.duration),
            icon: Icons.schedule_outlined,
            values: durations,
            onSelected: notifier.duration,
            formatter: (value) => value.isEmpty ? l10n.all : value,
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

Future<String?> _showDateFilter(BuildContext context, String currentDate) => showDialog<String>(
      context: context,
      builder: (context) => _DateFilterDialog(currentDate: currentDate),
    );

class _DateFilterDialog extends StatefulWidget {
  const _DateFilterDialog({required this.currentDate});

  final String currentDate;

  @override
  State<_DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<_DateFilterDialog> {
  static const _ranges = ['', '過去 24 小時', '過去 2 天', '過去 1 週', '過去 1 個月', '過去 3 個月', '過去 1 年'];
  _DateMode _mode = _DateMode.range;
  String _range = '';
  String _year = '';
  String _month = '';

  @override
  void initState() {
    super.initState();
    if (_ranges.contains(widget.currentDate)) {
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
                items: _ranges.map((value) => DropdownMenuItem(value: value, child: Text(value.isEmpty ? l10n.all : value))).toList(),
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

Future<_TagSelection?> _showTagFilter(BuildContext context, List<String> selectedTags, bool broad) => showDialog<_TagSelection>(
      context: context,
      builder: (context) => _TagFilterDialog(selectedTags: selectedTags, broad: broad),
    );

class _TagFilterDialog extends StatefulWidget {
  const _TagFilterDialog({required this.selectedTags, required this.broad});

  final List<String> selectedTags;
  final bool broad;

  @override
  State<_TagFilterDialog> createState() => _TagFilterDialogState();
}

class _TagFilterDialogState extends State<_TagFilterDialog> {
  late final Set<String> _selected = widget.selectedTags.toSet();
  late bool _broad = widget.broad;

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
            const Divider(),
            Expanded(
              child: ListView(
                children: searchableTagGroups.entries.map((entry) => _TagGroup(title: _tagGroupLabel(l10n, entry.key), tags: entry.value, selected: _selected, onChanged: (tag, selected) => setState(() => selected ? _selected.add(tag) : _selected.remove(tag)))).toList(),
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
  const _TagGroup({required this.title, required this.tags, required this.selected, required this.onChanged});

  final String title;
  final List<String> tags;
  final Set<String> selected;
  final void Function(String tag, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => FilterChip(label: Text(tag), selected: selected.contains(tag), onSelected: (value) => onChanged(tag, value))).toList(),
            ),
          ],
        ),
      );
}

const searchableTagGroups = <String, List<String>>{
  'videoAttributes': ['無碼', 'AI解碼', '中文字幕', '中文配音', '同人作品', '斷面圖', 'ASMR', '1080p', '60FPS'],
  'relationships': ['近親', '姐', '妹', '母', '女兒', '師生', '情侶', '青梅竹馬', '同事'],
  'characterSettings': ['JK', '處女', '御姐', '熟女', '人妻', '女教師', '男教師', '女醫生', '女病人', '護士', 'OL', '女警', '大小姐', '偶像', '女僕', '巫女', '魔女', '修女', '風俗娘', '公主', '女忍者', '女戰士', '女騎士', '魔法少女', '異種族', '天使', '妖精', '魔物娘', '魅魔', '吸血鬼', '女鬼', '獸娘', '福瑞', '乳牛', '機械娘', '碧池', '痴女', '雌小鬼', '不良少女', '傲嬌', '病嬌', '無口', '無表情', '眼神死', '正太', '偽娘', '扶他'],
  'appearance': ['短髮', '馬尾', '雙馬尾', '丸子頭', '巨乳', '乳環', '舌環', '貧乳', '黑皮膚', '曬痕', '眼鏡娘', '獸耳', '尖耳朵', '異色瞳', '美人痣', '肌肉女', '白虎', '陰毛', '腋毛', '大屌', '黑屌', '著衣', '水手服', '體操服', '泳裝', '比基尼', '死庫水', '和服', '兔女郎', '圍裙', '啦啦隊', '絲襪', '吊襪帶', '熱褲', '迷你裙', '性感內衣', '緊身衣', '丁字褲', '高跟鞋', '睡衣', '婚紗', '旗袍', '古裝', '哥德', '口罩', '刺青', '淫紋', '身體寫字'],
  'settings': ['校園', '教室', '圖書館', '保健室', '體育倉庫', '游泳池', '愛情賓館', '醫院', '辦公室', '浴室', '窗邊', '公共廁所', '公眾場合', '戶外野戰', '電車', '車震', '遊艇', '露營帳篷', '電影院', '健身房', '沙灘', '溫泉', '夜店', '監獄', '教堂'],
  'story': ['純愛', '戀愛喜劇', '後宮', '十指緊扣', '開大車', 'NTR', '精神控制', '藥物', '痴漢', '阿嘿顏', '哭泣', '精神崩潰', '獵奇', 'BDSM', '綑綁', '眼罩', '項圈', '調教', '異物插入', '尋歡洞', '肉便器', '性奴隸', '胃凸', '強制', '輪姦', '凌辱', '性暴力', '逆強制', '女王樣', '榨精', '母女丼', '姐妹丼', '出軌', '醉酒', '攝影', '睡眠姦', '機械姦', '蟲姦', '性轉換', '百合', '耽美', '時間停止', '異世界', '怪獸', '哥布林', '世界末日'],
  'positions': ['手交', '指交', '玩乳頭', '乳交', '乳頭交', '肛交', '雙洞齊下', '腳交', '素股', '拳交', '3P', '群交', '口交', '跪舔', '深喉嚨', '口爆', '吞精', '舔蛋蛋', '舔穴', '69', '自慰', '腋交', '舔腋下', '髮交', '舔耳朵', '舔腳', '內射', '外射', '顏射', '潮吹', '懷孕', '噴奶', '放尿', '排便', '騎乘位', '背後位', '側面位', '顏面騎乘', '火車便當', '一字馬', '性玩具', '飛機杯', '跳蛋', '毒龍鑽', '觸手', '獸交', '頸手枷', '扯頭髮', '掐脖子', '打屁股', '肉棒打臉', '陰道外翻', '男乳首責', '接吻', '舌吻', 'POV'],
};

String _tagGroupLabel(AppLocalizations l10n, String group) => switch (group) {
  'videoAttributes' => l10n.tagVideoAttributes,
  'relationships' => l10n.tagRelationships,
  'characterSettings' => l10n.tagCharacterSettings,
  'appearance' => l10n.tagAppearance,
  'settings' => l10n.tagSettings,
  'story' => l10n.tagStory,
  'positions' => l10n.tagPositions,
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
