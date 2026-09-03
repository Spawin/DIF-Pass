# DIF Pass — Design du jalon 8 (Finitions)

Statut : valide par l'utilisateur le 2026-09-03.

## Contexte

Jalon 7 (Sauvegarde) est fusionne dans main : les 7 jalons fonctionnels du
cahier des charges (`Prompt_Lancement_Claude_Code_DIF_Pass.md`) sont
complets. Ce jalon couvre le point 8 : "animations, retours haptiques,
ecrans vides, gestion d'erreurs, polish visuel", plus deux points herites
de la revue finale du jalon 7 explicitement reportes ici, et un point
deja marque dans le code comme differe a un jalon de polish.

Contrairement aux jalons precedents, celui-ci ne porte pas sur une
fonctionnalite mais traverse tous les ecrans existants. Aucune nouvelle
fonctionnalite metier n'est ajoutee ; le perimetre est le rendu, la
robustesse et le confort d'usage de ce qui existe deja.

## Decisions actees

- **Etats vides et erreurs : un widget partage.** Les ecrans a liste
  (`EventsListScreen`, `EventArchiveScreen`, `BeneficiariesListScreen`,
  `TicketsScreen`) affichent aujourd'hui un texte centre nu pour l'etat
  vide et pour l'etat d'erreur, sans icone ni action. Un widget
  `EmptyState` (icone + texte + CTA optionnel) et un widget `ErrorState`
  (icone + texte + bouton Reessayer) sont crees dans `lib/shared/widgets/`
  — ce dossier `shared/` est prevu depuis la structure initiale du projet
  mais n'a jamais ete cree, faute de besoin transverse jusqu'ici. Legere
  animation d'apparition (`flutter_animate`, deja une dependance depuis le
  jalon 6, aucune nouvelle dependance necessaire pour ce jalon).
  `ErrorState` prend un callback `onRetry` qui invalide le provider
  concerne (ex. `ref.invalidate(activeEventsProvider)`).
- **Messages d'erreur : pattern existant etendu, pas de message
  generique.** Plusieurs ecrans affichent aujourd'hui le texte brut d'une
  exception a l'utilisateur (`Text('$e')`, ex.
  `events_list_screen.dart`, `event_form_screen.dart`,
  `csv_import_screen.dart`, `beneficiary_form_screen.dart`,
  `beneficiaries_list_screen.dart`, `tickets_screen.dart`,
  `event_archive_screen.dart` — 7 fichiers au total). Ce jalon remplace
  chaque occurrence par une cle ARB localisee specifique a l'ecran/action
  (meme pattern deja etabli pour `eventsLoadError`,
  `beneficiariesLoadError`, `settingsExportError`/`settingsImportError` du
  jalon 7), plutot que d'introduire un message generique unique — coherent
  avec l'existant, pas de nouvelle abstraction pour un texte a afficher.
- **Polices : fichiers embarques, pas de fetch reseau.** Le
  `google_fonts` actuel (`GoogleFonts.bigShouldersTextTheme`,
  `GoogleFonts.ibmPlexSansTextTheme`, `GoogleFonts.ibmPlexMono` dans
  `app_typography.dart`) a le fetch reseau desactive
  (`GoogleFonts.config.allowRuntimeFetching = false` dans `main.dart`,
  jalon 1) pour respecter le principe offline-first du projet, mais sans
  les fichiers embarques cela fait echouer silencieusement le chargement
  des polices en dehors du cache local de l'appareil de developpement —
  confirme sur un Tecno CE9 physique (police systeme affichee au lieu de
  Big Shoulders Display / IBM Plex Sans). Les fichiers `.ttf` de Big
  Shoulders Display, IBM Plex Sans et IBM Plex Mono (licence SIL Open Font
  License, libres a redistribuer) sont telecharges et places dans
  `assets/fonts/`, declares dans `pubspec.yaml`. `app_typography.dart`
  utilise directement `fontFamily: 'BigShouldersDisplay'` / `'IBMPlexSans'`
  / `'IBMPlexMono'` au lieu des helpers `GoogleFonts.*`. La dependance
  `google_fonts` et le contournement dans `main.dart` sont retires : plus
  de chemin reseau possible du tout, donc plus besoin de le bloquer
  explicitement.
