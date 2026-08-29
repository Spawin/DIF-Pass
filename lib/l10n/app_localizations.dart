import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DIF Pass'**
  String get appTitle;

  /// No description provided for @eventsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsListTitle;

  /// No description provided for @eventsArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get eventsArchiveAction;

  /// No description provided for @eventsArchiveEventAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get eventsArchiveEventAction;

  /// No description provided for @eventsBeneficiariesAction.
  ///
  /// In en, this message translates to:
  /// **'Beneficiaries'**
  String get eventsBeneficiariesAction;

  /// No description provided for @eventsTicketsAction.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get eventsTicketsAction;

  /// No description provided for @eventsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No events yet. Create one to get started.'**
  String get eventsEmptyState;

  /// No description provided for @eventsNewAction.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventsNewAction;

  /// No description provided for @eventsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading events.'**
  String get eventsLoadError;

  /// No description provided for @eventFormTitleCreate.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventFormTitleCreate;

  /// No description provided for @eventFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventFormTitleEdit;

  /// No description provided for @eventFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get eventFormNameLabel;

  /// No description provided for @eventFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get eventFormNameRequired;

  /// No description provided for @eventFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventFormDateLabel;

  /// No description provided for @eventFormLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventFormLocationLabel;

  /// No description provided for @eventFormLogoAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a logo'**
  String get eventFormLogoAction;

  /// No description provided for @eventFormPresenceModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Presence mode'**
  String get eventFormPresenceModeLabel;

  /// No description provided for @eventFormPresenceModeSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple presence'**
  String get eventFormPresenceModeSimple;

  /// No description provided for @eventFormPresenceModeMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple entries'**
  String get eventFormPresenceModeMultiple;

  /// No description provided for @eventFormCustomFieldsLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get eventFormCustomFieldsLabel;

  /// No description provided for @eventFormAddFieldAction.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get eventFormAddFieldAction;

  /// No description provided for @eventFormFieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get eventFormFieldLabelHint;

  /// No description provided for @eventFormFieldLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Field label is required'**
  String get eventFormFieldLabelRequired;

  /// No description provided for @eventFormCustomFieldsLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked: tickets already exist for this event'**
  String get eventFormCustomFieldsLocked;

  /// No description provided for @eventFormSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventFormSaveAction;

  /// No description provided for @eventsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get eventsArchiveTitle;

  /// No description provided for @eventsArchiveEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No archived events'**
  String get eventsArchiveEmptyState;

  /// No description provided for @eventsRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get eventsRestoreAction;

  /// No description provided for @eventsDeletePermanentlyAction.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get eventsDeletePermanentlyAction;

  /// No description provided for @eventsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get eventsDeleteConfirmTitle;

  /// No description provided for @eventsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get eventsDeleteConfirmBody;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @beneficiariesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Beneficiaries'**
  String get beneficiariesListTitle;

  /// No description provided for @beneficiariesImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get beneficiariesImportAction;

  /// No description provided for @beneficiariesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No beneficiaries yet. Add one or import a CSV file.'**
  String get beneficiariesEmptyState;

  /// No description provided for @beneficiariesNewAction.
  ///
  /// In en, this message translates to:
  /// **'New beneficiary'**
  String get beneficiariesNewAction;

  /// No description provided for @beneficiariesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading beneficiaries.'**
  String get beneficiariesLoadError;

  /// No description provided for @beneficiariesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this beneficiary?'**
  String get beneficiariesDeleteConfirmTitle;

  /// No description provided for @beneficiaryFormTitleCreate.
  ///
  /// In en, this message translates to:
  /// **'New beneficiary'**
  String get beneficiaryFormTitleCreate;

  /// No description provided for @beneficiaryFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit beneficiary'**
  String get beneficiaryFormTitleEdit;

  /// No description provided for @beneficiaryFormFieldNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get beneficiaryFormFieldNumberInvalid;

  /// No description provided for @csvImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import beneficiaries'**
  String get csvImportTitle;

  /// No description provided for @csvImportPickFileAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a CSV file'**
  String get csvImportPickFileAction;

  /// No description provided for @csvImportMappingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name column'**
  String get csvImportMappingNameLabel;

  /// No description provided for @csvImportIgnoreColumn.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get csvImportIgnoreColumn;

  /// No description provided for @csvImportImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get csvImportImportAction;

  /// No description provided for @csvImportResult.
  ///
  /// In en, this message translates to:
  /// **'{imported} beneficiaries imported, {skipped} skipped'**
  String csvImportResult(int imported, int skipped);

  /// No description provided for @ticketsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get ticketsScreenTitle;

  /// No description provided for @ticketsTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket template'**
  String get ticketsTemplateLabel;

  /// No description provided for @ticketsTemplateCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get ticketsTemplateCompact;

  /// No description provided for @ticketsTemplateStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get ticketsTemplateStandard;

  /// No description provided for @ticketsTemplateElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get ticketsTemplateElegant;

  /// No description provided for @ticketsGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate tickets'**
  String get ticketsGenerateAction;

  /// No description provided for @ticketsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet.'**
  String get ticketsEmptyState;

  /// No description provided for @ticketsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading tickets.'**
  String get ticketsLoadError;

  /// No description provided for @ticketsGenerateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate tickets?'**
  String get ticketsGenerateConfirmTitle;

  /// No description provided for @ticketsGenerateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will lock custom-field editing for this event. This action cannot be undone.'**
  String get ticketsGenerateConfirmBody;

  /// No description provided for @ticketsGeneratedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ticket created} other{{count} tickets created}}'**
  String ticketsGeneratedCount(int count);

  /// No description provided for @ticketsExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export tickets'**
  String get ticketsExportAction;

  /// No description provided for @ticketsExportError.
  ///
  /// In en, this message translates to:
  /// **'Could not export the tickets.'**
  String get ticketsExportError;

  /// No description provided for @ticketPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticketPreviewTitle;

  /// No description provided for @ticketPreviewShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share ticket'**
  String get ticketPreviewShareAction;

  /// No description provided for @ticketPreviewShareError.
  ///
  /// In en, this message translates to:
  /// **'Could not share the ticket.'**
  String get ticketPreviewShareError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
