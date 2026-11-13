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

## Fusion avec `main` du 13/11 et vérification (architecte, 13/11)

`main` avait avancé de 32 commits : `20261123810000` (installée), `820000` (CORRIGER-SOURATE), `830000` (MA-PROGRESSION), `840000` (accent). Choix et preuves :

1. **`20261123810000` remise EXACTEMENT à la version de `main`** (diff vide). La correction de la classe rendue (`COALESCE(gm.groupe_id, i.groupe_id)`) est la migration neuve `20261123850000_parcours_inscrits_classe_adhesion.sql` (`CREATE OR REPLACE VIEW`, mêmes 22 colonnes dans le même ordre, pré-contrôle des colonnes et de l'état « affectée », `security_invoker` et droits redits). Preuve : le cas « membre de A, inscription vers B » est ROUGE sur la 810000 seule et VERT avec la 850000 (13 contrôles du scénario).
2. **Un seul hub : `ma_progression` (installée) reste l'appel de l'écran de l'élève et de sa famille ; elle lit désormais `etape_eleve_lecture`** (migration neuve `20261123910000_ma_progression_sur_socle.sql`, `CREATE OR REPLACE`, signature, propriétaire, droits et garde inchangés). Pourquoi cette direction : l'écran « Ma progression » de `main` est en ligne et lit `ma_progression` ; la lecture unique est la seule à connaître le fait par élève, la version propre à l'élève, les matières et la retenue des dates de l'enfant de 6 à 9 ans. `ma_progression` doublait ce calcul (étape par `suivi_pedagogique_eleve` et version publiée) et laissait passer des dates à l'enfant par `atteinte_le` et `rythme`. Elle garde ses clés (`etape`, `etapes_du_cycle` avec `franchie`, `en_cours`, `a_venir`, `sourates`, `reglage`) pour que l'écran en ligne continue de lire, et reçoit en plus `niveau`, `eleve_voit_dates`, `attente`, les matières, l'entrée dans l'étape et la durée et la date limite de chaque étape du chemin. Les sourates (`sourates_eleve`) et le réglage (`programme_etape_reglages`) restent servis par leurs fonctions, sans second calcul du chemin. Preuve : un scénario montre que `ma_progression` et `etape_eleve_lecture` rendent la même étape, le même niveau et le même chemin.
3. **Dart : un seul enum `StatutEtape`** (celui de `main`, `core/suivi/ma_progression.dart` : `franchie`, `enCours`, `aVenir`) ; le chemin parallèle du lot (`EtapeDuChemin`, `StatutEtape.precedente`) est retiré. Le mot visible d'une étape passée est « Étape précédente » (arbitrage de l'architecte du 13/11 ; la valeur technique reste `franchie`), source déclarée dans `tool/libelles_sources.json`. **L'arabe de ces deux libellés (`etapeFranchie`, `etapeFranchieLe`) est écrit par l'agent : à faire relire.** `CarteSuiviPedagogique` lit `MaProgression` seule et fusionne les deux apports. `eleveVoitDates` est nul quand le serveur ne le dit pas : la règle d'avant (Interface guidée = ni rythme ni date limite ni réglage) s'applique alors en entier ; quand il le dit, il décide, et l'écran du tuteur montre toujours les dates. `PortSuiviPedagogique` est rendu à l'enseignant seul (fiche de l'élève : « en attente de l'entretien ») : `ma_progression` ne lui est pas ouverte.
4. **`20261123900000`** : installée APRÈS `820000`, `830000`, `840000` (elle ne remplace aucune de leurs fonctions : elle lit `sourates_validees`, `sourates_des_bases`) ; plus aucun `BEGIN;` ni `COMMIT;` seul sur une ligne (idem 850000 et 910000). **Défaut trouvé et corrigé à la fusion** : depuis 820000 une sourate retirée garde sa ligne (`retiree_le`), et la lecture unique la comptait encore ; elle l'écarte maintenant, et le préflight refuse l'installation si 820000 manque. Prouvé par un scénario (3 sur 17 dans le hub ET dans la lecture unique).
5. **Zéro `DROP`, `DELETE`, `TRUNCATE`** dans les trois migrations (850000, 900000, 910000), comptés mot entier, commentaires compris.

**Ordre d'installation pour la production** (810000 à 840000 sont déjà installées) : 1. `20261123850000_parcours_inscrits_classe_adhesion.sql` ; 2. `20261123900000_socle_programme.sql` ; 3. `20261123910000_ma_progression_sur_socle.sql`. Deux fichiers sont à l'ordre près liés : 910000 appelle la fonction posée par 900000.

