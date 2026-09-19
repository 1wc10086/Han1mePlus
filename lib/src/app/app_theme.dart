import 'package:flutter/material.dart';

import '../core/settings.dart';

ThemeData appTheme(ColorScheme? dynamicScheme, Color seedColor, {Brightness brightness = Brightness.light, bool amoled = false}) {
  var scheme = dynamicScheme ?? ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  if (amoled) {
    scheme = scheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: Colors.black,
      surfaceContainer: Colors.black,
      surfaceContainerHigh: Colors.black,
      surfaceContainerHighest: Colors.black,
    );
  }
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: amoled ? Colors.black : null,
    canvasColor: amoled ? Colors.black : null,
    sliderTheme: const SliderThemeData(year2023: false),
  );
}

extension AppThemeColorSeed on AppThemeColor {
  Color seedColor(String customColor) => switch (this) {
        AppThemeColor.rose => const Color(0xffb3265a),
        AppThemeColor.blue => const Color(0xff00639b),
        AppThemeColor.teal => const Color(0xff006b5f),
        AppThemeColor.amber => const Color(0xff875400),
        AppThemeColor.green => const Color(0xff386a20),
        AppThemeColor.orange => const Color(0xff9b4400),
        AppThemeColor.indigo => const Color(0xff4a5f9e),
        AppThemeColor.pink => const Color(0xff9c3c66),
        AppThemeColor.purple => const Color(0xff6d3f90),
        AppThemeColor.custom => Color(int.parse('ff$customColor', radix: 16)),
      };
}
