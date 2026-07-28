import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/settings.dart';
import '../../core/platform_paths.dart';
import '../../data/han1me_repository.dart';
import '../../domain/models/download.dart';
import '../../domain/models/video.dart';
import '../../features/settings/settings_controller.dart';

class DownloadState {
  const DownloadState({this.groups = const [DownloadGroup(id: 'default', name: 'Default', createdAt: 0)], this.tasks = const []});

  final List<DownloadGroup> groups;
  final List<DownloadTask> tasks;

  Map<String, dynamic> toJson() => {'groups': groups.map((item) => item.toJson()).toList(), 'tasks': tasks.map((item) => item.toJson()).toList()};

  factory DownloadState.fromJson(Map<String, dynamic> json) {
    final groups = ((json['groups'] as List?) ?? const []).whereType<Map>().map((item) => DownloadGroup.fromJson(Map<String, dynamic>.from(item))).toList();
    return DownloadState(groups: groups.isEmpty ? const [DownloadGroup(id: 'default', name: 'Default', createdAt: 0)] : groups, tasks: ((json['tasks'] as List?) ?? const []).whereType<Map>().map((item) => DownloadTask.fromJson(Map<String, dynamic>.from(item))).toList());
  }
}

final downloadProvider = AsyncNotifierProvider<DownloadController, DownloadState>(DownloadController.new);

class DownloadController extends AsyncNotifier<DownloadState> {
  late Directory _root;
  final _running = <String>{};
  final _jobs = <String, ({VideoDetail detail, VideoSource source})>{};

