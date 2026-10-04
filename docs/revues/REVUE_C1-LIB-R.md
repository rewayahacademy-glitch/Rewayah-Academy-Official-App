# Revue croisée C1-LIB-R : LIB-LOT3-2, INTEG-MINEURS-1, DOC-VERIF-1, AD-NETTOYAGE

- **Objet revu** : `origin/corrections/c1-lib` @ `c1595c0e` (base `af20f6c2`), 4 commits de code, 64 fichiers (+1290 −109), dont 34 captures. Pilotage : `d3ea5fe9` (DOC-VERIF-1) et `240b754f` (AD-NETTOYAGE).
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit ce lot (auteur : `268bd1ef`).
- **Date** : 4 octobre 2026.
- **Fiche** : K-41 (élision), K-26 (pièces juridiques : statut seul changé, texte intact), jetons, Comptes.
- **Méthode** :
  - lecture du diff de code et des deux commits de pilotage ;
  - contrôles relancés dans le worktree `/home/user/rv-c1-lib` (détaché, sans commit) ;
  - quatre mutations ciblées, remises en place par `git checkout -- lib/` (`git status` propre à la fin) ;
  - cinq captures ouvertes ;
  - fusion à blanc avec `origin/corrections/revue-directeur-2026-10`.

## Verdict

**Acceptée avec réserves.** Les quatre étapes peuvent passer à « fait ». Aucun défaut visible, aucune règle cassée. Les tests sont discriminants : les quatre mutations sont prises. Restent des mineurs, et une fusion avec la branche commune qui demande une reprise à la main d'un fichier d'écran (voir D1).

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (code 0) |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **31** (39 attendus à la base). Les 8 relevés en moins sont ceux levés par INTEG-MINEURS-1 : 2 `EdgeInsets.fromLTRB` de `salle_seance.dart`, 4 durées de `demo_controleur_page.dart`, 2 de `historique_controleur_demo.dart`. Aucun nouveau relevé |
| Tests du lot (10 fichiers : libellés lot 3, Comptes, Journée, Centre de commande, redirection, feuille, GroupeReglages, barre MA, cahier EN-7c, source echecEnvoi) | **288 réussis, 0 échec** |
| Écrans qui utilisent les composants partagés modifiés (`AppBottomSheet`, `GroupeReglages`, `NavShell`) : 59 fichiers de test + `test/features/admin_dossiers` | **1169 réussis, 65 sautés, 0 échec** |
| Mutation 1 : Comptes sans le tri (`visibles = filtres`) | échec de « les enseignants en attente passent devant les lignes sans decision » |
| Mutation 2 : redirection revenue à `role == guardian` | 2 échecs : « ferme au tuteur » (élève, admin) et « ferme a un role illisible » |
| Mutation 3 : Journée affiche toujours `erreurPartielle` | 2 échecs : « seuls les cahiers en retard échouent » et « prière et cahiers échouent » |
| Mutation 4 : `AppBottomSheet` sans la `GlobalKey` du corps | échec de « la saisie et le focus survivent a 800 puis 300 puis 800 » |
| Fichiers interdits (`supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`) | Aucun touché |
| Fusion à blanc avec `origin/corrections/revue-directeur-2026-10` (`08a27c2e`) | **Conflit sur 3 fichiers** : `lib/core/i18n/strings_fr.g.dart`, `lib/features/admin_tableau/tableau_de_bord_page.dart`, `tool/libelles_sources.json` |

## Points de la fiche, un par un

