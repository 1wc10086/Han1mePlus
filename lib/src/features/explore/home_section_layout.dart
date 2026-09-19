import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/models/video.dart';
import '../settings/settings_controller.dart';
import 'explore_controller.dart';

String homeSectionKey(HomeSection section) {
  final uri = Uri.tryParse(section.moreUrl ?? '');
  final value = uri?.queryParameters['genre'] ?? uri?.queryParameters['sort'] ?? uri?.queryParameters['query'];
  if (value != null && value.isNotEmpty) return value;
  return section.title;
}

List<HomeSection> applyHomeSectionLayout(List<HomeSection> sections, List<String> order, List<String> hidden) {
  final hiddenKeys = hidden.toSet();
  final visible = sections.where((section) => !hiddenKeys.contains(homeSectionKey(section))).toList();
  if (order.isEmpty) return visible;
  final rank = {for (var index = 0; index < order.length; index++) order[index]: index};
  final ordered = [...visible];
  ordered.sort((left, right) {
    final leftRank = rank[homeSectionKey(left)] ?? order.length;
    final rightRank = rank[homeSectionKey(right)] ?? order.length;
    return leftRank.compareTo(rightRank);
  });
  return ordered;
}

Future<HomeFeed?> resolveHomeFeed(WidgetRef ref) async {
  final cached = ref.read(homeSectionsProvider).valueOrNull;
  if (cached != null) return cached;
  try {
    return await ref.read(homeSectionsProvider.notifier).refresh();
  } catch (_) {
    return null;
  }
}

Future<void> showHomeSectionLayoutDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final feed = await resolveHomeFeed(ref);
  if (!context.mounted) return;
  final sections = feed?.sections ?? const <HomeSection>[];
  if (sections.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.homeSectionLayoutUnavailable)));
    return;
  }
  final settings = ref.read(settingsProvider).valueOrNull;
  if (settings == null) return;
  final result = await showDialog<HomeSectionLayoutResult>(
    context: context,
    builder: (_) => HomeSectionLayoutDialog(
      entries: sections.map((section) => HomeSectionLayoutEntry(key: homeSectionKey(section), title: section.title)).toList(growable: false),
      order: settings.homeSectionOrder,
      hidden: settings.hiddenHomeSections,
    ),
  );
  if (result == null) return;
  await ref.read(settingsProvider.notifier).saveChanges(
        (current) => current.copyWith(
          homeSectionOrder: result.order,
          hiddenHomeSections: [...result.hidden],
        ),
      );
}

class HomeSectionLayoutEntry {
  const HomeSectionLayoutEntry({required this.key, required this.title});

  final String key;
  final String title;
}

class HomeSectionLayoutResult {
  const HomeSectionLayoutResult({required this.order, required this.hidden});

  final List<String> order;
  final Set<String> hidden;
}

class HomeSectionLayoutDialog extends StatefulWidget {
  const HomeSectionLayoutDialog({super.key, required this.entries, required this.order, required this.hidden});

  final List<HomeSectionLayoutEntry> entries;
  final List<String> order;
  final List<String> hidden;

  @override
  State<HomeSectionLayoutDialog> createState() => _HomeSectionLayoutDialogState();
}

class _HomeSectionLayoutDialogState extends State<HomeSectionLayoutDialog> {
  late List<String> _order = _normalize(widget.order);
  late Set<String> _hidden = widget.hidden.toSet();
  final _scrollController = ScrollController();

  List<String> _normalize(List<String> value) {
    final defaults = widget.entries.map((entry) => entry.key).toList(growable: false);
    final known = value.where(defaults.contains).toList(growable: false);
    return [...known, ...defaults.where((key) => !known.contains(key))];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = {for (final entry in widget.entries) entry.key: entry.title};
    return AlertDialog(
      title: Text(l10n.homeSectionLayout),
      content: SizedBox(
        width: 420,
        height: MediaQuery.sizeOf(context).height * .5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homeSectionLayoutSummary, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: _scrollController,
                buildDefaultDragHandles: false,
                itemCount: _order.length,
                onReorder: (oldIndex, newIndex) => setState(() {
                  final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  final key = _order.removeAt(oldIndex);
                  _order.insert(target, key);
                }),
                itemBuilder: (context, index) {
                  final key = _order[index];
                  return ListTile(
                    key: ValueKey(key),
                    contentPadding: EdgeInsets.zero,
                    title: Text(titles[key] ?? key, style: TextStyle(color: _hidden.contains(key) ? Theme.of(context).colorScheme.outline : null)),
                    leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator)),
                    trailing: Switch(
                      value: !_hidden.contains(key),
                      onChanged: (value) => setState(() => value ? _hidden.remove(key) : _hidden.add(key)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _order = widget.entries.map((entry) => entry.key).toList(growable: false);
            _hidden = {};
          }),
          child: Text(l10n.resetDefaults),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, HomeSectionLayoutResult(order: _order, hidden: _hidden)), child: Text(l10n.confirm)),
      ],
    );
  }
}
