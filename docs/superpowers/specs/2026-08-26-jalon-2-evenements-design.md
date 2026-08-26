# DIF Pass — Design du jalon 2 (Evenements)

Statut : valide par l'utilisateur le 2026-08-26.

## Contexte

Jalon 1 (Socle) est fusionne dans main : structure feature-first (`lib/core/`),
theme DIF, i18n FR/EN, go_router (avec un ecran d'accueil provisoire), et la
base Drift avec les six tables MVP (dont `Events`, `CustomFields`, `Tickets`,
`CheckIns`, deja creees et avec les cles etrangeres appliquees).

Ce jalon couvre la section 1 du cahier des charges (`Prompt_Lancement_Claude_Code_DIF_Pass.md`) :
CRUD evenement + archivage (soft delete), definition des champs personnalises,
choix du mode de controle de presence. La gestion des beneficiaires (section 2)
reste hors scope, elle arrive au jalon 3.

## Decisions actees

- **Champs personnalises modifiables tant qu'aucun ticket n'existe pour
  l'evenement.** La regle interroge directement la table `Tickets` (deja en
  base). Comme aucun ticket n'est genere avant le jalon 4, la regle est
  toujours vraie pour l'instant ; elle s'activera automatiquement plus tard
  sans retouche du code.
- **Mode de presence modifiable tant qu'aucun check-in n'existe pour
  l'evenement**, meme logique via la table `CheckIns`.
- **Logo** : selection d'image des ce jalon via `image_picker` (galerie ou
  appareil photo), redimensionnee et compressee via les parametres natifs du
  picker (`maxWidth: 512, maxHeight: 512, imageQuality: 80`), stockee en
  BLOB comme prevu par le schema du jalon 1. Pas de package de compression
  supplementaire.
- **Tri de la liste des evenements actifs** : par date d'evenement, le plus
  proche en premier.
- **Vue calendaire** : evaluee (cout faible : un package `table_calendar`,
  aucun changement de repository, un widget en plus) mais hors scope du
  cahier des charges MVP, reportee au jalon 8 (Finitions) si demandee plus
  tard.

## Architecture (repository + domaine)

```
lib/features/events/
  domain/
    event.dart                 (modele Event, decouple de Drift)
    custom_field.dart          (modele CustomField)
    presence_mode.dart         (enum PresenceMode { simple, multiple })
    custom_field_type.dart     (enum CustomFieldType { text, number })
  data/
    event_repository.dart          (interface)
    drift_event_repository.dart    (implementation Drift)
  presentation/
    providers/
      event_providers.dart     (Riverpod : repository, watchActiveEvents,
                                 watchArchivedEvents, watchCustomFields)
    screens/
      events_list_screen.dart      (route "/", remplace l'ecran provisoire
                                     du jalon 1)
      event_form_screen.dart       (route "/events/new" et "/events/:id/edit")
      event_archive_screen.dart    (route "/events/archives")
    widgets/
      event_card.dart
      custom_field_editor.dart     (liste dynamique ajout/suppression de
                                     champs personnalises)
```

Les ecrans et les providers ne dependent que de l'interface `EventRepository`,
jamais de Drift directement. `DriftEventRepository` est la seule classe a
importer `AppDatabase`. C'est cette separation qui permettra de brancher une
source cloud plus tard sans toucher aux ecrans, conformement a la contrainte
d'architecture du cahier des charges.

### Modeles de domaine

```dart
enum PresenceMode { simple, multiple }
enum CustomFieldType { text, number }

class Event {
  final int id;
  final String shortCode;       // "EVT3"
  final String name;
  final DateTime date;
  final String? location;
  final Uint8List? logo;
  final PresenceMode presenceMode;
  final DateTime? archivedAt;
  final DateTime createdAt;

  bool get isArchived => archivedAt != null;
}

class CustomField {
  final int id;
  final int eventId;
  final String label;
  final CustomFieldType type;
  final int sortOrder;
  final bool showOnTicket;
}
```

### Interface `EventRepository`

