import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../../domain/models/account.dart';
import '../../domain/models/library.dart';
import '../../domain/models/video.dart';
import 'han1me_http_client.dart';

class CloudflareChallengeException implements Exception {
  const CloudflareChallengeException(this.url);
  final String url;

  @override
  String toString() => 'Cloudflare browser verification is required';
}

class SearchResult {
  const SearchResult({required this.items, required this.page, required this.totalPages});
  final List<VideoCard> items;
  final int page;
  final int totalPages;
}

class Han1meApi {
  Han1meApi(this._http);

  final Han1meHttpClient _http;
  String? _cookie;
  final _resolvedOrigins = <String, String>{};

  static const userAgent = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36';

  void setCookie(String value) => _cookie = _mergeCookies(_cookie, value);
  void replaceCookie(String value) => _cookie = value;

  Future<HomeFeed> home(String baseUrl) async {
    final document = await _document('$baseUrl/');
    final sections = <HomeSection>[];
    final rowsWrapper = document.querySelectorAll('#home-rows-wrapper > a.horizontal-row-title');
    for (final titleAnchor in rowsWrapper) {
      final title = titleAnchor
          .querySelector('h3')
          ?.nodes
          .whereType<dom.Text>()
          .map((node) => node.text.trim())
          .where((text) => text.isNotEmpty)
          .join(' ') ?? '';
      final wrapper = titleAnchor.nextElementSibling;
      final row = wrapper?.querySelector('.home-rows-videos-wrapper.horizontal-row');
      if (row == null) continue;
      final items = row.querySelectorAll('div.horizontal-card').map(_card).where((video) => video.id.isNotEmpty).toList();
      if (items.isEmpty) continue;
      final moreUrl = titleAnchor.attributes['href'] ?? '';
      sections.add(HomeSection(title: title, moreUrl: moreUrl, videos: items));
    }
    final banner = document.querySelector('#home-banner-wrapper');
    final bannerImage = document.querySelector('div[style*="aspect-ratio"] img');
    final bannerTitle = banner?.querySelector('h1')?.text.trim();
    final bannerMeta = banner?.querySelector('h4')?.text.trim();
    final bannerCover = _absolute(baseUrl, bannerImage?.attributes['src']);
    final bannerId = RegExp(r'thumbnail/(\d+)').firstMatch(bannerCover)?.group(1) ?? '';
    final featured = bannerTitle == null || bannerTitle.isEmpty
        ? null
        : VideoCard(
            id: bannerId,
            title: bannerTitle,
            coverUrl: bannerCover,
            artist: bannerMeta?.split('•').first.trim(),
            views: bannerMeta?.split('•').skip(1).firstOrNull?.trim(),
          );
    return HomeFeed(sections: sections, featured: featured);
  }

