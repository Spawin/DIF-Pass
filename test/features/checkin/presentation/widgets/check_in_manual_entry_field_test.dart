import 'package:dif_pass/features/checkin/presentation/widgets/check_in_manual_entry_field.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'submitting the field calls onSubmit with the trimmed text and clears it',
    (tester) async {
      String? submitted;
      await tester.pumpWidget(
        _wrap(
          CheckInManualEntryField(
            onSubmit: (value) async {
              submitted = value;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  0042  ');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(submitted, '0042');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('submitting an empty field does not call onSubmit', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _wrap(
        CheckInManualEntryField(
          onSubmit: (value) async {
            called = true;
          },
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(called, isFalse);
  });

  testWidgets('disabled field cannot be submitted', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _wrap(
        CheckInManualEntryField(
          enabled: false,
          onSubmit: (value) async {
            called = true;
          },
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(called, isFalse);
  });
}
