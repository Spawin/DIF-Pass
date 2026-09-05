# Lot A (Finitions 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** First persisted settings (check-in confirmation delay, forced
language), a differentiated check-in confirmation (auto-dismiss on success,
tap-to-dismiss on exceptions), reliable export/share confirmations, an
undo snackbar for archive/restore, a field hint on the CSV import screen,
and documentation of a known font-coverage limitation.

**Architecture:** No new subsystem beyond one small settings layer
(`lib/core/settings/`), built once and reused for both the check-in delay
and the language override. Every other change is a targeted edit to an
existing screen.

**Tech Stack:** `shared_preferences` (already a dependency, currently
unused anywhere in the app), Riverpod `Notifier`/`NotifierProvider`
(already the pattern used throughout this codebase), `flutter/services.dart`
`HapticFeedback` (already used throughout), no new dependencies.

**Spec:** [docs/superpowers/specs/2026-09-05-lot-a-finitions-2-design.md](../specs/2026-09-05-lot-a-finitions-2-design.md)

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
  existing key), natural English text.
- `fvm flutter test` and `fvm flutter analyze` must be clean at the end of
  every task.
- A screen that has never had a widget test because it depends on a native
  platform feature this project cannot mock in `flutter test` (the camera
  via `mobile_scanner`, matching the same boundary already established for
  `file_picker` and `printing` in every prior jalon) stays that way here:
  do not attempt to widget-test `CheckInScanScreen` itself. Extract pure,
  unit-testable logic instead where the task calls for it.

---

### Task 1: `AppSettings` — persisted values, no Riverpod yet

**Files:**
- Create: `lib/core/settings/app_settings.dart`
- Test: `test/core/settings/app_settings_test.dart`

**Interfaces:**
- Produces: `AppSettings` (immutable data class: `checkinFeedbackDelayMs`
  (`int`), `localeOverride` (`String?`)), `AppSettings.defaultDelayMs`
  (`const int`, `1800`), `AppSettings.load()` (`Future<AppSettings>`,
  reads both values from `SharedPreferences`, falling back to
  `defaultDelayMs`/`null` when unset), `AppSettings.saveCheckinFeedbackDelayMs(int)`
  and `AppSettings.saveLocaleOverride(String?)` (both `static Future<void>`,
  write directly to `SharedPreferences`; passing `null` to
  `saveLocaleOverride` removes the stored key rather than storing a null).
- Consumed by: Task 2's `AppSettingsNotifier`.

- [ ] **Step 1: Write the failing test**

Create `test/core/settings/app_settings_test.dart`:

```dart
import 'package:dif_pass/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings.load', () {
    test('returns the default delay and no locale override when nothing is stored', () async {
      final settings = await AppSettings.load();

      expect(settings.checkinFeedbackDelayMs, AppSettings.defaultDelayMs);
      expect(settings.localeOverride, isNull);
    });

    test('returns stored values when present', () async {
      SharedPreferences.setMockInitialValues({
        'checkin_feedback_delay_ms': 2500,
        'locale_override': 'fr',
      });

      final settings = await AppSettings.load();

      expect(settings.checkinFeedbackDelayMs, 2500);
      expect(settings.localeOverride, 'fr');
    });
  });

  group('AppSettings.saveCheckinFeedbackDelayMs', () {
    test('persists the value for a later load', () async {
      await AppSettings.saveCheckinFeedbackDelayMs(3000);

      final settings = await AppSettings.load();

      expect(settings.checkinFeedbackDelayMs, 3000);
    });
  });

  group('AppSettings.saveLocaleOverride', () {
    test('persists a value for a later load', () async {
      await AppSettings.saveLocaleOverride('en');

      final settings = await AppSettings.load();

      expect(settings.localeOverride, 'en');
    });

    test('removes the stored value when set to null', () async {
      await AppSettings.saveLocaleOverride('en');
      await AppSettings.saveLocaleOverride(null);

      final settings = await AppSettings.load();

      expect(settings.localeOverride, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/core/settings/app_settings_test.dart`
Expected: FAIL (`lib/core/settings/app_settings.dart` does not exist).

- [ ] **Step 3: Implement `AppSettings`**

Create `lib/core/settings/app_settings.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({required this.checkinFeedbackDelayMs, this.localeOverride});

  final int checkinFeedbackDelayMs;
  final String? localeOverride;

  static const defaultDelayMs = 1800;
  static const _delayKey = 'checkin_feedback_delay_ms';
  static const _localeKey = 'locale_override';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      checkinFeedbackDelayMs: prefs.getInt(_delayKey) ?? defaultDelayMs,
      localeOverride: prefs.getString(_localeKey),
    );
  }

  static Future<void> saveCheckinFeedbackDelayMs(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_delayKey, value);
  }

  static Future<void> saveLocaleOverride(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, value);
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/core/settings/app_settings_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add lib/core/settings/app_settings.dart test/core/settings/app_settings_test.dart
git commit -m "Add AppSettings, this app's first persisted user preferences"
```

