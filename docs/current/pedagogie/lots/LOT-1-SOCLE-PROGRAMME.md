# Lot 1 · SOCLE-PROGRAMME

> Branche `claude/socle-programme`, ouverte le 12/11/2026 sur la branche de la charte (`179ab28f4`).
> Plan : `PLAN-DE-CONSTRUCTION.md`, section « Lot 1 ». Valeurs : `REGLAGES.md` (tableau 1 et 1 bis).
> Statut : **présent dans le code, testé localement, NON installé, NON prouvé en production.** Personne n'est désigné pour fusionner (blocage en tête du plan).

## Ce que le lot réutilise

| Existant | Comment |
|---|---|
| `programme_versions`, `programme_niveaux` (0020, C2) | Une ligne de `programme_niveaux` est une **étape** ; `code_technique` devient son identité stable (`BASES-1` à `BASES-4`). La version en brouillon de production est complétée puis publiée. |
| `programme_niveaux.objectifs`, `plage_support`, `durees` (C2) | `durees[tranche].prevue` = durée prévue de l'étape ; `durees[tranche].limite` = **date limite de l'étape** en semaines (tableau 1 bis), comptée depuis l'entrée de l'élève dans l'étape. |
| Contrôle de publication de C2 | Gardé tel quel ; un second contrôle s'ajoute (sommes des étapes = niveau). |
| `private.etape_eleve` (SUIVI-ELEVE) | Même signature ; lit d'abord le fait « étape en cours ». Toutes ses lectures (`etapes_eleves_classe`, `rythme_classe`, `suivi_pedagogique_eleve`, `lire_resultats_evaluations`) rendent donc la même étape. |
| `private.sourates_des_bases`, `sourates_validees` (SOURATES) | Les 17 sourates de la lecture unique viennent d'ici, sans copie. |
| `private.cahier_c1_peut_lire_classe` | Garde de l'enseignant titulaire, du remplaçant (fenêtre de la séance) et de la direction. |
| `private.vitesse_eleve` | Le rythme rendu par la lecture unique (le calcul « À surveiller » est le lot 7). |
| `decider_placement`, `progression_promouvoir` (0021, 0022) | Les gestes existants de la direction : chaque décision publiée corrige le fait « étape en cours » par un déclencheur. |
| Branche `claude/parcours-inscrits-main` | **Déjà dans `main` et installée en production** (migration `20261123810000`, jamais modifiée par ce lot) ; la correction de la classe rendue passe par la NOUVELLE migration `20261123850000` (13/11). |
| Branche `claude/ma-progression-main` | **Déjà dans `main` et installée en production** (`ma_progression`, `programme_etape_reglages`, `20261123830000`), après la rédaction de ce lot. Son hub est gardé et NOURRI par la lecture unique (migration `20261123910000`, 13/11) : un seul appel pour l'écran de l'élève et de sa famille, un seul calcul de l'étape (voir « Fusion avec `main` du 13/11 »). |
| Écrans `features/suivi_eleve`, `features/suivi_foyer` (`CarteSuiviPedagogique`) | Lisent `ma_progression` (un seul appel), qui lit `etape_eleve_lecture` ; aucun nouvel écran. L'enseignant lit la même fonction par `PortSuiviPedagogique`. |

## Ce que le lot crée

