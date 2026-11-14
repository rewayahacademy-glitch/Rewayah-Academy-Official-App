# Lot 5, partie A · PLAN-DE-CLASSE (gestes de la direction)

> Branche `claude/plan-de-classe`, ouverte le 13/11/2026 sur `claude/socle-programme` (lot 1, relu et figé).
> Plan : `PLAN-DE-CONSTRUCTION.md`, lot 5. Origine de la partie A : « Ce que la direction ne peut pas encore faire », fiche du lot 1.
> Arrêt du 13/11 (budget) : FAIT et testé en SQL (114 contrôles verts avec le lot 1 seul, le lot 2 avant et le lot 2 après) : B1bis (fiche d'élève supprimée), B2 (`jour_academie` aligné sur le lot 2 ; aperçu par le même chemin que l'écriture), I5 (`10.0`). Analyse, jetons, branchement, revue et 23 tests d'écran verts. NON FAIT : la suite `flutter test` complète n'a pas fini sur cette tête (14 274 passés, 0 échec, arrêtée aux trois quarts) ; le lot 2 doit passer son `CREATE FUNCTION private.jour_academie()` en `CREATE OR REPLACE` ; contre-lecture du delta non faite.
> Statut : **présent dans le code, testé localement (Postgres 16 nu et `flutter test`), NON installé, NON prouvé en production.**
> Ce que cette partie ne fait pas : le plan séance par séance daté par le serveur, le point de fin de séance, le chemin, le moteur. Aucun de ces fichiers n'est touché.

## Ce que la direction peut faire, une fois la migration installée

