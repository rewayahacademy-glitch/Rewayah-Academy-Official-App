# La salle : un seul modèle pour tous les modes d'affichage (11/11/2026)

Demande du directeur (11/11/2026) : « Les vidéos sont grandes, non ? Il faut juste des carrés comme
sur Zoom, et pense à les rendre esthétiques (leur layout) pour que ce soit plaisant de voir la
grille, ajoute aussi des animations. N'oublie pas de penser avec stratégie (sans bricolage) ce qui
se passe entre les modes d'affichage (entre l'affichage support/Coran, et tableau, vignettes
vidéos, etc.) : il faut que tout soit bien coordonné et ne pas agir comme des entités différentes.
Pense aussi aux transitions si nécessaire. »

Ce document est **la règle** ; le code s'y plie. Journal : D-028.

## 1. Ce qui ne va pas aujourd'hui (vu dans la vraie application, banc du 11/11)

- La grille des vidéos **étire** chaque cadre pour remplir l'écran : hauts et étroits au téléphone
  (171 x 330), très larges sur ordinateur (616 x 344), la dernière rangée collée d'un côté
  (`salle-banc/grille-11-11/03_…`, `05_…`, `06_…`).
- Sa propre image flotte par-dessus la grille et par-dessus la barre ; la barre du bas et « Ouvrir
  le Coran » passent sur des visages.
- Quand un document s'ouvre, **les visages des élèves disparaissent** chez l'enseignant sur
  ordinateur (il ne reste que des initiales dans le panneau) : or c'est en regardant la bouche
  qu'on corrige une récitation.
- Chaque mode a été construit à part : la grille (`_Galerie`), la page (`ZoneSupport`), le tableau,
  la vignette de l'enseignant (`VignetteVideo`, `VignetteAimantee`), la capsule du téléphone, les
  cartes du panneau. Chacun a sa forme de cadre, ses coins, son étiquette, sa façon d'apparaître.
  Trois drapeaux se croisent (`_scenePremierPlan`, tableau ouvert, page présentée).

## 2. Le modèle : une scène, des visages, jamais deux fois la même personne

**La scène** est le centre de l'écran. Elle montre **une seule chose** à la fois :

| Mode | Ce que montre la scène | Qui le décide |
| :--- | :--- | :--- |
| **Classe** | les visages, en grille | personne n'a rien ouvert, ou « Voir la classe » |
| **Document** | une page (Coran, livret) | l'enseignant ouvre un document de la Bibliothèque |
| **Tableau** | le tableau blanc | l'enseignant ouvre le Tableau |

**Les visages** existent toujours, dans **un seul** des deux endroits :

- en **grille**, dans la scène, en mode Classe ;
- en **ruban**, à côté de la scène, en mode Document ou Tableau : une suite de petits cadres, les
  mêmes cadres, plus petits.

Règles qui en découlent (elles ne se discutent plus écran par écran) :

