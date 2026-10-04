# Revue croisée EN-7c-R (EN-7c-200 + EN-7c-SUGG-T)

Date : 04/10/2026. Revue en lecture seule : aucun commit, aucun push, tableau de suivi non modifié.
Commits : e95d1025, d791d93f, b9fdeed2, fusion d57ed2b1 (branche `corrections/revue-directeur-2026-10`). Base de comparaison : e95d1025^ = 4a4fbe7f.

## Verdict

**ACCEPTÉE AVEC RÉSERVES** (aucun défaut bloquant ni majeur ; trois mineurs, documentaires ou de suivi).

Statut de preuve : `présent dans le code` et `testé localement`. Rien n'est `testé sur staging` ni `déployé`.

## Périmètre et commandes

Diff lu : `git diff e95d1025^ b9fdeed2 -- lib assets tool` et les deux fichiers de test. La fusion d57ed2b1 n'apporte **rien** de ce lot : elle reprend BENTO-1b et GALERIE-BENTO-2 (`git diff b9fdeed2 d57ed2b1 -- lib/features/cahier lib/core/enseignant assets test/features/cahier` est vide). Elle ajoute 2 lignes à `tool/libelles_sources.json` sans perdre `enseignant.cahier.travailMaisonSaisi` (1 occurrence, JSON valide).

Fichiers lib touchés par le lot : `lib/features/cahier/cahier_page.dart`, `lib/features/cahier/makharij.dart`, `lib/core/enseignant/modeles_enseignant.dart`, `assets/i18n/fr.i18n.json` + code slang régénéré (sa seule autre différence est un déplacement de deux clés entre deux `switch`, normal pour slang), `tool/libelles_sources.json`.

| Commande (worktree détaché d57ed2b1) | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | No issues found |
| `dart run tool/verifier_jetons.dart` | code 1 ; 39 constats, **liste identique à la base** 4a4fbe7f, seuls des numéros de ligne changent (`catalogue_galerie.dart`, `groupe_reglages.dart`, apportés par la fusion BENTO). Aucun constat dans `cahier/`, `makharij.dart` ou `modeles_enseignant.dart` |
| `dart run tool/verifier_revue.dart` | code 1 ; base 4a4fbe7f : 1629 ; b9fdeed2 (lot seul) : 1629, ensemble des constats identique ; d57ed2b1 : 1627 (libelle-sans-source 1568 vers 1566, effet de la fusion BENTO). Le lot n'ajoute aucun constat |
| `flutter test --concurrency=2 test/features/cahier test/features/cahier_test.dart test/features/demo/demo_enseignant_page_test.dart` | +40 ~42, All tests passed (les 42 sautés sont les groupes de capture, sans `CAPTURE_DIR`) |
| `cahier_en7c_test.dart` seul | 11/11 réussis |
| `CAPTURE_DIR=… flutter test test/features/cahier/captures_en7c_test.dart --plain-name texte200` | 2/2 réussis, 24 PNG régénérés ; même nombre de pages que dans le dépôt (320 : p01 à p11, 390 : p01 à p09) ; différences pixel limitées à l'anticrénelage des glyphes (comparaison visuelle 320_p01 : identique) |

### Contre-épreuve

Code lib remis entièrement à 4a4fbe7f : le test ne compile plus (6 erreurs : `FeuilleAjusterCahier`, `devoirSuggere`, `travailMaisonSaisi`). Pour une contre-épreuve de comportement, huit mutations ciblées ont été appliquées une par une puis annulées. **Les huit sont détectées :**

| Mutation | Tests en échec |
| :--- | :--- |
| M1 `isolerPaireArabe` rend le libellé brut | paire arabe isolée et insécable |
| M2 `_suggestionDevoir` revient à l'ancienne règle (texte non vide) | devoir saisi : jamais dit « suggestion » |
| M3 label flottant remis sur le champ objectif | 200 % 390 et 200 % 320 |
| M4 `Semantics(label:)` retiré du champ objectif | le champ éditable porte son nom |
| M5 `maxLines: 2` fixes (sans `minLines`) | 200 % 390 et 200 % 320 (défilement interne du champ > 0) |
| M6 `devoirSuggere: _suggestionDevoir` (provenance gardée après modification) | devoir suggéré, modifié |
| M7 `versJson` envoie `devoir_suggere` | devoir suggéré, gardé et modifié |
| M8 `preremplie` recopie `devoirPrecedent` comme suggestion | 3 tests, dont « la décision préremplie ne suggère aucun devoir » |

Sémantique vérifiée aussi par sonde : le nœud éditable porte `label=[Objectif de Nour]` et `label=[Devoir de Nour]`, sans doublon. Les titres visibles sont en `ExcludeSemantics`.

## Points de contrôle demandés

