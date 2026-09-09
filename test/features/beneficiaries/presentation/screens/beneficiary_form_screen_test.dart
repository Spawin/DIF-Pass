import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../events/fake_event_repository.dart';
import '../../../tickets/fake_ticket_repository.dart';
import '../../fake_beneficiary_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries, {
  FakeTicketRepository? fakeTickets,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets ?? FakeTicketRepository()),
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

  testWidgets('saving a beneficiary without a ticket does not show a confirmation', (
    tester,
  ) async {
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

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'editing a beneficiary with a ticket asks for confirmation, cancelling keeps the old data',
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
      final fakeTickets = FakeTicketRepository(tickets: [
        Ticket(
          id: 1,
          beneficiaryId: 7,
          eventId: eventId,
          readableId: '0001',
          randomPart: 'ABCD',
          qrPayload: 'EVT1-0001-ABCD',
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);

      await tester.pumpWidget(_wrap(
        BeneficiaryFormScreen(eventId: eventId, beneficiaryId: 7),
        fakeEvents,
        fakeBeneficiaries,
        fakeTickets: fakeTickets,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Jane Updated');
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Edit this beneficiary?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fakeBeneficiaries.beneficiaries.single.name, 'Jane Doe');
    },
  );
}
