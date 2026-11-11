# UX_REVIEW RUBAN-ORDINATEUR (11/11/2026)

Lot : la seconde moitié du modèle `docs/current/salle/MODES-AFFICHAGE.md` sur ordinateur (§4, première
ligne ; §5) : le ruban de l'enseignant dans le panneau des Élèves, les passages d'un mode à l'autre,
l'état unique, l'île dans la colonne, la tête commune des panneaux. Journal : D-030.

Demande du directeur (11/11/2026) : « N'oublie pas de penser avec stratégie (sans bricolage) ce qui se
passe entre les modes d'affichage (entre l'affichage support/Coran, et tableau, vignettes vidéos, etc.) :
il faut que tout soit bien coordonné et ne pas agir comme des entités différentes. Pense aussi aux
transitions si nécessaire. »

## La règle appliquée

| Règle | Source | Date de lecture | Conclusion | Modification |
| :--- | :--- | :--- | :--- | :--- |
| Pendant un partage, les visages restent à côté du contenu partagé, en petit, sans le réduire | Zoom, partage d'écran : « vue côte à côte » (support.zoom.com, « Side-by-side mode ») et bande de vignettes ; Google Meet, présentation : les tuiles passent dans une colonne à côté de la présentation (support.google.com/meet, « Change your layout ») | 11/11/2026 | L'enseignant corrige en regardant la bouche : il doit voir les élèves pendant que la page est montrée. Les deux outils gardent le contenu à sa taille et rangent les visages dans une bande | En mode Document ou Tableau, chaque carte du panneau des Élèves porte le cadre vivant de l'élève ; la page ne perd pas un point (mesuré par les tests CORAN-GRAND, toujours verts) |
| Teams « Together mode » | learn.microsoft.com, « Together mode in Teams » | 11/11/2026 | Écarté : il découpe les visages dans un décor commun ; il remplace la page au lieu de l'accompagner, et coûte du calcul à chaque image | Rien de tel |
| Une personne, un cadre | MODES-AFFICHAGE §2, règle 1 | 11/11/2026 | En mode Classe, les élèves sont déjà dans la grille : une seconde image dans le panneau serait la même personne deux fois | En mode Classe, les cartes gardent la photo ou l'initiale ; l'enseignant n'est jamais dans la grille (son seul cadre est en tête du panneau). Test : trois personnes, trois images, dans les deux modes et au retour |
| Celui qui récite se voit, en grand, en premier | MODES-AFFICHAGE §2, règle 5 ; Meet et Zoom mettent en tête la personne active | 11/11/2026 | La bouche à corriger est celle de l'élève qui récite : c'est elle qui mérite la place | En ruban, sa carte passe en premier et son cadre prend toute la largeur de la carte (252 x 189 en 4/3) ; les autres : 96 x 72 |
| Taille des autres cadres : 96 x 72 (4/3) dans une liste de cartes, plutôt que deux colonnes de cadres | Fitts (les gestes « Faire réciter », « Appeler » à un clic, dans la carte dépliée, sans menu de plus) ; Gestalt (le nom à côté de son visage) ; MODES-AFFICHAGE §3 (jamais plus large que 4/3) | 11/11/2026 | La liste garde tout ce que la carte sait faire (nom, état, réseau, dépliage sur place, autorisation d'écrire) sans changer un geste ; deux colonnes auraient caché les gestes derrière un toucher de plus. 96 de large : on voit qui est là et s'il regarde ; la place qui reste (environ 140) garde le nom et l'état lisibles | `largeurCadreRuban = 96`, `rapportCadreRuban = 4/3` |
| Le cadre de l'enseignant ne s'étire plus | MODES-AFFICHAGE §3 ; demande du directeur (« l'enseignant a plus besoin de voir les profils de ses élèves que le sien ») | 11/11/2026 | Avant, sa vidéo prenait la largeur du panneau et, sur un écran bas, devenait plus large que 4/3 (2,3:1 à 1280 x 720) : visage coupé | 4/3, à la largeur du panneau au plus, jamais plus haut que le sixième de l'écran, centré (`tailleCadreEnseignant`) |
| Les passages : rien ne saute, le contenu ne change pas de taille, la sortie plus courte que l'entrée | Material 3, « Motion : transitions » (m3.material.io, container transform et fade through) ; jetons du dépôt (D-025) | 11/11/2026 | Classe vers Document : la grille rétrécit (vers 90 %) et glisse de 16 vers le panneau en s'effaçant, la page arrive en fondu, les cadres des cartes grandissent en fondu, tout en 240 ms ; retour en 160 ms ; Document et Tableau : fondu court sans superposition | `PassageScene` (`lib/core/mouvement/`), `_PassageCadre` (`panneau_eleves.dart`) |
| Interruptible, rien au montage | WCAG 2.2.2 (Pause, Stop, Hide : aucune animation sans fin, toutes sous 300 ms) | 11/11/2026 | Un retour pendant le passage reprend de la position courante : la grille n'est pas reconstruite (test : un seul montage). Arrivée et reconnexion : rien ne se joue | `PassageScene` garde la couche qui part et la fait revenir |
| « Réduire les animations » | WCAG 2.3.3 (Animation from Interactions) | 11/11/2026 | L'information reste, le mouvement part : un fondu seul, sans échelle ni glissement ; la carte prend sa hauteur d'un coup | `AppMouvement.mouvementReduit` partout ; test dédié |
| « Revenir à la page » ne touche plus un visage | `lib/CLAUDE.md` (aucun élément ne recouvre un contenu à lire) ; MODES-AFFICHAGE §3 | 11/11/2026 | Il était posé au coin haut de début de la scène, sur le premier cadre | Il vit au même endroit qu'« Ouvrir le Coran », sous la grille, centré (`ActionSousLaScene`) ; test : il ne recoupe aucun cadre |
| Même tête pour deux panneaux de même rang | Gestalt (similarité) ; Material 3, « Side sheets » (en-tête : titre au début, fermer à la fin) | 11/11/2026 | Les Élèves n'avaient ni titre en tête ni croix ; la Bibliothèque, une pastille et une croix | `TetePanneau` (core) pour les deux ; la Bibliothèque garde la couleur de la marque et l'ornement (journal D-016) ; les Élèves, la même pastille en surface neutre avec leur icône. Test : même hauteur, croix de même taille au bout |
| L'île ne déborde plus de la colonne | Vraie application (capture `salle-banc/scene-classe-6/02_…`) | 11/11/2026 | Deux erreurs : le temps était mesuré au mauvais style (`labelMedium` au lieu de `titleMedium`), et les signes n'étaient pas comptés. Élargir la colonne coûtait 66 points de hauteur à la page à 1440 x 900 (mesuré : 774 au lieu de plus de 840) | La colonne ne s'élargit pas : repliée, l'île est bornée à la largeur de la colonne et ses signes passent sous le chrono quand ils n'y tiennent pas (place de deux lignes réservée, rien ne bouge quand un signe arrive) ; dépliée, elle passe toujours par-dessus le panneau. Tests : tous les signes, texte x1, x1,3, x2 |

## Ce qui a été écarté

- **Le vrai vol des cadres de la grille vers leur carte** (positions lues par clés globales, une copie qui
  vole dans une couche au-dessus). Raisons : les cadres de la grille vivent dans `scene_classe.dart` et
  `grille_visages.dart` (l'autre agent y travaillait en même temps) ; la copie d'une image vivante monte un
  second rendu de la même piste vidéo pendant le vol ; et la grille et le panneau changent tous deux de
  forme dans la même image. Fait à la place : la version coordonnée (§5 du modèle, seconde option du
  brief), dans le même temps et le même sens. À reprendre si le directeur la demande après l'avoir vue.
- **Deux colonnes de grands cadres dans le panneau** : gestes cachés derrière un toucher de plus.
- **Un bouton « Voir la classe » de plus dans la marge de la page** : un seul endroit par chose ; le geste
  d'avant (toucher son propre cadre en tête du panneau) est gardé, et il dit maintenant ce qu'il fait
  (« Voir la classe », « Revenir à la page »).
- **Élargir la colonne pour l'île** : la page du Coran perdait de la hauteur.

## Limites connues

- Panneau des Élèves fermé en mode Document : aucun visage, et plus de moyen de « Voir la classe » sur
  ordinateur (inchangé ; c'est le choix de l'enseignant, à confirmer par le directeur).
- Dans les dernières minutes et après l'heure, le chrono prend une capsule teintée (24 de plus) : l'île
  repliée peut alors dépasser la colonne de quelques points, dans l'écart de 16 et la marge du panneau.
- Le récitant qui change fait sauter l'ordre des cartes (pas d'animation de réordonnancement).
- L'île **dépliée** (à l'arrivée, six secondes, ou quand l'état change) passe par-dessus le panneau des
  Élèves comme avant ; elle y couvre maintenant le titre « Élèves 6/6 » au lieu du haut de la vidéo
  (capture de test `ruban-ordinateur/enseignant_1440_document_arabe.png`). Passager, mais visible.
- Le récitant en grand et l'anneau de parole ne sont prouvés que par les tests : aucun élève ne récite
  dans le script du banc.
