# UX_REVIEW RUBAN-TELEPHONE (11/11/2026)

Lot : la seconde moitié du modèle des modes d'affichage (`docs/current/salle/MODES-AFFICHAGE.md`), au
téléphone, sur tablette et chez l'élève. Journal : D-031. L'ordinateur de l'enseignant est un autre lot.

Demande du directeur (11/11/2026) : « N'oublie pas de penser avec stratégie (sans bricolage) ce qui se
passe entre les modes d'affichage (entre l'affichage support/Coran, et tableau, vignettes vidéos,
etc.) : il faut que tout soit bien coordonné et ne pas agir comme des entités différentes. Pense aussi
aux transitions si nécessaire. »

## Ce qui n'est pas prouvé

- Tout est vu en **tests de widget et captures de test** (faux moteur : les « images » sont des aplats
  vides). Rien n'est vu dans la vraie application : le banc n'était pas à ce lot.
- La capsule qui montre le récitant n'est testée qu'en widget seul (portée de `/salle` simulée) : dans
  la vraie salle, la parole de l'enseignant passe par le serveur (« Faire réciter ») et le harnais ne
  la pose pas.
- Le mode Tableau n'est pas monté dans les tests de la vraie salle : il passe par le même chemin que le
  mode Document (`page != null`), le fondu enchaîné Document vers Tableau est le même composant.

## Règles et sources

| Règle | Source | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Pendant un partage, le téléphone garde **un** visage, celui qui parle ou l'hôte, dans une vignette qu'on déplace ou qu'on range | Zoom mobile (partage d'écran reçu : vignette flottante de l'orateur, glissable, repliable au bord), Google Meet Android/iOS (présentation : une tuile flottante, déplaçable), FaceTime SharePlay (une vignette en coin) | Rejoint la règle du directeur : chez l'élève au téléphone, un seul cadre, l'enseignant | `identiteVignette` de l'élève = l'enseignant, toujours (le « Point 2 » du 30/10, qui y mettait le camarade récitant, est remplacé) |
| Sur grand écran, la bande de visages se pose **à côté** du contenu partagé, jamais dessus | Meet (vue « barre latérale » pendant une présentation), Zoom (« côte à côte ») | La bande de côté réservée (`GeometrieEleve.cote`) porte l'enseignant (bande de fin) et le récitant (milieu de la bande de début) ; la page garde sa taille | `cleRecitantBande`, `largeurCadreBande` |
| Une personne, un cadre | MODES-AFFICHAGE §2 règle 1 | Aucun visage deux fois, quatre rôles, trois tailles, Classe et Document | En mode Classe la capsule de l'enseignant montre l'enseignant (le récitant est dans la grille) ; en Document, le récitant |
| Taille des cibles | WCAG 2.2, 2.5.8 (24 au moins), plateforme 48 | Les trois places de la capsule : 48 | Test d'écarts égaux, ordre de lecture FR et AR |
| Contraste du bord d'un composant | WCAG 2.2, 1.4.11 (3:1) | Le cadre posé seul sur la page (même teinte que lui) avait un bord invisible | `CadreVisage(detache: true)` : filet `borderStrong` dans la vignette et la capsule ; la grille n'en change pas |
| Animation déclenchée par l'interaction | WCAG 2.2, 2.3.3 | « Réduire les animations » : fondu seul, aucune échelle | `PassageVisages` lit `AppMouvement.mouvementReduit` ; test |
| Un message ne se pose pas sur le contenu à lire | Règle du directeur (11/11), cahier §8 | « Caméra désactivée pour ce profil. » et le micro en attente passent en haut, sous l'île, avec un fond | `_StatutEnHaut`, `DockSeance(statutEnTete:)`, `FondStatutSalle` |

## Ce qui a été fait, par point

1. **Un seul cadre** : `VignetteVideo` est une enveloppe mince de `CadreVisage` (reste : sa largeur, son
   rapport, sa clé `vignette-video`, le toucher « voir en grand », les barres du réseau posées dans le
   cadre). Dans `/salle`, le cadre vient de la portée (`PorteeMediaSalle.cadre`), c'est le **même widget
   que la grille** (`SceneClasse.cadreHorsGrille`, nourri par le moteur : image, micro, parole). Signature
   publique conservée (ajouts : `identite`, `nom`, `cleCadre`).
