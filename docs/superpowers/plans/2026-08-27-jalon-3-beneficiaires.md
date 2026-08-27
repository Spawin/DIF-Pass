# Jalon 3 - Beneficiaires - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the full Beneficiaries feature (section 2 of the cahier des charges): manual add, edit, delete, and bulk CSV import with column mapping, for a given event's beneficiaries. Adds a "Beneficiaries" entry point to the events list.

**Architecture:** `lib/features/beneficiaries/` follows the exact repository-interface pattern established in jalon 2: screens and providers depend only on `BeneficiaryRepository` and domain types, never on Drift directly. The beneficiary form and the CSV mapping screen read the target event's custom fields through the existing `EventRepository`/`customFieldsProvider` (a features/beneficiaries -> features/events dependency is fine, the reverse is not).

**Tech Stack:** Flutter 3.44.7 (FVM) + Riverpod + go_router + Drift + `file_picker` and `csv` (both already dependencies since jalon 1, no new packages this jalon).

## Global Constraints

- Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Never hand-edit generated `.g.dart` or generated localization files.
- No em dashes in code, comments, or commit messages.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits.
- Reuse existing ARB keys where the visible text is identical rather than adding a duplicate (this plan calls out every reuse explicitly, follow it rather than adding a new key with the same value).
- No lock/edit restriction on beneficiaries: unlike custom fields and presence mode, nothing yet references a `Beneficiary` in a way that makes editing risky (tickets do not exist until jalon 4), so `BeneficiaryRepository` has no `canEdit*` methods.
- Every task below that adds ARB keys ends with `fvm flutter gen-l10n` before the tests are expected to pass.

---

### Task 1: Make `FakeEventRepository.watchCustomFields` live

**Context:** jalon 2's final review flagged that the test fake's `watchCustomFields` is a single-shot generator, not a live stream, and explicitly deferred fixing it until a task actually binds `customFieldsProvider` reactively in a widget. This jalon's beneficiary form and CSV mapping screen both do exactly that (Tasks 7 and 8), so this is the prerequisite.

**Files:**
- Modify: `test/features/events/fake_event_repository.dart`
- Modify: `test/features/events/presentation/providers/event_providers_test.dart`

**Interfaces:**
- Consumes: `CustomField`, `NewCustomField` (jalon 2, `lib/features/events/domain/custom_field.dart`).
- Produces: `FakeEventRepository.watchCustomFields(int)` now emits a fresh list every time `createEvent` or `replaceCustomFields` changes that event's custom fields, matching `DriftEventRepository`'s live behavior. Tasks 7 and 8 rely on this.

- [ ] **Step 1: Write the failing test**

Add this test to the existing file:

```dart
// test/features/events/presentation/providers/event_providers_test.dart (append inside main())
test('customFieldsProvider re-emits after replaceCustomFields', () async {
  final fake = FakeEventRepository();
  final eventId = await fake.createEvent(
    name: 'Gala DIF 2026',
    date: DateTime(2026, 12, 1),
    presenceMode: PresenceMode.simple,
    customFields: const [],
  );
  final container = ProviderContainer(
    overrides: [eventRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);

  final stream = container.read(customFieldsProvider(eventId).stream);
  final expectation = expectLater(
    stream,
    emitsInOrder([
      predicate<List<CustomField>>((list) => list.isEmpty),
      predicate<List<CustomField>>(
          (list) => list.length == 1 && list.single.label == 'Table number'),
    ]),
  );

  await fake.replaceCustomFields(eventId, const [
    NewCustomField(label: 'Table number', type: CustomFieldType.text, sortOrder: 0),
  ]);

  await expectation;
});
```

Add the needed imports at the top of the file:

```dart
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/providers/event_providers_test.dart
```

Expected: FAIL or hang/timeout (the single-shot stream only ever emits once, the second `predicate` in `emitsInOrder` is never satisfied).

- [ ] **Step 3: Make `watchCustomFields` live**

In `test/features/events/fake_event_repository.dart`, add a per-event broadcast controller alongside the existing `_activeController`/`_archivedController`:

```dart
final Map<int, StreamController<List<CustomField>>> _customFieldsControllers = {};

StreamController<List<CustomField>> _customFieldsController(int eventId) {
  return _customFieldsControllers.putIfAbsent(
    eventId,
    () => StreamController<List<CustomField>>.broadcast(),
  );
}

void _emitCustomFields(int eventId) {
  _customFieldsController(eventId).add(List.of(_customFields[eventId] ?? const []));
}
```

Replace the existing `watchCustomFields` override:

```dart
@override
Stream<List<CustomField>> watchCustomFields(int eventId) {
  Future.microtask(() => _emitCustomFields(eventId));
  return _customFieldsController(eventId).stream;
}
```

In `createEvent`, right after the line that sets `_customFields[id] = [...]` and before `_emit(); return id;`, add:

```dart
_emitCustomFields(id);
```

In `replaceCustomFields`, right after the line that sets `_customFields[eventId] = [...]`, add:

```dart
_emitCustomFields(eventId);
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/providers/event_providers_test.dart
```

Expected: PASS (both tests in the file).

- [ ] **Step 5: Commit**

```bash
git add test/features/events/fake_event_repository.dart test/features/events/presentation/providers/event_providers_test.dart
git commit -m "Make FakeEventRepository.watchCustomFields a live stream"
```

---

### Task 2: Beneficiary domain models and repository

