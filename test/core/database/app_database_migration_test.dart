import 'dart:io';

import 'package:dif_pass/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('opening a v1 database (no ticket_template column) upgrades cleanly '
      'and the new column reads as the standard default', () async {
    final dir = await Directory.systemTemp.createTemp(
      'dif_pass_migration_test',
    );
    final file = File(p.join(dir.path, 'legacy.sqlite'));
    addTearDown(() => dir.delete(recursive: true));

    // Build a v1 events table on disk (no ticket_template column), the
    // shape the app shipped with before this jalon, and stamp it at
    // user_version 1 the way drift itself would have left it.
    final legacyDb = sqlite3.sqlite3.open(file.path);
    legacyDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        short_code TEXT NOT NULL,
        name TEXT NOT NULL,
        date INTEGER NOT NULL,
        location TEXT NULL,
        logo BLOB NULL,
        presence_mode TEXT NOT NULL,
        archived_at INTEGER NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    legacyDb.execute(
      "INSERT INTO events (short_code, name, date, presence_mode, created_at) "
      "VALUES ('EVT1', 'Legacy Event', 0, 'simple', 0)",
    );
    legacyDb.userVersion = 1;
    legacyDb.close();

    // Opening the same file through the current (v2) AppDatabase must not
    // throw "no such column: ticket_template", and the migrated row should
    // read back with the standard default.
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final events = await db.select(db.events).get();

    expect(events, hasLength(1));
    expect(events.single.name, 'Legacy Event');
    expect(events.single.ticketTemplate, 'standard');

    await db.close();
  });
}
