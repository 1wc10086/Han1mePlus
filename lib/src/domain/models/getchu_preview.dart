class GetchuPreviewFeed {
  const GetchuPreviewFeed({required this.month, required this.groups});

  final String month;
  final List<GetchuPreviewGroup> groups;
}

class GetchuPreviewGroup {
  const GetchuPreviewGroup({required this.releaseDate, required this.items});

  final String releaseDate;
  final List<GetchuPreviewItem> items;
}

class GetchuPreviewItem {
  const GetchuPreviewItem({required this.id, required this.title, required this.detailUrl, this.brand, this.coverUrl, this.price});

  final String id;
  final String title;
  final String detailUrl;
  final String? brand;
  final String? coverUrl;
  final String? price;
}

class GetchuPreviewDetail {
  const GetchuPreviewDetail({
    required this.id,
    required this.title,
    required this.productUrl,
    required this.videoUrls,
    required this.sections,
    required this.sampleImages,
    required this.seriesItems,
    this.brand,
    this.coverUrl,
    this.description,
    this.releaseDate,
    this.price,
  });

  final String id;
  final String title;
  final String productUrl;
  final String? brand;
  final String? coverUrl;
  final String? description;
  final String? releaseDate;
  final String? price;
  final List<String> videoUrls;
  final List<GetchuPreviewSection> sections;
  final List<String> sampleImages;
  final List<GetchuPreviewItem> seriesItems;
}

class GetchuPreviewSection {
  const GetchuPreviewSection({required this.title, required this.body});

  final String title;
  final String body;
}
