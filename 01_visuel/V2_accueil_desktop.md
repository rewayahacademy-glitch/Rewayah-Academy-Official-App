# V2 - Accueil tuteur desktop (clair) et planche tablette + desktop (sombre)

Agent de relevé visuel, phase lecture seule, 24/09/2026. Aucun fichier du dépôt modifié.
Sources lues : `pilotage-tuteur-v1/BRIEF.md`, mandat `REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§2, §4, §5 Accueil/Historique, §8, §9, complément observation §1-2).

## 0. Manifeste

| # | Fichier | Zone (px) | Écran | Route logique (§4) | État | Thème | Format | Statut |
|---|---|---|---|---|---|---|---|---|
| A | `tutuor image\acceuil tuteur desktop light.png` (1774×887) | image entière | Accueil tuteur + shell desktop (rail déplié) | `/tuteur/accueil` | Nominal jour J, T-13 min, salle ouverte, blocage « aucun appareil », 3 tâches, dernière séance présente | Clair | Desktop ≈ 1440 dp | Nouveau high-fi |
| B | `tutuor image\acceuil tuteur desktop dark.png` (1774×887) | x 36-642, y 36-872 (libellé « TABLETTE » en 42,12) | Accueil tuteur + shell tablette (rail replié) | `/tuteur/accueil` | Identique à A (données identiques) | Sombre | Tablette portrait ≈ 690×960 dp | Nouveau high-fi (planche 2 formats) |
| C | même fichier que B | x 677-1740, y 40-838 (libellé « DESKTOP / WEB » en 680,12) | Accueil tuteur + shell desktop (rail déplié) | `/tuteur/accueil` | Identique à A | Sombre | Desktop étroit ≈ 1100 dp | Nouveau high-fi (planche 2 formats) |

Les libellés « TABLETTE » et « DESKTOP / WEB » (texte blanc sur fond de planche) sont des annotations de planche, pas de l'UI.

Tuiles de lecture produites et ouvertes (toutes lues avec Read) : `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles_V2\` : `L_01_rail_haut`, `L_02_selecteur`, `L_03_topright`, `L_04_carte_haut`, `L_05_carte_bas`, `L_06_col_droite_haut`, `L_07_col_droite_bas`, `L_08_rail_bas`, `L_zoom_typo`, `D_T01_tab_haut`, `D_T02_tab_carte`, `D_T03_tab_bas`, `D_T04_tab_rail`, `D_D01_rail`, `D_D02_selecteur`, `D_D03_carte`, `D_D04_col_droite` (.png).

### Méthode et échelle

- Couleurs : `System.Drawing.GetPixel`. Surfaces = couleur modale d'une zone. Textes et icônes = médiane des 4 % de pixels les plus éloignés du fond local (« encre »). Les extrêmes bruts sont faussés par un halo de netteté autour des glyphes : les images semblent générées, avec un liseré blanc autour des textes clairs.
- Échelle A : le CTA (y 708-767 = 59 px) et la pastille de nav active (y 108-168 = 60 px) valent 48 dp. On obtient **1,232 px/dp**, soit une largeur de **≈ 1440 dp**.
- Échelle C : les hauteurs de texte valent environ 0,78 × celles de A (titre 24 vs 31 px, « Prochaine séance » 17 vs 22, « 13:45 » 29 vs 35). On obtient **≈ 0,96 px/dp**, soit un cadre de 1060 px ≈ 1100 dp.
- Échelle B : hauteurs de texte ≈ 0,71 × A, soit **≈ 0,87 px/dp**, et un cadre de 604×834 px ≈ 690×960 dp.
- Précision annoncée : ±10 % sur les dp et ±2 dp sur les rayons. Ces valeurs sont des estimations d'image, pas une spécification.

---

## 1. Shell desktop / tablette (relevé demandé par le coordinateur)

### 1.1 Rail déplié (A clair, C sombre)

- **Conteneur shell** (A) : carte arrondie posée sur un fond de page lavande très pâle. Retrait de 22 px à gauche et à droite (≈ 18 dp) et de 12 px en haut et en bas (≈ 10 dp). Rayon ≈ 24 px (≈ 20 dp), bordure de 1 px `#F0F0F8` en (21,450). En C, cadre à bordure `#3E3F4D` (679,450) et rayon ≈ 14 px. **Probable cadre de présentation** : à décider par le coordinateur, sans le reproduire par défaut en plein écran web.
- **Largeur du rail** : A x 23-305 = 284 px ≈ **230 dp**. C x 682-874 = 192 px ≈ **200 dp**. Séparateur vertical de 1 px : A `#F4F4FA` (307,450), C `#393948` (875,450).
- **En-tête du rail** : mot-symbole « Rewayah » (gras, ≈ 22-24 dp, quasi-noir en A, blanc en C) aligné à gauche, et **bouton de repli « « »** à droite. Ce bouton est un cercle de 41 px ≈ 33 dp : fond `#F7F7FC`, bordure `#E9E9F2` (246,58), icône `#575979` en A ; bordure `#3E3E51` (824,90) et icône `#FBFCFE` en C. **Cible < 48 dp** : agrandir la zone tactile.
- **Destinations** (haut) : Accueil, Foyer, Historique. **Compte est épinglé en bas** du rail (A y ≈ 815, C y ≈ 797). Cela fait **4 destinations dans l'ordre exigé** Accueil · Foyer · Historique · Compte (§4), conforme au mandat.
- **Items** : icône pleine (style « fill », proche de Phosphor Fill : maison, groupe de trois personnes, deux carrés empilés, silhouette), puis libellé. Pas vertical ≈ 72-74 px ≈ 60 dp (centres y 138 / 210 / 284 en A).
- **Item actif** :
  - A : pastille pleine pâle `#F1ECFD` (180-270,112-124), x 45-287 × y 108-168, soit ≈ 196×49 dp, rayon ≈ 12-14 dp. Icône `#7B48ED` (62-92,124-154) et libellé `#5C2CE1` (120-190,128-148).
  - C : pastille pleine saturée `#BA98FB` (800-850,150-175), ≈ 180×49 dp, icône `#252435` et texte `#0B011C` (sombres sur l'accent).
- **Items inactifs** : A libellé `#2F3261` (Foyer, 120,200) / `#2F3165` (Historique) et icône `#6F6E8C` ; C libellé `#D8D9E5` (744,212) et icône `#DFDFEF`.
- Anomalie A : le libellé « Compte » est plus bleu (`#201F76`, 118-193,805-827) que Foyer et Historique. C'est un artefact de génération : **utiliser le même jeton que les autres items**.
- L'icône Historique (deux carrés empilés) est sémantiquement faible (proche de « copier »). À valider par le coordinateur, qui peut garder la forme ou lui préférer une horloge-historique de la même famille.

### 1.2 Rail replié (B tablette)

- Largeur x 41-111 = 70 px ≈ **80 dp**, fond `#242531` (50-100,400-700), séparateur à x ≈ 112-114.
- En haut, bouton **« » »** (déplier), icône `#F9F8FD` sur fond `#282834`.
- Items en icônes seules, dans le même ordre. L'actif est une **tuile carrée arrondie** pleine `#BA98FB` (x ≈ 46-105, y 110-167, ≈ 68×66 dp, rayon ≈ 12 dp) avec la maison `#272436`. Les inactifs `#E1E1F0` / `#D9DAE9`. Compte est épinglé en bas (y ≈ 820).
- **Aucun libellé visible** : infobulle, `Semantics(label:)` et focus visible sont obligatoires (§9).
- Comportement déduit : rail déplié sur desktop et replié sur tablette, avec bascule « / » manuelle. La planche ne fixe pas les seuils de largeur : c'est au coordinateur de les décider.

### 1.3 Barre d'en-tête de page (A, B, C)

- À gauche, titre de page « Accueil ». À droite, **sélecteur de thème segmenté** (soleil / lune), puis la **cloche**.
- Sélecteur de thème en A : conteneur x 1499-1642 × y 33-79 (≈ 116×37 dp), bordure `#EAEAF4`, fond `#FDFDFE`, forme en pilule. Segment actif (soleil) x 1506-1570 × y 38-76 (≈ 52×31 dp) en `#EAE2FD` (1512-1527,48-68), soleil `#7145E8` et lune inactive `#686988`.
- Sélecteur de thème en C et B : conteneur `#2B2B38`, segment actif (lune) `#B894FB` (1600-1630,72-92) avec lune `#160D27`, soleil inactif `#9995D0`.
- **Segments de 31 dp de haut, inférieurs à 48 dp** : agrandir la zone tactile.
- Pas d'option « Système » visible. Le mandat place « apparence » dans Compte > Préférences : ce sélecteur doit piloter **la même préférence**, et l'absence du mode système est à trancher.
- Cloche en trait (outline) : A `#646788` (1682-1712,45-77), C `#D3D5E7`. **Point non lu** accent : A `#9D76F6` (1710,41, ≈ 10-11 dp), C `#BB94F8` / `#CDABFF`. Le point ne doit refléter que de vraies notifications non lues (route `/tuteur/notifications`), jamais un décor.

---

## 2. Fiche A - Accueil desktop clair (image entière)

### 2.1 Composition, de haut en bas

1. **En-tête** (y 30-90) : « Accueil » (x 350, baseline y 73) · sélecteur de thème · cloche.
2. **Sélecteur de profils** (y 100-240), aligné à gauche, 5 éléments à pas de ≈ 167 px (≈ 136 dp), centres x 412 / 577 / 744 / 912 / 1081 :
   - avatar circulaire ≈ 90 px (≈ 73 dp), silhouette générique `#D2D3E0` sur fond `#F6F6FB`, bordure 1 px `#E5E5F0` (532-538,125-165) ;
   - profil actif (Mariam) : **anneau accent 2 px** `#9974F5` / `#AA8EF7` (367,145) ;
   - pastille de statut en bas à droite (≈ 16 px ≈ 13 dp) avec liseré blanc de 1-2 px ;
   - prénom en gras (≈ 16 dp, quasi-noir), sous-titre ≈ 14 dp. Le sous-titre de l'actif est en accent `#693DE2`, les autres en gris-bleu `#494B6E` / `#414169` ;
   - dernier élément : cercle vide bordure `#E4E4EF` (trait plein) avec « + » `#9292AB` et libellé sur deux lignes `#383A69`.
3. **Deux colonnes** (y 268-856, ≈ 477 dp de haut), gouttière 20 px (≈ 16 dp), proportion ≈ 62 / 38 :
   - **Colonne gauche = carte « séance »** : x 331-1194 (≈ 700 dp), fond teinté lavande `#F7F5FE` (600-900,300-340), bordure 1 px `#EDEEF9` (331,600), rayon ≈ 14 dp, padding ≈ 28 dp.
     1. En-tête élève/classe : monogramme « M » dans un cercle ≈ 77 dp (fond `#E8E0FD`, lettre `#7747E9`), puis sur 4 lignes « Mariam » (≈ 26 dp semi-gras), « Classe An-Nour » (≈ 20 dp gras), « Sayyida Amina » (≈ 18 dp, `#62627E`), « Règles de lecture • Niveau 1 » (≈ 15 dp, `#6C6E8A`).
     2. Séparateur horizontal 1 px `#E8E6F4` (900,451).
     3. Ligne titre : « Prochaine séance » (≈ 22-24 dp gras) à gauche et pastille « Salle ouverte » à droite. La pastille mesure x 984-1155 × y 472-516 (≈ 139×36 dp, en pilule) : fond `#E3F2EF`, point `#03C16C` et texte `#087F43`.
     4. Bloc horaire : « 13:45 » (chiffres de 35 px ≈ 40 dp, gras) avec en dessous « Lundi 21 septembre • Heure de Paris » (≈ 18 dp, `#52537C`). Séparateur vertical `#AEAEC6` (830, y 548-615), puis « Durée » (≈ 15 dp, `#404375`) et « 1 h 30 » (≈ 25 dp gras).
     5. Ligne compte à rebours : icône horloge en trait `#727390` et « Début dans 13 min » (≈ 18 dp gras).
     6. **CTA principal pleine largeur** « Voir la classe → ». Il mesure x 366-1160 × y 708-767 (≈ 645×48 dp) : fond **lavande doux** `#DFD2FD` (400-600,715-725), texte et flèche quasi-noirs (≈ 17 dp semi-gras), rayon ≈ 12-14 dp.
     7. Ligne d'aide : icône écran + téléphone en trait `#717290`, suivie de « Tablette ou ordinateur conseillé. Téléphone accepté. » (≈ 14-15 dp, `#6D6E8C`).
   - **Colonne droite = carte blanche** : x 1214-1736 (≈ 424 dp), fond `#FDFDFE`, bordure `#F0F1F8` (1214,600), rayon ≈ 14 dp, padding ≈ 25 dp.
     1. **Bloc blocage** : grande icône appareils **orange** `#EC9100` (1255-1310,305-360), puis le titre « Aucun appareil prêt pour Mariam » (≈ 18 dp gras), le corps « Connectez un appareil pour éviter tout problème. » (`#63647F`, 2 lignes) et le lien souligné accent « Connecter un appareil » (`#6437E5`), sans flèche.
     2. Séparateur `#EEEEF6` (1500,453).
     3. « Avant / Après la séance » (≈ 22 dp gras) et le lien « Voir tout → » (accent `#6C3DE5`, ≈ 16 dp).
     4. Trois lignes de liste (pas 50 px ≈ 41 dp) : case ronde vide en trait `#6E708E` (≈ 24 dp), texte ≈ 16 dp `#3B3D71`, séparateurs `#F1F2F8`-`#EDEDF6` en retrait sous le texte.
     5. Séparateur.
     6. « Dernière séance » (≈ 21-22 dp gras) et « Voir l'historique → » (accent `#7144E6`). Puis « 18 septembre • 1 h 30 » (`#60617F`) et la pastille « Présente » : x 1596-1705 × y 745-781 (≈ 88×29 dp, en pilule), fond `#E4F6EE`, texte `#08541D`.
     7. Séparateur, puis « Détails et connexion › » en gris `#626484` avec un chevron.

### 2.2 Iconographie, densité, surfaces

- Deux familles d'icônes : **pleines** pour la navigation, **en trait (outline) 1,5-2 px** pour le contenu (horloge, écrans, cloche, cases, flèches, soleil, lune). L'icône appareils orange est en trait épais et colorée.
- Densité aérée : un seul niveau de carte (pas de cartes imbriquées), séparateurs fins et typographie hiérarchisée. C'est conforme à §9 (« moins de cartes imbriquées »).
- Aucune ombre perceptible : les surfaces se distinguent par la teinte et une bordure de 1 px.

### 2.3 Textes lisibles (exacts)

`Rewayah` · `Accueil` · `Foyer` · `Historique` · `Compte` · `Accueil` (titre) · `Mariam` / `Dans 13 min` · `Yusuf` / `Session 18:00` · `Aïcha` / `Dernière séance 1 h` · `Adam` / `Absente` · `Ajouter` / `enfant` · `M` · `Mariam` · `Classe An-Nour` · `Sayyida Amina` · `Règles de lecture • Niveau 1` · `Prochaine séance` · `Salle ouverte` · `13:45` · `Lundi 21 septembre • Heure de Paris` · `Durée` · `1 h 30` · `Début dans 13 min` · `Voir la classe` · `Tablette ou ordinateur conseillé. Téléphone accepté.` · `Aucun appareil prêt pour Mariam` · `Connectez un appareil pour éviter tout problème.` · `Connecter un appareil` · `Avant / Après la séance` · `Voir tout` · `Réviser pages 24 à 26` · `Écouter la récitation` · `Mémoriser la partie Hifz` · `Dernière séance` · `Voir l'historique` · `18 septembre • 1 h 30` · `Présente` · `Détails et connexion`

---

## 3. Fiche B - Accueil tablette sombre (planche, zone x 36-642)

Composition en une seule colonne, de haut en bas :

1. Rail replié (voir 1.2), puis la zone de contenu `#21222D` / `#1F202B`.
2. En-tête : « Accueil » (blanc, gras), sélecteur de thème (lune active), cloche avec point.
3. Sélecteur de 5 éléments (plus serrés : avatars ≈ 58 px, texte ≈ 12-13 dp). Le « + » est dans un cercle à **bordure en pointillés**.
4. **Carte séance** `#2B2B39`, x 131-623 × y 231-645 (≈ 565 dp de large), rayon ≈ 12-14 dp. Même contenu et même ordre que A 2.1-3a. Le CTA « Voir la classe → » mesure x 149-607 × y 538-582 (≈ 526×51 dp) : **fond accent plein** `#BD9CFC` (200-280,550-570), texte quasi-noir.
5. **Liste sans carte** sous la carte (fond `#1F202A`), trois lignes séparées par des traits `#32333E` (300,658) et `#383946` (400,723) :
   - icône appareils orange `#FFCF30`, « Aucun appareil prêt pour Mariam » et « Connectez un appareil pour éviter tout problème. », avec à droite le lien « Connecter un appareil → » (`#C9B7EB`) ;
   - icône livre accent, « Avant / Après la séance », **une seule tâche** « Réviser pages 24 à 26 » avec sa case, et à droite « 2 autres activités → » (`#C6B2ED`) ;
   - icône barres accent, « Dernière séance » et « 18 septembre • 1 h 30 », avec à droite la pastille « Présente » (fond `#22473E`, texte blanc) et « Voir l'historique → ».
6. Pas de « Détails et connexion » sur tablette.

Textes (exacts, en plus de A) : `2 autres activités`, `Connecter un appareil` (avec flèche). Le reste est identique à A, sauf « Rewayah » absent (rail replié) et les libellés de nav absents.

## 4. Fiche C - Accueil desktop sombre (planche, zone x 677-1740)

- Shell : rail déplié (1.1) avec « Rewayah », « « », Accueil actif en pastille pleine `#BA98FB`, Foyer, Historique et Compte en bas.
- En-tête : « Accueil », sélecteur de thème (lune active), cloche.
- Sélecteur : 5 éléments. Anneau actif `#C9A8FA` (923,165), « + » en pointillés, sous-titre actif `#CAB9F4`, les autres `#CCCFD8`.
- **Colonne gauche** : carte `#2B2B39` x 896-1340 × y 272-768 (≈ 462 dp), sans bordure visible (`#282834` en 896). Contenu identique à A. Monogramme « M » : fond `#534D71`, lettre `#C5A5FF`. Pastille « Salle ouverte » : fond `#254D45`, point `#34FBA9`, texte blanc. Séparateur interne `#3C3C4C` (1100,425). CTA plein `#BC9BFC` x 917-1322 × y 639-691 (≈ 420×54 dp).
- **Colonne droite = pas de carte** : zone `#1F1F2A` séparée par un **trait vertical** `#2F2F3C` (1355, y ≈ 280-790), séparateurs `#41414F` (1600,433) et `#31323E` (1600,543). Proportion ≈ 54 / 46.
  - Icône appareils orange `#FFBC33`, titre, corps sur 2 lignes et **lien souligné avec flèche** « Connecter un appareil → » (`#CDB6F5`).
  - **Icône livre** accent `#CFB0FF`, « Avant / Après la séance » et « Voir tout → », puis 3 tâches.
  - **Icône barres** accent `#C8A4FD`, « Dernière séance » et « Voir l'historique → », « 18 septembre • 1 h 30 » avec la pastille « Présente » (fond `#214A42`, texte blanc), puis « **Détails et connexion →** » en **lien accent souligné avec flèche**.

Textes : identiques à A.

---

## 5. Jetons mesurés (valeurs brutes, coordonnées dans l'image source)

### 5.1 Couleurs - thème clair (A)

| Rôle | HEX | Coordonnées / zone |
|---|---|---|
| Fond de page (hors shell) | `#F7F6FD` / `#F8F7FE` | (2-12,2-12), (800-840,878-886) |
| Surface shell / rail / contenu | `#FDFDFE` | (100-250,450-650), (700-1000,20-80) |
| Carte séance (surface teintée) | `#F7F5FE` | (600-900,300-340) |
| Carte secondaire (colonne droite) | `#FDFDFE` | (1300-1600,440-460) |
| Bordure shell | `#F0F0F8` | (21,450) |
| Bordure carte | `#EDEEF9` / `#ECEAF7` / `#F0F1F8` | (331,600) / (700,269) / (1214,600) |
| Séparateur rail | `#F4F4FA` | (307,450) |
| Séparateur horizontal | `#E8E6F4` · `#EEEEF6` · `#EDEDF6` | (900,451) · (1500,453) · (1500,688) |
| Séparateur vertical fort | `#AEAEC6` | (830,580) |
| Texte principal (titres) | ≈ `#000013` (quasi-noir bleuté) | médiane encre (350-495,40-80) |
| Texte corps foncé (liste) | `#3B3D71` / `#2F3261` | (1307-1477,532-554) / (120-175,200-222) |
| Texte secondaire | `#62627E` · `#52537C` · `#63647F` · `#6C6E8A` | (490,375) · (367,595) · (1352,338) · (490,402) |
| Texte tertiaire / aide | `#6D6E8C` | (440-860,800-820) |
| Icônes neutres | `#6F6E8C` · `#727390` · `#646788` | (62,198) · (368,650) · (1682,45) |
| Accent texte / liens | `#5C2CE1` à `#7144E6` (médiane ≈ `#6538E4`) | nav (120,128) · lien (1352,397) · Voir tout (1605,483) |
| Accent icône / monogramme | `#7B48ED` · `#7747E9` · `#7145E8` | (62,124) · (395,335) · (1525,45) |
| Nav active (fond) | `#F1ECFD` | (180-270,112-124) |
| **CTA principal doux** (fond) | `#DFD2FD` | (400-600,715-725) |
| Texte sur CTA | ≈ `#00000D` | (684-814,728-750) |
| Thème actif (fond) | `#EAE2FD` | (1512-1527,48-68) |
| Monogramme (fond) | `#E8E0FD` | (375-390,320-335) |
| Anneau profil actif | `#9974F5` / `#AA8EF7` | (367,145) |
| Pastille statut verte | `#04B764` (cœur), sat. `#09CF6E` | (440,173), (439,179) |
| Pastille statut orange | `#FAB509` | (603,173) |
| Pastille statut grise | `#A5A6BB` | (770,173) |
| Pastille statut rouge | `#F53F54` | (940,173) |
| Pastille « Salle ouverte » fond / point / texte | `#E3F2EF` / `#03C16C` / `#087F43` | (1015-1154,480) / (1005,491) / (1030-1140,485-505) |
| Pastille « Présente » fond / texte | `#E4F6EE` / `#08541D` | (1600-1704,752-758) / (1610-1695,755-773) |
| Icône d'avertissement (appareil) | `#EC9100` (sat. `#F99700`) | (1255-1310,305-360) |
| Point non lu (cloche) | `#9D76F6` | (1710,41) |

Pas de bandeau d'alerte à fond coloré : le blocage est un bloc de contenu dont seule l'icône est orange.

### 5.2 Couleurs - thème sombre (B, C)

| Rôle | HEX | Coordonnées |
|---|---|---|
| Fond de planche | `#1B1C25` / `#1A1C24` | (5-25,300-500) |
| Fond contenu | `#21222D` | (1000-1300,100-120), (300-420,90-110) |
| Rail déplié / replié | `#21222D`-`#22232E` / `#242531` | (700-850,400-700) / (50-100,400-700) |
| Colonne secondaire (sans carte) | `#1F1F2A` | (1450-1700,440-455) |
| Carte séance | `#2B2B39` | (1000-1300,290-305), (300-450,240-255) |
| Bordure de cadre / séparateur rail | `#3E3F4D` / `#393948` | (679,450) / (875,450) |
| Séparateurs | `#3C3C4C` · `#41414F` · `#31323E` · `#2F2F3C` (vertical) | (1100,425) · (1600,433) · (1600,543) · (1355,450) |
| Texte principal | ≈ `#FFFFFF` | titres (mode blanc) |
| Texte secondaire | `#D5D6E4` · `#D0D1DE` · `#CACBD7` · `#CCCFD8` | (1018,359) · (922,538) · (1447,325) · (1046,229) |
| Nav inactive texte / icône | `#D8D9E5` / `#DFDFEF` | (744,212) / (703,210) |
| **Accent plein** (nav active, CTA, thème actif) | `#BA98FB` / `#BC9BFC` / `#B894FB` | (800-850,150-175) / (950-1050,650-680) / (1600,72) |
| Texte sur accent | `#0B011C` (≈ `#040208` pour la flèche du CTA) | (744,153) / (1172,657) |
| Accent texte / liens | `#CDB6F5` · `#CCB8F1` · `#CAB9F4` | (1448,380) · (1638,466) · (920,229) |
| Accent icônes | `#CFB0FF` · `#C8A4FD` · `#C9A8FA` (anneau) · `#C5A5FF` (monogramme) | (1377,462) · (1377,689) · (923,165) · (940,322) |
| Monogramme (fond) | `#534D71` | (930-945,315-330) |
| Pastilles statut vert / orange / gris / rouge | `#3DF4A6` / `#F6B00E` / `#7B799B` / `#F92F4A` | (979,186) / (1106,186) / (1231,186) / (1356,186) |
| « Salle ouverte » fond / point / texte | `#254D45` / `#34FBA9` / `#FFFFFF` | (1290-1310,450-465) / (1202,455) / (1233,462) |
| « Présente » fond / texte | `#214A42` / `#FFFFFF` | (1640-1655,727-742) / (1640,731) |
| Icône d'avertissement | `#FFBC33` (desktop), `#FFCF30` (tablette) | (1378-1428,297-347), (138-170,675-707) |
| Point non lu | `#BB94F8` | (1705,69) |

Dérivation observée : le sombre **n'est pas une inversion naïve**. Le CTA passe de lavande doux à accent saturé, la nav active de pâle à pleine, et les pastilles de statut deviennent vert foncé avec texte blanc.

### 5.3 Dimensions (A, en dp à 1,232 px/dp)

| Élément | px | dp estimés |
|---|---|---|
| Retrait du shell (gauche / haut) | 22 / 12 | 18 / 10 |
| Rayon du shell | ≈ 24 | ≈ 20 |
| Rail déplié (A / C) / replié (B) | 284 / 192 / 70 | 230 / 200 / 80 |
| Pastille nav active | 242×60, r ≈ 16 | 196×49, r ≈ 12-14 |
| Pas des items de nav | 72-74 | ≈ 60 |
| Bouton de repli | 41 (cercle) | 33, **cible < 48** |
| Marge contenu (séparateur rail → carte) | 24 | ≈ 20 |
| Marge droite (carte → bord du shell) | 16 | ≈ 13 |
| Avatar du sélecteur | ≈ 90 | ≈ 73 |
| Pas du sélecteur | ≈ 167 | ≈ 136 |
| Pastille de statut d'avatar | ≈ 16 (liseré blanc inclus) | ≈ 13 |
| Monogramme dans la carte | ≈ 95 | ≈ 77 |
| Écart sélecteur → cartes | 32 | ≈ 26 |
| Carte gauche / droite (largeur) | 863 / 522 | 700 / 424 |
| Gouttière entre colonnes | 20 | 16 |
| Rayon des cartes | ≈ 17 | ≈ 14 |
| Padding des cartes (gauche / droite) | 35 / 31 | ≈ 28 / 25 |
| CTA | 794×59, r ≈ 17 | 645×48, r ≈ 12-14 |
| Pastille « Salle ouverte » | 171×44 | 139×36 (pilule) |
| Pastille « Présente » | 109×36 | 88×29 (pilule) |
| Sélecteur de thème (conteneur / segment) | 143×46 / 64×38 | 116×37 / 52×31, **cible < 48** |
| Ligne de tâche (pas) | 50 | ≈ 41, **cible < 48** si la ligne est tactile |
| Case ronde | ≈ 30 | ≈ 24 |

### 5.4 Typographie observée (A, hauteurs mesurées par profil d'encre)

| Niveau | Exemple | Hauteur capitale / x (px) | Taille estimée | Graisse | Famille imposée (règle écrite) |
|---|---|---|---|---|---|
| Titre de page | « Accueil » | 31 / 21 | ≈ 34-36 dp | 700 | **DM Sans** |
| Mot-symbole | « Rewayah » | 21 / 14 | ≈ 22-24 dp | 700 | logo ou DM Sans (à trancher) |
| Affichage numérique | « 13:45 » | 35 | ≈ 40 dp | 700 | Jakarta, chiffres tabulaires recommandés (ce n'est pas un titre français, décision du coordinateur) |
| Nom de l'élève (carte) | « Mariam » | x 16 | ≈ 26 dp | 600-700 | DM Sans (style de titre) |
| Titre de section | « Prochaine séance » | 22 / 15 | ≈ 22-24 dp | 700 | **DM Sans** |
| Titre de section (colonne droite) | « Dernière séance », « Avant / Après… » | 19 / 13 | ≈ 21-22 dp | 700 | **DM Sans** |
| Sous-titre de carte | « Classe An-Nour » | 18 / 13 | ≈ 20 dp | 700 | DM Sans |
| Valeur | « 1 h 30 » | 22 | ≈ 25 dp | 700 | Jakarta |
| Corps fort | « Début dans 13 min », « Aucun appareil prêt… » | 16 / 11 | ≈ 18 dp | 700 | Jakarta (alerte : titre, donc DM Sans à trancher) |
| Corps | date, « Sayyida Amina », corps de l'alerte | 16 / 11 | ≈ 18 dp | 400 | Jakarta |
| Corps standard | tâches, nav, CTA, liens | 14-16 / 10 | ≈ 16-17 dp | 400 (nav), 600 (CTA) | Jakarta |
| Légende | sous-titres du sélecteur, aide, méta, « Durée » | 12-14 / 9 | ≈ 14-15 dp | 400-500 | Jakarta |

Famille apparente : sans-serif grotesque géométrique à « a » à deux étages, « y » à jambage droit et « 1 » à drapeau, proche de Plus Jakarta Sans ou DM Sans. Le halo de netteté empêche toute identification certaine, et la règle écrite prime : **DM Sans pour les titres français, Plus Jakarta Sans pour tout le reste**. Rappel du BRIEF : aucune trace de Jakarta ni de DM Sans dans le dépôt, contrairement à ce qu'affirme le mandat (contradiction déjà consignée par le coordinateur).

---

## 6. Divergences entre variantes (ne pas implémenter deux mises en page selon le thème)

| Point | A clair desktop | C sombre desktop | B tablette |
|---|---|---|---|
| Colonne droite | carte blanche bordée | pas de carte, trait vertical | liste sous la carte |
| Icônes de section (livre, barres) | absentes | présentes | présentes |
| « Connecter un appareil » | souligné, sans flèche | souligné, avec flèche | lien avec flèche en fin de ligne |
| « Détails et connexion » | gris avec chevron | lien accent souligné avec flèche | absent |
| Bouton « + » d'ajout | cercle en trait plein | cercle en pointillés | pointillés |
| CTA principal | lavande doux, texte noir | accent plein, texte noir | accent plein |
| Nav active | pastille pâle, texte accent | pastille pleine, texte sombre | tuile pleine |
| Proportion des colonnes | ≈ 62 / 38 | ≈ 54 / 46 | 1 colonne |
| Tâches visibles | 3 | 3 | 1 + « 2 autres activités » |

Recommandation au coordinateur : un seul arbre de widgets, avec des jetons clair et sombre. Seul le **format** (desktop, tablette) change la composition, jamais le thème. Il faut choisir une référence pour la colonne droite (carte ou trait) et pour les liens (flèche ou non), puis l'appliquer aux deux thèmes.

---

## 7. Erreurs métier et incohérences à NE PAS reproduire (confrontées au mandat)

1. **« Ajouter enfant »** : le mandat demande « Ajouter un profil élève » (§4 `/tuteur/foyer/ajouter`, §5 Foyer) et exige d'inclure le propre profil du parent « sans l'appeler « enfant » » (§5 Accueil). Le raccourci doit ouvrir le même flux que Foyer, et l'Accueil ne doit pas dupliquer le Foyer.
2. **« Session 18:00 »** : il faut employer « Séance » (vocabulaire du mandat). Le sous-titre doit refléter un état réel.
3. **« Adam / Absente »** : faute d'accord (prénom masculin). Surtout, une absence n'est jamais déduite d'une déconnexion (§5 Accueil) et une présence incertaine donne « En cours de vérification » (§5 Historique). Le point rouge encode aussi le statut par la seule couleur (§9 l'interdit) : il faut un libellé et une sémantique.
4. **« Aïcha / Dernière séance 1 h »** : texte ambigu (il y a une heure ? une durée d'une heure ?). C'est un faux texte, à remplacer par un état réel explicite.
5. **Photo de l'enseignant absente** : la carte montre le monogramme « M » de l'élève et « Sayyida Amina » sans portrait. Le mandat exige le « nom ET photo publique de l'enseignant, titre Sayyid/Sayyida. Ne confonds pas portrait élève et photo enseignant » (§5 Accueil). Il faut ajouter la photo de l'enseignant et ne pas prendre le « M » pour elle.
6. **« Détails et connexion »** : suggère une qualité réseau, qui n'est affichée que si elle est mesurée (§5 Accueil et Historique). Utiliser « Détails de la séance » sauf donnée réelle.
7. **« Avant / Après la séance »** : le mandat nomme ce bloc « Avant le prochain cours », jusqu'à 3 actions et un lien vers le travail complet (§5). La contradiction de libellé est à trancher. « Marquer fait » ne signifie pas compétence acquise. « 2 autres activités » est un compte calculé.
8. **Libellé de séance prolongée** : le mandat §5 écrit « Cours toujours en cours », or le complément observation interdit « Cours en cours » et impose « Séance en direct » / « En direct » / « En séance ». La contradiction est à arbitrer, avec préférence pour le complément, qui est plus récent. Aucun compte à rebours négatif.
9. **Valeurs illustratives, jamais des constantes** : prénoms (Mariam, Yusuf, Aïcha, Adam), « Sayyida Amina », « Classe An-Nour », « Règles de lecture • Niveau 1 », « 13:45 », « Lundi 21 septembre » (cohérent : c'est bien un lundi en 2026), « 18 septembre », « 1 h 30 », « 13 min », « pages 24 à 26 », « partie Hifz », le nombre de profils et la couleur des pastilles.
10. **« Heure de Paris »** : le fuseau vient du fuseau IANA de l'utilisateur ou de la classe, jamais d'un décalage fixe (§5 Classe).
11. **« Salle ouverte » à T-13** : l'ouverture dépend de la fenêtre existante et configurable (en général T-20), pas d'une constante. Le format du mandat au jour J est « Cours dans 3 h 28 », à harmoniser avec « Début dans 13 min » et « Dans 13 min » (deux comptes à rebours sur le même écran).
12. **Blocage « Aucun appareil prêt »** : à afficher seulement si les données le confirment, avec une action unique contextualisée (§5). Le corps « pour éviter tout problème » est vague : préférer une raison concrète. Le lien mène à `/appareils/connexion` dans le contexte de l'élève.
13. **« Tablette ou ordinateur conseillé. Téléphone accepté. »** : recommandation statique, à confirmer dans les specs avant de la garder.
14. **Avatars génériques (silhouettes) contre monogramme « M »** : le repli est incohérent. Il faut un seul repli (portrait réel, sinon l'initiale), et des états réels compréhensibles (§5).
15. **Cibles tactiles < 48 dp** : bouton de repli (33 dp), segments du sélecteur de thème (31 dp), lignes de tâches (41 dp) (§9).
16. **Sélecteur de thème sans mode « Système »** : il doit être relié à la préférence « apparence » de Compte > Préférences, sans créer un second réglage concurrent.
17. **Libellé « Compte » plus bleu** que les autres items (artefact) : même jeton pour tous les items de nav.
18. **Cadre arrondi autour de l'app sur fond lavande** : probablement une mise en scène de maquette, pas une obligation d'UI. C'est au coordinateur de trancher.
19. Rail replié sans libellés : infobulle, `Semantics` et focus obligatoires.
20. Navigation : ces maquettes montrent bien **4 destinations** (Accueil · Foyer · Historique · Compte), ce qui est conforme. La maquette mobile à 3 onglets (BRIEF) ne doit pas faire varier la navigation.

## 8. Conformité à l'ordre de lecture du mandat (§5 Accueil)

L'ordre exigé est : titre et notifications, puis sélecteur, prochaine séance, action bloquante, préparation, dernière séance.
- A et C : colonne gauche (séance), puis colonne droite (blocage, préparation, dernière séance). **Conforme** si l'ordre de focus et du lecteur d'écran suit gauche puis droite.
- B : **conforme** (empilement).

Éléments requis mais absents des maquettes, à dériver dans le même langage visuel :
- photo de l'enseignant ;
- profil propre du parent dans le sélecteur ;
- état vide (première inscription ou ajout de profil, sans fausse classe) ;
- états avant ouverture, en direct, prolongée, annulée ou reportée ;
- présence « En cours de vérification » ;
- chargement, erreur de bloc et hors ligne (§8).

## 9. Limites

- Échelles estimées à partir d'éléments supposés à 48 dp et du rapport des hauteurs de texte. Les dp sont indicatifs (±10 %).
- Les couleurs de texte sont des médianes d'encre sur des images au halo de netteté marqué (générées). Il faut les arrondir vers des jetons sémantiques, pas les copier au pixel.
- La police ne peut pas être identifiée avec certitude sur ces images.
