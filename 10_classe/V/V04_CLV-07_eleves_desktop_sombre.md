# V04 - CLV-07, salle de classe (vue enseignant, panneau Élèves ouvert), desktop, thème sombre : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V04_CLV-07_eleves_desktop_sombre`. Lecture seule : aucune commande git exécutée, aucun fichier hors de `C:\RA\pilotage\10_classe\V` modifié.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-07_eleves_desktop_sombre.png` |
| Dimensions | 1586 × 992 px, 1 372 016 octets |
| Image ouverte | oui, en entier avec l'outil Read, puis en tuiles agrandies (×2 et ×3) |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\t1_header.png` à `t11_notice_pill_close.png` (bandes et gros plans : en-tête, barre latérale, panneau Élèves, support, vidéo + outils, barre basse, coins) |
| Échantillonnage de précision | `System.Drawing.Bitmap.GetPixel`, balayages horizontaux et verticaux ligne par ligne pour localiser chaque bord (transition de couleur) des éléments corrigés, puis vérification par recadrage ciblé sur la boîte trouvée |
| Écrans détectés | **un seul écran** dans l'image (une fenêtre de navigateur simulée, coins arrondis, barre de trois pastilles macOS en haut à gauche, légende `CLV-07 · Élèves · Web` sous le cadre — cadre de maquette, à ne pas implémenter) |

Tous les textes ci-dessous ont été recopiés sur l'image ou les tuiles. Rien n'est déduit du nom de fichier.

## 1. Manifeste

| Fichier | Zone | Écran | État | Thème | Format |
|---|---|---|---|---|---|
| `CLV-07_eleves_desktop_sombre.png` | image entière (0,0)-(1586,992), un seul écran | Séance en direct, vue enseignant, panneau « Élèves » déroulé sur Mariam | nominal, séance en cours, 3/4 élèves présents, tuteur de Mariam en train d'observer, support « Chapitre 1 » ouvert page 1/12 | sombre | desktop, cadre de fenêtre navigateur |

## 2. Composition de l'écran, de haut en bas

1. **Barre de fenêtre** (y 56-90) : trois pastilles rouge/orange/vert (chrome de maquette).
2. **Barre latérale gauche** (x 24-252, pleine hauteur) : logo « Rewayah Academy » (icône livre + texte sur deux lignes) ; navigation verticale **Accueil, Foyer, Séance en direct, Classes, Historique, Bibliothèque, Profil** ; l'item actif « Séance en direct » est en pilule violette pleine avec un point vert clignotant-statut à droite du libellé.
3. **En-tête, ligne 1** (y ≈ 90-165) : chevron retour à gauche ; titre « Séance en direct » (gros, gras) ; sous-ligne « Classe An-Nour · Sayyida Amina » suivie d'une pastille verte « ● En ligne ». À droite : bascule thème clair/sombre, cloche de notification (point violet, non-lu), roue crantée (réglages), avatar rond « M » + « Mariam » + chevron (menu compte).
4. **En-tête, ligne 2 — bandeau d'état** (y 183-233), quatre éléments alignés côte à côte sans chevauchement :
   - pilule violette pleine « 🎥 Cours enregistré, visite de contrôle possible. » (x 273-737, w 464, h 50) ;
   - pilule verte « 📶 La séance se poursuit. » ;
   - bouton « 👥 Élèves 3/4 › » ;
   - bouton « 📄 Supports › ».
5. **Colonne gauche — panneau « Élèves »** (x ≈ 255-637, y ≈ 245-826) :
   - titre « Élèves » + bouton « ⋯ » ;
   - carte « Mariam » dépliée (avatar initiale « M », « ● Connecté », chevron vers le haut) avec une grille 2 colonnes (Niveau/À reprendre, Objectif actuel/Présence récente, Dernière séance/Travail actuel) puis 4 boutons outline en grille (Rappeler, Choisir pour réciter, Noter, Signaler un besoin) ;
   - ligne repliée « Yusuf · Pas encore connecté » (point orange) ;
   - ligne repliée « Aïcha · Connexion interrompue » (point rouge).
6. **Colonne centrale — support partagé** (carte blanche, x 640-1188, y 256-844) : badge « Chapitre 1 », titre « Les bonnes manières en classe », 3 lignes de texte fantôme (placeholder), photo d'ambiance à droite, encart mauve clair « Être attentif aux explications du professeur. », puis une liste numérotée (1 Écouter avec calme. / 2 Poser des questions poliment. / 3 Respecter les camarades.) et deux lignes fantôme finales.
7. **Colonne droite** (x ≈ 1206-1545) :
   - **carte vidéo de l'enseignante** « Sayyida Amina » (x 1206-1540, y 254-518, w 334, h 264) : photo plein cadre, étiquette de nom en bas à gauche, barres de réseau + bouton « ⋯ » en bas à droite ;
   - bloc « Outils d'enseignement » (x ≈ 1206-1545, y ≈ 527-698) avec 4 boutons outline en grille (Pointeur, Marquer, Masquer, Annoter) ;
   - pilule ocre pleine « 👁 Tuteur de Mariam observe. » (x 1208-1545, y 712-765, w 337, h 53).
