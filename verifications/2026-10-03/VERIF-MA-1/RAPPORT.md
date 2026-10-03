# VERIF-MA-1 : Mode Accessibilité, début de vague (MA-0 à MA-7)

Session 90248232, 03/10/2026, lecture seule (aucun commit de code). Branche `ui/accessibilite-v1` @ `7885b35` (contient `669ec05`), worktree détaché `D:\RA_TUTEUR\v-ma1` (`git rev-parse HEAD` = `7885b35b921e1d5c0203aebfb10376ab6b6c01f6`, `git status --short` vide, en tête de `analyze_reprise.log`). Les commits de chaque étape (`ecf2448`, `2442829`, `1ad9d03`, `79c4fe6`, `447f945`, `86d750d`, `f578d55`, `6edcd6e`, `ce918f2`, `e8d0dfc`, `669ec05`) sont tous ancêtres de `7885b35` (`git merge-base --is-ancestor`, code 0).

Rapport repris le 03/10 après les objections d'un contradicteur indépendant : voir la dernière section, « Reprise après contradiction ».

## Verdict : VÉRIFIÉ AVEC DÉFAUTS

Les promesses des neuf étapes sont tenues au commit vérifié, et les 3 majeurs de MA-7 restent corrigés. Mais six décisions définitives du directeur du 27/09, écrites sur les fiches MA-3 à MA-7, ne sont pas appliquées dans le code : A3, A4, A5, A6, A7 et A8 (tableau « Décisions du directeur » plus bas). Un majeur de la revue cloud de MA-3 (les cinq états de l'Accueil) est toujours ouvert. Il est déjà porté par l'étape DASH-MA-PROD, à faire.

La cause n'est pas seulement la chronologie. A3, A5, A6 et A7 ont bien été décidées après les commits de leurs étapes (décisions du 27/09 entre 16 h 49 et 16 h 51 UTC, commits entre 11 h 03 et 14 h 16 en +0300). Mais le travail du 02/10 a réécrit ou ajouté des textes visés par A4 et A8 sans appliquer ces décisions (`6686f9a`, `e23babd`, voir plus bas).

Trois étapes nouvelles sont proposées, toutes de gravité moyenne. Deux constats vont à des étapes déjà ouvertes (DASH-MA-PROD, TB-3).

## Verrou

| Commande | Résultat |
|---|---|
| `flutter pub get` | OK, « Got dependencies! » (`pubget.log`) |
| `dart analyze --fatal-infos lib test tool` (premier passage) | **No issues found!** (`analyze.log`, sans en-tête) |
| `(cd & git rev-parse HEAD & git status --short & dart analyze --fatal-infos lib test tool)` (reprise, dernier passage) | En tête : `D:\RA_TUTEUR\v-ma1`, `7885b35b921e1d5c0203aebfb10376ab6b6c01f6`, aucune ligne de `git status`. **No issues found!** Verrou : code 0, 252 s (`analyze_reprise.log`) |
| `flutter test test/core/accessibilite test/router/navigation_test.dart test/features/classe_eleve/preparation_eleve_test.dart` (sans CAPTURE_DIR) | **+149, ~13 ignorés, All tests passed!** Code 0 (`tests_ma1.log`). Les 13 tests ignorés sont tous des captures (« CAPTURE_DIR absent »). Fichiers exécutés : `navigation_ma2`, `accueil_ma3`, `ma_classe_ma4`, `salle_ma5`, `apres_ma6`, `coran_ma7`, `mode_accessibilite`, `mon_espace_ma8` |
| `(cd & git rev-parse HEAD & git status --short & flutter test test/core/accessibilite/coran_ma7_test.dart --reporter expanded)` (reprise, dernier passage, sans CAPTURE_DIR) | En tête : `D:\RA_TUTEUR\v-ma1`, `7885b35b…`, `git status` vide. **+17, All tests passed!** Verrou : code 0, 44 s (`coran_ma7_reprise.log`). Le `flutter test` refait la résolution des dépendances et modifie de nouveau les 3 fichiers générés de `windows/flutter/` : remis à l'état du commit (`git checkout --`), `git status` vide ensuite |
| `captures_ma_test.dart --name MA-[3457]` avec `CAPTURE_DIR=D:\RA_TUTEUR\captures_VERIF-MA-1` | **+41, All tests passed!** (`captures.log`) ; 56 PNG produits |

Le `pub get` a modifié 3 fichiers générés de `windows/flutter/`. Ils ont été remis à l'état du commit (`git checkout --`), et `git status` est vide (confirmé de nouveau à la reprise, en tête de `analyze_reprise.log`).

## Rendu du Coran intact

`git diff --stat 1108a4a..7885b35 -- lib/features/tc_mushaf lib/core/tc_coran lib/core/coran` : vide. Aucun asset Coran ou police dans `git diff --stat 1108a4a..7885b35 -- assets`. `669ec05` ne touche que 7 fichiers d'enrobage (i18n, `coran_accessibilite.dart`, `demo_accessibilite_page.dart`, deux tests).

## Les 3 majeurs de MA-7 (revue cloud du 27/09, fiche MA-7) : toujours corrigés à `7885b35`

| Majeur | Correctif | Constat à `7885b35` |
|---|---|---|
| (1) « Page précédente / Page suivante » coupés en plein mot à 390 | `669ec05` : `ActionPrincipale` fléchées, jamais coupées | Remplacé ensuite par MA-CMD-1 (décision du directeur du 02/10 : flèches sans texte). `coran_accessibilite.dart:417-452` : `_BoutonIcone` avec icônes `AppIcons.retour` / `flecheAction` (`matchTextDirection: true`, `app_icons.dart:383-410`). Le nom est lu par le lecteur d'écran et repris en infobulle (`:657-663`). Aucun texte visible, donc aucun mot coupé. Garde : `coran_ma7_test.dart:568-593` (une icône, aucun `Text`, au moins 48 × 48, libellé sémantique « Page précédente » / « Page suivante »), vert |
| (2) Commandes sous la ligne de flottaison (plancher 1100 × facteur) | `669ec05` : `_hauteurPlancher = 1100` supprimé | Aucun « 1100 » dans `coran_accessibilite.dart`. Commandes en bas dans `CommandesMasquables` (`:472-483`). Garde : `coran_ma7_test.dart:507-566` (390 et 1440 à ×1 sans défilement, 390 à ×2 atteignable), vert. Captures : `ma7_coran_lecteur_mariam_390_light.png` et `_1440_light.png`, commandes visibles en bas |
| (3) Démonstration : faux motif réseau et « Réessayer » qui ne peut pas aboutir | `669ec05` : `_demonstrationSansTexte` | `coran_accessibilite.dart:170-203` : `EmptyState` sans bouton, avec la vraie cause (`fr.i18n.json:638-640`). Garde : `coran_ma7_test.dart:151-159` (`indisponibleDetail` et `reessayer` absents), vert. Capture `ma7_coran_demo_sans_texte_lecteur_idriss_390_light.png` |

## Point par point (fiche de chaque étape)

| Étape | Promesse (fiche) | Commit | Constat avec fichier:ligne |
|---|---|---|---|
| MA-0 | Pilotage `15_accessibilite/` (00_REPRISE, 02_DECOUPAGE, V/) ; règles MA1 à MA24 | pilotage `8ed739e4`, ressources `d2a86d5c` | Les fichiers existent (00_REPRISE 4,4 ko, 02_DECOUPAGE 13 ko, `V/00_MAQUETTES_ACCESSIBILITE.md`, 4 planches). `projet/ressources:memoire/ACCESSIBILITE-2026-09-27.md` contient MA1 à MA24 (24 règles comptées) |
| MA-1a | UX_REVIEW_06 : 18 lignes (2 gardées, 16 adaptées), sources datées, 3 réglages sans effet, 3 lignes TH-2 | pilotage `b8d2e9b9` | `UX_REVIEW_06_ACCESSIBILITE.md` : 18 lignes (l. 74-91), table des sources (l. 25-45), V1 « Non » (l. 51-59), TH-2 (l. 105-109), synthèse 2 / 16 / 0 (l. 113). Les réglages relevés sont branchés depuis : `animationsReduites` (`mode_accessibilite.dart:93-95,152`, `app.dart:76-91`), `lectureGrande` (`coran_accessibilite.dart:137-140`), `effetsReduits` masqué en Mode Accessibilité (`compte_page.dart:296`) |
| MA-1b | Fournisseur unique sur `InterfaceMode`, mouvement réduit (préférence, système, iOS), `/demo/accessibilite` gardée | `ecf2448` | `modeAccessibiliteActifProvider` (`mode_accessibilite.dart:83`) ; `reduit = systeme \|\| reduceMotion \|\| preference` posé une fois sous `MaterialApp.builder` (`app.dart:76-91`, `ReglageMouvement`) ; route gardée par `environnementAutoriseDemo` (`demo_accessibilite_page.dart:54-55`, `redirection.dart:50-58`) ; `mode_accessibilite_test` vert |
| MA-2 | 4 destinations dans les deux présentations, routes inchangées | `2442829` | `nav_shell.dart:91-115` (Accueil, Ma classe → `/eleve/suivi`, Coran, Mon espace → `/compte`) ; `navigation_ma2_test` et `navigation_test` verts |
| MA-3 | Accueil dans l'ordre du doc §5, un seul bouton, initiales, tutoiement selon l'âge | `1ad9d03`, `79c4fe6` | Captures 390 et 1440 : salutation, Prochaine séance, un seul bouton « Voir ma classe », 3 tâches, Coran, aide en dernier, deux colonnes à 1440 ; « Ton heure » (Mariam) / « Votre heure » (Idriss) ; `accueil_ma3_test` vert. **A3 non appliquée** (MA-DEC-1). **Majeur de la revue cloud toujours ouvert** : l'Accueil n'a ni chargement, ni erreur, ni hors ligne, ni vide (voir « Relevés de la revue cloud ») |
| MA-4 | Titre « Ma classe », identité en pile à 200 %, « An‑Nour » insécable, Mon suivi atteignable, tutoiement | `447f945` | Capture 200 % : identité en pile, « Classe / An-Nour » sans coupure dans le mot ; ligne « Mon suivi » présente (`demo_accessibilite_page.dart:368-376`) ; `ma_classe_ma4_test` vert. **A5 non appliquée** (MA-DEC-1) |
| MA-5 | Fenêtre → Rejoindre → préparation → salle guidée ; observation tutoyée ; élève courant ; support en pile dès 150 % | `86d750d`, `f578d55`, `6edcd6e` | Parcours `demo_accessibilite_page.dart:303-347,354` ; `_seuilPile = 1.5` (`zone_support.dart:84-89,246`) ; `salle_ma5_test` vert. Notice tutoyée seulement pour la mineure **en démonstration** : `tutoiement: mineur` (`demo_accessibilite_page.dart:343`), capture Mariam « Ton parent observe la séance. », Idriss sans notice parentale. **Hors démonstration, le tutoiement suit la présentation** : `depuis_salle.dart:73` et `depuis_classe_live.dart:61` construisent `VueSeance` sans `tutoiement`, donc `_tutoie => tutoiement ?? _guidee` (`vue_seance.dart:405-410`) tutoie toute session guidée, adulte compris. **A4 non appliquée** (MA-TUTOIEMENT-1). Les commandes à 200 % sont en icônes : décision MA-CMD-1 du 02/10 (déjà vérifiée en VERIF-MA-2). **A6 non appliquée** (portée par TB-3, voir plus bas) |
| MA-6 | Résultat + « Retour à la Classe » seul bouton dominant, 3 travaux au plus, support, prochaine séance, aide ; ni « Très bien », ni confettis, ni message | `ce918f2` | `apres_seance_accessibilite.dart:71-77` (un seul `ActionPrincipale`), `:124` (`take(3)`), `:156`, `:162`, `:185` ; aucune chaîne « Très bien » ni confettis ; `apres_ma6_test` vert. **A7 non appliquée** (MA-APRES-1) |
| MA-7 | Entrée simple, reprise, « Lecture en grand texte » → verset agrandi, rendu intouché ; puis 3 majeurs corrigés (`669ec05`) | `e8d0dfc`, `669ec05` | Voir le tableau des majeurs ; reprise `coran_accessibilite.dart:106-142` ; `coran_ma7_test` vert, **17 cas** (+17, « All tests passed! », 17 noms de cas listés). **A4 non appliquée dans le lecteur** et **A8 non appliquée** (MA-TUTOIEMENT-1, MA-DEC-1) |

## Décisions du directeur du 27/09 portées par les fiches MA-1b à MA-7

Source : feuille `5hqpCULEK4Hwchu7D4BVtg` (énoncés et options lus dans la page, action `read`), recopiées dans le champ `decisions_directeur` des fiches.

| Décision | Fiches | État à `7885b35` | Preuve | Suite |
|---|---|---|---|---|
| A1 = a : 4 destinations aussi pour l'élève standard, harmonisation à HU-1 (note : garder les routeurs et ajouter ce dont l'élève standard a besoin) | MA-1b | Conforme au choix provisoire | `nav_shell.dart:91-115`, routes inchangées (`navigation_test` vert) | HU-1 (en attente) |
| A2 = a : boutons de 52 à 56, valeurs gardées si au moins 52 | MA-2 | Tenue | `test/accessibilite/ma11_technique_test.dart:34,197` (actions majeures ≥ 52), vert dans VERIF-MA-2 (`tests_ma2.log`) ; non rejoué ici | aucune |
| A3 = c : « Assalamou alaykoum, {prénom}. » | MA-3 | **Non appliquée** | `fr.i18n.json:618` « As-salāmu ’alaykum, {prenom}. » ; captures `ma3_*` | MA-DEC-1 |
| A4 = a : « Selon l'âge seulement : les textes du lecteur du Coran et les nouvelles phrases vouvoient l'adulte » | MA-3, MA-5, MA-7 | **Non appliquée** hors démonstration et dans le lecteur du Coran | Lecteur : `coran_accessibilite.dart:181` `LecteurCoranAccessibilite(onRetour: _fermer)` sans tutoiement ; il monte `VuePageMushaf` / `VueVersetAgrandi` (`:475-476`) qui affichent `t.eleve.coran.indisponibleDetail` « Dès que le réseau revient, ta page se rouvre ici. » (`vue_page_mushaf.dart:359`, `vue_verset_agrandi.dart:82`, `fr.i18n.json:2425`) et `absentDetail` « Signale-le : ce n'est pas toi. » (`vue_page_mushaf.dart:368`, `vue_verset_agrandi.dart:75`, `fr.i18n.json:2428`). Salle réelle : voir la ligne MA-5 ci-dessus. Appliquée seulement dans les écrans montés par la démonstration (Accueil, Ma classe, salle, après, entrée du Coran, écran « démonstration sans texte » : `demo_accessibilite_page.dart:343,362,394,424,445,472`) | MA-TUTOIEMENT-1 |
| A5 = a : montrer la progression, masquer le nombre de places | MA-4 | **Non appliquée** | `espace_groupe_page.dart:555-561` ; capture `ma4_ma_classe_mariam_avant_390_light.png` (« 3 élèves sur 6 places ») | MA-DEC-1 |
| A6 = a : « Le support reste dominant et fixe ; la vignette de l'enseignant défile » (question : « Salle en pile (texte agrandi) : que reste en haut ? ») | MA-5 | **Non appliquée** | L'option b refusée est « La vidéo de l'enseignant en haut (rendu actuel) ». Le code est ce rendu : en pile, `VignetteVideo` est le premier enfant de la colonne qui défile (`zone_support.dart:115-140`), avant le titre du support. `zone_support.dart` n'a pas changé depuis `6edcd6e` (27/09, 13 h 31 +0300, avant la décision), ni sur `corrections/revue-directeur-2026-10` (`git diff --stat 7885b35 7c612872` vide). Capture `ma5_salle_mariam_390_light_texte200.png` : la vidéo occupe le haut de la carte, au-dessus de « Chapitre 1 » | TB-3 (déjà ouverte) |
| A7 = a : un seul écran de fin, réutiliser `resultat_seance.dart` | MA-6 | **Non appliquée** | `apres_seance_accessibilite.dart:28` monté seulement par la démonstration (`demo_accessibilite_page.dart:418`) ; la vraie fin reste `resultat_seance.dart:40-115` | MA-APRES-1 |
| A8 = a : réutiliser les libellés existants (« Reprendre ta lecture »…) et ne rien ajouter | MA-7 | **Non appliquée** | `fr.i18n.json:627-635` (« Ouvrir le Coran », « Reprendre à ta / votre dernière page », `repriseRecherche*`, `repriseErreur*`) alors que « Reprendre ta lecture » existe (`fr.i18n.json:2421`) | MA-DEC-1 |

