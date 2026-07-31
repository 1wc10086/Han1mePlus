import 'dart:io';

/// 使用纯 Dart HTTP 栈的桌面平台（与 Windows 共用实现）。
bool get isDesktopHttpPlatform => Platform.isWindows || Platform.isMacOS;

/// 桌面端跳过移动端原生 PlatformService 能力。
bool get isDesktopPlatformService => isDesktopHttpPlatform;
