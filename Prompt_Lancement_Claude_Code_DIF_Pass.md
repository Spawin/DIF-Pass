# Prompt de lancement — DIF Pass

*À coller comme premier message dans Claude Code pour initier le projet.*

---

## Contexte

Je suis développeur chez DIF-Corporation (Togo). Je démarre un nouveau projet Flutter : **DIF Pass**, une application mobile de gestion de tickets/pass pour événements, destinée à être publiée sur Google Play et l'App Store et utilisée par différentes sociétés/organisateurs (chacun gère ses propres événements).

L'app permet à un organisateur de :
1. Créer un événement et une liste de bénéficiaires (participants)
2. Générer un ticket unique par bénéficiaire (avec QR code), à imprimer ou partager numériquement
3. Vérifier la présence des participants à l'entrée en scannant leur ticket

DIF Pass fait partie de la suite d'applications utilitaires DIF-Corporation. Principe "sister apps, not clones" : elle partage la base visuelle DIF mais adopte un accent propre (Indigo).

## Objectif de cette session

Avant d'écrire du code, on pose ensemble l'architecture et la structure. Ne génère pas tout d'un coup : propose d'abord la structure, valide-la avec moi, puis avançons par étapes (setup -> modèle de données -> écrans -> génération de tickets -> scan -> export/sauvegarde).

## Cahier des charges fonctionnel (MVP)

### 1. Gestion des événements
- Créer / modifier / archiver un événement (nom, date, lieu, logo optionnel)
- **Suppression = archivage (soft delete)** : l'événement est masqué de la liste principale mais récupérable depuis une vue "Archives", avec suppression définitive possible depuis les archives (champ `archivedAt`).
- Définir, pour chaque événement, une liste de **champs personnalisés** pour les bénéficiaires (en plus du nom, obligatoire) : ex. téléphone, catégorie, table n°, entreprise. L'organisateur choisit ces champs à la création.
- Définir, à la création de l'événement, le **mode de contrôle de présence** (voir section 4).

### 2. Gestion des bénéficiaires
- Ajout manuel unitaire
- Import en masse depuis un fichier **CSV** (mapping des colonnes vers les champs de l'événement)

### 3. Génération de tickets
- Un ticket = **identifiant unique** + **QR code** encodant cet identifiant.
- **Format de l'identifiant** : lisible + composante aléatoire, ex. `EVT3-0042-X7K9`. La partie lisible (`0042`) permet la saisie manuelle de secours ; la composante aléatoire (`X7K9`) empêche de deviner un ticket valide (anti-fraude).
- **Contenu du ticket** (par défaut) : QR + nom + identifiant lisible + nom/logo de l'événement. L'organisateur peut **cocher des champs personnalisés supplémentaires** à afficher sur le ticket (ex. table n°, catégorie), choix appliqué à tous les tickets de l'événement.
- **Modèles de ticket** : 2 à 3 templates au choix, tous dans la charte DIF :
  - *Compact* : beaucoup de tickets par page (économie de papier)
  - *Standard* : format carte classique
  - *Élégant* : plus aéré, accent Indigo
  - (Personnalisation libre des couleurs = V2, hors MVP)
- Export **PDF** de tous les tickets d'un événement, prêt à imprimer (mise en page propre selon le modèle choisi).
- Partage individuel d'un ticket (image ou PDF) via le partage natif (WhatsApp, email, SMS).

### 4. Contrôle de présence
- **Mode paramétrable par événement** :
  - *Présence simple* : un scan = présent ; les scans suivants du même ticket sont bloqués avec alerte ("déjà enregistré à HH:MM").
  - *Entrées/sorties multiples* : chaque scan est enregistré dans l'historique ; aucun blocage, on compte les passages.
- Le modèle de données conserve **tous** les scans (table CheckIn = historique complet). La règle de blocage et l'affichage dépendent du mode.
- Scan du QR via la caméra (overlay soigné, cadre animé, retour haptique)
- Saisie manuelle de l'identifiant en secours (QR abîmé/illisible), acceptant la partie lisible ou l'identifiant complet
- Marquage "présent" avec horodatage
- **Compteur de présence en direct** pendant la session de scan (ex. "127/300 arrivés"), animé

### 5. Données & sauvegarde
- Aucune connexion ni compte requis
- Données (événements, bénéficiaires, tickets, présences) stockées **localement**
- **Export/import de sauvegarde** (fichier unique exportable vers le stockage, Drive, WhatsApp, et ré-importable) contre la perte en cas de changement d'appareil

## Internationalisation

- Interface en **français + anglais dès le départ**. Mettre en place `flutter_localizations` + fichiers **ARB dès l'initialisation** (ne pas rétrofiter après).
- Détection automatique de la langue du téléphone + possibilité de forcer FR ou EN dans les réglages.
- Note : l'i18n couvre l'interface. Le contenu saisi par l'organisateur (noms d'événements, champs, tickets) reste dans la langue qu'il tape.

## Contraintes techniques

