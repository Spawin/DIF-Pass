import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/tickets/data/drift_ticket_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTicketRepository repository;
  late int eventId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTicketRepository(db);
    eventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
  });

  tearDown(() => db.close());

  Future<int> insertBeneficiary(String name) {
    return db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: eventId, name: name),
        );
  }

  test('generateMissingTickets creates one ticket per beneficiary without one', () async {
    await insertBeneficiary('Jane Doe');
    await insertBeneficiary('John Smith');

    final created = await repository.generateMissingTickets(eventId);

    expect(created, 2);
    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(2));
    expect(tickets.map((t) => t.readableId).toList(), ['0001', '0002']);
    expect(tickets.every((t) => t.qrPayload.startsWith('EVT1-')), isTrue);
  });

  test('generateMissingTickets is idempotent, only fills gaps', () async {
    final firstBeneficiaryId = await insertBeneficiary('Jane Doe');
    await repository.generateMissingTickets(eventId);
    final firstTicket = (await repository.watchTicketsForEvent(eventId).first).single;

    await insertBeneficiary('John Smith');
    final createdSecondRound = await repository.generateMissingTickets(eventId);

    expect(createdSecondRound, 1);
    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(2));
    final unchangedTicket =
        tickets.firstWhere((t) => t.beneficiaryId == firstBeneficiaryId);
    expect(unchangedTicket.id, firstTicket.id);
    expect(unchangedTicket.readableId, firstTicket.readableId);
    expect(unchangedTicket.randomPart, firstTicket.randomPart);
    expect(tickets.map((t) => t.readableId).toSet(), {'0001', '0002'});
  });

  test('watchTicketsForEvent only returns tickets for the given event, sorted by readableId', () async {
    final otherEventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT2',
            name: 'Other event',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await insertBeneficiary('Jane Doe');
    await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: otherEventId, name: 'Other person'),
        );
    await repository.generateMissingTickets(eventId);
    await DriftTicketRepository(db).generateMissingTickets(otherEventId);

    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(1));
    expect(tickets.single.eventId, eventId);
  });

  test('getTicket returns a single ticket by id', () async {
    await insertBeneficiary('Jane Doe');
    await repository.generateMissingTickets(eventId);
    final ticket = (await repository.watchTicketsForEvent(eventId).first).single;

    final fetched = await repository.getTicket(ticket.id);
    expect(fetched.readableId, ticket.readableId);
  });
}
