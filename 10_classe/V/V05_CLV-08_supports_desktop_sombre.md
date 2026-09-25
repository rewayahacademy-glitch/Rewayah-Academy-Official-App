# V05 - CLV-08 Supports, Enseignant desktop, thème sombre : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V05_CLV-08_supports_desktop_sombre`. Lecture seule : aucun fichier hors de `C:\RA\pilotage\10_classe\V` n'a été modifié, aucune commande git exécutée.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-08_supports_desktop_sombre.png` |
| Dimensions | 1586 × 992 px, 24 bpp RGB |
| Image ouverte | oui, en entier avec l'outil Read, puis en 6 tuiles de zone (×2) et 5 tuiles de vérification (×3-4) |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\CLV-08\t1_header.png` à `t6_bottombar.png` (zones : en-tête y 60-260, barre latérale x 0-300, panneau Supports x 300-650, support partagé x 650-1200, colonne vidéo/outils x 1190-1530, barre basse y 820-992) ; `z1_notice.png` à `z6_supportcard.png` pour les rectifications |
| Échantillonnage | `System.Drawing.Bitmap.GetPixel`, balayages de lignes/colonnes en pas de 2-10 px pour situer chaque bord (transition de couleur = bord de l'élément) |
| Vérification des rectifications | chaque boîte (x,y,w,h) listée en §5 a été recadrée séparément (tuiles `z1` à `z3`) pour confirmer qu'elle entoure bien l'élément fautif, sans le couper |

L'image ne contient qu'un seul écran (pas de composition côte à côte). Un libellé de légende sous le cadre du navigateur confirme le contexte : `CLV-08 · Supports · Web`.

### Manifeste

| Écran | x | y | w | h | Description |
|---|---|---|---|---|---|
| Enseignant · Desktop navigateur · Sombre · Supports partagés en salle | 57 | 56 | 1473 | 876 | Cadre de fenêtre macOS (feux de trafic), séance en direct, panneau « Supports » ouvert, support « Chapitre 1 » affiché, vidéo de l'enseignante en incrustation à droite |

## 4. Fiche d'écran : Supports (desktop, sombre)

### 4.1 Composition, de haut en bas

1. **Barre de fenêtre** (y 56-92) : trois feux de trafic (rouge, orange, vert). Cadre de maquette, à ne pas implémenter.
2. **En-tête, ligne 1** (y ≈ 90-150) : à gauche, chevron retour `‹` puis titre « Séance en direct » (gras, grand) ; à droite, interrupteur clair/sombre (thème actif = sombre), cloche de notification avec point violet, icône réglages, avatar rond « M » + « Mariam » + chevron.
3. **En-tête, ligne 2** (y ≈ 155-180) : « Classe An-Nour · Sayyida Amina » (texte secondaire) puis pastille verte « ● En ligne ».
4. **Rangée de badges** (y ≈ 197-253), 4 éléments côte à côte, non chevauchants :
   - badge violet plein, icône caméra, « Cours enregistré, visite de contrôle possible. » (x ≈ 305-770) — **voir rectification 1**
   - badge vert foncé, icône histogramme, « La séance se poursuit. » (x ≈ 785-1135)
   - badge contour sombre, icône groupe, « Élèves 3/4 › » (x ≈ 1150-1310)
   - badge contour sombre, icône document, « Supports › » (x ≈ 1335-1505)
5. **Colonne gauche : barre latérale de l'app** (x 60-290, pleine hauteur) : logo livre + « Rewayah Academy » ; puis 7 items de nav verticaux avec icône + libellé : « Accueil », « Foyer », « Séance en direct ● » (item actif, pilule violette pleine avec point vert « en direct »), « Classes », « Historique », « Bibliothèque », « Profil ». Un seul style de pilule active, cohérent avec le reste de l'app.
6. **Colonne centrale : panneau « Supports »** (x 300-655, y 268-825, fond carte sombre plus clair que le fond de page, bord arrondi), de haut en bas :
   - en-tête « Supports » (gras) + croix de fermeture `×` à droite ;
   - section « Reprendre » : carte « Chapitre 1 / Les bonnes manières » (miniature ronde dorée à gauche, « Support de cours · v2.0 » en dessous), bouton plein « Ouvrir » à droite (ne dépasse pas le cadre de la carte, marge ≈ 34 px vérifiée) ;
   - section « Récents » avec lien « Voir tout → » aligné à droite ; deux lignes-cartes cliquables « Fiche de mémorisation / PDF · 12 pages · v1.1 » et « Exercices – Chapitre 1 / PDF · 8 pages · v1.0 », chevron `›` à droite, séparateur fin entre les deux ;
   - section « Ressources de la Classe » : ligne « Bibliothèque An-Nour / 24 ressources » (icône dossier violet), chevron `›` ;
   - bouton pleine largeur « Voir toute la bibliothèque → », même violet clair que « Ouvrir ».
7. **Colonne centre-droite : support partagé** (x 655-1185, y 268-838, carte blanche — seule zone claire de l'écran sombre), dans l'ordre :
   - pastille « Chapitre 1 » (violet doux) ;
   - titre « Les bonnes manières en classe » (grand, gras, sur deux lignes) ;
   - à droite du titre, photo d'illustration (lanternes, livres empilés) dans un cadre arrondi ;
   - 3 barres grises (texte de remplissage) ;
   - encart mauve clair : « Être attentif aux explications du professeur. » ;
   - barre grise ;
   - liste numérotée à 3 items (pastille ronde numérotée + libellé) : « 1 Écouter avec calme. », « 2 Poser des questions poliment. », « 3 Respecter les camarades. » ;
   - 2 barres grises de bas de carte.
8. **Colonne droite : vidéo et outils** (x 1204-1512, y 271-838) :
   - **carte vidéo** de l'enseignante (x 1204-1508, y 271-514, soit 304 × 243 px) : portrait de « Sayyida Amina », libellé de nom en incrustation bas-gauche, barres de niveau audio (vert) bas-droite, bouton « ⋯ » — **voir rectification 3** ;
   - carte « Outils d'enseignement » (y ≈ 540-676) : titre puis grille de 4 boutons carrés (icône + libellé) : « Pointeur » (actif, icône violette), « Marquer », « Masquer », « Annoter » ;
   - **bandeau brun/orange séparé** (x 1204-1512, y 705-757) : icône œil jaune + « Tuteur de Mariam observe. » — **voir rectification 2**.
9. **Barre de contrôle flottante, bas de l'écran** (y ≈ 825-905) : à gauche, pagination du support « ‹ 1 / 12 › » ; au centre, pilule sombre avec 4 actions séparées par des filets : « Micro », « Caméra », « Réseau » (icônes + libellés), « Quitter » (bouton rond rouge) ; à droite, contrôle de zoom « − 100% + ⛶ ». Les trois groupes sont bien séparés, sans chevauchement.
10. **Légende hors cadre** (y ≈ 950) : `CLV-08 · Supports · Web` — repère de fichier, hors interface.

### 4.2 Textes lisibles, recopiés exactement

- `Séance en direct`
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Cours enregistré, visite de contrôle possible.`
- `La séance se poursuit.`
- `Élèves 3/4`
- `Supports`
- `Mariam`
- `Rewayah Academy`
- `Accueil` / `Foyer` / `Séance en direct` / `Classes` / `Historique` / `Bibliothèque` / `Profil`
- `Supports` (panneau) / `Reprendre`
- `Chapitre 1` / `Les bonnes manières` / `Ouvrir` / `Support de cours · v2.0`
- `Récents` / `Voir tout` (→)
- `Fiche de mémorisation` / `PDF · 12 pages · v1.1`
- `Exercices – Chapitre 1` / `PDF · 8 pages · v1.0`
- `Ressources de la Classe`
- `Bibliothèque An-Nour` / `24 ressources`
- `Voir toute la bibliothèque` (→)
- `Chapitre 1` (support) / `Les bonnes manières en classe`
- `Être attentif aux explications du professeur.`
- `1 Écouter avec calme.` / `2 Poser des questions poliment.` / `3 Respecter les camarades.`
- `Sayyida Amina`
- `Outils d'enseignement` / `Pointeur` / `Marquer` / `Masquer` / `Annoter`
- `Tuteur de Mariam observe.`
- `1 / 12`
- `Micro` / `Caméra` / `Réseau` / `Quitter`
- `100%`
- `CLV-08 · Supports · Web`

## 5. À garder tel quel

- La disposition générale en 3 colonnes (barre latérale, bibliothèque/supports, support partagé + panneau enseignant), les couleurs, le fond sombre, les icônes et tous les textes non visés par une rectification ci-dessous.
- Le panneau « Supports » (bibliothèque en salle) : hiérarchie « Reprendre / Récents / Ressources de la Classe », vignettes, bouton « Ouvrir » et bouton pleine largeur « Voir toute la bibliothèque » — même violet clair, même forme de pilule pour les deux, aucun dépassement du cadre de carte (vérifié par balayage de pixels : le bouton « Ouvrir » s'arrête à x≈622, la carte à x≈656, marge propre).
- Le support partagé (carte blanche « Les bonnes manières en classe ») : titre, image, encart mauve, liste numérotée — mise en page fidèle au mandat « le support est la priorité ».
- La barre de contrôle flottante du bas (pagination, Micro/Caméra/Réseau/Quitter, zoom) : trois groupes bien séparés, aucun chevauchement, aucune surcharge de boutons dans un coin.
- La barre latérale de l'app et son item actif « Séance en direct » en pilule pleine.
- La carte « Outils d'enseignement » (grille de 4 icônes claires, un seul style de bouton, pas de grappe excessive).
- Aucune déformation d'avatar ou de vidéo observée : la photo de Sayyida Amina garde des proportions de visage naturelles dans son cadre 304 × 243 px (aucun étirement horizontal constaté).

## 6. Rectifications

| # | Boîte (x, y, w, h) px source | Ce que montre la maquette | Règle | Correction attendue |
|---|---|---|---|---|
| 1 | (305, 197, 465, 57) | Bandeau plein violet avec icône caméra : « Cours enregistré, visite de contrôle possible. » — c'est un vrai bandeau (fond, padding, coins arrondis), pas une mention discrète | R1 | Retirer le fond/rectangle. Remplacer par un texte petit et discret, précédé d'un simple **point rouge** (pas l'icône caméra actuelle) signifiant l'enregistrement, combinant en une seule mention enregistrement + visite possible (le texte actuel convient déjà pour le fond ; c'est la forme visuelle — bandeau plein — qui est fautive). Le loger là où il ne gêne rien (par ex. sous le sous-titre de classe, en ligne fine) plutôt qu'en badge pleine largeur au même rang que les indicateurs d'état |
| 2 | (1204, 705, 308, 52) | Bloc séparé brun/orange, plein cadre, icône œil : « Tuteur de Mariam observe. », posé en permanence sous « Outils d'enseignement » | R2 | Supprimer ce bloc séparé. Quand un parent/tuteur observe réellement : le point rouge de la rectification 1 se met à clignoter subtilement (seul reste visible), et le texte de la mention légale est remplacé par la notice temporaire « Tuteur de Mariam observe. » (même emplacement discret, pas de nouveau bloc dans la colonne droite) |
| 3 | (1204, 271, 304, 243) | Vidéo de l'enseignante en carte pleine largeur de colonne, ≈ 304 × 243 px, soit environ 28 % de la hauteur utile de l'écran et toute la largeur de la colonne droite — elle capte une colonne entière | R3 | Réduire fortement la vidéo et la poser **en surimpression (z-index au-dessus)** sur un coin du support partagé (ex. coin bas-droit de la carte blanche), en petit format proportions conservées. Ne doit prendre ni colonne dédiée ni hauteur au support. Une fois la vidéo retirée de la colonne droite, élargir le support partagé (actuellement compacté à x 655-1185, soit 530 px de large seulement) pour qu'il occupe l'espace libéré et redevienne l'élément dominant de l'écran, conformément au mandat « le contenu partagé est la priorité » |

Ces trois rectifications sont liées : une fois la vidéo réduite en incrustation (rectif. 3), la colonne de droite ne conserve que « Outils d'enseignement » (ou fusionne dans la barre de contrôle basse), et l'espace récupéré agrandit le support partagé, ce qui répond aussi à la remarque du directeur sur le contenu « très compacté au centre ».