| Point | Constat |
| :--- | :--- |
| **K-41 élision** | ✅ `lib/core/i18n/elision.dart:11-24` : `deDevant` et le nouveau `queDevant` partagent `_elide`. Les clés passent de `{eleve}` à `{deEleve}` / `{queEleve}` (`fr.i18n.json`, `objectif`, `objectifDetail`, `travailMaison`), et les 6 appels de `cahier_page.dart` (l.595, 1084, 1097, 1108, 1124, 1151) passent par l'élision. Test unitaire (Aya, Élodie, Hadi, Nour, Ibrahim, Bilal) et deux tests d'écran : « Objectif d'Aya », « Ce qu'Aya », « Devoir d'Aya », puis « Objectif de Nour », « Ce que Nour ». Capture `cahier_aya_320_x2_light` : les trois textes élidés, sans mot coupé. Réserve m2 sur la portée hors français |
| **K-26 pièces juridiques** | ✅ dans le fond. `d3ea5fe9` touche 8 pièces de `14_controleur/` : le titre passe de « (projet) » à « (signée / validée le 02/10/2026) », un encadré de statut est ajouté avec renvoi à la ligne exacte de `SIGNATURES_2026-10-02.md` (l.7 à 14, vérifiées une à une), et dans les deux DPIA les cases « à signer » du tableau de signature deviennent « signé le 02/10/2026 ». Aucun paragraphe du corps n'est touché : le paragraphe « Statut. Projet... » d'origine reste, et l'encadré l'explique. Réserve m1 sur la phrase de l'encadré |
| **Jetons** | ✅ 31 relevés au lieu de 39, aucun nouveau. Les durées de démonstration passent sur `Mouvement.maximum` ; la salle passe en `EdgeInsetsDirectional.fromSTEB` (RTL juste). Dans `nav_shell.dart`, la marge de la barre reste à `AppSpacing.xs` ou `sm`, jamais 0 ; les onglets prennent des parts égales quand leurs minimums ne tiennent plus. Capture `manav1_apres_enfant_light_320x2` : la barre a sa marge de chaque côté, « Ma classe » et « Mon espace » vont à la ligne entre deux mots, aucun mot coupé |
| **Comptes** | ✅ `comptes_page.dart` : tri stable côté client (l.235-238), les enseignants en attente devant ; « Sans objet » pour le tuteur, et pour élève et personnel sans pièce (`_pieceSansObjet`, l.337-343) ; un rôle illisible garde le texte réel de la pièce ; une phrase signale le compte en attente au rôle illisible, sans le compter comme « attend une décision ». Clés ajoutées à `libelles_sources.json`. Capture `ad_nettoyage_comptes_320x2_dark` : enseignante Aicha en tête, puis tuteur « Sans objet », élève « Sans objet », puis la ligne UNKNOWN ; la phrase d'attente dit « Une personne » (l'enseignante seule) |
| Redirection (m3) | ✅ `redirection.dart:137` écrit la règle en positif : tout rôle autre qu'enseignant, y compris nul, est renvoyé de `/attente/piece` vers `/attente`. Trois nouveaux cas testés |
| Tuile Dossiers (m1) | ✅ `tableau_de_bord_page.dart` : la tuile compte comme la liste « À traiter » (`enseignantsSeulement`), le compteur serveur sert tant que la liste n'est pas lue. Test « la tuile Dossiers ne compte pas les tuteurs » (1, pas 3). Capture `ad_nettoyage_tableau_1440_light` : tuile à 1, aperçu « Moussa0 » |
| Case sans geste (m16) | ✅ `groupe_reglages.dart:176-180` : `enabled: false` seulement pour une case sans contrôle ni `onPress`. Test sémantique : cochée et inactive |
| `AppBottomSheet` (m15) | ✅ passe en `StatefulWidget` avec une `GlobalKey` sur le corps, sans fork du composant. Mutation 4 prise |
| LIB-LOT3-2, échec partiel exact | ✅ `journee_page.dart:237-245` : trois messages (prières, cahiers, tout). Capture `journee_erreur_cahiers_390_dark` : le texte nomme les seuls cahiers de transmission, bouton Réessayer en contour, le mode sombre est sombre |
| « cahiers de transmission » | ✅ `deconnexionConsequence` corrigée, et un test parcourt tout le nœud `enseignant` de `fr.i18n.json` pour refuser un « cahier » seul |
| DOC-VERIF-1 | ✅ `lib/CLAUDE.md` : limite du §4.3, échelle discrète, exception du directeur au §4 bis.8. `01_RELEVE.md` : `_points` l.49 et `Set _verifie` l.42, vérifiés sur l'historique de `dossiers_page.dart` (`57e72110`, `e60c5b46`, `76b77444`). UX_REVIEW : 3 gardées, 17 adaptées |
| AD-RC (`240b754f`) | ✅ en partie. Les 4 commits cités existent sur l'origine (`c1d33d8`, `f242c06`, `a8dfcb3` sur `claude/confident-mayer-m2fqsl`, `d5fdd94` sur le pilotage). Je n'ai pas pu refaire le contrôle des patch-id : les anciens commits locaux (`dcd85ce`, `23d39a5`, `746fb94`) ne sont pas dans ce dépôt |
| 5 états, i18n, capacité | ✅ Aucun écran nouveau. Tous les textes ajoutés passent par `t.` et ont leur source. Aucun widget ne lit un rôle pour décider d'un affichage hors du domaine (`CompteAdmin.role` est une donnée affichée, pas la session) |

