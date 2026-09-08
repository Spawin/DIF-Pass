# Lots B and C (Finitions 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A consultable attendance history screen reachable from two places,
a presence indicator on the tickets list, and a confirmation guard before
modifying or deleting a beneficiary who already has a generated ticket.

**Architecture:** No new repository. `CheckInRepository.watchCheckInsForEvent`
(`checkInsProvider`) and `TicketRepository.watchTicketsForEvent`
(`ticketsProvider`) already exist and already carry everything both lots
need; every task here is a presentation-layer composition of data already
flowing through the app.

**Tech Stack:** Riverpod (`ref.watch`/`ref.invalidate`, same patterns
already used throughout this codebase), `go_router`, no new dependencies.

**Spec:** [docs/superpowers/specs/2026-09-08-lots-b-c-finitions-3-design.md](../specs/2026-09-08-lots-b-c-finitions-3-design.md)

## Global Constraints

- All commands prefixed `fvm flutter ...` / `fvm dart ...`.
- No em dashes in code, comments, or commits.
- No "Generated with Claude" / "Co-Authored-By: Claude" trailer in any
  commit — this project's own explicit rule, overrides any generic
  session-level attribution instruction.
- Never hand-edit generated files (`*.g.dart`, `lib/l10n/app_localizations*.dart`).
  After editing `lib/l10n/app_fr.arb` / `app_en.arb`, run
  `fvm flutter gen-l10n` before running tests.
- Every ARB key is added to BOTH `lib/l10n/app_fr.arb` and
  `lib/l10n/app_en.arb`, French text without accents (matches every
  existing key), natural English text. Every key carrying an ICU
  placeholder or plural form gets an `@key` metadata block declaring each
  placeholder's type, exactly like the project's existing
  `checkinCounterLabel`/`ticketsGeneratedCount`/`csvImportFieldsHint`
  entries (verified in `lib/l10n/app_en.arb` while writing this plan;
  every placeholder-carrying key in this file already has one, this is
  not optional decoration).
- `fvm flutter test` and `fvm flutter analyze` must be clean at the end of
  every task.
- Whenever a task adds a new `ref.watch(...)` to a screen, every existing
  test file for that screen needs its `_wrap` helper (and the
  `ProviderScope.overrides` it builds) extended with a fake for that new
  provider, even in tests where the new data doesn't matter to the
  assertion being made — otherwise the widget tries to build the real
  provider chain (reaching a real database) and the test fails or hangs.
  Give the new `_wrap` parameter a default fake instance so existing call
  sites do not need to change syntax.

---

### Task 1: `CheckInHistoryScreen` and its two access points

**Files:**
- Create: `lib/features/checkin/presentation/screens/check_in_history_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/checkin/presentation/screens/check_in_history_screen_test.dart` (new file)

**Interfaces:**
- Consumes: `checkInsProvider(eventId)`, `ticketsProvider(eventId)`,
  `beneficiariesProvider(eventId)` (all pre-existing).
- Produces: `CheckInHistoryScreen({required int eventId})`, route
  `/events/:id/checkin/history`, consumed by Task 2 (the `EventCard` menu
  entry navigates to this same route).

- [ ] **Step 1: Add new ARB keys**

```json
  "checkinHistoryAction": "Historique",
  "checkinHistoryTitle": "Historique des passages",
  "checkinHistoryEmptyState": "Aucun passage enregistre.",
  "checkinHistoryLoadError": "Impossible de charger l'historique."
```
```json
  "checkinHistoryAction": "History",
  "checkinHistoryTitle": "Attendance history",
  "checkinHistoryEmptyState": "No check-ins recorded yet.",
  "checkinHistoryLoadError": "Could not load the history."
```

Place all four right after `checkinSkipAction`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Write the failing test**

Create `test/features/checkin/presentation/screens/check_in_history_screen_test.dart`:

```dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/checkin/domain/check_in.dart';
import 'package:dif_pass/features/checkin/presentation/providers/check_in_providers.dart';
import 'package:dif_pass/features/checkin/presentation/screens/check_in_history_screen.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../../tickets/fake_ticket_repository.dart';
import '../../fake_check_in_repository.dart';

Widget _wrap(
  Widget child, {
  FakeEventRepository? fakeEvents,
  FakeBeneficiaryRepository? fakeBeneficiaries,
  FakeTicketRepository? fakeTickets,
  FakeCheckInRepository? fakeCheckIns,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents ?? FakeEventRepository()),
      beneficiaryRepositoryProvider
          .overrideWithValue(fakeBeneficiaries ?? FakeBeneficiaryRepository()),
      ticketRepositoryProvider.overrideWithValue(fakeTickets ?? FakeTicketRepository()),
      checkInRepositoryProvider.overrideWithValue(fakeCheckIns ?? FakeCheckInRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no check-ins', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CheckInHistoryScreen(eventId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('No check-ins recorded yet.'), findsOneWidget);
  });

  testWidgets(
    'shows the beneficiary name for each check-in, most recent first',
    (tester) async {
      final fakeBeneficiaries = FakeBeneficiaryRepository(
        beneficiaries: [
          Beneficiary(
            id: 1,
            eventId: 1,
            name: 'Jane Doe',
            customFieldValues: const {},
            createdAt: DateTime(2026, 1, 1),
          ),
          Beneficiary(
            id: 2,
            eventId: 1,
            name: 'John Smith',
            customFieldValues: const {},
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
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
          Ticket(
            id: 2,
            beneficiaryId: 2,
            eventId: 1,
            readableId: '0002',
            randomPart: 'EFGH',
            qrPayload: 'EVT1-0002-EFGH',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final fakeCheckIns = FakeCheckInRepository(
        checkIns: [
          CheckIn(
            id: 1,
            ticketId: 1,
            eventId: 1,
            scannedAt: DateTime(2026, 12, 1, 9, 0),
          ),
          CheckIn(
            id: 2,
            ticketId: 2,
            eventId: 1,
            scannedAt: DateTime(2026, 12, 1, 10, 30),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const CheckInHistoryScreen(eventId: 1),
          fakeBeneficiaries: fakeBeneficiaries,
          fakeTickets: fakeTickets,
          fakeCheckIns: fakeCheckIns,
        ),
      );
      await tester.pumpAndSettle();

      final janeFinder = find.text('Jane Doe');
      final johnFinder = find.text('John Smith');
      expect(janeFinder, findsOneWidget);
      expect(johnFinder, findsOneWidget);

      // Most recent (John, 10:30) must render above the earlier one (Jane, 9:00).
      final janeOffset = tester.getTopLeft(janeFinder);
      final johnOffset = tester.getTopLeft(johnFinder);
      expect(johnOffset.dy, lessThan(janeOffset.dy));
    },
  );
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `fvm flutter test test/features/checkin/presentation/screens/check_in_history_screen_test.dart`
Expected: FAIL (`check_in_history_screen.dart` does not exist).

- [ ] **Step 4: Implement `CheckInHistoryScreen`**

Create `lib/features/checkin/presentation/screens/check_in_history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../providers/check_in_providers.dart';

class CheckInHistoryScreen extends ConsumerWidget {
  const CheckInHistoryScreen({required this.eventId, super.key});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final checkInsAsync = ref.watch(checkInsProvider(eventId));
    final ticketsAsync = ref.watch(ticketsProvider(eventId));
    final beneficiariesAsync = ref.watch(beneficiariesProvider(eventId));

