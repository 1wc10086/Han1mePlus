import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'Han1me+'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统默认'**
  String get systemDefault;

  /// No description provided for @simplifiedChinese.
  ///
  /// In zh_CN, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @traditionalChinese.
  ///
  /// In zh_CN, this message translates to:
  /// **'繁體中文'**
  String get traditionalChinese;

  /// No description provided for @keyframeSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键 H 帧设置'**
  String get keyframeSettings;

  /// No description provided for @edit.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @keyframesEnabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用关键 H 帧'**
  String get keyframesEnabled;

  /// No description provided for @keyframesEnabledDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器中显示关键 H 帧入口与倒计时'**
  String get keyframesEnabledDescription;

  /// No description provided for @keyframesDisabledDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键 H 帧功能已关闭'**
  String get keyframesDisabledDescription;

  /// No description provided for @shareKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'共享您的关键 H 帧集'**
  String get shareKeyframes;

  /// No description provided for @shareKeyframesDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'新增或修改后自动上传到共享数据源'**
  String get shareKeyframesDescription;

  /// No description provided for @shareKeyframesConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'将上传现有关键 H 帧并持续同步之后的更改。'**
  String get shareKeyframesConfirmation;

  /// No description provided for @useSharedKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'采用好心人的关键 H 帧集'**
  String get useSharedKeyframes;

  /// No description provided for @useSharedKeyframesDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动使用共享数据源中的关键 H 帧'**
  String get useSharedKeyframesDescription;

  /// No description provided for @preferSharedKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'优先采用共享关键 H 帧集'**
  String get preferSharedKeyframes;

  /// No description provided for @preferSharedKeyframesDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'当本地集和共享集都有该影片的关键 H 帧时，采用共享集'**
  String get preferSharedKeyframesDescription;

  /// No description provided for @upload.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传'**
  String get upload;

  /// No description provided for @uploadingKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在上传关键 H 帧'**
  String get uploadingKeyframes;

  /// No description provided for @uploadComplete.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传完成'**
  String get uploadComplete;

  /// No description provided for @keyframesUploadDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'共享功能已开启，之后的更改将自动上传。'**
  String get keyframesUploadDescription;

  /// No description provided for @keyframesUploadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传失败（{error}），请稍后重试。'**
  String keyframesUploadFailed(Object error);

  /// No description provided for @manage.
  ///
  /// In zh_CN, this message translates to:
  /// **'管理'**
  String get manage;

  /// No description provided for @noKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有关键 H 帧'**
  String get noKeyframes;

  /// No description provided for @editVideoTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'修改影片标题'**
  String get editVideoTitle;

  /// No description provided for @deleteVideoKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除该影片的关键 H 帧'**
  String get deleteVideoKeyframes;

  /// No description provided for @deleteVideoKeyframesConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除“{title}”的全部关键 H 帧？'**
  String deleteVideoKeyframesConfirmation(Object title);

  /// No description provided for @editPosition.
  ///
  /// In zh_CN, this message translates to:
  /// **'修改时间点'**
  String get editPosition;

  /// No description provided for @deleteKeyframe.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除关键 H 帧'**
  String get deleteKeyframe;

  /// No description provided for @deleteKeyframeTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除关键 H 帧'**
  String get deleteKeyframeTitle;

  /// No description provided for @videoTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'影片标题'**
  String get videoTitle;

  /// No description provided for @positionMilliseconds.
  ///
  /// In zh_CN, this message translates to:
  /// **'时间点（毫秒）'**
  String get positionMilliseconds;

  /// No description provided for @invalidKeyframe.
  ///
  /// In zh_CN, this message translates to:
  /// **'时间点无效或与其他关键帧间隔不足 10 秒'**
  String get invalidKeyframe;

  /// No description provided for @content.
  ///
  /// In zh_CN, this message translates to:
  /// **'内容'**
  String get content;

  /// No description provided for @languageSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言'**
  String get languageSettings;

  /// No description provided for @appearance.
  ///
  /// In zh_CN, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @themeAndColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题与色彩'**
  String get themeAndColor;

  /// No description provided for @interfaceLayout.
  ///
  /// In zh_CN, this message translates to:
  /// **'界面布局'**
  String get interfaceLayout;

  /// No description provided for @wallpaperColors.
  ///
  /// In zh_CN, this message translates to:
  /// **'壁纸颜色'**
  String get wallpaperColors;

  /// No description provided for @basicColors.
  ///
  /// In zh_CN, this message translates to:
  /// **'基本颜色'**
  String get basicColors;

  /// No description provided for @customAccentColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义强调色'**
  String get customAccentColor;

  /// No description provided for @invalidColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入六位十六进制颜色'**
  String get invalidColor;

  /// No description provided for @playback.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get playback;

  /// No description provided for @playerEngine.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器内核'**
  String get playerEngine;

  /// No description provided for @preferredQuality.
  ///
  /// In zh_CN, this message translates to:
  /// **'优先清晰度'**
  String get preferredQuality;

  /// No description provided for @resumePlayback.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动续播'**
  String get resumePlayback;

  /// No description provided for @resumePlaybackDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'再次播放时从上次退出的位置继续'**
  String get resumePlaybackDescription;

  /// No description provided for @site.
  ///
  /// In zh_CN, this message translates to:
  /// **'站点'**
  String get site;

  /// No description provided for @network.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络'**
  String get network;

  /// No description provided for @networkSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络设置'**
  String get networkSettings;

  /// No description provided for @useBuiltInHosts.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用内置 Hosts'**
  String get useBuiltInHosts;

  /// No description provided for @useBuiltInHostsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'为 Hanime1 域名使用内置的 Cloudflare IP 地址'**
  String get useBuiltInHostsDescription;

  /// No description provided for @doh.
  ///
  /// In zh_CN, this message translates to:
  /// **'DNS over HTTPS'**
  String get doh;

  /// No description provided for @useDoh.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用 DNS over HTTPS'**
  String get useDoh;

  /// No description provided for @dohSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'DNS over HTTPS 设置'**
  String get dohSettings;

  /// No description provided for @dohDisabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭'**
  String get dohDisabled;

  /// No description provided for @dohPreset.
  ///
  /// In zh_CN, this message translates to:
  /// **'服务商'**
  String get dohPreset;

  /// No description provided for @dohCustomUrl.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义 DoH 地址'**
  String get dohCustomUrl;

  /// No description provided for @dohBootstrapIps.
  ///
  /// In zh_CN, this message translates to:
  /// **'Bootstrap IP 地址'**
  String get dohBootstrapIps;

  /// No description provided for @dohBootstrapIpsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'可使用逗号、空格或换行分隔'**
  String get dohBootstrapIpsDescription;

  /// No description provided for @dohTimeoutSeconds.
  ///
  /// In zh_CN, this message translates to:
  /// **'超时秒数'**
  String get dohTimeoutSeconds;

  /// No description provided for @dohTimeoutSecondsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'范围为 1 至 60 秒'**
  String get dohTimeoutSecondsDescription;

  /// No description provided for @useEch.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用 ECH'**
  String get useEch;

  /// No description provided for @useEchDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'为 Hanime 站点加密 TLS ClientHello 中的域名信息'**
  String get useEchDescription;

  /// No description provided for @echLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'ECH 日志'**
  String get echLogs;

  /// No description provided for @echLogsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看 ECH 配置与连接状态'**
  String get echLogsDescription;

  /// No description provided for @clearEchLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空日志'**
  String get clearEchLogs;

  /// No description provided for @noEchLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无 ECH 日志'**
  String get noEchLogs;

  /// No description provided for @custom.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义'**
  String get custom;

  /// No description provided for @cloudflareVerification.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cloudflare 验证'**
  String get cloudflareVerification;

  /// No description provided for @cloudflareVerificationDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'访问受保护页面时完成验证'**
  String get cloudflareVerificationDescription;

  /// No description provided for @autoCheckUpdates.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动检查更新'**
  String get autoCheckUpdates;

  /// No description provided for @checkUpdates.
  ///
  /// In zh_CN, this message translates to:
  /// **'检查更新'**
  String get checkUpdates;

  /// No description provided for @application.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用'**
  String get application;

  /// No description provided for @applicationSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用程序'**
  String get applicationSettings;

  /// No description provided for @applicationSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'修改应用程序相关设置'**
  String get applicationSettingsDescription;

  /// No description provided for @other.
  ///
  /// In zh_CN, this message translates to:
  /// **'其他'**
  String get other;

  /// No description provided for @keyframeManagement.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键 H 帧管理'**
  String get keyframeManagement;

  /// No description provided for @about.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于 Han1me+'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本与开源信息'**
  String get aboutDescription;

  /// No description provided for @explore.
  ///
  /// In zh_CN, this message translates to:
  /// **'探索'**
  String get explore;

  /// No description provided for @library.
  ///
  /// In zh_CN, this message translates to:
  /// **'收藏'**
  String get library;

  /// No description provided for @cache.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存'**
  String get cache;

  /// No description provided for @more.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看更多'**
  String get more;

  /// No description provided for @featured.
  ///
  /// In zh_CN, this message translates to:
  /// **'首页推荐'**
  String get featured;

  /// No description provided for @retry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @completeCloudflareVerification.
  ///
  /// In zh_CN, this message translates to:
  /// **'完成 Cloudflare 验证'**
  String get completeCloudflareVerification;

  /// No description provided for @searchHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索视频、作者、标签…'**
  String get searchHint;

  /// No description provided for @noSearchResults.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的视频'**
  String get noSearchResults;

  /// No description provided for @category.
  ///
  /// In zh_CN, this message translates to:
  /// **'分类：{value}'**
  String category(Object value);

  /// No description provided for @sort.
  ///
  /// In zh_CN, this message translates to:
  /// **'排序：{value}'**
  String sort(Object value);

  /// No description provided for @releaseDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'发布日期：{value}'**
  String releaseDate(Object value);

  /// No description provided for @releaseDateTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'发布日期'**
  String get releaseDateTitle;

  /// No description provided for @duration.
  ///
  /// In zh_CN, this message translates to:
  /// **'时长：{value}'**
  String duration(Object value);

  /// No description provided for @searchAuthors.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索作者'**
  String get searchAuthors;

  /// No description provided for @tagsSelected.
  ///
  /// In zh_CN, this message translates to:
  /// **'标签：已选 {count}'**
  String tagsSelected(int count);

  /// No description provided for @broadMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'广泛配对'**
  String get broadMatch;

  /// No description provided for @broadMatchDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'匹配任一所选标签，结果更多但精度较低。'**
  String get broadMatchDescription;

  /// No description provided for @tagVideoAttributes.
  ///
  /// In zh_CN, this message translates to:
  /// **'影片属性'**
  String get tagVideoAttributes;

  /// No description provided for @tagRelationships.
  ///
  /// In zh_CN, this message translates to:
  /// **'人物关系'**
  String get tagRelationships;

  /// No description provided for @tagCharacterSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'角色设定'**
  String get tagCharacterSettings;

  /// No description provided for @tagAppearance.
  ///
  /// In zh_CN, this message translates to:
  /// **'外貌身材'**
  String get tagAppearance;

  /// No description provided for @tagSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'情境场所'**
  String get tagSettings;

  /// No description provided for @tagStory.
  ///
  /// In zh_CN, this message translates to:
  /// **'故事剧情'**
  String get tagStory;

  /// No description provided for @tagPositions.
  ///
  /// In zh_CN, this message translates to:
  /// **'性交体位'**
  String get tagPositions;

  /// No description provided for @dateRange.
  ///
  /// In zh_CN, this message translates to:
  /// **'大致范围'**
  String get dateRange;

  /// No description provided for @specificYearMonth.
  ///
  /// In zh_CN, this message translates to:
  /// **'具体年月'**
  String get specificYearMonth;

  /// No description provided for @year.
  ///
  /// In zh_CN, this message translates to:
  /// **'年份'**
  String get year;

  /// No description provided for @month.
  ///
  /// In zh_CN, this message translates to:
  /// **'月份'**
  String get month;

  /// No description provided for @allYears.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部年份'**
  String get allYears;

  /// No description provided for @allMonths.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部月份'**
  String get allMonths;

  /// No description provided for @apply.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除'**
  String get clear;

  /// No description provided for @all.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @defaultValue.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认'**
  String get defaultValue;

  /// No description provided for @comments.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论'**
  String get comments;

  /// No description provided for @reload.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @noComments.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有人评论'**
  String get noComments;

  /// No description provided for @previews.
  ///
  /// In zh_CN, this message translates to:
  /// **'新番预告'**
  String get previews;

  /// No description provided for @previewMonth.
  ///
  /// In zh_CN, this message translates to:
  /// **'{month} 新番表'**
  String previewMonth(Object month);

  /// No description provided for @previousMonth.
  ///
  /// In zh_CN, this message translates to:
  /// **'上个月'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In zh_CN, this message translates to:
  /// **'下个月'**
  String get nextMonth;

  /// No description provided for @previewUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'本月新番预告暂不可用'**
  String get previewUnavailable;

  /// No description provided for @previewUnavailableDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'可以重新加载，或查看此前月份的新番预告。'**
  String get previewUnavailableDescription;

  /// No description provided for @noPreviews.
  ///
  /// In zh_CN, this message translates to:
  /// **'这个月还没有新番预告'**
  String get noPreviews;

  /// No description provided for @noPreviewsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'新番资料发布后会在这里显示，也可以先浏览此前月份。'**
  String get noPreviewsDescription;

  /// No description provided for @watchVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'观看影片'**
  String get watchVideo;

  /// No description provided for @previewImages.
  ///
  /// In zh_CN, this message translates to:
  /// **'预告图片（{count}）'**
  String previewImages(int count);

  /// No description provided for @statistics.
  ///
  /// In zh_CN, this message translates to:
  /// **'统计'**
  String get statistics;

  /// No description provided for @watchDuration.
  ///
  /// In zh_CN, this message translates to:
  /// **'观看时长  {duration}'**
  String watchDuration(Object duration);

  /// No description provided for @noWatchHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无观看记录'**
  String get noWatchHistory;

  /// No description provided for @hoursMinutes.
  ///
  /// In zh_CN, this message translates to:
  /// **'{hours}时{minutes}分'**
  String hoursMinutes(Object hours, Object minutes);

  /// No description provided for @minutes.
  ///
  /// In zh_CN, this message translates to:
  /// **'{value}分钟'**
  String minutes(Object value);

  /// No description provided for @seconds.
  ///
  /// In zh_CN, this message translates to:
  /// **'{value}秒'**
  String seconds(Object value);

  /// No description provided for @myLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的收藏'**
  String get myLibrary;

  /// No description provided for @watchLater.
  ///
  /// In zh_CN, this message translates to:
  /// **'稍后观看'**
  String get watchLater;

  /// No description provided for @favoriteVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'喜欢的影片'**
  String get favoriteVideos;

  /// No description provided for @subscriptions.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的订阅'**
  String get subscriptions;

  /// No description provided for @noWatchLater.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无稍后观看影片'**
  String get noWatchLater;

  /// No description provided for @noFavoriteVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无喜欢的影片'**
  String get noFavoriteVideos;

  /// No description provided for @noSubscriptionVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无订阅影片'**
  String get noSubscriptionVideos;

  /// No description provided for @selectedItems.
  ///
  /// In zh_CN, this message translates to:
  /// **'已选 {count} 项'**
  String selectedItems(int count);

  /// No description provided for @select.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择'**
  String get select;

  /// No description provided for @deleteSelectedCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除所选缓存'**
  String get deleteSelectedCache;

  /// No description provided for @createGroup.
  ///
  /// In zh_CN, this message translates to:
  /// **'新建分组'**
  String get createGroup;

  /// No description provided for @noCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无缓存'**
  String get noCache;

  /// No description provided for @localVideoMissing.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地视频文件不存在，请删除该缓存后重新下载'**
  String get localVideoMissing;

  /// No description provided for @deleteCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除缓存'**
  String get deleteCache;

  /// No description provided for @deleteCacheConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除“{title}”的本地缓存？'**
  String deleteCacheConfirmation(Object title);

  /// No description provided for @deleteGroupTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除“{name}”'**
  String deleteGroupTitle(Object name);

  /// No description provided for @moveGroupCacheToDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'该分组中的缓存将移至默认分组。'**
  String get moveGroupCacheToDefault;

  /// No description provided for @groupName.
  ///
  /// In zh_CN, this message translates to:
  /// **'分组名称'**
  String get groupName;

  /// No description provided for @confirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @queued.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待中'**
  String get queued;

  /// No description provided for @downloading.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载中'**
  String get downloading;

  /// No description provided for @completed.
  ///
  /// In zh_CN, this message translates to:
  /// **'已完成'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In zh_CN, this message translates to:
  /// **'失败'**
  String get failed;

  /// No description provided for @commentsTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'{title} 评论'**
  String commentsTitle(Object title);

  /// No description provided for @date.
  ///
  /// In zh_CN, this message translates to:
  /// **'{year}年{month}月{day}日'**
  String date(int year, int month, int day);

  /// No description provided for @thirdPartyClient.
  ///
  /// In zh_CN, this message translates to:
  /// **'第三方 Hanime1 客户端'**
  String get thirdPartyClient;

  /// No description provided for @version.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @dataSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'数据来源'**
  String get dataSource;

  /// No description provided for @dataSourceDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Hanime1 网站公开页面内容'**
  String get dataSourceDescription;

  /// No description provided for @githubRepository.
  ///
  /// In zh_CN, this message translates to:
  /// **'GitHub 仓库'**
  String get githubRepository;

  /// No description provided for @reportIssue.
  ///
  /// In zh_CN, this message translates to:
  /// **'反馈问题'**
  String get reportIssue;

  /// No description provided for @submitGitHubIssue.
  ///
  /// In zh_CN, this message translates to:
  /// **'提交 GitHub Issue'**
  String get submitGitHubIssue;

  /// No description provided for @openSourceLicense.
  ///
  /// In zh_CN, this message translates to:
  /// **'开源许可'**
  String get openSourceLicense;

  /// No description provided for @verificationComplete.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证完成'**
  String get verificationComplete;

  /// No description provided for @pause.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @exitFullscreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'退出全屏'**
  String get exitFullscreen;

  /// No description provided for @fullscreenPlayback.
  ///
  /// In zh_CN, this message translates to:
  /// **'全屏播放'**
  String get fullscreenPlayback;

  /// No description provided for @pauseBeforeAddingKeyframe.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先暂停视频，再添加关键 H 帧'**
  String get pauseBeforeAddingKeyframe;

  /// No description provided for @addKeyframe.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加关键 H 帧'**
  String get addKeyframe;

  /// No description provided for @addKeyframeConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'将当前暂停位置加入关键 H 帧？\n\n当前时间：{position} ms\n相邻关键帧至少间隔 10 秒。'**
  String addKeyframeConfirmation(int position);

  /// No description provided for @add.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @keyframeAdded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已添加关键 H 帧'**
  String get keyframeAdded;

  /// No description provided for @keyframeTooClose.
  ///
  /// In zh_CN, this message translates to:
  /// **'与已有关键帧间隔不足 10 秒'**
  String get keyframeTooClose;

  /// No description provided for @longPressAddKeyframe.
  ///
  /// In zh_CN, this message translates to:
  /// **'长按添加关键 H 帧'**
  String get longPressAddKeyframe;

  /// No description provided for @keyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键 H 帧'**
  String get keyframes;

  /// No description provided for @deleteCurrentVideoKeyframes.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除当前影片的全部关键 H 帧'**
  String get deleteCurrentVideoKeyframes;

  /// No description provided for @deleteCurrentVideoKeyframesConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除当前影片的全部关键 H 帧？'**
  String get deleteCurrentVideoKeyframesConfirmation;

  /// No description provided for @editKeyframe.
  ///
  /// In zh_CN, this message translates to:
  /// **'修改关键 H 帧'**
  String get editKeyframe;

  /// No description provided for @keyframeCountdown.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键 H 帧还有 {seconds} 秒'**
  String keyframeCountdown(Object seconds);

  /// No description provided for @episodeList.
  ///
  /// In zh_CN, this message translates to:
  /// **'剧集列表'**
  String get episodeList;

  /// No description provided for @seriesVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'系列影片'**
  String get seriesVideos;

  /// No description provided for @relatedVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'相关推荐'**
  String get relatedVideos;

  /// No description provided for @studio.
  ///
  /// In zh_CN, this message translates to:
  /// **'厂商'**
  String get studio;

  /// No description provided for @subscribed.
  ///
  /// In zh_CN, this message translates to:
  /// **'已订阅'**
  String get subscribed;

  /// No description provided for @subscribe.
  ///
  /// In zh_CN, this message translates to:
  /// **'订阅'**
  String get subscribe;

  /// No description provided for @favorite.
  ///
  /// In zh_CN, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @download.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @share.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @selectDownloadQuality.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择下载清晰度'**
  String get selectDownloadQuality;

  /// No description provided for @startDownload.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始下载'**
  String get startDownload;

  /// No description provided for @addedToDownloadQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加入下载队列'**
  String get addedToDownloadQueue;

  /// No description provided for @collapse.
  ///
  /// In zh_CN, this message translates to:
  /// **'收起'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In zh_CN, this message translates to:
  /// **'展开'**
  String get expand;

  /// No description provided for @description.
  ///
  /// In zh_CN, this message translates to:
  /// **'简介'**
  String get description;

  /// No description provided for @commentsLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论加载失败'**
  String get commentsLoadFailed;

  /// No description provided for @keyframeCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 个关键帧'**
  String keyframeCount(int count);

  /// No description provided for @themeMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @followSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @light.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色'**
  String get dark;

  /// No description provided for @themeColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题色'**
  String get themeColor;

  /// No description provided for @rose.
  ///
  /// In zh_CN, this message translates to:
  /// **'玫红'**
  String get rose;

  /// No description provided for @blue.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝色'**
  String get blue;

  /// No description provided for @teal.
  ///
  /// In zh_CN, this message translates to:
  /// **'青绿'**
  String get teal;

  /// No description provided for @amber.
  ///
  /// In zh_CN, this message translates to:
  /// **'琥珀'**
  String get amber;

  /// No description provided for @forestGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'森林绿'**
  String get forestGreen;

  /// No description provided for @orange.
  ///
  /// In zh_CN, this message translates to:
  /// **'橙色'**
  String get orange;

  /// No description provided for @indigo.
  ///
  /// In zh_CN, this message translates to:
  /// **'靛蓝'**
  String get indigo;

  /// No description provided for @pink.
  ///
  /// In zh_CN, this message translates to:
  /// **'粉色'**
  String get pink;

  /// No description provided for @purple.
  ///
  /// In zh_CN, this message translates to:
  /// **'紫色'**
  String get purple;

  /// No description provided for @keyframeSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'管理开关及各影片的关键 H 帧'**
  String get keyframeSettingsDescription;

  /// No description provided for @latestVersion.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前已是最新版本'**
  String get latestVersion;

  /// No description provided for @newVersionAvailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现新版本 {version}'**
  String newVersionAvailable(Object version);

  /// No description provided for @newVersionReleased.
  ///
  /// In zh_CN, this message translates to:
  /// **'已发布新版本。'**
  String get newVersionReleased;

  /// No description provided for @later.
  ///
  /// In zh_CN, this message translates to:
  /// **'稍后'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'现在更新'**
  String get updateNow;

  /// No description provided for @noInstallableApk.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前版本没有可安装的 APK 文件'**
  String get noInstallableApk;

  /// No description provided for @updateIncomplete.
  ///
  /// In zh_CN, this message translates to:
  /// **'更新未完成'**
  String get updateIncomplete;

  /// No description provided for @downloadingUpdate.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在下载更新'**
  String get downloadingUpdate;

  /// No description provided for @connecting.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在连接...'**
  String get connecting;

  /// No description provided for @updateFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'更新失败：{error}'**
  String updateFailed(Object error);

  /// No description provided for @close.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @monetColors.
  ///
  /// In zh_CN, this message translates to:
  /// **'莫奈取色'**
  String get monetColors;

  /// No description provided for @monetColorsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用系统壁纸动态配色'**
  String get monetColorsDescription;

  /// No description provided for @downloadSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载设置'**
  String get downloadSettings;

  /// No description provided for @downloadSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'速度与并发下载限制'**
  String get downloadSettingsDescription;

  /// No description provided for @downloadSpeedLimit.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载速度限制'**
  String get downloadSpeedLimit;

  /// No description provided for @unlimited.
  ///
  /// In zh_CN, this message translates to:
  /// **'不限速'**
  String get unlimited;

  /// No description provided for @concurrentDownloads.
  ///
  /// In zh_CN, this message translates to:
  /// **'同时下载数量限制'**
  String get concurrentDownloads;

  /// No description provided for @concurrentDownloadsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'同时下载 {count} 个影片'**
  String concurrentDownloadsDescription(int count);

  /// No description provided for @downloadPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载路径'**
  String get downloadPath;

  /// No description provided for @defaultDownloadPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'/storage/emulated/0/Android/data/com.liar.han1meplus/files/Download/'**
  String get defaultDownloadPath;

  /// No description provided for @exportDownloads.
  ///
  /// In zh_CN, this message translates to:
  /// **'导出下载项'**
  String get exportDownloads;

  /// No description provided for @exportDownloadsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'将私有下载目录中的所有已下载项目导出到自定义目录'**
  String get exportDownloadsDescription;

  /// No description provided for @exportCompleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载项已导出'**
  String get exportCompleted;

  /// No description provided for @amoledMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'AMOLED 模式'**
  String get amoledMode;

  /// No description provided for @amoledModeDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色主题使用纯黑背景'**
  String get amoledModeDescription;

  /// No description provided for @watchHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'观看历史'**
  String get watchHistory;

  /// No description provided for @playlists.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放清单'**
  String get playlists;

  /// No description provided for @noPlaylists.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无播放清单'**
  String get noPlaylists;

  /// No description provided for @deletePlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除播放清单'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定删除“{title}”吗？'**
  String deletePlaylistConfirmation(Object title);

  /// No description provided for @videoCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 部影片'**
  String videoCount(int count);

  /// No description provided for @loadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载失败：{error}'**
  String loadFailed(Object error);

  /// No description provided for @playlistEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放清单为空'**
  String get playlistEmpty;

  /// No description provided for @writeComment.
  ///
  /// In zh_CN, this message translates to:
  /// **'发表评论'**
  String get writeComment;

  /// No description provided for @commentHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入评论内容'**
  String get commentHint;

  /// No description provided for @latest.
  ///
  /// In zh_CN, this message translates to:
  /// **'最新'**
  String get latest;

  /// No description provided for @popular.
  ///
  /// In zh_CN, this message translates to:
  /// **'热门'**
  String get popular;

  /// No description provided for @oldest.
  ///
  /// In zh_CN, this message translates to:
  /// **'最早'**
  String get oldest;

  /// No description provided for @playlistCreatedBy.
  ///
  /// In zh_CN, this message translates to:
  /// **'由 {name} 建立'**
  String playlistCreatedBy(Object name);

  /// No description provided for @playlistStats.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放清单 • {count} 部影片 • 观看次数：{views} 次'**
  String playlistStats(int count, int views);

  /// No description provided for @playAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部播放'**
  String get playAll;

  /// No description provided for @earliest.
  ///
  /// In zh_CN, this message translates to:
  /// **'最早'**
  String get earliest;

  /// No description provided for @mostReplies.
  ///
  /// In zh_CN, this message translates to:
  /// **'回复最多'**
  String get mostReplies;

  /// No description provided for @mostLikes.
  ///
  /// In zh_CN, this message translates to:
  /// **'最多点赞'**
  String get mostLikes;

  /// No description provided for @mostDislikes.
  ///
  /// In zh_CN, this message translates to:
  /// **'最多点踩'**
  String get mostDislikes;

  /// No description provided for @viewReplies.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看回复'**
  String get viewReplies;

  /// No description provided for @viewRepliesCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看回复 ({count})'**
  String viewRepliesCount(int count);

  /// No description provided for @reply.
  ///
  /// In zh_CN, this message translates to:
  /// **'回复'**
  String get reply;

  /// No description provided for @replyComment.
  ///
  /// In zh_CN, this message translates to:
  /// **'回复评论'**
  String get replyComment;

  /// No description provided for @send.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @addToPlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'加入清单'**
  String get addToPlaylist;

  /// No description provided for @newPlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'新建播放清单'**
  String get newPlaylist;

  /// No description provided for @name.
  ///
  /// In zh_CN, this message translates to:
  /// **'名称'**
  String get name;

  /// No description provided for @create.
  ///
  /// In zh_CN, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @account.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In zh_CN, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要退出当前账号吗？'**
  String get logoutConfirmation;

  /// No description provided for @accountProfile.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户资料'**
  String get accountProfile;

  /// No description provided for @signedIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'已登录'**
  String get signedIn;

  /// No description provided for @signedOut.
  ///
  /// In zh_CN, this message translates to:
  /// **'未登录'**
  String get signedOut;

  /// No description provided for @accountSummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'@{id}\n{subscriberCount} 位订阅者 · {videoCount} 部影片\n{joined}'**
  String accountSummary(
      Object id, int subscriberCount, int videoCount, Object joined);

  /// No description provided for @tapToLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击前往登录'**
  String get tapToLogin;

  /// No description provided for @editProfile.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑个人资料'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In zh_CN, this message translates to:
  /// **'更改密码'**
  String get changePassword;

  /// No description provided for @username.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @email.
  ///
  /// In zh_CN, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @saveProfile.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存资料'**
  String get saveProfile;

  /// No description provided for @oldPassword.
  ///
  /// In zh_CN, this message translates to:
  /// **'旧密码'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In zh_CN, this message translates to:
  /// **'新密码'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In zh_CN, this message translates to:
  /// **'确认新密码'**
  String get confirmNewPassword;

  /// No description provided for @login.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @finishLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'完成登录'**
  String get finishLogin;

  /// No description provided for @genreAdultAnimation.
  ///
  /// In zh_CN, this message translates to:
  /// **'裏番'**
  String get genreAdultAnimation;

  /// No description provided for @genreShortAnimation.
  ///
  /// In zh_CN, this message translates to:
  /// **'泡麵番'**
  String get genreShortAnimation;

  /// No description provided for @genre2dAnimation.
  ///
  /// In zh_CN, this message translates to:
  /// **'2D動畫'**
  String get genre2dAnimation;

  /// No description provided for @genreAiGenerated.
  ///
  /// In zh_CN, this message translates to:
  /// **'AI生成'**
  String get genreAiGenerated;

  /// No description provided for @sortLatestRelease.
  ///
  /// In zh_CN, this message translates to:
  /// **'最新上市'**
  String get sortLatestRelease;

  /// No description provided for @sortLatestUpload.
  ///
  /// In zh_CN, this message translates to:
  /// **'最新上傳'**
  String get sortLatestUpload;

  /// No description provided for @sortTrending.
  ///
  /// In zh_CN, this message translates to:
  /// **'他們在看'**
  String get sortTrending;

  /// No description provided for @playbackSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放设置'**
  String get playbackSettings;

  /// No description provided for @playbackSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'倍数、长按倍数与控制器显示时间'**
  String get playbackSettingsDescription;

  /// No description provided for @defaultPlaybackSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认播放倍数'**
  String get defaultPlaybackSpeed;

  /// No description provided for @longPressPlaybackSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认长按倍数'**
  String get longPressPlaybackSpeed;

  /// No description provided for @playerControlsTimeout.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放控制器消失时间'**
  String get playerControlsTimeout;

  /// No description provided for @playerControlsTimeoutDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'不操作时自动隐藏播放控制器'**
  String get playerControlsTimeoutDescription;

  /// No description provided for @privacySettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'隐私设置'**
  String get privacySettings;

  /// No description provided for @appLock.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用应用锁定屏幕'**
  String get appLock;

  /// No description provided for @appLockDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启后，进入应用时需验证屏幕锁，防止别人打开'**
  String get appLockDescription;

  /// No description provided for @emergencyExit.
  ///
  /// In zh_CN, this message translates to:
  /// **'紧急状况'**
  String get emergencyExit;

  /// No description provided for @emergencyExitDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启后，应用内连续按三次音量上键会停止播放并返回桌面'**
  String get emergencyExitDescription;

  /// No description provided for @hideFromRecents.
  ///
  /// In zh_CN, this message translates to:
  /// **'从最近任务中隐藏'**
  String get hideFromRecents;

  /// No description provided for @hideFromRecentsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用在后台时，从最近任务中隐藏应用'**
  String get hideFromRecentsDescription;

  /// No description provided for @commentSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论设置'**
  String get commentSettings;

  /// No description provided for @enableComments.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用评论区'**
  String get enableComments;

  /// No description provided for @commentsDisabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论区已关闭'**
  String get commentsDisabled;

  /// No description provided for @commentKeywordFilter.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键词屏蔽'**
  String get commentKeywordFilter;

  /// No description provided for @commentKeywordFilterDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'包含关键词的评论不会显示'**
  String get commentKeywordFilterDescription;

  /// No description provided for @keyword.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键词'**
  String get keyword;

  /// No description provided for @deepLinkSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用深层链接设置'**
  String get deepLinkSettings;

  /// No description provided for @deepLinkSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开相关网页后能快速跳转至本 App'**
  String get deepLinkSettingsDescription;

  /// No description provided for @openAppLinkSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'管理网页链接'**
  String get openAppLinkSettings;

  /// No description provided for @openAppLinkSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'在系统设置中允许 Han1me+ 打开支持的链接'**
  String get openAppLinkSettingsDescription;

  /// No description provided for @playbackSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放倍数'**
  String get playbackSpeed;

  /// No description provided for @lockControls.
  ///
  /// In zh_CN, this message translates to:
  /// **'锁定播放面板'**
  String get lockControls;

  /// No description provided for @unlockControls.
  ///
  /// In zh_CN, this message translates to:
  /// **'解除播放面板锁定'**
  String get unlockControls;

  /// No description provided for @brightness.
  ///
  /// In zh_CN, this message translates to:
  /// **'亮度'**
  String get brightness;

  /// No description provided for @volume.
  ///
  /// In zh_CN, this message translates to:
  /// **'音量'**
  String get volume;

  /// No description provided for @comicMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'观看漫画'**
  String get comicMode;

  /// No description provided for @horizontalSearchCards.
  ///
  /// In zh_CN, this message translates to:
  /// **'横向影片卡片'**
  String get horizontalSearchCards;

  /// No description provided for @horizontalSearchCardsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'影片使用横向卡片显示'**
  String get horizontalSearchCardsDescription;

  /// No description provided for @expandHomeVideoCards.
  ///
  /// In zh_CN, this message translates to:
  /// **'展开首页影片卡片'**
  String get expandHomeVideoCards;

  /// No description provided for @expandHomeVideoCardsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭时首页每个分类横向显示一行影片；开启后使用影片卡片每行数量设置'**
  String get expandHomeVideoCardsDescription;

  /// No description provided for @searchCardsPerRow.
  ///
  /// In zh_CN, this message translates to:
  /// **'影片卡片每行数量'**
  String get searchCardsPerRow;

  /// No description provided for @searchCardsPerRowValue.
  ///
  /// In zh_CN, this message translates to:
  /// **'每行 {count} 个'**
  String searchCardsPerRowValue(int count);

  /// No description provided for @comicModeDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启后首页、收藏和缓存仅显示漫画内容'**
  String get comicModeDescription;

  /// No description provided for @comicBrowse.
  ///
  /// In zh_CN, this message translates to:
  /// **'漫画筛选'**
  String get comicBrowse;

  /// No description provided for @trendingComics.
  ///
  /// In zh_CN, this message translates to:
  /// **'发烧漫画'**
  String get trendingComics;

  /// No description provided for @latestComics.
  ///
  /// In zh_CN, this message translates to:
  /// **'最新上传'**
  String get latestComics;

  /// No description provided for @comicSearchUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'漫画不支持关键词搜索'**
  String get comicSearchUnavailable;

  /// No description provided for @comicDetails.
  ///
  /// In zh_CN, this message translates to:
  /// **'漫画详情'**
  String get comicDetails;

  /// No description provided for @read.
  ///
  /// In zh_CN, this message translates to:
  /// **'阅读'**
  String get read;

  /// No description provided for @pageCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 页'**
  String pageCount(int count);

  /// No description provided for @tags.
  ///
  /// In zh_CN, this message translates to:
  /// **'标签'**
  String get tags;

  /// No description provided for @chapter.
  ///
  /// In zh_CN, this message translates to:
  /// **'目录'**
  String get chapter;

  /// No description provided for @chapterOne.
  ///
  /// In zh_CN, this message translates to:
  /// **'第 1 章'**
  String get chapterOne;

  /// No description provided for @addToLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加到收藏'**
  String get addToLibrary;

  /// No description provided for @cacheComicConfirmation.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定缓存整本漫画吗？'**
  String get cacheComicConfirmation;

  /// No description provided for @info.
  ///
  /// In zh_CN, this message translates to:
  /// **'信息'**
  String get info;

  /// No description provided for @noComics.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无漫画'**
  String get noComics;

  /// No description provided for @pageNumber.
  ///
  /// In zh_CN, this message translates to:
  /// **'页码'**
  String get pageNumber;

  /// No description provided for @readingMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'阅读模式'**
  String get readingMode;

  /// No description provided for @general.
  ///
  /// In zh_CN, this message translates to:
  /// **'常规'**
  String get general;

  /// No description provided for @leftToRight.
  ///
  /// In zh_CN, this message translates to:
  /// **'单页式（从左到右）'**
  String get leftToRight;

  /// No description provided for @rightToLeft.
  ///
  /// In zh_CN, this message translates to:
  /// **'单页式（从右到左）'**
  String get rightToLeft;

  /// No description provided for @topToBottom.
  ///
  /// In zh_CN, this message translates to:
  /// **'单页式（从上到下）'**
  String get topToBottom;

  /// No description provided for @scroll.
  ///
  /// In zh_CN, this message translates to:
  /// **'条漫'**
  String get scroll;

  /// No description provided for @scrollGap.
  ///
  /// In zh_CN, this message translates to:
  /// **'条漫（页间有空隙）'**
  String get scrollGap;

  /// No description provided for @black.
  ///
  /// In zh_CN, this message translates to:
  /// **'黑色'**
  String get black;

  /// No description provided for @gray.
  ///
  /// In zh_CN, this message translates to:
  /// **'灰色'**
  String get gray;

  /// No description provided for @white.
  ///
  /// In zh_CN, this message translates to:
  /// **'白色'**
  String get white;

  /// No description provided for @cacheCategory.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存分类'**
  String get cacheCategory;

  /// No description provided for @newCategory.
  ///
  /// In zh_CN, this message translates to:
  /// **'新分类'**
  String get newCategory;

  /// No description provided for @danmakuHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'发弹幕'**
  String get danmakuHint;

  /// No description provided for @sendDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送弹幕'**
  String get sendDanmaku;

  /// No description provided for @danmakuContentHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入发送的弹幕内容'**
  String get danmakuContentHint;

  /// No description provided for @danmakuSubmitted.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕已发送'**
  String get danmakuSubmitted;

  /// No description provided for @danmakuSubmitFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕发送失败，请稍后重试'**
  String get danmakuSubmitFailed;

  /// No description provided for @danmakuSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕设置'**
  String get danmakuSettings;

  /// No description provided for @danmakuSettingsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示、屏蔽与播放同步'**
  String get danmakuSettingsDescription;

  /// No description provided for @enableDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用弹幕'**
  String get enableDanmaku;

  /// No description provided for @enableDanmakuDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'在播放器中显示弹幕'**
  String get enableDanmakuDescription;

  /// No description provided for @danmakuKeywordFilter.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕关键词屏蔽'**
  String get danmakuKeywordFilter;

  /// No description provided for @danmakuKeywordFilterDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'包含关键词的弹幕不会显示'**
  String get danmakuKeywordFilterDescription;

  /// No description provided for @danmakuFollowsPlaybackSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕跟随视频倍速'**
  String get danmakuFollowsPlaybackSpeed;

  /// No description provided for @danmakuFollowsPlaybackSpeedDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频倍速改变时同步调整弹幕速度'**
  String get danmakuFollowsPlaybackSpeedDescription;

  /// No description provided for @showDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示弹幕'**
  String get showDanmaku;

  /// No description provided for @hideDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'隐藏弹幕'**
  String get hideDanmaku;

  /// No description provided for @navigationDrawer.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用导航抽屉'**
  String get navigationDrawer;

  /// No description provided for @navigationDrawerDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用抽屉替代底部导航栏'**
  String get navigationDrawerDescription;

  /// No description provided for @home.
  ///
  /// In zh_CN, this message translates to:
  /// **'主页'**
  String get home;

  /// No description provided for @seekSensitivity.
  ///
  /// In zh_CN, this message translates to:
  /// **'进度滑动灵敏度'**
  String get seekSensitivity;

  /// No description provided for @seekSensitivityDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'调低可减少左右滑动时的跳转幅度'**
  String get seekSensitivityDescription;

  /// No description provided for @seekSensitivityValue.
  ///
  /// In zh_CN, this message translates to:
  /// **'{value}%'**
  String seekSensitivityValue(int value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