**Files:**
- Create: `lib/features/beneficiaries/domain/beneficiary.dart`
- Create: `lib/features/beneficiaries/domain/new_beneficiary.dart`
- Create: `lib/features/beneficiaries/data/beneficiary_repository.dart`
- Create: `lib/features/beneficiaries/data/drift_beneficiary_repository.dart`
- Test: `test/features/beneficiaries/data/drift_beneficiary_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (jalon 1, with `Beneficiaries`/`BeneficiaryValues` tables and cascading FKs).
- Produces: `Beneficiary` (`id`, `eventId`, `name`, `customFieldValues: Map<int, String>`, `createdAt`), `NewBeneficiary` (`name`, `customFieldValues`). `BeneficiaryRepository` (abstract) with `watchBeneficiaries(int)`, `getBeneficiary(int)`, `createBeneficiary(int, NewBeneficiary)`, `updateBeneficiary(int, NewBeneficiary)`, `deleteBeneficiary(int)`, `importBeneficiaries(int, List<NewBeneficiary>)`. `DriftBeneficiaryRepository implements BeneficiaryRepository`. Task 4 (providers) and Task 6-8 (screens) depend on these exact names and signatures.

The domain models (`Beneficiary`, `NewBeneficiary`) are plain data classes with no derived behavior (no getters, no computed logic), so there is nothing to TDD in isolation for them, ponytail: no dedicated domain test file, they are exercised directly by the repository tests below.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/beneficiaries/data/drift_beneficiary_repository_test.dart
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

    await repository.updateBeneficiary(
      id,
      NewBeneficiary(name: 'Jane Doe', customFieldValues: {customFieldId: 'Table 9'}),
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
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/beneficiaries/data/drift_beneficiary_repository_test.dart
```

Expected: FAIL (`package:dif_pass/features/beneficiaries/...` does not exist).

- [ ] **Step 3: Implement the domain models and the repository**

```dart
// lib/features/beneficiaries/domain/beneficiary.dart
class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.eventId,
    required this.name,
    required this.customFieldValues,
    required this.createdAt,
  });

  final int id;
  final int eventId;
  final String name;
  final Map<int, String> customFieldValues;
  final DateTime createdAt;
}
```

```dart
// lib/features/beneficiaries/domain/new_beneficiary.dart
class NewBeneficiary {
  const NewBeneficiary({
    required this.name,
    required this.customFieldValues,
  });

  final String name;
  final Map<int, String> customFieldValues;
}
```

```dart
// lib/features/beneficiaries/data/beneficiary_repository.dart
import '../domain/beneficiary.dart';
import '../domain/new_beneficiary.dart';

abstract class BeneficiaryRepository {
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId);
  Future<Beneficiary> getBeneficiary(int id);
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary);
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary);
  Future<void> deleteBeneficiary(int id);
  Future<int> importBeneficiaries(int eventId, List<NewBeneficiary> beneficiaries);
}
```

```dart
// lib/features/beneficiaries/data/drift_beneficiary_repository.dart
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/beneficiary.dart';
import '../domain/new_beneficiary.dart';
import 'beneficiary_repository.dart';

class DriftBeneficiaryRepository implements BeneficiaryRepository {
  DriftBeneficiaryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId) {
    final query = _db.select(_db.beneficiaries).join([
      leftOuterJoin(
        _db.beneficiaryValues,
        _db.beneficiaryValues.beneficiaryId.equalsExp(_db.beneficiaries.id),
      ),
    ])
      ..where(_db.beneficiaries.eventId.equals(eventId));
    return query.watch().map(_groupRows);
  }

  @override
  Future<Beneficiary> getBeneficiary(int id) async {
    final query = _db.select(_db.beneficiaries).join([
      leftOuterJoin(
        _db.beneficiaryValues,
        _db.beneficiaryValues.beneficiaryId.equalsExp(_db.beneficiaries.id),
      ),
    ])
      ..where(_db.beneficiaries.id.equals(id));
    final rows = await query.get();
    return _groupRows(rows).single;
  }

  @override
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary) {
    return _db.transaction(() async {
      final id = await _db.into(_db.beneficiaries).insert(
            BeneficiariesCompanion.insert(eventId: eventId, name: beneficiary.name),
          );
      await _insertValues(id, beneficiary.customFieldValues);
      return id;
    });
  }

  @override
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary) {
    return _db.transaction(() async {
      await (_db.update(_db.beneficiaries)..where((tbl) => tbl.id.equals(id)))
          .write(BeneficiariesCompanion(name: Value(beneficiary.name)));
      await (_db.delete(_db.beneficiaryValues)
            ..where((tbl) => tbl.beneficiaryId.equals(id)))
          .go();
      await _insertValues(id, beneficiary.customFieldValues);
    });
  }

  @override
  Future<void> deleteBeneficiary(int id) async {
    await (_db.delete(_db.beneficiaries)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<int> importBeneficiaries(int eventId, List<NewBeneficiary> beneficiaries) {
    return _db.transaction(() async {
      var count = 0;
      for (final beneficiary in beneficiaries) {
        final id = await _db.into(_db.beneficiaries).insert(
              BeneficiariesCompanion.insert(eventId: eventId, name: beneficiary.name),
            );
        await _insertValues(id, beneficiary.customFieldValues);
        count++;
      }
      return count;
    });
  }

  Future<void> _insertValues(int beneficiaryId, Map<int, String> values) async {
    for (final entry in values.entries) {
      if (entry.value.trim().isEmpty) continue;
      await _db.into(_db.beneficiaryValues).insert(
            BeneficiaryValuesCompanion.insert(
              beneficiaryId: beneficiaryId,
              customFieldId: entry.key,
              value: entry.value,
            ),
          );
    }
  }

  List<Beneficiary> _groupRows(List<TypedResult> rows) {
    final beneficiaryRows = <int, BeneficiaryEntity>{};
    final values = <int, Map<int, String>>{};
    for (final row in rows) {
      final b = row.readTable(_db.beneficiaries);
      beneficiaryRows[b.id] = b;
      final v = row.readTableOrNull(_db.beneficiaryValues);
      final valueMap = values.putIfAbsent(b.id, () => {});
      if (v != null) {
        valueMap[v.customFieldId] = v.value;
      }
    }
    final result = beneficiaryRows.values
        .map((b) => Beneficiary(
              id: b.id,
              eventId: b.eventId,
              name: b.name,
              customFieldValues: Map.unmodifiable(values[b.id] ?? const {}),
              createdAt: b.createdAt,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/beneficiaries/data/drift_beneficiary_repository_test.dart
```