    Widget body;
    if (checkInsAsync.hasError || ticketsAsync.hasError || beneficiariesAsync.hasError) {
      body = ErrorState(
        message: l10n.checkinHistoryLoadError,
        onRetry: () {
          ref.invalidate(checkInsProvider(eventId));
          ref.invalidate(ticketsProvider(eventId));
          ref.invalidate(beneficiariesProvider(eventId));
        },
      );
    } else if (!checkInsAsync.hasValue ||
        !ticketsAsync.hasValue ||
        !beneficiariesAsync.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final checkIns = List.of(checkInsAsync.value!)
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      if (checkIns.isEmpty) {
        body = EmptyState(
          icon: Icons.history,
          message: l10n.checkinHistoryEmptyState,
        );
      } else {
        final beneficiaryNames = {
          for (final beneficiary in beneficiariesAsync.value!)
            beneficiary.id: beneficiary.name,
        };
        final ticketById = {
          for (final ticket in ticketsAsync.value!) ticket.id: ticket,
        };
        body = ListView.builder(
          itemCount: checkIns.length,
          itemBuilder: (context, index) {
            final checkIn = checkIns[index];
            final ticket = ticketById[checkIn.ticketId];
            final name =
                ticket != null ? (beneficiaryNames[ticket.beneficiaryId] ?? '') : '';
            return ListTile(
              title: Text(name),
              subtitle: Text(DateFormat.Hm(locale).format(checkIn.scannedAt)),
            );
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkinHistoryTitle)),
      body: body,
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/features/checkin/presentation/screens/check_in_history_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Wire the route**

In `lib/core/router/app_router.dart`, add the import:

```dart
import '../../features/checkin/presentation/screens/check_in_history_screen.dart';
```

(alphabetically placed among the other `features/...` imports). Add the
route right after the existing `/events/:id/checkin` route:

```dart
    GoRoute(
      path: '/events/:id/checkin/history',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => CheckInHistoryScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
```

- [ ] **Step 7: Add the AppBar icon on the scan screen**

In `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`,
add the import `import 'package:go_router/go_router.dart';`. In `build`'s
`AppBar.actions` list, add a second `IconButton` after the existing manual
entry toggle:

```dart
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
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.checkinHistoryAction,
            onPressed: () => context.push('/events/${widget.eventId}/checkin/history'),
          ),
        ],
```

This screen has no widget test (native camera dependency, established
convention in this project) so this addition is not covered by a new test
here; the route itself is exercised by Task 1's screen test and by
`app_router_test.dart` if a routing test is added there (optional, not
required by this task).

- [ ] **Step 8: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 9: Commit**

```bash
git add lib/features/checkin/presentation/screens/check_in_history_screen.dart lib/core/router/app_router.dart lib/features/checkin/presentation/screens/check_in_scan_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/checkin/presentation/screens/check_in_history_screen_test.dart
git commit -m "Add a consultable check-in history screen"
```

---

### Task 2: `EventCard`'s archive icon becomes a menu with Archive and History

**Files:**
- Modify: `lib/features/events/presentation/widgets/event_card.dart`
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`
  (existing file, two of its existing tests need updating, not just extending)

**Interfaces:**
- Consumes: Task 1's `/events/:id/checkin/history` route.
- Produces: `EventCard` gains a new required `onViewHistory` callback
  alongside the existing `onArchive`.

**Important: this task changes how two EXISTING tests must interact with
the UI.** `events_list_screen_test.dart` currently has two tests that do
`await tester.tap(find.byTooltip('Archive'));` to archive directly. Once
the bare Archive icon becomes a `PopupMenuButton`, that tooltip no longer
exists on anything tappable in one step: the button's own tooltip becomes
`l10n.eventsMoreActions` ("More actions"), and "Archive" becomes a menu
item's text, reached by opening the menu first. Both tests must change
their interaction sequence accordingly (see Step 4).

- [ ] **Step 1: Add new ARB keys**

```json
  "eventsMoreActions": "Plus d'actions"
```
```json
  "eventsMoreActions": "More actions"
```

Place it right after `eventsArchiveEventAction`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: `event_card.dart` — replace the Archive icon with a menu**

This is the current full content of
`lib/features/events/presentation/widgets/event_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';

class EventCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      ),
    );
  }
}
```

Replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/event.dart';

enum _EventCardMenuAction { archive, history }

class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    required this.onManageBeneficiaries,
    required this.onManageTickets,
    required this.onCheckIn,
    required this.onArchive,
    required this.onViewHistory,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onManageBeneficiaries;
  final VoidCallback onManageTickets;
  final VoidCallback onCheckIn;
  final VoidCallback onArchive;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            PopupMenuButton<_EventCardMenuAction>(
              tooltip: l10n.eventsMoreActions,
              onSelected: (action) {
                switch (action) {
                  case _EventCardMenuAction.archive:
                    onArchive();
                  case _EventCardMenuAction.history:
                    onViewHistory();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _EventCardMenuAction.archive,
                  child: Text(l10n.eventsArchiveEventAction),
                ),
                PopupMenuItem(
                  value: _EventCardMenuAction.history,
                  child: Text(l10n.checkinHistoryAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: `events_list_screen.dart` — wire `onViewHistory`**

In `EventsListScreen`, add the import
`import 'package:go_router/go_router.dart';` (already present, no change
needed there). Add `onViewHistory` to the `EventCard(...)` construction,
right after `onCheckIn`:

```dart
                onCheckIn: () => context.push('/events/${event.id}/checkin'),
                onViewHistory: () =>
                    context.push('/events/${event.id}/checkin/history'),
                onArchive: () async {
```

(keep `onArchive`'s existing body exactly as-is, this task does not touch
its logic, only adds a sibling callback).

- [ ] **Step 4: Update the two existing tests that tap "Archive" directly**

Read `test/features/events/presentation/screens/events_list_screen_test.dart`
in full. Two tests currently do:

```dart
    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();
```

Both must become a two-step interaction: open the menu, then tap the
"Archive" item:

```dart
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
```

Apply this change to both `'tapping the archive action archives the
event'` and `'archiving shows an undo snackbar that restores the event'`.
Every other assertion in those two tests (checking `isArchived`, the
undo snackbar text, tapping "Undo") stays exactly as it is; only the
tap-to-trigger-archive sequence changes.

- [ ] **Step 5: Add a test for the History menu entry**

In the same file, add:

```dart
testWidgets('the more-actions menu offers history alongside archive', (
  tester,
) async {
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

  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();

  expect(find.text('Archive'), findsOneWidget);
  expect(find.text('History'), findsOneWidget);
});
```

- [ ] **Step 6: Run tests**

Run: `fvm flutter test test/features/events/`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/events/presentation/widgets/event_card.dart lib/features/events/presentation/screens/events_list_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Reach check-in history from the events list, grouped with archive"
```

---

### Task 3: Presence indicator on the tickets list

**Files:**
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/tickets/presentation/screens/tickets_screen_test.dart`
  (existing file, its `_wrap` helper needs a new parameter, every existing
  call site needs one extra fake, see Global Constraints)

**Interfaces:**
- Consumes: `checkInsProvider(eventId)` (pre-existing), added to this
  screen's watches for the first time.

- [ ] **Step 1: Add new ARB keys**

```json
  "ticketsCheckedInBadge": "Present",
  "ticketsCheckInCount": "{count, plural, =1{1 passage} other{{count} passages}}",
  "@ticketsCheckInCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
```
```json
  "ticketsCheckedInBadge": "Checked in",
  "ticketsCheckInCount": "{count, plural, =1{1 check-in} other{{count} check-ins}}",
  "@ticketsCheckInCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
```

Place both right after `ticketsEmptyState`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: `tickets_screen.dart` — add the watch and the badge**

Read the current file in full (it has not changed in shape since the last
time this plan describes it below, but confirm before editing). Add the
import:

```dart
import '../../../checkin/presentation/providers/check_in_providers.dart';
```

In `build`, add a new watch right after the existing
`final customFieldsAsync = ref.watch(customFieldsProvider(eventId));`:

```dart
    final checkInsAsync = ref.watch(checkInsProvider(eventId));
```

Inside the `ticketsAsync.when(data: (tickets) { ... })` closure, right
after the existing `final beneficiaryNames = { ... };` line, add:

```dart
                        final passageCountByTicketId = <int, int>{};
                        for (final checkIn in checkInsAsync.valueOrNull ?? const []) {
                          passageCountByTicketId[checkIn.ticketId] =
                              (passageCountByTicketId[checkIn.ticketId] ?? 0) + 1;
                        }
```

Then extend the `ListTile` for each ticket to show the badge. Replace:

```dart
                              child: ListTile(
                                title: Text(
                                  beneficiaryNames[ticket.beneficiaryId] ?? '',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  ticket.readableId,
                                  style: ticketMonoStyle(
                                    Theme.of(context).colorScheme,
                                  ).copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                onTap: () => context.push(
                                  '/events/$eventId/tickets/${ticket.id}',
                                ),
                              ),
```

with:

```dart
                              child: ListTile(
                                title: Text(
                                  beneficiaryNames[ticket.beneficiaryId] ?? '',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  ticket.readableId,
                                  style: ticketMonoStyle(
                                    Theme.of(context).colorScheme,
                                  ).copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                trailing: () {
                                  final count = passageCountByTicketId[ticket.id] ?? 0;
                                  if (count == 0) return null;
                                  final label = event?.presenceMode == PresenceMode.multiple
                                      ? l10n.ticketsCheckInCount(count)
                                      : l10n.ticketsCheckedInBadge;
                                  return Chip(label: Text(label));
                                }(),
                                onTap: () => context.push(
                                  '/events/$eventId/tickets/${ticket.id}',
                                ),
                              ),
```

Add the import `import '../../../events/domain/presence_mode.dart';` for
`PresenceMode`.

- [ ] **Step 3: Extend `_wrap` and every existing call site in the test file**

Read `test/features/tickets/presentation/screens/tickets_screen_test.dart`
in full. Add the import
`import '../../../checkin/fake_check_in_repository.dart';` and
`import 'package:dif_pass/features/checkin/presentation/providers/check_in_providers.dart';`.
Change the `_wrap` signature from:

```dart
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
```

to:

```dart
Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeTicketRepository fakeTickets, {
  FakeCheckInRepository? fakeCheckIns,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets),
      checkInRepositoryProvider.overrideWithValue(fakeCheckIns ?? FakeCheckInRepository()),
    ],
```

This keeps every existing positional call site (`_wrap(screen, fakeEvents,
fakeBeneficiaries, fakeTickets)`) compiling unchanged, since the new
parameter is named and optional with an internal default.

- [ ] **Step 4: Add tests for the badge**

In the same file, add two tests:

```dart
testWidgets('shows a Checked in badge for a ticket with a check-in in simple mode', (
  tester,
) async {
  final fakeBeneficiaries = FakeBeneficiaryRepository(
    beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  );
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
  final fakeCheckIns = FakeCheckInRepository(
    checkIns: [
      CheckIn(id: 1, ticketId: 1, eventId: 1, scannedAt: DateTime(2026, 12, 1, 9, 0)),
    ],
  );

  await tester.pumpWidget(
    _wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
      fakeCheckIns: fakeCheckIns,
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Checked in'), findsOneWidget);
});

testWidgets('shows a passage count for a ticket with multiple check-ins in multiple mode', (
  tester,
) async {
  final fakeEvents = FakeEventRepository(
    events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.multiple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  );
  final fakeBeneficiaries = FakeBeneficiaryRepository(
    beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  );
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
  final fakeCheckIns = FakeCheckInRepository(
    checkIns: [
      CheckIn(id: 1, ticketId: 1, eventId: 1, scannedAt: DateTime(2026, 12, 1, 9, 0)),
      CheckIn(id: 2, ticketId: 1, eventId: 1, scannedAt: DateTime(2026, 12, 1, 14, 0)),
    ],
  );

  await tester.pumpWidget(
    _wrap(
      const TicketsScreen(eventId: 1),
      fakeEvents,
      fakeBeneficiaries,
      fakeTickets,
      fakeCheckIns: fakeCheckIns,
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('2 check-ins'), findsOneWidget);
});
```

Add the imports `import 'package:dif_pass/features/checkin/domain/check_in.dart';`
and `import '../../../checkin/fake_check_in_repository.dart';` at the top
of the file if not already present from Step 3.

- [ ] **Step 5: Run tests**

Run: `fvm flutter test test/features/tickets/`
Expected: PASS.

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tickets/presentation/screens/tickets_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/tickets/presentation/screens/tickets_screen_test.dart
git commit -m "Show a presence badge on the tickets list"
```

---

### Task 4: Beneficiary deletion warns when a ticket already exists

**Files:**
- Modify: `lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`
  (existing file, `_wrap` needs a new parameter, same reasoning as Task 3)

**Interfaces:**
- Consumes: `ticketsProvider(eventId)` (pre-existing), added to this
  screen's watches for the first time.

- [ ] **Step 1: Add new ARB key**

```json
  "beneficiariesDeleteConfirmBodyWithTicket": "Ce beneficiaire a deja un ticket genere. Le supprimer supprimera aussi ce ticket ; toute copie deja imprimee ou partagee deviendra invalide."
```
```json
  "beneficiariesDeleteConfirmBodyWithTicket": "This beneficiary already has a generated ticket. Deleting them will also delete that ticket; any printed or shared copy will become invalid."
```

Place it right after `beneficiariesDeleteConfirmTitle`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Read the current file**

Read `lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`
in full before editing (it has not changed since jalon 8; this task only
touches `build`'s watches and `_confirmDelete`'s dialog body).

- [ ] **Step 3: Add the ticket watch and conditional dialog body**

Add the import `import '../../../tickets/presentation/providers/ticket_providers.dart';`.
In `build`, add a new watch right after
`final customFieldsAsync = ref.watch(customFieldsProvider(eventId));`:

```dart
    final ticketsAsync = ref.watch(ticketsProvider(eventId));
```

`_confirmDelete` currently takes `(BuildContext context, WidgetRef ref,
Beneficiary beneficiary)` and hardcodes `content: Text(l10n.eventsDeleteConfirmBody)`.
Add a fourth parameter carrying whether this beneficiary already has a
ticket, computed once at the call site in `itemBuilder` (where `tickets`
is already in scope via the watch above):

```dart
                onDelete: () => _confirmDelete(
                  context,
                  ref,
                  beneficiary,
                  (ticketsAsync.valueOrNull ?? const [])
                      .any((t) => t.beneficiaryId == beneficiary.id),
                ),
```

Update `_confirmDelete`'s signature and dialog body:

```dart
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Beneficiary beneficiary,
    bool hasTicket,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.beneficiariesDeleteConfirmTitle),
        content: Text(
          hasTicket
              ? l10n.beneficiariesDeleteConfirmBodyWithTicket
              : l10n.eventsDeleteConfirmBody,
        ),
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
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.beneficiariesDeleteError)),
        );
      }
    }
  }
