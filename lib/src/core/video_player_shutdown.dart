import 'dart:async';

import 'package:video_player/video_player.dart';

class VideoPlayerShutdown {
  VideoPlayerShutdown._();

  static final _controllers = <VideoPlayerController>{};
  static VideoPlayerController? pipActive;

  static void track(VideoPlayerController controller) => _controllers.add(controller);

  static void untrack(VideoPlayerController controller) => _controllers.remove(controller);

  static Future<void> pauseAllExcept(VideoPlayerController keep) => pauseAll(except: keep);

  static Future<void> pauseAllExceptPip() => pauseAll(skipPip: true);

  static Future<void> pauseAll({VideoPlayerController? except, bool skipPip = false}) async {
    final controllers = _controllers.toList(growable: false);
    for (final controller in controllers) {
      if (identical(controller, except)) continue;
      if (skipPip && identical(controller, pipActive)) continue;
      try {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          await controller.pause().timeout(const Duration(milliseconds: 800));
        }
      } catch (_) {}
    }
  }
}