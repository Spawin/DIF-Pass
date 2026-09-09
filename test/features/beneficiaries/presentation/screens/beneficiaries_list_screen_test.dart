import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/event.dart';
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
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeEventRepository fakeEvents, {
  FakeTicketRepository? fakeTickets,
}) {
  return ProviderScope(
    overrides: [
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      ticketRepositoryProvider.overrideWithValue(fakeTickets ?? FakeTicketRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

FakeEventRepository _fakeEventsWithOneEvent() {
  return FakeEventRepository(events: [
    Event(
      id: 1,
      shortCode: 'EVT1',
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      createdAt: DateTime(2026, 1, 1),
    ),
  ]);
}

void main() {
  testWidgets('shows the empty state when there are no beneficiaries',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BeneficiariesListScreen(eventId: 1),
        FakeBeneficiaryRepository(),
        _fakeEventsWithOneEvent(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No beneficiaries yet. Add one or import a CSV file.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a tile per beneficiary for the given event', (tester) async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      _wrap(const BeneficiariesListScreen(eventId: 1), fake, _fakeEventsWithOneEvent()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation before removing a beneficiary',
      (tester) async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      _wrap(const BeneficiariesListScreen(eventId: 1), fake, _fakeEventsWithOneEvent()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(fake.beneficiaries, hasLength(1));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fake.beneficiaries, isEmpty);
  });

  testWidgets(
      'shows the event name in the header and a custom field preview on the tile',
      (tester) async {
    final fakeEvents = _fakeEventsWithOneEvent();
    await fakeEvents.replaceCustomFields(1, const [
      NewCustomField(label: 'Table number', type: CustomFieldType.text, sortOrder: 0),
    ]);
    final customFieldId = (await fakeEvents.watchCustomFields(1).first).single.id;

    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: {customFieldId: 'Table 5'},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      _wrap(const BeneficiariesListScreen(eventId: 1), fakeBeneficiaries, fakeEvents),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gala DIF 2026'), findsOneWidget);
    expect(find.text('Table 5'), findsOneWidget);
  });

  testWidgets(
    'delete confirmation warns about the existing ticket when one exists',
    (tester) async {
      final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
      final fakeTickets = FakeTicketRepository(
        tickets: [
          Ticket(
            id: 1,
            beneficiaryId: 1,
            eventId: 1,
            readableId: '0001',
            randomPart: 'ABCD',
            qrPayload: 'EVT1-0001-ABCD',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const BeneficiariesListScreen(eventId: 1),
          fakeBeneficiaries,
          _fakeEventsWithOneEvent(),
          fakeTickets: fakeTickets,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This beneficiary already has a generated ticket. Deleting them will also delete that ticket; any printed or shared copy will become invalid.',
        ),
        findsOneWidget,
      );
    },
  );
}
