# Reprise du programme pédagogique : ce qui est fait, ce qui ne l'est pas

**À lire par tout agent avant de toucher au programme, à la pédagogie, à « Apprendre », au suivi d'un élève, au cahier ou au point de fin de séance.**

Demande du directeur (15/11/2026) : « Tu vas prendre ce programme complet, comme il est, ce que tu penses être fait et ce qui ne l'est pas. Tu le consignes […] pour que jeudi prochain, après la réinitialisation des tokens, un agent reprenne le boulot que tu n'as pas fait. Qu'il ait automatiquement tous les contextes. […] Tu dois être sûr que ton diagnostic est vrai, que tu ne déclares pas non créé ce qui est déjà créé. »

Le directeur, le même jour : « sur l'application, c'est juste un texte comme un simple PDF que je vois. Beaucoup de choses ne sont pas livrées, et presque tout ce que tu as livré n'était pas conforme. Tu as même créé des maquettes, mais ces maquettes-là, elles sont tellement différentes de ce que tu as rendu. »

**Rien n'est en cours (15/11/2026, 03:40 UTC).** Sur ordre du directeur (« arrête tout »), la session PROGRAMME-REEL a été interrompue puis archivée sans avoir rien poussé. Aucune tâche planifiée ne relance ce chantier. **Ne relance rien sans un ordre du directeur.**

## 1. Comment ce diagnostic a été établi

Le 15/11/2026, en lecture seule, l'architecte pédagogique a vérifié trois choses :
- **sur `main`** : le journal des fusions et la présence des fichiers et des fonctions dans `lib/` et `supabase/migrations/` ;
- **sur les branches** : chaque branche `claude/*` du domaine, avec son nombre de commits absents de `main` (`git rev-list --count origin/main..<branche>`) ;
- **en production** (projet `gggmtelinlpseweouyav`) : la présence des tables et des fonctions et leurs nombres de lignes.

Ce qui n'a **pas** été vérifié :
- la conformité écran par écran avec les maquettes, au-delà du constat global du directeur ;
- les preuves en production des lots livrés, qui reviennent au directeur et qu'il n'a pas faites ;
- le contenu détaillé de la branche `claude/point-de-seance`, relue seulement par ses messages de commit et ses statistiques.

**Règle pour l'agent qui reprend** : avant d'écrire une ligne d'un lot, refais pour ce lot les trois vérifications ci-dessus. Cherche dans le code ce qui existe déjà : la consigne 5 du directeur dit « ne rien recréer ». Le constat du directeur « tout ça a été codé mais peut-être pas livré » est vrai pour le lot 6 et pour des morceaux anciens (section 4).

## 2. La mission (la référence complète est dans `docs/current/pedagogie/`)

Rôle : architecte pédagogique, sur délégation du directeur du 12/11/2026. Il arbitre tout ce qui reste ouvert sans poser de question ; le directeur installe les migrations, et l'architecte fait le reste, fusions comprises.

Lire dans cet ordre : `pedagogie/LIRE-D-ABORD.md`, `CHARTE-ACADEMIE.md`, `REGLAGES.md` (la seule table des valeurs), `SCENARIOS-ELEVES.md`, `MOTEUR-DE-SUIVI.md` (36 règles), `EVALUATIONS.md`, `ARBITRAGES.md`, `CONTENUS-ATTENDUS.md`, `PLAN-DE-CONSTRUCTION.md` (les 14 lots, leur but, ce qui se voit, ce qui est réutilisé, créé ou retiré, et leur preuve), `ANGLES-MORTS.md`, `STRATEGIE-FORMATION-DES-CLASSES.md`, `CONTENU-PRIERE-ET-ABLUTIONS.md`, `PROGRAMME-SEANCE-PAR-SEANCE.md` (312 séances). Ensuite, les compétences `programme-rewayah` et `mots-rewayah`.

**Décisions du directeur du 12/11** :
1. La classe n'attend jamais un absent : il rattrape seul, avec la voix enregistrée du directeur.
2. Le système reconnaît seul chaque situation, sans IA.
3. L'architecture est fixe ; les valeurs sont réglables par la direction.
4. L'interdiction de nouveaux écrans ne s'applique pas à ce projet.
5. Dans la page du programme, l'élève voit son niveau, les objectifs et les dates importantes ; jamais une autre tranche d'âge, jamais un autre élève.
6. Le directeur fait les migrations ; l'architecte fait le reste, fusions comprises.
7. « Apprendre » a trois onglets :
   - la Bibliothèque : documents de l'académie en haut, autres en bas ; grille ou liste ; filtre par type ; le Coran est un document ;
   - le Programme ;
   - « Mon livret ».

   Il faut aussi un lecteur performant pour le texte, l'audio et la vidéo.
