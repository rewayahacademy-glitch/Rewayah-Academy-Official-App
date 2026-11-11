# UX_REVIEW_BARRE-ORDINATEUR : la barre du bas de l'enseignant sur ordinateur

Lot demandé par le directeur le 11/11/2026 : « harmoniser aussi la barre d'outils en bas sur
ordinateur […] simplifier et permettre d'atteindre les outils principaux avec moins de clics […]
pour les enseignants les moins techniques ». Cahier §8 : « des boutons sont posés n'importe où, et
les outils sont moches et ne marchent pas ».

## Ce qui n'est pas prouvé (à lire d'abord)

- **Rien n'est prouvé en production.** Tout ce qui suit est `présent dans le code` et `testé
  localement` (tests de widgets, polices de test et vraies polices). Les captures « après » sont des
  **captures de test** (même fond, mêmes polices que l'application) ; la capture « avant » est celle
  de la **vraie application** (banc du 11/11).
- **« Les outils ne marchent pas » n'est pas réglé ici.** Ce lot place et nomme les outils ; il ne
  touche ni au tracé, ni à son envoi aux élèves (`synchro_salle.dart`, zone d'un autre agent). Je
  n'ai pas pu vérifier qu'un trait ou le pointeur arrive chez l'élève en production.
- **Le gain en clics est faible, et je le dis.** Les gestes courants étaient déjà à 1 ou 2 clics.
  Le vrai défaut était ailleurs : neuf doublons derrière « Plus », des états illisibles (le violet
  du Tableau), une page qui rétrécissait à chaque appui sur Écrire, des tuiles qui glissaient.
- Les références (Zoom, Meet, Teams, HIG, Material 3, Nielsen) sont citées **de mémoire, non
  relues en ligne le 11/11** : la règle retenue est indiquée, la page exacte est à revérifier.

## 1. Diagnostic par l'usage (avant, base `4e6e63f48`)

Fichiers : `lib/features/salle_seance/salle_ordinateur.dart` (noté SO), `dock_seance.dart` (DS),
`commandes_pedagogiques.dart` (CP). Actions réellement branchées en production :
`lib/features/salle/salle_page.dart` l. 1402-1525.

| Tuile (avant) | Ce qu'elle fait vraiment | Ce qui ne va pas |
| :--- | :--- | :--- |
| Élèves | ouvre ou ferme le panneau de gauche (SO l. 671-680) | aplat lilas « retenu » : le même que l'outil tenu, alors que ce n'est pas un outil |
| Pointeur | prend le pointeur (SO l. 682) | **rendu même sans page ni tableau** (capture 06 : la scène vidéo au centre) : un bouton qui ne peut pas aboutir |
| Écrire | prend le stylo (SO l. 683) | **disparaît** sans page (capture 06), réapparaît avec la page (capture 07) : Tableau et Plus glissent de 88 points ; à l'appui, la palette se pose **entre la page et la barre** (SO l. 210-218) et **vole 80 points de hauteur à la page**, qui saute |
| Tableau | ouvre ou ferme le tableau pour la classe (DS l. 445-464) | bascule « coupée » quand le tableau est **fermé** : violet de marque plein (DS l. 283, l. 455). Sur le Coran, l'enseignant voit un Tableau violet, « allumé » à ses yeux : l'état se lit à l'envers |
| Plus | ouvre les Commandes à droite, à la place de la Bibliothèque (SO l. 686-692) | **tout son contenu est en double** sur ordinateur (voir ci-dessous) ; et il chasse la Bibliothèque du panneau de droite |
| Micro, Caméra | ouvrent ou coupent (DS l. 388-417) | rien : états et couleurs du 25/10, gardés |
| Bibliothèque | ouvre ou ferme le panneau de droite (SO l. 708-717) | même aplat lilas que l'outil tenu ; deux tuiles lilas en même temps (Bibliothèque et Élèves) plus l'outil : « un seul état actif » est faux |
| Réduire, Quitter | SORTIE-SALLE | rien, gardés tels quels |
| (focus) | en focus, une tuile « Quitter le focus » s'insère avant Quitter (DS l. 536-539) | la barre change de longueur ; la sortie du focus est déjà contre le titre du support, en haut |

**Ce que « Plus » ouvrait en production (CP l. 491-602, `onAffichage: null`, `onEffacerNotes`
absent) :** Bibliothèque (déjà une tuile), le support et son menu « Ranger » (déjà la croix en
haut), la pagination (déjà la flèche contre la page), le zoom (déjà en haut), le focus (déjà en
haut et touche F), l'onglet Outils avec Pointeur et Écrire (déjà des tuiles) et **une deuxième
palette d'écriture** (`EcritureSeance`, en plus de `BarreOutilsSalle`). Rien d'unique : neuf
doublons, et deux façons d'écrire.

**Outils en haut et outils en bas :** zoom, ranger et focus sont contre le titre du support (en
haut, refait ce matin, gardé) ; Pointeur, Écrire, Tableau en bas ; la palette au milieu. Trois
endroits pour « ce qui agit sur la page ». La barre du haut est juste (un outil près de son
objet) ; c'est le reste qui s'éparpillait.

## 2. La proposition, codée

Une barre, cinq groupes nommés par ce que l'enseignant veut faire, séparés d'un filet, neuf tuiles
toujours à la même place (sens de lecture ; miroir en arabe) :

```
[ Micro  Caméra ] | [ Élèves ] | [ Pointeur  Écrire ]  ……  [ Bibliothèque  Tableau ] | [ Réduire  Quitter ]
  Ma voix et mon image  Ma classe     Sur la page                 Le support                Sortir
