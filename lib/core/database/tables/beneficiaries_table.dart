import 'package:drift/drift.dart';

import 'events_table.dart';

@DataClassName('BeneficiaryEntity')
class Beneficiaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
