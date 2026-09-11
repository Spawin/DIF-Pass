# Generic (Nameless) Ticket Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an organiser add a batch of tickets to an event without naming each recipient - for general-admission events controlled purely by presenting a ticket.

**Architecture:** No schema change. A generic ticket is a normal `Beneficiary` row auto-named `Ticket <readableId>` plus its normal `Ticket` row, created together in one transaction. Every existing code path (check-in, presence counting, export, the beneficiaries list) keeps working unmodified because, to them, this is just another beneficiary.

**Tech Stack:** Flutter/Dart, Drift, Riverpod, existing ARB/`AppLocalizations` i18n.

**Spec:** [docs/superpowers/specs/2026-09-11-generic-tickets-design.md](../specs/2026-09-11-generic-tickets-design.md)

## Global Constraints

- All Flutter/Dart tooling runs through FVM: `fvm flutter ...`, `fvm dart ...`.
- No schema/migration change. No change to check-in, presence counting, CSV import/export, or the ticket card/template.
- The count entered in the dialog must be validated as an integer between 1 and 500 inclusive; reject anything else with a visible message, never submit.
- The generic-beneficiary name convention is a fixed string, not localized: `'Ticket ${readableId}'` (matching `Events.shortCode`'s fixed `'EVT' + id` prefix elsewhere in this app).
- French ARB copy has no accents. Every ARB key with a placeholder needs an `@key` metadata block.
- Commit messages: no `Co-Authored-By: Claude` trailer, no "Generated with Claude" line, no em dashes anywhere.
- All existing tests must still pass at the end of every task.

---

### Task 1: `generateGenericTickets` on the ticket repository

**Files:**
- Modify: `lib/features/tickets/data/ticket_repository.dart`
- Modify: `lib/features/tickets/data/drift_ticket_repository.dart`
- Modify: `test/features/tickets/fake_ticket_repository.dart`
- Test: `test/features/tickets/data/drift_ticket_repository_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks (this is the data-layer task).
- Produces: `TicketRepository.generateGenericTickets(int eventId, int count) -> Future<int>` (returns `count` on success), implemented by `DriftTicketRepository` and by `FakeTicketRepository` (the fake takes a new optional constructor parameter `Future<int> Function(int eventId, String name)? createBeneficiary` - Task 2's screen test wires this directly to `FakeBeneficiaryRepository.createBeneficiary`, which already has exactly this shape: `Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary)`, called as `(eventId, name) => fakeBeneficiaries.createBeneficiary(eventId, NewBeneficiary(name: name, customFieldValues: const {}))`).

- [ ] **Step 1: Write the failing repository tests**

Read `test/features/tickets/data/drift_ticket_repository_test.dart` in full first (it already has a `setUp`/`insertBeneficiary` helper and an in-memory `AppDatabase`). Add these tests:

```dart
  test('generateGenericTickets creates the requested number of beneficiary+ticket pairs', () async {
    final created = await repository.generateGenericTickets(eventId, 3);

    expect(created, 3);
    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets, hasLength(3));
    expect(
      tickets.map((t) => t.readableId).toSet(),
      {'0001', '0002', '0003'},
    );

    final beneficiaryRows = await db.select(db.beneficiaries).get();
    expect(beneficiaryRows, hasLength(3));
    final namesByReadableId = {
      for (final t in tickets)
        t.readableId: beneficiaryRows.firstWhere((b) => b.id == t.beneficiaryId).name,
    };
    expect(namesByReadableId, {
      '0001': 'Ticket 0001',
      '0002': 'Ticket 0002',
      '0003': 'Ticket 0003',
    });
  });

  test('generateGenericTickets continues the sequence after existing tickets', () async {
    final beneficiaryId = await insertBeneficiary('Jane Doe');
    await repository.generateMissingTickets(eventId);
    // Confirm the named beneficiary got 0001 before adding generic ones.
    final firstBatch = await repository.watchTicketsForEvent(eventId).first;
    expect(firstBatch.single.beneficiaryId, beneficiaryId);
    expect(firstBatch.single.readableId, '0001');

    final created = await repository.generateGenericTickets(eventId, 2);

    expect(created, 2);
    final allTickets = await repository.watchTicketsForEvent(eventId).first;
    expect(allTickets, hasLength(3));
    expect(
      allTickets.map((t) => t.readableId).toSet(),
      {'0001', '0002', '0003'},
    );
  });

  test('each generic ticket has a well-formed QR payload', () async {
    await repository.generateGenericTickets(eventId, 1);

    final ticket = (await repository.watchTicketsForEvent(eventId).first).single;
    expect(ticket.qrPayload, 'EVT1-${ticket.readableId}-${ticket.randomPart}');
  });

  test('calling generateGenericTickets twice never reuses a readableId', () async {
    await repository.generateGenericTickets(eventId, 2);
    await repository.generateGenericTickets(eventId, 2);

    final tickets = await repository.watchTicketsForEvent(eventId).first;
    expect(tickets.map((t) => t.readableId).toSet(), hasLength(4));
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm flutter test test/features/tickets/data/drift_ticket_repository_test.dart`
Expected: FAIL to compile - `generateGenericTickets` does not exist on `DriftTicketRepository` yet.

- [ ] **Step 3: Add the method to the interface**

Edit `lib/features/tickets/data/ticket_repository.dart`:

```dart
import '../domain/ticket.dart';

abstract class TicketRepository {
  Stream<List<Ticket>> watchTicketsForEvent(int eventId);
  Future<Ticket> getTicket(int id);
  Future<int> generateMissingTickets(int eventId);
  Future<int> generateGenericTickets(int eventId, int count);
  Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput);
}
```

- [ ] **Step 4: Extract the shared sequence-numbering helper and implement `generateGenericTickets`**

Edit `lib/features/tickets/data/drift_ticket_repository.dart`. First, extract the sequence-scanning block that `generateMissingTickets` already has (the `var nextSequence = 1; for (final ticket in existingTickets) { ... }` loop) into a private helper, and use it from both methods - this avoids the two methods drifting out of sync on how a `readableId` becomes "the next one":

```dart
  Future<int> _nextSequence(int eventId) async {
    final existingTickets = await (_db.select(_db.tickets)
          ..where((tbl) => tbl.eventId.equals(eventId)))
        .get();
    var nextSequence = 1;
    for (final ticket in existingTickets) {
      final parsed = int.tryParse(ticket.readableId);
      if (parsed != null && parsed >= nextSequence) {
        nextSequence = parsed + 1;
      }
    }
    return nextSequence;
  }
```

In `generateMissingTickets`, replace its existing inline `existingTickets`/`nextSequence` computation:

```dart
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

      var nextSequence = await _nextSequence(eventId);

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
```

(This keeps `beneficiariesWithTickets`'s own `existingTickets` query as-is - it is still needed for the "who already has a ticket" check, `_nextSequence` runs its own separate query. Do not try to merge the two queries; keep this diff minimal.)

Add the new method right after it:

```dart
  @override
  Future<int> generateGenericTickets(int eventId, int count) {
    return _db.transaction(() async {
      final event = await (_db.select(_db.events)
            ..where((tbl) => tbl.id.equals(eventId)))
          .getSingle();

      var nextSequence = await _nextSequence(eventId);

      for (var i = 0; i < count; i++) {
        final generated = generateTicketId(sequence: nextSequence);
        final beneficiaryId = await _db.into(_db.beneficiaries).insert(
              BeneficiariesCompanion.insert(
                eventId: eventId,
                name: 'Ticket ${generated.readableId}',
              ),
            );
        await _db.into(_db.tickets).insert(
              TicketsCompanion.insert(
                beneficiaryId: beneficiaryId,
                eventId: eventId,
                readableId: generated.readableId,
                randomPart: generated.randomPart,
                qrPayload: generated.payloadFor(event.shortCode),
              ),
            );
        nextSequence++;
      }

      return count;
    });
  }
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `fvm flutter test test/features/tickets/data/drift_ticket_repository_test.dart`
Expected: PASS (all cases, including the pre-existing `generateMissingTickets` tests - the extraction must not change their behavior).

- [ ] **Step 6: Update `FakeTicketRepository`**

Read `test/features/tickets/fake_ticket_repository.dart` in full first. Add a new optional constructor parameter and field:

```dart
class FakeTicketRepository implements TicketRepository {
  FakeTicketRepository({
    List<Ticket>? tickets,
    List<int> Function(int eventId)? beneficiaryIdsForEvent,
    Future<int> Function(int eventId, String name)? createBeneficiary,
  })  : _tickets = List.of(tickets ?? const []),
        _beneficiaryIdsForEvent = beneficiaryIdsForEvent ?? ((_) => const []),
        _createBeneficiary = createBeneficiary;

  final List<Ticket> _tickets;
  final List<int> Function(int eventId) _beneficiaryIdsForEvent;
  final Future<int> Function(int eventId, String name)? _createBeneficiary;
  final Map<int, StreamController<List<Ticket>>> _controllers = {};
  int _nextId = 1000;
```

Add the doc comment above the class mentioning the new parameter, following the existing doc comment's style for `beneficiaryIdsForEvent`:

```dart
/// [createBeneficiary], if given, is called once per generic ticket with the
/// name this fake assigns it (`'Ticket <readableId>'`) and must return the
/// new beneficiary's id - wire it directly to a
/// `FakeBeneficiaryRepository`'s own `createBeneficiary`, e.g.
/// `(eventId, name) => fakeBeneficiaries.createBeneficiary(eventId, NewBeneficiary(name: name, customFieldValues: const {}))`.
/// If omitted, generic tickets get a synthetic beneficiary id with no
/// corresponding beneficiary row - fine for tests that only care about the
/// ticket side.
```

Add the method implementation (place it right after `generateMissingTickets`):

```dart
  @override
  Future<int> generateGenericTickets(int eventId, int count) async {
    var sequence = _tickets
            .where((t) => t.eventId == eventId)
            .map((t) => int.tryParse(t.readableId) ?? 0)
            .fold<int>(0, (highest, value) => value > highest ? value : highest) +
        1;

    for (var i = 0; i < count; i++) {
      final readableId = sequence.toString().padLeft(4, '0');
      final beneficiaryId = _createBeneficiary != null
          ? await _createBeneficiary(eventId, 'Ticket $readableId')
          : _nextId;
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
    }
    _emit(eventId);
    return count;
  }
```

- [ ] **Step 7: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass (the fake change is additive - every existing test constructing `FakeTicketRepository` without the new parameter keeps compiling), no new analyzer output.

- [ ] **Step 8: Commit**

```bash
git add lib/features/tickets/data test/features/tickets/data/drift_ticket_repository_test.dart test/features/tickets/fake_ticket_repository.dart
git commit -m "Add generateGenericTickets to create tickets without a named beneficiary"
```

---

### Task 2: "Add generic tickets" dialog and button on the tickets screen

**Files:**
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/tickets/presentation/screens/tickets_screen_test.dart`

**Interfaces:**
- Consumes from Task 1: `TicketRepository.generateGenericTickets(int eventId, int count)`, `FakeTicketRepository`'s new `createBeneficiary` constructor parameter.
- Produces: nothing - this is the last task.

- [ ] **Step 1: Add the ARB keys**

Add to `lib/l10n/app_fr.arb` (no accents), near `ticketsGenerateAction`:

```json
  "ticketsGenerateGenericAction": "Ajouter des tickets generiques",
  "ticketsGenerateGenericDialogTitle": "Combien de tickets ?",
  "ticketsGenerateGenericCountLabel": "Nombre de tickets",
  "ticketsGenerateGenericCountInvalid": "Entrez un nombre entre 1 et 500",
  "ticketsGenerateGenericSuccess": "{count} tickets generiques ajoutes",
  "@ticketsGenerateGenericSuccess": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "ticketsGenerateGenericError": "Echec de l'ajout des tickets generiques",
```

Add the matching English keys to `lib/l10n/app_en.arb` at the same relative position:

```json
  "ticketsGenerateGenericAction": "Add generic tickets",
  "ticketsGenerateGenericDialogTitle": "How many tickets?",
  "ticketsGenerateGenericCountLabel": "Number of tickets",
  "ticketsGenerateGenericCountInvalid": "Enter a number between 1 and 500",
  "ticketsGenerateGenericSuccess": "{count} generic tickets added",
  "@ticketsGenerateGenericSuccess": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "ticketsGenerateGenericError": "Failed to add generic tickets",
```

- [ ] **Step 2: Regenerate localizations**

Run: `fvm flutter gen-l10n`
Expected: no errors, `AppLocalizations` gains the five new getters (`ticketsGenerateGenericSuccess` takes an `int count` parameter).

- [ ] **Step 3: Write the failing widget tests**

Read `test/features/tickets/presentation/screens/tickets_screen_test.dart` in full first, in particular its `_wrap` helper signature and imports (you will need to add an import for `NewBeneficiary` alongside the existing `Beneficiary` import, from `package:dif_pass/features/beneficiaries/domain/new_beneficiary.dart`).

Add these tests (adjust the `_wrap(...)` call's argument shape to match exactly what the existing tests in this file already use):

```dart
  testWidgets('adding generic tickets creates the requested count', (tester) async {
    final fakeBeneficiaries = FakeBeneficiaryRepository();
    final fakeTickets = FakeTicketRepository(
      createBeneficiary: (eventId, name) => fakeBeneficiaries.createBeneficiary(
        eventId,
        NewBeneficiary(name: name, customFieldValues: const {}),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add generic tickets'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '3');
    await tester.tap(find.widgetWithText(TextButton, 'Add generic tickets'));
    await tester.pumpAndSettle();

    expect(fakeTickets.tickets, hasLength(3));
    expect(find.text('3 generic tickets added'), findsOneWidget);
  });

  testWidgets('cancelling the generic tickets dialog creates nothing', (tester) async {
    final fakeTickets = FakeTicketRepository();

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        FakeBeneficiaryRepository(),
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add generic tickets'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeTickets.tickets, isEmpty);
  });

  testWidgets('an invalid count is rejected without submitting', (tester) async {
    final fakeTickets = FakeTicketRepository();

    await tester.pumpWidget(
      _wrap(
        const TicketsScreen(eventId: 1),
        _fakeEventsWithOneEvent(),
        FakeBeneficiaryRepository(),
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add generic tickets'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.widgetWithText(TextButton, 'Add generic tickets'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a number between 1 and 500'), findsOneWidget);
    expect(fakeTickets.tickets, isEmpty);
  });
```

Note: `find.text('Add generic tickets')` matches both the screen's trigger button and the dialog's confirm button - the trigger tap happens first (before the dialog exists, so only one match), and after the dialog opens the confirm tap uses `find.widgetWithText(TextButton, ...)` to target the dialog's `TextButton` specifically rather than the screen's `OutlinedButton` behind it. If this ambiguity causes a real failure once the dialog is open (both buttons visible at once and both matching by type+text), disambiguate with `find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(TextButton, 'Add generic tickets'))` instead, following the pattern already used in `settings_screen_test.dart`'s delete-confirmation test.

- [ ] **Step 4: Run the tests to verify they fail**

Run: `fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart`
Expected: FAIL - the button/dialog do not exist yet.

- [ ] **Step 5: Add the dialog widget and wire the button**

Edit `lib/features/tickets/presentation/screens/tickets_screen.dart`.

Add the button right after the existing disabled-hint block (after the `if (!canGenerate) [...]` block, before the `SizedBox(height: 16)` that precedes the ticket list `Expanded`):

```dart
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addGenericTickets(context, ref),
                    icon: const Icon(Icons.playlist_add),
                    label: Text(l10n.ticketsGenerateGenericAction),
                  ),
                  const SizedBox(height: 16),
```

Add the new method to the `TicketsScreen` class, right after `_confirmGenerate`:

```dart
  Future<void> _addGenericTickets(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final auditLogger = ref.read(auditLoggerProvider);
    final count = await showDialog<int>(
      context: context,
      builder: (_) => const _GenericTicketCountDialog(),
    );
    if (count == null) return;
    try {
      final stopwatch = Stopwatch()..start();
      final created = await ref
          .read(ticketRepositoryProvider)
          .generateGenericTickets(eventId, count);
      stopwatch.stop();
      auditLogger.logTicketsGenerated(
        count: created,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsGenerateGenericSuccess(created))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsGenerateGenericError)),
      );
    }
  }
```

Add the private dialog widget at the bottom of the file, after the closing brace of the `TicketsScreen` class:

```dart
class _GenericTicketCountDialog extends StatefulWidget {
  const _GenericTicketCountDialog();

  @override
  State<_GenericTicketCountDialog> createState() =>
      _GenericTicketCountDialogState();
}

class _GenericTicketCountDialogState extends State<_GenericTicketCountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.ticketsGenerateGenericDialogTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.ticketsGenerateGenericCountLabel),
          validator: (value) {
            final count = int.tryParse(value?.trim() ?? '');
            if (count == null || count <= 0 || count > 500) {
              return l10n.ticketsGenerateGenericCountInvalid;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(int.parse(_controller.text.trim()));
            }
          },
          child: Text(l10n.ticketsGenerateGenericAction),
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart`
Expected: PASS. Fix any finder ambiguity per the note in Step 3.

- [ ] **Step 7: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 8: Commit**

```bash
git add lib/features/tickets/presentation/screens/tickets_screen.dart lib/l10n test/features/tickets/presentation/screens/tickets_screen_test.dart
git commit -m "Add a button and dialog to generate generic tickets without a name"
```
