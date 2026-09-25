# V07 - Classe visio, en séance (mobile, sombre) : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V07_CLV-04-05-06_mobile_sombre`. Lecture seule : aucun fichier de la maquette source n'a été modifié. Aucune commande git exécutée.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-04-05-06_mobile_sombre.png` |
| Dimensions | 1491 × 1055 px, PNG, 1 406 697 octets |
| Image ouverte | oui, en entier avec l'outil Read, puis en 3 tuiles pleine hauteur ×1,5 (un écran chacune) et 9 tuiles de zoom ciblé ×2,5 à ×4 |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\s1_full.png`, `s2_full.png`, `s3_full.png` (phone complet, recadrage source (40,30,480,1010) / (515,30,480,1010) / (990,30,480,1010), ×1,5 bicubique) ; `z_notice_s1.png` (70,185,420,55 ×3), `z_video_s1.png` (80,250,410,170 ×3), `z_video_s2_full.png`/`z_card_s2_top.png` (550,240,420,220 ×3 et 555,220,400,260 ×3), `z_photo_s3.png` (1230,300,200,160 ×4), `z_buttons_s1.png`/`z_buttons_s2.png` (60,820,420,150 et 535,820,420,150 ×2,5), `z_pills_s3.png` (1010,220,430,130 ×3), `z_toolbar_s3.png` (1010,690,430,100 ×3), `z_observe_s3b.png` (990,770,480,90 ×3) |
| Méthode | Recadrage `System.Drawing.Bitmap.DrawImage` sur rectangle source précis (script `crop.ps1`, paramètres x,y,w,h,scale), lecture visuelle sur l'agrandissement ; chaque boîte de rectification ci-dessous a été vérifiée par un recadrage dédié sur ses propres coordonnées |

L'image contient **3 écrans côte à côte** (trois téléphones), même cadre iPhone (barre d'état « 9:41 »), légende sous chaque téléphone :
- **CLV-04 · Élève standard** — x source ≈ 55-495
- **CLV-05 · Interface guidée** — x source ≈ 530-970
- **CLV-06 · Enseignant** — x source ≈ 1005-1445

Les trois écrans partagent la même carte de contenu (« Chapitre 1 / Les bonnes manières en classe ») avec superposition vidéo de l'enseignante « Sayyida Amina », et le même bandeau légal en haut. Thème sombre, format mobile (cadre de téléphone, à ne pas implémenter).

## 1. Manifeste

| Écran | Rôle | Titre d'en-tête | État |
|---|---|---|---|
| CLV-04 | Élève standard | « Séance en direct » | cours enregistré, notice légale visible, parent en observation |
| CLV-05 | Interface guidée (élève) | « Ma séance » | même état, variante guidée avec contrôles d'appel colorés |
| CLV-06 | Enseignant | « Séance en direct » | séance en cours confirmée, présence 3/4, panneau d'outils enseignant (pointeur/marquer/masquer/annoter), tuteur en observation |

## 2. Composition de chaque écran, de haut en bas

### 2.1 CLV-04 · Élève standard

1. **Barre d'état iOS** (y 0-95, cadre de maquette, à ne pas implémenter).
2. **En-tête** (y ≈ 130-200) : flèche retour « ‹ » à gauche, titre « Séance en direct » (gras, blanc), sous-ligne « Classe An-Nour · Sayyida Amina », à droite pastille verte « ● En ligne ».
3. **Bandeau légal** (x 83-480, y 188-235, fond violet foncé plein, coins arrondis) : icône caméra pleine dans un carré violet clair + texte « Cours enregistré, visite de contrôle possible. ».
4. **Carte de support** (x 83-480, y 257-773, fond blanc, coins arrondis) :
   - étiquette « Chapitre 1 » (puce lavande) ;
   - titre « Les bonnes manières en classe » (gras, noir) ;
   - **vidéo/photo de l'enseignante en incrustation**, coin supérieur droit de la carte (x 315-450, y 258-403), avec bandeau nom « Sayyida Amina » et indicateur audio (barres vertes) ;
   - 2 lignes de texte factice (squelette gris) ;
   - encart lavande « Être attentif aux explications du professeur. » ;
   - ligne squelette ;
   - liste numérotée 1-2-3 : « Écouter avec calme. », « Poser des questions poliment. », « Respecter les camarades. » ;
   - 2 lignes squelette finales.
5. **Bandeau d'observation** (x 83-480, y 787-837, fond brun/ocre plein) : icône œil + « Votre parent observe la séance. ».
6. **Barre d'appel** (y ≈ 855-935) : 4 boutons circulaires égaux — Micro, Caméra, Agrandir (fond gris sombre uniforme, icône blanche), Quitter (plein rouge).
7. **Légende de maquette** « CLV-04 · Élève standard » (hors interface).

### 2.2 CLV-05 · Interface guidée

