// lib/core/database/tables/custom_fields_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';

@DataClassName('CustomFieldEntity')
class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get label => text()();
  // plain text ('text' | 'number'), same reasoning as Events.presenceMode.
  TextColumn get fieldType => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get showOnTicket => boolean().withDefault(const Constant(false))();
}
