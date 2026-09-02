# DIF Pass — Design du jalon 7 (Sauvegarde)

Statut : valide par l'utilisateur le 2026-08-30.

## Contexte

Jalon 6 (Controle de presence) est fusionne dans main : evenements, beneficiaires,
tickets et presences fonctionnels de bout en bout. Ce jalon couvre la section 5
du cahier des charges (`Prompt_Lancement_Claude_Code_DIF_Pass.md`) : export/import
d'un fichier de sauvegarde unique, exportable vers le stockage/Drive/WhatsApp et
re-importable, contre la perte de donnees en cas de changement d'appareil.

Contrairement aux jalons precedents, celui-ci ne porte pas sur un evenement en
particulier : la sauvegarde couvre l'intégralité des donnees locales (tous les
evenements, beneficiaires, tickets, presences). `share_plus` et `file_picker`
sont deja en dependance depuis le jalon 1/3, aucune nouvelle dependance requise.

## Decisions actees

- **Format de la sauvegarde** : copie brute du fichier SQLite de Drift
  (`dif_pass.sqlite`), pas une serialisation JSON. Le fichier contient deja
  toutes les tables (evenements, champs personnalises, beneficiaires, valeurs
  de champs, tickets, presences) ; le copier tel quel garantit une fidelite
  totale sans code d'export/import a ecrire et maintenir table par table.
- **Coherence du fichier a l'export** : Drift n'active pas le mode WAL dans ce
  projet (seul `PRAGMA foreign_keys = ON` est positionne a l'ouverture), donc
  le mode journal SQLite par defaut garantit que le fichier `.sqlite` est
  toujours coherent en dehors d'une transaction active. Les ecritures de cette
  app sont de simples operations qui valident avant que l'`await` ne se
  termine ; au moment ou l'utilisateur appuie sur "Exporter", aucune ecriture
  n'est en cours. L'export peut donc lire le fichier directement, sans fermer
  la connexion Drift vivante ni provoquer de reconstruction de l'arbre de
  providers pour une simple lecture.
- **Import = remplacement complet, pas de fusion** : l'usage decrit ("contre
  la perte en cas de changement d'appareil") est une restauration complete,
  pas une fusion de donnees. Confirmation explicite obligatoire avant
  d'importer (action irreversible, remplace toutes les donnees actuelles),
  meme pattern que les confirmations deja etablies dans l'app (jalon 4 :
  generation de tickets ; jalons 2/3 : suppressions).
- **Validation avant remplacement** : le fichier importe est d'abord ecrit
  dans un fichier temporaire et ouvert pour verifier qu'il s'agit bien d'une
  base SQLite valide avec une table `events` ; si la validation echoue, rien
  n'est touche a la base reelle et un message d'erreur est affiche. Les
  differences de version de schema entre l'ancienne sauvegarde et la version
  actuelle de l'app sont gerees par la migration Drift deja existante
  (`AppDatabase.migration`) a la reouverture, pas par une logique de
  validation separee.
- **Emplacement des actions** : nouvel ecran `SettingsScreen` (nom generique,
  pas specifique a la sauvegarde, pour laisser la place a d'autres reglages
  futurs), accessible via une icone Reglages sur l'AppBar de l'ecran
  Evenements (a cote d'Archives), plutot que deux icones directement sur
  cet ecran.
- **Testabilite du repository de sauvegarde** : `getApplicationDocumentsDirectory()`
  (path_provider) n'est pas mockable dans `flutter test` (c'est exactement
  pourquoi `AppDatabase.forTesting` existe deja comme constructeur separe).
  `BackupRepository` ne resout donc pas lui-meme le chemin du fichier de la
  base : il recoit un chemin en entree et ne fait que de l'E/S fichier pure
  (`dart:io`), testable avec de vrais fichiers temporaires du systeme, sans
  dependre de path_provider ni de Riverpod.

## Architecture

```
lib/features/backup/
  data/
    backup_repository.dart          (interface)
    file_backup_repository.dart     (implementation dart:io)
  presentation/
    providers/
      backup_providers.dart
    screens/
      settings_screen.dart          (route /settings)
```

### `BackupRepository`

```dart
abstract class BackupRepository {
  Future<Uint8List> exportBackup();
  Future<void> importBackup(Uint8List bytes);
}
```

`FileBackupRepository` est construit avec le chemin du fichier de base actuel
(`FileBackupRepository(databaseFile)`, un `File`), resolu une seule fois par
la couche presentation/provider a partir du meme mecanisme de resolution de
chemin deja utilise par `AppDatabase._openConnection()` (jalon 1). Aucune
dependance a `AppDatabase`, Riverpod, `share_plus` ou `file_picker` dans ce
repository : il ne connait qu'un chemin de fichier et des octets.