  Future<SearchResult> search({
    required String baseUrl,
    required String query,
    required String genre,
    required String sort,
    required String date,
    required String duration,
    required List<String> tags,
    required bool broad,
    required String type,
    required int page,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': '$page',
      if (query.trim().isNotEmpty) 'query': query.trim(),
      if (genre.isNotEmpty) 'genre': genre,
      if (sort.isNotEmpty) 'sort': sort,
      if (date.isNotEmpty) 'date': date,
      if (duration.isNotEmpty) 'duration': duration,
      if (broad) 'broad': 'on',
      if (type.isNotEmpty) 'type': type,
    };
    final searchUri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {...queryParameters, if (tags.isNotEmpty) 'tags[]': tags},
    );
    final document = await _document(searchUri.toString());
    final normalCards = document.querySelectorAll('.content-padding-new div.horizontal-card, .content-padding div.horizontal-card');
    final videoItems = normalCards.isNotEmpty
        ? normalCards.map(_card).where((video) => video.id.isNotEmpty).toList(growable: false)
        : document.querySelectorAll('.home-rows-videos-wrapper').expand((wrapper) => wrapper.children).map(_simplifiedCard)
            .where((video) => video.id.isNotEmpty)
            .toList(growable: false);
    final items = videoItems.isNotEmpty || type != 'artist'
        ? videoItems
        : document.querySelectorAll('.search-artist-card').map((card) {
            final title = card.querySelector('.search-artist-title')?.text.trim() ?? '';
            final href = card.querySelector('a.overlay')?.attributes['href'];
            final artistQuery = Uri.tryParse(href ?? '')?.queryParameters['query'] ?? title;
            return VideoCard(
              id: '',
              title: title,
              coverUrl: _absolute(baseUrl, card.querySelector('img[style*="object-fit"]')?.attributes['src']),
              artist: card.querySelector('.search-artist-count')?.text.trim(),
              uploadTime: artistQuery,
            );
          }).where((artist) => artist.title.isNotEmpty && artist.coverUrl.isNotEmpty).toList(growable: false);
    final pagination = document.querySelectorAll('ul.pagination li.page-item > a.page-link');
    var currentPage = page;
    var totalPages = page;
    final pageNumbers = pagination.map((node) => int.tryParse(node.text.trim()) ?? 0).where((value) => value > 0).toList();
    if (pageNumbers.isNotEmpty) totalPages = pageNumbers.reduce((a, b) => a > b ? a : b);
    final activeNode = document.querySelector('ul.pagination li.page-item.active > span.page-link');
    if (activeNode != null) currentPage = int.tryParse(activeNode.text.trim()) ?? page;
    return SearchResult(items: items, page: currentPage, totalPages: totalPages);
  }

  Future<PreviewFeed> previews(String baseUrl, String month) async {
    final document = await _document('$baseUrl/previews/$month');
    final header = document.querySelector('.preview-top-content');
    final rows = document.querySelectorAll('.content-padding > div.row[id]');
    final items = rows.map((row) {
      final content = row.querySelector('.preview-info-content-padding');
      return PreviewItem(
        id: row.id,
        title: row.querySelector('h4, h3')?.text.trim() ?? '',
        coverUrl: _absolute(baseUrl, row.querySelector('.preview-info-cover > img')?.attributes['src']),
        videoTitle: content?.querySelector('h4')?.text.trim(),
        brand: content?.querySelector('h5 a')?.text.trim(),
        releaseDate: content?.querySelectorAll('h5').skip(1).firstOrNull?.text.trim(),
        description: content?.querySelector('h5.caption')?.text.trim(),
        tags: content?.querySelectorAll('.single-video-tag > a').map((tag) => tag.text.trim()).where((tag) => tag.isNotEmpty).toList() ?? const [],
        previewImages: content?.querySelectorAll('img.preview-image-modal-trigger').map((image) => _absolute(baseUrl, image.attributes['src'])).where((url) => url.isNotEmpty).toList() ?? const [],
      );
    }).where((item) => item.title.isNotEmpty && item.coverUrl.isNotEmpty).toList(growable: false);
    return PreviewFeed(
      title: header?.querySelector('h1')?.text.trim() ?? '$month previews',
      description: header?.querySelector('p')?.text.trim() ?? '',
      coverUrl: _absolute(baseUrl, document.querySelector('#player-div-wrapper > img')?.attributes['src']),
      items: items,
    );
  }

  Future<VideoDetail> video(String baseUrl, String id) async {
    final document = await _document('$baseUrl/watch?v=$id', referer: '$baseUrl/');
    final player = document.querySelector('video#player');
    final sources = (player == null ? const <dom.Element>[] : player.querySelectorAll('source'))
        .map((source) => VideoSource(
               quality: source.attributes['size'] ?? 'Default',
              url: _absolute(baseUrl, source.attributes['src']),
              type: source.attributes['type'],
            ))
        .where((source) => source.url.isNotEmpty)
        .toList();
    final title = (document.querySelector('meta[property="og:title"]')?.attributes['content'] ?? document.querySelector('title')?.text ?? '').trim();
    final finalTitle = title.contains('- Hanime1.me') || title.contains('- H\u52d5\u6f2b/\u88cf\u756a') ? title.split(' - ').first.trim() : title;
    final cover = _absolute(baseUrl, player?.attributes['poster'] ?? document.querySelector('meta[property="og:image"]')?.attributes['content']);
    final duration = _formatDuration(int.tryParse(document.querySelector('meta[property="og:video:duration"]')?.attributes['content'] ?? ''));
    final downloadUrl = _absolute(baseUrl, document.querySelector('#downloadBtn')?.attributes['href']);
    final descriptionPanel = document.querySelector('div.video-description-panel');
    final uploaderRow = descriptionPanel?.children.where((element) => (element.attributes['style'] ?? '').contains('display: flex')).firstOrNull;
    final uploader = uploaderRow?.querySelector('a[href*="/user/"] span')?.text.trim();
    final uploaderAvatarUrl = _absolute(baseUrl, uploaderRow?.querySelector('img')?.attributes['src']);
    final captionTitle = descriptionPanel
        ?.children
        .where((element) => element != uploaderRow && !element.classes.contains('hidden-xs') && !element.classes.contains('video-caption-text'))
        .map((element) => element.text.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((text) => text.isNotEmpty)
        .firstOrNull;
    final description = descriptionPanel?.querySelector('.video-caption-text')?.text.trim();
    final tags = document.querySelectorAll('.video-tags-wrapper .single-video-tag a')
        .where((tag) {
          final href = tag.attributes['href']?.trim() ?? '';
          dom.Element? element = tag;
          while (element != null && element.classes.contains('video-tags-wrapper') == false) {
            if (element.attributes.containsKey('data-target')) return false;
            if (element.attributes.containsKey('hidden') || element.classes.contains('hidden') || (element.attributes['style'] ?? '').replaceAll(' ', '').contains('display:none')) return false;
            element = element.parent;
          }
          return href.isNotEmpty;
        })
        .map((tag) {
          final text = tag.text.trim();
          final count = RegExp(r'\((\d+)\)').firstMatch(text)?.group(1);
          final href = tag.attributes['href']!.trim();
          final uri = Uri.tryParse(href);
          final name = uri?.queryParametersAll['tags[]']?.firstOrNull ?? uri?.queryParameters['tag'] ?? text.replaceFirst(RegExp(r'\s*\(\d+\)\s*$'), '').trim();
          return VideoTag(name: name, count: count == null ? null : int.parse(count), href: href);
        })
        .where((tag) => tag.name.isNotEmpty)
        .fold<List<VideoTag>>([], (list, tag) => list.any((item) => item.name == tag.name) ? list : [...list, tag]);
    final detail = descriptionPanel;
    final artistAnchor = document.querySelector('#video-user-avatar + img') ?? document.querySelector('#video-user-avatar') ?? detail?.querySelector('a[href*="/user/"] img');
    final artistName = document.querySelector('#video-artist-name')?.text.trim() ?? detail?.querySelector('a[href*="/user/"]')?.nextElementSibling?.querySelector('span')?.text.trim();
    final artistArea = document.querySelector('#video-artist-name')?.parent;
    final genreAnchor = artistArea?.querySelector('a[href*="genre"]') ?? document.querySelector('.video-description-panel a[href*="genre"], .video-details a[href*="genre"], #video-detail a[href*="genre"]');
    final genre = genreAnchor?.text.trim();
    final artistId = document.querySelector('#video-subscribe-form input[name="subscribe-artist-id"]')?.attributes['value'];
    final subscriptionUserId = document.querySelector('#video-subscribe-form input[name="subscribe-user-id"]')?.attributes['value'];
    final currentUserId = document.querySelector('input[name="like-user-id"]')?.attributes['value'];
    final csrfToken = document.querySelector('meta[name="csrf-token"]')?.attributes['content'] ?? document.querySelector('input[name="_token"]')?.attributes['value'];
    final artistAvatarUrl = _absolute(baseUrl, artistAnchor?.attributes['src']);
    final viewsLine = detail?.querySelector('div.hidden-xs')?.text.trim() ?? '';
    final views = _extractViews(viewsLine);
    final uploadDate = _extractDate(viewsLine);
    final commentCountText = document.querySelector('#tab-comments-count')?.text.replaceAll(RegExp(r'\D'), '') ?? '';
    final commentCount = int.tryParse(commentCountText);
    final playlist = document.querySelectorAll('#playlist-scroll .playlist-hover-wrap').map(_card).where((video) => video.id.isNotEmpty).fold<List<VideoCard>>([], _addUniqueCard);
    final rating = playlist.where((video) => video.id == id).firstOrNull?.rating;
    return VideoDetail(
      id: id,
       title: finalTitle.isEmpty ? 'Untitled' : finalTitle,
      coverUrl: cover,
      duration: duration,
      artist: artistName?.isEmpty == true ? null : artistName,
      artistId: artistId?.isEmpty == true ? null : artistId,
      artistAvatarUrl: artistAvatarUrl,
       uploader: uploader?.isEmpty == true ? null : uploader,
      uploaderAvatarUrl: uploaderAvatarUrl,
       genre: genre?.isEmpty == true ? null : genre,
       views: views,
       rating: rating,
       uploadDate: uploadDate,
       captionTitle: captionTitle,
       description: (description ?? '').isEmpty ? null : description,
      downloadUrl: downloadUrl,
      csrfToken: csrfToken,
      currentUserId: currentUserId,
      subscriptionUserId: subscriptionUserId,
      commentCount: commentCount,
      tags: tags,
      sources: sources,
        playlist: playlist,
        related: document
            .querySelectorAll('#related-tabcontent .horizontal-card, #related-tabcontent .related-video-margin-bottom')
            .map((element) => element.classes.contains('related-video-margin-bottom') ? _simplifiedCard(element.parent ?? element) : _card(element))
            .where((video) => video.id.isNotEmpty)
            .fold<List<VideoCard>>([], _addUniqueCard),
      );
  }

  Future<Account> account(String baseUrl) async {
    final home = await _document('$baseUrl/', referer: '$baseUrl/', skipCache: true);
    final profile = home.querySelector('#user-modal-trigger');
    final id = RegExp(r'/user/(\d+)').firstMatch(profile?.attributes['href'] ?? '')?.group(1) ??
        RegExp(r'\d+').firstMatch(home.querySelector('.profile-sub-stats-id')?.text ?? '')?.group(0);
    if (id == null) throw StateError('Account profile is unavailable');
    final document = await _document('$baseUrl/user/$id/edit', referer: '$baseUrl/', skipCache: true);
    final stats = home.querySelector('.profile-sub-stats-new-line')?.text ?? '';
    final numbers = RegExp(r'\d+').allMatches(stats).map((match) => int.parse(match.group(0)!)).toList();
    final avatar = document.querySelector('img#playlist-avatar') ?? home.querySelector('#user-modal-dp-wrapper img, .profile-avatar-wrapper img');
    return Account(
      cookie: _cookie ?? '',
      id: id,
      name: document.querySelector('input[name="name"]')?.attributes['value']?.trim() ?? home.querySelector('#user-modal-name, .profile-display-name')?.text.trim(),
      email: document.querySelector('input[name="email"]')?.attributes['value']?.trim(),
      avatarUrl: _absolute(baseUrl, avatar?.attributes['src']),
      csrfToken: document.querySelector('meta[name="csrf-token"]')?.attributes['content'] ?? document.querySelector('input[name="_token"]')?.attributes['value'],
      joinedLabel: home.querySelector('#user-modal-created')?.text.trim(),
      subscriberCount: numbers.isEmpty ? null : numbers.first,
      videoCount: numbers.length < 2 ? null : numbers[1],
    );
  }

  Future<void> updateProfile(String baseUrl, String userId, String token, String name, String email) => _form('$baseUrl/user/$userId', {'_token': token, '_method': 'patch', 'type': 'profile', 'name': name, 'email': email}, token);

  Future<void> updatePassword(String baseUrl, String userId, String token, String oldPassword, String password, String confirmation) => _form('$baseUrl/user/$userId', {'_token': token, '_method': 'patch', 'type': 'password', 'password_old': oldPassword, 'password_new': password, 'password_new_confirm': confirmation}, token);

  Future<RemoteLibrary> library(String baseUrl, String userId) async {
    final pages = await Future.wait([
      _document('$baseUrl/user/$userId/saves', skipCache: true),
      _document('$baseUrl/user/$userId/likes', skipCache: true),
      _document('$baseUrl/user/$userId/playlists', skipCache: true),
      _document('$baseUrl/user/$userId/histories?sort=latest&page=1', skipCache: true),
    ]);
    final subscriptionPage = await _document('$baseUrl/subscriptions?page=1', skipCache: true);
    final subscriptionArtists = _subscriptionArtists(baseUrl, subscriptionPage);
    final subscriptionPages = _pageCount(subscriptionPage);
    final subscriptionVideos = <FollowingVideo>[
      ..._subscriptionVideos(baseUrl, subscriptionPage),
      for (final page in await Future.wait([
        for (var number = 2; number <= subscriptionPages; number++) _document('$baseUrl/subscriptions?page=$number', skipCache: true),
      ]))
        ..._subscriptionVideos(baseUrl, page),
    ];
    final playlistPage = pages[2];
    final playlists = playlistPage.querySelectorAll('.user-tab-item-wrapper, .playlist-item-wrapper, .playlist-card').map((element) {
      final href = element.querySelector('a.video-link, a[href*="playlist?list="]')?.attributes['href'] ?? '';
      return Playlist(id: Uri.tryParse(href)?.queryParameters['list'] ?? RegExp(r'[?&]list=([^&]+)').firstMatch(href)?.group(1) ?? '', title: element.querySelector('.title, .playlist-title')?.text.trim() ?? '', count: int.tryParse(RegExp(r'\d+').firstMatch(element.querySelector('.stat-item, .playlist-count')?.text ?? '')?.group(0) ?? '') ?? 0, coverUrl: _absolute(baseUrl, element.querySelector('img.main-thumb, img')?.attributes['src']));
    }).where((item) => item.id.isNotEmpty && item.title.isNotEmpty).toList(growable: false);
    return RemoteLibrary(watchLater: _libraryVideos(baseUrl, pages[0]), favorites: _libraryVideos(baseUrl, pages[1]), playlists: playlists, subscriptionArtists: subscriptionArtists, subscriptions: subscriptionVideos, history: _libraryVideos(baseUrl, pages[3]), csrfToken: [playlistPage, pages[0], pages[1], pages[3]].map((page) => page.querySelector('meta[name="csrf-token"]')?.attributes['content'] ?? page.querySelector('input[name="_token"]')?.attributes['value']).whereType<String>().firstOrNull);
  }

  Future<void> saveToPlaylist(String baseUrl, String token, String listId, String videoId, bool checked) => _form('$baseUrl/save', {'_token': token, 'input_id': listId, 'video_id': videoId, 'is_checked': '$checked', 'user_id': ''}, token);
  Future<void> setSubscription(String baseUrl, String token, String userId, String artistId, bool enabled) => _form('$baseUrl/subscribe', {'_token': token, 'subscribe-user-id': userId, 'subscribe-artist-id': artistId, 'subscribe-status': enabled ? '' : '1'}, token);
  Future<void> createPlaylist(String baseUrl, String token, String videoId, String title, String description) => _form('$baseUrl/createPlaylist', {'_token': token, 'create-playlist-video-id': videoId, 'playlist-title': title, 'playlist-description': description}, token);
  Future<void> setFavorite(String baseUrl, String token, String userId, String videoId, bool enabled) => _form('$baseUrl/like', {'like-foreign-id': videoId, 'like-status': enabled ? '' : '1', '_token': token, 'like-user-id': userId, 'like-is-positive': '1'}, token);
  Future<PlaylistDetail> playlist(String baseUrl, String playlistId, String sort) async {
    final document = await _document('$baseUrl/playlist?list=$playlistId&sort=$sort&page=1', skipCache: true);
    final count = int.tryParse(document.querySelector('#sidebar-video-count')?.text.trim() ?? '');
    final views = int.tryParse(RegExp(r'(?:觀看次數|观看次数)\s*[:：]\s*(\d+)').firstMatch(document.querySelector('.playlist-stats')?.text ?? '')?.group(1) ?? '');
    final playlist = Playlist(id: playlistId, title: document.querySelector('.playlist-title')?.text.trim() ?? '', count: count ?? 0, coverUrl: _absolute(baseUrl, document.querySelector('.playlist-main-thumbnail')?.attributes['src']));
    return PlaylistDetail(playlist: playlist, author: document.querySelector('.playlist-author-info a')?.text.trim(), description: document.querySelector('.playlist-description')?.text.trim(), viewCount: views, videos: _playlistVideos(baseUrl, document));
  }
  Future<void> deletePlaylist(String baseUrl, String token, String playlistId) => _form('$baseUrl/playlist/$playlistId', {'_token': token, '_method': 'PUT', 'playlist-title': '', 'playlist-description': '', 'playlist-delete': 'on'}, token);
  Future<void> updatePlaylist(String baseUrl, String token, String playlistId, String title, String description, bool delete) => _form('$baseUrl/playlist/$playlistId', {'_token': token, '_method': 'PUT', 'playlist-title': title, 'playlist-description': description, if (delete) 'playlist-delete': 'on'}, token);
  Future<void> removePlaylistItem(String baseUrl, String token, String itemId) async {
    final origin = _resolvedOrigin(baseUrl);
    final currentToken = await _csrfToken(origin) ?? token;
    final response = await _http.delete('$origin/playlist/items/$itemId', const {}, headers: {'X-CSRF-TOKEN': currentToken, 'Accept': 'application/json', 'Referer': '$origin/'}, json: true);
    if (response.statusCode >= 400) throw DioException(requestOptions: RequestOptions(path: '$baseUrl/playlist/items/$itemId'), message: 'Request failed: HTTP ${response.statusCode}');
    final body = jsonDecode(response.body);
    if (body is! Map || body['success'] != true) throw DioException(requestOptions: RequestOptions(path: '$baseUrl/playlist/items/$itemId'), message: 'Playlist item removal failed');
  }
  Future<void> deleteHistory(String baseUrl, String token, String videoId) async {
    final origin = _resolvedOrigin(baseUrl);
    final currentToken = await _csrfToken(origin) ?? token;
    final response = await _http.delete('$origin/user/tab-item/$videoId', {'tab': 'histories'}, headers: {'X-CSRF-TOKEN': currentToken, 'Referer': '$origin/'});
    if (isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException('$baseUrl/user/tab-item/$videoId');
    if (response.statusCode >= 400) throw DioException(requestOptions: RequestOptions(path: '$baseUrl/user/tab-item/$videoId'), message: 'Request failed: HTTP ${response.statusCode}');
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['success'] != true) throw DioException(requestOptions: RequestOptions(path: '$baseUrl/user/tab-item/$videoId'), message: 'History deletion failed');
    } on FormatException {
      throw DioException(requestOptions: RequestOptions(path: '$baseUrl/user/tab-item/$videoId'), message: 'History deletion returned an invalid response');
    }
  }

  Future<List<VideoCard>> related(String baseUrl, String id) async {
    return (await video(baseUrl, id)).related;
  }

  Future<CommentPage> comments(String baseUrl, String videoId, {String type = 'video'}) async {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await _http.get(Uri.parse('$base/loadComment').replace(queryParameters: {'type': type, 'id': videoId}).toString());
    if (isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException('$base/watch?v=$videoId');
    if (response.statusCode >= 400) {
       throw DioException(requestOptions: RequestOptions(path: '$base/loadComment'), message: 'Comment request failed: HTTP ${response.statusCode}');
    }
    var body = response.body;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['comments'] is String) body = decoded['comments'] as String;
    } catch (_) {}
    final document = html_parser.parse(body);
    final root = document.querySelector('#comment-start');
    final csrfToken = document.querySelector('input[name="_token"]')?.attributes['value'];
    final currentUserId = document.querySelector('input[name="comment-user-id"]')?.attributes['value'];
    final children = root?.children ?? const <dom.Element>[];
    final comments = <Comment>[];

    for (var index = 0; index < children.length; index += 4) {
      final group = children.skip(index).take(4).toList();
      if (group.isEmpty) continue;
      final wrapper = dom.Element.tag('div')
        ..nodes.addAll(group.map((element) => element.clone(true)));
      final fields = wrapper.querySelectorAll('.comment-index-text');
      if (fields.length < 2) continue;

      final username = fields.first.querySelector('a')?.text.trim() ?? '';
      final content = fields[1].text.trim();
      if (username.isEmpty || content.isEmpty) continue;

      final avatarUrl = _absolute(base, wrapper.querySelector('img')?.attributes['src']);
      final timeAgo = fields.first.querySelector('span')?.text.trim();
      final likes = wrapper.querySelectorAll('#comment-like-form-wrapper span[style]');
      final replyWrapper = wrapper.querySelector('div[id^="reply-section-wrapper"]');
      final replyButtonText = wrapper.querySelectorAll('div.load-replies-btn').map((item) => item.text).join(' ');
      final replyCount = int.tryParse(RegExp(r'\d+').firstMatch(replyButtonText)?.group(0) ?? '');

      comments.add(Comment(
        id: replyWrapper?.id.split('-').last ?? '${username}_${_javaStringHash(content)}',
        username: username,
        content: content,
        avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
        timeAgo: timeAgo == null || timeAgo.isEmpty ? null : timeAgo,
        likeCount: likes.length > 1 ? likes[1].text.trim() : null,
        replyCount: replyCount,
        hasMoreReplies: wrapper.querySelector('div[class^="load-replies-btn"]') != null,
        foreignId: wrapper.querySelector('#foreign_id')?.attributes['value'],
        reportableId: wrapper.querySelector('span.report-btn')?.attributes['data-reportable-id'],
        reportableType: wrapper.querySelector('span.report-btn')?.attributes['data-reportable-type'],
        likeUserId: wrapper.querySelector('input[name="comment-like-user-id"]')?.attributes['value'],
        likesCount: int.tryParse(wrapper.querySelector('input[name="comment-likes-count"]')?.attributes['value'] ?? ''),
        likesSum: int.tryParse(wrapper.querySelector('input[name="comment-likes-sum"]')?.attributes['value'] ?? ''),
        liked: wrapper.querySelector('input[name="like-comment-status"]')?.attributes['value'] == '1',
        disliked: wrapper.querySelector('input[name="unlike-comment-status"]')?.attributes['value'] == '1',
      ));
    }
    return CommentPage(comments: comments, csrfToken: csrfToken, currentUserId: currentUserId);
  }

  Future<CommentPage> replies(String baseUrl, String commentId) async {
    final response = await _http.get(Uri.parse('$baseUrl/loadReplies').replace(queryParameters: {'id': commentId}).toString());
    if (isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException('$baseUrl/loadReplies');
    final decoded = jsonDecode(response.body) as Map;
    final document = html_parser.parse(decoded['replies'] as String? ?? '');
    final root = document.querySelector('div[id^="reply-start"]');
    final comments = <Comment>[];
    final children = root?.children ?? const <dom.Element>[];
    for (var index = 0; index + 1 < children.length; index += 2) {
      final body = children[index];
      final post = children[index + 1];
      final fields = body.querySelectorAll('.comment-index-text');
      if (fields.length < 2) continue;
      comments.add(Comment(id: '', username: fields.first.querySelector('a')?.text.trim() ?? '', content: fields[1].text.trim(), avatarUrl: _absolute(baseUrl, body.querySelector('img')?.attributes['src']), timeAgo: fields.first.querySelector('span')?.text.trim(), likeCount: post.querySelectorAll('span[style]').skip(1).firstOrNull?.text.trim(), foreignId: post.querySelector('#foreign_id')?.attributes['value'], likeUserId: post.querySelector('input[name="comment-like-user-id"]')?.attributes['value'], likesCount: int.tryParse(post.querySelector('input[name="comment-likes-count"]')?.attributes['value'] ?? ''), likesSum: int.tryParse(post.querySelector('input[name="comment-likes-sum"]')?.attributes['value'] ?? ''), liked: post.querySelector('input[name="like-comment-status"]')?.attributes['value'] == '1', disliked: post.querySelector('input[name="unlike-comment-status"]')?.attributes['value'] == '1', reportableId: body.querySelector('span.report-btn')?.attributes['data-reportable-id'], reportableType: body.querySelector('span.report-btn')?.attributes['data-reportable-type']));
    }
    return CommentPage(comments: comments);
  }

  Future<void> postComment(String baseUrl, String token, String userId, String type, String targetId, String text) => _form('$baseUrl/createComment', {'_token': token, 'comment-user-id': userId, 'comment-type': type, 'comment-foreign-id': targetId, 'comment-text': text, 'comment-count': '1', 'comment-is-political': '0'}, token);
  Future<void> replyComment(String baseUrl, String token, String commentId, String text) => _form('$baseUrl/replyComment', {'_token': token, 'reply-comment-id': commentId, 'reply-comment-text': text}, token);
  Future<void> voteComment(String baseUrl, String token, Comment comment, bool positive) => _form('$baseUrl/commentLike', {'_token': token, 'foreign_type': comment.id.isEmpty ? 'reply' : 'comment', 'foreign_id': comment.foreignId ?? '', 'is_positive': positive ? '1' : '0', 'comment-like-user-id': comment.likeUserId ?? '', 'comment-likes-count': '${comment.likesCount ?? 0}', 'comment-likes-sum': '${comment.likesSum ?? 0}', 'like-comment-status': comment.liked ? '1' : '0', 'unlike-comment-status': comment.disliked ? '1' : '0'}, token);
  Future<void> reportComment(String baseUrl, String token, String userId, Comment comment, String reason) => _form('$baseUrl/user/$userId/report', {'redirect-url': '', 'reportable-id': comment.reportableId ?? comment.foreignId ?? '', 'reportable-type': comment.reportableType ?? (comment.id.isEmpty ? 'reply' : 'comment'), 'reason': reason}, token);

  Future<dom.Document> _document(String url, {String? referer, bool skipCache = false}) async {
    final response = await _http.get(url, headers: referer == null ? null : {'Referer': referer});
    if (isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException(url);
    if (response.statusCode >= 400) {
      throw DioException(requestOptions: RequestOptions(path: url), message: 'Request failed: HTTP ${response.statusCode}');
    }
    final requestedOrigin = Uri.parse(url).origin;
    final resolvedOrigin = Uri.tryParse(response.url)?.origin;
    if (resolvedOrigin != null && resolvedOrigin != requestedOrigin) _resolvedOrigins[requestedOrigin] = resolvedOrigin;
    return html_parser.parse(response.body);
  }

  Future<void> _form(String url, Map<String, String> data, String token) async {
    final origin = _resolvedOrigin(url);
    final requestUrl = _atOrigin(url, origin);
    final currentToken = await _csrfToken(origin) ?? token;
    final formData = {...data, '_token': currentToken};
    final response = await _http.post(
      requestUrl,
      formData,
      headers: {'X-CSRF-TOKEN': currentToken, 'Referer': '$origin/'},
    );
    if (isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException(url);
    if (Uri.tryParse(response.url)?.path == '/login') {
      throw DioException(requestOptions: RequestOptions(path: url), message: 'Authentication expired');
    }
    if (response.statusCode >= 400 && response.statusCode != 302) throw DioException(requestOptions: RequestOptions(path: url), message: 'Request failed: HTTP ${response.statusCode}');
  }

  Future<String?> _csrfToken(String baseUrl) async {
    final response = await _http.get('$baseUrl/', headers: {'Referer': '$baseUrl/'});
    if (isCloudflareResponse(response.statusCode, response.headers, response.body)) throw CloudflareChallengeException(baseUrl);
    if (response.statusCode >= 400) return null;
    final document = html_parser.parse(response.body);
    return document.querySelector('meta[name="csrf-token"]')?.attributes['content'] ?? document.querySelector('input[name="_token"]')?.attributes['value'];
  }

  String _resolvedOrigin(String url) => _resolvedOrigins[Uri.parse(url).origin] ?? Uri.parse(url).origin;

  String _atOrigin(String url, String origin) {
    final target = Uri.parse(url);
    final base = Uri.parse(origin);
    return target.replace(scheme: base.scheme, host: base.host, port: base.hasPort ? base.port : null).toString();
  }

  List<FollowingVideo> _libraryVideos(String baseUrl, dom.Document document) => document.querySelectorAll('div[class^="user-tab-item-wrapper"]').map((card) {
        final link = card.querySelector('a')?.attributes['href'] ?? '';
        final image = card.querySelector('img');
        return FollowingVideo(videoCode: Uri.tryParse(link)?.queryParameters['v'] ?? '', title: card.querySelector('.title, .video-title')?.text.trim() ?? image?.attributes['alt']?.trim() ?? '', coverUrl: _absolute(baseUrl, image?.attributes['src']), artistName: card.querySelector('.subtitle a, .meta-author a')?.text.trim(), duration: card.querySelector('.duration')?.text.trim(), views: _statText(card.querySelectorAll('.stats-container .stat-item').skip(1).firstOrNull), rating: _statText(card.querySelector('.stats-container .stat-item')), uploadTime: card.querySelector('.meta-stats span')?.text.trim(), addedAt: 0, playlistItemId: null);
      }).where((video) => video.videoCode.isNotEmpty && video.title.isNotEmpty).toList(growable: false);

  List<FollowingVideo> _playlistVideos(String baseUrl, dom.Document document) => document.querySelectorAll('.playlist-video-list > div.user-tab-item-wrapper').map((card) {
        final link = card.querySelector('a[href*="watch"]')?.attributes['href'] ?? card.querySelector('[data-href]')?.attributes['data-href'] ?? '';
        final image = card.querySelector('img.main-thumb');
        return FollowingVideo(videoCode: Uri.tryParse(link)?.queryParameters['v'] ?? '', title: card.querySelector('.video-title')?.text.trim() ?? '', coverUrl: _absolute(baseUrl, image?.attributes['src']), artistName: card.querySelector('.meta-author a')?.text.trim(), duration: card.querySelector('.duration')?.text.trim(), views: _statText(card.querySelectorAll('.stats-container .stat-item').skip(1).firstOrNull), rating: _statText(card.querySelector('.stats-container .stat-item')), uploadTime: card.querySelector('.meta-stats span')?.text.trim(), addedAt: 0, playlistItemId: RegExp(r'playlist-item-(\d+)').firstMatch(card.id)?.group(1));
      }).where((video) => video.videoCode.isNotEmpty && video.title.isNotEmpty).toList(growable: false);

  List<SubscribedArtist> _subscriptionArtists(String baseUrl, dom.Document document) => document.querySelectorAll('.subscriptions-nav .subscriptions-artist-card').map((card) {
        final images = card.querySelectorAll('img');
        final name = card.querySelector('.card-mobile-title')?.text.trim() ?? '';
        return SubscribedArtist(id: name, name: name, avatarUrl: _absolute(baseUrl, images.length > 1 ? images[1].attributes['src'] : images.firstOrNull?.attributes['src']), addedAt: 0);
      }).where((artist) => artist.name.isNotEmpty).toList(growable: false);

  List<FollowingVideo> _subscriptionVideos(String baseUrl, dom.Document document) => document.querySelectorAll('.content-padding-new div[class^="video-item-container"]').map((card) {
        final link = card.querySelector('a[class^="video-link"]')?.attributes['href'] ?? '';
        final image = card.querySelector('img[class^="main-thumb"]');
        return FollowingVideo(videoCode: Uri.tryParse(link)?.queryParameters['v'] ?? '', title: card.attributes['title']?.trim() ?? '', coverUrl: _absolute(baseUrl, image?.attributes['src']), artistName: card.querySelector('.subtitle a')?.text.trim(), duration: card.querySelector('.duration')?.text.trim(), views: _statText(card.querySelectorAll('.stats-container .stat-item').skip(1).firstOrNull), rating: _statText(card.querySelector('.stats-container .stat-item')), uploadTime: card.querySelector('.meta-stats span')?.text.trim(), addedAt: 0);
      }).where((video) => video.videoCode.isNotEmpty && video.title.isNotEmpty).toList(growable: false);

  int _pageCount(dom.Document document) => document.querySelectorAll('ul.pagination a.page-link[href]').map((link) => int.tryParse(Uri.tryParse(link.attributes['href'] ?? '')?.queryParameters['page'] ?? '') ?? 1).fold(1, (count, page) => page > count ? page : count);

  static bool isCloudflareResponse(int? statusCode, Map<String, List<String>> headers, String body) => statusCode == 403 &&
      ((headers['cf-mitigated'] ?? headers['CF-Mitigated'] ?? const <String>[]).any((value) => value.toLowerCase() == 'challenge') ||
          body.contains('cf-chl-') ||
          body.contains('challenge-form') ||
          body.contains('Just a moment') ||
          body.contains('Attention Required'));

  VideoCard _card(dom.Element element) {
    final dataHref = element.attributes['data-href'] ?? '';
    final link = element.querySelector('a.video-link[href*="watch"], a[href*="watch?v="]');
    final href = link?.attributes['href'] ?? dataHref;
    final id = Uri.tryParse(href)?.queryParameters['v'] ?? '';
    final image = element.querySelector('img.main-thumb, img');
    final rating = _statText(element.querySelector('.stats-container .stat-item'));
    final views = element.querySelectorAll('.stats-container .stat-item').length > 1
        ? _statText(element.querySelectorAll('.stats-container .stat-item')[1])
        : null;
    final duration = element.querySelector('.duration')?.text.trim();
    final titleNode = element.querySelector('.title, .video-title, .home-rows-videos-title, .owl-home-rows-title');
    final title = titleNode?.text.trim() ?? image?.attributes['alt']?.trim() ?? '';
    final artistNode = element.querySelector('.subtitle a, .meta-author a');
    return VideoCard(
      id: id,
      title: title,
      coverUrl: image?.attributes['src'] ?? '',
      duration: duration,
      views: views,
      rating: rating,
      artist: artistNode?.text.trim(),
      uploadTime: element.querySelector('.meta-stats span')?.text.trim(),
    );
  }

  String? _statText(dom.Element? element) {
    if (element == null) return null;
    final text = element.nodes.whereType<dom.Text>().map((node) => node.text.trim()).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? element.text.trim() : text;
  }

  List<VideoCard> _addUniqueCard(List<VideoCard> cards, VideoCard video) => cards.any((item) => item.id == video.id) ? cards : [...cards, video];

  VideoCard _simplifiedCard(dom.Element element) {
    final href = element.attributes['href'] ?? element.attributes['data-href'] ?? element.querySelector('a')?.attributes['href'] ?? element.parent?.attributes['href'] ?? element.parent?.attributes['data-href'] ?? '';
    final id = Uri.tryParse(href)?.queryParameters['v'] ?? element.attributes['data-id'] ?? element.querySelector('[data-id]')?.attributes['data-id'] ?? '';
    final image = element.querySelector('img');
    return VideoCard(
      id: id,
      title: element.querySelector('.home-rows-videos-title, .owl-home-rows-title')?.text.trim() ?? element.parent?.querySelector('.home-rows-videos-title, .owl-home-rows-title')?.text.trim() ?? image?.attributes['alt']?.trim() ?? '',
      coverUrl: image?.attributes['src'] ?? '',
    );
  }

  String _absolute(String baseUrl, String? path) {
    if (path == null || path.isEmpty) return '';
    return Uri.parse(baseUrl).resolve(path).toString();
  }

  String _mergeCookies(String? current, String next) {
    final values = <String, String>{};
    for (final value in [current, next].whereType<String>().expand((cookie) => cookie.split(';'))) {
      final pair = value.trim();
      final index = pair.indexOf('=');
      if (index <= 0) continue;
      final name = pair.substring(0, index).trim();
      if (const {'domain', 'expires', 'httponly', 'max-age', 'partitioned', 'path', 'priority', 'samesite', 'secure'}.contains(name.toLowerCase())) continue;
      values[name] = pair.substring(index + 1).trim();
    }
    return values.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }

  String? _extractViews(String text) {
    final match = RegExp(r'(?:观看次数|觀看次數)\s*[:：]?\s*([^\s&]+(?:次)?)').firstMatch(text);
    return match?.group(1)?.trim();
  }

  String? _extractDate(String text) {
    final match = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(text);
    return match?.group(1);
  }

  String? _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final remainingSeconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$remainingSeconds' : '$minutes:$remainingSeconds';
  }

  int _javaStringHash(String text) {
    var hash = 0;
    for (final codeUnit in text.codeUnits) {
      hash = (31 * hash + codeUnit) & 0xffffffff;
    }
    return hash >= 0x80000000 ? hash - 0x100000000 : hash;
  }
}
