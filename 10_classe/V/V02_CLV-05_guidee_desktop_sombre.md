# V02 — CLV-05, interface guidée (élève), desktop, thème sombre : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V02_CLV-05_guidee_desktop_sombre`. Lecture seule : aucun fichier du dépôt n'a été modifié. La maquette prime : tout ce qui n'est pas listé en §Rectifications est à garder tel quel.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-05_guidee_desktop_sombre.png` |
| Dimensions | 1586 × 992 px, 24 bpp RGB (`System.Drawing.Image`), un seul écran (pas de montage côte à côte) |
| Image ouverte | oui, en entier avec l'outil Read, puis en tuiles agrandies (×2 et ×3) et en crops 1:1 pour la mesure |
| Tuiles utilisées | `C:\RA\pilotage\10_classe\V\tuiles\v2_header_full.png` (en-tête, x0-1586,y55-205, ×2), `v2_maincontent_1to1.png` (support+vidéo, x300-1530,y190-810, ×1), `v2_parent_banner.png` (bandeau parent, x1010-1530,y700-830, ×3), `t3_content_top.png`, `t4_content_list.png`, `t5_video_top.png`, `t6_video_bottom.png`, `t7_bottom_bar.png`, `t8_footer_caption.png`, `t2_sidebar.png` |
| Échantillonnage | `System.Drawing.Bitmap.GetPixel` en points isolés pour situer les bords de cartes (transition fond sombre `#17..#22` ↔ carte claire `#FC..#FF`, bandeau ocre `#43..#49`) ; coordonnées vérifiées par recadrage direct sur chaque boîte avant de les consigner |
| Avertissement | Le dossier `tuiles\` contient aussi des fichiers hérités d'un précédent agent pour d'autres écrans (`t1_header.png` provenait en réalité de CLV-06 « enseignant », pas de CLV-05 — nom réutilisé par erreur). Ces fichiers ont été identifiés et écartés ; ils ne sont pas cités ci-dessus et ne doivent pas être confondus avec CLV-05 |

Tous les textes ci-dessous ont été lus sur l'image ou sur les tuiles listées. Rien n'est déduit d'un nom de fichier.

## 1. Identification

Un seul écran : vue de l'**élève** (« Mariam ») pendant une séance en direct, en interface guidée (support imposé par l'enseignant), thème sombre, format desktop dans un cadre de navigateur (points rouge/orange/vert). Sous-titre de l'image : « CLV-05 · Interface guidée · Web ».

## 2. Composition, de haut en bas

1. **Cadre navigateur** (y 0-40) : trois points de fenêtre (rouge/orange/vert), cadre de maquette, à ne pas implémenter.
2. **Barre latérale** (x 57-313, y 40-991, fond marine plus sombre que le contenu) :
   - logo « Rewayah Academy » (icône livre violette + texte deux lignes) en haut ;
   - navigation verticale à 7 destinations : **Accueil**, **Foyer**, **Séance en direct** (item actif : pilule pleine violette + point vert clignotant à droite du libellé), **Classes**, **Historique**, **Bibliothèque**, **Profil**.
3. **En-tête de contenu** (x 313-1529, y 60-204) :
   - à gauche : chevron retour « < », titre « **Ma séance** » (grand, blanc), sous-ligne « Classe An-Nour · Sayyida Amina » suivie d'un badge vert plein « ● En ligne » ;
   - à droite : interrupteur clair/sombre, cloche (point violet de notification), roue crantée (réglages), avatar rond « M » + « Mariam » + chevron.
   - **Aucune mention légale d'enregistrement n'est visible dans cet écran** (ni bandeau, ni texte discret) — voir Rectification 1.
4. **Carte « support » (Chapitre 1)** (x 313-1005, y 204-816, w≈692, h≈612, fond blanc `#FCFCFE`, coins arrondis) :
   - pastille « Chapitre 1 » (fond lavande clair, texte violet) en haut à gauche ;
   - titre « Les bonnes manières en classe » (deux lignes, noir, gras) ;
   - 3 barres grises fines (lignes de texte décoratives / résumé), sous le titre ;
   - photo d'illustration (lanternes et livres, ambiance orientale) en haut à droite de la carte, coins arrondis, proportions naturelles ;
   - bloc surligné lavande : « Être attentif aux explications du professeur. » (texte violet, deux lignes) ;
   - une barre grise fine (séparateur) ;
   - liste numérotée à puces rondes violettes : **1** Écouter avec calme. **2** Poser des questions poliment. **3** Respecter les camarades. ;
   - deux barres grises fines en bas de carte (fin de liste / texte complémentaire).
5. **Colonne vidéo + notice parent** (x 1024-1509, y 204-809, w≈485), à droite du support, **même hauteur que le support** :
   - carte vidéo (y 204-722, h≈518) : portrait de l'enseignante en plein cadre, non déformé (proportions naturelles) ; étiquette « Sayyida Amina » en bas à gauche (fond sombre semi-opaque) ; indicateur de signal (barres vertes) en bas à droite ;
   - **bandeau séparé** (y 722-809, h≈87, fond ocre/brun plein `#44341D`-ish, bordure 1 px, coins arrondis) : icône œil jaune + texte « **Ton parent regarde la séance.** ».
