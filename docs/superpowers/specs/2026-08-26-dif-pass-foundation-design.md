# DIF Pass — Design du socle (structure, données, thème, i18n, jalons)

Statut : validé par l'utilisateur le 2026-08-26.

## Contexte

DIF Pass est une application Flutter de gestion de tickets/pass pour événements
(DIF-Corporation, Togo), publiée sur Google Play et l'App Store. Un organisateur
crée un événement, une liste de bénéficiaires, génère un ticket unique par
bénéficiaire (QR code), et vérifie la présence à l'entrée en scannant.

L'app fait partie de la suite DIF-Corporation ("sister apps, not clones") :
base visuelle DIF, accent Indigo propre à DIF Pass.

Le cahier des charges fonctionnel complet est dans
`Prompt_Lancement_Claude_Code_DIF_Pass.md` à la racine du dépôt et fait
référence pour tout ce qui n'est pas repris ici (règles de dev, stratégie de
test, contraintes techniques détaillées).

## Décisions actées

- **Bundle ID / Application ID** : `com.difcorporation.difpass` (Android
  applicationId et iOS bundle identifier).
- **Version Flutter (FVM)** : pas de version figée à l'avance. Au jalon
  Socle, exécuter `fvm flutter releases` pour choisir la dernière stable
  réellement disponible à ce moment-là, et créer `.fvmrc` avec ce numéro.
- **Saisie manuelle de secours** (QR abîmé/illisible) : les deux formats sont
  acceptés — la partie lisible seule (ex. `0042`, dans le contexte de
  l'événement en cours de scan) ou le payload complet (ex.
  `EVT3-0042-X7K9`).
- **Dimensions précises des 3 modèles de ticket** : non tranchées ici,
  détaillées au jalon 4 (Tickets) une fois le moteur PDF en place, avec
  aperçu visuel. Principe retenu pour l'instant :
  - *Compact* : grille dense type étiquettes, plusieurs tickets par page A4
  - *Standard* : format carte, un ticket occupe environ une moitié de page A4
  - *Élégant* : un ticket par page (A5/A6), plus aéré, accent Indigo visible

## Structure de dossiers (feature-first + repository pattern)

```
lib/
  main.dart
  core/
    theme/               app_colors.dart, app_typography.dart, app_theme.dart
    database/
      app_database.dart          (@DriftDatabase, jamais édité à la main)
      tables/                    events, custom_fields, beneficiaries,
                                  beneficiary_values, tickets, checkins
    router/app_router.dart       (go_router)
    settings/                    langue forcée FR/EN, prefs simples
    id/ticket_id_generator.dart  (génération identifiant lisible + aléatoire)
  l10n/
    app_en.arb   app_fr.arb      (+ l10n.yaml à la racine)
  features/
    events/
      data/        event_repository.dart (interface) + drift_event_repository.dart (impl)
      domain/      event.dart (modèle métier, découplé de la ligne Drift)
      presentation/ providers/, screens/, widgets/
    beneficiaries/   (même découpage data/domain/presentation)
    tickets/         + services/ticket_pdf_service.dart (templates PDF)
    checkin/         + presentation/widgets/live_counter.dart
    backup/          export/import du fichier de sauvegarde
  shared/
    widgets/         boutons, champs, empty states communs à la charte DIF
    extensions/
test/
  features/.../  core/id/ticket_id_generator_test.dart
```

Règle : chaque feature n'accède à Drift qu'à travers son repository.
`domain/` et `presentation/` ne connaissent jamais Drift directement — c'est
ce qui permet de brancher une source cloud plus tard (sync multi-appareils,
V2 payante) sans toucher aux écrans ni à la logique métier, conformément à la
contrainte d'architecture du cahier des charges.

## Schéma Drift affiné

Trois affinements par rapport au modèle de données initial du cahier des
charges :

- **IDs auto-incrémentés (`Int`)** plutôt qu'UUID. Le cloud n'est pas
  construit maintenant ; un `Int` local est plus simple. Le jour où le sync
  arrive, on pourra ajouter une colonne `remoteId` nullable sans tout
  migrer — le repository pattern isole ce choix du reste de l'app.
- **Logo stocké en `BLOB`** dans la table `Events`, pas en fichier séparé.
  Ça rend le fichier de sauvegarde trivial : la base Drift est déjà un
  fichier SQLite unique, donc "exporter la sauvegarde" = copier ce fichier
  (pas besoin de gérer un zip avec des images à côté).
- **Ajout d'un `shortCode` sur `Events`** (ex. `EVT3`), généré
  séquentiellement à la création. C'est le préfixe manquant dans l'exemple
  d'identifiant du cahier des charges (`EVT3-0042-X7K9`) : sans lui, rien ne
  distingue les tickets de deux événements différents dans le payload QR.

