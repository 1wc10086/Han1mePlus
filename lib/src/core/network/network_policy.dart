import '../logging/app_log.dart';
import '../site_hosts.dart';

const String kCfSharedEchConfig =
    'AEX+DQBBJgAgACBLqW6dHS0WNGRPgllF7G7nzY8QUnW4XzMNwtXaA+YFBQAEAAEAAQASY2xvdWRmbGFyZS1lY2guY29tAAA=';

const Set<String> kEchDomains = {
  'hanime1.me',
  'hanime1.com',
  'hanimeone.me',
  'javchu.com',
};

const Map<String, List<String>> kEchDomainAddresses = {
  'hanime1.me': ['104.26.8.104', '172.67.74.156', '104.26.9.104'],
  'hanime1.com': ['172.67.167.30', '104.21.42.221'],
  'hanimeone.me': ['172.67.215.214', '104.21.43.14'],
  'javchu.com': ['172.67.187.141', '104.21.7.70'],
};

const String kMediaCdnHost = 'vdownload.hembed.com';
const String kMediaBackupHost = '1497203185.rsc.cdn77.org';
const Set<String> kMediaCdnHosts = {kMediaCdnHost, kMediaBackupHost};

final RegExp _avCdnNode = RegExp(r'^((?:https?:)?//)t\d+\.(cdn2020\.com)(?=/|:)', caseSensitive: false);

bool isEchDomain(String host) {
  final value = host.toLowerCase();
  return kEchDomains.contains(value) || kEchDomains.any((domain) => value.endsWith('.$domain'));
}

bool isSiteDomain(String host) {
  final value = host.toLowerCase();
  return hanimeSiteHosts.contains(value) || hanimeSiteHosts.any((domain) => value.endsWith('.$domain'));
}

String rewriteMediaUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.host.toLowerCase() == kMediaCdnHost) {
    final rewritten = uri.replace(host: kMediaBackupHost).toString();
    AppLog.log('media host $kMediaCdnHost -> $kMediaBackupHost');
    return _rewriteAvCdnNode(rewritten);
  }
  return _rewriteAvCdnNode(url);
}

String _rewriteAvCdnNode(String url) => url.replaceAllMapped(
      _avCdnNode,
      (match) => '${match.group(1)}t33.${match.group(2)}',
    );
