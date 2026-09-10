import 'package:drift/drift.dart';

import '../uuid.dart';
import 'events_table.dart';

@DataClassName('CustomFieldEntity')
@TableIndex(name: 'idx_custom_fields_sync_id', columns: {#syncId}, unique: true)
class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  // plain text ('text' | 'number'), same reasoning as Events.presenceMode.
  TextColumn get fieldType => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get showOnTicket => boolean().withDefault(const Constant(false))();

  // Stable cross-device identifier for a future multi-device merge.
  // ponytail: nullable in the schema ONLY so the v2 -> v3 migration can add
  // it to already-populated tables (ALTER TABLE ADD COLUMN cannot take a
  // non-constant default). clientDefault fills every new row; the migration
  // backfills old rows; the unique index rejects a second null. Treated as
  // always-present by the app. Spec: docs/superpowers/specs/2026-09-10-lot-d
  // -sync-ready-identifiers-design.md
  TextColumn get syncId => text().nullable().clientDefault(() => uuidGen.v4())();
}
