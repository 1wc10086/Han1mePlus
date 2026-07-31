class VideoCard {
  const VideoCard({
    required this.id,
    required this.title,
    required this.coverUrl,
    this.duration,
    this.views,
    this.rating,
    this.artist,
    this.uploadTime,
  });

  final String id;
  final String title;
  final String coverUrl;
  final String? duration;
  final String? views;
  final String? rating;
  final String? artist;
  final String? uploadTime;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'coverUrl': coverUrl, 'duration': duration, 'views': views, 'rating': rating, 'artist': artist, 'uploadTime': uploadTime};
  factory VideoCard.fromJson(Map<String, dynamic> json) => VideoCard(id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', coverUrl: json['coverUrl'] as String? ?? '', duration: json['duration'] as String?, views: json['views'] as String?, rating: json['rating'] as String?, artist: json['artist'] as String?, uploadTime: json['uploadTime'] as String?);
}

class HomeSection {
  const HomeSection({required this.title, required this.videos, this.moreUrl, this.isFeatured = false});

  final String title;
  final List<VideoCard> videos;
  final String? moreUrl;
  final bool isFeatured;

  Map<String, dynamic> toJson() => {'title': title, 'videos': videos.map((video) => video.toJson()).toList(), 'moreUrl': moreUrl, 'isFeatured': isFeatured};
  factory HomeSection.fromJson(Map<String, dynamic> json) => HomeSection(title: json['title'] as String? ?? '', videos: ((json['videos'] as List?) ?? const []).whereType<Map>().map((item) => VideoCard.fromJson(Map<String, dynamic>.from(item))).toList(), moreUrl: json['moreUrl'] as String?, isFeatured: json['isFeatured'] == true);
}

class HomeFeed {
  const HomeFeed({required this.sections, this.featured});

  final VideoCard? featured;
  final List<HomeSection> sections;

  Map<String, dynamic> toJson() => {'featured': featured?.toJson(), 'sections': sections.map((section) => section.toJson()).toList()};
  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(featured: json['featured'] is Map ? VideoCard.fromJson(Map<String, dynamic>.from(json['featured'] as Map)) : null, sections: ((json['sections'] as List?) ?? const []).whereType<Map>().map((item) => HomeSection.fromJson(Map<String, dynamic>.from(item))).toList());
}

class PreviewItem {
  const PreviewItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    this.videoTitle,
    this.brand,
    this.releaseDate,
    this.description,
    this.tags = const [],
    this.previewImages = const [],
  });

  final String id;
  final String title;
  final String coverUrl;
  final String? videoTitle;
  final String? brand;
  final String? releaseDate;
  final String? description;
  final List<String> tags;
  final List<String> previewImages;
}

class PreviewFeed {
  const PreviewFeed({required this.title, required this.description, required this.items, this.coverUrl});

  final String title;
  final String description;
  final String? coverUrl;
  final List<PreviewItem> items;
}

class VideoTag {
  const VideoTag({required this.name, this.count});

  final String name;
  final int? count;
}

class VideoSource {
  const VideoSource({required this.quality, required this.url, this.type});

  final String quality;
  final String url;
  final String? type;
}

class VideoDetail {
  const VideoDetail({
    required this.id,
    required this.title,
    required this.sources,
    required this.tags,
    required this.playlist,
    required this.related,
    this.coverUrl,
    this.duration,
    this.artist,
    this.artistId,
    this.artistAvatarUrl,
    this.uploader,
    this.uploaderAvatarUrl,
    this.genre,
    this.views,
    this.rating,
    this.uploadDate,
    this.captionTitle,
    this.description,
    this.downloadUrl,
    this.csrfToken,
    this.currentUserId,
    this.subscriptionUserId,
  });

  final String id;
  final String title;
  final String? coverUrl;
  final String? duration;
  final String? artist;
  final String? artistId;
  final String? artistAvatarUrl;
  final String? uploader;
  final String? uploaderAvatarUrl;
  final String? genre;
  final String? views;
  final String? rating;
  final String? uploadDate;
  final String? captionTitle;
  final String? description;
  final String? downloadUrl;
  final String? csrfToken;
  final String? currentUserId;
  final String? subscriptionUserId;
  final List<VideoTag> tags;
  final List<VideoSource> sources;
  final List<VideoCard> playlist;
  final List<VideoCard> related;
}

class Comment {
  const Comment({required this.id, required this.username, required this.content, this.avatarUrl, this.timeAgo, this.likeCount, this.replyCount, this.hasMoreReplies = false, this.foreignId, this.likeUserId, this.likesCount, this.likesSum, this.liked = false, this.disliked = false});
  final String id;
  final String username;
  final String content;
  final String? avatarUrl;
  final String? timeAgo;
  final String? likeCount;
  final int? replyCount;
  final bool hasMoreReplies;
  final String? foreignId;
  final String? likeUserId;
  final int? likesCount;
  final int? likesSum;
  final bool liked;
  final bool disliked;
}

class CommentPage {
  const CommentPage({required this.comments, this.totalCount, this.csrfToken, this.currentUserId});
  final List<Comment> comments;
  final String? totalCount;
  final String? csrfToken;
  final String? currentUserId;
}