- **Rien d'inventé (D10)** : conforme. `DecisionEleve.preremplie` (`modeles_enseignant.dart:647-652`) ne remplit ni `travailMaison` ni `devoirSuggere`. Aucun code de `lib/` ne pose `devoirSuggere: true` (grep : seulement `cahier_page.dart:903, 907, 1235`, qui relaient la valeur reçue). Le devoir précédent reste affiché en lecture seule. M8 prouve que le test s'oppose à une suggestion fabriquée.
- **versJson** : `modeles_enseignant.dart:693-708` n'envoie pas `devoirSuggere`. Assertion `versJson().containsKey('devoir_suggere') == false` (test, l. 321), confirmée par M7.
- **Sémantique des champs** : conforme (`cahier_page.dart:1102-1115` et `1146-1157`, `ExcludeSemantics` sur les titres). Le nom lu est celui du titre visible. Le libellé suit donc WCAG 2.5.3 (le nom accessible contient le libellé visible).
- **Paire arabe** : `makharij.dart` (`isolerPaireArabe`) entoure la paire d'un isolat RLI…PDI (U+2067…U+2069) et rend ses espaces insécables. L'ordre logique des chaînes suit l'ordre français (س/ص, ت/ط, ذ/ز, ه/ح). À l'écran, lu de droite à gauche, il est juste dans les captures. La valeur stockée reste la clé (`sin_sad`…), pas le libellé : aucun caractère de contrôle ne part dans `point_phonetique`.
- **Couleurs en dur** : aucune dans le diff. `verifier_jetons` n'a aucun constat sur les fichiers du lot.
- **`@visibleForTesting` sur `FeuilleAjusterCahier`** (`cahier_page.dart:858`) : acceptable. Seul le cas positif (suggestion) passe par là, et il est inatteignable depuis la coquille faute de source. L'annotation fait signaler par l'analyseur tout usage hors test dans un autre fichier. La feuille est ouverte comme le cahier l'ouvre (`AppBottomSheet.ouvrir`), et le commentaire du test exige de repasser par la coquille dès qu'une source existera. Le cas négatif et les tests à 200 % passent bien par `CoquilleEnseignantDemo`.

## Défauts

Bloquant : aucun. Majeur : aucun.

Mineurs :

1. **Libellé sans source directeur** : `tool/libelles_sources.json`, entrée `enseignant.cahier.travailMaisonSaisi`, porte « … ; a valider par le directeur ». `lib/CLAUDE.md` demande « le commentaire du directeur comme source ». La phrase « Vous avez déjà noté ce devoir. Modifiez-le ou laissez-le tel quel. » est une proposition de l'auteur et reste à valider explicitement.
2. **Captures 200 % en clair seulement, sans LISEZMOI** : `test/features/cahier/captures_en7c_test.dart:87-150` ne capture que le thème clair. `docs/current/captures/EN-7c-200/` n'a pas de note de lecture (BENTO-1b en a une), et aucun document de `docs/current/` ne cite EN-7c-200 ni EN-7c-SUGG-T. Le lot n'exigeait pas le sombre, mais la règle d'accessibilité de `03` demande clair et sombre.
3. **Contrôle de troncature partiel** : `cahier_en7c_test.dart:160-175` vérifie `didExceedMaxLines` sur l'état initial seulement, avant la saisie du devoir. Il ne voit pas un mot coupé au milieu sans ellipse : seules les captures en témoignent. Ce n'est pas un défaut de code, c'est la limite de la preuve.

Observation hors périmètre (préexistant, pas imputable au lot) : la translittération « Hâ / Hâ' » pour (ه / ح) est ambiguë. Usuellement ه = Hâ', ح = Ḥâ'. C'est à soumettre à l'enseignant référent.

## Captures vues (Read sur PNG, dossier du dépôt)

| Capture | Constat |
| :--- | :--- |
| 320_p01 (et la même régénérée) | Titre « Ajuster · Nour », devoir précédent en lecture, carte « À revoir » : aucun mot coupé, identique à la régénération |
| 320_p06 | « La suite pour Nour », Continuer / Renforcer / Suspendre : texte entier |
| 320_p07 | Ligne de présence de Nour, « Corriger la présence » centré sur deux lignes |
| 320_p08 | « Point de prononciation », **« Sîn / Sâd (س / ص) »** : la paire tient sur une ligne, entre ses parenthèses, ordre RTL juste |
| 320_p09 | Tâ / Tâ emphatique (ت / ط), Dhâl / Zây (ذ / ز), Hâ / Hâ' (ه / ح) : paires entières, jamais coupées |
| 320_p10, p11 | « Objectif de Nour » et « Devoir de Nour » en titre, sans label flottant coupé. Champs de 2 lignes. Bouton « Enregistrer pour cet élève » centré sur deux lignes |
| 320_devoir_saisi | « Vous avez déjà noté ce devoir. Modifiez-le ou laissez-le tel quel. ». Devoir de 3 lignes lisible en entier, sans « Ajustez la suggestion » |
| 390_p03 | Faiblesses, « Madd » prérempli coché |
| 390_p07 | Les quatre paires arabes, sur une ligne quand elles tiennent, entières sinon |
| 390_p09 | Objectif et devoir, bouton du bas |
| 390_devoir_saisi | Même phrase « déjà noté », devoir sur 2 lignes |

Aucune troncature, aucun mot coupé, aucune paire arabe scindée ou inversée dans l'échantillon (11 captures, 320 et 390).

## Pour accepter sans réserve

1. Faire valider par le directeur la phrase `enseignant.cahier.travailMaisonSaisi` et mettre sa référence dans `tool/libelles_sources.json`.
2. Ajouter les captures 200 % en sombre (au moins p08 et devoir_saisi, 320) et un `LISEZMOI.md` dans `docs/current/captures/EN-7c-200/` (pages, ordre, commande de régénération).
3. Facultatif : refaire le contrôle `didExceedMaxLines` après la saisie du devoir et sur la feuille rouverte (« déjà noté »).
