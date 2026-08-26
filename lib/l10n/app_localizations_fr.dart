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

  @override
  String get eventFormTitleCreate => 'Nouvel evenement';

  @override
  String get eventFormTitleEdit => 'Modifier l\'evenement';

  @override
  String get eventFormNameLabel => 'Nom';

  @override
  String get eventFormNameRequired => 'Le nom est obligatoire';

  @override
  String get eventFormDateLabel => 'Date';

  @override
  String get eventFormLocationLabel => 'Lieu';

  @override
  String get eventFormLogoAction => 'Choisir un logo';

  @override
  String get eventFormPresenceModeLabel => 'Mode de presence';

  @override
  String get eventFormPresenceModeSimple => 'Presence simple';

  @override
  String get eventFormPresenceModeMultiple => 'Entrees et sorties multiples';

  @override
  String get eventFormCustomFieldsLabel => 'Champs personnalises';

  @override
  String get eventFormAddFieldAction => 'Ajouter un champ';

  @override
  String get eventFormFieldLabelHint => 'Libelle';

  @override
  String get eventFormCustomFieldsLocked =>
      'Verrouille : des tickets existent deja pour cet evenement';

  @override
  String get eventFormSaveAction => 'Enregistrer';
}
