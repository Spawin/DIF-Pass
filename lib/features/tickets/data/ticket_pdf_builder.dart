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
