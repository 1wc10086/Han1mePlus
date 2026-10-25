class MediaCdnRegion {
  const MediaCdnRegion({required this.id, required this.nodes});

  final String id;
  final List<String> nodes;
}

const List<MediaCdnRegion> mediaCdnRegions = [
  MediaCdnRegion(id: 'japan', nodes: ['178.249.213.26']),
  MediaCdnRegion(id: 'hongKong', nodes: ['156.146.44.89', '156.146.44.90']),
  MediaCdnRegion(id: 'taiwan', nodes: ['203.211.9.12']),
  MediaCdnRegion(id: 'russia', nodes: ['37.19.202.45']),
  MediaCdnRegion(
    id: 'unitedStates',
    nodes: ['156.146.43.178', '156.146.53.36', '143.244.51.58', '89.187.187.19', '89.187.187.18', '84.17.63.146'],
  ),
  MediaCdnRegion(
    id: 'europe',
    nodes: [
      '95.173.197.105',
      '95.173.197.104',
      '79.127.138.30',
      '79.112.216.203',
      '79.127.211.90',
      '212.102.56.179',
      '195.181.175.40',
      '195.181.172.3',
      '89.222.120.8',
      '84.17.50.8',
      '84.17.50.9',
      '109.61.92.54',
      '212.102.44.18',
    ],
  ),
  MediaCdnRegion(id: 'singapore', nodes: ['79.127.235.6', '79.127.235.2']),
];

MediaCdnRegion? mediaCdnRegionById(String id) {
  for (final region in mediaCdnRegions) {
    if (region.id == id) return region;
  }
  return null;
}

List<String> mediaCdnNodesFor({required String region, required String customIp}) {
  final custom = customIp
      .split(RegExp(r'[,;\s]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (custom.isNotEmpty) return custom;
  return mediaCdnRegionById(region)?.nodes ?? const [];
}
