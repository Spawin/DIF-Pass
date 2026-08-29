# Jalon 6 - Controle de presence - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an organizer scan (or manually type) a ticket at the door, record the beneficiary's presence according to the event's `PresenceMode`, and see a live animated counter of how many distinct tickets have been checked in. This closes cahier des charges section 4.

**Architecture:** A new `lib/features/checkin/` feature follows the same repository-interface pattern as every prior jalon. `TicketRepository` (jalon 4) gains one lookup method (`findTicketForCheckIn`) shared by both the camera and manual-entry paths. All business logic (ticket resolution, check-in recording, feedback selection) is extracted into plain, framework-independent functions so it is directly unit-testable; the camera widget itself is a thin shell around that logic and is deliberately not unit-tested (see Global Constraints).

**Tech Stack:** Flutter 3.44.7 (FVM) + Riverpod + go_router + Drift + `mobile_scanner` (camera scan, already a dependency since jalon 1, first real use in this codebase) + `flutter_animate` (counter animation, already a dependency since jalon 1, first real use in this codebase) + `HapticFeedback` from `package:flutter/services.dart` (stdlib, no new dependency). No new package for this jalon.

## Global Constraints

- Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Never hand-edit generated `.g.dart` or generated localization files.
- No em dashes in code, comments, or commit messages.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits.
- No file starts with a `// path/to/file.dart` first-line comment.
- No new dependency: `mobile_scanner`, `flutter_animate`, and `package:flutter/services.dart` (`HapticFeedback`) are already available.
- **`CheckInScanScreen` (Task 7) is never pumped in a widget test, and no router test navigates to `/events/:id/checkin` (Task 8).** `mobile_scanner` 7.4.0's `MobileScanner` widget calls `unawaited(_initializeController())` from `initState`, which calls `MobileScannerController.start()`, which makes a real platform-channel call. `flutter test` registers no mock for that channel, so the call throws, and because the call was never awaited by anything, the rejection becomes an unhandled async error the test framework cannot associate with a specific expectation. This mirrors an existing, deliberate precedent in this codebase: `CsvImportScreen` (jalon 3, wraps `file_picker`) has no screen-level test file and no router test navigates to `/events/:id/beneficiaries/import` either, only its testable sub-widget (`CsvMappingForm`) is tested. All business logic in this jalon is extracted into plain functions and a standalone widget precisely so it can be fully tested without ever constructing `MobileScanner` (Tasks 1-6 below).
- `checkInCounterProvider` must never divide; it returns a `(checkedIn, total)` record of two integers for the caller to format as text (e.g. `"0/0"` when an event has no tickets yet is a valid, crash-free display, not a division).

---

### Task 1: CheckIn domain model, CheckInOutcome, and CheckInRepository (Drift)

**Context:** First task of the milestone. Creates the check-in data layer: the `CheckIns` Drift table already exists (jalon 1 schema, `id`, `ticketId`, `eventId`, `scannedAt` with a DB-generated default). No schema change needed.

**Files:**
- Create: `lib/features/checkin/domain/check_in.dart`
- Create: `lib/features/checkin/domain/check_in_outcome.dart`
- Create: `lib/features/checkin/data/check_in_repository.dart`
- Create: `lib/features/checkin/data/drift_check_in_repository.dart`
- Test: `test/features/checkin/data/drift_check_in_repository_test.dart`

