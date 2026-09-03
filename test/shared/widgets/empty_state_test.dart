import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:dif_pass/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('EmptyState', () {
    testWidgets('shows the icon and message, no button without an action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(icon: Icons.event, message: 'Nothing here')),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byIcon(Icons.event), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('shows the action button and calls onAction when tapped', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          EmptyState(
            icon: Icons.event,
            message: 'Nothing here',
            actionLabel: 'Create one',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Create one'));
      expect(tapped, isTrue);
    });
  });

  group('ErrorState', () {
    testWidgets('shows the message and a Retry button that calls onRetry', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          ErrorState(message: 'Something broke', onRetry: () => retried = true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Something broke'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
