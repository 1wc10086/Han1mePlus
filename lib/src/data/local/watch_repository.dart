import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/library.dart';
import 'json_store.dart';

class WatchState {
  const WatchState({this.continueItems = const [], this.histories = const []});
  final List<WatchProgress> continueItems;
  final List<WatchHistory> histories;
  Map<String, dynamic> toJson() => {'continueItems': continueItems.map((item) => item.toJson()).toList(), 'histories': histories.map((item) => item.toJson()).toList()};
  factory WatchState.fromJson(Map<String, dynamic> json) => WatchState(continueItems: ((json['continueItems'] as List?) ?? const []).whereType<Map>().map((item) => WatchProgress.fromJson(Map<String, dynamic>.from(item))).toList(), histories: ((json['histories'] as List?) ?? const []).whereType<Map>().map((item) => WatchHistory.fromJson(Map<String, dynamic>.from(item))).toList());
}
final watchProvider = AsyncNotifierProvider<WatchController, WatchState>(WatchController.new);
class WatchController extends AsyncNotifier<WatchState> {
  final _store = JsonStore();
  Future<void> _writeQueue = Future.value();
  @override Future<WatchState> build() async => WatchState.fromJson(await _store.read('watch_store.json'));
  Future<void> _save(WatchState value) async { await _store.write('watch_store.json', value.toJson()); state = AsyncData(value); }
  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _writeQueue.then((_) => operation());
    _writeQueue = next.catchError((_) {});
    return next;
  }
  Future<void> progress({required String id, required String title, String? coverUrl, required int positionMs, required int durationMs}) => _enqueue(() async { final current = await future; final item = WatchProgress(videoCode: id, title: title, coverUrl: coverUrl, positionMs: max(positionMs, 0), durationMs: max(durationMs, 0), updatedAt: DateTime.now().millisecondsSinceEpoch); await _save(WatchState(continueItems: [item, ...current.continueItems.where((existing) => existing.videoCode != id)].take(6).toList(), histories: current.histories)); });
  Future<void> addTime(String id, String title, int watchedMs) { if (watchedMs <= 0) return Future.value(); return _enqueue(() async { final current = await future; final now = DateTime.now(); final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'; final history = WatchHistory(id: '${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}', videoCode: id, title: title, watchedMs: watchedMs, date: date, createdAt: now.millisecondsSinceEpoch); await _save(WatchState(continueItems: current.continueItems, histories: [...current.histories, history])); }); }
}
