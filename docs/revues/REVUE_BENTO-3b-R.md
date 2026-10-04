# Revue croisée BENTO-3b-R : `origin/corrections/c2-bento3b` (04/10/2026)

Revue faite par la session cloud 01MrLWqB, en lecture seule. Périmètre : `714b09e6..f0252b84`,
soit 4 commits (`102f9cf6`, `83e83246`, `c0fc78d6`, `f0252b84`). Aucun commit ni push sur la
branche revue. Le tableau de suivi est tenu par la session principale (réservation, verdict,
étapes de suite). Les worktrees de contrôle
(`/home/user/wt/b3b`, `fusion`, `mut-ordre`, `mut-helper`, `capt`) ont fini avec un
`git status --short` vide. Les worktrees des contre-vérifications ont été supprimés.

## Verdict

**ACCEPTÉE**, avec des mineurs à suivre.

- Les trois points obligatoires du contrat « Pour accepter » sont levés : encodage (0 `آ`),
  fusion sans conflit avec des captures refaites et assez hautes, `dart format` propre.
- Aucun constat bloquant ou majeur n'a résisté à la contre-vérification. Le seul majeur
  proposé (C7, mots coupés sur la capture du Contrôle) a été ramené à mineur : défaut
  antérieur à la branche, sur un écran hors périmètre, capturé « pour mémoire ».
- Les mesures de l'auteur se reproduisent exactement : analyze 0, jetons 39 et revue 1610
  sans ajout, 5381 tests réussis et 0 échec.
- La fusion à blanc avec la branche commune actuelle (`f6ac3658`) se fait sans conflit et
  passe toute la suite : 5455 réussis, 2774 sautés, 0 échec.
- Réserves : la contre-épreuve annoncée par l'auteur est inexacte (ORD-1). Le test unitaire
  m8 ne reproduit pas le cas qu'il annonce (M8-1, M8-2, M8-3). Le facteur « × échelle du
  texte » n'est gardé par aucun test (ORD-2). m5 n'est pas fait.

Tous les contrôles ont rendu un résultat. Aucun n'a manqué.

## Le contrat « Pour accepter » point par point

| Point | État | Preuve |
|---|---|---|
| 1. `grep -c 'آ'` = 0 sur le test adulte | **Levé** | `grep -c 'آ'` donne 0 sur `accueil_adulte_page_test.dart` et 0 sur `captures_ea2_test.dart`. Les 3 fichiers qui contiennent encore le motif à `f0252b84` (`strings_ar.g.dart`, `corpus_reference.json`, `nav_shell_accessibilite_test.dart:286`) sont de l'arabe valide (alef madda de القرآن), déjà présents à `af20f6c2`. `102f9cf6` ne change que des caractères et la mise en forme : texte identique après normalisation, 19/19 et 3/3 `testWidgets`. |
| 2. Fusion de la branche commune sans conflit, captures adulte_320x2 refaites sur la fusion, vue assez haute pour voir « Ressources » à 320×2 et 1440×2 | **Levé** | L'arbre de `83e83246` (`a5416013`) est identique à `git merge-tree --write-tree 102f9cf6 af20f6c2` : aucune résolution manuelle. `test/support/aucun_mot_coupe.dart` garde les deux apports. Vue de 4400 px (320/390 ×2) et 2800 px (768/1440 ×2). « Ressources de la classe » et ses 3 lignes sont visibles en entier à 320×2, 390×2, 768×2 et 1440×2. Les 4 PNG adulte 320×2 et 1440×2 régénérés depuis le script sont identiques au pixel près aux fichiers commités (`getbbox()` = None). |
| 3. `dart format` | **Levé** | `dart format --output=none --set-exit-if-changed` sur les 3 `.dart` des commits non fusion : 0 fichier changé. |
| 4a. Tests d'ordre discriminants (m3), recommandé | **Levé avec réserves** | Avec la page de `fa64a6ad`, les 4 tests d'ordre échouent (avec les tests de `714b09e6`, ils passaient tous). 9 mutations d'ordre sur 10 sont tuées. Réserves : à 390 et 768, seule l'assertion `GrilleBento` discrimine (ORD-3) ; le facteur d'échelle du seuil n'est pas testé (ORD-2). |
| 4b. Test unitaire de `_lignesDistinctes` / U+2011 (m8), recommandé | **Partiellement levé** | Le test existe (4/0). Il tue les mutations « liste vide » et « U+2011 compté comme coupure ». Mais il tourne en police de test FlutterTest, où « An‑Nour » donne une seule boîte : l'ancien critère de `af20f6c2` passe aussi (4/0). Voir M8-1 à M8-3. La garde réelle tient grâce à `accueil_adulte_page_test.dart` (6 échecs sous l'ancien critère). |
| 4c. `largeurMinCarteClasse` dans `grille_bento.dart` (m5), recommandé | **Non fait** | La constante reste dans `lib/features/accueil_famille/accueil_famille_page.dart:64`, valeur 360. |
| 5. Laissés ouverts (m6, seuil 360, m7, m2) | Toujours ouverts, comme prévu | m2 et m7 visibles sur les captures, inchangés. Voir « Laissé ouvert ». |

