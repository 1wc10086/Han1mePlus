import '../../core/desktop_platform.dart';
import '../../core/settings.dart';
import '../local/json_store.dart';
import 'han1me_http_client.dart';

Future<void> bootstrapDesktopNetwork([AppSettings? settings]) async {
  if (!isDesktopHttpPlatform) return;
  final resolved = settings ?? await SettingsStore(JsonStore()).load();
  await Han1meHttpClient().setNetworkSettings(
    useBuiltInHosts: resolved.useBuiltInHosts,
    useDoh: resolved.useDoh,
    dohPreset: resolved.dohPreset,
    dohCustomUrl: resolved.dohCustomUrl,
    dohBootstrapIps: resolved.dohBootstrapIps,
    dohTimeoutSeconds: resolved.dohTimeoutSeconds,
    useEch: resolved.useEch,
  );
}
