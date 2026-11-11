# UX_REVIEW_VIGNETTE-TELEPHONE : ranger la vidéo au bord, la rappeler (11/11/2026)

Lot VIGNETTE-TELEPHONE. Demande du directeur (11/11/2026) : « Est-ce qu'on peut bouger les
vignettes de vidéo ou les cacher comme on le veut, ou bien c'est toujours figé ? », puis : « pour
la vignette sur ordinateur, c'est déjà bon si elle est rangée sur le panneau des élèves. Je parlais
du mobile, téléphone. » Il a retenu la recommandation du pilote : glisser vers le bord range la
vignette et laisse une languette ; toucher (ou tirer) la languette la remontre ; le déplacement aux
quatre coins ne change pas ; cacher une vidéo chez soi ne coupe jamais la caméra de l'autre.

**Ce qui n'est pas prouvé.** Tout est vérifié par des tests locaux et des captures **de test** (le
vrai écran `/salle` de l'élève, monté avec un faux serveur de visio : mêmes fonds, même page). Rien
n'a été essayé sur un vrai téléphone, ni sur le banc, ni en production. Le geste au doigt réel
(lancer, seuils) n'a été rejoué que par le moteur de test de Flutter.

## 1. Ce qui existait avant ce lot

- Chez l'élève (et le tuteur, le contrôleur) devant une page, au téléphone et à la tablette en
  portrait : la vignette de l'enseignant passe par-dessus la page au toucher, avec les commandes, et
  se masque à 3 s (`CommandesMasquables`, lot CORAN-ELEVE). Elle se déplaçait aux quatre coins
  (lot salle 2 du 25/10, `Draggable`), toucher la mettait en grand. **On ne pouvait pas la cacher.**
- Sur ordinateur et en paysage, la vignette est dans une bande de côté (deux coins permis).
- Chez l'enseignant au téléphone, sa propre vidéo est la capsule du haut, qui n'apparaît qu'au
  toucher ; au repos, c'est l'île.

## 2. Ce qui est codé

Dans `VignetteAimantee` (`lib/features/salle_seance/telephone_plein_ecran.dart`), paramètre
`rangeable`, et un composant partagé neuf, `LanguetteBord` (`lib/core/widgets/languette_bord.dart`).

| Geste | Effet |
| :--- | :--- |
| Glisser la vignette | Elle suit le doigt, sans retard (le premier déplacement compte le seuil, rien ne saute). |
| Lâcher au milieu, ou glissement court | Elle va au coin permis le plus proche, sur un ressort sans rebond (`AppMouvement.ressort`, amortissement critique ; l'élan du lancer est borné pour ne jamais dépasser la place). |
| Lâcher avec la moitié de la vignette au-delà du bord gauche ou droit, ou la lancer vers le bord (plus de 700 points par seconde, `AppMouvement.elanRangement`) après en avoir passé le quart | Elle sort de l'écran ; une **languette** apparaît en fondu sur ce bord, à la hauteur où elle a été rangée. |
| Toucher la languette | La vignette revient au coin le plus proche de ce bord (en haut ou en bas selon la hauteur de la languette). |
| Tirer la languette vers l'intérieur (24 points au moins, ou un lancer) | La vignette sort du bord en suivant le doigt, puis se pose au coin ; un tirage plus court la laisse rangée. |
| Appui sur la **poignée** (petite languette collée au bord, à côté de la vignette posée) | Range la vignette, sans glisser (WCAG 2.5.7). |
| Appui sur la vignette | La met toujours en grand (inchangé). |

- **Arabe** : la vignette part du coin haut à gauche (fin de lecture) ; la poignée et la languette
  sont au bord physique où se trouve la vignette ; tout se miroite.
- **Clavier** : poignée et languette sont atteintes à la tabulation et s'activent par Entrée ou
  Espace (`Pressable`) ; le focus passe de l'une à l'autre (au clavier, sans mouvement, pour que la
  cible existe tout de suite).
- **Lecteur d'écran** : « Ranger la vidéo d'Amina », « Montrer la vidéo d'Amina » (élision par
  `deDevant`) ; en arabe « إخفاء فيديو … », « إظهار فيديو … ».
