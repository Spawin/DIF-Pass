import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderHomeScreen(),
    ),
  ],
);

// ponytail: temporary landing screen, replaced by the real events list
// screen in jalon 2 (Evenements).
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(child: Text(l10n.homeWelcome)),
    );
  }
}
