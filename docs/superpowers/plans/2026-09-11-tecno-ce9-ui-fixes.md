# Tecno CE9 UI Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six confirmed UI defects from a real-device test on a Tecno CE9: event-card text wrapping, a duplicated empty-state call-to-action overlapping the system nav bar, a cut-off form save button, a wrapping language label, low-contrast disabled buttons, and an unexplained disabled generate-tickets button.

**Architecture:** Five independent, narrowly-scoped fixes across existing screens/widgets. No new files, no schema/provider changes, no new dependencies.

**Tech Stack:** Flutter/Dart, existing ARB/`AppLocalizations` i18n, existing `AppColors` theme tokens.

**Spec:** [docs/superpowers/specs/2026-09-11-tecno-ce9-ui-fixes-design.md](../specs/2026-09-11-tecno-ce9-ui-fixes-design.md)

## Global Constraints

- All Flutter/Dart tooling runs through FVM: `fvm flutter ...`, `fvm dart ...`.
- French ARB copy has no accents. Every ARB key with placeholders needs an `@key` metadata block (none of this plan's new keys take placeholders).
- Do not touch anything about the ticket-template feature (Compact/Standard/Elegant) or the ticket card's vertical centering - out of scope this round.
- Do not touch the audit-export icon in Settings - already correct in the current code.
- Commit messages: no `Co-Authored-By: Claude` trailer, no "Generated with Claude" line, no em dashes anywhere.
- All existing tests must still pass at the end of every task.

---

### Task 1: Fix event card text wrapping by restructuring its trailing actions

**Files:**
- Modify: `lib/features/events/presentation/widgets/event_card.dart`
- Modify: `test/features/events/presentation/screens/events_list_screen_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `EventCard`'s public constructor is unchanged (same 6 callbacks); only its internal `trailing` layout changes. No other file references `EventCard`'s internals.

- [ ] **Step 1: Update the two now-failing tests first (TDD: adjust to the target shape, watch them fail)**

Read `test/features/events/presentation/screens/events_list_screen_test.dart` in full first. Replace the test `'shows a beneficiaries action for each event'` with one that opens the "more actions" menu and finds a "Beneficiaries" menu item instead of a tooltip'd icon button:

```dart
  testWidgets('offers a beneficiaries action in the more-actions menu', (
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

    expect(find.text('Beneficiaries'), findsOneWidget);
  });
```

Update the existing `'the more-actions menu offers history alongside archive'` test to also assert Beneficiaries is present (rename it too, since it now offers three items):

```dart
  testWidgets('the more-actions menu offers beneficiaries, archive, and history', (
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

    expect(find.text('Beneficiaries'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
```

Leave the existing `'shows a tickets action for each event'` and `'shows a check-in action for each event'` tests unchanged - Tickets and Check-in stay as direct `IconButton`s with tooltips.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart`
Expected: FAIL - `find.text('Beneficiaries')` finds nothing yet (it's still a tooltip'd icon, not menu text); the old `find.byTooltip('Beneficiaries')`-based test no longer exists so its removal itself isn't a failure, but the two new/renamed tests should fail against the current `EventCard`.

- [ ] **Step 3: Restructure `EventCard`'s trailing actions**

Edit `lib/features/events/presentation/widgets/event_card.dart`. Change `_EventCardMenuAction` to add a `beneficiaries` case, remove the Beneficiaries `IconButton` from `trailing`, and add a menu item for it:

```dart
enum _EventCardMenuAction { beneficiaries, archive, history }
```

Replace the `trailing: Row(...)` block:

```dart
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  case _EventCardMenuAction.beneficiaries:
                    onManageBeneficiaries();
                  case _EventCardMenuAction.archive:
                    onArchive();
                  case _EventCardMenuAction.history:
                    onViewHistory();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _EventCardMenuAction.beneficiaries,
                  child: Text(l10n.eventsBeneficiariesAction),
                ),
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
```

The constructor, its 6 required callbacks, and everything else in the file (imports, `leading`, `title`, `subtitle`) stay exactly as they are - only `trailing`'s children and the enum change.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart`
Expected: PASS (all cases, including the two updated ones and the still-passing Tickets/Check-in tooltip tests).

- [ ] **Step 5: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 6: Commit**

```bash
git add lib/features/events/presentation/widgets/event_card.dart test/features/events/presentation/screens/events_list_screen_test.dart
git commit -m "Move the beneficiaries action into the event card's menu to fix text wrapping"
```

---

### Task 2: Remove the duplicated empty-state action and keep the FAB clear of the system nav bar

**Files:**
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing consumed by later tasks. `EmptyState`'s own widget and test are untouched - it still supports an optional action for callers that want one, these two callers just stop passing one.

- [ ] **Step 1: `events_list_screen.dart` - drop the empty-state action, pad the FAB**

Read the full file first (already read during design). Change the `EmptyState` call (currently around line 38-43):

```dart
            return EmptyState(
              icon: Icons.event_outlined,
              message: l10n.eventsEmptyState,
            );
```

(Remove the `actionLabel:`/`onAction:` lines - everything else about this `EmptyState` call stays.)

Change the `floatingActionButton:` (currently around line 93-97):

```dart
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/events/new'),
          icon: const Icon(Icons.add),
          label: Text(l10n.eventsNewAction),
        ),
      ),
```

- [ ] **Step 2: `beneficiaries_list_screen.dart` - same two changes**

Read the full file first. Remove `actionLabel:`/`onAction:` from its `EmptyState` call (currently around line 54-58), and wrap its `floatingActionButton:` (currently around line 88-92) the same way:

```dart
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/events/$eventId/beneficiaries/new'),
          icon: const Icon(Icons.person_add_outlined),
          label: Text(l10n.beneficiariesNewAction),
        ),
      ),
```

- [ ] **Step 3: Run the affected tests**

Run: `fvm flutter test test/features/events/presentation/screens/events_list_screen_test.dart test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`
Expected: PASS unchanged - neither file's existing empty-state test asserts on the action button, only on the message text, so removing the action does not break them. If either file DOES have an assertion on the removed button (re-check after Step 1/2 - read-first, don't assume), update that assertion to confirm the button is now absent (`findsNothing`) instead of deleting the check outright.

- [ ] **Step 4: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 5: Commit**

```bash
git add lib/features/events/presentation/screens/events_list_screen.dart lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart
git commit -m "Remove the duplicated empty-state CTA and keep the FAB clear of the system nav bar"
```

---

### Task 3: Fix the cut-off form save button and the wrapping language label

**Files:**
- Modify: `lib/features/events/presentation/screens/event_form_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: `event_form_screen.dart` - bottom padding accounts for the system nav bar**

Read the full `build()` method first (already read during design - the `ListView`'s `padding` is currently `const EdgeInsets.all(16)`, around line 222). Change it to:

```dart
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.paddingOf(context).bottom + 24,
          ),
```

- [ ] **Step 2: Shorten the "Auto" language label**

Edit `lib/l10n/app_fr.arb`, change `"settingsLanguageAuto": "Automatique"` to `"settingsLanguageAuto": "Auto"`.

Edit `lib/l10n/app_en.arb`, change `"settingsLanguageAuto": "Automatic"` to `"settingsLanguageAuto": "Auto"`.

- [ ] **Step 3: Regenerate localizations**

Run: `fvm flutter gen-l10n`
Expected: no errors, `settingsLanguageAuto` now resolves to "Auto" in both locales.

- [ ] **Step 4: Run the affected tests**

Run: `fvm flutter test test/features/events/presentation/screens/event_form_screen_test.dart test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: PASS - no test hardcodes "Automatique"/"Automatic" (confirmed absent from the test suite during design), and the padding change has no test-visible effect.

- [ ] **Step 5: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 6: Commit**

```bash
git add lib/features/events/presentation/screens/event_form_screen.dart lib/l10n
git commit -m "Fix the cut-off event form save button and the wrapping Auto language label"
```

---

### Task 4: Fix disabled-button contrast on the audit export/delete buttons

**Files:**
- Modify: `lib/features/backup/presentation/screens/settings_screen.dart`
- Modify: `test/features/backup/presentation/screens/settings_screen_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing test first**

Read `test/features/backup/presentation/screens/settings_screen_test.dart` in full around the existing `'export and delete buttons are disabled when no audit file exists'` test (around line 269). Add two assertions to it, right after the existing two `expect(...).onPressed, isNull)` checks:

```dart
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Exporter les donnees d\'audit'),
            )
            .style
            ?.foregroundColor
            ?.resolve({WidgetState.disabled}),
        AppColors.ink.withValues(alpha: 0.6),
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Supprimer les donnees d\'audit'),
            )
            .style
            ?.foregroundColor
            ?.resolve({WidgetState.disabled}),
        AppColors.ink.withValues(alpha: 0.6),
      );
