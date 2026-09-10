import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/beneficiaries_table.dart';
import 'tables/beneficiary_values_table.dart';
import 'tables/checkins_table.dart';
import 'tables/custom_fields_table.dart';
import 'tables/events_table.dart';
import 'tables/tickets_table.dart';
import 'uuid.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Events,
    CustomFields,
    Beneficiaries,
    BeneficiaryValues,
    Tickets,
    CheckIns,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  // ponytail: same body as forTesting, a separate name documents that this
  // constructor is also used in production (lib/features/backup), not only
  // in tests, so a reader isn't confused by production code calling
  // something named "forTesting".
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(events, events.ticketTemplate);
      }
      if (from < 3) {
        await _addSyncIds(m);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// v2 -> v3: give every existing row in the five sync-tracked tables a
  /// stable `sync_id`, then enforce uniqueness. Fresh installs get the column
  /// and indexes from the table definitions via `createAll`; this path brings
  /// upgrading installs to the same shape.
  Future<void> _addSyncIds(Migrator m) async {
    await m.addColumn(events, events.syncId);
    await m.addColumn(customFields, customFields.syncId);
    await m.addColumn(beneficiaries, beneficiaries.syncId);
    await m.addColumn(tickets, tickets.syncId);
    await m.addColumn(checkIns, checkIns.syncId);

    for (final row in await select(events).get()) {
      await (update(events)..where((t) => t.id.equals(row.id)))
          .write(EventsCompanion(syncId: Value(uuidGen.v4())));
    }
    for (final row in await select(customFields).get()) {
      await (update(customFields)..where((t) => t.id.equals(row.id)))
          .write(CustomFieldsCompanion(syncId: Value(uuidGen.v4())));
    }
    for (final row in await select(beneficiaries).get()) {
      await (update(beneficiaries)..where((t) => t.id.equals(row.id)))
          .write(BeneficiariesCompanion(syncId: Value(uuidGen.v4())));
    }
    for (final row in await select(tickets).get()) {
      await (update(tickets)..where((t) => t.id.equals(row.id)))
          .write(TicketsCompanion(syncId: Value(uuidGen.v4())));
    }
    for (final row in await select(checkIns).get()) {
      await (update(checkIns)..where((t) => t.id.equals(row.id)))
          .write(CheckInsCompanion(syncId: Value(uuidGen.v4())));
    }

    const indexes = <String, String>{
      'idx_events_sync_id': 'events',
      'idx_custom_fields_sync_id': 'custom_fields',
      'idx_beneficiaries_sync_id': 'beneficiaries',
      'idx_tickets_sync_id': 'tickets',
      'idx_check_ins_sync_id': 'check_ins',
    };
    for (final entry in indexes.entries) {
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS ${entry.key} '
        'ON ${entry.value} (sync_id)',
      );
    }
  }
}

/// Resolves the on-disk path of the app's database file. Shared by the
/// normal app startup connection below and by the backup feature
/// (lib/features/backup), which needs the same path to export/import the
/// file directly.
Future<File> resolveDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return File(p.join(dbFolder.path, 'dif_pass.sqlite'));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await resolveDatabaseFile();
    return NativeDatabase.createInBackground(file);
  });
}
