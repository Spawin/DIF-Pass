# DIF Pass — Design du jalon 4 (Tickets)

Statut : valide par l'utilisateur le 2026-08-28.

## Contexte

Jalon 3 (Beneficiaires) est fusionne dans main : ajout manuel, import CSV,
edition, suppression. Ce jalon couvre la section 3 du cahier des charges
(`Prompt_Lancement_Claude_Code_DIF_Pass.md`) : generation des identifiants
de ticket (partie lisible + composante aleatoire) et du QR code, un ecran
d'apercu, le choix du modele de ticket et des champs personnalises affiches.

Precision sur le decoupage des jalons 4/5 : ce jalon produit un **apercu a
l'ecran** (widget Flutter) des tickets, pas encore le PDF imprimable. Le
moteur `pdf`/`printing` et les dimensions d'impression precises restent au
jalon 5 (Export/partage), comme prevu dans le plan de jalons d'origine. Une
note anterieure (design du jalon 2) suggerait de trancher les dimensions
d'impression "au jalon 4 une fois le moteur PDF en place" ; c'est imprecis,
le moteur PDF arrive au jalon 5. Les dimensions d'impression exactes sont
donc repoussees au jalon 5.

## Decisions actees

- **Declenchement de la generation et choix du modele** : un nouvel ecran
  "Tickets" par evenement (icone sur `EventCard`, meme pattern que
  Beneficiaires/Archiver au jalon 3), sans toucher au formulaire
  d'evenement du jalon 2 deja fusionne.
- **Generation en masse idempotente** : relancer "Generer les tickets"
  apres l'ajout de nouveaux beneficiaires ne cree que les tickets manquants.
  Les tickets deja emis (potentiellement deja imprimes/partages) ne sont
  jamais recrees ni modifies, conformement au principe anti-fraude (un
  ticket valide ne doit jamais changer une fois emis).
- **Partie lisible de l'identifiant** : numero sequentiel par evenement,
  zero-padde sur 4 chiffres ("0001", "0042"...), calcule depuis le plus
  grand `readableId` existant pour l'evenement + 1 (jamais recalcule depuis
  0), donc sur meme en generation incrementale repetee.
