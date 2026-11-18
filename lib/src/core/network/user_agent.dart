import 'dart:io';

const androidUserAgent =
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36';

const iosUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';

const macosUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15';

const windowsUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36';

const linuxUserAgent =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36';

String? webViewUserAgent;

String get siteUserAgent {
  final detected = webViewUserAgent;
  if (detected != null && detected.isNotEmpty) return detected;
  if (Platform.isAndroid) return androidUserAgent;
  if (Platform.isIOS) return iosUserAgent;
  if (Platform.isMacOS) return macosUserAgent;
  if (Platform.isWindows) return windowsUserAgent;
  return linuxUserAgent;
}