2. **Le ruban** : élève au téléphone, un cadre (l'enseignant) ; élève sur écran large, l'enseignant puis
   le récitant dans la bande ; enseignant au téléphone, la capsule montre le récitant en Document ou
   Tableau, lui-même sinon. La feuille « Élèves » garde ses cartes (zone de l'autre lot : si elle doit
   porter des images vivantes, c'est à lui).
3. **La capsule rangée** : trois places au même rythme (marge 8, écart 8, cibles 48) : « Réduire la
   salle », le cadre (réseau en haut à la fin, micro coupé en bas au début, dedans), « Voir la classe »
   (nouveau libellé, l'œil) ou « Revenir à la page ». Le point vert disait « rien n'est enregistré », ce
   qui est toujours vrai (A-01) : il ne se pose plus que rouge ; le profil déplié le garde, avec le
   réseau, et l'île dit l'état au repos.
4. **Seul dans la salle** : caméra allumée, son propre cadre sous la phrase d'attente, centré, 240 au plus
   (carré au téléphone, 4:3 au large), dans la colonne ; caméra éteinte : l'attente seule. L'enseignant
   n'en a pas (son image est déjà dans la capsule).
5. **Les passages** : version **coordonnée**, pas un vol (voir « écarté »). Classe vers Document ou
   Tableau : la grille retrécit vers la place du ruban (capsule ou vignette) et s'efface en 280 ms
   (`deplacementEntree`, ressort sans rebond), la vignette arrive en grandissant (`echelleVersIle`), la
   page arrive en fondu ; retour : la grille revient en grandissant depuis la même place en 190 ms
   (`deplacementSortie`, deux tiers) ; Document vers Tableau : fondu court (`fonduEntree`). Jetons du lot
   TRANSITIONS-SALLE seulement. Un passage ne se joue qu'à l'image où le mode change : ni à l'entrée, ni
   à une reconnexion, ni au masquage des commandes à 3 s (tests).
6. **Les phrases d'état** : devant une page qui garde l'écran (téléphone en portrait, bandes de côté),
   elles quittent le dessus de la pilule du bas et se posent en haut, sous l'île (et avant la vignette),
   sur le fond des pilules ; elles viennent et partent avec les commandes (à l'entrée, retenues 6 s pour
   le micro comme avant ; à chaque toucher). En Interface guidée (page entre deux rangées) et sur la
   scène, la pilule a sa place réservée : la phrase y reste, elle ne couvre rien. Lecteur d'écran :
   inchangé (zone vivante pour le micro ; les commandes restent toujours visibles pour lui).

## Écarté, et pourquoi

- **Un vrai vol du cadre de l'enseignant de la grille à la vignette** (`Hero` ou superposition qui suit
  les positions lues par des clés) : la vignette vit dans la couche des commandes (`CommandesMasquables`),
  la grille dans la scène, et la vignette peut être rangée ou posée dans un autre coin ; un vol propre
  demanderait une couche commune aux deux et deux rendus de la même vidéo pendant le vol. La version
  coordonnée donne la même lecture (la grille va vers la vignette, la vignette en sort) sans ce montage.
- **Une phrase d'état permanente dans l'île** : l'île est le composant d'un autre lot
  (`pilule_etat_salle.dart`, ajout possible mais non nécessaire) ; la phrase avec les commandes tient la
  règle « un court instant, jamais sur la page ».
- **Un bouton Caméra « qui dit pourquoi »** quand la caméra est interdite : un bouton qui ne peut pas
  aboutir n'est pas rendu (règle du dépôt) ; la phrase se lit en haut à chaque toucher.

## Flux vidéo

Le moteur s'abonne à toutes les vidéos et LiveKit ne fait circuler (`adaptiveStream`) que celles qui
sont affichées, à la taille affichée. Donc : l'enseignant au téléphone qui voit le récitant dans sa
capsule reçoit **un flux de plus** (petit : 96 points) ; l'élève sur grand écran pendant une récitation
reçoit **deux** flux (l'enseignant et le récitant, 200 points chacun) au lieu d'un ; l'élève au téléphone,
un seul (l'enseignant), comme avant. Le repli réseau (`RepliAudio`) coupe toutes les vidéos reçues avant
la voix : la voix passe avant l'image.
