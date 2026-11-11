# UX_REVIEW_CORAN-GRAND : le Coran grand chez l'enseignant sur ordinateur

Demande du directeur (11/11/2026) : « Sur PC, il faut que le Coran soit grand. » Décision du
directeur le même jour, sur la recommandation du pilote : **« la barre sur un côté d'abord »**
(plutôt que la double page). Journal : D-021 (`docs/current/salle/JOURNAL-DECISIONS.md`).

## Ce qui n'est pas prouvé (à lire d'abord)

- **Rien n'est vu en production ni sur le banc.** Tout est `présent dans le code` et `testé
  localement` (tests de widget, vraies polices pour les mesures). Les captures « avant » et
  « après » sont des **captures de test** (vrai `SallePage`, faux serveur de visio, fond et
  composants réels de `/salle`), pas des captures de la vraie application.
- **Panneaux ouverts à 1280 x 720, le gain est faible (+ 7 %)** : la largeur devient la limite
  (détail au §3). Rien ne se ferme à la place de l'enseignant ; c'est une question au directeur
  (§6, question 1).
- **À 720 points de haut, les noms des tuiles disparaissent dès le texte x1** (pas seulement à
  x1,3) : neuf tuiles nommées demandent environ 730 points ; il reste les icônes, leur infobulle
  et ce que lit le lecteur d'écran. À 900 points, les noms sont là.
- **L'île dépliée** (phrase d'état, mention à l'entrée pendant 10 s) grandit vers le bas dans la
  colonne : la colonne perd alors ses noms le temps qu'elle se replie (sa largeur et la page ne
  bougent pas). Si la phrase est plus haute que la place libre (écran bas, texte agrandi), elle est
  coupée en bas ; le lecteur d'écran la lit en entier. Non vu sur un vrai écran.
- **Quand l'enseignant écrit, la palette prend la place du panneau des Élèves** (le panneau est
  caché, gardé en vie, et revient quand il repose l'outil). C'est le prix de « rien ne réduit la
  page » quand la largeur est comptée. Question au directeur (§6, question 3).
- Les références (Fitts, Material 3, Apple HIG, Zoom, Teams) sont citées de mémoire, non relues en
  ligne le 11/11.

## 1. Constat (avant, base `18ed49ff6`)

Capture réelle : `docs/current/captures/E2E/salle-banc/avant-enseignant-vague2/05_enseignant_page-partagee.png`.
À 1440 x 900, la page de quinze lignes est **bornée par la hauteur** : la rangée du haut (Classe,
titre du support et ses outils, île) et la barre sombre du bas (cinq groupes) lui prenaient
environ 190 points. Le texte faisait 371 x 614, l'élève 479 x 794 sur le même écran.

## 2. La composition, codée

```
| Classe        | Panneau      |  [zoom]                       [ranger] | Bibliothèque |
| Coran · p. 42 | des Élèves   |                               [focus]  |              |
| (île)         | (vidéo en    |  (<)        PAGE           (>)         |              |
| ┌──────────┐  |  tête)       |      toute la hauteur                  |              |
| │ Micro    │  |              |                                        |              |
| │ Caméra   │  |              |                                        |              |
| │──────────│  |              |                                        |              |
| │ Élèves   │  |              |                                        |              |
| │──────────│  |              |                                        |              |
| │ Pointeur │  |              |                                        |              |
| │ Écrire   │  |              |                                        |              |
| │          │  |              |                                        |              |
| │ Biblioth.│  |              |                                        |              |
| │ Tableau  │  |              |                                        |              |
| │──────────│  |              |                                        |              |
| │ Réduire  │  |              |                                        |              |
| │ Quitter  │  |              |                                        |              |
| └──────────┘  |              |                                        |              |
```

- **La barre des commandes est une colonne sur le bord de début** (gauche en français, droite en
  arabe ; tout se miroite). Mêmes cinq groupes, dans le même ordre de haut en bas, mêmes tuiles
  `TuileCommandeSalle` (par `BoutonAppel(nom:)`), mêmes états, mêmes raccourcis (M, V, R, P, E, B,
  T, F, Échap), mêmes infobulles, mêmes noms lus des groupes. « Quitter » reste le seul rouge, tout
  en bas. Les tuiles prennent toute la largeur de la colonne. Groupes de début en haut, groupes de
  fin en bas, l'espace libre entre les deux.
- **Plus de rangée du haut** : en tête de la colonne, sur le fond de la salle, le nom de la Classe
  (deux lignes au plus), le titre du support (« Coran · Page 42 »), puis l'île (`PiluleEtatSalle`,
  non modifiée), au coin de début, hors de la page. Le nom de l'enseignant n'est plus affiché
  (l'enseignant connaît le sien ; il restait dans la rangée du haut seulement).
- **Les outils du support se posent contre la page**, dans les marges où vivent déjà ses grandes
  flèches, au-dessus d'elles : le zoom en haut de la marge de début, « Ranger » et le focus en haut
  de la marge de fin. Ils ne prennent rien à la page. Pour le tableau et la scène (pas de flèches),
  ranger et focus vivent dans une marge de fin de 64.
- **Les flèches de page restent à côté de la page, à mi-hauteur.** Quand la largeur manque, la page
  se compose plus basse, centrée, pour que ses flèches tiennent toujours : elle n'est jamais coupée.
- **La colonne ne défile jamais.** Repli, dans cet ordre, quand la hauteur manque : le titre du
  support part, puis le nom de la Classe, puis les noms des tuiles (icônes seules, infobulle et
  lecteur d'écran gardent le nom ; la colonne garde au moins la largeur de l'île repliée).
- **Focus (F)** : la page seule à pleine hauteur, les deux panneaux retirés. Il reste : la colonne
  en icônes (micro et Quitter toujours à un clic : on doit pouvoir couper son micro en focus),
  l'île (temps restant, état du réseau : ce qui empêche d'entendre ne se cache pas), le zoom et la
  sortie du focus contre la page. La Classe et le titre partent.
- **La palette d'écriture** (« Écrire » en main) se pose contre la page, du côté de début, sans la
  réduire : elle prend la place du panneau des Élèves quand il est ouvert ; panneau fermé, elle a
  sa propre place comme avant (et peut alors réduire la page si l'écran est étroit : voir §3).
- **Inchangés** : le téléphone et la tablette sous 840 points, l'élève (`GeometrieEleve`), le
  panneau des Élèves, l'étagère, l'île, le Coran lui-même.

## 3. Mesures (test, vraies polices)

Test : `CORAN-GRAND mesure` dans `test/features/salle_ordinateur_test.dart` (même test avant et
après ; il ne lit que la page et les tuiles Élèves et Bibliothèque). « Texte » : largeur d'une
ligne justifiée x hauteur des quinze lignes. Panneaux fermés : Élèves et Bibliothèque fermés.

| Écran | Panneaux | Avant | Après | Gain en hauteur |
| :--- | :--- | :--- | :--- | :--- |
| 1440 x 900 | ouverts | 371 x 614 | **448 x 742** | + 21 % |
| 1440 x 900 | fermés | 371 x 614 | **462 x 765** | + 25 % |
| 1280 x 720 | ouverts | 275 x 455 | **295 x 488** | + 7 % |
| 1280 x 720 | fermés | 275 x 455 | **366 x 607** | + 33 % |
| (élève, 1440 x 900, référence) | | 479 x 794 | 479 x 794 | inchangé |

La boîte de la page : 1440 x 900, panneaux fermés, 868 de haut (900 moins les marges de 16) ;
panneaux ouverts, 842. L'agent précédent estimait + 46 % : c'était sans compter les marges des
flèches (72 de chaque côté), la colonne (environ 120 à 150) et les deux panneaux (300 et 320).

**La largeur devient la limite, panneaux ouverts.** À 1280 x 720, il reste au centre
1280 − 32 − colonne − 316 − 336 ≈ 460 points ; moins les deux flèches (144), la page n'a que 316
de large, donc 565 de haut au lieu des 688 possibles. À 1440 x 900, la largeur la borne à peine
(842 au lieu de 868). Rien ne se ferme à la place de l'enseignant (consigne du directeur) ; la
Bibliothèque s'ouvre d'office à 1200 points et plus (règle existante, non modifiée).

## 4. Règles et sources (DESIGN-GOV §4)

| Règle | Source | Date | Conclusion |
| :--- | :--- | :--- | :--- |
| Le temps pour atteindre une cible baisse avec sa taille et sa proximité ; un bord d'écran arrête le pointeur | Loi de Fitts (1954) | | Colonne sur un bord ; tuiles à la largeur de la colonne (cibles plus larges que 48). Limite : 16 de marge entre le bord et la colonne, la cible n'est pas « infinie » (question 2) |
| Rail de navigation vertical au bord de début, miroité en écriture de droite à gauche | Material 3, *Navigation rail* ; *Bidirectionality* | consulté de mémoire, 11/11/2026 | Bord de début (gauche en français, droite en arabe), tout miroité |
| Le lecteur commence en haut au début de la ligne | Sens de lecture (F-pattern, Nielsen Norman Group) | | La Classe, le support, puis l'île en tête de la colonne ; Micro au début, Quitter à la fin |
| Commandes d'appel toujours au même endroit, micro au premier rang, raccrocher seul en rouge à l'extrémité | Zoom, Google Meet, Microsoft Teams (barres de réunion) | de mémoire | Micro en haut, Quitter en bas, seul rouge ; ordre des groupes inchangé |
| Une barre d'outils porte les actions fréquentes ; un outil près de son objet | Apple HIG, *Toolbars* ; Material 3, *Toolbars* | de mémoire | Zoom, ranger, focus contre la page, au-dessus des flèches |
| Aucun contenu ne défile dans un cadre de hauteur fixe | `DECISION-DEFILEMENT-2026-11-01.md` | 01/11/2026 | La colonne ne défile jamais ; repli par étapes (testé : aucun `Scrollable` dans la colonne) |
| Pas d'information par la couleur seule ; cible de 24 au moins | WCAG 2.2, 1.4.1, 2.5.8 | 2023 | Mêmes trois signaux qu'avant ; tuiles de 48 au moins, testé |
| Contenu visible au zoom du texte sans perte | WCAG 2.2, 1.4.4, 1.4.10 | 2023 | Texte x1,3 : noms en infobulle, rien de coupé ni hors de l'écran (testé) |
| Rien ne recouvre ni ne réduit la page du Coran | Directeur, 11/11/2026 | 11/11/2026 | Vérifié par `verifierSansChevauchement` (§5) |

## 5. Vérification

`test/features/salle_ordinateur_test.dart` :

- groupe `SALLE-ORDINATEUR B` (64 cas) : 1280 x 720, 1280 x 800, 1440 x 900, 1920 x 1080 ×
  panneaux ouverts et fermés × clair et sombre × français et arabe × texte x1 et x1,3 : la page a
  toute la hauteur que la largeur permet (fermés : la hauteur de l'écran moins 32), centrée ; ses
  flèches présentes ; zoom et outils dans ses marges, au-dessus de la flèche ;
  `verifierSansChevauchement` entre la page, la tête de la colonne, la colonne, le zoom, les
  outils et les panneaux ; colonne collée au bord de début, dans l'écran, sans `Scrollable` ; un
  seul bouton plein ;
- `B : repli` : 1440 x 900 neuf noms, Classe et titre ; 1280 x 720 texte x1,3 : aucun nom, neuf
  tuiles, chacune avec son infobulle ; 860 x 720 texte x2 : rien ne déborde ;
- `C` : à 1440 x 900, boîte de plus de 840 panneaux ouverts, 868 fermés ; focus à 1280 x 720 :
  panneaux, Classe et titre retirés, colonne en icônes, île et focus présents, page de 688 ;
- `BARRE-ORDINATEUR` : les cinq groupes et leur ordre (inchangés), une seule colonne, même largeur
  pour toutes les tuiles, ordre de haut en bas, un seul rouge, cibles de 48, un seul outil tenu,
  rien ne bouge quand on écrit (la page garde sa largeur et sa hauteur, la palette dans la place des
  Élèves), clavier P, E, T, Échap, palette du côté de début sans chevauchement ;
- tests voisins adaptés (hors zone, changement minimal) : `test/features/salle_test.dart` (page
  centrée et non plus collée en bas ; tableau à côté de la marge des outils ; palette qui ne
  recouvre pas la colonne) et `test/features/salle_200_test.dart` (les noms sont tous là ou tous
  partis).

Captures : `docs/current/captures/E2E/coran-grand/` (captures de test, île au repos) :
`avant_*` et `apres_*` pour `1440x900_clair`, `1440x900_sombre`, `1440x900_arabe`,
`1440x900_focus`, `1280x720_sombre`, `1280x720_arabe`, `1280x720_focus`, et
`*_1440x900_panneaux-ouverts`, `*_1440x900_panneaux-fermes`, `*_1280x720_panneaux-ouverts`,
`*_1280x720_panneaux-fermes` (prises par le test de mesure, île à l'entrée).

## 6. Écarts datés et questions au directeur

**Écarts datés (11/11/2026)** à la composition du 26/10 (`lib/CLAUDE.md`, « Salle sur ordinateur,
composition du 26/10/2026 ») et au lot BARRE-ORDINATEUR (D-015) :

1. « La barre des commandes est une barre sombre sur toute la largeur » : devient une **colonne
   sombre sur le bord de début** (décision du directeur du 11/11).
2. « Une tuile se place du côté du panneau qu'elle ouvre » (directeur, 26/10 ; gardée par D-015) :
   toutes les tuiles sont maintenant du même côté ; Élèves reste près de son panneau, Bibliothèque
   en est loin.
3. « Le focus retire le haut et les deux panneaux ; la barre du bas reste » : le focus retire les
   deux panneaux, la Classe, le titre et les noms de la colonne ; la colonne reste en icônes.
4. Rangée du haut du lot SALLE-ORDINATEUR (« le support et ses outils au centre du haut ») : le
   titre va en tête de la colonne, les outils dans les marges de la page.

**Questions** (une ligne chacune, avec ma recommandation) :

1. Panneaux ouverts sur un écran de 1280, le Coran ne gagne que 7 % : la Bibliothèque doit-elle
   rester ouverte d'office dès 1200 points ? **Recommandé : l'ouvrir d'office seulement à 1600 et
   plus** (en dessous, B ou la tuile l'ouvre ; rien ne se ferme seul en cours de séance).
2. Coller la colonne au bord de l'écran (sans la marge de 16) pour que le pointeur lancé au bord
   tombe sur une tuile (Fitts) ? **Recommandé : oui, dans un lot suivant**, après un essai réel.
3. Quand l'enseignant écrit, la palette cache le panneau des Élèves (sinon la page rétrécit) :
   acceptable ? **Recommandé : oui** ; le panneau revient dès qu'il repose le stylo (Échap).
4. À 720 points de haut, les noms des tuiles partent même en texte normal : réduire l'icône des
   tuiles de la colonne (32 vers 24) pour les garder ? **Recommandé : oui, à essayer** (environ
   70 points gagnés), après avis sur un vrai écran de 1280 x 720.
5. La double page (étude `UX_REVIEW_CORAN-ELEVE.md` §2) : elle montre plus de texte sans le
   grandir. **Recommandé : non pour l'instant.**
