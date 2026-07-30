class FollowingVideo {
  const FollowingVideo({required this.videoCode, required this.title, required this.addedAt, this.coverUrl, this.artistName, this.artistAvatarUrl, this.genre, this.duration, this.views, this.rating, this.uploadTime, this.playlistItemId});
  final String videoCode;
  final String title;
  final String? coverUrl;
  final String? artistName;
  final String? artistAvatarUrl;
  final String? genre;
  final String? duration;
  final String? views;
  final String? rating;
  final String? uploadTime;
  final int addedAt;
  final String? playlistItemId;
  Map<String, dynamic> toJson() => {'videoCode': videoCode, 'title': title, 'coverUrl': coverUrl, 'artistName': artistName, 'artistAvatarUrl': artistAvatarUrl, 'genre': genre, 'duration': duration, 'views': views, 'rating': rating, 'uploadTime': uploadTime, 'addedAt': addedAt}..removeWhere((key, value) => value == null);
  factory FollowingVideo.fromJson(Map<String, dynamic> json) => FollowingVideo(videoCode: json['videoCode'] as String? ?? '', title: json['title'] as String? ?? '', coverUrl: json['coverUrl'] as String?, artistName: json['artistName'] as String?, artistAvatarUrl: json['artistAvatarUrl'] as String?, genre: json['genre'] as String?, duration: json['duration'] as String?, views: json['views'] as String?, rating: json['rating'] as String?, uploadTime: json['uploadTime'] as String?, addedAt: json['addedAt'] as int? ?? 0);
}

class SubscribedArtist {
  const SubscribedArtist({required this.id, required this.name, required this.addedAt, this.avatarUrl, this.genre});
  final String id;
  final String name;
  final String? avatarUrl;
  final String? genre;
  final int addedAt;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatarUrl': avatarUrl, 'genre': genre, 'addedAt': addedAt}..removeWhere((key, value) => value == null);
  factory SubscribedArtist.fromJson(Map<String, dynamic> json) => SubscribedArtist(id: json['id'] as String? ?? '', name: json['name'] as String? ?? '', avatarUrl: json['avatarUrl'] as String?, genre: json['genre'] as String?, addedAt: json['addedAt'] as int? ?? 0);
}

class WatchProgress {
  const WatchProgress({required this.videoCode, required this.title, required this.positionMs, required this.durationMs, required this.updatedAt, this.coverUrl});
  final String videoCode;
  final String title;
  final String? coverUrl;
  final int positionMs;
  final int durationMs;
  final int updatedAt;
  Map<String, dynamic> toJson() => {'videoCode': videoCode, 'title': title, 'coverUrl': coverUrl, 'positionMs': positionMs, 'durationMs': durationMs, 'updatedAt': updatedAt}..removeWhere((key, value) => value == null);
  factory WatchProgress.fromJson(Map<String, dynamic> json) => WatchProgress(videoCode: json['videoCode'] as String? ?? '', title: json['title'] as String? ?? '', coverUrl: json['coverUrl'] as String?, positionMs: json['positionMs'] as int? ?? 0, durationMs: json['durationMs'] as int? ?? 0, updatedAt: json['updatedAt'] as int? ?? 0);
}

class WatchHistory {
  const WatchHistory({required this.id, required this.videoCode, required this.title, required this.watchedMs, required this.date, required this.createdAt});
  final String id;
  final String videoCode;
  final String title;
  final int watchedMs;
  final String date;
  final int createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'videoCode': videoCode, 'title': title, 'watchedMs': watchedMs, 'date': date, 'createdAt': createdAt};
  factory WatchHistory.fromJson(Map<String, dynamic> json) => WatchHistory(id: json['id'] as String? ?? '', videoCode: json['videoCode'] as String? ?? '', title: json['title'] as String? ?? '', watchedMs: json['watchedMs'] as int? ?? 0, date: json['date'] as String? ?? '', createdAt: json['createdAt'] as int? ?? 0);
}

class Playlist {
  const Playlist({required this.id, required this.title, required this.count, this.coverUrl, this.videos = const []});
  final String id;
  final String title;
  final int count;
  final String? coverUrl;
  final List<FollowingVideo> videos;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'count': count, 'coverUrl': coverUrl, 'videos': videos.map((item) => item.toJson()).toList()}..removeWhere((key, value) => value == null);
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', count: json['count'] as int? ?? 0, coverUrl: json['coverUrl'] as String?, videos: ((json['videos'] as List?) ?? const []).whereType<Map>().map((item) => FollowingVideo.fromJson(Map<String, dynamic>.from(item))).toList());
}

class PlaylistDetail {
  const PlaylistDetail({required this.playlist, required this.author, required this.description, required this.viewCount, required this.videos});

  final Playlist playlist;
  final String? author;
  final String? description;
  final int? viewCount;
  final List<FollowingVideo> videos;
}

class RemoteLibrary {
  const RemoteLibrary({required this.watchLater, required this.favorites, required this.playlists, required this.subscriptionArtists, required this.subscriptions, required this.history, this.csrfToken});
  final List<FollowingVideo> watchLater;
  final List<FollowingVideo> favorites;
  final List<Playlist> playlists;
  final List<SubscribedArtist> subscriptionArtists;
  final List<FollowingVideo> subscriptions;
  final List<FollowingVideo> history;
  final String? csrfToken;
}