**Tests existants modifiés, avec la raison**
- `supabase/tests/scenarios_ma_progression.sql` (de `main`) : la fixture attendait la date limite 18 de l'étape 2 (ancien × 1,3) ; le socle pose 19 (tableau 1 bis) ; l'étape se lit dans le fait propre à chaque élève (l'élève membre sans décision reçoit son étape 1 comme à l'installation, `private.rattacher_classes_et_eleves()`) ; `e1`, enfant de 6 à 9 ans qui lit pour lui-même, ne reçoit plus ni rythme ni date (c'est le défaut corrigé) : l'assertion « rythme non nul » devient « rythme nul », et un contrôle neuf prouve que son tuteur, lui, les reçoit ; `e2` est à l'étape 1 de son propre fait et non à l'étape 4 de la classe.
- `supabase/tests/scenarios_parcours_inscrits.sql` : ajout du cas e8 (membre de A, inscription vers B), qui n'a de sens qu'avec la 850000.
- `scenarios_cahier_c2_programme_donnees`, `scenarios_mes_classes_details`, `scenarios_rythme_lecture`, `scenarios_suivi_eleve_pedagogique` : adaptés par le lot (18 → 19 semaines, étape d'une version archivée rendue, installation rejouée, décision sur brouillon sans effet) ; inchangés depuis la fiche du 12/11.
- `test/features/admin_pedagogie_programmes/contenu_niveau_test.dart` : la date limite d'une étape se saisit (8 `ChoixNombre` au lieu de 4), le test de `dateLimiteDeduite` (× 1,3) disparaît avec la fonction.
- `test/features/fiche_groupe/etape_eleve_test.dart` : ajout seulement (attente de l'entretien de lecture).
- `test/features/suivi_foyer/carte_suivi_pedagogique_test.dart` (de `main`) : remis à la version de `main`, sans différence (le lot l'avait modifié le 12/11 ; la règle de repli de `eleveVoitDates` rend le test d'origine valable).

**Vérifications du 13/11, sur la tête de cette section** : voir « Ce qui est fait et testé » ci-dessous.

**Dettes nommées (rien d'ici n'est fait)**
- `ma_progression` garde les clés d'avant (`franchie`, `etapes_du_cycle`) pour l'écran en ligne ; à retirer avec `suivi_pedagogique_eleve` au lot 10. `ma_progression` appelle encore `suivi_pedagogique_eleve` pour sa garde.
- Fenêtre du remplaçant de 24 heures écrite en dur (« 1 day ») dans la garde partagée `private.cahier_c1_peut_lire_classe`, et séance annulée qui ouvre encore la lecture : à traiter dans un lot suivant (non touché, comme demandé).
- Texte « Proposition à valider par la direction » de l'écran Programmes (brouillon) : « une proposition, pas une règle ».
- L'ancien état vide visible du lot (« L'étape apparaîtra dès l'entrée dans une classe ») est retiré : sans étape, sans sourates et sans jalon, le bloc n'est pas posé, comme dans MA-PROGRESSION-ECRAN. À valider par l'architecte.
- La comparaison de `v_parcours_onboarding` avec la définition de production n'est pas faite (pas de lecture en production) : la 850000 remplace la vue installée par 810000 ; lire `pg_get_viewdef` avant d'installer.

## Comment un enfant accède à l'application (relevé dans le code)

Un enfant a **son propre compte** (`profiles.id` = compte d'authentification, rôle `student`). Il n'utilise jamais le jeton du tuteur : son appareil s'appaire par un code créé par le tuteur (`ServiceAppairage.creerCode`, RPC `creer_code_appairage`), puis la fonction `supabase/functions/session-enfant/index.ts` échange le code (`consommer_code_appairage`) ou le jeton de l'appareil (`profil_du_jeton_appareil`) contre une session de l'enfant (lien magique sur son courriel technique, `token_hash`). Sur un appareil partagé, choisir un profil local (`lib/core/appairage/profils_locaux.dart`) rouvre la session de cet enfant avec son jeton d'appareil (`ServiceEnfant.ouvrirSession`). Il voit donc l'espace de l'élève (`Routes.eleveSuivi`, « Ma classe », `SuiviElevePage`, Interface guidée de 6 à 9 ans), où `CarteSuiviPedagogique` lit pour lui-même. Le cas « enfant dans l'espace de l'élève avec le jeton du tuteur » n'existe pas dans le code ; il est tout de même couvert à l'écran par `eleve_voit_dates` (test dédié).

## Ce qui est fait et testé (13/11/2026, poste de l'agent, après la fusion avec `main`)

Statut : **présent dans le code, testé localement, NON installé, NON prouvé en production** (sur Postgres 16 ; la CI tourne en 17).

- Postgres 16 nu : `stub_auth.sql`, puis les 439 migrations (810000 à 910000 comprises), vert ; **278 scénarios sur 278 verts, 0 rouge** (`tool/rejouer_scenarios.sh`, une base neuve par scénario). `scenarios_socle_programme.sql` : 63 contrôles ; `scenarios_ma_progression.sql` : 35 ; `scenarios_parcours_inscrits.sql` : 13.
- Installation simulée du 12/11 (base reproduisant la production : brouillon `bases-lecture`, une classe sans étape, deux élèves débutants) : rejouée par `scenarios_socle_programme.sql` (étape 1 datée du jour de l'installation pour les élèves déjà présents).
- Flutter 3.47.9 : `dart run slang` et `dart run build_runner build --delete-conflicting-outputs` sans diff après régénération ; `dart analyze --fatal-infos` : aucun problème ; `flutter test` complet : **20 721 verts, 8 168 sautés, 0 échec** ; `dart run tool/verifier_jetons.dart` : 1 504 fichiers, aucune violation ; `dart run tool/verifier_branchement.dart` : 2 fichiers non atteints, tous tolérés avec une issue datée, aucun nouveau.
- Captures refaites le 13/11 (l'écran a changé : un seul appel, sourates, chemin) : `docs/current/captures/E2E/socle-programme/` (élève adulte, enfant de 6 à 9 ans, tuteur ; 390 et 1440 ; clair et sombre), vrai routeur, données simulées ; celles de la feuille d'une étape à la direction n'ont pas changé.
- Non testé : l'installation sur la base de production ou de staging ; Postgres 17 ; l'arabe des deux libellés ; la préproduction Vercel.

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
