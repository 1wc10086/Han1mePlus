import 'dart:ui';

import 'package:flutter/material.dart';

const horizontalScrollbarGutter = 6.0;

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (details.direction == AxisDirection.left ||
        details.direction == AxisDirection.right) {
      if (details.controller == null) return child;
      return Scrollbar(
        controller: details.controller,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        thumbVisibility: false,
        trackVisibility: false,
        interactive: true,
        thickness: 3,
        radius: Radius.zero,
        child: child,
      );
    }
    return super.buildScrollbar(context, child, details);
  }
}
