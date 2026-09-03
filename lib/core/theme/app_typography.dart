import 'package:flutter/material.dart';

TextTheme buildAppTextTheme(ColorScheme colorScheme) {
  final base = ThemeData(colorScheme: colorScheme).textTheme;
  final display = base.apply(fontFamily: 'BigShouldersDisplay');
  final body = base.apply(fontFamily: 'IBMPlexSans');

  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge,
    headlineMedium: display.headlineMedium,
    headlineSmall: display.headlineSmall,
    titleLarge: display.titleLarge,
  );
}

// Used for ticket identifiers, live counters, and other data-like text.
TextStyle ticketMonoStyle(ColorScheme colorScheme) {
  return TextStyle(fontFamily: 'IBMPlexMono', color: colorScheme.onSurface);
}