**Interfaces:**
- Consumes: `PresenceMode` (`lib/features/events/domain/presence_mode.dart`, jalon 2), `Ticket` (`lib/features/tickets/domain/ticket.dart`, jalon 4), `AppDatabase`/`CheckIns`/`CheckInEntity`/`CheckInsCompanion` (jalon 1 schema).
- Produces: `CheckIn` (`id`, `ticketId`, `eventId`, `scannedAt`). `CheckInOutcome` sealed type with `CheckInRecorded(CheckIn)` and `CheckInAlreadyRecorded(CheckIn existing)`. `CheckInRepository` (abstract) with `watchCheckInsForEvent(int)` and `recordCheckIn(Ticket, PresenceMode)`. `DriftCheckInRepository implements CheckInRepository`. Tasks 3 and 4 depend on these exact names and signatures.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/checkin/data/drift_check_in_repository_test.dart
import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/checkin/data/drift_check_in_repository.dart';
import 'package:dif_pass/features/checkin/domain/check_in_outcome.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftCheckInRepository repository;
  late int eventId;
  late int ticketId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftCheckInRepository(db);
    eventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: eventId, name: 'Jane Doe'),
        );
    ticketId = await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: eventId,
            readableId: '0001',
            randomPart: 'ABCD',
            qrPayload: 'EVT1-0001-ABCD',
          ),
        );
  });

  tearDown(() => db.close());

  Ticket ticket() => Ticket(
        id: ticketId,
        beneficiaryId: 1,
        eventId: eventId,
        readableId: '0001',
        randomPart: 'ABCD',
        qrPayload: 'EVT1-0001-ABCD',
        createdAt: DateTime(2026, 1, 1),
      );

  test('simple mode: first scan records a check-in', () async {
    final outcome = await repository.recordCheckIn(ticket(), PresenceMode.simple);

    expect(outcome, isA<CheckInRecorded>());
    final checkIns = await repository.watchCheckInsForEvent(eventId).first;
    expect(checkIns, hasLength(1));
    expect(checkIns.single.ticketId, ticketId);
  });

  test('simple mode: second scan of the same ticket is blocked', () async {
    final first = (await repository.recordCheckIn(ticket(), PresenceMode.simple))
        as CheckInRecorded;

    final second = await repository.recordCheckIn(ticket(), PresenceMode.simple);

    expect(second, isA<CheckInAlreadyRecorded>());
    expect(
      (second as CheckInAlreadyRecorded).existing.scannedAt,
      first.checkIn.scannedAt,
    );
    final checkIns = await repository.watchCheckInsForEvent(eventId).first;
    expect(checkIns, hasLength(1));
  });

  test('multiple mode: every scan records a new check-in', () async {
    final first = await repository.recordCheckIn(ticket(), PresenceMode.multiple);
    final second = await repository.recordCheckIn(ticket(), PresenceMode.multiple);

    expect(first, isA<CheckInRecorded>());
    expect(second, isA<CheckInRecorded>());
    final checkIns = await repository.watchCheckInsForEvent(eventId).first;
    expect(checkIns, hasLength(2));
  });

  test('watchCheckInsForEvent only returns check-ins for the given event', () async {
    final otherEventId = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT2',
            name: 'Other event',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );
    await repository.recordCheckIn(ticket(), PresenceMode.simple);

    final checkIns = await repository.watchCheckInsForEvent(otherEventId).first;
    expect(checkIns, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/checkin/data/drift_check_in_repository_test.dart
```

Expected: FAIL (none of the new files exist yet).

- [ ] **Step 3: Implement the domain types and the repository**

```dart
// lib/features/checkin/domain/check_in.dart
class CheckIn {
  const CheckIn({
    required this.id,
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
  });

  final int id;
  final int ticketId;
  final int eventId;
  final DateTime scannedAt;
}
```

```dart
// lib/features/checkin/domain/check_in_outcome.dart
import 'check_in.dart';

sealed class CheckInOutcome {
  const CheckInOutcome();
}

class CheckInRecorded extends CheckInOutcome {
  const CheckInRecorded(this.checkIn);

  final CheckIn checkIn;
}

class CheckInAlreadyRecorded extends CheckInOutcome {
  const CheckInAlreadyRecorded(this.existing);

  final CheckIn existing;
}
```

```dart
// lib/features/checkin/data/check_in_repository.dart
import '../../events/domain/presence_mode.dart';
import '../../tickets/domain/ticket.dart';
import '../domain/check_in.dart';
import '../domain/check_in_outcome.dart';

abstract class CheckInRepository {
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId);
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode);
}
```

```dart
// lib/features/checkin/data/drift_check_in_repository.dart
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../events/domain/presence_mode.dart';
import '../../tickets/domain/ticket.dart';
import '../domain/check_in.dart';
import '../domain/check_in_outcome.dart';
import 'check_in_repository.dart';

