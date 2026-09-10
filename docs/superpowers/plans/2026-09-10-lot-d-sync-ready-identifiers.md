# Lot D - Sync-ready identifiers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a stable global identifier (`syncId`, a v4 UUID) to the five independently-created database tables so a future multi-device merge can match rows across devices without depending on the colliding local autoincrement `id`.

**Architecture:** A nullable `sync_id TEXT` column on `Events`, `CustomFields`, `Beneficiaries`, `Tickets`, `CheckIns`, each with a Drift `clientDefault` that generates a UUID on every insert and a unique index. A v2 -> v3 migration adds the column to populated tables, backfills one UUID per existing row, then creates the unique indexes. The local `id`, primary keys, foreign keys, routes, and `Events.shortCode` are untouched. No merge, sync, or export logic.

**Tech Stack:** Flutter 3.44.7 (via FVM), Drift 2.34.x + drift_dev + build_runner, `uuid` (pub.dev), `sqlite3` (test fixtures), flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-10-lot-d-sync-ready-identifiers-design.md`

## Global Constraints

- All Flutter/Dart tooling runs through FVM: `fvm flutter ...`, `fvm dart ...`.
- Generated files (`lib/core/database/app_database.g.dart`) are never hand-edited. Regenerate with `fvm dart run build_runner build --delete-conflicting-outputs`.
- Commit messages: no `Co-Authored-By: Claude` trailer, no "Generated with Claude" line, no em dashes anywhere (code, comments, docs, messages).
- `syncId` is added to exactly 5 tables: `Events`, `CustomFields`, `Beneficiaries`, `Tickets`, `CheckIns`. `BeneficiaryValues` does NOT get one.
- The schema column is `text().nullable()` (nullable only for migration reasons). The domain field is `String? syncId`, optional in every constructor. `NewBeneficiary` / `NewCustomField` and other input value objects never carry `syncId`.
- `AppDatabase.schemaVersion` becomes `3`. Do not change local `id`, primary keys, foreign keys, `go_router` routes, or `Events.shortCode`.
- Unique index names: `idx_events_sync_id`, `idx_custom_fields_sync_id`, `idx_beneficiaries_sync_id`, `idx_tickets_sync_id`, `idx_check_ins_sync_id`. Each is `UNIQUE` on `(sync_id)`.
- All existing tests (158) must still pass at the end of each task.

---

## File Structure

- `pubspec.yaml` - add the `uuid` dependency.
- `lib/core/database/uuid.dart` (new) - one shared `uuidGen` instance, used by table `clientDefault`s and the migration backfill.
- `lib/core/database/tables/{events,custom_fields,beneficiaries,tickets,checkins}_table.dart` - add the `syncId` column and `@TableIndex`.
- `lib/core/database/app_database.dart` - bump `schemaVersion`, add the v2 -> v3 migration.
- `lib/core/database/app_database.g.dart` - regenerated, never hand-edited.
- `lib/features/*/domain/{event,custom_field,beneficiary,ticket,check_in}.dart` - add the optional `String? syncId` field.
- `lib/features/*/data/drift_*_repository.dart` - the entity -> domain mappers copy `row.syncId` through.
- `test/core/database/app_database_test.dart` - clientDefault + unique-index unit tests.
- `test/core/database/app_database_migration_test.dart` - expand the legacy fixture to all 6 tables; add a v2 -> v3 backfill case.
- `test/features/*/data/drift_*_repository_test.dart` - one `syncId` non-null assertion per repository.

---

## Task 1: syncId column, unique index, and the v2 -> v3 migration

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/database/uuid.dart`
- Modify: `lib/core/database/tables/events_table.dart`
- Modify: `lib/core/database/tables/custom_fields_table.dart`
- Modify: `lib/core/database/tables/beneficiaries_table.dart`
- Modify: `lib/core/database/tables/tickets_table.dart`
- Modify: `lib/core/database/tables/checkins_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Regenerate: `lib/core/database/app_database.g.dart`
- Test: `test/core/database/app_database_test.dart`
- Test: `test/core/database/app_database_migration_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks (first task).
- Produces:
  - `lib/core/database/uuid.dart` exports `final Uuid uuidGen;` (from `package:uuid/uuid.dart`).
  - After regen, each entity class gains a getter `String? get syncId`: `EventEntity`, `CustomFieldEntity`, `BeneficiaryEntity`, `TicketEntity`, `CheckInEntity`.
  - After regen, each companion (`EventsCompanion`, `CustomFieldsCompanion`, `BeneficiariesCompanion`, `TicketsCompanion`, `CheckInsCompanion`) gains `Value<String?> syncId`, and `.insert(...)` keeps `syncId` optional (a `clientDefault` supplies it).
  - `AppDatabase.schemaVersion == 3`; opening a v1 or v2 database upgrades cleanly with every row's `sync_id` populated and unique.

- [ ] **Step 1: Add the `uuid` dependency**

Run:
```bash
fvm flutter pub add uuid
```
Expected: `pubspec.yaml` gains `uuid: ^4.x.x` under `dependencies:` and `pub get` resolves with no version conflict. If `pub add` picks a 4.x line, keep it; do not pin below 4.0.0.

- [ ] **Step 2: Create the shared UUID generator**

Create `lib/core/database/uuid.dart`:
```dart
import 'package:uuid/uuid.dart';

/// Shared generator for the `sync_id` client defaults (table definitions)
/// and the v2 -> v3 backfill (app_database.dart).
///
/// ponytail: one plain instance, no caching singleton class. `Uuid()` holds
/// only a small RNG; a per-call `Uuid()` would also be fine, this just keeps
/// the call sites short.
final Uuid uuidGen = Uuid();
```

- [ ] **Step 3: Add the `syncId` column and index to all 5 table classes**

In each of the five table files, add the import, a class-level `@TableIndex`, and the column. The column body is identical in all five; only the index name changes.

`lib/core/database/tables/events_table.dart`:
```dart
import 'package:drift/drift.dart';

import '../uuid.dart';

@DataClassName('EventEntity')
@TableIndex(name: 'idx_events_sync_id', columns: {#syncId}, unique: true)
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortCode => text()();
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text().nullable()();
  BlobColumn get logo => blob().nullable()();
  TextColumn get presenceMode => text()();
  TextColumn get ticketTemplate =>
      text().withDefault(const Constant('standard'))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Stable cross-device identifier for a future multi-device merge.
  // ponytail: nullable in the schema ONLY so the v2 -> v3 migration can add
  // it to already-populated tables (ALTER TABLE ADD COLUMN cannot take a
  // non-constant default). clientDefault fills every new row; the migration
  // backfills old rows; the unique index rejects a second null. Treated as
  // always-present by the app. Spec: docs/superpowers/specs/2026-09-10-lot-d
  // -sync-ready-identifiers-design.md
  TextColumn get syncId => text().nullable().clientDefault(() => uuidGen.v4())();
}
```

Apply the same three additions to the other four files, keeping every existing column and annotation (including `Tickets.uniqueKeys`) exactly as-is:

| File | `@TableIndex` name |
| --- | --- |
| `custom_fields_table.dart` | `idx_custom_fields_sync_id` |
| `beneficiaries_table.dart` | `idx_beneficiaries_sync_id` |
| `tickets_table.dart` | `idx_tickets_sync_id` |
| `checkins_table.dart` | `idx_check_ins_sync_id` |

Do NOT touch `beneficiary_values_table.dart`.

- [ ] **Step 4: Bump the schema version and write the migration**

Edit `lib/core/database/app_database.dart`. Add the import, change `schemaVersion` to `3`, add the `from < 3` branch, and add the private `_addSyncIds` helper. Leave `_openConnection`, `resolveDatabaseFile`, the constructors, the `from < 2` branch, and `beforeOpen` unchanged.

```dart
import 'uuid.dart';
```

```dart
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
```

- [ ] **Step 5: Regenerate the Drift code**

Run:
```bash
fvm dart run build_runner build --delete-conflicting-outputs
```
Expected: `lib/core/database/app_database.g.dart` changes. Confirm by grep that each entity has `syncId`:
```bash
grep -c "String? syncId" lib/core/database/app_database.g.dart
```
Expected: at least `5`. Do not edit the generated file by hand.

- [ ] **Step 6: Run the existing database tests to see what breaks**

Run:
```bash
fvm flutter test test/core/database/
```
Expected: `app_database_test.dart` still passes. `app_database_migration_test.dart` now FAILS: its legacy fixture creates only the `events` table, so `_addSyncIds` throws `no such table: custom_fields` when the v1 database is opened at schema 3. This is expected and fixed in Step 7.

- [ ] **Step 7: Expand the v1 migration fixture to all six tables**

The existing test in `test/core/database/app_database_migration_test.dart` builds a v1 database with only `events`. A real v1 install had all six tables. Replace the single `CREATE TABLE events (...)` statement with all six tables in their v1 shape (v1 = current schema minus `events.ticket_template` and minus every `sync_id`). Keep the rest of the test (the insert, `userVersion = 1`, opening through `AppDatabase`, the three `expect`s) unchanged.

Replace the `legacyDb.execute('''CREATE TABLE events ...''');` block with:
```dart
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
```

- [ ] **Step 8: Run the database tests again**

Run:
```bash
fvm flutter test test/core/database/
```
Expected: all pass. The v1 fixture now has every table, so `_addSyncIds` runs to completion (it backfills zero rows in the five empty tables, one row in `events`) and the three original `expect`s still hold.

- [ ] **Step 9: Add the v2 -> v3 backfill test**

Append a second `test(...)` to `test/core/database/app_database_migration_test.dart`. Build a v2 database (v1 shape plus `events.ticket_template TEXT NOT NULL DEFAULT 'standard'`, still no `sync_id` anywhere), insert two events, one custom field, one beneficiary, one ticket, one check-in, stamp `userVersion = 2`, open through `AppDatabase.forTesting`, and assert every migrated row has a distinct, well-formed `syncId`.

```dart
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
```

- [ ] **Step 10: Add the clientDefault and unique-index unit tests**

Append two `test(...)` cases to `test/core/database/app_database_test.dart` (it already imports `AppDatabase` and `NativeDatabase`).

```dart
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
```

- [ ] **Step 11: Run the full test suite**

Run:
```bash
fvm flutter test
```
Expected: every test passes (158 existing + the new database tests). If any pre-existing test constructs an `EventsCompanion`/`CheckInsCompanion` etc. positionally, the added trailing optional `syncId` will not break it (companions use named params); investigate any failure before continuing.

- [ ] **Step 12: Analyze**

Run:
```bash
fvm flutter analyze
```
Expected: no new warnings or infos. Fix any that point at the changed files.

- [ ] **Step 13: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/database/ test/core/database/
git commit -m "Add a stable sync_id to the five sync-tracked tables"
```

---

## Task 2: Surface `syncId` on the domain objects

**Files:**
- Modify: `lib/features/events/domain/event.dart`
- Modify: `lib/features/events/domain/custom_field.dart`
- Modify: `lib/features/beneficiaries/domain/beneficiary.dart`
- Modify: `lib/features/tickets/domain/ticket.dart`
- Modify: `lib/features/checkin/domain/check_in.dart`
- Modify: `lib/features/events/data/drift_event_repository.dart`
- Modify: `lib/features/beneficiaries/data/drift_beneficiary_repository.dart`
- Modify: `lib/features/tickets/data/drift_ticket_repository.dart`
- Modify: `lib/features/checkin/data/drift_check_in_repository.dart`
- Test: `test/features/events/data/drift_event_repository_test.dart`
- Test: `test/features/beneficiaries/data/drift_beneficiary_repository_test.dart`
- Test: `test/features/tickets/data/drift_ticket_repository_test.dart`
- Test: `test/features/checkin/data/drift_check_in_repository_test.dart`

**Interfaces:**
- Consumes from Task 1: each entity class exposes `String? get syncId`.
- Produces: `Event`, `CustomField`, `Beneficiary`, `Ticket`, `CheckIn` each expose a `final String? syncId;` field, populated by their repository mapper. Nothing reads it yet; a future merge will.

- [ ] **Step 1: Write the failing repository test assertions**

In each of the four `drift_*_repository_test.dart` files, find the existing test that creates a record and reads it back as a domain object (for events, the "creates an event and reads it back" test that calls `repository.getEvent(id)`). Add one assertion that the returned domain object's `syncId` is a non-null, non-empty String. Example for `drift_event_repository_test.dart`:
```dart
    expect(event.syncId, isNotNull);
    expect(event.syncId, isNotEmpty);
```
For the beneficiary repository, assert on the object returned by `getBeneficiary`. For tickets, on `getTicket`. For check-ins, on the `CheckIn` inside the `CheckInRecorded` outcome from `recordCheckIn` (or `watchCheckInsForEvent`'s first emission, whichever the existing test already uses).

- [ ] **Step 2: Run the new assertions to verify they fail**

Run:
```bash
fvm flutter test test/features/events/data/drift_event_repository_test.dart test/features/beneficiaries/data/drift_beneficiary_repository_test.dart test/features/tickets/data/drift_ticket_repository_test.dart test/features/checkin/data/drift_check_in_repository_test.dart
```
Expected: FAIL to compile ("The named parameter 'syncId' isn't defined" is not it yet, the failure is `The getter 'syncId' isn't defined for the type 'Event'`), because the domain classes have no `syncId` field.

- [ ] **Step 3: Add the `syncId` field to the five domain classes**

Add an optional named parameter and a `final String? syncId;` field to `Event`, `CustomField`, `Beneficiary`, `Ticket`, `CheckIn`. Do NOT add it to `NewCustomField`, `NewBeneficiary`, or any other input value object. Do NOT add it to `CustomField`'s `operator ==` / `hashCode` (those compare `NewCustomField`; `CustomField` has no equality override, leave it that way).

`lib/features/checkin/domain/check_in.dart` becomes:
```dart
class CheckIn {
  const CheckIn({
    required this.id,
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
    this.syncId,
  });

  final int id;
  final int ticketId;
  final int eventId;
  final DateTime scannedAt;

  /// Stable cross-device identifier. Null only for domain objects built
  /// outside a repository (tests); rows read from the database always carry
  /// one. A future merge asserts non-null at its point of use.
  final String? syncId;
}
```
Apply the same shape to the other four: add `this.syncId,` as the last constructor entry and `final String? syncId;` as the last field, with the same doc comment on the first one you edit (a one-line `// stable cross-device id, see check_in.dart` reference is enough on the rest).

- [ ] **Step 4: Populate `syncId` in the four repository mappers**

- `lib/features/events/data/drift_event_repository.dart`: in `_toEvent`, add `syncId: row.syncId,`. In `_toCustomField`, add `syncId: row.syncId,`.
- `lib/features/beneficiaries/data/drift_beneficiary_repository.dart`: in `_groupRows`, the `Beneficiary(...)` constructor call, add `syncId: b.syncId,`.
- `lib/features/tickets/data/drift_ticket_repository.dart`: in `_toTicket`, add `syncId: row.syncId,`.
- `lib/features/checkin/data/drift_check_in_repository.dart`: in `_toCheckIn`, add `syncId: row.syncId,`.

- [ ] **Step 5: Run the repository tests to verify they pass**

Run:
```bash
fvm flutter test test/features/events/data/drift_event_repository_test.dart test/features/beneficiaries/data/drift_beneficiary_repository_test.dart test/features/tickets/data/drift_ticket_repository_test.dart test/features/checkin/data/drift_check_in_repository_test.dart
```
Expected: PASS.

- [ ] **Step 6: Run the full suite and analyze**

Run:
```bash
fvm flutter test && fvm flutter analyze
```
Expected: all tests pass, no new analyzer output. Existing tests that build `Event(...)`, `Ticket(...)`, etc. without `syncId` keep compiling because the parameter is optional.

- [ ] **Step 7: Commit**

```bash
git add lib/features test/features
git commit -m "Carry sync_id through to the domain objects"
```

---

## Self-Review

**Spec coverage:**
- 5 tables get `syncId`, `BeneficiaryValues` excluded - Task 1 Step 3 (explicit "Do NOT touch beneficiary_values_table.dart"). ✅
- Column shape `text().nullable().clientDefault(...)` - Task 1 Step 3. ✅
- Unique index, fresh installs via `@TableIndex` + `createAll`, upgrades via `customStatement` - Task 1 Steps 3 and 4. ✅
- Domain field `String? syncId`, optional, not on input objects - Task 2 Step 3. ✅
- Migration v2 -> v3: addColumn, per-row UUID backfill, then indexes - Task 1 Step 4. ✅
- `uuid` dependency + one shared instance - Task 1 Steps 1 and 2. ✅
- Migration test (v2 fixture, distinct well-formed UUIDs) - Task 1 Step 9. ✅
- clientDefault unit test - Task 1 Step 10. ✅
- Unique-index test - Task 1 Step 10. ✅
- Regenerate `.g.dart` - Task 1 Step 5. ✅
- All 158 existing tests still pass - Task 1 Step 11, Task 2 Step 6. ✅
- Out of scope (no merge/sync/export/UI, `id`/PK/FK/routes/`shortCode` untouched) - honored; no task touches those. ✅
- Not covered by spec but required for correctness: the existing v1 migration fixture only had `events` and would break once the migration touches five tables - Task 1 Step 7 expands it. Called out as a necessary side effect.

**Placeholder scan:** No TBD / "handle errors appropriately" / "write tests for the above" - every code and test block is literal. ✅

**Type consistency:** `uuidGen` (`Uuid`) used identically in table files and migration. `syncId` is `String?` in entities (generated), `String?` in domain, `Value<String?>` in companions - consistent. Index names match between `@TableIndex` annotations (Step 3) and `customStatement` (Step 4). Mapper field name `syncId` matches the domain constructor parameter. ✅

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-09-10-lot-d-sync-ready-identifiers.md`. Two execution options:

1. **Subagent-Driven (recommended)** - a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - execute tasks in this session with checkpoints for review.

Which approach?
