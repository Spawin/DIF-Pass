import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.checkinFeedbackDelayMs,
    this.localeOverride,
    this.auditEnabled = false,
  });

  final int checkinFeedbackDelayMs;
  final String? localeOverride;
  final bool auditEnabled;

  static const defaultDelayMs = 1800;
  static const _delayKey = 'checkin_feedback_delay_ms';
  static const _localeKey = 'locale_override';
  static const _auditEnabledKey = 'audit_enabled';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      checkinFeedbackDelayMs: prefs.getInt(_delayKey) ?? defaultDelayMs,
      localeOverride: prefs.getString(_localeKey),
      auditEnabled: prefs.getBool(_auditEnabledKey) ?? false,
    );
  }

  static Future<void> saveCheckinFeedbackDelayMs(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_delayKey, value);
  }

  static Future<void> saveLocaleOverride(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, value);
    }
  }

  static Future<void> saveAuditEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_auditEnabledKey, value);
  }
}