## Défauts retenus

Aucun MAJEUR.

- **D1 (mineur, fusion)** : conflit avec la branche commune sur `tableau_de_bord_page.dart`. DASH-ADM-1 a refait la tuile Dossiers (`apercuErreur`, `_SqueletteCompteurs`, lignes d'aperçu). Le paramètre `dossiersEnAttente` de m1 doit être repris à la main dans la nouvelle tuile, sinon m1 se perd sans bruit. `libelles_sources.json` : union simple des deux listes. `strings_fr.g.dart` : régénérer par `dart run slang`. Après fusion, relancer `tableau_de_bord_test.dart` (le test m1 doit passer).
- **m1 (mineur, K-26)** : l'encadré dit « Le texte ci-dessous n'a pas été modifié », alors que dans `DPIA_CONTROLEUR.md` et `DPIA_CLASSE.md` le tableau de signature et la ligne « Signature du directeur » ont été remplis. C'est bien un changement de statut, permis par K-26, mais la phrase devrait dire « seul le tableau de signature a été rempli ».
- **m2 (mineur, K-41)** : l'élision est choisie en code (`deDevant`, `queDevant`) et injectée dans le texte. C'est le motif déjà connu (`05_recette/AD/RAPPORT.md:94`). En arabe, ces clés n'existent pas : repli sur le français. Quand l'arabe viendra (LG-1), il faudra des clés propres à chaque langue, pas « de / d' » injecté.
- **m3 (cosmétique)** : la règle traite le « h » comme une voyelle (« d'Hadi », « qu'Hamza »). Pour un h aspiré, le français écrit « de Hamza ». Règle antérieure au lot, à trancher dans les libellés (DASH-LIB ou LIB).
- **m4 (cosmétique)** : la phrase du rôle illisible dit « Rechargez la page pour réessayer ». Sur Android ou iOS, il n'y a pas de « page ». Proposer « Réessayez plus tard » ou un bouton Réessayer, à valider avec la clé (déjà marquée « à valider par le directeur »).

## Pour accepter

1. Fusionner `corrections/c1-lib` dans la branche commune en reprenant D1 à la main, puis relancer `tableau_de_bord_test.dart`, `comptes_test.dart` et `libelles_lot3_test.dart`, et `dart run tool/verifier_jetons.dart` (31 attendus si rien d'autre n'a bougé).
2. Ranger m1 à m4 dans une étape de nettoyage (par exemple AD-NETTOYAGE-2 pour m4, LIB pour m2 et m3, une ligne de pilotage pour m1).

## Contre-vérification

Second relecteur, sceptique, session `01KyPAZg`, non auteur. Même worktree `/home/user/rv-c1-lib`, sans commit ni push.

**Verdict confirmé : acceptée avec réserves, sans MAJEUR.** Le premier relecteur n'a retenu aucun majeur, donc il n'y a rien à réfuter. J'ai cherché ce qui aurait pu lui échapper et je n'ai trouvé aucun nouveau majeur.

### Mesures refaites

| Contrôle | Résultat |
| :--- | :--- |
| Fusion à blanc `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` | Conflit sur les 3 mêmes fichiers : `strings_fr.g.dart`, `tableau_de_bord_page.dart`, `libelles_sources.json`. D1 est confirmé |
| Mutation 5 : `_elide` rend toujours « de / que {nom} », sans élision (`elision.dart:23`) | `libelles_lot3_test.dart` : **2 échecs** (8 réussis). Le cœur de K-41 est bien gardé par les tests |
| Mutation 6 : `_pieceSansObjet` réduit au seul tuteur (`comptes_page.dart:340`) | `comptes_test.dart` : **1 échec**, « seul l enseignant sans piece voit « Aucune pièce déposée » » |
| Remise en place | `git checkout -- lib/` après chaque mutation, `git status` propre |

### Points de la fiche, revus

- **K-41** ✅. `elision.dart` : une seule règle (`_elide`), sur la première lettre. Les clés `fr.i18n.json:3194-3196` ne prennent plus le nom brut. Aucune de ces clés n'existe dans `ar.i18n.json`, donc aucune clé arabe n'est cassée (m2 confirmé). Capture `cahier_aya_devoir_320_x2_dark` : « Objectif d'Aya », « Ce qu'Aya doit atteindre », « Devoir d'Aya ». Aucun mot coupé, un seul bouton plein, le sombre est sombre.
- **K-26** ✅. J'ai relu tout le diff de `d3ea5fe9` sur `14_controleur/`, hors encadrés ajoutés. Seuls trois types de lignes changent : les titres (« projet » vers « signée / validée le 02/10/2026 »), les cases « à signer » du tableau de signature des deux DPIA, et la ligne « Signature du directeur ». Le corps des 8 pièces n'est pas touché. Les renvois sont justes : `SIGNATURES_2026-10-02.md` l.7 donne `../DPIA_CONTROLEUR.md` et l.8 donne `DPIA_CLASSE.md`. Les chemins relatifs se résolvent bien depuis chaque pièce. m1 est confirmé : l'encadré dit « texte non modifié », alors que ces cases ont été remplies.
- **Jetons** ✅. Je ne les ai pas recomptés : le diff n'ajoute aucune valeur brute. Les seules nouvelles valeurs sont `AppSpacing.xs` et `AppSpacing.sm` (`nav_shell.dart`), `Mouvement.maximum` et `EdgeInsetsDirectional`.
- **Comptes** ✅. Capture `ad_nettoyage_comptes_320x2_light`. Ordre affiché : Aicha (enseignante en attente), Mariam (tuteur, « Sans objet »), Lina (élève, « Sans objet »), puis UNKNOWN. La phrase du rôle illisible s'affiche sous le compteur. Les identifiants (`TEACHER-AS-000001`) vont à la ligne au trait d'union, pas au milieu d'un mot.

### Captures ouvertes (4, différentes de celles du premier relecteur)

1. `LIB-LOT3-2/cahier_aya_devoir_320_x2_dark` : élision juste, rien de coupé.
2. `INTEG-MINEURS-1/manav1_apres_enfant_dark_320x2` : la barre garde sa marge des deux côtés. « Ma classe » et « Mon espace » passent sur deux lignes entre deux mots. La pastille « Accueil » tient dans sa part.
3. `LIB-LOT3-2/journee_erreur_cahiers_320_x2_light` : le message nomme les seuls cahiers de transmission. Le bouton « Réessayer » est en contour. Aucun mot coupé.
4. `AD-NETTOYAGE/ad_nettoyage_comptes_320x2_light` : voir Comptes plus haut.

### Ce que j'ai cherché sans le trouver

- Pas de texte en dur : les 3 messages de la Journée et les 2 du rôle illisible passent par `t.`.
- Pas de bouton dans un bouton, et pas de second bouton plein.
- Pas de couleur inventée.
- Pas de widget qui lit le rôle de la session.

### Écart nouveau (cosmétique, non bloquant)

- **n1** : aucune capture RTL dans les trois dossiers du lot. La salle passe pourtant en `EdgeInsetsDirectional.fromSTEB`. Ce changement est juste en RTL par construction, mais il n'est pas montré. À ajouter à la prochaine passe de captures (une capture `ar` de la salle suffit).

### Pour accepter

Rien de plus que la section « Pour accepter » ci-dessus :

1. Faire la fusion en reprenant D1 à la main.
2. Relancer `tableau_de_bord_test`, `comptes_test` et `libelles_lot3_test`, puis `verifier_jetons`.

## Suite complète (session principale 01KyPAZg)

Suite dossier par dossier (`flutter test` par dossier de `test/`, captures ignorées) : c1-lib : 5385 réussis, 0 échec.
