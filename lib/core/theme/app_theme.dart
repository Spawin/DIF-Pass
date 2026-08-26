import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

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
  );
}
