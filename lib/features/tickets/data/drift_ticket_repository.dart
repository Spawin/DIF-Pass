import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/ticket.dart';
import 'ticket_id_generator.dart';
import 'ticket_repository.dart';

class DriftTicketRepository implements TicketRepository {
  DriftTicketRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Ticket>> watchTicketsForEvent(int eventId) {
    final query = _db.select(_db.tickets)
      ..where((tbl) => tbl.eventId.equals(eventId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.readableId)]);
    return query.watch().map((rows) => rows.map(_toTicket).toList());
  }

  @override
  Future<Ticket> getTicket(int id) async {
    final row = await (_db.select(_db.tickets)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _toTicket(row);
  }

  @override
  Future<int> generateMissingTickets(int eventId) {
    return _db.transaction(() async {
      final event = await (_db.select(_db.events)
            ..where((tbl) => tbl.id.equals(eventId)))
          .getSingle();

      final beneficiaryRows = await (_db.select(_db.beneficiaries)
            ..where((tbl) => tbl.eventId.equals(eventId))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
          .get();

      final existingTickets = await (_db.select(_db.tickets)
            ..where((tbl) => tbl.eventId.equals(eventId)))
          .get();
      final beneficiariesWithTickets =
          existingTickets.map((t) => t.beneficiaryId).toSet();

      var nextSequence = 1;
      for (final ticket in existingTickets) {
        final parsed = int.tryParse(ticket.readableId);
        if (parsed != null && parsed >= nextSequence) {
          nextSequence = parsed + 1;
        }
      }

      var createdCount = 0;
      for (final beneficiary in beneficiaryRows) {
        if (beneficiariesWithTickets.contains(beneficiary.id)) continue;

        final generated = generateTicketId(sequence: nextSequence);
        await _db.into(_db.tickets).insert(
              TicketsCompanion.insert(
                beneficiaryId: beneficiary.id,
                eventId: eventId,
                readableId: generated.readableId,
                randomPart: generated.randomPart,
                qrPayload: generated.payloadFor(event.shortCode),
              ),
            );
        nextSequence++;
        createdCount++;
      }

      return createdCount;
    });
  }

  Ticket _toTicket(TicketEntity row) {
    return Ticket(
      id: row.id,
      beneficiaryId: row.beneficiaryId,
      eventId: row.eventId,
      readableId: row.readableId,
      randomPart: row.randomPart,
      qrPayload: row.qrPayload,
      createdAt: row.createdAt,
    );
  }
}