class DriftCheckInRepository implements CheckInRepository {
  DriftCheckInRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId) {
    final query = _db.select(_db.checkIns)
      ..where((tbl) => tbl.eventId.equals(eventId));
    return query.watch().map((rows) => rows.map(_toCheckIn).toList());
  }

  @override
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode) async {
    if (mode == PresenceMode.simple) {
      final existingRow = await (_db.select(_db.checkIns)
            ..where((tbl) => tbl.ticketId.equals(ticket.id))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.scannedAt)])
            ..limit(1))
          .getSingleOrNull();
      if (existingRow != null) {
        return CheckInAlreadyRecorded(_toCheckIn(existingRow));
      }
    }

    final row = await _db.into(_db.checkIns).insertReturning(
          CheckInsCompanion.insert(
            ticketId: ticket.id,
            eventId: ticket.eventId,
          ),
        );
    return CheckInRecorded(_toCheckIn(row));
  }

  CheckIn _toCheckIn(CheckInEntity row) {
    return CheckIn(
      id: row.id,
      ticketId: row.ticketId,
      eventId: row.eventId,
      scannedAt: row.scannedAt,
    );
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/checkin/data/drift_check_in_repository_test.dart
```

Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/checkin/domain lib/features/checkin/data test/features/checkin/data
git commit -m "Add CheckIn domain model and its Drift repository"
```

---

### Task 2: TicketRepository.findTicketForCheckIn

**Context:** Extends the jalon 4 `TicketRepository` with the lookup that resolves a scanned QR payload or a manually typed identifier to a `Ticket`, scoped to the event currently being controlled. This is the one method both the camera path and the manual-entry path call.

**Files:**
- Modify: `lib/features/tickets/data/ticket_repository.dart`
- Modify: `lib/features/tickets/data/drift_ticket_repository.dart`
- Modify: `test/features/tickets/fake_ticket_repository.dart`
- Test: `test/features/tickets/data/drift_ticket_repository_test.dart` (append to the existing file)

**Interfaces:**
- Produces: `TicketRepository.findTicketForCheckIn(int eventId, String rawInput) -> Future<Ticket?>`, implemented on both `DriftTicketRepository` and `FakeTicketRepository`. Task 4 depends on this.

- [ ] **Step 1: Write the failing test**

Append to the existing test file, inside `main()`, after the last test:

```dart
// test/features/tickets/data/drift_ticket_repository_test.dart (append inside main())
test('findTicketForCheckIn finds a ticket by its full QR payload', () async {
  await insertBeneficiary('Jane Doe');
  await repository.generateMissingTickets(eventId);
  final ticket = (await repository.watchTicketsForEvent(eventId).first).single;

  final found = await repository.findTicketForCheckIn(eventId, ticket.qrPayload);

  expect(found?.id, ticket.id);
});

test('findTicketForCheckIn finds a ticket by its readable id alone', () async {
  await insertBeneficiary('Jane Doe');
  await repository.generateMissingTickets(eventId);
  final ticket = (await repository.watchTicketsForEvent(eventId).first).single;

  final found = await repository.findTicketForCheckIn(eventId, ticket.readableId);

  expect(found?.id, ticket.id);
});

test('findTicketForCheckIn returns null for a ticket from another event', () async {
  await insertBeneficiary('Jane Doe');
  await repository.generateMissingTickets(eventId);
  final ticket = (await repository.watchTicketsForEvent(eventId).first).single;
  final otherEventId = await db.into(db.events).insert(
        EventsCompanion.insert(
          shortCode: 'EVT2',
          name: 'Other event',
          date: DateTime(2026, 12, 1),
          presenceMode: 'simple',
        ),
      );

  final found = await repository.findTicketForCheckIn(otherEventId, ticket.qrPayload);

  expect(found, isNull);
});

test('findTicketForCheckIn returns null for an unknown identifier', () async {
  final found = await repository.findTicketForCheckIn(eventId, 'nope');

  expect(found, isNull);
});
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/data/drift_ticket_repository_test.dart
```

Expected: FAIL (`findTicketForCheckIn` does not exist on `TicketRepository`).

- [ ] **Step 3: Add the method**

In `lib/features/tickets/data/ticket_repository.dart`, add to the abstract class body:

```dart
  Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput);
```

In `lib/features/tickets/data/drift_ticket_repository.dart`, add to the `DriftTicketRepository` class body:

```dart
  @override
  Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    final byPayload = await (_db.select(_db.tickets)
          ..where((tbl) =>
              tbl.eventId.equals(eventId) & tbl.qrPayload.equals(trimmed)))
        .getSingleOrNull();
    if (byPayload != null) return _toTicket(byPayload);

    final byReadableId = await (_db.select(_db.tickets)
          ..where((tbl) =>
              tbl.eventId.equals(eventId) &
              tbl.readableId.upper().equals(trimmed.toUpperCase())))
        .getSingleOrNull();
    return byReadableId == null ? null : _toTicket(byReadableId);
  }
```

In `test/features/tickets/fake_ticket_repository.dart`, add to the `FakeTicketRepository` class body (after `generateMissingTickets`, before the closing `}`):

```dart
  @override
  Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    for (final ticket in _tickets) {
      if (ticket.eventId == eventId && ticket.qrPayload == trimmed) {
        return ticket;
      }
    }
    for (final ticket in _tickets) {
      if (ticket.eventId == eventId &&
          ticket.readableId.toUpperCase() == trimmed.toUpperCase()) {
        return ticket;
      }
    }
    return null;
  }
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/data/drift_ticket_repository_test.dart
```

Expected: PASS (all tests in the file, including the 4 new ones).

- [ ] **Step 5: Run the full suite as a regression check**

```bash
fvm flutter test
```

Expected: all existing tests still pass (this confirms the new abstract method didn't break any other class implementing `TicketRepository`).

- [ ] **Step 6: Commit**

```bash
git add lib/features/tickets/data test/features/tickets/fake_ticket_repository.dart test/features/tickets/data/drift_ticket_repository_test.dart
git commit -m "Add TicketRepository.findTicketForCheckIn"
```

---

### Task 3: Riverpod providers and a shared test fake for check-ins

**Files:**
- Create: `lib/features/checkin/presentation/providers/check_in_providers.dart`
- Create: `test/features/checkin/fake_check_in_repository.dart`
- Test: `test/features/checkin/presentation/providers/check_in_providers_test.dart`

**Interfaces:**
- Consumes: `CheckInRepository`, `DriftCheckInRepository` (Task 1); `appDatabaseProvider` (jalon 1); `ticketsProvider` (jalon 4).
- Produces: `checkInRepositoryProvider` (`Provider<CheckInRepository>`), `checkInsProvider` (`StreamProvider.family<List<CheckIn>, int>`, keyed by eventId), `checkInCounterProvider` (`Provider.family<(int, int), int>`, keyed by eventId, returns `(checkedIn, total)`). `FakeCheckInRepository` (test-only) implements `CheckInRepository` in memory. Tasks 4, 7 depend on these.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/checkin/presentation/providers/check_in_providers_test.dart
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/presentation/providers/check_in_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tickets/fake_ticket_repository.dart';
import '../../fake_check_in_repository.dart';

void main() {
  test(
    'checkInCounterProvider counts distinct checked-in tickets against total tickets',
    () async {
      final fakeTickets = FakeTicketRepository(tickets: [
        Ticket(
          id: 1,
          beneficiaryId: 1,
          eventId: 42,
          readableId: '0001',
          randomPart: 'ABCD',
          qrPayload: 'EVT-0001-ABCD',
          createdAt: DateTime(2026, 1, 1),
        ),
        Ticket(
          id: 2,
          beneficiaryId: 2,
          eventId: 42,
          readableId: '0002',
          randomPart: 'EFGH',
          qrPayload: 'EVT-0002-EFGH',
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
      final fakeCheckIns = FakeCheckInRepository(checkIns: [
        CheckIn(id: 1, ticketId: 1, eventId: 42, scannedAt: DateTime(2026, 1, 1, 9)),
        CheckIn(id: 2, ticketId: 1, eventId: 42, scannedAt: DateTime(2026, 1, 1, 9, 5)),
      ]);
      final container = ProviderContainer(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(fakeTickets),
          checkInRepositoryProvider.overrideWithValue(fakeCheckIns),
        ],
      );
      addTearDown(container.dispose);

      await container.read(ticketsProvider(42).future);
      await container.read(checkInsProvider(42).future);

      final counter = container.read(checkInCounterProvider(42));
      expect(counter, (1, 2));
    },
  );
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/checkin/presentation/providers/check_in_providers_test.dart
```

Expected: FAIL (neither file exists).

- [ ] **Step 3: Implement the providers and the fake**

```dart
// lib/features/checkin/presentation/providers/check_in_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../../data/check_in_repository.dart';
import '../../data/drift_check_in_repository.dart';
import '../../domain/check_in.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCheckInRepository(db);
});

final checkInsProvider =
    StreamProvider.family<List<CheckIn>, int>((ref, eventId) {
  return ref.watch(checkInRepositoryProvider).watchCheckInsForEvent(eventId);
});

final checkInCounterProvider = Provider.family<(int, int), int>((ref, eventId) {
  final tickets = ref.watch(ticketsProvider(eventId)).valueOrNull ?? const [];
  final checkIns = ref.watch(checkInsProvider(eventId)).valueOrNull ?? const [];
  final distinctCheckedIn = checkIns.map((c) => c.ticketId).toSet().length;
  return (distinctCheckedIn, tickets.length);
});
```

```dart
// test/features/checkin/fake_check_in_repository.dart
import 'dart:async';

import 'package:dif_pass/features/checkin/data/check_in_repository.dart';
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/domain/check_in_outcome.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';

/// In-memory CheckInRepository for widget/provider tests. Not shipped in
/// the app, lives under test/ only.
class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository({List<CheckIn>? checkIns})
      : _checkIns = List.of(checkIns ?? const []);

  final List<CheckIn> _checkIns;
  final Map<int, StreamController<List<CheckIn>>> _controllers = {};
  int _nextId = 1000;

  List<CheckIn> get checkIns => List.unmodifiable(_checkIns);

  StreamController<List<CheckIn>> _controllerFor(int eventId) {
    return _controllers.putIfAbsent(
      eventId,
      () => StreamController<List<CheckIn>>.broadcast(),
    );
  }

  void _emit(int eventId) {
    final list = _checkIns.where((c) => c.eventId == eventId).toList();
    _controllerFor(eventId).add(list);
  }

  @override
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId) {
    Future.microtask(() => _emit(eventId));
    return _controllerFor(eventId).stream;
  }

  @override
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode) async {
    if (mode == PresenceMode.simple) {
      final existing = _checkIns.where((c) => c.ticketId == ticket.id).toList()
        ..sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
      if (existing.isNotEmpty) {
        return CheckInAlreadyRecorded(existing.first);
      }
    }
    final checkIn = CheckIn(
      id: _nextId++,
      ticketId: ticket.id,
      eventId: ticket.eventId,
      scannedAt: DateTime.now(),
    );
    _checkIns.add(checkIn);
    _emit(ticket.eventId);
    return CheckInRecorded(checkIn);
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/checkin/presentation/providers/check_in_providers_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/checkin/presentation/providers test/features/checkin/fake_check_in_repository.dart test/features/checkin/presentation/providers
git commit -m "Add check-in providers and a fake repository for tests"
```

---

### Task 4: CheckInFeedback and the check-in processing function

**Context:** This is the "isolated from the camera widget" logic the design doc calls for: given a raw scanned/typed string, resolve the ticket, record the check-in, and return a display-ready result. Both the camera detection callback and the manual-entry submit callback (Task 7) call this same function; this task's tests exercise it with zero widget dependency.

**Files:**
- Create: `lib/features/checkin/presentation/check_in_feedback.dart`
- Create: `lib/features/checkin/presentation/check_in_processor.dart`
- Test: `test/features/checkin/presentation/check_in_processor_test.dart`

**Interfaces:**
- Consumes: `TicketRepository.findTicketForCheckIn` (Task 2); `CheckInRepository.recordCheckIn` (Task 1); `BeneficiaryRepository.getBeneficiary` (jalon 3).
- Produces: `CheckInFeedback` sealed type (`CheckInFeedbackRecorded`, `CheckInFeedbackAlreadyRecorded`, `CheckInFeedbackNotFound`) and `processCheckIn({...}) -> Future<CheckInFeedback>`. Task 7 depends on both.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/checkin/presentation/check_in_processor_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/checkin/presentation/check_in_feedback.dart';
import 'package:dif_pass/features/checkin/presentation/check_in_processor.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../beneficiaries/fake_beneficiary_repository.dart';
import '../../tickets/fake_ticket_repository.dart';
import '../fake_check_in_repository.dart';

void main() {
  final ticket = Ticket(
    id: 1,
    beneficiaryId: 1,
    eventId: 42,
    readableId: '0001',
    randomPart: 'ABCD',
    qrPayload: 'EVT-0001-ABCD',
    createdAt: DateTime(2026, 1, 1),
  );
  final beneficiary = Beneficiary(
    id: 1,
    eventId: 42,
    name: 'Jane Doe',
    customFieldValues: const {},
    createdAt: DateTime(2026, 1, 1),
  );

  test('returns CheckInFeedbackNotFound when no ticket matches', () async {
    final feedback = await processCheckIn(
      ticketRepository: FakeTicketRepository(),
      checkInRepository: FakeCheckInRepository(),
      beneficiaryRepository: FakeBeneficiaryRepository(),
      eventId: 42,
      presenceMode: PresenceMode.simple,
      rawInput: 'nope',
    );

    expect(feedback, isA<CheckInFeedbackNotFound>());
  });

  test(
    'returns CheckInFeedbackRecorded with the beneficiary name on a fresh scan',
    () async {
      final feedback = await processCheckIn(
        ticketRepository: FakeTicketRepository(tickets: [ticket]),
        checkInRepository: FakeCheckInRepository(),
        beneficiaryRepository: FakeBeneficiaryRepository(beneficiaries: [beneficiary]),
        eventId: 42,
        presenceMode: PresenceMode.simple,
        rawInput: ticket.qrPayload,
      );

      expect(feedback, isA<CheckInFeedbackRecorded>());
      expect((feedback as CheckInFeedbackRecorded).beneficiaryName, 'Jane Doe');
    },
  );

  test(
    'returns CheckInFeedbackAlreadyRecorded with the first scan time in simple mode',
    () async {
      final fakeCheckIns = FakeCheckInRepository();
      final ticketRepo = FakeTicketRepository(tickets: [ticket]);
      final beneficiaryRepo =
          FakeBeneficiaryRepository(beneficiaries: [beneficiary]);
      await processCheckIn(
        ticketRepository: ticketRepo,
        checkInRepository: fakeCheckIns,
        beneficiaryRepository: beneficiaryRepo,
        eventId: 42,
        presenceMode: PresenceMode.simple,
        rawInput: ticket.qrPayload,
      );

      final feedback = await processCheckIn(
        ticketRepository: ticketRepo,
        checkInRepository: fakeCheckIns,
        beneficiaryRepository: beneficiaryRepo,
        eventId: 42,
        presenceMode: PresenceMode.simple,
        rawInput: ticket.readableId,
      );

      expect(feedback, isA<CheckInFeedbackAlreadyRecorded>());
      expect((feedback as CheckInFeedbackAlreadyRecorded).beneficiaryName, 'Jane Doe');
    },
  );

  test('multiple mode: repeated scans each return CheckInFeedbackRecorded', () async {
    final fakeCheckIns = FakeCheckInRepository();
    final ticketRepo = FakeTicketRepository(tickets: [ticket]);
    final beneficiaryRepo = FakeBeneficiaryRepository(beneficiaries: [beneficiary]);

    final first = await processCheckIn(
      ticketRepository: ticketRepo,
      checkInRepository: fakeCheckIns,
      beneficiaryRepository: beneficiaryRepo,
      eventId: 42,
      presenceMode: PresenceMode.multiple,
      rawInput: ticket.qrPayload,
    );
    final second = await processCheckIn(
      ticketRepository: ticketRepo,
      checkInRepository: fakeCheckIns,
      beneficiaryRepository: beneficiaryRepo,
      eventId: 42,
      presenceMode: PresenceMode.multiple,
      rawInput: ticket.qrPayload,
    );

    expect(first, isA<CheckInFeedbackRecorded>());
    expect(second, isA<CheckInFeedbackRecorded>());
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/checkin/presentation/check_in_processor_test.dart
```

Expected: FAIL (neither file exists).

- [ ] **Step 3: Implement the feedback type and the processor**

```dart
// lib/features/checkin/presentation/check_in_feedback.dart
sealed class CheckInFeedback {
  const CheckInFeedback();
}

class CheckInFeedbackRecorded extends CheckInFeedback {
  const CheckInFeedbackRecorded({required this.beneficiaryName});

  final String beneficiaryName;
}

class CheckInFeedbackAlreadyRecorded extends CheckInFeedback {
  const CheckInFeedbackAlreadyRecorded({
    required this.beneficiaryName,
    required this.scannedAt,
  });

  final String beneficiaryName;
  final DateTime scannedAt;
}

class CheckInFeedbackNotFound extends CheckInFeedback {
  const CheckInFeedbackNotFound();
}
```

```dart
// lib/features/checkin/presentation/check_in_processor.dart
import '../../beneficiaries/data/beneficiary_repository.dart';
import '../../events/domain/presence_mode.dart';
import '../../tickets/data/ticket_repository.dart';
import '../data/check_in_repository.dart';
import '../domain/check_in_outcome.dart';
import 'check_in_feedback.dart';

Future<CheckInFeedback> processCheckIn({
  required TicketRepository ticketRepository,
  required CheckInRepository checkInRepository,
  required BeneficiaryRepository beneficiaryRepository,
  required int eventId,
  required PresenceMode presenceMode,
  required String rawInput,
}) async {
  final ticket = await ticketRepository.findTicketForCheckIn(eventId, rawInput);
  if (ticket == null) {
    return const CheckInFeedbackNotFound();
  }

  final beneficiary =
      await beneficiaryRepository.getBeneficiary(ticket.beneficiaryId);
  final outcome = await checkInRepository.recordCheckIn(ticket, presenceMode);

  return switch (outcome) {
    CheckInRecorded() =>
      CheckInFeedbackRecorded(beneficiaryName: beneficiary.name),
    CheckInAlreadyRecorded(:final existing) => CheckInFeedbackAlreadyRecorded(
        beneficiaryName: beneficiary.name,
        scannedAt: existing.scannedAt,
      ),
  };
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/checkin/presentation/check_in_processor_test.dart
```

Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/checkin/presentation/check_in_feedback.dart lib/features/checkin/presentation/check_in_processor.dart test/features/checkin/presentation/check_in_processor_test.dart
git commit -m "Add CheckInFeedback and the check-in processing function"
```

---

### Task 5: Manual-entry field widget

**Files:**
- Create: `lib/features/checkin/presentation/widgets/check_in_manual_entry_field.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/checkin/presentation/widgets/check_in_manual_entry_field_test.dart`

**Interfaces:**
- Produces: `CheckInManualEntryField({required Future<void> Function(String rawInput) onSubmit, bool enabled = true})`. Task 7 composes this widget; it never constructs a camera, so it is fully testable.

- [ ] **Step 1: Add the ARB keys this widget needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "checkinManualEntryLabel": "Ticket ID",
  "checkinManualEntryAction": "Check in"
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "checkinManualEntryLabel": "Identifiant du ticket",
  "checkinManualEntryAction": "Enregistrer"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/checkin/presentation/widgets/check_in_manual_entry_field_test.dart
import 'package:dif_pass/features/checkin/presentation/widgets/check_in_manual_entry_field.dart';
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
    'submitting the field calls onSubmit with the trimmed text and clears it',
    (tester) async {
      String? submitted;
      await tester.pumpWidget(
        _wrap(
          CheckInManualEntryField(
            onSubmit: (value) async {
              submitted = value;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  0042  ');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(submitted, '0042');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('submitting an empty field does not call onSubmit', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _wrap(
        CheckInManualEntryField(
          onSubmit: (value) async {
            called = true;
          },
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(called, isFalse);
  });

  testWidgets('disabled field cannot be submitted', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _wrap(
        CheckInManualEntryField(
          enabled: false,
          onSubmit: (value) async {
            called = true;
          },
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(called, isFalse);
  });
}
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/checkin/presentation/widgets/check_in_manual_entry_field_test.dart
```

Expected: FAIL (`check_in_manual_entry_field.dart` does not exist).

- [ ] **Step 4: Implement the widget**

```dart
// lib/features/checkin/presentation/widgets/check_in_manual_entry_field.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class CheckInManualEntryField extends StatefulWidget {
  const CheckInManualEntryField({
    required this.onSubmit,
    this.enabled = true,
    super.key,
  });

  final Future<void> Function(String rawInput) onSubmit;
  final bool enabled;

  @override
  State<CheckInManualEntryField> createState() =>
      _CheckInManualEntryFieldState();
}

class _CheckInManualEntryFieldState extends State<CheckInManualEntryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.checkinManualEntryLabel),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.enabled ? _submit : null,
            child: Text(l10n.checkinManualEntryAction),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/checkin/presentation/widgets/check_in_manual_entry_field_test.dart
```

Expected: PASS (all 3 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/checkin/presentation/widgets test/features/checkin/presentation/widgets
git commit -m "Add the check-in manual entry field widget"
```

---

### Task 6: Check-in entry point on the events list

**Files:**
- Modify: `lib/features/events/presentation/widgets/event_card.dart`
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`

**Interfaces:**
- Produces: `EventCard` gains a new required `onCheckIn` (`VoidCallback`) parameter, a 4th trailing icon (between Tickets and Archive). `EventsListScreen` wires it to `/events/<id>/checkin`.

- [ ] **Step 1: Add the ARB key this change needs**

```json
// lib/l10n/app_en.arb (add this key, keep the existing ones)
{
  "eventsCheckInAction": "Check-in"
}
```

```json
// lib/l10n/app_fr.arb (add this key, keep the existing ones)
{
  "eventsCheckInAction": "Controle"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

Append to the existing test file, inside `main()`:

```dart
// test/features/events/presentation/screens/events_list_screen_test.dart (append inside main())
testWidgets('shows a check-in action for each event', (tester) async {
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

  expect(find.byTooltip('Check-in'), findsOneWidget);
});
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: FAIL (no widget with tooltip "Check-in" exists yet).

- [ ] **Step 4: Add the button**

In `lib/features/events/presentation/widgets/event_card.dart`, add `onCheckIn` to the constructor and fields:

```dart
  const EventCard({
    required this.event,
    required this.onTap,
    required this.onManageBeneficiaries,
    required this.onManageTickets,
    required this.onCheckIn,
    required this.onArchive,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onManageBeneficiaries;
  final VoidCallback onManageTickets;
  final VoidCallback onCheckIn;
  final VoidCallback onArchive;
```

Add a 4th `IconButton` to the trailing `Row`, between the tickets and archive buttons:

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
              icon: const Icon(Icons.qr_code_scanner_outlined),
              tooltip: l10n.eventsCheckInAction,
              onPressed: onCheckIn,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: l10n.eventsArchiveEventAction,
              onPressed: onArchive,
            ),
          ],
        ),
