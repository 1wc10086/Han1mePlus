import 'dart:async';

import 'package:video_player/video_player.dart';

/// 跟踪活动中的 [VideoPlayerController]，在桌面端退出前先暂停并释放，
/// 避免 libmpv FFI 回调在 isolate 销毁后触发导致崩溃。
class VideoPlayerShutdown {
  VideoPlayerShutdown._();

  static final _controllers = <VideoPlayerController>{};

  static void track(VideoPlayerController controller) => _controllers.add(controller);

  static void untrack(VideoPlayerController controller) => _controllers.remove(controller);

  static Future<void> shutdownAll() async {
    if (_controllers.isEmpty) return;
    final controllers = _controllers.toList(growable: false);
    _controllers.clear();
    for (final controller in controllers) {
      await _shutdown(controller);
    }
  }

  static Future<void> _shutdown(VideoPlayerController controller) async {
    try {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        await controller.pause();
        await Future<void>.delayed(const Duration(milliseconds: 64));
      }
    } catch (_) {}
    try {
      await controller.dispose().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
