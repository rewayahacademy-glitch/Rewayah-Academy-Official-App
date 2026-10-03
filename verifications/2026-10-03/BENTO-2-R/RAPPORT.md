# BENTO-2-R : revue croisée de corrections/c2-bento2 @ 27c57db5

Date : 03/10/2026. Revue en lecture seule (aucun commit, aucun push sur la branche revue).
Worktree : `D:\RA_TUTEUR\r-bento2` (détaché).

## Verdict : REFUSÉ (un défaut majeur)

Le moteur `hauteurContenu` est sain et bien testé, Aujourd'hui est conforme. Mais l'accueil
famille, sur tablette à texte normal, coupe des mots dans la carte de séance. Ce n'était pas le
cas avant BENTO-2. Une seule correction suffit.

## Base du diff

`27c57db5` a pour parent `235b18ab` (fusion BENTO-1b), pas `7c612872`. Le diff
`7c612872..27c57db5` montre donc à tort GALERIE-BENTO-2 « défait » (`tuiles_compteur.dart`,
`tableau_de_bord_page.dart`, captures galerie). Le vrai diff est `235b18ab..27c57db5` : 22
fichiers, `grille_bento.dart`, `journee_page.dart`, `accueil_famille_page.dart`, deux tests, 16
captures et le test de capture en `.txt`. La fusion à blanc (`git merge-tree`) avec
`origin/corrections/revue-directeur-2026-10` (d57ed2b1) passe **sans conflit**.

Aucun fichier interdit touché (pubspec, supabase, .github, thème, Coran). Aucune couleur
ajoutée, aucun `skip` ajouté.

## Défauts

### M1 (majeur) : accueil famille à 768 px, texte ×1 : « Duré / e », « 45 mi / n »

- **Où** : `lib/features/accueil_famille/accueil_famille_page.dart:308-312`. La carte classe
  est une tuile `grande` (2 colonnes sur 4) dès 600 px de place.
- **Preuve** : capture `D:\RA_TUTEUR\captures\BENTO-2-R_2026-10-03\famille_768_ltr_clair.png`.
  La carte fait environ 310 px de large. Sa ligne « 18:10 | Durée 45 min » n'a plus la place et
  coupe les mots au milieu (leçon 8). Avant BENTO-2, la tablette posait la carte en pleine
  largeur (`235b18ab`, ancien `else ...[carte, Ecart.vLg, carteGroupee]`) : c'est donc une
  **régression**, à texte normal, sur une largeur courante.
- **Remède attendu** : la carte classe ne doit jamais être plus étroite que son contenu ne le
  supporte. Deux options : (a) la carte classe en `EtendueBento(4, 2)` tant que la place est
  sous un seuil (par exemple sous 1024) ; (b) un minimum de largeur par tuile dans `_bloc`.
  Ajouter un test à 768 px, ×1 et ×2, qui vérifie qu'aucun mot n'est coupé, et la capture
  correspondante. Aujourd'hui (journee) à 768 est correct (`journee_768_ltr_clair.png`).

### m1 (mineur) : `BENTO_RECENSEMENT.md` n'est pas mis à jour

- **Où** : `docs/current/BENTO_RECENSEMENT.md:21-29`. « Accueil famille » et « Aujourd'hui »
  sont encore « À reprendre ». L'accueil élève y est encore « Candidat direct à
  `GrilleBento` », ce qui contredit D14 (`DASH_STRATEGIE.md` §3.2 l.156, sur
  `corrections/c2-dash1`).
- **Remède** : passer les deux écrans dans « Fait dans ce lot » et noter « pas de Bento (D14) »
  pour l'accueil élève.

### m2 (mineur) : le test « moulinet » ne prouve pas qu'il y a un moulinet

- **Où** : `test/core/grille_bento_test.dart` (groupe BENTO-2, dernier test). Le commentaire
  dit « si le placement forme un moulinet ». Le test vérifie seulement que les 6 tuiles sont
  présentes. Il n'affirme pas que la branche de repli (une colonne) a servi.
