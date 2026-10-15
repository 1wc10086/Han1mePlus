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
/// **背景（已查证）**：媒体域名存在两套后端，必须区分：
/// - 图片域 `vdownload.hembed.com`（含 javchu 图片）：DNS 规范名即备用 CDN77 域，
///   同后端、同证书（SAN 覆盖两域）→ 整体替换 host 合法，内容也在。
/// - 视频域 `-8`：站方自建 VPS（216.227.173.26，单 IP），证书只覆盖自身，
///   **不是 CDN77 后端**——替换后 TLS 能过（校验目标是备用域）但 CDN77 上
///   没有它的内容，等于白换 → **绝不进替换表**。
const String kMediaCdnHost = 'vdownload.hembed.com';
const String kMediaBackupHost = '1497203185.rsc.cdn77.org';

/// 媒体 CDN 区域节点表（CDN77 边缘，与 Han1meViewer CDN_REGION_NODES 同源）。
const Map<String, List<String>> kCdnRegionNodes = {
  '日本': ['178.249.213.26'],
  '香港': ['156.146.44.89', '156.146.44.90'],
  '中国台湾': ['203.211.9.12'],
  '俄罗斯': ['37.19.202.45'],
  '美国': ['156.146.43.178', '156.146.53.36', '143.244.51.58', '89.187.187.19', '89.187.187.18', '84.17.63.146'],
  '欧洲': ['95.173.197.105', '95.173.197.104', '79.127.138.30', '79.112.216.203', '79.127.211.90', '212.102.56.179', '195.181.175.40', '195.181.172.3', '89.222.120.8', '84.17.50.8', '84.17.50.9', '109.61.92.54', '212.102.44.18'],
  '新加坡': ['79.127.235.6', '79.127.235.2'],
};

/// 媒体 URL 改写规则（视频节点 t33 + 图片域备用域）。
String rewriteMediaUrl(String url) {
  var result = url;
  // 1. 图片 CDN 备用域替换：仅精确匹配图片域（-8 视频域是独立 VPS 后端，不进表）
  //    （替换后路径、参数原样保留；TLS 校验目标变为备用域，证书 SAN 已查证覆盖）
  final uri = Uri.tryParse(result);
  if (uri != null && uri.host.toLowerCase() == kMediaCdnHost) {
    result = uri.replace(host: kMediaBackupHost).toString();
    AppLog.log('图片域替换 ${uri.host} -> $kMediaBackupHost');
  }
  // 2. AV 站 CDN 节点前缀统一切到可用的 t33
  if (kAvCdnNodeRewrite.hasMatch(result)) {
    result = result.replaceAllMapped(
        kAvCdnNodeRewrite, (m) => '${m.group(1)}t33.${m.group(2)}');
  }
  return result;
}