```

In `lib/features/events/presentation/screens/events_list_screen.dart`, add to the `EventCard(...)` construction, between `onManageTickets` and `onArchive`:

```dart
                onCheckIn: () => context.push('/events/${event.id}/checkin'),
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart
```

Expected: PASS (all tests in the file).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/events/presentation/widgets/event_card.dart lib/features/events/presentation/screens/events_list_screen.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Add a check-in entry point to the events list"
```

---

### Task 7: CheckInScanScreen

**Context:** Composes everything from Tasks 1-6 into the actual scan screen: camera preview, animated live counter, manual-entry toggle, and a colored feedback overlay after each scan/submission. Per the Global Constraints, this screen is **not** unit-tested (the camera cannot be safely constructed in `flutter test`); its own logic was already fully tested in Tasks 3 and 4 via `checkInCounterProvider` and `processCheckIn`.

**Files:**
- Create: `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`

**Interfaces:**
- Consumes: `eventProvider` (jalon 2); `beneficiaryRepositoryProvider` (jalon 3); `ticketRepositoryProvider` (jalon 4); `checkInRepositoryProvider`, `checkInCounterProvider` (Task 3); `processCheckIn`, `CheckInFeedback` (Task 4); `CheckInManualEntryField` (Task 5).
- Produces: `CheckInScanScreen({required int eventId})`, the widget Task 8 wires to route `/events/:id/checkin`.

