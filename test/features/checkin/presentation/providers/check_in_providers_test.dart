import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/presentation/providers/check_in_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tickets/fake_ticket_repository.dart';
import '../../fake_check_in_repository.dart';

void main() {
  test(
    'checkInCounterProvider counts distinct checked-in tickets against total tickets',
    () async {
      final fakeTickets = FakeTicketRepository(tickets: [
        Ticket(
          id: 1,
          beneficiaryId: 1,
          eventId: 42,
          readableId: '0001',
          randomPart: 'ABCD',
          qrPayload: 'EVT-0001-ABCD',
          createdAt: DateTime(2026, 1, 1),
        ),
        Ticket(
          id: 2,
          beneficiaryId: 2,
          eventId: 42,
          readableId: '0002',
          randomPart: 'EFGH',
          qrPayload: 'EVT-0002-EFGH',
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
      final fakeCheckIns = FakeCheckInRepository(checkIns: [
        CheckIn(id: 1, ticketId: 1, eventId: 42, scannedAt: DateTime(2026, 1, 1, 9)),
        CheckIn(id: 2, ticketId: 1, eventId: 42, scannedAt: DateTime(2026, 1, 1, 9, 5)),
      ]);
      final container = ProviderContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(fakeTickets),
          checkInRepositoryProvider.overrideWithValue(fakeCheckIns),
        ],
      );
      addTearDown(container.dispose);

      await container.read(ticketsProvider(42).future);
      await container.read(checkInsProvider(42).future);

      final counter = container.read(checkInCounterProvider(42));
      expect(counter, (1, 2));
    },
  );
}
