# DIF Pass — Design du jalon 6 (Controle de presence)

Statut : valide par l'utilisateur le 2026-08-29.

## Contexte

Jalon 5 (Export/partage) est fusionne dans main : tickets generes, apercu,
export PDF en masse, partage individuel. Ce jalon couvre la section 4 du
cahier des charges (`Prompt_Lancement_Claude_Code_DIF_Pass.md`) : scanner
le ticket d'un beneficiaire a l'entree d'un evenement, verifier/enregistrer
sa presence selon le mode choisi a la creation de l'evenement (jalon 2,
`Event.presenceMode`), et afficher un compteur en direct.

La table `CheckIns` (id, ticketId, eventId, scannedAt) existe deja depuis
le schema du jalon 1. `mobile_scanner` est deja en dependance depuis le
jalon 1. Aucune migration de schema, aucune nouvelle dependance necessaire
pour ce jalon.

## Decisions actees

- **Saisie manuelle de secours** : un bouton "Saisie manuelle" sur l'ecran
  de scan remplace la camera par un champ texte (et inversement), sur le
  meme ecran. Pas d'ecran ni de route separee.
- **Denominateur du compteur** : le nombre total de **tickets generes**
  pour l'evenement (pas le nombre de beneficiaires : seuls les
  beneficiaires avec un ticket genere sont controlables a l'entree).
- **Numerateur du compteur, dans les deux modes** : le nombre de tickets
  **distincts** ayant recu au moins un scan, quel que soit le nombre de
  scans par ticket. Meme definition en mode simple et en mode entrees/
  sorties multiples, ce qui evite de devoir suivre un etat entree/sortie
  et garde le format "X/Y" toujours coherent (X ne peut jamais depasser Y).
- **Retour apres un scan** : affiche le nom du beneficiaire en plus de la
  couleur/statut (vert = enregistre, rouge = deja enregistre ou
  introuvable), pour que l'organisateur puisse verifier visuellement
  l'identite avant de laisser entrer la personne.
- **Regle de blocage par mode** (rappel du cahier des charges, deja actee
  au jalon 2 avec `PresenceMode`) : mode simple, un seul scan enregistre
  par ticket, les suivants sont bloques avec l'horodatage du premier scan
  affiche ; mode multiple, chaque scan est enregistre sans blocage. La
  table `CheckIns` conserve **tous** les scans dans les deux cas, la regle
  de blocage et le compteur sont une question d'affichage/logique
  applicative, pas de structure de donnees differente.
- **Pas de vue "liste des presents"** dans ce jalon : le cahier des
  charges ne demande que le compteur en direct pendant la session de scan,
  pas un ecran de consultation separe des presences. Hors perimetre (voir
  plus bas).

## Architecture

```
lib/features/checkin/
  domain/
    check_in.dart              (CheckIn : id, ticketId, eventId, scannedAt)
    check_in_outcome.dart      (CheckInOutcome, type scelle)
  data/
    check_in_repository.dart          (interface)
    drift_check_in_repository.dart    (implementation Drift)
  presentation/
    providers/
      check_in_providers.dart
    screens/
      check_in_scan_screen.dart   (route /events/:id/checkin)
```

### `TicketRepository` (jalon 4) : nouvelle methode de resolution

```dart
Future<Ticket?> findTicketForCheckIn(int eventId, String rawInput);
```

