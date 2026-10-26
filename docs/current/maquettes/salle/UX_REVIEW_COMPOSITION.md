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
  sont pas rendus (jamais grisés).
- **Fiche d'un élève.** Le serveur ne projette pas encore le domaine pédagogique pour
  l'enseignant : la carte dépliée dit « Suivi pédagogique indisponible » et porte ses actions.

## Ce qui est contrôlé

| Proposition contrôlée | Standard | Règle utile | Conclusion | Conséquence dans le code |
|---|---|---|---|---|
| Trois panneaux dès 840 points ; en dessous, la composition du téléphone | Material 3, classes de fenêtre (« expanded » à 840) ; Flutter adaptive | Au-delà de 840, des volets fixes remplacent les surimpressions | conforme | `salleOrdinateur()` : enseignant, `/salle`, largeur ≥ `AppGabarit.seuilEtendu` ; l'élève, le tuteur et le contrôleur gardent leur composition |
| Rien ne s'ouvre au milieu ; panneaux de côté de largeur fixe (300 et 320) | Material 3, « supporting pane » et « side sheet » standard ; Nielsen, visibilité de l'état | Un volet de côté qui ne recouvre pas le contenu principal ; l'état ouvert se voit | conforme | Élèves à gauche (`PanneauEleves`), Bibliothèque ou Commandes à droite ; plus aucune `AppBottomSheet` pour Élèves, Bibliothèque ou Commandes sur ordinateur ; test « rien ne se recouvre » (zones haut, gauche, centre, droite, bas) à 1440 et 1280, ×1 et ×2 |
| La Bibliothèque ouverte d'office à 1200 et plus, fermée entre 840 et 1200 | Material 3, « supporting pane » qui se replie quand la place manque | Le contenu principal garde la priorité | ajustée (écart au plan, qui la montre toujours) | À 840, deux panneaux ne laisseraient que 220 points à la page ; B ou le bouton l'ouvre |
| Panneaux miroités en arabe | Material 3, mise en page bidirectionnelle ; contrat B (start/end) | Les volets suivent le sens de lecture | conforme, vérifiée | `Row` sans direction forcée : les Élèves au bord de début, la Bibliothèque au bord de fin ; test arabe à 1440 et 1280 |
| Nom sous chaque icône de la barre (ordinateur) | Material 3, « navigation rail » et barres à libellés ; Nielsen, reconnaissance plutôt que rappel | Un libellé visible réduit la recherche (Hick) pour qui ne reconnaît pas l'icône | dérogation datée (Q1 du 26/10) au standard du 24/10 | `CommandeSalleNommee` (core) et `BoutonAppel(nom:)` ; le téléphone garde les icônes seules ; test K-54 (bouton et nom centrés, 320 et 1440, ×1 et ×2) ; test « barre nommée » à 1440 et 1024 (×1,5, ×2), aucun mot coupé |
| Barre en deux pilules de boutons ronds, et non la barre sombre à tuiles de la maquette | Standard des commandes d'appel du 24/10 (pilule, boutons ronds) | Une seule iconographie d'appel dans la salle | **écart à la maquette, à arbitrer** | La pilule et ses teintes (lot 3) sont gardées (plan §1) ; une barre à tuiles demanderait un nouveau composant |
| Panneaux et outils retenus : sombre ; fermés : violet | Règle des bascules du lot 3 (25/10) ; WCAG 1.4.1 | Un état ne se dit jamais par la couleur seule | conforme | `BoutonAppel(retenu:)` ; l'état est aussi dit au lecteur d'écran (`selectionne`) ; la couleur primaire seule se confondait avec un micro coupé |
| Tableau dans le groupe de gauche, entre Écrire et Plus | Plan §1 (« le Coran et le tableau marchent ») | Une fonction existante ne disparaît pas | ajustée (le plan ne le nomme pas dans la barre) | Le tableau garde son bouton ; « Écrire » prend l'icône du stylo (la police Phosphor livrée n'a pas d'icône de tableau, les deux partageaient `annoter`) |
| Focus : un geste, réversible, la barre du bas reste | Nielsen, contrôle et liberté ; WCAG 2.1.1 (clavier) | Une action se défait par le même geste ; elle est au clavier | conforme | Bouton du centre et touche F (`RaccourciSalle.focus`) ; test aller-retour |
| Barre d'outils horizontale, tout visible, au-dessus des commandes | Material 3, « toolbar » ; standard des tablettes de dessin | Les outils fréquents à un toucher, sans menu | conforme | `BarreOutilsSalle` : stylo, surligneur, gomme, annuler, rétablir, tout effacer, dix couleurs, trois épaisseurs ; Annuler et Rétablir disparaissent sans rien à faire, leur place reste (jamais grisés) |
| Dix couleurs, les quatre intentions d'abord avec leur nom | WCAG 1.4.11 (objets graphiques 3:1) ; WCAG 1.4.1 | Un trait se voit sur son fond ; la couleur retenue se dit autrement que par la couleur | conforme, mesurée | Test `nuancier_trait_test` : les quatre intentions au moins 3:1, les six franches au moins 4,5:1, sur la page et sur la feuille blanche ; `BoutonCouleur` : anneau, coche, « sélectionné » lu |
| Rétablir | Standard des éditeurs (pile de rétablissement vidée à tout nouveau geste) | Annuler et Rétablir sont symétriques | conforme | `ControleurHistorique.retablir` ; la classe reçoit l'opération refaite comme Annuler ; tests |
| Un seul bouton plein, même Bibliothèque dépliée | K-56 ; Material 3, un « filled » par vue | Une action dominante | conforme au rendu, sauf un cas | `verifierUnSeulBoutonPlein` à 1440 et 1280 ; **cas restant** : page du Coran en erreur (« Réessayer » plein) et Bibliothèque dépliée (« Présenter » plein) donnent deux boutons pleins |
| Cartes d'élèves et de supports séparées de 16 | K-55 | Contenus indépendants, 16 entre cartes | conforme, vérifiée | `PanneauEleves` (séparateur `Ecart.vLg`), `PileCartes` dans la Bibliothèque ; `verifierAucuneCarteCollee` |
| Les trois filtres de la Bibliothèque | FILTRES-1 (une rangée qui défile, jamais un `Wrap`) | Tout filtre atteignable | conforme à la règle du dépôt, écart à la maquette | Dans 320 points, la rangée défile un peu ; « Cette classe » (clé courte du plan) au lieu de « Pour cette Classe » |
| 1280 × 720, texte ×2 | WCAG 1.4.4 et 1.4.10 | Rien ne se coupe ni ne se recouvre ; le contenu reste atteignable | conforme, serré | Les deux groupes de commandes passent sur deux rangées ; les panneaux défilent ; la Bibliothèque défile d'un seul tenant (sa tête débordait de 122 points) |
| L'élève : aucun panneau, aucune liste | Q2 (non) | | conforme, avec une réserve | Test « élève, 1440 » ; **réserve** : la galerie vidéo existante de la scène montre encore le nom des autres élèves à l'élève (hors de ce lot) |

Ce que cette PR ne change pas : le téléphone (PR B), la vue de l'élève, la visite du tuteur et
du contrôleur, la page du Coran, le tableau 16:9 et leur synchronisation.
