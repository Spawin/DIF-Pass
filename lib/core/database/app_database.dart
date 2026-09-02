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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(events, events.ticketTemplate);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
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
