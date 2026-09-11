import 'dart:io';

import 'package:dif_pass/core/audit/audit_logger.dart';
import 'package:dif_pass/core/audit/audit_providers.dart';
import 'package:dif_pass/core/settings/app_settings.dart';
import 'package:dif_pass/core/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to AppSettings.defaultDelayMs and no locale override when not overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(appSettingsProvider);

    expect(settings.checkinFeedbackDelayMs, AppSettings.defaultDelayMs);
    expect(settings.localeOverride, isNull);
  });

  test('overriding with an initial value is honored', () {
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          () => AppSettingsNotifier(
            const AppSettings(checkinFeedbackDelayMs: 2500, localeOverride: 'fr'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final settings = container.read(appSettingsProvider);

    expect(settings.checkinFeedbackDelayMs, 2500);
    expect(settings.localeOverride, 'fr');
  });

  test('setCheckinFeedbackDelayMs updates state and persists the value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setCheckinFeedbackDelayMs(3000);

    expect(container.read(appSettingsProvider).checkinFeedbackDelayMs, 3000);
    expect((await AppSettings.load()).checkinFeedbackDelayMs, 3000);
  });

  test('setLocaleOverride updates state and persists the value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setLocaleOverride('en');

    expect(container.read(appSettingsProvider).localeOverride, 'en');
    expect((await AppSettings.load()).localeOverride, 'en');
  });

  test('setAuditEnabled updates state, persists, and updates the live AuditLogger', () async {
    final logger = AuditLogger(
      enabled: false,
      fileResolver: () async => File('${Directory.systemTemp.path}/unused_audit.jsonl'),
    );
    final container = ProviderContainer(
      overrides: [auditLoggerProvider.overrideWithValue(logger)],
    );
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setAuditEnabled(true);

    expect(container.read(appSettingsProvider).auditEnabled, isTrue);
    final settings = await AppSettings.load();
    expect(settings.auditEnabled, isTrue);
  });
}
