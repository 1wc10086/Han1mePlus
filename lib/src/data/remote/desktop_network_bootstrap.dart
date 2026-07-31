import '../../core/desktop_platform.dart';
import '../../core/settings.dart';
import '../local/json_store.dart';
import 'han1me_http_client.dart';

/// 在 [runApp] 之前初始化桌面 HTTP 栈，避免首屏请求时尚未应用内置 Hosts / 代理。
Future<void> bootstrapDesktopNetwork() async {
  if (!isDesktopHttpPlatform) return;
  final settings = await SettingsStore(JsonStore()).load();
  await Han1meHttpClient().setNetworkSettings(
    useBuiltInHosts: settings.useBuiltInHosts,
    useDoh: settings.useDoh,
    dohPreset: settings.dohPreset,
    dohCustomUrl: settings.dohCustomUrl,
    dohBootstrapIps: settings.dohBootstrapIps,
    dohTimeoutSeconds: settings.dohTimeoutSeconds,
    useEch: settings.useEch,
  );
}
