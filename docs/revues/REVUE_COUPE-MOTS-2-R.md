# Revue croisée COUPE-MOTS-2-R : légende de Mes Classes en arabe

- **Objet revu** : `corrections/c2-coupe2` @ `8343eb95` (base `af20f6c2`, branche commune). 2 commits, 8 fichiers : `mes_classes_page.dart` (+30 −16), `mes_classes_test.dart` (+69), 6 captures.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit COUPE-MOTS-2 (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Méthode** :
  - lecture du diff `af20f6c2..8343eb95` ;
  - contrôles relancés dans le worktree `/home/user/rv-coupe2` (tests ciblés seulement) ;
  - une mutation ciblée et une sonde de sémantique, remises en place (`git status` propre) ;
  - 3 captures ouvertes ;
  - fusion à blanc avec la branche commune.

## Verdict

**Acceptée avec réserves.** Le défaut de la fiche est corrigé : en RTL, la légende se lit « 3 élèves » et « Niveau 2 · Français · 3 élèves », dans l'ordre. Le test est discriminant. Aucun conflit avec la branche commune.

Les points 1 et 2 de la fiche (« À terminer » de la Journée, captures de la Journée) ont été traités par BENTO-2c, déjà fusionné dans la branche commune. Ils ne sont pas dans ce diff.

Trois réserves mineures, aucune bloquante : les isolats sont présents dans le libellé de sémantique (non testé), pas de capture sombre ni de script de capture versionné, et « 3 » se sépare de « élèves » en fin de ligne à 320 x2.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK (2044 sorties) |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `flutter test test/features/enseignant_classes` | **23 réussis, 0 échec** (dont les 2 nouveaux, ltr et rtl) |
| `demo_enseignant_page_test` + `parcours_enseignant_test` (autres tests qui montent Mes Classes) | **19 réussis, 0 échec** |
| Mutation : `_isole` renvoie le texte sans U+2068/U+2069 | **1 échec**, « COUPE-MOTS-2 … rtl » : attendu < 339,36, obtenu 438,34. Le cas ltr passe, comme prévu. Remis en place |
| Sonde de sémantique (test temporaire, retiré) | 3 nœuds portent les isolats, voir point 3 |
| Fusion à blanc `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` | **Aucun conflit** (arbre `a5478e2c`) |
| Fichiers interdits (supabase/, .github/, pubspec.yaml, vercel.json) | Aucun |
| Suite complète | Non lancée (consigne : une seule fois, sur la fusion des 10 branches) |

## Points de la fiche, un par un

| Point | Constat |
| :--- | :--- |
| 1. Isolat U+2068/U+2069 par ligne de légende | ✅ `mes_classes_page.dart:236-255` : la ligne « contexte » et la ligne « quand » sont chacune entourées par `_isole` (l. 324), puis jointes par `\n` (l. 269). Une seule isole par ligne, pas par segment : le commentaire explique pourquoi (à 320 px, des segments isolés un par un se liraient dans le désordre). Le sens est déduit du premier caractère fort (FSI), donc « 3 élèves » est lu de gauche à droite même dans un écran RTL |
| 2. Test LTR/RTL | ✅ `mes_classes_test.dart:325-387` : pour les deux sens, la boîte du chiffre est à gauche de celle du mot. Mesure réelle par `getBoxesForSelection`, pas une comparaison de chaînes. La mutation le fait échouer en RTL |
| 3. Sémantique : les isolats ne doivent rien ajouter à la lecture | ⚠ Non vérifié par l'auteur. La sonde montre que les libellés de sémantique contiennent les caractères : « An-Nour\|⁨3 élèves⁩\|⁨Prochaine séance : lundi à 18:00⁩ » (3 lignes sur 3). Ce sont des caractères de format invisibles (catégorie Cf). TalkBack, VoiceOver et les lecteurs web ne les prononcent pas en pratique, donc rien d'audible n'est ajouté. Mais aucun test ne le garantit, et une recherche exacte de texte (`find.text('3 élèves')`) ne trouverait plus la légende. Mineur m1 |
| 4. Captures K-61 (`docs/current/captures/COUPE-MOTS-2`) | ✅ 6 captures, 320, 390 et 1280, texte x2, LTR et RTL, clair. Ouvertes : `320_x2_rtl`, `320_x2_ltr`, `1280_x2_rtl`. Voir plus bas. Pas de capture sombre, et le test qui les a produites n'est pas versionné (m2) |
| Points 1 et 2 de la fiche d'étape (relevés par BENTO-2c-R) | ✅ hors de ce diff. `_ATerminer` de `journee_page.dart` a été repris par BENTO-2c, fusionné dans la branche commune (`2d61b9e0`). La contre-épreuve de BENTO-2c-R faisait échouer 2 cas « À terminer : terminer » à 320 x2 LTR/RTL. Les captures `docs/current/captures/BENTO-2c/journee4_320x2_{clair,sombre}.png` existent sur la branche commune |

## Règles du projet

| Règle | Constat |
| :--- | :--- |
| 5 états | Non touchés par le diff (la logique de chargement, vide, erreur, hors ligne de la page est inchangée) |
| 320 px et texte x2, aucun mot coupé | ✅ Captures 320 x2 : aucun mot coupé. Remarque m3 sur « 3 / élèves » |
| RTL | ✅ C'est l'objet du lot, mesuré par le test |
| Un seul bouton plein, pas de bouton dans un bouton | Non touchés |
| Aucune couleur ou valeur inventée | ✅ Aucune valeur ajoutée. Jetons : 39 |
| Aucun texte en dur | ✅ Les seuls ajouts sont deux caractères de contrôle. Les libellés restent `t.enseignant.classes.*`. Le test lit aussi les libellés par `t.` |
| Capacité, jamais rôle ; port neutre | Non touchés |
| Composants partagés modifiés | Aucun. `LigneRubrique` et `TexteSansCoupure` sont inchangés. Seule la chaîne passée en légende change |

## Captures ouvertes

- `mes_classes_320_x2_rtl.png` : écran aligné à droite. « 3 élèves » se lit dans le bon ordre pour An-Nour. Al-Badr : « Niveau 2 · / Français · 3 / élèves », dans l'ordre. « Prochaine séance : lundi à 18:00 » correct. Pastille « Remplacement » et « Cahier de transmission à valider » sans débordement. Aucun mot coupé.
- `mes_classes_320_x2_ltr.png` : même contenu, aligné à gauche. Aucun mot coupé, aucun débordement.
- `mes_classes_1280_x2_rtl.png` : les trois classes, « 3 élèves », « Niveau 2 · Français · 3 élèves », « 2 élèves », « Aucune séance prévue », dans le bon ordre. C'est le défaut de la fiche, corrigé.

## Défauts retenus

Aucun défaut majeur.

- **m1 (mineur)** : les isolats passent dans le libellé de sémantique. Rien d'audible en pratique, mais la fiche demandait que la lecture ne change pas, et aucun test ne le vérifie. Remède proposé : poser la légende sans isolats dans la sémantique (par exemple `semanticsLabel` du texte, ou retirer U+2068/U+2069 du libellé fusionné), et un test qui affirme qu'aucun nœud de Mes Classes ne contient U+2068 ni U+2069.
- **m2 (mineur)** : pas de capture en mode sombre, et le test de capture n'est pas versionné (BENTO-2b l'avait gardé en `.txt`). Les captures ne sont donc pas reproductibles depuis le dépôt.
- **m3 (cosmétique)** : à 320 x2, « 3 » reste en fin de ligne et « élèves » passe à la ligne suivante (LTR et RTL). Ce n'est pas un mot coupé, mais le nombre se sépare de son nom. Une espace insécable dans le libellé `eleves` (`fr.i18n.json`) l'éviterait.
- **m4 (cosmétique, hors lot)** : l'isolat suppose que la légende est en français (repli de la locale arabe). Le jour où `eleves` sera traduit en arabe, une ligne qui commence par « Français » serait isolée en LTR alors que le reste est arabe. À revoir avec la traduction.

