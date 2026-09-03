import 'package:dif_pass/core/theme/app_colors.dart';
import 'package:dif_pass/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: Brightness.light,
  );

  test('display and headline slots use Big Shoulders Display', () {
    final textTheme = buildAppTextTheme(colorScheme);

    for (final style in [
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
    ]) {
      expect(style!.fontFamily, 'BigShouldersDisplay');
    }
  });

  test('body and label slots use IBM Plex Sans', () {
    final textTheme = buildAppTextTheme(colorScheme);

    for (final style in [
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.titleMedium,
    ]) {
      expect(style!.fontFamily, 'IBMPlexSans');
    }
  });

  test('ticketMonoStyle uses IBM Plex Mono', () {
    final style = ticketMonoStyle(colorScheme);

    expect(style.fontFamily, 'IBMPlexMono');
    expect(style.color, colorScheme.onSurface);
  });
}
