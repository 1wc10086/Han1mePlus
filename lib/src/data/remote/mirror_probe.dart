import '../../core/site_url.dart';
import 'han1me_http_client.dart';

enum MirrorProbeKind { success, httpError, challenge, parseFailure, partialSuccess, failure }

class MirrorProbeResult {
  const MirrorProbeResult({
    required this.kind,
    this.statusCode,
    this.homeUrl,
    this.apiBase,
    this.error,
  });

  final MirrorProbeKind kind;
  final int? statusCode;
  final String? homeUrl;
  final String? apiBase;
  final String? error;
}

class MirrorProbe {
  MirrorProbe._();

  static Future<MirrorProbeResult> test({required String homeUrl, required bool appendPath}) async {
    final base = appendPath ? homeUrl : Uri.parse(homeUrl).origin;
    final http = Han1meHttpClient();
    try {
      final home = await http.get(siteHomeUrl(homeUrl));
      if (home.body.contains('cf-chl-') || home.body.contains('Just a moment')) {
        return const MirrorProbeResult(kind: MirrorProbeKind.challenge);
      }
      if (home.statusCode >= 400) {
        return MirrorProbeResult(kind: MirrorProbeKind.httpError, statusCode: home.statusCode, homeUrl: home.url);
      }
      if (!home.body.contains('home-rows-wrapper')) {
        return const MirrorProbeResult(kind: MirrorProbeKind.parseFailure);
      }
      final search = await http.get(siteEndpointUrl(base, 'search'));
      if (search.statusCode >= 400) {
        return MirrorProbeResult(kind: MirrorProbeKind.partialSuccess, statusCode: search.statusCode, homeUrl: home.url, apiBase: base);
      }
      return MirrorProbeResult(kind: MirrorProbeKind.success, homeUrl: home.url, apiBase: base);
    } catch (error) {
      return MirrorProbeResult(kind: MirrorProbeKind.failure, error: error.toString());
    }
  }
}
