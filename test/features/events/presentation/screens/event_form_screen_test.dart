import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/events/presentation/screens/event_form_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_event_repository.dart';

Widget _wrap(Widget child, FakeEventRepository fake) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(fake),
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
  testWidgets('shows a validation error when the name is empty', (tester) async {
    await tester.pumpWidget(_wrap(const EventFormScreen(), FakeEventRepository()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('creates an event with the entered name', (tester) async {
    final fake = FakeEventRepository();

    await tester.pumpWidget(_wrap(const EventFormScreen(), fake));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Gala DIF 2026');
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.events, hasLength(1));
    expect(fake.events.single.name, 'Gala DIF 2026');
  });

  testWidgets('editing an existing event pre-fills the name field', (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 42,
        shortCode: 'EVT42',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        location: 'Lome',
        presenceMode: PresenceMode.multiple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventFormScreen(eventId: 42), fake));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(nameField.controller?.text, 'Gala DIF 2026');
    expect(find.text('Edit event'), findsOneWidget);
  });

  testWidgets(
      'removing an earlier custom field keeps the correct label on the remaining row',
      (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 42,
        shortCode: 'EVT42',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    await fake.replaceCustomFields(42, const [
      NewCustomField(label: 'Table', type: CustomFieldType.text, sortOrder: 0),
      NewCustomField(label: 'Category', type: CustomFieldType.text, sortOrder: 1),
    ]);

    await tester.pumpWidget(_wrap(const EventFormScreen(eventId: 42), fake));
    await tester.pumpAndSettle();

    expect(find.text('Table'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Table'), findsNothing);
  });

  testWidgets('saving without touching custom fields keeps their ids stable',
      (tester) async {
    // The extra custom field row pushes the Save button below the fold at
    // the default test surface size; grow it so everything fits without
    // needing a scroll gesture to reach Save.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeEventRepository(events: [
      Event(
        id: 42,
        shortCode: 'EVT42',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    await fake.replaceCustomFields(42, const [
      NewCustomField(label: 'Table', type: CustomFieldType.text, sortOrder: 0),
    ]);
    final originalId = fake.customFieldsFor(42).single.id;

    await tester.pumpWidget(_wrap(const EventFormScreen(eventId: 42), fake));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Gala DIF 2027');
    await tester.ensureVisible(find.text('Save', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.customFieldsFor(42).single.id, originalId);
  });

  testWidgets(
      'editing a custom field label then reverting it keeps its id stable',
      (tester) async {
    // Same viewport reasoning as the test above: the extra custom field row
    // pushes Save below the fold at the default test surface size.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeEventRepository(events: [
      Event(
        id: 42,
        shortCode: 'EVT42',
        name: 'Gala DIF 2026',
        date: DateTime(2026, 12, 1),
        presenceMode: PresenceMode.simple,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    await fake.replaceCustomFields(42, const [
      NewCustomField(label: 'Table', type: CustomFieldType.text, sortOrder: 0),
    ]);
    final originalId = fake.customFieldsFor(42).single.id;

    await tester.pumpWidget(_wrap(const EventFormScreen(eventId: 42), fake));
    await tester.pumpAndSettle();

    // The custom field's label TextFormField is the third one on the form
    // (name, location, then the one custom field row).
    final labelField = find.byType(TextFormField).at(2);
    await tester.enterText(labelField, 'Temp label');
    await tester.pumpAndSettle();
    await tester.enterText(labelField, 'Table');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // This exercises NewCustomField's value equality directly: the field
    // object was replaced (edited, then edited back), so only value
    // equality -- not identity -- can prove nothing actually changed.
    expect(fake.customFieldsFor(42).single.id, originalId);
  });

  testWidgets(
      'locked event disables presence toggle and shows the locked message',
      (tester) async {
    final fake = FakeEventRepository(
      events: [
        Event(
          id: 42,
          shortCode: 'EVT42',
          name: 'Gala DIF 2026',
          date: DateTime(2026, 12, 1),
          presenceMode: PresenceMode.simple,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      customFieldsEditable: false,
      presenceModeEditable: false,
    );
    await fake.replaceCustomFields(42, const [
      NewCustomField(label: 'Table', type: CustomFieldType.text, sortOrder: 0),
    ]);

    await tester.pumpWidget(_wrap(const EventFormScreen(eventId: 42), fake));
    await tester.pumpAndSettle();

    final segmentedButton = tester.widget<SegmentedButton<PresenceMode>>(
      find.byType(SegmentedButton<PresenceMode>),
    );
    expect(segmentedButton.onSelectionChanged, isNull);
    expect(
      find.text('Locked: tickets already exist for this event'),
      findsOneWidget,
    );

    // The custom field label field (name, location, then the field row).
    final labelField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(2));
    expect(labelField.enabled, isFalse);
    expect(find.text('Add field'), findsNothing);
  });
}
