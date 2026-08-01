class ComicCard {
  const ComicCard({required this.id, required this.title, required this.coverUrl});
  final String id;
  final String title;
  final String coverUrl;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'coverUrl': coverUrl};
  factory ComicCard.fromJson(Map<String, dynamic> json) => ComicCard(id: json['id'] as String? ?? '', title: json['title'] as String? ?? '', coverUrl: json['coverUrl'] as String? ?? '');
}

class ComicHome {
  const ComicHome({required this.trending, required this.latest});
  final List<ComicCard> trending;
  final List<ComicCard> latest;
  Map<String, dynamic> toJson() => {'trending': trending.map((item) => item.toJson()).toList(), 'latest': latest.map((item) => item.toJson()).toList()};
  factory ComicHome.fromJson(Map<String, dynamic> json) => ComicHome(trending: _cards(json['trending']), latest: _cards(json['latest']));
}

List<ComicCard> _cards(Object? value) => (value as List? ?? const []).whereType<Map>().map((item) => ComicCard.fromJson(Map<String, dynamic>.from(item))).toList();

class ComicSearchResult {
  const ComicSearchResult({required this.items, required this.page, required this.totalPages});
  final List<ComicCard> items;
  final int page;
  final int totalPages;
}

class ComicTag {
  const ComicTag({required this.type, required this.name, required this.path});
  final String type;
  final String name;
  final String path;
}

class ComicDetail {
  const ComicDetail({required this.id, required this.title, required this.coverUrl, required this.pageCount, required this.tags, required this.imageUrls, this.artist, this.uploadTime, this.description});
  final String id;
  final String title;
  final String coverUrl;
  final int pageCount;
  final List<ComicTag> tags;
  final List<String> imageUrls;
  final String? artist;
  final String? uploadTime;
  final String? description;
}
