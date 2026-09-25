# V06 - Classe visio, fin de séance (desktop, sombre) : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V06_CLV-10_fin_desktop_sombre`. Lecture seule : aucun fichier de la maquette source n'a été modifié. Aucune commande git exécutée.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-10_fin_desktop_sombre.png` |
| Dimensions | 1586 × 992 px, PNG, 1 231 309 octets |
| Image ouverte | oui, en entier avec l'outil Read, puis en 4 tuiles ×2 (quadrants) et 2 tuiles de zoom ciblé ×3 |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\V06_CLV-10_fin_desktop_sombre\t_r0_c0_x0_y0.png`, `t_r0_c1_x793_y0.png`, `t_r1_c0_x0_y496.png`, `t_r1_c1_x793_y496.png` (quadrants 793×496, agrandis ×2 bicubique) ; `c_header_titre.png` (crop source 60,90,700,110, ×3) ; `c_sidebar_nav_actif.png` (crop source 60,240,270,150, ×3) |
| Échantillonnage coordonnées | Recadrage `System.Drawing.Bitmap.DrawImage` sur rectangle source précis, puis lecture visuelle sur l'agrandissement ; chaque boîte de rectification ci-dessous a été vérifiée par un recadrage dédié sur ses propres coordonnées |

L'image ne contient **qu'un seul écran** (une seule fenêtre de navigateur maquettée, coins de fenêtre macOS à titre de cadre uniquement, à ne pas implémenter). Aucun écran côte à côte.

## 1. Manifeste

| Fichier | Écran | État | Thème | Format |
|---|---|---|---|---|
| `CLV-10_fin_desktop_sombre.png` | Classe visio — écran de fin de séance, vu côté tuteur/parent (colonne « Foyer » présente dans le menu, profil actif « Mariam » en haut à droite) | séance terminée, cahier de séance prêt mais à compléter, 3/3 élèves ont été connectés | sombre | desktop navigateur (fenêtre encadrée) |

## 2. Composition, de haut en bas

1. **Barre de fenêtre** (y 0-90, cadre de maquette) : trois pastilles de feu tricolore (rouge/jaune/vert), décor de navigateur, à ne pas implémenter.
2. **Menu latéral** (x 60-291, pleine hauteur) :
   - logo « Rewayah / Academy » (icône livre violette) ;
   - 7 destinations : Accueil, Foyer, **Séance en direct** (active, fond violet plein, icône caméra, point vert à droite), Classes, Historique, Bibliothèque, Profil.
3. **En-tête de contenu** (y 90-210) :
   - à gauche : flèche retour « ‹ », titre « Séance en direct », sous-ligne « Classe An-Nour · Sayyida Amina » suivie d'une pastille verte « ● En ligne » ;
   - à droite : bascule clair/sombre, cloche de notification (point violet non-lu), roue de réglages, avatar rond « M » + « Mariam » + chevron.
4. **Bloc central de statut** (centré horizontalement, y ≈ 230-460) :
   - cercle violet avec coche, entouré de 4 étincelles décoratives ;
   - titre « Séance terminée » (grand, gras, blanc) ;
   - sous-titre « Le cahier est prêt avec les informations de la séance. ».
5. **Carte récapitulative** (x 630-1163, y 490-800, surface sombre légèrement plus claire que le fond, bordure fine, séparateurs horizontaux pâles entre les 4 lignes) :
   - icône livre + « Classe An-Nour » (fort) / « Sayyida Amina » (secondaire) ;
   - icône horloge + « Fin » (label) / « 15:16 » (valeur forte) ;
   - icône groupe + « 3 élèves connectés » (fort) / « sur 3 inscrits » (secondaire) ;
   - icône document + « Cahier de séance » (label) puis pastille ambre « ● Cahier à compléter ».
6. **CTA principal** pleine largeur de la carte : « Ouvrir le cahier → », fond lavande plein, texte quasi-noir, flèche à droite, centré.
7. **Bouton secondaire** pleine largeur : « Revenir à ma journée », contour sombre, texte clair, centré.

## 3. Textes lisibles, recopiés exactement

