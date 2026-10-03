# BENTO-1c-R : revue croisée de BENTO-1c (grille Bento, palier à 3 colonnes) et du point D12

- Relu en lecture seule : `corrections/c2-bento1c` @ `e7b94c3a` (diff `27c57db5..e7b94c3a`, 4 fichiers) dans `D:\RA_TUTEUR\r-bento1c` (détaché), et `corrections/c2-dash1` @ `9931897a` (D12 + `BENTO_RECENSEMENT.md`). 03/10/2026, vers 12 h 20.
- Rien n'a été commité ni poussé. Le test temporaire (`test/_revue_bento1c/`) a été retiré. `windows/flutter/generated_*` ont été restaurés. `git status` est propre à `e7b94c3a`.
- Captures hors dépôt : `D:\RA_TUTEUR\captures\BENTO-1c-R_2026-10-03\` (33 PNG). Journaux : `D:\RA_TUTEUR\yaaden-cache\BENTO-1c-R\`.

## Verdict

**Accepté. 0 bloquant, 0 majeur, 3 mineurs, 2 cosmétiques.** Deux défauts sont hors lot ; ils sont signalés à part.

## 1. Tables de colonnes, recalculées à la main

Règle à `e7b94c3a` (`grille_bento.dart:281-291`). On part de 4 colonnes si la largeur atteint 600 px, sinon de 2. Si l'échelle du texte est de 1 ou moins, on s'arrête là. Sinon, on enlève une colonne tant que la cellule `(L − 16·(n−1)) / n` est plus petite que `112 × échelle`. Les seuils valent 128,8 (×1,15), 145,6 (×1,3), 168 (×1,5), 196 (×1,75) et 224 (×2).

**Test unitaire `_colonnesAttendues`** (`grille_bento_test.dart`) :

| L | cellule à 4 | cellule à 3 | cellule à 2 | ×1 | ×1,15 | ×1,3 | ×2 |
|---|---|---|---|---|---|---|---|
| 320 | (base 2) | – | 152 | 2 | 2 (152 ≥ 128,8) | 2 (152 ≥ 145,6) | 1 (152 < 224) |
| 600 | 138 | 189,3 | 292 | 4 | 4 (138 ≥ 128,8) | **3** (138 < 145,6 ; 189,3 ≥ 145,6) | 2 (189,3 < 224 ; 292 ≥ 224) |
| 1024 | 244 | | | 4 | 4 | 4 | 4 (244 ≥ 224) |
| 1440 | 348 | | | 4 | 4 | 4 | 4 |

Ces valeurs sont celles du test. La table des pages réelles du même fichier est aussi exacte. Le cas 800 px ×2 sur une grille de 752 px donne 3 colonnes : la cellule à 4 fait 176 (< 224), celle à 3 fait 240 (≥ 224). Le cas 1024 ×2 sur 976 px donne 4 colonnes (cellule 232 ≥ 224). Le cas 320 ×1,3 sur 288 px donne 1 colonne (cellule 136 < 145,6). Le cas 600 ×2 sur 552 px donne 2 colonnes (base 2, cellule 268 ≥ 224).

**Vraie application** (vraie coquille, démonstrations, vraies polices), à comparer avec la mesure :

| vue | grille | ×1 | ×1,15 | ×1,3 | ×1,5 | ×1,75 | ×2 |
|---|---|---|---|---|---|---|---|
| 1440 admin | 1088 (cellule 260) | 4 | 4 | 4 | 4 | 4 | 4 |
| 1280 admin | 928 (220 / 298,7) | 4 | 4 | 4 | 4 | 4 | **3** |
| 1280 famille/journée | 960 (228) | 4 | 4 | 4 | 4 | 4 | 4 |
| 1024 | 896 (212 / 288) | 4 | 4 | 4 | 4 | 4 | **3** |
| 800 | 672 (156 / 213,3 / 328) | 4 | 4 | 4 | **3** | **3** | 2 |
| 768 | 640 (148 / 202,7 / 312) | 4 | 4 | 4 | **3** | **3** | 2 |
| 390 | 358 (171) | 2 | 2 | 2 | 2 | 1 | 1 |
| 360 | 328 (156) | 2 | 2 | 2 | 1 | 1 | 1 |
| 320 | 288 (136) | 2 | 2 | 1 | 1 | 1 | 1 |

Les 144 cas mesurés (3 rôles, 8 largeurs, 6 échelles) donnent exactement ces nombres de colonnes. Aucune exception de mise en page, aucun « overflowed » dans le journal (`mesure.log`).

## 2. Rien ne change à texte 100 % ? Comparaison avec `27c57db5`

- À `27c57db5`, le minimum valait `112 × max(1, échelle)`. À 100 %, deux colonnes passaient donc à une sous 240 px de place (`(L − 16)/2 < 112`). Quatre colonnes ne tombaient jamais, puisque 600 px donnent une cellule de 138.
- À `e7b94c3a`, quand l'échelle vaut 1 ou moins, la fonction rend 2 ou 4 colonnes sans autre condition (`:284`). Seule la place nulle (16 px ou moins) donne 1 colonne (`:282`), comme avant.
- **Écart réel avec 27c57db5 : de 17 à 239 px de place, à 100 %, on avait 1 colonne et on en a maintenant 2.** Partout ailleurs le comportement est identique. Le changement est voulu, écrit dans le message de commit et dans la documentation (« même dans une place étroite »), et testé (`colonnesPour(200) == 2`). Il remet le comportement d'avant BENTO-1b.
- Effet sur les vraies compositions : **aucun**. La grille la plus étroite mesurée fait 288 px (vue 320). À 100 %, les captures `admin_320x1_clair.png` et `*_1440x1_clair.png` gardent 2 et 4 colonnes, comme avant. Voir le mineur m-A.

## 3. Palier à 3 colonnes avec `etendueLarge`, sur les vraies compositions

`TuileBento.pour` donne l'étendue large à partir de 3 colonnes (`:74-75`), et `placerBento` ramène une étendue de 4 à 3 (`:144`). Placements calculés à la main, puis vérifiés en capture :

- **Centre de commande, calme** (grande, haute, carrée, carrée, double 4×1 → 3×1). Rangées 0-1 : la grande 2×2 et la haute 1×2. Rangée 2 : une carrée, puis une carrée élargie à 2 par la règle « la tuile de gauche s'élargit ». Rangée 3 : la double sur 3 colonnes. Aucun trou. Confirmé par `admin_1280x2_clair.png`, `admin_1280x2_sombre.png`, `admin_1280x2_rtl.png` et `admin_768x1_5_clair.png`.
  - Bords (1280 ×2) : en haut, le titre « Centre de commande » est entier. À gauche, la barre latérale de 288 px, puis la grille à 320. À droite, la grille finit à 1248, soit une marge de 32. En bas, « À traiter en premier » et sa liste suivent, coupés seulement par la hauteur de la capture. Écart de 16 px visible entre toutes les cartes (K-55). Aucun mot coupé dans la grille.
  - En RTL, tout est en miroir : la grande à droite, la haute à gauche, la carrée élargie à gauche.
  - Bords (768 ×1,5) : rail à gauche, grille de 104 à 744, titre sur deux lignes sans mot coupé. Les 3 colonnes sont visibles, la grande garde ses trois noms en aperçu.
- **Centre de commande, non calme** (calcul seul, la démo est calme) : incidents et accès échus, en large 2×1, sont chacun étirés à 3×1. Deux bandes pleine largeur, sans trou.
- **Aujourd'hui** (grande, [larges], haute→grande, grande, large). À 3 colonnes, aucune tuile de 2 ne laisse une voisine de 1 se placer à côté. La colonne 3 est comblée et chaque tuile passe à 3 de large. Le résultat est le même qu'à 2 colonnes : des bandes pleine largeur dans l'ordre déclaré. Rien n'est réduit, Ma journée n'est jamais à un tiers. Confirmé par `journee_768x1_5_clair.png`, sans débordement ni carte collée.
- **Accueil famille** (bandeau 4×1→3, grande, grande, large 4×1→3) : même effet, quatre bandes pleine largeur. Confirmé par `famille_768x1_5_clair.png`, sans débordement.
- Le palier à 3 sert donc vraiment le Centre de commande, où la 2×2 reste avec une voisine. Pour Aujourd'hui et la famille, il donne la même chose que 2 colonnes. Ce n'est pas un défaut, mais la phrase « la grande tuile 2×2 reste » est générale (voir c-2).

## 4. D12 et `BENTO_RECENSEMENT.md`

- `BENTO_RECENSEMENT.md` est le même blob (`eca26ef5`) sur `c2-bento1c` et dans `9931897a`. Les deux branches disent la même chose.
- Le contenu correspond au code : 2 ou 4 colonnes selon 600 px ; écart 16 ; ligne 160 × échelle ; 112 px × échelle ; 4 → 3 → 2 → 1 seulement au-dessus de 100 % ; étendue large à partir de 3 colonnes ; à 1440 ×2, plusieurs colonnes (mesuré : 4) ; à 320 ×2, une seule (mesuré).
- D12 (`DASH_STRATEGIE.md`, `9931897a`) : les noms `colonnesPour`, `hauteurLignePour` et `hauteurContenu`, le seuil 112 « à faire valider », « à 100 % ou moins rien ne change » et « en une colonne, hauteur libre » sont exacts. Deux scories : c-1 et m-B.

## 5. Le mineur m1 de BENTO-1b-R (réduction par FittedBox entre deux paliers) : il ne reste pas

J'ai refait la mesure de BENTO-1b-R (même méthode : vraie application, coquille admin, facteur de chaque `FittedBox` de la grille), deux fois :

- **Sans charger les polices du dépôt**, comme le test de BENTO-1b-R (`mesure_test.dart.txt` n'appelle pas `chargerPolicesDuDepot`) : on retrouve les mêmes chiffres. 768 ×1,3 → 0,93 (1,21 effectif) ; 360 ×1,15 → 0,94 ; 390 ×1,3 et 360 ×1,3 → 0,97 ; 1024 ×1,75 → 0,96. Il s'y ajoute 768 ×1,75 à 3 colonnes → 0,96 (`sanspolices.log`).
- **Avec les vraies polices** (`chargerPolicesDuDepot`, ce que l'application dessine) : **0 tuile réduite sur les 48 cas admin**, palier à 3 compris (`mesure.log`).
- Conclusion : m1 venait de la police de test de Flutter, dont les glyphes carrés sont bien plus larges, et non de la grille. **m1 ne reste pas.** Il faut le fermer, sans relever `largeurMinCellule`.
- Les captures `admin_768x1_3_clair.png` (4 colonnes) et `admin_390x1_3_clair.png` (2 colonnes) le confirment : texte à la taille demandée, rien de coupé.
- Pour l'accueil famille, la mesure trouve 2 `FittedBox` réduits jusqu'à 0,57 à ×2, même en une colonne. Ce sont les portraits (`avatar_nom.dart:437`), qui se réduisent par conception dans une case de taille fixe. Cela ne vient pas de la grille et n'est pas touché par ce lot.

## 6. Tests et analyse (sous le verrou)

- `flutter test test/core/grille_bento_test.dart test/features/tableau_de_bord_test.dart test/features/journee_test.dart test/planning/journee_test.dart test/widgets` : **357 réussis, 0 échec** (`tests.log`).
- `flutter test test/capture/bento_capture_test.dart test/core/grille_bento_test.dart` avec `CAPTURE_DIR` : **59 réussis** (`capture.log`, PNG dans `…\bento_capture\`).
- `dart analyze` des trois fichiers Dart touchés : 0 remarque.
- Diff : 4 fichiers (`grille_bento.dart`, `journee_page.dart`, `grille_bento_test.dart`, `BENTO_RECENSEMENT.md`). Aucun fichier interdit, aucune couleur ajoutée, aucun `skip` ajouté.

## Défauts

| # | Gravité | Lieu | Problème | Remède attendu |
|---|---|---|---|---|
| m-A | mineure | `grille_bento.dart:284` | À 100 % ou moins, une place de 17 à 239 px garde 2 colonnes (cellule < 112 px) alors que `27c57db5` donnait 1 colonne. Aucune vraie composition n'est concernée (288 px au minimum), mais une grille dans un panneau étroit réduirait ses tuiles par `FittedBox`. | Faire trancher par le directeur. Soit garder ce choix tel qu'il est écrit, soit remettre un plancher de largeur indépendant de l'échelle (par exemple 1 colonne sous 240 px). |
| m-B | mineure | `DASH_STRATEGIE.md` D12 (`9931897a`) | Le renvoi `BENTO_RECENSEMENT.md:3-7` est périmé : la règle occupe maintenant les lignes 3 à 16. | Remplacer par `BENTO_RECENSEMENT.md:3-16`. |
| m-C | mineure | `BENTO_RECENSEMENT.md:3-16`, D12 | « la grande tuile 2×2 reste » ne vaut que pour le Centre de commande. Pour Aujourd'hui et l'accueil famille, le palier à 3 donne des bandes pleine largeur, comme à 2 colonnes (calcul §3, captures `journee_768x1_5_clair.png`, `famille_768x1_5_clair.png`). | Ajouter une demi-phrase : « (Centre de commande ; Aujourd'hui et Famille restent en bandes pleine largeur) ». |
| c-1 | cosmétique | D12 (`9931897a`) | Il y a deux espaces avant « ; » dans « (seuil sans source, à faire valider)  ; ». | Garder une seule espace. |
| c-2 | cosmétique | `journee_page.dart:337` | Le commentaire dit encore « Ma journée haute (grande sur quatre colonnes) » ; c'est maintenant à partir de trois. | Écrire « grande à trois colonnes et plus ». |

## Hors lot (déjà présents, à router)

- **Mots coupés dans la coquille enseignant** (leçon 8), à 768 ×1,5 et 1280 ×2 : « Aujourd / 'hui », « Disponi / bilités » dans le rail, et « Aujourd'hu / i », « Disponibili / tés », « …Reway » dans la barre latérale RTL (`journee_768x1_5_clair.png`, `journee_1280x2_rtl.png`). → COUPE-MOTS-1.
- « Administrat / eur » en bas de la barre admin à ×2 (`admin_1280x2_*.png`) : c'est le m2 de BENTO-1b-R, toujours présent. → COUPE-MOTS-1.
- En RTL dans le harnais, les textes non traduits restent en français, et la ponctuation part au mauvais bout (« .une réponse »). Ce n'est pas lié à la grille.

## Questions pour le directeur

1. À 100 %, une place de moins de 240 px doit-elle garder 2 colonnes (choix de BENTO-1c) ou repasser à 1 (comportement de BENTO-1b) ?
2. Le seuil de 112 px × échelle reste « sans source » : faut-il le valider tel quel ? Avec les vraies polices, la mesure ne trouve aucune réduction.