```dart
enum PresenceMode { simple, multiple }
enum CustomFieldType { text, number }

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortCode => text()();          // "EVT3", généré à la création
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text().nullable()();
  BlobColumn get logo => blob().nullable()();
  TextColumn get presenceMode => textEnum<PresenceMode>()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get label => text()();
  TextColumn get fieldType => textEnum<CustomFieldType>()();
  IntColumn get sortOrder => integer()();
  BoolColumn get showOnTicket => boolean().withDefault(const Constant(false))();
}

class Beneficiaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BeneficiaryValues extends Table {           // EAV pour les champs personnalisés
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId => integer().references(Beneficiaries, #id)();
  IntColumn get customFieldId => integer().references(CustomFields, #id)();
  TextColumn get value => text()();
}

class Tickets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId => integer().references(Beneficiaries, #id)();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get readableId => text()();          // "0042"
  TextColumn get randomPart => text()();          // "X7K9"
  TextColumn get qrPayload => text()();           // "EVT3-0042-X7K9"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [{eventId, readableId}];
}

class CheckIns extends Table {                    // historique complet, dans les 2 modes
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId => integer().references(Tickets, #id)();
  IntColumn get eventId => integer().references(Events, #id)();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}
```

La règle de blocage (mode simple) vs comptage (mode multiple) vit dans
`CheckinRepository`, pas dans le schéma. La contrainte `uniqueKeys` sur
`(eventId, readableId)` permet à la saisie de secours d'accepter la partie
lisible seule (dans le contexte de l'événement en cours de scan) ou le
payload complet.

### Paquets additionnels (non listés dans le cahier des charges initial)

- `file_picker` — import CSV et restauration de sauvegarde
- `shared_preferences` — langue forcée FR/EN, réglages simples
- `path_provider` — localiser le fichier de sauvegarde avant partage via `share_plus`

## theme.dart

```dart
// core/theme/app_colors.dart
class AppColors {
  static const ink    = Color(0xFF1B1F3B);
  static const paper  = Color(0xFFF0F1F5);
  static const ochre  = Color(0xFFE8A33D);
  static const teal   = Color(0xFF1F6E5C);
  static const indigo = Color(0xFF5B6EE8); // accent DIF Pass
}

// core/theme/app_typography.dart
// Big Shoulders Display -> titres, IBM Plex Sans -> UI/corps, IBM Plex Mono -> identifiants/compteurs
// polices embarquées via google_fonts ou assets locaux (à trancher au jalon Socle selon poids de l'app)

// core/theme/app_theme.dart
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    primary: AppColors.indigo,
    secondary: AppColors.teal,
    tertiary: AppColors.ochre,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: buildAppTextTheme(colorScheme),
    useMaterial3: true,
  );
}
```

Thème clair uniquement pour le MVP (le dark mode n'est pas demandé dans le
cahier des charges ; à ajouter si besoin exprimé plus tard). Le skill
frontend-design sera consulté au moment de construire les écrans.

## Mise en place i18n

- `l10n.yaml` à la racine : `arb-dir: lib/l10n`, `template-arb-file:
  app_en.arb`, `output-localization-file: app_localizations.dart`
- `flutter_localizations` + `intl` dans `pubspec.yaml`, `generate: true`
- `MaterialApp.router` avec `localizationsDelegates` + `supportedLocales:
  [Locale('fr'), Locale('en')]`
- Détection automatique via la locale système, override manuel stocké dans
  `shared_preferences` (réglages)
- ARB créés dès le jalon Socle avec les premières clés (titres d'écrans
  vides, boutons communs), pour éviter le rétrofit plus tard

## Plan de jalons

1. **Socle** — init FVM (version stable choisie via `fvm flutter releases`
   au moment venu), structure feature-first, `theme.dart`, `go_router`,
   i18n ARB FR/EN, config Drift + première génération `build_runner`
2. **Événements** — CRUD + archivage, champs personnalisés, choix du mode
   de présence
3. **Bénéficiaires** — ajout manuel puis import CSV (mapping des colonnes)
4. **Tickets** — génération identifiants + QR, aperçu, choix modèle/champs
   affichés, dimensions précises des 3 modèles tranchées ici
5. **Export/partage** — PDF (3 modèles), partage individuel
6. **Contrôle de présence** — scan + saisie de secours, règles selon mode,
   compteur animé
7. **Sauvegarde** — export/import du fichier unique (copie du fichier
   SQLite)
8. **Finitions** — animations, retour haptique, empty states, gestion
   d'erreurs, polish visuel

Chaque jalon doit être livré fonctionnel et testable avant de passer au
suivant, conformément au cahier des charges.

## Stratégie de test (rappel du cahier des charges)

- Tests unitaires en priorité sur la logique métier sensible : génération
  des identifiants (unicité, format), règles de check-in selon le mode
  (blocage en mode simple, historique en mode multiple), parsing/mapping de
  l'import CSV.
- Tests de widget sur les écrans clés (formulaire événement, écran de scan,
  compteur).
- Pas de couverture exhaustive au MVP : cibler les zones à risque de
  régression.
- Exécution via `fvm flutter test`.
