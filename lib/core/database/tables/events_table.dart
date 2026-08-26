import 'package:drift/drift.dart';

@DataClassName('EventEntity')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortCode => text()();
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text().nullable()();
  BlobColumn get logo => blob().nullable()();
  // ponytail: plain text ('simple' | 'multiple') instead of Drift's
  // textEnum<T>() sugar, converted to PresenceMode in the repository layer.
  TextColumn get presenceMode => text()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