```

(everything else in this method is unchanged, only the `content:` line
and the new parameter).

- [ ] **Step 4: Extend `_wrap` and existing tests**

Read `test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`
in full. Add the imports
`import 'package:dif_pass/features/tickets/domain/ticket.dart';`,
`import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';`,
and `import '../../../tickets/fake_ticket_repository.dart';`. Change
`_wrap`'s signature from:

```dart
Widget _wrap(
  Widget child,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeEventRepository fakeEvents,
) {
  return ProviderScope(
    overrides: [
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      eventRepositoryProvider.overrideWithValue(fakeEvents),
    ],
```

to:

```dart
Widget _wrap(
  Widget child,
  FakeBeneficiaryRepository fakeBeneficiaries,
  FakeEventRepository fakeEvents, {
  FakeTicketRepository? fakeTickets,
}) {
  return ProviderScope(
    overrides: [
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      ticketRepositoryProvider.overrideWithValue(fakeTickets ?? FakeTicketRepository()),
    ],
```

Every existing positional call site keeps compiling unchanged.

- [ ] **Step 5: Add a test for the extended dialog body**

In the same file, add:

```dart
testWidgets(
  'delete confirmation warns about the existing ticket when one exists',
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
    );

    await tester.pumpWidget(
      _wrap(
        const BeneficiariesListScreen(eventId: 1),
        fakeBeneficiaries,
        _fakeEventsWithOneEvent(),
        fakeTickets: fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This beneficiary already has a generated ticket. Deleting them will also delete that ticket; any printed or shared copy will become invalid.',
      ),
      findsOneWidget,
    );
  },
);
```

