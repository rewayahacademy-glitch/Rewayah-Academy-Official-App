# Lot 5, partie A · PLAN-DE-CLASSE (gestes de la direction)

> Branche `claude/plan-de-classe`, ouverte le 13/11/2026 sur `claude/socle-programme` (lot 1, relu et figé).
> Plan : `PLAN-DE-CONSTRUCTION.md`, lot 5. Origine de la partie A : « Ce que la direction ne peut pas encore faire », fiche du lot 1.
> Statut : **présent dans le code, testé localement (Postgres 16 nu et `flutter test`), NON installé, NON prouvé en production.**
> Ce que cette partie ne fait pas : le plan séance par séance daté par le serveur, le point de fin de séance, le chemin, le moteur. Aucun de ces fichiers n'est touché.

## Ce que la direction peut faire, une fois la migration installée

1. **Donner une étape à une classe déjà ouverte.** Fiche de la classe côté direction (`/admin/operations/groupes/<id>`) : une ligne « Étape » (l'étape de la classe, ou « Aucune étape pour le moment », et combien de ses élèves n'ont pas d'étape) ; menu de la classe, « Donner une étape à la classe » : les étapes de la version publiée, un motif, un geste (`donner_niveau_classe`). Les membres sans étape la reçoivent par le mécanisme du lot 1 (`private.poser_etape_eleve`) : un débutant entre à l'étape 1, un élève qui déclare déjà lire attend la décision de la direction, un élève qui a déjà son étape la garde (jamais de doublon, jamais de remplacement). Tracé au journal (`classe_niveau_donne`).
2. **Dire qu'un élève déjà en cours a commencé à une date passée.** Deux endroits : le menu de chaque élève de la fiche de la classe (« Dire quand il a commencé », `dater_entree_etape`) et le formulaire de placement de Diagnostics (champ « A-t-il commencé avant aujourd'hui ? », `decider_placement_depuis`, un seul geste, une seule transaction). Bornes appliquées par le serveur : jamais dans le futur (`date_future`), jamais avant l'inscription de l'élève (`date_avant_inscription`). La date limite de l'étape se calcule depuis cette date (le calcul du lot 1, inchangé). Tracé (`entree_etape_datee` : ancienne et nouvelle date, motif).
3. **Placer les élèves déjà membres.** Diagnostics, en tête : « Élèves sans étape », avec pour chaque élève sa classe et pourquoi (`aucun programme publié`, `sait déjà lire : attente de l'entretien`, `débutant : recevra l'étape 1 au rattachement`) et les classes ouvertes sans étape ; le bouton « Rattacher les débutants et les classes » (`rattacher_eleves_et_classes`, qui appelle `private.rattacher_classes_et_eleves` du lot 1, sans le modifier) après une phrase qui dit ce qui va se passer. La file des placements, un élève à la fois, reste dessous, inchangée.
4. **Sortir de l'impasse du brouillon.** Programmes : un brouillon qui ne se publie pas dit pourquoi, en mots simples, d'après le serveur (`etat_publication_brouillon` essaie la publication dans une sous-transaction puis annule : aucune règle recopiée côté application, aucun effet), et offre « Repartir des bases » (`repartir_des_bases_programme` : une version neuve, vide puis remplie des bases, sans toucher ni effacer le brouillon). Le bouton « Créer une version vide » existait déjà et reste offert quand un brouillon existe (vérifié, test).

## Ce que le lot réutilise (rien n'est dupliqué)

`private.poser_etape_eleve`, `private.rattacher_classes_et_eleves`, `private.dates_etape`, `decider_placement`, `creer_version_programme`, `preremplir_bases_programme`, `publier_version_programme` ; les écrans Diagnostics, Programmes et la fiche de la classe ; `SelecteurNiveauProgramme`, `SelecteurMotif`, `ChampDate` (un paramètre `premier` ajouté pour ouvrir le calendrier vers le passé), `AppBottomSheet`, `MenuActions`, `LigneCleValeur`.

## Migration

