import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/csv_import_screen.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
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
      auditLoggerProvider.overrideWithValue(
        AuditLogger(
          enabled: false,
          fileResolver: () async =>
              throw UnimplementedError('not used - enabled is false'),
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
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

    // Once in the expected-schema preview header, once in the hint sentence.
    expect(find.textContaining('Table number'), findsNWidgets(2));
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

  testWidgets('shows the expected-schema preview header before a file is picked', (
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

    expect(find.text('Expected format'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
  });
}
