# DIF Pass — Design du jalon 5 (Export/partage)

Statut : valide par l'utilisateur le 2026-08-29.

## Contexte

Jalon 4 (Tickets) est fusionne dans main : generation des identifiants de
ticket, QR code, ecran d'apercu par ticket, choix du modele (compact,
standard, elegant) persiste par evenement. Ce jalon couvre la section 3 du
cahier des charges (`Prompt_Lancement_Claude_Code_DIF_Pass.md`), le point
laisse en suspens par le jalon 4 :

> Export **PDF** de tous les tickets d'un evenement, pret a imprimer (mise
> en page propre selon le modele choisi).
> Partage individuel d'un ticket (image ou PDF) via le partage natif
> (WhatsApp, email, SMS).

`pdf`, `printing` et `share_plus` sont deja en dependance depuis le jalon 1
(prevus dans le cahier des charges), aucun nouveau package necessaire.

## Decisions actees

- **Rendu du PDF** : construit directement avec les widgets natifs du
  package `pdf` (`pw.Widget`), pas une capture image des widgets Flutter de
  l'ecran d'apercu. Un rendu vectoriel reste net a toute echelle
  d'impression, produit un fichier plus leger, et garde le texte
  selectionnable dans le PDF. Le QR code utilise
  `pw.BarcodeWidget(barcode: Barcode.qrCode(), data: ticket.qrPayload)`,
  deja fourni par le package `pdf`, donc aucune nouvelle dependance ni
  aucune conversion image intermediaire.
- **Mise en page de l'export en masse** : grille decoupable sur page A4
  (plusieurs tickets par page, a decouper aux ciseaux apres impression),
  pas un ticket par page. Chaque modele definit une taille de carte cible
  en millimetres (voir Architecture) et la page calcule automatiquement
  combien de cartes tiennent par ligne/colonne selon cette taille, avec des
  marges de page et un espacement inter-cartes fixes. Le nombre de tickets
  par page varie donc naturellement selon le modele choisi, sans grille
  codee en dur separement pour chacun.
- **Format de partage individuel** : PDF uniquement (pas d'image PNG en
  alternative). Un seul chemin de code, reutilise le meme moteur de rendu
  que l'export en masse, et un PDF reste directement imprimable par le
  destinataire une fois recu (une image ne l'est pas aussi proprement).
- **Mecanisme technique** : `Printing.layoutPdf(onLayout: ...)` pour
  l'export en masse (ouvre l'apercu d'impression natif de la plateforme,
  qui propose deja imprimer/enregistrer/partager selon la plateforme,
  donc "pret a imprimer" est couvert directement) ; `Printing.sharePdf(...)`
  pour le partage individuel (ouvre directement le partage natif de l'OS,
  WhatsApp/email/SMS). Le package `printing` fournit les deux, ce qui
  couvre "partage natif" sans avoir a piloter `share_plus` separement pour
  cette fonctionnalite (`share_plus` reste en dependance pour un usage
  ulterieur, notamment le fichier de sauvegarde au jalon 7).
- **Points d'entree** :
  - `TicketsScreen` (jalon 4) : icone `Icons.print_outlined` dans l'AppBar,
    desactivee si `tickets.isEmpty`. Declenche l'export en masse.
  - `TicketPreviewScreen` (jalon 4) : nouvelle icone `Icons.share_outlined`
    dans l'AppBar. Declenche le partage du ticket affiche.

## Architecture

```
lib/features/tickets/
  data/
    ticket_pdf_builder.dart   (nouveau : construction des documents PDF,
                                fonction pure hors Drift)
  presentation/
    screens/
      tickets_screen.dart         (modifie : icone export en masse)
      ticket_preview_screen.dart  (modifie : icone partage individuel)
```

### `ticket_pdf_builder.dart`

Pas de dependance Drift ni Riverpod : prend en entree les types de domaine
deja charges par les providers existants (`Ticket`, `Beneficiary`, `Event`,
`List<CustomField>`), retourne des `Uint8List` (bytes PDF prets a l'emploi
pour `Printing.layoutPdf`/`Printing.sharePdf`).

```dart
Future<Uint8List> buildEventTicketsPdf({
  required Event event,
  required List<Ticket> tickets,
  required Map<int, Beneficiary> beneficiariesById,
  required List<CustomField> customFields,
});

Future<Uint8List> buildSingleTicketPdf({
  required Event event,
  required Ticket ticket,
  required Beneficiary beneficiary,
  required List<CustomField> customFields,
});
```

