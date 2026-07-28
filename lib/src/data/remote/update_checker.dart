import 'dart:io';

import 'package:dio/dio.dart';

class UpdateInfo {
  const UpdateInfo({required this.tagName, required this.htmlUrl, required this.body, required this.createdAt, required this.downloadUrl, required this.prerelease});
  final String tagName;
  final String htmlUrl;
  final String body;
  final String createdAt;
  final String downloadUrl;
  final bool prerelease;
}

class UpdateChecker {
  UpdateChecker(this._dio);
  final Dio _dio;

  Future<UpdateInfo?> check({String currentVersion = '1.0.7'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('https://api.github.com/repos/1wc10086/Han1mePlus/releases/latest', options: Options(responseType: ResponseType.json, headers: {'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'}));
      final data = response.data;
      if (response.statusCode == null || response.statusCode! >= 300 || data == null) return null;
      final tag = '${data['tag_name'] ?? ''}'.trim();
      final assets = (data['assets'] as List? ?? const []).whereType<Map>().cast<Map>();
      final preferredSuffix = Platform.isIOS ? '.ipa' : '.apk';
      final fallbackSuffix = Platform.isIOS ? '.apk' : '.ipa';
      final asset = assets.where((item) => '${item['name'] ?? ''}'.toLowerCase().endsWith(preferredSuffix)).firstOrNull
          ?? assets.where((item) => '${item['name'] ?? ''}'.toLowerCase().endsWith(fallbackSuffix)).firstOrNull;
      final downloadUrl = '${asset?['browser_download_url'] ?? ''}'.trim();
      final htmlUrl = '${data['html_url'] ?? ''}'.trim();
      if (tag.isEmpty || !_newer(tag, currentVersion)) return null;
      return UpdateInfo(
        tagName: tag,
        htmlUrl: htmlUrl,
        body: '${data['body'] ?? ''}',
        createdAt: '${data['created_at'] ?? ''}',
        downloadUrl: downloadUrl.isNotEmpty ? downloadUrl : htmlUrl,
        prerelease: data['prerelease'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  bool _newer(String remote, String local) {
    final a = _parts(remote), b = _parts(local);
    for (var index = 0; index < 3; index++) {
      if (a[index] != b[index]) return a[index] > b[index];
    }
    return false;
  }

  List<int> _parts(String value) {
    final clean = value.replaceFirst(RegExp(r'^[vV]'), '').split('-').first.split('+').first.split('.');
    return List.generate(3, (index) => index < clean.length ? int.tryParse(clean[index]) ?? 0 : 0);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