Même structure que CLV-04, avec ces différences :
1. Titre d'en-tête : **« Ma séance »** (au lieu de « Séance en direct »).
2. Pas de bandeau légal violet visible dans le cadrage (masqué/absent sur cette variante — à vérifier côté source, non mesuré ici car hors du recadrage du bandeau).
3. **Vidéo/photo de l'enseignante nettement plus grande** (x ≈ 767-927, y ≈ 222-388, soit 160 × 166 px), positionnée plus haut et plus large que sur CLV-04 et CLV-06 : elle **chevauche le titre** « Les bonnes manières en classe », dont le dernier caractère (le « e » final) est masqué derrière la photo → le texte affiche « Les bonnes manières en class ».
4. Bandeau d'observation : texte **« Ton parent regarde la séance. »** (formulation différente de CLV-04 et CLV-06).
5. Barre d'appel : 4 boutons de **styles différents** — « Parler » en disque plein vert, « Caméra » en disque plein violet, « Agrandir » en disque gris sombre (identique à CLV-04), « Quitter » en disque rouge plein.

### 2.3 CLV-06 · Enseignant

1. **Barre d'état iOS** (cadre de maquette).
2. **En-tête** : flèche retour, titre « Séance en direct », sous-ligne « Classe An-Nour · Sayyida Amina », pastille verte « ● En ligne ».
3. **Bandeau de statut** (fond vert plein, pleine largeur) : icône barres de signal + « La séance se poursuit. ».
4. **Rangée de deux pastilles** côte à côte, x 1033-1405 : « Éleves 3/4 › » (icône groupe) et « Supports › » (icône document), fond gris sombre, contour arrondi, chevron à droite sur chacune.
5. **Carte de support** (x 1033-1430, y ≈ 315-705) : même structure que CLV-04 (Chapitre 1, titre, photo en incrustation x 1269-1401 soit 132 × 133 px — taille proche de CLV-04, liste 1-2-3).
6. **Barre d'outils enseignant** (4 boutons égaux pleine largeur) : « Pointeur » (actif, icône violette), « Marquer », « Masquer », « Annoter » — même style de bouton (rectangle arrondi gris sombre) sur les 4.
7. **Bandeau d'observation** (x 1033-1405, y 792-835, fond brun/ocre) : icône œil + « Tuteur de Mariam observe. » (**3ᵉ formulation différente**).
8. **Barre d'appel** : Micro, Caméra (disques gris sombre uniformes), Réseau (icône Wi-Fi verte, même fond gris que les autres — pas de disque coloré ici), Quitter (plein rouge).

## 3. Textes lisibles, recopiés exactement

