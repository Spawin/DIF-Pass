import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // ponytail: prevents google_fonts from making network requests; without
  // bundled font assets this means the DIF typography silently falls back
  // to the system font offline instead of the app trying (and failing) to
  // fetch it. TODO(jalon 8 or before store release): bundle Big Shoulders,
  // IBM Plex Sans, and IBM Plex Mono as local assets and remove this line.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: DifPassApp()));
}

class DifPassApp extends StatelessWidget {
  const DifPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DIF Pass',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