---

### Task 2: `AppSettingsNotifier` and wiring the forced language into `DifPassApp`

**Files:**
- Create: `lib/core/settings/settings_providers.dart`
- Modify: `lib/main.dart`
- Test: `test/core/settings/settings_providers_test.dart`
- Test: `test/widget_test.dart` (read only, confirm it still passes
  unmodified, see the note below)

**Interfaces:**
- Consumes: `AppSettings` from Task 1.
- Produces: `appSettingsProvider` (`NotifierProvider<AppSettingsNotifier, AppSettings>`),
  `AppSettingsNotifier` (constructor `AppSettingsNotifier([AppSettings? initial])`,
  `build()` returns `initial` if given, else
  `const AppSettings(checkinFeedbackDelayMs: AppSettings.defaultDelayMs)`;
  methods `setCheckinFeedbackDelayMs(int)` and `setLocaleOverride(String?)`,
  both `Future<void>`, persist via `AppSettings.save*` then update `state`).
  Consumed by Task 3 (SettingsScreen controls) and Task 4 (check-in delay).

**Important: do not modify `test/widget_test.dart`.** It pumps `DifPassApp`
inside a bare `ProviderScope` with no `appSettingsProvider` override. Because
`AppSettingsNotifier`'s `build()` has a safe default (no `initial` given),
that test keeps working unchanged: it gets the default settings (1800 ms,
no locale override, i.e. automatic detection, the exact current behavior).
Only `main()` overrides the provider with the value loaded from disk.

- [ ] **Step 1: Write the failing test**

Create `test/core/settings/settings_providers_test.dart`:

```dart
import 'package:dif_pass/core/settings/app_settings.dart';
import 'package:dif_pass/core/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to AppSettings.defaultDelayMs and no locale override when not overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(appSettingsProvider);

    expect(settings.checkinFeedbackDelayMs, AppSettings.defaultDelayMs);
    expect(settings.localeOverride, isNull);
  });

  test('overriding with an initial value is honored', () {
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          () => AppSettingsNotifier(
            const AppSettings(checkinFeedbackDelayMs: 2500, localeOverride: 'fr'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final settings = container.read(appSettingsProvider);

    expect(settings.checkinFeedbackDelayMs, 2500);
    expect(settings.localeOverride, 'fr');
  });

  test('setCheckinFeedbackDelayMs updates state and persists the value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setCheckinFeedbackDelayMs(3000);

    expect(container.read(appSettingsProvider).checkinFeedbackDelayMs, 3000);
    expect((await AppSettings.load()).checkinFeedbackDelayMs, 3000);
  });

  test('setLocaleOverride updates state and persists the value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setLocaleOverride('en');

    expect(container.read(appSettingsProvider).localeOverride, 'en');
    expect((await AppSettings.load()).localeOverride, 'en');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/core/settings/settings_providers_test.dart`
Expected: FAIL (`lib/core/settings/settings_providers.dart` does not exist).

- [ ] **Step 3: Implement `AppSettingsNotifier`**

Create `lib/core/settings/settings_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  AppSettingsNotifier([this._initial]);

  final AppSettings? _initial;

  @override
  AppSettings build() =>
      _initial ?? const AppSettings(checkinFeedbackDelayMs: AppSettings.defaultDelayMs);

  Future<void> setCheckinFeedbackDelayMs(int value) async {
    await AppSettings.saveCheckinFeedbackDelayMs(value);
    state = AppSettings(checkinFeedbackDelayMs: value, localeOverride: state.localeOverride);
  }

  Future<void> setLocaleOverride(String? value) async {
    await AppSettings.saveLocaleOverride(value);
    state = AppSettings(checkinFeedbackDelayMs: state.checkinFeedbackDelayMs, localeOverride: value);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/core/settings/settings_providers_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Wire the loaded settings and the forced locale into `main.dart`**

This is the current full content of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: DifPassApp()));
}

class DifPassApp extends StatelessWidget {
  const DifPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DIF Pass',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

Replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_providers.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSettings = await AppSettings.load();
  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(() => AppSettingsNotifier(initialSettings)),
      ],
      child: const DifPassApp(),
    ),
  );
}

class DifPassApp extends ConsumerWidget {
  const DifPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeOverride = ref.watch(appSettingsProvider).localeOverride;
    return MaterialApp.router(
      title: 'DIF Pass',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      locale: localeOverride != null ? Locale(localeOverride) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

(`locale: null` leaves Flutter's own automatic detection in charge, matching
today's behavior exactly whenever no override is stored.)

- [ ] **Step 6: Confirm `test/widget_test.dart` still passes unmodified**

Run: `fvm flutter test test/widget_test.dart`
Expected: PASS, with no edits to that file. If it fails, do not "fix" it by
adding an `appSettingsProvider` override there; instead re-check that
`AppSettingsNotifier.build()` truly has a safe default with no `initial`,
since that default is what this test relies on.

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/core/settings/settings_providers.dart lib/main.dart test/core/settings/settings_providers_test.dart
git commit -m "Load persisted settings at startup and apply a forced locale"
```