Pourquoi A4 et A8 ne sont pas qu'une affaire de chronologie : après la décision, deux commits du 02/10, tous deux ancêtres de `7885b35`, ont touché ces textes sans l'appliquer.

- `6686f9a` (MA-11, 02/10 15 h 33 +0300) ajoute `repriseRecherche`, `repriseRechercheVous`, `repriseErreur`, `repriseErreurVous` (`git show 6686f9a -- assets/i18n/fr.i18n.json`) : quatre phrases nouvelles, contre « ne rien ajouter ».
- `e23babd` (mineurs de MA-RC, 02/10 17 h 50 +0300) remplace « Reprendre là où tu t'es arrêté(e) » par « Reprendre à ta / votre dernière page », au lieu de reprendre l'existant « Reprendre ta lecture ».

La fiche MA-7 portait pourtant la décision. Sur `corrections/revue-directeur-2026-10` (`7c612872`), « Reprendre ta lecture » existe (l. 2581), mais la clé du Mode Accessibilité garde « Reprendre à ta dernière page » (l. 661), et la salutation reste « As-salāmu ’alaykum » (l. 651).

## Relevés de la revue cloud du 27/09 (fiches MA-3 à MA-7) : état à `7885b35`

| Fiche | Relevé de la revue | État à `7885b35` | Où il est suivi |
|---|---|---|---|
| MA-3 | **MAJEUR** : l'Accueil n'a ni chargement, ni erreur, ni hors ligne, ni vide « aucune classe » (renvoyé à MA-11) | **Toujours ouvert.** `accueil_accessibilite.dart` (282 lignes) reçoit `final GroupHomeVM espace;` déjà résolu (l. 58) ; aucune occurrence de `chargement`, `erreur`, `horsLigne`, `EmptyState`, `AsyncValue`. Fichier inchangé depuis `79c4fe6` (27/09). MA-11 a traité les états de la reprise du Coran, pas l'Accueil. Seul montage : `demo_accessibilite_page.dart:442` | **DASH-MA-PROD** (à faire, CORR-2, dépend de INTEG-RC-1) : « États chargement / vide / erreur à faire ». Le hors ligne n'y est pas nommé : à ajouter à sa note |
| MA-3 | Initiale « I » seule ; démo Idriss « après » avec la date du 28/09 | Toujours visibles (captures `ma3_*`) | Démonstration seulement, remarques |
| MA-3 | « An- / Nour » et « 3 h / 28 » à 200 % sur l'Accueil | Toujours visibles (`ma3_accueil_mariam_avant_390_light_texte200.png`) | Remarques |
| MA-3 | Les 3 tâches ont un chevron mais mènent à Ma classe où elles ne sont pas actionnables | Inchangé : `onTache` → Ma classe (`demo_accessibilite_page.dart:452`) | Démonstration ; à traiter au branchement (MA-BR-4) |
| MA-3 | Questions : tutoiement étendu ; graphie de la salutation | Décisions A4 et A3 | MA-TUTOIEMENT-1, MA-DEC-1 |
| MA-4 | MAJEUR : préparation guidée non traitée | Traitée par MA-5 (`f578d55`) ; capture `ma5_preparation_mariam_390_light_texte200.png` | aucune |
| MA-4 | MAJEUR : « Mon suivi » vide en démo, on n'en sort qu'en touchant un onglet | Inchangé : `PageShell` avec `SizedBox.shrink` (`demo_accessibilite_page.dart:433-438`), `_suivi` remis à faux seulement au changement d'onglet (`:276`) | Démonstration seulement ; contenu réel à MA-BR-4 (non nommé dans sa ligne, à ajouter) |
| MA-4 | Mineur : orphelin « 1 » à 1440 | **Non prouvé** (pas de capture Ma classe 1440 ouverte ici) | — |
| MA-4 | Question : pastille des places | Décision A5 | MA-DEC-1 |
| MA-5 | MAJEUR : commandes en icônes seules à 200 % | Décision MA-CMD-1 du 02/10, vérifiée en VERIF-MA-2 | aucune |
| MA-5 | Mineur : seuil 150 % non testé | Toujours : `salle_ma5_test.dart:69` ne teste que ×1 et ×2 | Remarques |
| MA-5 | Mineur : hors ligne, reconnexion, échec non montrés | Inchangé | MA-BR-3 |
| MA-5 | Questions : vignette en pile ; tutoiement du moteur réel replié sur la présentation | Décisions A6 et A4, non appliquées | TB-3 ; MA-TUTOIEMENT-1 |
| MA-6 | Question : deux écrans de fin | Décision A7, non appliquée | MA-APRES-1 |
| MA-6 | Mineurs : prochaine séance sans l'heure ; aucun des 5 états (renvoyé à MA-11) | Inchangés : `dateDeLAppareil` ne donne que jour et date (`apres_seance_accessibilite.dart:167`, `bloc_seance.dart:198-202`) ; aucun état dans le fichier, inchangé depuis `ce918f2` | MA-APRES-1 (l'écran unique doit les porter) |
| MA-6 | Mineur : « Besoin d'aide ? » mène à un Mon espace vide | Mon espace a son contenu et son aide branchée depuis MA-8 et MA-R M3 (`357878c`, vérifié en VERIF-MA-2) | aucune |
| MA-7 | 3 MAJEURS | Corrigés (tableau plus haut) | aucune |
| MA-7 | Mineur : textes du lecteur qui tutoient l'adulte | **Toujours ouvert** (décision A4) | MA-TUTOIEMENT-1 |
| MA-7 | Mineurs : erreur de reprise avalée ; « Ouvrir le Coran » actif avant la reprise | Corrigés par MA-11 (`6686f9a`) : `coran_accessibilite.dart:106-122` (`EtatRepriseCoran.echec`, délai) ; vérifié en VERIF-MA-2 | aucune |
| MA-7 | Questions : libellés nouveaux ; ligne « À lire aujourd'hui » non faite | Décision A8, non appliquée ; « À lire aujourd'hui » toujours absente | MA-DEC-1 |

