import 'package:dif_pass/features/beneficiaries/domain/new_beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/widgets/csv_mapping_form.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
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
      'maps the name column and a custom field column, skips rows without a name',
      (tester) async {
    List<NewBeneficiary>? captured;
    var skippedCount = -1;

    await tester.pumpWidget(_wrap(CsvMappingForm(
      headers: const ['Full name', 'Table'],
      dataRows: const [
        ['Jane Doe', '5'],
        ['', '9'],
      ],
      customFields: const [
        CustomField(
          id: 1,
          eventId: 1,
          label: 'Table number',
          type: CustomFieldType.text,
          sortOrder: 0,
          showOnTicket: false,
        ),
      ],
      onImport: (beneficiaries, skipped) {
        captured = beneficiaries;
        skippedCount = skipped;
      },
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full name').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int?>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    expect(captured!.single.name, 'Jane Doe');
    expect(captured!.single.customFieldValues, {1: '5'});
    expect(skippedCount, 1);
  });
}
