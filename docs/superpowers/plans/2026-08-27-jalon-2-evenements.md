# Jalon 2 - Evenements - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the full Events feature (section 1 of the cahier des charges): create/edit/archive events, define custom fields per event, choose the presence-control mode, and browse/restore/permanently-delete archived events. Replaces the jalon 1 placeholder home screen with the real events list.

**Architecture:** Feature-first `lib/features/events/` (domain / data / presentation), same repository-interface pattern as the socle design: screens and Riverpod providers depend only on `EventRepository`, never on Drift directly. `DriftEventRepository` is the only class that imports `AppDatabase`.

**Tech Stack:** Flutter 3.44.7 (FVM) + Riverpod + go_router + Drift + `image_picker` (new dependency this jalon) + `intl` (date formatting, already present).

## Global Constraints

- Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Never hand-edit generated `.g.dart` files. Regenerate with `fvm dart run build_runner build --delete-conflicting-outputs`.
- Never hand-edit generated localization files. Regenerate with `fvm flutter gen-l10n` after editing `lib/l10n/app_en.arb` / `lib/l10n/app_fr.arb`. English is the template locale; every new key needs both an `en` and an `fr` value.
- No em dashes (tirets cadratins) in code, comments, or commit messages.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits.
- Application id, theme tokens (`AppColors`), and the FR/EN i18n setup are already in place (jalon 1), reuse them, do not redefine them.
- Custom fields are editable until the first ticket exists for the event (`EventRepository.canEditCustomFields`); presence mode is editable until the first check-in exists (`EventRepository.canEditPresenceMode`). Both are always `true` in practice this jalon (no ticket/check-in writer exists yet), the checks exist so the lock activates automatically once jalon 4/6 land.
- `shortCode` is derived from the row's autoincrement id (`'EVT$id'`), assigned right after insert, inside the same transaction. Never invent a separate counter.

---

### Task 1: Cascade deletes on existing foreign keys

**Context:** jalon 1 turned on `PRAGMA foreign_keys = ON`. Every child table (`CustomFields`, `Beneficiaries`, `BeneficiaryValues`, `Tickets`, `CheckIns`) references `Events` (or another child) with a plain `.references(...)`, which defaults to `RESTRICT`: deleting a parent row with existing children now throws instead of silently succeeding. This jalon's "supprimer definitivement" action (from Archives) needs to delete an `Events` row that may have `CustomFields` children, so this must be fixed first. Making all FK relationships cascade now (while no real data exists yet) is a one-time correctness fix, cheaper than patching it piecemeal as beneficiaries/tickets/check-ins get built in later jalons.

**Files:**
- Modify: `lib/core/database/tables/custom_fields_table.dart`
- Modify: `lib/core/database/tables/beneficiaries_table.dart`
- Modify: `lib/core/database/tables/beneficiary_values_table.dart`
- Modify: `lib/core/database/tables/tickets_table.dart`
- Modify: `lib/core/database/tables/checkins_table.dart`
- Modify (generated): `lib/core/database/app_database.g.dart`
- Test: `test/core/database/app_database_test.dart` (add a case to the existing file)

**Interfaces:**
- Consumes: the six tables and `AppDatabase` from jalon 1.
- Produces: deleting a row now cascades to every table that references it (directly or transitively), so `EventRepository.deleteEventPermanently` (Task 4) can delete an `Events` row without manually deleting its children first.

- [ ] **Step 1: Write the failing test**

Add this test to the existing file (do not remove the two tests already there):

```dart
// test/core/database/app_database_test.dart (append inside main(), after the existing tests)
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
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/database/app_database_test.dart
```

Expected: FAIL. The delete throws a foreign key constraint error instead of cascading (the custom field row still references the deleted event).

- [ ] **Step 3: Add `onDelete: KeyAction.cascade` to every foreign key**

```dart
// lib/core/database/tables/custom_fields_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';

@DataClassName('CustomFieldEntity')
class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  // plain text ('text' | 'number'), same reasoning as Events.presenceMode.
  TextColumn get fieldType => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get showOnTicket => boolean().withDefault(const Constant(false))();
}
```

```dart
// lib/core/database/tables/beneficiaries_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';

@DataClassName('BeneficiaryEntity')
class Beneficiaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

```dart
// lib/core/database/tables/beneficiary_values_table.dart
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
```

```dart
// lib/core/database/tables/tickets_table.dart
import 'package:drift/drift.dart';

import 'beneficiaries_table.dart';
import 'events_table.dart';

@DataClassName('TicketEntity')
class Tickets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId =>
      integer().references(Beneficiaries, #id, onDelete: KeyAction.cascade)();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get readableId => text()();
  TextColumn get randomPart => text()();
  TextColumn get qrPayload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {eventId, readableId},
      ];
}
```

```dart
// lib/core/database/tables/checkins_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';
import 'tickets_table.dart';

@DataClassName('CheckInEntity')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId =>
      integer().references(Tickets, #id, onDelete: KeyAction.cascade)();
  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}
```

Regenerate:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: exit code 0, `app_database.g.dart` now emits `ON DELETE CASCADE` for all eight foreign keys.

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/database/app_database_test.dart
```

Expected: PASS (all 3 tests in the file, including the new one and the two from jalon 1).

- [ ] **Step 5: Commit**

```bash
git add lib/core/database test/core/database
git commit -m "Cascade deletes on all foreign keys"
```

---

### Task 2: Add the image_picker dependency

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `image_picker` available as an import for Task 7 (event form logo picker).

