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

@DriftDatabase(tables: [
  Events,
  CustomFields,
  Beneficiaries,
  BeneficiaryValues,
  Tickets,
  CheckIns,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dif_pass.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
