# V03 - CLV-06, Enseignant · Desktop navigateur · Sombre : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V03_CLV-06_enseignant_desktop_sombre`. Lecture seule sur l'image source ; aucune commande git exécutée. Méthode alignée sur `C:\RA\pilotage\01_visuel\V1_accueil_mobile.md` (§0, §4, §5).

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-06_enseignant_desktop_sombre.png` |
| Dimensions | 1586 × 992 px |
| Image ouverte | oui, en entier avec l'outil Read, puis en 11 tuiles agrandies (×1.3 à ×3, bicubique, `System.Drawing`) |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\CLV06_t1_header.png` à `CLV06_t11_overlap.png` |
| Un seul écran | oui : la légende hors-cadre en bas de l'image (« CLV-06 · Enseignant · Web ») confirme qu'il s'agit d'un seul écran, pas d'un montage de plusieurs écrans côte à côte |
| Mesures de proximité/superposition | `System.Drawing.Bitmap.GetPixel` le long d'une ligne verticale (x=717, y=795-835) pour vérifier l'écart réel entre le support et la barre de contrôles flottante |
| Vérification des boîtes | chaque rectification ci-dessous a été recadrée isolément (tuiles `CLV06_t6` à `CLV06_t11`) avant d'être consignée |

Tous les textes ci-dessous sont recopiés depuis l'image ou les tuiles, aucun n'est déduit du nom de fichier.

## 1. Manifeste

| Écran | Zone visible | État | Thème | Format |
|---|---|---|---|---|
| Séance en direct, vue enseignant | fenêtre de navigateur complète (barre de titre macOS simulée), 1586×992 | nominal : séance en cours (« La séance se poursuit »), 3/4 élèves présents, chapitre 1/12 affiché, un tuteur observe | sombre | desktop navigateur |

## 2. Composition, de haut en bas

1. **Barre de fenêtre** (y 0-70) : trois points de feu (rouge/jaune/vert), factice, cadre de maquette à ne pas implémenter.
2. **Barre latérale gauche** (x 0-292, pleine hauteur) : logo « Rewayah Academy » (icône livre + libellé sur deux lignes), puis navigation verticale : Accueil, Foyer, **Séance en direct** (état actif : fond violet plein, icône caméra + point), Classes, Historique, Bibliothèque, Profil. Un seul style de pastille active, cohérent.
3. **En-tête de contenu** (x ≈ 300-1508) :
   - ligne 1 (y ≈ 100-165) : flèche retour, titre « Séance en direct » (grand, blanc), sous-titre « Classe An-Nour · Sayyida Amina » + badge vert « ● En ligne » ; à droite, groupe compact : bascule thème clair/sombre, cloche (point de notification violet), roue de réglages, avatar « M » + « Mariam » + chevron.
   - ligne 2 (y ≈ 192-249) : quatre éléments en rangée serrée — bandeau violet plein « Cours enregistré, visite de contrôle possible. » (icône caméra), pastille verte « La séance se poursuit. », bouton « Élèves 3/4 › », bouton « Supports › ».
4. **Zone de travail** (y ≈ 266-832), deux colonnes :
   - **Support partagé** (carte blanche, x ≈ 308-1123, y ≈ 268-832) : pastille « Chapitre 1 », titre « Les bonnes manières en classe », 3 lignes de texte substitut, photo (livres + lanternes), bloc lavande « Être attentif aux explications du professeur. », liste numérotée 1-2-3 (« Écouter avec calme. », « Poser des questions poliment. », « Respecter les camarades. »), filet substitut en pied de carte.
   - **Colonne droite** (x ≈ 1130-1508, presque toute la hauteur du support) : vignette vidéo de l'enseignante « Sayyida Amina » (barres de signal, bouton « ⋯ »), puis panneau « Outils d'enseignement » (Pointeur actif / Marquer / Masquer / Annoter, même style de bouton), puis bandeau brun « Tuteur de Mariam observe. » (icône œil).
5. **Barre flottante inférieure** (y ≈ 818-915) : pagination « ‹ 1/12 › » à gauche, pilule de contrôles média « Micro / Caméra / Réseau / Quitter » (Quitter en rouge) au centre, zoom « − 100% + ⛶ » à droite.
6. **Légende hors-cadre** (y ≈ 950-980) : « CLV-06 · Enseignant · Web », sous la fenêtre — repère de maquette, pas un élément d'interface.

## 3. Textes lisibles, recopiés exactement

- `Rewayah Academy`
- `Accueil` · `Foyer` · `Séance en direct` · `Classes` · `Historique` · `Bibliothèque` · `Profil`
- `Séance en direct`
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Mariam`
- `Cours enregistré, visite de contrôle possible.`
- `La séance se poursuit.`
- `Élèves 3/4`
- `Supports`
- `Chapitre 1`
- `Les bonnes manières en classe`
- `Être attentif aux explications du professeur.`
- `Écouter avec calme.` / `Poser des questions poliment.` / `Respecter les camarades.`
- `Sayyida Amina`
- `Outils d'enseignement`
- `Pointeur` · `Marquer` · `Masquer` · `Annoter`
- `Tuteur de Mariam observe.`
- `1 / 12`
- `Micro` · `Caméra` · `Réseau` · `Quitter`
- `100%`
- `CLV-06 · Enseignant · Web`

