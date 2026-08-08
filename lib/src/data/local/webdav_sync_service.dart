import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/settings.dart';
import '../../domain/models/library.dart';
import 'watch_repository.dart';

class WebDavSyncService {
  WebDavSyncService(this._dio);

  final Dio _dio;

  Future<WatchState> syncWatchState(AppSettings settings, WatchState local) async {
    final url = _fileUrl(settings.webDavUrl, 'han1meplus-watch-history.json');
    final options = _options(settings);
    WatchState remote = const WatchState();
    try {
      final response = await _dio.get<String>(url, options: options.copyWith(responseType: ResponseType.plain));
      final decoded = jsonDecode(response.data ?? '');
      if (decoded is Map<String, dynamic>) remote = WatchState.fromJson(decoded);
      if (decoded is Map) remote = WatchState.fromJson(Map<String, dynamic>.from(decoded));
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    } on FormatException {}
    final merged = _merge(local, remote);
    await _dio.put<void>(url, data: jsonEncode(merged.toJson()), options: options);
    return merged;
  }

  Future<List<FollowingVideo>> syncFavorites(AppSettings settings, List<FollowingVideo> local) async {
    final url = _fileUrl(settings.webDavUrl, 'han1meplus-favorites.json');
    final options = _options(settings);
    var remote = const <FollowingVideo>[];
    try {
      final response = await _dio.get<String>(url, options: options.copyWith(responseType: ResponseType.plain));
      final decoded = jsonDecode(response.data ?? '');
      if (decoded is List) remote = decoded.whereType<Map>().map((item) => FollowingVideo.fromJson(Map<String, dynamic>.from(item))).toList();
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    } on FormatException {}
    final merged = <String, FollowingVideo>{for (final item in remote) item.videoCode: item};
    for (final item in local) {
      final existing = merged[item.videoCode];
      if (existing == null || item.addedAt > existing.addedAt) merged[item.videoCode] = item;
    }
    final values = merged.values.toList()..sort((left, right) => right.addedAt.compareTo(left.addedAt));
    await _dio.put<void>(url, data: jsonEncode(values.map((item) => item.toJson()).toList()), options: options);
    return values;
  }

  Options _options(AppSettings settings) => Options(headers: {'Authorization': 'Basic ${base64Encode(utf8.encode('${settings.webDavUsername}:${settings.webDavPassword}'))}', 'Content-Type': 'application/json'});

  String _fileUrl(String base, String file) {
    final uri = Uri.tryParse(base.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) throw const FormatException('Invalid WebDAV URL');
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: '$path/$file').toString();
  }

  WatchState _merge(WatchState local, WatchState remote) {
    final progress = <String, WatchProgress>{};
    for (final item in [...local.continueItems, ...remote.continueItems]) {
      final existing = progress[item.videoCode];
      if (existing == null || item.updatedAt > existing.updatedAt) progress[item.videoCode] = item;
    }
    final history = <String, WatchHistory>{};
    for (final item in [...local.histories, ...remote.histories]) {
      final existing = history[item.id];
      if (existing == null || item.createdAt > existing.createdAt) history[item.id] = item;
    }
    final progressItems = progress.values.toList()..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final historyItems = history.values.toList()..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return WatchState(continueItems: progressItems.take(6).toList(), histories: historyItems);
  }
}
