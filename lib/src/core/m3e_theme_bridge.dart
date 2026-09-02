import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as modern;

class M3EThemeBridge extends StatelessWidget {
  const M3EThemeBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return modern.Theme(data: _toModern(Theme.of(context)), child: child);
  }

  modern.ThemeData _toModern(ThemeData theme) {
    final source = theme.colorScheme;
    final text = theme.textTheme;
    return modern.ThemeData(
      useMaterial3: true,
      platform: theme.platform,
      visualDensity: modern.VisualDensity(
        horizontal: theme.visualDensity.horizontal,
        vertical: theme.visualDensity.vertical,
      ),
      textTheme: modern.TextTheme(
        displayLarge: text.displayLarge,
        displayMedium: text.displayMedium,
        displaySmall: text.displaySmall,
        headlineLarge: text.headlineLarge,
        headlineMedium: text.headlineMedium,
        headlineSmall: text.headlineSmall,
        titleLarge: text.titleLarge,
        titleMedium: text.titleMedium,
        titleSmall: text.titleSmall,
        bodyLarge: text.bodyLarge,
        bodyMedium: text.bodyMedium,
        bodySmall: text.bodySmall,
        labelLarge: text.labelLarge,
        labelMedium: text.labelMedium,
        labelSmall: text.labelSmall,
      ),
      colorScheme: modern.ColorScheme.fromSeed(
        seedColor: source.primary,
        brightness: source.brightness,
        primary: source.primary,
        onPrimary: source.onPrimary,
        primaryContainer: source.primaryContainer,
        onPrimaryContainer: source.onPrimaryContainer,
        primaryFixed: source.primaryFixed,
        primaryFixedDim: source.primaryFixedDim,
        onPrimaryFixed: source.onPrimaryFixed,
        onPrimaryFixedVariant: source.onPrimaryFixedVariant,
        secondary: source.secondary,
        onSecondary: source.onSecondary,
        secondaryContainer: source.secondaryContainer,
        onSecondaryContainer: source.onSecondaryContainer,
        secondaryFixed: source.secondaryFixed,
        secondaryFixedDim: source.secondaryFixedDim,
        onSecondaryFixed: source.onSecondaryFixed,
        onSecondaryFixedVariant: source.onSecondaryFixedVariant,
        tertiary: source.tertiary,
        onTertiary: source.onTertiary,
        tertiaryContainer: source.tertiaryContainer,
        onTertiaryContainer: source.onTertiaryContainer,
        tertiaryFixed: source.tertiaryFixed,
        tertiaryFixedDim: source.tertiaryFixedDim,
        onTertiaryFixed: source.onTertiaryFixed,
        onTertiaryFixedVariant: source.onTertiaryFixedVariant,
        error: source.error,
        onError: source.onError,
        errorContainer: source.errorContainer,
        onErrorContainer: source.onErrorContainer,
        outline: source.outline,
        outlineVariant: source.outlineVariant,
        surface: source.surface,
        onSurface: source.onSurface,
        surfaceDim: source.surfaceDim,
        surfaceBright: source.surfaceBright,
        surfaceContainerLowest: source.surfaceContainerLowest,
        surfaceContainerLow: source.surfaceContainerLow,
        surfaceContainer: source.surfaceContainer,
        surfaceContainerHigh: source.surfaceContainerHigh,
        surfaceContainerHighest: source.surfaceContainerHighest,
        onSurfaceVariant: source.onSurfaceVariant,
        inverseSurface: source.inverseSurface,
        onInverseSurface: source.onInverseSurface,
        inversePrimary: source.inversePrimary,
        shadow: source.shadow,
        scrim: source.scrim,
        surfaceTint: source.surfaceTint,
      ),
    );
  }
}