## Captures (ouvertes une à une, 4 bords regardés ; aucune bande jaune et noire, aucun débordement)

- `ma3_accueil_mariam_avant_390_light.png` : « As-salāmu ’alaykum, Mariam. », carte Prochaine séance (initiale « I », 18:00 Paris, 45 min, « Cours dans 3 h 28 »), un bouton plein « Voir ma classe », 3 tâches, « Lire le Coran », « Besoin d'aide ? », barre à 4 onglets.
- `ma3_accueil_mariam_avant_390_light_texte200.png` et son recadrage `ma3_accueil_texte200_barre_recadree.png` : rien ne déborde. Dans la carte, « Classe An- / Nour » et « Cours dans 3 h / 28 » (mineurs déjà relevés par la revue cloud MA-3). Dans la barre du bas, l'onglet actif est coupé en plein mot, « Accuei / l » (voir remarques).
- `ma3_accueil_mariam_avant_1440_light.png` : barre latérale, carte sur toute la largeur, bouton au bord de fin, deux colonnes dessous (tâches ; Coran et aide).
- `ma3_accueil_idriss_apres_390_light.png` : vouvoiement (« Votre heure »), mais « Prochaine séance · Lundi 28 septembre · Séance terminée » (relevé mineur de MA-3, démonstration).
- `ma4_ma_classe_mariam_avant_390_light.png` : titre « Ma classe », photo, « Classe An-Nour », **pastille « 3 élèves sur 6 places »**, carte de séance avec la mention tablette, Avant le prochain cours, Bibliothèque, Progression « Chapitre 1 · 60 % », Mon suivi, aide.
- `ma4_ma_classe_mariam_avant_390_light_texte200.png` : identité en pile, « Classe / An-Nour » entier, aucun débordement.
- `ma5_salle_mariam_390_light.png` : en-tête « Ma séance » entier, « En ligne », mention d'observation tutoyée, support dominant, vignette de l'enseignant en coin, 4 disques d'icônes en bas.
- `ma5_salle_mariam_390_light_texte200.png` (rouverte à la reprise pour A6) : en haut, « < Ma séance » et la pastille « En ligne », puis « Ton parent observe la séance. » sur deux lignes. Dans la carte blanche, la vignette de l'enseignant (silhouette, étiquette « Sayyid Ibrahim ») occupe tout le haut, au bord de fin ; « Chapitre 1 » et « Les bonnes manières en classe » viennent dessous, puis les lignes grises et « 1 Écouter avec calme. ». En bas, le dock (micro vert, caméra violette, agrandir, raccrocher rouge) recouvre la suite (« Poser des… »), qui se lit en faisant défiler la carte. Bords gauche et droit nets, aucun mot coupé, aucune bande d'erreur. C'est le rendu « la vidéo de l'enseignant en haut » (option b de A6).
- `ma5_preparation_mariam_390_light_texte200.png` : « Tout est prêt. », « Le micro sera coupé en entrant. », bouton « Entrer dans la classe » visible, sans pied collant.
- `ma5_salle_idriss_1440_light.png` : support à gauche, enseignant à droite, commandes « Parler, Caméra, Agrandir, Quitter » avec libellés, aucune notice parentale.
- `ma7_coran_mariam_390_light.png` : entrée « Tu en étais page 6. », bouton **« Reprendre à ta dernière page »**, aide.
- `ma7_coran_lecteur_mariam_390_light.png` : en-tête d'une ligne, 5 disques (flèche gauche, navigation, zoom moins, zoom plus, flèche droite) visibles en bas, attribution Tanzil sur deux lignes. `_masque.png` : commandes et barre effacées, Coran 724 / 844 = 85,8 % de l'écran (`captures.log`).
- `ma7_coran_lecteur_mariam_390_light_texte200.png` : commandes visibles ; en-tête sur deux lignes, déjà suivi par MA-CORAN-TETE-1 (cité, non reproposé).
- `ma7_coran_lecteur_mariam_1440_light.png` : commandes visibles en bas de l'écran de 900, sans défilement.
- `ma7_coran_demo_sans_texte_lecteur_idriss_390_light.png` : « Le texte du Coran n'est pas chargé dans la démonstration », explication vouvoyée, aucun bouton.