```dart
abstract class EventRepository {
  Stream<List<Event>> watchActiveEvents();   // archivedAt IS NULL, tries par date
  Stream<List<Event>> watchArchivedEvents(); // archivedAt IS NOT NULL
  Future<Event> getEvent(int id);
  Stream<List<CustomField>> watchCustomFields(int eventId);

  Future<int> createEvent({
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
    required List<NewCustomField> customFields,
  });

  Future<void> updateEvent(
    int id, {
    required String name,
    required DateTime date,
    String? location,
    Uint8List? logo,
    required PresenceMode presenceMode,
  });

  Future<bool> canEditCustomFields(int eventId);
  Future<void> replaceCustomFields(int eventId, List<NewCustomField> customFields);

  Future<bool> canEditPresenceMode(int eventId);

  Future<void> archiveEvent(int id);
  Future<void> restoreEvent(int id);
  Future<void> deleteEventPermanently(int id); // uniquement depuis les archives
}

class NewCustomField {
  final String label;
  final CustomFieldType type;
  final int sortOrder;
  final bool showOnTicket;
}
```

### Generation du `shortCode`

Pas de compteur separe a maintenir. `DriftEventRepository.createEvent` insere
la ligne, recupere l'id auto-incremente genere par SQLite, puis met a jour
`shortCode = 'EVT$id'` dans la meme transaction Drift (`db.transaction`). Ca
garantit un `shortCode` unique pour toujours, meme si un evenement est
supprime definitivement plus tard : `Events.id` utilise deja
`integer().autoIncrement()`, qui genere `PRIMARY KEY AUTOINCREMENT` en SQL
(verifie dans `lib/core/database/app_database.g.dart`), donc SQLite ne
reutilise jamais un id supprime.

## Ecrans

- **Liste des evenements** (`events_list_screen.dart`, route `/`, remplace
  l'ecran provisoire du jalon 1) : cartes triees par date d'evenement (plus
  proche en premier), bouton flottant "Nouvel evenement", acces a
  "Archives", etat vide soigne si aucun evenement actif.
- **Formulaire** (`event_form_screen.dart`, meme ecran pour creation et
  edition) : nom (obligatoire), date, lieu (optionnel), logo (optionnel via
  `image_picker`), mode de presence (segmented control simple/multiple,
  desactive si `canEditPresenceMode` est faux), liste de champs
  personnalises editable (libellé + type text/number + case "afficher sur
  le ticket", desactivee si `canEditCustomFields` est faux). Le rendu visuel
  exact (espacements, style des champs, feedback de validation) sera affine
  avec le skill frontend-design au moment du code, comme prevu au cahier des
  charges.
- **Archives** (`event_archive_screen.dart`, route `/events/archives`) :
  liste des evenements archives, action "Restaurer" et "Supprimer
  definitivement" (avec confirmation explicite avant suppression
  definitive, cf regle de dev generale sur les actions irreversibles).

Changement de router : les routes `/events/new`, `/events/:id/edit`,
`/events/archives` s'ajoutent a `lib/core/router/app_router.dart`. La route
`/` pointe desormais vers `EventsListScreen` ; le
`_PlaceholderHomeScreen` du jalon 1 est supprime.

## Tests

Priorite a la logique metier sensible, comme demande au cahier des charges :

- `DriftEventRepository` : generation du `shortCode` (unicite, format
  `EVT<id>`), filtrage actifs/archives, `canEditCustomFields` /
  `canEditPresenceMode` (vrai sans ticket/check-in, faux si un ticket ou un
  check-in existe deja pour l'evenement, insere directement en base pour le
  test), `archiveEvent` / `restoreEvent` (bascule correcte de
  `archivedAt`), `deleteEventPermanently` (suppression reelle, y compris des
  champs personnalises lies).
- Tests de widget legers : validation du formulaire (nom obligatoire),
  affichage de la liste a partir d'un `EventRepository` fake via override de
  provider (`ProviderScope(overrides: [...])`), affichage de l'ecran
  Archives.
