// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DIF Pass';

  @override
  String get eventsListTitle => 'Events';

  @override
  String get eventsArchiveAction => 'Archives';

  @override
  String get eventsArchiveEventAction => 'Archive';

  @override
  String get eventsBeneficiariesAction => 'Beneficiaries';

  @override
  String get eventsCheckInAction => 'Check-in';

  @override
  String get eventsTicketsAction => 'Tickets';

  @override
  String get eventsEmptyState => 'No events yet. Create one to get started.';

  @override
  String get eventsNewAction => 'New event';

  @override
  String get eventsLoadError => 'Something went wrong loading events.';

  @override
  String get eventsArchiveError => 'Could not archive this event.';

  @override
  String get eventsArchivedMessage => 'Event archived.';

  @override
  String get eventFormTitleCreate => 'New event';

  @override
  String get eventFormTitleEdit => 'Edit event';

  @override
  String get eventFormNameLabel => 'Name';

  @override
  String get eventFormNameRequired => 'Name is required';

  @override
  String get eventFormDateLabel => 'Date';

  @override
  String get eventFormLocationLabel => 'Location';

  @override
  String get eventFormLogoAction => 'Choose a logo';

  @override
  String get eventFormPresenceModeLabel => 'Presence mode';

  @override
  String get eventFormPresenceModeSimple => 'Simple presence';

  @override
  String get eventFormPresenceModeMultiple => 'Multiple entries';

  @override
  String get eventFormCustomFieldsLabel => 'Custom fields';

  @override
  String get eventFormAddFieldAction => 'Add field';

  @override
  String get eventFormFieldLabelHint => 'Label';

  @override
  String get eventFormFieldLabelRequired => 'Field label is required';

  @override
  String get eventFormCustomFieldsLocked =>
      'Locked: tickets already exist for this event';

  @override
  String get eventFormSaveAction => 'Save';

  @override
  String get eventFormLoadError => 'Could not load this event.';

  @override
  String get eventFormSaveError => 'Could not save this event.';

  @override
  String get eventsArchiveTitle => 'Archives';

  @override
  String get eventsArchiveEmptyState => 'No archived events';

  @override
  String get eventsRestoreAction => 'Restore';

  @override
  String get eventsRestoreError => 'Could not restore this event.';

  @override
  String get eventsRestoredMessage => 'Event restored.';

  @override
  String get eventsDeletePermanentlyAction => 'Delete permanently';

  @override
  String get eventsDeleteConfirmTitle => 'Delete permanently?';

  @override
  String get eventsDeleteConfirmBody => 'This action cannot be undone.';

  @override
  String get eventsDeletePermanentlyError => 'Could not delete this event.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetryAction => 'Retry';

  @override
  String get beneficiariesListTitle => 'Beneficiaries';

  @override
  String get beneficiariesImportAction => 'Import CSV';

  @override
  String get beneficiariesEmptyState =>
      'No beneficiaries yet. Add one or import a CSV file.';

  @override
  String get beneficiariesNewAction => 'New beneficiary';

  @override
  String get beneficiariesLoadError =>
      'Something went wrong loading beneficiaries.';

  @override
  String get beneficiariesDeleteError => 'Could not delete this beneficiary.';

  @override
  String get beneficiariesDeleteConfirmTitle => 'Delete this beneficiary?';

  @override
  String get beneficiaryFormTitleCreate => 'New beneficiary';

  @override
  String get beneficiaryFormTitleEdit => 'Edit beneficiary';

  @override
  String get beneficiaryFormFieldNumberInvalid => 'Enter a number';

  @override
  String get beneficiaryFormLoadError => 'Could not load this beneficiary.';

  @override
  String get beneficiaryFormSaveError => 'Could not save this beneficiary.';

  @override
  String get csvImportTitle => 'Import beneficiaries';

  @override
  String get csvImportPickFileAction => 'Choose a CSV file';

  @override
  String get csvImportMappingNameLabel => 'Name column';

  @override
  String get csvImportIgnoreColumn => 'Ignore';

  @override
  String get csvImportImportAction => 'Import';

  @override
  String csvImportResult(int imported, int skipped) {
    return '$imported beneficiaries imported, $skipped skipped';
  }

  @override
  String get csvImportPickError => 'Could not read this CSV file.';

  @override
  String get csvImportSaveError => 'Could not import beneficiaries.';

  @override
  String get ticketsScreenTitle => 'Tickets';

  @override
  String get ticketsTemplateLabel => 'Ticket template';

  @override
  String get ticketsTemplateCompact => 'Compact';

  @override
  String get ticketsTemplateStandard => 'Standard';

  @override
  String get ticketsTemplateElegant => 'Elegant';

  @override
  String get ticketsGenerateAction => 'Generate tickets';

  @override
  String get ticketsEmptyState => 'No tickets yet.';

  @override
  String get ticketsLoadError => 'Something went wrong loading tickets.';

  @override
  String get ticketsGenerateConfirmTitle => 'Generate tickets?';

  @override
  String get ticketsGenerateConfirmBody =>
      'This will lock custom-field editing for this event. This action cannot be undone.';

  @override
  String ticketsGeneratedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets created',
      one: '1 ticket created',
    );
    return '$_temp0';
  }

  @override
  String get ticketsExportAction => 'Export tickets';

  @override
  String get ticketsExportError => 'Could not export the tickets.';

  @override
  String get ticketsExportSuccess => 'Tickets exported.';

  @override
  String get ticketsTemplateUpdateError =>
      'Could not change the ticket template.';

  @override
  String get ticketsGenerateError => 'Could not generate tickets.';

  @override
  String get ticketPreviewTitle => 'Ticket';

  @override
  String get ticketPreviewShareAction => 'Share ticket';

  @override
  String get ticketPreviewShareError => 'Could not share the ticket.';

  @override
  String get ticketPreviewShareSuccess => 'Ticket shared.';

  @override
  String get checkinManualEntryLabel => 'Ticket ID';

  @override
  String get checkinManualEntryAction => 'Check in';

  @override
  String get checkinScreenTitle => 'Check-in';

  @override
  String get checkinManualEntryToggleAction => 'Manual entry';

  @override
  String get checkinBackToScanAction => 'Back to scanning';

  @override
  String checkinCounterLabel(int checkedIn, int total) {
    return '$checkedIn/$total arrived';
  }

  @override
  String checkinAlreadyRecordedMessage(String time) {
    return 'Already checked in at $time';
  }

  @override
  String get checkinNotFoundMessage => 'Ticket not found';

  @override
  String get checkinUnexpectedError =>
      'Something went wrong recording the check-in.';

  @override
  String get checkinSkipAction => 'Skip';

  @override
  String get settingsAction => 'Settings';

  @override
  String get settingsImportAction => 'Import backup';

  @override
  String get settingsImportConfirmTitle => 'Import this backup?';

  @override
  String get settingsImportConfirmBody =>
      'This will replace all current data. This action cannot be undone.';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsExportAction => 'Export backup';

  @override
  String get settingsExportError => 'Could not export the backup.';

  @override
  String get settingsExportSuccess => 'Backup exported.';

  @override
  String get settingsCheckinDelayLabel => 'Check-in confirmation delay';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageAuto => 'Automatic';

  @override
  String get settingsLanguageFrench => 'French';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsImportError =>
      'Could not import this file. Make sure it is a valid DIF Pass backup.';
}
