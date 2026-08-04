import 'dart:async';

import 'package:video_player/video_player.dart';

class VideoPlayerShutdown {
  VideoPlayerShutdown._();

  static final _controllers = <VideoPlayerController>{};

  static void track(VideoPlayerController controller) => _controllers.add(controller);

  static void untrack(VideoPlayerController controller) => _controllers.remove(controller);

  static Future<void> pauseAllExcept(VideoPlayerController keep) async {
    final controllers = _controllers.toList(growable: false);
    for (final controller in controllers) {
      if (identical(controller, keep)) continue;
      try {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          await controller.pause().timeout(const Duration(seconds: 1));
        }
      } catch (_) {}
    }
  }
}
