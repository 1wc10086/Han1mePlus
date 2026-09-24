import 'dart:io';

import '../../core/platform_service.dart';

class GitHubReleaseAssets {
  GitHubReleaseAssets._();

  static const repository = '1wc10086/Han1mePlus';
  static const releasesPageUrl = 'https://github.com/$repository/releases/latest';

  static const _androidVariants = {
    'arm64-v8a': 'arm64',
    'armeabi-v7a': 'arm32',
    'x86_64': 'x64',
  };
  static const _platformNames = {
    'windows': 'windows.amd64-setup.exe',
    'linux': 'linux-x64.tar.gz',
    'ios': 'iphone.arm64.ipa',
  };
  static const _linuxSuffixes = ['.tar.gz', '.tar.xz', '.deb'];
  static const _platformSuffixes = {
    'ios': ['.ipa'],
    'macos': ['.dmg'],
  };

  static Future<String?>? _androidAbi;

  static Future<String?> _abi() => _androidAbi ??= PlatformService.androidUpdateAbi();

  static Future<String?> resolveName() async {
    if (Platform.isAndroid) {
      final variant = _androidVariants[await _abi()];
      return variant == null ? null : 'android.$variant.apk';
    }
    return _platformNames[Platform.operatingSystem];
  }

  static Future<Map?> selectApiAsset(Iterable<Map> assets) async {
    if (Platform.isAndroid) {
      final variant = _androidVariants[await _abi()];
      return variant == null ? null : _firstMatching(assets, ['android.$variant.apk']);
    }
    return switch (Platform.operatingSystem) {
      'windows' => _windowsAsset(assets),
      'linux' => _firstMatching(assets, _linuxSuffixes),
      _ => _firstMatching(assets, _platformSuffixes[Platform.operatingSystem] ?? const []),
    };
  }

  static String downloadUrl(String tag, String name) =>
      'https://github.com/$repository/releases/download/${Uri.encodeComponent(tag)}/$name';

  static String releaseUrl(String tag) => 'https://github.com/$repository/releases/tag/${Uri.encodeComponent(tag)}';

  static Map? _windowsAsset(Iterable<Map> assets) {
    final executables = assets
        .where((asset) => '${asset['name'] ?? ''}'.toLowerCase().endsWith('.exe'))
        .toList(growable: false);
    if (executables.isEmpty) return null;
    return executables.firstWhere(
      (asset) {
        final name = '${asset['name'] ?? ''}'.toLowerCase();
        return name.contains('setup') || name.contains('installer');
      },
      orElse: () => executables.first,
    );
  }

  static Map? _firstMatching(Iterable<Map> assets, List<String> suffixes) {
    for (final suffix in suffixes) {
      final match = assets
          .where((asset) => '${asset['name'] ?? ''}'.toLowerCase().endsWith(suffix))
          .firstOrNull;
      if (match != null) return match;
    }
    return null;
  }
}
