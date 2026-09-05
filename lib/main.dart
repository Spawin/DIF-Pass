import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_providers.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSettings = await AppSettings.load();
  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(() => AppSettingsNotifier(initialSettings)),
      ],
      child: const DifPassApp(),
    ),
  );
}

class DifPassApp extends ConsumerWidget {
  const DifPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeOverride = ref.watch(appSettingsProvider).localeOverride;
    return MaterialApp.router(
      title: 'DIF Pass',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      locale: localeOverride != null ? Locale(localeOverride) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