## 4. À garder tel quel

- La barre latérale gauche entière : logo, ordre et libellés de navigation, état actif violet plein.
- L'en-tête : flèche retour, titre, sous-titre, badge « En ligne ».
- Le support partagé : « Chapitre 1 », titre, image, bloc lavande, liste numérotée — mise en page, couleurs, textes.
- Le panneau « Outils d'enseignement » : 4 boutons, style, icônes, libellés, état actif du Pointeur.
- La pastille verte « La séance se poursuit. » et les boutons « Élèves 3/4 » / « Supports » : forme, couleur, contenu.
- La barre de contrôles média (Micro/Caméra/Réseau/Quitter) et la pagination « 1/12 » : forme et contenu (seul l'espacement avec le support est à corriger, §5.4).
- Le portrait vidéo de Sayyida Amina : cadrage, proportions naturelles, aucune déformation (R4 respecté) — seule sa **taille et sa position** changent (§5.3).
- Le fond sombre général, la police, les rayons de carte, les couleurs violettes d'accent.

## 5. Rectifications

| # | x, y, w, h (px source) | Ce que montre la maquette | Règle | Correction attendue |
|---|---|---|---|---|
| 1 | 306, 192, 460, 56 | Bandeau « Cours enregistré, visite de contrôle possible. » : rectangle plein violet, bordure, gros pictogramme caméra — traité comme une pilule d'action au même rang que « Élèves 3/4 » et « Supports » | R1 | Supprimer le fond et la bordure ; remplacer le pictogramme par un simple **point rouge** ; texte petit et discret, une seule mention combinant enregistrement et visite possible ; la déplacer là où elle ne dispute plus l'espace aux vraies actions (ex. accolée au badge « En ligne » de la ligne 1, pas en pilule pleine largeur dans la ligne d'actions) |
| 2 | 1135, 728, 407, 54 | Bandeau séparé « Tuteur de Mariam observe. » (fond brun, icône œil) logé sous les outils d'enseignement, dans la colonne vidéo | R2 | Supprimer ce bloc. Quand un parent/tuteur observe : la mention de la rectification n°1 se rétracte à son seul point rouge, qui clignote subtilement, et son texte est remplacé par la notice temporaire « Tuteur de Mariam observe. » **au même emplacement** (une pierre deux oiseaux) — pas un second bandeau ailleurs dans l'écran |
| 3 | 1130, 266, 380, 516 (colonne vidéo) vs 308, 268, 815, 564 (support) | La vidéo de l'enseignante occupe une colonne entière à droite, presque aussi haute que le support partagé (516 px sur 564) : elle rivalise avec le support au lieu de le laisser dominer | R3 | Réduire la vidéo à une vignette, en surimpression (z-index au-dessus) sur un coin du support (ex. coin inférieur droit), sans lui réserver de colonne ni de hauteur dédiées ; le support s'étend alors sur toute la largeur disponible |
| 4 | 314, 818, 1029, 97 (barre flottante) contre y=818 (bas du support, mesuré au pixel en x=717) | La barre de contrôles média, la pagination et le zoom flottent à 0-1 px du bord bas du support/de la colonne vidéo : aucune marge, ils semblent soudés à la carte | R6 | Réserver une marge claire (16-24 px) entre le bas de la zone de travail et la barre flottante, sur toute sa largeur |
| 5 | 1113, 113, 387, 35 | Quatre commandes compactes empilées dans le coin supérieur droit : bascule thème, cloche, réglages, avatar+chevron | R7 | Alléger ce coin : regrouper (ex. réglages sous le menu avatar) ou espacer davantage pour qu'il ne lise pas comme une grappe de boutons |

### Constat annexe (non chiffré, disparaît avec la correction n°2)

Le bandeau « Tuteur de Mariam observe. » et le bouton « Masquer » du panneau d'outils utilisent la **même icône d'œil** (contour ouvert, pupille pleine) pour deux significations opposées — « quelqu'un vous observe » contre « masquer un élément ». C'est une incohérence de pictogramme dans la maquette actuelle ; elle disparaît d'elle-même une fois la rectification n°2 appliquée (la mention d'observation devient un point rouge, plus une icône œil).

## 6. Hors-sujet pour cette fiche

- Aucune mesure de couleur (HEX) n'a été faite : non demandée pour ce relevé (§0/§4/§5 seulement, sur le modèle du rôle tuteur).
- R8 (défilement au pouce, pas de pagination comme seul moyen) ne s'applique pas : cet écran est desktop, pas mobile. La pagination « ‹ 1/12 › » est donc conforme ici et à garder telle quelle.
- R5 (un seul style de bouton) : aucun écart trouvé sur cet écran — boutons de la rangée d'actions, outils d'enseignement et navigation partagent déjà la même famille de forme/couleur.
