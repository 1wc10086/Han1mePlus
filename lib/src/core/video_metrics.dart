import 'package:video_player/video_player.dart';

double videoAspectRatio(VideoPlayerValue value) {
  final width = value.size.width;
  final height = value.size.height;
  if (width <= 0 || height <= 0) return 16 / 9;
  final ratio = width / height;
  if (!ratio.isFinite || ratio < 0.1 || ratio > 10) return 16 / 9;
  return ratio;
}