6. **Barre de contrôle d'appel** (y ≈816-953, centrée horizontalement sous les deux colonnes) : 4 boutons ronds avec libellé dessous — micro vert « Parler », caméra violette « Caméra », agrandir gris foncé « Agrandir », raccrocher rouge « Quitter ».
7. **Légende de bas de page** (centrée, hors cadre app) : « CLV-05 · Interface guidée · Web », texte violet clair, petit.

### Alignements observés

- Support et vidéo partagent le même haut (y≈204) et une largeur de gouttière cohérente (≈20 px, x 1005-1024) — alignement correct, à garder.
- Le bas du support (y≈816) et le bas du bandeau parent (y≈809) sont à 7 px l'un de l'autre : écart mineur, dans la tolérance visuelle, pas une erreur d'alignement à corriger séparément (il disparaît de toute façon avec la Rectification 2).
- Contenu du support aligné à une seule marge (x≈350-357 pour la pastille, le titre et les puces) : cohérent, à garder.

## 3. Textes recopiés exactement

- `Rewayah` / `Academy`
- `Accueil`
- `Foyer`
- `Séance en direct`
- `Classes`
- `Historique`
- `Bibliothèque`
- `Profil`
- `Ma séance`
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Mariam`
- `Chapitre 1`
- `Les bonnes manières en classe`
- `Être attentif aux explications du professeur.`
- `Écouter avec calme.`
- `Poser des questions poliment.`
- `Respecter les camarades.`
- `Sayyida Amina`
- `Ton parent regarde la séance.`
- `Parler` / `Caméra` / `Agrandir` / `Quitter`
- `CLV-05 · Interface guidée · Web`

## 4. À garder tel quel

- La barre latérale complète : logo, 7 destinations, style de la pilule active (violet plein + point vert), ordre des libellés.
- L'en-tête : titre « Ma séance », sous-ligne « Classe An-Nour · Sayyida Amina », badge « En ligne », interrupteur clair/sombre, cloche, réglages, avatar « Mariam ». Aucun chevauchement constaté entre ces éléments.
- Le style et le contenu de la carte « support » (pastille de chapitre, titre, illustration non déformée, bloc surligné, liste numérotée à puces rondes) — c'est le style que le directeur préfère ; ne pas le redessiner, seulement libérer sa largeur (Rectification 2).
- Le portrait de l'enseignante : cadrage et proportions naturels, non déformé (R4 respecté sur ce point).
- L'étiquette « Sayyida Amina » et l'indicateur de signal sur la vidéo.
- La barre de contrôle d'appel (Parler / Caméra / Agrandir / Quitter) : 4 boutons ronds de même taille, un code couleur par fonction, libellé sous chaque icône, aucun chevauchement, aucune surcharge dans un coin.
- Le cadre navigateur (points de fenêtre) et la légende de bas de page.

## 5. Rectifications

| # | Ce que montre la maquette | Boîte (x, y, w, h en px source) | Règle | Correction attendue |
|---|---|---|---|---|
| 1 | Aucune mention légale d'enregistrement/visite n'apparaît sur cet écran (ni bandeau, ni texte discret, nulle part) | en-tête de contenu, zone disponible entre le badge « En ligne » et les icônes de droite, ex. x 780-1100, y 158-182 | R1 | Ajouter la mention unique, petite et discrète, précédée d'un point rouge (enregistrement) : « Cours enregistré, visite de contrôle possible. » Pas de fond ni de bandeau : texte simple sur le fond de l'en-tête, placé là où il ne chevauche ni le badge « En ligne » ni les icônes de droite |
| 2 | Bandeau séparé plein « Ton parent regarde la séance. » (fond ocre/brun, icône œil), sous la vidéo | x 1024, y 722, w 485, h 87 | R2 | Supprimer ce bloc séparé. À la place : la mention de la Rectification 1 se **rétracte** à son seul point rouge (clignotant subtilement) pendant que le parent observe, et le texte qui apparaît à côté du point devient « Ton parent regarde la séance. » (une pierre deux oiseaux — un seul emplacement pour les deux notices) |
| 3 | Vidéo de l'enseignante en colonne pleine hauteur, égale à la hauteur du support (x 1024, y 204, w 485, h 518) | x 1024, y 204, w 485, h 518 | R3 | Réduire la vidéo et la poser **en incrustation** (surimpression, z-index au-dessus) sur un coin du support (ex. coin inférieur droit de la carte « Chapitre 1 »), sans occuper de colonne ni la hauteur du support. Conserver le cadrage non déformé de la photo (R4) et l'étiquette « Sayyida Amina » sur l'incrustation |
| 4 | Le support (« Chapitre 1 ») est artificiellement rétréci (w≈692 sur 1586 de large, soit 44 % de la largeur totale) pour laisser la place à la colonne vidéo | carte support : x 313, y 204, w 692, h 612 | R3 | Une fois la vidéo réduite en incrustation (Rectification 3), élargir le support jusqu'à la marge droite de la page (≈ x 313 à x 1509) : le support partagé redevient l'élément dominant de l'écran, conformément à la priorité du contenu partagé |

Aucune autre erreur avérée n'a été relevée sur cet écran (pas de texte coupé, pas d'avatar étiré en dehors de ce qui précède, pas de libellé incohérent, pas de carte qui sort du cadre). Le style de bouton unique (R5) et l'absence de surcharge (R7) n'ont pas de contre-exemple probant sur cette seule image ; une vérification croisée avec les autres écrans de la salle (CLV-06 à CLV-10) reste utile mais sort du périmètre de cette fiche.
