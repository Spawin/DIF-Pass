# Jalon 5 - Export/partage - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a PDF export of all tickets for an event (grid layout on A4, ready to print, laid out differently per ticket template) and native sharing of a single ticket as a one-page PDF. This is the last piece of the cahier des charges' section 3 (Tickets), started in jalon 4.

**Architecture:** A single new pure-ish builder module, `lib/features/tickets/data/ticket_pdf_builder.dart`, renders `Ticket`/`Event`/`Beneficiary`/`CustomField` domain data into PDF documents using the `pdf` package's own widget system (`pw.*`), independent of Drift and Riverpod. `TicketsScreen` and `TicketPreviewScreen` (both from jalon 4) each gain one AppBar icon that calls this builder and hands the resulting bytes to the `printing` package (`Printing.layoutPdf` for the bulk export, `Printing.sharePdf` for the individual share). No new screens, no new routes.

**Tech Stack:** Flutter 3.44.7 (FVM) + `pdf` (already a dependency since jalon 1, provides the QR barcode widget too via the `barcode` package it re-exports) + `printing` (already a dependency since jalon 1).

## Global Constraints

- Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Never hand-edit generated `.g.dart` or generated localization files.
- No em dashes in code, comments, or commit messages.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits.
- No file starts with a `// path/to/file.dart` first-line comment.
- No new dependency needed anywhere in this jalon: `pdf` and `printing` are already in `pubspec.yaml` (added in jalon 1), and both the QR barcode widget (`pw.BarcodeWidget`/`pw.Barcode`) and `PdfColor`/`PdfPageFormat` come from packages `pdf` and `printing` already depend on. Do not add `barcode`, `share_plus` usage, or any other package to this feature.
- Never call `pdfDefaultTheme()` (from `package:printing`) or any `PdfGoogleFonts.*` method. Both fetch font files from `fonts.gstatic.com` over the network at first use, which breaks this project's offline-first requirement (the same requirement that made jalon 1 disable `google_fonts`' runtime fetching for the Flutter UI). Rely on the `pdf` package's built-in base-14 fonts (`pw.Font.helvetica()`, `pw.Font.helveticaBold()`, `pw.Font.courier()`, used implicitly as the default or explicitly where noted below), which need no assets and no network access.
- `Printing.layoutPdf`/`Printing.sharePdf` are platform integrations. Following this project's established convention (the `file_picker` call in jalon 3's CSV import is tested the same way), widget tests verify the triggering button's presence and enabled/disabled state, not the native call itself.

---

### Task 1: Ticket card PDF renderer and single-ticket export

**Context:** This task creates the new `ticket_pdf_builder.dart` module and its single-ticket entry point, `buildSingleTicketPdf`. It also creates the private per-template card widget (`_ticketCardPdf`) that Task 2's bulk export will reuse. `TicketPreviewScreen`'s `_TicketCard` (jalon 4, Flutter widgets) is the visual reference for what this card should show; this is the same content rendered with `pw.*` widgets instead, since the PDF engine does not use the Flutter widget tree.

**Files:**
- Create: `lib/features/tickets/data/ticket_pdf_builder.dart`
- Test: `test/features/tickets/data/ticket_pdf_builder_test.dart`

**Interfaces:**
- Consumes: `Ticket` (`lib/features/tickets/domain/ticket.dart`), `Event`/`TicketTemplate` (`lib/features/events/domain/event.dart`, `lib/features/events/domain/ticket_template.dart`), `Beneficiary` (`lib/features/beneficiaries/domain/beneficiary.dart`), `CustomField` (`lib/features/events/domain/custom_field.dart`).
- Produces: `Future<Uint8List> buildSingleTicketPdf({required Event event, required Ticket ticket, required Beneficiary beneficiary, required List<CustomField> customFields})`. Also `pw.Document buildSingleTicketDocument({...})` (same parameters, returns the document before serialization) so this task's own tests can inspect the page count without re-parsing bytes; `buildSingleTicketPdf` is a one-line wrapper that calls `.save()` on it. Task 3 depends on `buildSingleTicketPdf`. Task 2 depends on the private helpers this task creates in the same file (`_ticketCardPdf`, `_cardWidthMm`, `_cardMinHeightMm`, `_visibleFieldLines`, `_indigo`, `_pageMarginMm`, `_cardSpacingMm`) and will edit this same file to add its own public functions alongside these.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/tickets/data/ticket_pdf_builder_test.dart
import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/domain/ticket_template.dart';
import 'package:dif_pass/features/tickets/data/ticket_pdf_builder.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event({TicketTemplate template = TicketTemplate.standard}) {
  return Event(
    id: 1,
    shortCode: 'EVT1',
    name: 'Gala DIF 2026',
    date: DateTime(2026, 12, 1),
    presenceMode: PresenceMode.simple,
    ticketTemplate: template,
    createdAt: DateTime(2026, 1, 1),
  );
}

