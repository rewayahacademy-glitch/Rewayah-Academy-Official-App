# UX_REVIEW : CHIFFRES-ACADEMIE (21/11/2026)

Page « Les chiffres de l'académie » (`lib/features/admin_chiffres/`). Demande du directeur du 20/11/2026 :
une vitrine en chiffres, à jour à la minute, légère (« mon PC est un Core i3 »). Planche acceptée par le
pilote le 21/11 avec sept corrections, toutes appliquées.

## Ce qui n'est pas prouvé

- Aucune revue par une personne qui lit l'arabe : les phrases arabes sont de l'agent.
- Aucun essai avec un lecteur d'écran réel ; la sémantique est vérifiée par les tests seulement.
- La page n'a jamais été ouverte en production (la migration n'y est pas installée).

## Règles confrontées

| Règle | Source | Conclusion | Conséquence dans la page |
|---|---|---|---|
| Une grille qui change de colonnes avec la largeur, sans défilement imbriqué | Material 3, Adaptive layouts (consulté de mémoire, 21/11/2026) ; `DECISION-DEFILEMENT-2026-11-01.md` | Appliquée | 2 colonnes au téléphone, 3 sur tablette, 4 sur ordinateur ; la page seule défile |
| Le texte agrandi à 200 % reste lisible sans perte | WCAG 2.2, 1.4.4 | Appliquée | À partir de 150 % au téléphone, une seule colonne ; le chiffre se réduit plutôt que de se couper |
| Une information ne passe pas par la couleur seule | WCAG 2.2, 1.4.1 | Appliquée | Hausse et baisse dites en mots ou en signe dans la pastille ; chaque dessin qui dit plus que le chiffre a un libellé lu |
| Rien ne bouge, clignote ou défile plus de 5 s sans pouvoir l'arrêter | WCAG 2.2, 2.2.2 | Appliquée | Aucune animation continue ; un chiffre qui change tourne une fois, moins d'une seconde |
| Proximité : ce qui va ensemble se touche | Gestalt | Appliquée | Une carte = un chiffre, sa phrase, son dessin ; deux sections titrées |
| Un dessin ne suggère pas une proportion qu'il ne montre pas | Correction 5 du pilote | Appliquée | Un point = une unité (pays, langues, familles) ; au-delà de 60, plus de points |
| Un chiffre affiché n'est pas répété par sa phrase | Correction 1 du pilote | Appliquée | Les phrases ne contiennent pas le nombre |
| Sens de lecture de droite à gauche | Material 3, Bidirectionality | Appliquée | Colonnes, jauge, segments, points et partage se dessinent en miroir en arabe |

## Écarts assumés

- Le grand nombre s'écrit sans séparateur de milliers (`11959`) : le composant `NombreRouleaux` du core
  rend un entier brut, et ce lot ne le modifie pas.
- Pas de bouton sur la page : c'est une vitrine. « Réessayer » n'apparaît qu'en cas d'échec.