- **Polices : reutilisees pour les PDF de tickets.**
  `ticket_pdf_builder.dart` utilise aujourd'hui les polices de base du
  package `pdf` (Helvetica/Courier), qui ne supportent que Latin-1 ; tout
  caractere hors Latin-1 est remplace par un `'?'` visible sur le ticket
  imprime (`_sanitizeForPdf`, deja commente dans le code comme "deferred to
  a later polish milestone"). Comme les memes fichiers `.ttf` sont deja
  embarques pour l'UI, ce jalon les reutilise pour le PDF
  (`pw.Font.ttf(...)` charge depuis `rootBundle`), ce qui donne un support
  Unicode complet et permet de supprimer `_sanitizeForPdf`.
- **Animations et haptique : etendues aux confirmations, pas
  generalisees a toute action.** Le cahier des charges ne nomme
  explicitement qu'un "ecran de succes apres import" (CSV) comme animation
  manquante ; le feedback check-in (vert/rouge, haptique) et le compteur
  en direct sont deja faits (jalon 6). Ce jalon etend le meme principe
  (haptique legere `HapticFeedback.lightImpact()` + animation courte
  `flutter_animate`, pas de nouvelle dependance Lottie) a quatre autres
  moments de confirmation deja identifies comme naturels : sauvegarde
  d'un evenement, generation de ticket, archivage d'un evenement, et succes
  d'un partage/export (ticket ou sauvegarde). Aucune autre action
  (navigation, listes, formulaires) ne recoit de traitement special —
  hors perimetre explicitement.
- **Ecran de succes CSV : icone Material animee, pas de Lottie.**
  Discute et tranche explicitement : `flutter_animate` sur une icone
  `Icons.check_circle_outline` (meme pattern que
  `check_in_scan_screen.dart`) plutot qu'une animation Lottie dediee.
  Une seule occurrence dans l'app ne justifie pas une nouvelle dependance
  ni un fichier `.json` externe a sourcer/licencier.
- **Polish visuel : passe de relecture generale, pas de liste figee a
  l'avance.** Fait apres les blocs precedents (les vraies polices
  changent la hierarchie visuelle percue), avec le skill
  `frontend-design`. Les corrections concretes (espacement, alignement,
  coherence des composants) se decident a la lecture, pas a l'avance —
  YAGNI, pas de refonte structurelle hors de ce qui sert directement ce
  jalon.
- **Testabilite de `SettingsScreen._import()` (reporte du jalon 7).**
  `FilePicker.pickFile` est actuellement appele en dur dans `_import()`,
  ce qui empechait tout test de la sequence complete (fermeture de la
  connexion, import, invalidation, navigation) deja verifiee
  manuellement/par revue a trois reprises pendant le jalon 7.
  `SettingsScreen` recoit un parametre constructeur `pickFile` avec
  `FilePicker.pickFile` comme valeur par defaut. Ce n'est pas un pattern
  deja present ailleurs dans le projet (les autres ecrans appelant
  `FilePicker.pickFile`, comme `CsvImportScreen`, l'appellent en dur et
  restent, eux, hors du perimetre teste du declenchement natif — ce jalon
  ne change que `SettingsScreen`, dont la sequence qui suit le choix du
  fichier est la plus sensible de l'app, jalon 7 l'a montre) ; c'est le
  meme principe deja applique a `AppDatabase.forTesting`
  (`lib/core/database/app_database.dart`, jalon 7) pour un autre point
  d'integration plateforme non mockable. Ce parametre debloque les deux
  tests que le design du jalon 7 demandait sans les avoir : bouton
  desactive pendant le traitement, dialogue de confirmation affiche avant
  tout appel a `importBackup` (annuler ne l'appelle pas).

## Architecture

```
lib/shared/
  widgets/
    empty_state.dart      (EmptyState, ErrorState)

assets/fonts/
  BigShouldersDisplay-*.ttf
  IBMPlexSans-*.ttf
  IBMPlexMono-*.ttf
```

Fichiers modifies (pas de nouveau fichier hors `empty_state.dart`) :

- `lib/core/theme/app_typography.dart` : polices en `fontFamily` local
  plutot que `GoogleFonts.*`.
- `lib/main.dart` : suppression du contournement
  `GoogleFonts.config.allowRuntimeFetching = false`.
- `lib/features/tickets/data/ticket_pdf_builder.dart` : chargement des
  `.ttf` embarques via `pw.Font.ttf(...)`, suppression de
  `_sanitizeForPdf`.
- `pubspec.yaml` : ajout de la section `fonts:`, retrait de
  `google_fonts`.
- `lib/features/events/presentation/screens/events_list_screen.dart`,
  `event_archive_screen.dart`, `event_form_screen.dart` : `EmptyState`/
  `ErrorState`, messages d'erreur localises specifiques, retour de
  confirmation sur sauvegarde et archivage.
- `lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`,
  `csv_import_screen.dart`, `beneficiary_form_screen.dart` : idem, plus
  l'ecran de succes anime pour l'import CSV.
- `lib/features/tickets/presentation/screens/tickets_screen.dart`,
  `ticket_preview_screen.dart` : `EmptyState`/`ErrorState`, retour de
  confirmation sur generation et partage.
- `lib/features/backup/presentation/screens/settings_screen.dart` :
  parametre `pickFile` injectable, retour de confirmation sur export/
  import reussis.
- `lib/l10n/app_fr.arb`, `app_en.arb` : nouvelles cles pour les messages
  d'erreur remplaces (une par ecran/action concerne) et pour les textes
  des `EmptyState`/`ErrorState` (bouton "Reessayer", etc.).

### `EmptyState` / `ErrorState`

```dart
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
}
```

Rendu : `Center` + `Column` (icone outlined 48px, texte
`bodyLarge`, bouton optionnel), l'ensemble anime en fondu+leger scale a
l'apparition (`.animate().fadeIn().scale()`, meme mecanisme que
`check_in_scan_screen.dart`). `ErrorState.onRetry` est fourni par
l'ecran appelant (ex. `() => ref.invalidate(activeEventsProvider)`), le
widget ne connait rien de Riverpod.