Expected: PASS (all 6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/beneficiaries/domain lib/features/beneficiaries/data test/features/beneficiaries/data
git commit -m "Add BeneficiaryRepository and its Drift implementation"
```

---

### Task 3: CSV parser

**Files:**
- Create: `lib/features/beneficiaries/data/csv_parser.dart`
- Test: `test/features/beneficiaries/data/csv_parser_test.dart`

**Interfaces:**
- Produces: `ParsedCsv` (`headers: List<String>`, `rows: List<List<String>>`), `parseCsvContent(String) -> ParsedCsv`. A pure function, no Flutter/platform dependency. Task 8 (CSV import screen) is the only consumer.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/beneficiaries/data/csv_parser_test.dart
import 'package:dif_pass/features/beneficiaries/data/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCsvContent splits the header row from the data rows', () {
    final result = parseCsvContent('Name,Table\nJane Doe,5\nJohn Smith,9\n');

    expect(result.headers, ['Name', 'Table']);
    expect(result.rows, [
      ['Jane Doe', '5'],
      ['John Smith', '9'],
    ]);
  });

  test('parseCsvContent returns empty headers and rows for empty content', () {
    final result = parseCsvContent('');

    expect(result.headers, isEmpty);
    expect(result.rows, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/beneficiaries/data/csv_parser_test.dart
```

Expected: FAIL (`csv_parser.dart` does not exist).

- [ ] **Step 3: Implement the parser**

```dart
// lib/features/beneficiaries/data/csv_parser.dart
import 'package:csv/csv.dart';

class ParsedCsv {
  const ParsedCsv({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

ParsedCsv parseCsvContent(String content) {
  final rows = const CsvToListConverter(eol: '\n').convert(content);
  if (rows.isEmpty) {
    return const ParsedCsv(headers: [], rows: []);
  }
  final headers = rows.first.map((cell) => cell.toString()).toList();
  final dataRows = rows
      .skip(1)
      .map((row) => row.map((cell) => cell.toString()).toList())
      .toList();
  return ParsedCsv(headers: headers, rows: dataRows);
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/beneficiaries/data/csv_parser_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/beneficiaries/data/csv_parser.dart test/features/beneficiaries/data/csv_parser_test.dart
git commit -m "Add CSV parser for beneficiary import"
```

---

### Task 4: Riverpod providers and a shared test fake

**Files:**
- Create: `lib/features/beneficiaries/presentation/providers/beneficiary_providers.dart`
- Create: `test/features/beneficiaries/fake_beneficiary_repository.dart`
- Test: `test/features/beneficiaries/presentation/providers/beneficiary_providers_test.dart`

**Interfaces:**
- Consumes: `BeneficiaryRepository`, `DriftBeneficiaryRepository` (Task 2); `appDatabaseProvider` (jalon 1).
- Produces: `beneficiaryRepositoryProvider` (`Provider<BeneficiaryRepository>`), `beneficiariesProvider` (`StreamProvider.family<List<Beneficiary>, int>`, keyed by eventId). `FakeBeneficiaryRepository` (test-only, `test/features/beneficiaries/fake_beneficiary_repository.dart`) implements `BeneficiaryRepository` in memory with a public `beneficiaries` getter. Tasks 6, 7, 8 import it and override `beneficiaryRepositoryProvider` in their widget tests.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/beneficiaries/presentation/providers/beneficiary_providers_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_beneficiary_repository.dart';

void main() {
  test('beneficiariesProvider streams beneficiaries for the given event', () async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 42,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [beneficiaryRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final beneficiaries = await container.read(beneficiariesProvider(42).future);
    expect(beneficiaries, hasLength(1));
    expect(beneficiaries.single.name, 'Jane Doe');
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/beneficiaries/presentation/providers/beneficiary_providers_test.dart
```

Expected: FAIL (neither file exists).

- [ ] **Step 3: Implement the providers and the fake**

```dart
// lib/features/beneficiaries/presentation/providers/beneficiary_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/beneficiary_repository.dart';
import '../../data/drift_beneficiary_repository.dart';
import '../../domain/beneficiary.dart';

final beneficiaryRepositoryProvider = Provider<BeneficiaryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftBeneficiaryRepository(db);
});

final beneficiariesProvider =
    StreamProvider.family<List<Beneficiary>, int>((ref, eventId) {
  return ref.watch(beneficiaryRepositoryProvider).watchBeneficiaries(eventId);
});
```

```dart
// test/features/beneficiaries/fake_beneficiary_repository.dart
import 'dart:async';

import 'package:dif_pass/features/beneficiaries/data/beneficiary_repository.dart';
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/domain/new_beneficiary.dart';

/// In-memory BeneficiaryRepository for widget/provider tests. Not shipped
/// in the app, lives under test/ only.
class FakeBeneficiaryRepository implements BeneficiaryRepository {
  FakeBeneficiaryRepository({List<Beneficiary>? beneficiaries})
      : _beneficiaries = List.of(beneficiaries ?? const []);

  final List<Beneficiary> _beneficiaries;
  final Map<int, StreamController<List<Beneficiary>>> _controllers = {};
  int _nextId = 1000;

  List<Beneficiary> get beneficiaries => List.unmodifiable(_beneficiaries);

  StreamController<List<Beneficiary>> _controllerFor(int eventId) {
    return _controllers.putIfAbsent(
      eventId,
      () => StreamController<List<Beneficiary>>.broadcast(),
    );
  }

  void _emit(int eventId) {
    _controllerFor(eventId).add(
      _beneficiaries.where((b) => b.eventId == eventId).toList(),
    );
  }

  @override
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId) {
    Future.microtask(() => _emit(eventId));
    return _controllerFor(eventId).stream;
  }

  @override
  Future<Beneficiary> getBeneficiary(int id) async =>
      _beneficiaries.firstWhere((b) => b.id == id);

  @override
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary) async {
    final id = _nextId++;
    _beneficiaries.add(Beneficiary(
      id: id,
      eventId: eventId,
      name: beneficiary.name,
      customFieldValues: Map.of(beneficiary.customFieldValues),
      createdAt: DateTime.now(),
    ));
    _emit(eventId);
    return id;
  }

  @override
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    final existing = _beneficiaries[index];
    _beneficiaries[index] = Beneficiary(
      id: existing.id,
      eventId: existing.eventId,
      name: beneficiary.name,
      customFieldValues: Map.of(beneficiary.customFieldValues),
      createdAt: existing.createdAt,
    );
    _emit(existing.eventId);
  }

  @override
  Future<void> deleteBeneficiary(int id) async {
    final index = _beneficiaries.indexWhere((b) => b.id == id);
    final eventId = _beneficiaries[index].eventId;
    _beneficiaries.removeAt(index);
    _emit(eventId);
  }

  @override
  Future<int> importBeneficiaries(
    int eventId,
    List<NewBeneficiary> beneficiaries,
  ) async {
    for (final beneficiary in beneficiaries) {
      final id = _nextId++;
      _beneficiaries.add(Beneficiary(
        id: id,
        eventId: eventId,
        name: beneficiary.name,
        customFieldValues: Map.of(beneficiary.customFieldValues),
        createdAt: DateTime.now(),
      ));
    }
    _emit(eventId);
    return beneficiaries.length;
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/beneficiaries/presentation/providers/beneficiary_providers_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/beneficiaries/presentation/providers test/features/beneficiaries/fake_beneficiary_repository.dart test/features/beneficiaries/presentation/providers
git commit -m "Add beneficiary providers and a fake repository for tests"
```

---

### Task 5: "Beneficiaries" entry point on the events list

**Files:**
- Modify: `lib/features/events/presentation/widgets/event_card.dart`
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`

**Interfaces:**
- Produces: `EventCard` gains a new required `onManageBeneficiaries` (`VoidCallback`) parameter, rendered as a second trailing icon button alongside the existing archive action. `EventsListScreen` wires it to navigate to `/events/<id>/beneficiaries` (the route itself is wired in Task 9, this task only adds the button and the navigation call; the route does not exist until Task 9, that is fine, `context.push` on a route that does not exist yet is only exercised once Task 9 lands, this task's own test only checks the button exists).

- [ ] **Step 1: Add the ARB key this change needs**

```json
// lib/l10n/app_en.arb (add this key, keep the existing ones)
{
  "eventsBeneficiariesAction": "Beneficiaries"
}
```

```json
// lib/l10n/app_fr.arb (add this key, keep the existing ones)
{
  "eventsBeneficiariesAction": "Beneficiaires"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

Add this test to the existing file:

```dart
// test/features/events/presentation/screens/events_list_screen_test.dart (append inside main())
testWidgets('shows a beneficiaries action for each event', (tester) async {
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

  expect(find.byTooltip('Beneficiaries'), findsOneWidget);
});
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: FAIL (no widget with tooltip "Beneficiaries" exists yet).

- [ ] **Step 4: Add the button**

```dart
// lib/features/events/presentation/widgets/event_card.dart
// Replace the class body's constructor and trailing field with:
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    required this.onManageBeneficiaries,
    required this.onArchive,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onManageBeneficiaries;
  final VoidCallback onArchive;

  // ... build() stays the same up to `trailing:`, replace only that:
```

```dart
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: l10n.eventsBeneficiariesAction,
              onPressed: onManageBeneficiaries,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: l10n.eventsArchiveEventAction,
              onPressed: onArchive,
            ),
          ],
        ),
```

```dart
// lib/features/events/presentation/screens/events_list_screen.dart
// In the EventCard(...) construction inside itemBuilder, add:
              return EventCard(
                event: event,
                onTap: () => context.push('/events/${event.id}/edit'),
                onManageBeneficiaries: () =>
                    context.push('/events/${event.id}/beneficiaries'),
                onArchive: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(eventRepositoryProvider)
                        .archiveEvent(event.id);
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              );
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: PASS (all tests in the file, including the two from jalon 2).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/widgets/event_card.dart lib/features/events/presentation/screens/events_list_screen.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Add a beneficiaries entry point to the events list"
```

---

### Task 6: Beneficiaries list screen

**Files:**
- Create: `lib/features/beneficiaries/presentation/widgets/beneficiary_list_tile.dart`
- Create: `lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`

**Interfaces:**
- Consumes: `beneficiariesProvider`, `beneficiaryRepositoryProvider` (Task 4); reuses the existing `eventsDeleteConfirmBody`, `commonCancel`, `commonDelete` ARB keys from jalon 2 (identical wording applies here, do not duplicate them).
- Produces: `BeneficiaryListTile` (`beneficiary`, `onTap`, `onDelete` params). `BeneficiariesListScreen({required int eventId})`, the widget Task 9 wires to route `/events/:id/beneficiaries`.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "beneficiariesListTitle": "Beneficiaries",
  "beneficiariesImportAction": "Import CSV",
  "beneficiariesEmptyState": "No beneficiaries yet. Add one or import a CSV file.",
  "beneficiariesNewAction": "New beneficiary",
  "beneficiariesLoadError": "Something went wrong loading beneficiaries.",
  "beneficiariesDeleteConfirmTitle": "Delete this beneficiary?"
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "beneficiariesListTitle": "Beneficiaires",
  "beneficiariesImportAction": "Importer un CSV",
  "beneficiariesEmptyState": "Aucun beneficiaire pour l'instant. Ajoutez-en un ou importez un fichier CSV.",
  "beneficiariesNewAction": "Nouveau beneficiaire",
  "beneficiariesLoadError": "Un probleme est survenu lors du chargement des beneficiaires.",
  "beneficiariesDeleteConfirmTitle": "Supprimer ce beneficiaire ?"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_beneficiary_repository.dart';

Widget _wrap(Widget child, FakeBeneficiaryRepository fake) {
  return ProviderScope(
    overrides: [beneficiaryRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no beneficiaries',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const BeneficiariesListScreen(eventId: 1), FakeBeneficiaryRepository()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No beneficiaries yet. Add one or import a CSV file.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a tile per beneficiary for the given event', (tester) async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const BeneficiariesListScreen(eventId: 1), fake));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation before removing a beneficiary',
      (tester) async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const BeneficiariesListScreen(eventId: 1), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(fake.beneficiaries, hasLength(1));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fake.beneficiaries, isEmpty);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart
```

Expected: FAIL (`beneficiaries_list_screen.dart` does not exist).

- [ ] **Step 4: Implement the widget and the screen**

```dart
// lib/features/beneficiaries/presentation/widgets/beneficiary_list_tile.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/beneficiary.dart';

class BeneficiaryListTile extends StatelessWidget {
  const BeneficiaryListTile({
    required this.beneficiary,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Beneficiary beneficiary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(beneficiary.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: onDelete,
        ),
      ),
    );
  }
}
```

```dart
// lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/beneficiary.dart';
import '../providers/beneficiary_providers.dart';
import '../widgets/beneficiary_list_tile.dart';

class BeneficiariesListScreen extends ConsumerWidget {
  const BeneficiariesListScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final beneficiariesAsync = ref.watch(beneficiariesProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.beneficiariesListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: l10n.beneficiariesImportAction,
            onPressed: () => context.push('/events/$eventId/beneficiaries/import'),
          ),
        ],
      ),
      body: beneficiariesAsync.when(
        data: (beneficiaries) {
          if (beneficiaries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.beneficiariesEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: beneficiaries.length,
            itemBuilder: (context, index) {
              final beneficiary = beneficiaries[index];
              return BeneficiaryListTile(
                beneficiary: beneficiary,
                onTap: () => context
                    .push('/events/$eventId/beneficiaries/${beneficiary.id}/edit'),
                onDelete: () => _confirmDelete(context, ref, beneficiary),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/$eventId/beneficiaries/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.beneficiariesNewAction),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Beneficiary beneficiary,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.beneficiariesDeleteConfirmTitle),
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
      try {
        await repository.deleteBeneficiary(beneficiary.id);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/beneficiaries/presentation/widgets/beneficiary_list_tile.dart lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart
git commit -m "Add beneficiaries list screen"
```

---

### Task 7: Beneficiary form screen (create and edit)

**Files:**
- Create: `lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart`

**Interfaces:**
- Consumes: `beneficiaryRepositoryProvider` (Task 4); `customFieldsProvider`, `eventRepositoryProvider` (jalon 2, now live per Task 1); reuses the existing `eventFormNameLabel`, `eventFormNameRequired`, `eventFormSaveAction` ARB keys (identical wording, "Name" / "Name is required" / "Save", do not duplicate).
- Produces: `BeneficiaryFormScreen({required int eventId, int? beneficiaryId})`: no `beneficiaryId` means create, a value means edit. Task 9 wires this to routes `/events/:id/beneficiaries/new` and `/events/:id/beneficiaries/:beneficiaryId/edit`.

**Note on test viewport:** if a `tester.tap` on the Save button misses because it renders below the default 800x600 test viewport, the fix belongs in the test (`await tester.ensureVisible(find.text('Save')); await tester.pumpAndSettle();` before the tap, or resize the test viewport with `tester.view.physicalSize`), never by shrinking production spacing to fit the test. This exact mistake happened in jalon 2 and was corrected, do not repeat it.

**Note on the frontend-design skill:** this screen uses plain Material components and the DIF theme's defaults, same as jalon 2's event form. Consult the frontend-design skill for spacing/styling polish while keeping the structure and behavior below intact.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "beneficiaryFormTitleCreate": "New beneficiary",
  "beneficiaryFormTitleEdit": "Edit beneficiary",
  "beneficiaryFormFieldNumberInvalid": "Enter a number"
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "beneficiaryFormTitleCreate": "Nouveau beneficiaire",
  "beneficiaryFormTitleEdit": "Modifier le beneficiaire",
  "beneficiaryFormFieldNumberInvalid": "Entrez un nombre"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../events/fake_event_repository.dart';
import '../../fake_beneficiary_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows a validation error when the name is empty', (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId),
      fakeEvents,
      FakeBeneficiaryRepository(),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('creates a beneficiary with the entered name and custom field value',
      (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [
        NewCustomField(label: 'Table number', type: CustomFieldType.text, sortOrder: 0),
      ],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository();

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId),
      fakeEvents,
      fakeBeneficiaries,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextFormField).at(1), 'Table 5');
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeBeneficiaries.beneficiaries, hasLength(1));
    expect(fakeBeneficiaries.beneficiaries.single.name, 'Jane Doe');
    expect(fakeBeneficiaries.beneficiaries.single.customFieldValues.values,
        contains('Table 5'));
  });

  testWidgets('editing an existing beneficiary pre-fills the name field',
      (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 7,
        eventId: eventId,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId, beneficiaryId: 7),
      fakeEvents,
      fakeBeneficiaries,
    ));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(nameField.controller?.text, 'Jane Doe');
    expect(find.text('Edit beneficiary'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart
```

Expected: FAIL (`beneficiary_form_screen.dart` does not exist).

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/custom_field.dart';
import '../../../events/domain/custom_field_type.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/new_beneficiary.dart';
import '../providers/beneficiary_providers.dart';

class BeneficiaryFormScreen extends ConsumerStatefulWidget {
  const BeneficiaryFormScreen({required this.eventId, this.beneficiaryId, super.key});

  final int eventId;
  final int? beneficiaryId;

  @override
  ConsumerState<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends ConsumerState<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Map<int, TextEditingController> _fieldControllers = {};
  bool _loading = false;

  bool get _isEditing => widget.beneficiaryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingBeneficiary(widget.beneficiaryId!);
    }
  }

  Future<void> _loadExistingBeneficiary(int id) async {
    try {
      final repository = ref.read(beneficiaryRepositoryProvider);
      final beneficiary = await repository.getBeneficiary(id);
      if (!mounted) return;
      setState(() {
        _nameController.text = beneficiary.name;
        for (final entry in beneficiary.customFieldValues.entries) {
          _controllerFor(entry.key).text = entry.value;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  TextEditingController _controllerFor(int customFieldId) {
    return _fieldControllers.putIfAbsent(customFieldId, () => TextEditingController());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<CustomField> customFields) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final values = <int, String>{
      for (final field in customFields)
        if (_controllerFor(field.id).text.trim().isNotEmpty)
          field.id: _controllerFor(field.id).text.trim(),
    };
    final newBeneficiary =
        NewBeneficiary(name: _nameController.text.trim(), customFieldValues: values);
    try {
      if (_isEditing) {
        await repository.updateBeneficiary(widget.beneficiaryId!, newBeneficiary);
      } else {
        await repository.createBeneficiary(widget.eventId, newBeneficiary);
      }
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.beneficiaryFormTitleEdit : l10n.beneficiaryFormTitleCreate),
      ),
      body: customFieldsAsync.when(
        data: (customFields) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.eventFormNameLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.eventFormNameRequired
                    : null,
              ),
              const SizedBox(height: 16),
              for (final field in customFields) ...[
                TextFormField(
                  controller: _controllerFor(field.id),
                  keyboardType: field.type == CustomFieldType.number
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: field.label),
                  validator: field.type == CustomFieldType.number
                      ? (value) => (value == null ||
                              value.trim().isEmpty ||
                              num.tryParse(value.trim()) != null)
                          ? null
                          : l10n.beneficiaryFormFieldNumberInvalid
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _loading ? null : () => _save(customFields),
                child: Text(l10n.eventFormSaveAction),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart
```

Expected: PASS (all 3 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart
git commit -m "Add beneficiary form screen"
```

---

### Task 8: CSV mapping widget and the import screen

**Files:**
- Create: `lib/features/beneficiaries/presentation/widgets/csv_mapping_form.dart`
- Create: `lib/features/beneficiaries/presentation/screens/csv_import_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/beneficiaries/presentation/widgets/csv_mapping_form_test.dart`

**Interfaces:**
- Consumes: `NewBeneficiary` (Task 2); `CustomField` (jalon 2); `parseCsvContent`/`ParsedCsv` (Task 3); `beneficiaryRepositoryProvider`, `customFieldsProvider` (Tasks 4, jalon 2).
- Produces: `CsvMappingForm({required headers, required dataRows, required customFields, required onImport})`, a pure presentation widget with no repository/provider knowledge, this is the piece with real logic and gets a real test. `CsvImportScreen({required int eventId})`: orchestrates file picking (via `file_picker`) and step transitions, wraps `CsvMappingForm`. Task 9 wires it to route `/events/:id/beneficiaries/import`.

**Deliberate scope limit, do not "fix" this:** `CsvImportScreen`'s file-picking step (`FilePicker.platform.pickFiles()`) is not covered by an automated test. Testing a real file picker requires mocking the `file_picker` platform channel, which is disproportionate effort for glue code around a well-established third-party package. The actual parsing and mapping logic it calls into (`parseCsvContent`, `CsvMappingForm`) are both independently tested. Manual verification of the file-picking step happens when the app is run.

- [ ] **Step 1: Add the ARB keys this task needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "csvImportTitle": "Import beneficiaries",
  "csvImportPickFileAction": "Choose a CSV file",
  "csvImportMappingNameLabel": "Name column",
  "csvImportIgnoreColumn": "Ignore",
  "csvImportImportAction": "Import",
  "csvImportResult": "{imported} beneficiaries imported, {skipped} skipped",
  "@csvImportResult": {
    "placeholders": {
      "imported": {"type": "int"},
      "skipped": {"type": "int"}
    }
  }
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "csvImportTitle": "Importer des beneficiaires",
  "csvImportPickFileAction": "Choisir un fichier CSV",
  "csvImportMappingNameLabel": "Colonne Nom",
  "csvImportIgnoreColumn": "Ignorer",
  "csvImportImportAction": "Importer",
  "csvImportResult": "{imported} beneficiaires importes, {skipped} ignores"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/beneficiaries/presentation/widgets/csv_mapping_form_test.dart
import 'package:dif_pass/features/beneficiaries/domain/new_beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/widgets/csv_mapping_form.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
      'maps the name column and a custom field column, skips rows without a name',
      (tester) async {
    List<NewBeneficiary>? captured;
    var skippedCount = -1;

    await tester.pumpWidget(_wrap(CsvMappingForm(
      headers: const ['Full name', 'Table'],
      dataRows: const [
        ['Jane Doe', '5'],
        ['', '9'],
      ],
      customFields: const [
        CustomField(
          id: 1,
          eventId: 1,
          label: 'Table number',
          type: CustomFieldType.text,
          sortOrder: 0,
          showOnTicket: false,
        ),
      ],
      onImport: (beneficiaries, skipped) {
        captured = beneficiaries;
        skippedCount = skipped;
      },
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full name').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int?>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    expect(captured!.single.name, 'Jane Doe');
    expect(captured!.single.customFieldValues, {1: '5'});
    expect(skippedCount, 1);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/beneficiaries/presentation/widgets/csv_mapping_form_test.dart
```

Expected: FAIL (`csv_mapping_form.dart` does not exist).

- [ ] **Step 4: Implement `CsvMappingForm`**

```dart
// lib/features/beneficiaries/presentation/widgets/csv_mapping_form.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/custom_field.dart';
import '../../domain/new_beneficiary.dart';

class CsvMappingForm extends StatefulWidget {
  const CsvMappingForm({
    required this.headers,
    required this.dataRows,
    required this.customFields,
    required this.onImport,
    super.key,
  });

  final List<String> headers;
  final List<List<String>> dataRows;
  final List<CustomField> customFields;
  final void Function(List<NewBeneficiary> beneficiaries, int skippedCount) onImport;

  @override
  State<CsvMappingForm> createState() => _CsvMappingFormState();
}

class _CsvMappingFormState extends State<CsvMappingForm> {
  int? _nameColumnIndex;
  final Map<int, int?> _customFieldColumnIndex = {};

  void _submit() {
    if (_nameColumnIndex == null) return;
    final beneficiaries = <NewBeneficiary>[];
    var skipped = 0;
    for (final row in widget.dataRows) {
      final name = _nameColumnIndex! < row.length ? row[_nameColumnIndex!].trim() : '';
      if (name.isEmpty) {
        skipped++;
        continue;
      }
      final values = <int, String>{};
      for (final field in widget.customFields) {
        final columnIndex = _customFieldColumnIndex[field.id];
        if (columnIndex != null && columnIndex < row.length) {
          final value = row[columnIndex].trim();
          if (value.isNotEmpty) values[field.id] = value;
        }
      }
      beneficiaries.add(NewBeneficiary(name: name, customFieldValues: values));
    }
    widget.onImport(beneficiaries, skipped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnOptions = <DropdownMenuItem<int?>>[
      DropdownMenuItem(value: null, child: Text(l10n.csvImportIgnoreColumn)),
      for (var i = 0; i < widget.headers.length; i++)
        DropdownMenuItem(value: i, child: Text(widget.headers[i])),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.csvImportMappingNameLabel, style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<int?>(
          value: _nameColumnIndex,
          items: columnOptions,
          onChanged: (value) => setState(() => _nameColumnIndex = value),
        ),
        const SizedBox(height: 16),
        for (final field in widget.customFields) ...[
          Text(field.label, style: Theme.of(context).textTheme.titleSmall),
          DropdownButton<int?>(
            value: _customFieldColumnIndex[field.id],
            items: columnOptions,
            onChanged: (value) => setState(() => _customFieldColumnIndex[field.id] = value),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: _nameColumnIndex != null ? _submit : null,
          child: Text(l10n.csvImportImportAction),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/beneficiaries/presentation/widgets/csv_mapping_form_test.dart
```

Expected: PASS.

- [ ] **Step 6: Implement `CsvImportScreen`** (no dedicated test, see the scope-limit note above)

```dart
// lib/features/beneficiaries/presentation/screens/csv_import_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/csv_parser.dart';
import '../../domain/new_beneficiary.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/beneficiary_providers.dart';
import '../widgets/csv_mapping_form.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  List<String>? _headers;
  List<List<String>>? _dataRows;
  int? _importedCount;
  int? _skippedCount;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
    final content = await File(result.files.single.path!).readAsString();
    final parsed = parseCsvContent(content);
    if (!mounted) return;
    setState(() {
      _headers = parsed.headers;
      _dataRows = parsed.rows;
    });
  }

  Future<void> _handleImport(List<NewBeneficiary> beneficiaries, int skipped) async {
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported =
          await repository.importBeneficiaries(widget.eventId, beneficiaries);
      if (!mounted) return;
      setState(() {
        _importedCount = imported;
        _skippedCount = skipped;
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_importedCount != null) {
      body = Center(
        child: Text(l10n.csvImportResult(_importedCount!, _skippedCount!)),
      );
    } else if (_headers != null && _dataRows != null) {
      final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));
      body = customFieldsAsync.when(
        data: (customFields) => CsvMappingForm(
          headers: _headers!,
          dataRows: _dataRows!,
          customFields: customFields,
          onImport: _handleImport,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
      );
    } else {
      body = Center(
        child: FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(l10n.csvImportPickFileAction),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvImportTitle)),
      body: body,
    );
  }
}
```

- [ ] **Step 7: Run the full suite so far and analyze**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer clean (this step has no new tests of its own, it just confirms `CsvImportScreen` compiles cleanly against everything built so far).

- [ ] **Step 8: Commit**

```bash
git add lib/l10n lib/features/beneficiaries/presentation/widgets/csv_mapping_form.dart lib/features/beneficiaries/presentation/screens/csv_import_screen.dart test/features/beneficiaries/presentation/widgets/csv_mapping_form_test.dart
git commit -m "Add CSV mapping form and the import screen"
```

---

### Task 9: Wire the beneficiaries routes, full milestone check

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Test: `test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `BeneficiariesListScreen` (Task 6), `BeneficiaryFormScreen` (Task 7), `CsvImportScreen` (Task 8).
- Produces: `appRouter` gains 4 routes. This is the last task of the milestone.

- [ ] **Step 1: Write the failing test**

Add this test to the existing file (do not remove the "/" test from jalon 2):

```dart
// test/core/router/app_router_test.dart (append inside main())
testWidgets('app router shows the beneficiaries list at /events/:id/beneficiaries',
    (tester) async {
  final fakeEvents = FakeEventRepository();
  final eventId = await fakeEvents.createEvent(
    name: 'Gala DIF 2026',
    date: DateTime(2026, 12, 1),
    presenceMode: PresenceMode.simple,
    customFields: const [],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(fakeEvents),
        beneficiaryRepositoryProvider.overrideWithValue(FakeBeneficiaryRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  appRouter.go('/events/$eventId/beneficiaries');
  await tester.pumpAndSettle();

  expect(find.text('Beneficiaries'), findsOneWidget);
  expect(
    find.text('No beneficiaries yet. Add one or import a CSV file.'),
    findsOneWidget,
  );
});
```

Add the needed imports at the top of the file:

```dart
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
```

and add this relative import alongside the existing `FakeEventRepository` one:

```dart
import '../../features/beneficiaries/fake_beneficiary_repository.dart';
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: FAIL (route `/events/:id/beneficiaries` does not exist, go_router falls back to an error page or `/`).

- [ ] **Step 3: Wire the routes**

```dart
// lib/core/router/app_router.dart
// Add these imports alongside the existing feature imports:
import '../../features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart';
import '../../features/beneficiaries/presentation/screens/beneficiary_form_screen.dart';
import '../../features/beneficiaries/presentation/screens/csv_import_screen.dart';
```

```dart
// lib/core/router/app_router.dart
// Add these routes to the `routes:` list, alongside the existing events routes:
    GoRoute(
      path: '/events/:id/beneficiaries',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => BeneficiariesListScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/beneficiaries/new',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => BeneficiaryFormScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/beneficiaries/:beneficiaryId/edit',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final beneficiaryId = int.tryParse(state.pathParameters['beneficiaryId'] ?? '');
        return (id == null || beneficiaryId == null) ? '/' : null;
      },
      builder: (context, state) => BeneficiaryFormScreen(
        eventId: int.parse(state.pathParameters['id']!),
        beneficiaryId: int.parse(state.pathParameters['beneficiaryId']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/beneficiaries/import',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => CsvImportScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: PASS (both tests in the file).

- [ ] **Step 5: Run the full suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer reports no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/router test/core/router
git commit -m "Wire beneficiaries routes"
```

---

## Milestone acceptance

Jalon 3 (Beneficiaires) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and from the events list, tapping the "Beneficiaries" icon on an event opens its beneficiaries list, from which an organizer can add a beneficiary manually (with values for the event's custom fields), edit or delete an existing one, and import a batch from a CSV file by mapping its columns, seeing a final "X imported, Y skipped" summary.