Methode unique geree cote Drift, en deux temps, toujours filtree sur
l'evenement en cours : (1) correspondance exacte sur `qrPayload` (couvre
le scan QR, qui contient toujours l'identifiant complet, et le cas ou
l'utilisateur tape l'identifiant complet a la main) ; (2) si aucune
correspondance, correspondance sur `readableId` seul apres normalisation
de la saisie (`trim()`, casse insensible) (couvre le cas ou l'utilisateur
ne tape que la partie lisible, ex. "0042"). Retourne `null` si rien ne
correspond (ticket introuvable ou appartenant a un autre evenement, memes
consequences pour l'utilisateur, un seul etat "introuvable" cote ecran).
Ces deux etapes couvrent a elles seules "accepte la partie lisible ou
l'identifiant complet" du cahier des charges, sans logique de decoupage
de chaine supplementaire.

### Modele de domaine

```dart
class CheckIn {
  final int id;
  final int ticketId;
  final int eventId;
  final DateTime scannedAt;
}
```

```dart
sealed class CheckInOutcome {}

class CheckInRecorded extends CheckInOutcome {
  final CheckIn checkIn;
}

class CheckInAlreadyRecorded extends CheckInOutcome {
  final CheckIn existing; // scannedAt du premier scan, pour l'alerte "deja enregistre a HH:MM"
}
```

Le cas "ticket introuvable" n'est pas un `CheckInOutcome` : il se traduit
par un `Ticket? == null` renvoye par `findTicketForCheckIn`, avant meme
d'appeler `CheckInRepository`. L'ecran distingue ainsi deux causes
d'echec independantes (introuvable vs deja enregistre) sans les melanger
dans un seul type.

### Interface `CheckInRepository`

```dart
abstract class CheckInRepository {
  Stream<List<CheckIn>> watchCheckInsForEvent(int eventId);
  Future<CheckInOutcome> recordCheckIn(Ticket ticket, PresenceMode mode);
}
```

`recordCheckIn` : en mode `simple`, verifie s'il existe deja une ligne
`CheckIns` pour ce `ticket.id` ; si oui, retourne
`CheckInAlreadyRecorded(existing)` sans rien inserer ; si non, insere et
retourne `CheckInRecorded`. En mode `multiple`, insere toujours une
nouvelle ligne et retourne `CheckInRecorded`. `PresenceMode` vient de
`event.presenceMode` (jalon 2), fourni par l'appelant (l'ecran a deja
l'`Event` charge), le repository ne le redecouvre pas lui-meme.

### Provider du compteur

```dart
final checkInCounterProvider = Provider.family<(int, int), int>((ref, eventId) {
  final tickets = ref.watch(ticketsProvider(eventId)).valueOrNull ?? const [];
  final checkIns = ref.watch(checkInsProvider(eventId)).valueOrNull ?? const [];
  final distinctCheckedIn = checkIns.map((c) => c.ticketId).toSet().length;
  return (distinctCheckedIn, tickets.length);
});
```

Recalcule automatiquement des que `ticketsProvider` (jalon 4) ou le nouveau
`checkInsProvider` (`watchCheckInsForEvent`) emettent, ce qui anime le
compteur en direct sans code de synchronisation manuel.

## Ecran

`CheckInScanScreen({required int eventId})`, route `/events/:id/checkin`,
declenchee par une 4e icone sur `EventCard` (meme emplacement que
Tickets/Beneficiaires/Archiver, jalons 3/4).

- Camera (`mobile_scanner`) plein ecran avec un cadre de visee anime
  (overlay dessine par-dessus la preview camera, pas de logique metier
  dedans), et le compteur ("127/300 arrives") anime en overlay
  (`flutter_animate`), alimente par `checkInCounterProvider`.
- Bouton "Saisie manuelle" qui bascule l'ecran entre la vue camera et un
  champ texte + bouton de validation (meme ecran, pas de navigation, la
  camera est mise en pause pendant la saisie manuelle pour ne pas
  continuer a consommer la batterie/le CPU inutilement).
- Le traitement d'un scan ou d'une saisie est isole dans une fonction/
  methode independante du widget camera lui-meme, par exemple
  `Future<void> _handleDetection(String rawInput)`, qui appelle
  `findTicketForCheckIn` puis, si un ticket est trouve, `recordCheckIn`.
  Cette separation est ce qui rend la logique testable sans materiel
  camera, meme principe deja applique dans ce projet pour `file_picker`
  (jalon 3) et `printing` (jalon 5) : le declenchement est teste, pas
  l'integration plateforme sous-jacente.
- Apres traitement, affichage d'un retour pendant ~1.5-2 secondes avant de
  reprendre le scan (la camera reste en pause le temps du retour, pour
  eviter de re-detecter le meme QR encore visible dans le cadre) :
  - Vert + nom du beneficiaire : `CheckInRecorded`.
  - Rouge + nom du beneficiaire + heure du premier scan : `CheckInAlreadyRecorded`.
  - Rouge + message "introuvable" (pas de nom a afficher) : `findTicketForCheckIn` a renvoye `null`.
  - Retour haptique a chaque resultat (`HapticFeedback` de `package:flutter/services.dart`,
    deja dans le SDK Flutter, aucune nouvelle dependance), intensite
    differente succes/echec.

## Tests

- `DriftCheckInRepository.recordCheckIn` : mode simple, un premier scan
  cree une ligne et renvoie `CheckInRecorded` ; un deuxieme scan du meme
  ticket ne cree pas de nouvelle ligne et renvoie `CheckInAlreadyRecorded`
  avec l'horodatage du premier scan. Mode multiple : deux scans du meme
  ticket creent deux lignes, chacune renvoie `CheckInRecorded`.
- `DriftTicketRepository.findTicketForCheckIn` (extension du jalon 4) :
  trouve par `qrPayload` complet, trouve par `readableId` seul, ne trouve
  rien pour un identifiant d'un autre evenement, ne trouve rien pour un
  identifiant qui n'existe pas.
- `checkInCounterProvider` : renvoie bien (tickets distincts scannes,
  total tickets), y compris apres plusieurs scans du meme ticket en mode
  multiple (le numerateur ne double pas).
- Tests de widget sur `CheckInScanScreen` cibles sur `_handleDetection`
  appelee directement avec une chaine (succes, deja enregistre,
  introuvable), pas sur le flux camera reel. Bouton de bascule vers la
  saisie manuelle : verifie que le champ texte apparait et que la camera
  disparait (et inversement).

## Hors perimetre

- Vue "liste des presents"/roster de consultation des presences : non
  demandee par le cahier des charges pour ce jalon (uniquement le
  compteur en direct pendant la session de scan). Pourrait etre ajoutee
  dans un jalon ulterieur si demande.
- Personnalisation du delai d'affichage du retour (~1.5-2s) ou de
  l'intensite du retour haptique : valeurs fixes pour ce jalon, pas de
  reglage utilisateur.
- Export/consultation de l'historique des `CheckIns` en dehors du
  compteur en direct : hors perimetre, potentiellement lie a la
  sauvegarde (jalon 7) ou a des finitions ulterieures.
