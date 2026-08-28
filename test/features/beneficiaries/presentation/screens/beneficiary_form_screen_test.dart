import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../events/fake_event_repository.dart';
import '../../fake_beneficiary_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows a validation error when the name is empty', (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId),
      fakeEvents,
      FakeBeneficiaryRepository(),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('creates a beneficiary with the entered name and custom field value',
      (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [
        NewCustomField(label: 'Table number', type: CustomFieldType.text, sortOrder: 0),
      ],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository();

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId),
      fakeEvents,
      fakeBeneficiaries,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextFormField).at(1), 'Table 5');
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeBeneficiaries.beneficiaries, hasLength(1));
    expect(fakeBeneficiaries.beneficiaries.single.name, 'Jane Doe');
    expect(fakeBeneficiaries.beneficiaries.single.customFieldValues.values,
        contains('Table 5'));
  });

  testWidgets('editing an existing beneficiary pre-fills the name field',
      (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 7,
        eventId: eventId,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId, beneficiaryId: 7),
      fakeEvents,
      fakeBeneficiaries,
    ));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(nameField.controller?.text, 'Jane Doe');
    expect(find.text('Edit beneficiary'), findsOneWidget);
  });
}
