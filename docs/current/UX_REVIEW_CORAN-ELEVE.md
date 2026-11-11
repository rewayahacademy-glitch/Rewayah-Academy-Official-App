# UX_REVIEW_CORAN-ELEVE (11/11/2026)

Lot CORAN-ELEVE : le Coran tel que l'élève le voit et l'utilise, et le Coran grand sur ordinateur.
Demandes du directeur du 11/11/2026 : « N'oublie pas de corriger aussi le Coran que l'élève
utilise » ; « Sur PC, il faut que le Coran soit grand » ; « l'île doit rester sur le Coran quand
elle est dépliée, sans compacter la page du Coran » ; cahier de la salle, §8 (Coran).

**Ce qui n'est pas prouvé** : rien de ce lot n'a été vu dans la vraie application ni sur le banc.
Toutes les preuves sont des tests de widget et des captures de test
(`docs/current/captures/E2E/coran-eleve/`, fond et composants réels de `/salle`, faux serveur de
visio). Le Coran grand chez l'**enseignant** sur ordinateur n'est pas codé (zone de l'agent de la
barre et de `salle_ordinateur.dart`) : seule l'étude est écrite (§2).

## 1. Rien ne reste sur le texte du Coran chez l'élève

**Reprise du pilote (11/11/2026, après la première version)** : la première version réservait au
téléphone et à la tablette en portrait deux rangées permanentes (île en haut, pilule de l'appel en
bas) ; le texte y perdait 14 % (390) et 20 % (820). Le pilote l'a refusée : le directeur a dit
« l'île doit rester sur le Coran quand elle est dépliée, sans compacter la page du Coran », et il
veut le Coran grand. La règle en portrait est devenue celle du téléphone de l'enseignant (composition
du 26/10, `CommandesMasquables`) : au repos la page seule, au toucher les commandes, masquées à 3 s.