### Retours de confirmation

Meme mecanisme partout : `HapticFeedback.lightImpact()` appele juste
avant l'action de retour/fermeture (pop, navigation, ou affichage d'un
`SnackBar`), le `SnackBar` ou l'icone de confirmation anime en
fondu+scale sur 200-300ms (coherent avec les durees deja utilisees dans
`check_in_scan_screen.dart`). Aucune nouvelle infrastructure : chaque
ecran appelle directement `HapticFeedback.lightImpact()` (deja dans
`flutter/services.dart`) et `flutter_animate` a l'endroit concerne, pas
de widget partage pour ce point (le geste est trop simple pour justifier
une abstraction).

## Tests

- `EmptyState`/`ErrorState` : tests de widget purs — rendu de l'icone/
  texte/bouton, `onAction`/`onRetry` appele au tap. Pas de test sur
  l'animation elle-meme (rendu visuel, verifie manuellement).
- Ecran de succes CSV : test de widget verifiant que l'icone de succes et
  le decompte s'affichent apres un import reussi (etat deja teste
  aujourd'hui pour le texte, etendu pour l'icone).
- `SettingsScreen` (une fois `pickFile` injectable) : les deux tests
  demandes par le design du jalon 7 et non livres — bouton Importer
  desactive pendant le traitement ; dialogue de confirmation affiche
  avant tout appel a `importBackup`, annulation du dialogue n'appelle pas
  le repository (`pickFile` factice retournant un fichier fixe en test).
- Messages d'erreur localises : pas de nouveau test dedie par cle (deja
  couverts indirectement par les tests d'ecran existants qui declenchent
  ces chemins d'erreur) sauf si un chemin d'erreur n'a aucun test
  aujourd'hui, auquel cas un test minimal est ajoute en meme temps que la
  cle.
- Polices : aucun test automatise (rendu visuel non verifiable en
  `flutter test` sans capture d'ecran) ; verification manuelle sur le
  Tecno CE9 physique en fin de jalon, meme methode que la decouverte du
  defaut initial.
- `fvm flutter test` et `fvm flutter analyze` doivent rester verts a
  chaque tache, comme pour tous les jalons precedents.

## Hors perimetre

- Mode sombre : non demande par le cahier des charges, qui ne decrit
  qu'une palette claire (Ink/Paper/Ochre/Teal/Indigo).
- Personnalisation des couleurs par l'organisateur : explicitement V2
  dans le cahier des charges.
- Animations Lottie ou toute animation elaboree au-dela de
  `flutter_animate` : tranche explicitement au profit de la coherence
  avec l'existant et de l'absence de nouvelle dependance pour un besoin
  ponctuel.
- Refonte structurelle des ecrans (nouveaux layouts, nouveaux flux) : la
  passe de polish visuel corrige la coherence de l'existant, elle ne
  redessine pas les ecrans.
- Sauvegarde automatique programmee, chiffrement du fichier de
  sauvegarde : deja explicitement hors perimetre depuis le jalon 7, aucun
  changement ici.