---

### Task 3: `SettingsScreen` — check-in delay slider and language selector

**Files:**
- Modify: `lib/features/backup/presentation/screens/settings_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/backup/presentation/screens/settings_screen_test.dart`
  (existing file, read it first, extend it)

**Interfaces:**
- Consumes: `appSettingsProvider` from Task 2.

- [ ] **Step 1: Add new ARB keys**

```json
  "settingsCheckinDelayLabel": "Delai de confirmation check-in",
  "settingsLanguageLabel": "Langue",
  "settingsLanguageAuto": "Automatique",
  "settingsLanguageFrench": "Francais",
  "settingsLanguageEnglish": "Anglais"
```
```json
  "settingsCheckinDelayLabel": "Check-in confirmation delay",
  "settingsLanguageLabel": "Language",
  "settingsLanguageAuto": "Automatic",
  "settingsLanguageFrench": "French",
  "settingsLanguageEnglish": "English"
```

Place all five right after `settingsExportSuccess`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Read the current file**

Read `lib/features/backup/presentation/screens/settings_screen.dart` in
full before editing (do not guess its content; it has been touched by two
prior jalons and this task only adds to the end of `build()`, it does not
change `_export`/`_import`).

- [ ] **Step 3: Add the two new controls**

Add the import `import 'package:flutter_riverpod/flutter_riverpod.dart';`
is already present. Add:

```dart
import '../../../../core/settings/settings_providers.dart';
```

In `build(BuildContext context)`, capture the current settings right after
the existing `final l10n = AppLocalizations.of(context)!;` line:

```dart
final settings = ref.watch(appSettingsProvider);
```

Append to the `Column`'s `children`, after the existing `OutlinedButton.icon`
for import (keep everything already there unchanged, this is additive):

```dart
            const SizedBox(height: 32),
            Text(l10n.settingsCheckinDelayLabel, style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: settings.checkinFeedbackDelayMs.toDouble(),
              min: 1000,
              max: 4000,
              divisions: 30,
              label: '${(settings.checkinFeedbackDelayMs / 1000).toStringAsFixed(1)}s',
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setCheckinFeedbackDelayMs(value.round()),
            ),
            const SizedBox(height: 16),
            Text(l10n.settingsLanguageLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String?>(
              segments: [
                ButtonSegment(value: null, label: Text(l10n.settingsLanguageAuto)),
                ButtonSegment(value: 'fr', label: Text(l10n.settingsLanguageFrench)),
                ButtonSegment(value: 'en', label: Text(l10n.settingsLanguageEnglish)),
              ],
              selected: {settings.localeOverride},
              onSelectionChanged: (selection) => ref
                  .read(appSettingsProvider.notifier)
                  .setLocaleOverride(selection.first),
            ),
```

- [ ] **Step 4: Extend the existing test file**

Read `test/features/backup/presentation/screens/settings_screen_test.dart`
in full (it already has a `_wrap` helper and several tests; do not
duplicate that helper). Add a test confirming the new controls render and
respond, following the file's existing style (a bare `_wrap(const
SettingsScreen())` with no repository override is enough, matching the
file's first test):

```dart
testWidgets('moving the check-in delay slider persists the new value', (
  tester,
) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(_wrap(const SettingsScreen()));
  await tester.pumpAndSettle();

  final slider = tester.widget<Slider>(find.byType(Slider));
  expect(slider.value, 1800);

  await tester.drag(find.byType(Slider), const Offset(200, 0));
  await tester.pumpAndSettle();

  final updated = tester.widget<Slider>(find.byType(Slider));
  expect(updated.value, isNot(1800));
});

testWidgets('selecting a language updates the segmented button selection', (
  tester,
) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(_wrap(const SettingsScreen()));
  await tester.pumpAndSettle();

  await tester.tap(find.text('French'));
  await tester.pumpAndSettle();

  final segmentedButton = tester.widget<SegmentedButton<String?>>(
    find.byType(SegmentedButton<String?>),
  );
  expect(segmentedButton.selected, {'fr'});
});
```

Add `import 'package:shared_preferences/shared_preferences.dart';` to the
test file's imports for `setMockInitialValues`. Both tests must call
`SharedPreferences.setMockInitialValues({})` before pumping, since
`appSettingsProvider`'s default `build()` path still calls into
`SharedPreferences` indirectly through `setCheckinFeedbackDelayMs`/
`setLocaleOverride` when the slider/segmented button are used, and an
un-mocked `SharedPreferences.getInstance()` throws in `flutter test`.

- [ ] **Step 5: Run tests**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: PASS (all existing tests plus the 2 new ones).

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/backup/presentation/screens/settings_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/backup/presentation/screens/settings_screen_test.dart
git commit -m "Add a check-in delay slider and a language selector to Settings"
```