- [ ] **Step 1: Add the ARB keys this screen needs**

```json
// lib/l10n/app_en.arb (add these keys, keep the existing ones)
{
  "checkinScreenTitle": "Check-in",
  "checkinManualEntryToggleAction": "Manual entry",
  "checkinBackToScanAction": "Back to scanning",
  "checkinCounterLabel": "{checkedIn}/{total} arrived",
  "@checkinCounterLabel": {
    "placeholders": {
      "checkedIn": {"type": "int"},
      "total": {"type": "int"}
    }
  },
  "checkinAlreadyRecordedMessage": "Already checked in at {time}",
  "@checkinAlreadyRecordedMessage": {
    "placeholders": {
      "time": {"type": "String"}
    }
  },
  "checkinNotFoundMessage": "Ticket not found",
  "checkinUnexpectedError": "Something went wrong recording the check-in."
}
```

```json
// lib/l10n/app_fr.arb (add these keys, keep the existing ones)
{
  "checkinScreenTitle": "Controle de presence",
  "checkinManualEntryToggleAction": "Saisie manuelle",
  "checkinBackToScanAction": "Revenir au scan",
  "checkinCounterLabel": "{checkedIn}/{total} arrives",
  "checkinAlreadyRecordedMessage": "Deja enregistre a {time}",
  "checkinNotFoundMessage": "Ticket introuvable",
  "checkinUnexpectedError": "Un probleme est survenu lors de l'enregistrement de la presence."
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Implement the screen**

```dart
// lib/features/checkin/presentation/screens/check_in_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../check_in_feedback.dart';
import '../check_in_processor.dart';
import '../providers/check_in_providers.dart';
import '../widgets/check_in_manual_entry_field.dart';