- **Composante aleatoire** : 4 caracteres tires d'un alphabet excluant les
  caracteres ambigus (`O`/`0`, `I`/`1`) pour rester lisibles en saisie
  manuelle de secours (decision actee au jalon 1) :
  `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Genere via `Random.secure()` (classe
  standard `dart:math`, aucune nouvelle dependance) pour un tirage reellement
  imprevisible, coherent avec l'objectif anti-fraude.
- **Prerequis inclus** : `eventProvider` (jalon 3) passe en
  `.autoDispose`, recommandation de la revue finale du jalon 3, faite ici
  puisque ce jalon retouche `event_providers.dart` de toute facon.

## Architecture (repository + domaine)

```
lib/features/tickets/
  domain/
    ticket.dart              (Ticket : id, beneficiaryId, eventId,
                               readableId, randomPart, qrPayload, createdAt)
    ticket_template.dart     (enum TicketTemplate { compact, standard, elegant })
  data/
    ticket_repository.dart          (interface)
    drift_ticket_repository.dart    (implementation Drift)
    ticket_id_generator.dart        (generation identifiant + composante
                                      aleatoire, fonction pure, testable
                                      isolement, aucune dependance Drift)
  presentation/
    providers/
      ticket_providers.dart
    screens/
      tickets_screen.dart         (route /events/:id/tickets : selecteur
                                    de modele, bouton "Generer les tickets",
                                    liste des tickets)
      ticket_preview_screen.dart  (route /events/:id/tickets/:ticketId :
                                    apercu detaille d'un ticket)
    widgets/
      ticket_card_preview.dart    (rendu visuel du ticket, un style par
                                    modele)
```

Meme pattern repository que les jalons precedents. L'ecran d'apercu compose
`TicketRepository.getTicket`, `BeneficiaryRepository.getBeneficiary`
(donne deja `customFieldValues: Map<int, String>`, jalon 3),
`EventRepository.getEvent` et `customFieldsProvider` (jalon 2) pour
assembler les donnees d'affichage — pas de nouvelle requete jointe complexe
dans `TicketRepository`, qui reste concentre sur les tickets eux-memes.

### Modele de domaine

```dart
enum TicketTemplate { compact, standard, elegant }

class Ticket {
  final int id;
  final int beneficiaryId;
  final int eventId;
  final String readableId;   // "0042"
  final String randomPart;   // "X7K9"
  final String qrPayload;    // "EVT3-0042-X7K9"
  final DateTime createdAt;
}
```

### Generateur d'identifiant (fonction pure)

```dart
class GeneratedTicketId {
  final String readableId;
  final String randomPart;
  String payloadFor(String eventShortCode) =>
      '$eventShortCode-$readableId-$randomPart';
}

GeneratedTicketId generateTicketId({required int sequence}) {
  // sequence = plus grand readableId existant (en int) + 1, fourni par
  // l'appelant (le repository, qui connait l'etat de la base)
  final readableId = sequence.toString().padLeft(4, '0');
  final randomPart = _randomCode(4); // Random.secure(), alphabet sans
                                      // caracteres ambigus
  return GeneratedTicketId(readableId: readableId, randomPart: randomPart);
}
```

Fonction pure : la sequence est un `int` fourni par l'appelant (pas de
lecture DB ici), ce qui la rend testable sans base de donnees — seule la
composante aleatoire varie entre deux appels a sequence egale, testable en
verifiant le format (longueur, alphabet) plutot que l'egalite exacte.

### Interface `TicketRepository`

```dart
abstract class TicketRepository {
  Stream<List<Ticket>> watchTicketsForEvent(int eventId); // tries par readableId
  Future<Ticket> getTicket(int id);
  Future<int> generateMissingTickets(int eventId); // idempotent, retourne
                                                     // le nombre de tickets
                                                     // reellement crees
}
```

`generateMissingTickets` : recupere les beneficiaires de l'evenement (via
`BeneficiaryRepository`, injecte dans le constructeur du repository comme
`EventRepository` l'est deja implicitement pour d'autres features),
determine ceux qui n'ont pas encore de ticket, et pour chacun, dans l'ordre
de creation du beneficiaire, insere un ticket avec l'identifiant suivant
dans la sequence de l'evenement. Une seule transaction Drift pour
l'ensemble de l'operation.

### Extension d'`EventRepository` (jalon 2)

```dart
Future<void> updateTicketTemplate(int eventId, TicketTemplate template);
```

Methode dediee plutot que de surcharger `updateEvent` (qui demande tous les
autres champs). `Events.ticketTemplate` : nouvelle colonne texte, defaut
`'standard'`, convertie en `TicketTemplate` dans le repository layer (meme
pattern que `presenceMode`/`fieldType`, ponytail deja etabli au jalon 1).
Pas de bump de version de schema : le projet n'est pas encore publie, meme
principe que l'ajout des cascades au jalon 2.

## Ecrans

- **Ecran Tickets** (`tickets_screen.dart`) : selecteur de modele
  (`SegmentedButton<TicketTemplate>`, 3 options), bouton "Generer les
  tickets" (desactive si tous les beneficiaires actifs de l'evenement ont
  deja un ticket), liste des tickets (nom du beneficiaire + identifiant
  lisible), tap sur une ligne -> apercu.
- **Apercu d'un ticket** (`ticket_preview_screen.dart`) : QR code
  (`qr_flutter`, deja en dependance depuis le jalon 1), nom du beneficiaire,
  identifiant lisible, nom/logo de l'evenement, valeurs des champs
  personnalises coches `showOnTicket` (deja definis au jalon 2). Rendu
  visuellement distinct selon le modele choisi (compact/standard/elegant),
  sans viser les dimensions d'impression exactes (jalon 5).

## Tests

- `generateTicketId` : format (4 chiffres zero-paddes, 4 caracteres
  aleatoires dans l'alphabet attendu), le payload complet correspond au
  format attendu.
- `DriftTicketRepository` : `generateMissingTickets` cree un ticket par
  beneficiaire sans ticket, ne recree pas ceux qui existent deja (appel
  repete = idempotent), la sequence continue correctement apres un premier
  lot de generation partielle, `watchTicketsForEvent` trie par
  `readableId` et se limite a l'evenement demande.
- Tests de widget legers sur l'ecran Tickets (bouton desactive quand tout
  est genere, liste apres generation) et l'apercu (champs `showOnTicket`
  bien affiches, ceux non coches absents).
