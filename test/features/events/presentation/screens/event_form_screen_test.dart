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
    overrides: [eventRepositoryProvider.overrideWithValue(fake)],
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
}
