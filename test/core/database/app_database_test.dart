// test/core/database/app_database_test.dart
import 'package:dif_pass/core/database/app_database.dart';
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
}
