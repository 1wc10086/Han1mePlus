import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../core/settings.dart';
import '../../core/platform_paths.dart';
import '../../core/platform_service.dart';
import '../../data/han1me_repository.dart';
import '../../data/remote/han1me_http_client.dart';
import '../../domain/models/download.dart';
import '../../domain/models/video.dart';
import '../../features/settings/settings_controller.dart';

class DownloadState {
  const DownloadState({this.groups = const [DownloadGroup(id: 'default', name: 'Cached', createdAt: 0)], this.tasks = const []});

  final List<DownloadGroup> groups;
  final List<DownloadTask> tasks;

  Map<String, dynamic> toJson() => {'groups': groups.map((item) => item.toJson()).toList(), 'tasks': tasks.map((item) => item.toJson()).toList()};

  factory DownloadState.fromJson(Map<String, dynamic> json) {
    final groups = ((json['groups'] as List?) ?? const []).whereType<Map>().map((item) => DownloadGroup.fromJson(Map<String, dynamic>.from(item))).where((group) => group.id.isNotEmpty).toList();
    final normalizedGroups = groups.any((group) => group.id == 'default') ? groups : [const DownloadGroup(id: 'default', name: 'Cached', createdAt: 0), ...groups];
    final groupIds = normalizedGroups.map((group) => group.id).toSet();
    final tasks = ((json['tasks'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => DownloadTask.fromJson(Map<String, dynamic>.from(item)))
        .map((task) => task.copyWith(groupIds: task.groupIds.where(groupIds.contains).toSet(), updatedAt: task.updatedAt))
        .toList();
    return DownloadState(groups: normalizedGroups, tasks: tasks);
  }
}

final downloadProvider = AsyncNotifierProvider<DownloadController, DownloadState>(DownloadController.new);

class DownloadController extends AsyncNotifier<DownloadState> {
  late Directory _root;
  final _running = <String>{};
  final _jobs = <String, ({VideoDetail detail, VideoSource source})>{};
  Future<void> _writeQueue = Future<void>.value();
  DateTime _lastProgressWrite = DateTime.fromMillisecondsSinceEpoch(0);
  static const _progressWriteInterval = Duration(milliseconds: 700);

  @override
  Future<DownloadState> build() async {
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (previous, next) {
      // Only re-initialize when the user actually changes the download path;
      // the initial settings load (previous == null) must not invalidate this
      // provider, or anything awaiting it hangs while it is being rebuilt.
      final previousPath = previous?.valueOrNull?.downloadPath;
      if (previousPath != null && previousPath != next.valueOrNull?.downloadPath) {
        ref.invalidateSelf();
      } else {
        _schedule();
      }
    });
    final settings = await ref.read(settingsProvider.future);
    _root = Directory(await normalizeDownloadPath(settings.downloadPath));
    await _root.create(recursive: true);
    final loaded = _restoreJobs(await _readStore());
    final restored = await _mergeRecovered(loaded);
    if (!identical(restored, loaded)) await _persist(restored);
    Timer.run(_schedule);
    return restored;
  }

  File get _storeFile => File(path.join(_root.path, 'download_store.json'));
  File get _backupStoreFile => File(path.join(_root.path, 'download_store.json.bak'));

  DownloadState _restoreJobs(DownloadState loaded) {
    final tasks = loaded.tasks.map((task) {
      if (task.status == DownloadStatus.completed) return task;
      if (task.sourceUrl?.isEmpty != false) return task.copyWith(status: DownloadStatus.failed, errorMessage: 'Download interrupted');
      _jobs[task.id] = (
        detail: VideoDetail(id: task.videoCode, title: task.title, coverUrl: task.coverUrl, sources: const [], tags: const [], playlist: const [], related: const []),
        source: VideoSource(quality: task.quality, url: task.sourceUrl!),
      );
      return task.copyWith(status: DownloadStatus.queued, clearError: true);
    }).toList();
    return DownloadState(groups: loaded.groups, tasks: tasks);
  }

  Future<DownloadState> _readStore() async {
    final store = await _decodeStore(_storeFile);
    if (store != null) return store;
    final backup = await _decodeStore(_backupStoreFile);
    return backup ?? const DownloadState();
  }

  Future<DownloadState?> _decodeStore(File file) async {
    try {
      if (!await file.exists()) return null;
      return DownloadState.fromJson(Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<DownloadState> _mergeRecovered(DownloadState value) async {
    final known = value.tasks.map((task) => task.videoCode).toSet();
    final recovered = <DownloadTask>[];
    try {
      final entries = await _root.list().toList();
      for (final entry in entries) {
        if (entry is! Directory) continue;
        final code = path.basename(entry.path);
        if (code.isEmpty || known.contains(code)) continue;
        final task = await _recover(entry, code);
        if (task != null) recovered.add(task);
      }
    } catch (error) {
      debugPrint('Failed to scan download directory: $error');
    }
    if (recovered.isEmpty) return value;
    return DownloadState(groups: value.groups, tasks: [...value.tasks, ...recovered]);
  }

  Future<DownloadTask?> _recover(Directory directory, String videoCode) async {
    final meta = File(path.join(directory.path, 'detail.json'));
    if (!await meta.exists()) return null;
    final Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(await meta.readAsString()) as Map);
    } catch (_) {
      return null;
    }
    final video = await _videoFile(directory);
    if (video == null) return null;
    final stat = await video.stat();
    final cover = File(path.join(directory.path, 'cover.jpg'));
    return DownloadTask(
      id: videoCode,
      videoCode: videoCode,
      title: data['title'] as String? ?? videoCode,
      coverUrl: data['coverUrl'] as String?,
      duration: data['duration'] as String?,
      views: data['viewsText'] as String?,
      rating: data['rating'] as String?,
      uploadTime: data['uploadDate'] as String?,
      sourceUrl: data['sourceUrl'] as String?,
      groupIds: const {},
      quality: data['sourceQuality'] as String? ?? path.basenameWithoutExtension(video.path).replaceFirst('video_', ''),
      status: DownloadStatus.completed,
      progress: 1,
      downloadedBytes: stat.size,
      totalBytes: stat.size,
      createdAt: stat.modified.millisecondsSinceEpoch,
      updatedAt: stat.modified.millisecondsSinceEpoch,
      localVideoPath: video.path,
      localCoverPath: await cover.exists() ? cover.path : null,
      localMetaPath: meta.path,
    );
  }

  Future<File?> _videoFile(Directory directory) async {
    try {
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = path.basename(entity.path);
        if (name.startsWith('video_') && name.endsWith('.mp4')) return entity;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _save(DownloadState value) async {
    state = AsyncData(value);
    await _persist(value);
  }

  Future<void> _persist(DownloadState value) async {
    final store = _storeFile;
    final temporary = File('${store.path}.tmp');
    final backup = _backupStoreFile;
    _writeQueue = _writeQueue.then((_) async {
      try {
        await temporary.writeAsString(jsonEncode(value.toJson()), flush: true);
        if (await store.exists()) {
          try {
            await store.copy(backup.path);
          } catch (_) {}
        }
        await temporary.rename(store.path);
      } catch (error) {
        debugPrint('Failed to persist download store: $error');
      }
    });
    await _writeQueue;
  }

  Future<void> _progress(String id, DownloadTask Function(DownloadTask) update) async {
    final current = state.value ?? const DownloadState();
    state = AsyncData(DownloadState(groups: current.groups, tasks: current.tasks.map((task) => task.id == id ? update(task) : task).toList()));
    final now = DateTime.now();
    if (now.difference(_lastProgressWrite) < _progressWriteInterval) return;
    _lastProgressWrite = now;
    await _persist(state.value ?? const DownloadState());
  }

  Future<String?> addGroup(String name, DownloadGroupSort sort) async {
    final text = name.trim();
    final current = state.value ?? const DownloadState();
    if (text.isEmpty || current.groups.any((group) => group.name == text)) return null;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _save(DownloadState(groups: [...current.groups, DownloadGroup(id: id, name: text, createdAt: DateTime.now().millisecondsSinceEpoch, sort: sort)], tasks: current.tasks));
    return id;
  }

  Future<void> updateGroup(String id, String name, DownloadGroupSort sort) async {
    final text = name.trim();
    final current = state.value ?? const DownloadState();
    if (text.isEmpty || current.groups.any((group) => group.id != id && group.name == text)) return;
    await _save(DownloadState(groups: current.groups.map((group) => group.id == id ? group.copyWith(name: text, sort: sort) : group).toList(), tasks: current.tasks));
  }

  Future<void> deleteGroup(String id) async {
    if (id == 'default') return;
    final current = state.value ?? const DownloadState();
    final tasks = current.tasks.map((task) => task.groupIds.contains(id) ? task.copyWith(groupIds: {...task.groupIds}..remove(id)) : task).toList();
    await _save(DownloadState(groups: current.groups.where((group) => group.id != id).toList(), tasks: tasks));
  }

  Future<void> deleteTasks(Set<String> ids) async {
    final current = state.value ?? const DownloadState();
    for (final task in current.tasks.where((task) => ids.contains(task.id))) {
      final directory = Directory(path.join(_root.path, task.videoCode));
      if (await directory.exists()) await directory.delete(recursive: true);
      _jobs.remove(task.id);
    }
    await _save(DownloadState(groups: current.groups, tasks: current.tasks.where((task) => !ids.contains(task.id)).toList()));
  }

  Future<void> togglePinned(Set<String> ids) async {
    final current = state.value ?? const DownloadState();
    final selected = current.tasks.where((task) => ids.contains(task.id)).toList();
    if (selected.isEmpty) return;
    final pinned = !selected.every((task) => task.pinned);
    await _save(DownloadState(groups: current.groups, tasks: current.tasks.map((task) => ids.contains(task.id) ? task.copyWith(pinned: pinned) : task).toList()));
  }

  Future<void> setTaskGroups(Set<String> ids, Set<String> groupIds) async {
    final current = state.value ?? const DownloadState();
    final valid = groupIds.where((id) => id != 'default' && current.groups.any((group) => group.id == id)).toSet();
    await _save(DownloadState(groups: current.groups, tasks: current.tasks.map((task) => ids.contains(task.id) ? task.copyWith(groupIds: valid) : task).toList()));
  }

  Future<void> replace(DownloadState value) => _save(value);

  Future<void> create(VideoDetail detail, VideoSource source, String groupId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final task = DownloadTask(id: detail.id, videoCode: detail.id, title: detail.title, coverUrl: detail.coverUrl, duration: detail.duration, views: detail.views, rating: detail.rating, uploadTime: detail.uploadDate, sourceUrl: source.url, groupIds: groupId == 'default' ? const {} : {groupId}, quality: source.quality, status: DownloadStatus.queued, progress: 0, downloadedBytes: 0, totalBytes: 0, createdAt: now, updatedAt: now);
    final current = state.value ?? const DownloadState();
    _jobs[task.id] = (detail: detail, source: source);
    await _save(DownloadState(groups: current.groups, tasks: [...current.tasks.where((item) => item.videoCode != detail.id), task]));
    _schedule();
  }

  Future<void> _replace(String id, DownloadTask Function(DownloadTask) update) async {
    final current = state.value ?? const DownloadState();
    await _save(DownloadState(groups: current.groups, tasks: current.tasks.map((task) => task.id == id ? update(task) : task).toList()));
  }

  Future<void> retry(String id) async {
    final current = state.value ?? const DownloadState();
    final task = current.tasks.where((item) => item.id == id).firstOrNull;
    if (task == null || task.status != DownloadStatus.failed) return;
    final settings = await ref.read(settingsProvider.future);
    VideoDetail detail;
    VideoSource? source;
    try {
      detail = await ref.read(han1meRepositoryProvider).video(settings.resolvedBaseUrl, task.videoCode);
      source = detail.sources.where((item) => item.quality == task.quality).firstOrNull ?? detail.sources.firstOrNull;
    } catch (_) {
      if (task.sourceUrl?.isEmpty != false) return;
      detail = VideoDetail(id: task.videoCode, title: task.title, coverUrl: task.coverUrl, sources: const [], tags: const [], playlist: const [], related: const []);
      source = VideoSource(quality: task.quality, url: task.sourceUrl!);
    }
    if (source == null) return;
    _jobs[id] = (detail: detail, source: source);
    await _replace(id, (value) => value.copyWith(status: DownloadStatus.queued, progress: 0, downloadedBytes: 0, totalBytes: 0, sourceUrl: source!.url, clearError: true));
    _schedule();
  }

  Future<void> exportCompleted(String destinationPath) async {
    final destination = Directory(destinationPath);
    await destination.create(recursive: true);
    final tasks = (state.value ?? const DownloadState()).tasks.where((task) => task.status == DownloadStatus.completed);
    for (final task in tasks) {
      final source = Directory(path.join(_root.path, task.videoCode));
      if (!await source.exists()) continue;
      await for (final entity in source.list(recursive: true)) {
        if (entity is! File) continue;
        final relativePath = entity.path.substring(source.path.length + 1);
        final target = File(path.join(destination.path, task.videoCode, relativePath));
        await target.parent.create(recursive: true);
        await entity.copy(target.path);
      }
    }
  }

  Future<bool> exportCompletedWithPicker() async {
    if (!Platform.isAndroid) return false;
    final destination = await PlatformService.selectDirectory();
    if (destination == null) return false;
    final temporary = await Directory.systemTemp.createTemp('han1me_plus_export_');
    try {
      await exportCompleted(temporary.path);
      await PlatformService.exportDirectory(temporary.path, destination);
      return true;
    } finally {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    }
  }

  void _schedule() {
    final limit = ref.read(settingsProvider).value?.concurrentDownloads ?? 2;
    while (_running.length < limit) {
      final queued = (state.value?.tasks ?? const <DownloadTask>[]).where((item) => item.status == DownloadStatus.queued && _jobs.containsKey(item.id) && !_running.contains(item.id));
      final task = queued.isEmpty ? null : queued.first;
      if (task == null) return;
      final job = _jobs[task.id]!;
      _running.add(task.id);
      _run(task, job.detail, job.source).whenComplete(() {
        _running.remove(task.id);
        _schedule();
      });
    }
  }

  Future<void> _run(DownloadTask task, VideoDetail detail, VideoSource source) async {
    try {
      final directory = Directory(path.join(_root.path, task.videoCode));
      await directory.create(recursive: true);
      final meta = File(path.join(directory.path, 'detail.json'));
      await meta.writeAsString(jsonEncode({'videoCode': detail.id, 'title': detail.title, 'coverUrl': detail.coverUrl, 'artistName': detail.artist, 'genre': detail.genre, 'duration': detail.duration, 'rating': detail.rating, 'viewsText': detail.views, 'uploadDate': detail.uploadDate, 'introduction': detail.description, 'tags': detail.tags.map((tag) => tag.name).toList(), 'sourceQuality': source.quality, 'sourceUrl': source.url}));
      await _replace(task.id, (value) => value.copyWith(status: DownloadStatus.downloading));
      final localCoverPath = await _downloadCover(detail.coverUrl, directory);
      if (localCoverPath != null) await _replace(task.id, (value) => value.copyWith(localCoverPath: localCoverPath));
      final quality = source.quality.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
      final video = File(path.join(directory.path, 'video_$quality.mp4'));
      await _downloadVideo(source.url, video, task.id);
      await _replace(task.id, (value) => value.copyWith(status: DownloadStatus.completed, progress: 1, localVideoPath: video.path, localMetaPath: meta.path, clearError: true));
    } catch (error) {
      await _replace(task.id, (value) => value.copyWith(status: DownloadStatus.failed, errorMessage: '$error'));
    } finally {
      _jobs.remove(task.id);
    }
  }

  Future<void> _downloadVideo(String url, File destination, String taskId) async {
    final partial = File('${destination.path}.part');
    final received = await partial.exists() ? await partial.length() : 0;
    final response = await Dio().get<ResponseBody>(url, options: Options(responseType: ResponseType.stream, headers: received > 0 ? {'Range': 'bytes=$received-'} : null));
    final rangeAccepted = response.statusCode == 206;
    if (!rangeAccepted && received > 0) {
      await partial.delete();
      return _downloadVideo(url, destination, taskId);
    }
    final total = (response.data?.contentLength ?? -1) < 0 ? -1 : (rangeAccepted ? received : 0) + response.data!.contentLength;
    var downloaded = received;
    var windowStart = DateTime.now();
    var windowBytes = 0;
    var speedStart = DateTime.now();
    var speedBytes = 0;
    var speed = 0;
    final sink = partial.openWrite(mode: received > 0 && rangeAccepted ? FileMode.append : FileMode.write);
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        windowBytes += chunk.length;
        speedBytes += chunk.length;
        final elapsed = DateTime.now().difference(speedStart);
        if (elapsed >= const Duration(milliseconds: 800)) {
          speed = (speedBytes / elapsed.inMilliseconds * 1000).round();
          speedStart = DateTime.now();
          speedBytes = 0;
        }
        await _progress(taskId, (value) => value.copyWith(progress: total <= 0 ? 0 : downloaded / total, downloadedBytes: downloaded, totalBytes: total, speedBytesPerSecond: speed));
        final limit = ref.read(settingsProvider).value?.downloadSpeedLimitMbps ?? 0;
        if (limit > 0) {
          final elapsed = DateTime.now().difference(windowStart);
          final target = Duration(microseconds: (windowBytes * Duration.microsecondsPerSecond / (limit * 1024 * 1024)).round());
          if (target > elapsed) await Future<void>.delayed(target - elapsed);
          if (DateTime.now().difference(windowStart) >= const Duration(seconds: 1)) {
            windowStart = DateTime.now();
            windowBytes = 0;
          }
        }
      }
    } finally {
      await sink.close();
    }
    if (await destination.exists()) await destination.delete();
    await partial.rename(destination.path);
  }

  Future<String?> _downloadCover(String? url, Directory directory) async {
    if (url == null || url.isEmpty) return null;
    final cover = File(path.join(directory.path, 'cover.jpg'));
    try {
      await Dio().download(url, cover.path);
      return cover.path;
    } catch (_) {
      return null;
    }
  }
}
