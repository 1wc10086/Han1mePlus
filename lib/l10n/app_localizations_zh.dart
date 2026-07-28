// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Han1me+';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '系统默认';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get keyframeSettings => '关键 H 帧设置';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get keyframesEnabled => '启用关键 H 帧';

  @override
  String get keyframesEnabledDescription => '播放器中显示关键 H 帧入口与倒计时';

  @override
  String get keyframesDisabledDescription => '关键 H 帧功能已关闭';

  @override
  String get shareKeyframes => '共享您的关键 H 帧集';

  @override
  String get shareKeyframesDescription => '新增或修改后自动上传到共享数据源';

  @override
  String get shareKeyframesConfirmation => '将上传现有关键 H 帧并持续同步之后的更改。';

  @override
  String get useSharedKeyframes => '采用好心人的关键 H 帧集';

  @override
  String get useSharedKeyframesDescription => '自动使用共享数据源中的关键 H 帧';

  @override
  String get preferSharedKeyframes => '优先采用共享关键 H 帧集';

  @override
  String get preferSharedKeyframesDescription => '当本地集和共享集都有该影片的关键 H 帧时，采用共享集';

  @override
  String get upload => '上传';

  @override
  String get uploadingKeyframes => '正在上传关键 H 帧';

  @override
  String get uploadComplete => '上传完成';

  @override
  String get keyframesUploadDescription => '共享功能已开启，之后的更改将自动上传。';

  @override
  String keyframesUploadFailed(Object error) {
    return '上传失败（$error），请稍后重试。';
  }

  @override
  String get manage => '管理';

  @override
  String get noKeyframes => '还没有关键 H 帧';

  @override
  String get editVideoTitle => '修改影片标题';

  @override
  String get deleteVideoKeyframes => '删除该影片的关键 H 帧';

  @override
  String deleteVideoKeyframesConfirmation(Object title) {
    return '删除“$title”的全部关键 H 帧？';
  }

  @override
  String get editPosition => '修改时间点';

  @override
  String get deleteKeyframe => '删除关键 H 帧';

  @override
  String get deleteKeyframeTitle => '删除关键 H 帧';

  @override
  String get videoTitle => '影片标题';

  @override
  String get positionMilliseconds => '时间点（毫秒）';

  @override
  String get invalidKeyframe => '时间点无效或与其他关键帧间隔不足 10 秒';

  @override
  String get content => '内容';

  @override
  String get languageSettings => '语言';

  @override
  String get appearance => '外观';

  @override
  String get themeAndColor => '主题与色彩';

  @override
  String get interfaceLayout => '界面布局';

  @override
  String get wallpaperColors => '壁纸颜色';

  @override
  String get basicColors => '基本颜色';

  @override
  String get customAccentColor => '自定义强调色';

  @override
  String get invalidColor => '请输入六位十六进制颜色';

  @override
  String get playback => '播放';

  @override
  String get playerEngine => '播放器内核';

  @override
  String get preferredQuality => '优先清晰度';

  @override
  String get resumePlayback => '自动续播';

  @override
  String get resumePlaybackDescription => '再次播放时从上次退出的位置继续';

  @override
  String get site => '站点';

  @override
  String get network => '网络';

  @override
  String get networkSettings => '网络设置';

  @override
  String get useBuiltInHosts => '使用内置 Hosts';

  @override
  String get useBuiltInHostsDescription => '为 Hanime1 域名使用内置的 Cloudflare IP 地址';

  @override
  String get doh => 'DNS over HTTPS';

  @override
  String get useDoh => '使用 DNS over HTTPS';

  @override
  String get dohSettings => 'DNS over HTTPS 设置';

  @override
  String get dohDisabled => '已关闭';

  @override
  String get dohPreset => '服务商';

  @override
  String get dohCustomUrl => '自定义 DoH 地址';

  @override
  String get dohBootstrapIps => 'Bootstrap IP 地址';

  @override
  String get dohBootstrapIpsDescription => '可使用逗号、空格或换行分隔';

  @override
  String get dohTimeoutSeconds => '超时秒数';

  @override
  String get dohTimeoutSecondsDescription => '范围为 1 至 60 秒';

  @override
  String get useEch => '启用 ECH';

  @override
  String get useEchDescription => '为 Hanime 站点加密 TLS ClientHello 中的域名信息';

  @override
  String get echLogs => 'ECH 日志';

  @override
  String get echLogsDescription => '查看 ECH 配置与连接状态';

  @override
  String get clearEchLogs => '清空日志';

  @override
  String get noEchLogs => '暂无 ECH 日志';

  @override
  String get custom => '自定义';

  @override
  String get cloudflareVerification => 'Cloudflare 验证';

  @override
  String get cloudflareVerificationDescription => '访问受保护页面时完成验证';

  @override
  String get autoCheckUpdates => '自动检查更新';

  @override
  String get checkUpdates => '检查更新';

  @override
  String get application => '应用';

  @override
  String get applicationSettings => '应用程序';

  @override
  String get applicationSettingsDescription => '修改应用程序相关设置';

  @override
  String get other => '其他';

  @override
  String get keyframeManagement => '关键 H 帧管理';

  @override
  String get about => '关于 Han1me+';

  @override
  String get aboutDescription => '版本与开源信息';

  @override
  String get explore => '探索';

  @override
  String get library => '收藏';

  @override
  String get cache => '缓存';

  @override
  String get more => '查看更多';

  @override
  String get featured => '首页推荐';

  @override
  String get retry => '重试';

  @override
  String get completeCloudflareVerification => '完成 Cloudflare 验证';

  @override
  String get searchHint => '搜索视频、作者、标签…';

  @override
  String get noSearchResults => '没有找到匹配的视频';

  @override
  String category(Object value) {
    return '分类：$value';
  }

  @override
  String sort(Object value) {
    return '排序：$value';
  }

  @override
  String releaseDate(Object value) {
    return '发布日期：$value';
  }

  @override
  String get releaseDateTitle => '发布日期';

  @override
  String duration(Object value) {
    return '时长：$value';
  }

  @override
  String get searchAuthors => '搜索作者';

  @override
  String tagsSelected(int count) {
    return '标签：已选 $count';
  }

  @override
  String get broadMatch => '广泛配对';

  @override
  String get broadMatchDescription => '匹配任一所选标签，结果更多但精度较低。';

  @override
  String get tagVideoAttributes => '影片属性';

  @override
  String get tagRelationships => '人物关系';

  @override
  String get tagCharacterSettings => '角色设定';

  @override
  String get tagAppearance => '外貌身材';

  @override
  String get tagSettings => '情境场所';

  @override
  String get tagStory => '故事剧情';

  @override
  String get tagPositions => '性交体位';

  @override
  String get dateRange => '大致范围';

  @override
  String get specificYearMonth => '具体年月';

  @override
  String get year => '年份';

  @override
  String get month => '月份';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get apply => '应用';

  @override
  String get clear => '清除';

  @override
  String get all => '全部';

  @override
  String get defaultValue => '默认';

  @override
  String get comments => '评论';

  @override
  String get reload => '重新加载';

  @override
  String get noComments => '还没有人评论';

  @override
  String get previews => '新番预告';

  @override
  String previewMonth(Object month) {
    return '$month 新番表';
  }

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previewUnavailable => '本月新番预告暂不可用';

  @override
  String get previewUnavailableDescription => '可以重新加载，或查看此前月份的新番预告。';

  @override
  String get noPreviews => '这个月还没有新番预告';

  @override
  String get noPreviewsDescription => '新番资料发布后会在这里显示，也可以先浏览此前月份。';

  @override
  String get watchVideo => '观看影片';

  @override
  String previewImages(int count) {
    return '预告图片（$count）';
  }

  @override
  String get statistics => '统计';

  @override
  String watchDuration(Object duration) {
    return '观看时长  $duration';
  }

  @override
  String get noWatchHistory => '暂无观看记录';

  @override
  String hoursMinutes(Object hours, Object minutes) {
    return '$hours时$minutes分';
  }

  @override
  String minutes(Object value) {
    return '$value分钟';
  }

  @override
  String seconds(Object value) {
    return '$value秒';
  }

  @override
  String get myLibrary => '我的收藏';

  @override
  String get watchLater => '稍后观看';

  @override
  String get favoriteVideos => '喜欢的影片';

  @override
  String get subscriptions => '我的订阅';

  @override
  String get noWatchLater => '暂无稍后观看影片';

  @override
  String get noFavoriteVideos => '暂无喜欢的影片';

  @override
  String get noSubscriptionVideos => '暂无订阅影片';

  @override
  String selectedItems(int count) {
    return '已选 $count 项';
  }

  @override
  String get select => '选择';

  @override
  String get deleteSelectedCache => '删除所选缓存';

  @override
  String get createGroup => '新建分组';

  @override
  String get noCache => '暂无缓存';

  @override
  String get localVideoMissing => '本地视频文件不存在，请删除该缓存后重新下载';

  @override
  String get deleteCache => '删除缓存';

  @override
  String deleteCacheConfirmation(Object title) {
    return '删除“$title”的本地缓存？';
  }

  @override
  String deleteGroupTitle(Object name) {
    return '删除“$name”';
  }

  @override
  String get moveGroupCacheToDefault => '该分组中的缓存将移至默认分组。';

  @override
  String get groupName => '分组名称';

  @override
  String get confirm => '确定';

  @override
  String get queued => '等待中';

  @override
  String get downloading => '下载中';

  @override
  String get completed => '已完成';

  @override
  String get failed => '失败';

  @override
  String commentsTitle(Object title) {
    return '$title 评论';
  }

  @override
  String date(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get thirdPartyClient => '第三方 Hanime1 客户端';

  @override
  String get version => '版本';

  @override
  String get dataSource => '数据来源';

  @override
  String get dataSourceDescription => 'Hanime1 网站公开页面内容';

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get reportIssue => '反馈问题';

  @override
  String get submitGitHubIssue => '提交 GitHub Issue';

  @override
  String get openSourceLicense => '开源许可';

  @override
  String get verificationComplete => '验证完成';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get fullscreenPlayback => '全屏播放';

  @override
  String get pauseBeforeAddingKeyframe => '请先暂停视频，再添加关键 H 帧';

  @override
  String get addKeyframe => '添加关键 H 帧';

  @override
  String addKeyframeConfirmation(int position) {
    return '将当前暂停位置加入关键 H 帧？\n\n当前时间：$position ms\n相邻关键帧至少间隔 10 秒。';
  }

  @override
  String get add => '添加';

  @override
  String get keyframeAdded => '已添加关键 H 帧';

  @override
  String get keyframeTooClose => '与已有关键帧间隔不足 10 秒';

  @override
  String get longPressAddKeyframe => '长按添加关键 H 帧';

  @override
  String get keyframes => '关键 H 帧';

  @override
  String get deleteCurrentVideoKeyframes => '删除当前影片的全部关键 H 帧';

  @override
  String get deleteCurrentVideoKeyframesConfirmation => '删除当前影片的全部关键 H 帧？';

  @override
  String get editKeyframe => '修改关键 H 帧';

  @override
  String keyframeCountdown(Object seconds) {
    return '关键 H 帧还有 $seconds 秒';
  }

  @override
  String get episodeList => '剧集列表';

  @override
  String get seriesVideos => '系列影片';

  @override
  String get relatedVideos => '相关推荐';

  @override
  String get studio => '厂商';

  @override
  String get subscribed => '已订阅';

  @override
  String get subscribe => '订阅';

  @override
  String get favorite => '收藏';

  @override
  String get download => '下载';

  @override
  String get share => '分享';

  @override
  String get selectDownloadQuality => '选择下载清晰度';

  @override
  String get startDownload => '开始下载';

  @override
  String get addedToDownloadQueue => '已加入下载队列';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get description => '简介';

  @override
  String get commentsLoadFailed => '评论加载失败';

  @override
  String keyframeCount(int count) {
    return '$count 个关键帧';
  }

  @override
  String get themeMode => '主题模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get themeColor => '主题色';

  @override
  String get rose => '玫红';

  @override
  String get blue => '蓝色';

  @override
  String get teal => '青绿';

  @override
  String get amber => '琥珀';

  @override
  String get forestGreen => '森林绿';

  @override
  String get orange => '橙色';

  @override
  String get indigo => '靛蓝';

  @override
  String get pink => '粉色';

  @override
  String get purple => '紫色';

  @override
  String get keyframeSettingsDescription => '管理开关及各影片的关键 H 帧';

  @override
  String get latestVersion => '当前已是最新版本';

  @override
  String newVersionAvailable(Object version) {
    return '发现新版本 $version';
  }

  @override
  String get newVersionReleased => '已发布新版本。';

  @override
  String get later => '稍后';

  @override
  String get updateNow => '现在更新';

  @override
  String get noInstallableApk => '当前版本没有可安装的 APK 文件';

  @override
  String get updateIncomplete => '更新未完成';

  @override
  String get downloadingUpdate => '正在下载更新';

  @override
  String get connecting => '正在连接...';

  @override
  String updateFailed(Object error) {
    return '更新失败：$error';
  }

  @override
  String get close => '关闭';

  @override
  String get monetColors => '莫奈取色';

  @override
  String get monetColorsDescription => '使用系统壁纸动态配色';

  @override
  String get downloadSettings => '下载设置';

  @override
  String get downloadSettingsDescription => '速度与并发下载限制';

  @override
  String get downloadSpeedLimit => '下载速度限制';

  @override
  String get unlimited => '不限速';

  @override
  String get concurrentDownloads => '同时下载数量限制';

  @override
  String concurrentDownloadsDescription(int count) {
    return '同时下载 $count 个影片';
  }

  @override
  String get downloadPath => '下载路径';

  @override
  String get defaultDownloadPath =>
      '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

  @override
  String get exportDownloads => '导出下载项';

  @override
  String get exportDownloadsDescription => '将私有下载目录中的所有已下载项目导出到自定义目录';

  @override
  String get exportCompleted => '下载项已导出';

  @override
  String get amoledMode => 'AMOLED 模式';

  @override
  String get amoledModeDescription => '深色主题使用纯黑背景';

  @override
  String get watchHistory => '观看历史';

  @override
  String get playlists => '播放清单';

  @override
  String get noPlaylists => '暂无播放清单';

  @override
  String get deletePlaylist => '删除播放清单';

  @override
  String deletePlaylistConfirmation(Object title) {
    return '确定删除“$title”吗？';
  }

  @override
  String videoCount(int count) {
    return '$count 部影片';
  }

  @override
  String loadFailed(Object error) {
    return '加载失败：$error';
  }

  @override
  String get playlistEmpty => '播放清单为空';

  @override
  String get writeComment => '发表评论';

  @override
  String get commentHint => '输入评论内容';

  @override
  String get latest => '最新';

  @override
  String get popular => '热门';

  @override
  String get oldest => '最早';

  @override
  String playlistCreatedBy(Object name) {
    return '由 $name 建立';
  }

  @override
  String playlistStats(int count, int views) {
    return '播放清单 • $count 部影片 • 观看次数：$views 次';
  }

  @override
  String get playAll => '全部播放';

  @override
  String get earliest => '最早';

  @override
  String get mostReplies => '回复最多';

  @override
  String get mostLikes => '最多点赞';

  @override
  String get mostDislikes => '最多点踩';

  @override
  String get viewReplies => '查看回复';

  @override
  String viewRepliesCount(int count) {
    return '查看回复 ($count)';
  }

  @override
  String get reply => '回复';

  @override
  String get replyComment => '回复评论';

  @override
  String get send => '发送';

  @override
  String get addToPlaylist => '加入清单';

  @override
  String get newPlaylist => '新建播放清单';

  @override
  String get name => '名称';

  @override
  String get create => '创建';

  @override
  String get account => '账户';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirmation => '确定要退出当前账号吗？';

  @override
  String get accountProfile => '账户资料';

  @override
  String get signedIn => '已登录';

  @override
  String get signedOut => '未登录';

  @override
  String accountSummary(
      Object id, int subscriberCount, int videoCount, Object joined) {
    return '@$id\n$subscriberCount 位订阅者 · $videoCount 部影片\n$joined';
  }

  @override
  String get tapToLogin => '点击前往登录';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get changePassword => '更改密码';

  @override
  String get username => '用户名';

  @override
  String get email => '邮箱';

  @override
  String get saveProfile => '保存资料';

  @override
  String get oldPassword => '旧密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get login => '登录';

  @override
  String get finishLogin => '完成登录';

  @override
  String get genreAdultAnimation => '裏番';

  @override
  String get genreShortAnimation => '泡麵番';

  @override
  String get genre2dAnimation => '2D動畫';

  @override
  String get genreAiGenerated => 'AI生成';

  @override
  String get sortLatestRelease => '最新上市';

  @override
  String get sortLatestUpload => '最新上傳';

  @override
  String get sortTrending => '他們在看';

  @override
  String get playbackSettings => '播放设置';

  @override
  String get playbackSettingsDescription => '倍数、长按倍数与控制器显示时间';

  @override
  String get defaultPlaybackSpeed => '默认播放倍数';

  @override
  String get longPressPlaybackSpeed => '默认长按倍数';

  @override
  String get playerControlsTimeout => '播放控制器消失时间';

  @override
  String get playerControlsTimeoutDescription => '不操作时自动隐藏播放控制器';

  @override
  String get privacySettings => '隐私设置';

  @override
  String get appLock => '使用应用锁定屏幕';

  @override
  String get appLockDescription => '开启后，进入应用时需验证屏幕锁，防止别人打开';

  @override
  String get emergencyExit => '紧急状况';

  @override
  String get emergencyExitDescription => '开启后，应用内连续按三次音量上键会停止播放并返回桌面';

  @override
  String get hideFromRecents => '从最近任务中隐藏';

  @override
  String get hideFromRecentsDescription => '应用在后台时，从最近任务中隐藏应用';

  @override
  String get commentSettings => '评论设置';

  @override
  String get enableComments => '启用评论区';

  @override
  String get commentsDisabled => '评论区已关闭';

  @override
  String get commentKeywordFilter => '关键词屏蔽';

  @override
  String get commentKeywordFilterDescription => '包含关键词的评论不会显示';

  @override
  String get keyword => '关键词';

  @override
  String get deepLinkSettings => '应用深层链接设置';

  @override
  String get deepLinkSettingsDescription => '打开相关网页后能快速跳转至本 App';

  @override
  String get openAppLinkSettings => '管理网页链接';

  @override
  String get openAppLinkSettingsDescription => '在系统设置中允许 Han1me+ 打开支持的链接';

  @override
  String get playbackSpeed => '播放倍数';

  @override
  String get lockControls => '锁定播放面板';

  @override
  String get unlockControls => '解除播放面板锁定';

  @override
  String get brightness => '亮度';

  @override
  String get volume => '音量';

  @override
  String get comicMode => '观看漫画';

  @override
  String get horizontalSearchCards => '横向影片卡片';

  @override
  String get horizontalSearchCardsDescription => '影片使用横向卡片显示';

  @override
  String get expandHomeVideoCards => '展开首页影片卡片';

  @override
  String get expandHomeVideoCardsDescription =>
      '关闭时首页每个分类横向显示一行影片；开启后使用影片卡片每行数量设置';

  @override
  String get searchCardsPerRow => '影片卡片每行数量';

  @override
  String searchCardsPerRowValue(int count) {
    return '每行 $count 个';
  }

  @override
  String get comicModeDescription => '开启后首页、收藏和缓存仅显示漫画内容';

  @override
  String get comicBrowse => '漫画筛选';

  @override
  String get trendingComics => '发烧漫画';

  @override
  String get latestComics => '最新上传';

  @override
  String get comicSearchUnavailable => '漫画不支持关键词搜索';

  @override
  String get comicDetails => '漫画详情';

  @override
  String get read => '阅读';

  @override
  String pageCount(int count) {
    return '$count 页';
  }

  @override
  String get tags => '标签';

  @override
  String get chapter => '目录';

  @override
  String get chapterOne => '第 1 章';

  @override
  String get addToLibrary => '添加到收藏';

  @override
  String get cacheComicConfirmation => '确定缓存整本漫画吗？';

  @override
  String get info => '信息';

  @override
  String get noComics => '暂无漫画';

  @override
  String get pageNumber => '页码';

  @override
  String get readingMode => '阅读模式';

  @override
  String get general => '常规';

  @override
  String get leftToRight => '单页式（从左到右）';

  @override
  String get rightToLeft => '单页式（从右到左）';

  @override
  String get topToBottom => '单页式（从上到下）';

  @override
  String get scroll => '条漫';

  @override
  String get scrollGap => '条漫（页间有空隙）';

  @override
  String get black => '黑色';

  @override
  String get gray => '灰色';

  @override
  String get white => '白色';

  @override
  String get cacheCategory => '缓存分类';

  @override
  String get newCategory => '新分类';

  @override
  String get danmakuHint => '发弹幕';

  @override
  String get sendDanmaku => '发送弹幕';

  @override
  String get danmakuContentHint => '输入发送的弹幕内容';

  @override
  String get danmakuSubmitted => '弹幕已发送';

  @override
  String get danmakuSubmitFailed => '弹幕发送失败，请稍后重试';

  @override
  String get danmakuSettings => '弹幕设置';

  @override
  String get danmakuSettingsDescription => '显示、屏蔽与播放同步';

  @override
  String get enableDanmaku => '启用弹幕';

  @override
  String get enableDanmakuDescription => '在播放器中显示已弹幕';

  @override
  String get danmakuKeywordFilter => '弹幕关键词屏蔽';

  @override
  String get danmakuKeywordFilterDescription => '包含关键词的弹幕不会显示';

  @override
  String get danmakuFollowsPlaybackSpeed => '弹幕跟随视频倍速';

  @override
  String get danmakuFollowsPlaybackSpeedDescription => '视频倍速改变时同步调整弹幕速度';

  @override
  String get showDanmaku => '显示弹幕';

  @override
  String get hideDanmaku => '隐藏弹幕';

  @override
  String get navigationDrawer => '使用导航抽屉';

  @override
  String get navigationDrawerDescription => '使用抽屉替代底部导航栏';

  @override
  String get home => '主页';

  @override
  String get seekSensitivity => '进度滑动灵敏度';

  @override
  String get seekSensitivityDescription => '调低可减少左右滑动时的跳转幅度';

  @override
  String seekSensitivityValue(int value) {
    return '$value%';
  }
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'Han1me+';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '系统默认';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get keyframeSettings => '关键 H 帧设置';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get keyframesEnabled => '启用关键 H 帧';

  @override
  String get keyframesEnabledDescription => '播放器中显示关键 H 帧入口与倒计时';

  @override
  String get keyframesDisabledDescription => '关键 H 帧功能已关闭';

  @override
  String get shareKeyframes => '共享您的关键 H 帧集';

  @override
  String get shareKeyframesDescription => '新增或修改后自动上传到共享数据源';

  @override
  String get shareKeyframesConfirmation => '将上传现有关键 H 帧并持续同步之后的更改。';

  @override
  String get useSharedKeyframes => '采用好心人的关键 H 帧集';

  @override
  String get useSharedKeyframesDescription => '自动使用共享数据源中的关键 H 帧';

  @override
  String get preferSharedKeyframes => '优先采用共享关键 H 帧集';

  @override
  String get preferSharedKeyframesDescription => '当本地集和共享集都有该影片的关键 H 帧时，采用共享集';

  @override
  String get upload => '上传';

  @override
  String get uploadingKeyframes => '正在上传关键 H 帧';

  @override
  String get uploadComplete => '上传完成';

  @override
  String get keyframesUploadDescription => '共享功能已开启，之后的更改将自动上传。';

  @override
  String keyframesUploadFailed(Object error) {
    return '上传失败（$error），请稍后重试。';
  }

  @override
  String get manage => '管理';

  @override
  String get noKeyframes => '还没有关键 H 帧';

  @override
  String get editVideoTitle => '修改影片标题';

  @override
  String get deleteVideoKeyframes => '删除该影片的关键 H 帧';

  @override
  String deleteVideoKeyframesConfirmation(Object title) {
    return '删除“$title”的全部关键 H 帧？';
  }

  @override
  String get editPosition => '修改时间点';

  @override
  String get deleteKeyframe => '删除关键 H 帧';

  @override
  String get deleteKeyframeTitle => '删除关键 H 帧';

  @override
  String get videoTitle => '影片标题';

  @override
  String get positionMilliseconds => '时间点（毫秒）';

  @override
  String get invalidKeyframe => '时间点无效或与其他关键帧间隔不足 10 秒';

  @override
  String get content => '内容';

  @override
  String get languageSettings => '语言';

  @override
  String get appearance => '外观';

  @override
  String get themeAndColor => '主题与色彩';

  @override
  String get interfaceLayout => '界面布局';

  @override
  String get wallpaperColors => '壁纸颜色';

  @override
  String get basicColors => '基本颜色';

  @override
  String get customAccentColor => '自定义强调色';

  @override
  String get invalidColor => '请输入六位十六进制颜色';

  @override
  String get playback => '播放';

  @override
  String get playerEngine => '播放器内核';

  @override
  String get preferredQuality => '优先清晰度';

  @override
  String get resumePlayback => '自动续播';

  @override
  String get resumePlaybackDescription => '再次播放时从上次退出的位置继续';

  @override
  String get site => '站点';

  @override
  String get network => '网络';

  @override
  String get networkSettings => '网络设置';

  @override
  String get useBuiltInHosts => '使用内置 Hosts';

  @override
  String get useBuiltInHostsDescription => '为 Hanime1 域名使用内置的 Cloudflare IP 地址';

  @override
  String get doh => 'DNS over HTTPS';

  @override
  String get useDoh => '使用 DNS over HTTPS';

  @override
  String get dohSettings => 'DNS over HTTPS 设置';

  @override
  String get dohDisabled => '已关闭';

  @override
  String get dohPreset => '服务商';

  @override
  String get dohCustomUrl => '自定义 DoH 地址';

  @override
  String get dohBootstrapIps => 'Bootstrap IP 地址';

  @override
  String get dohBootstrapIpsDescription => '可使用逗号、空格或换行分隔';

  @override
  String get dohTimeoutSeconds => '超时秒数';

  @override
  String get dohTimeoutSecondsDescription => '范围为 1 至 60 秒';

  @override
  String get useEch => '启用 ECH';

  @override
  String get useEchDescription => '为 Hanime 站点加密 TLS ClientHello 中的域名信息';

  @override
  String get echLogs => 'ECH 日志';

  @override
  String get echLogsDescription => '查看 ECH 配置与连接状态';

  @override
  String get clearEchLogs => '清空日志';

  @override
  String get noEchLogs => '暂无 ECH 日志';

  @override
  String get custom => '自定义';

  @override
  String get cloudflareVerification => 'Cloudflare 验证';

  @override
  String get cloudflareVerificationDescription => '访问受保护页面时完成验证';

  @override
  String get autoCheckUpdates => '自动检查更新';

  @override
  String get checkUpdates => '检查更新';

  @override
  String get application => '应用';

  @override
  String get applicationSettings => '应用程序';

  @override
  String get applicationSettingsDescription => '修改应用程序相关设置';

  @override
  String get other => '其他';

  @override
  String get keyframeManagement => '关键 H 帧管理';

  @override
  String get about => '关于 Han1me+';

  @override
  String get aboutDescription => '版本与开源信息';

  @override
  String get explore => '探索';

  @override
  String get library => '收藏';

  @override
  String get cache => '缓存';

  @override
  String get more => '查看更多';

  @override
  String get featured => '首页推荐';

  @override
  String get retry => '重试';

  @override
  String get completeCloudflareVerification => '完成 Cloudflare 验证';

  @override
  String get searchHint => '搜索视频、作者、标签…';

  @override
  String get noSearchResults => '没有找到匹配的视频';

  @override
  String category(Object value) {
    return '分类：$value';
  }

  @override
  String sort(Object value) {
    return '排序：$value';
  }

  @override
  String releaseDate(Object value) {
    return '发布日期：$value';
  }

  @override
  String get releaseDateTitle => '发布日期';

  @override
  String duration(Object value) {
    return '时长：$value';
  }

  @override
  String get searchAuthors => '搜索作者';

  @override
  String tagsSelected(int count) {
    return '标签：已选 $count';
  }

  @override
  String get broadMatch => '广泛配对';

  @override
  String get broadMatchDescription => '匹配任一所选标签，结果更多但精度较低。';

  @override
  String get tagVideoAttributes => '影片属性';

  @override
  String get tagRelationships => '人物关系';

  @override
  String get tagCharacterSettings => '角色设定';

  @override
  String get tagAppearance => '外貌身材';

  @override
  String get tagSettings => '情境场所';

  @override
  String get tagStory => '故事剧情';

  @override
  String get tagPositions => '性交体位';

  @override
  String get dateRange => '大致范围';

  @override
  String get specificYearMonth => '具体年月';

  @override
  String get year => '年份';

  @override
  String get month => '月份';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get apply => '应用';

  @override
  String get clear => '清除';

  @override
  String get all => '全部';

  @override
  String get defaultValue => '默认';

  @override
  String get comments => '评论';

  @override
  String get reload => '重新加载';

  @override
  String get noComments => '还没有人评论';

  @override
  String get previews => '新番预告';

  @override
  String previewMonth(Object month) {
    return '$month 新番表';
  }

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get previewUnavailable => '本月新番预告暂不可用';

  @override
  String get previewUnavailableDescription => '可以重新加载，或查看此前月份的新番预告。';

  @override
  String get noPreviews => '这个月还没有新番预告';

  @override
  String get noPreviewsDescription => '新番资料发布后会在这里显示，也可以先浏览此前月份。';

  @override
  String get watchVideo => '观看影片';

  @override
  String previewImages(int count) {
    return '预告图片（$count）';
  }

  @override
  String get statistics => '统计';

  @override
  String watchDuration(Object duration) {
    return '观看时长  $duration';
  }

  @override
  String get noWatchHistory => '暂无观看记录';

  @override
  String hoursMinutes(Object hours, Object minutes) {
    return '$hours时$minutes分';
  }

  @override
  String minutes(Object value) {
    return '$value分钟';
  }

  @override
  String seconds(Object value) {
    return '$value秒';
  }

  @override
  String get myLibrary => '我的收藏';

  @override
  String get watchLater => '稍后观看';

  @override
  String get favoriteVideos => '喜欢的影片';

  @override
  String get subscriptions => '我的订阅';

  @override
  String get noWatchLater => '暂无稍后观看影片';

  @override
  String get noFavoriteVideos => '暂无喜欢的影片';

  @override
  String get noSubscriptionVideos => '暂无订阅影片';

  @override
  String selectedItems(int count) {
    return '已选 $count 项';
  }

  @override
  String get select => '选择';

  @override
  String get deleteSelectedCache => '删除所选缓存';

  @override
  String get createGroup => '新建分组';

  @override
  String get noCache => '暂无缓存';

  @override
  String get localVideoMissing => '本地视频文件不存在，请删除该缓存后重新下载';

  @override
  String get deleteCache => '删除缓存';

  @override
  String deleteCacheConfirmation(Object title) {
    return '删除“$title”的本地缓存？';
  }

  @override
  String deleteGroupTitle(Object name) {
    return '删除“$name”';
  }

  @override
  String get moveGroupCacheToDefault => '该分组中的缓存将移至默认分组。';

  @override
  String get groupName => '分组名称';

  @override
  String get confirm => '确定';

  @override
  String get queued => '等待中';

  @override
  String get downloading => '下载中';

  @override
  String get completed => '已完成';

  @override
  String get failed => '失败';

  @override
  String commentsTitle(Object title) {
    return '$title 评论';
  }

  @override
  String date(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get thirdPartyClient => '第三方 Hanime1 客户端';

  @override
  String get version => '版本';

  @override
  String get dataSource => '数据来源';

  @override
  String get dataSourceDescription => 'Hanime1 网站公开页面内容';

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get reportIssue => '反馈问题';

  @override
  String get submitGitHubIssue => '提交 GitHub Issue';

  @override
  String get openSourceLicense => '开源许可';

  @override
  String get verificationComplete => '验证完成';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get fullscreenPlayback => '全屏播放';

  @override
  String get pauseBeforeAddingKeyframe => '请先暂停视频，再添加关键 H 帧';

  @override
  String get addKeyframe => '添加关键 H 帧';

  @override
  String addKeyframeConfirmation(int position) {
    return '将当前暂停位置加入关键 H 帧？\n\n当前时间：$position ms\n相邻关键帧至少间隔 10 秒。';
  }

  @override
  String get add => '添加';

  @override
  String get keyframeAdded => '已添加关键 H 帧';

  @override
  String get keyframeTooClose => '与已有关键帧间隔不足 10 秒';

  @override
  String get longPressAddKeyframe => '长按添加关键 H 帧';

  @override
  String get keyframes => '关键 H 帧';

  @override
  String get deleteCurrentVideoKeyframes => '删除当前影片的全部关键 H 帧';

  @override
  String get deleteCurrentVideoKeyframesConfirmation => '删除当前影片的全部关键 H 帧？';

  @override
  String get editKeyframe => '修改关键 H 帧';

  @override
  String keyframeCountdown(Object seconds) {
    return '关键 H 帧还有 $seconds 秒';
  }

  @override
  String get episodeList => '剧集列表';

  @override
  String get seriesVideos => '系列影片';

  @override
  String get relatedVideos => '相关推荐';

  @override
  String get studio => '厂商';

  @override
  String get subscribed => '已订阅';

  @override
  String get subscribe => '订阅';

  @override
  String get favorite => '收藏';

  @override
  String get download => '下载';

  @override
  String get share => '分享';

  @override
  String get selectDownloadQuality => '选择下载清晰度';

  @override
  String get startDownload => '开始下载';

  @override
  String get addedToDownloadQueue => '已加入下载队列';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get description => '简介';

  @override
  String get commentsLoadFailed => '评论加载失败';

  @override
  String keyframeCount(int count) {
    return '$count 个关键帧';
  }

  @override
  String get themeMode => '主题模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get themeColor => '主题色';

  @override
  String get rose => '玫红';

  @override
  String get blue => '蓝色';

  @override
  String get teal => '青绿';

  @override
  String get amber => '琥珀';

  @override
  String get forestGreen => '森林绿';

  @override
  String get orange => '橙色';

  @override
  String get indigo => '靛蓝';

  @override
  String get pink => '粉色';

  @override
  String get purple => '紫色';

  @override
  String get keyframeSettingsDescription => '管理开关及各影片的关键 H 帧';

  @override
  String get latestVersion => '当前已是最新版本';

  @override
  String newVersionAvailable(Object version) {
    return '发现新版本 $version';
  }

  @override
  String get newVersionReleased => '已发布新版本。';

  @override
  String get later => '稍后';

  @override
  String get updateNow => '现在更新';

  @override
  String get noInstallableApk => '当前版本没有可安装的 APK 文件';

  @override
  String get updateIncomplete => '更新未完成';

  @override
  String get downloadingUpdate => '正在下载更新';

  @override
  String get connecting => '正在连接...';

  @override
  String updateFailed(Object error) {
    return '更新失败：$error';
  }

  @override
  String get close => '关闭';

  @override
  String get monetColors => '莫奈取色';

  @override
  String get monetColorsDescription => '使用系统壁纸动态配色';

  @override
  String get downloadSettings => '下载设置';

  @override
  String get downloadSettingsDescription => '速度与并发下载限制';

  @override
  String get downloadSpeedLimit => '下载速度限制';

  @override
  String get unlimited => '不限速';

  @override
  String get concurrentDownloads => '同时下载数量限制';

  @override
  String concurrentDownloadsDescription(int count) {
    return '同时下载 $count 个影片';
  }

  @override
  String get downloadPath => '下载路径';

  @override
  String get defaultDownloadPath =>
      '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

  @override
  String get exportDownloads => '导出下载项';

  @override
  String get exportDownloadsDescription => '将私有下载目录中的所有已下载项目导出到自定义目录';

  @override
  String get exportCompleted => '下载项已导出';

  @override
  String get amoledMode => 'AMOLED 模式';

  @override
  String get amoledModeDescription => '深色主题使用纯黑背景';

  @override
  String get watchHistory => '观看历史';

  @override
  String get playlists => '播放清单';

  @override
  String get noPlaylists => '暂无播放清单';

  @override
  String get deletePlaylist => '删除播放清单';

  @override
  String deletePlaylistConfirmation(Object title) {
    return '确定删除“$title”吗？';
  }

  @override
  String videoCount(int count) {
    return '$count 部影片';
  }

  @override
  String loadFailed(Object error) {
    return '加载失败：$error';
  }

  @override
  String get playlistEmpty => '播放清单为空';

  @override
  String get writeComment => '发表评论';

  @override
  String get commentHint => '输入评论内容';

  @override
  String get latest => '最新';

  @override
  String get popular => '热门';

  @override
  String get oldest => '最早';

  @override
  String playlistCreatedBy(Object name) {
    return '由 $name 建立';
  }

  @override
  String playlistStats(int count, int views) {
    return '播放清单 • $count 部影片 • 观看次数：$views 次';
  }

  @override
  String get playAll => '全部播放';

  @override
  String get earliest => '最早';

  @override
  String get mostReplies => '回复最多';

  @override
  String get mostLikes => '最多点赞';

  @override
  String get mostDislikes => '最多点踩';

  @override
  String get viewReplies => '查看回复';

  @override
  String viewRepliesCount(int count) {
    return '查看回复 ($count)';
  }

  @override
  String get reply => '回复';

  @override
  String get replyComment => '回复评论';

  @override
  String get send => '发送';

  @override
  String get addToPlaylist => '加入清单';

  @override
  String get newPlaylist => '新建播放清单';

  @override
  String get name => '名称';

  @override
  String get create => '创建';

  @override
  String get account => '账户';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirmation => '确定要退出当前账号吗？';

  @override
  String get accountProfile => '账户资料';

  @override
  String get signedIn => '已登录';

  @override
  String get signedOut => '未登录';

  @override
  String accountSummary(
      Object id, int subscriberCount, int videoCount, Object joined) {
    return '@$id\n$subscriberCount 位订阅者 · $videoCount 部影片\n$joined';
  }

  @override
  String get tapToLogin => '点击前往登录';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get changePassword => '更改密码';

  @override
  String get username => '用户名';

  @override
  String get email => '邮箱';

  @override
  String get saveProfile => '保存资料';

  @override
  String get oldPassword => '旧密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get login => '登录';

  @override
  String get finishLogin => '完成登录';

  @override
  String get genreAdultAnimation => '裏番';

  @override
  String get genreShortAnimation => '泡麵番';

  @override
  String get genre2dAnimation => '2D動畫';

  @override
  String get genreAiGenerated => 'AI生成';

  @override
  String get sortLatestRelease => '最新上市';

  @override
  String get sortLatestUpload => '最新上傳';

  @override
  String get sortTrending => '他們在看';

  @override
  String get playbackSettings => '播放设置';

  @override
  String get playbackSettingsDescription => '倍数、长按倍数与控制器显示时间';

  @override
  String get defaultPlaybackSpeed => '默认播放倍数';

  @override
  String get longPressPlaybackSpeed => '默认长按倍数';

  @override
  String get playerControlsTimeout => '播放控制器消失时间';

  @override
  String get playerControlsTimeoutDescription => '不操作时自动隐藏播放控制器';

  @override
  String get privacySettings => '隐私设置';

  @override
  String get appLock => '使用应用锁定屏幕';

  @override
  String get appLockDescription => '开启后，进入应用时需验证屏幕锁，防止别人打开';

  @override
  String get emergencyExit => '紧急状况';

  @override
  String get emergencyExitDescription => '开启后，应用内连续按三次音量上键会停止播放并返回桌面';

  @override
  String get hideFromRecents => '从最近任务中隐藏';

  @override
  String get hideFromRecentsDescription => '应用在后台时，从最近任务中隐藏应用';

  @override
  String get commentSettings => '评论设置';

  @override
  String get enableComments => '启用评论区';

  @override
  String get commentsDisabled => '评论区已关闭';

  @override
  String get commentKeywordFilter => '关键词屏蔽';

  @override
  String get commentKeywordFilterDescription => '包含关键词的评论不会显示';

  @override
  String get keyword => '关键词';

  @override
  String get deepLinkSettings => '应用深层链接设置';

  @override
  String get deepLinkSettingsDescription => '打开相关网页后能快速跳转至本 App';

  @override
  String get openAppLinkSettings => '管理网页链接';

  @override
  String get openAppLinkSettingsDescription => '在系统设置中允许 Han1me+ 打开支持的链接';

  @override
  String get playbackSpeed => '播放倍数';

  @override
  String get lockControls => '锁定播放面板';

  @override
  String get unlockControls => '解除播放面板锁定';

  @override
  String get brightness => '亮度';

  @override
  String get volume => '音量';

  @override
  String get comicMode => '观看漫画';

  @override
  String get horizontalSearchCards => '横向影片卡片';

  @override
  String get horizontalSearchCardsDescription => '影片使用横向卡片显示';

  @override
  String get expandHomeVideoCards => '展开首页影片卡片';

  @override
  String get expandHomeVideoCardsDescription =>
      '关闭时首页每个分类横向显示一行影片；开启后使用影片卡片每行数量设置';

  @override
  String get searchCardsPerRow => '影片卡片每行数量';

  @override
  String searchCardsPerRowValue(int count) {
    return '每行 $count 个';
  }

  @override
  String get comicModeDescription => '开启后首页、收藏和缓存仅显示漫画内容';

  @override
  String get comicBrowse => '漫画筛选';

  @override
  String get trendingComics => '发烧漫画';

  @override
  String get latestComics => '最新上传';

  @override
  String get comicSearchUnavailable => '漫画不支持关键词搜索';

  @override
  String get comicDetails => '漫画详情';

  @override
  String get read => '阅读';

  @override
  String pageCount(int count) {
    return '$count 页';
  }

  @override
  String get tags => '标签';

  @override
  String get chapter => '目录';

  @override
  String get chapterOne => '第 1 章';

  @override
  String get addToLibrary => '添加到收藏';

  @override
  String get cacheComicConfirmation => '确定缓存整本漫画吗？';

  @override
  String get info => '信息';

  @override
  String get noComics => '暂无漫画';

  @override
  String get pageNumber => '页码';

  @override
  String get readingMode => '阅读模式';

  @override
  String get general => '常规';

  @override
  String get leftToRight => '单页式（从左到右）';

  @override
  String get rightToLeft => '单页式（从右到左）';

  @override
  String get topToBottom => '单页式（从上到下）';

  @override
  String get scroll => '条漫';

  @override
  String get scrollGap => '条漫（页间有空隙）';

  @override
  String get black => '黑色';

  @override
  String get gray => '灰色';

  @override
  String get white => '白色';

  @override
  String get cacheCategory => '缓存分类';

  @override
  String get newCategory => '新分类';

  @override
  String get danmakuHint => '发弹幕';

  @override
  String get sendDanmaku => '发送弹幕';

  @override
  String get danmakuContentHint => '输入发送的弹幕内容';

  @override
  String get danmakuSubmitted => '弹幕已发送';

  @override
  String get danmakuSubmitFailed => '弹幕发送失败，请稍后重试';

  @override
  String get danmakuSettings => '弹幕设置';

  @override
  String get danmakuSettingsDescription => '显示、屏蔽与播放同步';

  @override
  String get enableDanmaku => '启用弹幕';

  @override
  String get enableDanmakuDescription => '在播放器中显示弹幕';

  @override
  String get danmakuKeywordFilter => '弹幕关键词屏蔽';

  @override
  String get danmakuKeywordFilterDescription => '包含关键词的弹幕不会显示';

  @override
  String get danmakuFollowsPlaybackSpeed => '弹幕跟随视频倍速';

  @override
  String get danmakuFollowsPlaybackSpeedDescription => '视频倍速改变时同步调整弹幕速度';

  @override
  String get showDanmaku => '显示弹幕';

  @override
  String get hideDanmaku => '隐藏弹幕';

  @override
  String get navigationDrawer => '使用导航抽屉';

  @override
  String get navigationDrawerDescription => '使用抽屉替代底部导航栏';

  @override
  String get home => '主页';

  @override
  String get seekSensitivity => '进度滑动灵敏度';

  @override
  String get seekSensitivityDescription => '调低可减少左右滑动时的跳转幅度';

  @override
  String seekSensitivityValue(int value) {
    return '$value%';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'Han1me+';

  @override
  String get settings => '設定';

  @override
  String get language => '語言';

  @override
  String get systemDefault => '系統預設';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get keyframeSettings => '關鍵 H 幀設定';

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get keyframesEnabled => '啟用關鍵 H 幀';

  @override
  String get keyframesEnabledDescription => '播放器中顯示關鍵 H 幀入口與倒數計時';

  @override
  String get keyframesDisabledDescription => '關鍵 H 幀功能已關閉';

  @override
  String get shareKeyframes => '分享您的關鍵 H 幀集';

  @override
  String get shareKeyframesDescription => '新增或修改後自動上傳至分享資料來源';

  @override
  String get shareKeyframesConfirmation => '將上傳現有關鍵 H 幀並持續同步後續變更。';

  @override
  String get useSharedKeyframes => '採用好心人的關鍵 H 幀集';

  @override
  String get useSharedKeyframesDescription => '自動使用分享資料來源中的關鍵 H 幀';

  @override
  String get preferSharedKeyframes => '優先採用分享關鍵 H 幀集';

  @override
  String get preferSharedKeyframesDescription => '當本機集和分享集都有該影片的關鍵 H 幀時，採用分享集';

  @override
  String get upload => '上傳';

  @override
  String get uploadingKeyframes => '正在上傳關鍵 H 幀';

  @override
  String get uploadComplete => '上傳完成';

  @override
  String get keyframesUploadDescription => '分享功能已開啟，之後的變更將自動上傳。';

  @override
  String keyframesUploadFailed(Object error) {
    return '上傳失敗（$error），請稍後再試。';
  }

  @override
  String get manage => '管理';

  @override
  String get noKeyframes => '還沒有關鍵 H 幀';

  @override
  String get editVideoTitle => '修改影片標題';

  @override
  String get deleteVideoKeyframes => '刪除該影片的關鍵 H 幀';

  @override
  String deleteVideoKeyframesConfirmation(Object title) {
    return '刪除「$title」的全部關鍵 H 幀？';
  }

  @override
  String get editPosition => '修改時間點';

  @override
  String get deleteKeyframe => '刪除關鍵 H 幀';

  @override
  String get deleteKeyframeTitle => '刪除關鍵 H 幀';

  @override
  String get videoTitle => '影片標題';

  @override
  String get positionMilliseconds => '時間點（毫秒）';

  @override
  String get invalidKeyframe => '時間點無效或與其他關鍵幀間隔不足 10 秒';

  @override
  String get content => '內容';

  @override
  String get languageSettings => '語言';

  @override
  String get appearance => '外觀';

  @override
  String get themeAndColor => '主題與色彩';

  @override
  String get interfaceLayout => '介面配置';

  @override
  String get wallpaperColors => '桌布顏色';

  @override
  String get basicColors => '基本顏色';

  @override
  String get customAccentColor => '自訂強調色';

  @override
  String get invalidColor => '請輸入六位十六進位顏色';

  @override
  String get playback => '播放';

  @override
  String get playerEngine => '播放器核心';

  @override
  String get preferredQuality => '優先畫質';

  @override
  String get resumePlayback => '自動續播';

  @override
  String get resumePlaybackDescription => '再次播放時從上次退出的位置繼續';

  @override
  String get site => '網站';

  @override
  String get network => '網路';

  @override
  String get networkSettings => '網路設定';

  @override
  String get useBuiltInHosts => '使用內建 Hosts';

  @override
  String get useBuiltInHostsDescription => '為 Hanime1 網域使用內建的 Cloudflare IP 位址';

  @override
  String get doh => 'DNS over HTTPS';

  @override
  String get useDoh => '使用 DNS over HTTPS';

  @override
  String get dohSettings => 'DNS over HTTPS 設定';

  @override
  String get dohDisabled => '已關閉';

  @override
  String get dohPreset => '服務商';

  @override
  String get dohCustomUrl => '自訂 DoH 位址';

  @override
  String get dohBootstrapIps => 'Bootstrap IP 位址';

  @override
  String get dohBootstrapIpsDescription => '可使用逗號、空格或換行分隔';

  @override
  String get dohTimeoutSeconds => '逾時秒數';

  @override
  String get dohTimeoutSecondsDescription => '範圍為 1 至 60 秒';

  @override
  String get useEch => '啟用 ECH';

  @override
  String get useEchDescription => '為 Hanime 網站加密 TLS ClientHello 中的網域資訊';

  @override
  String get echLogs => 'ECH 日誌';

  @override
  String get echLogsDescription => '查看 ECH 設定與連線狀態';

  @override
  String get clearEchLogs => '清除日誌';

  @override
  String get noEchLogs => '尚無 ECH 日誌';

  @override
  String get custom => '自訂';

  @override
  String get cloudflareVerification => 'Cloudflare 驗證';

  @override
  String get cloudflareVerificationDescription => '存取受保護頁面時完成驗證';

  @override
  String get autoCheckUpdates => '自動檢查更新';

  @override
  String get checkUpdates => '檢查更新';

  @override
  String get application => '應用程式';

  @override
  String get applicationSettings => '應用程式';

  @override
  String get applicationSettingsDescription => '修改應用程式相關設定';

  @override
  String get other => '其他';

  @override
  String get keyframeManagement => '關鍵 H 幀管理';

  @override
  String get about => '關於 Han1me+';

  @override
  String get aboutDescription => '版本與開源資訊';

  @override
  String get explore => '探索';

  @override
  String get library => '收藏';

  @override
  String get cache => '快取';

  @override
  String get more => '查看更多';

  @override
  String get featured => '首頁推薦';

  @override
  String get retry => '重試';

  @override
  String get completeCloudflareVerification => '完成 Cloudflare 驗證';

  @override
  String get searchHint => '搜尋影片、作者、標籤…';

  @override
  String get noSearchResults => '沒有找到符合的影片';

  @override
  String category(Object value) {
    return '分類：$value';
  }

  @override
  String sort(Object value) {
    return '排序：$value';
  }

  @override
  String releaseDate(Object value) {
    return '發布日期：$value';
  }

  @override
  String get releaseDateTitle => '發布日期';

  @override
  String duration(Object value) {
    return '時長：$value';
  }

  @override
  String get searchAuthors => '搜尋作者';

  @override
  String tagsSelected(int count) {
    return '標籤：已選 $count';
  }

  @override
  String get broadMatch => '廣泛配對';

  @override
  String get broadMatchDescription => '配對任一已選標籤，結果較多但精準度較低。';

  @override
  String get tagVideoAttributes => '影片屬性';

  @override
  String get tagRelationships => '人物關係';

  @override
  String get tagCharacterSettings => '角色設定';

  @override
  String get tagAppearance => '外貌身材';

  @override
  String get tagSettings => '情境場所';

  @override
  String get tagStory => '故事劇情';

  @override
  String get tagPositions => '性交體位';

  @override
  String get dateRange => '大致範圍';

  @override
  String get specificYearMonth => '具體年月';

  @override
  String get year => '年份';

  @override
  String get month => '月份';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get apply => '套用';

  @override
  String get clear => '清除';

  @override
  String get all => '全部';

  @override
  String get defaultValue => '預設';

  @override
  String get comments => '評論';

  @override
  String get reload => '重新載入';

  @override
  String get noComments => '還沒有人評論';

  @override
  String get previews => '新番預告';

  @override
  String previewMonth(Object month) {
    return '$month 新番表';
  }

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String get previewUnavailable => '本月新番預告暫時無法使用';

  @override
  String get previewUnavailableDescription => '可以重新載入，或查看此前月份的新番預告。';

  @override
  String get noPreviews => '這個月還沒有新番預告';

  @override
  String get noPreviewsDescription => '新番資料發布後會在這裡顯示，也可以先瀏覽此前月份。';

  @override
  String get watchVideo => '觀看影片';

  @override
  String previewImages(int count) {
    return '預告圖片（$count）';
  }

  @override
  String get statistics => '統計';

  @override
  String watchDuration(Object duration) {
    return '觀看時長  $duration';
  }

  @override
  String get noWatchHistory => '暫無觀看紀錄';

  @override
  String hoursMinutes(Object hours, Object minutes) {
    return '$hours時$minutes分';
  }

  @override
  String minutes(Object value) {
    return '$value分鐘';
  }

  @override
  String seconds(Object value) {
    return '$value秒';
  }

  @override
  String get myLibrary => '我的收藏';

  @override
  String get watchLater => '稍後觀看';

  @override
  String get favoriteVideos => '喜歡的影片';

  @override
  String get subscriptions => '我的訂閱';

  @override
  String get noWatchLater => '暫無稍後觀看影片';

  @override
  String get noFavoriteVideos => '暫無喜歡的影片';

  @override
  String get noSubscriptionVideos => '暫無訂閱影片';

  @override
  String selectedItems(int count) {
    return '已選 $count 項';
  }

  @override
  String get select => '選擇';

  @override
  String get deleteSelectedCache => '刪除所選快取';

  @override
  String get createGroup => '新增群組';

  @override
  String get noCache => '暫無快取';

  @override
  String get localVideoMissing => '本機影片檔案不存在，請刪除該快取後重新下載';

  @override
  String get deleteCache => '刪除快取';

  @override
  String deleteCacheConfirmation(Object title) {
    return '刪除「$title」的本機快取？';
  }

  @override
  String deleteGroupTitle(Object name) {
    return '刪除「$name」';
  }

  @override
  String get moveGroupCacheToDefault => '該群組中的快取將移至預設群組。';

  @override
  String get groupName => '群組名稱';

  @override
  String get confirm => '確定';

  @override
  String get queued => '等待中';

  @override
  String get downloading => '下載中';

  @override
  String get completed => '已完成';

  @override
  String get failed => '失敗';

  @override
  String commentsTitle(Object title) {
    return '$title 評論';
  }

  @override
  String date(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get thirdPartyClient => '第三方 Hanime1 用戶端';

  @override
  String get version => '版本';

  @override
  String get dataSource => '資料來源';

  @override
  String get dataSourceDescription => 'Hanime1 網站公開頁面內容';

  @override
  String get githubRepository => 'GitHub 儲存庫';

  @override
  String get reportIssue => '回報問題';

  @override
  String get submitGitHubIssue => '提交 GitHub Issue';

  @override
  String get openSourceLicense => '開源授權';

  @override
  String get verificationComplete => '驗證完成';

  @override
  String get pause => '暫停';

  @override
  String get play => '播放';

  @override
  String get exitFullscreen => '退出全螢幕';

  @override
  String get fullscreenPlayback => '全螢幕播放';

  @override
  String get pauseBeforeAddingKeyframe => '請先暫停影片，再新增關鍵 H 幀';

  @override
  String get addKeyframe => '新增關鍵 H 幀';

  @override
  String addKeyframeConfirmation(int position) {
    return '將目前暫停位置加入關鍵 H 幀？\n\n目前時間：$position ms\n相鄰關鍵幀至少間隔 10 秒。';
  }

  @override
  String get add => '新增';

  @override
  String get keyframeAdded => '已新增關鍵 H 幀';

  @override
  String get keyframeTooClose => '與已有關鍵幀間隔不足 10 秒';

  @override
  String get longPressAddKeyframe => '長按新增關鍵 H 幀';

  @override
  String get keyframes => '關鍵 H 幀';

  @override
  String get deleteCurrentVideoKeyframes => '刪除目前影片的全部關鍵 H 幀';

  @override
  String get deleteCurrentVideoKeyframesConfirmation => '刪除目前影片的全部關鍵 H 幀？';

  @override
  String get editKeyframe => '修改關鍵 H 幀';

  @override
  String keyframeCountdown(Object seconds) {
    return '關鍵 H 幀還有 $seconds 秒';
  }

  @override
  String get episodeList => '劇集清單';

  @override
  String get seriesVideos => '系列影片';

  @override
  String get relatedVideos => '相關推薦';

  @override
  String get studio => '廠商';

  @override
  String get subscribed => '已訂閱';

  @override
  String get subscribe => '訂閱';

  @override
  String get favorite => '收藏';

  @override
  String get download => '下載';

  @override
  String get share => '分享';

  @override
  String get selectDownloadQuality => '選擇下載畫質';

  @override
  String get startDownload => '開始下載';

  @override
  String get addedToDownloadQueue => '已加入下載佇列';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展開';

  @override
  String get description => '簡介';

  @override
  String get commentsLoadFailed => '評論載入失敗';

  @override
  String keyframeCount(int count) {
    return '$count 個關鍵幀';
  }

  @override
  String get themeMode => '主題模式';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get themeColor => '主題色';

  @override
  String get rose => '玫紅';

  @override
  String get blue => '藍色';

  @override
  String get teal => '青綠';

  @override
  String get amber => '琥珀';

  @override
  String get forestGreen => '森林綠';

  @override
  String get orange => '橙色';

  @override
  String get indigo => '靛藍';

  @override
  String get pink => '粉色';

  @override
  String get purple => '紫色';

  @override
  String get keyframeSettingsDescription => '管理開關及各影片的關鍵 H 幀';

  @override
  String get latestVersion => '目前已是最新版本';

  @override
  String newVersionAvailable(Object version) {
    return '發現新版本 $version';
  }

  @override
  String get newVersionReleased => '已發布新版本。';

  @override
  String get later => '稍後';

  @override
  String get updateNow => '現在更新';

  @override
  String get noInstallableApk => '目前版本沒有可安裝的 APK 檔案';

  @override
  String get updateIncomplete => '更新未完成';

  @override
  String get downloadingUpdate => '正在下載更新';

  @override
  String get connecting => '正在連線...';

  @override
  String updateFailed(Object error) {
    return '更新失敗：$error';
  }

  @override
  String get close => '關閉';

  @override
  String get monetColors => '莫內取色';

  @override
  String get monetColorsDescription => '使用系統桌布動態配色';

  @override
  String get downloadSettings => '下載設定';

  @override
  String get downloadSettingsDescription => '速度與同時下載數量限制';

  @override
  String get downloadSpeedLimit => '下載速度限制';

  @override
  String get unlimited => '不限速';

  @override
  String get concurrentDownloads => '同時下載數量限制';

  @override
  String concurrentDownloadsDescription(int count) {
    return '同時下載 $count 部影片';
  }

  @override
  String get downloadPath => '下載路徑';

  @override
  String get defaultDownloadPath =>
      '/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/';

  @override
  String get exportDownloads => '匯出下載項目';

  @override
  String get exportDownloadsDescription => '將私有下載目錄中的所有已下載項目匯出至自訂目錄';

  @override
  String get exportCompleted => '下載項目已匯出';

  @override
  String get amoledMode => 'AMOLED 模式';

  @override
  String get amoledModeDescription => '深色主題使用純黑背景';

  @override
  String get watchHistory => '觀看記錄';

  @override
  String get playlists => '播放清單';

  @override
  String get noPlaylists => '暫無播放清單';

  @override
  String get deletePlaylist => '刪除播放清單';

  @override
  String deletePlaylistConfirmation(Object title) {
    return '確定刪除「$title」嗎？';
  }

  @override
  String videoCount(int count) {
    return '$count 部影片';
  }

  @override
  String loadFailed(Object error) {
    return '載入失敗：$error';
  }

  @override
  String get playlistEmpty => '播放清單為空';

  @override
  String get writeComment => '發表評論';

  @override
  String get commentHint => '輸入評論內容';

  @override
  String get latest => '最新';

  @override
  String get popular => '熱門';

  @override
  String get oldest => '最早';

  @override
  String playlistCreatedBy(Object name) {
    return '由 $name 建立';
  }

  @override
  String playlistStats(int count, int views) {
    return '播放清單 • $count 部影片 • 觀看次數：$views 次';
  }

  @override
  String get playAll => '全部播放';

  @override
  String get earliest => '最早';

  @override
  String get mostReplies => '回覆最多';

  @override
  String get mostLikes => '最多讚';

  @override
  String get mostDislikes => '最多倒讚';

  @override
  String get viewReplies => '查看回覆';

  @override
  String viewRepliesCount(int count) {
    return '查看回覆 ($count)';
  }

  @override
  String get reply => '回覆';

  @override
  String get replyComment => '回覆評論';

  @override
  String get send => '傳送';

  @override
  String get addToPlaylist => '加入清單';

  @override
  String get newPlaylist => '新增播放清單';

  @override
  String get name => '名稱';

  @override
  String get create => '建立';

  @override
  String get account => '帳戶';

  @override
  String get logout => '登出';

  @override
  String get logoutConfirmation => '確定要登出目前帳戶嗎？';

  @override
  String get accountProfile => '帳戶資料';

  @override
  String get signedIn => '已登入';

  @override
  String get signedOut => '未登入';

  @override
  String accountSummary(
      Object id, int subscriberCount, int videoCount, Object joined) {
    return '@$id\n$subscriberCount 位訂閱者 · $videoCount 部影片\n$joined';
  }

  @override
  String get tapToLogin => '點擊前往登入';

  @override
  String get editProfile => '編輯個人資料';

  @override
  String get changePassword => '變更密碼';

  @override
  String get username => '使用者名稱';

  @override
  String get email => '電子郵件';

  @override
  String get saveProfile => '儲存資料';

  @override
  String get oldPassword => '舊密碼';

  @override
  String get newPassword => '新密碼';

  @override
  String get confirmNewPassword => '確認新密碼';

  @override
  String get login => '登入';

  @override
  String get finishLogin => '完成登入';

  @override
  String get genreAdultAnimation => '裏番';

  @override
  String get genreShortAnimation => '泡麵番';

  @override
  String get genre2dAnimation => '2D動畫';

  @override
  String get genreAiGenerated => 'AI生成';

  @override
  String get sortLatestRelease => '最新上市';

  @override
  String get sortLatestUpload => '最新上傳';

  @override
  String get sortTrending => '他們在看';

  @override
  String get playbackSettings => '播放設定';

  @override
  String get playbackSettingsDescription => '倍數、長按倍數與控制器顯示時間';

  @override
  String get defaultPlaybackSpeed => '預設播放倍數';

  @override
  String get longPressPlaybackSpeed => '預設長按倍數';

  @override
  String get playerControlsTimeout => '播放控制器消失時間';

  @override
  String get playerControlsTimeoutDescription => '不操作時自動隱藏播放控制器';

  @override
  String get privacySettings => '隱私設定';

  @override
  String get appLock => '使用應用鎖定螢幕';

  @override
  String get appLockDescription => '開啟後，進入應用時需驗證螢幕鎖，防止別人開啟';

  @override
  String get emergencyExit => '緊急狀況';

  @override
  String get emergencyExitDescription => '開啟後，應用內連續按三次音量上鍵會停止播放並返回桌面';

  @override
  String get hideFromRecents => '從最近工作中隱藏';

  @override
  String get hideFromRecentsDescription => '應用在背景時，從最近工作中隱藏應用';

  @override
  String get commentSettings => '評論設定';

  @override
  String get enableComments => '啟用評論區';

  @override
  String get commentsDisabled => '評論區已關閉';

  @override
  String get commentKeywordFilter => '關鍵詞屏蔽';

  @override
  String get commentKeywordFilterDescription => '包含關鍵詞的評論不會顯示';

  @override
  String get keyword => '關鍵詞';

  @override
  String get deepLinkSettings => '應用深層連結設定';

  @override
  String get deepLinkSettingsDescription => '開啟相關網頁後能快速跳轉至本 App';

  @override
  String get openAppLinkSettings => '管理網頁連結';

  @override
  String get openAppLinkSettingsDescription => '在系統設定中允許 Han1me+ 開啟支援的連結';

  @override
  String get playbackSpeed => '播放倍數';

  @override
  String get lockControls => '鎖定播放面板';

  @override
  String get unlockControls => '解除播放面板鎖定';

  @override
  String get brightness => '亮度';

  @override
  String get volume => '音量';

  @override
  String get comicMode => '觀看漫畫';

  @override
  String get horizontalSearchCards => '橫向影片卡片';

  @override
  String get horizontalSearchCardsDescription => '影片使用橫向卡片顯示';

  @override
  String get expandHomeVideoCards => '展開首頁影片卡片';

  @override
  String get expandHomeVideoCardsDescription =>
      '關閉時首頁每個分類橫向顯示一行影片；開啟後使用影片卡片每行數量設定';

  @override
  String get searchCardsPerRow => '影片卡片每行數量';

  @override
  String searchCardsPerRowValue(int count) {
    return '每行 $count 個';
  }

  @override
  String get comicModeDescription => '開啟後首頁、收藏和快取僅顯示漫畫內容';

  @override
  String get comicBrowse => '漫畫篩選';

  @override
  String get trendingComics => '發燒漫畫';

  @override
  String get latestComics => '最新上傳';

  @override
  String get comicSearchUnavailable => '漫畫不支援關鍵字搜尋';

  @override
  String get comicDetails => '漫畫詳情';

  @override
  String get read => '閱讀';

  @override
  String pageCount(int count) {
    return '$count 頁';
  }

  @override
  String get tags => '標籤';

  @override
  String get chapter => '目錄';

  @override
  String get chapterOne => '第 1 章';

  @override
  String get addToLibrary => '加入收藏';

  @override
  String get cacheComicConfirmation => '確定快取整本漫畫嗎？';

  @override
  String get info => '資訊';

  @override
  String get noComics => '暫無漫畫';

  @override
  String get pageNumber => '頁碼';

  @override
  String get readingMode => '閱讀模式';

  @override
  String get general => '一般';

  @override
  String get leftToRight => '單頁式（從左到右）';

  @override
  String get rightToLeft => '單頁式（從右到左）';

  @override
  String get topToBottom => '單頁式（從上到下）';

  @override
  String get scroll => '條漫';

  @override
  String get scrollGap => '條漫（頁間有空隙）';

  @override
  String get black => '黑色';

  @override
  String get gray => '灰色';

  @override
  String get white => '白色';

  @override
  String get cacheCategory => '快取分類';

  @override
  String get newCategory => '新分類';

  @override
  String get danmakuHint => '發彈幕';

  @override
  String get sendDanmaku => '傳送彈幕';

  @override
  String get danmakuContentHint => '輸入要傳送的彈幕內容';

  @override
  String get danmakuSubmitted => '彈幕已送出';

  @override
  String get danmakuSubmitFailed => '彈幕傳送失敗，請稍後重試';

  @override
  String get danmakuSettings => '彈幕設定';

  @override
  String get danmakuSettingsDescription => '顯示、屏蔽與播放同步';

  @override
  String get enableDanmaku => '啟用彈幕';

  @override
  String get enableDanmakuDescription => '在播放器中顯示彈幕';

  @override
  String get danmakuKeywordFilter => '彈幕關鍵詞屏蔽';

  @override
  String get danmakuKeywordFilterDescription => '包含關鍵詞的彈幕不會顯示';

  @override
  String get danmakuFollowsPlaybackSpeed => '彈幕跟隨影片倍速';

  @override
  String get danmakuFollowsPlaybackSpeedDescription => '影片倍速改變時同步調整彈幕速度';

  @override
  String get showDanmaku => '顯示彈幕';

  @override
  String get hideDanmaku => '隱藏彈幕';

  @override
  String get navigationDrawer => '使用導覽抽屜';

  @override
  String get navigationDrawerDescription => '使用抽屜取代底部導覽列';

  @override
  String get home => '首頁';

  @override
  String get seekSensitivity => '進度滑動靈敏度';

  @override
  String get seekSensitivityDescription => '調低可減少左右滑動時的跳轉幅度';

  @override
  String seekSensitivityValue(int value) {
    return '$value%';
  }
}