- **Réduire les animations** : ni ressort ni fondu ; la vignette est à sa place ou rangée d'un coup.
- **Mémoire** : le coin et l'état rangé sont gardés dans le stockage de la route (comme le coin
  depuis le 25/10) : toute la séance, et « montrée » à la séance suivante.
- **Sécurité** : rien n'est envoyé. Ni la salle (aucun paquet publié), ni le serveur (aucune
  demande), ni la caméra, ni le micro ne sont touchés ; le test le mesure.
- **Où c'est actif** : élève, tuteur, contrôleur devant une page, au téléphone et à la tablette en
  portrait (vignette par-dessus), et sur ordinateur et en paysage (vignette dans la bande de côté :
  la languette vit au bord de la fenêtre, dans la bande, jamais sur la page). **Pas en Interface
  guidée** : l'enfant garde toujours le visage de son enseignant. **Rien ne change chez
  l'enseignant.**

## 3. Règles et sources

| Règle | Source | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| La vidéo d'un appel en image dans l'image se range au bord d'un glissement ; une languette reste et la ramène d'un appui ou d'un glissement | Apple HIG, *Picture in Picture* et le comportement de FaceTime sur iPhone (glisser la vidéo hors du bord : elle se range, une languette à flèche reste ; toucher la languette la remontre) | Le geste attendu par un utilisateur de téléphone ; même grammaire chez nous | Glisser au-delà du bord range ; languette au bord, à la hauteur ; toucher ou tirer ramène |
| Le déplacement d'une image dans l'image se pose au coin le plus proche | Apple HIG (PiP) ; Google Meet ; lot salle 2 du 25/10 | Inchangé | Les coins permis restent ceux du lot CORAN-ELEVE |
| Le mouvement suit le doigt, puis se pose sans rebond | Material 3, *Motion* (direct manipulation, ressorts) ; `DESIGN-GOV` (durées gelées), `AppMouvement` (aucun rebond hors des deux exceptions du directeur) | Le ressort critique `AppMouvement.ressort` ; l'élan est borné à 10 pour que le ressort ne dépasse jamais | Aucune durée ni courbe nouvelle ; un seul jeton nouveau : `elanRangement` (vitesse) |
| Une action faite en glissant a une alternative à un seul appui, sans glisser | WCAG 2.2, 2.5.7 *Dragging Movements* (AA) | Ranger : la poignée ; montrer : la languette (un appui) | Poignée et languette sont des boutons nommés |
| Une cible fait au moins 24 sur 24 points ; ici 48 (règle du dépôt) | WCAG 2.2, 2.5.8 *Target Size (Minimum)* ; `lib/CLAUDE.md` (cible 48) | La languette fait 24 de large à l'œil et 48 sur 48 au toucher, la cible déborde vers l'intérieur | `LanguetteBord.cible = 48`, `largeurVisible = 24` |
| Un état ne se lit jamais par la couleur seule | WCAG 1.4.1 ; `lib/CLAUDE.md` | La languette porte une icône : caméra (vidéo rangée, à montrer) ; la poignée un chevron vers le bord (ranger) | Icônes `AppIcons.camera` et `AppIcons.suivant` (retourné au bord gauche) |
| Rien ne recouvre ni ne réduit la page du Coran | Règle absolue du directeur (11/11/2026) | La languette est au bord, petite, et se masque avec les commandes au repos (la page est seule) ; sur ordinateur elle est dans la bande | Aucune exception : elle n'est jamais forcée à l'écran |
| Distinguer appui, déplacement et rangement | Material 3 (seuils de geste) ; Apple HIG (gestes) | Appui sans déplacement = mise en grand ; déplacement = coin ; rangement seulement à la moitié au-delà du bord, ou sur un lancer après le quart (le bord est à 16 points de la vignette : un glissement court ne peut pas ranger) | Seuils dans `_finGeste` |
| La page dessous a son propre glissement (« La page suit celle de l'enseignant ») | Lot CORAN-ELEVE, `GlisserPage` | Le glisser de la vignette part à 16 points, celui de la page à 18 : un glissement commencé sur la vignette la déplace toujours | Seuil du glisser de la vignette réglé à 16 |

## 4. Décisions à justifier

**La caméra de l'enseignant se rallume alors que la vignette est rangée : faut-il prévenir
l'élève ?** Non, pas de signe en plus. La vignette (et donc la languette) n'existe que quand la
caméra de l'enseignant est allumée (`voitVignetteSurSupport`). Caméra éteinte, il n'y a ni vignette
ni languette ; rallumée, l'état rangé est gardé et **la languette réapparaît au prochain toucher** :
son apparition est le signe, et son nom le dit (« Montrer la vidéo d'Amina »). L'affichage n'est
jamais forcé (règle absolue : rien sur la page sans geste de l'élève). Le test le prouve.

**Chez l'enseignant au téléphone, faut-il le même geste pour ranger sa capsule ?** Non. Sa capsule
n'apparaît déjà qu'au toucher et se masque à 3 s ; au repos, c'est l'île. Elle porte « Réduire la
salle » et « Voir la vidéo en grand » : la ranger cacherait ces deux gestes sans rien libérer (la
page est déjà seule au repos). La composition du téléphone réduit refaite ce matin n'est pas
touchée.

**La vidéo des élèves mise en grand chez l'enseignant au téléphone se ferme-t-elle facilement ?**
Oui. Au téléphone, il n'existe pas de cadre d'un seul élève agrandi : « Voir la vidéo en grand »
ouvre la galerie (la scène) à la place de la page. Sur la scène, la capsule reste visible au repos
(pilote C10) et son œil devient « Revenir à la page » : un appui, cible de 48, en haut. Chez
l'élève, la vidéo mise en grand se ferme par « Revenir à la page » (`ZoneSupport`, en haut, toujours
visible). Rien à changer.

**Sur ordinateur, chez l'élève ?** Fait, parce que c'est le même composant : la vignette est dans
la bande de fin, la poignée et la languette au bord de la fenêtre, dans la bande, jamais sur la
page (test à 1440 x 900, clair et sombre, texte x2). Chez l'enseignant sur ordinateur, rien ne
change (sa vidéo est en tête du panneau des élèves, décision du directeur).

## 5. Écarts et limites

- La poignée est **visible avec les commandes**, à côté de la vignette : c'est l'alternative au
  glissement. Sa cible de 48 recouvre 32 points du bord de la vignette (la vignette du téléphone fait
  96 de large) ; un appui sur ces 32 points range au lieu de mettre en grand. Accepté : la poignée
  est nommée et dessinée, et le reste de la vignette (64 points) garde l'appui « en grand ». À
  revoir si le directeur trouve qu'on range par erreur.
- La languette n'a pas d'infobulle au survol (le composant `Pressable` n'en pose pas) ; son nom est
  lu par le lecteur d'écran.
- `LanguetteBord` est un composant neuf de `lib/core/widgets/` (entrée de galerie et nom dans
  `test/widgets/catalogue_galerie_test.dart`) : un bouton dessiné au bord dans un écran aurait été
  un bouton recomposé (`bouton-recompose`).

## 6. Preuves

- Tests : `test/features/salle_vignette_telephone_test.dart` (le vrai `/salle` de l'élève) : ranger
  par glissement et par la poignée ; rappeler par appui et par tirage ; glissement court et lancer
  court sans rangement ; appui = mise en grand ; rangée en bas, rappelée en bas ; arabe (bord
  gauche) ; lecteur d'écran ; clavier ; réduire les animations ; état gardé au masquage et quand la
  caméra s'éteint puis se rallume ; rien d'envoyé ; 320 x 568, 390 x 844, 820 x 1180, 1440 x 900,
  clair et sombre, texte x1 et x2. Le test du lot salle 2 (`test/features/salle_test.dart`, « vignette
  deplacable ») passe toujours.
- Captures **de test** : `docs/current/captures/E2E/vignette-telephone/` (montrée, rangée avec sa
  languette, rappelée ; 390 clair, sombre et arabe, 820, 1440 clair et sombre).

## 7. Conclusion

Recommandation du pilote codée telle quelle, avec deux précisions : la poignée (alternative au
glissement, WCAG 2.5.7) et l'activation sur ordinateur chez l'élève (même composant, languette dans
la bande). Pas d'alerte quand la caméra se rallume : la languette qui réapparaît est le signe.
