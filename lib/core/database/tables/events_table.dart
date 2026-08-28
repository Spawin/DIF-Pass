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
  // ponytail: plain text ('compact' | 'standard' | 'elegant') instead of
  // Drift's textEnum<T>() sugar, same reasoning as presenceMode above.
  TextColumn get ticketTemplate =>
      text().withDefault(const Constant('standard'))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