## Commandes lancées

Sur la branche (`/home/user/wt/b3b`, `f0252b84`), sauf mention contraire. Toutes les suites
avec `--concurrency=2`.

| Commande | Résultat |
|---|---|
| `grep -c 'آ'` sur les 2 tests adulte | 0 et 0 |
| `git grep -IlE` motifs de mojibake, `lib test '*.md'` | `af20f6c2` : 4 fichiers, 11 lignes. `714b09e6` : 5 fichiers, 23 lignes. `f0252b84` : 3 fichiers, 10 lignes, tous de l'arabe valide |
| `dart format --set-exit-if-changed` (3 fichiers) | 0 changé |
| `dart analyze --fatal-infos` | No issues found |
| `dart run tool/verifier_jetons.dart` (branche et base `714b09e6`) | code 1, **39 = 39**. Seule différence : `groupe_reglages.dart:349` devient `:381` (même règle, décalage venu de la fusion) |
| `dart run tool/verifier_revue.dart --detail` (branche et base) | code 1, **1610 = 1610**, diff des 1622 lignes vide |
| `flutter test test/features` | +2483, ~2062 sautés, 0 échec |
| `flutter test test/core` | +648, 0 échec |
| `flutter test test/router` | +277, 0 échec |
| `flutter test test/widgets` | +274, 0 échec |
| `flutter test` sur les 25 autres dossiers | +1699, ~712 sautés, 0 échec |
| **Total branche** | **5381 réussis, 2774 sautés, 0 échec** (= annonce de l'auteur pour les réussis) |
| `flutter test accueil_adulte_page_test.dart -r expanded` | 30/30, noms lisibles (« » et §3.7) |
| `flutter test test/widgets/aucun_mot_coupe_test.dart` | 4/0 |
| 7 fichiers appelants du helper (`accueil_adulte_page_test`, `coupe_mots1*`, `mes_classes_test`, `accueil_famille_test`, `journee_test`, `nav_shell_accessibilite_test`) | 216/0 |
| `git merge-tree --write-tree 102f9cf6 af20f6c2` ; `git rev-parse 83e83246^{tree}` | `a5416013` des deux côtés |
| `git diff af20f6c2 f0252b84 --stat` | 57 fichiers, +1035/−31, tous de BENTO-3 ou BENTO-3b |
| `git merge-tree --write-tree f0252b84 f6ac3658` ; `git rev-parse a8889a0c^{tree}` | `1fcb0d1d` des deux côtés : fusion à blanc automatique |
| Fusion `a8889a0c` : `dart analyze --fatal-infos` | No issues found (46,7 s) |
| Fusion : tests ciblés (21 chemins, dont les 10 fichiers qui emploient `aucun_mot_coupe`) | +895, ~753 sautés, 0 échec |
| Fusion : `test/features` | +2557, ~2062 sautés, 0 échec |
| Fusion : `test/core` | +648, 0 échec |
| Fusion : `test/router` | +277, 0 échec |
| Fusion : `test/widgets` | +274, 0 échec |
| Fusion : 26 autres dossiers | +1699, ~712 sautés, 0 échec |
| **Total fusion** | **5455 réussis, 2774 sautés, 0 échec** (+74 dans `test/features`, apportés par c2-bento2c et c2-adm1) |
| Fusion : `dart run slang` puis `git status --short` | vide |
| PIL : tailles des 48 PNG | 320/390 : 2600 (×1), 4400 (×2). 768/1440 : 1500 (×1), 2800 (×2) |
| `CAPTURE_DIR=… flutter test test/capture/bento3_capture_test.dart --plain-name 'adulte 320x2_'` puis `'adulte 1440x2_'` | 2 + 2 réussis, 4 PNG. `ImageChops.difference(...).getbbox()` = None pour les 4 |

Les tests sautés sont les tests de capture sans `CAPTURE_DIR`. Ils sont aussi nombreux sur la
branche que sur la fusion (2774). L'annonce de l'auteur (5381/0) ne les mentionne pas. Je n'ai
pas mesuré ce chiffre sur la base `714b09e6`.

## Contre-épreuve et mutations

### Contre-épreuve : page de `fa64a6ad` (compile sans adaptation)

| Fichier de test | Résultat |
|---|---|
| Tests de `f0252b84` | **+14 −16.** Échouent : vrai routeur, 390, 768, 1440 rtl, 1440 ltr, 1440 sans « Avant », les 10 « aucun mot coupé ». 768 échoue sur `findsOneWidget` `GrilleBento` (l.488). |
| Tests de `f0252b84` sans les 2 blocs `GrilleBento` | +3 −14. 390 et 768 **passent**. 1440 ltr et rtl échouent sur « parcours sous la séance » (l.534). |
| Tests de `714b09e6` (avant `c0fc78d6`) | +5 −12. 390, 768, 1440 ltr et rtl **passent tous**. |

`c0fc78d6` rend donc bien les 4 tests d'ordre discriminants. L'annonce « 768 passe encore » est
fausse (ORD-1). Confirmé par une contre-vérification dans un worktree neuf : « +14 −16 ».

### Mutations sur la page courante (`accueil_adulte_page.dart`)

| Mutation | Tests qui échouent |
|---|---|
| M1 parcours au-dessus de la séance | 5 (390, 768, 1440 rtl, 1440 ltr, 1440 sans « Avant ») |
| M2 « Avant » avant la séance | 5 (bureau côte à côte, 390, 768, 1440 rtl, 1440 ltr) |
| M3 parcours sans `etendueLarge` (2×1 à 1440) | 3 (1440 rtl, ltr, sans « Avant ») |
| M4 Dernières séances et Ressources inversées | 4 (390, 768, 1440 rtl, ltr) |
| M5 colonne D14 à la place de `GrilleBento` | 17 |
| M6 `Directionality` ltr forcé (RTL ignoré) | 1 (1440 rtl) |
| M7 séance pas seule sans « Avant » | 1 (1440 sans « Avant ») |
| M8 `coteACote` toujours vrai | 1 (768) |
| **M9 seuil sans « × échelle du texte »** | **0 : survit** (30/30, et 34/34 avec `aucun_mot_coupe_test`) |
| M10 parcours entre séance et « Avant » | 2 (390, 768). Équivalent à 1440 : `placerBento` remet « Avant » à droite |

Sonde M9 : à 1440×2, la grille fait 1120 px, (1120 − 16) / 2 = 552. La page actuelle empile
(552 < 720), le mutant met côte à côte (séance 288-840, « Avant » 856-1408).
`verifierAucunMotCoupe` reste vert dans les deux cas.

### Mutations sur le helper (`test/support/aucun_mot_coupe.dart`), mesurées avec `aucun_mot_coupe_test.dart`

| Mutation | Résultat |
|---|---|
| a : ancien critère `{b.top.round()}.length > 1` (`af20f6c2`) | **survit** (4/0). Dans les 7 appelants : +210 −6, les 6 tests « aucun mot coupé … texte ×2 » de l'accueil adulte échouent sur `Classe An‑Nour : An‑Nour` |
| b : `return <String>[]` | tuée (2 échecs) |
| c : U+2011 compté comme coupure | tuée (1 échec) |
| c2 : mot découpé au U+2011 (`[^\s‑]+`) | **survit** (4/0) |
| d1 : intervalle du milieu élargi d'une hauteur de ligne | **survit** (4/0) |
| d2 : clause symétrique supprimée | **survit** (4/0) |
| d3 : `milieu = b.top` | **survit** (4/0) |
| Témoin (toujours 1 ligne) | tuée : la suite voit un helper complètement cassé |

Sonde : en police FlutterTest (10 « i » à 20 px = 200.0), « An‑Nour » à 400 px donne une seule
boîte `[112, 0, 224, 16]`. Avec DMSans + `fontFamilyFallback: ['NotoSansArabic']`, hauteur 1.3
(style `_titre`, `app_typography.dart:284-301`), elle donne 3 boîtes, dont celle du U+2011 à
top −6.25 contre −0.14. Un cas « Remplacement » à 16 px dans 0,6 × sa largeur naturelle donne
2 boîtes `[0..16]` et `[16..32]` et tue d1 et d3.

## Défauts

### Bloquants

Aucun.

### Majeurs

Aucun qui ait tenu. C7 a été proposé majeur et ramené à mineur (voir plus bas).

### Mineurs

- **ORD-1. Contre-épreuve de la fiche inexacte.** `test/features/accueil_adulte/accueil_adulte_page_test.dart:488`.
  La fiche dit « 390, 1440 ltr et rtl échouent, 768 passe encore ». Mesuré : 768 échoue aussi,
  sur `findsOneWidget` `GrilleBento`, et 390 n'échoue qu'à cause de cette même assertion.
  Seuls 1440 ltr et rtl échouent aussi sur la géométrie. Le chiffre de l'auteur ne correspond à
  aucun des trois fichiers de test mesurés. L'erreur sous-estime ce que les tests détectent,
  mais c'est un chiffre annoncé sans être mesuré sur l'état livré.
  Correction : écrire dans la fiche « page fa64a6ad : 16/30 tests échouent, dont les 4 tests
  d'ordre ; à 390 et 768 seule l'assertion GrilleBento discrimine, à 1440 la géométrie aussi ».
- **ORD-2. Facteur « × échelle du texte » non testé.** `lib/features/accueil_adulte/accueil_adulte_page.dart:382-384`.
  Mutant M9 survivant (voir plus haut). La règle est écrite dans `DASH_STRATEGIE.md:243`
  (« 360 px × échelle du texte … seuil sans source ») mais elle ne fait pas partie du contrat.
  Le seul test à texte ×2 (l.613-634) appelle `verifierAucunMotCoupe`, qui ne voit pas la
  disposition. Correction : un test 1440 px, texte ×2, qui vérifie `a.top > s.bottom`.
- **M8-1. Le cas U+2011 du test unitaire ne se place pas dans le bon régime.**
  `test/widgets/aucun_mot_coupe_test.dart:22, 59-64`. `TextStyle(fontSize: 16)` sans police
  réelle ni repli : une seule boîte, et l'ancien critère passe (4/0). La garde globale tient
  grâce à l'appelant (6 échecs). Correction : monter le cas avec DMSans +
  `fontFamilyFallback: ['NotoSansArabic']`, hauteur 1.3, ajouter une assertion de contexte
  (au moins 2 boîtes à des `top` différents), puis vérifier que la mutation a fait échouer le
  test.
- **M8-2. Le seuil du « milieu vertical » n'est pas testé.** `test/support/aucun_mot_coupe.dart:89-103`.
  d1, d2 et d3 survivent : les cas « nommé » coupent le mot sur 13 et 7 lignes, jamais sur
  exactement 2. Correction : un cas « Remplacement » coupé sur 2 lignes (16 px, largeur
  0,6 × naturelle, mesuré), attendu nommé. Il tue d1 et d3. La clause symétrique (d2) ne sert
  à aucun cas couvert : lui donner un cas ou la retirer.
- **M8-3. Le cas étroit vérifie seulement `isNotEmpty`.** `test/widgets/aucun_mot_coupe_test.dart:70`.
  À 30 px, « Classe » est déjà coupé, donc l'assertion est vraie quoi que fasse le helper sur
  « An‑Nour » (c2 survit, sonde `[Classe An‑Nour : Classe, Classe An‑Nour : An, Classe An‑Nour : Nour]`).
  Le titre du test promet plus qu'il ne contrôle. Proposé cosmétique, relevé à mineur par la
  contre-vérification. Correction : `contains('Classe An‑Nour : An‑Nour')`.
- **C5. Titre « Ressources de la classe » plus petit à 320×2 et 390×2.**
  `docs/current/captures/BENTO-3/adulte_320x2_clair.png`, `adulte_390x2_clair.png`. Hauteur de
  majuscule environ 16 px à 320×2 et 20 px à 390×2, sur une ligne, contre environ 34 px sur
  deux lignes pour « Mon parcours » et « Dernières séances ». Cause :
  `lib/features/tc_espace_groupe/emplacements_groupe.dart:146-166`, `BlocBibliotheque` en mode
  « empile » (échelle ≥ 1.5, `app_gabarit.dart:71`) enveloppe l'en-tête dans
  `FittedBox(scaleDown)` + `IntrinsicWidth`, qui rétrécit toute la phrase. Antérieur à la
  branche (même code à `fa64a6ad` et `714b09e6`, commits 9c5be750 et 447f9452). BENTO-3b le
  rend seulement visible en allongeant la vue. À ouvrir à part, sur le composant partagé.
- **C7. Mots coupés en pleine lettre sur la capture du Contrôle à 320×2.**
  `docs/current/captures/BENTO-3/controle_320x2_clair.png`. « Classe / à obser / ver mai /
  ntenan / t ». Rendu identique à `714b09e6`. `controle_page.dart` n'est pas modifié dans
  `fa64a6ad..f0252b84`. La capture est faite « pour mémoire » (`bento3_capture_test.dart.txt`
  l.2) et le contrat ne vise que l'accueil adulte. « An- / Nour » se coupe sur le trait
  d'union, ce qui est légitime. Proposé majeur, ramené à mineur. À consigner comme défaut
  ouvert (suite de COUPE-MOTS sur `controle_page`), ou à déclarer dans un LISEZMOI des
  captures, comme `BENTO-1b/LISEZMOI.md:28`.
- **C8. Adresse de courriel coupée sur Mon espace à 320×2.**
  `docs/current/captures/BENTO-3/monespace_320x2_sombre.png`. « mamadou.dia / llo@example. /
  com ». Vient de `lib/features/compte/compte_tuteur_page.dart:352`, inchangé depuis 653ce318.
  Antérieur, hors lot, écran hors Bento. Relève d'un lot compte.

### Cosmétiques

- **F5. Titre et chapeau du recensement périmés après la fusion.**
  `docs/current/BENTO_RECENSEMENT.md:1, 15-24, 26` dans la fusion à blanc `a8889a0c`. Le titre
  et la section disent « BENTO-1 à BENTO-2c » alors que la ligne 33 porte l'accueil adulte
  (BENTO-3). Le paragraphe sur trois et quatre colonnes ne cite pas la page adulte, qui
  applique pourtant `largeurMinCarteClasse`. Le défaut n'existe pas sur la branche seule : il
  naît de la fusion sans conflit. À corriger en poussant la fusion : titre « BENTO-1 à
  BENTO-3 », page adulte ajoutée à la phrase.
- **C4. Liseré violet décroché à 320×2.** `adulte_320x2_clair.png`, x≈16-19, y≈484-505.
  C'est `LisereGroupe` (invariant J7), taille fixe, centré dans la `Row` d'`IdentiteGroupe`
  (`espace_groupe_page.dart:581-595`), donc entre les deux lignes du titre. Présent à
  `fa64a6ad`. Relève de m7. À 1440×2 il est collé au titre (x=288-291, y=345-367).
- **C6. « Cours dans 3 h » / « 28 » à 390×2.** `adulte_390x2_clair.png`. Coupure sur une
  espace ordinaire, aucun mot coupé. Chaîne `assets/i18n/fr.i18n.json:3657`, antérieure.
  Aucune règle écrite n'impose d'espace insécable. Amélioration possible hors lot : U+00A0 ou
  U+202F dans `dansHeures`, `resteHeures`, `heuresMinutes`.

### Écartés ou reclassés par la contre-vérification

- C4 : proposé mineur, ramené à cosmétique (liseré J7 voulu, antérieur, rattaché à m7).
- C6 : proposé mineur, ramené à cosmétique (coupure sur espace, sans règle écrite, antérieur).
- C7 : proposé majeur, ramené à mineur (antérieur, écran hors contrat, capture « pour mémoire »).
- M8-3 : proposé cosmétique, relevé à mineur (titre de test qui promet plus qu'il ne contrôle).

### Vérifié sans défaut (info)

- E1 à E5 : mojibake réparé, `102f9cf6` purement typographique, format propre, noms lisibles,
  arabe légitime laissé en place.
- F1 à F4, F6, F7 : fusion `83e83246` automatique, helper avec les deux apports, rien de la
  branche commune perdu, `DASH_STRATEGIE.md` entre dans la branche commune (qui y renvoie déjà
  sans l'avoir), blocs disjoints avec `f6ac3658`, fusion à blanc verte.
- ORD-4, ORD-5 : mutations d'ordre §3.7 tuées, portée des assertions de `c0fc78d6`
  (une seule `GrilleBento` ; parcours qui chevauche séance et « Avant » à 1440).
- M8-4 : cas 1, 2 et « U+2011 comme coupure » décrits et tués.
- Suite : analyze 0, jetons et revue sans ajout, comptes égaux à l'annonce.

## Captures vues

Images ouvertes par tranches (PIL) sur `f0252b84` :
- `adulte_320x2_clair` et `adulte_320x2_sombre` : « Mamadou » entier, « Dernières séances » et
  « Ressources de la classe » visibles en entier (dernière ressource vers y=4010 sur 4400).
  Aucun débordement sur les 4 bords. On y voit C4 (liseré), C5 (titre Ressources réduit) et m7
  (enseignant au-dessus du nom de classe). « Voir tout » sous le titre. Sombre lisible.
- `adulte_390x2_clair` : Ressources visible, C5 (titre environ 20 px), C6 (« 3 h » / « 28 »).
- `adulte_768x2_sombre` : une tuile par bande, Ressources visible, sombre lisible.
- `adulte_1440x2_clair` et `adulte_1440x2_sombre` : une seule colonne (moitié 552 < 720),
  Ressources visible (fin vers y=2165 sur 2800). m2 toujours présent : « Voir tout » sur sa
  propre ligne. « Mon espace » sur deux lignes dans le rail, coupure à l'espace (C10, info).
- `adulte_320_clair` : m7 inversé par rapport à ×2 (classe puis avatar), « Voir tout » à droite
  du titre.
- `adulte_1440_clair` : « Voir tout » à droite du titre, liseré collé au titre.
- `controle_320x2_clair` : C7 (« à obser / ver mai / ntenan / t »), antérieur.
- `monespace_320x2_sombre` : C8 (courriel coupé), le reste entier et lisible.
- Régénération des 4 variantes adulte 320×2 et 1440×2 : identiques au pixel aux fichiers
  commités. Les captures viennent bien du code de `f0252b84`.

## Fusion dans la branche commune

**Prête.** Base commune avec `origin/corrections/revue-directeur-2026-10` @ `f6ac3658` :
`af20f6c2`. 57 fichiers modifiés côté BENTO-3b, 51 côté branche commune, un seul en commun :
`docs/current/BENTO_RECENSEMENT.md`, avec des blocs disjoints (c2-bento2c : lignes 1-24 ;
BENTO-3 : lignes 33 et 41-48).

- Fusion à blanc locale `a8889a0c` (HEAD détachée, jamais poussée) : arbre `1fcb0d1d`, identique
  à `git merge-tree --write-tree f0252b84 f6ac3658`. Aucune résolution manuelle.
- `grille_bento.dart`, `aucun_mot_coupe.dart` et la page adulte ne bougent que d'un côté.
  `largeurMinCarteClasse` reste 360 après c2-bento2c, même formule dans les deux pages
  (famille l.324-326, adulte l.382-384), et l'import `show largeurMinCarteClasse` se résout.
- `dart analyze --fatal-infos` : No issues found. `dart run slang` : rien à régénérer.
- Suite complète sur la fusion : features 2557, core 648, router 277, widgets 274, autres 1699,
  soit **5455 réussis, 2774 sautés, 0 échec**.
- La fusion fait entrer `docs/current/DASH_STRATEGIE.md` (488 lignes) dans la branche commune,
  qui y renvoie déjà (§3.4, §3.5, D12, DASH-ADM-1).
- À faire en poussant la fusion : corriger le titre et le chapeau du recensement (F5).
  `origin/corrections/revue-directeur-2026-10` est toujours sur `f6ac3658`.

## Laissé ouvert (suivi)

Étapes inscrites au tableau par la session principale à la remise de ce rapport (voir plus bas). Points suivis :

- **m5** : déplacer `largeurMinCarteClasse` de `accueil_famille_page.dart:64` vers
  `core/widgets/grille_bento.dart`. Non fait.
- **Seuil 360** : toujours sans source (`DASH_STRATEGIE.md:243`).
- **m6** : squelette D11 encore en colonnes.
- **m7** : `IdentiteGroupe` à 320 (enseignant au-dessus du nom de classe), avec C4 (liseré
  décroché).
- **m2** : « Voir tout » de Ressources sur sa propre ligne en ×2 et à 1440×2.
- **768 non discriminant par la géométrie (ORD-3)** : à 768 la grille fait 640 px, (640 − 16) / 2
  = 312 < 360, donc même géométrie qu'une colonne. Ajouter un cas où la bascule côte à côte se
  produit à texte ×1 (grille d'au moins 736 px), ou vérifier l'écart vertical de 16 entre bandes.

Étapes proposées :

1. **BENTO-3c (tests, petit)** : ORD-2 (test 1440 texte ×2), ORD-3 (cas de bascule), M8-1,
   M8-2, M8-3 (test unitaire du helper en vraie police, cas sur 2 lignes, `contains`), m5,
   et correction de la fiche (ORD-1).
2. **Composant `BlocBibliotheque`** : C5, remplacer le `FittedBox(scaleDown)` de l'en-tête en
   mode empilé par un retour à la ligne, avec m2.
3. **Suite COUPE-MOTS sur `controle_page`** : C7, avec `verifierEcranSansMotCoupe` sur le
   Contrôle à 320×2.
4. Hors lot, au choix : C8 (courriel dans le compte), C6 (espaces insécables dans les durées).