```

Add the import `import 'package:dif_pass/core/theme/app_colors.dart';` at the top of the test file if not already present.

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: FAIL - the two new assertions find `null` (no explicit style set yet) instead of the expected color.

- [ ] **Step 3: Add the explicit disabled style to both buttons**

Read the current `OutlinedButton.icon`/`TextButton.icon` block in `lib/features/backup/presentation/screens/settings_screen.dart` (inside the `FutureBuilder<File?>` builder, around line 278-289 pre-Task-1/2/3 renumbering - locate by the `settingsAuditExportAction`/`settingsAuditDeleteAction` labels). Add a `style:` to each:

```dart
                    OutlinedButton.icon(
                      onPressed: hasFile ? _exportAudit : null,
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(l10n.settingsAuditExportAction),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: AppColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: hasFile ? _deleteAudit : null,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.settingsAuditDeleteAction),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        disabledForegroundColor: AppColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
```

(The delete button already sets an active-state `foregroundColor` for its error styling - keep that line, only add `disabledForegroundColor` alongside it. The export button gets a `style:` for the first time.)

Add the import `import '../../../../core/theme/app_colors.dart';` to `settings_screen.dart` if not already present (it is not - `AppColors` isn't currently imported there).

- [ ] **Step 4: Run the test to verify it passes**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 6: Commit**

```bash
git add lib/features/backup/presentation/screens/settings_screen.dart test/features/backup/presentation/screens/settings_screen_test.dart
git commit -m "Fix contrast on the disabled audit export/delete buttons"
```

---

### Task 5: Explain why "Generer les tickets" is disabled

**Files:**
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/tickets/presentation/screens/tickets_screen_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the two ARB keys**

Add to `lib/l10n/app_fr.arb` (no accents), near `ticketsGenerateAction`:

```json
  "ticketsGenerateNoBeneficiariesHint": "Ajoutez des beneficiaires avant de generer les tickets.",
  "ticketsGenerateAllDoneHint": "Tous les tickets ont deja ete generes.",
