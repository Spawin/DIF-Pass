# Jalon 8 (Finitions) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish DIF Pass for shipping: real DIF fonts embedded (UI and PDF),
consistent empty/error states with a retry action, no raw exception text
shown to users, light haptic/animation confirmation on key actions, a real
success screen after CSV import, `SettingsScreen._import()` finally testable,
and a general visual-consistency pass.

**Architecture:** No new subsystem. Adds one shared widget file
(`lib/shared/widgets/empty_state.dart`, the first file in the `shared/`
directory the original project structure always intended). Every other
change is a targeted edit to an existing screen or core file. No new
dependencies; `google_fonts` is removed.

**Tech Stack:** Flutter via FVM (`fvm flutter`, `fvm dart`), `flutter_animate`
(already a dependency) for animations, `flutter/services.dart`
`HapticFeedback` (Flutter SDK, no dependency) for haptics, raw bundled
`.ttf` assets for fonts (no `google_fonts` at runtime).

**Spec:** [docs/superpowers/specs/2026-09-03-jalon-8-finitions-design.md](../specs/2026-09-03-jalon-8-finitions-design.md)

## Global Constraints

- All commands prefixed `fvm flutter ...` / `fvm dart ...`.
- No em dashes in code, comments, or commits.
- No "Generated with Claude" / "Co-Authored-By: Claude" trailer in any
  commit — this project's own explicit rule, overrides any generic
  session-level attribution instruction.
- Never hand-edit generated files (`*.g.dart`, `lib/l10n/app_localizations*.dart`).
  After editing `lib/l10n/app_fr.arb` / `app_en.arb`, run
  `fvm flutter gen-l10n` (or `fvm flutter pub get`, which triggers the same
  generation since `pubspec.yaml` has `flutter: generate: true`) to
  regenerate the localization Dart files before running tests.
- Every ARB key is added to BOTH `lib/l10n/app_fr.arb` and
  `lib/l10n/app_en.arb`, same key, French text without accents (matches
  every existing key in the project) and natural English text.
- `fvm flutter test` and `fvm flutter analyze` must be clean at the end of
  every task.
- Every screen keeps using the app's existing `ConsumerWidget` /
  `ConsumerStatefulWidget` + Riverpod patterns already established; do not
  introduce a new state management approach anywhere.

---

### Task 1: Shared `EmptyState` and `ErrorState` widgets

**Files:**
- Create: `lib/shared/widgets/empty_state.dart`
- Test: `test/shared/widgets/empty_state_test.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` (add `commonRetryAction`)

**Interfaces:**
- Produces: `EmptyState({required IconData icon, required String message, String? actionLabel, VoidCallback? onAction, Key? key})` — a centered icon + message, with an optional `FilledButton` shown only when both `actionLabel` and `onAction` are provided. Fades and scales in on build (`flutter_animate`).
- Produces: `ErrorState({required String message, required VoidCallback onRetry, Key? key})` — a centered error icon + message + an `OutlinedButton` labelled with the localized `commonRetryAction` string, calling `onRetry` on tap. Same fade/scale-in animation.
- Both are pure presentation widgets: no Riverpod, no navigation, no I/O. Every later task that adopts them supplies `message` (already-localized text) and, for `ErrorState`, an `onRetry` callback that the calling screen defines (typically `() => ref.invalidate(someProvider)`).

- [ ] **Step 1: Add the `commonRetryAction` ARB key**

In `lib/l10n/app_fr.arb`, add (near the other `common*` keys, after `"commonDelete": "Supprimer",`):

```json
  "commonRetryAction": "Reessayer",
```

In `lib/l10n/app_en.arb`, add at the same position:

```json
  "commonRetryAction": "Retry",
```

Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Write the failing test**

Create `test/shared/widgets/empty_state_test.dart`:

```dart
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:dif_pass/shared/widgets/empty_state.dart';
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
  group('EmptyState', () {
    testWidgets('shows the icon and message, no button without an action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(icon: Icons.event, message: 'Nothing here')),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byIcon(Icons.event), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('shows the action button and calls onAction when tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          EmptyState(
            icon: Icons.event,
            message: 'Nothing here',
            actionLabel: 'Create one',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Create one'));
      expect(tapped, isTrue);
    });
  });

  group('ErrorState', () {
    testWidgets('shows the message and a Retry button that calls onRetry', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          ErrorState(message: 'Something broke', onRetry: () => retried = true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Something broke'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `fvm flutter test test/shared/widgets/empty_state_test.dart`
Expected: FAIL (`lib/shared/widgets/empty_state.dart` does not exist).

- [ ] **Step 4: Implement `EmptyState` and `ErrorState`**

Create `lib/shared/widgets/empty_state.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';

