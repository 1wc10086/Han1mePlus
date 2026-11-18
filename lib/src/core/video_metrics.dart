import 'package:video_player/video_player.dart';

const double portraitVideoThreshold = 1.0;

const double portraitPlayerViewportFraction = 0.46;

const double portraitPlayerMinHeight = 180.0;

const double portraitPlayerMaxDp = 380.0;

double videoAspectRatio(VideoPlayerValue value) {
  final width = value.size.width;
  final height = value.size.height;
  if (width > 0 && height > 0) {
    final ratio = width / height;
    if (ratio.isFinite && ratio >= .1 && ratio <= 10) return ratio;
  }
  final fallback = value.aspectRatio;
  if (fallback.isFinite && fallback >= .1 && fallback <= 10) return fallback;
  return 16 / 9;
}

bool isPortraitVideoAspectRatio(double ratio) => ratio < portraitVideoThreshold;

bool isPortraitVideo(VideoPlayerValue value) => isPortraitVideoAspectRatio(videoAspectRatio(value));

double playerHeightLimit(double viewportHeight) {
  final fraction = viewportHeight * portraitPlayerViewportFraction;
  final limit = fraction > portraitPlayerMaxDp ? portraitPlayerMaxDp : fraction;
  return limit < portraitPlayerMinHeight ? portraitPlayerMinHeight : limit;
}
