import 'package:dif_pass/features/backup/presentation/widgets/import_confirm_dialog.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(bool? Function() readResult, Future<void> Function(BuildContext) onPressed) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () => onPressed(context),
          child: const Text('trigger'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('returns false and dismisses the dialog when cancelled', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(() => result, (context) async {
        result = await showImportConfirmDialog(context);
      }),
    );

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('returns true when confirmed', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(() => result, (context) async {
        result = await showImportConfirmDialog(context);
      }),
    );

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