  @override
  Future<DownloadState> build() async {
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (previous, next) {
      if (previous?.valueOrNull?.downloadPath != next.valueOrNull?.downloadPath) {
        ref.invalidateSelf();
      } else {
        _schedule();
      }
    });
    final settings = await ref.read(settingsProvider.future);
    final downloadPath = await normalizeDownloadPath(settings.downloadPath);
    _root = Directory(downloadPath);
    await _root.create(recursive: true);
    final file = File('${_root.path}/download_store.json');
    try {
      final loaded = DownloadState.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      return DownloadState(groups: loaded.groups, tasks: loaded.tasks.map((task) => task.status == DownloadStatus.completed || task.status == DownloadStatus.failed ? task : task.copyWith(status: DownloadStatus.failed, errorMessage: 'Download interrupted')).toList());
    } catch (_) {
      return const DownloadState();
    }
  }

  Future<void> _save(DownloadState value) async {
    await File('${_root.path}/download_store.json').writeAsString(jsonEncode(value.toJson()), flush: true);
    state = AsyncData(value);
  }

  Future<void> addGroup(String name) async {
    final text = name.trim();
    final current = state.value ?? const DownloadState();
    if (text.isEmpty || current.groups.any((group) => group.name == text)) return;
    await _save(DownloadState(groups: [...current.groups, DownloadGroup(id: DateTime.now().microsecondsSinceEpoch.toString(), name: text, createdAt: DateTime.now().millisecondsSinceEpoch)], tasks: current.tasks));
  }

  Future<void> deleteGroup(String id) async {
    if (id == 'default') return;
    final current = state.value ?? const DownloadState();
    final tasks = current.tasks.map((task) => task.groupId == id ? DownloadTask(id: task.id, videoCode: task.videoCode, title: task.title, coverUrl: task.coverUrl, duration: task.duration, views: task.views, rating: task.rating, uploadTime: task.uploadTime, sourceUrl: task.sourceUrl, groupId: 'default', quality: task.quality, status: task.status, progress: task.progress, downloadedBytes: task.downloadedBytes, totalBytes: task.totalBytes, localVideoPath: task.localVideoPath, localCoverPath: task.localCoverPath, localMetaPath: task.localMetaPath, localCommentPath: task.localCommentPath, errorMessage: task.errorMessage, createdAt: task.createdAt, updatedAt: task.updatedAt) : task).toList();
    await _save(DownloadState(groups: current.groups.where((group) => group.id != id).toList(), tasks: tasks));
  }

  Future<void> deleteTasks(Set<String> ids) async {
    final current = state.value ?? const DownloadState();
    for (final task in current.tasks.where((task) => ids.contains(task.id))) {
      final directory = Directory('${_root.path}/${task.videoCode}');
      if (await directory.exists()) await directory.delete(recursive: true);
      _jobs.remove(task.id);
    }
    await _save(DownloadState(groups: current.groups, tasks: current.tasks.where((task) => !ids.contains(task.id)).toList()));
  }

  Future<void> create(VideoDetail detail, VideoSource source, String groupId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final task = DownloadTask(id: detail.id, videoCode: detail.id, title: detail.title, coverUrl: detail.coverUrl, duration: detail.duration, views: detail.views, rating: detail.rating, uploadTime: detail.uploadDate, sourceUrl: source.url, groupId: groupId, quality: source.quality, status: DownloadStatus.queued, progress: 0, downloadedBytes: 0, totalBytes: 0, createdAt: now, updatedAt: now);
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
      detail = await ref.read(han1meRepositoryProvider).video(settings.baseUrl, task.videoCode);
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

  Future<void> exportCompleted(String path) async {
    final destination = Directory(path);
    await destination.create(recursive: true);
    final tasks = (state.value ?? const DownloadState()).tasks.where((task) => task.status == DownloadStatus.completed);
    for (final task in tasks) {
      final source = Directory('${_root.path}/${task.videoCode}');
      if (!await source.exists()) continue;
      await for (final entity in source.list(recursive: true)) {
        if (entity is! File) continue;
        final relativePath = entity.path.substring(source.path.length + 1);
        final target = File('${destination.path}/${task.videoCode}/$relativePath');
        await target.parent.create(recursive: true);
        await entity.copy(target.path);
      }
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
      final directory = Directory('${_root.path}/${task.videoCode}');
      await directory.create(recursive: true);
      final meta = File('${directory.path}/detail.json');
      await meta.writeAsString(jsonEncode({'videoCode': detail.id, 'title': detail.title, 'coverUrl': detail.coverUrl, 'artistName': detail.artist, 'genre': detail.genre, 'viewsText': detail.views, 'uploadDate': detail.uploadDate, 'introduction': detail.description, 'tags': detail.tags, 'sourceQuality': source.quality, 'sourceUrl': source.url}));
      await _replace(task.id, (value) => value.copyWith(status: DownloadStatus.downloading));
      final localCoverPath = await _downloadCover(detail.coverUrl, directory);
      if (localCoverPath != null) await _replace(task.id, (value) => value.copyWith(localCoverPath: localCoverPath));
      final video = File('${directory.path}/video_${source.quality}.mp4');
      await _downloadVideo(source.url, video, task.id);
      await _replace(task.id, (value) => value.copyWith(status: DownloadStatus.completed, progress: 1, localVideoPath: video.path, localMetaPath: meta.path, clearError: true));
    } catch (error) {
      await _replace(task.id, (value) => value.copyWith(status: DownloadStatus.failed, errorMessage: '$error'));
    } finally {
      _jobs.remove(task.id);
    }
  }

  Future<void> _downloadVideo(String url, File destination, String taskId) async {
    final response = await Dio().get<ResponseBody>(url, options: Options(responseType: ResponseType.stream));
    final total = response.data?.contentLength ?? -1;
    var received = 0;
    var windowStart = DateTime.now();
    var windowBytes = 0;
    final sink = destination.openWrite();
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        windowBytes += chunk.length;
        await _replace(taskId, (value) => value.copyWith(progress: total <= 0 ? 0 : received / total, downloadedBytes: received, totalBytes: total));
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
  }

  Future<String?> _downloadCover(String? url, Directory directory) async {
    if (url == null || url.isEmpty) return null;
    final cover = File('${directory.path}/cover.jpg');
    try {
      await Dio().download(url, cover.path);
      return cover.path;
    } catch (_) {
      return null;
    }
  }
}
