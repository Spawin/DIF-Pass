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

// ponytail: IBM Plex Sans does not cover every Unicode codepoint (verified:
// it lacks U+0186, used in some West African orthographies, e.g. Ewe). The
// pdf package renders a visible crossed-box placeholder for a codepoint it
// cannot draw, not a silent gap and not a crash, so this is left as a known
// limitation rather than adding a fallback font for one character with no
// reported real-world case yet. Upgrade path if it becomes one: pass a
// broader-coverage font via TextStyle.fontFallback on the affected text.
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
  Uint8List? beneficiaryPhoto,
  required String readableId,
  required String qrPayload,
  required List<String> visibleFieldLines,
  required pw.Font monoFont,
}) {
  final isCompact = template == TicketTemplate.compact;
  final isElegant = template == TicketTemplate.elegant;
  final qrSizeMm = isCompact ? 20.0 : 28.0;

  // An undecodable photo (e.g. from a hand-modified backup) must not abort
  // the whole export: skip just this card's photo instead of throwing.
  pw.MemoryImage? photoImage;
  if (beneficiaryPhoto != null) {
    try {
      photoImage = pw.MemoryImage(beneficiaryPhoto);
    } catch (_) {
      photoImage = null;
    }
  }

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
        if (photoImage != null) ...[
          pw.Container(
            width: (isCompact ? 12 : 16) * PdfPageFormat.mm,
            height: (isCompact ? 12 : 16) * PdfPageFormat.mm,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              image: pw.DecorationImage(
                image: photoImage,
                fit: pw.BoxFit.cover,
              ),
            ),
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.mm),
        ],
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
          beneficiaryPhoto: beneficiary.photo,
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
                  beneficiaryPhoto: beneficiariesById[ticket.beneficiaryId]!.photo,
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