Rouvertes à la reprise par l'agent de reprise : `ma5_salle_mariam_390_light_texte200.png`, `ma3_accueil_mariam_avant_390_light_texte200.png` (capture de page entière 390 × 3400 : salutation sur trois lignes, « Classe An- / Nour », « 3 h / 28 », onglet « Accuei / l » en bas, rien d'autre de coupé), `ma4_ma_classe_mariam_avant_390_light.png` (pastille « 3 élèves sur 6 places » sous « Sayyid Ibrahim »), `ma7_coran_mariam_390_light.png` (« Reprendre à ta dernière page »), `ma7_coran_lecteur_mariam_390_light_texte200.png` (en-tête « Aal-`Imraan . Page 6 sur 604 » sur deux lignes, 5 disques en bas au-dessus de l'attribution, barre à 4 onglets entière). Les descriptions ci-dessus sont confirmées.

Aucune capture ne montre le lecteur réel en état « indisponible » ou « absent » (la démonstration ne charge pas le texte). Le défaut A4 du lecteur est un fait de texte, prouvé par le code cité ; il n'a pas de rendu à juger.

## Défauts → étapes proposées (K-38 : aucune étape terminée rouverte)

1. **MA-APRES-1 (gravité moyenne, voie probable CORR-1, dépend de INTEG-RC-1)** : « Après la séance en Mode Accessibilité : un seul écran (décision A7 = a) ». Le directeur a choisi le 27/09 : « Un seul écran : réutiliser `resultat_seance.dart`, comme le demande le découpage » (feuille `5hqpCULEK4Hwchu7D4BVtg`, A7, choix a). À `7885b35`, deux écrans coexistent toujours :
   - `ApresSeanceAccessibilite` (`apres_seance_accessibilite.dart:28`) n'est monté que dans la démonstration (`demo_accessibilite_page.dart:418`) ;
   - la vraie fin de salle reste `ResultatSeance` (`resultat_seance.dart:40-115`), qui affiche en Mode Accessibilité « Retour à l'accueil » et une coche de succès même après « Quitter » (`:57`, `:96-102`).
   Aucun commit n'a touché ces fichiers après `ce918f2`, et ils existent encore sur `corrections/revue-directeur-2026-10` (`7c612872`). Remède : porter l'ordre et le contenu de MA-6 dans `ResultatSeance` (ou son équivalent sur la branche des corrections), puis retirer le doublon. L'écran unique doit aussi porter les deux mineurs de la revue MA-6 encore ouverts : l'heure de la prochaine séance (`apres_seance_accessibilite.dart:167` ne donne que la date) et les cinq états. Test depuis la vraie salle, captures 390 ×1 et ×2 et 1440 (K-61).
2. **MA-DEC-1 (gravité moyenne, voie probable CORR-1, dépend de INTEG-RC-1)** : « Mode Accessibilité : appliquer les décisions A3, A5 et A8 du 27/09 ».
   - A3 = c : « Assalamou alaykoum, {prénom}. ». Le code garde « As-salāmu ’alaykum, {prenom}. » (`fr.i18n.json:618` ; captures `ma3_*` ; branche des corrections l. 651).
   - A5 = a : montrer la progression, masquer le nombre de places. La pastille « 3 élèves sur 6 places » est affichée à l'élève dans Ma classe (`espace_groupe_page.dart:555-561`, posée sans condition de rôle ; capture `ma4_ma_classe_mariam_avant_390_light.png`).
   - A8 = a : réutiliser les libellés existants (« Reprendre ta lecture », `fr.i18n.json:2421`) et ne rien ajouter. Le code garde « Ouvrir le Coran », « Reprendre à ta / votre dernière page », « Le Coran s'ouvre en lecture agrandie, verset par verset. », « Retour à l'entrée du Coran », et les phrases `repriseRecherche*` et `repriseErreur*` (`fr.i18n.json:627-637` ; capture `ma7_coran_mariam_390_light.png`). Cause : le travail du 02/10 (`6686f9a`, `e23babd`) a ajouté et réécrit ces libellés sans tenir compte de la décision portée par la fiche MA-7. Les messages d'échec de la reprise répondent à un défaut de revue (K-59) : l'étape doit les fonder sur des textes existants, ou faire valider leur ajout par le directeur, au lieu de les garder sans le dire.
   Sur `corrections/revue-directeur-2026-10` (`7c612872`), A3 et A8 sont dans le même état (l. 651, l. 660-667), et la pastille des places est toujours posée dans `espace_groupe_page.dart`.
3. **MA-TUTOIEMENT-1 (gravité moyenne, voie probable CORR-1, dépend de INTEG-RC-1 ; partie salle réelle aussi de BR-1)** : « Mode Accessibilité : vouvoyer l'adulte dans le lecteur du Coran et dans la salle réelle (décision A4 = a) ». Le directeur a choisi le 27/09 : « Selon l'âge seulement : les textes du lecteur du Coran et les nouvelles phrases vouvoient l'adulte » (fiches MA-3, MA-5, MA-7). À `7885b35` :
   - Lecteur du Coran en Mode Accessibilité : `LecteurCoranAccessibilite(onRetour: _fermer)` (`coran_accessibilite.dart:181`) ne reçoit pas le tutoiement. Les vues montées (`:475-476`) affichent à l'adulte « Dès que le réseau revient, ta page se rouvre ici. » et « Signale-le : ce n'est pas toi. » (`vue_page_mushaf.dart:359,368`, `vue_verset_agrandi.dart:75,82`, `fr.i18n.json:2425,2428`). C'est le mineur « textes du lecteur tutoient l'adulte » de la revue cloud MA-7, jamais corrigé. Attention : ces deux vues sont dans `lib/features/tc_mushaf` (rendu du Coran, K-19). Le correctif doit rester dans l'enrobage (le texte de l'état vient de l'appelant) ou recevoir l'accord du directeur pour toucher ces deux fichiers, rendu inchangé dans tous les cas (`git diff --stat` vide sur le rendu).
   - Salle réelle : `depuis_salle.dart:73` et `depuis_classe_live.dart:61` construisent `VueSeance` sans `tutoiement`, et `vue_seance.dart:410` replie sur la présentation (`tutoiement ?? _guidee`) : un adulte en Mode Accessibilité est tutoyé. L'âge vient du serveur, d'où la dépendance à BR-1 pour cette partie ; d'ici là, un port neutre (K-09) peut porter l'âge.
   - Même état sur `corrections/revue-directeur-2026-10` (`7c612872`) : `coran_accessibilite.dart:181`, `vue_page_mushaf.dart:359,368`, `depuis_salle.dart` sans `tutoiement`.
   Preuve attendue : test du lecteur MA pour Idriss avec un état « indisponible » et « absent » (texte vouvoyé), test de la salle réelle adulte, `git diff --stat` vide sur `tc_mushaf`, `tc_coran`, `coran`.

Constats qui vont à des étapes déjà ouvertes (aucune étape nouvelle) :

- **Accueil sans ses cinq états** (majeur de la revue cloud MA-3) → **DASH-MA-PROD** (à faire, CORR-2, dépend de INTEG-RC-1), dont la note dit « États chargement / vide / erreur à faire ». Le hors ligne n'y figure pas : je propose à l'orchestrateur de l'ajouter à la note de DASH-MA-PROD (étape non commencée, donc pas une réouverture).
- **A6 non appliquée** (vignette en haut de la carte en pile) → **TB-3** (à faire, voie TB), dont la note dit « Règle aussi la vignette en pile à 150 % (ex-PT-B-cfbdb7a5) ». Elle ne cite pas A6. Je propose de l'ajouter à la note : « A6 = a : en pile, le support reste en haut et fixe, la vignette ne le précède pas ». `18_supports_tableau/00_REPRISE.md:111` dit que, pendant le partage, une capsule sans vidéo remplace la vignette, et que hors partage « la vignette reste » : TB-3 doit dire où elle reste en pile, et A6 répond « pas en haut ».

## Remarques (sans étape nouvelle)

- **Onglet « Accuei / l » coupé à ×2 sur 390** (`ma3_accueil_texte200_barre_recadree.png`). `_OngletBarreGuide` affiche un `Text` simple (`nav_shell.dart:761-768`), et le correctif MA-NAV-1 `703ca08` (`TexteSansCoupure`) n'est pas dans `7885b35` (`merge-base --is-ancestor` : code 1). La branche est gelée, et INTEG-RC-1 a gardé `TexteSansCoupure` à la fusion : rapport INTEG-RC-1-R, l. 56-59 ; à l. 133, « Accueil », « Ma classe » et « Mon espace » sont entiers. Déjà résolu sur la branche des corrections ; rien à proposer.
- MA-CORAN-TETE-1 (en-tête du Coran sur deux lignes à ×2) : déjà en étape, constaté de nouveau sur `ma7_coran_lecteur_mariam_390_light_texte200.png`.
- Mineurs déjà relevés par la revue cloud de MA-3 et toujours visibles en démonstration : initiale « I » seule ; Idriss « après » avec la date du 28/09 ; « An- / Nour » et « 3 h / 28 » sur l'Accueil à ×2 ; tâches à chevron qui mènent à Ma classe.
- « Mon suivi » de la démonstration est une page vide dont on ne sort que par un onglet (`demo_accessibilite_page.dart:276,433-438`). La promesse MA-4 (« atteignable ») est tenue ; le contenu réel relève du branchement (MA-BR-4, `15_accessibilite/MA-BR.md:9`), qui ne nomme pas Mon suivi : à ajouter à sa ligne.
- Seuil de pile à 150 % jamais testé entre ×1 et ×2 (`salle_ma5_test.dart:69`), mineur de la revue MA-5 toujours vrai.
- Non revérifié ici, car hors captures demandées : rendu visuel de MA-6 (le test `apres_ma6_test` est vert) ; orphelin « 1 » de Ma classe à 1440.

## Étapes couvertes

| Étape | Statut | Pourquoi |
|---|---|---|
| MA-0 | verifie | Fichiers du pilotage et règles MA1 à MA24 présents (`8ed739e4`, `d2a86d5c`) |
| MA-1a | verifie | UX_REVIEW_06 conforme à la preuve (18 lignes, sources, V1, TH-2) ; les réglages sans effet relevés sont branchés depuis |
| MA-1b | verifie | Fournisseur unique, mouvement réduit posé une fois, route gardée ; analyse 0, tests verts ; A1 conforme au choix provisoire |
| MA-2 | verifie | 4 destinations, `navigation_ma2_test` et `navigation_test` verts ; A2 tenue ; coupure de l'onglet à ×2 déjà résolue par INTEG-RC-1 |
| MA-3 | verifie | Promesse tenue (captures 390, 200 %, 1440 ; test vert). A3 → MA-DEC-1 ; A4 → MA-TUTOIEMENT-1 ; majeur des cinq états de l'Accueil toujours ouvert, porté par DASH-MA-PROD |
| MA-4 | verifie | Promesse tenue (capture 200 %, test vert). A5 → MA-DEC-1 |
| MA-5 | verifie | Parcours, pile à 150 %, observation selon l'âge en démonstration ; captures 390 ×1 et ×2, 1440 ; test vert. A4 (salle réelle) → MA-TUTOIEMENT-1 ; A6 non appliquée → TB-3 |
| MA-6 | verifie | Promesse tenue (code et test). A7 et deux mineurs de la revue → MA-APRES-1 |
| MA-7 | verifie | 3 majeurs toujours corrigés (code, 17 cas verts, captures 390, 1440, 200 %, démonstration) ; rendu intouché. A8 → MA-DEC-1 ; A4 (lecteur) → MA-TUTOIEMENT-1 |

## Fichiers de ce dossier

Journaux : `pubget.log`, `analyze.log` (premier passage), `analyze_reprise.log` (reprise, avec dossier, commit et `git status`), `tests_ma1.log`, `coran_ma7_reprise.log` (reprise, rapporteur détaillé), `captures.log`. Captures citées : les 16 PNG listés plus haut et le recadrage `ma3_accueil_texte200_barre_recadree.png`. Captures brutes complètes (56) : `D:\RA_TUTEUR\captures_VERIF-MA-1`.

## Reprise après contradiction (03/10)

Un contradicteur indépendant a fait six objections. Chacune a été reprise, avec la preuve indiquée.

| # | Objection | Gravité | Ce qui a été fait | Conclusion |
|---|---|---|---|---|
| 1 | A4 = a ni traitée ni citée ; le lecteur du Coran tutoie l'adulte ; « notice tutoyée seulement si l'élève est mineur » ne vaut qu'en démonstration | moyen | Fiches MA-3, MA-5, MA-7 relues (A4 présente sur les trois) ; énoncé lu dans la feuille ; code vérifié : `coran_accessibilite.dart:181`, `vue_page_mushaf.dart:359,368`, `vue_verset_agrandi.dart:75,82`, `fr.i18n.json:2425,2428`, `vue_seance.dart:405-410`, `depuis_salle.dart:73`, `depuis_classe_live.dart:61` ; même état sur `7c612872` | **Objection fondée.** A4 ajoutée au tableau des décisions ; ligne MA-5 corrigée (« en démonstration ») ; étape nouvelle **MA-TUTOIEMENT-1** |
| 2 | Majeur de la revue MA-3 sauté : l'Accueil sans ses cinq états | moyen | Fichier relu (`accueil_accessibilite.dart:58`, aucune trace d'état, inchangé depuis `79c4fe6`) ; tableau ajouté de tous les relevés de la revue cloud MA-3 à MA-7 avec leur état ; recherche d'une étape existante : DASH-MA-PROD la porte (sans le hors ligne) | **Objection fondée.** Constat ajouté ; renvoyé à DASH-MA-PROD avec la demande d'ajouter le hors ligne à sa note ; deux autres oublis de la même nature réparés (mineurs MA-6 → MA-APRES-1, sortie de Mon suivi, seuil 150 %) |
| 3 | A8 : l'explication par la chronologie est inexacte | mineur | `git show 6686f9a` et `git show e23babd` sur `fr.i18n.json` ; dates et ascendance vérifiées (code 0) ; `7c612872` l. 2581 et 661 relues | **Objection fondée.** Verdict et MA-DEC-1 corrigés : le travail du 02/10 a ajouté et réécrit ces libellés sans appliquer A8 |
| 4 | A6 laissée « pas prouvée » alors qu'elle correspondrait littéralement à l'option a | mineur | Énoncé de la feuille lu : « Salle en pile (texte agrandi) : que reste en haut ? », option b « La vidéo de l'enseignant en haut (rendu actuel) » ; `zone_support.dart:115-140` relu ; historique (`6edcd6e`, avant la décision) ; capture 200 % rouverte | **En partie fondée.** Il fallait conclure sans renvoyer au directeur. Mais la conclusion est l'inverse : la question porte sur ce qui reste en haut, la vignette est le premier élément de la colonne qui défile, et la feuille appelle ce rendu « rendu actuel » (option b, refusée). Le support défile lui aussi : il n'est pas « fixe » par rapport à la vignette. **A6 est non appliquée.** Pas d'étape nouvelle : TB-3 règle déjà la vignette en pile ; il faut y citer A6 |
| 5 | « coran_ma7_test vert (15 cas) » inexact | mineur | Fichier relu : 2 (l. 84-85) + 2 (l. 169-170, Mariam et Idriss) + 1 (l. 221) + 2 (l. 276-277) + 4 (l. 394-396) + 6 (l. 507-513) = 17 ; test rejoué avec le rapporteur détaillé (`coran_ma7_reprise.log`) : +17, « All tests passed! », 17 noms de cas listés | **Objection fondée.** Corrigé en 17 cas |
| 6 | `analyze.log` ne dit ni le dossier ni le commit | mineur | Analyse rejouée par le verrou avec `cd`, `git rev-parse HEAD` et `git status --short` en tête (`analyze_reprise.log`) : `D:\RA_TUTEUR\v-ma1`, `7885b35b921e…`, `git status` vide, « No issues found! » | **Objection fondée.** Traçabilité rétablie |
