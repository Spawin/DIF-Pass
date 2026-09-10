import 'package:drift/drift.dart';

import '../uuid.dart';
import 'events_table.dart';

@DataClassName('BeneficiaryEntity')
@TableIndex(name: 'idx_beneficiaries_sync_id', columns: {#syncId}, unique: true)
class Beneficiaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Stable cross-device identifier for a future multi-device merge.
  // ponytail: nullable in the schema ONLY so the v2 -> v3 migration can add
  // it to already-populated tables (ALTER TABLE ADD COLUMN cannot take a
  // non-constant default). clientDefault fills every new row and the
  // migration backfills old rows, so in practice it is always set. Treated
  // as always-present by the app. Spec: docs/superpowers/specs/2026-09-10-lot-d
  // -sync-ready-identifiers-design.md
  TextColumn get syncId => text().nullable().clientDefault(() => uuidGen.v4())();
}
