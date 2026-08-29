import 'package:dif_pass/core/router/app_router.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/beneficiaries/fake_beneficiary_repository.dart';
import '../../features/events/fake_event_repository.dart';
import '../../features/tickets/fake_ticket_repository.dart';

void main() {
  testWidgets('app router shows the events list screen at /', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventRepositoryProvider.overrideWithValue(FakeEventRepository())],
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('No events yet. Create one to get started.'), findsOneWidget);
  });

  testWidgets('app router shows the beneficiaries list at /events/:id/beneficiaries',
      (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(fakeEvents),
          beneficiaryRepositoryProvider.overrideWithValue(FakeBeneficiaryRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/events/$eventId/beneficiaries');
    await tester.pumpAndSettle();

    expect(find.text('Beneficiaries'), findsOneWidget);
    expect(
      find.text('No beneficiaries yet. Add one or import a CSV file.'),
      findsOneWidget,
    );
  });

  testWidgets('app router shows the tickets screen at /events/:id/tickets',
      (tester) async {
    final fakeEvents = FakeEventRepository();
    final eventId = await fakeEvents.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(fakeEvents),
          beneficiaryRepositoryProvider.overrideWithValue(FakeBeneficiaryRepository()),
          ticketRepositoryProvider.overrideWithValue(FakeTicketRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/events/$eventId/tickets');
    await tester.pumpAndSettle();

    expect(find.text('Tickets'), findsWidgets);
    expect(find.text('No tickets yet.'), findsOneWidget);
  });
}
