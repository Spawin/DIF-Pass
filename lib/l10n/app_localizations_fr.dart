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
  String get eventsListTitle => 'Evenements';

  @override
  String get eventsArchiveAction => 'Archives';

  @override
  String get eventsArchiveEventAction => 'Archiver';

  @override
  String get eventsBeneficiariesAction => 'Beneficiaires';

  @override
  String get eventsTicketsAction => 'Tickets';

  @override
  String get eventsEmptyState =>
      'Aucun evenement pour l\'instant. Creez-en un pour commencer.';

  @override
  String get eventsNewAction => 'Nouvel evenement';

  @override
  String get eventsLoadError =>
      'Un probleme est survenu lors du chargement des evenements.';

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
  String get eventFormFieldLabelRequired =>
      'Le libelle du champ est obligatoire';

  @override
  String get eventFormCustomFieldsLocked =>
      'Verrouille : des tickets existent deja pour cet evenement';

  @override
  String get eventFormSaveAction => 'Enregistrer';

  @override
  String get eventsArchiveTitle => 'Archives';

  @override
  String get eventsArchiveEmptyState => 'Aucun evenement archive';

  @override
  String get eventsRestoreAction => 'Restaurer';

  @override
  String get eventsDeletePermanentlyAction => 'Supprimer definitivement';

  @override
  String get eventsDeleteConfirmTitle => 'Supprimer definitivement ?';

  @override
  String get eventsDeleteConfirmBody => 'Cette action est irreversible.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get beneficiariesListTitle => 'Beneficiaires';

  @override
  String get beneficiariesImportAction => 'Importer un CSV';

  @override
  String get beneficiariesEmptyState =>
      'Aucun beneficiaire pour l\'instant. Ajoutez-en un ou importez un fichier CSV.';

  @override
  String get beneficiariesNewAction => 'Nouveau beneficiaire';

  @override
  String get beneficiariesLoadError =>
      'Un probleme est survenu lors du chargement des beneficiaires.';

  @override
  String get beneficiariesDeleteConfirmTitle => 'Supprimer ce beneficiaire ?';

  @override
  String get beneficiaryFormTitleCreate => 'Nouveau beneficiaire';

  @override
  String get beneficiaryFormTitleEdit => 'Modifier le beneficiaire';

  @override
  String get beneficiaryFormFieldNumberInvalid => 'Entrez un nombre';

  @override
  String get csvImportTitle => 'Importer des beneficiaires';

  @override
  String get csvImportPickFileAction => 'Choisir un fichier CSV';

  @override
  String get csvImportMappingNameLabel => 'Colonne Nom';

  @override
  String get csvImportIgnoreColumn => 'Ignorer';

  @override
  String get csvImportImportAction => 'Importer';

  @override
  String csvImportResult(int imported, int skipped) {
    return '$imported beneficiaires importes, $skipped ignores';
  }
}
