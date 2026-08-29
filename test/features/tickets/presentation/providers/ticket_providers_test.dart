import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_ticket_repository.dart';

void main() {
  test('ticketsProvider streams tickets for the given event from the overridden repository', () async {
    final fake = FakeTicketRepository(tickets: [
      Ticket(
        id: 1,
        beneficiaryId: 1,
        eventId: 42,
        readableId: '0001',
        randomPart: 'ABCD',
        qrPayload: 'EVT-0001-ABCD',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [ticketRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final tickets = await container.read(ticketsProvider(42).future);
    expect(tickets, hasLength(1));
    expect(tickets.single.readableId, '0001');
  });
}
