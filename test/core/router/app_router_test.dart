// test/core/router/app_router_test.dart
import 'package:dif_pass/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app router shows the placeholder home screen at /',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    expect(find.text('Welcome to DIF Pass'), findsOneWidget);
  });
}
