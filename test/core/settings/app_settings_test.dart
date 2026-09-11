import 'package:dif_pass/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings.load', () {
    test('returns the default delay and no locale override when nothing is stored', () async {
      final settings = await AppSettings.load();

      expect(settings.checkinFeedbackDelayMs, AppSettings.defaultDelayMs);
      expect(settings.localeOverride, isNull);
    });

    test('returns stored values when present', () async {
      SharedPreferences.setMockInitialValues({
        'checkin_feedback_delay_ms': 2500,
        'locale_override': 'fr',
      });

      final settings = await AppSettings.load();

      expect(settings.checkinFeedbackDelayMs, 2500);
      expect(settings.localeOverride, 'fr');
    });
  });

  group('AppSettings.saveCheckinFeedbackDelayMs', () {
    test('persists the value for a later load', () async {
      await AppSettings.saveCheckinFeedbackDelayMs(3000);

      final settings = await AppSettings.load();

      expect(settings.checkinFeedbackDelayMs, 3000);
    });
  });

  group('AppSettings.saveLocaleOverride', () {
    test('persists a value for a later load', () async {
      await AppSettings.saveLocaleOverride('en');

      final settings = await AppSettings.load();

      expect(settings.localeOverride, 'en');
    });

    test('removes the stored value when set to null', () async {
      await AppSettings.saveLocaleOverride('en');
      await AppSettings.saveLocaleOverride(null);

      final settings = await AppSettings.load();

      expect(settings.localeOverride, isNull);
    });
  });

  group('AppSettings.auditEnabled', () {
    test('defaults to false when nothing is stored', () async {
      final settings = await AppSettings.load();
      expect(settings.auditEnabled, isFalse);
    });

    test('saveAuditEnabled persists the value for a later load', () async {
      await AppSettings.saveAuditEnabled(true);
      final settings = await AppSettings.load();
      expect(settings.auditEnabled, isTrue);
    });
  });
}