| Règle | Source | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Un élément ne recouvre jamais un contenu à lire | `lib/CLAUDE.md` ; WCAG 2.2, 2.4.11 *Focus Not Obscured* ; directeur 11/11 | Avant : sur ordinateur, la pilule de l'appel et l'infobulle couvraient les deux dernières lignes et le numéro de page ; au téléphone et à la tablette, la pilule, la vignette et l'île couvraient le texte au toucher (captures `avant-*.png`) | `GeometrieEleve` (`telephone_plein_ecran.dart`) : trois compositions, ci-dessous |
| **Ordinateur, tablette et téléphone en paysage** : utiliser la largeur | directeur 11/11 ; Material 3, *supporting pane* | Quand les bandes vides à côté d'une page pleine hauteur logent la pilule de l'appel (4 boutons et marges : 264 sur ordinateur, 296 au téléphone), tout passe sur les côtés | Île en haut de la bande de début (toujours là) ; vignette (200) en haut de la bande de fin, déplaçable en bas de la bande de début ; zoom au milieu et pilule de l'appel en bas de la bande de fin, masqués à 3 s comme avant. Page : toute la hauteur |
| **Téléphone et tablette en portrait** : la page à pleine taille | pilote 11/11 ; composition du 26/10 (téléphone de l'enseignant) | La page garde l'écran entier (ligne de 377 à 390, 628 à 820, comme avant le lot) | **Au repos** : la page et l'île **repliée** en haut, seule (cercle, temps restant, signe du micro ouvert). **Au toucher** (tout contact, tout geste) : la pilule de l'appel, la vignette (de nouveau déplaçable aux quatre coins, lot salle 2) et le zoom passent par-dessus, puis s'effacent au délai de `CommandesMasquables` (3 s) ; ils restent tant qu'un doigt est posé. Aucun second mécanisme |
| Lecteur d'écran et clavier | `CommandesMasquables` (MA-CMD-1, TB-2) | Avec le lecteur d'écran ou au clavier, les commandes restent toujours visibles (même mécanisme que l'enseignant) | Rien à ajouter |
| Les commandes ne se masquent pas | pilote 11/11 | Avant qu'un support soit présenté (scène, vidéos) ; pendant « votre micro s'ouvrira quand votre enseignant sera là » (visible `AppMouvement.ilePassage`, 6 s, à son apparition, puis suit les commandes) ; pendant une reconnexion (`visioMaintenue`, existant) ; en Interface guidée | `maintenir` de `CommandesMasquables` |
| **Interface guidée en portrait** | pilote 11/11 (« un enfant doit toujours voir ses boutons ») | La page se pose entre deux rangées (île, zoom, vignette en haut ; pilule de l'appel mesurée en bas), rien ne se masque | La page y est plus petite (non mesurée dans ce lot) |
| Réduire les animations | `Mouvement.reduit` dans `CommandesMasquables` | Les commandes se masquent sans fondu | Rien à ajouter |
| Le micro ouvert reste su | pilote 11/11 (vie privée : je parle, on m'entend) | Commandes masquées, on ne voyait plus que le micro était ouvert | Signe dans l'île repliée (`PiluleEtatSalle.microOuvert`) : icône du micro, nom lu « Micro ouvert », jamais la couleur seule ; absent micro fermé, en attente ou bloqué. À 320 en texte x2, l'île reste sur une ligne (écart serré de 4 ; il reste environ 1 point de marge) |
| La vignette de l'enseignant | pilote 11/11 | Par défaut, elle suit les commandes (masquée au repos). Pour que l'enseignant montre quelque chose à la caméra, l'élève touche l'écran ou la met en grand (scène) | Choix à confirmer (question 2) |

Vérification : `test/features/salle_coran_eleve_test.dart`, sur la vraie composition (`SallePage`,
rôle élève, page reçue, caméra de l'enseignant allumée), 4 tailles x clair/sombre x fr/ar x texte
x1/x1,3 (32 cas) :
- ordinateur (1280, 1440), au toucher : page, île, pilule, vignette, zoom deux à deux, sans
  recouvrement, rien hors de l'écran ;
- portrait (390, 820) : au toucher, île, pilule et vignette ne se recouvrent pas ; après le délai,
  pilule, vignette et zoom ne sont plus touchables et leur opacité est nulle ; la page a l'écran
  entier ; l'île repliée reste touchable, plus étroite que la moitié de l'écran, une ligne ;
- micro ouvert : signe présent au repos, lu « Micro ouvert » ; micro refermé : signe absent ;
- Interface guidée (390, 820) : commandes toujours touchables, page, île, pilule et vignette sans
  recouvrement.

**Ce qui reste posé sur la page au repos, en portrait** : l'île repliée, en haut au début. Elle
couvre le coin de l'en-tête de la page (nom du juz ou de la sourate), jamais une ligne du texte ni
le numéro de page. Au toucher, la pilule de l'appel et la vignette couvrent le texte 3 s.

Le tuteur et le contrôleur suivent la même composition (même widget).

### Mesures (même test, avant sur `4e6e63f48`, après sur cette branche)

| Écran | Page avant | Ligne avant | Page après | Ligne après |
| :--- | :--- | :--- | :--- | :--- |
| 390 x 844 | 390 x 844 | 377 | 390 x 844 | 377 (=) |
| 820 x 1180 | 820 x 1180 | 628 | 820 x 1180 | 628 (=) |
| 1280 x 800 | 622 x 800 | 426 | 622 x 800 | 426 (=) |
| 1440 x 900 | 700 x 900 | 479 | 700 x 900 | 479 (=) |

La première version (rangées permanentes) donnait 324 à 390 et 503 à 820 : abandonnée.

## 2. Le Coran grand sur ordinateur (étude ; enseignant non codé)

La page de quinze lignes est bornée par la **hauteur** : à 1440 x 900, la ligne fait 479 points
chez l'élève, et la page de l'enseignant 371 x 614 (barre du bas et haut réparti).

- **(a) Rendre la hauteur** : chez l'élève, fait (tout est sur les côtés, la page a les 900 points).
  Chez l'enseignant, la barre du bas et le haut prennent environ 286 points ; les mettre sur les
  côtés rendrait 46 % de hauteur (614 vers 900, ligne d'environ 330 vers 480). C'est la zone de
  l'agent de la barre : à faire par lui, ou dans un lot suivant.
- **(b) La double page** : le lecteur la sait déjà faire (`VuePageMushaf.doublePageDans`,
  `PlancheMushafVM.tientEnDoublePage`, ouverture page impaire à droite, paire à gauche). Dans la
  salle, l'enseignant présente **une** page (`ContenuPresente.page`) : l'élève suivrait l'ouverture
  qui la contient, avec un repère sur la page présentée. Conséquences : le pointeur et les notes
  sont normalisés sur **une** page (`SupportPageFixe.largeurCanonique`) : deux pages demandent de
  dire sur laquelle on écrit ; le suivi de page reste juste si l'ouverture se calcule de la page
  présentée (aucun changement serveur). Mais chaque page n'a que la moitié de la largeur : à
  1440 x 900, deux pages de 900 de haut prennent 2 x 500 = 1000 points, la taille du texte ne
  change pas. **La double page ne grandit pas le texte ; elle montre plus de texte.** Non codée :
  elle touche au pointeur et à l'écriture (zone d'un autre agent) sans grandir la page.
- **(c) Mode agrandi** : chez l'élève, inutile désormais sur ordinateur (rien ne prend la hauteur).
  Chez l'enseignant, le « Focus » de la salle retire le haut et les panneaux mais garde la barre du
  bas : il ne rend que le haut. Un vrai mode agrandi la ferait passer sur un côté.

Typographie (interligne, police) et couleurs de fond : inchangées.

## 3. « Reprendre la lecture »

Où : le lecteur de l'élève, `/eleve/coran` (`MushafPage`, `_Reprises`) : une ou deux cartes
(« Reprendre ta lecture » ; « Reprendre le cours ») posées **au-dessus** de la page,
qui la poussaient vers le bas et ne partaient jamais. Le Mode Accessibilité n'a pas ce bandeau (sa
reprise est l'écran d'entrée, avec son bouton) : inchangé.

Ce qu'il devient : il passe **par-dessus** le haut de la page (il ne la pousse plus), s'efface seul
après `AppMouvement.ilePassage` (6 s, le jeton de l'île), et se retrouve d'un appui sur le signet
de l'en-tête (« Revoir où reprendre la lecture »). Un appui sur la reprise y va et le referme.
Réduire les animations : il s'efface sans fondu. Test : `test/teaching_core/c/reprise_lecture_test.dart`
(390 et 1400 : par-dessus, effacé, rappelé, effacé de nouveau ; l'en-tête ne bouge pas).

## 4. Changer de page et glisser au doigt

- Lecteur de l'élève (`/eleve/coran`) : au téléphone, le glisser tourne la page (feuilletage de
  `VuePageMushaf`, et `FeuilletageDesModes` en lecture agrandie) ; sur tablette et ordinateur, une
  flèche de chaque côté et les touches. Déjà couvert par `test/features/tc_mushaf/mushaf_15l_pagination_test.dart`
  (glisser, arabe, actions d'accessibilité, flèches) : vert après le lot.
- Salle, l'enseignant présente : l'élève suit la page de la classe ; il ne peut pas la tourner
  (le serveur ne lui donne aucun rappel de page). Avant, un glissement ne faisait rien, sans un mot.
  Après : un glissement dit un court instant, au pied de la page, « La page suit celle de
  l'enseignant. Elle tourne avec la classe. » (`GlisserPage.messageSansDroit`). L'élève ne peut donc
  pas se perdre. Test : `salle_coran_eleve_test.dart`, « glisser sur la page de la classe ».
- Salle, hors partage : l'élève voit la scène (les visages), sans page à tourner.

## 5. La table des sourates « pas dans l'ordre officiel »

Écrans vérifiés (lecture du code) :

| Écran | Liste de sourates ? | Ordre |
| :--- | :--- | :--- |
| Lecteur de l'élève `/eleve/coran`, feuille « Aller à » | Non : un champ de recherche (nom, numéro, juz, référence), pas de table | sans objet |
| Mode Accessibilité (`coran_accessibilite.dart`) | Non | sans objet |
| Salle, Bibliothèque de l'enseignant (`panneau_enseignant.dart`) | Oui, les 114 | ordre du serveur, `order('numero')` (`service_coran.dart`) : ordre du mushaf |
| **Cahier de transmission, « Où reprendre » (`cahier/selecteur_reprise.dart`, `FeuilleReprise`)** | Oui, 6 au plus | **La sourate déjà retenue est mise en tête, puis les autres dans l'ordre** : avec Al-Kahf retenue, la liste se lit 18, 1, 2, 3, 4, 5. C'est le seul écran trouvé qui affiche des sourates hors de l'ordre du mushaf |

Le dernier écran est hors de ma zone (enseignant, cahier) : non modifié. Aucun écran de l'élève
n'affiche de table des sourates. Il faut que le directeur montre l'écran qu'il a vu.

## 6. Le lecteur de l'élève, deux modes

Page du mushaf et lecture agrandie : les tests du lecteur (`test/teaching_core/c/`,
`test/features/tc_mushaf/`) restent verts après le lot. Rien n'est posé sur le texte du lecteur,
sauf la reprise (6 s, par-dessus le haut, puis effacée) et le retour « Taille maximale atteinte »
(existant, 3 s). Pas de capture du lecteur produite dans ce lot.

## Questions à trancher par le directeur

1. En Interface guidée seulement (portrait), la page est plus petite : elle se pose entre deux
   rangées pour que l'enfant voie toujours ses boutons. Recommandation : garder.
2. La vignette de l'enseignant suit les commandes (masquée au repos, en portrait). Faut-il la
   garder visible quand l'enseignant montre quelque chose à la caméra ? Recommandation : non par
   défaut ; l'élève touche l'écran, ou passe à la scène.
3. Coran grand chez l'enseignant sur ordinateur : passer la barre du bas sur un côté (rend environ
   46 % de hauteur, estimé) ? Recommandation : oui, lot de l'agent de la barre.
4. Double page dans la salle : elle montre deux pages sans grandir le texte et touche au pointeur.
   Recommandation : non pour l'instant.
5. Cahier, « Où reprendre » : la sourate retenue en tête, hors de l'ordre du mushaf. Est-ce l'écran
   vu ? Recommandation : la laisser à sa place dans l'ordre et la marquer « retenue ».