- [ ] **Step 1: Add the dependency**

```bash
fvm flutter pub add image_picker
```

Expected: exit code 0, `image_picker` listed under `dependencies:` in `pubspec.yaml`.

- [ ] **Step 2: Verify resolution and static analysis**

```bash
fvm flutter pub get
fvm flutter analyze
```

Expected: both exit 0, no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "Add image_picker dependency"
```

---

### Task 3: Domain models

**Files:**
- Create: `lib/features/events/domain/presence_mode.dart`
- Create: `lib/features/events/domain/custom_field_type.dart`
- Create: `lib/features/events/domain/event.dart`
- Create: `lib/features/events/domain/custom_field.dart`
- Test: `test/features/events/domain/event_test.dart`

**Interfaces:**
- Produces: `PresenceMode` (`simple`, `multiple`), `CustomFieldType` (`text`, `number`), `Event` (with `isArchived` getter), `CustomField`, `NewCustomField`. Task 4 (repository) and every presentation task consume these directly; nothing in this feature imports Drift's generated row types (`EventEntity`, `CustomFieldEntity`) outside `DriftEventRepository`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/events/domain/event_test.dart
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Event.isArchived reflects archivedAt', () {
    final active = Event(
      id: 1,
      shortCode: 'EVT1',
      name: 'Gala',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(active.isArchived, isFalse);

    final archived = Event(
      id: 2,
      shortCode: 'EVT2',
      name: 'Old event',
      date: DateTime(2025, 1, 1),
      presenceMode: PresenceMode.multiple,
      archivedAt: DateTime(2026, 2, 1),
      createdAt: DateTime(2025, 1, 1),
    );
    expect(archived.isArchived, isTrue);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/domain/event_test.dart
```

Expected: FAIL (`package:dif_pass/features/events/domain/event.dart` does not exist).

- [ ] **Step 3: Implement the domain models**

```dart
// lib/features/events/domain/presence_mode.dart
enum PresenceMode { simple, multiple }
```

```dart
// lib/features/events/domain/custom_field_type.dart
enum CustomFieldType { text, number }
```

```dart
// lib/features/events/domain/event.dart
import 'dart:typed_data';

import 'presence_mode.dart';

class Event {
  const Event({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.date,
    this.location,
    this.logo,
    required this.presenceMode,
    this.archivedAt,
    required this.createdAt,
  });

  final int id;
  final String shortCode;
  final String name;
  final DateTime date;
  final String? location;
  final Uint8List? logo;
  final PresenceMode presenceMode;
  final DateTime? archivedAt;
  final DateTime createdAt;

  bool get isArchived => archivedAt != null;
}
```

```dart
// lib/features/events/domain/custom_field.dart
import 'custom_field_type.dart';

class CustomField {
  const CustomField({
    required this.id,
    required this.eventId,
    required this.label,
    required this.type,
    required this.sortOrder,
    required this.showOnTicket,
  });

  final int id;
  final int eventId;
  final String label;
  final CustomFieldType type;
  final int sortOrder;
  final bool showOnTicket;
}

class NewCustomField {
  const NewCustomField({
    required this.label,
    required this.type,
    required this.sortOrder,
    this.showOnTicket = false,
  });

  final String label;
  final CustomFieldType type;
  final int sortOrder;
  final bool showOnTicket;
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/domain/event_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/events/domain test/features/events/domain
git commit -m "Add events domain models"
```

---

### Task 4: EventRepository interface and Drift implementation

**Files:**
- Create: `lib/features/events/data/event_repository.dart`
- Create: `lib/features/events/data/drift_event_repository.dart`
- Test: `test/features/events/data/drift_event_repository_test.dart`