- **Remède** : affirmer le placement (`placerBento`) ou que toutes les tuiles ont la pleine
  largeur, pour que la branche de repli soit vraiment couverte.

### c1 (cosmétique) : le bandeau de blocage, nu dans sa tuile 4×1

- **Preuve** : `famille_blocage_1440.png`. Le bandeau n'a pas de surface de carte, alors que
  les autres tuiles en ont une. Sur bureau, il était avant dans la carte groupée. Rien ne
  déborde. Le bouton reste secondaire : c'est la ligne DASH-TUT-CTA, hors BENTO-2.

## 1. Mode `hauteurContenu` (`lib/core/widgets/grille_bento.dart:318-323`, `:355-422`)

- **Pas de hauteur fixe** : `_bloc` n'emploie que des `Column`, des `Row` et des `SizedBox`
  de **largeur**. Aucune hauteur n'est posée, donc aucun texte n'est réduit ni rogné.
- **Pas de débordement horizontal** : les largeurs de la `Row` (`largeur(x - debut) + ecart +
  largeur(fin - x)`) redonnent exactement la largeur du parent. `placerBento` ne laisse aucun
  trou, donc `fin` vaut le nombre de colonnes.
- **Ordre de lecture** : une coupe horizontale d'abord (le dessus, puis le dessous), sinon une
  coupe verticale (le début, puis la fin). Les tuiles sont toujours prises dans l'ordre déclaré.
- **RTL** : la `Row` suit `Directionality`. Le test RTL (`grille_bento_test.dart`, boucle
  `TextDirection.values`) et mes captures RTL (`journee_1440_rtl_clair.png`,
  `famille_1440x2_rtl_sombre.png`) montrent le miroir : rang 1 à droite.
- **Rien n'est perdu au changement de colonnes** : à 1 colonne, chemin inchangé ; à 2 colonnes,
  une `haute` seule s'élargit (règle sans trou). Une disposition sans coupe possible repasse en
  une colonne dans l'ordre déclaré : toutes les tuiles restent affichées (voir m2 pour la
  preuve par test).
- Les tuiles d'une bande sont alignées en haut : à 1440, un vide reste sous Ma journée, à côté
  de la carte. C'est voulu et documenté (l.240), pas un défaut.
- Note pour la suite : BENTO-1c (4 → 3 → 2 → 1, sur `c2-dash1`) n'est pas encore dans la
  branche commune. `_bloc` supporte 3 colonnes (par élargissement sans trou). Il faudra
  recapturer à la fusion.

## 2. Conformité à DASH_STRATEGIE.md (lu sur `origin/corrections/c2-dash1`)

**§3.5 Aujourd'hui (`journee_page.dart:363-376`)** : Prochaine séance grande 2×2 ;
Remplacement large 2×1 / 2×1, une tuile par remplacement ; Ma journée haute 1×2 / 2×2 ;
À terminer grande ; Alertes large. Rangs et tailles **conformes**. La frise n'est pas bornée
(D6 a). À 1440 sans remplacement, À terminer prend toute la largeur (élargissement sans trou),
ce qui est cohérent avec le test. La limite « 3 remplacements au plus » n'est pas dans ce lot
(DASH-ENS-REMPL).

**§3.4 Accueil famille (`accueil_famille_page.dart:303-321`)** : bandeau large 2×1 / 4×1,
carte grande, Avant le prochain cours grande, Dernière séance large 2×1 / 4×1, sélecteur hors
grille. Rangs et tailles **conformes**. La tuile-lien et le bouton « Connecter un appareil » en
primaire relèvent de DASH-TUT-CTA, hors lot.

## 3. Captures `docs/current/captures/BENTO-2` (16, toutes ouvertes)

- **journee 1440 ×1 clair et sombre** : en haut, le titre ; à gauche et à droite, une gouttière
  de 152 ; en bas, du vide. Carte à gauche, Ma journée à droite, À terminer en pleine largeur
  dessous, 16 entre les deux. Aucun débordement.
