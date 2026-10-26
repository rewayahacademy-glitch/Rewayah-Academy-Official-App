# Revue UX de la composition de la salle sur ordinateur (règle gelée DESIGN-GOV §4.2)

Plan : `docs/current/maquettes/salle/PLAN-SALLE-COMPOSITION-2026-10-26.md`, validé par le directeur
le 26/10/2026 à 08:40 (Q1 oui, Q2 non, Q3 bande gardée). Maquette :
`references/2026-10-26-directeur-ordinateur-trois-panneaux.webp`. PR A (ordinateur).

**Limites à dire d'abord.**

- Rien n'est prouvé en production. Tout est testé localement (tests d'écran, captures
  `captures/salle-1440-*.png`) ; « fait » attend la vérification du directeur.
- Les standards ci-dessous sont cités de mémoire, dans leur version publique connue (Material 3,
  WCAG 2.2, Flutter adaptive, Fitts, Hick), sans lecture en ligne le 26/10/2026.
- **Couleurs franches : perdues au rechargement.** Elles voyagent dans le message du trait (champ
  `couleur`) ; la table des annotations n'a pas de colonne pour elles. Un trait rechargé depuis la
  base reprend la couleur de son intention. Migration ultérieure : colonne `couleur` sur les
  annotations (zone `supabase/`, hors de ce lot). Un client plus ancien, lui, peint l'intention.
- **Photos.** La photo de l'enseignant suit la clé de son profil de Classe (seau `avatars`) ; ce
  chemin n'est vérifié par aucun écran en production. Les élèves restent en initiales : ni la
  présence ni le roster n'exposent leur clé de photo (serveur, hors de ce lot).
- **Actions d'un élève.** « Faire réciter » et « Appeler discrètement » aboutissent ; « Noter »,
  « Signaler un besoin » et « Autoriser à écrire » n'ont pas de propriétaire dans `/salle` : ils ne
  sont pas rendus (jamais grisés). Accepté pour cette PR (pilote, 26/10/2026).
- **Galerie vidéo de l'élève.** Hors de ce lot et inchangée : la scène existante montre encore à
  l'élève le prénom des autres élèves (décision du pilote du 26/10/2026).
- **« Support »** reste le nom de l'onglet des Commandes (téléphone, PR B ; accepté).
- **Fiche d'un élève.** Le serveur ne projette pas encore le domaine pédagogique pour
  l'enseignant : la carte dépliée dit « Suivi pédagogique indisponible » et porte ses actions.

## Ce qui est contrôlé

