import 'package:drift/drift.dart';

import 'beneficiaries_table.dart';
import 'events_table.dart';

@DataClassName('TicketEntity')
class Tickets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId =>
      integer().references(Beneficiaries, #id, onDelete: KeyAction.cascade)();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get readableId => text()();
  TextColumn get randomPart => text()();
  TextColumn get qrPayload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {eventId, readableId},
      ];
}
