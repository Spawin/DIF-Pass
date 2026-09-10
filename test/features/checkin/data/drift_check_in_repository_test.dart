import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/checkin/data/drift_check_in_repository.dart';
import 'package:dif_pass/features/checkin/domain/check_in_outcome.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftCheckInRepository repository;
  late int eventId;
  late int ticketId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftCheckInRepository(db);
    eventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: eventId, name: 'Jane Doe'),
        );
    ticketId = await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: eventId,
            readableId: '0001',
            randomPart: 'ABCD',
            qrPayload: 'EVT1-0001-ABCD',
          ),
        );
  });

  tearDown(() => db.close());

  Ticket ticket() => Ticket(
        id: ticketId,
        beneficiaryId: 1,
        eventId: eventId,
        readableId: '0001',
        randomPart: 'ABCD',
        qrPayload: 'EVT1-0001-ABCD',
        createdAt: DateTime(2026, 1, 1),
      );

  test('simple mode: first scan records a check-in', () async {
    final outcome = await repository.recordCheckIn(ticket(), PresenceMode.simple);

    expect(outcome, isA<CheckInRecorded>());
    final checkIns = await repository.watchCheckInsForEvent(eventId).first;
    expect(checkIns, hasLength(1));
    expect(checkIns.single.ticketId, ticketId);
    final recorded = outcome as CheckInRecorded;
    expect(recorded.checkIn.syncId, isNotNull);
    expect(recorded.checkIn.syncId, isNotEmpty);
  });

  test('simple mode: second scan of the same ticket is blocked', () async {
    final first = (await repository.recordCheckIn(ticket(), PresenceMode.simple))
        as CheckInRecorded;

    final second = await repository.recordCheckIn(ticket(), PresenceMode.simple);

    expect(second, isA<CheckInAlreadyRecorded>());
    expect(
      (second as CheckInAlreadyRecorded).existing.scannedAt,
      first.checkIn.scannedAt,
    );
    final checkIns = await repository.watchCheckInsForEvent(eventId).first;
    expect(checkIns, hasLength(1));
  });

  test('multiple mode: every scan records a new check-in', () async {
    final first = await repository.recordCheckIn(ticket(), PresenceMode.multiple);
    final second = await repository.recordCheckIn(ticket(), PresenceMode.multiple);

    expect(first, isA<CheckInRecorded>());
    expect(second, isA<CheckInRecorded>());
    final checkIns = await repository.watchCheckInsForEvent(eventId).first;
    expect(checkIns, hasLength(2));
  });

  test('watchCheckInsForEvent only returns check-ins for the given event', () async {
    final otherEventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT2',
            name: 'Other event',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await repository.recordCheckIn(ticket(), PresenceMode.simple);

    final checkIns = await repository.watchCheckInsForEvent(otherEventId).first;
    expect(checkIns, isEmpty);
  });
}