1. **Une personne, un cadre.** Jamais deux images de la même personne à l'écran.
2. **Un seul cadre** (`CadreVisage`, composant du core) pour la grille, le ruban, la vignette, la
   capsule et les cartes du panneau : même forme, mêmes coins, même étiquette du nom, même signe du
   micro, même anneau de parole, même repli quand la caméra est éteinte (la photo ou l'initiale).
   Seule la taille change.
3. **Le cadre ne s'étire jamais.** Il a une forme fixe (voir §3). L'image se recadre au centre.
4. **Rien ne passe sur un visage ni sur la page** : ni barre, ni bouton, ni sa propre image. Sa
   propre image est un cadre comme les autres (le dernier), jamais un objet flottant.
5. **Celui qui parle se voit** : anneau autour de son cadre ; en ruban, l'élève qui récite passe en
   premier et son cadre est le plus grand du ruban.
6. **Changer de mode ne fait rien disparaître brutalement** : les visages glissent de la grille au
   ruban (et retour) ; la page ou le tableau arrive en fondu. Voir §5.
7. **Un seul état** dans le code : `ModeScene { classe, document, tableau }`, calculé à un seul
   endroit ; plus de drapeaux croisés.
8. **Rien ne s'ouvre seul, rien n'est envoyé de plus** : ce modèle ne change que l'affichage. Aucun
   droit, aucun micro, aucune caméra ne change ; l'élève ne publie rien de plus.

## 3. La grille (mode Classe)

- **Forme du cadre** : entre le carré (1:1) et 4:3. Au téléphone en portrait : carré. Sur un écran
  large : 4:3. Jamais plus haut que large, jamais plus large que 4:3.
- **Taille** : pour N visages dans la place disponible, on essaie chaque nombre de colonnes et on
  garde celui qui donne **les plus grands cadres** (le calcul de Zoom et de Meet). Un cadre ne
  dépasse pas une taille maximale : à deux ou trois dans une grande fenêtre, les cadres restent
  des cadres, la grille ne remplit pas l'écran pour le remplir.
- **Placement** : la grille est **centrée** dans la scène, en largeur et en hauteur ; une dernière
  rangée incomplète est centrée elle aussi. Écart constant de 16 entre les cadres.
- **Ordre** : l'enseignant d'abord (chez l'élève), puis les élèves dans un ordre qui ne bouge pas ;
  soi-même en dernier. L'ordre ne change pas quand quelqu'un parle (l'anneau suffit).
- **Seul avec une personne** (cours à deux) : un seul grand cadre, à sa forme, centré.
- **Seul dans la salle** : la scène d'attente (le symbole et ses ondes). Si sa caméra est allumée,
  son propre cadre est posé sous la scène d'attente, centré, borné (240 de large au plus), dans la
  mise en page : on vérifie son image avant l'arrivée des autres, et rien ne flotte (décidé par le
  pilote le 11/11 après le lot SCENE-CLASSE, qui l'avait retiré).
- **Au-delà de la place** (jamais atteint à 7 personnes) : la grille défile par pages entières,
  jamais des cadres minuscules.
- **Les commandes** : la barre a sa place réservée sous la grille (téléphone) ou sur le côté
  (ordinateur) ; la grille se calcule dans ce qui reste. « Ouvrir le Coran » n'est plus posé sur un
  visage : il vit avec les commandes.

## 4. Le ruban (modes Document et Tableau)

| Appareil | Où est le ruban | Détail |
| :--- | :--- | :--- |
| Ordinateur, enseignant | le panneau des Élèves | chaque carte d'élève porte son cadre vivant (à la place de l'initiale) ; l'enseignant en tête ; panneau fermé : aucun visage, c'est son choix |
| Ordinateur ou tablette large, élève | la bande de côté déjà réservée | l'enseignant, puis l'élève qui récite s'il y en a un |
| Téléphone, élève | la vignette qu'on déplace et qu'on range (D-023) | un seul cadre : l'enseignant, toujours (c'est lui qui corrige ; le camarade qui récite s'entend) |
| Téléphone, enseignant | la feuille « Élèves » et la capsule du haut | la capsule montre l'élève qui récite s'il y en a un, sinon lui-même |

- La page garde **toute** sa taille : le ruban ne la réduit jamais (règle du directeur).
- « Voir la classe » (l'œil d'aujourd'hui) repasse en mode Classe **sans fermer** le document : il
  attend, « Revenir à la page » le remet. C'est un changement de mode, pas un quatrième mode.

## 5. Les transitions entre modes

Jetons et règles : ceux du lot TRANSITIONS-SALLE (D-025, `lib/core/theme/app_mouvement.dart`),
aucun nouveau langage.

| Passage | Ce qui bouge |
| :--- | :--- |
| Classe → Document ou Tableau | les cadres rétrécissent et glissent vers le ruban (ressort sans rebond, 240 à 280 ms) ; la page arrive en fondu dessous ; rien ne saute |
| Document ou Tableau → Classe | l'inverse, plus vite (les deux tiers) |
| Document ↔ Tableau | fondu enchaîné court dans la scène ; le ruban ne bouge pas |
| Un visage arrive ou part | il grandit ou rétrécit en fondu (200 ms) ; les autres se replacent sur le même ressort |
| Quelqu'un parle | l'anneau apparaît en fondu ; aucun cadre ne change de place |
| La caméra s'allume ou s'éteint | fondu entre l'image et la photo, dans le même cadre |

« Réduire les animations » : fondu seul. Aucune animation sans fin. Rien ne se rejoue à une
reconnexion.

## 5 bis. Où en est le code (11/11/2026, soir)

- **Fait (lot SCENE-CLASSE, D-028)** : `CadreVisage` et `GrilleVisages` (core), la scène en mode
  Classe chez tous (`lib/features/salle/scene_classe.dart`), `ModeScene` et son calcul
  (`media_salle.dart`). Vu dans la vraie application sur le banc à 3 et 6 élèves
  (`captures/E2E/salle-banc/scene-classe-3/`, `scene-classe-6/`). Bornes choisies : cadre de 480 de
  large au plus, 96 au moins ; en dessous, la grille passe en pages (seul cas : 7 personnes sur un
  téléphone de 320 de large, deux pages).
- **Fait sur ordinateur (lot RUBAN-ORDINATEUR, D-030)** : le ruban de l'enseignant (première ligne du
  §4) : chaque carte d'élève dans la salle porte son cadre vivant en mode Document ou Tableau (96 x 72,
  le récitant en premier et à la largeur de la carte), l'initiale ou la photo en mode Classe ; le cadre
  de l'enseignant en tête du panneau (4/3, jamais étiré). Les passages du §5 en version coordonnée (la
  grille rétrécit et s'efface vers le panneau pendant que la page arrive en fondu et que les cadres des
  cartes grandissent ; 240 ms, retour en 160 ms ; Document et Tableau : fondu court ;
  `PassageScene`) : **pas** le vol des cadres de la grille vers leur carte. « Revenir à la page » sous
  la grille, avec « Ouvrir le Coran ». Plus aucun drapeau croisé dans l'affichage (`ZoneSupport` lit
  `modeSceneDe`). Vu dans la vraie application : `captures/E2E/salle-banc/ruban-ordinateur-6/` et
  `ruban-ordinateur-3/` (11 : la page partagée et le ruban). Coût mesuré : 415 à 546 kbit/s de vidéo
  reçue de plus, à la plus petite couche, voix intacte.
