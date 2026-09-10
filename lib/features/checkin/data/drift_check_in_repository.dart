import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../events/domain/presence_mode.dart';
import '../../tickets/domain/ticket.dart';
import '../domain/check_in.dart';
import '../domain/check_in_outcome.dart';
import 'check_in_repository.dart';

class DriftCheckInRepository implements CheckInRepository {
  DriftCheckInRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId) {
    final query = _db.select(_db.checkIns)
      ..where((tbl) => tbl.eventId.equals(eventId));
    return query.watch().map((rows) => rows.map(_toCheckIn).toList());
  }

  @override
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode) async {
    if (mode == PresenceMode.simple) {
      final existingRow = await (_db.select(_db.checkIns)
            ..where((tbl) => tbl.ticketId.equals(ticket.id))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.scannedAt)])
            ..limit(1))
          .getSingleOrNull();
      if (existingRow != null) {
        return CheckInAlreadyRecorded(_toCheckIn(existingRow));
      }
    }

    final row = await _db.into(_db.checkIns).insertReturning(
          CheckInsCompanion.insert(
            ticketId: ticket.id,
            eventId: ticket.eventId,
          ),
        );
    return CheckInRecorded(_toCheckIn(row));
  }

  CheckIn _toCheckIn(CheckInEntity row) {
    return CheckIn(
      id: row.id,
      ticketId: row.ticketId,
      eventId: row.eventId,
      scannedAt: row.scannedAt,
      syncId: row.syncId,
    );
  }
}
