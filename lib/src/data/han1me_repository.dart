import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/video.dart';
import '../domain/models/account.dart';
import '../domain/models/library.dart';
import 'remote/han1me_api.dart';
import 'remote/han1me_http_client.dart';

final han1meHttpClientProvider = Provider((ref) => Han1meHttpClient());
final han1meRepositoryProvider = Provider((ref) {
  return Han1meRepository(Han1meApi(ref.read(han1meHttpClientProvider)));
});

class Han1meRepository {
  Han1meRepository(this._api);

  final Han1meApi _api;
  final _requests = <String, Future<dynamic>>{};

  Future<T> _merge<T>(String key, Future<T> Function() request) {
    final existing = _requests[key];
    if (existing != null) return existing as Future<T>;
    final future = request();
    _requests[key] = future;
    future.then<void>((_) => _requests.remove(key), onError: (_, __) => _requests.remove(key));
    return future;
  }

  Future<HomeFeed> home(String baseUrl) => _api.home(baseUrl);
  Future<SearchResult> search({required String baseUrl, required String query, required String genre, required String sort, required int page}) =>
      _merge('search:$baseUrl:$query:$genre:$sort:$page', () => _api.search(baseUrl: baseUrl, query: query, genre: genre, sort: sort, page: page));
  Future<PreviewFeed> previews(String baseUrl, String month) => _merge('previews:$baseUrl:$month', () => _api.previews(baseUrl, month));
  void setCookie(String cookie) => _api.setCookie(cookie);
  void replaceCookie(String cookie) => _api.replaceCookie(cookie);
  void setCloudflareCookie(String cookie) => _api.setCookie(cookie);
  Future<VideoDetail> video(String baseUrl, String id) => _merge('video:$baseUrl:$id', () => _api.video(baseUrl, id));
  Future<Account> account(String baseUrl) => _merge('account:$baseUrl', () => _api.account(baseUrl));
  Future<void> updateProfile(String baseUrl, String id, String token, String name, String email) => _api.updateProfile(baseUrl, id, token, name, email);
  Future<void> updatePassword(String baseUrl, String id, String token, String oldPassword, String password, String confirmation) => _api.updatePassword(baseUrl, id, token, oldPassword, password, confirmation);
  Future<RemoteLibrary> library(String baseUrl, String id) => _merge('library:$baseUrl:$id', () => _api.library(baseUrl, id));
  Future<void> saveToPlaylist(String baseUrl, String token, String listId, String videoId, bool checked) => _api.saveToPlaylist(baseUrl, token, listId, videoId, checked);
  Future<void> createPlaylist(String baseUrl, String token, String videoId, String title, String description) => _api.createPlaylist(baseUrl, token, videoId, title, description);
  Future<void> setFavorite(String baseUrl, String token, String userId, String videoId, bool enabled) => _api.setFavorite(baseUrl, token, userId, videoId, enabled);
  Future<List<FollowingVideo>> playlistItems(String baseUrl, String id) => _api.playlistItems(baseUrl, id);
  Future<void> deletePlaylist(String baseUrl, String token, String id) => _api.deletePlaylist(baseUrl, token, id);
  Future<List<VideoCard>> related(String baseUrl, String id) => _merge('related:$baseUrl:$id', () => _api.related(baseUrl, id));
  Future<CommentPage> comments(String baseUrl, String id, {String type = 'video'}) => _merge('comments:$baseUrl:$type:$id', () => _api.comments(baseUrl, id, type: type));
  Future<CommentPage> replies(String baseUrl, String id) => _api.replies(baseUrl, id);
  Future<void> postComment(String baseUrl, String token, String userId, String type, String targetId, String text) => _api.postComment(baseUrl, token, userId, type, targetId, text);
  Future<void> replyComment(String baseUrl, String token, String id, String text) => _api.replyComment(baseUrl, token, id, text);
  Future<void> voteComment(String baseUrl, String token, Comment comment, bool positive) => _api.voteComment(baseUrl, token, comment, positive);
}
