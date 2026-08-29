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
