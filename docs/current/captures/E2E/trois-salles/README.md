# Les trois salles du candidat enseignant, en captures (rang 14, 03/11/2026)

Ce que voient le candidat et la direction dans chacune des trois salles du recrutement, avec les
noms côté candidat du 02/11 (`recrutement.salles`). Une page par salle :

1. [Salle d'examen](salle-1-examen.md)
2. [Salle de vérification et d'entretien](salle-2-verification-entretien.md)
3. [Salle des prêts à enseigner](salle-3-prets-a-enseigner.md)

## Ce qui est prouvé, et ce qui ne l'est pas

- **Prouvé** : l'affichage, sur la pile locale (`tool/e2e/trois_salles.mjs`), main du 03/11
  (75efd389), à 390 x 844 et 1440 x 900. Journal et verdict dans `2026-11-03/`.
- **Non prouvé** : le chemin qui mène d'une salle à la suivante. Les trois candidates sont
  **amorcées en SQL local** directement dans leur salle (comme `amorcer.sh` pour ce que l'interface
  ne sait pas créer) ; l'invitation, le questionnaire et l'admission ont leurs propres robots. Rien
  n'est montré en production ni sur un aperçu.
- Les trois candidates sont des femmes, comme la direction de test : la liste de la direction est
  **cloisonnée par genre en base** (CAND-Q07). Un candidat homme, essayé au premier passage,
  n'apparaissait ni dans la liste ni sur sa fiche (« Cette candidature n'existe pas, ou plus ») pour
  cette direction.
- Les listes de la direction montrent aussi les candidates des passages précédents du robot sur le
  même banc : elles sont du même modèle, rien d'autre.

## Les manques, salle par salle

| Salle | Manque |
| :--- | :--- |
| 1. Salle d'examen | Rien de bloquant vu ici : la candidate est invitée à compléter sa candidature, la direction la voit « À compléter ». Plusieurs blocs de la fiche direction attendent leur branchement serveur. |
| 2. Salle de vérification et d'entretien | **Sans entretien** : la candidate ne voit aucun entretien ; la direction lit « Entretien à planifier » mais le bloc « Entretien » dit « Disponible au branchement serveur », sans aucune action (lots V1 et V2 de la visio d'entretien). |
| 3. Salle des prêts à enseigner | **Non reliée** : avec sa pièce approuvée et ses accords signés, la candidate lit « Votre dossier est en cours de vérification » ; rien ne lui dit qu'elle est prête. Côté direction, « Affectation » attend son branchement serveur et « Aucune action n'est disponible ». |
