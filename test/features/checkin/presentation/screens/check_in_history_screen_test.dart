import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/presentation/providers/check_in_providers.dart';
import 'package:dif_pass/features/checkin/presentation/screens/check_in_history_screen.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../../tickets/fake_ticket_repository.dart';
import '../../fake_check_in_repository.dart';

Widget _wrap(
  Widget child, {
  FakeEventRepository? fakeEvents,
  FakeBeneficiaryRepository? fakeBeneficiaries,
  FakeTicketRepository? fakeTickets,
  FakeCheckInRepository? fakeCheckIns,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents ?? FakeEventRepository()),
      beneficiaryRepositoryProvider
          .overrideWithValue(fakeBeneficiaries ?? FakeBeneficiaryRepository()),
      ticketRepositoryProvider.overrideWithValue(fakeTickets ?? FakeTicketRepository()),
      checkInRepositoryProvider.overrideWithValue(fakeCheckIns ?? FakeCheckInRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no check-ins', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CheckInHistoryScreen(eventId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('No check-ins recorded yet.'), findsOneWidget);
  });

  testWidgets(
    'shows the beneficiary name for each check-in, most recent first',
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
          Beneficiary(
            id: 2,
            eventId: 1,
            name: 'John Smith',
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
          Ticket(
            id: 2,
            beneficiaryId: 2,
            eventId: 1,
            readableId: '0002',
            randomPart: 'EFGH',
            qrPayload: 'EVT1-0002-EFGH',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final fakeCheckIns = FakeCheckInRepository(
        checkIns: [
          CheckIn(
            id: 1,
            ticketId: 1,
            eventId: 1,
            scannedAt: DateTime(2026, 12, 1, 9, 0),
          ),
          CheckIn(
            id: 2,
            ticketId: 2,
            eventId: 1,
            scannedAt: DateTime(2026, 12, 1, 10, 30),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const CheckInHistoryScreen(eventId: 1),
          fakeBeneficiaries: fakeBeneficiaries,
          fakeTickets: fakeTickets,
          fakeCheckIns: fakeCheckIns,
        ),
      );
      await tester.pumpAndSettle();

      final janeFinder = find.text('Jane Doe');
      final johnFinder = find.text('John Smith');
      expect(janeFinder, findsOneWidget);
      expect(johnFinder, findsOneWidget);

      // Most recent (John, 10:30) must render above the earlier one (Jane, 9:00).
      final janeOffset = tester.getTopLeft(janeFinder);
      final johnOffset = tester.getTopLeft(johnFinder);
      expect(johnOffset.dy, lessThan(janeOffset.dy));
    },
  );
}
