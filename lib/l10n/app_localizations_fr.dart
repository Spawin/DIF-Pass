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
  String get eventsMoreActions => 'Plus d\'actions';

  @override
  String get eventsBeneficiariesAction => 'Beneficiaires';

  @override
  String get eventsCheckInAction => 'Controle';

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
  String get eventsArchiveError => 'Impossible d\'archiver cet evenement.';

  @override
  String get eventsArchivedMessage => 'Evenement archive.';

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
  String get eventFormLoadError => 'Impossible de charger cet evenement.';

  @override
  String get eventFormSaveError => 'Impossible d\'enregistrer cet evenement.';

  @override
  String get eventsArchiveTitle => 'Archives';

  @override
  String get eventsArchiveEmptyState => 'Aucun evenement archive';

  @override
  String get eventsRestoreAction => 'Restaurer';

  @override
  String get eventsRestoreError => 'Impossible de restaurer cet evenement.';

  @override
  String get eventsRestoredMessage => 'Evenement restaure.';

  @override
  String get eventsDeletePermanentlyAction => 'Supprimer definitivement';

  @override
  String get eventsDeleteConfirmTitle => 'Supprimer definitivement ?';

  @override
  String get eventsDeleteConfirmBody => 'Cette action est irreversible.';

  @override
  String get eventsDeletePermanentlyError =>
      'Impossible de supprimer cet evenement.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetryAction => 'Reessayer';

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
  String get beneficiariesDeleteError =>
      'Impossible de supprimer ce beneficiaire.';

  @override
  String get beneficiariesDeleteConfirmTitle => 'Supprimer ce beneficiaire ?';

  @override
  String get beneficiariesDeleteConfirmBodyWithTicket =>
      'Ce beneficiaire a deja un ticket genere. Le supprimer supprimera aussi ce ticket ; toute copie deja imprimee ou partagee deviendra invalide.';

  @override
  String get beneficiaryFormTitleCreate => 'Nouveau beneficiaire';

  @override
  String get beneficiaryFormTitleEdit => 'Modifier le beneficiaire';

  @override
  String get beneficiaryFormFieldNumberInvalid => 'Entrez un nombre';

  @override
  String get beneficiaryFormLoadError =>
      'Impossible de charger ce beneficiaire.';

  @override
  String get beneficiaryFormSaveError =>
      'Impossible d\'enregistrer ce beneficiaire.';

  @override
  String get beneficiaryFormEditConfirmTitle => 'Modifier ce beneficiaire ?';

  @override
  String get beneficiaryFormEditConfirmBody =>
      'Ce beneficiaire a deja un ticket genere. Le modifier peut rendre les informations du ticket incoherentes avec les donnees reelles.';

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

  @override
  String get csvImportPickError => 'Impossible de lire ce fichier CSV.';

  @override
  String get csvImportSaveError => 'Impossible d\'importer les beneficiaires.';

  @override
  String csvImportFieldsHint(String fields) {
    return 'Vous pourrez associer les colonnes de votre fichier a : Nom, $fields';
  }

  @override
  String get csvImportFieldsHintNameOnly =>
      'Vous pourrez associer les colonnes de votre fichier au champ Nom.';

  @override
  String get ticketsScreenTitle => 'Tickets';

  @override
  String get ticketsTemplateLabel => 'Modele de ticket';

  @override
  String get ticketsTemplateCompact => 'Compact';

  @override
  String get ticketsTemplateStandard => 'Standard';

  @override
  String get ticketsTemplateElegant => 'Elegant';

  @override
  String get ticketsGenerateAction => 'Generer les tickets';

  @override
  String get ticketsEmptyState => 'Aucun ticket pour l\'instant.';

  @override
  String get ticketsCheckedInBadge => 'Present';

  @override
  String ticketsCheckInCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passages',
      one: '1 passage',
    );
    return '$_temp0';
  }

  @override
  String get ticketsLoadError =>
      'Un probleme est survenu lors du chargement des tickets.';

  @override
  String get ticketsGenerateConfirmTitle => 'Generer les tickets ?';

  @override
  String get ticketsGenerateConfirmBody =>
      'Cette action verrouillera la modification des champs personnalises pour cet evenement. Cette action est irreversible.';

  @override
  String ticketsGeneratedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets crees',
      one: '1 ticket cree',
    );
    return '$_temp0';
  }

  @override
  String get ticketsExportAction => 'Exporter les tickets';

  @override
  String get ticketsExportError => 'Impossible d\'exporter les tickets.';

  @override
  String get ticketsExportSuccess => 'Tickets exportes.';

  @override
  String get ticketsTemplateUpdateError =>
      'Impossible de changer le modele de ticket.';

  @override
  String get ticketsGenerateError => 'Impossible de generer les tickets.';

  @override
  String get ticketPreviewTitle => 'Ticket';

  @override
  String get ticketPreviewShareAction => 'Partager le ticket';

  @override
  String get ticketPreviewShareError => 'Impossible de partager le ticket.';

  @override
  String get ticketPreviewShareSuccess => 'Ticket partage.';

  @override
  String get checkinManualEntryLabel => 'Identifiant du ticket';

  @override
  String get checkinManualEntryAction => 'Enregistrer';

  @override
  String get checkinScreenTitle => 'Controle de presence';

  @override
  String get checkinManualEntryToggleAction => 'Saisie manuelle';

  @override
  String get checkinBackToScanAction => 'Revenir au scan';

  @override
  String checkinCounterLabel(int checkedIn, int total) {
    return '$checkedIn/$total arrives';
  }

  @override
  String checkinAlreadyRecordedMessage(String time) {
    return 'Deja enregistre a $time';
  }

  @override
  String get checkinNotFoundMessage => 'Ticket introuvable';

  @override
  String get checkinUnexpectedError =>
      'Un probleme est survenu lors de l\'enregistrement de la presence.';

  @override
  String get checkinSkipAction => 'Passer';

  @override
  String get checkinHistoryAction => 'Historique';

  @override
  String get checkinHistoryTitle => 'Historique des passages';

  @override
  String get checkinHistoryEmptyState => 'Aucun passage enregistre.';

  @override
  String get checkinHistoryLoadError => 'Impossible de charger l\'historique.';

  @override
  String get settingsAction => 'Reglages';

  @override
  String get settingsImportAction => 'Importer une sauvegarde';

  @override
  String get settingsImportConfirmTitle => 'Importer cette sauvegarde ?';

  @override
  String get settingsImportConfirmBody =>
      'Cette action remplacera toutes les donnees actuelles. Cette action est irreversible.';

  @override
  String get settingsScreenTitle => 'Reglages';

  @override
  String get settingsExportAction => 'Exporter la sauvegarde';

  @override
  String get settingsExportError => 'Impossible d\'exporter la sauvegarde.';

  @override
  String get settingsExportSuccess => 'Sauvegarde exportee.';

  @override
  String get settingsCheckinDelayLabel => 'Delai de confirmation check-in';

  @override
  String get settingsLanguageLabel => 'Langue';

  @override
  String get settingsLanguageAuto => 'Automatique';

  @override
  String get settingsLanguageFrench => 'Francais';

  @override
  String get settingsLanguageEnglish => 'Anglais';

  @override
  String get settingsImportError =>
      'Impossible d\'importer ce fichier. Verifiez qu\'il s\'agit bien d\'une sauvegarde DIF Pass valide.';

  @override
  String get settingsAuditSectionTitle => 'Statistiques d\'utilisation';

  @override
  String get settingsAuditExplanation =>
      'Enregistre localement les scans et les principales actions (creation d\'evenement, generation de tickets, import, sauvegarde) pour ameliorer l\'application plus tard. Aucun nom, aucune donnee personnelle. Reste sur cet appareil sauf si vous exportez le fichier vous-meme. Desactivable et supprimable a tout moment.';

  @override
  String get settingsAuditToggleLabel =>
      'Activer les statistiques d\'utilisation';

  @override
  String get settingsAuditExportAction => 'Exporter les donnees d\'audit';

  @override
  String get settingsAuditDeleteAction => 'Supprimer les donnees d\'audit';

  @override
  String get settingsAuditDeleteConfirmTitle =>
      'Supprimer les donnees d\'audit ?';

  @override
  String get settingsAuditDeleteConfirmBody =>
      'Cette action supprime definitivement le journal d\'utilisation enregistre sur cet appareil.';

  @override
  String get settingsAuditDeleteSuccess => 'Donnees d\'audit supprimees';

  @override
  String get settingsAuditDeleteError =>
      'Echec de la suppression des donnees d\'audit';

  @override
  String get settingsAuditExportError =>
      'Echec de l\'export des donnees d\'audit';
}
