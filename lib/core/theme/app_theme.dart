import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

// Matches the design bundle's buttons (rounded rectangles, not the M3
// default stadium/pill shape) and its "Compact / Standard / Elegant"-style
// segmented control (docs/design_handoff_ticket_redesign).
const _buttonRadius = 10.0;
const _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
);
const _buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 20);
const _fieldRadius = 4.0;

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: Brightness.light,
    primary: AppColors.indigo,
    secondary: AppColors.teal,
    tertiary: AppColors.ochre,
    onTertiary: AppColors.ink,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: buildAppTextTheme(colorScheme),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: _buttonShape,
        padding: _buttonPadding,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _buttonShape,
        padding: _buttonPadding,
        side: const BorderSide(color: AppColors.indigo, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: _buttonShape,
        padding: _buttonPadding,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: _buttonShape),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_buttonRadius - 2)),
          ),
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.indigo
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.ink.withValues(alpha: 0.55),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: AppColors.ink.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.teal.withValues(alpha: 0.12),
      labelStyle: const TextStyle(
        color: AppColors.teal,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelStyle: const TextStyle(color: AppColors.indigo),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppColors.indigo, width: 2),
      ),
    ),
  );
}