| Proposition contrôlée | Standard | Règle utile | Conclusion | Conséquence dans le code |
|---|---|---|---|---|
| Trois panneaux dès 840 points ; en dessous, la composition du téléphone | Material 3, classes de fenêtre (« expanded » à 840) ; Flutter adaptive | Au-delà de 840, des volets fixes remplacent les surimpressions | conforme | `salleOrdinateur()` : enseignant, `/salle`, largeur ≥ `AppGabarit.seuilEtendu` ; l'élève, le tuteur et le contrôleur gardent leur composition |
| Rien ne s'ouvre au milieu ; panneaux de côté de largeur fixe (300 et 320) | Material 3, « supporting pane » et « side sheet » standard ; Nielsen, visibilité de l'état | Un volet de côté qui ne recouvre pas le contenu principal ; l'état ouvert se voit | conforme | Élèves à gauche (`PanneauEleves`), Bibliothèque ou Commandes à droite ; plus aucune `AppBottomSheet` pour Élèves, Bibliothèque ou Commandes sur ordinateur ; test « rien ne se recouvre » (zones haut, gauche, centre, droite, bas) à 1440 et 1280, ×1 et ×2 |
| La Bibliothèque ouverte d'office à 1200 et plus, fermée par défaut entre 840 et 1200 | Material 3, « supporting pane » qui se replie quand la place manque | Le contenu principal garde la priorité | ajustée, acceptée par le pilote le 26/10/2026 | À 840, deux panneaux ne laisseraient que 220 points à la page ; B ou le bouton l'ouvre |
| Panneaux miroités en arabe | Material 3, mise en page bidirectionnelle ; contrat B (start/end) | Les volets suivent le sens de lecture | conforme, vérifiée | `Row` sans direction forcée : les Élèves au bord de début, la Bibliothèque au bord de fin ; test arabe à 1440 et 1280 |
| Nom sous chaque icône de la barre (ordinateur) | Material 3, « navigation rail » et barres à libellés ; Nielsen, reconnaissance plutôt que rappel | Un libellé visible réduit la recherche (Hick) pour qui ne reconnaît pas l'icône | dérogation datée (Q1 du 26/10) au standard du 24/10 | `TuileCommandeSalle` (core) par `BoutonAppel(nom:)` ; le téléphone garde les icônes seules ; garde K-54 (icône et nom centrés, cible de 48, 320 et 1440, ×1 et ×2, quatre états) ; test « barre nommée » à 1440 et 1024 (×1,5, ×2), aucun mot coupé |
| Une barre sombre sur toute la largeur, deux groupes de tuiles, un filet entre eux (maquette ; décision du pilote du 26/10/2026) ; chaque tuile du côté du panneau qu'elle ouvre | Material 3, « bottom app bar » ; Gestalt, proximité | Les commandes d'un même rôle se groupent ; la séparation se voit ; une commande se tient près de ce qu'elle ouvre | ajustée, décision du directeur du 26/10/2026 : la tuile du côté de son panneau (la maquette les inversait) | `surfaceInverse` (sombre en clair, claire en sombre : encres de la paire) ; au début Élèves, Pointeur, Écrire, Tableau, Plus ; à la fin Micro, Caméra, Bibliothèque, Quitter (dernier, seul rouge) ; miroir en arabe ; test « une barre sombre, deux groupes, un filet, cibles de 48 » (ordre des tuiles) et matrice fr/ar (tuile et panneau du même côté du filet) |
| États des tuiles : panneau ouvert ou outil retenu en aplat lilas ; bascule coupée en violet, icône barrée ; Quitter seul rouge | Maquette ; règle des bascules du lot 3 (25/10) ; WCAG 1.4.1 | Un état ne se dit jamais par la couleur seule | conforme | Aplat, icône (barrée pour une bascule) et lecteur d'écran (acte puis état, `selectionne`) ; Quitter en `surfaceAlert` plein |
| Tableau dans le groupe de gauche, entre Écrire et Plus | Plan §1 (« le Coran et le tableau marchent ») | Une fonction existante ne disparaît pas | ajustée (le plan ne le nomme pas dans la barre) | Le tableau garde son bouton ; « Écrire » prend l'icône du stylo (la police Phosphor livrée n'a pas d'icône de tableau, les deux partageaient `annoter`) |
| Focus : un geste, réversible, la barre du bas reste | Nielsen, contrôle et liberté ; WCAG 2.1.1 (clavier) | Une action se défait par le même geste ; elle est au clavier | conforme | Bouton du centre et touche F (`RaccourciSalle.focus`) ; test aller-retour |
| Barre d'outils horizontale, tout visible, au-dessus des commandes | Material 3, « toolbar » ; standard des tablettes de dessin | Les outils fréquents à un toucher, sans menu | conforme | `BarreOutilsSalle` : stylo, surligneur, gomme, annuler, rétablir, tout effacer, dix couleurs, trois épaisseurs ; Annuler et Rétablir disparaissent sans rien à faire, leur place reste (jamais grisés) |
| Dix couleurs, les quatre intentions d'abord avec leur nom | WCAG 1.4.11 (objets graphiques 3:1) ; WCAG 1.4.1 | Un trait se voit sur son fond ; la couleur retenue se dit autrement que par la couleur | conforme, mesurée | Test `nuancier_trait_test` : les quatre intentions au moins 3:1, les six franches au moins 4,5:1, sur la page et sur la feuille blanche ; `BoutonCouleur` : anneau, coche, « sélectionné » lu |
| Rétablir | Standard des éditeurs (pile de rétablissement vidée à tout nouveau geste) | Annuler et Rétablir sont symétriques | conforme | `ControleurHistorique.retablir` ; la classe reçoit l'opération refaite comme Annuler ; tests |
| Un seul bouton plein, même Bibliothèque dépliée | K-56 ; Material 3, un « filled » par vue | Une action dominante | conforme, vérifiée au rendu | `verifierUnSeulBoutonPlein` à 1440 et 1280 ; page du Coran en erreur : « Réessayer » reste le seul plein, « Présenter » passe en contour (`pagePresenteeEnErreur`, décision du pilote du 26/10/2026) ; test « page en erreur, Bibliothèque dépliée » |
| Cartes d'élèves et de supports séparées de 16 | K-55 | Contenus indépendants, 16 entre cartes | conforme, vérifiée | `PanneauEleves` (séparateur `Ecart.vLg`), `PileCartes` dans la Bibliothèque ; `verifierAucuneCarteCollee` |
| Les trois filtres de la Bibliothèque | FILTRES-1 (une rangée qui défile, jamais un `Wrap`) | Tout filtre atteignable | conforme à la règle du dépôt, écart à la maquette | Dans 320 points, la rangée défile un peu ; « Cette classe » (clé courte du plan) au lieu de « Pour cette Classe » |
| 1280 × 720, texte ×2 | WCAG 1.4.4 et 1.4.10 | Rien ne se coupe ni ne se recouvre ; le contenu reste atteignable | conforme, serré | Les deux groupes de commandes passent sur deux rangées ; les panneaux défilent ; la Bibliothèque défile d'un seul tenant (sa tête débordait de 122 points) |
| L'élève : aucun panneau, aucune liste | Q2 (non) | | conforme, avec une réserve | Test « élève, 1440 » ; **réserve** : la galerie vidéo existante de la scène montre encore le nom des autres élèves à l'élève (hors de ce lot) |

