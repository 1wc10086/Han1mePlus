library;

import 'app_log.dart';
import 'site_hosts.dart';

/// ECH 域名策略静态配置。
///
/// 判定原则（用户定调）：
/// - **托管在 Cloudflare 的域名一律强制共享 ECH**（CF 的 ECH 是全体共享配置，
///   不依赖目标自身发布 ech= 记录）；这些域名被墙，降级明文 = SNI 裸奔 = RST，
///   所以 fail-closed（拿不到 ECH 配置宁可连不上）。
/// - **非 CF 域名（媒体 CDN 等）绝不用 CF 共享 ECH**：物理 IP 直连 + 普通 TLS，
///   系统解析真实 IP 即可（它们没被墙）。
///
/// 主站静态 IP 为 2026-10-14 GitHub Actions 探针实测解析值（IPv4）。

/// CF 共享 ECH 配置（由 crypto.cloudflare.com 发布，对全体走 CF 的站点生效）。
/// 静态内置，不依赖 DoH / DNS 查询。
const String kCfSharedEchConfigList =
    'AEX+DQBBJgAgACBLqW6dHS0WNGRPgllF7G7nzY8QUnW4XzMNwtXaA+YFBQAEAAEAAQASY2xvdWRmbGFyZS1lY2guY29tAAA=';

/// 强制 ECH 的主域（CF 托管、被墙、fail-closed）。
/// 与 Han1meViewer 的 HANIME_HOSTNAME 同源（单一事实来源）。
const Set<String> kEchDomains = {
  'hanime1.me',
  'hanime1.com',
  'hanimeone.me',
  'javchu.com',
};

/// 主域 → 静态真实 IP（探针实测，2026-10-14）。
/// 物理连接用这些 IP 直连；TLS 身份 / HTTP Host 保持原域名。
const Map<String, List<String>> kEchDomainAddresses = {
  'hanime1.me': ['104.26.8.104', '172.67.74.156', '104.26.9.104'],
  'hanime1.com': ['172.67.167.30', '104.21.42.221'],
  'hanimeone.me': ['172.67.215.214', '104.21.43.14'],
  'javchu.com': ['172.67.187.141', '104.21.7.70'],
};

/// 是否对该 host 强制 ECH（含子域匹配）。
bool isEchDomain(String host) {
  final h = host.toLowerCase();
  return kEchDomains.contains(h) || kEchDomains.any((d) => h.endsWith('.$d'));
}

/// 是否为站点主域（用于重定向回退判断：跨出站点域即交回原生通道）。
bool isSiteDomain(String host) {
  final h = host.toLowerCase();
  return hanimeSiteHosts.contains(h) ||
      hanimeSiteHosts.any((d) => h.endsWith('.$d'));
}

/// 媒体 URL 改写：AV 站 CDN 节点前缀统一切到可用的 t33
/// （t26 / t27 / t30 等旧节点已失效，站长未更新数据库，产生死链）。
/// 规则与 Han1meViewer Parser.kt 一致：
///   ^((?:https?:)?//)t\d+\.cdn2020\.com(?=/|:)  →  $1t33.cdn2020.com
final RegExp kAvCdnNodeRewrite =
    RegExp(r'^((?:https?:)?//)t\d+\.(cdn2020\.com)(?=/|:)', caseSensitive: false);

/// 媒体 CDN 替换规则。
///
/// **背景（已查证）**：媒体域名统一为 `vdownload.hembed` 系列
/// （图片、javchu 图片、视频均在此域下），移动按 SNI 封锁该域，IPv4 阻断。
/// 解决办法：URL 整体替换 host 为备用 CDN77 域。
/// TLS 校验的是替换后 URL 的 host（备用域），而备用域证书 SAN 覆盖自身，
/// 因此 **vdownload.hembed 全部子域（含视频用的 -8 变体）替换均合法**。
/// 已实测：备用域证书 SAN = 1497203185.rsc.cdn77.org + vdownload.hembed.com。
const String kMediaCdnHostPrefix = 'vdownload.hembed';
const String kMediaBackupHost = '1497203185.rsc.cdn77.org';

/// 媒体 URL 改写规则（视频节点 t33 + 媒体 CDN 备用域）。
String rewriteMediaUrl(String url) {
  var result = url;
  // 1. 媒体 CDN 备用域替换：host 以 vdownload.hembed 开头 → 备用域
  //    （替换后路径、参数原样保留；TLS 校验目标变为备用域，证书覆盖）
  final uri = Uri.tryParse(result);
  if (uri != null && uri.host.toLowerCase().startsWith(kMediaCdnHostPrefix)) {
    final original = uri.host;
    result = uri.replace(host: kMediaBackupHost).toString();
    AppLog.log('媒体域替换 $original -> $kMediaBackupHost');
  }
  // 2. AV 站 CDN 节点前缀统一切到可用的 t33
  if (kAvCdnNodeRewrite.hasMatch(result)) {
    result = result.replaceAllMapped(
        kAvCdnNodeRewrite, (m) => '${m.group(1)}t33.${m.group(2)}');
  }
  return result;
}
