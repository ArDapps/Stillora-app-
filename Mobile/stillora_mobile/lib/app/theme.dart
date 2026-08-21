import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/stillora_colors.dart';
import '../core/design/stillora_spacing.dart';
import '../core/i18n/app_locale.dart';

ThemeData buildStilloraTheme(
  Brightness brightness, [
  AppLanguage language = AppLanguage.english,
]) => buildStilloraThemeFor(
  StilloraPalette.forBrightness(brightness),
  fontFamily: language.fontFamily,
);

/// Builds the app theme from an explicit [palette].
///
/// This deliberately reads `palette.x` rather than the ambient
/// `StilloraColors.x`: `MaterialApp` builds *both* the light and the dark
/// `ThemeData` up front, so during one of those two calls the ambient palette
/// is the wrong one.
ThemeData buildStilloraThemeFor(
  StilloraPalette palette, {
  String fontFamily = 'Geist',
}) {
  final isDark = palette.isDark;

  final colorScheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    primaryContainer: palette.primaryContainer,
    onPrimaryContainer: palette.onPrimaryContainer,
    secondary: palette.secondary,
    onSecondary: palette.onSecondary,
    secondaryContainer: palette.secondaryContainer,
    onSecondaryContainer: palette.onSecondaryContainer,
    tertiary: palette.tertiary,
    onTertiary: palette.onTertiary,
    tertiaryContainer: palette.tertiaryContainer,
    onTertiaryContainer: palette.onTertiaryContainer,
    error: palette.error,
    onError: palette.onError,
    errorContainer: palette.errorContainer,
    onErrorContainer: palette.onErrorContainer,
    surface: palette.surface,
    onSurface: palette.onSurface,
    surfaceContainerLowest: palette.surfaceContainerLowest,
    surfaceContainerLow: palette.surfaceContainerLow,
    surfaceContainer: palette.surfaceContainer,
    surfaceContainerHigh: palette.surfaceContainerHigh,
    surfaceContainerHighest: palette.surfaceContainerHighest,
    onSurfaceVariant: palette.onSurfaceVariant,
    outline: palette.outline,
    outlineVariant: palette.outlineVariant,
    inverseSurface: palette.inverseSurface,
    onInverseSurface: palette.inverseOnSurface,
    inversePrimary: palette.inversePrimary,
  );

  return ThemeData(
    colorScheme: colorScheme,
    brightness: palette.brightness,
    fontFamily: fontFamily,
    useMaterial3: true,
    scaffoldBackgroundColor: palette.surface,
    canvasColor: palette.surface,
    dividerColor: palette.glassStroke,
    dividerTheme: DividerThemeData(
      color: palette.glassStroke,
      space: 1,
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: palette.surfaceDim,
      foregroundColor: palette.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      // Keep the iOS status bar legible against the app bar in both palettes.
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: palette.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(StilloraRadius.full),
        ),
        side: BorderSide(color: palette.glassStroke),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        disabledBackgroundColor: palette.surfaceContainerHigh,
        disabledForegroundColor: palette.onSurfaceVariant,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StilloraRadius.full),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primary,
        side: BorderSide(color: palette.primary),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StilloraRadius.full),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.primary),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: palette.surfaceContainerHigh,
        selectedBackgroundColor: palette.primaryContainer,
        selectedForegroundColor: palette.onPrimaryContainer,
        foregroundColor: palette.onSurfaceVariant,
        side: BorderSide(color: palette.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StilloraRadius.xl),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surfaceDim.withValues(alpha: 0.94),
      indicatorColor: palette.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected
              ? palette.onPrimaryContainer
              : palette.onSurfaceVariant,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? palette.onPrimaryContainer
              : palette.onSurfaceVariant,
        );
      }),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: palette.surfaceDim),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.primary,
      textColor: palette.onSurface,
      subtitleTextStyle: TextStyle(
        color: palette.onSurfaceVariant,
        fontSize: 14,
        height: 20 / 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.onPrimary
            : palette.onSurfaceVariant,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.surfaceContainerHigh,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.surfaceContainerHigh,
      circularTrackColor: palette.surfaceContainerHigh,
    ),
    sliderTheme: SliderThemeData(
      // Consistent violet brand slider: violet active track, faded-violet
      // inactive track, and a violet thumb.
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.accent.withValues(alpha: 0.24),
      thumbColor: palette.accent,
      overlayColor: palette.accent.withValues(alpha: 0.18),
      valueIndicatorColor: palette.accent,
      valueIndicatorTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      trackHeight: 5,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceContainerHigh,
      selectedColor: palette.primaryContainer,
      labelStyle: TextStyle(color: palette.onSurfaceVariant),
      side: BorderSide(color: palette.outlineVariant),
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceContainerHigh,
      hintStyle: TextStyle(color: palette.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StilloraRadius.md),
        borderSide: BorderSide(color: palette.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StilloraRadius.md),
        borderSide: BorderSide(color: palette.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StilloraRadius.md),
        borderSide: BorderSide(color: palette.accent, width: 2),
      ),
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
          bodyColor: palette.onSurface,
          displayColor: palette.onSurface,
        ),
  );
}

/// Keeps the ambient [StilloraColors] palette pointed at whichever theme
/// `MaterialApp` resolved, and re-runs every build method when that flips.
///
/// The design tokens are read as plain statics from ~80 files, so they are not
/// an inherited dependency — a theme change alone would leave those widgets
/// holding stale colours. Marking the tree dirty once per switch is what makes
/// the toggle take effect everywhere without threading a `BuildContext` through
/// every token lookup.
class StilloraPaletteScope extends StatefulWidget {
  const StilloraPaletteScope({super.key, required this.child});

  final Widget child;

  @override
  State<StilloraPaletteScope> createState() => _StilloraPaletteScopeState();
}

class _StilloraPaletteScopeState extends State<StilloraPaletteScope> {
  bool _rebuildScheduled = false;

  @override
  Widget build(BuildContext context) {
    final palette = StilloraPalette.forBrightness(
      Theme.of(context).brightness,
    );
    if (StilloraColors.activate(palette) && !_rebuildScheduled) {
      // Can't mark the tree dirty mid-build; do it as soon as this frame ends.
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        _markTreeDirty();
      });
    }
    return widget.child;
  }

  static void _markTreeDirty() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root != null) visit(root);
  }
}
