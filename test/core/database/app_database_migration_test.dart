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
    legacyDb.execute('''
      CREATE TABLE custom_fields (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        label TEXT NOT NULL,
        field_type TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        show_on_ticket INTEGER NOT NULL DEFAULT 0
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE beneficiaries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE beneficiary_values (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER NOT NULL REFERENCES beneficiaries (id) ON DELETE CASCADE,
        custom_field_id INTEGER NOT NULL REFERENCES custom_fields (id) ON DELETE CASCADE,
        value TEXT NOT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE tickets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER NOT NULL REFERENCES beneficiaries (id) ON DELETE CASCADE,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        readable_id TEXT NOT NULL,
        random_part TEXT NOT NULL,
        qr_payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE (event_id, readable_id)
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE check_ins (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL REFERENCES tickets (id) ON DELETE CASCADE,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        scanned_at INTEGER NOT NULL
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

  test('opening a v2 database backfills a distinct sync_id on every row '
      'of the five sync-tracked tables', () async {
    final dir = await Directory.systemTemp.createTemp('dif_pass_migration_v2');
    final file = File(p.join(dir.path, 'legacy_v2.sqlite'));
    addTearDown(() => dir.delete(recursive: true));

    final legacyDb = sqlite3.sqlite3.open(file.path);
    // v2 shape: v1 tables + events.ticket_template, no sync_id anywhere.
    legacyDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        short_code TEXT NOT NULL,
        name TEXT NOT NULL,
        date INTEGER NOT NULL,
        location TEXT NULL,
        logo BLOB NULL,
        presence_mode TEXT NOT NULL,
        ticket_template TEXT NOT NULL DEFAULT 'standard',
        archived_at INTEGER NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE custom_fields (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        label TEXT NOT NULL,
        field_type TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        show_on_ticket INTEGER NOT NULL DEFAULT 0
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE beneficiaries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE beneficiary_values (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER NOT NULL REFERENCES beneficiaries (id) ON DELETE CASCADE,
        custom_field_id INTEGER NOT NULL REFERENCES custom_fields (id) ON DELETE CASCADE,
        value TEXT NOT NULL
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE tickets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER NOT NULL REFERENCES beneficiaries (id) ON DELETE CASCADE,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        readable_id TEXT NOT NULL,
        random_part TEXT NOT NULL,
        qr_payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE (event_id, readable_id)
      );
    ''');
    legacyDb.execute('''
      CREATE TABLE check_ins (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL REFERENCES tickets (id) ON DELETE CASCADE,
        event_id INTEGER NOT NULL REFERENCES events (id) ON DELETE CASCADE,
        scanned_at INTEGER NOT NULL
      );
    ''');
    legacyDb.execute(
      "INSERT INTO events (short_code, name, date, presence_mode, created_at) "
      "VALUES ('EVT1', 'A', 0, 'simple', 0), ('EVT2', 'B', 0, 'multiple', 0)",
    );
    legacyDb.execute(
      "INSERT INTO custom_fields (event_id, label, field_type, sort_order) "
      "VALUES (1, 'Table', 'text', 0)",
    );
    legacyDb.execute(
      "INSERT INTO beneficiaries (event_id, name, created_at) "
      "VALUES (1, 'Ama', 0)",
    );
    legacyDb.execute(
      "INSERT INTO tickets (beneficiary_id, event_id, readable_id, random_part, "
      "qr_payload, created_at) VALUES (1, 1, '1', 'abcd', 'EVT1-1-abcd', 0)",
    );
    legacyDb.execute(
      "INSERT INTO check_ins (ticket_id, event_id, scanned_at) VALUES (1, 1, 0)",
    );
    legacyDb.userVersion = 2;
    legacyDb.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final ids = <String>[];
    ids.addAll((await db.select(db.events).get()).map((r) => r.syncId!));
    ids.addAll((await db.select(db.customFields).get()).map((r) => r.syncId!));
    ids.addAll((await db.select(db.beneficiaries).get()).map((r) => r.syncId!));
    ids.addAll((await db.select(db.tickets).get()).map((r) => r.syncId!));
    ids.addAll((await db.select(db.checkIns).get()).map((r) => r.syncId!));

    expect(ids, hasLength(6));
    for (final id in ids) {
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(id),
        isTrue,
        reason: 'not a v4 UUID: $id',
      );
    }
    expect(ids.toSet(), hasLength(6), reason: 'sync_id values must be distinct');
  });
}
