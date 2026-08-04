import 'dart:io';

bool get isDesktopHttpPlatform => Platform.isWindows || Platform.isMacOS;

bool get isDesktopPlatformService => isDesktopHttpPlatform;
