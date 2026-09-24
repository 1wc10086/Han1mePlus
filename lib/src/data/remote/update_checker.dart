import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/models/update_info.dart';
import 'github_release_assets.dart';
import 'github_release_atom.dart';

class UpdateChecker {
  UpdateChecker(this._dio);

  final Dio _dio;

  static const _apiHeaders = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  static const _atomHeaders = {
    'Accept': 'application/atom+xml, application/xml;q=0.9, */*;q=0.8',
  };

  Future<UpdateInfo?> check({String? currentVersion}) async {
    try {
      final installedVersion = currentVersion ?? (await PackageInfo.fromPlatform()).version;
      final assetName = await GitHubReleaseAssets.resolveName();
      final release = await _fromApi() ?? await _fromAtom(assetName);
      if (release == null || !_newer(release.tagName, installedVersion)) return null;
      return release;
    } catch (_) {
      return null;
    }
  }

  Future<UpdateInfo?> _fromApi() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/${GitHubReleaseAssets.repository}/releases/latest',
        options: Options(responseType: ResponseType.json, headers: _apiHeaders),
      );
      final data = response.data;
      if (response.statusCode == null || response.statusCode! >= 300 || data == null) return null;
      final tag = '${data['tag_name'] ?? ''}'.trim();
      if (tag.isEmpty) return null;
      final asset = await GitHubReleaseAssets.selectApiAsset((data['assets'] as List? ?? const []).whereType<Map>().cast<Map>());
      final downloadUrl = Platform.isMacOS
          ? GitHubReleaseAssets.releasesPageUrl
          : '${asset?['browser_download_url'] ?? ''}'.trim();
      return UpdateInfo(
        tagName: tag,
        htmlUrl: '${data['html_url'] ?? ''}'.trim(),
        body: '${data['body'] ?? ''}',
        createdAt: '${data['created_at'] ?? ''}',
        downloadUrl: downloadUrl.isNotEmpty || Platform.isAndroid ? downloadUrl : '${data['html_url'] ?? ''}'.trim(),
        prerelease: data['prerelease'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UpdateInfo?> _fromAtom(String? assetName) async {
    try {
      final response = await _dio.get<String>(
        'https://github.com/${GitHubReleaseAssets.repository}/releases.atom',
        options: Options(responseType: ResponseType.plain, headers: _atomHeaders),
      );
      final feed = response.data;
      if (response.statusCode == null || response.statusCode! >= 300 || feed == null || feed.isEmpty) return null;
      return GitHubReleaseAtom.parseLatest(feed, assetName: assetName);
    } catch (_) {
      return null;
    }
  }

  bool _newer(String remote, String local) {
    final remoteParts = _parts(remote);
    final localParts = _parts(local);
    for (var index = 0; index < 3; index++) {
      if (remoteParts[index] != localParts[index]) {
        return remoteParts[index] > localParts[index];
      }
    }
    return false;
  }

  List<int> _parts(String value) {
    final parts = value
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('-')
        .first
        .split('+')
        .first
        .split('.');
    return List.generate(
      3,
      (index) => index < parts.length ? int.tryParse(parts[index]) ?? 0 : 0,
    );
  }
}
