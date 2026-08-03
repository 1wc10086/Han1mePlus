import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'json_store.dart';

final keyframeVideosProvider = FutureProvider<List<KeyframeVideo>>((ref) async {
  final json = await JsonStore().read('keyframes.json');
  final videos = <KeyframeVideo>[];
  for (final entry in json.entries) {
    final value = entry.value;
    final keyframes = value is Map
        ? (value['keyframes'] as List? ?? const <Object?>[])
        : value as List? ?? const <Object?>[];
    final title = value is Map ? value['title'] as String? ?? entry.key : entry.key;
    final positions = keyframes.whereType<num>().map((item) => item.toInt()).toList()..sort();
    if (positions.isNotEmpty) {
      videos.add(KeyframeVideo(id: entry.key, title: title, positions: positions));
    }
  }
  videos.sort((a, b) => a.title.compareTo(b.title));
  return videos;
});

final keyframesProvider = AsyncNotifierProviderFamily<KeyframesController, List<int>, String>(KeyframesController.new);

class KeyframeVideo {
  const KeyframeVideo({required this.id, required this.title, required this.positions});

  final String id;
  final String title;
  final List<int> positions;
}

class KeyframesController extends FamilyAsyncNotifier<List<int>, String> {
  final _store = JsonStore();

  @override
  Future<List<int>> build(String videoId) async {
    final local = _positions(await _store.read('keyframes.json'), videoId);
    return local;
  }

  Future<void> setTitle(String title) async {
    final json = await _store.read('keyframes.json');
    final positions = _positions(json, arg);
    if (positions.isEmpty) return;
    await _write(json, positions, title: title);
  }

  Future<bool> add(int positionMs, {String? title}) async {
    final json = await _store.read('keyframes.json');
    final current = _positions(json, arg);
    if (current.any((value) => (value - positionMs).abs() < 10000)) return false;
    await _write(json, [...current, positionMs]..sort(), title: title);
    return true;
  }

  Future<bool> updatePosition(int oldPositionMs, int newPositionMs) async {
    final json = await _store.read('keyframes.json');
    final current = _positions(json, arg);
    if (newPositionMs < 0 || current.where((item) => item != oldPositionMs).any((item) => (item - newPositionMs).abs() < 10000)) return false;
    await _write(json, [...current.where((item) => item != oldPositionMs), newPositionMs]..sort());
    return true;
  }

  Future<void> remove(int positionMs) async {
    final json = await _store.read('keyframes.json');
    final next = _positions(json, arg).where((item) => item != positionMs).toList();
    if (next.isEmpty) {
      json.remove(arg);
      await _store.write('keyframes.json', json);
      state = const AsyncData([]);
      ref.invalidate(keyframeVideosProvider);
      return;
    }
    await _write(json, next);
  }

  Future<void> deleteVideo() async {
    final json = await _store.read('keyframes.json');
    json.remove(arg);
    await _store.write('keyframes.json', json);
    state = const AsyncData([]);
    ref.invalidate(keyframeVideosProvider);
  }

  List<int> _positions(Map<String, dynamic> json, String id) {
    final value = json[id];
    final list = value is Map ? value['keyframes'] as List? : value as List?;
    return (list ?? const <Object?>[]).whereType<num>().map((item) => item.toInt()).toList()..sort();
  }

  Future<void> _write(Map<String, dynamic> json, List<int> positions, {String? title}) async {
    final existing = json[arg];
    final savedTitle = title ?? (existing is Map ? existing['title'] as String? : null) ?? arg;
    await _store.write('keyframes.json', {...json, arg: {'title': savedTitle, 'keyframes': positions}});
    state = AsyncData(positions);
    ref.invalidate(keyframeVideosProvider);
  }
}
