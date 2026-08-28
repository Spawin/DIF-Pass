import 'package:dif_pass/features/beneficiaries/domain/beneficiary.dart';
import 'package:dif_pass/features/beneficiaries/presentation/providers/beneficiary_providers.dart';
import 'package:dif_pass/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_beneficiary_repository.dart';

Widget _wrap(Widget child, FakeBeneficiaryRepository fake) {
  return ProviderScope(
    overrides: [beneficiaryRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('shows the empty state when there are no beneficiaries',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const BeneficiariesListScreen(eventId: 1), FakeBeneficiaryRepository()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No beneficiaries yet. Add one or import a CSV file.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a tile per beneficiary for the given event', (tester) async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const BeneficiariesListScreen(eventId: 1), fake));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation before removing a beneficiary',
      (tester) async {
    final fake = FakeBeneficiaryRepository(beneficiaries: [
      Beneficiary(
        id: 1,
        eventId: 1,
        name: 'Jane Doe',
        customFieldValues: const {},
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_wrap(const BeneficiariesListScreen(eventId: 1), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(fake.beneficiaries, hasLength(1));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fake.beneficiaries, isEmpty);
  });
}