- **Flutter géré via FVM** : le projet utilise fvm. Prévoir un `.fvmrc` (version stable à figer, à me proposer). Toutes les commandes préfixées `fvm flutter ...` et `fvm dart ...`.
- Cible **Android + iOS**
- **Base locale** : Drift (SQLite typé)
- **State management** : Riverpod
- **Navigation** : go_router
- **QR** : génération `qr_flutter`, scan `mobile_scanner`
- **PDF** : `pdf` + `printing`
- **Import CSV** : package `csv`
- **Partage** : `share_plus`
- **Animations** : `flutter_animate` (feedback check-in vert/rouge, incrémentation du compteur, écran de succès après import), transitions via go_router
- **i18n** : `flutter_localizations` + intl / ARB

## Design / identité visuelle

DIF Pass reprend la charte graphique DIF-Corporation, avec l'Indigo comme accent propre :
- **Palette** : Ink `#1B1F3B`, Paper `#F0F1F5`, Ochre `#E8A33D`, Teal `#1F6E5C`, Indigo `#5B6EE8` (accent principal de DIF Pass)
- **Typographie** : Big Shoulders Display (titres), IBM Plex Sans (UI/corps), IBM Plex Mono (identifiants de tickets, compteurs, données chiffrées)
- Objectif : un rendu soigné et distinctif, pas le style "template Flutter par défaut". Consulte le skill **frontend-design** avant de construire les écrans.
- Première étape design : traduire ces tokens en un `theme.dart` partagé.

## Architecture

- Architecture en couches avec **pattern repository** : toute la logique métier (création d'événement, génération de ticket, enregistrement de présence) passe par des interfaces de repository, indépendantes de la source de données.
- Objectif explicite : la source locale (Drift) doit pouvoir être complétée plus tard par une source cloud (sync multi-appareils, fonctionnalité payante future) **sans modifier la logique métier ni les écrans**. Prévoir cette séparation dès le départ, ne pas implémenter le cloud maintenant.
- Structure **feature-first** : `lib/features/events`, `lib/features/beneficiaries`, `lib/features/tickets`, `lib/features/checkin`, `lib/core`, `lib/shared`.

## Modèle de données (à valider / affiner ensemble)

- **Event** : id, nom, date, lieu, logo (optionnel), mode de présence (simple | multiple), archivedAt (nullable), createdAt
- **CustomField** : id, eventId, libellé, type, ordre, afficherSurTicket (bool)
- **Beneficiary** : id, eventId, nom, valeurs des champs personnalisés (table de valeurs liée), createdAt
- **Ticket** : id, beneficiaryId, eventId, identifiantLisible (ex. EVT3-0042), composanteAleatoire (X7K9), payloadQR, createdAt
- **CheckIn** : id, ticketId, eventId, horodatage, (mode multiple : plusieurs lignes par ticket possible)

## Règles de développement à respecter strictement

- **Ne jamais écrire à la main du code généré.** Pour Drift (tables, DAO) et tout code produit par build_runner, utiliser la commande de génération (`fvm dart run build_runner build`), jamais éditer les `.g.dart` manuellement.
- Pas de tirets cadratins dans le code, les commentaires ou les commits.
- Noms de branches Git cohérents et descriptifs.
- Aucune mention "Generated with Claude" ni "Co-Authored-By: Claude" dans les commits ou Pull Requests.

## Points à trancher ensemble avant de coder

- Bundle ID / Application ID : je propose `com.difcorporation.difpass` (à confirmer)
- Version Flutter exacte à figer dans FVM
- Saisie de secours : accepter uniquement la partie lisible (`0042`) ou l'identifiant complet ?
- Détail exact des 2-3 modèles de ticket (dimensions, nombre par page)

## Première étape attendue

Propose-moi :
1. La structure de dossiers complète
2. Le schéma des tables Drift (Event, CustomField, Beneficiary, Ticket, CheckIn) affiné
3. Le `theme.dart` à partir des tokens ci-dessus
4. La mise en place i18n (structure ARB)
5. Un plan de développement par jalons

Attends ma validation avant de générer le code.

## Plan de jalons proposé (à valider / réordonner)

1. **Socle** : init projet via FVM, structure feature-first, theme.dart (charte DIF), go_router, mise en place i18n (ARB FR/EN), config Drift + première génération build_runner.
2. **Événements** : CRUD événements + archivage, définition des champs personnalisés, choix du mode de présence.
3. **Bénéficiaires** : ajout manuel, puis import CSV avec mapping des colonnes.
4. **Tickets** : génération des identifiants (lisible + aléatoire) et QR, écran d'aperçu, choix du modèle et des champs affichés.
5. **Export/partage** : rendu PDF des tickets (3 modèles), partage individuel.
6. **Contrôle de présence** : scan caméra + saisie de secours, règles selon le mode, compteur en direct animé.
7. **Sauvegarde** : export/import du fichier de sauvegarde local.
8. **Finitions** : animations, retours haptiques, écrans vides, gestion d'erreurs, polish visuel.

Livrer chaque jalon de façon fonctionnelle et testable avant de passer au suivant.

## Stratégie de test

- **Tests unitaires** en priorité sur la logique métier sensible : génération des identifiants (unicité, format), règles de check-in selon le mode (blocage en mode simple, historique en mode multiple), parsing/mapping de l'import CSV.
- **Tests de widget** sur les écrans clés (formulaire événement, écran de scan, compteur).
- Ne pas viser une couverture exhaustive au MVP : cibler les zones à risque de régression.
- Exécuter les tests via `fvm flutter test`.
