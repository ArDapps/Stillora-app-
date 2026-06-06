import 'package:flutter/material.dart';

import '../core/design/stillora_colors.dart';
import '../core/design/stillora_spacing.dart';

ThemeData buildStilloraTheme(Brightness brightness) {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: StilloraColors.primary,
    onPrimary: StilloraColors.onPrimary,
    primaryContainer: StilloraColors.primaryContainer,
    onPrimaryContainer: StilloraColors.onPrimaryContainer,
    secondary: StilloraColors.secondary,
    onSecondary: StilloraColors.onSecondary,
    secondaryContainer: StilloraColors.secondaryContainer,
    onSecondaryContainer: StilloraColors.onSecondaryContainer,
    tertiary: StilloraColors.tertiary,
    onTertiary: StilloraColors.onTertiary,
    tertiaryContainer: StilloraColors.tertiaryContainer,
    onTertiaryContainer: StilloraColors.onTertiaryContainer,
    error: StilloraColors.error,
    onError: StilloraColors.onError,
    errorContainer: StilloraColors.errorContainer,
    onErrorContainer: StilloraColors.onErrorContainer,
    surface: StilloraColors.surface,
    onSurface: StilloraColors.onSurface,
    surfaceContainerLowest: StilloraColors.surfaceContainerLowest,
    surfaceContainerLow: StilloraColors.surfaceContainerLow,
    surfaceContainer: StilloraColors.surfaceContainer,
    surfaceContainerHigh: StilloraColors.surfaceContainerHigh,
    surfaceContainerHighest: StilloraColors.surfaceContainerHighest,
    onSurfaceVariant: StilloraColors.onSurfaceVariant,
    outline: StilloraColors.outline,
    outlineVariant: StilloraColors.outlineVariant,
    inverseSurface: StilloraColors.inverseSurface,
    onInverseSurface: StilloraColors.inverseOnSurface,
    inversePrimary: StilloraColors.inversePrimary,
  );

  return ThemeData(
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    fontFamily: 'Geist',
    useMaterial3: true,
    scaffoldBackgroundColor: StilloraColors.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: StilloraColors.surfaceDim,
      foregroundColor: StilloraColors.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: StilloraColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(StilloraRadius.full)),
        side: BorderSide(color: StilloraColors.glassStroke),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: StilloraColors.primary,
        foregroundColor: StilloraColors.onPrimary,
        disabledBackgroundColor: StilloraColors.surfaceContainerHigh,
        disabledForegroundColor: StilloraColors.onSurfaceVariant,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StilloraRadius.full),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StilloraColors.primary,
        side: const BorderSide(color: StilloraColors.primary),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StilloraRadius.full),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: StilloraColors.surfaceContainerHigh,
        selectedBackgroundColor: StilloraColors.primaryContainer,
        selectedForegroundColor: StilloraColors.onPrimaryContainer,
        foregroundColor: StilloraColors.onSurfaceVariant,
        side: const BorderSide(color: StilloraColors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StilloraRadius.xl),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: StilloraColors.surfaceDim.withValues(alpha: 0.94),
      indicatorColor: StilloraColors.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected
              ? StilloraColors.onPrimaryContainer
              : StilloraColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? StilloraColors.onPrimaryContainer
              : StilloraColors.onSurfaceVariant,
        );
      }),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: StilloraColors.primary,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: StilloraColors.primaryContainer,
      inactiveTrackColor: StilloraColors.surfaceContainerHigh,
      thumbColor: Colors.white,
      overlayColor: StilloraColors.primaryGlow,
      valueIndicatorColor: StilloraColors.primaryContainer,
      valueIndicatorTextStyle: const TextStyle(
        color: StilloraColors.onPrimaryContainer,
        fontWeight: FontWeight.w700,
      ),
      trackHeight: 5,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: StilloraColors.surfaceContainerHigh,
      selectedColor: StilloraColors.primaryContainer,
      labelStyle: TextStyle(color: StilloraColors.onSurfaceVariant),
      side: BorderSide(color: StilloraColors.outlineVariant),
      shape: StadiumBorder(),
    ),
    textTheme:
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 56,
            height: 64 / 56,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            fontSize: 40,
            height: 48 / 40,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
          ),
        ).apply(
          bodyColor: StilloraColors.onSurface,
          displayColor: StilloraColors.onSurface,
        ),
  );
}
