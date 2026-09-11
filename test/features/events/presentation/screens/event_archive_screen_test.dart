import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
import 'package:dif_pass/features/events/domain/event.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/events/presentation/screens/event_archive_screen.dart';
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
  testWidgets('shows the empty state when there are no archived events',
      (tester) async {
    await tester.pumpWidget(_wrap(const EventArchiveScreen(), FakeEventRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No archived events'), findsOneWidget);
  });

  testWidgets('restore button restores the event', (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Old gala',
        date: DateTime(2025, 1, 1),
        presenceMode: PresenceMode.simple,
        archivedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventArchiveScreen(), fake));
    await tester.pumpAndSettle();

    expect(find.text('Old gala'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();

    expect(fake.events.single.isArchived, isFalse);
  });

  testWidgets('restoring shows an undo snackbar that archives the event', (
    tester,
  ) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Old gala',
        date: DateTime(2025, 1, 1),
        presenceMode: PresenceMode.simple,
        archivedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventArchiveScreen(), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Event restored.'), findsOneWidget);
    expect(fake.events.single.isArchived, isFalse);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(fake.events.single.isArchived, isTrue);
  });

  testWidgets('delete permanently asks for confirmation before deleting',
      (tester) async {
    final fake = FakeEventRepository(events: [
      Event(
        id: 1,
        shortCode: 'EVT1',
        name: 'Old gala',
        date: DateTime(2025, 1, 1),
        presenceMode: PresenceMode.simple,
        archivedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const EventArchiveScreen(), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pumpAndSettle();

    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(fake.events, hasLength(1));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fake.events, isEmpty);
  });
}