`exportBackup()` : lit et retourne les octets du fichier de base actuel tel
quel (voir la note sur la coherence du fichier plus haut).

`importBackup(bytes)` : ecrit `bytes` dans un fichier temporaire (meme
dossier que le fichier cible, pour que le remplacement final soit un simple
renommage atomique sur le meme systeme de fichiers), tente de l'ouvrir comme
base SQLite et d'y lire au moins une ligne de `sqlite_master` pour la table
`events` ; en cas d'echec, supprime le fichier temporaire et leve une
exception explicite (le fichier reel n'est jamais touche) ; en cas de succes,
remplace le fichier cible par le fichier temporaire.

### Fermeture/reouverture de la connexion vive (couche presentation)

La fermeture de la connexion Drift avant l'import et sa reouverture apres
sont la responsabilite de l'ecran, pas du repository (le repository ne doit
pas dependre de Riverpod). Sequence complete d'un import reussi :

1. `ref.read(appDatabaseProvider).close()` (ferme la connexion vivante,
   necessaire pour pouvoir remplacer le fichier proprement, en particulier
   sur certaines plateformes qui verrouillent un fichier ouvert).
2. `await backupRepository.importBackup(bytes)` (valide, remplace).
3. `ref.invalidate(appDatabaseProvider)` (reconstruit une connexion fraiche
   sur le meme chemin, desormais avec le contenu importe).
4. Navigation vers `/` (liste des evenements) : evite qu'un ecran affiche
   encore un evenement, un beneficiaire ou un ticket dont l'id n'existe plus
   dans les donnees restaurees.

## Ecran

`SettingsScreen`, route `/settings`, declenche par une icone Reglages sur
l'AppBar de `EventsListScreen` (a cote d'Archives).

- **Exporter la sauvegarde** : lit les octets via `exportBackup()`, les
  ecrit dans un fichier temporaire au nom convivial
  (`dif-pass-sauvegarde-AAAA-MM-JJ.sqlite`), puis `Share.shareXFiles(...)`
  (partage natif : stockage, Drive, WhatsApp, etc.).
- **Importer une sauvegarde** : `FilePicker` pour choisir un fichier, puis
  dialogue de confirmation explicite (« Cette action remplacera toutes les
  donnees actuelles. Cette action est irreversible. ») avant tout traitement.
  Si confirme : sequence de fermeture/import/invalidation/navigation
  decrite ci-dessus. Bouton desactive pendant le traitement (import comme
  export). Erreur (validation echouee, E/S) affichee via un message localise,
  base actuelle jamais touchee dans ce cas.

## Tests

- `FileBackupRepository` (tests `dart:io` purs, fichiers temporaires reels,
  aucun mock de plateforme) : `exportBackup` retourne les octets exacts d'un
  fichier source donne ; `importBackup` avec un fichier SQLite valide
  (contenant une table `events`) remplace bien le fichier cible ; `importBackup`
  avec un fichier invalide (texte quelconque, ou SQLite sans table `events`)
  leve une exception et laisse le fichier cible intact (verifie en comparant
  son contenu avant/apres la tentative).
- Tests de widget sur `SettingsScreen` : le bouton Importer est desactive
  pendant le traitement ; le dialogue de confirmation s'affiche avant tout
  appel a `importBackup` (verifie qu'annuler le dialogue n'appelle pas le
  repository). L'appel natif `Share.shareXFiles`/`FilePicker.pickFile`
  lui-meme n'est pas exerce en test de widget, meme principe deja applique
  dans ce projet pour `file_picker` (jalon 3) et `printing` (jalon 5) : le
  declenchement est teste, pas l'integration plateforme sous-jacente.

## Hors perimetre

- Sauvegarde automatique programmee (ex. quotidienne) : non demandee par le
  cahier des charges, qui ne decrit qu'un export/import manuel a la demande.
- Sauvegarde de securite automatique des donnees actuelles avant un import
  destructeur (pour permettre l'annulation apres coup) : ajouterait de la
  complexite (gestion d'un fichier "precedent") non demandee par le cahier
  des charges ; la confirmation explicite avant import est jugee suffisante
  pour ce jalon.
- Chiffrement du fichier de sauvegarde : non demande par le cahier des
  charges ; les donnees (noms, listes de presence) ne sont pas jugees plus
  sensibles une fois exportees qu'elles ne le sont deja localement sur
  l'appareil.
