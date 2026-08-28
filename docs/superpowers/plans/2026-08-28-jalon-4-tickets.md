# Jalon 4 - Tickets - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver ticket identifier and QR generation, a per-event Tickets screen (template choice + bulk "generate" + list), and a per-ticket preview screen. This jalon produces an in-app visual preview of a ticket, not the printable PDF (that is jalon 5's job).

**Architecture:** `lib/features/tickets/` follows the same repository-interface pattern as jalons 2/3: screens and providers depend only on `TicketRepository` and domain types, plus the existing `EventRepository`/`BeneficiaryRepository` (a features/tickets -> features/events, features/tickets -> features/beneficiaries dependency, one-directional, matching the established pattern).

**Tech Stack:** Flutter 3.44.7 (FVM) + Riverpod + go_router + Drift + `qr_flutter` (already a dependency since jalon 1, no new packages this jalon) + `dart:math` (`Random.secure()`, stdlib).

## Global Constraints

- Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Never hand-edit generated `.g.dart` or generated localization files.
- No em dashes in code, comments, or commit messages.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits.
- No file starts with a `// path/to/file.dart` first-line comment. This recurred repeatedly in jalon 3 and was fixed each time; do not reintroduce it.
- Any new single-item `FutureProvider.family` added this jalon (`eventProvider`'s fix, the new `beneficiaryProvider`, the new `ticketProvider`) must be `.autoDispose` from the start. jalon 3's final review found `eventProvider` (added without `.autoDispose`) could go stale after a rename; do not repeat that mistake on the new providers.
- `TicketTemplate` lives in the **events** domain (`lib/features/events/domain/ticket_template.dart`), not the tickets domain, because it is stored as a column on `Events` and is conceptually an event-level setting, mirroring `PresenceMode`'s precedent (also an events-domain enum, also consumed by a different feature). `lib/features/tickets/` imports it from there.
- `Event.ticketTemplate` gets a **default value** (`= TicketTemplate.standard`) in its constructor, not a required parameter, specifically so the many existing `Event(...)` constructions across jalon 2/3 test files keep compiling unchanged.
- No schema version bump for the new `Events.ticketTemplate` column: the project is not yet released, same principle already used for jalon 2's cascade-delete addition.
- Ticket generation is idempotent: `generateMissingTickets` only creates tickets for beneficiaries that do not yet have one. Already-issued tickets (`id`, `readableId`, `randomPart`, `qrPayload`) must never change.

---

### Task 1: Prerequisite fixes: `eventProvider.autoDispose` and the `ticketTemplate` column

**Context:** two small pieces of housekeeping bundled because both touch events-feature files before the real tickets work starts. (1) jalon 3's final review recommended making `eventProvider` `.autoDispose`. (2) This jalon needs a place to store the organizer's chosen ticket template per event.

**Files:**
- Modify: `lib/features/events/presentation/providers/event_providers.dart`
- Create: `lib/features/events/domain/ticket_template.dart`
- Modify: `lib/features/events/domain/event.dart`
- Modify: `lib/core/database/tables/events_table.dart`
- Modify (generated): `lib/core/database/app_database.g.dart`
- Modify: `lib/features/events/data/event_repository.dart`
- Modify: `lib/features/events/data/drift_event_repository.dart`
- Modify: `test/features/events/fake_event_repository.dart`
- Test: `test/features/events/data/drift_event_repository_test.dart` (add a case to the existing file)

**Interfaces:**
- Produces: `TicketTemplate` enum (`compact`, `standard`, `elegant`). `Event.ticketTemplate` field (defaults to `TicketTemplate.standard`). `EventRepository.updateTicketTemplate(int, TicketTemplate)`, implemented on both `DriftEventRepository` and `FakeEventRepository`. `eventProvider` is now `FutureProvider.autoDispose.family`. Tasks 6 and 7 depend on all of this.

- [ ] **Step 1: Write the failing test**

Add this test to the existing file (do not remove the tests already there):

```dart
// test/features/events/data/drift_event_repository_test.dart (append inside main(), add the import below at the top)
// import 'package:dif_pass/features/events/domain/ticket_template.dart';

test('updateTicketTemplate persists the chosen template, defaulting to standard', () async {
  final id = await repository.createEvent(
    name: 'Gala DIF 2026',
    date: DateTime(2026, 12, 1),
    presenceMode: PresenceMode.simple,
    customFields: const [],
  );
  expect((await repository.getEvent(id)).ticketTemplate, TicketTemplate.standard);

  await repository.updateTicketTemplate(id, TicketTemplate.elegant);

  expect((await repository.getEvent(id)).ticketTemplate, TicketTemplate.elegant);
});
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/data/drift_event_repository_test.dart
```

Expected: FAIL (`TicketTemplate` does not exist, `Event.ticketTemplate` does not exist, `updateTicketTemplate` does not exist on the interface).

- [ ] **Step 3: Add the enum, the domain field, the schema column, and the repository method**

```dart
// lib/features/events/domain/ticket_template.dart
enum TicketTemplate { compact, standard, elegant }
```

In `lib/features/events/domain/event.dart`, add the import and the field (default value, NOT required):

```dart
import 'ticket_template.dart';
```

```dart
  const Event({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.date,
    this.location,
    this.logo,
    required this.presenceMode,
    this.ticketTemplate = TicketTemplate.standard,
    this.archivedAt,
    required this.createdAt,
  });
```

Add the field declaration alongside the existing ones, after `presenceMode`:

```dart
  final TicketTemplate ticketTemplate;
```

In `lib/core/database/tables/events_table.dart`, add a column after `presenceMode`:

```dart
  // ponytail: plain text ('compact' | 'standard' | 'elegant') instead of
  // Drift's textEnum<T>() sugar, same reasoning as presenceMode above.
  TextColumn get ticketTemplate =>
      text().withDefault(const Constant('standard'))();
```

Regenerate:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

In `lib/features/events/data/event_repository.dart`, add the import and the new abstract method:

```dart
import 'ticket_template.dart';
```
(add alongside the existing domain imports, path is `../domain/ticket_template.dart`)

```dart
  Future<void> updateTicketTemplate(int eventId, TicketTemplate template);
```
(add inside the `abstract class EventRepository { ... }` body, anywhere after the existing methods)

In `lib/features/events/data/drift_event_repository.dart`:

Add the import:
```dart
import '../domain/ticket_template.dart';
```

Update `_toEvent` to include the new field:
```dart
  Event _toEvent(EventEntity row) {
    return Event(
      id: row.id,
      shortCode: row.shortCode,
      name: row.name,
      date: row.date,
      location: row.location,
      logo: row.logo,
      presenceMode: PresenceMode.values.byName(row.presenceMode),
      ticketTemplate: TicketTemplate.values.byName(row.ticketTemplate),
      archivedAt: row.archivedAt,
      createdAt: row.createdAt,
    );
  }
```

Add the new method (anywhere in the class body):
```dart
  @override
  Future<void> updateTicketTemplate(int eventId, TicketTemplate template) async {
    await (_db.update(_db.events)..where((tbl) => tbl.id.equals(eventId)))
        .write(EventsCompanion(ticketTemplate: Value(template.name)));
  }
```

In `lib/features/events/presentation/providers/event_providers.dart`, change:

```dart
final eventProvider = FutureProvider.family<Event, int>((ref, id) {
  return ref.watch(eventRepositoryProvider).getEvent(id);
});
```
to:
```dart
final eventProvider = FutureProvider.autoDispose.family<Event, int>((ref, id) {
  return ref.watch(eventRepositoryProvider).getEvent(id);
});
```

In `test/features/events/fake_event_repository.dart`:

Add the import:
```dart
import 'package:dif_pass/features/events/domain/ticket_template.dart';
```

In `updateEvent`, `archiveEvent`, and `restoreEvent`, each of which reconstructs a new `Event` copying fields from `existing`, add `ticketTemplate: existing.ticketTemplate,` to each reconstruction (right after the `presenceMode:` line in each) so a previously-chosen template is not silently reset to the default whenever any of those three methods run. `createEvent` needs no change (a newly created event correctly gets the default via `Event`'s own default parameter).

Add the new method to the class:
```dart
  @override
  Future<void> updateTicketTemplate(int eventId, TicketTemplate template) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    final existing = _events[index];
    _events[index] = Event(
      id: existing.id,
      shortCode: existing.shortCode,
      name: existing.name,
      date: existing.date,
      location: existing.location,
      logo: existing.logo,
      presenceMode: existing.presenceMode,
      ticketTemplate: template,
      archivedAt: existing.archivedAt,
      createdAt: existing.createdAt,
    );
    _emit();
  }
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/data/drift_event_repository_test.dart
```

Expected: PASS (all tests in the file, including the new one).

- [ ] **Step 5: Run the full suite as a regression check**

```bash
fvm flutter test
```

Expected: all existing tests still pass (this confirms the default-valued `ticketTemplate` field did not break any existing `Event(...)` construction across the codebase, and the three `FakeEventRepository` copy-sites now preserve it correctly).

- [ ] **Step 6: Commit**

```bash
git add lib/features/events lib/core/database test/features/events
git commit -m "Add ticketTemplate to Event and make eventProvider autoDispose"
```

---

### Task 2: Ticket domain model and identifier generator

**Files:**
- Create: `lib/features/tickets/domain/ticket.dart`
- Create: `lib/features/tickets/data/ticket_id_generator.dart`
- Test: `test/features/tickets/data/ticket_id_generator_test.dart`

**Interfaces:**
- Produces: `Ticket` (`id`, `beneficiaryId`, `eventId`, `readableId`, `randomPart`, `qrPayload`, `createdAt`). `GeneratedTicketId` (`readableId`, `randomPart`, `payloadFor(String eventShortCode) -> String`) and `generateTicketId({required int sequence, Random? random}) -> GeneratedTicketId`, a pure function with an injectable `Random` for deterministic tests. Task 3 (repository) is the only consumer of `generateTicketId`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/tickets/data/ticket_id_generator_test.dart
import 'dart:math';

import 'package:dif_pass/features/tickets/data/ticket_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const _safeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

void main() {
  test('generateTicketId pads the sequence to 4 digits', () {
    final result = generateTicketId(sequence: 42, random: Random(1));
    expect(result.readableId, '0042');
  });

  test('generateTicketId produces a 4-character random part from the safe alphabet', () {
    final result = generateTicketId(sequence: 1, random: Random(1));
    expect(result.randomPart, hasLength(4));
    expect(
      result.randomPart.split('').every((c) => _safeAlphabet.contains(c)),
      isTrue,
    );
  });

  test('payloadFor assembles the full ticket identifier', () {
    final result = generateTicketId(sequence: 42, random: Random(1));
    expect(result.payloadFor('EVT3'), 'EVT3-0042-${result.randomPart}');
  });

  test('generateTicketId defaults to Random.secure and still produces a valid format', () {
    final result = generateTicketId(sequence: 7);
    expect(result.readableId, '0007');
    expect(result.randomPart, hasLength(4));
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/data/ticket_id_generator_test.dart
```

Expected: FAIL (`ticket_id_generator.dart` does not exist).

- [ ] **Step 3: Implement the domain model and the generator**

```dart
// lib/features/tickets/domain/ticket.dart
class Ticket {
  const Ticket({
    required this.id,
    required this.beneficiaryId,
    required this.eventId,
    required this.readableId,
    required this.randomPart,
    required this.qrPayload,
    required this.createdAt,
  });

  final int id;
  final int beneficiaryId;
  final int eventId;
  final String readableId;
  final String randomPart;
  final String qrPayload;
  final DateTime createdAt;
}
```

```dart
// lib/features/tickets/data/ticket_id_generator.dart
import 'dart:math';

const _safeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class GeneratedTicketId {
  const GeneratedTicketId({required this.readableId, required this.randomPart});

  final String readableId;
  final String randomPart;

  String payloadFor(String eventShortCode) =>
      '$eventShortCode-$readableId-$randomPart';
}

GeneratedTicketId generateTicketId({required int sequence, Random? random}) {
  final rng = random ?? Random.secure();
  final readableId = sequence.toString().padLeft(4, '0');
  final randomPart = List.generate(
    4,
    (_) => _safeAlphabet[rng.nextInt(_safeAlphabet.length)],
  ).join();
  return GeneratedTicketId(readableId: readableId, randomPart: randomPart);
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/data/ticket_id_generator_test.dart
```

Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/domain lib/features/tickets/data/ticket_id_generator.dart test/features/tickets/data/ticket_id_generator_test.dart
git commit -m "Add Ticket domain model and identifier generator"
```

---

### Task 3: TicketRepository and its Drift implementation

**Files:**
- Create: `lib/features/tickets/data/ticket_repository.dart`
- Create: `lib/features/tickets/data/drift_ticket_repository.dart`
- Test: `test/features/tickets/data/drift_ticket_repository_test.dart`

**Interfaces:**
- Consumes: `Ticket`, `generateTicketId` (Task 2); `AppDatabase` (jalon 1).
- Produces: `TicketRepository` (abstract) with `watchTicketsForEvent(int)`, `getTicket(int)`, `generateMissingTickets(int) -> Future<int>`. `DriftTicketRepository implements TicketRepository`. Task 4 (providers) depends on these exact names and signatures.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/tickets/data/drift_ticket_repository_test.dart
import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/tickets/data/drift_ticket_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTicketRepository repository;
  late int eventId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTicketRepository(db);
    eventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
  });

  tearDown(() => db.close());

  Future<int> insertBeneficiary(String name) {
    return db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: eventId, name: name),
        );
  }

  test('generateMissingTickets creates one ticket per beneficiary without one', () async {
    await insertBeneficiary('Jane Doe');
    await insertBeneficiary('John Smith');

    final created = await repository.generateMissingTickets(eventId);

    expect(created, 2);
    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(2));
    expect(tickets.map((t) => t.readableId).toList(), ['0001', '0002']);
    expect(tickets.every((t) => t.qrPayload.startsWith('EVT1-')), isTrue);
  });

  test('generateMissingTickets is idempotent, only fills gaps', () async {
    final firstBeneficiaryId = await insertBeneficiary('Jane Doe');
    await repository.generateMissingTickets(eventId);
    final firstTicket = (await repository.watchTicketsForEvent(eventId).first).single;

    await insertBeneficiary('John Smith');
    final createdSecondRound = await repository.generateMissingTickets(eventId);

    expect(createdSecondRound, 1);
    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(2));
    final unchangedTicket =
        tickets.firstWhere((t) => t.beneficiaryId == firstBeneficiaryId);
    expect(unchangedTicket.id, firstTicket.id);
    expect(unchangedTicket.readableId, firstTicket.readableId);
    expect(unchangedTicket.randomPart, firstTicket.randomPart);
    expect(tickets.map((t) => t.readableId).toSet(), {'0001', '0002'});
  });

  test('watchTicketsForEvent only returns tickets for the given event, sorted by readableId', () async {
    final otherEventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT2',
            name: 'Other event',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await insertBeneficiary('Jane Doe');
    await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: otherEventId, name: 'Other person'),
        );
    await repository.generateMissingTickets(eventId);
    await DriftTicketRepository(db).generateMissingTickets(otherEventId);

    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(1));
    expect(tickets.single.eventId, eventId);
  });

  test('getTicket returns a single ticket by id', () async {
    await insertBeneficiary('Jane Doe');
    await repository.generateMissingTickets(eventId);
    final ticket = (await repository.watchTicketsForEvent(eventId).first).single;

    final fetched = await repository.getTicket(ticket.id);
    expect(fetched.readableId, ticket.readableId);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/data/drift_ticket_repository_test.dart
```

Expected: FAIL (`package:dif_pass/features/tickets/data/drift_ticket_repository.dart` does not exist).

- [ ] **Step 3: Implement the repository**

```dart
// lib/features/tickets/data/ticket_repository.dart
import '../domain/ticket.dart';

abstract class TicketRepository {
  Stream<List<Ticket>> watchTicketsForEvent(int eventId);
  Future<Ticket> getTicket(int id);
  Future<int> generateMissingTickets(int eventId);
}
```

```dart
// lib/features/tickets/data/drift_ticket_repository.dart
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/ticket.dart';
import 'ticket_id_generator.dart';
import 'ticket_repository.dart';

class DriftTicketRepository implements TicketRepository {
  DriftTicketRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Ticket>> watchTicketsForEvent(int eventId) {
    final query = _db.select(_db.tickets)
      ..where((tbl) => tbl.eventId.equals(eventId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.readableId)]);
    return query.watch().map((rows) => rows.map(_toTicket).toList());
  }

  @override
  Future<Ticket> getTicket(int id) async {
    final row = await (_db.select(_db.tickets)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    return _toTicket(row);
  }

  @override
  Future<int> generateMissingTickets(int eventId) {
    return _db.transaction(() async {
      final event = await (_db.select(_db.events)
            ..where((tbl) => tbl.id.equals(eventId)))
          .getSingle();

      final beneficiaryRows = await (_db.select(_db.beneficiaries)
            ..where((tbl) => tbl.eventId.equals(eventId))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
          .get();

      final existingTickets = await (_db.select(_db.tickets)
            ..where((tbl) => tbl.eventId.equals(eventId)))
          .get();
      final beneficiariesWithTickets =
          existingTickets.map((t) => t.beneficiaryId).toSet();

      var nextSequence = 1;
      for (final ticket in existingTickets) {
        final parsed = int.tryParse(ticket.readableId);
        if (parsed != null && parsed >= nextSequence) {
          nextSequence = parsed + 1;
        }
      }

      var createdCount = 0;
      for (final beneficiary in beneficiaryRows) {
        if (beneficiariesWithTickets.contains(beneficiary.id)) continue;

        final generated = generateTicketId(sequence: nextSequence);
        await _db.into(_db.tickets).insert(
              TicketsCompanion.insert(
                beneficiaryId: beneficiary.id,
                eventId: eventId,
                readableId: generated.readableId,
                randomPart: generated.randomPart,
                qrPayload: generated.payloadFor(event.shortCode),
              ),
            );
        nextSequence++;
        createdCount++;
      }

      return createdCount;
    });
  }

  Ticket _toTicket(TicketEntity row) {
    return Ticket(
      id: row.id,
      beneficiaryId: row.beneficiaryId,
      eventId: row.eventId,
      readableId: row.readableId,
      randomPart: row.randomPart,
      qrPayload: row.qrPayload,
      createdAt: row.createdAt,
    );
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/data/drift_ticket_repository_test.dart
```

Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/data/ticket_repository.dart lib/features/tickets/data/drift_ticket_repository.dart test/features/tickets/data/drift_ticket_repository_test.dart
git commit -m "Add TicketRepository and its Drift implementation"
```

---

### Task 4: Riverpod providers and shared test fakes

**Files:**
- Create: `lib/features/tickets/presentation/providers/ticket_providers.dart`
- Modify: `lib/features/beneficiaries/presentation/providers/beneficiary_providers.dart`
- Create: `test/features/tickets/fake_ticket_repository.dart`
- Test: `test/features/tickets/presentation/providers/ticket_providers_test.dart`

**Interfaces:**
- Consumes: `TicketRepository`, `DriftTicketRepository` (Task 3); `appDatabaseProvider` (jalon 1); `BeneficiaryRepository` (jalon 3).
- Produces: `ticketRepositoryProvider` (`Provider<TicketRepository>`), `ticketsProvider` (`StreamProvider.family<List<Ticket>, int>`, keyed by eventId), `ticketProvider` (`FutureProvider.autoDispose.family<Ticket, int>`, keyed by ticket id). `beneficiaryProvider` (`FutureProvider.autoDispose.family<Beneficiary, int>`, keyed by beneficiary id, added to the existing jalon 3 providers file). `FakeTicketRepository` (test-only, `test/features/tickets/fake_ticket_repository.dart`) implements `TicketRepository` in memory, taking an injectable `beneficiaryIdsForEvent` callback so tests can wire it to whatever `FakeBeneficiaryRepository` they are already using, without a hard dependency between the two fakes. Tasks 6, 7, 8 all use it.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/tickets/presentation/providers/ticket_providers_test.dart
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_ticket_repository.dart';

void main() {
  test('ticketsProvider streams tickets for the given event from the overridden repository', () async {
    final fake = FakeTicketRepository(tickets: [
      Ticket(
        id: 1,
        beneficiaryId: 1,
        eventId: 42,
        readableId: '0001',
        randomPart: 'ABCD',
        qrPayload: 'EVT-0001-ABCD',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [ticketRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final tickets = await container.read(ticketsProvider(42).future);
    expect(tickets, hasLength(1));
    expect(tickets.single.readableId, '0001');
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/presentation/providers/ticket_providers_test.dart
```

Expected: FAIL (neither file exists).

- [ ] **Step 3: Implement the providers and the fake**

```dart
// lib/features/tickets/presentation/providers/ticket_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/drift_ticket_repository.dart';
import '../../data/ticket_repository.dart';
import '../../domain/ticket.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTicketRepository(db);
});

final ticketsProvider = StreamProvider.family<List<Ticket>, int>((ref, eventId) {
  return ref.watch(ticketRepositoryProvider).watchTicketsForEvent(eventId);
});

final ticketProvider = FutureProvider.autoDispose.family<Ticket, int>((ref, id) {
  return ref.watch(ticketRepositoryProvider).getTicket(id);
});
```

In `lib/features/beneficiaries/presentation/providers/beneficiary_providers.dart`, add:

```dart
final beneficiaryProvider = FutureProvider.autoDispose.family<Beneficiary, int>((ref, id) {
  return ref.watch(beneficiaryRepositoryProvider).getBeneficiary(id);
});
```

```dart
// test/features/tickets/fake_ticket_repository.dart
import 'dart:async';

import 'package:dif_pass/features/tickets/data/ticket_repository.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';

/// In-memory TicketRepository for widget/provider tests. Not shipped in
/// the app, lives under test/ only.
///
/// [beneficiaryIdsForEvent] lets a test say which beneficiary ids exist for
/// a given event, without this fake depending on FakeBeneficiaryRepository's
/// type. Wire it to whatever fake beneficiary repository the same test
/// already constructed, e.g.
/// `(eventId) => fakeBeneficiaries.beneficiaries.where((b) => b.eventId == eventId).map((b) => b.id).toList()`.
class FakeTicketRepository implements TicketRepository {
  FakeTicketRepository({
    List<Ticket>? tickets,
    List<int> Function(int eventId)? beneficiaryIdsForEvent,
  })  : _tickets = List.of(tickets ?? const []),
        _beneficiaryIdsForEvent = beneficiaryIdsForEvent ?? ((_) => const []);

  final List<Ticket> _tickets;
  final List<int> Function(int eventId) _beneficiaryIdsForEvent;
  final Map<int, StreamController<List<Ticket>>> _controllers = {};
  int _nextId = 1000;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  StreamController<List<Ticket>> _controllerFor(int eventId) {
    return _controllers.putIfAbsent(
      eventId,
      () => StreamController<List<Ticket>>.broadcast(),
    );
  }

  void _emit(int eventId) {
    final list = _tickets.where((t) => t.eventId == eventId).toList()
      ..sort((a, b) => a.readableId.compareTo(b.readableId));
    _controllerFor(eventId).add(list);
  }

  @override
  Stream<List<Ticket>> watchTicketsForEvent(int eventId) {
    Future.microtask(() => _emit(eventId));
    return _controllerFor(eventId).stream;
  }

  @override
  Future<Ticket> getTicket(int id) async =>
      _tickets.firstWhere((t) => t.id == id);

  @override
  Future<int> generateMissingTickets(int eventId) async {
    final beneficiaryIds = _beneficiaryIdsForEvent(eventId);
    final withTickets = _tickets
        .where((t) => t.eventId == eventId)
        .map((t) => t.beneficiaryId)
        .toSet();

    var sequence = _tickets
            .where((t) => t.eventId == eventId)
            .map((t) => int.tryParse(t.readableId) ?? 0)
            .fold<int>(0, (highest, value) => value > highest ? value : highest) +
        1;

    var created = 0;
    for (final beneficiaryId in beneficiaryIds) {
      if (withTickets.contains(beneficiaryId)) continue;
      final readableId = sequence.toString().padLeft(4, '0');
      _tickets.add(Ticket(
        id: _nextId++,
        beneficiaryId: beneficiaryId,
        eventId: eventId,
        readableId: readableId,
        randomPart: 'TEST',
        qrPayload: 'EVT-$readableId-TEST',
        createdAt: DateTime.now(),
      ));
      sequence++;
      created++;
    }
    _emit(eventId);
    return created;
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/presentation/providers/ticket_providers_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/presentation/providers lib/features/beneficiaries/presentation/providers/beneficiary_providers.dart test/features/tickets/fake_ticket_repository.dart test/features/tickets/presentation/providers
git commit -m "Add ticket providers and a fake repository for tests"
```

---

### Task 5: "Tickets" entry point on the events list

**Files:**
- Modify: `lib/features/events/presentation/widgets/event_card.dart`
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`

**Interfaces:**
- Produces: `EventCard` gains a new required `onManageTickets` (`VoidCallback`) parameter, a third trailing icon (alongside Beneficiaries and Archive). `EventsListScreen` wires it to `/events/<id>/tickets`.

- [ ] **Step 1: Add the ARB key this change needs**

```json
// lib/l10n/app_en.arb (add this key, keep the existing ones)
{
  "eventsTicketsAction": "Tickets"
}
```

```json
// lib/l10n/app_fr.arb (add this key, keep the existing ones)
{
  "eventsTicketsAction": "Tickets"
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
testWidgets('shows a tickets action for each event', (tester) async {
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

  expect(find.byTooltip('Tickets'), findsOneWidget);
});
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: FAIL (no widget with tooltip "Tickets" exists yet).

- [ ] **Step 4: Add the button**

In `lib/features/events/presentation/widgets/event_card.dart`, add `onManageTickets` to the constructor and fields:

```dart
  const EventCard({
    required this.event,
    required this.onTap,
    required this.onManageBeneficiaries,
    required this.onManageTickets,
    required this.onArchive,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onManageBeneficiaries;
  final VoidCallback onManageTickets;
  final VoidCallback onArchive;
```

Add a third `IconButton` to the trailing `Row`, between the beneficiaries and archive buttons:

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
              icon: const Icon(Icons.confirmation_number_outlined),
              tooltip: l10n.eventsTicketsAction,
              onPressed: onManageTickets,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: l10n.eventsArchiveEventAction,
              onPressed: onArchive,
            ),
          ],
        ),
```

In `lib/features/events/presentation/screens/events_list_screen.dart`, add to the `EventCard(...)` construction:

```dart
                onManageTickets: () =>
                    context.push('/events/${event.id}/tickets'),
```
(add it between `onManageBeneficiaries` and `onArchive`)

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: PASS (all tests in the file).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/widgets/event_card.dart lib/features/events/presentation/screens/events_list_screen.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Add a tickets entry point to the events list"
```

---

### Task 6: Tickets screen (template choice, bulk generate, list)

**Files:**
- Create: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/tickets/presentation/screens/tickets_screen_test.dart`

**Interfaces:**
- Consumes: `eventProvider`, `eventRepositoryProvider` (jalon 2/Task 1); `beneficiariesProvider` (jalon 3); `ticketsProvider`, `ticketRepositoryProvider` (Task 4); `TicketTemplate` (Task 1).
- Produces: `TicketsScreen({required int eventId})`, the widget Task 8 wires to route `/events/:id/tickets`.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "ticketsScreenTitle": "Tickets",
  "ticketsTemplateLabel": "Ticket template",
  "ticketsTemplateCompact": "Compact",
  "ticketsTemplateStandard": "Standard",
  "ticketsTemplateElegant": "Elegant",
  "ticketsGenerateAction": "Generate tickets",
  "ticketsEmptyState": "No tickets yet.",
  "ticketsLoadError": "Something went wrong loading tickets."
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "ticketsScreenTitle": "Tickets",
  "ticketsTemplateLabel": "Modele de ticket",
  "ticketsTemplateCompact": "Compact",
  "ticketsTemplateStandard": "Standard",
  "ticketsTemplateElegant": "Elegant",
  "ticketsGenerateAction": "Generer les tickets",
  "ticketsEmptyState": "Aucun ticket pour l'instant.",
  "ticketsLoadError": "Un probleme est survenu lors du chargement des tickets."
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/tickets/presentation/screens/tickets_screen_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/features/tickets/presentation/screens/tickets_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../fake_ticket_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeTicketRepository fakeTickets,
) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

FakeEventRepository _fakeEventsWithOneEvent() {
  return FakeEventRepository(events: [
    Event(
      id: 1,
      shortCode: 'EVT1',
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      createdAt: DateTime(2026, 1, 1),
    ),
  ]);
}

void main() {
  testWidgets(
      'shows the empty state and an enabled generate button when a beneficiary has no ticket yet',
      (tester) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final fakeTickets = FakeTicketRepository(
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(_wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    expect(find.text('No tickets yet.'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('generate button is disabled once every beneficiary has a ticket',
      (tester) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final fakeTickets = FakeTicketRepository(
      tickets: [
        Ticket(
          id: 1,
          beneficiaryId: 1,
          eventId: 1,
          readableId: '0001',
          randomPart: 'ABCD',
          qrPayload: 'EVT1-0001-ABCD',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(_wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping generate creates tickets and the list updates', (tester) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final fakeTickets = FakeTicketRepository(
      beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
          .where((b) => b.eventId == eventId)
          .map((b) => b.id)
          .toList(),
    );

    await tester.pumpWidget(_wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(fakeTickets.tickets, hasLength(1));
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart
```

Expected: FAIL (`tickets_screen.dart` does not exist).

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/tickets/presentation/screens/tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/ticket_providers.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventAsync = ref.watch(eventProvider(eventId));
    final beneficiariesAsync = ref.watch(beneficiariesProvider(eventId));
    final ticketsAsync = ref.watch(ticketsProvider(eventId));

    final event = eventAsync.valueOrNull;
    final beneficiaries = beneficiariesAsync.valueOrNull ?? const [];
    final tickets = ticketsAsync.valueOrNull ?? const [];
    final canGenerate = beneficiaries.length > tickets.length;

    return Scaffold(
      appBar: AppBar(
        title: event == null
            ? Text(l10n.ticketsScreenTitle)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ticketsScreenTitle),
                  Text(event.name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ticketsTemplateLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (event != null)
              SegmentedButton<TicketTemplate>(
                segments: [
                  ButtonSegment(
                    value: TicketTemplate.compact,
                    label: Text(l10n.ticketsTemplateCompact),
                  ),
                  ButtonSegment(
                    value: TicketTemplate.standard,
                    label: Text(l10n.ticketsTemplateStandard),
                  ),
                  ButtonSegment(
                    value: TicketTemplate.elegant,
                    label: Text(l10n.ticketsTemplateElegant),
                  ),
                ],
                selected: {event.ticketTemplate},
                onSelectionChanged: (selection) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(eventRepositoryProvider)
                        .updateTicketTemplate(eventId, selection.first);
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canGenerate
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(ticketRepositoryProvider)
                            .generateMissingTickets(eventId);
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  : null,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: Text(l10n.ticketsGenerateAction),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ticketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.ticketsEmptyState,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }
                  final beneficiaryNames = {
                    for (final beneficiary in beneficiaries) beneficiary.id: beneficiary.name,
                  };
                  return ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(beneficiaryNames[ticket.beneficiaryId] ?? ''),
                          subtitle: Text(ticket.readableId),
                          onTap: () =>
                              context.push('/events/$eventId/tickets/${ticket.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(l10n.ticketsLoadError)),
              ),
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
fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart
```

Expected: PASS (all 3 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/tickets/presentation/screens/tickets_screen.dart test/features/tickets/presentation/screens/tickets_screen_test.dart
git commit -m "Add the tickets screen with template choice and bulk generation"
```

---

### Task 7: Ticket preview screen

**Files:**
- Create: `lib/features/tickets/presentation/screens/ticket_preview_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/tickets/presentation/screens/ticket_preview_screen_test.dart`

**Interfaces:**
- Consumes: `ticketProvider` (Task 4); `beneficiaryProvider` (Task 4); `eventProvider` (jalon 2/Task 1); `customFieldsProvider` (jalon 2); `ticketMonoStyle` (jalon 1, `lib/core/theme/app_typography.dart`); `qr_flutter`'s `QrImageView`.
- Produces: `TicketPreviewScreen({required int ticketId})`, the widget Task 8 wires to route `/events/:id/tickets/:ticketId`. This screen only needs `ticketId`, it derives `eventId`/`beneficiaryId` from the fetched `Ticket`.

- [ ] **Step 1: Add the ARB key this screen needs**

```json
// lib/l10n/app_en.arb (add this key, keep the existing ones)
{
  "ticketPreviewTitle": "Ticket"
}
```

```json
// lib/l10n/app_fr.arb (add this key, keep the existing ones)
{
  "ticketPreviewTitle": "Ticket"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/features/tickets/presentation/screens/ticket_preview_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../fake_ticket_repository.dart';

Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeTicketRepository fakeTickets,
) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets(
      'shows the beneficiary name, readable id, and only the checked custom fields',
      (tester) async {
    final fakeEvents = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    await fakeEvents.replaceCustomFields(1, const [
      NewCustomField(
        label: 'Table number',
        type: CustomFieldType.text,
        sortOrder: 0,
        showOnTicket: true,
      ),
      NewCustomField(
        label: 'Internal note',
        type: CustomFieldType.text,
        sortOrder: 1,
        showOnTicket: false,
      ),
    ]);
    final fields = await fakeEvents.watchCustomFields(1).first;
    final tableFieldId = fields.firstWhere((f) => f.label == 'Table number').id;
    final noteFieldId = fields.firstWhere((f) => f.label == 'Internal note').id;

    final fakeBeneficiaries = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: {tableFieldId: 'Table 5', noteFieldId: 'VIP'},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final fakeTickets = FakeTicketRepository(tickets: [
      Ticket(
        id: 1,
        beneficiaryId: 1,
        eventId: 1,
        readableId: '0001',
        randomPart: 'ABCD',
        qrPayload: 'EVT1-0001-ABCD',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(
      const TicketPreviewScreen(ticketId: 1),
      fakeEvents,
      fakeBeneficiaries,
      fakeTickets,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('0001'), findsOneWidget);
    expect(find.text('Table number: Table 5'), findsOneWidget);
    expect(find.text('Internal note: VIP'), findsNothing);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
```

Expected: FAIL (`ticket_preview_screen.dart` does not exist).

- [ ] **Step 4: Implement the screen**

```dart
// lib/features/tickets/presentation/screens/ticket_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/ticket_providers.dart';

class TicketPreviewScreen extends ConsumerWidget {
  const TicketPreviewScreen({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ticketAsync = ref.watch(ticketProvider(ticketId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketPreviewTitle)),
      body: ticketAsync.when(
        data: (ticket) {
          final beneficiaryAsync = ref.watch(beneficiaryProvider(ticket.beneficiaryId));
          final eventAsync = ref.watch(eventProvider(ticket.eventId));
          final customFieldsAsync = ref.watch(customFieldsProvider(ticket.eventId));

          if (!beneficiaryAsync.hasValue ||
              !eventAsync.hasValue ||
              !customFieldsAsync.hasValue) {
            return const Center(child: CircularProgressIndicator());
          }

          final beneficiary = beneficiaryAsync.value!;
          final event = eventAsync.value!;
          final visibleFields =
              customFieldsAsync.value!.where((f) => f.showOnTicket).toList();

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _TicketCard(
                template: event.ticketTemplate,
                eventName: event.name,
                beneficiaryName: beneficiary.name,
                readableId: ticket.readableId,
                qrPayload: ticket.qrPayload,
                visibleFieldLines: [
                  for (final field in visibleFields)
                    if (beneficiary.customFieldValues[field.id] != null)
                      '${field.label}: ${beneficiary.customFieldValues[field.id]}',
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.ticketsLoadError)),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.template,
    required this.eventName,
    required this.beneficiaryName,
    required this.readableId,
    required this.qrPayload,
    required this.visibleFieldLines,
  });

  final TicketTemplate template;
  final String eventName;
  final String beneficiaryName;
  final String readableId;
  final String qrPayload;
  final List<String> visibleFieldLines;

  @override
  Widget build(BuildContext context) {
    final isElegant = template == TicketTemplate.elegant;
    final isCompact = template == TicketTemplate.compact;

    return Card(
      color: isElegant ? AppColors.indigo.withValues(alpha: 0.05) : null,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(eventName, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: isCompact ? 8 : 16),
            QrImageView(
              data: qrPayload,
              size: isCompact ? 120 : 180,
            ),
            SizedBox(height: isCompact ? 8 : 16),
            Text(beneficiaryName, style: Theme.of(context).textTheme.titleLarge),
            Text(
              readableId,
              style: ticketMonoStyle(Theme.of(context).colorScheme),
            ),
            for (final line in visibleFieldLines) ...[
              const SizedBox(height: 4),
              Text(line),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/tickets/presentation/screens/ticket_preview_screen.dart test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
git commit -m "Add the ticket preview screen"
```

---

### Task 8: Wire the tickets routes, full milestone check

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Test: `test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `TicketsScreen` (Task 6), `TicketPreviewScreen` (Task 7).
- Produces: `appRouter` gains 2 routes. This is the last task of the milestone.

- [ ] **Step 1: Write the failing test**

Add this test to the existing file (do not remove the tests already there):

```dart
// test/core/router/app_router_test.dart (append inside main())
testWidgets('app router shows the tickets screen at /events/:id/tickets',
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
        ticketRepositoryProvider.overrideWithValue(FakeTicketRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  appRouter.go('/events/$eventId/tickets');
  await tester.pumpAndSettle();

  expect(find.text('Tickets'), findsWidgets);
  expect(find.text('No tickets yet.'), findsOneWidget);
});
```

Add the needed imports at the top of the file, alongside the existing ones:

```dart
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
```

and this relative import alongside the existing fake-repository ones:

```dart
import '../../features/tickets/fake_ticket_repository.dart';
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: FAIL (route `/events/:id/tickets` does not exist).

- [ ] **Step 3: Wire the routes**

```dart
// lib/core/router/app_router.dart
// Add these imports alongside the existing feature imports:
import '../../features/tickets/presentation/screens/ticket_preview_screen.dart';
import '../../features/tickets/presentation/screens/tickets_screen.dart';
```

```dart
// lib/core/router/app_router.dart
// Add these routes to the `routes:` list, alongside the existing routes:
    GoRoute(
      path: '/events/:id/tickets',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => TicketsScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/tickets/:ticketId',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final ticketId = int.tryParse(state.pathParameters['ticketId'] ?? '');
        return (id == null || ticketId == null) ? '/' : null;
      },
      builder: (context, state) => TicketPreviewScreen(
        ticketId: int.parse(state.pathParameters['ticketId']!),
      ),
    ),
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: PASS (all tests in the file).

- [ ] **Step 5: Run the full suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer reports no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/router test/core/router
git commit -m "Wire tickets routes"
```

---

## Milestone acceptance

Jalon 4 (Tickets) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and from an event's Tickets screen, an organizer can pick a template, generate tickets for every beneficiary who does not have one yet (idempotently, re-running after adding more beneficiaries only fills the gap), and tap any ticket to see a preview with its QR code, readable identifier, and the custom fields checked "show on ticket".
