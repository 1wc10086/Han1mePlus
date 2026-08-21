class SearchRouteRequest {
  SearchRouteRequest({this.initialUrl}) : sessionId = _nextId();

  const SearchRouteRequest.fromRoute(this.sessionId, {this.initialUrl});

  final String sessionId;
  final String? initialUrl;

  static var _sequence = 0;

  static String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  @override
  bool operator ==(Object other) => other is SearchRouteRequest && other.sessionId == sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.genre = '',
    this.sort = '',
    this.date = '',
    this.duration = '',
    this.tags = const [],
    this.broad = false,
    this.type = '',
    this.page = 1,
  });

  final String text;
  final String genre;
  final String sort;
  final String date;
  final String duration;
  final List<String> tags;
  final bool broad;
  final String type;
  final int page;

  factory SearchQuery.fromUri(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null) return const SearchQuery();
    final parameters = uri.queryParameters;
    return SearchQuery(
      text: parameters['query'] ?? '',
      genre: parameters['genre'] ?? '',
      sort: parameters['sort'] ?? '',
      date: parameters['date'] ?? '',
      duration: parameters['duration'] ?? '',
      tags: List.unmodifiable(uri.queryParametersAll['tags[]'] ?? const <String>[]),
      broad: parameters['broad'] == 'on' || parameters['broad'] == 'true' || parameters['broad'] == '1',
      type: parameters['type'] ?? '',
    );
  }

  factory SearchQuery.fromJson(Map<String, dynamic> json) => SearchQuery(
        text: json['text'] as String? ?? '',
        genre: json['genre'] as String? ?? '',
        sort: json['sort'] as String? ?? '',
        date: json['date'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        tags: List.unmodifiable((json['tags'] as List? ?? const []).whereType<String>()),
        broad: json['broad'] == true,
        type: json['type'] as String? ?? '',
      );

  SearchQuery copyWith({
    String? text,
    String? genre,
    String? sort,
    String? date,
    String? duration,
    List<String>? tags,
    bool? broad,
    String? type,
    int? page,
  }) => SearchQuery(
        text: text ?? this.text,
        genre: genre ?? this.genre,
        sort: sort ?? this.sort,
        date: date ?? this.date,
        duration: duration ?? this.duration,
        tags: tags ?? this.tags,
        broad: broad ?? this.broad,
        type: type ?? this.type,
        page: page ?? this.page,
      );

  Uri toUri() {
    final parameters = <String, List<String>>{};

    void add(String key, String value) {
      if (value.isNotEmpty) parameters[key] = [value];
    }

    add('query', text);
    add('genre', genre);
    add('sort', sort);
    add('date', date);
    add('duration', duration);
    add('type', type);
    if (tags.isNotEmpty) parameters['tags[]'] = tags;
    if (broad) parameters['broad'] = const ['on'];
    return Uri(path: '/search', queryParameters: parameters);
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'genre': genre,
        'sort': sort,
        'date': date,
        'duration': duration,
        'tags': tags,
        'broad': broad,
        'type': type,
      };

  bool get hasSearchCriteria => text.isNotEmpty || genre.isNotEmpty || sort.isNotEmpty || date.isNotEmpty || duration.isNotEmpty || tags.isNotEmpty || type.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.genre == genre &&
      other.sort == sort &&
      other.date == date &&
      other.duration == duration &&
      other.broad == broad &&
      other.type == type &&
      _sameTags(other.tags);

  @override
  int get hashCode => Object.hash(text, genre, sort, date, duration, broad, type, Object.hashAll(tags));

  bool _sameTags(List<String> other) => other.length == tags.length && List.generate(tags.length, (index) => tags[index] == other[index]).every((same) => same);
}
