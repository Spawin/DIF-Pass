import 'package:drift/drift.dart';

import 'events_table.dart';
import 'tickets_table.dart';

@DataClassName('CheckInEntity')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId => integer().references(Tickets, #id)();
  IntColumn get eventId => integer().references(Events, #id)();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}
