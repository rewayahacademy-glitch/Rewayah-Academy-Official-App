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

## 1. Rien ne recouvre le texte du Coran chez l'élève

| Règle | Source | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Un élément ne recouvre jamais un contenu à lire | `lib/CLAUDE.md` (« Aucun élément ne recouvre un contenu à lire ») ; WCAG 2.2, 2.4.11 *Focus Not Obscured* ; directeur 11/11 | Avant : sur ordinateur, la pilule de l'appel et l'infobulle couvraient les deux dernières lignes et le numéro de page ; au téléphone et à la tablette, la pilule de l'appel et la vignette de l'enseignant couvraient le texte (captures `avant-*.png`) | `GeometrieEleve` (`telephone_plein_ecran.dart`) donne à chaque chose sa place hors de la page |
| Utiliser la largeur sur ordinateur | directeur 11/11 (« sur ordinateur, on utilise la largeur ») ; Material 3, *canonical layouts / supporting pane* | Quand les bandes vides à côté d'une page pleine hauteur logent la pilule de l'appel (bande d'au moins 4 boutons + marges : 264 sur ordinateur, 296 au téléphone en paysage), tout passe sur les côtés | Île en haut de la bande de début ; vignette (200) en haut de la bande de fin, déplaçable en bas de la bande de début ; zoom au milieu et pilule de l'appel en bas de la bande de fin. Page : toute la hauteur, inchangée |
| Téléphone et tablette en portrait | directeur 11/11 (« la page prend la place libre entre ce qui est fixe ») ; Apple HIG *Layout* (contenu dans la zone sûre, commandes hors du contenu) | Pas de bande de côté : la page s'arrête entre la rangée du haut (île repliée, zoom, vignette de 96) et la pilule de l'appel (hauteur mesurée) | La rangée du haut garde la hauteur de l'île **repliée** : l'île qui se déplie passe par-dessus la page un court instant, sans la compacter (demande du directeur sur la capture de l'île) |
| Infobulle (C6-9) | constat C6-9 | Sous la page, l'infobulle de la pilule tomberait sur la dernière ligne | Sous la page, elle ne s'affiche plus (`TooltipVisibility`) ; le nom reste lu par le lecteur d'écran. Sur les côtés, elle reste, dans la bande |
| Vignette déplaçable (lot salle 2, 25/10) | directeur 25/10 | Ses quatre coins tombaient sur le texte | Sur les côtés : deux coins libres (haut de fin, bas de début). Au téléphone et à la tablette en portrait : elle reste dans la rangée du haut (le test `salle_test.dart` « vignette déplaçable 390 px » le dit) |

Vérification : `test/features/salle_coran_eleve_test.dart`, `verifierSansChevauchement` sur la
vraie composition (`SallePage`, rôle élève, page reçue de l'enseignant, caméra de l'enseignant
allumée), à 390 x 844, 820 x 1180, 1280 x 800 et 1440 x 900, clair et sombre, français et arabe,
texte x1 et x1,3 : page, île, pilule de l'appel, vignette, zoom deux à deux, et rien hors de
l'écran. 32 cas : tous échouaient avant (captures `avant-*`), tous passent après.

Le tuteur et le contrôleur suivent la même composition (même widget) : protégés aussi.

### Mesures (même test, avant sur `4e6e63f48`, après sur cette branche)

| Écran | Page avant | Ligne du texte avant | Page après | Ligne du texte après |
| :--- | :--- | :--- | :--- | :--- |
| 390 x 844 | 390 x 844 (pilule et vignette dessus) | 377 | 390 x 609 | 324 (-14 %) |
| 820 x 1180 | 820 x 1180 (pilule et vignette dessus) | 628 | 735 x 945 | 503 (-20 %) |
| 1280 x 800 | 622 x 800 (pilule dessus) | 426 | 622 x 800 | 426 (=) |
| 1440 x 900 | 700 x 900 (pilule dessus) | 479 | 700 x 900 | 479 (=) |

**Le prix, dit en premier** : au téléphone et à la tablette en portrait, ne plus rien poser sur le
texte coûte 14 % et 20 % de la taille du texte (la page de quinze lignes est bornée par la
hauteur). Sur ordinateur, rien n'est perdu.

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

1. Téléphone et tablette en portrait : garder « rien sur le texte » au prix de 14 % (téléphone) et
   20 % (tablette) de taille du texte, ou revenir à la page plein écran avec la pilule par-dessus
   tant qu'elle est visible (3 s) ? Recommandation : garder « rien sur le texte ».
2. Vignette au téléphone : elle ne se déplace plus (tout autre coin couvre le texte). D'accord ?
   Recommandation : oui.
3. Coran grand chez l'enseignant sur ordinateur : passer la barre du bas sur un côté (rend 46 % de
   hauteur) ? Recommandation : oui, lot de l'agent de la barre.
4. Double page dans la salle : elle montre deux pages sans grandir le texte et touche au pointeur.
   Recommandation : non pour l'instant.
5. Cahier, « Où reprendre » : la sourate retenue en tête, hors de l'ordre du mushaf. Est-ce l'écran
   vu ? Recommandation : la laisser à sa place dans l'ordre et la marquer « retenue ».