8. Un hub et des raccourcis, jamais de doublons.
9. Pas de vente : seulement la place du second rayon.

**Décisions du directeur du 13/11** :
1. Les règles élémentaires du tajwid avant ou pendant les 17 sourates ; 9 sont retenues.
2. Les livres seront rédigés par des agents après la validation du programme.
3. Prière et ablutions : la référence est ce qui est enseigné en Arabie saoudite.
4. « Le cahier me fatigue » : il est remplacé par le point de fin de séance.
5. La gamification : le chemin.
6. Jamais « école », toujours « l'académie ».
7. Le programme est découpé au jour près (312 séances).

Pour chaque lot, l'arabe de contenu est en UthmanicHafs (`AppFontFamily.arabeMushaf`), avec une capture qui le prouve.

## 3. État des 14 lots (vérifié le 15/11/2026)

Légende :
- **Livré** : fusionné dans `main` et migration installée en production.
- **Branche** : du code existe, mais hors de `main`.
- **Rien** : aucun code trouvé ni sur `main` ni sur une branche.

« Prouvé par le directeur » n'est vrai pour **aucun** lot.

| # | Lot | État | Preuves | Ce qui manque |
|---|---|---|---|---|
| 1 | SOCLE-PROGRAMME | **Livré** | PR #454 ; migrations `20261123900000_socle_programme`, `20261123905000_ma_progression_sur_socle` (et `20261123810000_parcours_inscrits_affectee`). En production : `programme_versions` a 1 version **publiée le 14/11/2026**, `programme_niveaux` 4, `programme_cycles` 1, `eleve_etape_en_cours` 7 lignes ; `etape_eleve_lecture` et `ma_progression` sont installées. | La preuve du directeur : même étape et même date limite vues comme direction, enseignant et tuteur. Les « parties du programme » (leçon ou page, sourate) prévues par le lot ne sont pas vérifiées : à contrôler dans `private.contenu_bases`. |
| 2 | CALENDRIER-ET-PAUSES | **Livré** (code et tables) | PR #459 ; `20261123910000_calendrier_pauses`, `…911000_…evenement`, `20261124100000_pause_proposee`. En production, les tables `calendrier_ecole`, `pauses_eleve` et `seances_fermees` existent, **toutes vides**. | Aucune fermeture ni pause saisie. La preuve du directeur (fermeture de l'Aïd : les dates reculent). |
| 3 | BIBLIOTHEQUE-UNE | **Livré** | PR #453 ; `20261123920000_bibliotheque_une_types`, `…921000_bibliotheque_une`. En production : la colonne `library_resource.rayon` existe, avec **2 documents**. Le dépôt simple a suivi (PR #471, `LOT-DEPOT-SIMPLE.md`). | Les documents eux-mêmes (`CONTENUS-ATTENDUS.md`). La preuve du directeur. |
| 4 | LECTEUR | **Partiel, non conforme** | Il existe des rendus séparés (`features/tc_catalogue`, `lib/core/coran/vue_lecteur.dart`, `features/tc_mushaf`). Aucun lecteur unique, aucune reprise audio ou vidéo. | Tout le lot tel que décrit dans le plan. |
| 5 | PLAN-DE-CLASSE | **Partiel** | Seule la partie A est livrée (PR #473, `20261125700000_plan_de_classe_a_gestes_direction` ; installées : `donner_niveau_classe`, `dater_entree_etape`, `apercu_date_limite`, `niveau_classe_direction`, `decider_placement_depuis`), c'est-à-dire le niveau d'une classe, l'entrée datée et le placement. | **Le cœur du lot n'existe nulle part** : ni tables du découpage séance par séance (312 lignes, depuis `PROGRAMME-SEANCE-PAR-SEANCE.md`), ni plan daté par classe calculé par le serveur, ni glissement, ni écart au plan (règle 36), ni lecture par rôle. C'est la raison principale de « l'onglet Programme est un texte ». |
| 6 | POINT-DE-SEANCE | **Branche** | `claude/point-de-seance`, 3 commits hors de `main` (13/11), 85 fichiers, environ 8 700 lignes : « point de fin de séance, historique des séances, scénarios, tests, captures ». Son dernier commit dit : « réglage tient_lieu_de_cahier non construit, suite complète non prouvée ». Jamais de PR fusionnée. | Fusionner `main` dans la branche (sans rebase), la relire contre le lot 6 et contre la maquette (section 5), construire le réglage manquant, prouver la suite complète, ouvrir la PR. **Ne pas réécrire ce lot.** |
| 7 | ESPACE-APPRENDRE | **Livré, non conforme** | PR #468 (et `claude/apprendre-correctifs`, fusionnée) : `lib/features/apprendre/` (`espace_apprendre_page.dart`, `onglet_bibliotheque.dart`, `onglet_programme.dart` de 301 lignes, `onglet_livret.dart`). | L'onglet Programme affiche du texte et non la maquette (section 5). « Mon livret » est vide tant que le lot 12 n'est pas là. |
| 8 | SUIVI-UNIQUE | **Partiel** | Morceaux réutilisables livrés : `20261122900000_sourates_validees`, `20261123820000_corriger_sourate` (installée en production : `retirer_sourate_validee`, `sourates_eleve`), `20261123830000_ma_progression` (installée : `ma_progression`) ; écrans `features/suivi_eleve`, `features/suivi_famille`. | La fiche de suivi unique, « Stable » calculé par le serveur, le travail écrit dans `learning_assignment` (0 ligne en production), les raccourcis, le retrait des anciennes échelles. |
| 9 | RETRAIT-CAHIER | **Rien** (par construction) | Ce lot attend que le lot 6 soit prouvé en production. | Tout. |
| 10 | CHEMIN | **Rien** | Aucun code. La maquette existe (section 5). | Tout : le chemin, les collections (28 lettres, 9 règles, 17 sourates), la régularité, les célébrations, une seule lecture serveur, et les interdits testés. |
| 11 | MOTEUR-1 | **Rien** | Aucune table `suivi_regles`, `suivi_declenchements` ni `cours_rattrape`. La charte `MOTEUR-DE-SUIVI.md` est fusionnée (branche `charte-moteur`). | Tout. Attention : sa migration réécrit la contrainte `notifications_evenement_check`. Le lot ANNONCES-SIMPLES (PR #495) la réécrit aussi : partir de la version en production. |
| 12 | EVALUATIONS-ET-LIVRET | **Rien** (au sens du lot) | Les tables `evaluations` et `evaluation_publications` existent (0 évaluation en production). `onglet_livret.dart` est vide. La charte `EVALUATIONS.md` est fusionnée. | Les trois résultats, la réévaluation, les attestations et leur page de vérification, le livret rempli. |
| 13 | MOTEUR-2 | **Rien** | | Tout. |
| 14 | NETTOYAGE | **Rien** (au sens du lot) | Les branches `nettoyage-*` du 11/11 ont été fusionnées, mais c'est un autre nettoyage, antérieur à la charte. | Tout, en dernier, avec l'accord du directeur sur la liste des suppressions. |

Livrés à côté des lots, dans le même chantier :
- la prière, avec horloge et lieu et sans saisie (`20261123930000_priere_serveur`, `20261123940000_horloge_lieu`, `20261123943000_lieux`, `20261124500000_priere_zero_saisie`, et `LOT-PRIERE-1/2.md`) ;
- le suivi d'attente (PR #455, `20261123960000_suivi_attente` et suivantes) ;
- le dépôt simple de la Bibliothèque (PR #471).

## 4. Branches non fusionnées du domaine, à relire avant d'écrire

| Branche | Hors de `main` | Contenu | Que faire |
|---|---|---|---|
| `claude/point-de-seance` | 3 commits, 13/11 | Le lot 6 presque entier | Le reprendre (lot 6 ci-dessus) |
| `claude/suivi-eleve` | 10 commits, 07/11 | Écran de suivi de l'élève, robot vert, 75 vérifications, 2 049 lignes | Le relire pour le lot 8 : ce qui est conforme à la charte se reprend, le reste s'écarte avec sa raison |
| `claude/ma-progression` | 3 commits, 08/11 | Lecture serveur de la progression et « réglage par étape » | Le plan écarte la table `programme_etape_reglages` (les heures de révision dépendent de l'âge, pas de l'étape). Cette table **existe pourtant en production**, vide. Ne pas la remplir ; à retirer au lot 14 |
| `claude/ma-progression-fiche` | 4 commits, 08/11 | Une fiche de décisions (documentation) | Lire seulement |
| `claude/proposition-progression-sourates` | 1 commit, 11/11 | Proposition « progression par sourate » (documentation) | Lire seulement |

Les branches `claude/socle-programme`, `calendrier-pauses`, `bibliotheque-une`, `espace-apprendre`, `plan-de-classe`, `suivi-attente`, `charte-*`, `corriger-sourate-*`, `ma-progression-main`, `ma-progression-ecran-travail`, `progression-adulte*` et `sourates-*` n'ont plus rien hors de `main` : leur contenu est déjà livré. Les très vieilles branches d'octobre (`bibliotheque`, `biblio-lecture`, `suivi-famille`, `ped-progression-spec`, `ar-suivi-famille`, `nettoyage-verif`), qui ont plus de 1 500 commits de retard, sont caduques.

## 5. Les maquettes, critère d'acceptation visuel

`docs/current/pedagogie/maquettes/` :
- `programme-des-bases.html` : le programme des bases (4 étapes, durées par âge, les 9 règles, l'examen). Le directeur l'a lu : « c'est pas mal ».
- `maquette-programme-vivant-v2.html` : l'onglet Programme vivant. On y trouve la carte du chemin (arches, Bab, porte de lumière), la planche de tuiles, le plan séance par séance et le point de fin de séance de l'enseignant, avec l'arabe de contenu en police du Coran. **Le directeur ne l'a pas encore validée.**

Constat du 15/11 : aucun lot livré ne l'a prise comme critère. Pour les lots 5, 6, 7 et 10, la règle de sortie est donc :
- une capture de la maquette à côté d'une capture de l'application, à 390 et à 1440 ;
- un tableau des écarts ;
- zéro écart non justifié.

Un écart reste à trancher. La charte visuelle réserve le style Silhouette aux publications et demande un violet rare dans l'application ; la maquette met Bab et un aplat violet dans l'onglet Programme. La consigne 19 s'applique : le directeur ne tranche pas l'UX, c'est la compétence `design-taste-frontend` qui arbitre, avec la raison écrite.

## 6. Ordre de reprise conseillé (seulement sur ordre du directeur)

1. **Lot 5, le cœur** : le découpage des 312 séances en données, le plan daté de chaque classe, l'onglet Programme dessiné comme la maquette (tuiles, plan séance par séance).
2. **Lot 6** : reprendre `claude/point-de-seance` (section 4).
3. **Lot 8** : la fiche de suivi unique, en relisant `claude/suivi-eleve`.
4. **Lot 10** : le chemin, depuis la maquette.
5. **Lot 4** : le lecteur unique.
6. **Lots 11 et 12**, puis 9, 13 et 14.

## 7. Règles de livraison (rappel, toutes en vigueur)

- Une PR par lot, en brouillon, puis fusion par le pilote quand la CI est verte.
- Captures R3 sous `docs/current/captures/E2E/<lot>/`.
- Migrations additives, rejouables, sans `DROP`, `DELETE` ni `TRUNCATE` (sauf pour réécrire une contrainte CHECK), sans `BEGIN` ni `COMMIT`. Le directeur les colle à partir d'une page générée par `tool/page_migrations/generer.py`.
- Tests jamais affaiblis ni sautés. Pas de `.github/`. Jamais de force push.
- Protection des mineurs : aucune notification, aucun courriel, aucun push à un enfant ; ni date ni échéance de 6 à 9 ans ; jamais d'argent devant un enfant.
- Une session enfant ne peut pas lire la production (l'autorisation d'`execute_sql` n'y est accordée par personne). Elle écrit ses requêtes dans la PR, sous « Requêtes pour le pilote », et le pilote les exécute.
- Chaque lot commencé a sa ligne le jour même dans `docs/current/REGISTRE-LOTS.md`.
- « Fait » veut dire « prouvé par le directeur en production ».
- Ce fichier se met à jour à chaque lot livré : on change la ligne du lot dans la section 3, avec la PR et la preuve.
