class FollowingVideo {
  const FollowingVideo({required this.videoCode, required this.title, required this.addedAt, this.coverUrl, this.artistName, this.artistAvatarUrl, this.genre});
  final String videoCode;
  final String title;
  final String? coverUrl;
  final String? artistName;
  final String? artistAvatarUrl;
  final String? genre;
  final int addedAt;
  Map<String, dynamic> toJson() => {'videoCode': videoCode, 'title': title, 'coverUrl': coverUrl, 'artistName': artistName, 'artistAvatarUrl': artistAvatarUrl, 'genre': genre, 'addedAt': addedAt}..removeWhere((key, value) => value == null);
  factory FollowingVideo.fromJson(Map<String, dynamic> json) => FollowingVideo(videoCode: json['videoCode'] as String? ?? '', title: json['title'] as String? ?? '', coverUrl: json['coverUrl'] as String?, artistName: json['artistName'] as String?, artistAvatarUrl: json['artistAvatarUrl'] as String?, genre: json['genre'] as String?, addedAt: json['addedAt'] as int? ?? 0);
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
  const Playlist({required this.id, required this.title, required this.count, this.coverUrl});
  final String id;
  final String title;
  final int count;
  final String? coverUrl;
}

class RemoteLibrary {
  const RemoteLibrary({required this.watchLater, required this.favorites, required this.history, required this.playlists, this.csrfToken});
  final List<FollowingVideo> watchLater;
  final List<FollowingVideo> favorites;
  final List<FollowingVideo> history;
  final List<Playlist> playlists;
  final String? csrfToken;
}