```

Add the matching English keys to `lib/l10n/app_en.arb`:

```json
  "ticketsGenerateNoBeneficiariesHint": "Add beneficiaries before generating tickets.",
  "ticketsGenerateAllDoneHint": "All tickets have already been generated.",
```

Neither key takes placeholders, so no `@key` metadata blocks are needed.

- [ ] **Step 2: Regenerate localizations**

Run: `fvm flutter gen-l10n`

- [ ] **Step 3: Write the failing tests**

Read `test/features/tickets/presentation/screens/tickets_screen_test.dart` in full around the two existing generate-button tests (`'shows the empty state and an enabled generate button when a beneficiary has no ticket yet'` and `'generate button is disabled once every beneficiary has a ticket'`, both already read during design). Add to the FIRST of those two (the enabled case) a check that no hint is shown:

```dart
      expect(find.text('Add beneficiaries before generating tickets.'), findsNothing);
      expect(find.text('All tickets have already been generated.'), findsNothing);
```

(This file's `_wrap` helper sets no `locale:`, so the app renders in English by default here, same as `events_list_screen_test.dart` - use the English ARB strings above, not French.)

Add to the SECOND existing test (the "every beneficiary has a ticket" disabled case) a check that the correct hint appears:

```dart
      expect(find.text('All tickets have already been generated.'), findsOneWidget);
```

Add a NEW third test for the other disabled reason (zero beneficiaries at all):

```dart
  testWidgets(
    'generate button is disabled with a hint when there are no beneficiaries yet',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TicketsScreen(eventId: 1),
          _fakeEventsWithOneEvent(),
          FakeBeneficiaryRepository(),
          FakeTicketRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('Add beneficiaries before generating tickets.'), findsOneWidget);
    },
  );
```

Match the exact constructor call shape (`_wrap(...)` argument order/names) to what the existing two tests already use - read them first, this is illustrative.

- [ ] **Step 4: Run the tests to verify they fail**

Run: `fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart`
Expected: FAIL - no hint text exists yet.

- [ ] **Step 5: Add the hint text to the screen**

Read the full `build()` method around the `FilledButton.icon` for generate (already read during design, around line 134-140). Add a hint `Text` right after it, before the next `SizedBox`:

```dart
                  FilledButton.icon(
                    onPressed: canGenerate
                        ? () => _confirmGenerate(context, ref)
                        : null,
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: Text(l10n.ticketsGenerateAction),
                  ),
                  if (!canGenerate) ...[
                    const SizedBox(height: 4),
                    Text(
                      beneficiaries.isEmpty
                          ? l10n.ticketsGenerateNoBeneficiariesHint
                          : l10n.ticketsGenerateAllDoneHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
```

(`beneficiaries` and `canGenerate` are both already in scope in `build()` - no new variables needed.)

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyze**

Run: `fvm flutter test && fvm flutter analyze`
Expected: all tests pass, no new analyzer output.

- [ ] **Step 8: Commit**

```bash
git add lib/features/tickets/presentation/screens/tickets_screen.dart lib/l10n test/features/tickets/presentation/screens/tickets_screen_test.dart
git commit -m "Explain why the generate-tickets button is disabled"
```
