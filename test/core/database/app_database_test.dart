import 'package:dif_pass/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppDatabase can insert and read back an event', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );

    final saved = await (db.select(db.events)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    expect(saved.name, 'Gala DIF 2026');
    expect(saved.presenceMode, 'simple');
    expect(saved.archivedAt, isNull);
  });

  test('foreign keys are enforced', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      () => db.into(db.customFields).insert(
            CustomFieldsCompanion.insert(
              eventId: 999999,
              label: 'Table number',
              fieldType: 'text',
              sortOrder: 0,
            ),
          ),
      throwsA(anything),
    );
  });

  test('deleting an event cascades to its custom fields', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final eventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await db.into(db.customFields).insert(
          CustomFieldsCompanion.insert(
            eventId: eventId,
            label: 'Table number',
            fieldType: 'text',
            sortOrder: 0,
          ),
        );

    await (db.delete(db.events)..where((tbl) => tbl.id.equals(eventId))).go();

    final remainingFields = await db.select(db.customFields).get();
    expect(remainingFields, isEmpty);
  });

  test('clientDefault gives every inserted row a distinct sync_id', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final a = await db.into(db.events).insertReturning(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'A',
            date: DateTime(2026),
            presenceMode: 'simple',
          ),
        );
    final b = await db.into(db.events).insertReturning(
          EventsCompanion.insert(
            shortCode: 'EVT2',
            name: 'B',
            date: DateTime(2026),
            presenceMode: 'simple',
          ),
        );

    expect(a.syncId, isNotNull);
    expect(b.syncId, isNotNull);
    expect(a.syncId, isNot(b.syncId));
  });

  test('sync_id has a unique index', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final a = await db.into(db.events).insertReturning(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'A',
            date: DateTime(2026),
            presenceMode: 'simple',
          ),
        );

    await expectLater(
      db.into(db.events).insert(
            EventsCompanion.insert(
              shortCode: 'EVT2',
              name: 'B',
              date: DateTime(2026),
              presenceMode: 'simple',
              syncId: Value(a.syncId!),
            ),
          ),
      throwsA(anything),
    );
  });
}
