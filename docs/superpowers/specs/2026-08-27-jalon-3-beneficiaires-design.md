# DIF Pass — Design du jalon 3 (Beneficiaires)

Statut : valide par l'utilisateur le 2026-08-27.

## Contexte

Jalon 2 (Evenements) est fusionne dans main : CRUD evenement, archivage,
champs personnalises, mode de presence, tous testes et fusionnes. Ce jalon
couvre la section 2 du cahier des charges (`Prompt_Lancement_Claude_Code_DIF_Pass.md`) :
ajout manuel de beneficiaires et import en masse depuis un fichier CSV avec
mapping des colonnes vers les champs de l'evenement. La generation de
tickets (section 3) reste hors scope, elle arrive au jalon 4.

## Decisions actees

- **Navigation** : une icone "Beneficiaires" sur `EventCard` (meme pattern
  que l'icone Archiver du jalon 2), sans toucher au tap existant sur la
  carte (qui ouvre toujours l'edition de l'evenement).
- **CRUD complet sur `Beneficiary`** : creation, modification, suppression
  (avec confirmation). Pas de regle de verrouillage necessaire a ce stade,
  aucun ticket n'existe encore dans l'application (jalon 4).
- **Import CSV** : les lignes sans valeur dans la colonne mappee au champ
  Nom sont ignorees ; un ecran de resultat affiche le nombre importe et le
  nombre ignore. Aucune nouvelle dependance : `file_picker` et `csv` sont
  deja presents depuis le jalon 1. Lecture du fichier via `dart:io`
  (`file_picker` fournit un chemin local fiable sur Android/iOS), parsing
  avec `CsvToListConverter`. La premiere ligne du CSV est traitee comme les
  en-tetes de colonnes, utilises pour construire le mapping.
- **Formulaire manuel** : nom obligatoire, un champ de saisie par champ
  personnalise actif de l'evenement (texte ou numerique selon le type),
  tous optionnels.

## Architecture (repository + domaine)

```
lib/features/beneficiaries/
  domain/
    beneficiary.dart        (Beneficiary : id, eventId, name,
                              customFieldValues: Map<int, String>, createdAt)
    new_beneficiary.dart     (NewBeneficiary : name, customFieldValues,
                              utilise pour la creation et l'import)
  data/
    beneficiary_repository.dart          (interface)
    drift_beneficiary_repository.dart    (implementation Drift)
  presentation/
    providers/
      beneficiary_providers.dart
    screens/
      beneficiaries_list_screen.dart   (route /events/:id/beneficiaries)
      beneficiary_form_screen.dart     (creation + edition,
                                         /events/:id/beneficiaries/new et
                                         /events/:id/beneficiaries/:beneficiaryId/edit)
      csv_import_screen.dart           (route /events/:id/beneficiaries/import,
                                         un seul ecran a etats internes :
                                         choix du fichier -> mapping des
                                         colonnes -> resultat)
    widgets/
      beneficiary_list_tile.dart
```

Meme pattern repository que les jalons precedents : les ecrans et les
providers ne dependent que de `BeneficiaryRepository`, jamais de Drift
directement. `beneficiary_form_screen.dart` et `csv_import_screen.dart`
lisent les champs personnalises de l'evenement via `EventRepository` /
`customFieldsProvider` deja en place (jalon 2) — une feature qui depend du
repository d'une autre feature est normal dans ce pattern, tant que ca reste
a sens unique (beneficiaries -> events, jamais l'inverse).

### Modele de domaine

```dart
class Beneficiary {
  final int id;
  final int eventId;
  final String name;
  final Map<int, String> customFieldValues; // customFieldId -> valeur
  final DateTime createdAt;
}

class NewBeneficiary {
  final String name;
  final Map<int, String> customFieldValues;
}
```

### Interface `BeneficiaryRepository`

```dart
abstract class BeneficiaryRepository {
  Stream<List<Beneficiary>> watchBeneficiaries(int eventId);
  Future<Beneficiary> getBeneficiary(int id);
  Future<int> createBeneficiary(int eventId, NewBeneficiary beneficiary);
  Future<void> updateBeneficiary(int id, NewBeneficiary beneficiary);
  Future<void> deleteBeneficiary(int id);
  Future<int> importBeneficiaries(int eventId, List<NewBeneficiary> beneficiaries); // retourne le nombre reellement insere
}
```

`importBeneficiaries` recoit une liste deja filtree et validee (le filtrage
"ligne sans nom = ignoree" est une regle de parsing CSV, elle vit dans
`csv_import_screen.dart`, pas dans le repository) et insere tout dans une
seule transaction Drift.

## Ecrans

- **Liste des beneficiaires** (`beneficiaries_list_screen.dart`) : nom de
  l'evenement en entete, liste des beneficiaires (nom + apercu des valeurs
  de champs personnalises), actions "Ajouter" (formulaire) et "Importer un
  CSV" (ecran d'import), edition/suppression par ligne (suppression avec
  confirmation explicite, action irreversible).
- **Formulaire** (`beneficiary_form_screen.dart`, meme ecran pour creation
  et edition) : nom (obligatoire), un champ par champ personnalise actif de
  l'evenement (texte ou numerique selon le type, tous optionnels). Rendu
  visuel affine avec le skill frontend-design au moment du code, comme les
  jalons precedents.
- **Import CSV** (`csv_import_screen.dart`) : ecran a trois etats internes
  (pas trois routes separees, pour garder la navigation simple) :
  1. Choix du fichier (`file_picker`)
  2. Mapping des colonnes : un menu deroulant par champ de l'app (Nom +
     chaque champ personnalise), options = en-tetes de colonnes du CSV ou
     "Ignorer"
  3. Resultat : "X beneficiaires importes, Y lignes ignorees (nom manquant)"

## Tests

- `DriftBeneficiaryRepository` : creation, modification, suppression,
  `watchBeneficiaries` reactif et filtre par evenement,
  `importBeneficiaries` (insertion en masse, comptage correct, transaction
  atomique).
- Tests de widget legers sur la liste, le formulaire (validation du nom
  obligatoire) et le flux d'import (etats mapping -> resultat), via un
  `FakeBeneficiaryRepository` suivant le meme pattern que
  `FakeEventRepository` du jalon 2.
