import 'package:drift/drift.dart';

import '../uuid.dart';

@DataClassName('EventEntity')
@TableIndex(name: 'idx_events_sync_id', columns: {#syncId}, unique: true)
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

  // Stable cross-device identifier for a future multi-device merge.
  // ponytail: nullable in the schema ONLY so the v2 -> v3 migration can add
  // it to already-populated tables (ALTER TABLE ADD COLUMN cannot take a
  // non-constant default). clientDefault fills every new row; the migration
  // backfills old rows; the unique index rejects a second null. Treated as
  // always-present by the app. Spec: docs/superpowers/specs/2026-09-10-lot-d
  // -sync-ready-identifiers-design.md
  TextColumn get syncId => text().nullable().clientDefault(() => uuidGen.v4())();
}