- **journee 1440 ×2 clair et sombre** : même disposition, la carte passe en clé et valeur
  empilées, les quatre bords sont nets. Les icônes de la frise ne grandissent pas avec le texte
  (c'était déjà le cas avant).
- **journee 390 ×1 clair et sombre** : une colonne, cartes à 12 des bords, 16 entre les blocs.
- **journee 390 ×2 clair et sombre** : une colonne, rien ne sort à droite. **« À termi / ner »**
  est coupé. Le défaut existait avant (déjà relevé par VERIF-CORR-3 à 320 ×2, en-tête inchangé
  par ce lot), mais il se voit aussi à 390 ×2. Il est à porter au chantier COUPE-MOTS, pas
  compté contre BENTO-2.
- **famille 1440 ×1 clair et sombre** : carte et Avant le prochain cours côte à côte, Dernière
  séance en 4×1, 16 d'écart, la barre latérale à gauche est entière.
- **famille 1440 ×2 clair et sombre** : même grille. La barre montre « Reway… » (connu,
  COUPE-MOTS-1, pas compté).
- **famille 390 ×1 et ×2, clair et sombre** : une colonne. À ×2, « Aj » est rogné à droite
  dans le sélecteur de profils, qui défile (c'était déjà le cas avant).

**Variantes manquantes au regard de K-61** : 320, 768 et RTL, plus les états avec blocage,
remplacement ou alertes. Je les ai refaites (ci-dessous). Les captures du lot couvrent un seul
état par écran.

## Captures de la revue (`D:\RA_TUTEUR\captures\BENTO-2-R_2026-10-03\`)

Test temporaire copié dans `test/capture/`, lancé avec `CAPTURE_DIR`, puis retiré.
`windows/flutter` a été restauré. 18 sur 18 passent, sans exception.

- `journee_320_ltr_clair`, `journee_320x2_*` : une colonne, aucun débordement. (À 320 ×2,
  « À terminer » reste coupé : défaut connu, VERIF-CORR-3.)
- `famille_320x2_ltr_sombre` : une colonne, même composition qu'avant. On y voit « Duré / e »
  et « Historiq / ue » dans la barre du bas : défaut préexistant (même largeur qu'avant le
  lot), à porter à COUPE-MOTS.
- `journee_768_*` : correct.
- `famille_768_ltr_clair` : **M1**.
- `famille_768x2_ltr_clair` : une colonne, correct.
- `*_rtl_*` : le miroir est correct. La ponctuation française déplacée (« .relié ») vient de
  mon forçage du RTL sur une locale française, pas du lot.
- `famille_blocage_390`, `famille_blocage_1440` : le bandeau est en premier et pleine largeur,
  16 sous lui ; voir c1.

## 5. Tests (sous verrou, journaux dans `D:\RA_TUTEUR\yaaden-cache\BENTO-2-R\`)

- `flutter test test/features/journee_test.dart test/features/accueil_famille_test.dart
  test/core/grille_bento_test.dart test/accessibilite/rtl_echelle_texte_ecrans_test.dart
  test/widgets` : **402 réussis, 0 échec, 0 sauté** (`tests.log`).
- `flutter analyze` : **0 problème** (`analyze.log`).

## 4. « Pas de Bento pour l'accueil élève » (D14)

**Justifié.** D14 dit : 2 tuiles ou moins, pas de Bento. `accueil_eleve_page.dart:218-228` ne
rend que deux blocs (`_BlocPrincipal`, `_BlocCoran`) et le commentaire l.118 dit « Deux blocs,
rien d'autre ». Le Mode Accessibilité garde une colonne linéaire pour n'avoir qu'un seul ordre
de lecture (§3.3). Seul `BENTO_RECENSEMENT.md` contredit encore cette décision (m1).

## Pour accepter

1. Corriger M1 : la carte classe de l'accueil famille ne coupe aucun mot à 600-1024 px, à
   ×1 et ×2. Ajouter un test et une capture à 768.
2. Recommandé : m1 (recensement) et m2 (test du moulinet).
