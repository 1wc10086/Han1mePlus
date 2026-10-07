import 'package:flutter/material.dart';

class SettingsSurface extends StatelessWidget {
  const SettingsSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.light) return child;
    final cardColor = theme.cardTheme.color;
    final resolved = cardColor == null
        ? theme.colorScheme.surfaceContainerLow
        : cardColor is WidgetStateColor
            ? cardColor.resolve(const <WidgetState>{})
            : cardColor;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(surfaceContainerLowest: resolved),
      ),
      child: child,
    );
  }
}