---

### Task 4: Check-in — differentiated dismiss, configurable delay, skip button

**Files:**
- Create: `test/features/checkin/presentation/check_in_feedback_test.dart`
- Modify: `lib/features/checkin/presentation/check_in_feedback.dart`
- Modify: `lib/features/checkin/presentation/screens/check_in_scan_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`

**Interfaces:**
- Consumes: `appSettingsProvider` from Task 2.
- Produces: `checkInFeedbackAutoDismisses(CheckInFeedback)` (`bool`,
  pure function), consumed only inside `check_in_scan_screen.dart` in
  this plan, but kept as a standalone top-level function (not a private
  method on the screen's state) specifically so it stays unit-testable
  without a widget pump.

`CheckInScanScreen` has never had a widget test in this project (it wraps
`MobileScannerController`/`MobileScanner`, a native camera dependency that
cannot be exercised in `flutter test`, the same boundary already
established for `file_picker` and `printing` in every prior jalon). This
task does not change that: the new dismiss logic is verified through the
pure function's unit test, not through a widget test of the screen.

- [ ] **Step 1: Add new ARB keys**

```json
  "checkinSkipAction": "Passer",
  "commonOk": "OK"
```
```json
  "checkinSkipAction": "Skip",
  "commonOk": "OK"
```

Place `checkinSkipAction` after `checkinUnexpectedError`, and `commonOk`
after `commonDelete`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Write the failing test for the pure function**

Create `test/features/checkin/presentation/check_in_feedback_test.dart`:

```dart
import 'package:dif_pass/features/checkin/presentation/check_in_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkInFeedbackAutoDismisses', () {
    test('true for a recorded check-in', () {
      const feedback = CheckInFeedbackRecorded(beneficiaryName: 'Jane Doe');

      expect(checkInFeedbackAutoDismisses(feedback), isTrue);
    });

    test('false for an already-recorded check-in', () {
      final feedback = CheckInFeedbackAlreadyRecorded(
        beneficiaryName: 'Jane Doe',
        scannedAt: DateTime(2026, 1, 1),
      );

      expect(checkInFeedbackAutoDismisses(feedback), isFalse);
    });

    test('false when the ticket is not found', () {
      const feedback = CheckInFeedbackNotFound();

      expect(checkInFeedbackAutoDismisses(feedback), isFalse);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `fvm flutter test test/features/checkin/presentation/check_in_feedback_test.dart`
Expected: FAIL (`checkInFeedbackAutoDismisses` does not exist).

- [ ] **Step 4: Add the pure function**

This is the current full content of
`lib/features/checkin/presentation/check_in_feedback.dart`:

```dart
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

Append to the end of the file:

```dart

// Whether this feedback should close itself automatically after a delay
// (the success case, to keep an entrance queue moving) or wait for an
// explicit tap (the two exception cases, which need the agent's attention).
bool checkInFeedbackAutoDismisses(CheckInFeedback feedback) =>
    feedback is CheckInFeedbackRecorded;
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/features/checkin/presentation/check_in_feedback_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Wire the differentiated dismiss into the screen**

This is the current full content of
`lib/features/checkin/presentation/screens/check_in_scan_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
      } catch (_) {
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
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                final size = constraints.biggest;
                final windowSide = size.shortestSide * 0.7;
                final scanWindow = Rect.fromCenter(
                  center: size.center(Offset.zero),
                  width: windowSide,
                  height: windowSide,
                );
                return ScanWindowOverlay(
                  controller: _controller,
                  scanWindow: scanWindow,
                  borderColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  borderWidth: 3,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.03, 1.03),
                      duration: 900.ms,
                    );
              },
            )
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
                  color: AppColors.ink.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.checkinCounterLabel(checkedIn, total),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.merge(ticketMonoStyle(Theme.of(context).colorScheme))
                      .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                )
                    .animate(key: ValueKey(checkedIn))
                    .scale(duration: 300.ms)
                    .fadeIn(duration: 300.ms),
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
    final theme = Theme.of(context);
    final isSuccess = feedback is CheckInFeedbackRecorded;
    final color = isSuccess ? AppColors.teal : theme.colorScheme.error;
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                if (name != null)
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                if (message != null)
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/settings/settings_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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

    CheckInFeedback? feedback;
    if (mounted) {
      try {
        final event = await ref.read(eventProvider(widget.eventId).future);
        feedback = await processCheckIn(
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
      } catch (_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.checkinUnexpectedError)),
          );
        }
        _dismissFeedback();
        return;
      }
    }

    if (feedback != null && checkInFeedbackAutoDismisses(feedback)) {
      final delayMs = ref.read(appSettingsProvider).checkinFeedbackDelayMs;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      _dismissFeedback();
    }
    // Exceptions (already recorded / not found) wait for the overlay's OK
    // button to call _dismissFeedback instead of a timer.
  }

  void _dismissFeedback() {
    if (!mounted) return;
    setState(() {
      _feedback = null;
      _busy = false;
    });
    if (!_manualEntry) {
      _controller.start();
    }
  }

  void _toggleManualEntry() {
    setState(() => _manualEntry = !_manualEntry);
    if (_manualEntry) {
      _controller.stop();
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
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                final size = constraints.biggest;
                final windowSide = size.shortestSide * 0.7;
                final scanWindow = Rect.fromCenter(
                  center: size.center(Offset.zero),
                  width: windowSide,
                  height: windowSide,
                );
                return ScanWindowOverlay(
                  controller: _controller,
                  scanWindow: scanWindow,
                  borderColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  borderWidth: 3,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.03, 1.03),
                      duration: 900.ms,
                    );
              },
            )
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
                  color: AppColors.ink.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.checkinCounterLabel(checkedIn, total),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.merge(ticketMonoStyle(Theme.of(context).colorScheme))
                      .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                )
                    .animate(key: ValueKey(checkedIn))
                    .scale(duration: 300.ms)
                    .fadeIn(duration: 300.ms),
              ),
            ),
          ),
          if (_feedback != null)
            _CheckInFeedbackOverlay(feedback: _feedback!, locale: locale, onDismiss: _dismissFeedback),
        ],
      ),
    );
  }
}

