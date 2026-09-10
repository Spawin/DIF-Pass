import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/beneficiaries/data/drift_beneficiary_repository.dart';
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/domain/new_beneficiary.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftBeneficiaryRepository repository;
  late int eventId;
  late int customFieldId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftBeneficiaryRepository(db);
    eventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    customFieldId = await db.into(db.customFields).insert(
          CustomFieldsCompanion.insert(
            eventId: eventId,
            label: 'Table number',
            fieldType: 'text',
            sortOrder: 0,
          ),
        );
  });

  tearDown(() => db.close());

  test('createBeneficiary stores the name and custom field values', () async {
    final id = await repository.createBeneficiary(
      eventId,
      NewBeneficiary(name: 'Jane Doe', customFieldValues: {customFieldId: 'Table 5'}),
    );

    final beneficiary = await repository.getBeneficiary(id);
    expect(beneficiary.name, 'Jane Doe');
    expect(beneficiary.customFieldValues, {customFieldId: 'Table 5'});
    expect(beneficiary.syncId, isNotNull);
    expect(beneficiary.syncId, isNotEmpty);
  });

  test('watchBeneficiaries only returns beneficiaries for the given event', () async {
    final otherEventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT2',
            name: 'Other event',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await repository.createBeneficiary(
      eventId,
      const NewBeneficiary(name: 'Jane Doe', customFieldValues: {}),
    );
    await repository.createBeneficiary(
      otherEventId,
      const NewBeneficiary(name: 'Other person', customFieldValues: {}),
    );

    final beneficiaries = await repository.watchBeneficiaries(eventId).first;
    expect(beneficiaries.map((b) => b.name).toList(), ['Jane Doe']);
  });

  test('watchBeneficiaries re-emits when a custom field value changes on an existing beneficiary', () async {
    final id = await repository.createBeneficiary(
      eventId,
      const NewBeneficiary(name: 'Jane Doe', customFieldValues: {}),
    );

    final stream = repository.watchBeneficiaries(eventId);
    final expectation = expectLater(
      stream,
      emitsInOrder([
        predicate<List<Beneficiary>>(
            (list) => list.single.customFieldValues[customFieldId] == null),
        predicate<List<Beneficiary>>(
            (list) => list.single.customFieldValues[customFieldId] == 'Table 9'),
      ]),
    );

    await db.into(db.beneficiaryValues).insert(
          BeneficiaryValuesCompanion.insert(
            beneficiaryId: id,
            customFieldId: customFieldId,
            value: 'Table 9',
          ),
        );

    await expectation;
  });

  test('updateBeneficiary replaces the name and custom field values', () async {
    final id = await repository.createBeneficiary(
      eventId,
      NewBeneficiary(name: 'Jane Doe', customFieldValues: {customFieldId: 'Table 5'}),
    );

    await repository.updateBeneficiary(
      id,
      NewBeneficiary(name: 'Jane Smith', customFieldValues: {customFieldId: 'Table 9'}),
    );

    final beneficiary = await repository.getBeneficiary(id);
    expect(beneficiary.name, 'Jane Smith');
    expect(beneficiary.customFieldValues, {customFieldId: 'Table 9'});
  });

  test('deleteBeneficiary removes the beneficiary and its values', () async {
    final id = await repository.createBeneficiary(
      eventId,
      NewBeneficiary(name: 'Jane Doe', customFieldValues: {customFieldId: 'Table 5'}),
    );

    await repository.deleteBeneficiary(id);

    expect(await db.select(db.beneficiaries).get(), isEmpty);
    expect(await db.select(db.beneficiaryValues).get(), isEmpty);
  });

  test('importBeneficiaries inserts every row and returns the count', () async {
    final imported = await repository.importBeneficiaries(eventId, [
      NewBeneficiary(name: 'Jane Doe', customFieldValues: {customFieldId: 'Table 5'}),
      const NewBeneficiary(name: 'John Smith', customFieldValues: {}),
    ]);

    expect(imported, 2);
    final beneficiaries = await repository.watchBeneficiaries(eventId).first;
    expect(beneficiaries.map((b) => b.name).toSet(), {'Jane Doe', 'John Smith'});
  });
}