**Interfaces:**
- Consumes: `Event`, `CustomField`, `NewCustomField`, `PresenceMode`, `CustomFieldType` (Task 3); `AppDatabase` (jalon 1, with cascading deletes from Task 1).
- Produces: `EventRepository` (abstract) with `watchActiveEvents()`, `watchArchivedEvents()`, `getEvent(int)`, `watchCustomFields(int)`, `createEvent(...)`, `updateEvent(...)`, `canEditCustomFields(int)`, `replaceCustomFields(int, List<NewCustomField>)`, `canEditPresenceMode(int)`, `archiveEvent(int)`, `restoreEvent(int)`, `deleteEventPermanently(int)`. `DriftEventRepository implements EventRepository`. Task 5 (providers) and Task 9 (main wiring context) depend on these exact method names and signatures.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/events/data/drift_event_repository_test.dart
import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/events/data/drift_event_repository.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftEventRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftEventRepository(db);
  });

  tearDown(() => db.close());

  test('createEvent derives a unique shortCode from the inserted id', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    final event = await repository.getEvent(id);
    expect(event.shortCode, 'EVT$id');
    expect(event.name, 'Gala DIF 2026');
    expect(event.presenceMode, PresenceMode.simple);
    expect(event.isArchived, isFalse);
  });

  test('createEvent also creates the given custom fields', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [
        NewCustomFieldFixture(),
      ],
    );

    final fields = await repository.watchCustomFields(id).first;
    expect(fields, hasLength(1));
    expect(fields.single.label, 'Table number');
    expect(fields.single.type, CustomFieldType.number);
    expect(fields.single.showOnTicket, isTrue);
  });

  test('watchActiveEvents excludes archived events and sorts by date ascending', () async {
    final laterId = await repository.createEvent(
      name: 'Later event',
      date: DateTime(2026, 12, 20),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final soonerId = await repository.createEvent(
      name: 'Sooner event',
      date: DateTime(2026, 12, 5),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final archivedId = await repository.createEvent(
      name: 'Archived event',
      date: DateTime(2026, 11, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    await repository.archiveEvent(archivedId);

    final active = await repository.watchActiveEvents().first;
    expect(active.map((e) => e.id).toList(), [soonerId, laterId]);
  });

  test('watchArchivedEvents returns only archived events', () async {
    final activeId = await repository.createEvent(
      name: 'Active event',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final archivedId = await repository.createEvent(
      name: 'Archived event',
      date: DateTime(2026, 11, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    await repository.archiveEvent(archivedId);

    final archived = await repository.watchArchivedEvents().first;
    expect(archived.map((e) => e.id).toList(), [archivedId]);
    expect(archived.single.isArchived, isTrue);

    final active = await repository.watchActiveEvents().first;
    expect(active.map((e) => e.id).toList(), [activeId]);
  });

  test('archiveEvent then restoreEvent clears archivedAt', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    await repository.archiveEvent(id);
    expect((await repository.getEvent(id)).isArchived, isTrue);

    await repository.restoreEvent(id);
    expect((await repository.getEvent(id)).isArchived, isFalse);
  });

  test('canEditCustomFields is true with no tickets and false once one exists', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    expect(await repository.canEditCustomFields(id), isTrue);

    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: id, name: 'Jane Doe'),
        );
    await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: id,
            readableId: '0001',
            randomPart: 'X7K9',
            qrPayload: '${(await repository.getEvent(id)).shortCode}-0001-X7K9',
          ),
        );

    expect(await repository.canEditCustomFields(id), isFalse);
  });

  test('canEditPresenceMode is true with no check-ins and false once one exists', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    expect(await repository.canEditPresenceMode(id), isTrue);

    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: id, name: 'Jane Doe'),
        );
    final ticketId = await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: id,
            readableId: '0001',
            randomPart: 'X7K9',
            qrPayload: 'EVT-0001-X7K9',
          ),
        );
    await db.into(db.checkIns).insert(
          CheckInsCompanion.insert(ticketId: ticketId, eventId: id),
        );

    expect(await repository.canEditPresenceMode(id), isFalse);
  });

  test('replaceCustomFields replaces the full set for an event', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [NewCustomFieldFixture()],
    );

    await repository.replaceCustomFields(id, const [
      NewCustomField(
        label: 'Category',
        type: CustomFieldType.text,
        sortOrder: 0,
      ),
    ]);

    final fields = await repository.watchCustomFields(id).first;
    expect(fields, hasLength(1));
    expect(fields.single.label, 'Category');
    expect(fields.single.type, CustomFieldType.text);
  });

  test('deleteEventPermanently removes the event and its custom fields', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [NewCustomFieldFixture()],
    );
    await repository.archiveEvent(id);

    await repository.deleteEventPermanently(id);

    expect(await repository.watchArchivedEvents().first, isEmpty);
    expect(await (db.select(db.customFields)).get(), isEmpty);
  });
}

// Small named fixture so every test that just needs "one custom field"
// does not repeat the same three-argument constructor call.
class NewCustomFieldFixture extends NewCustomField {
  const NewCustomFieldFixture()
      : super(
          label: 'Table number',
          type: CustomFieldType.number,
          sortOrder: 0,
          showOnTicket: true,
        );
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/data/drift_event_repository_test.dart
```

Expected: FAIL (`package:dif_pass/features/events/data/drift_event_repository.dart` does not exist).

- [ ] **Step 3: Implement the repository**

```dart
// lib/features/events/data/event_repository.dart
import 'dart:typed_data';

import '../domain/custom_field.dart';
import '../domain/event.dart';
import '../domain/presence_mode.dart';

abstract class EventRepository {
  Stream<List<Event>> watchActiveEvents();
  Stream<List<Event>> watchArchivedEvents();
  Future<Event> getEvent(int id);
  Stream<List<CustomField>> watchCustomFields(int eventId);

  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  });

  Future<void> updateEvent(
    int id, {
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
  });

  Future<bool> canEditCustomFields(int eventId);
  Future<void> replaceCustomFields(int eventId, List<NewCustomField> customFields);

  Future<bool> canEditPresenceMode(int eventId);

  Future<void> archiveEvent(int id);
  Future<void> restoreEvent(int id);
  Future<void> deleteEventPermanently(int id);
}
```

```dart
// lib/features/events/data/drift_event_repository.dart
import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/custom_field.dart';
import '../domain/custom_field_type.dart';
import '../domain/event.dart';
import '../domain/presence_mode.dart';
import 'event_repository.dart';