- `Rewayah` / `Academy`
- `Accueil` · `Foyer` · `Séance en direct` · `Classes` · `Historique` · `Bibliothèque` · `Profil`
- `Séance en direct`
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Mariam`
- `Séance terminée`
- `Le cahier est prêt avec les informations de la séance.`
- `Classe An-Nour`
- `Sayyida Amina`
- `Fin`
- `15:16`
- `3 élèves connectés`
- `sur 3 inscrits`
- `Cahier de séance`
- `Cahier à compléter`
- `Ouvrir le cahier` (suivi d'une flèche →)
- `Revenir à ma journée`

## 4. À garder tel quel

Conformément au mandat (« la maquette PRIME »), tout ce qui suit est conservé sans modification :

- la structure du menu latéral, ses 7 destinations, ses icônes et l'état actif plein violet ;
- la palette sombre, les violets d'accent, les surfaces de carte, les séparateurs internes ;
- le bloc central (cercle-coche + étincelles + titre + sous-titre), sa composition et son centrage ;
- la carte récapitulative : ses 4 lignes, ses icônes, ses séparateurs, l'alignement label/valeur ;
- la pastille ambre « Cahier à compléter » ;
- le couple de boutons pleine largeur (CTA plein lavande + bouton secondaire à contour), leurs libellés, leur ordre et leurs formes (coins très arrondis identiques) ;
- l'en-tête haut-droit (bascule thème, cloche, réglages, compte) : éléments espacés, non chevauchés, alignés sur une seule ligne ;
- tous les textes recopiés en §3 ;
- le cadre de fenêtre de navigateur (décor de maquette, hors implémentation).

## 5. Rectifications

| # | x | y | w | h | Ce que montre la maquette | Règle | Correction attendue |
|---|---|---|---|---|---|---|---|
| 1 | 360 | 113 | 362 | 67 | L'en-tête affiche encore **« Séance en direct »** en titre et la pastille **« ● En ligne »** (vert), alors que le contenu de l'écran affiche « **Séance terminée** », un « Fin 15:16 » déjà passé et un cahier de séance à compléter : deux états contradictoires sur le même écran, l'un dit « en cours », l'autre dit « terminé ». | relevé — libellé incohérent (même principe que V1 §5 n° 4 : un seul état temporel dérivé de la même source de données) | Faire dériver le titre et le badge du **même état** que le corps de l'écran : titre « Séance terminée » (ou « Compte-rendu de séance »), pastille neutre/grise « Terminée » ou pastille masquée sur cet écran. Ne jamais laisser « En direct »/« En ligne » actif une fois la séance close. |
| 2 | 70 | 311 | 210 | 61 | L'entrée de menu **« Séance en direct »** reste affichée en **état actif plein** (fond violet) avec son **point vert clignotant de « en direct »**, alors que la séance affichée est terminée. | relevé — libellé/état incohérent, même cause que la rectification n° 1 | Une fois la séance terminée, retirer le point vert « en direct » de l'entrée de menu (ou le remplacer par un indicateur neutre) ; l'entrée peut rester en surbrillance de navigation (écran courant) mais sans signal « en direct » actif. |

Aucune autre erreur de chevauchement, désalignement, débordement de carte, avatar déformé ou style de bouton divergent n'a été relevée sur cet écran : la grille, les marges de carte (x 630-1163 alignées sur toute la colonne), le centrage des textes et la forme unique des boutons sont respectés.

## 6. États à dériver (absents de l'image)

- Le contenu de la carte (nom de l'enseignant, heure de fin, nombre d'élèves connectés/inscrits, statut du cahier) doit provenir des données réelles de la séance, jamais de constantes.
- L'état « Cahier à compléter » / « Cahier complété » doit refléter l'état réel du cahier de séance.
- Aucune notice d'enregistrement ni notice de visite n'apparaît sur cet écran : normal, la séance est terminée (R1/R2 du 25/09 ne s'appliquent pas ici, il n'y a plus de flux vidéo actif).
- Aucune vidéo n'est présente sur cet écran (R3 non applicable ici).