Beneficiary _beneficiary({Map<int, String> customFieldValues = const {}}) {
  return Beneficiary(
    id: 1,
    eventId: 1,
    name: 'Jane Doe',
    customFieldValues: customFieldValues,
    createdAt: DateTime(2026, 1, 1),
  );
}

Ticket _ticket() {
  return Ticket(
    id: 1,
    beneficiaryId: 1,
    eventId: 1,
    readableId: '0001',
    randomPart: 'ABCD',
    qrPayload: 'EVT1-0001-ABCD',
    createdAt: DateTime(2026, 1, 1),
  );
}

bool _isPdf(List<int> bytes) =>
    bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';

void main() {
  group('buildSingleTicketPdf', () {
    test('produces a valid one-page PDF', () async {
      final doc = buildSingleTicketDocument(
        event: _event(),
        ticket: _ticket(),
        beneficiary: _beneficiary(),
        customFields: const [],
      );
      final bytes = await doc.save();

      expect(_isPdf(bytes), isTrue);
      expect(doc.document.pdfPageList.pages.length, 1);
    });

    test('does not crash when a shown custom field has no value', () async {
      final bytes = await buildSingleTicketPdf(
        event: _event(),
        ticket: _ticket(),
        beneficiary: _beneficiary(),
        customFields: const [
          CustomField(
            id: 1,
            eventId: 1,
            label: 'Table number',
            type: CustomFieldType.text,
            sortOrder: 0,
            showOnTicket: true,
          ),
        ],
      );

      expect(_isPdf(bytes), isTrue);
    });

    test('only includes custom fields checked showOnTicket', () async {
      final bytes = await buildSingleTicketPdf(
        event: _event(),
        ticket: _ticket(),
        beneficiary: _beneficiary(
          customFieldValues: {1: 'Table 5', 2: 'VIP'},
        ),
        customFields: const [
          CustomField(
            id: 1,
            eventId: 1,
            label: 'Table number',
            type: CustomFieldType.text,
            sortOrder: 0,
            showOnTicket: true,
          ),
          CustomField(
            id: 2,
            eventId: 1,
            label: 'Internal note',
            type: CustomFieldType.text,
            sortOrder: 1,
            showOnTicket: false,
          ),
        ],
      );

      expect(_isPdf(bytes), isTrue);
    });

    for (final template in TicketTemplate.values) {
      test('produces a valid document for the ${template.name} template', () async {
        final bytes = await buildSingleTicketPdf(
          event: _event(template: template),
          ticket: _ticket(),
          beneficiary: _beneficiary(),
          customFields: const [],
        );

        expect(_isPdf(bytes), isTrue);
      });
    }
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart
```

Expected: FAIL (`ticket_pdf_builder.dart` does not exist).

- [ ] **Step 3: Implement the builder**

```dart
// lib/features/tickets/data/ticket_pdf_builder.dart
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
      border: isElegant ? pw.Border.all(color: _indigo, width: 1.5) : null,
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
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart
```

Expected: PASS (all 6 tests: one-page check, no-value custom field, filtered custom field, one test per `TicketTemplate` value).

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/data/ticket_pdf_builder.dart test/features/tickets/data/ticket_pdf_builder_test.dart
git commit -m "Add the ticket PDF card renderer and single-ticket export"
```

---

### Task 2: Bulk PDF export for all tickets of an event

**Context:** Adds `buildEventTicketsPdf` to the same `ticket_pdf_builder.dart` file Task 1 created, reusing its private `_ticketCardPdf`/`_cardWidthMm`/`_visibleFieldLines` helpers. Cards are placed in a `pw.Wrap` (each card has a fixed width, so `pw.Wrap` computes on its own how many fit per line) inside a `pw.MultiPage` (`pw.Wrap` implements the pagination protocol `pw.MultiPage` uses, so the grid flows across as many pages as needed with no manual column or page-count math in this codebase).

**Files:**
- Modify: `lib/features/tickets/data/ticket_pdf_builder.dart`
- Test: `test/features/tickets/data/ticket_pdf_builder_test.dart` (append to the existing file)

**Interfaces:**
- Consumes: the private helpers from Task 1, in the same file.
- Produces: `Future<Uint8List> buildEventTicketsPdf({required Event event, required List<Ticket> tickets, required Map<int, Beneficiary> beneficiariesById, required List<CustomField> customFields})` and `pw.Document buildEventTicketsDocument({...})` (same parameters, pre-`save()`, for this task's page-count tests). Task 4 depends on `buildEventTicketsPdf`.

- [ ] **Step 1: Write the failing test**

Append to the existing test file, inside `main()`, after the `buildSingleTicketPdf` group:

```dart
// test/features/tickets/data/ticket_pdf_builder_test.dart (append inside main())
group('buildEventTicketsPdf', () {
  test('a single ticket produces exactly one page', () async {
    final beneficiary = _beneficiary();
    final doc = buildEventTicketsDocument(
      event: _event(),
      tickets: [_ticket()],
      beneficiariesById: {beneficiary.id: beneficiary},
      customFields: const [],
    );
    await doc.save();

    expect(doc.document.pdfPageList.pages.length, 1);
  });

  test(
    'many more tickets than fit on one page produce multiple pages',
    () async {
      final beneficiary = _beneficiary();
      // Comfortably more than the compact template's estimated columns per
      // A4 page (see docs/superpowers/specs/2026-08-29-jalon-5-export-partage-design.md),
      // to prove pw.Wrap/pw.MultiPage actually paginate rather than
      // overflow silently or throw.
      final tickets = [
        for (var i = 1; i <= 40; i++)
          Ticket(
            id: i,
            beneficiaryId: beneficiary.id,
            eventId: 1,
            readableId: i.toString().padLeft(4, '0'),
            randomPart: 'ABCD',
            qrPayload: 'EVT1-${i.toString().padLeft(4, '0')}-ABCD',
            createdAt: DateTime(2026, 1, 1),
          ),
      ];
      final doc = buildEventTicketsDocument(
        event: _event(template: TicketTemplate.compact),
        tickets: tickets,
        beneficiariesById: {beneficiary.id: beneficiary},
        customFields: const [],
      );
      await doc.save();

      expect(doc.document.pdfPageList.pages.length, greaterThan(1));
    },
  );

  test('a ticket with no matching beneficiary is skipped, not a crash', () async {
    final doc = buildEventTicketsDocument(
      event: _event(),
      tickets: [_ticket()],
      beneficiariesById: const {},
      customFields: const [],
    );
    final bytes = await doc.save();

    expect(_isPdf(bytes), isTrue);
    expect(doc.document.pdfPageList.pages.length, 1);
  });

  for (final template in TicketTemplate.values) {
    test('produces a valid document for the ${template.name} template', () async {
      final beneficiary = _beneficiary();
      final bytes = await buildEventTicketsPdf(
        event: _event(template: template),
        tickets: [_ticket()],
        beneficiariesById: {beneficiary.id: beneficiary},
        customFields: const [],
      );

      expect(_isPdf(bytes), isTrue);
    });
  }
});
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart
```

Expected: FAIL (`buildEventTicketsDocument`/`buildEventTicketsPdf` do not exist).

- [ ] **Step 3: Implement the bulk export functions**

Append to `lib/features/tickets/data/ticket_pdf_builder.dart`, after `buildSingleTicketPdf`:

```dart
// lib/features/tickets/data/ticket_pdf_builder.dart (append)
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

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/data/ticket_pdf_builder_test.dart
```

Expected: PASS (all tests in the file, both groups).

- [ ] **Step 5: Commit**

```bash
git add lib/features/tickets/data/ticket_pdf_builder.dart test/features/tickets/data/ticket_pdf_builder_test.dart
git commit -m "Add the bulk PDF export for all tickets of an event"
```

---

### Task 3: Share a single ticket as a PDF from the preview screen

**Files:**
- Modify: `lib/features/tickets/presentation/screens/ticket_preview_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/tickets/presentation/screens/ticket_preview_screen_test.dart` (append to the existing file)

**Interfaces:**
- Consumes: `buildSingleTicketPdf` (Task 1); `Printing.sharePdf` (`package:printing/printing.dart`); `beneficiaryProvider`, `eventProvider`, `customFieldsProvider` (jalon 4, already watched elsewhere in this file, now also read via `ref.read(...future)` in the new method).
- Produces: `TicketPreviewScreen`'s AppBar gains a share `IconButton`.

- [ ] **Step 1: Add the ARB key this change needs**

```json
// lib/l10n/app_en.arb (add these keys; ticketPreviewTitle already exists and needs a trailing comma now that another key follows it)
{
  "ticketsExportAction": "Export tickets",
  "ticketPreviewTitle": "Ticket",
  "ticketPreviewShareAction": "Share ticket"
}
```

The `ticketsExportAction` key is added here because it shares the same insertion point in the file as `ticketPreviewTitle`; Task 4 is the one that actually uses it. Concretely, the tail of `lib/l10n/app_en.arb` becomes:

```json
  "ticketsGeneratedCount": "{count, plural, =1{1 ticket created} other{{count} tickets created}}",
  "@ticketsGeneratedCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "ticketsExportAction": "Export tickets",
  "ticketPreviewTitle": "Ticket",
  "ticketPreviewShareAction": "Share ticket"
}
```

And the tail of `lib/l10n/app_fr.arb` becomes:

```json
  "ticketsGeneratedCount": "{count, plural, =1{1 ticket cree} other{{count} tickets crees}}",
  "ticketsExportAction": "Exporter les tickets",
  "ticketPreviewTitle": "Ticket",
  "ticketPreviewShareAction": "Partager le ticket"
}
```

Regenerate:

```bash
fvm flutter gen-l10n
```

- [ ] **Step 2: Write the failing test**

Append to the existing test file, inside `main()`:

```dart
// test/features/tickets/presentation/screens/ticket_preview_screen_test.dart (append inside main())
testWidgets('shows an enabled share action once the ticket is loaded', (
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

  final button = tester.widget<IconButton>(find.byTooltip('Share ticket'));
  expect(button.onPressed, isNotNull);
});
```

- [ ] **Step 3: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
```

Expected: FAIL (no widget with tooltip "Share ticket" exists yet).

- [ ] **Step 4: Add the share button**

Replace the import block at the top of `lib/features/tickets/presentation/screens/ticket_preview_screen.dart` with:

```dart
// lib/features/tickets/presentation/screens/ticket_preview_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../data/ticket_pdf_builder.dart';
import '../../domain/ticket.dart';
import '../providers/ticket_providers.dart';
```

Replace the `Scaffold(...)` returned by `build` so its `appBar` gains a share action (only the `appBar:` line changes, `body:` stays exactly as it is):

```dart
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ticketPreviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.ticketPreviewShareAction,
            onPressed: ticketAsync.hasValue
                ? () => _shareTicket(context, ref, ticketAsync.value!)
                : null,
          ),
        ],
      ),
      body: ticketAsync.when(
```

Add this method to the `TicketPreviewScreen` class, after `build`:

```dart
  Future<void> _shareTicket(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final beneficiary = await ref.read(
        beneficiaryProvider(ticket.beneficiaryId).future,
      );
      final event = await ref.read(eventProvider(ticket.eventId).future);
      final customFields = await ref.read(
        customFieldsProvider(ticket.eventId).future,
      );
      final bytes = await buildSingleTicketPdf(
        event: event,
        ticket: ticket,
        beneficiary: beneficiary,
        customFields: customFields,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${ticket.readableId}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
```

- [ ] **Step 5: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
```

Expected: PASS (all tests in the file).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n lib/features/tickets/presentation/screens/ticket_preview_screen.dart test/features/tickets/presentation/screens/ticket_preview_screen_test.dart
git commit -m "Add sharing a ticket as a PDF from the preview screen"
```

---

### Task 4: Export all tickets of an event as a PDF, full milestone check

**Files:**
- Modify: `lib/features/tickets/presentation/screens/tickets_screen.dart`
- Test: `test/features/tickets/presentation/screens/tickets_screen_test.dart` (append to the existing file)

**Interfaces:**
- Consumes: `buildEventTicketsPdf` (Task 2); `Printing.layoutPdf` (`package:printing/printing.dart`); `ticketsExportAction` (Task 3 already added this ARB key).
- Produces: `TicketsScreen`'s AppBar gains an export `IconButton`. This is the last task of the milestone.

- [ ] **Step 1: Write the failing test**

Append to the existing test file, inside `main()`:

```dart
// test/features/tickets/presentation/screens/tickets_screen_test.dart (append inside main())
testWidgets('export action is disabled when there are no tickets', (
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
    beneficiaryIdsForEvent: (eventId) => fakeBeneficiaries.beneficiaries
        .where((b) => b.eventId == eventId)
        .map((b) => b.id)
        .toList(),
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

  final button = tester.widget<IconButton>(find.byTooltip('Export tickets'));
  expect(button.onPressed, isNull);
});

testWidgets('export action is enabled once at least one ticket exists', (
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

  await tester.pumpWidget(
    _wrap(
      const TicketsScreen(eventId: 1),
      _fakeEventsWithOneEvent(),
      fakeBeneficiaries,
      fakeTickets,
    ),
  );
  await tester.pumpAndSettle();

  final button = tester.widget<IconButton>(find.byTooltip('Export tickets'));
  expect(button.onPressed, isNotNull);
});
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart
```

Expected: FAIL (no widget with tooltip "Export tickets" exists yet).

- [ ] **Step 3: Add the export button**

Replace the import block at the top of `lib/features/tickets/presentation/screens/tickets_screen.dart` with:

```dart
// lib/features/tickets/presentation/screens/tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/domain/beneficiary.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/domain/custom_field.dart';
import '../../../events/domain/event.dart';
import '../../../events/domain/ticket_template.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../data/ticket_pdf_builder.dart';
import '../../domain/ticket.dart';
import '../providers/ticket_providers.dart';
```

In the `build` method, right after the existing `final ticketsAsync = ref.watch(ticketsProvider(eventId));` line, add:

```dart
    final customFieldsAsync = ref.watch(customFieldsProvider(eventId));
```

Right after the existing `final canGenerate = beneficiaries.length > tickets.length;` line, add:

```dart
    final customFields = customFieldsAsync.valueOrNull ?? const [];
    final beneficiariesById = {
      for (final beneficiary in beneficiaries) beneficiary.id: beneficiary,
    };
    final canExport = event != null && tickets.isNotEmpty;
```

Change the `AppBar(...)` (currently only has a `title:`) to also have an `actions:` list:

```dart
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.ticketsScreenTitle),
              Text(event.name, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          loading: () => Text(l10n.ticketsScreenTitle),
          error: (_, _) => Text(l10n.ticketsScreenTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: l10n.ticketsExportAction,
            onPressed: canExport
                ? () => _exportAllTickets(
                      context,
                      event!,
                      tickets,
                      beneficiariesById,
                      customFields,
                    )
                : null,
          ),
        ],
      ),
```

Change the `body:` guard condition to also account for `customFieldsAsync`:

```dart
      body: eventAsync.hasError ||
              beneficiariesAsync.hasError ||
              customFieldsAsync.hasError
          ? Center(child: Text(l10n.ticketsLoadError))
          : Padding(
```

Add this method to the `TicketsScreen` class, after `_confirmGenerate`:

```dart
  Future<void> _exportAllTickets(
    BuildContext context,
    Event event,
    List<Ticket> tickets,
    Map<int, Beneficiary> beneficiariesById,
    List<CustomField> customFields,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await buildEventTicketsPdf(
        event: event,
        tickets: tickets,
        beneficiariesById: beneficiariesById,
        customFields: customFields,
      );
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'tickets-${event.shortCode}',
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/features/tickets/presentation/screens/tickets_screen_test.dart
```

Expected: PASS (all tests in the file, including the 4 pre-existing ones).

- [ ] **Step 5: Run the full suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests pass, analyzer reports no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tickets/presentation/screens/tickets_screen.dart test/features/tickets/presentation/screens/tickets_screen_test.dart
git commit -m "Add exporting all tickets of an event as a printable PDF"
```

---

## Milestone acceptance

Jalon 5 (Export/partage) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and from an event's Tickets screen an organizer can tap the export icon to get a print-ready PDF grid of every generated ticket (laid out differently depending on the chosen template), and from any single ticket's preview screen can tap the share icon to send that one ticket as a PDF through the device's native share sheet (WhatsApp, email, SMS, or any other installed app).
