import 'dart:ui';

import 'package:flutter/material.dart';

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
      return child;
    }
    return super.buildScrollbar(context, child, details);
  }
}