8. **Barre basse** (y ≈ 850-925, centrée sous support + vidéo) : pagination « ‹ 1/12 › » à gauche ; groupe Micro / Caméra / Réseau / Quitter (rouge) au centre ; zoom « − 100% + » et plein écran à droite.
9. **Légende hors cadre** : `CLV-07 · Élèves · Web` (cadre de maquette, à ne pas implémenter).

## 3. Textes lisibles, recopiés exactement

- `Rewayah` / `Academy`
- `Accueil` · `Foyer` · `Séance en direct` · `Classes` · `Historique` · `Bibliothèque` · `Profil`
- `Séance en direct`
- `Classe An-Nour · Sayyida Amina` / `En ligne`
- `Mariam`
- `Cours enregistré, visite de contrôle possible.`
- `La séance se poursuit.`
- `Élèves 3/4`
- `Supports`
- `Élèves`
- `Mariam` / `Connecté`
- `Niveau` / `1`
- `À reprendre` / `Pages 24 à 26`
- `Objectif actuel` / `Chapitre 1` / `(les bonnes manières)`
- `Présence récente` / `3 séances cette semaine`
- `Dernière séance` / `18 sept. 2024`
- `Travail actuel` / `Écoute de la récitation`
- `Rappeler`
- `Choisir pour` / `réciter`
- `Noter`
- `Signaler` / `un besoin`
- `Yusuf` / `Pas encore connecté`
- `Aïcha` / `Connexion interrompue`
- `Chapitre 1`
- `Les bonnes manières en classe`
- `Être attentif aux explications du professeur.`
- `1` `Écouter avec calme.`
- `2` `Poser des questions poliment.`
- `3` `Respecter les camarades.`
- `Sayyida Amina`
- `Outils d'enseignement`
- `Pointeur` · `Marquer` · `Masquer` · `Annoter`
- `Tuteur de Mariam observe.`
- `1 / 12`
- `Micro` · `Caméra` · `Réseau` · `Quitter`
- `100%`
- `CLV-07 · Élèves · Web`

## 4. À garder tel quel

Conformément au principe « la maquette prime », tout ce qui suit est conservé sans modification :

- Palette sombre entière (fond, cartes, accents violet/vert/orange), typographie, iconographie (Phosphor-like, outline).
- Barre latérale : logo, ordre et libellés des 7 items, style de la pilule active avec point de statut vert.
- En-tête ligne 1 : titre, chevron retour, pastille « En ligne », groupe d'icônes (thème, cloche, réglages, compte) — aucun chevauchement mesuré, espacement régulier.
- Pilule « La séance se poursuit. » et boutons « Élèves 3/4 » / « Supports » : style, position et libellés.
- Panneau « Élèves » en entier : structure de la carte dépliée (grille 2×3, 4 boutons outline Rappeler/Choisir pour réciter/Noter/Signaler un besoin), lignes repliées Yusuf/Aïcha avec points de statut colorés, tout aligné sans débordement du cadre.
- Style des boutons outline (icône au-dessus du libellé, coin arrondi, contour fin) : **identique** entre le panneau Élèves (Rappeler…) et « Outils d'enseignement » (Pointeur…) — un seul style de bouton observé, conforme à R5. Rien à corriger sur ce point précis.
- Support partagé : badge « Chapitre 1 », titre, image d'ambiance, encart mauve, liste numérotée — mise en page, textes et couleurs.
- Barre basse (pagination, micro/caméra/réseau/quitter, zoom, plein écran) : position centrée, style des boutons ronds.
- Cadre de fenêtre (pastilles macOS) et légende de bas de page : éléments de présentation de la maquette, non des erreurs.
- Aucun avatar ni la photo de l'enseignante ne présente de déformation visible (proportions du visage cohérentes sur la vidéo et sur les avatars Yusuf/Aïcha/M) — R4 déjà respectée ici.
- Aucun chevauchement réel détecté par balayage pixel entre les blocs de l'en-tête, entre le panneau Élèves et le support, ni entre le support et la colonne vidéo (marge mesurée d'environ 15-18 px entre chaque colonne).

## 5. Rectifications (numérotées, coordonnées en px source de l'image 1586×992)

### R-1 — Bandeau « Cours enregistré » : supprimer le fond, réduire, ajouter le point rouge (règle R1)