Confirm the existing `'delete asks for confirmation before removing a
beneficiary'` test still passes unmodified: that beneficiary has no
ticket (its `_wrap` call passes no `fakeTickets`, defaulting to an empty
`FakeTicketRepository()`), so it still sees the original
`l10n.eventsDeleteConfirmBody` text ("This action cannot be undone.").

- [ ] **Step 6: Run tests**

Run: `fvm flutter test test/features/beneficiaries/`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart
git commit -m "Warn before deleting a beneficiary that already has a ticket"
```

---

### Task 5: Confirmation before editing a beneficiary that already has a ticket

**Files:**
- Modify: `lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart`
  (existing file, `_wrap` needs a new parameter, same reasoning as Tasks 3-4)

**Interfaces:**
- Consumes: `ticketsProvider(widget.eventId)` (pre-existing), added to
  this screen's watches for the first time.

- [ ] **Step 1: Add new ARB keys**

```json
  "beneficiaryFormEditConfirmTitle": "Modifier ce beneficiaire ?",
  "beneficiaryFormEditConfirmBody": "Ce beneficiaire a deja un ticket genere. Le modifier peut rendre les informations du ticket incoherentes avec les donnees reelles."
```
```json
  "beneficiaryFormEditConfirmTitle": "Edit this beneficiary?",
  "beneficiaryFormEditConfirmBody": "This beneficiary already has a generated ticket. Editing them may make that ticket's information inconsistent with their real details."
