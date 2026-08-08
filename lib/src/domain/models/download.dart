enum DownloadStatus { queued, downloading, completed, failed }

enum DownloadGroupSort { defaultOrder, recentlyUpdated, name }

class DownloadGroup {
  const DownloadGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sort = DownloadGroupSort.defaultOrder,
  });

  final String id;
  final String name;
  final int createdAt;
  final DownloadGroupSort sort;

  DownloadGroup copyWith({String? name, DownloadGroupSort? sort}) => DownloadGroup(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'sort': sort.name,
      };

  factory DownloadGroup.fromJson(Map<String, dynamic> json) => DownloadGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
        sort: DownloadGroupSort.values.where((value) => value.name == json['sort']).firstOrNull ?? DownloadGroupSort.defaultOrder,
      );
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.videoCode,
    required this.title,
    required this.groupIds,
    required this.quality,
    required this.status,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.createdAt,
    required this.updatedAt,
    this.coverUrl,
    this.duration,
    this.views,
    this.rating,
    this.uploadTime,
    this.sourceUrl,
    this.localVideoPath,
    this.localCoverPath,
    this.localMetaPath,
    this.localCommentPath,
    this.errorMessage,
    this.pinned = false,
  });

  final String id;
  final String videoCode;
  final String title;
  final String? coverUrl;
  final String? duration;
  final String? views;
  final String? rating;
  final String? uploadTime;
  final String? sourceUrl;
  final Set<String> groupIds;
  final String quality;
  final DownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final String? localVideoPath;
  final String? localCoverPath;
  final String? localMetaPath;
  final String? localCommentPath;
  final String? errorMessage;
  final int createdAt;
  final int updatedAt;
  final bool pinned;

  DownloadTask copyWith({
    Set<String>? groupIds,
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? sourceUrl,
    String? localVideoPath,
    String? localCoverPath,
    String? localMetaPath,
    String? localCommentPath,
    String? errorMessage,
    bool clearError = false,
    bool? pinned,
    int? updatedAt,
  }) =>
      DownloadTask(
        id: id,
        videoCode: videoCode,
        title: title,
        coverUrl: coverUrl,
        duration: duration,
        views: views,
        rating: rating,
        uploadTime: uploadTime,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        groupIds: groupIds ?? this.groupIds,
        quality: quality,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        localVideoPath: localVideoPath ?? this.localVideoPath,
        localCoverPath: localCoverPath ?? this.localCoverPath,
        localMetaPath: localMetaPath ?? this.localMetaPath,
        localCommentPath: localCommentPath ?? this.localCommentPath,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
        pinned: pinned ?? this.pinned,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoCode': videoCode,
        'title': title,
        'coverUrl': coverUrl,
        'duration': duration,
        'views': views,
        'rating': rating,
        'uploadTime': uploadTime,
        'sourceUrl': sourceUrl,
        'groupIds': groupIds.toList(),
        'quality': quality,
        'status': status.name,
        'progress': progress,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'localVideoPath': localVideoPath,
        'localCoverPath': localCoverPath,
        'localMetaPath': localMetaPath,
        'localCommentPath': localCommentPath,
        'errorMessage': errorMessage,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'pinned': pinned,
      }..removeWhere((key, value) => value == null);

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    final savedGroups = (json['groupIds'] as List?)?.whereType<String>().toSet();
    final legacyGroup = json['groupId'] as String?;
    return DownloadTask(
      id: json['id'] as String? ?? '',
      videoCode: json['videoCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      duration: json['duration'] as String?,
      views: json['views'] as String?,
      rating: json['rating'] as String?,
      uploadTime: json['uploadTime'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      groupIds: savedGroups != null ? savedGroups.where((id) => id != 'default').toSet() : legacyGroup == null || legacyGroup == 'default' ? {} : {legacyGroup},
      quality: json['quality'] as String? ?? '',
      status: DownloadStatus.values.where((value) => value.name == json['status']).firstOrNull ?? DownloadStatus.queued,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      localVideoPath: json['localVideoPath'] as String?,
      localCoverPath: json['localCoverPath'] as String?,
      localMetaPath: json['localMetaPath'] as String?,
      localCommentPath: json['localCommentPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}