- **Boîte fautive** : x=273, y=183, w=464, h=50.
- **Constat** : la mention légale est traitée comme une pilule violette **pleine**, aussi visible qu'un bouton d'action, avec une icône caméra à la place d'un point rouge. Elle occupe une place disproportionnée pour une simple formalité vue une fois.
- **Rectification** : retirer le fond violet et la bordure ; remplacer l'icône caméra par un **point rouge plein** (réutiliser le rouge déjà présent dans l'interface pour « Quitter », ≈ #FD5056, mesuré en (1053,878), pour ne pas créer une nouvelle paire de couleurs) ; texte petit, discret, couleur secondaire neutre (pas violet vif) : « Cours enregistré · visite de contrôle possible. » Le message reste **unique**, combinant enregistrement et visite possible (ce point est déjà correct dans la maquette, à conserver). Le nouvel élément doit être nettement plus compact (hauteur proche d'une simple ligne de texte, pas une pilule de 50 px de haut) et placé à un endroit qui ne gêne ni n'est gêné par les pilules voisines (« La séance se poursuit. », « Élèves 3/4 », « Supports »).
- **Règle** : R1.

### R-2 — Bandeau « Tuteur de Mariam observe » : fusionner dans le point rouge rétracté (règle R2)

- **Boîte fautive** : x=1208, y=712, w=337, h=53.
- **Constat** : ce bandeau ocre plein, distinct, avec sa propre paire de couleurs (brun/ocre), duplique l'information : la séance est déjà signalée comme enregistrée/observable en haut de l'écran (R-1). Ici, un parent/tuteur observe réellement, mais l'info est isolée dans un second bloc coloré, loin du point rouge, ce qui multiplie les zones d'attention à l'écran (à l'opposé de R7 : pas de surcharge visuelle).
- **Rectification** : supprimer ce bloc ocre. Quand un tuteur observe réellement la séance, le petit indicateur de R-1 se rétracte à son seul point rouge (qui se met à **clignoter subtilement**), et le texte à côté du point devient temporairement « Le tuteur de Mariam observe la séance. » (une pierre deux oiseaux : même emplacement, même composant, qui alterne entre le message légal générique et la notice de visite en cours). Aucune nouvelle couleur ocre à conserver.
- **Règle** : R2 (et R7 pour la disparition de la seconde zone colorée).

### R-3 — Vidéo de l'enseignante trop grande : la réduire en incrustation (règle R3)

- **Boîte fautive** : x=1206, y=254, w=334, h=264 (carte vidéo pleine largeur de colonne, ≈ 21 % de la largeur totale de l'écran et 42 % de la hauteur de la colonne de droite).
- **Constat** : la vidéo de l'enseignante occupe toute une colonne dédiée (largeur et hauteur), au même niveau hiérarchique que le support partagé. Le support (le contenu pédagogique, priorité de l'écran) reste comprimé dans sa propre carte pendant que la vidéo capte une part disproportionnée de l'espace.
- **Rectification** : réduire nettement la vidéo et la faire flotter **en surimpression** (z-index au-dessus) sur un coin du support partagé (par exemple le coin inférieur droit de la carte support, x≈1188 côté), en conservant son ratio d'origine (pas d'étirement, R4). L'espace de colonne ainsi libéré doit revenir au support, qui doit dominer visuellement l'écran. Le nom « Sayyida Amina » et les indicateurs (réseau, menu « ⋯ ») restent sur la vignette réduite.
- **Règle** : R3 (et R4 pour la conservation du ratio pendant la réduction).

### R-4 — Espace libéré par la vidéo : agrandir le support (conséquence de R3)

- **Boîte concernée** : colonne droite x 1206-1545, y 254-698 (ancienne vidéo + bloc « Outils d'enseignement ») et carte support x 640-1188, y 256-844.
- **Constat** : une fois la vidéo réduite en incrustation (R-3), la colonne de droite ne doit plus réserver une bande verticale pleine hauteur seulement pour la vidéo ; le bloc « Outils d'enseignement » peut rester une colonne étroite, mais le support doit pouvoir s'étendre pour redevenir la priorité de l'écran, conformément à la consigne du directeur (« le contenu partagé … c'est la priorité »).
- **Rectification** : élargir la carte du support vers la droite pour occuper l'espace laissé libre par la vidéo (en gardant « Outils d'enseignement » accessible, en colonne fine ou en repli), sans reproduire une mise en page où le support reste petit et centré alors qu'il est actif.
- **Règle** : R3 (conséquence directe).

## 6. Synthèse pour l'implémentation

- Un seul composant « notice légale + visite » à créer : état par défaut = petit texte + point rouge fixe ; état « observé » = même composant, point rouge clignotant, texte remplacé temporairement par la notice de visite. Combine R-1 et R-2.
- Un seul composant vidéo pédagogique, réutilisable en grande taille (séance côté élève) ou réduit en incrustation (ici, côté enseignant) — même carte, même ratio, juste une taille et une position différentes (coin du support, au-dessus).
- Aucune autre erreur de chevauchement, de désalignement, de carte hors cadre, de texte coupé ou de style de bouton divergent n'a été mesurée sur cet écran : le reste de la maquette (barre latérale, panneau Élèves, support, outils d'enseignement, barre basse) est à garder tel quel, en l'état.
