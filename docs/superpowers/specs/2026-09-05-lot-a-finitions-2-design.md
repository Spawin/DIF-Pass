# DIF Pass — Design du lot A (Finitions 2)

Statut : valide par l'utilisateur le 2026-09-05.

## Contexte

Jalon 8 (Finitions) est fusionne dans main : les 8 jalons du cahier des
charges initial (`Prompt_Lancement_Claude_Code_DIF_Pass.md`) sont complets.
Une verification sur un Tecno CE9 physique et une relecture des ecrans ont
fait remonter une nouvelle serie de points, dont un premier lot ("lot A")
resserre a des corrections et ajouts cibles, independants les uns des
autres, sur des ecrans deja existants :

1. Confirmation fiable apres export groupe de tickets et partage individuel
2. Confirmation de check-in differenciee (succes auto, exceptions au tap),
   delai reglable et bouton pour l'ecourter
3. Premiers reglages persistants de l'app (delai check-in, langue FR/EN),
   fonctionnalite de selection de langue promise au demarrage du projet
   mais jamais construite
4. Snackbar annulable au lieu d'un dialogue modal pour archiver/desarchiver
   un evenement
5. Indication des champs disponibles avant import CSV
6. Documentation d'une limite connue (glyphe manquant dans la police PDF),
   sans correction immediate

D'autres points remontes dans la meme session (garde-fou benediciaire apres
generation de ticket, historique de presence consultable, indicateur de
presence sur la liste des tickets, schema d'identifiants pret pour une
future synchronisation, mesures d'usage locales) sont volontairement hors
de ce lot ; ils feront l'objet de brainstormings separes.

## Decisions actees

- **Export groupe et partage individuel : meme traitement, verifie.**
  `Printing.layoutPdf` et `Printing.sharePdf` renvoient tous les deux un
  `Future<bool>` (verifie contre le code source du package
  `printing 5.15.0`) que le code actuel ignore dans les deux cas. Ce lot
  verifie ce booleen avant d'afficher une confirmation de succes (haptique
  legere + snackbar), pour les deux actions, plutot que de supposer que
  l'appel a reussi des qu'il ne leve pas d'exception.
