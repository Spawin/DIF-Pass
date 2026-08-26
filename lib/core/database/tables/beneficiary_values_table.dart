// lib/core/database/tables/beneficiary_values_table.dart
import 'package:drift/drift.dart';

import 'beneficiaries_table.dart';
import 'custom_fields_table.dart';

@DataClassName('BeneficiaryValueEntity')
class BeneficiaryValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId => integer().references(Beneficiaries, #id)();
  IntColumn get customFieldId => integer().references(CustomFields, #id)();
  TextColumn get value => text()();
}
