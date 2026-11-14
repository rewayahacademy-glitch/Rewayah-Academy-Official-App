# Registre des lots (créé le 11/11/2026)

Ordre urgent du directeur du 11/11, relayé par le garde-cap puis par le pilote : « ne plus perdre un seul lot ».
Ce registre recense tout lot qui existe hors de `main` : une branche distante, une PR ouverte, une dette nommée.
Chaque ligne a **un seul statut et sa preuve** :

- **LIVRÉ (#N)** ;
- **REMPLACÉ par #N** (ou par le commit de `main` qui l'a remplacé) ;
- **ABANDONNÉ** (avec la décision datée) ;
- **À LIVRER** (avec l'agent et l'ordre) ;
- **non vérifié**, quand aucune preuve n'a été trouvée. Une ligne sans preuve n'a jamais de statut deviné.

Relevé fait par E le 11/11/2026 vers 12 h UTC, sur `main` `b86dbc9d9`, avec `tool/registre_lots.sh` lancé sur un vrai clone (historique complet).

## D'abord : ce qui est faux, bloqué ou non prouvé

- **Tri du 12/11 (agent B, git seul, lecture seule ; verdicts du garde-cap par délégation du directeur)** : les 102 branches « non vérifié » sont tranchées. 53 DÉJÀ DANS MAIN ou REMPLACÉ ; 43 ABANDONNÉ (les branches restent comme archive, rien n'est supprimé) ; 4 À LIVRER (TESTS-EDGE pour 2 lignes, TESTS-ADAPTATEURS, EXPORT-COMPTABLE, priorité basse) ; 1 ARCHIVE À RELIRE (Fable) ; 1 À FAIRE (APERCUS-STAGING) ; 0 À RELEVER. Le wagon F86-GARDES-POSITIVES est annulé (gardes déjà dans main) et 20261123840000 libéré. Les preuves de sécurité sont lues sur une base rejouée de main 3e6fe21c7, pas sur la production. Nouveaux noms au registre : CI-SCENARIOS (pilote), EXPORT-COMPTABLE, EDGE-TESTS-CONTRAT, TESTS-ADAPTATEURS, APERCUS-STAGING ; completer_kyc_document reste SECURITY DEFINER, par écrit (garde-cap, 12/11). `rech_d4_rechercher_reference_finance` n'est pas une branche (aucune tête distante) : sa ligne reste « non vérifié ».
- ~~**112 lignes sur 241 sont « non vérifié »** (117 au premier relevé ; 5 PR de la file ont reçu leur agent du pilote le 11/11 à 12:02). Leur contenu manque à `main` au 11/11, et aucune décision ni aucun ordre écrit ne dit quoi en faire. Ce sont autant de lots peut-être perdus. Pour chacune, le pilote décide, ou le directeur quand il s'agit d'une décision de produit.~~ Dépassé par le tri du 12/11 (ligne précédente) : il ne reste qu'une ligne « non vérifié », qui n'est pas une branche.
- **Trois PR ouvertes attendent une décision du directeur depuis le 08/11, sans réponse écrite trouvée** (`docs/orchestration/TRI-PR-AVANT-25-10.md`) :
  - **#26** : les aperçus de PR construisent encore l'application avec les secrets Supabase de la **production**. `.github/workflows/flutter-deploy.yml`, lignes 150-151, au 11/11. La PR 26 les isolait sur STAGING. Le risque est probable, non prouvé : je ne peux pas lire la valeur des secrets.
  - **#42** : 18 compétences tierces sous `.claude/skills/`.
  - ~~#22~~ : **fermée** le 11/11 sur décision du directeur (« oui ferme la 22 ») ; remplacée par #365, #338, SEC-AUDIT, KYC-AUDIT et SEC-GARDE-4.
- **Les verdicts « remplacé » et « abandonné » viennent pour la plupart d'un relais.** C'est l'annexe de `ALERTE-LOTS-NON-LIVRES-2026-11-08.md`, un relevé de E du 08/11 sur `main` `13fc04c09`. Ce qui est mesuré le 11/11, c'est seulement que le contenu de ces branches est toujours absent de `main`. Un « REMPLACÉ par <commit> » renvoie au commit de `main` qui a réécrit leurs fichiers ; il ne prouve pas, ligne par ligne, que rien d'utile n'a été perdu.
- **Écart avec la mesure du garde-cap.**
  - Le garde-cap comptait 162 branches sans PR ; j'en compte 166.
  - Les branches poussées depuis expliquent au moins une partie de l'écart, dont `claude/profils-p1-travail`, poussée par moi aujourd'hui.
  - Les deux autres chiffres sont retrouvés à l'identique : 206 branches livrées, 75 PR non fusionnées.
- **PR fermées sans fusion.** Parmi toutes les PR fermées sans fusion, 62 l'ont été le 08/11 (date de fermeture lue sur GitHub). Celles d'avant le 25/10 suivent les propositions de `TRI-PR-AVANT-25-10.md`. Pour les autres, je n'ai trouvé aucune raison écrite : leur ligne le dit.

- **PARTAGE-ET-NOM-ARABE (14/11/2026)** : branche `claude/partage-et-nom-arabe`, PR brouillon. Statut : **À LIVRER** (aucune preuve en production). (1) Le partage de la carte (« Aidez une personne à apprendre la parole d'Allah ») donne le lien du site public `https://rewayahacademy.com/<langue>/` dans la langue de la carte, jamais `app.rewayahacademy.com` ; l'image part avec le lien dans le texte. (2) Le nom arabe « أكاديمية الرواية » (M-27) remplace « أكاديمية رواية » dans `ar.i18n.json`, le modèle de courriel arabe et le cadre religieux arabe (migration `20261125710000_cadre_nom_arabe.sql`, correction en place, même version, sans mot d'effacement).
- **REVENUS-DUREE-PAYEE (14/11/2026)** : branche `claude/revenus-duree-payee`, PR brouillon. Statut : **À LIVRER** (aucune preuve en production). L'écran des revenus montrait les minutes connectées ; il dira la durée payée du serveur (`mes_durees_payees_enseignant`, migration `20261125300000`). **Dépend de PAIE-FENETRE** (`claude/paie-fenetre`, migrations `20261124800000` et `20261124900000`, non fusionnée au 14/11) : à fusionner et installer avant elle.

## Chantier pédagogique (architecte pédagogique, relevé du 13/11/2026 à 04 h UTC)

Consigne du directeur du 13/11 : « Attention à ne pas perdre notre travail depuis le début, car on a rien mis en prod. » **Rien de ce chantier n'est dans `main` ni installé en production.** Tout est poussé sur les branches ci-dessous. Avant d'écrire un lot, chercher ici s'il existe déjà.

| Lot | Branche (tête au relevé) | Migrations | Statut et preuve |
|---|---|---|---|
| Paie et présence : minutes perdues à chaque reconnexion (`private.presence_temps_reel`) | `claude/paie-minutes-reconnexion` | 20261124800000 | À LIVRER (13/11). Testé localement seulement : 440 migrations rejouées sur une base neuve, 281 scénarios SQL verts, scénario `scenarios_paie_minutes_reconnexion.sql` rouge avec l'ancienne définition. Non relu par un tiers, pas sur staging, pas en production. Aucun montant déjà écrit n'est recalculé. Défaut distinct signalé, non corrigé : séance en cours, la borne de fin vaut la fin prévue plus la grâce |
| Paie : fenêtre payable (règle du directeur du 13/11 : classe d'adultes 1 h 30, classe d'enfants 1 heure, rien avant ni après) et borne de fin d'une séance sans fin financière | `claude/paie-fenetre` (sur `claude/paie-minutes-reconnexion`) | 20261124900000 | À LIVRER (13/11). Testé localement seulement : scénario `scenarios_paie_fenetre.sql`, 10 mutations rouges ; détail et réserves dans le rapport au pilote. Non relu par un tiers, pas sur staging, pas en production. Aucun montant déjà écrit n'est recalculé. Document enseignant : `docs/current/paie/COMPTAGE-DES-MINUTES.md` |
| Charte de l'académie, programme séance par séance, tajwid des bases, prière et ablutions, point de fin de séance, chemin, police de l'arabe | `claude/charte-ecole` | aucune | LIVRÉ par la PR de la charte du 13/11. Auditée le 12/11 (33 corrections) puis le 13/11 (14 corrections). À relire par le directeur : objectifs, découpage hors étape 1 des 6-9 ans, textes de la prière, le ya, le point de fin de séance (D4) |
| Lot 1, socle du programme | `claude/socle-programme` (40a3d563) | 20261123850000, 900000, 905000 | À LIVRER. Trois revues indépendantes, aucun bloquant ; correction en cours : la migration ne publie plus le programme |
| Lot 2, calendrier et pauses | `claude/calendrier-pauses` (6917fb62) | 20261123910000, 911000 | À LIVRER. Non relu par un tiers |
| Lot 3, bibliothèque | `claude/bibliotheque-une` (3d601f0f) | 20261123920000, 921000 | À LIVRER. Revue indépendante : un bloquant (tranche d'âge contournée par l'onglet de la classe), en correction |
| Lot 5, espace Apprendre à trois onglets | `claude/espace-apprendre` (02f680f4) | aucune | À LIVRER. Non relu par un tiers |
| Lot 5 partie A, PLAN-DE-CLASSE (gestes de la direction : étape d'une classe ouverte, jour de début d'un élève, élèves sans étape et rattachement, impasse du brouillon) | `claude/plan-de-classe` (sur `claude/socle-programme`) | 20261125700000 (après 850000, 900000, 905000) | À LIVRER. Testé localement (scénario SQL 114 vérifications (vert avec le lot 2 avant et après), 52 mutations rouges ; 23 tests d'écran) ; non installé, non prouvé en production ; fiche `pedagogie/lots/LOT-5-PLAN-DE-CLASSE-A.md` |
| Suivi de l'attente | `claude/suivi-attente` (3ff5e1c4) | 20261123960000, 961000 | À LIVRER. Revue indépendante : deux bloquants (courriel vers un mineur, fiche de l'enseignant visible après un départ), en correction |
| Prière, heures et pause prévue | `claude/priere-serveur` (0f7116ef) | 20261123930000 | À LIVRER. Revue indépendante : aucun bloquant, corrections en cours |
| Horloge de La Mecque et ville | `claude/horloge-lieu` (tête du 13/11, voir le rapport du lot) | 20261123940000 à 949999 (partie A : 940000, 940100, 940300 ; partie B : 940200 villes, 942100 à 942200 données des villes, 943000 lieux, 943100 aperçu, 943200 correctifs de la revue) | À LIVRER. Corrections de la partie A faites ; partie B codée ; suite Flutter complète, 281 scénarios SQL et vérifications au vert sur la tête ; à faire par le directeur : installer l'application à jour, puis les migrations, et ne modifier aucun horaire entre les deux |
| Pause en salle (session de la salle) | `claude/zealous-tesla-ewstzw` (bc38bf4d), PR #449 | 20261124100000 à 400000 | À LIVRER. À relire avec la prière |
| Maquettes | `docs/current/pedagogie/maquettes/` | aucune | LIVRÉ (#450), mises à jour avec la charte |
| PLAN-DE-CLASSE, POINT-DE-SEANCE, CHEMIN, lecteur, moteur de suivi, évaluations et livret, classes vitrines FC-1 à FC-4 | aucune | aucune | Spécifiés dans la charte, **non commencés** : détail lot par lot dans la section « Lots de la charte pédagogique » plus bas |

Ordre de livraison prévu : la charte ; le lot 1 ; puis prière, bibliothèque, suivi de l'attente, calendrier, espace Apprendre, horloge, chacun après sa revue indépendante et l'installation de ses migrations par le directeur.

## Comment refaire le relevé

```
tool/registre_lots.sh            # résumé, puis une ligne par branche hors de main
tool/registre_lots.sh --tsv      # lignes seules, pour un tableur
tool/registre_lots.sh --sans-fetch
```

Git seul, lecture seule. `git fetch` met à jour les références du clone ; `git ls-remote origin 'refs/pull/*/head'` donne la PR à la tête de chaque branche. Une PR compte comme fusionnée si `main` porte « (#N) » ou « Merge pull request #N » dans son journal. Aucun appel à l'API GitHub, aucune écriture distante.

Pour chaque ligne, le contenu présent ou absent de `main` au 11/11 est mesuré comme suit. Le diff de la branche depuis sa base commune avec `main` est réappliqué à l'envers sur `main` :

```
git diff --binary $(git merge-base origin/main origin/B) origin/B > b.patch
git apply --check -R b.patch
```

S'il passe sans conflit, le contenu est dans `main`. Un diff nul ne contient rien hors de `main`.

## Règle de méthode (pilote et garde-cap, 11/11/2026)

1. **Tout lot commencé a sa branche `claude/<lot>-travail` et sa ligne dans ce registre, le jour même.** La ligne porte l'agent et l'ordre (À LIVRER).
2. **Toute PR fermée sans fusion porte, en dernier commentaire, la raison et son remplaçant** (PR ou commit de `main`). Sans ce commentaire, la ligne reste « non vérifié ».
3. **Le pilote lance `tool/registre_lots.sh` avant chaque série de fusions.** Il met ce registre à jour : une ligne livrée passe à LIVRÉ (#N), une branche nouvelle reçoit sa ligne.
4. **Le garde-cap contrôle** que le résumé du script et ce registre se correspondent.
5. Une ligne n'est jamais écrite « fait », « livré », « à faire » ou « non branché » sans sa preuve du jour : un commit dans `main`, un fichier:ligne ou une lecture en production. Sans preuve, on écrit « non vérifié ». Un relais d'un autre agent se signale comme tel (consigne du directeur du 11/11, `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`, V9).

## Lots de construction du 12-13/11

| Lot | Branche | Statut | Preuve |
| :-- | :-- | :-- | :-- |
| SUIVI-ATTENTE (suivi de l'attente de la classe, « comme une livraison ») | `claude/suivi-attente` | **À LIVRER** (agent de construction, ordre de l'architecte pédagogique du 12/11 ; aucune PR : l'architecte l'ouvre et fusionne) | Fiche `docs/current/pedagogie/lots/LOT-SUIVI-ATTENTE.md`, §6 ; migrations `20261123960000`, `20261123961000` (mot d'effacement, collée par le directeur), `20261123962000` ; scénario `supabase/tests/scenarios_suivi_attente.sql` ; captures `docs/current/captures/E2E/suivi-attente/`. **Non prouvé** : production, que seul le directeur prouve ; `ci.yml` ne rejoue pas encore le scénario (zone interdite au lot). |

## Train du 11/11 (#435, `main` `f30527be4`, fusionné à 22:34 UTC)

Ordre du directeur du 11/11 (« tout ce qui est codé part en production d'un coup ») relayé par le
garde-cap et le pilote ; train construit par E sur `claude/train-1111`, partie de `main` `b86dbc9d9`,
fusions `--no-ff` dans l'ordre du pilote, puis PR #435 fusionnée par le pilote. Chaque lot ci-dessous
est **LIVRÉ (#435)** ; les statuts « À LIVRER » des tables plus bas, pour ces lots, sont dépassés.
**Non prouvé** : la mise en production, que seul le directeur prouve (règle du 24/10) ; les migrations
du train restent à installer par le pilote. `20261123700100` (RESEAU-PREUVE) est dans `main`, non
installé, sous les conditions (a)(b)(c) de `docs/orchestration/garde-cap/RESERVATIONS-MIGRATIONS.md`.
GARDE-ECHEANCES (wagon 26) est livré : `verifier_branchement` échoue désormais sur une échéance dépassée.

| # | Lot | Tête fusionnée | Commit de fusion | Conflit et résolution |
| --: | :-- | :-- | :-- | :-- |
| 1 | REGISTRE (1) | `f659f3744` | `e862a6121` |  |
| 2 | REGISTRE (2) | `ef913d586` | `32ca08fbe` |  |
| 3 | PR 430 SOMBRE-SANS-ÉCLAIR | `90a76a3d9` | `298b86bc4` |  |
| 4 | PR 426 bande sous la barre | `7bd35718c` | `9affde7d0` |  |
| 5 | PR 429 clé morte `absenceDetectee` | `595604ca7` | `8b7b32ed1` |  |
| 6 | PR 431 geste de la carte Horaire | `fdf001851` | `0eb510aca` |  |
| 7 | PR 432 titulaire sans appareil | `5da0f52f0` | `afda34a6e` | `strings*.g.dart` régénérés par slang |
| 8 | BANDE-SUITE (remplace la 426) | `bfcb63483` | `02c2f5b44` |  |
| 9 | PR 433 goutte d'huile (+ texte seul de H) | `c27d77927` | `f68c8ccf1` | `accueil_famille_page.dart` : `?autreAppareil` passé à `goutte()` par un paramètre nommé, après `?lienEspaceEleve` (choix du garde-cap) |
| 10 | TRANSITIONS | `e4dd58c10` | `6254f1f22` | `app_bottom_sheet.dart`, imports : union |
| 11 | TRANSITIONS, dettes | `8ba6a373a` | `816f41a03` |  |
| 12 | SOURATES | `c159acca8` | `614870c91` | `RESERVATIONS-MIGRATIONS.md` : la ligne détaillée de SOURATES remplace la courte |
| 13 | PRÉFÉRENCES-PAR-COMPTE | `19ce91fa7` | `f6b457f22` |  |
| 14 | PROFILS P1+P4 | `531434c12` | `bfc3b4a02` | `strings*.g.dart` régénérés |
| 15 | NON-BRANCHÉ-ÉCHUS | `86840822c` | `690996986` |  |
| 16 | MON-ESPACE-ADULTE-SUPPR | `20c8ad26e` | `1b57d4b77` | `strings*.g.dart` régénérés |
| 17 | NETTOYAGE-1 | `601a61103` | `80cb80edf` | `strings*.g.dart` régénérés |
| 18 | PORTS-DIRECTION | `6643dad1c` | `b2f2e9d59` |  |
| 19 | PORTS-COMPTABLE | `717c3f505` | `2ba2f9749` |  |
| 20 | PORTS-CARTES | `df12e9c1e` | `897460a70` |  |
| 21 | CATALOGUE (invisibles) | `c6aa8ef3d` | `13523cf3b` | `accueil_famille_page.dart` : structure goutte, bouton parcours seul ; `catalogue_classes_test.dart` supprimé ; `strings.g.dart` régénéré |
| 22 | COMPTE-SUSPENDU | `26bf8d105` | `e02c70238` | `tool/libelles_sources.json` : union de clés disjointes ; `strings*.g.dart` régénérés |
| 23 | SEC-GARDE-4 | `8d7c884a3` | `7bb7ee957` |  |
| 24 | SEC-GARDE-5 | `ebf712067` | `ec803116c` |  |
| 25 | C29-UNE-SOURCE | `d08529b53` | `ce7db7823` |  |
| 26 | GARDE-ECHEANCES | `acf956e30` | `9b7f972c8` |  |
| 27 | NETTOYAGE-INVENTAIRE | `3790ff918` | `14025f518` |  |
| 28 | correction jeton (`retour_navigateur`, dette 3 de TRANSITIONS) | commit du train | `36134a7b9` | `AppMouvement.fenetreRetourNavigateur` |
| 29 | CAHIER-C3 (coupure active) | `da1119d86` | `050023d3c` |  |
| 30 | CI-FLUTTER (Flutter 3.47.9 épinglé) | `c4a0c17c8` | `42455f29e` |  |
| 31 | NETTOYAGE-2 | `4553e8bd3` | `af9769aa6` |  |
| 31 bis | correction de la tolérance compte (`MonEspaceAdultePage`) | commit du train | `cb8e42e6d` | oubli de E dans MON-ESPACE-ADULTE-SUPPR, vu par Fable |
| 32 | SALLE (#409) | `7ccdc6461` | `81c1a3546` |  |
| 33 | PARCOURS-PROFIL-CHOISI | `06e030d04` | `2e9e41b06` |  |
| 34 | correction SEC-GARDE-4 b (`sourates_validees` dans la liste 1) | commit du train | `3a47b69f5` | CI rouge de #435 ; liste 1 seule (choix du garde-cap) |

## État de la production au 11/11, 22:57 UTC (pilote ; postflights vérifiés en lecture par le garde-cap)

Relais du pilote du 11/11 ; aucune lecture de la production n'est faite par E.

- **Installées** par le pilote (`apply_migration`), CONFORMES pour le garde-cap :
  - `20261122900000` (sourates_validees), `20261123200000` (preference_theme_compte),
    `20261123300000` (sec_garde_4_lectures) : avec l'écart PROSRC-SANS-COMMENTAIRES (voir les dettes) ;
  - `20261123400000` (hook, compte désactivé), `20261123400100` (interrupteur KYC),
    `20261123500000` (C29 une source), `20261123600000` (coupure C3, au 2026-11-12 00:00 UTC),
    `20261123700000` (partage générique) : appliquées telles quelles, corps identiques au dépôt (md5 de `prosrc` comparé au dépôt par le pilote ;
    postflights RLS, droits, coupure et politiques vérifiés par le garde-cap).
- **Collée** par le directeur : `20261123300100` (SEC-GARDE-4 b), CONFORME ; inscrite à l'historique par
  `historique_sec_garde_4_b_editeur_sql` (version `20261123300100`).
- **Reportées** :
  - `20261123400200` : DERIVE-GUARD-PROFILE. Cause trouvée par le garde-cap : accents abîmés dans le message
    d'erreur du corps en production, sans effet sur le comportement. Lot pour B le 12/11 :
    SEC-GARDE-5-C-RECALIBRAGE (accepter les deux empreintes, avec le constat en commentaire).
  - `20261123700100` : RESEAU-PREUVE-INSTALLATION, bloquée par les conditions (a), (b) et (c) de
    `docs/orchestration/garde-cap/RESERVATIONS-MIGRATIONS.md`, en attente de la décision du directeur sur les textes.
- **À expliquer le 12/11 par une lecture** : 6 comptes « disabled », contre 5 au préflight de 12:40.
- `public` compte maintenant 190 tables (`classe_position_support`).
- **Non prouvé** : la connexion réelle après le hook ; la preuve, c'est le directeur.

## Les PR ouvertes (13, au 11/11)

| PR | Branche | Statut | Preuve |
| :-: | :-- | :-- | :-- |
| 433 | `claude/goutte-huile` | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 432 | `claude/titulaire-sans-appareil` | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 431 | `claude/fix-clignote-demande` | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 430 | `claude/sombre-sans-eclair` | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 429 | `claude/retirer-absence-detectee` | en production le 11/11 (`f30527be4`), wagon de #435 | tête `595604ca7` ; elle ne se pousse que pour corriger un test rouge (pilote, 11/11) |
| 426 | `claude/bande-barre` | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 421 | `claude/proposition-progression-sourates` | **REMPLACÉ** | documentation seule ; ni agent ni ordre écrit trouvé. La question qu'elle posait (« sourate validée ») est tranchée en option A (pilote, 11/11) ; tri du 12/11 : par docs/current/PROPOSITION-PROGRESSION-SOURATES-2026-11-11.md de main et l'option A (20261122900000) (garde-cap, 12/11) |
| 409 | `claude/zealous-tesla-ewstzw` | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 : PR en cours, personne d'autre n'y touche |
| 382 | `claude/ma-progression` | À LIVRER (H, après le lot SOURATES de B) | pilote, 11/11 : « sourate validée » est tranchée en option A ; la PR dépend de SOURATES (migration) |
| 380 | `claude/progression-adulte` | À LIVRER (A, après la file actuelle) | pilote, 11/11 : abandonnée le 08/11 sur une panne de CI sqlite3 qui ne venait pas d'elle |
| 42 | `claude/jolly-gauss-7rlt4y` | **ABANDONNÉ** | DÉCISION du directeur demandée le 08/11 (`TRI-PR-AVANT-25-10.md`) : 18 compétences tierces sous `.claude/skills/` (104 fichiers) ; absentes de `main` au 11/11, qui n'a que `marque-rewayah`, `mots-rewayah` et `programme-rewayah` ; tri du 12/11 : remplacées par les compétences du compte (constat de B, 12/11), par délégation du directeur (« à toi de voir », 11/11) ; le pilote ferme la PR 42 ; la branche reste (garde-cap, 12/11) |
| 26 | `codex/backend-staging-preview-secrets` | **À FAIRE** | DÉCISION du directeur demandée le 08/11 ; au 11/11, `flutter-deploy.yml` (l. 150-151) construit encore les aperçus avec les secrets de production. La branche vise un ancien `flutter-deploy.yml` et ne s'applique pas telle quelle ; tri du 12/11 : APERCUS-STAGING, priorité moyenne : risque réduit depuis le 12/11 (aperçu seulement sur l'étiquette apercu) ; recommandation dans la page du réveil du directeur ; pas de code cette nuit (garde-cap, 12/11) |
| 22 | `codex/backend-sec-prod` | ABANDONNÉ (PR fermée) | décision du directeur du 11/11 (« oui ferme la 22 », relayée par le pilote) ; remplacée par #365, #338, SEC-AUDIT et KYC-AUDIT du 11/11, et SEC-GARDE-4 (B, en cours) |

## La file du pilote et les lots en cours (pilote, 11/11/2026 12:02, relais)

Mise à jour du 11/11 après midi. Les agents sont ceux que donne le pilote ; la branche est lue
par `git ls-remote` le 11/11. « non poussée » : aucune branche distante au moment du relevé.

| Rang | Lot | Agent | Statut | Branche ou PR |
| --: | :-- | :-: | :-- | :-- |
| 1 | SOMBRE-SANS-ÉCLAIR | A | en production le 11/11 (`f30527be4`) | PR 430 |
| 2 | Bande sous la barre | B | en production le 11/11 (`f30527be4`) | PR 426 |
| 3 | Clé morte `absenceDetectee` | E | en production le 11/11 (`f30527be4`) | PR 429 |
| 4 | Geste de la carte « Horaire à choisir » | H | en production le 11/11 (`f30527be4`) | PR 431 |
| 5 | Jamais « Aucun appareil prêt » pour le titulaire | H | en production le 11/11 (`f30527be4`) | PR 432 |
| 6 | Goutte d'huile des profils | H | en production le 11/11 (`f30527be4`) | PR 433 |
| 7 | Bande, suite | B | en production le 11/11 (`f30527be4`) | `claude/bande-suite-travail` (`bfcb63483`) |
| 8 | Progression de l'élève adulte | A | À LIVRER | PR 380 ; `claude/progression-adulte-travail` (`8d27fa751`) |
| 9 | TRANSITIONS et ses trois dettes | A | en production le 11/11 (`f30527be4`) | `claude/transitions-travail` (`e4dd58c10`) |
| 10 | SOURATES | B | en production le 11/11 (`f30527be4`) | `claude/sourates-travail` (`cfa41c158`) |
| 11 | MA-PROGRESSION | H | À LIVRER (après SOURATES) | PR 382 |
| en cours | PRÉFÉRENCES-PAR-COMPTE (passe avant P1+P4 ; apporte `langue_compte.dart`) | A | en production le 11/11 (`f30527be4`) | `claude/preferences-compte-travail`, non poussée |
| en cours | PROFILS P1+P4 (gabarit du Compte et ComptePage partagée) | E | en production le 11/11 (`f30527be4`) | `claude/profils-p1-travail` (`0f934cbab` au 11/11 13 h ; reprise en cours sur la branche de A) |
| en cours | NETTOYAGE-INVENTAIRE | A | en production le 11/11 (`f30527be4`) | branche non écrite |
| en cours | PROFILS P2 | H | PAS livré : aucune branche ; `compte_tuteur_page.dart` inchangé par le train | aucune branche au 11/11 23 h |
| en cours | PROFILS P3 | B | PAS livré : commencé par B ; `profil_enseignant_page.dart` inchangé par le train | branche non écrite |
| en cours | SEC-GARDE-4 | B | en production le 11/11 (`f30527be4`) | migrations réservées 20261123300000–399999 ; branche non écrite |
| en cours | SEC-GARDE-5 (les manques de TRI-CODEX A) | B | en production le 11/11 (`f30527be4`) | migrations réservées 20261123400000–499999 ; branche non écrite |
| après SEC-GARDE-5 | Écran « Compte suspendu » | B | en production le 11/11 (`f30527be4`) | pilote, 11/11 ; branche non écrite |
| créneau de 00:40 | NON-BRANCHÉ-ÉCHUS (suppression de `port_capacite_payout.dart`) | E | en production le 11/11 (`f30527be4`) | `claude/non-branche-echus-travail` (`86840822c`), poussée le 11/11 ; suite complète : 21 741 verts, 0 rouge, en deux passes |
| 12/11, nuit | SOMMAIRE-SOURATES (la table des 114 sourates : numéro, nom arabe, nom translittéré, page ; lecteur de l'élève et salle) | Fable | À LIVRER : présent dans le code, testé localement ; ni sur staging ni en production | `claude/zealous-tesla-ewstzw` ; demande du directeur du 11/11 à 23:25 UTC, relayée par le garde-cap ; `docs/current/salle/JOURNAL-DECISIONS.md` D-034 |
| 12/11, nuit | HEURE-PROFIL, partie salle (l'écran de fin et les deux refus à l'heure du profil, formée au dessin ; « heure de cet appareil » en repli seulement) | Fable | À LIVRER : présent dans le code, testé localement ; ni sur staging ni en production | `claude/zealous-tesla-ewstzw` ; plan accepté par le garde-cap le 12/11 à 02:29 UTC (suite de HEURE-PROFIL-PARTOUT) ; journal de la salle D-035 |
| 12/11, nuit | PARENTS-PLURIEL (salle : « {n} parents observent cette séance » quand plusieurs tuteurs visitent ; fiche 0, ligne 16) | Fable | À LIVRER : présent dans le code, testé localement ; ni sur staging ni en production | `claude/zealous-tesla-ewstzw` ; demande du garde-cap du 12/11 à 03:29 UTC ; journal de la salle D-036 |
| 12/11, soir | RETOURS-SALLE-1211 (retours du directeur après sa séance du 12/11 et compléments du soir : plan et état lot par lot dans `docs/current/salle/PLAN-RETOURS-2026-11-12.md`) | Fable, exécution déléguée à des sous-agents, relue et testée | À LIVRER : POINTEUR, VISAGES, BIBLIOTHEQUE-SALLE, ENTREE-ROBUSTE, PAGES-FLUIDES, CAMERA-JUMELAGE, PAUSE-SERVEUR (migration `20261124100000`, non installée), HORS-SALLE-1 et DYNAMIQUE-CHRONO-1, DYNAMIQUE-CHRONO-2, CAMARADES (migration `20261124300000`), SERVEUR-PETITS (migration `20261124400000`), HARMONIE-SALLE, HORS-SALLE-2 (migration `20261124200000`, journal éteint par défaut) et SYNCHRO-SESSION sont présents dans le code et testés localement, migrations non installées ; PR brouillon 449, contrôles verts sur les quinze lots (tête `f89e67a1`) ; PAS COMMENCÉ : RETRAIT, écran « Mes accords », vidéo des camarades côté serveur de visio ; REGLE-CHRONO attend le directeur (argent) ; rien sur staging ni en production | `claude/zealous-tesla-ewstzw` ; demandes du directeur du 12/11 (relayées à 20:40 UTC, puis dites par lui le soir) ; journal de la salle D-037 à D-045 |
| 12/11, matin | EDIT-INFOS-PERSO (le prénom et le nom changés par la personne elle-même, sur la page Informations commune : enseignant, tuteur, élève adulte autonome ; jamais un élève mineur ; sans RPC ni migration, par `profiles_self_update` et `guard_profile_privileged_columns`, décision du garde-cap) | A | À LIVRER : présent dans le code, testé localement ; ni sur staging ni en production ; scénario SQL demandé au pilote par le garde-cap | `claude/edit-infos-perso` ; `test/features/compte/edit_infos_perso_test.dart` ; captures `docs/current/captures/E2E/EDIT-INFOS-PERSO/` ; scénario `supabase/tests/scenarios_edit_infos_perso.sql` (26 vérifications, Postgres local) ; l'élève adulte autonome passe déjà par la page commune (`/compte` le mène au Compte du tuteur, `_aliasTuteur`) : aucune route ajoutée |
| charte 1 | SOCLE-PROGRAMME (lot 1 du plan de la charte, 12/11) : programme des bases publié, étape unique par élève, lecture unique `etape_eleve_lecture`, servie à l'élève et à sa famille par `ma_progression` ; trois migrations : 20261123850000 (correctif de la classe rendue du parcours), 20261123900000, 20261123905000 (`ma_progression` sur le socle) ; la 20261123810000 de `main` est inchangée | agent du lot 1 | À LIVRER : testé localement (Postgres 16, Flutter 3.47.9), non installé, PR #454 ouverte par l'architecte ; testé sur staging : non ; déployé : non | `claude/socle-programme` |
| 12/11, nuit | PRIERE-1 (la prière à l'heure, calculée par le serveur : calcul SQL prouvé contre `adhan`, pause de prière placée par séance, prière qui se ferme, écrans direction/enseignant/élève ; arbitrages P1 à P11 et C45 de l'architecte pédagogique) | Claude (session PRIERE-1) | À LIVRER : présent dans le code, testé localement (migration `20261123930000_priere_serveur.sql` sur Postgres nu, scénarios SQL, suite Flutter) ; **testé sur staging : non ; déployé : non** ; les valeurs de fiqh et la règle de la prière qui se ferme sont à faire valider par le directeur | `claude/priere-serveur`, fiche `docs/current/pedagogie/lots/LOT-PRIERE-1.md` ; migration, aucune PR (ordre de l'architecte) |
| 13/11 | PRIERE-2 (la prière sans formulaire, « zéro saisie » : l'enseignant partage sa position d'un toucher, la méthode suit le pays, la direction lit une liste et corrige une exception ; amende P3) | Claude (session PRIERE-1) | À LIVRER : présent dans le code, testé localement (migration `20261124500000_priere_zero_saisie.sql` sur Postgres nu, scénarios SQL, suite Flutter) ; **testé sur staging : non ; déployé : non** ; la règle « méthode selon le pays » est à faire valider par le directeur | `claude/priere-serveur` (la branche `claude/priere-zero-saisie` demandée n'a pas été poussée : le garde-fou de la session n'autorise que la branche de PRIERE-1), fiche `docs/current/pedagogie/lots/LOT-PRIERE-2.md` |
| charte 2 | CALENDRIER-ET-PAUSES (lot 2 du plan de la charte, 12/11) : calendrier de l'académie saisi par la direction (fermetures, rencontres, évaluations), pause d'un mois et pause d'exception, recul de la date limite de l'étape calculé en un seul endroit, séances non créées un jour de fermeture ; migrations 20261123910000 et 20261123911000 (la seconde porte le seul mot d'effacement : l'événement de notification) | agent du lot 2 | À LIVRER : testé localement (Postgres 16 : 280 scénarios verts ; Flutter, 34 blocs verts ; trois revues de l'architecte traitées, gardes vérifiées par mutation), non installé, aucune PR (ordre de l'architecte), rien d'argent | `claude/calendrier-pauses` ; fiche `docs/current/pedagogie/lots/LOT-2-CALENDRIER-ET-PAUSES.md` ; scénario `supabase/tests/scenarios_calendrier_pauses.sql` ; captures `docs/current/captures/E2E/calendrier-pauses/` |
| charte 5 | ESPACE-APPRENDRE (lot 5 du plan de la charte, 12/11) : l'espace « Apprendre » à trois onglets (Bibliothèque, Programme, Mon livret) pour l'élève adulte et le mineur ; planche de documents commune dans `lib/core/apprendre` ; aucune migration | agent du lot 5 | À LIVRER : testé localement (Flutter 3.47.9, tests par le vrai routeur), aucune PR (l'architecte ouvre la PR et fusionne), non prouvé en production | `claude/espace-apprendre` |

**Remplacé** : `claude/profils-p1-travail-a` (`5fe00c834`), le P1 fait en parallèle par A, est
REMPLACÉ par le P1 de E (`claude/profils-p1-travail`, `ec427b9f3`). Décision du pilote, 11/11
12:03. Une seule pièce en est reprise : `lib/core/compte/langue_compte.dart`
(`choisirLangueCompte`, `synchroLangueCompteProvider`). Elle arrive par le lot
PRÉFÉRENCES-PAR-COMPTE de A.

## Dettes nommées, hors branche

| Date | Dette | Statut | Preuve |
| :-- | :-- | :-- | :-- |
| 11/11 | TRANSITIONS (1) : focus sur le titre et annonce du lecteur d'écran au changement de page (WCAG 2.4.3), dans le core, une seule fois | À LIVRER (A) : absente de la branche livrée par le train (seule la dette 3 y est) | garde-cap : TRANSITIONS jugé CONFORME SOUS RÉSERVES ; relayé par le pilote le 11/11 |
| 11/11 | TRANSITIONS (2) : position de défilement au retour, prouvée par un test sur une liste | À LIVRER (A) : absente de la branche livrée par le train (seule la dette 3 y est) | idem |
| 11/11 | TRANSITIONS (3) : sur le web, tout retour est un fondu court (simplification acceptée, à écrire) | en production le 11/11 (`f30527be4`) (commits `b8904d668`, `8ba6a373a`) | idem |
| 11/11 | NON-BRANCHÉ-ÉCHUS : suppression de `lib/core/capacites/port_capacite_payout.dart` (ligne échue de `tool/branchement_tolere.txt`) | en production le 11/11 (`f30527be4`) | `claude/non-branche-echus-travail` (`86840822c`), poussée le 11/11 ; CONFORME pour le garde-cap |
| 08/11 | Recherche, volet finance : `rech_d4_rechercher_reference_finance` (en production d'après la lecture du 08/11) sans adaptateur dans l'application | non vérifié | `ALERTE-LOTS-NON-LIVRES-2026-11-08.md`, état au 11/11 ; aucun agent ni ordre écrit |
| 11/11 | `ProfilPersonnelPage` (`/compte/profil`) : page pleine de « Non disponible », que le Compte partagé n'ouvre plus depuis P4 | À LIVRER (H, PROFILS P2 : suppression) | arbitrage du garde-cap, relayé par le pilote le 11/11 |
| 11/11 | `langue_courriels_page` supprimée dans P1+P4 (une seule langue, celle du compte) ; « Réduire les effets » branché (coupe les lumières) ; notifications Cours/Foyer et économie de données retirées des réglages | en production le 11/11 (`f30527be4`), avec P1+P4 | arbitrage du garde-cap, relayé par le pilote le 11/11 |
| 11/11 | C29-UNE-SOURCE (dette bornée) : `c29_attribuer_mission_controle` doit lire le plafond dans la dernière version de `controle_regles`, avec repli sur `app_config`, comme `lire_regles_tirage` ; lu en production le 11/11 : clé = 5, table vide, déclencheurs à 'O', donc aucune divergence aujourd'hui | en production le 11/11 (`f30527be4`) ; migration `20261123500000` installée | pilote, 11/11 (lecture de production faite par le pilote, relayée) |
| 11/11 | AGE-SALLE : `portAgeEleveProvider` rend toujours « inconnu », donc un enfant est vouvoyé dans `/salle` ; à brancher sur `student_profiles.student_type` | À LIVRER (Fable, sa zone) | garde-cap, relayé par le pilote le 11/11 ; Fable prévenu |
| 11/11 | CORRIGER-SOURATE : aujourd'hui, une sourate cochée par erreur est définitive ; proposition : l'enseignant auteur la retire dans un court délai, avec audit | DÉCIDÉ OUI (garde-cap, délégation du directeur, 11/11 au soir) : l'enseignant auteur retire une sourate cochée par erreur dans les 24 h, avec trace d'audit ; migration `20261123820000` ; codé par E : `claude/corriger-sourate-travail` (`2a7cef7e0`), CONFORME du garde-cap sous condition de la suite complète | garde-cap, relayé par le pilote le 11/11 ; verdict du garde-cap le 12/11 |
| 12/11 | LANGUE-INFORMATIONS-EN-DUR : la page « Informations personnelles » (commune au tuteur et, depuis COMPTE-ENSEIGNANT-IDENTITE, à l'enseignant) écrit la langue de l'interface en dur (`t.compte.francais`, `informations_page.dart`) : « Français », et « الفرنسية » en arabe, quelle que soit la langue du compte ; `nomLangueCompte` (`lignes_compte.dart`) existe déjà | À LIVRER (A) : la page lit `nomLangueCompte(langueEffective(context))`, comme la ligne « Langue » des Préférences, sans nouveau texte ; présent dans le code, testé localement (fr et ar, le test arabe échoue sans le lot) ; ni sur staging ni en production | garde-cap, 12/11 ; `claude/langue-informations-travail` ; `test/features/compte/langue_informations_test.dart` ; captures `docs/current/captures/E2E/langue-informations/` |
| 12/11 | FUSEAU-IDENTITE-PRO : la feuille « Identité professionnelle » du Compte de l'enseignant (`profil_enseignant_page.dart`, `_IdentiteProfessionnelle`) lit encore le fuseau par `monFuseauProvider` (`mon_fuseau()`, repli sur Europe/Paris) : un enseignant sans fuseau y voit Paris, une valeur inventée ; même défaut dans `creneaux/plages_disponibilite.dart` ; correctif : `monHorlogeProvider`, comme la page Informations depuis COMPTE-ENSEIGNANT-IDENTITE | CODÉ par E (voie A, décision du garde-cap du 12/11) : `claude/fuseau-identite-pro-travail` (`e1213da05`) ; l'enseignant règle lui-même son fuseau (ligne « Fuseau de mes cours », `maj_profil_enseignant(p_timezone)`) ; sans fuseau du profil, aucune disponibilité ne se pose ; suite complète en cours | relevé par E le 12/11 en codant COMPTE-ENSEIGNANT-IDENTITE ; décisions du garde-cap le 12/11 |
| 12/11 | FUSEAU-LISTE-COMPLETE : la feuille du fuseau ne propose que les fuseaux du pays et les 8 fuseaux de l'application, sans décalage, plus le nom international en champ d'expert ; la liste complète (914 noms, `app_private.fuseaux_connus`) avec le décalage actuel (`private.fuseau_info`) demande une RPC de lecture paginée, donc une migration | À FAIRE (non daté, sans numéro réservé tant qu'aucun train n'est décidé) | garde-cap, 12/11 |
| 12/11 | FUSEAUX-PROPOSES-GOLFE : Asia/Riyadh n'est proposé nulle part (ni `fuseauxProposes`, ni `paysProposes`) ; ajouter l'Arabie saoudite et le Golfe aux fuseaux proposés, familles et enseignants ensemble, par le propriétaire de `parcours_offres` (zone refusée par le garde-fou), sur décision ; d'ici là, le directeur saisit « Asia/Riyadh » dans le champ d'expert | À FAIRE (sur décision) | garde-cap, 12/11 |
| 12/11 | FUSEAU-DEFAUT-SERVEUR : `weekly_availability.timezone_iana` est `NOT NULL DEFAULT 'Europe/Paris'` (0005:385) ; sans effet aujourd'hui (le client et `salle3_valider_piece` envoient toujours un fuseau), mais une insertion qui l'omettrait écrirait Paris sans le dire | À FAIRE (plus tard, migration) | garde-cap, 12/11 |
| 12/11 | FUSEAU-CHANGE-PLAGES : quand l'enseignant change de fuseau, ses plages déjà posées gardent l'ancien (`timezone_iana` de chaque ligne) ; l'écran les nomme (« Ces plages sont à l'heure de Paris. ») mais une plage retouchée est réécrite dans le nouveau fuseau, aux mêmes heures murales, sans conversion | À DÉCIDER (convertir, garder, ou demander) | relevé par E le 12/11 en codant FUSEAU-IDENTITE-PRO |
| 12/11 | PAIEMENTS-RECUS-TUTEUR : la ligne « Paiements et reçus » est retirée de la page Compte du tuteur par P2 (H), tant que les reçus ne marchent pas ; **`PaiementsComptePage` et sa route `/tuteur/compte/paiements` RESTENT** (la classe porte aussi « Paiements du foyer » et « Recharger » de l'adulte, et une dizaine de fichiers de tests FI) : plus aucun lien du Compte vers elle | À FAIRE (non daté) : remettre la ligne quand les reçus marchent | garde-cap, relayé par le pilote le 12/11 ; P2 `c3e35fe1e` (décision (b) du garde-cap : elle reste jusqu'à PAIEMENTS-RECUS-TUTEUR) |
| 12/11 | GOUTTE-PROFILS abandonnée, PROFILS-EFFET : décision du directeur du 12/11/2026, 07:11 UTC : « On abandonne la goutte entre profils, on ajoute un simple effet pour le contenu du profil et un autre qui montre le profil sélectionné. » Retirés de `lib/` : `goutte_profils.dart`, `liaison_liquide.dart`, leurs tests, les durées propres à la goutte d'`app_mouvement`. Ajoutés : `FonduContenuProfil` (fondu court du contenu, léger glissement) ; le profil sélectionné se reconnaît à son rond qui grandit et à son anneau d'accent en douceur (`CercleSelectionnable`) ; mouvement réduit = instantané. La branche distante `claude/goutte-nappe-travail` n'est PAS supprimée | À LIVRER (H, branche `claude/profils-effet`) | garde-cap, demande du directeur relayée le 12/11 |
| 12/11 | TEST-ZOOM-BLOQUE : la suite Flutter complète reste bloquée dans le `tearDownAll` de `test/features/salle_seance/zoom_lib_1_test.dart` (vue à 8428 tests verts, 3880 sautés, 0 échec, puis plus rien ; processus tué à la main) ; **rejeu du fichier seul le 12/11 : 56 verts, 7 sautés, 3 s, sans blocage** : le blocage ne lui est donc pas propre | À FAIRE (non daté) : le reproduire dans la suite complète (ordre ou charge de la machine) avant d'accuser un test | H, suite complète sur P2 `c3e35fe1e`, 12/11 vers 02:26 UTC ; non encore expliqué |
| 12/11 | A-FAIRE-LANGUES, textes arabes absents vus par DATE-ARABE-ISOLAT : onze clés n'existent pas dans `ar.i18n.json` et l'interface arabe montre le français de repli (non vu à l'écran) : `alertes.creeeLe`, `alertes.ligne`, `accessibilite.apres.prochaineDateHeure`, `recrutement.invitations.utiliseeLe`, `recrutement.invitations.expireLe`, `recrutement.candidat.valide`, `recrutement.signature.dejaSigne`, `argent.acces.placeConservee`, `foyer.finances.prochainDebitValeur`, `adulte.reprise.phrases.redepotLe`, `foyer.transactions.ligne`. Au total, 929 clés de `fr.i18n.json` n'ont pas d'équivalent arabe (décompte du 12/11 sur la branche DATE-ARABE-SOURCE). Aucune traduction faite | EN ATTENTE (lot A-FAIRE-LANGUES, ordre du directeur) | garde-cap, 12/11 |
| 12/11 | CORRIGER-SOURATE-DIRECTION : le serveur permet à la direction de retirer une sourate sans limite de temps (`retirer_sourate_validee`, `sourates_retirables_classe`), mais aucun écran de l'administration ne l'atteint (le cahier est sous `/enseignant`, le suivi de l'élève est pour la famille) | À FAIRE (pas le 11/11 au soir) : un geste de la direction, sur un écran existant, lu par la capacité `sourates_retirables_classe` | garde-cap, 12/11 |
| 11/11 | `preparer_depot_piece_identite` : le dépôt pour autrui est voulu dans son périmètre (un tuteur pour son foyer, un admin valide, un enseignant ou un contrôleur pour lui seul) ; aucune lecture ouverte | VÉRIFIÉ, rien à changer | B et le garde-cap, le 11/11 (relayé par le pilote) |
| 11/11 | TRI-CODEX A (sécurité), comparé à la production : 17 PRÉSENTS, 3 PARTIELS (`rls-disabled`, `f69-k65`, `f69-super-admin-controls`), 1 ABSENT (`sec-prod-27-invoker`) ; aucune branche à rejouer | les manques passent à SEC-GARDE-5 (B) | garde-cap, le 11/11 (relayé par le pilote) ; lecture de la production faite par eux, pas par E |
| 11/11 | `DemandesHorairesSupabase` et `ResumeSeanceFamilleSupabase` | REMPLACÉS : le premier par #204 (`port_demandes_horaires`, doublon de `admin_regroupements`, parcours servi par `FriseDemandesSupabase` et `DemandesSuiviSupabase`) ; le second par #388 (`port_resume_seance_famille`, feu vert du directeur du 08/11) | verdict du garde-cap du 11/11, relayé par le pilote |
| 11/11 | P2 (H), condition : la Bibliothèque passe sur l'Accueil du tuteur, dans le bloc de la classe de l'enfant choisi, puis P2 la retire du Compte du tuteur ; jusque-là, sa présence dans le Compte du tuteur et de l'adulte est transitoire | À LIVRER (H, P2) | garde-cap, 11/11, relayé par le pilote |
| 11/11 | BARRE-UNE-SOURCE (dette mineure) : `SessionState.barreEleveAdulte` recopie la condition de `app_router.dart:3259` ; après la 426, une seule fonction de choix de barre, lue par `nav_shell` et par `SuiviElevePage` | À LIVRER (après la 426) | garde-cap, 11/11, relayé par le pilote |
| 11/11 | P2 (H), condition : le forfait famille après acceptation a une ligne dans Compte > Paiements > Accès des profils | À LIVRER (H, P2) | garde-cap, 11/11, relayé par le pilote ; manque relevé par E (l'état de l'invitation répondue n'est plus dit nulle part depuis MON-ESPACE-ADULTE-SUPPR) |
| 11/11 | P2 (H), condition : vérification obligatoire de la ligne d'accès de l'adulte autonome dans `AccesComptePage` (aucun test ne couvre ce cas) | À LIVRER (H, P2) | garde-cap, 11/11, relayé par le pilote |
| 11/11 | « Quitter le forfait famille (un adulte sort du foyer) » : ABSENTE, n'a jamais eu de serveur (EA-BR-21 et 22), touche la remise famille ; repartira d'une décision du directeur, pas du code actuel (que A retire) | ABSENTE (décision du directeur à prendre) | garde-cap, 11/11, relayé par le pilote |
| 11/11 | `test/capture/txt1_presence_capture_test.dart` échoue, même sans les changements de P1+P4 : « Présence pas encore connue » introuvable (vieille vérification) ; sauté sans `CAPTURE_DIR` | dette existante, hors P1+P4 | relevé de E le 11/11 ; à inscrire selon le pilote |
| 11/11 | Rejouer les `tool/e2e` `cahier_c1`, `c2`, `c3`, `fn109_paie` et `paiement_integre` avec la coupure du cahier C3 active | À LIVRER (demain, sur le banc de Fable) | pilote, 11/11 |
| 11/11 | PARCOURS-INSCRITS : `v_parcours_onboarding` ne voit pas les classes actives | À LIVRER (H, demain) | pilote, 11/11 |
| 14/11 | MESSAGERIE-PUSH (pilote, 14/11, après #477 ; réécriture d'un CHECK autorisée par la règle du directeur) : à chaque message d'un candidat, la direction de son côté reçoit une notification « à faire » (geste « Répondre », ouvre le fil), un push et un courriel (catégorie recrutement), par le circuit PUSH-1 existant (`push1_ajouter`, déclencheurs de `notifications`) ; une seule notification ouverte par fil et par personne, close à la lecture du fil ; migration `20261125850000` (deux contraintes CHECK réécrites : à coller dans l'éditeur SQL, après `20261125800000`) ; rien ne change côté candidat (`pending_kyc`) (branche `claude/messagerie-push`, PR brouillon) | À LIVRER (PR brouillon, après #477) | agent, 14/11 |
| 14/11 | MESSAGERIE-TEMPS-REEL (directeur, 14/11, retour en production relayé par le pilote : la messagerie candidat / direction n'est ni en direct ni signalée) : signal `public.com_signaux` (une ligne par personne, sans texte, RLS, publié dans Realtime) posé à chaque message et à chaque lecture (migration `20261125800000`, sans mot d'effacement) ; fil ouvert, liste, badges du candidat et de la direction relus en direct ; avis « Vous avez reçu un nouveau message » ; accès aux Messages avec le nombre dans l'en-tête de la direction ; repli toutes les 30 s et bandeau K-59 si le temps réel tombe (branche `claude/messagerie-temps-reel`, PR brouillon). Recherche préalable : `core/fraicheur` (veille Realtime, modèle repris sur un canal à part), `avisEphemereProvider`, `ClocheNotifications`, `BadgeNonLu`, `nonLusParCandidatureProvider` réutilisés ; `notifications` et push NON branchés (contrainte à remplacer = mot d'effacement ; politique qui exclut un candidat `pending_kyc`) | À LIVRER (PR brouillon ; migration à installer par le pilote ; push et courriel d'un nouveau message : dette, décision à prendre) | agent, 14/11 |
| 14/11 | ONBOARDING-BOUCLE (directeur, 14/11, demande répétée plus de 10 fois) : questionnaire d'abord, e-mail à la fin, plus de retour au début ; code à 6 chiffres dans le courriel de connexion et champ « ou saisissez le code reçu », ligne « Vos réponses sont gardées », bandeau « réponses restées sur l'autre navigateur » (branche `claude/onboarding-boucle`, PR brouillon). Recherche préalable : aucun correctif déjà codé dans le dépôt ni dans les branches | À LIVRER (PR brouillon ; le modèle de courriel `magic_link` doit être publié sur Supabase par le directeur) | agent, 14/11 |
| 11/11 | PROFILS P2 (Compte du tuteur, H) n'a pas de branche et n'est PAS livré ; PROFILS P3 (B) est commencé et n'est PAS livré : `lib/features/compte/compte_tuteur_page.dart` et `lib/features/profil_enseignant/profil_enseignant_page.dart` sont inchangés par le train (diff `b86dbc9d9`..`f30527be4` vide) | PAS livrés | garde-cap (R2 non tenue), relayé par le pilote le 11/11 ; diff vérifié par E |
| 11/11 | FERMETURE-CRON (Fable) : une salle sans enseignant se ferme après 120 s, et le micro des élèves reste fermé sans l'enseignant ; mais la fermeture par cron **n'est pas assurée chaque minute en production** : il faut un cron régulier ; plage réservée `20261123700200` | À LIVRER (Fable), sans date | pilote, 11/11 |
| 11/11 | PUSH-1, condition de P2 (H) : l'alerte à la direction pour une demande de changement de fuseau, et la notification de l'enseignant à la réponse, ne partent pas en push (ligne visible seulement dans l'application) ; le garde-cap doit encore accepter que la notification de l'enseignant passe en push plus tard | À LIVRER (H, P2), push à décider | pilote, 11/11 |
| 11/11 | Dettes de la salle (Fable) : (a) écritures de jetons pendant le polling de récitation ; (b) course sur les métadonnées de salle ; (c) jetons délivrés avant le déploiement ; (d) question ouverte « un admin visible conduit-il la classe ? » ; (e) 6 lectures d'`AppRole` dans `salle_page.dart` (un widget lit une capacité, jamais un rôle) | À LIVRER (Fable) ; (d) décision à prendre | pilote, 11/11 |
| 11/11 | #380 (progression de l'élève adulte, A) et #382 (MA-PROGRESSION, H) | À LIVRER : premiers wagons du prochain train (12/11) | pilote, 11/11 |
| 11/11 | ci-propose | REPORTÉ (garde-cap, délégation du directeur, 11/11 au soir) | nommé par le pilote le 11/11, sans texte relayé |
| 11/11 | Relevé de qualité de connexion (RESEAU-PREUVE, `20261123700100`) : DÉCIDÉ OUI ; les 3 blocs de la politique de confidentialité (fr, ar) reviennent depuis `docs/current/TEXTES-VALIDES/INFORMATION-RELEVE-QUALITE.md`, puis la migration est installée | À LIVRER (train 3) | garde-cap, délégation du directeur, 11/11 au soir ; relayé par le pilote |
| 11/11 | Traductions : hors du chantier de la nuit ; `A-FAIRE-LANGUES.md` reste en attente | EN ATTENTE (ordre du directeur) | garde-cap, 11/11 au soir ; relayé par le pilote |
| 07/11 | PROPOSITION-HARMONISER-ARGENT : relevé et proposition, phase 1 (`docs/current/PROPOSITION-HARMONISER-ARGENT-2026-11-07.md`, branche `claude/harmoniser-argent` `9cf1b12f7`, documents seuls) | LIVRABLE tel quel (verdict du garde-cap) ; fichier repris sans réécriture dans cette branche du registre | garde-cap, relayé par le pilote le 11/11 |
| 11/11 | SOMMAIRE-SOURATES : le Coran de l'élève n'a pas de table des sourates (navigation par numéro de page seulement), salle à vérifier aussi ; un composant unique du core, table standard de 1 à 114 (nom arabe, nom français, page de départ ; données de `public.sourate` et `public.verset`) | À LIVRER (Fable, `claude/zealous-tesla-ewstzw`, priorité P2 de la nuit) | directeur, 11/11 au soir ; relayé par le pilote |
| 11/11 | GOUTTE-REFONTE : les rendus de GOUTTE-NAPPE jugés « immondes » par le directeur ; la nappe n'est pas livrée (`claude/goutte-nappe-travail` `6f9525a12`) ; en attendant, GOUTTE-COUPÉE (A) : plus aucune peinture de goutte ; la refonte prendra l'option « carte conteneur » du directeur, rien livré sans sa validation d'une vidéo ou d'une planche | À LIVRER (A : GOUTTE-COUPÉE ; refonte après validation) | directeur, 11/11 au soir ; relayé par le pilote |
| 11/11 | HEURES-ACCUEIL-ENSEIGNANT : sur « Aujourd'hui », « Prochaine séance » (fuseau du profil) et « Ma journée » (heure de l'appareil, `timeline_row.dart:110-113`) disaient deux heures pour la même Classe, et « Classe Classe Coran » (`journee_page.dart:1756`) | À LIVRER (E) : `claude/heures-accueil-enseignant-travail` (`59db7ca36`), suite complète en cours au 11/11 23:35 | directeur et garde-cap, 11/11 au soir |
| 12/11 | HEURE-PROFIL-PARTOUT : limite connue de HEURES-ACCUEIL-ENSEIGNANT (`13a4e8776`) ; `heureChezMoi` et `chezMoi` (`lib/core/tc_horloge/mon_horloge.dart`) lisent le fuseau du profil posé par `monHorlogeProvider`, mais seule la Journée (`journee_page.dart`, `ref.watch(monHorlogeProvider)`) écoute ce fournisseur ; un autre écran qui appelle `heureChezMoi` sans l'écouter montre l'heure de l'appareil tant que la Journée n'a pas été ouverte, et ne se redessine pas quand le fuseau arrive | À FAIRE : chaque écran qui affiche une heure écoute `monHorlogeProvider` (ou un seul point du core le fait pour tous) ; relevé des appelants à faire avant de coder | garde-cap, 11/11 (verdict de HEURES) |
| 07/11 | PHOTO-CANDIDATURE-FIGEE (A ; repris par H) : la photo du dossier d'un candidat figée à l'envoi des réponses | LIVRÉ (#357, `d36d47ef0`) : migration renumérotée `20261121300000` (version durcie : figée une seule fois), branchement `main.dart:533`, scénario `scenarios_photo_candidature_figee.sql`, libellés fr et ar ; restes de la branche `claude/photo-candidature-figee` (`968d57c13`) sans objet : un commentaire au vieux numéro, un `AvatarTile` remplacé dans `main` par `urlPhotoFigee`, des fixtures et un compte de contrôles déjà mis à jour ; le scénario n'est pas dans `ci.yml` (comme 124 des 154) | vérifié par E le 11/11 vers 23:45, contre `main` `f30527be4` ; la consigne « 72 % dans main, manquent migration, branchement, scénario, libellés » était fausse |
| 11/11 | SEC-GARDE-4 b et SOURATES : le préflight de SEC-GARDE-4 b exigeait toute table de `public` dans sa liste 1, et SOURATES créait `sourates_validees` (CI rouge de #435) | CORRIGÉ dans le train par `3a47b69f5` (liste 1 seule, avec commentaire ; choix du garde-cap) | train #435 |
| 07-08/11 | Les 38 PR fermées le 07 et le 08/11 | couvertes selon le garde-cap ; liste à joindre | pilote, 11/11 (liste non relayée) |
| 11/11 | PROSRC-SANS-COMMENTAIRES : en appliquant `20261122900000`, `20261123200000` et `20261123300000`, le pilote a retiré des commentaires à l'intérieur des corps de fonctions ; le `prosrc` en production diffère donc du dépôt pour ces 3 fichiers (`sourates_eleve`, `sourates_bases_classe`, `ma_preference_theme`, `ma_preference_theme_regler` et les autres fonctions de ces fichiers) ; comportement identique ; depuis, les fichiers sont appliqués tels quels | écart connu (préflights md5 futurs à calibrer sur la production) | pilote, 11/11 |
| 11/11 | DERIVE-GUARD-PROFILE : en production, `guard_profile_immutable_id()` a le md5 `1fff46e3`, le dépôt rejoué donne `7c0dc793` ; `20261123400200` est reportée ; cause (garde-cap) : accents abîmés dans le message d'erreur du corps en production, sans effet sur le comportement | À LIVRER (B, 12/11) : SEC-GARDE-5-C-RECALIBRAGE, accepter les deux empreintes avec le constat en commentaire | pilote et garde-cap, 11/11 22:57 |
| 12/11 | PAIEMENTS-TUTEUR (A) : remplace la ligne PAIEMENTS-RECUS-TUTEUR ; le Compte du tuteur reprend une ligne « Paiements » (jamais « et reçus »), sous capacité ; la page dit montant rendu, statut en mots, jour au fuseau du profil ; refus 42501 dit en clair ; date arabe dans le bon ordre (marque U+061C posée à la source, dans `dateLongue`) | À LIVRER (train 6), après lecture en production de `public.paiements_foyer` au réveil du directeur (sinon installer d'abord `20261017160100`) | `claude/paiements-tuteur-travail` ; garde-cap, 12/11 |
| 12/11 | REÇUS-FAMILLE : aucun reçu n'existe côté serveur (`justificatifDisponible` codé faux dans `paiements_foyer`, `recu` nul dans les mouvements, `PortRecus` sans implémentation, FI-BR-05) ; il faut une RPC, une génération et un stockage, et une décision du directeur sur la forme du reçu | DÉCISION DU DIRECTEUR, avec HARMONISER-ARGENT | relevé de A, garde-cap, 12/11 |
| 12/11 | H5-SEMAINE-PROFIL : le planning de la direction relit ses semaines au lundi de l'APPAREIL (`lundiDe`, `PortPlanningDirection.semaine`) ; seul le regroupement par jour est au fuseau du profil (H3) | À FAIRE (pas cette nuit) | garde-cap, 12/11 ; en-tête de `parJour` |
| 12/11 | DATE-ARABE-ISOLAT : un gabarit arabe qui isole chaque morceau d'une date, posé dans une phrase qui isole la date entière, donne un isolat extérieur sans lettre forte, donc de gauche à droite : la date se lit à l'envers (année, mois, jour). CORRIGÉ à la source pour `dateLongue` (`compte/donnees_compte.dart`, U+061C en tête en arabe) : Paiements, Accès (« انتهى في {date} »), acces_finance, acceptation_invitation, reprise_foyer, resultat_recharge. Même forme, À RELEVER (pour plus tard) : `historique.dateCourte`, `historique.dateCourteSansAnnee`, `historique.dateLongue` (`dateCourte`, `dateMoyenne`, `dateLongueHistorique`), `commun.dates.jourDate` (`dateDeLAppareil`), `enseignant.revenus.periode` et `jourMois`, `enseignant.journee.date`, `admin.groupes.c1.jourDate`, `foyer.membre.date`, `dossiers.file.dateChiffres`, `ficheEleve.finances.periodeAFinancerValeur` ; chacun n'est fautif que là où une phrase l'isole à son tour | PARTIEL (dateLongue corrigé) ; reste À RELEVER | relevé de A (script sur `assets/i18n/ar.i18n.json`), garde-cap, 12/11 ; tests `date_arabe_isolat_test.dart`, `paiements_tuteur_test.dart` |
| 12/11 | SUITES-ORPHELINES (leçon pour les agents) : arrêter une suite avec `pkill -f "flutter test"` ne l'arrête PAS ; le processus s'appelle `dartvm … flutter_tools.snapshot test …`, et ses lanceurs `flutter_tester`. Des suites complètes laissées ainsi tournaient en parallèle d'autres, ralentissaient tout et ont fait planter le compilateur des tests (« The Dart compiler exited unexpectedly »). Arrêter avec `pkill -f "flutter_tools.snapshot test"` puis `pkill -f flutter_tester`, et vérifier avec `pgrep -fc "flutter_tools.snapshot\|flutter_tester"` (0 attendu) avant de lancer une suite qui doit donner un chiffre | LEÇON (à connaître) | A, garde-cap, 12/11 |
| 12/11 | TEST-HORLOGE-SURCHARGE : un test qui monte une page qui écoute `monHorlogeProvider` doit surcharger ce fournisseur (hors Supabase, il rend null et remet à vide la lecture posée par `poserMonHorlogePourTest`) ; modèle : `test/features/compte/paiements_tuteur_test.dart` (`_avec`) | RÈGLE DE TEST (à connaître) | A, garde-cap, 12/11 |
| 12/11 | HORLOGE-ET-LIEU : tous les créneaux de classe à l'heure de La Mecque (`Asia/Riyadh`), chacun lit son heure locale d'abord, annonce du changement d'heure, ville obligatoire de chaque foyer et enseignant (liste GeoNames embarquée côté serveur), signalement des incohérences à la direction ; reprend FUSEAUX-PROPOSES-GOLFE, FUSEAU-DEFAUT-SERVEUR et FUSEAU-CHANGE-PLAGES | TEMPS 1 (relevé et plan) : `claude/horloge-lieu` ; attend l'accord de l'architecte pédagogique avant toute migration ou code ; migration réservée `20261123940000` | architecte pédagogique, 12/11 ; `docs/current/pedagogie/HORLOGE-ET-LIEU.md`, `docs/current/pedagogie/lots/LOT-HORLOGE-ET-LIEU.md` |

## Lots de la charte pédagogique (architecte, 13/11/2026)

Spécifiés dans `docs/current/pedagogie/PLAN-DE-CONSTRUCTION.md` (branche `claude/charte-ecole`, documentation seule, pas encore dans `main`). Numérotation du 13/11 ; aucun n'a de branche de code.

| N° | Lot | Statut | Preuve |
| :-- | :-- | :-- | :-- |
| 1 | SOCLE-PROGRAMME | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 1 ; aucune branche de code au 13/11 |
| 2 | CALENDRIER-ET-PAUSES | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 2 ; aucune branche de code au 13/11 |
| 3 | BIBLIOTHEQUE-UNE | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 3 ; aucune branche de code au 13/11 |
| 4 | LECTEUR | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 4 ; aucune branche de code au 13/11 |
| 5 | PLAN-DE-CLASSE (ajouté le 13/11) | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 5 ; aucune branche de code au 13/11 |
| 6 | POINT-DE-SEANCE (ajouté le 13/11) | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 6 ; aucune branche de code au 13/11 |
| 7 | ESPACE-APPRENDRE | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 7 ; aucune branche de code au 13/11 |
| 8 | SUIVI-UNIQUE | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 8 ; aucune branche de code au 13/11 |
| 9 | RETRAIT-CAHIER (ajouté le 13/11) | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 9 ; aucune branche de code au 13/11 |
| 10 | CHEMIN (ajouté le 13/11) | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 10 ; aucune branche de code au 13/11 |
| 11 | MOTEUR-1 | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 11 ; aucune branche de code au 13/11 |
| 12 | EVALUATIONS-ET-LIVRET | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 12 ; aucune branche de code au 13/11 |
| 13 | MOTEUR-2 | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 13 ; aucune branche de code au 13/11 |
| 14 | NETTOYAGE | non commencé, spécifié | `PLAN-DE-CONSTRUCTION.md`, lot 14 ; aucune branche de code au 13/11 |

## Branches mortes, à proposer à la suppression au directeur (11/11)

Proposition seulement : aucune branche n'est supprimée sans le feu vert du directeur sur cette
liste précise (`CLAUDE.md`, invariants).

| Branche | Pourquoi | Source |
| :-- | :-- | :-- |
| `claude/profils-p1-travail-a` | P1 parallèle de A, REMPLACÉ par le P1 de E | pilote, 11/11 12:03 |
| `claude/mots-cahier-travail` | branche morte | garde-cap, relayé par le pilote le 11/11 |
| `claude/sourates-seul-travail` | branche morte | garde-cap, relayé par le pilote le 11/11 |

## Les branches hors de `main`, une par une (241 non livrées)

Les 206 branches livrées (PR fusionnée) ne figurent que dans la sortie du script, plus bas.

### À LIVRER (10 au relevé de 12 h ; 8 en production le 11/11 par #435, restent #380 et #382)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-11 | `claude/zealous-tesla-ewstzw` | 409 | 77 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 |
| 2026-11-11 | `claude/retirer-absence-detectee` | 429 | 2 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 2026-11-11 | `claude/profils-p1-travail` | - | 1 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 2026-11-13 | `claude/depot-simple` | - | à relever | À LIVRER (DEPOT-SIMPLE, temps 2 : formulaire réduit au nécessaire, états visibles, vignette facultative, dépôt direct de la direction ; **migration `20261124700000` à installer AVANT la fusion** ; `scenarios_depot_direct.sql` à ajouter à `ci.yml` par le pilote) | agent du lot, 13/11 ; `docs/current/pedagogie/lots/LOT-DEPOT-SIMPLE.md` ; non prouvé en production |
| 2026-11-13 | `claude/depot-nom-libre` | 458 | 3 | À LIVRER (DEPOT-NOM-LIBRE, temps 1 de DEPOT-SIMPLE : tout nom de fichier passe, une phrase vraie par cause d'échec ; AUCUNE migration ; la fusion déploie `bibliotheque-upload` par `deploy.yml` ; l'architecte pédagogique fusionne après CI verte et relecture) | agent du lot, 13/11 ; tests des cinq noms rouges avant, verts après ; captures `docs/current/captures/E2E/depot-nom-libre/` ; non prouvé en production |
| 2026-11-12 | `claude/bibliotheque-une` | - | 4 | À LIVRER (lot 3 BIBLIOTHEQUE-UNE ; l'architecte pédagogique ouvre la PR et fusionne ; le directeur installe 20261123920000 puis 20261123921000 et déploie `bibliotheque-lecture` et `bibliotheque-upload`) | agent du lot 3, 12/11 ; `docs/current/pedagogie/lots/LOT-3-BIBLIOTHEQUE-UNE.md` |
| 2026-11-08 | `claude/progression-adulte` | 380 | 4 | À LIVRER (A, après la file actuelle) | pilote, 11/11 : abandonnée le 08/11 sur une panne de CI sqlite3 qui ne venait pas d'elle |
| 2026-11-08 | `claude/ma-progression` | 382 | 3 | À LIVRER (H, après le lot SOURATES de B) | pilote, 11/11 : « sourate validée » tranchée en option A |
| 2026-11-11 | `claude/titulaire-sans-appareil` | 432 | 1 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 2026-11-11 | `claude/sombre-sans-eclair` | 430 | 5 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 2026-11-11 | `claude/goutte-huile` | 433 | 3 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 2026-11-11 | `claude/fix-clignote-demande` | 431 | 1 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |
| 2026-11-11 | `claude/bande-barre` | 426 | 8 | en production le 11/11 (`f30527be4`), wagon de #435 | pilote, 11/11 12:02 (relais) |

### Non vérifié (112)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-11 | `claude/proposition-progression-sourates` | 421 | 1 | **REMPLACÉ** | PR 421 ouverte (documentation seule) ; ni agent ni ordre écrits trouvés ; tri du 12/11 : par docs/current/PROPOSITION-PROGRESSION-SOURATES-2026-11-11.md de main et l'option A (20261122900000) (garde-cap, 12/11) |
| 2026-10-19 | `claude/jolly-gauss-7rlt4y` | 42 | 1 | **ABANDONNÉ** | PR 42 ouverte ; DÉCISION du directeur demandée le 08/11 (TRI-PR-AVANT-25-10 l.75), sans réponse écrite trouvée ; tri du 12/11 : remplacées par les compétences du compte (constat de B, 12/11), par délégation du directeur (« à toi de voir », 11/11) ; le pilote ferme la PR 42 ; la branche reste (garde-cap, 12/11) |
| 2026-10-17 | `claude/sharp-goldberg-z10a13` | 40 | 7 | **ABANDONNÉ** | PR 40 fermée sans fusion le 2026-11-08 ; annexe 08/11 l.26, verdict a (livrable tel quel) : simulation économique sur STAGING (seed, outils ; PR 40 ouverte) ; contenu absent de main au 11/11 ; tri du 12/11 : antérieure à DECISION-TARIFS-2026-10-18, chiffres caducs ; seeds du staging ; la branche reste (garde-cap, 12/11) |
| 2026-10-10 | `codex/backend-staging-preview-secrets` | 26 | 2 | **À FAIRE** | PR 26 ouverte ; DÉCISION du directeur demandée le 08/11 (TRI-PR-AVANT-25-10 l.61) ; au 11/11, flutter-deploy.yml construit encore les aperçus avec secrets.SUPABASE_URL et SUPABASE_ANON_KEY (lignes 150-151), comme la production ; tri du 12/11 : APERCUS-STAGING, priorité moyenne : risque réduit depuis le 12/11 (aperçu seulement sur l'étiquette apercu) ; recommandation dans la page du réveil du directeur ; pas de code cette nuit (garde-cap, 12/11) |
| 2026-10-10 | `codex/backend-sec-prod` | 22 | 29 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 22 FERMÉE, décision du directeur du 11/11 « oui ferme la 22 », remplacée par #365, #338, SEC-AUDIT, KYC-AUDIT et SEC-GARDE-4 ; PR 22 ouverte ; proposée FERMER après vérification du garde-cap (TRI-PR-AVANT-25-10 l.57), vérification non trouvée ; docs/backend/SEC_PROD_REMEDIATION.sql absent de main au 11/11 |
| 2026-11-11 | `claude/transitions-travail` | - | 1 | **DÉJÀ DANS MAIN** | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : branche ancêtre de main (garde-cap, 12/11) |
| 2026-11-11 | `claude/sourates-travail` | - | 3 | **DÉJÀ DANS MAIN** | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : branche ancêtre de main (SOURATES, #435) (garde-cap, 12/11) |
| 2026-11-11 | `claude/progression-adulte-travail` | - | 5 | **DÉJÀ DANS MAIN** | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : branche ancêtre de main (garde-cap, 12/11) |
| 2026-11-11 | `claude/lumiere-accueils-vert` | - | 3 | **DÉJÀ DANS MAIN** | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : lib/core/accueil/signaux_famille.dart (MotifFamille.salle, salleRejoignable) (garde-cap, 12/11) |
| 2026-11-11 | `claude/bande-suite-travail` | - | 11 | **DÉJÀ DANS MAIN** | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : branche ancêtre de main (garde-cap, 12/11) |
| 2026-11-08 | `claude/harmonisation-a` | 329 | 2 | **REMPLACÉ** | PR 329 fermée sans fusion le 2026-11-08 ; absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261120300000 à 20261120300200 (renumérotées) (garde-cap, 12/11) |
| 2026-11-07 | `claude/vigilant-pascal-utfgbs` | 314 | 29 | **ABANDONNÉ** | PR 314 fermée sans fusion le 2026-11-08 ; annexe 08/11 l.323, verdict d (proposé abandonné) : passation du garde-cap du 07/11 au soir, « renvoyé par le directeur » (titre du commit) ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d de l'annexe du 08/11 ; journal et réservations de main plus récents ; la branche reste (garde-cap, 12/11) |
| 2026-11-07 | `claude/revenus` | - | 3 | **REMPLACÉ** | annexe 08/11 l.40, verdict a (livrable tel quel) : 3 commits absents de main (présence partielle comptée, total à recevoir, migration 20261110220000_revenus_pres ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261121200000_revenus_presence.sql et 20261110200000_revenus_verite.sql (garde-cap, 12/11) |
| 2026-11-07 | `claude/photo-candidature-figee` | - | 2 | **REMPLACÉ** | annexe 08/11 l.118, verdict b (à reprendre) : migration 20261111200000 (photo du dossier figée à l'envoi, réservée) jamais livrée ; 6 fichiers en conflit ; contenu absent de main au 11/11 ; tri du 12/11 : par supabase/migrations/20261121300000_photo_candidature_figee.sql (renumérotée) (garde-cap, 12/11) |
| 2026-11-07 | `claude/page-salle3` | - | 3 | **ABANDONNÉ** | annexe 08/11 l.39, verdict a (livrable tel quel) : page du directeur pour 20261119000000, déjà installée : utile seulement comme modèle ; contenu absent de main au 11/11 ; tri du 12/11 : 20261119000000 déjà installée ; refus BEGIN/COMMIT dans tool/page_migrations/generer.py:7 ; la branche reste (garde-cap, 12/11) |
| 2026-11-07 | `claude/page-push1` | - | 2 | **REMPLACÉ** | annexe 08/11 l.38, verdict a (livrable tel quel) : outil des pages de migration : refuse un fichier avec BEGIN; ou COMMIT; seul sur une ligne ; contenu absent de main au 11/11 ; tri du 12/11 : par tool/page_migrations/generer.py:7 (garde-cap, 12/11) |
| 2026-11-07 | `claude/methode-pilote-garde` | 322 | 1 | **ABANDONNÉ** | PR 322 fermée sans fusion le 2026-11-07 ; annexe 08/11 l.37, verdict a (livrable tel quel) : document d'orchestration du 07/11 ; contenu absent de main au 11/11 ; tri du 12/11 : méthode en vigueur : docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md ; la branche reste comme archive (garde-cap, 12/11) |
| 2026-11-07 | `claude/harmoniser-argent` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.36, verdict a (livrable tel quel) : relevé de la phase 1, cité par REPONSES-HARMONISER-ARGENT (section 6) ; contenu absent de main au 11/11 ; tri du 12/11 : fichier identique dans main (garde-cap, 12/11) |
| 2026-11-07 | `claude/ci-propose` | - | 3 | **ABANDONNÉ** | annexe 08/11 l.35, verdict a (livrable tel quel) : liste de 218 scénarios SQL pour la CI (ordre de docs/current/ordre-scenarios-ci.txt) ; ci.yml par le pilote ; contenu absent de main au 11/11 ; tri du 12/11 : fichier abandonné ; la question va au registre sous CI-SCENARIOS (lot du pilote, page du directeur) ; la branche reste (garde-cap, 12/11) |
| 2026-11-07 | `claude/brouillon-persistant` | 281 | 6 | **DÉJÀ DANS MAIN** | PR 281 fermée sans fusion le 2026-11-08 ; absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : brouillon présent dans lib/features/inscription/etapes/identite_etape.dart (garde-cap, 12/11) |
| 2026-11-07 | `claude/admiring-brown-r6ai72` | - | 9 | **ABANDONNÉ** | annexe 08/11 l.34, verdict a (livrable tel quel) : RECETTE-FINALE du 07/11 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : état daté du 07/11, remplacé par docs/current/REGISTRE-LOTS.md ; la branche reste (garde-cap, 12/11) |
| 2026-11-06 | `claude/classe-minuscule` | - | 4 | **DÉJÀ DANS MAIN** | annexe 08/11 l.33, verdict a (livrable tel quel) : « classe » en minuscule au milieu d'une phrase (garde-cap 06/11) ; conflit sur les textes fr seulement ; contenu absent de main au 11/11 ; tri du 12/11 : 5b504e41e (#359, 08/11), ancêtre de main ; les « Classe » restants sont voulus (candidat, TEXTES-VALIDES) (garde-cap, 12/11) |
| 2026-11-03 | `claude/preuve-rouge-ci` | 159 | 1 | **ABANDONNÉ** | PR 159 fermée sans fusion le 2026-11-03 ; annexe 08/11 l.322, verdict d (proposé abandonné) : test cassé exprès, « ne pas fusionner » (titre du commit, 03/11) ; contenu absent de main au 11/11 ; tri du 12/11 : test cassé exprès, verdict d de l'annexe ; la branche reste (garde-cap, 12/11) |
| 2026-10-28 | `claude/admiring-brown-r6ai72-audit` | - | 3 | **ABANDONNÉ** | annexe 08/11 l.32, verdict a (livrable tel quel) : inventaire du code du 28/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : inventaires remplacés (INVENTAIRE-NON-BRANCHE-2026-10-31 et 2026-11-11) ; mandat d'audit dépassé par DESIGN-GOV ; la branche reste (garde-cap, 12/11) |
| 2026-10-27 | `claude/admiring-brown-r6ai72-surface` | - | 2 | **ABANDONNÉ** | annexe 08/11 l.31, verdict a (livrable tel quel) : passation vers l'agent local (document) ; contenu absent de main au 11/11 ; tri du 12/11 : passation hors méthode, périmée ; la branche reste (garde-cap, 12/11) |
| 2026-10-27 | `claude/admiring-brown-r6ai72-fiche-0` | - | 2 | **ARCHIVE À RELIRE** | annexe 08/11 l.30, verdict a (livrable tel quel) : fiche 0 section H (document) ; contenu absent de main au 11/11 ; tri du 12/11 : confiée à Fable pour son prochain lot de salle (section H contre 20261123700100) ; pas d'abandon avant lecture (garde-cap, 12/11) |
| 2026-10-27 | `claude/admiring-brown-r6ai72-admission` | - | 1 | **REMPLACÉ** | annexe 08/11 l.29, verdict a (livrable tel quel) : fiche admission lot D (document) ; contenu absent de main au 11/11 ; tri du 12/11 : par docs/current/PLAN-TROIS-SALLES-2026-11-07.md (garde-cap, 12/11) |
| 2026-10-26 | `claude/admiring-brown-r6ai72-passation-2` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.28, verdict a (livrable tel quel) : passation du 26/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : passation périmée ; la branche reste (garde-cap, 12/11) |
| 2026-10-13 | `codex/journal` | - | 10 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.115, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-13 | `codex/backend-c29-versioned-quota` | - | 1 | **REMPLACÉ** | annexe 08/11 l.114, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261123500000_c29_une_source.sql (garde-cap, 12/11) |
| 2026-10-13 | `archive/pc-2026-10-13/codex/proof-f70-ccr-merge` | - | 1 | **ABANDONNÉ** | absente de l'annexe du 08/11 ; contenu absent de main au 11/11 ; tri du 12/11 : branche d'archive, l'essentiel est dans main ; la branche reste (garde-cap, 12/11) |
| 2026-10-12 | `codex2/x2-18` | - | 12 | **À LIVRER** | annexe 08/11 l.113, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : EXPORT-COMPTABLE, à recréer, priorité basse : en production le port vaut ExportRapportsIndisponible (capacité indisponible, annoncée) ; pas cette nuit (garde-cap, 12/11) |
| 2026-10-12 | `codex/deleg-fin-1-serveur` | - | 7 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.112, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/com-back-1-wip` | - | 2 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.111, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-12 | `codex/backend-sec-prod-27-invoker` | - | 2 | **REMPLACÉ** | annexe 08/11 l.110, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261123400200_sec_garde_5_invoker_droits.sql (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-titulaire-profile-create-guard` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.109, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : garde déjà dans main (base rejouée de main 3e6fe21c7, pas la production ; md5 3ecfd4e9) : auth.uid() NULL refusé, coalesce(app_role() = 'guardian' and app_account_valid(), false) (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-teacher-profile-guard` | - | 1 | **REMPLACÉ** | annexe 08/11 l.108, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261021220000_cand_l1b_forme_compte_candidat.sql (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-pairing-code-guard` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.107, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : garde positive déjà dans la définition de main (pg_get_functiondef, base rejouée de main 3e6fe21c7, pas la production ; md5 c9511be4) : coalesce(app_account_valid() and app_role() = 'guardian', false) ; wagon F86-GARDES-POSITIVES annulé, 20261123840000 libéré (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-null-safe-review-fixes` | - | 4 | **DÉJÀ DANS MAIN** | annexe 08/11 l.106, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : sûreté contre NULL assurée par le SCHÉMA (base rejouée de main 3e6fe21c7, pas la production) : creer_offre_horaire laisse passer un NULL dans « not in », mais type_public, langue_code, fuseau_iana, jours et heure_locale sont NOT NULL avec CHECK ; annonces_observation compare à sessions.teacher_id, NOT NULL ; transmettre_student_concern refuse déjà NULL (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-null-safe` | - | 2 | **REMPLACÉ** | annexe 08/11 l.105, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par la branche codex/backend-f86-null-safe-review-fixes (même migration, version revue) (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-archive-retention-guard` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.104, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : garde déjà dans main (base rejouée de main 3e6fe21c7, pas la production ; md5 16918d09) : coalesce(app_role() = 'admin' and app_account_valid(), false) ; p_recording_id et p_gel NULL refusés (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-archive-listen-guard` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.103, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : garde positive déjà dans main (base rejouée de main 3e6fe21c7, pas la production ; md5 5c0bc833) : « toute inconnue ferme », v_role in (admin, controller), enseignant de la séance, ou v_role in (guardian, student) et foyer (HYGIENE-GARDES 08/11) ; p_recording_id NULL refusé (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f86-admin-group-mutator-guards` | - | 2 | **REMPLACÉ** | annexe 08/11 l.102, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261021210200, 20261024150000, 20261031200000, 20261017120600, 20261017110100, 20261021220000 (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-f70-review-fixes` | - | 34 | **REMPLACÉ** | annexe 08/11 l.101, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0086 à 0092, 0076_suivi_demandes_horaires_foyer, 20261011190000 et 20261012171600 (renumérotées) (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-ea-role-br` | - | 2 | **REMPLACÉ** | annexe 08/11 l.100, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par lib/core/session/port_capacite_eleve_supabase.dart (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-cap29-review-fixes` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.99, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : modifiait une migration déjà installée ; la branche reste (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-c29-f86-hashes` | - | 1 | **REMPLACÉ** | annexe 08/11 l.98, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261123500000 (COMMENT F86 dynamique) (garde-cap, 12/11) |
| 2026-10-12 | `codex/backend-b09-notifs` | - | 3 | **REMPLACÉ** | annexe 08/11 l.97, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0085_b09_request_notifications.sql (renumérotée) (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-19` | - | 5 | **REMPLACÉ** | annexe 08/11 l.96, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par tool/rejouer_scenarios.sh (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-13` | - | 2 | **À LIVRER** | annexe 08/11 l.95, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : EDGE-TESTS-CONTRAT (TESTS-EDGE), à recréer, priorité basse ; pas cette nuit (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-12` | - | 2 | **ABANDONNÉ** | annexe 08/11 l.94, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : instantané du 11/10 ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-11` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.93, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : inventaire du 11/10 ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-09` | - | 3 | **DÉJÀ DANS MAIN** | annexe 08/11 l.92, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : TrackSource dans supabase/functions/_shared/livekit.ts ; 0199 et 0200 : voir codex2/x2-08 (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-08` | - | 3 | **ABANDONNÉ** | annexe 08/11 l.91, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : 0200 contredit 20261029180000_langues_cours_publiques et 20261121800200_hygiene_vitrine_offres ; 0199 abandonnée (voir codex2/x2-07) ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-07` | - | 5 | **ABANDONNÉ** | annexe 08/11 l.90, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : 0199 : un retrait en bloc des droits de service_role casserait 9 appels Edge (autoriser_jeton_video, enregistrer_webhook_livekit, enregistrer_archive_seance, consommer_code_appairage, profil_du_jeton_appareil, confirmer/preparer_depot_piece_identite, remettre_session_agent, app_role) ; tout retrait fonction par fonction, sur un besoin écrit (base rejouée de main 3e6fe21c7, pas la production) ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-06` | - | 2 | **ABANDONNÉ** | annexe 08/11 l.89, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : inventaire du 11/10 ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-05` | - | 9 | **À LIVRER** | annexe 08/11 l.88, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : TESTS-EDGE, avec codex2/x2-13, priorité basse ; pas cette nuit (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-04` | - | 5 | **À LIVRER** | annexe 08/11 l.87, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : TESTS-ADAPTATEURS, à recréer, priorité basse ; pas cette nuit (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-03` | - | 4 | **ABANDONNÉ** | annexe 08/11 l.86, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : instantané ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-02` | - | 25 | **ABANDONNÉ** | annexe 08/11 l.85, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : scénario écrit contre le schéma du 11/10 : rouge sur public.id_sequences (table disparue), puis sur guard_teacher_activation_signatures ; main couvre la RLS du foyer : 192 tables public sous RLS, 0 sans, 8 scénarios du foyer (base rejouée de main 3e6fe21c7, pas la production) ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex2/x2-01` | - | 2 | **ABANDONNÉ** | annexe 08/11 l.84, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : instantané, remplacé par les lots SEC-GARDE ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-sec-prod-m2-fixes` | - | 17 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.83, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-sec-prod-allowlist` | - | 30 | **ABANDONNÉ** | annexe 08/11 l.82, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : documents du 11/10 ; 0049 : completer_kyc_document reste DEFINER (voir archive/pc-2026-10-13/codex/backend-c11bis) ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-rls-disabled` | - | 1 | **REMPLACÉ** | annexe 08/11 l.81, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261123400000 (SEC-GARDE-5 a, en production) (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-offres-adapters` | - | 15 | **REMPLACÉ** | annexe 08/11 l.80, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par les migrations du même nom et les adaptateurs de main (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-foyer-ports` | - | 15 | **REMPLACÉ** | annexe 08/11 l.79, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par lib/features/foyer/invitation_conjoint_supabase.dart et 0053_invitations_foyer.sql (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-f79-allowlist` | - | 4 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.78, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-f70-contract-publication` | - | 25 | **REMPLACÉ** | annexe 08/11 l.77, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0092_publish_teacher_contract_2026_10_jur.sql et 0086 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-f69-super-admin-controls` | - | 2 | **REMPLACÉ** | annexe 08/11 l.76, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0088, 0090_a81_f69_review_fixes et 20261123400100 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-f69-k65` | - | 1 | **REMPLACÉ** | annexe 08/11 l.75, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0088, 0090 et 20261123400100 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-contract-signature-continuation` | - | 21 | **REMPLACÉ** | annexe 08/11 l.74, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0092 et 0086 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-contract-signature` | - | 1 | **REMPLACÉ** | annexe 08/11 l.73, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0086_signature_contrat_versionnee.sql (renumérotée) (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-cap29-version-integrity` | - | 27 | **REMPLACÉ** | annexe 08/11 l.72, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par cap29 et bibliotheque_admin de main (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-cap29-library-visibility` | - | 30 | **REMPLACÉ** | annexe 08/11 l.71, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par lib/core/admin/bibliotheque_admin_supabase.dart et la base commune (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c25-regroupements` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.70, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : lib/core/offres/regroupements_pages_supabase.dart et supabase/functions/regroupements-pages ; son test va à TESTS-ADAPTATEURS (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c23-reprise-adapter` | - | 4 | **REMPLACÉ** | annexe 08/11 l.69, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par lib/core/foyer/reprises_admin_supabase.dart et port_reprises_admin.dart (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c22-hardening` | - | 1 | **REMPLACÉ** | annexe 08/11 l.68, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261103300000_cahier_remplacant.sql (etat_presence) et SEC-GARDE-4 a (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c22-canon-adapter` | - | 3 | **REMPLACÉ** | annexe 08/11 l.67, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 20261011200004_c22_presentation_timezone_projection.sql et 0090 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c22-age-presentation` | - | 287 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; annexe 08/11 l.66, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-11 | `codex/backend-c21-kyc-verdict` | - | 15 | **REMPLACÉ** | annexe 08/11 l.65, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0091_c21_kyc_access_verdict.sql (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c21-kyc-access-adapter` | - | 19 | **REMPLACÉ** | annexe 08/11 l.64, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0091_c21_kyc_access_verdict.sql et lib/core/dossier/port_acces_pieces_kyc_supabase.dart (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-c17-signature-status` | - | 27 | **REMPLACÉ** | annexe 08/11 l.63, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par lib/core/recrutement/port_statuts_signature_supabase.dart, 0086 et 20261012171600 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-b12-f84-ccr` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.62, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : remise à plat d'architecture, interdite pendant la Boucle 1 ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-b09-f1-producers` | - | 25 | **REMPLACÉ** | annexe 08/11 l.61, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0085_b09_request_notifications.sql et la base commune (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-b03-b12` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.60, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : remise à plat d'architecture ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-adult-kyc-contract` | - | 15 | **REMPLACÉ** | annexe 08/11 l.59, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par port_capacite_eleve_supabase.dart, 0087 et 0090 (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-a81-f86` | - | 1 | **REMPLACÉ** | annexe 08/11 l.58, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0090_a81_f69_review_fixes.sql (ma_capacite_eleve) (garde-cap, 12/11) |
| 2026-10-11 | `codex/backend-a81-f69-hardening` | - | 17 | **REMPLACÉ** | annexe 08/11 l.57, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 ; tri du 12/11 : par 0090_a81_f69_review_fixes.sql et 0088 (garde-cap, 12/11) |
| 2026-10-11 | `claude/revue-backend-codex-1` | - | 2 | **ABANDONNÉ** | annexe 08/11 l.24, verdict a (livrable tel quel) : verdicts des adaptateurs du 11/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : remplacé par INVENTAIRE-NON-BRANCHE-2026-11-11.md et tool/verifier_branchement.dart ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `claude/f86-manifeste` | - | 3 | **ABANDONNÉ** | annexe 08/11 l.23, verdict a (livrable tel quel) : manifeste F86 du 11/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : remplacé par le COMMENT F86 dynamique (20261123500000) ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `claude/compta-recon` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.22, verdict a (livrable tel quel) : rapport d'écart Finance/Comptable du 11/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : antérieur à DECISION-TARIFS (18/10) et à FINANCE-ENSEIGNANT ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `claude/catalogue-canon-fixes` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.21, verdict a (livrable tel quel) : catalogue de 416 fichiers docs/backend du 11/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : instantané périmé du 11/10 ; la branche reste (garde-cap, 12/11) |
| 2026-10-11 | `archive/pc-2026-10-13/codex/backend-c23-reprise` | - | 5 | **DÉJÀ DANS MAIN** | annexe 08/11 l.320, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 ; tri du 12/11 : tool/security_definer_gate/ de main (garde-cap, 12/11) |
| 2026-10-11 | `archive/pc-2026-10-13/codex/backend-c11bis` | - | 45 | **ABANDONNÉ** | annexe 08/11 l.319, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 ; tri du 12/11 : base et documents du 10/10 ; 0049 : completer_kyc_document RESTE DEFINER, par écrit : les comptes authenticated insèrent dans kyc_documents, le déclencheur appelle get_config (non exécutable par authenticated) et force purge_at (base rejouée de main 3e6fe21c7, pas la production) ; la branche reste (garde-cap, 12/11) |
| 2026-10-10 | `ui/brand-logo-2026` | - | 1 | **DÉJÀ DANS MAIN** | annexe 08/11 l.318, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : SVG du logo dans main (garde-cap, 12/11) |
| 2026-10-10 | `docs/specs-entrantes-2026-10-10` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.317, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d de l'annexe ; antérieur à la Boucle 1 ; la branche reste (garde-cap, 12/11) |
| 2026-10-10 | `codex/backend-passation-2026-10-10` | - | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.55, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-10 | `codex/backend-f1-ccr-port` | - | 20 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.48, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-10 | `claude/wizardly-babbage-lmhkog` | - | 2 | **ABANDONNÉ** | annexe 08/11 l.20, verdict a (livrable tel quel) : 665 captures du bilan TB du 10/10 (document lourd, déconseillé) ; contenu absent de main au 11/11 ; tri du 12/11 : document lourd, dépassé par les captures E2E ; la branche reste (garde-cap, 12/11) |
| 2026-10-09 | `revues/2026-10-04-b061fd81` | - | 14 | **ABANDONNÉ** | annexe 08/11 l.316, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d de l'annexe ; la branche reste (garde-cap, 12/11) |
| 2026-10-09 | `codex/backend-staging-deploy` | - | 14 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe 08/11 l.42, verdict b (à reprendre) : lot serveur Codex du 09 au 13/10 ; base trop vieille ; contenu absent de main au 11/11 |
| 2026-10-05 | `juridique/licence-code` | - | 4 | **ABANDONNÉ** | annexe 08/11 l.314, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : pas de fichier LICENSE : le code reste « tous droits réservés », choix prudent, réversible ; par délégation du directeur (garde-cap, 12/11) |
| 2026-10-04 | `revues/2026-10-04-01MrLWqB` | - | 4 | **ABANDONNÉ** | annexe 08/11 l.313, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d ; la branche reste (garde-cap, 12/11) |
| 2026-10-04 | `corrections/c2-ea-coran` | - | 3 | **ABANDONNÉ** | annexe 08/11 l.311, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d ; démonstration, lecteur refait (tc_mushaf) ; la branche reste (garde-cap, 12/11) |
| 2026-10-04 | `claude/collaborative-task-tracking-r47ieu` | - | 11 | **ABANDONNÉ** | annexe 08/11 l.19, verdict a (livrable tel quel) : revues croisées du 04/10 (document) ; contenu absent de main au 11/11 ; tri du 12/11 : revues d'avant la Boucle 1 ; la branche reste (garde-cap, 12/11) |
| 2026-10-04 | `ccr-a2ce253e-vnv87y` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.310, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d ; la branche reste (garde-cap, 12/11) |
| 2026-09-27 | `archive/pc-2026-10-13/adrc/m4` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.307, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 ; tri du 12/11 : archive ; PageShell réécrit ; la branche reste (garde-cap, 12/11) |
| 2026-09-27 | `archive/pc-2026-10-13/adrc/m3` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.306, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 ; tri du 12/11 : archive, verdict d ; la branche reste (garde-cap, 12/11) |
| 2026-09-27 | `archive/pc-2026-10-13/adrc/m1` | - | 1 | **ABANDONNÉ** | annexe 08/11 l.305, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 ; tri du 12/11 : archive ; liste des Comptes refaite ; la branche reste (garde-cap, 12/11) |
| 2026-09-26 | `ui/tuteur-v1-t` | - | 35 | **ABANDONNÉ** | annexe 08/11 l.304, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d ; espace tuteur refait ; la branche reste (garde-cap, 12/11) |
| 2026-09-26 | `reserve/theme-monochrome-k36` | - | 34 | **ABANDONNÉ** | annexe 08/11 l.303, verdict d (proposé abandonné) : revue, relevé ou maquette d'avant la Boucle 1 (24/10), sans effet sur l'application ; contenu absent de main au 11/11 ; tri du 12/11 : verdict d ; thème redécidé (DESIGN-GOV) ; la branche reste (garde-cap, 12/11) |
| 2026-09-23 | `archive/pc-2026-10-13/integration/core24-classes-v2-remediation` | - | 15 | **ABANDONNÉ** | annexe 08/11 l.302, verdict d (proposé abandonné) : archive du poste du 13/10 (archive/pc-2026-10-13) ; contenu absent de main au 11/11 ; tri du 12/11 : CORE24 suspendu, remplacé par les classes précréées ; verdict d ; la branche reste (garde-cap, 12/11) |

### Remplacé (87)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-08 | `claude/profil-adulte-place` | 330 | 3 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.282 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/photo-foyer` | 326 | 4 | REMPLACÉ par ea0c3c5d0 | annexe ALERTE 08/11 l.281 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/notif-defaut` | 328 | 202 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.279 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/garde-cap-nuit-0711` | 323 | 9 | REMPLACÉ par d936adca4 | annexe ALERTE 08/11 l.278 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-08 | `claude/fluidite-1-g4` | 327 | 202 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.277 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/suivi-eleve` | 287 | 10 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.274 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/selection-texte` | 293 | 8 | REMPLACÉ par 225a957da | annexe ALERTE 08/11 l.273 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/sans-barre-fixe` | 305 | 8 | REMPLACÉ par dbacab482 | annexe ALERTE 08/11 l.272 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle2-entretien` | 301 | 20 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.271 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle-3-accueil` | 300 | 9 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.270 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle-1-tout-ici` | 298 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.269 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/salle-1-suite` | 312 | 118 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.268 (relevé de E le 08/11, relayé) : SALLE-1-TOUT-ICI suite nommé dans les trains G4 et G5 |
| 2026-11-07 | `claude/remplacement-temps-reel` | 310 | 7 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.267 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/push-textes` | 308 | 1 | REMPLACÉ par 18d5da209 | annexe ALERTE 08/11 l.266 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/piece-avant-envoi` | 292 | 2 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.264 (relevé de E le 08/11, relayé) : CAND-L1B nommé dans les trains G4 et G5 |
| 2026-11-07 | `claude/nouveautes` | 285 | 9 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.263 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/messages-candidat` | 304 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.262 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/invitations-personnelles` | 311 | 5 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.261 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/invitation-second-adulte` | 275 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.260 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/harmonisation-e` | 321 | 121 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.259 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/fluidite-2` | - | 9 | REMPLACÉ par 225a957da | annexe ALERTE 08/11 l.117 (relevé de E le 08/11, relayé) : FLUIDITE-2 livré par la PR 349 (84eb99dcb) le 08/11 ; main en avance, ne pas fusionner (corrigé par le garde-cap) ; 2 fi |
| 2026-11-07 | `claude/fluidite-1-bouton` | 320 | 14 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.258 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-07 | `claude/fluidite-1` | 295 | 6 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.257 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/dettes-ui` | 279 | 4 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.256 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/cand-photo` | - | 2 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.255 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-07 | `claude/cahiers-par-seance` | 276 | 5 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.254 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/cadre-ecran` | 296 | 9 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.252 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-07 | `claude/bouton-attente` | 286 | 7 | REMPLACÉ par 225a957da | annexe ALERTE 08/11 l.251 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-07 | `claude/accords-lisez-bas` | - | 32 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.250 (relevé de E le 08/11, relayé) : SALLE-1 lot 4 nommé dans les trains G4 et G5 ; reste : captures |
| 2026-11-05 | `train/2026-11-06-photos` | 244 | 2 | REMPLACÉ par b02056ec8 | annexe ALERTE 08/11 l.249 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-04 | `train/2026-11-04` | - | 1 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.248 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-11-03 | `claude/photos-ecrans` | - | 4 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.116 (relevé de E le 08/11, relayé) : PHOTOS-2a livré sous 20261109300000_photos_2a_fermer_ecriture_avatar.sql (e7b9ce49c, PR 212), dans main et en production |
| 2026-11-03 | `claude/onboarding-fin-sauvegarde` | - | 1 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.224 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-11-03 | `claude/ci-scenarios-03-11` | - | 1 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.209 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-30 | `rewayahacademy-glitch-patch-5` | - | 1 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.157 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-26 | `rewayahacademy-glitch-patch-2` | - | 1 | REMPLACÉ par 48f0bde6d | annexe ALERTE 08/11 l.156 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-26 | `rewayahacademy-glitch-patch-1` | - | 1 | REMPLACÉ par 48f0bde6d | annexe ALERTE 08/11 l.155 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-25 | `claude/admiring-brown-r6ai72-relais` | - | 12 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.154 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-25 | `claude/admiring-brown-r6ai72-passation` | - | 1 | REMPLACÉ par cef3a65f3 | annexe ALERTE 08/11 l.153 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-24 | `claude/lucid-mccarthy-qpk6yq` | 45,50 | 17 | REMPLACÉ par 0081ee309 | annexe ALERTE 08/11 l.152 (relevé de E le 08/11, relayé) : socle CANDIDATURES du 24/10 (PR 45 et 50 ouvertes), repris par les lots candidats livrés depuis |
| 2026-10-13 | `codex/backend-c21-negative-context-r1` | - | 1 | REMPLACÉ par 5fd08c31d | annexe ALERTE 08/11 l.151 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-13 | `codex/backend-c04-negative-context-r1` | - | 1 | REMPLACÉ par b9af42c6c | annexe ALERTE 08/11 l.150 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-13 | `codex/backend-b09-notifications-sources` | - | 1 | REMPLACÉ par 18d5da209 | annexe ALERTE 08/11 l.149 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-13 | `claude/beautiful-ptolemy-xmhiki` | 34 | 4 | REMPLACÉ par main (voir le tri) | PR 34 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.68 |
| 2026-10-12 | `codex2/imm-back-1-wip` | - | 1 | REMPLACÉ par 410d29579 | annexe ALERTE 08/11 l.148 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex2/imm-back-1` | - | 1 | REMPLACÉ par 410d29579 | annexe ALERTE 08/11 l.147 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-rech-d3-enseignants` | - | 5 | REMPLACÉ par 81c838165 | annexe ALERTE 08/11 l.146 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-f86-b18-negative-cases` | - | 2 | REMPLACÉ par e3f52ffa1 | annexe ALERTE 08/11 l.145 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-cap29-back-2` | - | 5 | REMPLACÉ par 291249c7f | annexe ALERTE 08/11 l.144 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-c29-port-wiring` | - | 1 | REMPLACÉ par 0081ee309 | annexe ALERTE 08/11 l.143 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-12 | `codex/backend-b09-events-destinations-r2` | - | 1 | REMPLACÉ par 355ba7dee | annexe ALERTE 08/11 l.142 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex2/x2-10` | - | 2 | REMPLACÉ par bab82154f | annexe ALERTE 08/11 l.141 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-recherche-classes` | - | 1 | REMPLACÉ par ad1e4c28a | annexe ALERTE 08/11 l.140 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-f70-status-tests` | - | 1 | REMPLACÉ par d2f4561eb | annexe ALERTE 08/11 l.139 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-cap29-catalogue` | - | 4 | REMPLACÉ par 291249c7f | annexe ALERTE 08/11 l.138 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-c29-tirage` | - | 4 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.137 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b18-ci-state` | - | 1 | REMPLACÉ par e3f52ffa1 | annexe ALERTE 08/11 l.136 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b09-notifications` | - | 8 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.135 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b09-adaptateur` | - | 1 | REMPLACÉ par 355ba7dee | annexe ALERTE 08/11 l.134 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-b04-reprise` | - | 3 | REMPLACÉ par ea1a0da98 | annexe ALERTE 08/11 l.133 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-al01-05-f86` | - | 3 | REMPLACÉ par b2a59b705 | annexe ALERTE 08/11 l.132 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `codex/backend-a81-c24-adapter` | - | 1 | REMPLACÉ par aa68b38c9 | annexe ALERTE 08/11 l.131 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-11 | `claude/mushaf-15l-captures` | - | 1 | REMPLACÉ par c025d5da0 | annexe ALERTE 08/11 l.130 (relevé de E le 08/11, relayé) : reste : captures ou documents de preuve ; le lot est livré |
| 2026-10-11 | `claude/br1-branchement` | - | 2 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.129 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-notifications` | - | 6 | REMPLACÉ par 355ba7dee | annexe ALERTE 08/11 l.127 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-lota-ledger-provenance` | 32 | 3 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 32 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.67 |
| 2026-10-10 | `codex/backend-lot-f1` | 13,19 | 98 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; PR 13 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.53 |
| 2026-10-10 | `codex/backend-lot-c-staging-api` | 20 | 115 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 20 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.55 |
| 2026-10-10 | `codex/backend-lot-a-manifest` | 25 | 4 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 25 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.60 |
| 2026-10-10 | `codex/backend-f2-b13-admin-rls` | 17 | 58 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; PR 17 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.54 |
| 2026-10-10 | `codex/backend-f2-after-c` | 21 | 282 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; PR 21 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.56 |
| 2026-10-10 | `codex/backend-f1-ccr-8ea7831` | 29,33 | 2 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 29 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.64 |
| 2026-10-10 | `codex/backend-blueprint` | 24 | 5 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 24 fermée le 2026-11-08 sur la proposition « FERMER (à archiver si besoin) » de TRI-PR-AVANT-25-10 l.59 |
| 2026-10-10 | `codex/backend-b20-ccr-8ea7831` | 30 | 2 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 30 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.65 |
| 2026-10-10 | `codex/backend-b20-agent-identity` | 28 | 7 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 28 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.63 |
| 2026-10-10 | `codex/backend-b13-ci-ccr` | 27 | 5 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.126 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-b13-ccr-8ea7831` | 31 | 3 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.125 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-10-10 | `codex/backend-b13-admin-suspended` | 23 | 3 | REMPLACÉ par main (voir le tri) | PR 23 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.58 |
| 2026-10-10 | `claude/com-suite` | - | 3 | REMPLACÉ par 13fc04c09 | annexe ALERTE 08/11 l.124 (relevé de E le 08/11, relayé) : décisions en attente du 10/10, remplacées par CONSIGNES-DIRECTEUR-EN-VIGUEUR et 08 §5 bis |
| 2026-10-09 | `codex/backend-lot-c` | 10 | 14 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 10 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.52 |
| 2026-10-08 | `codex/site-public-preview-main` | 8 | 1 | REMPLACÉ par 48f0bde6d | annexe ALERTE 08/11 l.123 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-28 | `ui/essai-ci-d2` | 7 | 1 | REMPLACÉ par main (voir le tri) | PR 7 fermée le 2026-11-08 sur la proposition « FERMER » de TRI-PR-AVANT-25-10 l.50 |
| 2026-09-28 | `claude/modest-hopper-hj96t5` | 7 | 1 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.122 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-28 | `claude/essai-ci-d2` | 6 | 2 | REMPLACÉ par 4b9980cb6 | annexe ALERTE 08/11 l.121 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-27 | `claude/confident-mayer-m2fqsl` | 5 | 2 | REMPLACÉ par main (voir le tri) | PR 5 fermée le 2026-11-08 sur la proposition « FERMER (rapport à archiver si le pilote veut la trace) » de TRI-PR-AVANT-25-10 l.49 |
| 2026-09-23 | `v0/verite-produit` | - | 1 | REMPLACÉ par f53bfdde0 | annexe ALERTE 08/11 l.120 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |
| 2026-09-23 | `nettoyage/base-2026-09-23` | - | 2 | REMPLACÉ par f53bfdde0 | annexe ALERTE 08/11 l.119 (relevé de E le 08/11, relayé) : chaque fichier qui diffère a été réécrit dans main depuis |

### Abandonné (15)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-09-22 | `lot/onboarding-offres` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.301 : avant la remise à plat du 23/09 |
| 2026-09-22 | `core24/fable-frontend` | - | 2 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.300 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/integration/core24-classes-v2` | - | 10 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.299 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/docs/core24-classes-arbitration` | - | 2 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.298 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/astra/core24-v2` | - | 17 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.297 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/astra/core24-presence-safeguard` | - | 18 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.296 : avant la remise à plat du 23/09 |
| 2026-09-22 | `archive/pc-2026-10-13/astra/core24-classes-legacy-snapshot` | - | 19 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.295 : avant la remise à plat du 23/09 |
| 2026-09-21 | `observation/lot-2026-09-21` | - | 11 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.294 : avant la remise à plat du 23/09 |
| 2026-09-21 | `archive/pc-2026-10-13/sauvegarde/r2-du-tiers` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.293 : avant la remise à plat du 23/09 |
| 2026-09-20 | `teaching-core/0-coordinateur` | - | 2 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.292 : avant la remise à plat du 23/09 |
| 2026-09-15 | `archive/pc-2026-10-13/codex/vague5-integration` | - | 7 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.291 : avant la remise à plat du 23/09 |
| 2026-09-15 | `archive/pc-2026-10-13/codex/presence-correction-ui` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.290 : avant la remise à plat du 23/09 |
| 2026-09-15 | `archive/pc-2026-10-13/codex/login-demo` | - | 1 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.289 : avant la remise à plat du 23/09 |
| 2026-09-14 | `archive/pc-2026-10-13/codex/r2-adaptive-shell` | - | 4 | ABANDONNÉ (remise à plat du 23/09/2026) | annexe ALERTE 08/11 l.288 : avant la remise à plat du 23/09 |
| 2026-09-13 | `codex/r1-adaptive-design-system` | - | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; annexe ALERTE 08/11 l.287 : avant la remise à plat du 23/09 |

### Livré (contenu déjà dans `main`, mesuré le 11/11) (17)

| Date | Branche | PR | Commits hors main | Statut | Preuve |
| :-- | :-- | :-: | --: | :-- | :-- |
| 2026-11-07 | `rewayahacademy-glitch-patch-13` | 265 | 6 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/purge-cron` | 316 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/perf-index-session-events` | 318 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/perf-fuseaux` | 325 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/perf-enseignants-public` | 324 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/mesure-fluidite-selection` | - | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/etat-dossier-photo` | 317 | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-11-07 | `claude/cadre-langues` | 313 | 2 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-10-13 | `archive/pc-2026-10-13/patchs` | - | 2 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-12 | `codex2/imm-accueil-back-phase2-wip` | - | 1 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-10-12 | `codex/backend-kyc-lecture-1` | - | 2 | LIVRÉ (contenu dans main) | 11/11 : le diff de la branche se réapplique à l'envers sur main b86dbc9d sans conflit (git apply -R --check) |
| 2026-10-12 | `codex/backend-c22-presentation-adapter-safe` | - | 1 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-12 | `codex/backend-c11bis-f74-canon` | - | 1 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-09 | `pilotage/tuteur-v1` | - | 341 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-10-04 | `projet/ressources` | - | 16 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-09-09 | `specs` | - | 1 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |
| 2026-09-09 | `refactor-ui-lavender-3628477128789856989` | 1 | 3 | LIVRÉ (rien hors de main) | 11/11 : diff nul entre la branche et sa base commune avec main |

## TRI-CODEX B : produit (pilote, 11/11/2026)

Pour douze branches `codex/backend-*` : la fonction qu'elles apportaient existe-t-elle déjà dans
`main` (`b86dbc9d9`), sous un autre nom ? Relevé mécanique par un sous-agent (petit modèle), en
lecture seule, par recherche de noms et d'appels RPC, sans exécution. Contrôlé par sondage par E
le 11/11 : `DemandesHorairesSupabase` et `ResumeSeanceFamilleSupabase` sont bien absents de `lib/`
(offres-adapters « partielle ») ; `lib/core/offres/regroupements_pages_supabase.dart` est bien
dans `main` (c25-regroupements « présente »). **Ce tri ne tranche rien** : il va au garde-cap et
au directeur.

Verdicts : présente 9, partielle 3, absente 0, non vérifié 0. origin/main = b86dbc9d9 (chemins relatifs au dépôt, lignes lues dans origin/main). Les branches se chevauchent (série empilée) : la colonne « Commits hors main » donne origin/main..ref, et les commits exclusifs à la branche sont indiqués quand ils existent.

| Branche | Commits hors main | Verdict | Preuve dans main (fichier:ligne) ou à quoi elle servait |
| :--- | :--- | :--- | :--- |
| codex/backend-f70-contract-publication | 25 (0 exclusif : tous présents dans cap29-version-integrity et cap29-library-visibility) | partielle | Présent : signature versionnée, `supabase/migrations/0086_signature_contrat_versionnee.sql:6` (contract_texts), `:61` (completer_contract_acceptance), `:125` (signer_contrat). Garde d'activation par signatures courantes, `supabase/migrations/0089_teacher_contract_activation_guard.sql:24` (guard_teacher_activation_signatures), reprise `supabase/migrations/20261021210400_pe_code_conduite_avant_activation.sql:76`. Publication du contrat approuvé, `supabase/migrations/0092_publish_teacher_contract_2026_10_jur.sql:7,38`. Statuts client, `lib/core/recrutement/port_statuts_signature_supabase.dart:38-48`. Hash et nom exposés côté adaptateur de signature, `lib/core/recrutement/port_signature_contrat.dart:262,291-292`. Manque : `lib/core/profil/service_acceptations.dart:89` sélectionne toujours `contract_kind, version, accepted_at` sans `signed_sha256` ni `signer_name` (commit a7e607f19, « exposer hash et nom des acceptations »). |
| codex/backend-cap29-version-integrity | 27 (3acf16851 et 195769f34 sont aussi dans cap29-library-visibility) | présente | Intégrité des versions publiées : `supabase/migrations/20261011112952_cap29_resource_version_integrity.sql:71` (cap29_guard_resource_version), `:147` (trigger), `:192` (cap29_guard_download_asset), `:229` (cap29_assert_published_resource_version). Identique au fichier de la branche, à la qualification `pg_catalog.clock_timestamp` près. Validation des payloads de statut de signature : `lib/core/recrutement/port_statuts_signature.dart:33` (SigneAncienneVersion), `:42` (NonSigne), `lib/core/recrutement/port_statuts_signature_supabase.dart:38-48`. |
| codex/backend-cap29-library-visibility | 30 (dont f2df5eaed et 8bc02d4d8 exclusifs à la série cap29) | présente | Visibilité par publication : `supabase/migrations/20261011112954_cap29_library_visibility.sql:9-17` (library_resource_lecture avec archived_at et current_version_id), `:50` (resource_version_lecture). Même contenu que la branche, main ajoute un grant service_role. Lecture catalogue paginée : `supabase/migrations/20261011112956_cap29_catalogue_read.sql:52` (library_get_catalogue), `:223` (facettes), corrigée par `supabase/migrations/20261016100600_cap29_catalogue_correctif.sql:17` (p_filtre, p_curseur, p_limite). |
| codex/backend-offres-adapters | 15 (9d24e0ece exclusif : corrections de fixtures SQL) | partielle | Présent côté SQL : `supabase/migrations/0050_demandes_horaires_privees_admin.sql:70` (mes_demandes_horaires), `0053_invitations_foyer.sql:73` (inviter_conjoint), `0054_seance_resumes_famille.sql:68` (enregistrer_resume_seance). Présent côté Dart : `lib/core/capacites/profil_eleve_titulaire_supabase.dart:13`, `lib/core/capacites/progression_famille_supabase.dart`, `lib/core/offres/demandes_suivi_supabase.dart:6` (DemandesSuiviSupabase, équivalent de PortSuiviDemandesSupabase). Manque (recherche par nom de classe et d'appel RPC dans lib/) : DemandesHorairesSupabase et PortDemandesHorairesFamille (demandes_horaires_supabase.dart, port_demandes_horaires.dart) ; les RPC mes_demandes_horaires et demander_creneau_personnalise ne sont appelées depuis aucun fichier de lib/. ResumeSeanceFamilleSupabase absent de lib/ (main n'a que publier_resume_seance et revoquer_resume_seance dans lib/core/capacites/partage_pedagogique_supabase.dart:266,282). Non vérifié : une lecture famille du résumé faite autrement. |
| codex/backend-foyer-ports | 15 (5 exclusifs : ports et adaptateurs d'invitation) | présente (autre emplacement) | Invitation du second adulte : `lib/features/foyer/invitation_conjoint_supabase.dart:11,21,44` (InvitationConjointSupabase : inviter_conjoint, annuler_invitation_conjoint). Réponse et lecture de l'invitation reçue : `lib/features/foyer/reponse_invitation_supabase.dart:13,19-23,42` (ReponseInvitationSupabase : mon_invitation_en_cours, repondre_invitation_conjoint). SQL : `supabase/migrations/0053_invitations_foyer.sql:73,176`. Différence : la branche range les ports dans lib/core/foyer/, main les garde dans lib/features/foyer/. |
| codex/backend-c23-reprise-adapter | 4 (395b4a87e exclusif : branchement du port admin) | présente | `lib/core/foyer/reprises_admin_supabase.dart` (ReprisesAdminSupabase, mêmes RPC lister_reprises_admin et decider_reprise_foyer que la branche). SQL : `supabase/migrations/0098_b04_reprises_foyer.sql:36` (deposer_reprise_foyer), `supabase/migrations/0099_b04_titulaire_refusal_terminal.sql` (refus du titulaire, état terminal). |
| codex/backend-c25-regroupements | 1 | présente | `lib/core/offres/regroupements_pages_supabase.dart` existe déjà dans main (différence de 42 lignes avec la branche). Fonction Edge `supabase/functions/regroupements-pages/index.ts` présente (2 lignes de différence). Entrée `supabase/config.toml:542`. Branchement `lib/main.dart:164`. |
| codex/backend-b09-notifs | 3 (407137d8f, 6dcfccec3, 6f3554d9c propres à la branche) | présente | Table privée des notifications : `supabase/migrations/0063_notifications_privatives.sql:4` (create table notifications). Producteur des demandes famille : `supabase/migrations/0085_b09_request_notifications.sql:5` (tc_notification_demande_horaire_famille), `:66` (trigger). Adaptateur : `lib/core/capacites/notifications_supabase.dart:140` (NotificationsSupabase). Branchement en production : `lib/features/notifications/notifications_supabase_provider.dart:15`. |
| codex/backend-b09-f1-producers | 25 (15 exclusifs : producteurs, tests, adaptateurs) | présente | Producteurs de notifications de demandes : `supabase/migrations/0085_b09_request_notifications.sql:5` (famille), `:74` (tc_demandes_horaires_enseignant_affecte), `:19` (refus et retrait, etat refusee ou retiree). La version de main est plus large que la variante de la branche (`0086`, commits c85d0e7eb et f0e6ab5df) : elle couvre aussi les adultes (eleve_id) et les comptes provisional_active, et porte le motif. |
| codex/backend-c29-versioned-quota | 1 | partielle | Plafond hebdomadaire présent : `supabase/migrations/20261011231500_c29_recent_teacher_effective_history.sql:26-33` (lit controle_regles, mais le quota vient de app_config 'controle.missions_par_semaine', repli à 5), et `supabase/migrations/20261011220000_c29_director_arbitration.sql:120-127` (même principe). Manque : la règle versionnée comme seule source du plafond (commit 118fb75a1, `v_quota := v_regle.missions_par_semaine`). |
| codex/backend-b12-f84-ccr | 1 (d7277de06 exclusif) | présente (autre emplacement) | Modèles et ports de contrôle déjà présents dans lib/features/controleur/ : `observation_controle.dart:30,81,100` (NatureObservation, EleveRoster, ObservationControle), `historique_controleur.dart:18,58,152` (StatutRapport, RapportControle, PortHistorique), `echanges_controleur.dart:17,36,60,95` (EtatFilEchange, MessageEchange, FilEchange, PortEchanges), `compte_rendu_controle.dart:28,77` (FaitsVisite, ChoixCompteRendu). La branche les déplace vers lib/core/controle/ ; ce dossier ne contient dans main que port_tirage_controle et service_controle. Le déplacement lui-même est absent de main. |
| codex/backend-b03-b12 | 1 (59a20a495, même patch-id que d7277de06) | présente (autre emplacement) | Même commit que b12-f84-ccr (refactor des ports et modèles de contrôle). Preuves identiques à la ligne ci-dessus. |

## TRI-CODEX : les branches `codex/*` (pilote, 11/11/2026)

Les 177 branches distantes `codex/*` (lot serveur Codex, surtout du 10 au 13/10), une par une,
sur `main` `b86dbc9d9`. Relevé mécanique par un sous-agent (petit modèle), contrôlé par sondage
par E le 11/11 : `codex/backend-c29-versioned-quota` ABSENT (sa migration `20261013000400`
manque à `main`) ; `codex/site-public-local-2026-10-13` ancêtre de `main`.

- **LIVRÉ** (92) : branche ancêtre de `main`, diff réappliqué à l'envers sans conflit, ou diff nul.
- **REMPLACÉ** (23) : seulement quand l'annexe ALERTE du 08/11 donne un verdict c avec le commit
  de `main` qui a réécrit les fichiers (relais du 08/11).
- **ABSENT de main** (62) : le contenu manque à `main` au 11/11. La description vient des seuls
  sujets de commit et chemins de fichiers.

**Ce qui touche au produit, à la sécurité ou au KYC est porté au directeur par le pilote. Ce
tri ne tranche rien.**

| Date | Branche | Commits hors main | Fichiers | Statut | Ce qu'elle fait (pour ABSENT : à quoi elle servait, fichiers principaux) |
| :-- | :-- | --: | --: | :-- | :-- |
| 2026-10-13 | `codex/site-public-local-2026-10-13` | 0 | 0 | LIVRÉ (ancêtre de main) | site public : version locale la plus recente (reprise finale), sauvegarde du 13/10/2026 |
| 2026-10-13 | `codex/journal` | 10 | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Journal de notes du lot serveur Codex (scénarios de confidentialité C-20), documentation seule. Fichiers principaux : docs/backend/codex1/JOURNAL.md. |
| 2026-10-13 | `codex/backend-x2-22-anon-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(x2-22): cover disabled and anonymous pause callers |
| 2026-10-13 | `codex/backend-rech-back-4-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(rech-back-4): cover anon and disabled controller |
| 2026-10-13 | `codex/backend-imm-accueil-f86` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(imm-accueil): pin exact F86 fingerprints |
| 2026-10-13 | `codex/backend-f86-take-student-context-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): reject unauthorized student assignment contexts |
| 2026-10-13 | `codex/backend-f86-registration-acl-r3` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): reject confirmed or signed-in child accounts |
| 2026-10-13 | `codex/backend-f86-registration-acl-r2` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): require server child provenance |
| 2026-10-13 | `codex/backend-f86-observation-context-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): reject unauthorized observation contexts |
| 2026-10-13 | `codex/backend-f70-review-fixes-r2` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f70): clear const infos in test |
| 2026-10-13 | `codex/backend-canon-fixes` | 0 | 0 | LIVRÉ (ancêtre de main) | Merge remote-tracking branch 'origin/codex2/imm-accueil-back-phase3-wip' into codex/backend-canon-imm-accueil-integration |
| 2026-10-13 | `codex/backend-c35-library-read-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(c35): reject disabled reader account |
| 2026-10-13 | `codex/backend-c29-versioned-quota` | 1 | 2 | ABSENT de main | Quota hebdomadaire des missions versionné (migration 20261013000400) et scénarios de poids d'affectation. Fichiers principaux : supabase/migrations/20261013000400_c29_versioned_mission_quota.sql; supabase/tests/scenarios_c29_assignment_weights.sql. |
| 2026-10-13 | `codex/backend-c29-rules-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(c29): cover rule RPC negative contexts |
| 2026-10-13 | `codex/backend-c29-control-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(c29): cover negative capability contexts |
| 2026-10-13 | `codex/backend-c21-negative-context-r1` | 1 | 1 | REMPLACÉ par 5fd08c31d (annexe 08/11 ligne 151, relais) | Test de refus : accès non autorisé au verdict KYC (scénario c21). Fichiers principaux : supabase/tests/scenarios_c21_kyc_access_verdict.sql. |
| 2026-10-13 | `codex/backend-c20-timeline-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(c20): deny cross-household and anonymous timeline reads |
| 2026-10-13 | `codex/backend-c04-negative-context-r1` | 1 | 1 | REMPLACÉ par b9af42c6c (annexe 08/11 ligne 150, relais) | Test de refus : appelants interdits pour la candidature de titre enseignant (c04). Fichiers principaux : supabase/tests/scenarios_c04_teacher_title.sql. |
| 2026-10-13 | `codex/backend-b15-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b15): cover disabled and anonymous annotation RPCs |
| 2026-10-13 | `codex/backend-b14-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b14): cover disabled and anonymous RPC access |
| 2026-10-13 | `codex/backend-b13-anon-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b13): deny anonymous observation history read |
| 2026-10-13 | `codex/backend-b11-student-concern-anon-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b11): deny anonymous student concern RPCs |
| 2026-10-13 | `codex/backend-b11-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b11): cover disabled and anonymous feedback access |
| 2026-10-13 | `codex/backend-b10-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b10): cover anon and disabled support access |
| 2026-10-13 | `codex/backend-b09-replacement-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b09): cover replacement RPC negative contexts |
| 2026-10-13 | `codex/backend-b09-notifications-sources` | 1 | 1 | REMPLACÉ par 18d5da209 (annexe 08/11 ligne 149, relais) | Libellés des événements de notification cités dans une source (tool/libelles_sources.json). Fichiers principaux : tool/libelles_sources.json. |
| 2026-10-13 | `codex/backend-b09-notifications-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b09): deny disabled notification recipient |
| 2026-10-13 | `codex/backend-b09-notifications-integration-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | feat(b09): combine notification adapter on current canon |
| 2026-10-13 | `codex/backend-b09-notifications-canon-r3` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(notifications): source B-09 event labels |
| 2026-10-13 | `codex/backend-b09-dart-l10n-r4` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(notifications): source B-09 event labels |
| 2026-10-13 | `codex/backend-b08-summary-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b08): reject anon and disabled summary writers |
| 2026-10-13 | `codex/backend-b07-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b07): cover disabled and anonymous holder access |
| 2026-10-13 | `codex/backend-b04-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b04): cover disabled and anonymous recovery access |
| 2026-10-13 | `codex/backend-b03-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b03): cover disabled and anonymous invitation RPCs |
| 2026-10-13 | `codex/backend-agt01-negative-context-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(agt01): cover admin RPC denial contexts |
| 2026-10-13 | `codex/backend-age-presentation-negative-r1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(age-presentation): cover anonymous and disabled access |
| 2026-10-12 | `codex/deleg-fin-1-serveur` | 7 | 547 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Fusion DELEG-FIN-1 (intégration Ccr) : polices, i18n et documents mêlés ; le détail au-delà du titre n'est pas lisible dans les commits. Fichiers principaux : lib/core/i18n/strings_fr.g.dart; lib/core/i18n/strings_ar.g.dart; test/features/ped_apres/admin_partage_test.dart; test/features/admin_finance/reserve_delegation/deleg_fin_1_test.dart; lib/features/tc_mushaf/page_madina_15.dart. |
| 2026-10-12 | `codex/com-back-1-wip` | 2 | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Proposition COM-BACK-1 (document d'orientation), une seule modification d'espaces. Fichiers principaux : docs/orchestration/COM-BACK-1-PROPOSITION.md. |
| 2026-10-12 | `codex/backend-sec-prod-27-invoker` | 2 | 3 | ABSENT de main | Audit des fonctions SECURITY DEFINER conservées (SEC-PROD 27) : migration de déclencheurs en mode invoker et scénario de sécurité. Fichiers principaux : docs/backend/SEC_PROD_DEFINER_27.md; supabase/migrations/20261012020000_sec_prod_27_pure_triggers_invoker.sql; supabase/tests/scenarios_b18_security_definer.sql. |
| 2026-10-12 | `codex/backend-rech-d3-enseignants` | 5 | 10 | REMPLACÉ par 81c838165 (annexe 08/11 ligne 146, relais) | Recherche d'enseignants : dédoublonnage des résultats avant pagination, fonction recherche-enseignants et curseur. Fichiers principaux : supabase/functions/recherche-enseignants/index.ts; supabase/functions/_shared/recherche/curseur.ts; supabase/functions/recherche-enseignants/index_test.ts; supabase/functions/_shared/recherche/curseur_test.ts; supabase/functions/_shared/recherche/appelant.ts. |
| 2026-10-12 | `codex/backend-kyc-lecture-negative-coverage` | 0 | 0 | LIVRÉ (ancêtre de main) | test(kyc): assert anon lacks RPC execute |
| 2026-10-12 | `codex/backend-kyc-lecture-1` | 2 | 2 | LIVRÉ (dans main, apply -R --check) | revert(kyc): keep workflow outside lot scope |
| 2026-10-12 | `codex/backend-instant-creneau-a793` | 0 | 0 | LIVRÉ (ancêtre de main) | test(a793): space generated etape4 slots |
| 2026-10-12 | `codex/backend-imm-back-1-integration` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(db): mark IMM-BACK-1 F86 fingerprints pending |
| 2026-10-12 | `codex/backend-f86-titulaire-profile-create-guard` | 1 | 1 | ABSENT de main | Garde F86 sur la création du profil titulaire (migration 20261012112000). Fichiers principaux : supabase/migrations/20261012112000_f86_titulaire_profile_create_guard.sql. |
| 2026-10-12 | `codex/backend-f86-timezone-transition-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): guard timezone transition admin RPC |
| 2026-10-12 | `codex/backend-f86-teacher-profile-guard` | 1 | 2 | ABSENT de main | Garde F86 : un profil enseignant doit avoir un compte valide (migration et scénario). Fichiers principaux : supabase/migrations/20261012122000_f86_teacher_profile_guard.sql; supabase/tests/scenarios_f86_teacher_profile.sql. |
| 2026-10-12 | `codex/backend-f86-take-student-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): avoid teacher activation fixture |
| 2026-10-12 | `codex/backend-f86-student-identity-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): align pairing guard preflight |
| 2026-10-12 | `codex/backend-f86-schedule-withdraw-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): add positive guards to schedule withdrawal RPCs |
| 2026-10-12 | `codex/backend-f86-schedule-request-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): escape schedule request guard literals |
| 2026-10-12 | `codex/backend-f86-registration-acl` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): scope registration RPCs to authenticated guardians |
| 2026-10-12 | `codex/backend-f86-refus-a774` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): reach guarded schedule calls |
| 2026-10-12 | `codex/backend-f86-refus` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): cover guarded RPC refusals |
| 2026-10-12 | `codex/backend-f86-presence-scope` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): make presence scope denial null-safe |
| 2026-10-12 | `codex/backend-f86-pairing-code-guard` | 1 | 1 | ABSENT de main | Garde F86 positive sur la création des codes d'appairage (migration). Fichiers principaux : supabase/migrations/20261012140000_f86_pairing_code_positive_guard.sql. |
| 2026-10-12 | `codex/backend-f86-observation-policy-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): align observation policy preflight |
| 2026-10-12 | `codex/backend-f86-observation-join-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): reject null-role observation callers |
| 2026-10-12 | `codex/backend-f86-observation-entry-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): align observation entry message |
| 2026-10-12 | `codex/backend-f86-null-safe-review-fixes` | 4 | 4 | ABSENT de main | Gardes F86 contre les entrées nulles du catalogue ; scénarios isolés après C11 bis. Fichiers principaux : supabase/migrations/20261012010000_f86_catalog_null_safe_guards.sql; supabase/tests/scenarios_f86_null_inputs.sql; supabase/tests/scenarios_ctr01.sql; supabase/tests/scenarios_b11_student_concern.sql. |
| 2026-10-12 | `codex/backend-f86-null-safe` | 2 | 4 | ABSENT de main | Gardes F86 sur les entrées nulles, hashes revus et cas nuls (migration catalogue et scénarios). Fichiers principaux : supabase/migrations/20261012010000_f86_catalog_null_safe_guards.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/tests/scenarios_ctr01.sql; supabase/tests/scenarios_b11_student_concern.sql. |
| 2026-10-12 | `codex/backend-f86-manual-assignment` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): harden manual assignment guard |
| 2026-10-12 | `codex/backend-f86-kyc-document-read-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): escape KYC guard literals |
| 2026-10-12 | `codex/backend-f86-kyc-decision` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): harden KYC decision guard |
| 2026-10-12 | `codex/backend-f86-dossiers-pending-guard` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): require valid admin for pending dossiers |
| 2026-10-12 | `codex/backend-f86-class-assignment-negative-contexts` | 0 | 0 | LIVRÉ (ancêtre de main) | test(security): cover F86 assignment denial contexts |
| 2026-10-12 | `codex/backend-f86-class-assignment-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): escape class guard message literals |
| 2026-10-12 | `codex/backend-f86-b18-negative-cases` | 2 | 1 | REMPLACÉ par e3f52ffa1 (annexe 08/11 ligne 145, relais) | Test F86 : statut de compte désactivé valide dans le scénario B18. Fichiers principaux : supabase/tests/scenarios_b18_security_definer.sql. |
| 2026-10-12 | `codex/backend-f86-assignment-read-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): guard manual assignment read RPCs |
| 2026-10-12 | `codex/backend-f86-archive-retention-guard` | 1 | 1 | ABSENT de main | Garde F86 durcie sur la rétention des archives (migration). Fichiers principaux : supabase/migrations/20261012113500_f86_archive_retention_guard.sql. |
| 2026-10-12 | `codex/backend-f86-archive-listen-guard` | 1 | 1 | ABSENT de main | Garde F86 : restreindre les rôles d'écoute des archives (migration). Fichiers principaux : supabase/migrations/20261012114500_f86_archive_listen_role_guard.sql. |
| 2026-10-12 | `codex/backend-f86-admin-negative-cases` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): fix admin fixture values |
| 2026-10-12 | `codex/backend-f86-admin-mutators-negative` | 0 | 0 | LIVRÉ (ancêtre de main) | test(f86): cover invalid admin identities |
| 2026-10-12 | `codex/backend-f86-admin-mutators` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): harden admin mutation guards |
| 2026-10-12 | `codex/backend-f86-admin-group-mutator-guards` | 2 | 4 | ABSENT de main | Gardes F86 sur les modifications de groupes par l'administration (migration et scénarios). Fichiers principaux : supabase/migrations/20261012123000_f86_admin_group_mutator_guards.sql; supabase/tests/scenarios_f86_admin_group_mutator_guards.sql; supabase/migrations/20261012122000_f86_teacher_profile_guard.sql; supabase/tests/scenarios_f86_teacher_profile.sql. |
| 2026-10-12 | `codex/backend-f70-review-fixes` | 34 | 46 | ABSENT de main | Fusion des corrections canon dans F70 : CI, capacités famille et dossiers (lot large). Fichiers principaux : supabase/migrations/0076_b08_published_summary_controls.sql; supabase/tests/scenarios_f69_kyc_super_admin.sql; supabase/migrations/0057_signature_contrat_versionnee.sql; supabase/migrations/0087_teacher_contract_activation_guard.sql; lib/core/offres/port_suivi_demandes_supabase.dart. |
| 2026-10-12 | `codex/backend-etape4-timezone-review-fix` | 0 | 0 | LIVRÉ (ancêtre de main) | test(etape4): avoid cross-zone past-hour rollover |
| 2026-10-12 | `codex/backend-ea-role-br` | 2 | 3 | ABSENT de main | Fusion de la branche canon-fixes dans le rôle BR : port de capacité élève côté Supabase. Fichiers principaux : test/core/session/port_capacite_eleve_supabase_test.dart; lib/core/session/port_capacite_eleve_supabase.dart; lib/core/session/port_capacite_eleve.dart. |
| 2026-10-12 | `codex/backend-cap29-review-fixes` | 1 | 1 | ABSENT de main | Correction CAP29 : lecture des métadonnées de droits révoquée pour les comptes connectés (migration). Fichiers principaux : supabase/migrations/20261011112958_cap29_rights_metadata.sql. |
| 2026-10-12 | `codex/backend-cap29-r2-upload` | 0 | 0 | LIVRÉ (ancêtre de main) | test(cap29): sign teacher contracts before activation |
| 2026-10-12 | `codex/backend-cap29-c35` | 0 | 0 | LIVRÉ (ancêtre de main) | merge: current canon-fixes into C-35 |
| 2026-10-12 | `codex/backend-cap29-back-2` | 5 | 6 | REMPLACÉ par 291249c7f (annexe 08/11 ligne 144, relais) | Scénarios CAP29 : appels RPC admin en anon, clés R2 et détail de bibliothèque. Fichiers principaux : supabase/tests/scenarios_cap29_rights_review.sql; supabase/tests/scenarios_cap29_library_detail.sql; supabase/tests/scenarios_c35_library_read.sql; supabase/functions/_shared/r2/signature_test.ts; supabase/functions/_shared/r2/cles_test.ts. |
| 2026-10-12 | `codex/backend-canon-fixes-a778` | 0 | 0 | LIVRÉ (ancêtre de main) | test: verify shared class instant across timezones |
| 2026-10-12 | `codex/backend-c35-review-fix` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(c35): align rights joins with version metadata |
| 2026-10-12 | `codex/backend-c29-port-wiring` | 1 | 1 | REMPLACÉ par 0081ee309 (annexe 08/11 ligne 143, relais) | Branchement du port de tirage réel dans lib/main.dart. Fichiers principaux : lib/main.dart. |
| 2026-10-12 | `codex/backend-c29-fixture-time` | 0 | 0 | LIVRÉ (ancêtre de main) | test(c29): make session fixtures time independent |
| 2026-10-12 | `codex/backend-c29-f86-hashes` | 1 | 1 | ABSENT de main | Enregistrer les hashes des définitions de fonctions revues (C29 / F86, migration). Fichiers principaux : supabase/migrations/20261012110000_c29_f86_functiondef_hashes.sql. |
| 2026-10-12 | `codex/backend-c29-effective-teacher` | 0 | 0 | LIVRÉ (ancêtre de main) | Merge remote-tracking branch 'origin/codex/backend-canon-fixes' into codex/backend-c29-effective-teacher |
| 2026-10-12 | `codex/backend-c22-presentation-adapter-safe` | 1 | 0 | LIVRÉ (diff nul) | merge: corrected canon fixes into C22 adapter |
| 2026-10-12 | `codex/backend-c21-canon-adapter` | 0 | 0 | LIVRÉ (ancêtre de main) | test(c21): sign current teacher NDA in fixture |
| 2026-10-12 | `codex/backend-c20-frise-2` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(c20): guard optional realtime publication |
| 2026-10-12 | `codex/backend-c11bis-f74-canon` | 1 | 0 | LIVRÉ (diff nul) | merge: corrected canon fixes into C11bis F74 |
| 2026-10-12 | `codex/backend-b12-negative-contexts` | 0 | 0 | LIVRÉ (ancêtre de main) | Merge branch 'codex/backend-canon-fixes' of https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App into codex/backend-b12-negative-contexts |
| 2026-10-12 | `codex/backend-b12-control-mission-1` | 0 | 0 | LIVRÉ (ancêtre de main) | test(b12): repair control mission fixtures |
| 2026-10-12 | `codex/backend-b09-notifs` | 3 | 8 | ABSENT de main | CI : scénario SQL des notifications B-09, avec adaptateur, migrations 0063 et 0086. Fichiers principaux : supabase/tests/scenarios_b09_notifications.sql; lib/core/capacites/notifications_supabase.dart; supabase/migrations/0086_b09_request_notifications.sql; test/core/capacites/notifications_supabase_test.dart; supabase/migrations/0063_notifications_privatives.sql. |
| 2026-10-12 | `codex/backend-b09-notifications-canon-2` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(b09): combine notification events and localized provider |
| 2026-10-12 | `codex/backend-b09-events-destinations-r2` | 1 | 2 | REMPLACÉ par 355ba7dee (annexe 08/11 ligne 142, relais) | Adaptateur des notifications : prise en charge de tous les événements de base de données (B-09). Fichiers principaux : lib/core/capacites/notifications_supabase.dart; test/core/capacites/notifications_supabase_test.dart. |
| 2026-10-12 | `codex/backend-b04-reprise-canon` | 0 | 0 | LIVRÉ (ancêtre de main) | merge: reviewed canon-fixes into B-04 |
| 2026-10-12 | `codex/backend-a816-a793-occurrence` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(a793): secure weekly slot helper and assert offsets |
| 2026-10-11 | `codex/pubspec-mushaf` | 0 | 0 | LIVRÉ (ancêtre de main) | chore(mushaf): register Uthmanic Hafs font |
| 2026-10-11 | `codex/backend-sec-prod-m2-fixes` | 17 | 2 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Correction des gardes de rôle d'observation (SEC-PROD : snapshot et remédiation). Fichiers principaux : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/SEC_PROD_REMEDIATION.sql. |
| 2026-10-11 | `codex/backend-sec-prod-allowlist` | 30 | 12 | ABSENT de main | Inventaire des déclencheurs d'événements et liste blanche SECURITY DEFINER (SEC-PROD, F79) ; 30 commits. Fichiers principaux : docs/backend/SECURITY_DEFINER_INVENTORY_PROD_2026-10-11.json; docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/SEC_PROD_REMEDIATION.sql; tool/security_definer_gate/verify_allowlist.py; tool/security_definer_gate/tests/test_verify_allowlist.py. |
| 2026-10-11 | `codex/backend-rls-disabled` | 1 | 2 | ABSENT de main | Bloquer l'accès des comptes désactivés (migration et scénario RLS). Fichiers principaux : supabase/tests/scenarios_disabled_account_access.sql; supabase/migrations/20261011192337_disabled_account_access_guards.sql. |
| 2026-10-11 | `codex/backend-recherche-classes` | 1 | 2 | REMPLACÉ par ad1e4c28a (annexe 08/11 ligne 140, relais) | Curseurs de pagination signés pour la recherche de classes. Fichiers principaux : supabase/functions/_shared/recherche/curseur.ts; supabase/functions/_shared/recherche/curseur_test.ts. |
| 2026-10-11 | `codex/backend-offres-adapters` | 15 | 27 | ABSENT de main | Corrections des scénarios SQL B08 et offres, adaptateurs offres (lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-foyer-ports` | 15 | 35 | ABSENT de main | Adaptateur de lecture des invitations reçues du foyer (lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-f86-positive-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | fix(f86): canonical guard for spouse invitation cancel |
| 2026-10-11 | `codex/backend-f79-allowlist` | 4 | 6 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; CI : isoler les vérifications F79 à chaque push (liste blanche SECURITY DEFINER). Fichiers principaux : tool/security_definer_gate/verify_allowlist.py; tool/security_definer_gate/tests/test_verify_allowlist.py; tool/security_definer_gate/tests/test_guard_scanner.py; tool/security_definer_gate/catalog.sql; docs/backend/SECURITY_DEFINER_GATE.md. |
| 2026-10-11 | `codex/backend-f70-status-tests` | 1 | 1 | REMPLACÉ par d2f4561eb (annexe 08/11 ligne 139, relais) | Test de l'accès au statut de signature enseignant (scénario etape3). Fichiers principaux : supabase/tests/scenarios_etape3.sql. |
| 2026-10-11 | `codex/backend-f70-contract-publication` | 25 | 55 | ABSENT de main | Publication du contrat enseignant approuvé (feat backend, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-f69-super-admin-controls` | 2 | 2 | ABSENT de main | Contrôles super-admin F69 (migration et scénarios) ; fusion des corrections canon. Fichiers principaux : supabase/migrations/20261011153000_f69_super_admin_controls.sql; supabase/tests/scenarios_f69_super_admin_controls.sql. |
| 2026-10-11 | `codex/backend-f69-k65` | 1 | 2 | ABSENT de main | Restreindre l'exception KYC F69 au seul rôle postgres (migration). Fichiers principaux : supabase/migrations/0100_f69_postgres_only_controls.sql; supabase/tests/scenarios_f69_operator_controls.sql. |
| 2026-10-11 | `codex/backend-contract-signature-continuation` | 21 | 55 | ABSENT de main | Exposer le hash et le nom des acceptations de contrat (suite de la signature, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-contract-signature` | 1 | 2 | ABSENT de main | Versionner la signature du contrat enseignant (migration 0057 et scénario). Fichiers principaux : supabase/migrations/0057_signature_contrat_versionnee.sql; supabase/tests/scenarios_etape3.sql. |
| 2026-10-11 | `codex/backend-cap29-version-integrity` | 27 | 58 | ABSENT de main | Intégrité des versions publiées de la bibliothèque (CAP29, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-cap29-rights-schema` | 0 | 0 | LIVRÉ (ancêtre de main) | feat(backend): add CAP29 rights review RPC |
| 2026-10-11 | `codex/backend-cap29-library-visibility` | 30 | 61 | ABSENT de main | Lectures paginées du catalogue administrateur (CAP29, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-cap29-catalogue` | 4 | 4 | REMPLACÉ par 291249c7f (annexe 08/11 ligne 138, relais) | Valider les clés d'objet avant signature R2 (CAP29). Fichiers principaux : supabase/functions/_shared/r2/cles_test.ts; supabase/functions/_shared/r2/signature_test.ts; supabase/functions/_shared/r2/cles.ts; supabase/functions/_shared/r2/signature.ts. |
| 2026-10-11 | `codex/backend-canon` | 0 | 0 | LIVRÉ (ancêtre de main) | feat(backend): assemble canonical migrations 0049-0092 |
| 2026-10-11 | `codex/backend-c29-tirage` | 4 | 5 | REMPLACÉ par 4b9980cb6 (annexe 08/11 ligne 137, relais) | Test : les règles cibles ne peuvent être ni modifiées ni supprimées (C29, migrations). Fichiers principaux : supabase/migrations/20261011121039_c29_control_capabilities.sql; supabase/migrations/20261011125034_c29_mission_engine.sql; supabase/tests/scenarios_c29_control_capabilities.sql; supabase/tests/scenarios_c29_mission_engine.sql; .github/workflows/ci.yml. |
| 2026-10-11 | `codex/backend-c25-regroupements` | 1 | 4 | ABSENT de main | Adaptateur des pages de regroupement (C-25) : fonction regroupements-pages et config Supabase. Fichiers principaux : supabase/functions/regroupements-pages/index.ts; lib/core/offres/regroupements_pages_supabase.dart; test/core/offres/regroupements_pages_supabase_test.dart; supabase/config.toml. |
| 2026-10-11 | `codex/backend-c25-c11bis-followup` | 0 | 0 | LIVRÉ (ancêtre de main) | feat: connect paged C-25 regroupement admin |
| 2026-10-11 | `codex/backend-c23-reprise-adapter` | 4 | 78 | ABSENT de main | Brancher le port des reprises de foyer côté administration (C23, lot large). Fichiers principaux : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/migrations/0061_assignations_annotations_securisees.sql. |
| 2026-10-11 | `codex/backend-c23-adapter` | 0 | 0 | LIVRÉ (ancêtre de main) | feat(c23): add household reprise admin adapter |
| 2026-10-11 | `codex/backend-c22-hardening` | 1 | 2 | ABSENT de main | Durcir l'accès au retour d'expérience et à la présence (migration et scénario). Fichiers principaux : supabase/migrations/20261011170000_c22_feedback_presence_account_guard.sql; supabase/tests/scenarios_b11_feedback_questions.sql. |
| 2026-10-11 | `codex/backend-c22-canon-adapter` | 3 | 8 | ABSENT de main | Projection du fuseau horaire du foyer pour les demandes de présentation (C22). Fichiers principaux : test/core/accessibilite/reponse_presentation_supabase_test.dart; supabase/migrations/20261011200000_c22_presentation_timezone_projection.sql; lib/core/accessibilite/reponse_presentation_supabase.dart; supabase/migrations/20261011100000_a81_capacity_positive_guard.sql; supabase/tests/scenarios_age_presentation.sql. |
| 2026-10-11 | `codex/backend-c22-age-presentation` | 287 | 101 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; Stabiliser le scénario de présentation selon l'âge (C22, très grand lot). Fichiers principaux : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql. |
| 2026-10-11 | `codex/backend-c21-kyc-verdict` | 15 | 32 | ABSENT de main | Port serveur du verdict d'accès KYC (C21, 32 fichiers). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-c21-kyc-access-adapter` | 19 | 48 | ABSENT de main | Fermer l'accès du rôle service au verdict KYC (C21). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-c17-signature-status` | 27 | 56 | ABSENT de main | Fermer le garde des statuts de signature (sécurité, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-c11bis-f74-v2` | 0 | 0 | LIVRÉ (ancêtre de main) | feat(backend): partition C-11 bis groups by F74 dimensions |
| 2026-10-11 | `codex/backend-c11bis-adapter` | 0 | 0 | LIVRÉ (ancêtre de main) | feat(offres): map C11bis regroupements to Supabase |
| 2026-10-11 | `codex/backend-b18-ci-state` | 1 | 1 | REMPLACÉ par e3f52ffa1 (annexe 08/11 ligne 136, relais) | Test : accepter le code SQLSTATE du refus KYC protégé (B18). Fichiers principaux : supabase/tests/scenarios_b18_security_definer.sql. |
| 2026-10-11 | `codex/backend-b12-f84-ccr` | 1 | 10 | ABSENT de main | Extraire les ports et modèles B12 vers le cœur (contrôles), 10 fichiers. Fichiers principaux : lib/core/controle/modele_rapport_controle.dart; lib/core/controle/modele_observation_controle.dart; lib/core/controle/modele_echanges.dart; lib/core/controle/modele_visite.dart; lib/core/controle/port_historique.dart. |
| 2026-10-11 | `codex/backend-b09-remplacements` | 1 | 0 | LIVRÉ (ancêtre de main) | feat(b09): add audited replacement producers |
| 2026-10-11 | `codex/backend-b09-notifications` | 8 | 5 | REMPLACÉ par 4b9980cb6 (annexe 08/11 ligne 135, relais) | CI : scénario SQL des notifications B-09 (migration 0063 et tests). Fichiers principaux : lib/core/capacites/notifications_supabase.dart; supabase/tests/scenarios_b09_notifications.sql; test/core/capacites/notifications_supabase_test.dart; supabase/migrations/0063_notifications_privatives.sql; .github/workflows/ci.yml. |
| 2026-10-11 | `codex/backend-b09-f1-producers` | 25 | 35 | ABSENT de main | Corriger les compteurs B-09 (producteurs de notifications F1, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-b09-adaptateur` | 1 | 2 | REMPLACÉ par 355ba7dee (annexe 08/11 ligne 134, relais) | Adaptateur Supabase des notifications (B-09). Fichiers principaux : lib/core/capacites/notifications_supabase.dart; test/core/capacites/notifications_supabase_test.dart. |
| 2026-10-11 | `codex/backend-b04-reprise` | 3 | 76 | REMPLACÉ par ea1a0da98 (annexe 08/11 ligne 133, relais) | Fermer les reprises de foyer refusées par le titulaire (B-04, 76 fichiers). Fichiers principaux : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/migrations/0061_assignations_annotations_securisees.sql. |
| 2026-10-11 | `codex/backend-b03-b12` | 1 | 10 | ABSENT de main | Extraire les ports et modèles B12 vers le cœur (contrôles), même contenu que la branche b12-f84-ccr. Fichiers principaux : lib/core/controle/modele_rapport_controle.dart; lib/core/controle/modele_observation_controle.dart; lib/core/controle/modele_echanges.dart; lib/core/controle/modele_visite.dart; lib/core/controle/port_historique.dart. |
| 2026-10-11 | `codex/backend-al01-05-f86` | 3 | 4 | REMPLACÉ par b2a59b705 (annexe 08/11 ligne 132, relais) | Bloquer l'identité de rôle auth dans la porte de fonctions F86 (outillage de contrôle). Fichiers principaux : tool/security_definer_gate/verify_allowlist.py; tool/security_definer_gate/tests/test_verify_allowlist.py; tool/security_definer_gate/tests/test_guard_scanner.py; tool/security_definer_gate/catalog.sql. |
| 2026-10-11 | `codex/backend-adult-kyc-contract` | 15 | 49 | ABSENT de main | Scénarios adulte et KYC dans la CI Postgres (lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-a81-f86` | 1 | 2 | ABSENT de main | Garde de capacité élève autonome (migration a81 et scénario d'âge). Fichiers principaux : supabase/migrations/20261011100000_a81_capacity_positive_guard.sql; supabase/tests/scenarios_age_presentation.sql. |
| 2026-10-11 | `codex/backend-a81-f69-hardening` | 17 | 45 | ABSENT de main | Durcir la capacité adulte et l'accès KYC (A81 / F69, lot large). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-11 | `codex/backend-a81-c24-adapter` | 1 | 1 | REMPLACÉ par aa68b38c9 (annexe 08/11 ligne 131, relais) | Lire la capacité élève autonome depuis Supabase (adaptateur de session). Fichiers principaux : lib/core/session/port_capacite_eleve_supabase.dart. |
| 2026-10-10 | `codex/backend-teacher-recruitment` | 0 | 0 | LIVRÉ (ancêtre de main) | REPRISE : decisions du directeur (paie hors app, contrat valide, Actions epuisees) |
| 2026-10-10 | `codex/backend-staging-preview-secrets` | 2 | 1 | REMPLACÉ par 48f0bde6d (annexe 08/11 ligne 128, relais) | Fusion ccr dans la branche des secrets d'aperçu staging (workflow de déploiement Flutter). Fichiers principaux : .github/workflows/flutter-deploy.yml. |
| 2026-10-10 | `codex/backend-sec-prod` | 29 | 2 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; PR 22 FERMÉE, décision du directeur du 11/11 « oui ferme la 22 », remplacée par #365, #338, SEC-AUDIT, KYC-AUDIT et SEC-GARDE-4 ; Durcir et exercer le scanner M2 global (SEC-PROD : snapshot et remédiation). Fichiers principaux : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/SEC_PROD_REMEDIATION.sql. |
| 2026-10-10 | `codex/backend-passation-2026-10-10` | 1 | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Instantané de passation Codex du 10/10 (document). Fichiers principaux : docs/backend/PASSATION-CODEX-2026-10-10.md. |
| 2026-10-10 | `codex/backend-notifications` | 6 | 4 | REMPLACÉ par 355ba7dee (annexe 08/11 ligne 127, relais) | Corriger la transaction de migration des notifications (B-09). Fichiers principaux : lib/core/capacites/notifications_supabase.dart; supabase/tests/scenarios_b09_notifications.sql; test/core/capacites/notifications_supabase_test.dart; supabase/migrations/0063_notifications_privatives.sql. |
| 2026-10-10 | `codex/backend-lota-ledger-provenance` | 3 | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Documenter les limites d'historique des migrations (addendum de réconciliation). Fichiers principaux : docs/backend/RECONCILIATION_MIGRATIONS_ADDENDUM_2026-10-10.md. |
| 2026-10-10 | `codex/backend-lot-f1` | 98 | 22 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; Fusion de la dernière version ccr dans le lot F1 (blueprint, profil élève, lot large). Fichiers principaux : docs/backend/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql. |
| 2026-10-10 | `codex/backend-lot-c-staging-api` | 115 | 26 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Horodatages émis complétés pour les jetons de test SEC-01 (lot large, 115 commits). Fichiers principaux : docs/backend/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql. |
| 2026-10-10 | `codex/backend-lot-a-manifest` | 4 | 1 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Comparer les corps des migrations live pour le lot A (document de réconciliation). Fichiers principaux : docs/backend/RECONCILIATION_MIGRATIONS_BR0B_2026-10-10.md. |
| 2026-10-10 | `codex/backend-f2-b13-admin-rls` | 58 | 20 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; Renvoyer les violations de contrôle pour les ancrages invalides (B-15) ; RLS administrateur. Fichiers principaux : supabase/migrations/0058_assignations_annotations_securisees.sql; lib/core/tc_outils/annotations_supabase.dart; supabase/migrations/0056_student_concern_rpc.sql; supabase/tests/scenarios_b15_assignations_annotations.sql; lib/core/tc_outils/assignations_supabase.dart. |
| 2026-10-10 | `codex/backend-f2-after-c` | 282 | 98 | en cours de tri A/B | garde-cap, 11/11 (relayé par le pilote) : seules ses migrations et ses scénarios restent à examiner ; Scénario de titre enseignant C-04 en CI (très grand lot, 282 commits). Fichiers principaux : docs/backend/PROD_SECURITY_SNAPSHOT_2026-10-10.md; docs/backend/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql. |
| 2026-10-10 | `codex/backend-f1-ccr-port` | 20 | 20 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Utiliser le faux JWT compatible PostgREST dans les tests (F1). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-10 | `codex/backend-f1-ccr-8ea7831` | 2 | 20 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Fusion des instructions ccr courantes dans la branche backend (F1). Fichiers principaux : supabase/migrations/0049_creneau_personnalise_ouvert_au_quota.sql; supabase/migrations/0053_invitations_foyer.sql; supabase/tests/scenarios_offres_personnalisees.sql; supabase/migrations/0054_seance_resumes_famille.sql; supabase/migrations/0050_demandes_horaires_privees_admin.sql. |
| 2026-10-10 | `codex/backend-blueprint` | 5 | 5 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Statut d'exécution BR-0B courant (documents de blueprint). Fichiers principaux : docs/backend/blueprints/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; docs/backend/blueprints/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_1.md; docs/backend/blueprints/REWAYAH_CAP55_PRESENTATION_APP_HANDOFF_CLAUDE_V1.md; docs/backend/blueprints/REWAYAH_COMPLEMENT_IMMATRICULATION_IDENTITES_V0_1.md; docs/backend/blueprints/BR0B_EXECUTION_STATUS_2026-10-10.md. |
| 2026-10-10 | `codex/backend-b20-ccr-8ea7831` | 2 | 6 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Fusion des instructions ccr dans la branche backend (identité d'agent B20). Fichiers principaux : supabase/tests/scenarios_agent_identity.sql; supabase/migrations/0074_agent_identity_account_validity.sql; supabase/migrations/0057_agent_identity_subject.sql; supabase/tests/scenarios_agt01.sql; supabase/tests/stub_auth.sql. |
| 2026-10-10 | `codex/backend-b20-agent-identity` | 7 | 6 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Test : claims JWT PostgREST pour les changements de rôle (identité d'agent). Fichiers principaux : supabase/tests/scenarios_agent_identity.sql; supabase/migrations/0074_agent_identity_account_validity.sql; supabase/migrations/0057_agent_identity_subject.sql; supabase/tests/scenarios_agt01.sql; supabase/tests/stub_auth.sql. |
| 2026-10-10 | `codex/backend-b13-ci-ccr` | 5 | 3 | REMPLACÉ par 4b9980cb6 (annexe 08/11 ligne 126, relais) | Retirer le numéro de migration réservé à F1 (B13). Fichiers principaux : supabase/tests/scenarios_b13_admin_suspended.sql; supabase/migrations/0058_guardian_visit_admin_account_valid.sql; .github/workflows/ci.yml. |
| 2026-10-10 | `codex/backend-b13-ccr-8ea7831` | 3 | 3 | REMPLACÉ par 4b9980cb6 (annexe 08/11 ligne 125, relais) | Fusion des instructions ccr dans la branche B13 (visite du tuteur, compte admin valide). Fichiers principaux : supabase/tests/scenarios_b13_admin_suspended.sql; supabase/migrations/0058_guardian_visit_admin_account_valid.sql; .github/workflows/ci.yml. |
| 2026-10-10 | `codex/backend-b13-admin-suspended` | 3 | 3 | ABSENT de main | CI : scénario B-13 du compte administrateur suspendu. Fichiers principaux : supabase/tests/scenarios_b13_admin_suspended.sql; supabase/migrations/0049_guardian_visit_admin_active_account.sql; .github/workflows/ci.yml. |
| 2026-10-09 | `codex/backend-staging-deploy` | 14 | 16 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Utiliser les secrets de staging et conditionner le déploiement des fonctions staging (CI). Fichiers principaux : docs/claude-handoff/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_2.md; supabase/migrations/0039_budget_observation_repond_sur_la_visite_en_cours.sql; supabase/migrations/0040_tuteur_masque_et_annonce_reservee_a_son_enfant.sql; docs/claude-handoff/REWAYAH_BR0B_CANONICAL_BACKEND_BLUEPRINT_V0_1.md; docs/claude-handoff/REWAYAH_CAP55_PRESENTATION_APP_HANDOFF_CLAUDE_V1.md. |
| 2026-10-09 | `codex/backend-security-null-guards` | 0 | 0 | LIVRÉ (ancêtre de main) | Add negative B-18 role and missing-claim scenarios |
| 2026-10-09 | `codex/backend-security-acl` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(backend): documenter la revue ACL Supabase en lecture seule |
| 2026-10-09 | `codex/backend-migrations-historiques` | 0 | 0 | LIVRÉ (ancêtre de main) | Document restoration provenance for applied migrations 0039-0042 |
| 2026-10-09 | `codex/backend-lot-f2` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(orchestration): STAGING devient l'etape obligatoire avant PROD |
| 2026-10-09 | `codex/backend-lot-c` | 14 | 7 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Vérifier le type de la fonction de session agent (CI, identité d'agent). Fichiers principaux : supabase/tests/scenarios_agent_identity.sql; supabase/migrations/20261009180731_agent_identity_subject.sql; supabase/tests/scenarios_agt01.sql; supabase/tests/stub_storage.sql; .github/workflows/ci.yml. |
| 2026-10-09 | `codex/backend-lot-b` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(orchestration): STAGING devient l'etape obligatoire avant PROD |
| 2026-10-09 | `codex/backend-lot-a` | 0 | 0 | LIVRÉ (ancêtre de main) | Preserve authenticated ACLs when revoking PUBLIC |
| 2026-10-09 | `codex/backend-inventory` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(backend): préciser les sources candidates des migrations historiques |
| 2026-10-09 | `codex/backend-catalogue-classes` | 0 | 0 | LIVRÉ (ancêtre de main) | docs(orchestration): STAGING devient l'etape obligatoire avant PROD |
| 2026-10-08 | `codex/site-public-preview-main` | 1 | 25 | REMPLACÉ par 48f0bde6d (annexe 08/11 ligne 123, relais) | Aperçu du site public en français à côté du web Flutter (documents site-public et workflow). Fichiers principaux : site-public/content/pages.json; site-public/build_site.py; site-public/styles/site.css; site-public/tests/test_build_site_qa.py; .github/workflows/flutter-deploy.yml. |
| 2026-09-15 | `codex/release-all-20260915` | 0 | 0 | LIVRÉ (ancêtre de main) | fix: add local fictional-role demo access |
| 2026-09-13 | `codex/r1-adaptive-design-system` | 1 | 30 | ABANDONNÉ (tri C du garde-cap, 11/11) | documentation ou outillage de Codex dépassé (garde-cap, relayé par le pilote le 11/11) ; Système de design adaptatif R1 (couleurs, élévation, espacements, mouvement, thème). Fichiers principaux : lib/core/theme/app_theme.dart; lib/core/theme/app_palette.dart; lib/features/_dev/galerie/catalogue_galerie.dart; lib/core/widgets/schedule_option.dart; CODEX_FRONTEND_BASELINE.md. |

## Sortie du script (11/11/2026, vrai clone, historique complet)

```
Relevé du 2026-11-11T11:54Z, main = b86dbc9d9
Branches hors de main : 447
  livrées (PR fusionnée)      : 206
  PR non fusionnée            : 75
  commits hors de main sans PR : 166

date	branche	PR	statut	commits hors main
2026-11-11	claude/zealous-tesla-ewstzw	409	PR non fusionnée	77
2026-11-11	claude/transitions-travail	-	sans PR	1
2026-11-11	claude/titulaire-sans-appareil	432	PR non fusionnée	1
2026-11-11	claude/sourates-travail	-	sans PR	3
2026-11-11	claude/sombre-sans-eclair	430	PR non fusionnée	5
2026-11-11	claude/selection-retiree	418	livrée	3
2026-11-11	claude/retirer-absence-detectee	429	PR non fusionnée	2
2026-11-11	claude/proposition-progression-sourates	421	PR non fusionnée	1
2026-11-11	claude/progression-adulte-travail	-	sans PR	5
2026-11-11	claude/profils-p1-travail	-	sans PR	1
2026-11-11	claude/profil-eleve-deja-ouvrir	423	livrée	8
2026-11-11	claude/nav-panneau	413	livrée	7
2026-11-11	claude/nav-liquide	407	livrée	13
2026-11-11	claude/nav-halo-salle	410	livrée	5
2026-11-11	claude/nav-halo-compte	406	livrée	17
2026-11-11	claude/nav-direction	415	livrée	5
2026-11-11	claude/lumiere-vert	428	livrée	7
2026-11-11	claude/lumiere-retard	419	livrée	5
2026-11-11	claude/lumiere-douce	425	livrée	6
2026-11-11	claude/lumiere-accueils-vert	-	sans PR	3
2026-11-11	claude/lumiere-accueils-3-4	414	livrée	6
2026-11-11	claude/lumiere-accueils-1	417	livrée	4
2026-11-11	claude/lumiere-3-absents	424	livrée	7
2026-11-11	claude/liquide-matiere	420	livrée	5
2026-11-11	claude/inventaire-non-branche-1111	427	livrée	2
2026-11-11	claude/halo-lumiere	411	livrée	7
2026-11-11	claude/halo-adulte	412	livrée	2
2026-11-11	claude/goutte-huile	433	PR non fusionnée	3
2026-11-11	claude/fix-clignote-demande	431	PR non fusionnée	1
2026-11-11	claude/entetes-telephone	408	livrée	16
2026-11-11	claude/bande-suite-travail	-	sans PR	11
2026-11-11	claude/bande-barre	426	PR non fusionnée	8
2026-11-11	claude/alertes-bloquees-retard	416	livrée	2
2026-11-11	claude/accueil-chargement	422	livrée	11
2026-11-10	claude/nav-cercle-ressort	405	livrée	10
2026-11-10	claude/nav-cercle-compte	403	livrée	2
2026-11-10	claude/nav-barre-sans-aplat	404	livrée	8
2026-11-10	claude/a-faire-lumiere-accueils	402	livrée	4
2026-11-09	claude/onboarding-tuteur-entree	398	livrée	1
2026-11-09	claude/nav-barre-flottante	401	livrée	5
2026-11-09	claude/mes-classes-details	397	livrée	2
2026-11-09	claude/invitation-accueil	399	livrée	12
2026-11-09	claude/accueil-tuteur-une-porte	400	livrée	1
2026-11-08	claude/tri-pr-avant-25-10	389	livrée	1
2026-11-08	claude/train-g5	332	livrée	237
2026-11-08	claude/train-g4	319	livrée	205
2026-11-08	claude/suppression-toleres	388	livrée	2
2026-11-08	claude/source-commun-reussite	340	livrée	1
2026-11-08	claude/signaler-depuis-salle	364	livrée	8
2026-11-08	claude/scenarios-horloge-sessions	370	livrée	4
2026-11-08	claude/scenarios-cand-com-ma-candidature	360	livrée	1
2026-11-08	claude/rythme-lecture	373	livrée	5
2026-11-08	claude/roster-remplacant	393	livrée	1
2026-11-08	claude/rls-tables-private	338	livrée	1
2026-11-08	claude/revenus-2-main	353	livrée	10
2026-11-08	claude/retour-eclair	354	livrée	4
2026-11-08	claude/reprise-cand-4	396	livrée	5
2026-11-08	claude/reprise-cand-3	392	livrée	3
2026-11-08	claude/reprise-cand-1	390	livrée	7
2026-11-08	claude/recherche-livraison	347	livrée	4
2026-11-08	claude/recherche-fils-comptable	361	livrée	1
2026-11-08	claude/recherche-d2	351	livrée	3
2026-11-08	claude/proposition-harmoniser-argent	337	livrée	3
2026-11-08	claude/projection-eleves	395	livrée	4
2026-11-08	claude/progression-adulte	380	PR non fusionnée	4
2026-11-08	claude/profil-adulte-place	330	PR non fusionnée	3
2026-11-08	claude/prevue-minuscule	384	livrée	3
2026-11-08	claude/preuves-suppression	383	livrée	2
2026-11-08	claude/photo-lecture-courante	358	livrée	1
2026-11-08	claude/photo-foyer	326	PR non fusionnée	4
2026-11-08	claude/photo-figee-main	357	livrée	14
2026-11-08	claude/page-push1-main	355	livrée	1
2026-11-08	claude/notifs-l6-horloge	334	livrée	1
2026-11-08	claude/notif-retenu	339	livrée	5
2026-11-08	claude/notif-defaut	328	PR non fusionnée	202
2026-11-08	claude/noms-classes	350	livrée	13
2026-11-08	claude/nom-latin-candidat	391	livrée	3
2026-11-08	claude/nb-observations-classe	348	livrée	4
2026-11-08	claude/mon-espace-guide	375	livrée	6
2026-11-08	claude/mesure-lecture	371	livrée	6
2026-11-08	claude/ma-progression-fiche	381	livrée	4
2026-11-08	claude/ma-progression	382	PR non fusionnée	3
2026-11-08	claude/inventaire-non-livres	345	livrée	6
2026-11-08	claude/hygiene-gardes	372	livrée	10
2026-11-08	claude/hygiene-2	374	livrée	7
2026-11-08	claude/horloge-2	394	livrée	1
2026-11-08	claude/harmonisation-a	329	PR non fusionnée	2
2026-11-08	claude/garde-versements	368	livrée	6
2026-11-08	claude/garde-compte-desactive	365	livrée	7
2026-11-08	claude/garde-cap-reservations-0811d	362	livrée	1
2026-11-08	claude/garde-cap-reservations-0811c	356	livrée	7
2026-11-08	claude/garde-cap-reservations-0811b	352	livrée	5
2026-11-08	claude/garde-cap-reservations-0811	346	livrée	3
2026-11-08	claude/garde-cap-registre-0811f	386	livrée	1
2026-11-08	claude/garde-cap-registre-0811e	379	livrée	2
2026-11-08	claude/garde-cap-registre-0811	333	livrée	3
2026-11-08	claude/garde-cap-nuit-0711	323	PR non fusionnée	9
2026-11-08	claude/frise-heure-serveur	369	livrée	6
2026-11-08	claude/frise-heure-murale-client	385	livrée	1
2026-11-08	claude/frise-heure-client	363	livrée	4
2026-11-08	claude/formule-vitesse-unique	378	livrée	9
2026-11-08	claude/fn025-horloge	367	livrée	1
2026-11-08	claude/fluidite-reglages-foyer	343	livrée	1
2026-11-08	claude/fluidite-foyer	341	livrée	1
2026-11-08	claude/fluidite-2-main	349	livrée	3
2026-11-08	claude/fluidite-1-g4	327	PR non fusionnée	202
2026-11-08	claude/fix-mdp-enfant	331	livrée	1
2026-11-08	claude/fiche-eleve-salle	376	livrée	4
2026-11-08	claude/d2-retrait-profil	342	livrée	1
2026-11-08	claude/curseur-clic	387	livrée	1
2026-11-08	claude/classe-minuscule-main	359	livrée	1
2026-11-08	claude/champ-obligatoire-2	344	livrée	6
2026-11-08	claude/champ-obligatoire	336	livrée	5
2026-11-08	claude/cahier-c3-sans-tx	335	livrée	1
2026-11-07	rewayahacademy-glitch-patch-13	265	PR non fusionnée	6
2026-11-07	claude/vigilant-pascal-utfgbs	314	PR non fusionnée	29
2026-11-07	claude/train-g3	315	livrée	78
2026-11-07	claude/train-g2	307	livrée	20
2026-11-07	claude/suivi-eleve	287	PR non fusionnée	10
2026-11-07	claude/selection-texte	293	PR non fusionnée	8
2026-11-07	claude/sans-barre-fixe	305	PR non fusionnée	8
2026-11-07	claude/salle2-entretien	301	PR non fusionnée	20
2026-11-07	claude/salle-3-accueil	300	PR non fusionnée	9
2026-11-07	claude/salle-1-tout-ici	298	PR non fusionnée	6
2026-11-07	claude/salle-1-suite	312	PR non fusionnée	118
2026-11-07	claude/revenus	-	sans PR	3
2026-11-07	claude/remplacement-temps-reel	310	PR non fusionnée	7
2026-11-07	claude/push-textes	308	PR non fusionnée	1
2026-11-07	claude/push-1	284	livrée	9
2026-11-07	claude/purge-cron	316	PR non fusionnée	1
2026-11-07	claude/piece-avant-envoi	292	PR non fusionnée	2
2026-11-07	claude/photo-candidature-figee	-	sans PR	2
2026-11-07	claude/perf-index-session-events	318	PR non fusionnée	1
2026-11-07	claude/perf-fuseaux	325	PR non fusionnée	1
2026-11-07	claude/perf-enseignants-public	324	PR non fusionnée	1
2026-11-07	claude/page-salle3	-	sans PR	3
2026-11-07	claude/page-push1	-	sans PR	2
2026-11-07	claude/nouveautes	285	PR non fusionnée	9
2026-11-07	claude/methode-pilote-garde	322	PR non fusionnée	1
2026-11-07	claude/mesure-fluidite-selection	-	sans PR	1
2026-11-07	claude/messages-candidat	304	PR non fusionnée	6
2026-11-07	claude/invitations-personnelles	311	PR non fusionnée	5
2026-11-07	claude/invitation-second-adulte	275	PR non fusionnée	6
2026-11-07	claude/harmoniser-argent	-	sans PR	1
2026-11-07	claude/harmonisation-e	321	PR non fusionnée	121
2026-11-07	claude/fluidite-2	-	sans PR	9
2026-11-07	claude/fluidite-1-bouton	320	PR non fusionnée	14
2026-11-07	claude/fluidite-1	295	PR non fusionnée	6
2026-11-07	claude/etat-dossier-photo	317	PR non fusionnée	1
2026-11-07	claude/dettes-ui	279	PR non fusionnée	4
2026-11-07	claude/ci-propose	-	sans PR	3
2026-11-07	claude/cand-photo	-	sans PR	2
2026-11-07	claude/cahiers-par-seance	276	PR non fusionnée	5
2026-11-07	claude/cadre-migrations	294	livrée	5
2026-11-07	claude/cadre-langues	313	PR non fusionnée	2
2026-11-07	claude/cadre-ecran	296	PR non fusionnée	9
2026-11-07	claude/brouillon-persistant	281	PR non fusionnée	6
2026-11-07	claude/bouton-attente	286	PR non fusionnée	7
2026-11-07	claude/admiring-brown-r6ai72	-	sans PR	9
2026-11-07	claude/accords-lisez-bas	-	sans PR	32
2026-11-06	claude/classe-minuscule	-	sans PR	4
2026-11-05	train/2026-11-06-photos	244	PR non fusionnée	2
2026-11-04	train/2026-11-04	-	sans PR	1
2026-11-04	claude/v2a-bis-personne-occupee	223	livrée	3
2026-11-04	claude/regle-trains-p5	228	livrée	2
2026-11-04	claude/photos-2b	225	livrée	10
2026-11-04	claude/photos-2a	212	livrée	5
2026-11-04	claude/p5-pousser-peu	233	livrée	2
2026-11-04	claude/mfa-direction	211	livrée	6
2026-11-04	claude/garde-profil	236	livrée	1
2026-11-04	claude/fuseaux-serveur	214	livrée	1
2026-11-04	claude/demo-suppr-p	232	livrée	1
2026-11-04	claude/demo-prod	230	livrée	3
2026-11-04	claude/connexion-align	229	livrée	9
2026-11-04	claude/chargement-bis	224	livrée	2
2026-11-03	claude/v1b-creneaux	208	livrée	2
2026-11-03	claude/v1a-bis-super-admin	205	livrée	2
2026-11-03	claude/v1-entretiens	189	livrée	4
2026-11-03	claude/ux-046-questionnaire	151	livrée	2
2026-11-03	claude/txt-1-textes	158	livrée	3
2026-11-03	claude/supprimer-serveur	198	livrée	2
2026-11-03	claude/supprimer-bis	201	livrée	1
2026-11-03	claude/snt-ecrans	171	livrée	3
2026-11-03	claude/snt	170	livrée	2
2026-11-03	claude/scenarios-enchaines	190	livrée	2
2026-11-03	claude/salle3-prets-serveur	197	livrée	1
2026-11-03	claude/remb-14	157	livrée	5
2026-11-03	claude/rejeu-e2e	178	livrée	9
2026-11-03	claude/recharge-carte	181	livrée	5
2026-11-03	claude/recharge-1	161	livrée	2
2026-11-03	claude/rang19-scenarios-a	186	livrée	2
2026-11-03	claude/rang14-trois-salles	191	livrée	1
2026-11-03	claude/preuve-rouge-ci	159	PR non fusionnée	1
2026-11-03	claude/photos-serveur	180	livrée	2
2026-11-03	claude/photos-ecrans	-	sans PR	4
2026-11-03	claude/pay-ux	153	livrée	8
2026-11-03	claude/onboarding-fin-sauvegarde	-	sans PR	1
2026-11-03	claude/o1-ouvrir-observation	169	livrée	1
2026-11-03	claude/o1-observation	152	livrée	7
2026-11-03	claude/niv1-reprise-profils	175	livrée	3
2026-11-03	claude/niv1-niveau-une-fois	172	livrée	8
2026-11-03	claude/n4-serveur	194	livrée	1
2026-11-03	claude/n4-r2-octets	196	livrée	1
2026-11-03	claude/n4-ecrans	207	livrée	5
2026-11-03	claude/n3-s2-pause	202	livrée	6
2026-11-03	claude/n3-d3-mission	199	livrée	4
2026-11-03	claude/n2-foyer-adulte	165	livrée	7
2026-11-03	claude/m1-suppr-doublons	204	livrée	6
2026-11-03	claude/m1-modules-en-double	184	livrée	2
2026-11-03	claude/fn-serveur	183	livrée	1
2026-11-03	claude/fn-divers-serveur	195	livrée	2
2026-11-03	claude/deploy-sans-lib	185	livrée	2
2026-11-03	claude/defil-feuille	177	livrée	2
2026-11-03	claude/d1ter-famille-lit-transmis	174	livrée	11
2026-11-03	claude/d1bis-vue-lecture-seule	173	livrée	3
2026-11-03	claude/d1-bis-signalement	164	livrée	7
2026-11-03	claude/courriels-ux	192	livrée	2
2026-11-03	claude/ci-scenarios-03-11	-	sans PR	1
2026-11-03	claude/anti-robot-ecrans	209	livrée	7
2026-11-03	claude/anti-robot	206	livrée	1
2026-11-03	claude/adm-ux-bis	179	livrée	2
2026-11-03	claude/adm-ux	167	livrée	2
2026-11-03	claude/a3-bis-remplacement	156	livrée	6
2026-11-02	claude/ux-047-accords	148	livrée	3
2026-11-02	claude/regles-remplacement	128	livrée	8
2026-11-02	claude/regles-quatre-agents	140	livrée	4
2026-11-02	claude/notifs-l6-reprise	138	livrée	4
2026-11-02	claude/notifs-l6	137	livrée	5
2026-11-02	claude/n1-communications	147	livrée	7
2026-11-02	claude/l5-listes-dossiers	133	livrée	1
2026-11-02	claude/l4-listes-traitement	132	livrée	3
2026-11-02	claude/l3-listes-regroupements	129	livrée	3
2026-11-02	claude/inscription-3	135	livrée	2
2026-11-02	claude/i1-invitations	145	livrée	10
2026-11-02	claude/fn115b-remboursements-serveur	131	livrée	12
2026-11-02	claude/fn115a-conditions-remboursement	130	livrée	2
2026-11-02	claude/fn-115c-ecran	143	livrée	5
2026-11-02	claude/fn-115c	142	livrée	1
2026-11-02	claude/fn-109	144	livrée	1
2026-11-02	claude/etat-ouverture-0211	134	livrée	4
2026-11-02	claude/c1-classes	150	livrée	8
2026-11-02	claude/b-acces-paye	136	livrée	4
2026-11-02	claude/a-tarifs-particuliers	139	livrée	12
2026-11-01	mots-genre-2026-11-01	112	livrée	1
2026-11-01	claude/salle-acces-perdu	124	livrée	7
2026-11-01	claude/regle-defilement	119	livrée	1
2026-11-01	claude/parcours-ouverture	105	livrée	20
2026-11-01	claude/paiement-dans-app	120	livrée	9
2026-11-01	claude/l2-listes-comptes	126	livrée	4
2026-11-01	claude/fn114a-courriel-defaut	121	livrée	5
2026-11-01	claude/fn113-plafond	122	livrée	11
2026-11-01	claude/fin-seance-motif	117	livrée	4
2026-11-01	claude/fin-seance-chrono	113	livrée	4
2026-11-01	claude/fin-seance-avis	118	livrée	3
2026-11-01	claude/etat-ouverture-lots	115	livrée	2
2026-11-01	claude/e2e-verifier-branchement	114	livrée	3
2026-11-01	claude/e2e-parcours-ouverture	107	livrée	52
2026-11-01	claude/decision-push	111	livrée	2
2026-11-01	claude/decision-courriel	110	livrée	4
2026-11-01	claude/decision-branchement	109	livrée	2
2026-11-01	claude/chargement-differe-bloque	123	livrée	5
2026-11-01	claude/adulte-rechargement	127	livrée	3
2026-11-01	claude/adulte-accueil-apres-acceptation	125	livrée	2
2026-11-01	claude/admiring-brown-r6ai72-paiement-recu	116	livrée	3
2026-10-31	claude/tri-quatre-roles	101	livrée	4
2026-10-31	claude/seance-ouverte-jeton	100	livrée	6
2026-10-31	claude/seance-arriere-plan	94	livrée	3
2026-10-31	claude/remplacement-auto	98	livrée	7
2026-10-31	claude/reaffecter-classe	104	livrée	3
2026-10-31	claude/presence-minutes	102	livrée	3
2026-10-31	claude/paie-remplacant	93	livrée	2
2026-10-31	claude/finir-remplacement	96	livrée	2
2026-10-31	claude/eleve-adulte	99	livrée	3
2026-10-31	claude/decisions-31-10	97	livrée	1
2026-10-31	claude/cahier-remplacant	108	livrée	2
2026-10-31	claude/cahier-hebdomadaire	103	livrée	3
2026-10-31	claude/cahier-exception-presence	106	livrée	1
2026-10-30	rewayahacademy-glitch-patch-5	-	sans PR	1
2026-10-28	claude/admiring-brown-r6ai72-audit	-	sans PR	3
2026-10-27	claude/admiring-brown-r6ai72-surface	-	sans PR	2
2026-10-27	claude/admiring-brown-r6ai72-fiche-0	-	sans PR	2
2026-10-27	claude/admiring-brown-r6ai72-admission	-	sans PR	1
2026-10-26	rewayahacademy-glitch-patch-2	-	sans PR	1
2026-10-26	rewayahacademy-glitch-patch-1	-	sans PR	1
2026-10-26	claude/admiring-brown-r6ai72-passation-2	-	sans PR	1
2026-10-25	claude/admiring-brown-r6ai72-relais	-	sans PR	12
2026-10-25	claude/admiring-brown-r6ai72-passation	-	sans PR	1
2026-10-24	claude/lucid-mccarthy-qpk6yq	45,50	PR non fusionnée	17
2026-10-19	claude/jolly-gauss-7rlt4y	42	PR non fusionnée	1
2026-10-17	claude/sharp-goldberg-z10a13	40	PR non fusionnée	7
2026-10-13	codex/journal	-	sans PR	10
2026-10-13	codex/backend-c29-versioned-quota	-	sans PR	1
2026-10-13	codex/backend-c21-negative-context-r1	-	sans PR	1
2026-10-13	codex/backend-c04-negative-context-r1	-	sans PR	1
2026-10-13	codex/backend-b09-notifications-sources	-	sans PR	1
2026-10-13	claude/beautiful-ptolemy-xmhiki	34	PR non fusionnée	4
2026-10-13	archive/pc-2026-10-13/patchs	-	sans PR	2
2026-10-13	archive/pc-2026-10-13/codex/proof-f70-ccr-merge	-	sans PR	1
2026-10-12	codex2/x2-18	-	sans PR	12
2026-10-12	codex2/imm-back-1-wip	-	sans PR	1
2026-10-12	codex2/imm-back-1	-	sans PR	1
2026-10-12	codex2/imm-accueil-back-phase2-wip	-	sans PR	1
2026-10-12	codex/deleg-fin-1-serveur	-	sans PR	7
2026-10-12	codex/com-back-1-wip	-	sans PR	2
2026-10-12	codex/backend-sec-prod-27-invoker	-	sans PR	2
2026-10-12	codex/backend-rech-d3-enseignants	-	sans PR	5
2026-10-12	codex/backend-kyc-lecture-1	-	sans PR	2
2026-10-12	codex/backend-f86-titulaire-profile-create-guard	-	sans PR	1
2026-10-12	codex/backend-f86-teacher-profile-guard	-	sans PR	1
2026-10-12	codex/backend-f86-pairing-code-guard	-	sans PR	1
2026-10-12	codex/backend-f86-null-safe-review-fixes	-	sans PR	4
2026-10-12	codex/backend-f86-null-safe	-	sans PR	2
2026-10-12	codex/backend-f86-b18-negative-cases	-	sans PR	2
2026-10-12	codex/backend-f86-archive-retention-guard	-	sans PR	1
2026-10-12	codex/backend-f86-archive-listen-guard	-	sans PR	1
2026-10-12	codex/backend-f86-admin-group-mutator-guards	-	sans PR	2
2026-10-12	codex/backend-f70-review-fixes	-	sans PR	34
2026-10-12	codex/backend-ea-role-br	-	sans PR	2
2026-10-12	codex/backend-cap29-review-fixes	-	sans PR	1
2026-10-12	codex/backend-cap29-back-2	-	sans PR	5
2026-10-12	codex/backend-c29-port-wiring	-	sans PR	1
2026-10-12	codex/backend-c29-f86-hashes	-	sans PR	1
2026-10-12	codex/backend-c22-presentation-adapter-safe	-	sans PR	1
2026-10-12	codex/backend-c11bis-f74-canon	-	sans PR	1
2026-10-12	codex/backend-b09-notifs	-	sans PR	3
2026-10-12	codex/backend-b09-events-destinations-r2	-	sans PR	1
2026-10-11	codex2/x2-19	-	sans PR	5
2026-10-11	codex2/x2-13	-	sans PR	2
2026-10-11	codex2/x2-12	-	sans PR	2
2026-10-11	codex2/x2-11	-	sans PR	1
2026-10-11	codex2/x2-10	-	sans PR	2
2026-10-11	codex2/x2-09	-	sans PR	3
2026-10-11	codex2/x2-08	-	sans PR	3
2026-10-11	codex2/x2-07	-	sans PR	5
2026-10-11	codex2/x2-06	-	sans PR	2
2026-10-11	codex2/x2-05	-	sans PR	9
2026-10-11	codex2/x2-04	-	sans PR	5
2026-10-11	codex2/x2-03	-	sans PR	4
2026-10-11	codex2/x2-02	-	sans PR	25
2026-10-11	codex2/x2-01	-	sans PR	2
2026-10-11	codex/backend-sec-prod-m2-fixes	-	sans PR	17
2026-10-11	codex/backend-sec-prod-allowlist	-	sans PR	30
2026-10-11	codex/backend-rls-disabled	-	sans PR	1
2026-10-11	codex/backend-recherche-classes	-	sans PR	1
2026-10-11	codex/backend-offres-adapters	-	sans PR	15
2026-10-11	codex/backend-foyer-ports	-	sans PR	15
2026-10-11	codex/backend-f79-allowlist	-	sans PR	4
2026-10-11	codex/backend-f70-status-tests	-	sans PR	1
2026-10-11	codex/backend-f70-contract-publication	-	sans PR	25
2026-10-11	codex/backend-f69-super-admin-controls	-	sans PR	2
2026-10-11	codex/backend-f69-k65	-	sans PR	1
2026-10-11	codex/backend-contract-signature-continuation	-	sans PR	21
2026-10-11	codex/backend-contract-signature	-	sans PR	1
2026-10-11	codex/backend-cap29-version-integrity	-	sans PR	27
2026-10-11	codex/backend-cap29-library-visibility	-	sans PR	30
2026-10-11	codex/backend-cap29-catalogue	-	sans PR	4
2026-10-11	codex/backend-c29-tirage	-	sans PR	4
2026-10-11	codex/backend-c25-regroupements	-	sans PR	1
2026-10-11	codex/backend-c23-reprise-adapter	-	sans PR	4
2026-10-11	codex/backend-c22-hardening	-	sans PR	1
2026-10-11	codex/backend-c22-canon-adapter	-	sans PR	3
2026-10-11	codex/backend-c22-age-presentation	-	sans PR	287
2026-10-11	codex/backend-c21-kyc-verdict	-	sans PR	15
2026-10-11	codex/backend-c21-kyc-access-adapter	-	sans PR	19
2026-10-11	codex/backend-c17-signature-status	-	sans PR	27
2026-10-11	codex/backend-b18-ci-state	-	sans PR	1
2026-10-11	codex/backend-b12-f84-ccr	-	sans PR	1
2026-10-11	codex/backend-b09-notifications	-	sans PR	8
2026-10-11	codex/backend-b09-f1-producers	-	sans PR	25
2026-10-11	codex/backend-b09-adaptateur	-	sans PR	1
2026-10-11	codex/backend-b04-reprise	-	sans PR	3
2026-10-11	codex/backend-b03-b12	-	sans PR	1
2026-10-11	codex/backend-al01-05-f86	-	sans PR	3
2026-10-11	codex/backend-adult-kyc-contract	-	sans PR	15
2026-10-11	codex/backend-a81-f86	-	sans PR	1
2026-10-11	codex/backend-a81-f69-hardening	-	sans PR	17
2026-10-11	codex/backend-a81-c24-adapter	-	sans PR	1
2026-10-11	claude/revue-backend-codex-1	-	sans PR	2
2026-10-11	claude/mushaf-15l-captures	-	sans PR	1
2026-10-11	claude/f86-manifeste	-	sans PR	3
2026-10-11	claude/compta-recon	-	sans PR	1
2026-10-11	claude/catalogue-canon-fixes	-	sans PR	1
2026-10-11	claude/br1-branchement	-	sans PR	2
2026-10-11	archive/pc-2026-10-13/codex/backend-c23-reprise	-	sans PR	5
2026-10-11	archive/pc-2026-10-13/codex/backend-c11bis	-	sans PR	45
2026-10-10	ui/brand-logo-2026	-	sans PR	1
2026-10-10	docs/specs-entrantes-2026-10-10	-	sans PR	1
2026-10-10	codex/backend-staging-preview-secrets	26	PR non fusionnée	2
2026-10-10	codex/backend-sec-prod	22	PR non fusionnée	29
2026-10-10	codex/backend-passation-2026-10-10	-	sans PR	1
2026-10-10	codex/backend-notifications	-	sans PR	6
2026-10-10	codex/backend-lota-ledger-provenance	32	PR non fusionnée	3
2026-10-10	codex/backend-lot-f1	13,19	PR non fusionnée	98
2026-10-10	codex/backend-lot-c-staging-api	20	PR non fusionnée	115
2026-10-10	codex/backend-lot-a-manifest	25	PR non fusionnée	4
2026-10-10	codex/backend-f2-b13-admin-rls	17	PR non fusionnée	58
2026-10-10	codex/backend-f2-after-c	21	PR non fusionnée	282
2026-10-10	codex/backend-f1-ccr-port	-	sans PR	20
2026-10-10	codex/backend-f1-ccr-8ea7831	29,33	PR non fusionnée	2
2026-10-10	codex/backend-blueprint	24	PR non fusionnée	5
2026-10-10	codex/backend-b20-ccr-8ea7831	30	PR non fusionnée	2
2026-10-10	codex/backend-b20-agent-identity	28	PR non fusionnée	7
2026-10-10	codex/backend-b13-ci-ccr	27	PR non fusionnée	5
2026-10-10	codex/backend-b13-ccr-8ea7831	31	PR non fusionnée	3
2026-10-10	codex/backend-b13-admin-suspended	23	PR non fusionnée	3
2026-10-10	claude/wizardly-babbage-lmhkog	-	sans PR	2
2026-10-10	claude/com-suite	-	sans PR	3
2026-10-09	revues/2026-10-04-b061fd81	-	sans PR	14
2026-10-09	pilotage/tuteur-v1	-	sans PR	341
2026-10-09	codex/backend-staging-deploy	-	sans PR	14
2026-10-09	codex/backend-lot-c	10	PR non fusionnée	14
2026-10-08	codex/site-public-preview-main	8	PR non fusionnée	1
2026-10-05	juridique/licence-code	-	sans PR	4
2026-10-04	revues/2026-10-04-01MrLWqB	-	sans PR	4
2026-10-04	projet/ressources	-	sans PR	16
2026-10-04	corrections/c2-ea-coran	-	sans PR	3
2026-10-04	claude/collaborative-task-tracking-r47ieu	-	sans PR	11
2026-10-04	ccr-a2ce253e-vnv87y	-	sans PR	1
2026-09-28	ui/essai-ci-d2	7	PR non fusionnée	1
2026-09-28	claude/modest-hopper-hj96t5	7	PR non fusionnée	1
2026-09-28	claude/essai-ci-d2	6	PR non fusionnée	2
2026-09-27	claude/confident-mayer-m2fqsl	5	PR non fusionnée	2
2026-09-27	archive/pc-2026-10-13/adrc/m4	-	sans PR	1
2026-09-27	archive/pc-2026-10-13/adrc/m3	-	sans PR	1
2026-09-27	archive/pc-2026-10-13/adrc/m1	-	sans PR	1
2026-09-26	ui/tuteur-v1-t	-	sans PR	35
2026-09-26	reserve/theme-monochrome-k36	-	sans PR	34
2026-09-23	v0/verite-produit	-	sans PR	1
2026-09-23	nettoyage/base-2026-09-23	-	sans PR	2
2026-09-23	archive/pc-2026-10-13/integration/core24-classes-v2-remediation	-	sans PR	15
2026-09-22	lot/onboarding-offres	-	sans PR	1
2026-09-22	core24/fable-frontend	-	sans PR	2
2026-09-22	archive/pc-2026-10-13/integration/core24-classes-v2	-	sans PR	10
2026-09-22	archive/pc-2026-10-13/docs/core24-classes-arbitration	-	sans PR	2
2026-09-22	archive/pc-2026-10-13/astra/core24-v2	-	sans PR	17
2026-09-22	archive/pc-2026-10-13/astra/core24-presence-safeguard	-	sans PR	18
2026-09-22	archive/pc-2026-10-13/astra/core24-classes-legacy-snapshot	-	sans PR	19
2026-09-21	observation/lot-2026-09-21	-	sans PR	11
2026-09-21	archive/pc-2026-10-13/sauvegarde/r2-du-tiers	-	sans PR	1
2026-09-20	teaching-core/0-coordinateur	-	sans PR	2
2026-09-15	archive/pc-2026-10-13/codex/vague5-integration	-	sans PR	7
2026-09-15	archive/pc-2026-10-13/codex/presence-correction-ui	-	sans PR	1
2026-09-15	archive/pc-2026-10-13/codex/login-demo	-	sans PR	1
2026-09-14	archive/pc-2026-10-13/codex/r2-adaptive-shell	-	sans PR	4
2026-09-13	codex/r1-adaptive-design-system	-	sans PR	1
2026-09-09	specs	-	sans PR	1
2026-09-09	refactor-ui-lavender-3628477128789856989	1	PR non fusionnée	3
```