- `9:41`
- `Séance en direct` (CLV-04, CLV-06) / `Ma séance` (CLV-05)
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Cours enregistré, visite de contrôle possible.`
- `Chapitre 1`
- `Les bonnes manières en classe` (CLV-04, CLV-06) / `Les bonnes manières en class` — tronqué (CLV-05)
- `Sayyida Amina` (bandeau nom sur la vidéo)
- `Être attentif aux explications du professeur.`
- `1` `Écouter avec calme.`
- `2` `Poser des questions poliment.`
- `3` `Respecter les camarades.`
- `Votre parent observe la séance.` (CLV-04)
- `Ton parent regarde la séance.` (CLV-05)
- `Tuteur de Mariam observe.` (CLV-06)
- `Micro` · `Caméra` · `Agrandir` · `Quitter` (CLV-04)
- `Parler` · `Caméra` · `Agrandir` · `Quitter` (CLV-05)
- `Micro` · `Caméra` · `Réseau` · `Quitter` (CLV-06)
- `La séance se poursuit.` (CLV-06)
- `Éleves 3/4` (CLV-06 — voir orthographe au §5)
- `Supports` (CLV-06)
- `Pointeur` · `Marquer` · `Masquer` · `Annoter` (CLV-06)
- `CLV-04 · Élève standard` / `CLV-05 · Interface guidée` / `CLV-06 · Enseignant` (légendes de maquette)

## 4. À garder tel quel

- La disposition générale des 3 écrans, l'ordre des blocs (en-tête → carte de support → notices → barre d'appel), et le fait que la carte de support domine visuellement l'écran.
- Le thème sombre, la palette (fond sombre neutre, carte de support blanche, accents violets, vert de statut, rouge de fin d'appel).
- Les textes pédagogiques de la carte (« Chapitre 1 », titre, encart lavande, liste 1-2-3) et leur mise en forme.
- La photo/vidéo de l'enseignante en incrustation sur un coin de la carte (le principe, pas la taille — voir R3) : dans ses tailles CLV-04 et CLV-06, le ratio largeur/hauteur (135×145 et 132×133) est proche du carré, sans étirement visible ni déformation du visage (R4 respecté à ces deux endroits).
- Le bandeau nom « Sayyida Amina » + indicateur audio sur la vidéo.
- Le panneau d'outils enseignant CLV-06 (Pointeur/Marquer/Masquer/Annoter) : 4 boutons égaux, même style, pleine largeur, pas de grappe en coin — conforme à R7.
- Les pastilles « Éleves 3/4 » et « Supports » de CLV-06 : bien alignées côte à côte, ne débordent pas du cadre.
- Le bouton « Quitter » plein rouge, identique sur les 3 écrans.
- Le bandeau vert « La séance se poursuit. » de CLV-06.
- La barre d'état iOS et le cadre de téléphone (décor de maquette, non implémentés).

## 5. Rectifications

| # | x | y | w | h | Ce que montre la maquette | Règle | Correction attendue |
|---|---|---|---|---|---|---|---|
| 1 | 83 | 188 | 397 | 47 | **Bandeau légal en rectangle plein** violet foncé avec icône caméra, sur CLV-04 (même défaut sur CLV-05/CLV-06 où le bandeau est probablement présent hors du recadrage détaillé ici) | R1 | Supprimer le fond rectangulaire ; remplacer l'icône caméra par un simple point rouge (= enregistrement) ; texte petit et discret, une seule fois, placé sans gêner le reste de l'en-tête |
| 2 | 83 | 787 | 397 | 50 | **Bandeau séparé** « Votre parent observe la séance. » (CLV-04), en plus du bandeau légal du haut : les deux bandeaux coexistent alors qu'ils devraient être combinés | R1, R2 | Quand un parent/tuteur observe, rétracter le bandeau légal du haut à son seul point rouge clignotant, et faire apparaître ce texte temporaire à sa place (une pierre deux oiseaux) ; supprimer ce second bloc séparé |
| 3 | 767 | 222 | 160 | 166 | **Vidéo/photo de l'enseignante trop grande** sur CLV-05, positionnée en pleine largeur haute de la carte : elle chevauche le titre et **tronque le texte** (« en class » au lieu de « en classe ») | R3, R6 | Réduire la vidéo à une taille cohérente avec CLV-04/CLV-06 (≈ 132-145 px de côté), en surimpression sur un coin, sans jamais recouvrir de texte ; le support garde toute sa largeur et sa hauteur |
| 4 | 558 | 767 | 377 | 50 | **Bandeau d'observation** de CLV-05 : texte différent (« Ton parent regarde la séance. ») de celui de CLV-04 (« Votre parent observe la séance. ») et de CLV-06 (« Tuteur de Mariam observe. ») pour désigner le même événement | R2 | Un seul libellé, cohérent sur les 3 écrans (adapté seulement au rôle du destinataire — parent/tuteur — pas à un style de phrase différent à chaque fois) ; même remarque pour le point rouge/notice combinée du n°2 |
| 5 | 1033 | 792 | 372 | 43 | Bandeau d'observation CLV-06 : **3ᵉ formulation** « Tuteur de Mariam observe. », toujours pas alignée avec les deux autres écrans | R2 | Harmoniser avec le libellé unique retenu au n°4 |
| 6 | 60 | 855 | 420 | 90 | Barre d'appel CLV-04 : Micro/Caméra/Agrandir en disques **gris sombre uniformes** | R5 (référence) | — (référence de style correcte, à généraliser — voir n°7) |
| 7 | 535 | 855 | 420 | 90 | Barre d'appel CLV-05 : mêmes actions Micro→« Parler » et Caméra rendues en **disques pleins vert et violet**, un style totalement différent de CLV-04/CLV-06 pour les mêmes commandes | R5 | Un seul style de bouton pour la barre d'appel, identique entre écran normal et écran guidé ; pas de nouvelle paire de couleurs (vert/violet plein) réservée à ce seul écran |
| 8 | 1260 | 315 | 133 | 133 | Vidéo de l'enseignante CLV-06 : taille correcte, mais **aucun z-index de surimpression visible** distinct de CLV-04 — à uniformiser avec le traitement final retenu (coin, surimpression, taille unique) une fois R3 appliqué | R3 | Reprendre la même taille/traitement d'incrustation qu'après correction du n°3, sur les 3 écrans |
| 9 | 1033 | 220 | 372 | 100 | Libellé « **Éleves** 3/4 » (CLV-06) : accent manquant sur le é de « Élèves » | relevé (orthographe) | Corriger en « Élèves 3/4 » |
| 10 | 60 | 130 | 420 | 70 | Titre d'en-tête « **Séance en direct** » (CLV-04) vs « **Ma séance** » (CLV-05) pour un même flux d'appel vu côté élève, avec/sans mode guidé | relevé (libellé incohérent) | À confirmer côté coordinateur : soit un titre unique, soit documenter que le mode guidé change intentionnellement le titre |

## 6. Note de méthode

Conformément au mandat : la maquette prime. Les rectifications ci-dessus corrigent uniquement des erreurs (chevauchement et troncature de texte prouvés au n°3, incohérence de libellés prouvée aux n°4-5, incohérence de style de bouton prouvée aux n°6-7, faute d'orthographe au n°9) ou appliquent les corrections imposées R1/R2 par le directeur. Aucune couleur, disposition, icône ou texte pédagogique n'a été changé par goût.