1. **Donner une étape à une classe déjà ouverte.** Fiche de la classe côté direction (`/admin/operations/groupes/<id>`) : une ligne « Étape » (l'étape de la classe, ou « Aucune étape pour le moment », et combien de ses élèves n'ont pas d'étape) ; menu de la classe, « Donner une étape à la classe » : les étapes de la version publiée, un motif, un geste (`donner_niveau_classe`). Les membres sans étape la reçoivent par le mécanisme du lot 1 (`private.poser_etape_eleve`) : un débutant entre à l'étape 1, un élève qui déclare déjà lire attend la décision de la direction, un élève qui a déjà son étape la garde (jamais de doublon, jamais de remplacement). Tracé au journal (`classe_niveau_donne`).
2. **Dire qu'un élève déjà en cours a commencé à une date passée.** Deux endroits : le menu de chaque élève de la fiche de la classe (« Dire quand il a commencé », `dater_entree_etape`) et le formulaire de placement de Diagnostics (champ « A-t-il commencé avant aujourd'hui ? », `decider_placement_depuis`, un seul geste, une seule transaction). Bornes appliquées par le serveur (arbitrage de l'architecte, 13/11) : jamais dans le futur, au jour de La Mecque (`date_future`) ; jamais sous un plancher, réglage `programme.date_debut_plancher_annees` (dix ans par défaut, `date_sous_plancher`, le message donne le plus ancien jour accepté). Aucune référence à la date d'inscription du compte : l'académie enseignait avant l'application, un élève déjà en cours a presque toujours commencé avant la création de son compte. La date limite de l'étape se calcule depuis cette date (le calcul du lot 1, inchangé). Tracé (`entree_etape_datee` : ancienne et nouvelle date, motif).
3. **Placer les élèves déjà membres.** Diagnostics, en tête : « Élèves sans étape », avec pour chaque élève sa classe et pourquoi (`aucun programme publié`, `sait déjà lire : attente de l'entretien`, `débutant : recevra l'étape 1 au rattachement`) et les classes ouvertes sans étape ; le bouton « Rattacher les débutants et les classes » (`rattacher_eleves_et_classes`, qui appelle `private.rattacher_classes_et_eleves` du lot 1, sans le modifier) après une phrase qui dit ce qui va se passer. La file des placements, un élève à la fois, reste dessous, inchangée.
4. **Sortir de l'impasse du brouillon.** Programmes : un brouillon qui ne se publie pas dit pourquoi, en mots simples, d'après le serveur (`etat_publication_brouillon` essaie la publication dans une sous-transaction puis annule : aucune règle recopiée côté application, aucun effet), et offre « Repartir des bases » (`repartir_des_bases_programme` : une version neuve, vide puis remplie des bases, sans toucher ni effacer le brouillon). Le bouton « Créer une version vide » existait déjà et reste offert quand un brouillon existe (vérifié, test).

## Ce que le lot réutilise (rien n'est dupliqué)

`private.poser_etape_eleve`, `private.rattacher_classes_et_eleves`, `private.dates_etape`, `decider_placement`, `creer_version_programme`, `preremplir_bases_programme`, `publier_version_programme` ; les écrans Diagnostics, Programmes et la fiche de la classe ; `SelecteurNiveauProgramme`, `SelecteurMotif`, `ChampDate` (un paramètre `premier` ajouté pour ouvrir le calendrier vers le passé), `AppBottomSheet`, `MenuActions`, `LigneCleValeur`.

## Migration

`supabase/migrations/20261125700000_plan_de_classe_a_gestes_direction.sql`  : un fichier, additif, zéro DROP, DELETE ni TRUNCATE (grep ; `apply_migration` ne demandera donc pas de seconde confirmation). Pas de `BEGIN;`/`COMMIT;` dans le fichier, comme les migrations du lot 1 : c'est l'enveloppe de collage (`tool/envelopper_pour_editeur_sql.py`) qui l'exécute en une seule transaction. Un bloc de garde qui contrôle ce que la migration utilise vraiment (les neuf objets du lot 1 : tout vient de `20261123900000` ; `850000` et `905000` ne sont pas utilisés ici, sinon refus net), cinq fonctions privées (`jour_academie`, `plancher_date_debut`, `eleve_placable`, `fixer_entree_etape`, `version_bases_intacte`, toutes fermées à tous), dix fonctions publiques, toutes `SECURITY DEFINER`, `search_path` vide, `REVOKE` de PUBLIC, anon et service_role, `EXECUTE` à `authenticated` ; la garde est la direction (`app_role() = 'admin'` et compte valide, exigence positive). Rejouable (`CREATE OR REPLACE`). Aucune table, aucune colonne.

**Ordre d'installation** : `20261123850000`, `20261123900000`, `20261123905000` (lot 1), puis cette migration. Entre l'installation de cette migration et la fusion de la branche, rien ne change pour personne : aucun écran de `main` n'appelle ces fonctions.

## Preuves

- `supabase/tests/scenarios_plan_de_classe_a.sql` : 17 transactions séparées (une par enchaînement de gestes, chacune sur sa fixture), 114 vérifications. Rejoué sur une base neuve (stub d'authentification puis toutes les migrations) : vert. **Contre-épreuve** : 52 mutations (dont 2 qui ne rougissent que sur une base avec le lot 2) (chaque garde de direction, chaque refus métier, chaque borne de date et le plancher, sa lecture sûre, l'adulte titulaire et le tuteur refusé, la date reposée dans les deux sens, le recul conservé, l'aperçu, l'idempotence de « repartir des bases », l'annulation de l'essai de publication, les `REVOKE`, le `search_path`, l'ouverture des aides privées, la protection des étapes existantes, l'exclusion des élèves sortis ou supprimés) : chacune fait rougir le scénario.
- Tests d'écran par le vrai routeur (`test/features/admin_plan_de_classe/plan_de_classe_a_test.dart`) : 23 tests (geste envoyé, phrase du refus, bouton jamais grisé, motif jamais pré-choisi, états chargement / contenu / vide / erreur de la section).
- Captures : `test/capture/plan_de_classe_a_capture_test.dart` (390 et 1440, clair et sombre, français et arabe), sautées sans `CAPTURE_DIR`.

## Hypothèses et arbitrages

Arbitrés par l'architecte pédagogique le 13/11/2026 (le directeur ne répond pas aux questions du lot) :

1. **REFUSÉE puis corrigée** : la borne « pas avant l'inscription du compte » détruisait le besoin. Règle : jamais dans le futur, plancher réglable (dix ans par défaut), lu côté serveur ; plus aucune référence à `profiles.created_at`.
2. **Le jour se compte au jour de La Mecque** (jour de référence de l'académie), par `private.jour_academie()` : le fuseau `Asia/Riyadh` est écrit en dur dans CETTE seule fonction, à rebrancher sur la fonction de jour du lot 2 quand elle sera dans `main`.
3. Un débutant d'une classe portée à l'étape 3 reçoit quand même l'étape 1 (règle du lot 1) ; la feuille le dit avant le geste. Acceptée.
4. Le rattachement donne l'étape 1 à toutes les classes ouvertes sans étape d'un coup ; pour une autre étape, faire le geste par classe d'abord. Acceptée.
5. Un brouillon abandonné reste un brouillon (pas de suppression ni d'archivage de brouillon). Acceptée.
6. La date de début se donne par élève. Acceptée. **DETTE** : un geste « toute la classe a commencé le… » n'est pas fait dans ce lot.
7. Écrans de la direction : l'Interface guidée (libellé toujours visible, cibles de 72) ne concerne pas ces écrans.

Le calendrier de l'écran remonte large (30 ans) : le plancher est dit par le serveur, jamais recopié côté Flutter.

## Règles ajoutées après la relecture indépendante du 13/11 (arbitrées par l'architecte)

- **Adulte titulaire.** Un adulte élève autonome a le rôle `guardian` ; `decider_placement` (main) ne le place pas. `decider_placement_depuis` place aussi « un titulaire adulte qui est lui-même élève autonome » (`student_profiles.titulaire_profile_id` = son identifiant, type autonome), jamais un tuteur qui n'est pas élève, jamais un compte supprimé ; elle reprend les refus et la trace de `decider_placement`, qui reste intacte. L'écran Diagnostics offre « Décider son placement » sur chaque ligne « attente de l'entretien ».
- **Date reposée.** Elle REMPLACE celle qu'on avait posée. L'entrée dans le niveau suit quand elle coïncide avec l'entrée dans l'étape ; si l'élève est monté d'une étape précédente (les deux dates diffèrent), elle reste et n'est abaissée que si la nouvelle date la précède. Limite connue : sans historique des entrées d'étape, un élève monté puis daté avant son entrée dans le niveau n'a plus que la date posée comme entrée dans le niveau.
- **`recul_jours`** : ce lot ne l'écrit jamais. Lot 1 seul : il reste ce qu'il était. Avec le lot 2 : son déclencheur le dérive à chaque écriture du fait, donc à chaque date posée ; l'aperçu passe par le même chemin (voir ci-dessous).
- **Date limite déjà passée à la pose.** Avant de confirmer, la feuille montre la date limite qui en résulte (`apercu_date_limite`) et dit en mots simples quand elle est déjà passée ; aucune notification, la direction confirme en connaissance de cause. **DETTE, question pour le directeur** : faut-il qu'un élève repris en cours reçoive un délai neuf plutôt qu'une limite déjà passée ?
- **Plancher lu sans sûreté** corrigé : entier de 1 à 50, sinon dix ans, jamais d'erreur brute (0, négatif, texte, décimal, booléen, 100000, null JSON, exposant énorme).
- **Repartir des bases est idempotent** : un brouillon « des bases » jamais modifié (les quatre étapes et le niveau exactement comme `remplir_version_bases` les écrit) est rendu au lieu d'en créer un autre.
- **Le calendrier borne sur le jour du serveur** (`jour_academie_direction`, jour de La Mecque), jamais sur celui de l'appareil.

## Contre-lecture du 13/11 (second tour) : collision avec le lot 2, arbitrée par l'architecte

- **`private.jour_academie()`** existe aussi dans le lot 2 (`20261123910000`). Même en-tête, même corps (octet pour octet), mêmes droits, `CREATE OR REPLACE` dans les deux fichiers : l'ordre d'installation est indifférent. **Action pour le lot 2** : passer sa ligne `CREATE FUNCTION private.jour_academie()` en `CREATE OR REPLACE FUNCTION` (la consigne est donnée à son auteur).
- **L'aperçu est le même calcul que l'écriture.** `apercu_date_limite` ne recalcule plus rien : il fait le geste (placement et/ou datation, par `private.fixer_entree_etape` et l'insertion de la décision, donc avec les déclencheurs d'aujourd'hui et de demain), lit `private.dates_etape`, puis ANNULE tout dans une sous-transaction (aucune trace, aucun journal). Avec le lot 2, le recul est celui que son déclencheur dérive à l'écriture. Un jour que l'écriture refuserait est refusé par l'aperçu (`refus`, sans date). La fonction est volatile (elle écrit puis annule).
- **Scénario vert dans les trois états**, rejoué : lot 1 seul, lot 2 installé AVANT cette migration, lot 2 installé APRÈS (copie de `origin/claude/calendrier-pauses`, `52d6ee1d`, avec `jour_academie` en `CREATE OR REPLACE`). Une fermeture publiée de 7 jours prouve que l'aperçu annonce exactement la date posée ensuite ; l'ancien aperçu (qui reprenait le `recul_jours` d'avant) est rouge dans les deux ordres.
- **`private.eleve_placable`** teste aussi `student_profiles.deleted_at` (fiche d'élève autonome supprimée : plus de placement).
- **Réglage du plancher** : `10.0` ne lève plus d'erreur (numeric, entier contrôlé, puis cast).

## Non prouvé, bloqué ou à faire par un autre

- **Rien n'est installé ni éprouvé en production.** « Fait » veut dire prouvé par le directeur après installation et fusion.
- **`.github/workflows/ci.yml`** ne nomme pas le nouveau scénario SQL, et le garde du dépôt interdit à l'agent d'y écrire : le pilote ajoute `scenarios_plan_de_classe_a.sql` à la liste.
- `flutter test` complet : voir le rapport (résultat au moment de la poussée).
- Le garde `verifier_revue` : voir le rapport.
