# Messagerie : checklist du pilote

**Mise à jour : 16/11/2026, 19 h 45 UTC.**

Pilote : session `session_0163Kjrx8uX1pRbk4RhE7Yuz` (nuit du 16 au 17/11). Il succède au pilote de la
passation `MESSAGERIE-HANDOFF-2026-11-16.md`, puis à la session `session_0163KjrvfAPWhND7VanbMLHL`
(ouverte à 19 h 18, archivée à 19 h 23), dont cette page reprend la checklist (#560).
La carte du chantier reste `MESSAGERIE-ETAT-ET-PLAN-2026-11-16.md`.

Statuts : `à faire` ; `en cours` ; `PR` (ouverte, pas fusionnée) ; `en prod` (fusionné, déployé, pas vu
par le directeur) ; `en prod (vu)` (vu par le directeur en production : le seul « fait »).

## Point du matin (dix lignes au plus)

_Rempli au matin._

## Faux, bloqué ou non prouvé (à lire d'abord)

- La messagerie est grise depuis #512, la croix du volet a disparu (#540), le champ de saisie
  s'arrondit en cercle : corrections dans la PR #551, **pas fusionnée**, CI en cours sur `667a9543`.
- L'agent de #551 est marqué « déconnecté », son contexte est à environ 734 000 sur 1 000 000 :
  il ne prendra pas d'autre lot.
- Le plafond de quatre agents est atteint (trois au Pilote Équipe, un ici) : **NOUVEAU-FILS ne peut
  pas partir** avant qu'une place se libère.
- #538, #540, #546 sont en production mais **pas vus** par le directeur.
- Le plantage à l'ouverture d'une conversation depuis un profil n'est **pas reproduit**.
- Erreurs de l'ordre de prise de poste, constatées : le fichier `PASSATION-MESSAGERIE-2026-11-16.md`
  n'existe pas (la passation s'appelle `MESSAGERIE-HANDOFF-2026-11-16.md`) ; l'adresse du Pilote Équipe
  donnée par la passation (`session_0163KjrudJVgfH6zMjadp2bb`) diffère de celle reçue ce soir
  (`session_0163KjrvqR38dL9HhgktqAdg`, retenue).

## En cours

| Lot | Qui | Statut | Prochaine étape |
| :--- | :--- | :--- | :--- |
| MESSAGERIE-COULEURS #551 | agent `session_0163KjrvV6fGAftwzWig2qU9` | PR, CI en cours | l'agent fusionne `main`, relance `dart run slang` deux fois, pousse ; le pilote relit les captures avant/après (téléphone et ordinateur, clair et sombre, ce qui change ailleurs), lit la CI, prévient le Pilote Équipe (`lib/core`, `assets/i18n`), fusionne |
| Cette checklist #560 | pilote | PR | fusion quand la CI est verte |

## À lancer

| # | Lot | Condition | Détail |
| :--- | :--- | :--- | :--- |
| 1 | NOUVEAU-FILS | après #551 et une place d'agent libre | badge « Nouveau » (`lib/core/widgets/badge_nouveau.dart`), « Nouveau · aucun message » pour une conversation vide, filtre « Nouveaux » ; règle serveur : moins de 7 jours et aucune ligne `com_lectures` d'un membre de l'équipe ; migration `202611295xxxxx` au-delà de `20261129500000` (déjà pris), vérifiée sur `origin/main` ; session neuve |
| 2 | NOUVELLE-VERSION | après NOUVEAU-FILS | bandeau « Nouvelle version disponible » qui lit `version.json` ; jamais de rechargement pendant un brouillon ou un envoi |
| 3 | Canal du Studio dans la nouvelle présentation | décision du directeur | d'abord un emplacement d'en-tête au fil plein écran ; risque sur le mode focus |
| 4 | Bouton « i » emporté par la barre repliée (Messages, ordinateur) | lot à part | relevé par l'agent de #551, hors de #551 |
| 5 | `scenarios_fac_f_relances_suspension.sql` indépendant de l'heure | sans urgence | échoue le lundi 7-8 h UTC |
| 6 | Recette du directeur en production : #538, #540, #546, puis #551 | après fusion de #551 | liste d'essais, une par une, page humaine |

## Corrections non bloquantes demandées par le directeur

| Date | Demande | Statut |
| :--- | :--- | :--- |
| 16/11 | Le lecteur vocal dans sa propre bulle : contraste à revoir | à faire, à l'ouverture des vocaux |
| 16/11 | « Enregistrer l'image » exige la règle CORS sur le `GET` | à vérifier dans Cloudflare |
| 16/11 | Test local `images_messagerie_test` (glisser vers le bas) qui échoue en local, passe en CI | cause inconnue |

## Pour le directeur au réveil

1. Un fin contour sur les bulles reçues si, après #551, elles se fondent dans le fond clair
   (contraste 1,14:1) ?
2. Le canal du Studio dans la nouvelle présentation, au risque du mode focus ?
3. Ajouter `scenarios_image_candidat.sql` à `.github/workflows/ci.yml` (zone interdite aux agents) ?
4. Le plantage depuis un profil : au prochain essai, noter l'heure exacte et faire une capture.

## Journal du pilote

- 16/11, 19 h 18 : prise de poste de `session_0163KjrvfAPWhND7VanbMLHL` ; checklist ouverte (#560) ;
  session archivée à 19 h 23.
- 16/11, 19 h 40 : prise de poste de `session_0163Kjrx8uX1pRbk4RhE7Yuz` ; lectures faites ; agent de
  #551 contacté ; Pilote Équipe contacté (plafond d'agents, fichiers partagés) ; checklist renommée
  `MESSAGERIE-CHECKLIST.md`.
