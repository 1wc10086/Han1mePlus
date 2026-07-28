class Account {
  const Account({required this.cookie, this.id, this.name, this.email, this.avatarUrl, this.csrfToken, this.joinedLabel, this.subscriberCount, this.videoCount});

  final String cookie;
  final String? id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String? csrfToken;
  final String? joinedLabel;
  final int? subscriberCount;
  final int? videoCount;

  Account copyWith({String? cookie, String? id, String? name, String? email, String? avatarUrl, String? csrfToken, String? joinedLabel, int? subscriberCount, int? videoCount}) => Account(
        cookie: cookie ?? this.cookie,
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        csrfToken: csrfToken ?? this.csrfToken,
        joinedLabel: joinedLabel ?? this.joinedLabel,
        subscriberCount: subscriberCount ?? this.subscriberCount,
        videoCount: videoCount ?? this.videoCount,
      );

  Map<String, dynamic> toJson() => {'cookie': cookie, 'id': id, 'name': name, 'email': email, 'avatarUrl': avatarUrl, 'csrfToken': csrfToken, 'joinedLabel': joinedLabel, 'subscriberCount': subscriberCount, 'videoCount': videoCount};

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        cookie: json['cookie'] as String? ?? '',
        id: json['id'] as String?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        csrfToken: json['csrfToken'] as String?,
        joinedLabel: json['joinedLabel'] as String?,
        subscriberCount: json['subscriberCount'] as int?,
        videoCount: json['videoCount'] as int?,
      );
}