Ce que cette PR ne change pas : le téléphone (PR B), la vue de l'élève, la visite du tuteur et
du contrôleur, la page du Coran, le tableau 16:9 et leur synchronisation.

## PR B : la salle de l'enseignant au téléphone (26/10/2026)

Plan : `PLAN-SALLE-COMPOSITION-2026-10-26.md` §4 et §7 ligne B. Maquettes :
`references/2026-10-26-directeur-telephone-commandes.webp` et
`-telephone-visio-au-toucher.webp`. Captures : `captures/salle-390-*.png`.

**Limites à dire d'abord.**

- Rien n'est prouvé en production : tests d'écran et captures seulement, à 390×844 et
  360×780, texte ×1 et ×2, français et arabe. « Fait » attend la vérification du directeur.
- **Écart à la maquette, assumé** : la maquette pose une puce « Commandes » au-dessus de la
  pilule quand les commandes sont visibles. Elle coûtait une rangée de plus et, à 320 points
  en texte ×2, poussait le constat « Cette page n'a pas pu être lue » et son « Réessayer »
  hors de l'écran (test `SALLE-ERR-320-1`, qui l'a refusée). « Commandes » est donc le
  bouton « Plus » de la pilule au toucher, et la puce seule en bas au repos, comme le dit le
  plan §4 (« au repos … un petit bouton Commandes »).
- **Le tableau quitte la pilule du téléphone** : il vit dans l'onglet Outils du tiroir
  (plan §4). Un enseignant qui le cherchait dans la pilule ne l'y trouve plus.
- La capsule vidéo ne se pose pas sur une page illisible (erreur, corpus absent) : son
  constat et son « Réessayer » restent lisibles. Elle n'apparaît donc pas dans ces états.
- Le haut reste chargé : pilule d'état, bouton « Élèves », capsule et croix de rangement se
  partagent deux rangées, sur la page. Aucune n'est nouvelle sauf la capsule.
- « Noter », « Signaler un besoin », « Autoriser à écrire » restent absents de `/salle`
  (PR A), et la galerie vidéo de l'élève est inchangée.