- `public.programme_cycles` : le **niveau** d'une version (code stable `bases`, nom, durée prévue et date limite par tranche d'âge).
- `programme_niveaux.cycle_code` et `programme_niveaux.matieres` (matière principale et matière secondaire par tranche d'âge).
- `public.eleve_etape_en_cours` : le fait unique par élève (étape, date d'entrée dans l'étape, date d'entrée dans le niveau, tranche d'âge figée, `recul_jours` = point d'accroche du lot 2) ; `private.dates_etape` calcule, à un seul endroit, la date limite de l'étape et l'horizon du niveau.
- L'archivage automatique de la version publiée précédente à chaque publication, et un index qui interdit deux versions publiées.
- Le niveau de chaque classe posé seul (classes existantes et classes nouvelles) ; l'étape de chaque élève posée seule à l'entrée en classe (et pour les élèves déjà présents).
- `public.etape_eleve_lecture(p_eleve_id)` : la lecture unique, pour l'élève, le tuteur, l'enseignant, le remplaçant et la direction.
- Le réglage `programme.age_voit_date_limite` (10 ans) dans `app_config`.

## Ce qui reste pour le lot 10

Les anciens calculs restent en base, plus lus par les écrans touchés : la branche « sans fait » de `private.etape_eleve` (ancienne règle), `suivi_pedagogique_eleve` (plus appelée par le suivi de l'élève et du tuteur), l'étape de `groupe_roster_enseignant` (lit encore `progression_historique`, n'est affichée nulle part), `progression_admin`, `unite_curriculum`, `progression_famille.level`.

## Correction de l'architecte du 12/11 (appliquée)

La consigne initiale mettait la date limite sur le niveau, avec des repères indicatifs par étape. L'architecte l'a corrigée après audit (décision du directeur du 14/10) : **chaque étape a sa date limite par tranche d'âge**. Appliqué dans ce lot :

1. Données : chaque étape porte, par tranche, sa durée prévue et sa date limite (tableau 1 bis : 8 (10) / 6 (8) / 5 (6) / 3 (4) ; 14 (19) / 11 (14) / 9 (13) / 6 (8) ; 8 (10) / 6 (8) / 5 (6) / 3 (4) ; 7 (9) / 5 (6) / 5 (6) / 3 (4)). Les sommes restent 37/28/24/15 et 48/36/31/20, contrôlées à la publication et par le scénario.
2. La date limite d'une étape part de l'entrée de l'élève dans l'étape. La lecture unique rend l'étape, sa date d'entrée, sa durée prévue, sa date limite, et la fin du niveau (somme des étapes restantes, depuis l'entrée dans l'étape) comme simple horizon. Point d'accroche du recul : `recul_jours`.
3. L'enfant de 6 à 9 ans qui lit pour lui-même ne reçoit ni la date limite de l'étape ni l'horizon (ni le rythme) ; son tuteur les reçoit.
4. Un élève débutant (niveau déclaré vide, « débute avec les lettres » ou « lettres avec aide ») entre à l'étape 1, datée de son entrée en classe ; jamais « l'étape de la classe ». Les 3 classes reçoivent « les bases », étape 1. Un élève qui déclare déjà lire n'a pas d'étape supposée : la décision de la direction (entretien de lecture, `decider_placement`) la pose.
5. Les documents de `docs/current/pedagogie/` ne sont pas modifiés par ce lot (seule cette fiche) ; là où ils disent encore « date limite du niveau, repères », c'est cette correction qui s'applique.

## Choix techniques

- **Une ligne de `programme_niveaux` reste une étape** (ce que C2 avait déjà semé) ; le niveau est une table neuve `programme_cycles` plutôt que de renommer l'existant (aucun retrait possible dans ce lot).
- **Dates** : date limite de l'étape = entrée dans l'étape + `durees[tranche].limite` de l'étape + `recul_jours` ; horizon = entrée dans l'étape + dates limites de cette étape et des suivantes + `recul_jours`. Une décision publiée de la direction (placement, promotion, réévaluation, correction) change l'étape et date l'entrée du jour de la décision. Tranche figée à l'entrée dans le niveau.
- **Date d'entrée des élèves déjà présents** = jour de l'installation (revue du 12/11, règle de stabilité : un changement vaut pour la suite) ; un élève qui entre en classe après garde sa date d'entrée en classe.
- **Tranche inconnue** : `student_profiles.cohorte`, sinon « adulte » dans une classe d'adultes ; sinon aucune durée ni date (jamais supposée).
- **Qui voit les dates** : le serveur rend `eleve_voit_dates` (tranche connue et âge maximum ≥ `programme.age_voit_date_limite` = 10, ou tranche d'adultes ; tranche inconnue : faux). L'élève qui lit avec son propre compte et ne voit pas ses dates ne reçoit aucune date ni aucun nombre de semaines (étape, chemin, niveau). L'écran, dans l'espace de l'élève, n'affiche dates et durées que si `eleve_voit_dates` ; chez le tuteur, toujours. Le mode d'interface ne décide plus rien (un adulte en Interface guidée garde ses dates).
- **Semis à l'installation** : brouillon le plus récent complété (une ligne étrangère unique, ici `bases-lecture`, devient `BASES-1` ; rien n'est retiré), sinon version neuve ; auteur = auteur du brouillon, sinon plus ancien compte de la direction. Sur une base sans direction (CI), rien n'est semé : le scénario appelle `private.semer_programme_bases`.
- **`preremplir_bases_programme` et `creer_version_programme`** remplacés à signature identique : la proposition est désormais le contenu décidé ; la copie emporte niveau et matières.
- **Version du programme (règle 4 du directeur, `programme-rewayah` : « l'élève finit son étape dans sa version »)** : la publication ne déplace ni classe ni élève ; l'étape en cours se lit dans sa version, publiée ou archivée, jamais un brouillon (`private.etape_eleve`, `etape_eleve_lecture`, `etapes_eleves_classe`, `mes_classes_details` corrigée). Le chemin montre les étapes passées et l'étape en cours de la version de l'élève, les étapes à venir de la version publiée. Le changement de version se fait au passage d'étape : une décision de la direction (ou un changement d'étape d'une classe) mène à l'étape de même code dans la version publiée (`private.etape_publiee_equivalente`) ; code absent : refus `programme_code_absent`. `public.etapes_sur_ancienne_version()` dit à la direction combien d'élèves et de classes finissent une étape d'une version archivée.
- **Statut du chemin** : `precedente` (« Étape précédente »), jamais « Étape validée », réservé au résultat d'une évaluation (lot 8).
- **Élève en attente de l'entretien de lecture** : la lecture rend `{"attente": "entretien_de_lecture"}` ; l'écran dit « Votre étape sera fixée après l'entretien de lecture avec la direction. » (tutoiement en Interface guidée ; « Pour {prénom}, l'étape sera fixée… » chez le tuteur). « L'étape apparaîtra dès l'entrée dans une classe » reste pour l'élève sans classe.
- **`private.etape_eleve`** (même signature) lit le fait d'abord : `etapes_eleves_classe`, `rythme_classe`, `suivi_pedagogique_eleve` rendent la même étape et la même date limite d'étape ; sans fait, l'ancienne règle (lot 10).
- **Remplaçant** : un seul chemin, la garde partagée `private.cahier_c1_peut_lire_classe` (inchangée). Elle ouvre la lecture à l'enseignant effectif d'une séance de la classe (`private.c29_enseignant_effectif_session` : le remplaçant du dernier événement `remplacement_pris` ou `remplacement_designe_admin`, donc dès l'acceptation) tant que la fin prévue de cette séance (`sessions.ended_at`) est dans moins de 24 heures passées : c'est exactement la fenêtre de la charte (de l'acceptation à 24 heures après la fin). Le second chemin ajouté plus tôt était redondant : retiré, avec son réglage. Testé : avant acceptation, refus ; accepté avant la séance, lecture ; 25 heures après la fin, refus ; autre classe, refus. Limite : la durée de 24 heures est écrite en dur dans la garde partagée (« 1 day »), pas lue dans `app_config`.
- **Écran** : `CarteSuiviPedagogique` (élève et tuteur) lit `ma_progression` (qui lit `etape_eleve_lecture`) : étape, page de reprise, objectifs, matières, date d'entrée, durée de l'étape (« N semaines prévues, M au plus »), « À finir avant le » (étape), « Les bases : fin au plus tard le » (horizon), rythme, chemin du niveau ; sourates et réglage de la direction (apports de `ma_progression`) ; sans étape, sans sourates ni jalon, le bloc n'est pas posé (contrat de MA-PROGRESSION-ECRAN, qui prévaut sur l'ancien état vide du lot). Enfant de 6 à 9 ans : ni date, ni horizon, ni rythme, ni durées (le serveur les retient ; une réponse sans `eleve_voit_dates` garde la règle d'avant : Interface guidée = ni rythme ni date limite). Côté enseignant, rien ne change à l'écran.

## Seconde revue du 12/11 (appliquée)

1. Enfant de 6 à 9 ans : aucune date, la date d'entrée comprise (`etape.entree_le`, `niveau.entree_le` à NULL quand les dates sont retenues) ; à l'écran, la ligne « Dans cette étape depuis le » suit la même règle.
2. Élève sans fait (déclaré lecteur, en attente de l'entretien) : dès qu'une version est publiée, `private.etape_eleve` ne lui suppose plus l'étape de la classe ; `etapes_eleves_classe`, `rythme_classe` et `etape_eleve_lecture` disent la même chose ; la fiche de l'élève chez l'enseignant affiche « En attente de l'entretien de lecture avec la direction ».
3. Publication refusée (`programme_sans_bases`) pour une version sans le niveau des bases complet ou avec une étape hors d'un niveau.
4. Écran Programmes de la direction : la date limite d'une étape se lit et s'enregistre telle que le serveur la rend, la direction la modifie (un `ChoixNombre` par tranche) ; plus de calcul × 1,3 (`dateLimiteDeduite` retiré) ; refus de publication en mots simples (`programme_incoherent`, `programme_sans_bases`).
5. Une décision sur l'étape en cours (même code : réévaluation, certification) ne change ni l'étape, ni la date d'entrée, ni la date limite.
6. `suivi_pedagogique_eleve` (ancienne lecture) applique le même masquage, par la même fonction (`private.dates_retenues`).
7. Le message du semis compte les faits réellement posés.
8. `etapes_sur_ancienne_version` ne compte que les élèves non supprimés membres actifs d'une classe vivante.
9. Retour en classe après une sortie d'au moins un jour : le fait est gardé, la date d'entrée dans l'étape devient le jour du retour ; un transfert le même jour ne change rien (choix de l'agent : seuil d'un jour).
10. Matière secondaire de l'étape 4 pour les 6-9 ans : « La suite des sourates commencées (An-Nâs, Al-Falaq, Al-Ikhlâs), puis les paroles de la prière et les ablutions, puis les invocations ; avec la révision de la lecture et l'adab » (lignes 46 et 48 de la compétence, citées dans `private.contenu_bases`). L'ajout « avec la révision de la lecture et l'adab » vient de la ligne 48, en plus du texte demandé.

**Reste à faire dans un lot suivant (noté, non touché)** : la garde partagée du remplaçant (`private.cahier_c1_peut_lire_classe`) ne regarde pas si la séance est annulée et garde « 24 heures » en dur (« 1 day ») au lieu d'un réglage ; le texte « Proposition à valider par la direction » de l'écran Programmes (brouillon) dit encore « une proposition, pas une règle ».

## Comment un enfant accède à l'application (relevé dans le code)

Un enfant a **son propre compte** (`profiles.id` = compte d'authentification, rôle `student`). Il n'utilise jamais le jeton du tuteur : son appareil s'appaire par un code créé par le tuteur (`ServiceAppairage.creerCode`, RPC `creer_code_appairage`), puis la fonction `supabase/functions/session-enfant/index.ts` échange le code (`consommer_code_appairage`) ou le jeton de l'appareil (`profil_du_jeton_appareil`) contre une session de l'enfant (lien magique sur son courriel technique, `token_hash`). Sur un appareil partagé, choisir un profil local (`lib/core/appairage/profils_locaux.dart`) rouvre la session de cet enfant avec son jeton d'appareil (`ServiceEnfant.ouvrirSession`). Il voit donc l'espace de l'élève (`Routes.eleveSuivi`, « Ma classe », `SuiviElevePage`, Interface guidée de 6 à 9 ans), où `CarteSuiviPedagogique` lit pour lui-même. Le cas « enfant dans l'espace de l'élève avec le jeton du tuteur » n'existe pas dans le code ; il est tout de même couvert à l'écran par `eleve_voit_dates` (test dédié).

## Ce qui est fait et testé (12/11/2026, poste de l'agent)

- Postgres 16 local (la CI tourne en 17) : stub, puis les 434 migrations, vert ; `scenarios_socle_programme.sql` : 60 contrôles verts ; `scenarios_parcours_inscrits.sql` : 13 (dont le cas classe A et inscription vers B) ; `scenarios_suivi_eleve_pedagogique.sql`, `scenarios_rythme_lecture.sql` et `scenarios_cahier_c2_programme_donnees.sql` rejouent l'installation (`rattacher_classes_et_eleves`) et lisent la vitesse par le tuteur (l'enfant de 6-9 ans ne la reçoit plus) ; `scenarios_mes_classes_details.sql` adapté (l'étape d'une version archivée est rendue) ; les 276 scénarios du dossier : tous verts (`cahier_c2`, `suivi_eleve_pedagogique`, `rythme_lecture` adaptés : 19 semaines au lieu de 18 pour l'étape 2 en 6-9 ans, et la décision sur brouillon qui ne change plus le fait).
- Installation simulée sur une base qui reproduit l'état de production (brouillon `bases-lecture`, une classe sans étape, deux élèves débutants entrés il y a 10 et 30 jours) : version publiée, 4 étapes, classe à BASES-1, 2 élèves à l'étape 1 datée du jour de l'installation ; un élève sans tranche reçoit son étape sans date (jamais supposée).
- Flutter 3.47.9 (12/11, après la dernière modification, commit `2fbee95`) : slang et build_runner sans diff ; `dart analyze --fatal-infos` sans problème ; `flutter test` complet : 20 661 verts, 8 122 sautés, 0 échec ; `verifier_jetons` : aucune violation ; `verifier_branchement` : aucun fichier nouveau non atteint.
- Captures : `docs/current/captures/E2E/socle-programme/` (élève adulte, enfant en Interface guidée, tuteur, feuille d'une étape à la direction ; 390 et 1440 ; clair et sombre), vrai routeur, données simulées.

## Écarts entre le plan et le code trouvé

1. Le plan dit « `programme_niveaux` : 1 niveau » ; dans le code, une ligne de `programme_niveaux` est une **étape** (C2 y sème `BASES-1` à `BASES-4`). Le « niveau » n'existait qu'en texte (`cycle`). D'où `programme_cycles`.
2. C2 calculait la date limite d'étape par durée × 1,3 (sommes 47/37/33/20) ; remplacée par le tableau 1 bis (sommes 48/36/31/20). La date reste par étape (correction de l'architecte du 12/11) ; la charte, qui la met sur le niveau, est en cours de correction sur `claude/charte-ecole`.
3. Objectifs : ceux de C2 sont repris, sauf deux formulations corrigées vers `EVALUATIONS.md` 4.2 et 4.3 (« Reconnaît chaque lettre dans le désordre », « Lit une lettre avec chacune des trois voyelles ») ; ceux de l'étape 4 gardent la phrase citée par le directeur le 11/11.
4. Matière secondaire des 10 ans et plus : « Al-Fatiha dès la première semaine, puis le même ordre » (`EVALUATIONS.md` 4.1, ARBITRÉ) ; 6-9 ans : aucune avant la chadda (étapes 1 et 2).
5. `groupe_roster_enseignant` lit encore `progression_historique` pour l'étape ; aucun écran ne l'affiche : laissé pour le lot 10.
6. L'écran Programmes de la direction calcule encore la date limite × 1,3 dans sa feuille de saisie d'un brouillon : non touché (hors des écrans du lot) ; à corriger avec la saisie du programme. Le niveau de chaque classe se lit déjà dans les écrans de classes (`mes_classes_details`).
7. Numéros de migration du lot : `20261123850000`, `20261123900000`, `20261123910000` (plage du lot ; à confirmer par le garde-cap).
8. « Étape de la classe par défaut » : le plan disait « par défaut l'étape de la classe » ; la correction du 12/11 l'interdit pour un élève (débutant à l'étape 1). Un élève qui déclare lire attend l'entretien : il peut donc rester sans étape (choix de l'agent, à valider).
9. La migration n'est pas rejouable : son préflight refuse une seconde installation (le semis seul est idempotent).
10. `parcours-inscrits` (installée en production) : la classe rendue était celle de l'inscription (`COALESCE(i.groupe_id, gm.groupe_id)`) alors que l'état « affectée » vient de l'adhésion ; prouvé faux par un cas de test (membre de A, inscription vers B : rouge sur la 810000 seule, vert avec la 850000). La 810000 est remise EXACTEMENT à la version de `main` ; la correction est la migration neuve `20261123850000_parcours_inscrits_classe_adhesion.sql`.
11. Matière secondaire de l'étape 4 : les paroles de la prière et les ablutions y sont rétablies « tant qu'elles ne sont pas confirmées » (exigées à l'examen ; un enfant de 6 à 9 ans ne les atteint pas avant l'étape 4). Sources ligne par ligne dans le commentaire de `private.contenu_bases`.
12. `progression_promouvoir` exige une première décision (« passez par Diagnostics ») : pour un élève posé automatiquement, le premier geste de la direction est `decider_placement` (règle existante, non changée).
