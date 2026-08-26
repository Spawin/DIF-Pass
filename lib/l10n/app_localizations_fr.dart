// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DIF Pass';

  @override
  String get homeWelcome => 'Bienvenue sur DIF Pass';

  @override
  String get eventsListTitle => 'Evenements';

  @override
  String get eventsArchiveAction => 'Archives';

  @override
  String get eventsEmptyState =>
      'Aucun evenement pour l\'instant. Creez-en un pour commencer.';

  @override
  String get eventsNewAction => 'Nouvel evenement';
}