- **Reste** : le téléphone et la tablette (vignette, capsule, bande de côté de l'élève : autre lot du
  11/11) ; son propre cadre quand on est seul ; le vrai vol des cadres si le directeur le demande ;
  panneau fermé en mode Document, aucun moyen de « Voir la classe » sur ordinateur.

- **Fait au téléphone et chez l'élève (lot RUBAN-TELEPHONE, D-031, tests et captures de test, pas
  encore vu sur le banc)** : la vignette de l'enseignant, la capsule de l'enseignant au téléphone et la
  bande de côté de l'élève passent par `CadreVisage`, servi par la portée (le même cadre que la grille) ;
  élève au téléphone : un seul cadre, l'enseignant ; élève sur écran large : l'enseignant (bande de fin)
  puis le récitant (milieu de la bande de début), même taille ; enseignant au téléphone : la capsule
  (Réduire la salle · cadre · Voir la classe) montre le récitant en Document ou Tableau ; seul dans la
  salle, son propre cadre sous l'attente (240 au plus) ; les passages du §5 en version coordonnée
  (`PassageVisages`), pas un vol ; les phrases d'état de l'élève en haut. Restent : la bande se masque
  avec les commandes à 3 s sur grand écran (à trancher) ; la feuille « Élèves » du téléphone sans image
  vivante (autre lot).

## 6. Ce que ce modèle ne fait pas (à décider ensuite)

- Épingler un élève en grand à côté de la page (utile pour corriger une bouche) : proposé, pas
  dans ce lot.
- Le tuteur et le contrôleur suivent le même modèle, sans ruban à eux (ils regardent).
- La forme exacte du cadre (carré ou 4:3 sur écran large) est une proposition : au directeur de
  dire s'il préfère le carré partout.
