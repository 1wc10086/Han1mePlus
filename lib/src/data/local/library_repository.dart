import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/library.dart';
import '../../domain/models/video.dart';
import 'json_store.dart';

final libraryRepositoryProvider = Provider((_) => LibraryRepository(JsonStore()));

class LibraryState {
  const LibraryState({this.watchLater = const [], this.favorites = const [], this.playlists = const [], this.artists = const [], this.subscriptionVideos = const {}});
  final List<FollowingVideo> watchLater;
  final List<FollowingVideo> favorites;
  final List<Playlist> playlists;
  final List<SubscribedArtist> artists;
  final Map<String, List<FollowingVideo>> subscriptionVideos;
  Map<String, dynamic> toJson() => {'watchLater': watchLater.map((item) => item.toJson()).toList(), 'favorites': favorites.map((item) => item.toJson()).toList(), 'playlists': playlists.map((item) => item.toJson()).toList(), 'subscribedArtists': artists.map((item) => item.toJson()).toList(), 'subscriptionVideos': subscriptionVideos.map((key, value) => MapEntry(key, value.map((item) => item.toJson()).toList()))};
  factory LibraryState.fromJson(Map<String, dynamic> json) {
    List<FollowingVideo> list(String key) => ((json[key] as List?) ?? const []).whereType<Map>().map((item) => FollowingVideo.fromJson(Map<String, dynamic>.from(item))).toList();
    final entries = (json['subscriptionVideos'] as Map?) ?? const {};
    return LibraryState(watchLater: list('watchLater'), favorites: list('favorites'), playlists: ((json['playlists'] as List?) ?? const []).whereType<Map>().map((item) => Playlist.fromJson(Map<String, dynamic>.from(item))).toList(), artists: ((json['subscribedArtists'] as List?) ?? const []).whereType<Map>().map((item) => SubscribedArtist.fromJson(Map<String, dynamic>.from(item))).toList(), subscriptionVideos: entries.map((key, value) => MapEntry('$key', (value as List? ?? const []).whereType<Map>().map((item) => FollowingVideo.fromJson(Map<String, dynamic>.from(item))).toList())));
  }
}

class LibraryRepository {
  LibraryRepository(this._store);
  final JsonStore _store;
  Future<LibraryState> load() async => LibraryState.fromJson(await _store.read('following_store.json'));
  Future<void> save(LibraryState state) => _store.write('following_store.json', state.toJson());
}

final libraryProvider = AsyncNotifierProvider<LibraryController, LibraryState>(LibraryController.new);
class LibraryController extends AsyncNotifier<LibraryState> {
  @override Future<LibraryState> build() => ref.read(libraryRepositoryProvider).load();
  FollowingVideo _item(VideoDetail video) => FollowingVideo(videoCode: video.id, title: video.title, coverUrl: video.coverUrl, artistName: video.artist, artistAvatarUrl: video.artistAvatarUrl, genre: video.genre, duration: video.duration, views: video.views, rating: video.rating, uploadTime: video.uploadDate, addedAt: DateTime.now().millisecondsSinceEpoch);
  Future<void> _save(LibraryState value) async { state = AsyncData(value); await ref.read(libraryRepositoryProvider).save(value); }
  Future<void> setWatchLater(VideoDetail video, bool enabled) async { final current = state.value ?? const LibraryState(); final items = current.watchLater.where((item) => item.videoCode != video.id).toList(); if (enabled) items.insert(0, _item(video)); await _save(_copy(current, watchLater: items)); }
  Future<void> setFavorite(VideoDetail video, bool enabled) async { final current = state.value ?? const LibraryState(); final items = current.favorites.where((item) => item.videoCode != video.id).toList(); if (enabled) items.insert(0, _item(video)); await _save(_copy(current, favorites: items)); }
  Future<void> createPlaylist(VideoDetail video, String title) async { final current = state.value ?? const LibraryState(); final playlist = Playlist(id: '${DateTime.now().microsecondsSinceEpoch}', title: title, count: 1, coverUrl: video.coverUrl, videos: [_item(video)]); await _save(_copy(current, playlists: [playlist, ...current.playlists])); }
  Future<void> saveToPlaylist(VideoDetail video, String playlistId) async { final current = state.value ?? const LibraryState(); final playlists = current.playlists.map((playlist) { if (playlist.id != playlistId) return playlist; final videos = [
        _item(video),
        ...playlist.videos.where((item) => item.videoCode != video.id),
      ]; return Playlist(id: playlist.id, title: playlist.title, count: videos.length, coverUrl: video.coverUrl ?? playlist.coverUrl, videos: videos); }).toList(); await _save(_copy(current, playlists: playlists)); }
  Future<void> setSubscription(VideoDetail video, bool enabled) async { final name = video.artist?.trim() ?? ''; if (name.isEmpty) return; final current = state.value ?? const LibraryState(); final id = _artistId(name); final artists = current.artists.where((artist) => artist.id != id).toList(); final videos = Map<String, List<FollowingVideo>>.from(current.subscriptionVideos); if (enabled) { artists.insert(0, SubscribedArtist(id: id, name: name, avatarUrl: video.artistAvatarUrl, genre: video.genre, addedAt: DateTime.now().millisecondsSinceEpoch)); videos[id] = [_item(video), ...?videos[id]?.where((item) => item.videoCode != video.id)]; } else { videos.remove(id); } await _save(_copy(current, artists: artists, subscriptionVideos: videos)); }
  Future<void> addSubscriptionVideo(VideoDetail video) async { final current = state.value ?? const LibraryState(); final name = video.artist?.trim() ?? ''; final id = _artistId(name); if (name.isEmpty || !current.artists.any((artist) => artist.id == id)) return; final videos = Map<String, List<FollowingVideo>>.from(current.subscriptionVideos); videos[id] = [_item(video), ...?videos[id]?.where((item) => item.videoCode != video.id)]; await _save(_copy(current, subscriptionVideos: videos)); }
  Future<void> cacheRemote(RemoteLibrary remote) async {
    final current = state.value ?? const LibraryState();
    final artists = remote.subscriptionArtists;
    final videos = <String, List<FollowingVideo>>{};
    for (final artist in artists) {
      videos[_artistId(artist.name)] = remote.subscriptions.where((video) => video.artistName == artist.name).toList();
    }
    await _save(_copy(current, watchLater: remote.watchLater, favorites: remote.favorites, playlists: remote.playlists, artists: artists, subscriptionVideos: videos));
  }
  Future<void> replaceFavorites(List<FollowingVideo> favorites) async {
    final current = state.value ?? const LibraryState();
    await _save(_copy(current, favorites: favorites));
  }
  Future<void> replace(LibraryState value) => _save(value);
  LibraryState _copy(LibraryState value, {List<FollowingVideo>? watchLater, List<FollowingVideo>? favorites, List<Playlist>? playlists, List<SubscribedArtist>? artists, Map<String, List<FollowingVideo>>? subscriptionVideos}) => LibraryState(watchLater: watchLater ?? value.watchLater, favorites: favorites ?? value.favorites, playlists: playlists ?? value.playlists, artists: artists ?? value.artists, subscriptionVideos: subscriptionVideos ?? value.subscriptionVideos);
  String _artistId(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}