class CheckInScanScreen extends ConsumerStatefulWidget {
  const CheckInScanScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<CheckInScanScreen> createState() => _CheckInScanScreenState();
}

class _CheckInScanScreenState extends ConsumerState<CheckInScanScreen> {
  final _controller = MobileScannerController();
  bool _manualEntry = false;
  bool _busy = false;
  CheckInFeedback? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final rawValue =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (rawValue == null) return;
    await _process(rawValue);
  }

  Future<void> _process(String rawInput) async {
    setState(() => _busy = true);
    await _controller.stop();

    if (mounted) {
      try {
        final event = await ref.read(eventProvider(widget.eventId).future);
        final feedback = await processCheckIn(
          ticketRepository: ref.read(ticketRepositoryProvider),
          checkInRepository: ref.read(checkInRepositoryProvider),
          beneficiaryRepository: ref.read(beneficiaryRepositoryProvider),
          eventId: widget.eventId,
          presenceMode: event.presenceMode,
          rawInput: rawInput,
        );
        if (mounted) {
          setState(() => _feedback = feedback);
          if (feedback is CheckInFeedbackRecorded) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.heavyImpact();
          }
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.checkinUnexpectedError)),
          );
        }
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _feedback = null;
      _busy = false;
    });
    if (!_manualEntry) {
      await _controller.start();
    }
  }

  void _toggleManualEntry() {
    setState(() => _manualEntry = !_manualEntry);
    if (_manualEntry) {
      _controller.stop();
    } else {
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final (checkedIn, total) = ref.watch(checkInCounterProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.checkinScreenTitle),
              Text(event.name, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          loading: () => Text(l10n.checkinScreenTitle),
          error: (_, _) => Text(l10n.checkinScreenTitle),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _manualEntry ? Icons.qr_code_scanner : Icons.keyboard_outlined,
            ),
            tooltip: _manualEntry
                ? l10n.checkinBackToScanAction
                : l10n.checkinManualEntryToggleAction,
            onPressed: _busy ? null : _toggleManualEntry,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_manualEntry)
            MobileScanner(controller: _controller, onDetect: _onDetect)
          else
            Center(
              child: CheckInManualEntryField(
                enabled: !_busy,
                onSubmit: _process,
              ),
            ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.checkinCounterLabel(checkedIn, total),
                  key: ValueKey(checkedIn),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().scale(duration: 300.ms).fadeIn(duration: 300.ms),
              ),
            ),
          ),
          if (_feedback != null)
            _CheckInFeedbackOverlay(feedback: _feedback!, locale: locale),
        ],
      ),
    );
  }
}

