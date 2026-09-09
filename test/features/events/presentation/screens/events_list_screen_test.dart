import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/events/presentation/screens/events_list_screen.dart';
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
  testWidgets('shows the empty state when there are no active events',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const EventsListScreen(), FakeEventRepository()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No events yet. Create one to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a card per active event', (tester) async {
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

    expect(find.text('Gala DIF 2026'), findsOneWidget);
  });

  testWidgets('tapping the archive action archives the event', (tester) async {
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

    expect(find.text('Gala DIF 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Gala DIF 2026'), findsNothing);
    expect(fake.events.single.isArchived, isTrue);
  });

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

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Event archived.'), findsOneWidget);
    expect(fake.events.single.isArchived, isTrue);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(fake.events.single.isArchived, isFalse);
  });

  testWidgets('the more-actions menu offers history alongside archive', (
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

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('shows a beneficiaries action for each event', (tester) async {
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

    expect(find.byTooltip('Beneficiaries'), findsOneWidget);
  });

  testWidgets('shows a tickets action for each event', (tester) async {
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

    expect(find.byTooltip('Tickets'), findsOneWidget);
  });

  testWidgets('shows a check-in action for each event', (tester) async {
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

    expect(find.byTooltip('Check-in'), findsOneWidget);
  });

  testWidgets('shows a settings action', (tester) async {
    await tester.pumpWidget(
      _wrap(const EventsListScreen(), FakeEventRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsOneWidget);
  });
}
