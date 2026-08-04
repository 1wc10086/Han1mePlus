import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../data/local/watch_repository.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  var _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final watch = ref.watch(watchProvider).value ?? const WatchState();
    final l10n = AppLocalizations.of(context)!;
    final date = _date(_selected);
    final grouped = <String, int>{};
    for (final item in watch.histories.where((item) => item.date == date)) {
      grouped[item.title] = (grouped[item.title] ?? 0) + item.watchedMs;
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = grouped.values.fold(0, (value, next) => value + next);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 280,
            child: CalendarDatePicker(
              initialDate: _selected,
              firstDate: DateTime(DateTime.now().year, DateTime.now().month - 5),
              lastDate: DateTime.now(),
              onDateChanged: (value) => setState(() => _selected = value),
            ),
          ),
          Text(
            l10n.date(_selected.year, _selected.month, _selected.day),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.watchDuration(_duration(total)), style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  if (entries.isEmpty)
                    Text(l10n.noWatchHistory)
                  else
                    ...entries.map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        trailing: Text(_duration(entry.value)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _duration(int value) {
    final l10n = AppLocalizations.of(context)!;
    final seconds = value ~/ 1000;
    final minutes = seconds ~/ 60;
    if (minutes >= 60) return l10n.hoursMinutes(minutes ~/ 60, minutes % 60);
    if (minutes > 0) return l10n.minutes(minutes);
    return l10n.seconds(seconds);
  }
}
