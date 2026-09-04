import 'dart:convert';

import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/domain/ticket_template.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/domain/ticket.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/features/tickets/presentation/screens/ticket_preview_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../beneficiaries/fake_beneficiary_repository.dart';
import '../../../events/fake_event_repository.dart';
import '../../fake_ticket_repository.dart';

// A minimal valid 1x1 transparent PNG, so Image.memory can decode it without
// throwing during the test.
final _testLogoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

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
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets(
    'shows the beneficiary name, readable id, and only the checked custom fields',
    (tester) async {
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
          showOnTicket: true,
        ),
        NewCustomField(
          label: 'Internal note',
          type: CustomFieldType.text,
          sortOrder: 1,
          showOnTicket: false,
        ),
      ]);
      final fields = await fakeEvents.watchCustomFields(1).first;
      final tableFieldId = fields
          .firstWhere((f) => f.label == 'Table number')
          .id;
      final noteFieldId = fields
          .firstWhere((f) => f.label == 'Internal note')
          .id;

      final fakeBeneficiaries = FakeBeneficiaryRepository(
        beneficiaries: [
          Beneficiary(
            id: 1,
            eventId: 1,
            name: 'Jane Doe',
            customFieldValues: {tableFieldId: 'Table 5', noteFieldId: 'VIP'},
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

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('0001'), findsOneWidget);
      expect(find.text('Table number: Table 5'), findsOneWidget);
      expect(find.text('Internal note: VIP'), findsNothing);
    },
  );

  testWidgets('renders the event logo when the event has one', (tester) async {
    final fakeEvents = FakeEventRepository(
      events: [
        Event(
          id: 1,
          shortCode: 'EVT1',
          name: 'Gala DIF 2026',
          date: DateTime(2026, 12, 1),
          logo: _testLogoBytes,
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

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets(
    'elegant and standard templates render with a different Card shape',
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

      Future<ShapeBorder?> pumpAndGetCardShape(TicketTemplate template) async {
        final fakeEvents = FakeEventRepository(
          events: [
            Event(
              id: 1,
              shortCode: 'EVT1',
              name: 'Gala DIF 2026',
              date: DateTime(2026, 12, 1),
              presenceMode: PresenceMode.simple,
              ticketTemplate: template,
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
        return tester.widget<Card>(find.byType(Card)).shape;
      }

      final standardShape = await pumpAndGetCardShape(TicketTemplate.standard);
      final elegantShape = await pumpAndGetCardShape(TicketTemplate.elegant);

      expect(standardShape, isNull);
      expect(elegantShape, isNotNull);
    },
  );

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

    expect(find.byTooltip('Share ticket'), findsOneWidget);
    final buttons = find.byType(IconButton);
    expect(buttons, findsOneWidget);
    final button = tester.widget<IconButton>(buttons);
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'shows a confirmation snackbar after successfully sharing the ticket',
    (tester) async {
      const printingChannel = MethodChannel('net.nfet.printing');
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(printingChannel, null);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(printingChannel, (methodCall) async {
        if (methodCall.method == 'sharePdf') return 1;
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

      expect(find.text('Ticket shared.'), findsOneWidget);
    },
  );
}