```

- **Plus de « Plus » sur ordinateur.** Tout ce qu'il ouvrait reste à un clic, à un seul endroit.
  (Le téléphone garde son « Commandes » : rien n'y change.)
- **Un seul aplat lilas : l'outil tenu** (Pointeur ou Écrire), dit par trois signaux : l'aplat,
  l'icône pleine, l'état « sélectionné » lu, plus l'infobulle « Pointeur en main (Échap pour le
  reposer) ». Un deuxième appui ou Échap le repose.
- **Ouvert ou montré = un trait sous l'icône** (nouveau ton `TonTuileSalle.ouvert`, dans le
  composant du core) : panneau Élèves ouvert, Bibliothèque ouverte, **tableau montré à la classe**.
  Plus de violet sur le Tableau. Trois signaux : le trait, l'icône pleine, « sélectionné ».
- **Violet = coupé (micro, caméra seulement), rouge = Quitter seul** : inchangé (25/10).
- **Rien ne bouge.** Pointeur et Écrire gardent leur place quand ils ne peuvent pas servir (place
  vide, ni vue, ni touchée, ni lue : un bouton qui ne peut pas aboutir n'est pas rendu, sa place
  reste, comme Annuler et Rétablir dans la palette). La sortie du focus n'entre plus dans la barre.
  Un panneau qui s'ouvre change un trait, pas une largeur.
- **La palette d'écriture se pose contre la page**, du côté d'Écrire, dans la largeur libre à côté
  d'elle (colonne de 272 : six outils, dix couleurs, trois épaisseurs, tout visible). **La page ne
  perd plus un point de hauteur** (test : même `top`, même `height` avant et après Écrire, à 1440).
- **Clavier** : M, V, R, B, F (existants) et **P, E, T, Échap** (nouveaux : Pointeur, Écrire,
  Tableau, reposer l'outil). Chaque tuile montre sa touche dans l'infobulle et la dit au lecteur
  d'écran (« Pointeur (touche P) »). V n'est montré que caméra allumée (il ne l'allume jamais).
  Une touche refusée n'est pas prise (champ de texte, feuille ouverte).
- **Groupes lus par leur nom** (`Semantics` conteneur : « Ma voix et mon image », « Ma classe »,
  « Sur la page », « Le support », « Sortir »). Les noms ne sont pas peints (question 2).

### Avant / après, en clics (enseignant, 1440, Coran présenté)

| Geste courant | Avant | Après | Note |
| :--- | :---: | :---: | :--- |
| Ouvrir le Coran et le montrer | 2 (3 sous 1200) | 2 (3 sous 1200) | panneau Bibliothèque, hors zone, inchangé |
| Changer de page | 1 | 1 | flèche contre la page (hors zone) ; le doublon dans « Plus » part |
| Pointer un mot | 1 + 1 | 1 + 1, ou P + 1 | Pointeur n'apparaît plus là où il ne peut rien |
| Écrire sur la page | 1 + la page saute | 1, ou E ; la page ne bouge pas | palette contre la page |
| Effacer un trait / tout | 2 / 2 | 2 / 2 | Gomme, Tout effacer en première rangée de la palette |
| Changer de couleur | 2 | 2 | inchangé |
| Lâcher l'outil (revenir à la lecture) | 1 (deviner qu'il faut re-cliquer) | 1, ou Échap, et l'infobulle le dit | |
| Ouvrir le tableau pour la classe | 1, état lu à l'envers | 1, ou T, état juste | plus de violet |
| Faire réciter un élève | 2 | 2 | panneau des élèves, hors zone |
| Couper son micro | 1 (M) | 1 (M) | inchangé, au coin de la barre (Fitts) |
| Voir ses élèves | 0 (panneau ouvert) / 1 | 0 / 1 | |
| Zoomer, focus, ranger | 1 (en haut) ; doublons dans « Plus » | 1 (en haut) | un seul endroit |
| Atteindre une chose « derrière Plus » | 2 | aucun | il n'y a plus rien derrière |

## 3. Règles et sources (DESIGN-GOV §4 : règle, source, date, conclusion)

| Règle | Source | Date | Conclusion dans ce lot |
| :--- | :--- | :--- | :--- |
| Micro et caméra au bord, toujours au même endroit ; un clic pour couper | Zoom, commandes de réunion (barre du bas, micro au coin) | consulté de mémoire, 11/11/2026 | Micro et Caméra au coin de début ; le public le moins technique connaît Zoom |
| Les panneaux (personnes, discussion) se signalent par un état « ouvert » distinct de « coupé » | Microsoft Teams, barre de réunion (bouton de panneau actif souligné) | idem | ton `ouvert` = trait sous l'icône, jamais l'aplat de l'outil |
| Raccrocher seul en rouge, à l'extrémité | Google Meet (barre d'appel) | idem | Quitter reste le seul rouge, au bout (inchangé) |
| Peu d'outils, gros, nommés, le reste sur le support | Classroomscreen ; Miro (barre d'outils réduite) | idem | 9 tuiles au lieu de 10 dont un « Plus » de 9 doublons |
| Une barre d'outils porte les actions fréquentes ; pas de surcharge ; l'état d'une bascule se voit | Apple HIG, Toolbars | idem | « Plus » retiré ; outil tenu visible |
| Barre d'outils flottante près du contenu qu'elle modifie | Material 3, Toolbars (floating toolbar) | idem | palette d'écriture contre la page, pas sous la page |
| Visibilité de l'état du système | Nielsen, heuristique 1 | 1994, rév. 2020 | Tableau : état juste ; outil tenu : trois signaux |
| Reconnaître plutôt que se souvenir | Nielsen, heuristique 6 | idem | plus rien caché derrière « Plus » ; touches montrées dans l'infobulle |
| Cohérence | Nielsen, heuristique 4 | idem | une seule palette d'écriture, une seule entrée par geste |
| Le temps de choix croît avec le nombre d'options | Loi de Hick (Hick 1952, Hyman 1953) | | groupes de 1 à 2 tuiles, nommés |
| Cibles grandes et aux bords | Loi de Fitts (1954) | | cibles de 48 gardées ; micro au coin, Quitter à l'autre coin |
| Pas d'information par la couleur seule | WCAG 2.2, 1.4.1 | 2023 | trois signaux pour tenu et ouvert |
| Tout au clavier | WCAG 2.2, 2.1.1 | 2023 | P, E, T, Échap ajoutés, montrés |
| Cible de 24 au moins (ici 48) | WCAG 2.2, 2.5.8 | 2023 | toutes les tuiles ≥ 48 (testé) |
| Proximité : ce qui va ensemble se touche | Gestalt | | filets entre groupes, écart de 8 dans un groupe |

## 4. Écarts datés aux compositions existantes (11/11/2026)

1. **Barre du 26/10 (deux groupes séparés d'un filet, « Plus » dans la barre)** : remplacée sur
   ordinateur par cinq groupes nommés et sans « Plus » (demande du directeur du 11/11).
2. **Tableau du 25/10 (décision du pilote : fermé = violet de marque)** : sur ordinateur, le
   tableau n'est plus une bascule « coupée » ; fermé au repos, ouvert avec le trait. Le téléphone
   et la pilule ronde gardent la règle du 25/10.
3. **Tuile « panneau ouvert ou outil retenu = aplat lilas » (26/10)** : l'aplat lilas reste à
   l'outil tenu ; un panneau ouvert prend le trait (`TonTuileSalle.ouvert`).
4. **Plan §3 du 26/10 (la palette au-dessus des commandes)** : la palette se pose contre la page,
   en colonne (règle du directeur du 11/11 : rien ne réduit la page du Coran).
5. **Sortie du focus dans la barre (TB-2)** : retirée de la barre de l'ordinateur ; elle reste
   contre le titre du support (visible en focus aussi) et la touche F.
6. **« Une tuile du côté du panneau qu'elle ouvre » (directeur, 26/10)** : **gardée** (Élèves au
   début, Bibliothèque à la fin).

## 5. Questions au directeur (une ligne chacune, avec ma recommandation)

1. Micro et Caméra au coin de début, comme Zoom (fait), ou au centre comme Meet ? **Recommandé :
   au coin, comme maintenant.**
2. Peindre le nom des groupes au-dessus de la barre (« Ma classe », « Sur la page »…) ? Cela
   prend 16 points à la page. **Recommandé : non, filets seulement ; le nom est lu par le lecteur
   d'écran.**
3. Garder les six couleurs franches et les trois épaisseurs dans la palette, ou seulement les
   quatre couleurs de l'intention ? **Recommandé : n'en garder que quatre et une épaisseur, après
   une semaine d'usage réel.** (Rien de retiré dans ce lot.)
4. « Tout effacer » sans confirmation (Annuler le défait) : garder ? **Recommandé : oui.**
5. La croix « Ranger dans la bibliothèque » en haut ressemble à « fermer la fenêtre » : la
   remplacer par une icône de rangement avec le mot ? **Recommandé : oui, lot du haut, pas ici.**
6. Afficher les touches dans les infobulles même quand les raccourcis sont coupés dans les
   préférences ? **Recommandé : non (fait ainsi).**

## 6. Tests et preuves

- `test/features/salle_ordinateur_test.dart`, groupe `BARRE-ORDINATEUR` : cinq groupes et leur
  ordre, aucun « Plus », un seul rouge, cibles de 48, une rangée ; un seul outil tenu (trois
  signaux), le tableau ouvert par le trait, **aucune tuile ne bouge** (Écrire, tableau, panneau),
  **la page garde sa hauteur** ; clavier P, E, T, Échap et touche dans l'infobulle ; 1280, 1440,
  1920 × clair, sombre × français, arabe × texte ×1 et ×1,3 (aucun mot coupé dans la barre,
  palette du côté du début de lecture, aucun chevauchement, un seul bouton plein) ; vraies polices
  à 1280 en texte ×1 et ×1,3 : aucun mot coupé dans la palette, barre sur une rangée.
- Captures : `docs/current/captures/E2E/barre-ordinateur/` (voir le bilan du lot).
