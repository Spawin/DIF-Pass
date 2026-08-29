import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/features/tickets/presentation/screens/tickets_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../fake_ticket_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeTicketRepository fakeTickets,
) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets),
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
  testWidgets(
      'shows the empty state and an enabled generate button when a beneficiary has no ticket yet',
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
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(_wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    expect(find.text('No tickets yet.'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('generate button is disabled once every beneficiary has a ticket',
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
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(_wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping generate creates tickets and the list updates', (tester) async {
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
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(_wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(fakeTickets.tickets, hasLength(1));
  });
}
