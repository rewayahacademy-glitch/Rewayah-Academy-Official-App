# Décision du directeur : parcours d'entrée, cartes et accords (17/10/2026)

Source : commentaire du directeur sur la synthèse de la nuit, 17/10/2026 06:09 UTC. Demande la plus récente : elle prévaut sur `DESIGN-GOV-2026-09-26.md`, `03_DESIGN_SYSTEM_ET_UX.md` et la règle BOUTONS-GRISES-1 là où elle les contredit. Audit qui la détaille : `docs/audit-final/AUDIT-ENTREE-2026-10-17.md`.

## Suppressions autorisées

- L'ancienne classe `lib/features/tc_classe_live` (route `/tc/classe`). Une seule salle reste : `/salle`.
- L'ancien système de matching individuel par disponibilités.
- Les pages qui défilent avant la connexion. L'app n'est pas sur les stores pour le moment : la page d'accueil du site suffit.

## Site public

Le site public est rapatrié dans le dépôt pour être lisible par tous les agents. Il sera complété visuellement plus tard.

## Cartes, dans toute l'app

- Toute la carte est cliquable, pas un petit repère sur le côté.
- Sur web et grand écran, des cartes propres au grand écran, en disposition bento. Jamais les cartes du mobile étirées.
- Jamais plusieurs cartes de même taille et de même style sur une même page. On varie : un choix en carré, un autre en rectangle horizontal ou vertical selon la situation.
- Chaque choix est expliqué, avec un exemple quand il aide à comprendre avant de choisir.
- Les cartes de choix sont illustrées.

## Questions de l'onboarding

- Une même information n'est demandée qu'une fois et toujours de la même façon (l'âge : jamais une fois en tranche et une fois en chiffres).

## Accords et consentements

- Une seule page qui défile. Chaque texte à accepter a sa case.
- Un seul bouton « Suivant », inactif tant que toutes les cases ne sont pas cochées, comme dans les autres apps. Cette règle remplace BOUTONS-GRISES-1 pour les accords.
- On ne peut pas entrer dans l'app sans avoir consenti, et l'app ne renvoie jamais en arrière pour cocher après coup.
