class UpdateInfo {
  const UpdateInfo({
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.createdAt,
    required this.downloadUrl,
    required this.prerelease,
  });

  final String tagName;
  final String htmlUrl;
  final String body;
  final String createdAt;
  final String downloadUrl;
  final bool prerelease;
}