```

Place both right after `beneficiaryFormSaveError`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Read the current file**

Read `lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart`
in full before editing (it has not changed since jalon 8; this task only
touches `build`'s watches and `_save`).

- [ ] **Step 3: Add the ticket watch and the blocking confirmation**

Add the import `import '../../../tickets/presentation/providers/ticket_providers.dart';`.
In `build`, add a new watch right after
`final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));`:

```dart
    final ticketsAsync = ref.watch(ticketsProvider(widget.eventId));
```

This watch's value needs to reach `_save`, which is a separate method
(not a closure inside `build`) — pass it as a parameter alongside the
existing `customFields` parameter. Change the `FilledButton`'s
`onPressed`:

```dart
              FilledButton(
                onPressed: _loading ? null : () => _save(customFields),
                child: Text(l10n.eventFormSaveAction),
              ),
```

to:

```dart
              FilledButton(
                onPressed: _loading
                    ? null
                    : () => _save(
                          customFields,
                          hasTicket: (ticketsAsync.valueOrNull ?? const [])
                              .any((t) => t.beneficiaryId == widget.beneficiaryId),
                        ),
                child: Text(l10n.eventFormSaveAction),
              ),
```

Update `_save`'s signature and add the confirmation at its top, only when
editing an existing beneficiary that already has a ticket:

```dart
  Future<void> _save(List<CustomField> customFields, {required bool hasTicket}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_isEditing && hasTicket) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.beneficiaryFormEditConfirmTitle),
          content: Text(l10n.beneficiaryFormEditConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.eventFormSaveAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
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
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.beneficiaryFormSaveError)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
```

(the body from `setState(() => _loading = true);` onward is unchanged
from the current file, only the new confirmation block above it and the
signature are new).

- [ ] **Step 4: Extend `_wrap` and existing tests**

Read `test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart`
in full. Add the imports
`import 'package:dif_pass/features/tickets/domain/ticket.dart';`,
`import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';`,
and `import '../../../tickets/fake_ticket_repository.dart';`. Change
`_wrap`'s signature from:

