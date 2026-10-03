# INTEG-RC-1-R : revue croisée de INTEG-RC-1 (03/10/2026)

Voie VERIF, lecture seule. Aucune ligne de code commitée. Revue faite pour la session orchestratrice
00166a22 ; INTEG-RC-1 a été faite par la session b0cfa272.

- Worktree de revue : `D:\RA_TUTEUR\r-integ`, détaché sur `4a4fbe7` (= `origin/corrections/revue-directeur-2026-10`
  au moment de la revue, vérifié par `git rev-parse`).
- Base avant intégration : `98e3f9d`. Chaîne de premier parent vérifiée : `0c0b739` → `f4c917c` → `328a737` → `760802c` → `4a4fbe7`.
- Seconds parents = pointes actuelles des branches gelées : `058c525` (ui/enseignant-v1), `39a702a` (ui/controleur-v1),
  `5629693` (ui/eleves-adultes-v1), `7885b35` (ui/accessibilite-v1). Rien n'a donc été oublié en amont.

## Verdict

**Accepté.** Aucun bloquant. Aucune intention perdue trouvée dans les quatre fusions ; i18n en union stricte
(0 clé perdue) ; aucune couleur ajoutée par l'intégration ; aucun `skip` ajouté hors captures ; analyse à 0 ;
`verifier_revue` : 0 violation née de l'intégration ; suites salle, accessibilité et Coran vertes.
Restent des points à arbitrer par le directeur (déjà écrits par INTEG-RC-1 dans `REVUE-DIRECTEUR-2026-10.md`,
confirmés ici sur capture) et quelques mineurs de traçabilité.

## 1. Fusions relues par `git show --remerge-diff`

Sorties complètes : `remerge_<sha>.txt` ; diff de la correction : `correction_4a4fbe7.diff`.

### 0c0b739 (enseignant), 3 fichiers en conflit
- `fr.i18n.json` `enseignant.cahier.*` (remerge l. 9-29) : libellés « cahier de transmission » des corrections
  (LIB-CAHIER-1) gardés, `echecEnvoi` d'EN-7c gardé (« L'envoi n'a pas été confirmé… », D5). Les deux intentions tiennent.
- `cahier_page.dart` (remerge l. 133-158) : titre `travailMaison(eleve:)` des corrections + phrase de suggestion
  conditionnelle d'EN-7c. Résultat vérifié dans `git show 0c0b739:lib/features/cahier/cahier_page.dart` (l. 1084-1098) :
  `travailMaisonDetail` n'apparaît que `if (_suggestionDevoir)`, avec la clé `cahier-devoir-suggestion`. Correct.
- Générés slang : seulement l'ordre des blocs `switch` (artefact du découpage, sans effet).

### f4c917c (contrôleur)
- `fr.i18n.json` (remerge l. 9-36) : `etatIndisponible` = « Visite plus proposée » et `incognito` = « Votre présence
  n'est pas annoncée en temps réel. » pris du contrôleur ; ce sont les décisions du directeur (`0703d80` CT-RC S2 = a,
  `91f31eb` planche 02/10), plus récentes que les textes des corrections (`b5f528d` CT-2, `f4e84a8` CT-1b). `dejaEnCours*`
  et `etatDejaControlee` des corrections gardés. Correct.
- `controle_page.dart` (remerge l. 150-218) : `_BlocATerminer` par visite (`cleReprendre(v.seanceId)`, adresse
  `adresseCompteRendu`) du contrôleur, et le crochet `onReprendreCompteRendu` des corrections conservé en
  `ValueChanged<String>` (4a4fbe7 : `controle_page.dart:51`, `:118` ; démo `demo_controleur_page.dart:757`, `:767`).
  Titre de carte : `missionEnDirect` (C1 = a) dans la `Row` avec la pastille des corrections. Les deux intentions tiennent.
- Mineur m1 : le message de commit n'a pas de corps (aucun conflit décrit), contrairement aux trois autres fusions.

### 328a737 (élèves adultes)
- `fr.i18n.json` (remerge l. 9-22) : `enfantAttente` « dès que votre accès est ouvert » des corrections (`2fac423`,
  HL-A-6, K-47 : pas de validation tuteur) gardé ; `procheTitre`/`procheDescription` retirés comme en EA-5c (`b9c8edd`).
  Aucun code ne les lit (`git grep` : seul un commentaire de test, `formulaire_profil_eleve_test.dart:206`). Correct.