class DriftEventRepository implements EventRepository {
  DriftEventRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Event>> watchActiveEvents() {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.archivedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.date)]);
    return query.watch().map((rows) => rows.map(_toEvent).toList());
  }

  @override
  Stream<List<Event>> watchArchivedEvents() {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.archivedAt.isNotNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.archivedAt)]);
    return query.watch().map((rows) => rows.map(_toEvent).toList());
  }

  @override
  Future<Event> getEvent(int id) async {
    final row = await (_db.select(_db.events)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _toEvent(row);
  }

  @override
  Stream<List<CustomField>> watchCustomFields(int eventId) {
    final query = _db.select(_db.customFields)
      ..where((tbl) => tbl.eventId.equals(eventId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toCustomField).toList());
  }

  @override
  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  }) {
    return _db.transaction(() async {
      final id = await _db.into(_db.events).insert(
            EventsCompanion.insert(
              shortCode: '',
              name: name,
              date: date,
              location: Value(location),
              logo: Value(logo),
              presenceMode: presenceMode.name,
            ),
          );

      await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id)))
          .write(EventsCompanion(shortCode: Value('EVT$id')));

      await _insertCustomFields(id, customFields);

      return id;
    });
  }

  @override
  Future<void> updateEvent(
    int id, {
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
  }) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id))).write(
      EventsCompanion(
        name: Value(name),
        date: Value(date),
        location: Value(location),
        logo: Value(logo),
        presenceMode: Value(presenceMode.name),
      ),
    );
  }

  @override
  Future<bool> canEditCustomFields(int eventId) async {
    final anyTicket = await (_db.select(_db.tickets)
          ..where((tbl) => tbl.eventId.equals(eventId))
          ..limit(1))
        .getSingleOrNull();
    return anyTicket == null;
  }

  @override
  Future<void> replaceCustomFields(
    int eventId,
    List<NewCustomField> customFields,
  ) {
    return _db.transaction(() async {
      await (_db.delete(_db.customFields)
            ..where((tbl) => tbl.eventId.equals(eventId)))
          .go();
      await _insertCustomFields(eventId, customFields);
    });
  }

  @override
  Future<bool> canEditPresenceMode(int eventId) async {
    final anyCheckIn = await (_db.select(_db.checkIns)
          ..where((tbl) => tbl.eventId.equals(eventId))
          ..limit(1))
        .getSingleOrNull();
    return anyCheckIn == null;
  }

  @override
  Future<void> archiveEvent(int id) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id)))
        .write(EventsCompanion(archivedAt: Value(DateTime.now())));
  }

  @override
  Future<void> restoreEvent(int id) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(id)))
        .write(const EventsCompanion(archivedAt: Value(null)));
  }

  @override
  Future<void> deleteEventPermanently(int id) async {
    await (_db.delete(_db.events)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> _insertCustomFields(
    int eventId,
    List<NewCustomField> customFields,
  ) async {
    for (final field in customFields) {
      await _db.into(_db.customFields).insert(
            CustomFieldsCompanion.insert(
              eventId: eventId,
              label: field.label,
              fieldType: field.type.name,
              sortOrder: field.sortOrder,
              showOnTicket: Value(field.showOnTicket),
            ),
          );
    }
  }

  Event _toEvent(EventEntity row) {
    return Event(
      id: row.id,
      shortCode: row.shortCode,
      name: row.name,
      date: row.date,
      location: row.location,
      logo: row.logo,
      presenceMode: PresenceMode.values.byName(row.presenceMode),
      archivedAt: row.archivedAt,
      createdAt: row.createdAt,
    );
  }

  CustomField _toCustomField(CustomFieldEntity row) {
    return CustomField(
      id: row.id,
      eventId: row.eventId,
      label: row.label,
      type: CustomFieldType.values.byName(row.fieldType),
      sortOrder: row.sortOrder,
      showOnTicket: row.showOnTicket,
    );
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/data/drift_event_repository_test.dart
```

Expected: PASS (all 9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/events/data test/features/events/data
git commit -m "Add EventRepository and its Drift implementation"
```

---

### Task 5: Riverpod providers and a shared test fake

**Files:**
- Create: `lib/features/events/presentation/providers/event_providers.dart`
- Create: `test/features/events/fake_event_repository.dart`
- Test: `test/features/events/presentation/providers/event_providers_test.dart`

**Interfaces:**
- Consumes: `EventRepository`, `DriftEventRepository` (Task 4); `appDatabaseProvider` (jalon 1, `lib/core/database/database_provider.dart`).
- Produces: `eventRepositoryProvider` (`Provider<EventRepository>`), `activeEventsProvider` (`StreamProvider<List<Event>>`), `archivedEventsProvider` (`StreamProvider<List<Event>>`), `customFieldsProvider` (`StreamProvider.family<List<CustomField>, int>`). `FakeEventRepository` (in `test/features/events/fake_event_repository.dart`, NOT under `lib/`, test-only) implements `EventRepository` in memory with a public `events` getter for assertions; Tasks 6, 7, 8, 9 all import it and override `eventRepositoryProvider` with it in their widget tests instead of touching the real database.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/events/presentation/providers/event_providers_test.dart
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_event_repository.dart';

void main() {
  test('activeEventsProvider streams events from the overridden repository', () async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [eventRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final events = await container.read(activeEventsProvider.future);
    expect(events, hasLength(1));
    expect(events.single.name, 'Gala DIF 2026');
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/providers/event_providers_test.dart
```

Expected: FAIL (neither `event_providers.dart` nor `fake_event_repository.dart` exist).

- [ ] **Step 3: Implement the providers and the fake**

```dart
// lib/features/events/presentation/providers/event_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_event_repository.dart';
import '../../data/event_repository.dart';
import '../../domain/custom_field.dart';
import '../../domain/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftEventRepository(db);
});

final activeEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchActiveEvents();
});

final archivedEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchArchivedEvents();
});

final customFieldsProvider =
    StreamProvider.family<List<CustomField>, int>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchCustomFields(eventId);
});
```

```dart
// test/features/events/fake_event_repository.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:dif_pass/features/events/data/event_repository.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';

