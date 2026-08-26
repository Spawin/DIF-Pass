import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'AppLocalizations exposes French and English copy from the ARB files',
      (tester) async {
    Future<AppLocalizations> loadFor(Locale locale) async {
      late AppLocalizations localizations;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return localizations;
    }

    final fr = await loadFor(const Locale('fr'));
    expect(fr.eventsListTitle, 'Evenements');

    final en = await loadFor(const Locale('en'));
    expect(en.eventsListTitle, 'Events');
  });
}
