# V01 - CLV-04, Élève desktop, thème sombre : relevé visuel

Date : 25/09/2026. Agent de relevé visuel. Lecture seule : aucun fichier de la maquette n'a été modifié.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-04_eleve_desktop_sombre.png` |
| Dimensions | 1586 × 992 px, fichier de 1 281 004 octets |
| Image ouverte | oui, en entier avec l'outil Read, puis en tuiles agrandies (×2, ×3, ×4, ×6) |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\` : `t1_header` (0,0,1586,260), `t2_card_top` (0,230,1140,340), `t3_card_bottom` (0,540,1140,320), `t4_video_notice` (1130,230,460,400), `t5_bottom_bar` (280,820,1310,172), `t6_sidebar` (0,0,300,992), puis vérifications ciblées `t7_rightedge_check` (1480,230,106,400 ×4), `t8_notice_box_check` (280,165,1265,90 ×2), `t9_video_box_check` (1120,235,415,315 ×2), `t10_observe_box_check` (1115,545,445,85 ×2), `t11_card_corner_check` (280,235,60,40 ×6), `t12_header_cluster` (1120,70,466,100 ×3) |
| Échantillonnage | `System.Drawing.Bitmap.GetPixel` en balayages horizontaux/verticaux pour localiser les transitions de couleur (bords des blocs), puis recadrage de vérification sur chaque boîte retenue |
| Un seul écran | oui : un unique panneau d'application (fenêtre avec barre de titre à 3 points), pas d'écran secondaire côte à côte |

Tous les textes ci-dessous ont été lus sur l'image ou sur les tuiles. Rien n'est déduit d'un nom de fichier.

## 4. Fiche d'écran : Séance en direct, élève (desktop, sombre)

### 4.1 Composition, de haut en bas

1. **Barre latérale gauche** (x 0-300, pleine hauteur), fond bleu-nuit : logo « Rewayah Academy » (icône livre violette) en haut, puis navigation verticale : Accueil, Foyer, **Séance en direct** (élément actif, surligné violet, avec un point vert de statut à droite du libellé), Classes, Historique, Bibliothèque, Profil.
2. **En-tête de la zone de contenu** (x 300-1560, y 40-165) :
   - à gauche : chevron « ‹ » de retour, puis titre « Séance en direct » (gras, blanc) ; en dessous, ligne « Classe An-Nour · Sayyida Amina » suivie d'une pastille verte « ● En ligne » ;
   - à droite, un groupe de 4 éléments alignés sans chevauchement : interrupteur clair/sombre (icône soleil + toggle violet), cloche de notification (avec point violet), icône réglages (engrenage), puis avatar rond « M » (initiale, violet) + « Mariam » + chevron « ⌄ ».
3. **Bandeau violet plein** « Cours enregistré, visite de contrôle possible. » (x≈296-1530, y≈180-235), icône caméra violette à gauche du texte — occupe presque toute la largeur du contenu (voir rectification n°1).
4. **Zone principale** en deux colonnes côte à côte :
   - **Colonne gauche, carte support** (x≈301-1113, y≈253-845, fond blanc, coins arrondis) :
     - pastille « Chapitre 1 » (fond lavande, texte violet) ;
     - titre « Les bonnes manières en classe » (grand, gras, encre foncée) ;
     - 3 lignes grises de texte de remplissage (placeholders) ;
     - à droite du titre, une image encadrée (lanternes suspendues et pile de livres sur un tapis) ;
     - bloc encadré lavande : citation « Être attentif aux explications du professeur. » ;
     - une ligne grise de remplissage ;
     - liste numérotée à puces rondes lavande : « 1 Écouter avec calme. », « 2 Poser des questions poliment. », « 3 Respecter les camarades. » ;
     - deux lignes grises de remplissage en bas de carte.
   - **Colonne droite, empilement de 2 blocs, plus étroit que la carte** :
     - **Tuile vidéo** de l'enseignante (x≈1134-1524, y≈247-539, coins arrondis) : photo de « Sayyida Amina » (portrait souriant, foulard mauve), étiquette de nom « Sayyida Amina » en bas à gauche, indicateur de signal (3 barres vertes) en bas à droite — occupe toute une colonne et sa propre hauteur (voir rectification n°3).
     - **Bloc « Votre parent observe la séance. »** (x≈1131-1544, y≈559-616, fond ocre/brun plein), icône œil jaune à gauche du texte, séparé et permanent sous la vidéo (voir rectification n°2).
     - en dessous, colonne droite vide jusqu'au bas de la carte (espace inoccupé, la colonne droite est bien plus courte que la carte de gauche).
5. **Barre de contrôle flottante, en bas** (y≈845-935, superposée au bas de la carte, ne recouvre pas son contenu) :
   - à gauche : pagination « ‹ 1 / 12 › » (flèches rondes sombres) ;
   - au centre : pilule sombre à 4 boutons ronds « Micro », « Caméra », « Agrandir » (icônes contour blanc), « Quitter » (fond rouge plein, icône combiné) ;
   - à droite : contrôle de zoom « − 100 % + » (boutons ronds), puis bouton plein écran isolé.