/// In-memory EventRepository for widget/provider tests. Not shipped in the
/// app, lives under test/ only.
class FakeEventRepository implements EventRepository {
  FakeEventRepository({List<Event>? events})
      : _events = List.of(events ?? const []);

  final List<Event> _events;
  final Map<int, List<CustomField>> _customFields = {};
  final _activeController = StreamController<List<Event>>.broadcast();
  final _archivedController = StreamController<List<Event>>.broadcast();
  int _nextId = 1000;

  List<Event> get events => List.unmodifiable(_events);

  void _emit() {
    _activeController.add(_events.where((e) => !e.isArchived).toList());
    _archivedController.add(_events.where((e) => e.isArchived).toList());
  }

  @override
  Stream<List<Event>> watchActiveEvents() {
    Future.microtask(_emit);
    return _activeController.stream;
  }

  @override
  Stream<List<Event>> watchArchivedEvents() {
    Future.microtask(_emit);
    return _archivedController.stream;
  }

  @override
  Future<Event> getEvent(int id) async =>
      _events.firstWhere((e) => e.id == id);

  @override
  Stream<List<CustomField>> watchCustomFields(int eventId) async* {
    yield _customFields[eventId] ?? const [];
  }

  @override
  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  }) async {
    final id = _nextId++;
    _events.add(Event(
      id: id,
      shortCode: 'EVT$id',
      name: name,
      date: date,
      location: location,
      logo: logo,
      presenceMode: presenceMode,
      createdAt: DateTime.now(),
    ));
    _customFields[id] = [
      for (final field in customFields)
        CustomField(
          id: _nextId++,
          eventId: id,
          label: field.label,
          type: field.type,
          sortOrder: field.sortOrder,
          showOnTicket: field.showOnTicket,
        ),
    ];
    _emit();
    return id;
  }

  @override
  Future<void> updateEvent(
    int id, {
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
  }) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: name,
      date: date,
      location: location,
      logo: logo,
      presenceMode: presenceMode,
      archivedAt: existing.archivedAt,
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<bool> canEditCustomFields(int eventId) async => true;

  @override
  Future<void> replaceCustomFields(
    int eventId,
    List<NewCustomField> customFields,
  ) async {
    _customFields[eventId] = [
      for (final field in customFields)
        CustomField(
          id: _nextId++,
          eventId: eventId,
          label: field.label,
          type: field.type,
          sortOrder: field.sortOrder,
          showOnTicket: field.showOnTicket,
        ),
    ];
  }

  @override
  Future<bool> canEditPresenceMode(int eventId) async => true;

  @override
  Future<void> archiveEvent(int id) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: existing.name,
      date: existing.date,
      location: existing.location,
      logo: existing.logo,
      presenceMode: existing.presenceMode,
      archivedAt: DateTime.now(),
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<void> restoreEvent(int id) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: existing.name,
      date: existing.date,
      location: existing.location,
      logo: existing.logo,
      presenceMode: existing.presenceMode,
      createdAt: existing.createdAt,
    );
    _emit();
  }

  @override
  Future<void> deleteEventPermanently(int id) async {
    _events.removeWhere((e) => e.id == id);
    _customFields.remove(id);
    _emit();
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/providers/event_providers_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/events/presentation/providers test/features/events/fake_event_repository.dart test/features/events/presentation/providers
git commit -m "Add event providers and a fake repository for tests"
```

---

### Task 6: Events list screen

**Files:**
- Create: `lib/features/events/presentation/widgets/event_card.dart`
- Create: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`

**Interfaces:**
- Consumes: `activeEventsProvider`, `eventRepositoryProvider` (Task 5); `AppColors` (jalon 1); `FakeEventRepository` (Task 5, test-only).
- Produces: `EventCard` widget (`event`, `onTap` params). `EventsListScreen` (no params), the widget Task 9 wires to route `/`.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "eventsListTitle": "Events",
  "eventsArchiveAction": "Archives",
  "eventsEmptyState": "No events yet. Create one to get started.",
  "eventsNewAction": "New event"
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "eventsListTitle": "Evenements",
  "eventsArchiveAction": "Archives",
  "eventsEmptyState": "Aucun evenement pour l'instant. Creez-en un pour commencer.",
  "eventsNewAction": "Nouvel evenement"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/events/presentation/screens/events_list_screen_test.dart
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/events/presentation/screens/events_list_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_event_repository.dart';

Widget _wrap(Widget child, FakeEventRepository fake) {
  return ProviderScope(
    overrides: [eventRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no active events',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const EventsListScreen(), FakeEventRepository()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No events yet. Create one to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a card per active event', (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventsListScreen(), fake));
    await tester.pumpAndSettle();

    expect(find.text('Gala DIF 2026'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: FAIL (`events_list_screen.dart` does not exist).

- [ ] **Step 4: Implement the widget and the screen**

```dart
// lib/features/events/presentation/widgets/event_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({required this.event, required this.onTap, super.key});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = DateFormat.yMMMMd(locale).format(event.date);
    final subtitleParts = [
      dateLabel,
      if (event.location != null && event.location!.trim().isNotEmpty)
        event.location!,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(event.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitleParts.join(' - ')),
        leading: CircleAvatar(
          backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
          backgroundImage: event.logo != null ? MemoryImage(event.logo!) : null,
          child: event.logo == null
              ? const Icon(Icons.event, color: AppColors.indigo)
              : null,
        ),
      ),
    );
  }
}
```

```dart
// lib/features/events/presentation/screens/events_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/event_providers.dart';
import '../widgets/event_card.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(activeEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: l10n.eventsArchiveAction,
            onPressed: () => context.push('/events/archives'),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.eventsEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                onTap: () => context.push('/events/${event.id}/edit'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.eventsNewAction),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/widgets/event_card.dart lib/features/events/presentation/screens/events_list_screen.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Add events list screen"
```

---

### Task 7: Event form screen (create and edit)

**Files:**
- Create: `lib/features/events/presentation/widgets/custom_field_editor.dart`
- Create: `lib/features/events/presentation/screens/event_form_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/event_form_screen_test.dart`

**Interfaces:**
- Consumes: `eventRepositoryProvider` (Task 5); `PresenceMode`, `CustomFieldType`, `NewCustomField` (Task 3); `image_picker` (Task 2).
- Produces: `CustomFieldEditor` widget (`fields`, `locked`, `onAdd`, `onRemove`, `onChanged` params). `EventFormScreen({int? eventId})`: `null` means create, a value means edit. Task 9 wires this to routes `/events/new` and `/events/:id/edit`.

**Note on the frontend-design skill:** the widgets below use plain Material components and the DIF theme's default styling (`Theme.of(context)`, `AppColors`). Before or while implementing this task, consult the frontend-design skill for spacing, field styling, and layout polish per the project's rule to avoid a generic "default Flutter template" look, keeping the structure and behavior below intact.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "eventFormTitleCreate": "New event",
  "eventFormTitleEdit": "Edit event",
  "eventFormNameLabel": "Name",
  "eventFormNameRequired": "Name is required",
  "eventFormDateLabel": "Date",
  "eventFormLocationLabel": "Location",
  "eventFormLogoAction": "Choose a logo",
  "eventFormPresenceModeLabel": "Presence mode",
  "eventFormPresenceModeSimple": "Simple presence",
  "eventFormPresenceModeMultiple": "Multiple entries",
  "eventFormCustomFieldsLabel": "Custom fields",
  "eventFormAddFieldAction": "Add field",
  "eventFormFieldLabelHint": "Label",
  "eventFormCustomFieldsLocked": "Locked: tickets already exist for this event",
  "eventFormSaveAction": "Save"
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "eventFormTitleCreate": "Nouvel evenement",
  "eventFormTitleEdit": "Modifier l'evenement",
  "eventFormNameLabel": "Nom",
  "eventFormNameRequired": "Le nom est obligatoire",
  "eventFormDateLabel": "Date",
  "eventFormLocationLabel": "Lieu",
  "eventFormLogoAction": "Choisir un logo",
  "eventFormPresenceModeLabel": "Mode de presence",
  "eventFormPresenceModeSimple": "Presence simple",
  "eventFormPresenceModeMultiple": "Entrees et sorties multiples",
  "eventFormCustomFieldsLabel": "Champs personnalises",
  "eventFormAddFieldAction": "Ajouter un champ",
  "eventFormFieldLabelHint": "Libelle",
  "eventFormCustomFieldsLocked": "Verrouille : des tickets existent deja pour cet evenement",
  "eventFormSaveAction": "Enregistrer"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/events/presentation/screens/event_form_screen_test.dart
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/events/presentation/screens/event_form_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_event_repository.dart';

Widget _wrap(Widget child, FakeEventRepository fake) {
  return ProviderScope(
    overrides: [eventRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows a validation error when the name is empty', (tester) async {
    await tester.pumpWidget(_wrap(const EventFormScreen(), FakeEventRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('creates an event with the entered name', (tester) async {
    final fake = FakeEventRepository();

    await tester.pumpWidget(_wrap(const EventFormScreen(), fake));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Gala DIF 2026');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.events, hasLength(1));
    expect(fake.events.single.name, 'Gala DIF 2026');
  });

  testWidgets('editing an existing event pre-fills the name field', (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 42,
        shortCode: 'EVT42',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        location: 'Lome',
        presenceMode: PresenceMode.multiple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventFormScreen(eventId: 42), fake));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(nameField.controller?.text, 'Gala DIF 2026');
    expect(find.text('Edit event'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/event_form_screen_test.dart
```

Expected: FAIL (`event_form_screen.dart` does not exist).

- [ ] **Step 4: Implement the widget and the screen**

```dart
// lib/features/events/presentation/widgets/custom_field_editor.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/custom_field.dart';
import '../../domain/custom_field_type.dart';

class CustomFieldEditor extends StatelessWidget {
  const CustomFieldEditor({
    required this.fields,
    required this.locked,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final List<NewCustomField> fields;
  final bool locked;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, NewCustomField field) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locked)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.eventFormCustomFieldsLocked,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (var i = 0; i < fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('custom_field_label_$i'),
                    initialValue: fields[i].label,
                    enabled: !locked,
                    decoration:
                        InputDecoration(labelText: l10n.eventFormFieldLabelHint),
                    onChanged: (value) => onChanged(
                      i,
                      NewCustomField(
                        label: value,
                        type: fields[i].type,
                        sortOrder: fields[i].sortOrder,
                        showOnTicket: fields[i].showOnTicket,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<CustomFieldType>(
                  value: fields[i].type,
                  onChanged: locked
                      ? null
                      : (type) {
                          if (type == null) return;
                          onChanged(
                            i,
                            NewCustomField(
                              label: fields[i].label,
                              type: type,
                              sortOrder: fields[i].sortOrder,
                              showOnTicket: fields[i].showOnTicket,
                            ),
                          );
                        },
                  items: CustomFieldType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        ),
                      )
                      .toList(),
                ),
                Checkbox(
                  value: fields[i].showOnTicket,
                  onChanged: locked
                      ? null
                      : (value) => onChanged(
                            i,
                            NewCustomField(
                              label: fields[i].label,
                              type: fields[i].type,
                              sortOrder: fields[i].sortOrder,
                              showOnTicket: value ?? false,
                            ),
                          ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: locked ? null : () => onRemove(i),
                ),
              ],
            ),
          ),
        if (!locked)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.eventFormAddFieldAction),
          ),
      ],
    );
  }
}
```

```dart
// lib/features/events/presentation/screens/event_form_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/custom_field_type.dart';
import '../../domain/event.dart';
import '../../domain/presence_mode.dart';
import '../providers/event_providers.dart';
import '../widgets/custom_field_editor.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({this.eventId, super.key});

  final int? eventId;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _date = DateTime.now();
  PresenceMode _presenceMode = PresenceMode.simple;
  Uint8List? _logo;
  final List<NewCustomField> _customFields = [];
  bool _customFieldsLocked = false;
  bool _presenceModeLocked = false;
  bool _loading = false;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingEvent(widget.eventId!);
    }
  }

  Future<void> _loadExistingEvent(int id) async {
    final repository = ref.read(eventRepositoryProvider);
    final event = await repository.getEvent(id);
    final fields = await repository.watchCustomFields(id).first;
    final customFieldsLocked = !(await repository.canEditCustomFields(id));
    final presenceModeLocked = !(await repository.canEditPresenceMode(id));

    if (!mounted) return;
    setState(() {
      _nameController.text = event.name;
      _locationController.text = event.location ?? '';
      _date = event.date;
      _presenceMode = event.presenceMode;
      _logo = event.logo;
      _customFields
        ..clear()
        ..addAll(
          fields.map(
            (f) => NewCustomField(
              label: f.label,
              type: f.type,
              sortOrder: f.sortOrder,
              showOnTicket: f.showOnTicket,
            ),
          ),
        );
      _customFieldsLocked = customFieldsLocked;
      _presenceModeLocked = presenceModeLocked;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _logo = bytes);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(
        NewCustomField(
          label: '',
          type: CustomFieldType.text,
          sortOrder: _customFields.length,
        ),
      );
    });
  }

  void _removeCustomField(int index) {
    setState(() => _customFields.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final repository = ref.read(eventRepositoryProvider);
    final location =
        _locationController.text.trim().isEmpty ? null : _locationController.text.trim();

    if (_isEditing) {
      await repository.updateEvent(
        widget.eventId!,
        name: _nameController.text.trim(),
        date: _date,
        location: location,
        logo: _logo,
        presenceMode: _presenceMode,
      );
      if (!_customFieldsLocked) {
        await repository.replaceCustomFields(widget.eventId!, _customFields);
      }
    } else {
      await repository.createEvent(
        name: _nameController.text.trim(),
        date: _date,
        location: location,
        logo: _logo,
        presenceMode: _presenceMode,
        customFields: _customFields,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    // Guarded: in a widget test (or any context where this screen is the
    // only route), there is nothing to pop back to.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.eventFormTitleEdit : l10n.eventFormTitleCreate),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.eventFormNameLabel),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? l10n.eventFormNameRequired : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.eventFormDateLabel),
              subtitle: Text(DateFormat.yMMMMd(locale).format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: l10n.eventFormLocationLabel),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_logo != null) ...[
                  CircleAvatar(backgroundImage: MemoryImage(_logo!), radius: 24),
                  const SizedBox(width: 12),
                ],
                TextButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.eventFormLogoAction),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.eventFormPresenceModeLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<PresenceMode>(
              segments: [
                ButtonSegment(
                  value: PresenceMode.simple,
                  label: Text(l10n.eventFormPresenceModeSimple),
                ),
                ButtonSegment(
                  value: PresenceMode.multiple,
                  label: Text(l10n.eventFormPresenceModeMultiple),
                ),
              ],
              selected: {_presenceMode},
              onSelectionChanged: _presenceModeLocked
                  ? null
                  : (selection) => setState(() => _presenceMode = selection.first),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.eventFormCustomFieldsLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            CustomFieldEditor(
              fields: _customFields,
              locked: _customFieldsLocked,
              onAdd: _addCustomField,
              onRemove: _removeCustomField,
              onChanged: (index, field) => setState(() => _customFields[index] = field),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(l10n.eventFormSaveAction),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/event_form_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/widgets/custom_field_editor.dart lib/features/events/presentation/screens/event_form_screen.dart test/features/events/presentation/screens/event_form_screen_test.dart
git commit -m "Add event form screen with custom fields editor"
```

---

### Task 8: Archives screen

**Files:**
- Create: `lib/features/events/presentation/screens/event_archive_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/event_archive_screen_test.dart`

**Interfaces:**
- Consumes: `archivedEventsProvider`, `eventRepositoryProvider` (Task 5).
- Produces: `EventArchiveScreen` (no params), the widget Task 9 wires to route `/events/archives`.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "eventsArchiveTitle": "Archives",
  "eventsArchiveEmptyState": "No archived events",
  "eventsRestoreAction": "Restore",
  "eventsDeletePermanentlyAction": "Delete permanently",
  "eventsDeleteConfirmTitle": "Delete permanently?",
  "eventsDeleteConfirmBody": "This action cannot be undone.",
  "commonCancel": "Cancel",
  "commonDelete": "Delete"
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "eventsArchiveTitle": "Archives",
  "eventsArchiveEmptyState": "Aucun evenement archive",
  "eventsRestoreAction": "Restaurer",
  "eventsDeletePermanentlyAction": "Supprimer definitivement",
  "eventsDeleteConfirmTitle": "Supprimer definitivement ?",
  "eventsDeleteConfirmBody": "Cette action est irreversible.",
  "commonCancel": "Annuler",
  "commonDelete": "Supprimer"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/events/presentation/screens/event_archive_screen_test.dart
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/events/presentation/screens/event_archive_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_event_repository.dart';

Widget _wrap(Widget child, FakeEventRepository fake) {
  return ProviderScope(
    overrides: [eventRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no archived events',
      (tester) async {
    await tester.pumpWidget(_wrap(const EventArchiveScreen(), FakeEventRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No archived events'), findsOneWidget);
  });

  testWidgets('restore button restores the event', (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Old gala',
        date: DateTime(2025, 1, 1),
        presenceMode: PresenceMode.simple,
        archivedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventArchiveScreen(), fake));
    await tester.pumpAndSettle();

    expect(find.text('Old gala'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();

    expect(fake.events.single.isArchived, isFalse);
  });

  testWidgets('delete permanently asks for confirmation before deleting',
      (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Old gala',
        date: DateTime(2025, 1, 1),
        presenceMode: PresenceMode.simple,
        archivedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventArchiveScreen(), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pumpAndSettle();

    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(fake.events, hasLength(1));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fake.events, isEmpty);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/event_archive_screen_test.dart
```

Expected: FAIL (`event_archive_screen.dart` does not exist).

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/events/presentation/screens/event_archive_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';
import '../providers/event_providers.dart';

class EventArchiveScreen extends ConsumerWidget {
  const EventArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(archivedEventsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventsArchiveTitle)),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(child: Text(l10n.eventsArchiveEmptyState));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(event.name),
                  subtitle: Text(DateFormat.yMMMMd(locale).format(event.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: l10n.eventsRestoreAction,
                        onPressed: () =>
                            ref.read(eventRepositoryProvider).restoreEvent(event.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_outlined),
                        tooltip: l10n.eventsDeletePermanentlyAction,
                        onPressed: () => _confirmDelete(context, ref, event),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.eventsDeleteConfirmTitle),
        content: Text(l10n.eventsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(eventRepositoryProvider).deleteEventPermanently(event.id);
    }
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/event_archive_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/screens/event_archive_screen.dart test/features/events/presentation/screens/event_archive_screen_test.dart
git commit -m "Add archives screen"
```

---

### Task 9: Wire the router, remove the placeholder, full milestone check

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `test/core/router/app_router_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `EventsListScreen` (Task 6), `EventFormScreen` (Task 7), `EventArchiveScreen` (Task 8), `FakeEventRepository` (Task 5).
- Produces: `appRouter` now has 4 real routes; `/` no longer shows the jalon 1 placeholder. This is the last task of the milestone.

- [ ] **Step 1: Write the failing test**

Replace the router test's assertion (it currently expects the jalon 1 placeholder text, which is going away):

```dart
// test/core/router/app_router_test.dart
import 'package:dif_pass/core/router/app_router.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/events/fake_event_repository.dart';

void main() {
  testWidgets('app router shows the events list screen at /', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventRepositoryProvider.overrideWithValue(FakeEventRepository())],
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('No events yet. Create one to get started.'), findsOneWidget);
  });
}
```

And the app-level smoke test:

```dart
// test/widget_test.dart
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/events/fake_event_repository.dart';

void main() {
  testWidgets('DifPassApp boots to the events list screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventRepositoryProvider.overrideWithValue(FakeEventRepository())],
        child: const DifPassApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run both tests, verify they fail**

```bash
fvm flutter test test/core/router/app_router_test.dart test/widget_test.dart
```

Expected: FAIL. `app_router_test.dart` fails because `/` still shows the jalon 1 placeholder text, not "Events". `widget_test.dart` fails the same way.

- [ ] **Step 3: Wire the real routes**

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

import '../../features/events/presentation/screens/event_archive_screen.dart';
import '../../features/events/presentation/screens/event_form_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EventsListScreen(),
    ),
    GoRoute(
      path: '/events/new',
      builder: (context, state) => const EventFormScreen(),
    ),
    GoRoute(
      path: '/events/:id/edit',
      builder: (context, state) => EventFormScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/archives',
      builder: (context, state) => const EventArchiveScreen(),
    ),
  ],
);
```

This deletes the `_PlaceholderHomeScreen` class and its ponytail comment entirely, along with the now-unused `flutter/material.dart` and `app_localizations.dart` imports it needed.

- [ ] **Step 4: Run both tests, verify they pass**

```bash
fvm flutter test test/core/router/app_router_test.dart test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 5: Run the full suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer reports no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/router test/core/router test/widget_test.dart
git commit -m "Wire events routes, remove the jalon 1 placeholder screen"
```

---

## Milestone acceptance

Jalon 2 (Evenements) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and `fvm flutter run` boots to the events list (empty state on a fresh database), from which an organizer can create an event with custom fields and a presence mode, see it in the list, edit it, archive it, and restore or permanently delete it from the Archives screen.
