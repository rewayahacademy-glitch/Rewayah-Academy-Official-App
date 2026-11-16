# Messagerie : checklist du pilote (ouverte le 16/11/2026)

Pilote : session `session_0163KjrvfAPWhND7VanbMLHL`, qui succède au pilote de la passation
`MESSAGERIE-HANDOFF-2026-11-16.md`. La carte du chantier reste `MESSAGERIE-ETAT-ET-PLAN-2026-11-16.md` ;
cette page est la liste à cocher, tenue à jour à chaque geste, en miroir de la liste de tâches de la
session.

Statuts : `à faire` ; `en cours` ; `PR` (ouverte, pas fusionnée) ; `en prod` (fusionné, déployé, pas vu
par le directeur) ; `en prod (vu)` (vu par le directeur en production : le seul « fait »).

## Faux, bloqué ou non prouvé (à lire d'abord)

- La messagerie est grise depuis #512, la croix du volet a disparu (#540), le champ de saisie
  s'arrondit en cercle : corrections dans la PR #551, **pas fusionnée**, CI pas encore lue.
- #538, #540, #546 sont en production mais **pas vus** par le directeur.
- Le plantage à l'ouverture d'une conversation depuis un profil n'est **pas reproduit** : il faut
  l'heure exacte et une capture au prochain essai.
- `scenarios_image_candidat.sql` n'est pas dans `ci.yml` (`.github/` interdit aux agents) : décision du
  directeur attendue.

## Lots, dans l'ordre

| # | Lot | Statut | Preuve / prochaine étape |
| :--- | :--- | :--- | :--- |
| 1 | Passation #554 (docs seules) | PR | fusion par le pilote quand la CI est verte |
| 2 | MESSAGERIE-COULEURS #551 (couleurs d'avant #512, carte blanche ligne par ligne, fond du fil = fond de page, champ à rayon fixe, croix et Échap du volet) | PR (agent `session_0163KjrvV6fGAftwzWig2qU9`) | relire captures avant/après téléphone ET ordinateur, clair ET sombre, chercher ce qui change ailleurs ; lire la CI ; fusionner ; dire au directeur de fermer puis rouvrir l'application |
| 3 | NOUVEAU-FILS : badge « Nouveau » (`lib/core/widgets/badge_nouveau.dart`), « Nouveau · aucun message », filtre « Nouveaux » ; règle serveur : moins de 7 jours et aucune ligne `com_lectures` d'un membre de l'équipe | à faire | migration dans la plage `202611295xxxxx`+ (`20261129500000` déjà pris : vérifier `origin/main`) |
| 4 | NOUVELLE-VERSION : bandeau « Nouvelle version disponible » qui lit `version.json`, jamais de rechargement pendant un brouillon ou un envoi | à faire | |
| 5 | Recette du directeur en production : #538, #540, #546, puis #551 | à faire | liste d'essais à lui donner après la fusion de #551 |
| 5 bis | Défaut connu : dans Messages sur ordinateur, la barre du fil plein écran se replie au défilement et emporte le bouton « i » du panneau de contexte | à faire, lot à part | relevé par l'agent de #551 ; volontairement hors de #551 |
| 6 | `scenarios_fac_f_relances_suspension.sql` indépendant de l'heure (échoue le lundi 7-8 h UTC) | à faire, sans urgence | |

## Décisions qui attendent le directeur

1. Un fin contour sur les bulles reçues si elles se fondent dans le fond clair (contraste 1,14:1) ?
2. Le canal du Studio dans la nouvelle présentation (risque sur le mode focus) ?
3. Ajouter `scenarios_image_candidat.sql` à `.github/workflows/ci.yml` (zone interdite aux agents) ?

## Corrections non bloquantes demandées par le directeur

| Date | Demande | Statut |
| :--- | :--- | :--- |
| — | (aucune reçue depuis la prise de poste du 16/11 au soir) | |

## Journal du pilote

- 16/11, soir : prise de poste ; présentation à l'agent de #551 ; passation lue ; checklist ouverte.
