# UX_REVIEW SALLE-ORDINATEUR : l'écran de l'enseignant sur ordinateur, et les modes du Coran

Demandes du directeur du 11/11/2026, sur sa capture de l'enseignant à 1440 x 900. Elles prévalent
sur le plan de composition du 26/10/2026 (`PLAN-SALLE-COMPOSITION-2026-10-26.md`) pour ces points.
Aucune règle métier modifiée : ni droit, ni état serveur, ni donnée nouvelle.

## A. La vidéo de l'enseignant dans le panneau des élèves

| Règle | Source | Conclusion |
| :-- | :-- | :-- |
| Proximité et région commune : ce qui va ensemble se range dans le même cadre | Gestalt (proximité, région commune) ; Material 3, « Layout · Panes » | La vidéo flottait seule en haut à gauche, sans taille commune avec le reste. Elle est maintenant **le premier élément de la liste du panneau des Élèves**, à la largeur des cartes, au même rayon (`arrondiMd`), séparée par le même écart (16). Format 4:3 : plus haute qu'une carte d'élève. |
| Une seule surface qui se replie avec son contenu | Material 3, « Panes · hide and show » | Panneau fermé ou focus : la vidéo part avec lui, rien ne flotte ailleurs. |
| Un état ne se lit jamais par la couleur seule ; le statut du système reste visible | Nielsen n° 1 (visibilité de l'état) ; WCAG 2.2, 1.4.1 | Caméra allumée, panneau fermé : la tuile Caméra de la barre du bas reste au repos (icône caméra non barrée, libellé « Éteindre la caméra, Caméra allumée ») ; éteinte, elle passe au violet de marque, icône barrée. Testé. |
| Aucun contenu qui défile dans un cadre de hauteur fixe | `DECISION-DEFILEMENT-2026-11-01.md` | **Non résolu, inchangé** : la liste du panneau défile toujours dans le panneau (défaut C6-7 du constat). La vidéo fait partie de cette même liste ; elle n'ajoute pas de second défilement. |

## B. Le haut réparti sur toute la largeur

| Règle | Source | Conclusion |
| :-- | :-- | :-- |
| Un outil se pose près de l'objet sur lequel il agit | Fitts ; Gestalt (proximité) ; Apple HIG, « Toolbars » | Une seule rangée : au début la Classe et l'enseignant ; **au centre** le titre du support (« Coran · Page 604 ») avec zoom, ranger et focus collés à lui ; à la fin la pilule d'état, posée telle quelle. |
| Début et fin suivent le sens de lecture | Material 3, « Bidirectionality » | Rangée miroir en arabe (testé à 1280, 1440, 1920, texte x1 et x1,3). |
| Repli prévisible quand la place manque | Material 3, « Applying layout · Adaptive » | Ordre : le nom de l'enseignant part d'abord (bord de début sous 192 points), puis le nom de la Classe et le titre du support se coupent par des points de suspension ; outils et pilule gardent leur taille. Testé à 860 x 720 en texte x2. |

## C. Le Coran grand sur ordinateur

| Règle | Source | Conclusion |
| :-- | :-- | :-- |
| Le contenu principal prend la place, le chrome la cède | Material 3, « Canonical layouts · Supporting pane » ; Nielsen n° 8 (minimalisme) | La rangée de titre du support, qui prenait 72 points au-dessus de la page, est montée dans le haut. La page prend toute la hauteur entre le haut et la barre du bas. |

Mesures (test `C :` de `test/features/salle_ordinateur_test.dart`, vraies polices, 1440 x 900,
deux panneaux ouverts) : boîte de la page 499 x 642 avant, 541 x 696 après ; texte de la page
342 x 566 avant, **371 x 614 après (+8 %)**.

**Limite, à dire au directeur** : la page de Médine a quinze lignes et son interligne est fixé à
1,95 corps ; sa taille est bornée par la **hauteur**, pas par la largeur. Fermer un panneau ne la
grandit donc pas (elle se recentre). Aller plus loin demande soit une barre du bas plus basse
(zone d'un autre agent), soit un interligne plus serré sur ordinateur (typographie du mushaf :
décision du directeur).

## D. Les modes du lecteur du Coran

Les mots du directeur (« mode focus, ou agrandi, et mode normal ; le troisième ne marche pas »)
correspondent au choix « Mode de lecture » du lecteur (`/eleve/coran`, `MushafPage`), pas au
bouton Focus de la salle. Sur la page de Médine, « Focus » rendait la même colonne que « Lecture
agrandie » ; son seul ajout (surligner une plage désignée par la classe) n'est envoyé par aucun
écran. Il est retiré du choix ; un focus gardé ou reçu retombe sur la page du mushaf. Le bouton
Focus de la salle (retirer les panneaux) fonctionne et reste.