Les deux fonctions partagent une fonction privee `pw.Widget _ticketCard(...)`
qui construit le rendu d'un ticket selon `event.ticketTemplate`, miroir
conceptuel du widget `_TicketCard` Flutter du jalon 4 (memes donnees
affichees : nom/logo evenement, QR, nom du beneficiaire, identifiant
lisible, champs personnalises coches `showOnTicket`), mais en widgets `pw`
puisque le moteur de rendu PDF n'utilise pas l'arbre de widgets Flutter.

`buildEventTicketsPdf` calcule d'abord, a partir de la taille de carte
cible du modele et de `PdfPageFormat.a4` (marge de page fixe 15mm,
espacement inter-cartes fixe 4mm), combien de colonnes tiennent sur la
largeur utile de la page ; la liste de tickets est ensuite decoupee en
groupes de cette taille, chaque groupe compose manuellement en une
`pw.Row` de cartes, les lignes empilees dans une `pw.Column`, et
`pw.MultiPage` gere le passage a la page suivante quand le contenu deborde
de la hauteur utile. Cette composition manuelle (plutot que `pw.GridView`,
pensee pour un nombre de colonnes fixe a l'avance) est ce qui permet au
nombre de colonnes de varier selon le modele choisi.

| Modele   | Taille de carte cible | Approx. par page A4 portrait |
|----------|-----------------------|-------------------------------|
| Compact  | 85 x 54 mm             | ~12 (grille 3x4)               |
| Standard | 90 x 60 mm             | ~6 (grille 2x3)                |
| Elegant  | 100 x 65 mm            | ~4 (grille 2x2)                |

Ces dimensions sont des cibles de mise en page pour l'export en masse, pas
les dimensions d'impression exactes finales d'un ticket individuel decoupe
(hors perimetre de ce jalon, l'export produit une grille imprimable
raisonnable, pas un gabarit de decoupe certifie au dixieme de millimetre).

`buildSingleTicketPdf` place une seule carte, centree, sur une page A4
(reutilise `_ticketCard` avec la meme taille cible que ci-dessus selon le
modele).

### Ecrans

- **`TicketsScreen`** : nouvelle icone AppBar `Icons.print_outlined`,
  tooltip localise, desactivee (`onPressed: null`) quand `tickets.isEmpty`.
  Au tap : construit `buildEventTicketsPdf(...)` a partir des donnees deja
  chargees par les providers de l'ecran (`eventProvider`,
  `ticketsProvider`, `beneficiariesProvider`, `customFieldsProvider`),
  puis `Printing.layoutPdf(onLayout: (format) async => bytes)`. Erreurs
  (construction PDF ou appel `printing`) attrapees, `SnackBar` avec message
  localise, meme pattern que les autres actions asynchrones de l'ecran
  (garde `context.mounted` avant utilisation post-await).
- **`TicketPreviewScreen`** : nouvelle icone AppBar `Icons.share_outlined`,
  tooltip localise, toujours activee des que le ticket est charge (l'ecran
  n'affiche deja rien avant que ticket/beneficiaire/evenement/champs soient
  disponibles). Au tap : construit `buildSingleTicketPdf(...)` a partir des
  donnees deja chargees par l'ecran, puis
  `Printing.sharePdf(bytes: bytes, filename: '${ticket.readableId}.pdf')`.
  Meme gestion d'erreur que ci-dessus.

## Tests

- `ticket_pdf_builder_test.dart` : les bytes retournes commencent par l'en-
  tete `%PDF` (verification qu'un document PDF valide a bien ete produit) ;
  `buildEventTicketsPdf` avec N tickets produit un document dont le nombre
  de pages correspond au nombre de cartes par page calcule (verifie via
  `PdfDocument.openData` du package `printing`, qui expose `pagesCount`) ;
  un ticket sans aucun champ personnalise coche `showOnTicket` ne fait pas
  planter le rendu (liste vide geree) ; les trois modeles produisent chacun
  un document valide (pas de crash de mise en page specifique a un
  modele).
- Tests de widget legers sur `TicketsScreen` (icone d'export desactivee
  sans tickets, presente et activee des qu'au moins un ticket existe) et
  `TicketPreviewScreen` (icone de partage presente une fois le ticket
  charge). L'appel natif `Printing.layoutPdf`/`Printing.sharePdf`
  lui-meme n'est pas exerce en test de widget, comme les autres
  integrations plateforme deja presentes dans le projet (`file_picker` au
  jalon 3 suit le meme principe : le declenchement est teste, pas
  l'integration OS sous-jacente).

## Hors perimetre

- Personnalisation libre des couleurs/mise en page (V2, explicitement hors
  MVP dans le cahier des charges).
- Export selectif (un sous-ensemble de tickets plutot que tous ceux de
  l'evenement) : l'export en masse couvre toujours l'integralite des
  tickets generes pour l'evenement.
- Partage en image (PNG) : tranche en faveur du PDF uniquement (voir
  Decisions actees).