- Les couleurs franches restent perdues au rechargement (même cause qu'en PR A).

## Ce qui est contrôlé (PR B)

| Proposition contrôlée | Standard | Règle utile | Conclusion | Conséquence dans le code |
|---|---|---|---|---|
| Au repos, la page seule et un petit « Commandes » en bas | Material 3, plein écran immersif ; plan §4 | Le contenu garde l'écran ; une sortie reste visible | conforme | `TelephonePleinEcran.cleCommandesRepos`, rendu quand les commandes sont masquées (`CommandesMasquables.visiblesDe`) ; test « au repos … au toucher » |
| Au toucher, la capsule vidéo en haut et la pilule micro, caméra, quitter en bas | Maquette « visio au toucher » ; standard des commandes d'appel (24/10) | Ce dont on a besoin revient d'un toucher, au même endroit | conforme, avec l'écart ci-dessus | `CapsuleVideoTelephone` (vidéo + « Voir la vidéo en grand »), `DockSeance` borné à micro, caméra, quitter ; tout se masque à 3 s (`CommandesMasquables`) |
| Le tiroir « Commandes » à trois onglets : Support, Outils, Séance | Plan §4 ; Material 3, « bottom sheet » ; ONGLETS-1 | Les commandes d'un même rôle se groupent ; tout onglet reste atteignable | conforme, ajustée | `TiroirCommandesTelephone` dans `PanneauSeance(feuille)` avec « Réduire » ; sections par `SelecteurSection` (ONGLETS-1) : rangée segmentée quand les trois mots tiennent, menu déroulant sinon (360 en texte ×2), jamais un mot coupé |
| Le tiroir ne recouvre jamais la pilule de l'appel | SUPERPOS-1 ; WCAG 2.4.11 | Rien d'essentiel sous un panneau flottant | conforme, mesurée | Le tiroir et la pilule sont une colonne ancrée en bas : le tiroir se tasse (`Flexible` + hauteur maximale 60 %) au lieu de couvrir ; test « rien ne se recouvre » à 360 en texte ×2 |
| La pilule du zoom ne flotte pas sur un panneau ouvert | SUPERPOS-1 | Un élément flottant ne couvre pas un contenu à lire | conforme | Rendue seulement sans panneau du téléphone ouvert |
| Les élèves en feuille du bas, cartes qui se déplient sur place | Plan §4 ; K-55 | Pas de place pour une colonne ; les mêmes cartes que sur ordinateur | conforme | `FeuilleElevesTelephone` (même `PanneauEleves`) ; le bouton rond « Élèves » du haut et la tuile de l'onglet Séance ouvrent la même feuille ; `verifierAucuneCarteCollee` (16 entre cartes) |
| Outils : stylo, surligneur, gomme, annuler, rétablir, dix couleurs, trois épaisseurs | Plan §3 et §4 ; Material 3, « toolbar » | Les outils fréquents à un toucher, sans menu | conforme, ajustée | `BarreOutilsSalle` réemployée ; à 390 ses dix couleurs ne tiennent pas sur une rangée : chaque groupe (outils, couleurs) défile au doigt plutôt que de perdre une couleur (une rangée d'outils, pas des filtres : FILTRES-1 ne s'y applique pas) ; test « les dix couleurs restent atteignables » |
| Un seul bouton plein, cartes séparées de 16, aucun mot coupé | K-55, K-56 ; WCAG 1.4.4 et 1.4.10 | Une action dominante ; rien ne se coupe | conforme, vérifiée au rendu | `verifierUnSeulBoutonPlein`, `verifierAucuneCarteCollee`, `verifierAucunMotCoupe` à 390 et 360, ×1 et ×2, fr et ar |
| Miroir en arabe | Material 3, mise en page bidirectionnelle ; contrat B | Les panneaux suivent le sens de lecture | conforme | Aucune direction forcée ; toute la matrice de tests tourne aussi en arabe |
| L'élève, le tuteur, le contrôleur : inchangés | Plan §5 | Ce lot ne touche que l'enseignant | conforme | Test « élève au téléphone : ni capsule, ni tiroir, ni Commandes » |
| Tableau sur téléphone : la bande 16:9 | Q3 (bande gardée) | | conforme, inchangé | Le tableau s'ouvre depuis l'onglet Outils ; sa feuille 16:9 ne change pas (test K4 à 390) |
