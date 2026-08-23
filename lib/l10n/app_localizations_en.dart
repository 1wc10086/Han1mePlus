// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Han1me+';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get english => 'English';

  @override
  String get keyframeSettings => 'Key H-Frame Settings';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get keyframesEnabled => 'Enable Key H-Frames';

  @override
  String get keyframesEnabledDescription =>
      'Show key H-frame entries and countdown in the player';

  @override
  String get keyframesDisabledDescription => 'Key H-frames are disabled';

  @override
  String get manage => 'Manage';

  @override
  String get noKeyframes => 'No key H-frames yet';

  @override
  String get editVideoTitle => 'Edit Video Title';

  @override
  String get deleteVideoKeyframes => 'Delete this video\'s key H-frames';

  @override
  String deleteVideoKeyframesConfirmation(Object title) {
    return 'Delete all key H-frames for \"$title\"?';
  }

  @override
  String get editPosition => 'Edit Position';

  @override
  String get deleteKeyframe => 'Delete Key H-Frame';

  @override
  String get deleteKeyframeTitle => 'Delete Key H-Frame';

  @override
  String get videoTitle => 'Video Title';

  @override
  String get positionMilliseconds => 'Position (ms)';

  @override
  String get invalidKeyframe =>
      'Invalid position, or less than 10 seconds from another keyframe';

  @override
  String get content => 'Content';

  @override
  String get languageSettings => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAndColor => 'Theme & Color';

  @override
  String get interfaceLayout => 'Interface Layout';

  @override
  String get wallpaperColors => 'Wallpaper Colors';

  @override
  String get basicColors => 'Basic Colors';

  @override
  String get customAccentColor => 'Custom Accent Color';

  @override
  String get invalidColor => 'Enter a six-digit hex color';

  @override
  String get playback => 'Playback';

  @override
  String get playerEngine => 'Player Engine';

  @override
  String get preferredQuality => 'Preferred Quality';

  @override
  String get resumePlayback => 'Resume Playback';

  @override
  String get resumePlaybackDescription =>
      'Continue from the last position on next playback';

  @override
  String get autoPlayOnOpen => 'Play Immediately';

  @override
  String get autoPlayOnOpenDescription =>
      'Start playback automatically when a video page opens';

  @override
  String get site => 'Site';

  @override
  String get network => 'Network';

  @override
  String get networkSettings => 'Network Settings';

  @override
  String get useBuiltInHosts => 'Use Built-in Hosts';

  @override
  String get useBuiltInHostsDescription =>
      'Use built-in Cloudflare addresses for Hanime1 domains, falling back to system DNS automatically';

  @override
  String get doh => 'DNS over HTTPS';

  @override
  String get useDoh => 'Use DNS over HTTPS';

  @override
  String get dohSettings => 'DNS over HTTPS Settings';

  @override
  String get dohDisabled => 'Disabled';

  @override
  String get dohPreset => 'Provider';

  @override
  String get dohCustomUrl => 'Custom DoH URL';

  @override
  String get dohBootstrapIps => 'Bootstrap IP Addresses';

  @override
  String get dohBootstrapIpsDescription =>
      'Separated by comma, space, or newline';

  @override
  String get dohTimeoutSeconds => 'Timeout (seconds)';

  @override
  String get dohTimeoutSecondsDescription => 'Range from 1 to 60 seconds';

  @override
  String get useEch => 'Enable ECH';

  @override
  String get useEchDescription =>
      'Encrypt the domain name in the TLS ClientHello for Hanime sites';

  @override
  String get echLogs => 'ECH Logs';

  @override
  String get echLogsDescription =>
      'View ECH configuration and connection status';

  @override
  String get clearEchLogs => 'Clear Logs';

  @override
  String get noEchLogs => 'No ECH logs';

  @override
  String get customMirrorSite => 'Custom Mirror Site';

  @override
  String get customMirrorSiteHint =>
      'Enter a mirror site with the same structure as the main site that opens its homepage directly, e.g. https://www.example.com/enter; the homepage is requested exactly as entered';

  @override
  String get enableCustomMirrorSite => 'Enable custom mirror site';

  @override
  String get customMirrorSiteInvalid =>
      'Enter a valid HTTPS URL that opens the homepage directly, e.g. https://www.example.com/enter';

  @override
  String get customMirrorApiPathMode => 'Other API Path';

  @override
  String get customMirrorPathFollowHome => 'Follow Home Directory';

  @override
  String get customMirrorPathFollowHomeSummary =>
      'e.g. https://www.example.com/enter/search';

  @override
  String get customMirrorPathRoot => 'Use Root Domain';

  @override
  String get customMirrorPathRootSummary =>
      'e.g. https://www.example.com/search. The homepage always uses the URL entered above';

  @override
  String get testConnection => 'Test Connection';

  @override
  String customMirrorTestSuccess(Object homeUrl, Object apiBase) {
    return 'Test succeeded\nHomepage: $homeUrl\nOther API base: $apiBase';
  }

  @override
  String customMirrorTestPartialSuccess(Object apiBase, int statusCode) {
    return 'Homepage test succeeded, but other API test failed\nOther API base: $apiBase\nReason: HTTP $statusCode';
  }

  @override
  String customMirrorTestFailed(Object error) {
    return 'Test failed: $error';
  }

  @override
  String customMirrorTestFailedHttp(int statusCode, Object url) {
    return 'Test failed: HTTP $statusCode\nHomepage: $url';
  }

  @override
  String get customMirrorTestParseFailed =>
      'Connected, but failed to parse the homepage structure';

  @override
  String get customMirrorTestChallenge =>
      'The site is protected by Cloudflare and may not be usable';

  @override
  String get custom => 'Custom';

  @override
  String get cloudflareVerification => 'Cloudflare Verification';

  @override
  String get cloudflareVerificationDescription =>
      'Complete verification when visiting protected pages';

  @override
  String get autoCheckUpdates => 'Auto-check for updates';

  @override
  String get useUpdateMirror => 'Automatically use update mirrors';

  @override
  String get useUpdateMirrorDescription =>
      'Try update mirrors in order when the original GitHub download fails';

  @override
  String get checkUpdates => 'Check for Updates';

  @override
  String get application => 'App';

  @override
  String get applicationSettings => 'Application';

  @override
  String get applicationSettingsDescription => 'Modify app-related settings';

  @override
  String get other => 'Other';

  @override
  String get keyframeManagement => 'Key H-Frame Management';

  @override
  String get about => 'About Han1me+';

  @override
  String get aboutDescription => 'Version and open-source info';

  @override
  String get explore => 'Explore';

  @override
  String get library => 'Library';

  @override
  String get cache => 'Cache';

  @override
  String get more => 'See More';

  @override
  String get featured => 'Featured';

  @override
  String get retry => 'Retry';

  @override
  String get videoSourceUnavailable => 'No playable video source';

  @override
  String get videoPlaybackFailed => 'Failed to load video';

  @override
  String get completeCloudflareVerification =>
      'Complete Cloudflare Verification';

  @override
  String get searchHint => 'Search videos, authors, tags…';

  @override
  String get noSearchResults => 'No matching videos found';

  @override
  String category(Object value) {
    return 'Category: $value';
  }

  @override
  String sort(Object value) {
    return 'Sort: $value';
  }

  @override
  String releaseDate(Object value) {
    return 'Release date: $value';
  }

  @override
  String get releaseDateTitle => 'Release Date';

  @override
  String duration(Object value) {
    return 'Duration: $value';
  }

  @override
  String get searchAuthors => 'Search Authors';

  @override
  String tagsSelected(int count) {
    return 'Tags: $count selected';
  }

  @override
  String get broadMatch => 'Broad Match';

  @override
  String get broadMatchDescription =>
      'Matches any of the selected tags; more results but lower precision.';

  @override
  String get tagVideoAttributes => 'Video Attributes';

  @override
  String get tagRelationships => 'Relationships';

  @override
  String get tagCharacterSettings => 'Character Settings';

  @override
  String get tagAppearance => 'Appearance';

  @override
  String get tagSettings => 'Scenes & Places';

  @override
  String get tagStory => 'Story';

  @override
  String get tagPositions => 'Positions';

  @override
  String get dateRange => 'Date Range';

  @override
  String get specificYearMonth => 'Specific Year & Month';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get allYears => 'All Years';

  @override
  String get allMonths => 'All Months';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear';

  @override
  String get all => 'All';

  @override
  String get defaultValue => 'Default';

  @override
  String get comments => 'Comments';

  @override
  String get reload => 'Reload';

  @override
  String get noComments => 'No comments yet';

  @override
  String get previews => 'Season Previews';

  @override
  String get getchuPreviews => 'Getchu Season Previews';

  @override
  String getchuPreviewMonth(Object month) {
    return 'Getchu $month Release Schedule';
  }

  @override
  String get getchuPreviewUnavailable =>
      'Getchu season previews are unavailable';

  @override
  String get noGetchuPreviews => 'No Getchu season previews this month';

  @override
  String get getchuPreviewDetail => 'Getchu Preview Details';

  @override
  String get openGetchu => 'Open Getchu';

  @override
  String get playTrailer => 'Play trailer';

  @override
  String trailerNumber(int number) {
    return 'Trailer $number';
  }

  @override
  String get productIntroduction => 'Product Introduction';

  @override
  String get story => 'Story';

  @override
  String get staff => 'Staff';

  @override
  String get getchuSeries => 'Series Products';

  @override
  String previewMonth(Object month) {
    return '$month Release Schedule';
  }

  @override
  String get previousMonth => 'Previous Month';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get previewUnavailable => 'Season previews unavailable this month';

  @override
  String get previewUnavailableDescription =>
      'You can reload, or view previews from earlier months.';

  @override
  String get noPreviews => 'No season previews this month';

  @override
  String get noPreviewsDescription =>
      'Previews will appear here once released. You can also browse earlier months.';

  @override
  String get watchVideo => 'Watch Video';

  @override
  String previewImages(int count) {
    return 'Preview Images ($count)';
  }

  @override
  String get statistics => 'Statistics';

  @override
  String watchDuration(Object duration) {
    return 'Watch time  $duration';
  }

  @override
  String get noWatchHistory => 'No watch history';

  @override
  String hoursMinutes(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String minutes(Object value) {
    return '$value min';
  }

  @override
  String seconds(Object value) {
    return '$value sec';
  }

  @override
  String get myLibrary => 'My Library';

  @override
  String get watchLater => 'Watch Later';

  @override
  String get favoriteVideos => 'Favorite Videos';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get noWatchLater => 'No watch-later videos';

  @override
  String get noFavoriteVideos => 'No favorite videos';

  @override
  String get noSubscriptionVideos => 'No subscription videos';

  @override
  String selectedItems(int count) {
    return '$count selected';
  }

  @override
  String get select => 'Select';

  @override
  String get deleteSelectedCache => 'Delete Selected Cache';

  @override
  String get createGroup => 'Create Group';

  @override
  String get noCache => 'No cache';

  @override
  String get localVideoMissing =>
      'Local video file not found. Delete this cache and re-download.';

  @override
  String get deleteCache => 'Delete Cache';

  @override
  String deleteCacheConfirmation(Object title) {
    return 'Delete the local cache for \"$title\"?';
  }

  @override
  String deleteGroupTitle(Object name) {
    return 'Delete \"$name\"';
  }

  @override
  String get moveGroupCacheToDefault =>
      'Caches in this group will move to the default group.';

  @override
  String get groupName => 'Group Name';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmExitTitle => 'Exit app?';

  @override
  String get queued => 'Queued';

  @override
  String get downloading => 'Downloading';

  @override
  String get completed => 'Completed';

  @override
  String get failed => 'Failed';

  @override
  String commentsTitle(Object title) {
    return '$title Comments';
  }

  @override
  String date(int year, int month, int day) {
    return '$month/$day/$year';
  }

  @override
  String get thirdPartyClient => 'Third-party Hanime1 client';

  @override
  String get version => 'Version';

  @override
  String get dataSource => 'Data Source';

  @override
  String get dataSourceDescription =>
      'Public page content from the Hanime1 website';

  @override
  String get githubRepository => 'GitHub Repository';

  @override
  String get reportIssue => 'Report an Issue';

  @override
  String get submitGitHubIssue => 'Submit a GitHub Issue';

  @override
  String get openSourceLicense => 'Open Source License';

  @override
  String get verificationComplete => 'Verification Complete';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get exitFullscreen => 'Exit Fullscreen';

  @override
  String get fullscreenPlayback => 'Fullscreen Playback';

  @override
  String get pauseBeforeAddingKeyframe =>
      'Pause the video before adding a key H-frame';

  @override
  String get addKeyframe => 'Add Key H-Frame';

  @override
  String addKeyframeConfirmation(int position) {
    return 'Add the current paused position as a key H-frame?\n\nCurrent time: $position ms\nAdjacent keyframes must be at least 10 seconds apart.';
  }

  @override
  String get add => 'Add';

  @override
  String get keyframeAdded => 'Key H-frame added';

  @override
  String get keyframeTooClose =>
      'Less than 10 seconds from an existing keyframe';

  @override
  String get longPressAddKeyframe => 'Long press to add a key H-frame';

  @override
  String get keyframes => 'Key H-Frames';

  @override
  String get deleteCurrentVideoKeyframes =>
      'Delete all key H-frames for the current video';

  @override
  String get deleteCurrentVideoKeyframesConfirmation =>
      'Delete all key H-frames for the current video?';

  @override
  String get editKeyframe => 'Edit Key H-Frame';

  @override
  String keyframeCountdown(Object seconds) {
    return 'Key H-frame in $seconds seconds';
  }

  @override
  String get episodeList => 'Episode List';

  @override
  String get seriesVideos => 'Series Videos';

  @override
  String get relatedVideos => 'Related Videos';

  @override
  String get studio => 'Studio';

  @override
  String get subscribed => 'Subscribed';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get favorite => 'Favorite';

  @override
  String get download => 'Download';

  @override
  String get share => 'Share';

  @override
  String get selectDownloadQuality => 'Select Download Quality';

  @override
  String get startDownload => 'Start Download';

  @override
  String get addedToDownloadQueue => 'Added to download queue';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get description => 'Description';

  @override
  String get commentsLoadFailed => 'Failed to load comments';

  @override
  String keyframeCount(int count) {
    return '$count keyframes';
  }

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get followSystem => 'Follow System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get rose => 'Rose';

  @override
  String get blue => 'Blue';

  @override
  String get teal => 'Teal';

  @override
  String get amber => 'Amber';

  @override
  String get forestGreen => 'Forest Green';

  @override
  String get orange => 'Orange';

  @override
  String get indigo => 'Indigo';

  @override
  String get pink => 'Pink';

  @override
  String get purple => 'Purple';

  @override
  String get keyframeSettingsDescription =>
      'Manage the toggle and per-video key H-frames';

  @override
  String get latestVersion => 'You\'re up to date';

  @override
  String newVersionAvailable(Object version) {
    return 'New version $version available';
  }

  @override
  String get newVersionReleased => 'A new version has been released.';

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get noInstallableApk => 'No installable APK for this version';

  @override
  String get updateIncomplete => 'Update Incomplete';

  @override
  String get downloadingUpdate => 'Downloading Update';

  @override
  String get connecting => 'Connecting...';

  @override
  String updateFailed(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get close => 'Close';

  @override
  String get monetColors => 'Monet Colors';

  @override
  String get monetColorsDescription => 'Use dynamic system wallpaper colors';

  @override
  String get downloadSettings => 'Download Settings';

  @override
  String get downloadSettingsDescription =>
      'Speed and concurrent download limits';

  @override
  String get downloadSpeedLimit => 'Download Speed Limit';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get concurrentDownloads => 'Concurrent Download Limit';

  @override
  String concurrentDownloadsDescription(int count) {
    return 'Download $count videos at the same time';
  }

  @override
  String get downloadPath => 'Download Path';

  @override
  String get defaultDownloadPath =>
      '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

  @override
  String get exportDownloads => 'Export Downloads';

  @override
  String get exportDownloadsDescription =>
      'Export all downloaded items from the private download directory to a custom directory';

  @override
  String get exportCompleted => 'Downloads exported';

  @override
  String get amoledMode => 'AMOLED Mode';

  @override
  String get amoledModeDescription => 'Use pure black background in dark theme';

  @override
  String get textSize => 'Text Size';

  @override
  String get textSizePreview => 'What is the meaning of life?';

  @override
  String get preview => 'Preview';

  @override
  String get watchHistory => 'Watch History';

  @override
  String get playlists => 'Playlists';

  @override
  String get noPlaylists => 'No playlists';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirmation(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String videoCount(int count) {
    return '$count videos';
  }

  @override
  String loadFailed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get playlistEmpty => 'Playlist is empty';

  @override
  String get writeComment => 'Write a Comment';

  @override
  String get commentHint => 'Enter your comment';

  @override
  String get latest => 'Latest';

  @override
  String get popular => 'Popular';

  @override
  String get oldest => 'Oldest';

  @override
  String playlistCreatedBy(Object name) {
    return 'Created by $name';
  }

  @override
  String playlistStats(int count, int views) {
    return 'Playlist • $count videos • $views views';
  }

  @override
  String get playAll => 'Play All';

  @override
  String get earliest => 'Earliest';

  @override
  String get mostReplies => 'Most Replies';

  @override
  String get mostLikes => 'Most Liked';

  @override
  String get mostDislikes => 'Most Disliked';

  @override
  String get viewReplies => 'View Replies';

  @override
  String viewRepliesCount(int count) {
    return 'View Replies ($count)';
  }

  @override
  String get reply => 'Reply';

  @override
  String get replyComment => 'Reply to Comment';

  @override
  String get send => 'Send';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get name => 'Name';

  @override
  String get create => 'Create';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirmation => 'Log out of the current account?';

  @override
  String get accountProfile => 'Account Profile';

  @override
  String get signedIn => 'Signed In';

  @override
  String get signedOut => 'Signed Out';

  @override
  String accountSummary(
      Object id, int subscriberCount, int videoCount, Object joined) {
    return '@$id\n$subscriberCount subscribers · $videoCount videos\n$joined';
  }

  @override
  String get tapToLogin => 'Tap to Log In';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get login => 'Log In';

  @override
  String get finishLogin => 'Finish Log In';

  @override
  String get playbackSettings => 'Playback Settings';

  @override
  String get playbackSettingsDescription =>
      'Playback speed, long-press speed, and control display time';

  @override
  String get defaultPlaybackSpeed => 'Default Playback Speed';

  @override
  String get longPressPlaybackSpeed => 'Default Long-press Speed';

  @override
  String get playerControlsTimeout => 'Player Controls Auto-Hide';

  @override
  String get playerControlsTimeoutDescription =>
      'Automatically hide player controls when idle';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockDescription =>
      'When enabled, screen-lock verification is required to enter the app';

  @override
  String get emergencyExit => 'Emergency Exit';

  @override
  String get emergencyExitDescription =>
      'When enabled, pressing volume up three times stops playback and returns to the home screen';

  @override
  String get hideFromRecents => 'Hide from Recents';

  @override
  String get hideFromRecentsDescription =>
      'Hide the app from the recents screen when in the background';

  @override
  String get commentSettings => 'Comment Settings';

  @override
  String get enableComments => 'Enable Comments';

  @override
  String get commentsDisabled => 'Comments are disabled';

  @override
  String get commentKeywordFilter => 'Keyword Filter';

  @override
  String get commentKeywordFilterDescription =>
      'Comments containing a keyword will be hidden';

  @override
  String get keyword => 'Keyword';

  @override
  String get deepLinkSettings => 'Deep Link Settings';

  @override
  String get deepLinkSettingsDescription =>
      'Jump into this app quickly after opening related web pages';

  @override
  String get openAppLinkSettings => 'Manage Web Links';

  @override
  String get openAppLinkSettingsDescription =>
      'Allow Han1me+ to open supported links in system settings';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get lockControls => 'Lock Controls';

  @override
  String get unlockControls => 'Unlock Controls';

  @override
  String get brightness => 'Brightness';

  @override
  String get volume => 'Volume';

  @override
  String get comicMode => 'Comic Mode';

  @override
  String get horizontalSearchCards => 'Horizontal Video Cards';

  @override
  String get horizontalSearchCardsDescription =>
      'Display videos as horizontal cards';

  @override
  String get compactSearchCards => 'Use New Cards for Some Categories';

  @override
  String get compactSearchCardsDescription =>
      'When enabled, Hentai and Short Anime categories use compact vertical cards with cover on top and title below';

  @override
  String get expandHomeVideoCards => 'Expand Home Video Cards';

  @override
  String get expandHomeVideoCardsDescription =>
      'When off, each home category shows a row of videos; when on, uses the videos-per-row setting';

  @override
  String get searchCardsPerRow => 'Video Cards Per Row';

  @override
  String searchCardsPerRowValue(int count) {
    return '$count per row';
  }

  @override
  String get comicModeDescription =>
      'When enabled, home, library, and cache show comic content only';

  @override
  String get comicBrowse => 'Comic Filters';

  @override
  String get trendingComics => 'Trending Comics';

  @override
  String get latestComics => 'Latest Uploads';

  @override
  String get comicSearchUnavailable => 'Comics don\'t support keyword search';

  @override
  String get comicDetails => 'Comic Details';

  @override
  String get read => 'Read';

  @override
  String pageCount(int count) {
    return '$count pages';
  }

  @override
  String get tags => 'Tags';

  @override
  String get chapter => 'Chapters';

  @override
  String get chapterOne => 'Chapter 1';

  @override
  String get addToLibrary => 'Add to Library';

  @override
  String get cacheComicConfirmation => 'Cache the entire comic?';

  @override
  String get info => 'Info';

  @override
  String get noComics => 'No comics';

  @override
  String get pageNumber => 'Page Number';

  @override
  String get readingMode => 'Reading Mode';

  @override
  String get general => 'General';

  @override
  String get leftToRight => 'Single Page (Left to Right)';

  @override
  String get rightToLeft => 'Single Page (Right to Left)';

  @override
  String get topToBottom => 'Single Page (Top to Bottom)';

  @override
  String get scroll => 'Scroll';

  @override
  String get scrollGap => 'Scroll (with gaps)';

  @override
  String get black => 'Black';

  @override
  String get gray => 'Gray';

  @override
  String get white => 'White';

  @override
  String get cacheCategory => 'Cache Category';

  @override
  String get newCategory => 'New Category';

  @override
  String get navigationDrawer => 'Use Navigation Drawer';

  @override
  String get navigationDrawerDescription =>
      'Use a drawer instead of the bottom navigation bar';

  @override
  String get liquidGlassBottomBar => 'Liquid Glass Bottom Bar';

  @override
  String get liquidGlassBottomBarDescription =>
      'Use a floating Liquid Glass bottom navigation bar';

  @override
  String get home => 'Home';

  @override
  String get quality => 'Quality';

  @override
  String get anime4k => 'Anime4K';

  @override
  String get uploader => 'Uploader';

  @override
  String get seekSensitivity => 'Seek Sensitivity';

  @override
  String get seekSensitivityDescription =>
      'Lower it to reduce the jump distance when swiping left or right';

  @override
  String seekSensitivityValue(int value) {
    return '$value%';
  }

  @override
  String get playerSettings => 'Player Settings';

  @override
  String get playerSettingsDescription =>
      'Decoder, renderer, and advanced libmpv options';

  @override
  String get hardwareDecode => 'Hardware Decode';

  @override
  String get hardwareDecodeDescription =>
      'Use hardware-accelerated video decoding';

  @override
  String get decoder => 'Decoder';

  @override
  String get decoderSettings => 'Decoder Settings';

  @override
  String get videoRenderer => 'Video Renderer';

  @override
  String get viewSettings => 'View Settings';

  @override
  String get customParameters => 'Custom Parameters';

  @override
  String get customParametersDescription =>
      'libmpv options applied on top of the defaults';

  @override
  String get customParametersHint => 'One key=value per line, e.g. cache=yes';

  @override
  String get superResolution => 'Super Resolution';

  @override
  String get superResolutionDescription =>
      'Upscale with Anime4K through libmpv shaders';

  @override
  String get availableOnlyForLibmpv =>
      'Only available when the decoder is libmpv';

  @override
  String get none => 'None';

  @override
  String get libMpv => 'libmpv';

  @override
  String get exoPlayer => 'ExoPlayer';

  @override
  String get avPlayer => 'AVPlayer';

  @override
  String get rendererAuto => 'auto';

  @override
  String get rendererGpu => 'gpu';

  @override
  String get rendererGpuNext => 'gpu-next';

  @override
  String get rendererMediacodecEmbed => 'mediacodec_embed';

  @override
  String get viewPlatformView => 'PlatformView';

  @override
  String get viewSurfaceView => 'SurfaceView';

  @override
  String get superResolutionOff => 'Off';

  @override
  String get superResolutionEfficiency => 'Efficiency';

  @override
  String get superResolutionQuality => 'Quality';

  @override
  String get accountManage => 'Account Management';

  @override
  String get accountManageSubtitleEmpty =>
      'Add or switch accounts for this site';

  @override
  String accountManageSubtitleCount(int count) {
    return '$count account(s) saved for this site';
  }

  @override
  String get removeAccount => 'Remove Account';

  @override
  String get addAccount => 'Add Account';

  @override
  String get defaultCategory => 'Default';

  @override
  String get appLocked => 'App Locked';

  @override
  String get unlocking => 'Unlocking…';

  @override
  String get unlock => 'Unlock';

  @override
  String get homeCategoryTabs => 'Use Home Category Tabs';

  @override
  String get homeCategoryTabsDescription =>
      'Show home categories as swipeable tabs and expand their video cards';

  @override
  String get recommendationFilters => 'Recommendation Filters';

  @override
  String get filters => 'Filters';

  @override
  String get videoTitleKeywordFilter => 'Video Title Keyword Filter';

  @override
  String get videoTitleKeywordFilterDescription =>
      'Hide videos whose titles contain a keyword';

  @override
  String get minimumVideoDuration => 'Minimum Video Duration';

  @override
  String get minimumVideoViews => 'Minimum Views';

  @override
  String get noFilter => 'No Filter';

  @override
  String get value => 'Value';

  @override
  String get authorFilter => 'Author Filter';

  @override
  String get authorFilterDescription => 'Hide videos by author name or ID';

  @override
  String get author => 'Author';

  @override
  String get exemptSubscribedAuthors => 'Exempt Subscribed Authors';

  @override
  String get exemptSubscribedAuthorsDescription =>
      'Content from subscribed authors is not filtered';

  @override
  String get applyFiltersToRelated => 'Apply Filters to Related Videos';

  @override
  String get applyFiltersToRelatedDescription =>
      'Filter related videos on the video details page';

  @override
  String get applyFiltersToSearch => 'Apply Filters to Search';

  @override
  String get applyFiltersToSearchDescription =>
      'Filter videos in search results';

  @override
  String get commentUserFilter => 'Comment User Filter';

  @override
  String get commentUserFilterDescription => 'Hide comments by user name or ID';

  @override
  String get incognitoPlayback => 'Incognito Mode';

  @override
  String get incognitoPlaybackDescription => 'Do not retain watch history';

  @override
  String get autoPlayNext => 'Auto Play Next';

  @override
  String get autoPlayNextDescription =>
      'Play the next episode after the current video finishes';

  @override
  String get autoPictureInPicture => 'Auto Picture-in-Picture';

  @override
  String get autoPictureInPictureDescription =>
      'Enter picture-in-picture when leaving the app during playback';

  @override
  String get webDavSettings => 'WebDAV Settings';

  @override
  String get webDav => 'WebDAV';

  @override
  String get webDavSync => 'WebDAV Sync';

  @override
  String get watchHistorySync => 'Watch History Sync';

  @override
  String get favoriteSync => 'Favorite Sync';

  @override
  String get webDavConfiguration => 'WebDAV Configuration';

  @override
  String get syncWatchHistoryNow => 'Sync Watch History Now';

  @override
  String get webDavDisabled => 'Enable WebDAV sync first';

  @override
  String get syncQueued => 'Watch history sync is queued';

  @override
  String get webDavUrl => 'WebDAV URL';

  @override
  String get password => 'Password';

  @override
  String get report => 'Report';

  @override
  String get filter => 'Filter';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get castToDevice => 'Cast to Device';

  @override
  String get pictureInPicture => 'Picture-in-Picture';

  @override
  String get videoAspectRatio => 'Video Aspect Ratio';

  @override
  String get aspectAuto => 'Auto';

  @override
  String get aspectCrop => 'Crop to Fill';

  @override
  String get aspectStretch => 'Stretch to Fill';

  @override
  String get aspectFourThree => '4:3';

  @override
  String get searchHistory => 'Search History';

  @override
  String get searchHistoryEmpty => 'No search history';

  @override
  String get deleteSearchHistory => 'Delete search history';

  @override
  String get restoreSearchHistory => 'Search this combination';

  @override
  String searchHistorySummary(Object query, Object filters) {
    return '$query · $filters';
  }

  @override
  String get searchHistoryAll => 'All';

  @override
  String searchHistoryTags(int count) {
    return '$count tags';
  }

  @override
  String get externalPlayback => 'External Playback';

  @override
  String get addTags => 'Add Tags';

  @override
  String get removeTags => 'Remove Tags';

  @override
  String get translate => 'Translate';

  @override
  String get translating => 'Translating...';

  @override
  String get translationFailed => 'Translation failed';

  @override
  String get cachedDownloads => 'Cached';

  @override
  String get bookshelfSettings => 'Shelf Settings';

  @override
  String get selectAll => 'Select All';

  @override
  String get pin => 'Pin';

  @override
  String get switchGroup => 'Switch Groups';

  @override
  String get pinned => 'Pinned';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get recentlyUpdated => 'Recently Updated';

  @override
  String get deleteBookshelf => 'Delete Shelf';

  @override
  String get deleteBookshelfDescription =>
      'Permanently delete this group without deleting cached media';

  @override
  String get deleteBookshelfConfirmation =>
      'Delete this group? It will be gone forever! (A really long time!)';

  @override
  String get backupSettings => 'Backup Settings';

  @override
  String get backupSettingsDescription =>
      'Import or export an application data backup';

  @override
  String get exportDataBackup => 'Export Data Backup';

  @override
  String get exportDataBackupDescription =>
      'Export settings, watch history, download groups and video information, key H-frames, and check-in records for device migration.';

  @override
  String get importDataBackup => 'Import Data Backup';

  @override
  String get importDataBackupDescription =>
      'Restore settings, watch history, download groups and video information, key H-frames, and check-in records from a backup file.';

  @override
  String get backupExported => 'Data backup exported';

  @override
  String get backupImported => 'Data backup imported';

  @override
  String get androidPrivateDownloadPath =>
      'Android downloads use the private app directory. Export downloads to save them through SAF.';

  @override
  String get privateDownloadPath =>
      'Mobile downloads use the private app directory. Export downloads to save them to a custom directory.';

  @override
  String get chooseFolder => 'Choose Folder';

  @override
  String get manualCookieLogin => 'Enter Cookies Manually';

  @override
  String get cookies => 'Cookies';

  @override
  String get invalidCookies => 'Enter valid cookies';
}
