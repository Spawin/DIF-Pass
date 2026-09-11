import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/presentation/providers/check_in_providers.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/domain/ticket_template.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/features/tickets/presentation/screens/tickets_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../checkin/fake_check_in_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../fake_ticket_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeTicketRepository fakeTickets, {
  FakeCheckInRepository? fakeCheckIns,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets),
      checkInRepositoryProvider.overrideWithValue(fakeCheckIns ?? FakeCheckInRepository()),
      auditLoggerProvider.overrideWithValue(
        AuditLogger(
          enabled: false,
          fileResolver: () async =>
              throw UnimplementedError('not used - enabled is false'),
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

FakeEventRepository _fakeEventsWithOneEvent() {
  return FakeEventRepository(
    events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'shows the empty state and an enabled generate button when a beneficiary has no ticket yet',
    (tester) async {
      final fakeBeneficiaries = FakeBeneficiaryRepository(
        beneficiaries: [
          Beneficiary(
            id: 1,
            eventId: 1,
            name: 'Jane Doe',
            customFieldValues: const {},
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final fakeTickets = FakeTicketRepository(
        beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
            .where((b) => b.eventId == eventId)
            .map((b) => b.id)
            .toList(),
      );

      await tester.pumpWidget(
        _wrap(
          const TicketsScreen(eventId: 1),
          _fakeEventsWithOneEvent(),
          fakeBeneficiaries,
          fakeTickets,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tickets yet.'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'generate button is disabled once every beneficiary has a ticket',
    (tester) async {
      final fakeBeneficiaries = FakeBeneficiaryRepository(
        beneficiaries: [
          Beneficiary(
            id: 1,
            eventId: 1,
            name: 'Jane Doe',
            customFieldValues: const {},
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
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

      await tester.pumpWidget(
        _wrap(
          const TicketsScreen(eventId: 1),
          _fakeEventsWithOneEvent(),
          fakeBeneficiaries,
          fakeTickets,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('tapping generate creates tickets and the list updates', (
    tester,
  ) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final fakeTickets = FakeTicketRepository(
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Generate tickets'));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(fakeTickets.tickets, hasLength(1));
    expect(find.text('1 ticket created'), findsOneWidget);
  });

  testWidgets(
    'picking a different ticket template updates the selected segment',
    (tester) async {
      final fakeEvents = _fakeEventsWithOneEvent();
      final fakeBeneficiaries = FakeBeneficiaryRepository(
        beneficiaries: const [],
      );
      final fakeTickets = FakeTicketRepository(
        beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
            .where((b) => b.eventId == eventId)
            .map((b) => b.id)
            .toList(),
      );

      await tester.pumpWidget(
        _wrap(
          const TicketsScreen(eventId: 1),
          fakeEvents,
          fakeBeneficiaries,
          fakeTickets,
        ),
      );
      await tester.pumpAndSettle();

      var button = tester.widget<SegmentedButton<TicketTemplate>>(
        find.byType(SegmentedButton<TicketTemplate>),
      );
      expect(button.selected, {TicketTemplate.standard});

      await tester.tap(find.text('Elegant'));
      await tester.pumpAndSettle();

      button = tester.widget<SegmentedButton<TicketTemplate>>(
        find.byType(SegmentedButton<TicketTemplate>),
      );
      expect(button.selected, {TicketTemplate.elegant});
      expect(
        fakeEvents.events.firstWhere((e) => e.id == 1).ticketTemplate,
        TicketTemplate.elegant,
      );
    },
  );

  testWidgets('export action is disabled when there are no tickets', (
    tester,
  ) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final fakeTickets = FakeTicketRepository(
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Export tickets'), findsOneWidget);
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('export action is enabled once at least one ticket exists', (
    tester,
  ) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
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

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Export tickets'), findsOneWidget);
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('shows a Checked in badge for a ticket with a check-in in simple mode', (
    tester,
  ) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
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
    final fakeCheckIns = FakeCheckInRepository(
      checkIns: [
        CheckIn(id: 1, ticketId: 1, eventId: 1, scannedAt: DateTime(2026, 12, 1, 9, 0)),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        fakeBeneficiaries,
        fakeTickets,
        fakeCheckIns: fakeCheckIns,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checked in'), findsOneWidget);
  });

  testWidgets('shows a passage count for a ticket with multiple check-ins in multiple mode', (
    tester,
  ) async {
    final fakeEvents = FakeEventRepository(
      events: [
        Event(
          id: 1,
          shortCode: 'EVT1',
          name: 'Gala DIF 2026',
          date: DateTime(2026, 12, 1),
          presenceMode: PresenceMode.multiple,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository(
      beneficiaries: [
        Beneficiary(
          id: 1,
          eventId: 1,
          name: 'Jane Doe',
          customFieldValues: const {},
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
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
    final fakeCheckIns = FakeCheckInRepository(
      checkIns: [
        CheckIn(id: 1, ticketId: 1, eventId: 1, scannedAt: DateTime(2026, 12, 1, 9, 0)),
        CheckIn(id: 2, ticketId: 1, eventId: 1, scannedAt: DateTime(2026, 12, 1, 14, 0)),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        fakeEvents,
        fakeBeneficiaries,
        fakeTickets,
        fakeCheckIns: fakeCheckIns,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 check-ins'), findsOneWidget);
  });
}