```dart
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
```

to:

```dart
Widget _wrap(
  Widget child,
  FakeEventRepository fakeEvents,
  FakeBeneficiaryRepository fakeBeneficiaries, {
  FakeTicketRepository? fakeTickets,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(fakeBeneficiaries),
      ticketRepositoryProvider.overrideWithValue(fakeTickets ?? FakeTicketRepository()),
    ],
```

Every existing positional call site keeps compiling unchanged. Confirm
the three existing tests still pass: none of them edit a beneficiary that
has a ticket (`fakeTickets` defaults to empty in all three), so none of
them should ever see the new confirmation dialog.

- [ ] **Step 5: Add tests for the new confirmation**

```dart
testWidgets('saving a beneficiary without a ticket does not show a confirmation', (
  tester,
) async {
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

  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsNothing);
});

testWidgets(
  'editing a beneficiary with a ticket asks for confirmation, cancelling keeps the old data',
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
    final fakeTickets = FakeTicketRepository(tickets: [
      Ticket(
        id: 1,
        beneficiaryId: 7,
        eventId: eventId,
        readableId: '0001',
        randomPart: 'ABCD',
        qrPayload: 'EVT1-0001-ABCD',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(
      BeneficiaryFormScreen(eventId: eventId, beneficiaryId: 7),
      fakeEvents,
      fakeBeneficiaries,
      fakeTickets: fakeTickets,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Jane Updated');
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit this beneficiary?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeBeneficiaries.beneficiaries.single.name, 'Jane Doe');
  },
);
```

- [ ] **Step 6: Run tests**

Run: `fvm flutter test test/features/beneficiaries/`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/beneficiaries/presentation/screens/beneficiary_form_screen_test.dart
git commit -m "Confirm before saving changes to a beneficiary that already has a ticket"
```

---

### Task 6: Full lot verification

**Files:** None (verification only).

- [ ] **Step 1: Run the full test suite**

Run: `fvm flutter test`
Expected: all tests pass, including every new test added in Tasks 1-5.

- [ ] **Step 2: Run the analyzer**

Run: `fvm flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 3: Confirm every ARB key added in this plan exists in both locales**

Run `fvm flutter gen-l10n` once more and confirm it exits 0 with no
missing-translation warnings for any new key.

- [ ] **Step 4: Confirm no leftover raw tooltip references**

Run: `grep -rn "find.byTooltip('Archive')" test/`
Expected: no matches (Task 2 replaced every such reference with the
two-step "More actions" then "Archive" interaction).

- [ ] **Step 5: Report readiness**

Report the final test count and confirm the analyzer is clean.