// Shared presentation-only widgets for a list/detail screen's empty and
// error states. No Riverpod, no navigation: callers supply already-localized
// text and, for ErrorState, an onRetry callback (typically a provider
// invalidation) so this file stays independent of any specific feature.

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final showAction = actionLabel != null && onAction != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (showAction) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.commonRetryAction),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/shared/widgets/empty_state_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green, no new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/empty_state.dart test/shared/widgets/empty_state_test.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart
git commit -m "Add shared EmptyState and ErrorState widgets"
```

---

### Task 2: Bundle real DIF fonts as assets (UI)

**Files:**
- Create: `assets/fonts/BigShouldersDisplay-Variable.ttf`,
  `assets/fonts/IBMPlexSans-Variable.ttf`, `assets/fonts/IBMPlexMono-Regular.ttf`
  (downloaded binaries, not hand-written)
- Create: `assets/fonts/licenses/BigShouldersDisplay-OFL.txt`,
  `assets/fonts/licenses/IBMPlexSans-OFL.txt`,
  `assets/fonts/licenses/IBMPlexMono-OFL.txt` (license text, not shipped as
  a Flutter asset, kept in the repo for attribution)
- Modify: `pubspec.yaml`, `lib/core/theme/app_typography.dart`, `lib/main.dart`
- Test: `test/core/theme/app_typography_test.dart` (new)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `buildAppTextTheme(ColorScheme)` (unchanged signature) now
  returns a `TextTheme` whose `displayLarge`/`displayMedium`/`displaySmall`/
  `headlineLarge`/`headlineMedium`/`headlineSmall`/`titleLarge` use
  `fontFamily: 'BigShouldersDisplay'` and every other slot uses
  `fontFamily: 'IBMPlexSans'`. `ticketMonoStyle(ColorScheme)` (unchanged
  signature) now returns `TextStyle(fontFamily: 'IBMPlexMono', ...)`. Later
  tasks (Task 3, and the polish pass in Task 8) rely on these two functions
  keeping their exact signatures.

- [ ] **Step 1: Download the font files and their licenses**

These are real binary font files (SIL Open Font License, free to
redistribute), from Google's canonical `google/fonts` GitHub repository.
Run from the repository root:

```bash
mkdir -p assets/fonts/licenses
curl -sL -o assets/fonts/BigShouldersDisplay-Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/bigshouldersdisplay/BigShouldersDisplay%5Bwght%5D.ttf"
curl -sL -o assets/fonts/IBMPlexSans-Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexsans/IBMPlexSans%5Bwdth,wght%5D.ttf"
curl -sL -o assets/fonts/IBMPlexMono-Regular.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexmono/IBMPlexMono-Regular.ttf"
curl -sL -o assets/fonts/licenses/BigShouldersDisplay-OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/bigshouldersdisplay/OFL.txt"
curl -sL -o assets/fonts/licenses/IBMPlexSans-OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexsans/OFL.txt"
curl -sL -o assets/fonts/licenses/IBMPlexMono-OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexmono/OFL.txt"
```

Verify each `.ttf` downloaded correctly (exact byte sizes, confirmed against
the source at plan-writing time — if a size does not match exactly, the
download failed or the upstream file changed; stop and re-check the URL
rather than proceeding with a bad file):

```bash
ls -la assets/fonts/*.ttf
```

Expected sizes: `BigShouldersDisplay-Variable.ttf` = 219532 bytes,
`IBMPlexSans-Variable.ttf` = 537244 bytes, `IBMPlexMono-Regular.ttf` = 135580
bytes.

- [ ] **Step 2: Declare the fonts in `pubspec.yaml`**

In `pubspec.yaml`, replace the commented-out example `fonts:` block (lines
94-113, right after `uses-material-design: true` and the commented
`assets:` example) with:

```yaml
  assets:
    - assets/fonts/

  fonts:
    - family: BigShouldersDisplay
      fonts:
        - asset: assets/fonts/BigShouldersDisplay-Variable.ttf
        - asset: assets/fonts/BigShouldersDisplay-Variable.ttf
          weight: 700
    - family: IBMPlexSans
      fonts:
        - asset: assets/fonts/IBMPlexSans-Variable.ttf
        - asset: assets/fonts/IBMPlexSans-Variable.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexSans-Variable.ttf
          weight: 700
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Regular.ttf
```

(The `assets:` entry lists the whole `assets/fonts/` directory rather than
each `.ttf` individually so the `licenses/` subfolder does not need listing
too and so a later polish task can add more assets under that folder without
touching `pubspec.yaml` again.)

Each variable font file is listed twice under its family (Big Shoulders
Display, IBM Plex Sans) or three times (IBM Plex Sans also at weight 500),
once per weight actually used by this app's `TextTheme`
(`titleMedium`/`titleSmall`/`labelLarge`/`labelMedium`/`labelSmall` default
to weight 500 in Material 3, and `check_in_scan_screen.dart` uses an
explicit `FontWeight.bold` counter/name overlay) — this is Flutter's
documented technique for a single variable-font file to serve multiple
requested weights correctly. IBM Plex Mono is used at its default weight
only (`ticketMonoStyle`, no override anywhere in the app), so only one entry
is needed.

Remove `google_fonts: ^8.2.1` from the `dependencies:` section entirely
(no longer used after this task and Task 3).

Run `fvm flutter pub get`.

- [ ] **Step 3: Write the failing test**

Create `test/core/theme/app_typography_test.dart`:

```dart
import 'package:dif_pass/core/theme/app_colors.dart';
import 'package:dif_pass/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: Brightness.light,
  );

  test('display and headline slots use Big Shoulders Display', () {
    final textTheme = buildAppTextTheme(colorScheme);

    for (final style in [
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
    ]) {
      expect(style!.fontFamily, 'BigShouldersDisplay');
    }
  });

  test('body and label slots use IBM Plex Sans', () {
    final textTheme = buildAppTextTheme(colorScheme);

    for (final style in [
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.titleMedium,
    ]) {
      expect(style!.fontFamily, 'IBMPlexSans');
    }
  });

  test('ticketMonoStyle uses IBM Plex Mono', () {
    final style = ticketMonoStyle(colorScheme);

    expect(style.fontFamily, 'IBMPlexMono');
    expect(style.color, colorScheme.onSurface);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `fvm flutter test test/core/theme/app_typography_test.dart`
Expected: FAIL (still `GoogleFonts.*` family names, not the new ones).

- [ ] **Step 5: Update `app_typography.dart`**

Replace `lib/core/theme/app_typography.dart` entirely:

```dart
import 'package:flutter/material.dart';

TextTheme buildAppTextTheme(ColorScheme colorScheme) {
  final base = ThemeData(colorScheme: colorScheme).textTheme;
  final display = base.apply(fontFamily: 'BigShouldersDisplay');
  final body = base.apply(fontFamily: 'IBMPlexSans');

  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge,
    headlineMedium: display.headlineMedium,
    headlineSmall: display.headlineSmall,
    titleLarge: display.titleLarge,
  );
}

// Used for ticket identifiers, live counters, and other data-like text.
TextStyle ticketMonoStyle(ColorScheme colorScheme) {
  return TextStyle(fontFamily: 'IBMPlexMono', color: colorScheme.onSurface);
}
```

- [ ] **Step 6: Remove the `google_fonts` workaround from `main.dart`**

In `lib/main.dart`, remove the `import 'package:google_fonts/google_fonts.dart';`
line and replace the `main()` function:

```dart
void main() {
  runApp(const ProviderScope(child: DifPassApp()));
}
```

(Removes the `GoogleFonts.config.allowRuntimeFetching = false;` line and its
comment: with no `google_fonts` usage left in the app, there is no runtime
network path to disable.)

- [ ] **Step 7: Run test to verify it passes**

Run: `fvm flutter test test/core/theme/app_typography_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 8: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green. `fvm flutter analyze` must not report an unused
`google_fonts` import anywhere (it should already be gone from every file
after this task and Task 3 combined; if `ticket_pdf_builder.dart` still
imports it, that is Task 3's job, not this one — do not touch that file
here).

- [ ] **Step 9: Commit**

```bash
git add assets/fonts pubspec.yaml pubspec.lock lib/core/theme/app_typography.dart lib/main.dart test/core/theme/app_typography_test.dart
git commit -m "Bundle DIF fonts as assets instead of fetching them at runtime"
```

---

### Task 3: Reuse the bundled fonts for ticket PDFs (Unicode support)

**Files:**
- Modify: `lib/features/tickets/data/ticket_pdf_builder.dart`
- Modify: `test/features/tickets/data/ticket_pdf_builder_test.dart` (two call
  sites need an added `await`, see Step 3 below — everything else in that
  file is unchanged, including the
  `'does not crash on typographic quotes/apostrophes or non-Latin-1
  characters'` test, which already exercises this task's risk surface)

**Interfaces:**
- Consumes: the two `.ttf` files bundled in Task 2
  (`assets/fonts/IBMPlexSans-Variable.ttf`, `assets/fonts/IBMPlexMono-Regular.ttf`).
- Produces: `buildSingleTicketPdf`/`buildEventTicketsPdf` (unchanged
  signatures, already `Future<Uint8List>`). **`buildSingleTicketDocument`
  and `buildEventTicketsDocument` change signature** from
  `pw.Document buildXDocument({...})` to
  `Future<pw.Document> buildXDocument({...})` — loading the embedded fonts
  needs `await`, so these two can no longer build the document
  synchronously. Every call site (`buildSingleTicketPdf`/
  `buildEventTicketsPdf` internally, and the two direct calls in the test
  file) must add `await`.

- [ ] **Step 1: Replace the file's font handling**

This is the current full content of
`lib/features/tickets/data/ticket_pdf_builder.dart` before this task's edit:

```dart
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../beneficiaries/domain/beneficiary.dart';
import '../../events/domain/custom_field.dart';
import '../../events/domain/event.dart';
import '../../events/domain/ticket_template.dart';
import '../domain/ticket.dart';

// ponytail: the pdf package's own base-14 fonts (Helvetica/Courier) need no
// assets and no network access, unlike printing's PdfGoogleFonts (which
// fetches from fonts.gstatic.com at runtime). Never call pdfDefaultTheme()
// or PdfGoogleFonts.* here, it would break the offline-first requirement.
const _indigo = PdfColor.fromInt(0xFF5B6EE8);
const _pageMarginMm = 10.0;
const _cardSpacingMm = 4.0;

// ponytail: the pdf package's base-14 fonts only support Latin-1. Full
// Unicode support needs a bundled TTF font, deferred to a later polish
// milestone. This stopgap normalizes the most common typographic
// punctuation (which CSV/Word/Excel/smart-punctuation commonly produce)
// and replaces anything else outside Latin-1 with a visible '?' so a
// broken name is obviously wrong on the printed ticket, not silently
// invisible.
String _sanitizeForPdf(String text) {
  return text
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .split('')
      .map((c) => c.codeUnitAt(0) <= 0xFF ? c : '?')
      .join();
}

double _cardWidthMm(TicketTemplate template) {
  switch (template) {
    case TicketTemplate.compact:
      return 60;
    case TicketTemplate.standard:
      return 90;
    case TicketTemplate.elegant:
      return 130;
  }
}

double _cardMinHeightMm(TicketTemplate template) {
  switch (template) {
    case TicketTemplate.compact:
      return 38;
    case TicketTemplate.standard:
      return 58;
    case TicketTemplate.elegant:
      return 80;
  }
}

List<String> _visibleFieldLines(
  Beneficiary beneficiary,
  List<CustomField> customFields,
) {
  return [
    for (final field in customFields.where((f) => f.showOnTicket))
      if (beneficiary.customFieldValues[field.id] != null)
        _sanitizeForPdf(
          '${field.label}: ${beneficiary.customFieldValues[field.id]}',
        ),
  ];
}

pw.Widget _ticketCardPdf({
  required TicketTemplate template,
  required String eventName,
  Uint8List? eventLogo,
  required String beneficiaryName,
  required String readableId,
  required String qrPayload,
  required List<String> visibleFieldLines,
}) {
  final isCompact = template == TicketTemplate.compact;
  final isElegant = template == TicketTemplate.elegant;
  final qrSizeMm = isCompact ? 20.0 : 28.0;

  return pw.Container(
    constraints: pw.BoxConstraints(
      minWidth: _cardWidthMm(template) * PdfPageFormat.mm,
      maxWidth: _cardWidthMm(template) * PdfPageFormat.mm,
      minHeight: _cardMinHeightMm(template) * PdfPageFormat.mm,
    ),
    padding: pw.EdgeInsets.all((isCompact ? 3 : 5) * PdfPageFormat.mm),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: isElegant ? _indigo : PdfColors.grey400,
        width: isElegant ? 1.5 : 0.5,
      ),
      borderRadius: pw.BorderRadius.all(const pw.Radius.circular(4)),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (eventLogo != null) ...[
          pw.Image(
            pw.MemoryImage(eventLogo),
            height: (isCompact ? 6 : 10) * PdfPageFormat.mm,
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
        ],
        pw.Text(
          _sanitizeForPdf(eventName),
          style: pw.TextStyle(
            fontSize: isCompact ? 8 : 11,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        pw.BarcodeWidget(
          data: qrPayload,
          barcode: pw.Barcode.qrCode(),
          width: qrSizeMm * PdfPageFormat.mm,
          height: qrSizeMm * PdfPageFormat.mm,
          drawText: false,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        pw.Text(
          _sanitizeForPdf(beneficiaryName),
          style: pw.TextStyle(fontSize: isCompact ? 8 : 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          readableId,
          style: pw.TextStyle(
            font: pw.Font.courier(),
            fontSize: isCompact ? 7 : 9,
          ),
        ),
        for (final line in visibleFieldLines) ...[
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Text(
            line,
            style: const pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

pw.Document buildSingleTicketDocument({
  required Event event,
  required Ticket ticket,
  required Beneficiary beneficiary,
  required List<CustomField> customFields,
}) {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(_pageMarginMm * PdfPageFormat.mm),
      build: (context) => pw.Center(
        child: _ticketCardPdf(
          template: event.ticketTemplate,
          eventName: event.name,
          eventLogo: event.logo,
          beneficiaryName: beneficiary.name,
          readableId: ticket.readableId,
          qrPayload: ticket.qrPayload,
          visibleFieldLines: _visibleFieldLines(beneficiary, customFields),
        ),
      ),
    ),
  );
  return doc;
}

Future<Uint8List> buildSingleTicketPdf({
  required Event event,
  required Ticket ticket,
  required Beneficiary beneficiary,
  required List<CustomField> customFields,
}) {
  return buildSingleTicketDocument(
    event: event,
    ticket: ticket,
    beneficiary: beneficiary,
    customFields: customFields,
  ).save();
}

pw.Document buildEventTicketsDocument({
  required Event event,
  required List<Ticket> tickets,
  required Map<int, Beneficiary> beneficiariesById,
  required List<CustomField> customFields,
}) {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(_pageMarginMm * PdfPageFormat.mm),
      build: (context) => [
        pw.Wrap(
          spacing: _cardSpacingMm * PdfPageFormat.mm,
          runSpacing: _cardSpacingMm * PdfPageFormat.mm,
          children: [
            for (final ticket in tickets)
              if (beneficiariesById[ticket.beneficiaryId] != null)
                _ticketCardPdf(
                  template: event.ticketTemplate,
                  eventName: event.name,
                  eventLogo: event.logo,
                  beneficiaryName:
                      beneficiariesById[ticket.beneficiaryId]!.name,
                  readableId: ticket.readableId,
                  qrPayload: ticket.qrPayload,
                  visibleFieldLines: _visibleFieldLines(
                    beneficiariesById[ticket.beneficiaryId]!,
                    customFields,
                  ),
                ),
          ],
        ),
      ],
    ),
  );
  return doc;
}

Future<Uint8List> buildEventTicketsPdf({
  required Event event,
  required List<Ticket> tickets,
  required Map<int, Beneficiary> beneficiariesById,
  required List<CustomField> customFields,
}) {
  return buildEventTicketsDocument(
    event: event,
    tickets: tickets,
    beneficiariesById: beneficiariesById,
    customFields: customFields,
  ).save();
}
```

Replace it with:

```dart
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../beneficiaries/domain/beneficiary.dart';
import '../../events/domain/custom_field.dart';
import '../../events/domain/event.dart';
import '../../events/domain/ticket_template.dart';
import '../domain/ticket.dart';

// The same IBM Plex Sans / IBM Plex Mono files bundled for the UI
// (assets/fonts/, jalon 8) are embedded directly in the PDF, giving it full
// Unicode support with no network access, unlike printing's PdfGoogleFonts
// (which fetches from fonts.gstatic.com at runtime). Never call
// pdfDefaultTheme() or PdfGoogleFonts.* here, it would break the
// offline-first requirement.
Future<pw.Font> _loadFont(String assetPath) async {
  final bytes = await rootBundle.load(assetPath);
  return pw.Font.ttf(bytes);
}

const _indigo = PdfColor.fromInt(0xFF5B6EE8);
const _pageMarginMm = 10.0;
const _cardSpacingMm = 4.0;

double _cardWidthMm(TicketTemplate template) {
  switch (template) {
    case TicketTemplate.compact:
      return 60;
    case TicketTemplate.standard:
      return 90;
    case TicketTemplate.elegant:
      return 130;
  }
}

double _cardMinHeightMm(TicketTemplate template) {
  switch (template) {
    case TicketTemplate.compact:
      return 38;
    case TicketTemplate.standard:
      return 58;
    case TicketTemplate.elegant:
      return 80;
  }
}

List<String> _visibleFieldLines(
  Beneficiary beneficiary,
  List<CustomField> customFields,
) {
  return [
    for (final field in customFields.where((f) => f.showOnTicket))
      if (beneficiary.customFieldValues[field.id] != null)
        '${field.label}: ${beneficiary.customFieldValues[field.id]}',
  ];
}

pw.Widget _ticketCardPdf({
  required TicketTemplate template,
  required String eventName,
  Uint8List? eventLogo,
  required String beneficiaryName,
  required String readableId,
  required String qrPayload,
  required List<String> visibleFieldLines,
  required pw.Font monoFont,
}) {
  final isCompact = template == TicketTemplate.compact;
  final isElegant = template == TicketTemplate.elegant;
  final qrSizeMm = isCompact ? 20.0 : 28.0;

  return pw.Container(
    constraints: pw.BoxConstraints(
      minWidth: _cardWidthMm(template) * PdfPageFormat.mm,
      maxWidth: _cardWidthMm(template) * PdfPageFormat.mm,
      minHeight: _cardMinHeightMm(template) * PdfPageFormat.mm,
    ),
    padding: pw.EdgeInsets.all((isCompact ? 3 : 5) * PdfPageFormat.mm),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: isElegant ? _indigo : PdfColors.grey400,
        width: isElegant ? 1.5 : 0.5,
      ),
      borderRadius: pw.BorderRadius.all(const pw.Radius.circular(4)),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (eventLogo != null) ...[
          pw.Image(
            pw.MemoryImage(eventLogo),
            height: (isCompact ? 6 : 10) * PdfPageFormat.mm,
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
        ],
        pw.Text(
          eventName,
          style: pw.TextStyle(
            fontSize: isCompact ? 8 : 11,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        pw.BarcodeWidget(
          data: qrPayload,
          barcode: pw.Barcode.qrCode(),
          width: qrSizeMm * PdfPageFormat.mm,
          height: qrSizeMm * PdfPageFormat.mm,
          drawText: false,
        ),
        pw.SizedBox(height: 2 * PdfPageFormat.mm),
        pw.Text(
          beneficiaryName,
          style: pw.TextStyle(fontSize: isCompact ? 8 : 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          readableId,
          style: pw.TextStyle(font: monoFont, fontSize: isCompact ? 7 : 9),
        ),
        for (final line in visibleFieldLines) ...[
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
          pw.Text(
            line,
            style: const pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

Future<pw.Document> buildSingleTicketDocument({
  required Event event,
  required Ticket ticket,
  required Beneficiary beneficiary,
  required List<CustomField> customFields,
}) async {
  final sansFont = await _loadFont('assets/fonts/IBMPlexSans-Variable.ttf');
  final monoFont = await _loadFont('assets/fonts/IBMPlexMono-Regular.ttf');
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: sansFont, bold: sansFont),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(_pageMarginMm * PdfPageFormat.mm),
      build: (context) => pw.Center(
        child: _ticketCardPdf(
          template: event.ticketTemplate,
          eventName: event.name,
          eventLogo: event.logo,
          beneficiaryName: beneficiary.name,
          readableId: ticket.readableId,
          qrPayload: ticket.qrPayload,
          visibleFieldLines: _visibleFieldLines(beneficiary, customFields),
          monoFont: monoFont,
        ),
      ),
    ),
  );
  return doc;
}

Future<Uint8List> buildSingleTicketPdf({
  required Event event,
  required Ticket ticket,
  required Beneficiary beneficiary,
  required List<CustomField> customFields,
}) async {
  final doc = await buildSingleTicketDocument(
    event: event,
    ticket: ticket,
    beneficiary: beneficiary,
    customFields: customFields,
  );
  return doc.save();
}

Future<pw.Document> buildEventTicketsDocument({
  required Event event,
  required List<Ticket> tickets,
  required Map<int, Beneficiary> beneficiariesById,
  required List<CustomField> customFields,
}) async {
  final sansFont = await _loadFont('assets/fonts/IBMPlexSans-Variable.ttf');
  final monoFont = await _loadFont('assets/fonts/IBMPlexMono-Regular.ttf');
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: sansFont, bold: sansFont),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(_pageMarginMm * PdfPageFormat.mm),
      build: (context) => [
        pw.Wrap(
          spacing: _cardSpacingMm * PdfPageFormat.mm,
          runSpacing: _cardSpacingMm * PdfPageFormat.mm,
          children: [
            for (final ticket in tickets)
              if (beneficiariesById[ticket.beneficiaryId] != null)
                _ticketCardPdf(
                  template: event.ticketTemplate,
                  eventName: event.name,
                  eventLogo: event.logo,
                  beneficiaryName:
                      beneficiariesById[ticket.beneficiaryId]!.name,
                  readableId: ticket.readableId,
                  qrPayload: ticket.qrPayload,
                  visibleFieldLines: _visibleFieldLines(
                    beneficiariesById[ticket.beneficiaryId]!,
                    customFields,
                  ),
                  monoFont: monoFont,
                ),
          ],
        ),
      ],
    ),
  );
  return doc;
}

Future<Uint8List> buildEventTicketsPdf({
  required Event event,
  required List<Ticket> tickets,
  required Map<int, Beneficiary> beneficiariesById,
  required List<CustomField> customFields,
}) async {
  final doc = await buildEventTicketsDocument(
    event: event,
    tickets: tickets,
    beneficiariesById: beneficiariesById,
    customFields: customFields,
  );
  return doc.save();
}
```

(`bold: sansFont` in both `pw.ThemeData.withFont(...)` calls is load-bearing,
not redundant: without it, any `pw.FontWeight.bold` request — the event name
text style above uses one — falls back to the `pdf` package's own
Helvetica-Bold base-14 font, silently reintroducing the exact Latin-1-only
bug this task removes, just for bold text specifically. Passing the same
regular-weight `sansFont` file for both `base` and `bold` means bold
requests render in the correct family with full Unicode coverage, just
without a visually heavier stroke — a strictly better trade than a wrong
font family that cannot render half the alphabet.)

- [ ] **Step 2: Confirm every `_sanitizeForPdf` reference is gone**

Run: `grep -n "_sanitizeForPdf" lib/features/tickets/data/ticket_pdf_builder.dart`
Expected: no matches.

- [ ] **Step 3: Update the direct `buildXDocument` call sites in the test file**

Read `test/features/tickets/data/ticket_pdf_builder_test.dart`. Three tests
call `buildSingleTicketDocument(...)` or `buildEventTicketsDocument(...)`
directly instead of through `buildSingleTicketPdf`/`buildEventTicketsPdf`
(every other test in the file already goes through the
`Future<Uint8List>`-returning wrappers and needs no change). Add `await` to
all three call sites:

```dart
final doc = buildSingleTicketDocument(
```
becomes
```dart
final doc = await buildSingleTicketDocument(
```
in `'produces a valid one-page PDF'` (the `buildSingleTicketPdf` group).

```dart
final doc = buildEventTicketsDocument(
```
becomes
```dart
final doc = await buildEventTicketsDocument(
```
in both `'a single ticket produces exactly one page'` and
`'many more tickets than fit on one page produce multiple pages'` (the
`buildEventTicketsPdf` group).

Grep the file for `buildSingleTicketDocument(` and
`buildEventTicketsDocument(` after editing to confirm every direct call
site (not the ones already going through `buildSingleTicketPdf`/
`buildEventTicketsPdf`) has `await` immediately before it.

- [ ] **Step 4: Run the tests**

Run: `fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart`
Expected: PASS, including the pre-existing
`'does not crash on typographic quotes/apostrophes or non-Latin-1
characters'` test (name `N'Diaye "VIP" Ɔ`) — this is the test proving the
embedded font handles the exact character class that used to become `'?'`.
Do not weaken or remove this test; if it fails, the font embedding is wrong,
not the test.

- [ ] **Step 5: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green. Also run
`grep -rn "buildSingleTicketDocument\|buildEventTicketsDocument" lib/ test/`
and confirm every call site now has `await` in front of it (the analyzer
would already fail on a missing `await` producing a `Future<pw.Document>`
where a `pw.Document` is expected, but double-check explicitly since a
silently-wrong `.then()`-free future misuse can sometimes still compile in
looser contexts).

- [ ] **Step 6: Commit**

```bash
git add lib/features/tickets/data/ticket_pdf_builder.dart test/features/tickets/data/ticket_pdf_builder_test.dart
git commit -m "Embed IBM Plex fonts in ticket PDFs for full Unicode support"
```

---

### Task 4: Events feature — empty/error states, localized errors, confirmations

**Files:**
- Modify: `lib/features/events/presentation/screens/events_list_screen.dart`
- Modify: `lib/features/events/presentation/screens/event_archive_screen.dart`
- Modify: `lib/features/events/presentation/screens/event_form_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/events/presentation/screens/events_list_screen_test.dart`,
  `test/features/events/presentation/screens/event_archive_screen_test.dart`,
  `test/features/events/presentation/screens/event_form_screen_test.dart`
  (existing files — read each before editing, add to it, do not replace it)

**Interfaces:**
- Consumes: `EmptyState`, `ErrorState` from Task 1
  (`lib/shared/widgets/empty_state.dart`).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add new ARB keys**

Add to both `lib/l10n/app_fr.arb` and `lib/l10n/app_en.arb` (French text
without accents, matching the project's existing convention):

```json
  "eventsArchiveError": "Impossible d'archiver cet evenement.",
  "eventsRestoreError": "Impossible de restaurer cet evenement.",
  "eventsDeletePermanentlyError": "Impossible de supprimer cet evenement.",
  "eventFormLoadError": "Impossible de charger cet evenement.",
  "eventFormSaveError": "Impossible d'enregistrer cet evenement."
```
```json
  "eventsArchiveError": "Could not archive this event.",
  "eventsRestoreError": "Could not restore this event.",
  "eventsDeletePermanentlyError": "Could not delete this event.",
  "eventFormLoadError": "Could not load this event.",
  "eventFormSaveError": "Could not save this event."
```

Place `eventsArchiveError` right after `eventsLoadError`,
`eventsRestoreError` right after `eventsRestoreAction`,
`eventsDeletePermanentlyError` right after `eventsDeleteConfirmBody`, and
the two `eventForm*` keys right after `eventFormSaveAction`, matching each
file's existing key grouping by screen.

Run `fvm flutter gen-l10n`.

- [ ] **Step 2: `events_list_screen.dart` — empty/error state, archive confirmation**

Read the current file (reproduced here for reference; this is the file's
current full content before this task's edit):

```dart
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsAction,
            onPressed: () => context.push('/settings'),
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
                onManageBeneficiaries: () =>
                    context.push('/events/${event.id}/beneficiaries'),
                onManageTickets: () =>
                    context.push('/events/${event.id}/tickets'),
                onCheckIn: () => context.push('/events/${event.id}/checkin'),
                onArchive: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(eventRepositoryProvider)
                        .archiveEvent(event.id);
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.eventsLoadError)),
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

Replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsAction,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyState(
              icon: Icons.event_outlined,
              message: l10n.eventsEmptyState,
              actionLabel: l10n.eventsNewAction,
              onAction: () => context.push('/events/new'),
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
                onManageBeneficiaries: () =>
                    context.push('/events/${event.id}/beneficiaries'),
                onManageTickets: () =>
                    context.push('/events/${event.id}/tickets'),
                onCheckIn: () => context.push('/events/${event.id}/checkin'),
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.eventsLoadError,
          onRetry: () => ref.invalidate(activeEventsProvider),
        ),
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

(The archived event disappearing from this list, driven by the underlying
stream, is itself the visible confirmation of a successful archive; the
added haptic is the "leger retour" the design calls for, no new snackbar
text needed on success.)

- [ ] **Step 3: `event_archive_screen.dart` — empty/error state, localized errors**

This is the current full content of
`lib/features/events/presentation/screens/event_archive_screen.dart` before
this task's edit:

```dart
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
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(eventRepositoryProvider)
                                .restoreEvent(event.id);
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('$e')));
                          }
                        },
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
        error: (error, stack) => Center(child: Text(l10n.eventsLoadError)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(eventRepositoryProvider);
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
      try {
        await repository.deleteEventPermanently(event.id);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
```

Replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
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
            return EmptyState(
              icon: Icons.archive_outlined,
              message: l10n.eventsArchiveEmptyState,
            );
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
        error: (error, stack) => ErrorState(
          message: l10n.eventsLoadError,
          onRetry: () => ref.invalidate(archivedEventsProvider),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(eventRepositoryProvider);
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
      try {
        await repository.deleteEventPermanently(event.id);
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsDeletePermanentlyError)),
        );
      }
    }
  }
}
```

- [ ] **Step 4: `event_form_screen.dart` — localized errors, save confirmation**

Read the current file. Add the import `import 'package:flutter/services.dart';`.

Replace the load-error catch block:

```dart
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}
```

(the one inside `_loadExistingEvent`) with:

```dart
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.eventFormLoadError)));
  }
}
```

`_loadExistingEvent` does not currently have an `l10n` local — add
`final l10n = AppLocalizations.of(context)!;` as its first line (it already
has `mounted`/`context` available since it is a State method).

Replace the save success/error handling inside `_save`:

```dart
      if (!mounted) return;
      // Guarded: in a widget test (or any context where this screen is the
      // only route), there is nothing to pop back to.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
```

with:

```dart
      if (!mounted) return;
      HapticFeedback.lightImpact();
      // Guarded: in a widget test (or any context where this screen is the
      // only route), there is nothing to pop back to.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.eventFormSaveError)));
      }
    } finally {
```

(`_save` has no `l10n` local today — `build`'s `l10n` is a separate method
scope. Add `final l10n = AppLocalizations.of(context)!;` as the first line
of `_save`, before `if (!_formKey.currentState!.validate()) return;`.)

- [ ] **Step 5: Update existing widget tests**

Read `test/features/events/presentation/screens/events_list_screen_test.dart`,
`event_archive_screen_test.dart`, and `event_form_screen_test.dart`. If any
test asserts the old raw-text empty/error rendering (e.g.
`find.text('...')` matching the bare message with no icon, or specifically
checking there was no button), update the assertion to match the new
`EmptyState`/`ErrorState` structure (e.g. `find.byIcon(Icons.event_outlined)`
alongside the text, or `find.byType(EmptyState)`). If no existing test
exercises these branches, that is fine — these widgets already have direct
coverage from Task 1's test file; do not add redundant coverage here beyond
confirming the screens still build without error in their existing tests.

- [ ] **Step 6: Run tests**

Run: `fvm flutter test test/features/events/`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/events lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/events
git commit -m "Give the events screens shared empty/error states and localized errors"
```

---

### Task 5: Beneficiaries feature — empty/error states, localized errors, animated CSV success

**Files:**
- Modify: `lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`
- Modify: `lib/features/beneficiaries/presentation/screens/beneficiary_form_screen.dart`
- Modify: `lib/features/beneficiaries/presentation/screens/csv_import_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/beneficiaries/presentation/screens/beneficiaries_list_screen_test.dart`,
  `beneficiary_form_screen_test.dart`, `csv_import_screen_test.dart`
  (existing files — read and extend, do not replace)

**Interfaces:**
- Consumes: `EmptyState`, `ErrorState` from Task 1.

- [ ] **Step 1: Add new ARB keys**

Add to both ARB files, French without accents:

```json
  "beneficiariesDeleteError": "Impossible de supprimer ce beneficiaire.",
  "beneficiaryFormLoadError": "Impossible de charger ce beneficiaire.",
  "beneficiaryFormSaveError": "Impossible d'enregistrer ce beneficiaire.",
  "csvImportPickError": "Impossible de lire ce fichier CSV.",
  "csvImportSaveError": "Impossible d'importer les beneficiaires."
```
```json
  "beneficiariesDeleteError": "Could not delete this beneficiary.",
  "beneficiaryFormLoadError": "Could not load this beneficiary.",
  "beneficiaryFormSaveError": "Could not save this beneficiary.",
  "csvImportPickError": "Could not read this CSV file.",
  "csvImportSaveError": "Could not import beneficiaries."
```

Place `beneficiariesDeleteError` after `beneficiariesLoadError`,
`beneficiaryFormLoadError`/`beneficiaryFormSaveError` after
`beneficiaryFormFieldNumberInvalid`, and the two `csvImport*Error` keys
after `csvImportResult`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: `beneficiaries_list_screen.dart` — empty/error state, localized delete error**

Read the current file. Add
`import '../../../../shared/widgets/empty_state.dart';`.

Replace the empty-state branch:

```dart
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
```

with:

```dart
if (beneficiaries.isEmpty) {
  return EmptyState(
    icon: Icons.people_outline,
    message: l10n.beneficiariesEmptyState,
    actionLabel: l10n.beneficiariesNewAction,
    onAction: () => context.push('/events/$eventId/beneficiaries/new'),
  );
}
```

Replace the error branch:

```dart
error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
```

with:

```dart
error: (error, stack) => ErrorState(
  message: l10n.beneficiariesLoadError,
  onRetry: () => ref.invalidate(beneficiariesProvider(eventId)),
),
```

Replace the raw error in `_confirmDelete`:

```dart
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
```

with:

```dart
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.beneficiariesDeleteError)),
        );
      }
```

- [ ] **Step 3: `beneficiary_form_screen.dart` — localized errors**

Read the current file. Replace the raw error in `_loadExistingBeneficiary`:

```dart
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
```

with:

```dart
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.beneficiaryFormLoadError)));
    }
```

(`_loadExistingBeneficiary` has no `l10n` local today; add
`final l10n = AppLocalizations.of(context)!;` as its first line, before
`try {`.)

Replace the raw error in `_save`:

```dart
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
```

with:

```dart
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.beneficiaryFormSaveError)),
      );
    } finally {
```

(`_save` takes `customFields` as a parameter and has no `l10n` local today;
add `final l10n = AppLocalizations.of(context)!;` as the first line of
`_save`, before `if (!_formKey.currentState!.validate()) return;`.)

- [ ] **Step 4: `csv_import_screen.dart` — localized errors, animated success screen**

Read the current file (reproduced here for reference):

```dart
import 'dart:convert';

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
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final parsed = parseCsvContent(content);
      if (!mounted) return;
      setState(() {
        _headers = parsed.headers;
        _dataRows = parsed.rows;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
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
      if (!mounted) return;
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

Replace it with:

```dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final parsed = parseCsvContent(content);
      if (!mounted) return;
      setState(() {
        _headers = parsed.headers;
        _dataRows = parsed.rows;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvImportPickError)));
    }
  }

  Future<void> _handleImport(List<NewBeneficiary> beneficiaries, int skipped) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported =
          await repository.importBeneficiaries(widget.eventId, beneficiaries);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _importedCount = imported;
        _skippedCount = skipped;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvImportSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_importedCount != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(duration: 300.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Text(l10n.csvImportResult(_importedCount!, _skippedCount!)),
          ],
        ),
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

- [ ] **Step 5: Update existing widget tests**

Read `test/features/beneficiaries/presentation/screens/csv_import_screen_test.dart`.
Whatever test currently asserts the success state (looking for
`l10n.csvImportResult(...)` text after a simulated import), keep that
assertion — the text is unchanged, only an icon was added above it — and
add `await tester.pump(const Duration(milliseconds: 350));` after the state
change so the entrance animation settles before assertions run (matching
how `check_in_scan_screen_test.dart` or similar already handles
`flutter_animate` in this project; check for that pattern and follow it).

- [ ] **Step 6: Run tests**

Run: `fvm flutter test test/features/beneficiaries/`
Expected: PASS.

- [ ] **Step 7: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/beneficiaries lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/beneficiaries
git commit -m "Give the beneficiaries screens shared empty/error states and an animated CSV success screen"
```

---

### Task 6: Tickets feature — empty/error states, localized errors, confirmations

**Files:**
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Modify: `lib/features/tickets/presentation/screens/ticket_preview_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/tickets/presentation/screens/tickets_screen_test.dart`,
  `ticket_preview_screen_test.dart` (existing files — read and extend)

**Interfaces:**
- Consumes: `EmptyState`, `ErrorState` from Task 1.

- [ ] **Step 1: Add new ARB keys**

```json
  "ticketsTemplateUpdateError": "Impossible de changer le modele de ticket.",
  "ticketsGenerateError": "Impossible de generer les tickets.",
  "ticketPreviewShareSuccess": "Ticket partage."
```
```json
  "ticketsTemplateUpdateError": "Could not change the ticket template.",
  "ticketsGenerateError": "Could not generate tickets.",
  "ticketPreviewShareSuccess": "Ticket shared."
```

Place the two `tickets*Error` keys after `ticketsExportError`, and
`ticketPreviewShareSuccess` after `ticketPreviewShareError`. Run
`fvm flutter gen-l10n`.

- [ ] **Step 2: `tickets_screen.dart` — empty/error states, localized errors, generate confirmation**

Read the current file. Add imports
`import 'package:flutter/services.dart';` and
`import '../../../../shared/widgets/empty_state.dart';`.

Replace the combined loading-error branch:

```dart
      body: eventAsync.hasError ||
              beneficiariesAsync.hasError ||
              customFieldsAsync.hasError
          ? Center(child: Text(l10n.ticketsLoadError))
          : Padding(
```

with:

```dart
      body: eventAsync.hasError ||
              beneficiariesAsync.hasError ||
              customFieldsAsync.hasError
          ? ErrorState(
              message: l10n.ticketsLoadError,
              onRetry: () {
                ref.invalidate(eventProvider(eventId));
                ref.invalidate(beneficiariesProvider(eventId));
                ref.invalidate(customFieldsProvider(eventId));
              },
            )
          : Padding(
```

Replace the raw error in the template `onSelectionChanged` handler:

```dart
                        } catch (e) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text('$e')));
                        }
```

with:

```dart
                        } catch (e) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.ticketsTemplateUpdateError)),
                          );
                        }
```

Replace the tickets-list empty state:

```dart
                        if (tickets.isEmpty) {
                          return Center(
                            child: Text(
                              l10n.ticketsEmptyState,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        }
```

with:

```dart
                        if (tickets.isEmpty) {
                          return EmptyState(
                            icon: Icons.confirmation_number_outlined,
                            message: l10n.ticketsEmptyState,
                          );
                        }
```

Replace the tickets-list error branch:

```dart
                      error: (error, stack) =>
                          Center(child: Text(l10n.ticketsLoadError)),
```

with:

```dart
                      error: (error, stack) => ErrorState(
                        message: l10n.ticketsLoadError,
                        onRetry: () => ref.invalidate(ticketsProvider(eventId)),
                      ),
```

Replace the generate-confirmation success and error handling in
`_confirmGenerate`:

```dart
    if (confirmed != true) return;
    try {
      final created = await ref
          .read(ticketRepositoryProvider)
          .generateMissingTickets(eventId);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsGeneratedCount(created))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
```

with:

```dart
    if (confirmed != true) return;
    try {
      final created = await ref
          .read(ticketRepositoryProvider)
          .generateMissingTickets(eventId);
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.ticketsGeneratedCount(created))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ticketsGenerateError)));
    }
  }
```

- [ ] **Step 3: `ticket_preview_screen.dart` — share confirmation**

Read the current file. Add `import 'package:flutter/services.dart';`.

Replace the success path of `_shareTicket`:

```dart
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${ticket.readableId}.pdf',
      );
    } catch (e) {
```

with:

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

(the existing `error:` branches at lines 57 and 88, both already using
`l10n.ticketsLoadError`, are left as `Center(child: Text(...))` — they are
detail-screen error states after navigating to a specific ticket, not a
list; converting them to `ErrorState` is optional polish, not required by
this task, since there is no natural single "retry" provider to invalidate
without knowing which of the three nested providers failed. Leave them
as-is unless the polish pass in Task 8 finds a clean way to do it.)

- [ ] **Step 4: Update existing widget tests**

Read `test/features/tickets/presentation/screens/tickets_screen_test.dart`
and `ticket_preview_screen_test.dart`. Update any assertion that depended on
the exact prior widget tree for the empty/error states (e.g. bare
`find.text(...)` with no icon). Add a test (or extend an existing one) in
`ticket_preview_screen_test.dart` asserting that after a successful share,
`l10n.ticketPreviewShareSuccess` text appears in a `SnackBar` — the existing
test setup for this screen likely already stubs `Printing.sharePdf` or
similar for its current share-error test; reuse that stub for the success
path instead of building a new one.

- [ ] **Step 5: Run tests**

Run: `fvm flutter test test/features/tickets/`
Expected: PASS.

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tickets lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/tickets
git commit -m "Give the tickets screens shared empty/error states, localized errors, and share confirmation"
```

---

### Task 7: `SettingsScreen` — injectable file picker, missing tests, export confirmation

**Files:**
- Modify: `lib/features/backup/presentation/screens/settings_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/backup/presentation/screens/settings_screen_test.dart`
  (existing file — extend, do not replace)

**Interfaces:**
- Produces: `SettingsScreen({Future<PlatformFile?> Function({FileType type, List<String>? allowedExtensions}) pickFile = FilePicker.pickFile, Key? key})` — a new optional constructor parameter with `FilePicker.pickFile` as its default, so tests can inject a fake.

- [ ] **Step 1: Add new ARB key**

```json
  "settingsExportSuccess": "Sauvegarde exportee."
```
```json
  "settingsExportSuccess": "Backup exported."
```

Place it right after `settingsExportError`. Run `fvm flutter gen-l10n`.

- [ ] **Step 2: Write the failing tests**

Read `test/features/backup/presentation/screens/settings_screen_test.dart`
in full first (it currently has one test, "shows the export and import
actions, both enabled"). Add these tests to the same file, reusing whatever
provider-override/wrapper setup the existing test already uses (read it to
match the pattern exactly rather than inventing a new one):

```dart
testWidgets('disables both buttons while an import is in progress', (
  tester,
) async {
  final completer = Completer<PlatformFile?>();
  await tester.pumpWidget(
    _wrap(SettingsScreen(pickFile: ({type, allowedExtensions}) => completer.future)),
    // (reuse this test file's existing ProviderScope/override wrapper here
    // instead of a bare _wrap if one already exists; match the file's own
    // established helper, this is illustrative of the assertions needed,
    // not a mandate to introduce a second wrapper helper)
  );

  await tester.tap(find.text('Import backup'));
  await tester.pump();

  expect(
    tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
    isNull,
  );
  expect(
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
    isNull,
  );

  completer.complete(null);
  await tester.pumpAndSettle();
});

testWidgets('cancelling the confirm dialog does not call importBackup', (
  tester,
) async {
  var importCalled = false;
  // Override backupRepositoryProvider with a fake BackupRepository whose
  // importBackup() sets importCalled = true, and pickFile returning a
  // PlatformFile for a fixed, tiny valid-looking byte array so the
  // confirm dialog is reached. Read this test file's existing overrides
  // (it already provides a backupRepositoryProvider fake for its export
  // test) and extend that fake rather than building a second one.

  await tester.tap(find.text('Import backup'));
  await tester.pumpAndSettle();
  expect(find.text('Cancel'), findsOneWidget);

  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  expect(importCalled, isFalse);
});
```

(These two illustrate the exact behavior the jalon 7 design asked for and
never got: button disabled while processing, and cancel not touching the
repository. Read the existing test file's fakes/wrappers first and write
these two tests to fit that file's established structure rather than a
literal copy of the sketch above — the sketch is here to specify the
required assertions, not the exact helper plumbing.)

- [ ] **Step 3: Run tests to verify they fail**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: FAIL (`SettingsScreen` has no `pickFile` parameter yet).

- [ ] **Step 4: Make `pickFile` injectable, add export confirmation**

Read the current `lib/features/backup/presentation/screens/settings_screen.dart`
(reproduced here for reference; this is its current full content before
this task's edit):

```dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/backup_providers.dart';
import '../widgets/import_confirm_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final bytes = await repository.exportBackup();
      final tempDir = await getTemporaryDirectory();
      final dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final exportFile = File(
        p.join(tempDir.path, 'dif-pass-sauvegarde-$dateLabel.sqlite'),
      );
      await exportFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(exportFile.path)]),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsExportError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    // Captured before any await: ProviderScope.containerOf needs a mounted
    // context, and the container (unlike ref) stays safe to call
    // invalidate() on even if this widget gets disposed while the import
    // is in flight (e.g. the user navigates away mid-import).
    final container = ProviderScope.containerOf(context, listen: false);

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['sqlite', 'db'],
    );
    if (file == null) return;
    if (!mounted) return;

    final confirmed = await showImportConfirmDialog(context);
    if (!confirmed) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final repository = await ref.read(backupRepositoryProvider.future);
      await ref.read(appDatabaseProvider).close();
      await repository.importBackup(bytes);
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_outlined),
              label: Text(l10n.settingsExportAction),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.settingsImportAction),
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
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/backup_providers.dart';
import '../widgets/import_confirm_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({this.pickFile = FilePicker.pickFile, super.key});

  // Injectable for tests: FilePicker.pickFile talks to the platform and
  // cannot be exercised in flutter test, same reason AppDatabase.forTesting
  // exists as its own constructor (jalon 7). Every other screen that calls
  // FilePicker.pickFile in this app calls it directly and stays untested at
  // that boundary; this screen is the one exception because the sequence
  // that follows the picked file (close db, import, invalidate, navigate)
  // is the most failure-sensitive code in the app, per jalon 7's review.
  final Future<PlatformFile?> Function({
    FileType type,
    List<String>? allowedExtensions,
  }) pickFile;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final bytes = await repository.exportBackup();
      final tempDir = await getTemporaryDirectory();
      final dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final exportFile = File(
        p.join(tempDir.path, 'dif-pass-sauvegarde-$dateLabel.sqlite'),
      );
      await exportFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(exportFile.path)]),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsExportError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    // Captured before any await: ProviderScope.containerOf needs a mounted
    // context, and the container (unlike ref) stays safe to call
    // invalidate() on even if this widget gets disposed while the import
    // is in flight (e.g. the user navigates away mid-import).
    final container = ProviderScope.containerOf(context, listen: false);

    final file = await widget.pickFile(
      type: FileType.custom,
      allowedExtensions: ['sqlite', 'db'],
    );
    if (file == null) return;
    if (!mounted) return;

    final confirmed = await showImportConfirmDialog(context);
    if (!confirmed) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final repository = await ref.read(backupRepositoryProvider.future);
      await ref.read(appDatabaseProvider).close();
      await repository.importBackup(bytes);
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      context.go('/');
    } catch (e) {
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_outlined),
              label: Text(l10n.settingsExportAction),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.settingsImportAction),
            ),
          ],
        ),
      ),
    );
  }
}
```

(The only behavioral change beyond the injectable `pickFile` and the export
success snackbar/haptic: `_import` now calls `widget.pickFile(...)` instead
of the static `FilePicker.pickFile(...)`. The default value makes this a
no-op change for production code — `SettingsScreen()` with no arguments
behaves exactly as before.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `fvm flutter test test/features/backup/presentation/screens/settings_screen_test.dart`
Expected: PASS (original test plus the two new ones).

- [ ] **Step 6: Run the full suite and analyzer**

Run: `fvm flutter test` and `fvm flutter analyze`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/backup/presentation/screens/settings_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations*.dart test/features/backup/presentation/screens/settings_screen_test.dart
git commit -m "Make SettingsScreen's file picker injectable and cover the import sequence"
```

---

### Task 8: Visual polish pass

**Files:** Determined during the task, scoped to `lib/features/**/presentation/**`
and `lib/core/theme/**` — no new files expected, only spacing/style
adjustments to existing screens.

**Interfaces:** None (pure visual adjustments, no signature changes).

This task runs last because it depends on every other task: the real DIF
fonts (Task 2) change the visual hierarchy on every screen, and the shared
`EmptyState`/`ErrorState` (Tasks 1, 4-6) change several screens' layouts.
Reviewing before those land would mean reviewing against fonts and layouts
that are about to change anyway.

- [ ] **Step 1: Load the `frontend-design` skill**

Invoke it before making any change in this task.

- [ ] **Step 2: Read every screen under `lib/features/*/presentation/screens/`**

For each, check against the DIF Pass design tokens (Ink `#1B1F3B`, Paper
`#F0F1F5`, Ochre `#E8A33D`, Teal `#1F6E5C`, Indigo `#5B6EE8`,
`lib/core/theme/app_colors.dart`) and the now-real typography (Big
Shoulders Display for display/headline/titleLarge, IBM Plex Sans
elsewhere, IBM Plex Mono for ticket identifiers/counters) for: inconsistent
padding/spacing between visually-equivalent screens, text styles picked ad
hoc instead of from `Theme.of(context).textTheme`, colors hardcoded instead
of referencing `AppColors`/`colorScheme`, and any layout that visibly
misuses the display font now that it renders correctly (e.g. a heading that
reads better at a different `textTheme` slot than the one it was using with
the fallback system font).