## Pour accepter

Rien de bloquant. COUPE-MOTS-2 peut passer à « fait » et `c2-coupe2` peut être fusionnée dans la branche commune (aucun conflit). m1 et m2 peuvent suivre dans une petite étape de reprise.

## Contre-vérification

- **Relecteur** : session `01KyPAZg`, sceptique indépendant, non auteur. 4 octobre 2026. Worktree `/home/user/rv-coupe2` @ `8343eb95`.

### Contrôles relancés

| Contrôle | Résultat |
| :--- | :--- |
| `flutter test test/features/enseignant_classes` | **23 réussis, 0 échec** (même chiffre que la première revue) |
| `dart analyze --fatal-infos` | **0 problème** |
| Jetons `grep -c "\["` | **39** |
| `CAPTURE_DIR=<scratch> flutter test test/capture/coupe_mots1_capture_test.dart --plain-name "Mes Classes"` | **6 réussis, 0 échec**. Ce test versionné mesure aussi qu'aucun mot de l'écran entier n'est coupé ni tronqué : il passe avec les isolats |
| Comparaison octet par octet des 6 PNG régénérés avec `docs/current/captures/COUPE-MOTS-2/` | **6 sur 6 identiques** (`cmp`) |
| `git status` en fin de contre-vérification | propre |

### Majeurs de la première revue

Aucun majeur n'avait été retenu. Rien à réfuter.

### Mineurs

- **m1** : confirmé, reste mineur. Les isolats sont des caractères de format (Cf), non prononcés. La légende est un texte secondaire d'une rubrique, pas un bouton imbriqué.
- **m2** : **rejeté en partie**. Les captures SONT reproductibles depuis le dépôt : le test versionné `test/capture/coupe_mots1_capture_test.dart` (groupe « Mes Classes ») les régénère à l'octet près. Il reste seulement l'absence de capture en sombre pour ce lot. Ce point est cosmétique, puisque le diff ne touche ni couleur ni thème.
- **m3, m4** : confirmés, cosmétiques.

### Recherche d'un majeur oublié

- Bouton dans un bouton : rien de neuf. Seule la chaîne de `legende` change. `LigneRubrique` est inchangé.
- Mot coupé à 320 x2 : aucun. Je l'ai vérifié sur la capture `320_x2_rtl` et par la mesure du test de capture (6 sur 6).
- État manquant : les 5 états ne sont pas touchés par le diff.
- Test non discriminant : non. La mutation de la première revue fait échouer le cas RTL. Le test mesure des boîtes réelles avec `getBoxesForSelection`.
- Régression d'un composant partagé : aucun composant partagé n'est modifié. `TexteSansCoupure` borne l'échelle sur le mot le plus long. Les isolats ont une largeur nulle, et la mesure du test de capture reste verte.
- Texte en dur : aucun. Seuls U+2068 et U+2069 sont ajoutés, dans une fonction privée commentée.

**Aucun majeur nouveau.**

### Verdict final

**Acceptée avec réserves**, verdict inchangé. Réserves maintenues : m1 (sémantique non testée), m2 réduit à l'absence de capture sombre, m3 et m4 cosmétiques.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
