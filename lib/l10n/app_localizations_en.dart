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
  String get eventsTicketsAction => 'Tickets';

  @override
  String get eventsEmptyState => 'No events yet. Create one to get started.';

  @override
  String get eventsNewAction => 'New event';

  @override
  String get eventsLoadError => 'Something went wrong loading events.';

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
  String get eventsArchiveTitle => 'Archives';

  @override
  String get eventsArchiveEmptyState => 'No archived events';

  @override
  String get eventsRestoreAction => 'Restore';

  @override
  String get eventsDeletePermanentlyAction => 'Delete permanently';

  @override
  String get eventsDeleteConfirmTitle => 'Delete permanently?';

  @override
  String get eventsDeleteConfirmBody => 'This action cannot be undone.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

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
  String get beneficiariesDeleteConfirmTitle => 'Delete this beneficiary?';

  @override
  String get beneficiaryFormTitleCreate => 'New beneficiary';

  @override
  String get beneficiaryFormTitleEdit => 'Edit beneficiary';

  @override
  String get beneficiaryFormFieldNumberInvalid => 'Enter a number';

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
    return '$count tickets created';
  }

  @override
  String get ticketPreviewTitle => 'Ticket';
}
