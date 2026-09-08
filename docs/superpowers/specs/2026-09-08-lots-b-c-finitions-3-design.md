# DIF Pass — Design des lots B et C (Finitions 3)

Statut : valide par l'utilisateur le 2026-09-08.

## Contexte

Lot A (Finitions 2) est fusionne dans main. Cette session poursuit la liste
de retours remontee apres jalon 8 et le test sur Tecno CE9, avec deux lots
traites ensemble car ils partagent la meme base de donnees deja en place
(`checkInsProvider`, `ticketsProvider`) :

- **Lot B** : un ecran d'historique des passages consultable, et un
  indicateur de presence sur la liste des tickets.
- **Lot C** : un garde-fou avant de modifier ou supprimer un beneficiaire
  qui a deja un ticket genere.

Aucun nouveau repository n'est necessaire : `CheckInRepository.watchCheckInsForEvent`
et son provider `checkInsProvider(eventId)` existent deja depuis le jalon 6
(la table `CheckIns` conserve deja tout l'historique des passages, y
compris en mode presence simple ou l'UI ne l'affichait pas jusqu'ici) ;
`ticketsProvider(eventId)` existe depuis le jalon 4. Les deux lots sont des
compositions de donnees deja disponibles, pas de nouvelles sources.

## Decisions actees

- **Acces a l'historique : deux points d'entree.** Une icone dans l'AppBar
  de `check_in_scan_screen.dart` (acces pendant que l'agent scanne), et un
  acces depuis la liste des evenements (pour consulter apres coup, "faire
  le point"). Les deux menent au meme ecran.
- **Icone Archiver de `EventCard` transformee en menu.** `EventCard` a deja
  4 icones (beneficiaires, tickets, check-in, archiver) dans la zone
  d'actions de son `ListTile`. Ajouter une 5e icone brute risquait un
  debordement sur un petit ecran (le Tecno CE9 qui a deja servi de
  reference dans ce projet). L'icone Archiver devient un `PopupMenuButton`
  ("Plus d'actions") regroupant "Archiver" et "Historique des passages" ;
  les trois actions les plus frequentes (beneficiaires/tickets/check-in)
  restent des icones directes.
- **Historique : liste chronologique, pas de resume agrege.** Tri par
  horodatage decroissant (le plus recent en premier). En mode
  entrees/sorties multiples, chaque passage d'un meme ticket apparait
  comme une ligne distincte, coherent avec le modele de donnees qui garde
  deja tout l'historique par design (jalon 6).
- **Indicateur sur la liste des tickets : niveau de detail selon le mode.**
  Mode presence simple : une pastille "Present" si au moins un passage
  existe pour ce ticket, rien sinon. Mode entrees/sorties multiples : le
  nombre de passages ("N passages"), puisque le compte a un sens dans ce
  mode alors qu'une simple pastille presence/absence perdrait de
  l'information deja disponible sans cout supplementaire (le compte est
  deja calculable depuis les memes donnees).
- **Garde-fou suppression : meme dialogue, texte etendu.** Le dialogue de
  confirmation de suppression d'un beneficiaire existe deja
  (`beneficiaries_list_screen.dart`). Quand ce beneficiaire a deja un
  ticket, le corps du dialogue est remplace par un texte qui previent
  explicitement que le ticket associe sera aussi supprime (suppression en
  cascade deja en place dans le schema Drift, `Tickets.beneficiaryId
  references Beneficiaries onDelete: cascade`) et qu'un ticket deja
  imprime ou partage deviendrait invalide. Pas de nouveau mecanisme, un
  texte conditionnel sur le dialogue existant.
- **Garde-fou modification : dialogue de confirmation bloquant.** Tranche
  explicitement en faveur du meme niveau de friction que la suppression
  (pas d'une simple bannière d'avertissement) : editer le nom ou un champ
  personnalise d'un beneficiaire dont le ticket est deja genere/imprime/
  partage peut rendre ce ticket incoherent avec les donnees reelles, et
  l'utilisateur doit explicitement confirmer avant que l'enregistrement ne
  parte. Sans ticket existant pour ce beneficiaire, aucun changement de
  comportement (le cas majoritaire, creation ou edition avant generation
  des tickets, reste sans friction ajoutee).

## Architecture

### Lot B : ecran d'historique

```
lib/features/checkin/presentation/screens/
  check_in_history_screen.dart   (nouveau, route /events/:id/checkin/history)
```

`CheckInHistoryScreen(eventId)` watche `checkInsProvider(eventId)`,
`ticketsProvider(eventId)`, `beneficiariesProvider(eventId)`. Construit une
carte `ticketId -> nom du beneficiaire` (meme pattern que
`tickets_screen.dart`'s `beneficiaryNames`), trie les `CheckIn` par
`scannedAt` decroissant, et affiche une `ListView` de lignes nom + heure
(`DateFormat.Hm`, meme format que `checkinAlreadyRecordedMessage`). Etat
vide via le widget partage `EmptyState` (jalon 8) si la liste est vide.
Etat d'erreur (l'un des trois flux echoue) via `ErrorState`, `onRetry`
invalidant les trois providers, meme pattern que `tickets_screen.dart`.

Route ajoutee dans `app_router.dart`, memes garde-fous `redirect` que les
routes `/events/:id/...` existantes :
```dart
GoRoute(
  path: '/events/:id/checkin/history',
  redirect: (context, state) {
    final id = int.tryParse(state.pathParameters['id'] ?? '');
    return id == null ? '/' : null;
  },
  builder: (context, state) => CheckInHistoryScreen(
    eventId: int.parse(state.pathParameters['id']!),
  ),
),
```

`check_in_scan_screen.dart` gagne une deuxieme action dans son AppBar (a
cote du bouton saisie manuelle) qui navigue vers cette route.

`events_list_screen.dart`/`event_card.dart` : `EventCard.onArchive` est
remplace par un `PopupMenuButton` avec deux entrees ("Archiver",
"Historique des passages"), `EventCard` gagne un nouveau callback
`onViewHistory` en plus de `onArchive` (les deux restent necessaires,
seule leur presentation change).

### Lot B : indicateur sur la liste des tickets

`tickets_screen.dart` ajoute un watch sur `checkInsProvider(eventId)` et
construit `Map<int, int> passageCountByTicketId` (compte des `CheckIn` par
`ticketId`). Chaque `ListTile` de ticket affiche, apres le sous-titre
existant (l'identifiant lisible en police mono), un badge conditionnel :
rien si le compte est 0, un texte/icone "Present" si `event.presenceMode
== PresenceMode.simple`, sinon "N passages".

### Lot C : garde-fou beneficiaire

Les deux ecrans concernes watchent (ou etendent leur watch existant de)
`ticketsProvider(eventId)` pour calculer, pour un beneficiaire donne,
`hasTicket = tickets.any((t) => t.beneficiaryId == beneficiary.id)`.

`beneficiaries_list_screen.dart` : `_confirmDelete` choisit le corps du
dialogue selon `hasTicket` (deux cles ARB au lieu d'une, meme titre, meme
structure Oui/Annuler).

`beneficiary_form_screen.dart` : `_save`, uniquement quand `_isEditing &&
hasTicket`, affiche un `showDialog<bool>` de confirmation avant de
poursuivre l'enregistrement (meme structure que les confirmations deja
existantes ailleurs dans l'app, ex. generation de tickets). Si annule,
`_save` s'arrete sans rien ecrire, `_loading` redevient false.

## Tests

- `CheckInHistoryScreen` : test verifiant l'ordre chronologique decroissant
  et l'affichage du nom associe a chaque passage (via des fakes
  `FakeCheckInRepository`/`FakeTicketRepository`/`FakeBeneficiaryRepository`
  deja existants dans le projet) ; test de l'etat vide.
- `tickets_screen.dart` : tests etendus verifiant la pastille "Present" en
  mode simple et le compte "N passages" en mode multiple, et l'absence de
  badge quand aucun passage n'existe pour un ticket.
- `beneficiaries_list_screen.dart` : test verifiant que le corps du
  dialogue de suppression change quand le beneficiaire a un ticket.
- `beneficiary_form_screen.dart` : test verifiant que sauvegarder un
  beneficiaire SANS ticket ne declenche aucun dialogue (comportement
  actuel preserve), et qu'editer un beneficiaire AVEC ticket affiche le
  dialogue de confirmation, dont annuler n'enregistre rien.
- `event_card_test.dart` (ou equivalent existant) : test verifiant que le
  menu "Plus d'actions" expose bien les deux entrees et declenche le bon
  callback pour chacune.

## Hors perimetre

- Filtrage ou recherche dans l'ecran d'historique (par nom, par plage
  horaire) : liste chronologique simple suffit pour ce lot, a
  reconsiderer si un evenement avec un tres grand nombre de passages rend
  la liste difficile a parcourir en pratique.
- Export de l'historique des passages (CSV, PDF) : non demande, distinct
  de l'export de sauvegarde complet du jalon 7.
- Empecher completement la modification/suppression d'un beneficiaire
  avec ticket (bloquer plutot que confirmer) : le cahier des charges ne
  demande pas de verrouillage total, et une confirmation explicite est
  jugee suffisante, coherent avec le niveau de friction deja choisi
  ailleurs dans l'app (jalon 7, generation de tickets).
- Schema d'identifiants pret pour une future synchronisation multi-
  appareils (lot D) : hors perimetre de cette session, decision
  d'architecture separee.
