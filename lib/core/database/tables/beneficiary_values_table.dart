import 'package:drift/drift.dart';

import 'beneficiaries_table.dart';
import 'custom_fields_table.dart';

@DataClassName('BeneficiaryValueEntity')
class BeneficiaryValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId =>
      integer().references(Beneficiaries, #id, onDelete: KeyAction.cascade)();
  IntColumn get customFieldId =>
      integer().references(CustomFields, #id, onDelete: KeyAction.cascade)();
  TextColumn get value => text()();
}