class _CheckInFeedbackOverlay extends StatelessWidget {
  const _CheckInFeedbackOverlay({
    required this.feedback,
    required this.locale,
    required this.onDismiss,
  });

  final CheckInFeedback feedback;
  final String locale;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSuccess = feedback is CheckInFeedbackRecorded;
    final color = isSuccess ? AppColors.teal : theme.colorScheme.error;
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                if (name != null)
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                if (message != null)
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    isSuccess ? l10n.checkinSkipAction : l10n.commonOk,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

(`_dismissFeedback` is idempotent by design: if the user taps the button
right as the delay timer also completes, both calls check `mounted`,
both set the same final state, and `_controller.start()` being called
twice is harmless. It is deliberately not awaited when called from a
button's `onPressed`, matching the void `VoidCallback` signature the
overlay needs.)

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green. `CheckInScanScreen` itself has no widget test to run
here (see the note in this task's header); the pure-function test from
Steps 2-5 is this task's coverage.

- [ ] **Step 8: Commit**

```bash
git add lib/features/checkin/presentation/check_in_feedback.dart lib/features/checkin/presentation/screens/check_in_scan_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/checkin/presentation/check_in_feedback_test.dart
git commit -m "Auto-dismiss check-in success, require a tap on exceptions, use the configured delay"
```

---

### Task 5: Reliable export/share confirmations

**Files:**
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/features/tickets/presentation/screens/ticket_preview_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/tickets/presentation/screens/ticket_preview_screen_test.dart`
  (existing file, extend it)

**Interfaces:**
- None new; `Printing.layoutPdf`/`Printing.sharePdf` (package `printing`
  5.15.0) both already return `Future<bool>` (verified against
  `lib/src/method_channel.dart` in the pinned package source:
  `sharePdf` returns `await _channel.invokeMethod<int>('sharePdf', ...) != 0`).

- [ ] **Step 1: Add new ARB key**

```json
  "ticketsExportSuccess": "Tickets exportes."
```
```json
  "ticketsExportSuccess": "Tickets exported."
```

Place it right after `ticketsExportError`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: `tickets_screen.dart` — verify the export result**

In `_exportAllTickets`, replace:

```dart
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'tickets-${event.shortCode}',
      );
    } catch (e) {
```

with:

```dart
      final success = await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'tickets-${event.shortCode}',
      );
      if (!context.mounted || !success) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsExportSuccess)),
      );
    } catch (e) {
```

No new test is added for this specific branch: `Printing.layoutPdf`
completes through a two-step native handshake (`printPdf` invoked, then a
separate `onCompleted` call arrives back into the plugin's own method
channel handler to resolve the `Future<bool>`, per
`lib/src/method_channel.dart`), unlike `sharePdf`'s direct return value.
Simulating that handshake in `flutter test` would mean re-implementing
part of the `printing` package's own internal protocol rather than testing
this app's logic, and there is no precedent for it anywhere in this
project (grep `test/` for `layoutPdf`/`printPdf` confirms zero existing
mocks). The change here is a one-line `if (!success) return;` guard,
reviewable by inspection; `_shareTicket`'s equivalent change (Step 3) has
real coverage since its mock is a simple synchronous return.

- [ ] **Step 3: `ticket_preview_screen.dart` — verify the share result**

In `_shareTicket`, replace:

```dart
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${ticket.readableId}.pdf',
      );
      if (!context.mounted) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketPreviewShareSuccess)),
      );
    } catch (e) {
```

with:

```dart
      final shared = await Printing.sharePdf(
        bytes: bytes,
        filename: '${ticket.readableId}.pdf',
      );
      if (!context.mounted || !shared) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketPreviewShareSuccess)),
      );
    } catch (e) {
```

- [ ] **Step 4: Add a test for the cancelled-share case**

Read `test/features/tickets/presentation/screens/ticket_preview_screen_test.dart`
in full (it already has a test, `'shows a confirmation snackbar after
successfully sharing the ticket'`, mocking the `net.nfet.printing` method
channel's `sharePdf` method to return `1`, per
`lib/src/method_channel.dart`'s `!= 0` check that turns that into `true`).
Add a new test in the same file, reusing the same mock shape, returning
`0` instead of `1` to simulate the user cancelling the native share sheet:

```dart
testWidgets(
  'shows no confirmation when the native share is cancelled',
  (tester) async {
    const printingChannel = MethodChannel('net.nfet.printing');
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(printingChannel, null);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printingChannel, (methodCall) async {
      if (methodCall.method == 'sharePdf') return 0;
      return null;
    });

    final fakeEvents = FakeEventRepository(
      events: [
        Event(
          id: 1,
          shortCode: 'EVT1',
          name: 'Gala DIF 2026',
          date: DateTime(2026, 12, 1),
          presenceMode: PresenceMode.simple,
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
    );

    await tester.pumpWidget(
      _wrap(
        const TicketPreviewScreen(ticketId: 1),
        fakeEvents,
        fakeBeneficiaries,
        fakeTickets,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Share ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Ticket shared.'), findsNothing);
  },
);
```

(Place it as a sibling of the existing `'shows a confirmation snackbar
after successfully sharing the ticket'` test, reusing the same fixture
data shape already used throughout this file, not a new helper.)

- [ ] **Step 5: Run tests**

Run: `fvm flutter test test/features/tickets/`
Expected: PASS.

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tickets/presentation/screens/tickets_screen.dart lib/features/tickets/presentation/screens/ticket_preview_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
git commit -m "Only confirm export or share when the native action actually succeeded"
```

---

### Task 6: Archive/restore — undo snackbar

**Files:**
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/features/events/presentation/screens/event_archive_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`,
  `event_archive_screen_test.dart` (existing files, extend them)

**Interfaces:**
- None new.

- [ ] **Step 1: Add new ARB keys**

```json
  "commonUndo": "Annuler",
  "eventsArchivedMessage": "Evenement archive.",
  "eventsRestoredMessage": "Evenement restaure."
```
```json
  "commonUndo": "Undo",
  "eventsArchivedMessage": "Event archived.",
  "eventsRestoredMessage": "Event restored."
```

Place `commonUndo` after `commonDelete` (after Task 4's `commonOk` if that
task already landed; either order is fine, both are new keys in the same
region). Place `eventsArchivedMessage` after `eventsArchiveError`, and
`eventsRestoredMessage` after `eventsRestoreError`. Run
`fvm flutter gen-l10n`.

- [ ] **Step 2: `events_list_screen.dart` — undo after archiving**

In `EventsListScreen`'s `onArchive` callback, replace:

```dart
                onArchive: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(eventRepositoryProvider)
                        .archiveEvent(event.id);
                    HapticFeedback.lightImpact();
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.eventsArchiveError)),
                    );
                  }
                },
```

with:

```dart
                onArchive: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final repository = ref.read(eventRepositoryProvider);
                  try {
                    await repository.archiveEvent(event.id);
                    HapticFeedback.lightImpact();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.eventsArchivedMessage),
                        action: SnackBarAction(
                          label: l10n.commonUndo,
                          onPressed: () => repository.restoreEvent(event.id),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.eventsArchiveError)),
                    );
                  }
                },
```

- [ ] **Step 3: `event_archive_screen.dart` — undo after restoring**

In the restore `IconButton`'s `onPressed`, replace:

```dart
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(eventRepositoryProvider)
                                .restoreEvent(event.id);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.eventsRestoreError)),
                            );
                          }
                        },
```

with:

```dart
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final repository = ref.read(eventRepositoryProvider);
                          try {
                            await repository.restoreEvent(event.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.eventsRestoredMessage),
                                action: SnackBarAction(
                                  label: l10n.commonUndo,
                                  onPressed: () => repository.archiveEvent(event.id),
                                ),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.eventsRestoreError)),
                            );
                          }
                        },
```

- [ ] **Step 4: Extend the existing tests**

Read `test/features/events/presentation/screens/events_list_screen_test.dart`
in full (it has a `_wrap(Widget child, FakeEventRepository fake)` helper
and a `'tapping the archive action archives the event'` test already).
Add, in the same file:

```dart
testWidgets('archiving shows an undo snackbar that restores the event', (
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

  await tester.tap(find.byTooltip('Archive'));
  await tester.pumpAndSettle();

  expect(find.text('Event archived.'), findsOneWidget);
  expect(fake.events.single.isArchived, isTrue);

  await tester.tap(find.text('Undo'));
  await tester.pumpAndSettle();

  expect(fake.events.single.isArchived, isFalse);
});
```

Read `test/features/events/presentation/screens/event_archive_screen_test.dart`
in full (same `_wrap` shape, plus a `'restore button restores the event'`
test). Add, in the same file:

```dart
testWidgets('restoring shows an undo snackbar that archives the event', (
  tester,
) async {
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

  await tester.tap(find.byTooltip('Restore'));
  await tester.pumpAndSettle();

  expect(find.text('Event restored.'), findsOneWidget);
  expect(fake.events.single.isArchived, isFalse);

  await tester.tap(find.text('Undo'));
  await tester.pumpAndSettle();

  expect(fake.events.single.isArchived, isTrue);
});
```

(The restore button's tooltip is `l10n.eventsRestoreAction`, English value
"Restore", confirmed in `lib/l10n/app_en.arb`; use `find.byTooltip('Restore')`.)

- [ ] **Step 5: Run tests**

Run: `fvm flutter test test/features/events/`
Expected: PASS.

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/events/presentation/screens/events_list_screen.dart lib/features/events/presentation/screens/event_archive_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/events/presentation/screens/events_list_screen_test.dart test/features/events/presentation/screens/event_archive_screen_test.dart
git commit -m "Replace the archive/restore snackbars with an undoable version"
```

---

### Task 7: CSV import — field hint before file selection

**Files:**
- Modify: `lib/features/beneficiaries/presentation/screens/csv_import_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Create: `test/features/beneficiaries/presentation/screens/csv_import_screen_test.dart`
  (this file does not exist yet anywhere in this project's history,
  confirmed via `git log --all` during planning; this is a new file, not
  an extension of an existing one)

**Interfaces:**
- None new.

- [ ] **Step 1: Add new ARB keys**

```json
  "csvImportFieldsHint": "Vous pourrez associer les colonnes de votre fichier a : Nom, {fields}",
  "csvImportFieldsHintNameOnly": "Vous pourrez associer les colonnes de votre fichier au champ Nom."
```
```json
  "csvImportFieldsHint": "You'll be able to map your file's columns to: Name, {fields}",
  "csvImportFieldsHintNameOnly": "You'll be able to map your file's columns to the Name field."
```

Place both right after `csvImportSaveError`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Read the current file**

Read `lib/features/beneficiaries/presentation/screens/csv_import_screen.dart`
in full before editing (it has three body branches in `build()`; this
task only changes the `else` branch, the one shown before any file is
picked).

- [ ] **Step 3: Add the field hint**

In `build(BuildContext context)`, move the existing
`final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));`
line (currently declared only inside the `else if (_headers != null && ...)`
branch) up to the top of `build`, right after
`final l10n = AppLocalizations.of(context)!;`, so it is available to both
branches that need it:

```dart
final l10n = AppLocalizations.of(context)!;
final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));
```

Remove the now-duplicate declaration from inside the
`else if (_headers != null && _dataRows != null)` branch (it stays used
there via `customFieldsAsync.when(...)`, just no longer redeclared).

Replace the final `else` branch:

```dart
    } else {
      body = Center(
        child: FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(l10n.csvImportPickFileAction),
        ),
      );
    }
```

with:

```dart
    } else {
      final fieldLabels =
          customFieldsAsync.valueOrNull?.map((f) => f.label).join(', ') ?? '';
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fieldLabels.isEmpty
                    ? l10n.csvImportFieldsHintNameOnly
                    : l10n.csvImportFieldsHint(fieldLabels),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.csvImportPickFileAction),
              ),
            ],
          ),
        ),
      );
    }
```

(While `customFieldsAsync` is still loading, `valueOrNull` is `null` and
the hint reads as "Name only" until the real list arrives, then rebuilds
with the full list; no loading spinner needed for a one-line hint text.)

- [ ] **Step 4: Write the new test file**

Create `test/features/beneficiaries/presentation/screens/csv_import_screen_test.dart`,
starting with:

```dart
import 'package:dif_pass/features/beneficiaries/presentation/screens/csv_import_screen.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../events/fake_event_repository.dart';
import '../../fake_beneficiary_repository.dart';

Widget _wrap(Widget child, FakeEventRepository fakeEvents) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fakeEvents),
      beneficiaryRepositoryProvider.overrideWithValue(FakeBeneficiaryRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
```

(matching `beneficiaries_list_screen_test.dart`'s established `_wrap`
shape; `beneficiaryRepositoryProvider` is overridden with a plain
`FakeBeneficiaryRepository()` even though neither test below exercises
`_handleImport`, for consistency with every other test in this feature
and in case a later test in this file needs it). Then the two tests:

```dart
testWidgets('shows the custom field labels before a file is picked', (
  tester,
) async {
  final fakeEvents = FakeEventRepository(
    events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  );
  await fakeEvents.replaceCustomFields(1, const [
    NewCustomField(
      label: 'Table number',
      type: CustomFieldType.text,
      sortOrder: 0,
    ),
  ]);

  await tester.pumpWidget(_wrap(const CsvImportScreen(eventId: 1), fakeEvents));
  await tester.pumpAndSettle();

  expect(find.textContaining('Table number'), findsOneWidget);
});

testWidgets('mentions only Name when the event has no custom fields', (
  tester,
) async {
  final fakeEvents = FakeEventRepository(
    events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
  );

  await tester.pumpWidget(_wrap(const CsvImportScreen(eventId: 1), fakeEvents));
  await tester.pumpAndSettle();

  expect(
    find.text("You'll be able to map your file's columns to the Name field."),
    findsOneWidget,
  );
});
```

Also add the missing import `NewCustomField` needs:
`import 'package:dif_pass/features/events/domain/custom_field.dart';`
(for `NewCustomField`) at the top of the test file, alongside the others.

- [ ] **Step 5: Run tests**

Run: `fvm flutter test test/features/beneficiaries/presentation/screens/csv_import_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/beneficiaries/presentation/screens/csv_import_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/beneficiaries/presentation/screens/csv_import_screen_test.dart
git commit -m "Show the event's custom fields before picking a CSV file to import"
```

---

### Task 8: Document the missing PDF glyph as known debt

**Files:**
- Modify: `lib/features/tickets/data/ticket_pdf_builder.dart`

**Interfaces:** None.

- [ ] **Step 1: Add the comment**

Read `lib/features/tickets/data/ticket_pdf_builder.dart`. Near the
`_loadFont` helper (added in jalon 8's font-embedding task), add:

```dart
// ponytail: IBM Plex Sans does not cover every Unicode codepoint (verified:
// it lacks U+0186, used in some West African orthographies, e.g. Ewe). The
// pdf package renders a visible crossed-box placeholder for a codepoint it
// cannot draw, not a silent gap and not a crash, so this is left as a known
// limitation rather than adding a fallback font for one character with no
// reported real-world case yet. Upgrade path if it becomes one: pass a
// broader-coverage font via TextStyle.fontFallback on the affected text.
```

Place it directly above `Future<pw.Font> _loadFont(String assetPath)`.

- [ ] **Step 2: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green (comment-only change, no behavior difference).

- [ ] **Step 3: Commit**

```bash
git add lib/features/tickets/data/ticket_pdf_builder.dart
git commit -m "Document the IBM Plex Sans glyph gap as a known limitation"
```

---

### Task 9: Full lot verification

**Files:** None (verification only).

- [ ] **Step 1: Run the full test suite**

Run: `fvm flutter test`
Expected: all tests pass, including every new test added in Tasks 1-7.

- [ ] **Step 2: Run the analyzer**

Run: `fvm flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 3: Confirm `shared_preferences` is actually used now**

Run: `grep -rln "shared_preferences" lib/`
Expected: at least `lib/core/settings/app_settings.dart` (previously this
returned nothing at all, per the design doc's own finding during
brainstorming).

- [ ] **Step 4: Confirm every ARB key added in this plan exists in both locales**

Run `fvm flutter gen-l10n` once more and confirm it exits 0 with no
missing-translation warnings for any new key.

- [ ] **Step 5: Report readiness**

Report the final test count and confirm the analyzer is clean. Note for
whoever reviews this branch: `CheckInScanScreen`'s new dismiss logic is
covered only through the pure `checkInFeedbackAutoDismisses` function
(Task 4) and `_exportAllTickets`'s success-confirmation branch (Task 5)
has no automated test, both by deliberate, documented choice matching
this project's established native-platform-boundary testing convention,
not an oversight.