- **Check-in : succes auto-ferme (delai reglable), exceptions au tap.**
  Le delai fixe actuel (1800 ms, choisi arbitrairement au jalon 6, aucune
  justification retrouvee dans l'historique ni les documents de ce jalon)
  ne s'applique plus qu'au cas `CheckInFeedbackRecorded`. Les cas
  `CheckInFeedbackAlreadyRecorded` et `CheckInFeedbackNotFound` n'ont plus
  de delai automatique : l'overlay affiche un bouton "OK" et attend un tap
  explicite avant de refermer et relancer le scan. Le cas succes garde une
  fermeture automatique (pour ne pas ralentir un flux d'entree avec de
  nombreux arrivants) mais gagne un bouton "Passer" pour l'ecourter a la
  demande de l'agent, et le delai lui-meme devient un reglage utilisateur
  (1 a 4 secondes, defaut 1800 ms) plutot qu'une constante figee dans le
  code — faute de donnees d'usage reelles pour calculer une valeur exacte
  (voir la mesure d'usage locale, hors perimetre de ce lot, comme piste
  pour obtenir ces donnees plus tard).
- **Premiers reglages persistants : meme mecanisme pour le delai et la
  langue.** `shared_preferences` est deja une dependance du projet mais
  n'est utilisee nulle part dans le code actuel — la fonctionnalite
  "detection automatique de la langue + possibilite de forcer FR ou EN
  dans les reglages", explicitement demandee dans le cahier des charges
  initial, n'a jamais ete implementee. Ce lot construit l'infrastructure
  minimale de reglages persistants une fois, et l'utilise pour les deux
  besoins (delai check-in, langue), plutot que de la construire deux fois.
  La langue force reste geree par le mecanisme `intl`/ARB deja en place
  (`AppLocalizations`, `app_fr.arb`/`app_en.arb`) : aucun nouveau systeme
  d'i18n, seulement une preference stockee qui remplace la detection
  automatique du telephone quand elle est definie.
- **Archivage/desarchivage : snackbar annulable, pas de dialogue modal.**
  L'archivage est deja concu comme une action sure et reversible
  ("suppression = archivage... recuperable depuis Archives", cahier des
  charges section 1). Un dialogue de confirmation a chaque archivage irait
  a l'encontre de cet objectif de friction minimale. A la place, un
  snackbar avec une action "Annuler" apparait juste apres l'archivage ou
  le desarchivage, qui refait l'action inverse (desarchiver si on vient
  d'archiver, et reciproquement) si l'utilisateur la declenche. La
  suppression definitive garde son dialogue de confirmation existant
  (seule action reellement irreversible de cet ecran).
- **Import CSV : indiquer les champs disponibles avant le choix du
  fichier, pas un format impose.** Le mapping de colonnes
  (`csv_mapping_form.dart`) est deja entierement libre : n'importe quelle
  colonne peut etre associee a Nom ou a n'importe quel champ personnalise
  de l'evenement, apres coup. Il n'y a donc pas de format de fichier a
  proprement imposer. Ce lot ajoute un texte informatif sur l'ecran de
  selection du fichier (avant meme le choix), listant les champs
  personnalises de l'evenement courant, pour que l'organisateur sache par
  avance ce qu'il pourra associer.
- **Glyphe manquant dans la police PDF : documente, pas corrige.** IBM
  Plex Sans (jalon 8) ne couvre pas U+0186 (utilise dans certaines
  orthographes ouest-africaines, ex. l'ewe) ; le paquet `pdf` affiche deja
  un rectangle barre visible pour ce caractere precis, pas un caractere
  invisible ni un crash. Ajouter une police de secours pour un seul
  caractere serait disproportionne sans signalement d'un cas reel. Un
  commentaire dans `ticket_pdf_builder.dart` documente cette limite
  connue et la piste de correction (`TextStyle.fontFallback`) si elle
  devient un vrai probleme.

## Architecture

### Reglages persistants

```
lib/core/settings/
  app_settings.dart         (lecture/ecriture SharedPreferences brutes)
  settings_providers.dart   (etat Riverpod charge une fois au demarrage)
```

`app_settings.dart` :

```dart
class AppSettings {
  const AppSettings({required this.checkinFeedbackDelayMs, this.localeOverride});

  final int checkinFeedbackDelayMs;
  final String? localeOverride; // 'fr' | 'en' | null (automatique)

  static const _delayKey = 'checkin_feedback_delay_ms';
  static const _localeKey = 'locale_override';
  static const defaultDelayMs = 1800;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      checkinFeedbackDelayMs: prefs.getInt(_delayKey) ?? defaultDelayMs,
      localeOverride: prefs.getString(_localeKey),
    );
  }

  Future<void> saveCheckinFeedbackDelayMs(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_delayKey, value);
  }

  Future<void> saveLocaleOverride(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, value);
    }
  }
}
```

`settings_providers.dart` expose un `Notifier<AppSettings>` (Riverpod)
dont l'etat initial est fourni par `main()` avant `runApp`, pour que tout
le reste de l'arbre (y compris `MaterialApp.router` a la racine) puisse le
lire de facon synchrone des le premier build, sans etat de chargement
visible :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSettings = await AppSettings.load();
  runApp(
    ProviderScope(
      overrides: [appSettingsProvider.overrideWith(() => AppSettingsNotifier(initialSettings))],
      child: const DifPassApp(),
    ),
  );
}
```

`DifPassApp` lit `ref.watch(appSettingsProvider).localeOverride` et le
convertit en `Locale?` pour `MaterialApp.router(locale: ...)` (`null`
laisse `supportedLocales`/la detection automatique de Flutter s'appliquer,
comportement actuel inchange par defaut). `check_in_scan_screen.dart` lit
`ref.watch(appSettingsProvider).checkinFeedbackDelayMs` a la place de la
constante `1800`.

`SettingsScreen` gagne deux controles, sous les boutons export/import
existants : un curseur (`Slider`, 1000-4000 ms, pas de 100 ms) pour le
delai check-in, et un choix a trois options (Automatique/Francais/Anglais)
pour la langue. Chaque changement appelle
`ref.read(appSettingsProvider.notifier).setCheckinFeedbackDelayMs(...)` /
`setLocaleOverride(...)`, qui persiste via `AppSettings` et met a jour
l'etat Riverpod dans le meme geste (pas de rechargement d'app necessaire
pour voir l'effet, `MaterialApp.router` reagit au changement de `locale`
comme tout widget consommant un provider Riverpod).

### Check-in : confirmation differenciee

`_CheckInFeedbackOverlay` gagne un parametre `onDismiss: VoidCallback`,
toujours fourni par l'ecran parent. Le bouton affiche differe selon le cas
(`l10n.checkinSkipAction` "Passer" pour le succes, `l10n.commonOk` "OK"
pour les deux cas d'exception), mais appelle `onDismiss` dans tous les cas.

Dans `_CheckInScanScreenState._process` : le bloc `await
Future<void>.delayed(...)` puis reset de `_feedback`/`_busy` et redemarrage
du scanner est extrait dans une methode `_dismissFeedback()` (idempotente,
verifie `mounted` avant tout, un double appel — ex. le delai qui expire
juste apres un tap sur "Passer" — est sans consequence). Cette methode est
appelee : automatiquement apres le delai regle par l'utilisateur
uniquement quand `feedback is CheckInFeedbackRecorded` ; immediatement si
l'utilisateur tape "Passer" ou "OK" sur l'overlay ; immediatement (sans
delai ni overlay a fermer) si `processCheckIn` a leve une exception
inattendue, comme aujourd'hui pour ce cas precis.

### Export/partage : confirmation verifiee

`tickets_screen.dart` (`_exportAllTickets`) et
`ticket_preview_screen.dart` (`_shareTicket`) : le `bool` retourne par
`Printing.layoutPdf`/`Printing.sharePdf` est capture. Si `true` :
`HapticFeedback.lightImpact()` puis un snackbar de succes
(`l10n.ticketsExportSuccess` pour l'export groupe, `l10n.ticketPreviewShareSuccess`
deja existant pour le partage individuel, reutilise tel quel). Si `false`
(utilisateur a annule cote natif) : aucune confirmation, aucune erreur non
plus (annuler n'est pas un echec).

### Archivage/desarchivage

`events_list_screen.dart` (`onArchive`) et `event_archive_screen.dart`
(bouton restaurer) : apres l'appel reussi a `archiveEvent`/`restoreEvent`,
un `SnackBar` avec `action: SnackBarAction(label: l10n.commonUndo, onPressed: ...)`
qui appelle l'action inverse sur le meme `event.id`. Pas de nouvel etat a
gerer : le flux normal (liste qui se met a jour via le stream Riverpod
existant) fonctionne de la meme facon que l'action initiale.

### Import CSV : indication des champs

`csv_import_screen.dart`, branche `else` (avant selection du fichier) :
lecture de `customFieldsProvider(widget.eventId)` (deja utilise plus loin
dans le meme fichier) pour afficher, au-dessus du bouton "Choisir un
fichier CSV", un texte listant les libelles des champs personnalises de
l'evenement (ex. "Vous pourrez associer les colonnes de votre fichier a :
Nom, Table n°, Categorie"). Si l'evenement n'a aucun champ personnalise,
le texte se limite a mentionner Nom.

## Tests

- `AppSettings` : tests `dart:io` purs sur une instance
  `SharedPreferences` en memoire (`SharedPreferences.setMockInitialValues`,
  deja le mecanisme standard du package pour les tests) : valeur par
  defaut du delai quand rien n'est stocke, lecture/ecriture des deux
  valeurs, `localeOverride` null par defaut.
- `check_in_scan_screen.dart` : test verifiant que le cas succes se ferme
  seul apres le delai configure (avec un `AppSettings` de test a delai
  court, pour ne pas ralentir la suite de tests) ; test verifiant que les
  cas `AlreadyRecorded`/`NotFound` NE se ferment PAS automatiquement meme
  apres un delai long, et se ferment seulement apres un tap sur "OK" ; test
  verifiant que "Passer" ferme immediatement le cas succes sans attendre
  le delai.
- `tickets_screen.dart`/`ticket_preview_screen.dart` : tests existants
  etendus pour verifier qu'un retour `false` de `Printing.layoutPdf`/
  `sharePdf` n'affiche pas la confirmation de succes (le mock deja
  construit au jalon 8 pour `ticket_preview_screen_test.dart` est reutilise
  et parametre pour retourner `false` dans un nouveau cas).
- `events_list_screen.dart`/`event_archive_screen.dart` : test verifiant
  que le snackbar "Annuler" apparait apres archivage/desarchivage et que
  le taper appelle bien l'action inverse sur le bon `event.id`.
- `csv_import_screen.dart` : test verifiant que les libelles des champs
  personnalises de l'evenement apparaissent sur l'ecran de selection du
  fichier, avant tout choix de fichier.

## Hors perimetre

- Garde-fou avant modification/suppression d'un beneficiaire ayant deja un
  ticket genere : brainstorming separe.
- Historique de presence consultable et indicateur "deja utilise" sur la
  liste des tickets : brainstorming separe.
- Schema d'identifiants pret pour une future synchronisation multi-appareils :
  decision d'architecture separee, a traiter avant toute fonctionnalite de
  synchronisation reelle, pas avant.
- Mesures d'usage locales avec export et consentement explicite : nouveau
  lot separe (lot E), avec sa propre reflexion vie privee.
- Toute police de secours pour le glyphe manquant U+0186 : documente comme
  dette, pas traite ici (voir Decisions actees).
