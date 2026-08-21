import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/platform_service.dart';

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

class UpdateChecker {
  UpdateChecker(this._dio);

  final Dio _dio;

  Future<UpdateInfo?> check({String? currentVersion}) async {
    try {
      final installedVersion = currentVersion ?? (await PackageInfo.fromPlatform()).version;
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/1wc10086/Han1mePlus/releases/latest',
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ),
      );
      final data = response.data;
      if (response.statusCode == null || response.statusCode! >= 300 || data == null) return null;
      final tag = '${data['tag_name'] ?? ''}'.trim();
      final assets = (data['assets'] as List? ?? const []).whereType<Map>().cast<Map>();
      final asset = await _selectAsset(assets);
      final downloadUrl = Platform.isMacOS
          ? 'https://github.com/1wc10086/Han1mePlus/releases/latest'
          : '${asset?['browser_download_url'] ?? ''}'.trim();
      final htmlUrl = '${data['html_url'] ?? ''}'.trim();
      if (tag.isEmpty || !_newer(tag, installedVersion)) return null;
      return UpdateInfo(
        tagName: tag,
        htmlUrl: htmlUrl,
        body: '${data['body'] ?? ''}',
        createdAt: '${data['created_at'] ?? ''}',
        downloadUrl: downloadUrl.isNotEmpty || Platform.isAndroid ? downloadUrl : htmlUrl,
        prerelease: data['prerelease'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map?> _selectAsset(Iterable<Map> assets) async {
    if (Platform.isAndroid) {
      final abi = await PlatformService.androidUpdateAbi();
      final variant = switch (abi) {
        'arm64-v8a' => 'arm64',
        'armeabi-v7a' => 'arm32',
        'x86_64' => 'x64',
        _ => null,
      };
      return variant == null
          ? null
          : assets
              .where((asset) => '${asset['name'] ?? ''}'.toLowerCase() == 'android.$variant.apk')
              .firstOrNull;
    }
    return switch (Platform.operatingSystem) {
      'linux' => _firstMatching(assets, const ['.tar.gz', '.tar.xz', '.deb']),
      'windows' => _windowsAsset(assets),
      'ios' => _firstMatching(assets, const ['.ipa']),
      'macos' => _firstMatching(assets, const ['.dmg']),
      _ => null,
    };
  }

  Map? _windowsAsset(Iterable<Map> assets) {
    final exes = assets
        .where((asset) => '${asset['name'] ?? ''}'.toLowerCase().endsWith('.exe'))
        .toList(growable: false);
    if (exes.isEmpty) return null;
    return exes.firstWhere(
      (asset) {
        final name = '${asset['name'] ?? ''}'.toLowerCase();
        return name.contains('setup') || name.contains('installer');
      },
      orElse: () => exes.first,
    );
  }

  Map? _firstMatching(Iterable<Map> assets, List<String> suffixes) {
    for (final suffix in suffixes) {
      final match = assets
          .where((asset) => '${asset['name'] ?? ''}'.toLowerCase().endsWith(suffix))
          .firstOrNull;
      if (match != null) return match;
    }
    return null;
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
