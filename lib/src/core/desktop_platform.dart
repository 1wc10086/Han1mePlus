import 'dart:io';

bool get isDesktopHttpPlatform => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool get isDesktopPlatformService => isDesktopHttpPlatform;