- `repere_demonstration.dart` (remerge l. 193-233) : libellé i18n K-41 des corrections + `ReserveCoinFin` du rôle. Correct.
- `place_adulte.dart` : imports du rôle ajoutés. Correct.
- Mineur m2 : `recharge_foyer.dart` (remerge l. 251-265) porte un changement qui n'est dans **aucun** parent
  (`Ecart.vMd` → `Ecart.vLg`, K-55 ; `5629693` a `Ecart.vMd`, le fichier n'existe pas dans `f4c917c`). Il est annoncé
  dans le message de la fusion ; c'est de l'espacement, pas une couleur. Acceptable, mais à savoir : un changement de
  conception logé dans une fusion échappe à la revue des branches.

### 760802c (accessibilité), 15 fichiers en conflit
- `groupe_reglages.dart` (l. 226-287) : largeur pleine MA-GR-1 + graisse sélectionnée et pastille des corrections. Correct.
- `nav_shell.dart` (l. 288-729) : point de fond. Les corrections retiraient le Coran de la barre MA (MA-NAV-1,
  `essentielle: false`) ; la fusion le garde (4 destinations). Ce choix suit `DECISIONS_DELEGUEES_2026-10-02.md:35`
  (« Non, le Coran reste »), ouvert et lu. `TexteSansCoupure` (MA-NAV-1) et la coquille `_CoquilleBarreBasse` (MA-CMD-1)
  sont gardés ; le fond `surfaceCanvas` sous la barre aussi (`nav_shell.dart:501` dans 4a4fbe7).
  Mineur m3 : environ 100 lignes de mise en page **nouvelles** sont écrites dans la fusion elle-même
  (`_largeursOnglets`, `_minimumsOnglets`, `_motLePlusLong`, marge latérale à zéro à 320 px). Elles sont annoncées dans
  le message, couvertes par `nav_shell_accessibilite_test.dart` (vert, voir §3) et visibles sur capture (§4), mais
  n'ont eu aucune revue de branche avant cette revue-ci.
- `page_shell.dart` (l. 730-781) : `_Bascule` à clés globales (AD-RC M4) + `teteDefile ||` (MA-RC B1). Lu dans
  4a4fbe7 `page_shell.dart:197-239` et `:301-369` : une seule structure, les deux intentions tiennent.
- `setting_row.dart` : `aPlat` (K-55) + `fusion` MergeSemantics (WCAG 4.1.2). Correct.
- `compte_page.dart` (l. 807-1079) : `CarteLignes` des corrections + lignes masquées en Mode Accessibilité (MA-RC, MA-GR-1).
  Vérifié dans 4a4fbe7 : clé `reglage-raccourcis-salle` (l. 315), ligne Français (l. 339), bloc `apres` (l. 442). Correct.
- `dock_seance.dart` : `CommandeSalleCompacte` partagé (corrections) au lieu de `_DockEtroit` (rôle) + diamètre `cible`
  en MA (rôle). Plus aucune occurrence de `_DockEtroit`. Correct.
- `module_reglages_observation.dart` : `largeurControle` du rôle posé sur les trois lignes de la `CarteLignes`. Correct.
- `demo_accessibilite_page.dart` : présentation suivant la bascule de démo (`_presentation`). Correct.
- Tests (l. 1244-1750) : alignés sur le Coran dans la barre et sur les icônes seules. Deux hunks à signaler :
  - Mineur m4 : `guidee_fin_test.dart` (l. 1536-1557) : `find.text('Micro ouvert')` (mot visible) devient
    `_bouton('Micro ouvert')` (le libellé du `BoutonAppel`, visible ou non). L'assertion ne prouve plus que le mot
    d'état est **affiché** ; c'est cohérent avec le comportement provisoire (voir D1), pas avec la décision du 02/10.
  - `nav_shell_accessibilite_test.dart` (l. 1725-1736) : `closeTo(13)` devient `inInclusiveRange(10, 13.001)` ; c'est
    le côté corrections (MA-NAV-1, `TexteSansCoupure` qui réduit sans descendre sous 1), gardé à juste titre.

### 4a4fbe7 (correction après relecture)
- `coran_accessibilite.dart` : à la première ou dernière page, la flèche disparaît et sa place reste
  (`placePrecedenteKey`/`placeSuivanteKey`, `SizedBox.square(cible)`), plus de bouton inerte. Test ajouté
  `coran_ma7_test.dart` « NAV-FLECHES-1 » (vert, §3). Vu sur capture (§4).
- `REVUE-DIRECTEUR-2026-10.md` : exception NAV-FLECHES-1 écrite, Coran dans la barre écrit comme « accord écrit du
  directeur à obtenir », et contradiction ouverte sur le mot d'état au-delà de 130 % (voir D1).
- Aucune clé i18n ajoutée ou retirée (`05_union_i18n.log`, dernière ligne fr et ar).

## 2. i18n, slang, couleurs, skips

- **Union i18n** (`union_i18n.py.txt` → `05_union_i18n.log`) : pour chaque fusion, clés des deux parents moins clés du
  résultat, chaque absente classée « retrait voulu » si elle est dans la base de fusion et absente d'un parent.
  **PERTES = 0** dans les 4 fusions, en fr et en ar ; **0 clé née dans une fusion**. fr : 3582 (98e3f9d) → 3877 (4a4fbe7) ;
  ar : 98 → 98, aucune clé ar sans clé fr.
- **Slang** : `dart run slang` relancé sur 4a4fbe7 (`08_slang.log`) : régénération OK. `git status` marque les trois
  `strings*.g.dart` modifiés mais `git diff --stat` ne montre aucune ligne : écart de fins de ligne seulement
  (avertissements LF/CRLF dans le même journal). Recontrôle octet à octet, fins de ligne normalisées :
  `11_slang_recontrole.log` : `strings.g.dart` 6613 octets, `strings_fr.g.dart` 893240, `strings_ar.g.dart` 24888,
  **identique=True** pour les trois ; `git diff --numstat` vide, avec ou sans `--ignore-cr-at-eol` (core.autocrlf=true).
  Le généré du commit est donc exactement celui des `.i18n.json`. Fichiers restaurés ensuite (status vide).
- **Couleurs (K-37)** : aucune ligne `Color(0x`, `Colors.`, `fromARGB`, `fromRGBO`, `withOpacity`, `withValues(alpha`
  ajoutée par les commits d'intégration (remerge-diff des 4 fusions + 4a4fbe7) ; aucun fichier `lib/core/theme` touché
  par eux (`06_skip_couleurs.log`).
- **Skips** : `git diff 98e3f9d 4a4fbe7 -- test` ajoute 21 lignes `skip:`, toutes `skip: sautSansCapture` dans des groupes
  de capture apportés par les branches (EA, EN-7c, CT-8, CT-12, MA-8, MA-9, MA-12) ; aucune retirée ; aucune dans les
  remerge-diff (`06_skip_couleurs.log`). Le seul skip conditionnel hors capture rencontré dans les suites lancées,
  `salle_200_test.dart:143-144` (`reste`, SALLE-200-2), existait avant (absent des lignes ajoutées).

## 3. Commandes relancées (verrou partagé, worktree `r-integ`, HEAD 4a4fbe7)

| Commande | Résultat | Journal |
|---|---|---|
| `flutter pub get` | Got dependencies | `01_pub_get.log` |
| `dart analyze` | **No issues found!** | `02_dart_analyze.log` |
| `dart run tool/verifier_revue.dart` | 1664 violation(s) (code 1) : libelle-sans-source 1568, bouton-grise 80, affirmation-reseau 5, avatar-taille 4, avatar-recompose 3, plein-multiple 3, bouton-recompose 1 | `03_verifier_revue.log` |
| idem `--detail` sur 4a4fbe7, 98e3f9d et les 4 pointes (outil de 4a4fbe7 posé sur les pointes qui ne l'ont pas) | **0 violation née de l'intégration** ; 250 violations des parents disparues | `07_…`, `10_…`, `compare_verifier.py.txt` → `12_compare_verifier.log` |
| `flutter test test/features/salle_seance test/features/salle_test.dart test/features/salle_200_test.dart test/features/salle_enseignant_test.dart test/features/demo/demo_salle_page_test.dart test/core/accessibilite test/accessibilite test/video/vue_salle_test.dart test/features/controleur/salle_controleur_test.dart test/features/controleur/ctrl_salle1_test.dart test/core/widgets/commande_salle_test.dart test/coran` | **+1027 ~370, All tests passed!** (369 skips « CAPTURE_DIR absent », 1 skip SALLE-200-2 préexistant ; 0 échec) | `04_tests_salle_accessibilite.log` |

Le dossier `test/salle` demandé n'existe pas : la salle est dans `test/features/salle_seance` et les fichiers listés.
Non lancés : la suite complète (test/core, test/teaching_core, test/features entiers, le reste) ; le message de
760802c annonce 1153 + 2429 + 1662 verts, non revérifiés ici. Comptage à rapprocher : la base 98e3f9d a déjà
1399 violations de `verifier_revue` (le chiffre n'est pas une régression de l'intégration) ; la règle « 0 violation
au-delà du socle » n'est tenue sur aucune des branches.

## 4. Captures (test temporaire, non commité)

Test : `integ_rc1_r_capture_test.dart.txt` (copie), lancé seul avec `CAPTURE_DIR` puis retiré du worktree
(`09_captures.log` : 7 tests verts, `takeException` nul partout). PNG dans `captures/`, tous ouverts :

- `salle_ma_mariam_390_x2_light.png`, `…_dark`, `salle_ma_idriss_390_x2_light.png`, `…_dark` : en-tête compact,
  « Ma séance » entier sur une ligne (MA-TITRE-1), dock de 4 disques en icônes seules, aucun débordement.
  **Aucun mot d'état visible** (« Micro ouvert », « Caméra allumée ») : voir D1.
- `coran_ma_entree_mushaf_derniere_390_x2.png` : entrée « Le Coran », reprise page 6, barre de 4 onglets avec Coran
  actif ; « Accueil », « Ma classe », « Mon espace » entiers, sans coupure de mot.
- `coran_ma_lecteur_mushaf_derniere_390_x2.png` : en-tête une ligne + page, 3 commandes (← ☰ →) posées sur le Mushaf,
  attribution Tanzil sur deux lignes, barre visible pendant que les commandes le sont.
- `coran_ma_lecteur_verset_agrandi_derniere_390_x2.png` : 5 disques sur une rangée (← ☰ − + →), au bord de l'écran (4 px).
- `…_masque.png` (3) : commandes et barre effacées ; zone du Coran `CommandesMasquables` = 704 / 844 = 83,4 % (journal).
- `coran_ma_lecteur_mushaf_page1_390_x2.png` : page 1, flèche « précédente » absente (infobulle comptée 0 dans le
  journal), ☰ et → à la même place qu'en page 6 : la place est réservée (correction 4a4fbe7 vérifiée).
- Rendu du Coran non touché par la revue (corpus de référence des tests, texte factice « texte »).

## Défauts

- **D1 (moyen, à arbitrer, préexistant, non créé par la fusion)** : en Mode Accessibilité à 390 px et texte ×2, le dock
  de la salle n'affiche aucun mot d'état (4 captures salle). Contraire à `DECISIONS_DELEGUEES_2026-10-02.md:36`
  (« le mot d'état reste », WCAG 1.4.1). INTEG-RC-1 l'a écrit comme contradiction ouverte (4a4fbe7,
  `REVUE-DIRECTEUR-2026-10.md`, choix (a) ou (b) mesurés). Selon ce document, `salle_ma5_test.dart` vérifie le comportement
  provisoire ; `guidee_fin_test.dart` aussi (m4, lu dans le remerge-diff). Étape proposée : **ETATS-MA-1** après arbitrage du directeur.
- m1 (mineur) : `f4c917c` sans corps de message, conflits non décrits.
- m2 (mineur) : `328a737` contient un changement K-55 de `recharge_foyer.dart` absent des deux parents (annoncé).
- m3 (mineur) : `760802c` écrit ~100 lignes de mise en page nouvelles dans `nav_shell.dart` (annoncées, testées, vues).
- m4 (mineur) : `guidee_fin_test.dart` ne prouve plus l'affichage du mot d'état (lié à D1).

## Questions pour le directeur

1. Coran dans la barre de l'élève en Mode Accessibilité (4 destinations) : la fusion annule votre demande MA-NAV-1 sur la
   foi de la décision déléguée du 02/10. Confirmez-vous par écrit ?
2. Mot d'état des bascules au-delà de 130 % en Mode Accessibilité : (a) le mot reste, dock sur deux rangées ou support
   qui cède de la hauteur (MA-CMD-1 relâché), ou (b) MA-CMD-1 prime et la décision du 02/10 est reprise par une
   décision datée ?
