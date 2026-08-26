import 'package:drift/drift.dart';

import 'events_table.dart';
import 'tickets_table.dart';

@DataClassName('CheckInEntity')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId =>
      integer().references(Tickets, #id, onDelete: KeyAction.cascade)();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}
