import '../../domain/models/update_info.dart';
import 'github_release_assets.dart';

class GitHubReleaseAtom {
  GitHubReleaseAtom._();

  static UpdateInfo? parseLatest(String feed, {String? assetName}) {
    final entry = _entry(feed);
    if (entry == null) return null;
    final tag = _text(entry, 'title')?.trim();
    if (tag == null || tag.isEmpty) return null;
    return UpdateInfo(
      tagName: tag,
      htmlUrl: _alternateHref(entry) ?? GitHubReleaseAssets.releaseUrl(tag),
      body: _plainText(_text(entry, 'content') ?? ''),
      createdAt: _text(entry, 'updated')?.trim() ?? '',
      downloadUrl: assetName == null ? GitHubReleaseAssets.releasesPageUrl : GitHubReleaseAssets.downloadUrl(tag, assetName),
      prerelease: false,
    );
  }

  static String? _entry(String feed) {
    final start = feed.indexOf(_entryOpen);
    if (start < 0) return null;
    final end = feed.indexOf(_entryClose, start);
    return end < 0 ? null : feed.substring(start, end);
  }

  static String? _text(String entry, String tag) {
    final open = entry.indexOf('<$tag');
    if (open < 0) return null;
    final start = entry.indexOf('>', open) + 1;
    final end = entry.indexOf('</$tag>', start);
    if (start <= 0 || end < 0) return null;
    return entry.substring(start, end);
  }

  static String? _alternateHref(String entry) {
    var offset = 0;
    while (true) {
      final open = entry.indexOf('<link', offset);
      if (open < 0) return null;
      final close = entry.indexOf('>', open);
      if (close < 0) return null;
      final attributes = entry.substring(open, close);
      if (attributes.contains(_alternateMarker)) {
        final href = _hrefPattern.firstMatch(attributes)?.group(1);
        if (href != null && href.isNotEmpty) return href;
      }
      offset = open + 1;
    }
  }

  static String _plainText(String html) => _decodeEntities(html)
      .replaceAll(_tagPattern, '')
      .replaceAll(_trailingSpacesPattern, '\n')
      .replaceAll(_blankLinesPattern, '\n\n')
      .trim();

  static String _decodeEntities(String value) {
    final decoded = value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    return decoded
        .replaceAllMapped(_hexEntityPattern, (match) => _character(match.group(1)!, 16) ?? match.group(0)!)
        .replaceAllMapped(_decimalEntityPattern, (match) => _character(match.group(1)!, 10) ?? match.group(0)!)
        .replaceAll('&amp;', '&');
  }

  static String? _character(String code, int radix) {
    final value = int.tryParse(code, radix: radix);
    return value == null ? null : String.fromCharCode(value);
  }

  static const _entryOpen = '<entry>';
  static const _entryClose = '</entry>';
  static const _alternateMarker = 'rel="alternate"';
  static final _hrefPattern = RegExp('href\\s*=\\s*"([^"]*)"');
  static final _tagPattern = RegExp('<[^>]+>');
  static final _trailingSpacesPattern = RegExp('[ \t]+\n');
  static final _blankLinesPattern = RegExp('\n{2,}');
  static final _decimalEntityPattern = RegExp(r'&#(\d+);');
  static final _hexEntityPattern = RegExp(r'&#[xX]([0-9a-fA-F]+);');
}
