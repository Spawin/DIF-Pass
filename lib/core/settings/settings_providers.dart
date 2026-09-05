import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  AppSettingsNotifier([this._initial]);

  final AppSettings? _initial;

  @override
  AppSettings build() =>
      _initial ?? const AppSettings(checkinFeedbackDelayMs: AppSettings.defaultDelayMs);

  Future<void> setCheckinFeedbackDelayMs(int value) async {
    await AppSettings.saveCheckinFeedbackDelayMs(value);
    state = AppSettings(checkinFeedbackDelayMs: value, localeOverride: state.localeOverride);
  }

  Future<void> setLocaleOverride(String? value) async {
    await AppSettings.saveLocaleOverride(value);
    state = AppSettings(checkinFeedbackDelayMs: state.checkinFeedbackDelayMs, localeOverride: value);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
