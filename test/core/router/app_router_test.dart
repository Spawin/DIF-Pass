import 'package:dif_pass/core/router/app_router.dart';
import 'package:dif_pass/features/events/presentation/providers/event_providers.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/events/fake_event_repository.dart';

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
}