- [ ] **Step 3: Apply and commit each fix set**

Group related fixes into small commits (e.g. "Align empty-state and card
padding across list screens", "Use textTheme slots consistently on the
event form"), each with `fvm flutter test` and `fvm flutter analyze` green
before committing. Do not restructure any screen's layout wholesale — this
is a consistency pass, not a redesign (per the design doc's explicit
"hors perimetre": no new layouts, no new flows).

If no fix is warranted anywhere (the existing per-screen use of
`frontend-design` across jalons 1-7 already left the app consistent), say so
explicitly and skip to Task 9 rather than inventing changes.

---

### Task 9: Full milestone verification

**Files:** None (verification only).

- [ ] **Step 1: Run the full test suite**

Run: `fvm flutter test`
Expected: all tests pass, including every new test added in Tasks 1-7.

- [ ] **Step 2: Run the analyzer**

Run: `fvm flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 3: Confirm `google_fonts` is fully gone**

Run: `grep -rn "google_fonts\|GoogleFonts" lib/ pubspec.yaml`
Expected: no matches (Task 2 removed the dependency and its usage in
`app_typography.dart`/`main.dart`; Task 3 removed it from
`ticket_pdf_builder.dart`).

- [ ] **Step 4: Confirm no raw exception text remains**

Run: `grep -rn "Text('\\\$e')" lib/`
Expected: no matches (every catch block identified in the design doc's
"Decisions actees" section now shows a localized message instead).

- [ ] **Step 5: Confirm every ARB key added in this plan exists in both locales**

Run: `fvm dart run build_runner build --delete-conflicting-outputs` is not
needed here (l10n is not build_runner-generated in this project); instead
run `fvm flutter gen-l10n` once more and confirm it exits 0 with no
"missing translation" warnings for any new key.

- [ ] **Step 6: Report readiness**

This is the last task of the last jalon in the cahier des charges. Report
the final test count, confirm analyzer is clean, and note that physical
device verification (the Tecno CE9 that originally surfaced the font
defect) is a manual step for whoever is driving this plan to run
afterward, not something this task automates — launching the app on a
device requires explicit confirmation each time per this project's
standing process, independent of this plan.
