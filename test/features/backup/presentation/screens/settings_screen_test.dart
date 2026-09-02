import 'package:dif_pass/features/backup/presentation/screens/settings_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the export and import actions, both enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    final exportButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(exportButton.onPressed, isNotNull);
    final importButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(importButton.onPressed, isNotNull);
  });
}