`supabase/migrations/20261124600000_plan_de_classe_a_gestes_direction.sql`  : un fichier, additif, zéro DROP, DELETE ni TRUNCATE (grep ; `apply_migration` ne demandera donc pas de seconde confirmation). Pas de `BEGIN;`/`COMMIT;` dans le fichier, comme les migrations du lot 1 : c'est l'enveloppe de collage (`tool/envelopper_pour_editeur_sql.py`) qui l'exécute en une seule transaction. Un bloc de garde (le lot 1 doit être installé, sinon refus net), une fonction privée, huit fonctions publiques, toutes `SECURITY DEFINER`, `search_path` vide, `REVOKE` de PUBLIC, anon et service_role, `EXECUTE` à `authenticated` ; la garde est la direction (`app_role() = 'admin'` et compte valide, exigence positive). Rejouable (`CREATE OR REPLACE`). Aucune table, aucune colonne.

**Ordre d'installation** : `20261123850000`, `20261123900000`, `20261123905000` (lot 1), puis cette migration. Entre l'installation de cette migration et la fusion de la branche, rien ne change pour personne : aucun écran de `main` n'appelle ces fonctions.

## Preuves

- `supabase/tests/scenarios_plan_de_classe_a.sql` : 9 transactions séparées (une par enchaînement de gestes, chacune sur sa fixture), 66 vérifications. Rejoué sur une base neuve (stub d'authentification puis toutes les migrations) : vert. **Contre-épreuve** : 24 mutations (chaque garde de direction, chaque refus métier, chaque borne de date, l'annulation de l'essai de publication, deux `REVOKE`, le `search_path`, l'ouverture de l'aide privée, la protection des étapes existantes, l'exclusion des élèves sortis) : chacune fait rougir le scénario.
- Tests d'écran par le vrai routeur (`test/features/admin_plan_de_classe/plan_de_classe_a_test.dart`) : 16 tests (geste envoyé, phrase du refus, bouton jamais grisé, motif jamais pré-choisi, états chargement / contenu / vide / erreur de la section).
- Captures : `test/capture/plan_de_classe_a_capture_test.dart` (390 et 1440, clair et sombre, français et arabe), sautées sans `CAPTURE_DIR`.

## Hypothèses (le directeur ne répond pas aux questions du lot)

1. **« Avant son inscription »** se lit sur `profiles.created_at`. Un inscrit actuel importé ne peut donc pas remonter avant la date d'import de son compte ; si le directeur veut une autre borne, c'est une décision.
2. **Un débutant d'une classe portée à l'étape 3 reçoit quand même l'étape 1** (règle du lot 1, « jamais l'étape de la classe »). La fiche le dit avant le geste.
3. **Le jour se compte en UTC** pour la borne « pas dans le futur » : le Canada étant en retard sur l'UTC, aucune date légitime n'est refusée à tort ; un jour tout juste à venir à Toronto peut passer quelques heures.
4. **Le rattachement donne l'étape 1 à toutes les classes ouvertes sans étape à la fois** (comportement de `private.rattacher_classes_et_eleves`). Pour donner une autre étape à une classe, faire ce geste d'abord, puis le rattachement.
5. **Un brouillon abandonné reste un brouillon** (la base n'a pas de suppression ni d'archivage de brouillon, et ce lot n'en ajoute pas).
6. La **date de début** se donne par élève ; il n'y a pas de geste « toute la classe a commencé le… ».
7. Écrans de la direction : l'Interface guidée (libellé toujours visible, cibles de 72) ne concerne pas ces écrans, réservés à la direction.

## Non prouvé, bloqué ou à faire par un autre

- **Rien n'est installé ni éprouvé en production.** « Fait » veut dire prouvé par le directeur après installation et fusion.
- **`.github/workflows/ci.yml`** ne nomme pas le nouveau scénario SQL, et le garde du dépôt interdit à l'agent d'y écrire : le pilote ajoute `scenarios_plan_de_classe_a.sql` à la liste.
- `flutter test` complet : voir le rapport (résultat au moment de la poussée).
- Le garde `verifier_revue` : voir le rapport.
