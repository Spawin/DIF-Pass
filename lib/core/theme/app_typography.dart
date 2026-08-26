import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildAppTextTheme(ColorScheme colorScheme) {
  final base = ThemeData(colorScheme: colorScheme).textTheme;
  final display = GoogleFonts.bigShouldersTextTheme(base);
  final body = GoogleFonts.ibmPlexSansTextTheme(base);

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
  return GoogleFonts.ibmPlexMono(color: colorScheme.onSurface);
}
