class Danmaku {
  const Danmaku({required this.id, required this.positionMs, required this.content});

  final int id;
  final int positionMs;
  final String content;

  factory Danmaku.fromJson(Map<String, dynamic> json) => Danmaku(
        id: (json['id'] as num).toInt(),
        positionMs: (json['position_ms'] as num).toInt(),
        content: json['content'] as String,
      );
}

class DanmakuSubmission {
  const DanmakuSubmission({
    required this.videoId,
    required this.positionMs,
    required this.content,
    required this.installationId,
    this.accountId,
    this.accountName,
  });

  final String videoId;
  final int positionMs;
  final String content;
  final String installationId;
  final String? accountId;
  final String? accountName;

  Map<String, dynamic> toJson() => {
        'video_id': videoId,
        'position_ms': positionMs,
        'content': content,
        'installation_id': installationId,
        if (accountId != null) 'account_id': accountId,
        if (accountName != null) 'account_name': accountName,
        'client': 'han1me_plus',
        'client_version': '1',
      };
}
