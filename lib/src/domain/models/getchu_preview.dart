class GetchuPreview {
  const GetchuPreview({required this.month, required this.groups});

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