6. **Légende hors interface**, sous le cadre de la fenêtre (y≈965-985) : « CLV-04 · Élève standard · Web » — mention de production, ne fait pas partie de l'UI.

### 4.2 Textes lisibles, recopiés exactement

- `Rewayah Academy`
- `Accueil` / `Foyer` / `Séance en direct` / `Classes` / `Historique` / `Bibliothèque` / `Profil`
- `Séance en direct`
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Cours enregistré, visite de contrôle possible.`
- `Chapitre 1`
- `Les bonnes manières en classe`
- `Être attentif aux explications du professeur.`
- `1` `Écouter avec calme.`
- `2` `Poser des questions poliment.`
- `3` `Respecter les camarades.`
- `Sayyida Amina` (étiquette sur la vidéo)
- `Votre parent observe la séance.`
- `1 / 12`
- `Micro` / `Caméra` / `Agrandir` / `Quitter`
- `100%`
- `CLV-04 · Élève standard · Web`
- `Mariam`

## 5. À garder tel quel

- La disposition générale de l'application : barre latérale gauche fixe, en-tête de contenu, carte de support blanche à gauche.
- La palette sombre, l'accent violet, les icônes de navigation et leurs libellés, le point vert de statut « Séance en direct » dans la barre latérale.
- Le style de la carte support (fond blanc, coins arrondis, pastille « Chapitre 1 », titre, image, bloc de citation lavande, liste numérotée à puces rondes).
- Le style unique des boutons de la barre de contrôle (pilule sombre, icônes au trait, boutons ronds identiques pour Micro/Caméra/Agrandir/pagination/zoom) — cohérent dans toute la zone.
- Le bouton rouge « Quitter » (convention universelle de fin d'appel, seule exception de couleur justifiée sémantiquement).
- Le groupe d'en-tête à droite (interrupteur clair/sombre, cloche, réglages, avatar) : bien espacé, sans chevauchement.
- L'étiquette de nom et l'indicateur de signal sur la tuile vidéo, la photo de l'enseignante elle-même (portrait net, non déformé, à conserver au même ratio après réduction).
- La pagination « ‹ 1 / 12 › » du support et les contrôles de zoom.
- Tous les textes, couleurs et icônes non cités dans les rectifications ci-dessous.

## 6. Rectifications

| # | Boîte (x, y, w, h en px source) | Ce que montre la maquette | Règle | Correction attendue |
|---|---|---|---|---|
| 1 | (296, 180, 1234, 55) | Bandeau violet plein, pleine largeur (55 px de haut, 1234 px de large), avec icône caméra, pour « Cours enregistré, visite de contrôle possible. » | **R1** | Supprimer le fond/rectangle. Remplacer par une mention petite et discrète, précédée d'un point rouge (symbole d'enregistrement), placée à un endroit qui ne gêne rien (ex. à côté du titre ou en fin d'en-tête). Une seule mention qui combine enregistrement et visite de contrôle possible — pas de bandeau pleine largeur |
| 2 | (1131, 559, 413, 57) | Bloc séparé, fond ocre plein, en permanence sous la vidéo : « Votre parent observe la séance. » avec icône œil | **R2** | Supprimer ce bloc séparé. Quand un parent/tuteur observe : la mention de la rectification n°1 se rétracte à son seul point rouge (qui clignote subtilement), et le texte « Votre parent observe la séance. » apparaît à la place du texte de la mention (une pierre deux oiseaux) |
| 3 | (1134, 247, 390, 292) | Vidéo de l'enseignante en tuile pleine colonne (390 × 292 px, ≈ 25 % de la largeur de l'écran), avec sa propre hauteur dédiée à côté du support | **R3** | Réduire la vidéo et la passer en surimpression (au-dessus, z-index supérieur) sur un coin du support partagé ; elle ne doit occuper ni colonne ni hauteur dédiée. Le support doit dominer visuellement |
| 4 | (1524, 247, 20, 369) | Désalignement : le bord droit de la vidéo (x≈1524) ne correspond pas au bord droit du bloc « Votre parent observe la séance. » juste en dessous (x≈1544) ; écart d'environ 20 px entre deux blocs de la même colonne | relevé (désalignement) | Sans objet une fois R2/R3 appliquées (le bloc séparé disparaît et la vidéo devient une surimpression), mais à noter comme défaut d'alignement de la maquette actuelle |
| 5 | (310, 193, 25, 25) | La mention d'enregistrement utilise une icône de caméra violette, pas un point rouge | **R1** | Remplacer l'icône caméra par un simple point rouge (indicateur d'enregistrement), cohérent avec R1 et R2 |