class _CheckInFeedbackOverlay extends StatelessWidget {
  const _CheckInFeedbackOverlay({required this.feedback, required this.locale});

  final CheckInFeedback feedback;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSuccess = feedback is CheckInFeedbackRecorded;
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;

    String? name;
    String? message;
    switch (feedback) {
      case CheckInFeedbackRecorded(:final beneficiaryName):
        name = beneficiaryName;
      case CheckInFeedbackAlreadyRecorded(:final beneficiaryName, :final scannedAt):
        name = beneficiaryName;
        message = l10n.checkinAlreadyRecordedMessage(
          DateFormat.Hm(locale).format(scannedAt),
        );
      case CheckInFeedbackNotFound():
        message = l10n.checkinNotFoundMessage;
    }

    return Positioned.fill(
      child: ColoredBox(
        color: color.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              if (name != null)
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (message != null)
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run the full suite as a regression check**

```bash
fvm flutter test
```

Expected: all existing tests still pass. There is no new test in this task (see Global Constraints); this step only confirms the new screen file compiles cleanly and did not break anything it touches (ARB regeneration, imports).

- [ ] **Step 4: Run the analyzer**

```bash
fvm flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n lib/features/checkin/presentation/screens
git commit -m "Add the check-in scan screen"
```

---

### Task 8: Wire the check-in route, full milestone check

**Files:**
- Modify: `lib/core/router/app_router.dart`

**Interfaces:**
- Consumes: `CheckInScanScreen` (Task 7).
- Produces: `appRouter` gains 1 route. This is the last task of the milestone. Per the Global Constraints, no router test targets this route (mirrors the existing, untested `/events/:id/beneficiaries/import` route from jalon 3, which also leads to a screen wrapping a native integration).

- [ ] **Step 1: Wire the route**

```dart
// lib/core/router/app_router.dart
// Add this import alongside the existing feature imports:
import '../../features/checkin/presentation/screens/check_in_scan_screen.dart';
```

```dart
// lib/core/router/app_router.dart
// Add this route to the `routes:` list, alongside the existing routes:
    GoRoute(
      path: '/events/:id/checkin',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => CheckInScanScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
```

- [ ] **Step 2: Run the full suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer reports no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router
git commit -m "Wire the check-in route"
```

---

## Milestone acceptance

Jalon 6 (Controle de presence) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and from an event's Check-in screen, an organizer can scan a ticket's QR code (or type its identifier manually) and see the beneficiary's name confirmed (green), see a repeat scan blocked with the original scan time in simple mode (red) or recorded again with no blocking in multiple mode, see an unmatched identifier reported as not found (red), and see the live counter animate to reflect distinct tickets checked in against the event's total ticket count.
