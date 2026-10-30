# Lots des Boucles 2 à 4, plan du pilote du 30/10/2026

Ordre du directeur du 30/10 : « c'est à toi de faire tout le nécessaire pour que, le jour où je
décide de tester, tout marche ». Ce plan vient d'un relevé de `main` (5fac37a5e) et de la
production en lecture seule, fait le 30/10. Deux agents au plus ; chacun enchaîne sa file ; le
pilote fusionne, applique les migrations et tient ce tableau à jour.

## Ce que le relevé a trouvé de faux (à dire d'abord)

- **B2.1 ne peut pas marcher aujourd'hui.** L'import des inscrits actuels range les élèves dans
  `private.preinscription_*` : ni compte, ni foyer, ni matricule. Ils n'apparaissent pas dans
  Comptes et ne se placent pas en classe.
- **B2.4** (tableau des définitions) et **B3.3** (liste des 568) n'ont aucun écran.
- **B2.5** : la vue de la paie par la direction renvoie `CapaciteIndisponible`.
- **PR 50** : 267 commits de retard, 20 conflits ; `prevenir_par_courriel` (en production)
  enverrait le lien d'inscription à toutes les réponses, pas aux seuls retenus.
- **Communauté** : écrans présents, aucune table, aucune RPC ; en production l'écran est mort.
- **Stripe** : fonctions `recharge-payer` et `stripe-webhook` déployées (lu le 30/10) ; la
  présence des secrets est inconnue (illisible pour le pilote).

## Files des agents

| Ordre | Agent 1 (seul sur l'i18n) | Agent 2 |
|---|---|---|
| 1 | TRANSPARENCE : `politique_commerciale_famille`, page des prix en pourcentages, « Bibliothèque » dans la salle | RELIQUATS-B2 : R9, D5 (adulte élève), D2 (e-mail d'enseignant validé), R3 ; retirer Communauté du menu tant qu'elle n'est pas branchée |
| 2 | B3 : écran « Réponses importées » (les 568 : tri, filtre, sélection, « retenu ») sur `lister_formulaires_importes` ; invitation nominative d'un retenu ; `prevenir_par_courriel` limité aux retenus | B2.1 : les pré-inscriptions deviennent foyers, comptes de tuteur, profils d'élèves et matricules, par une fonction serveur appelée à la confirmation de l'import (idempotente, essai à blanc inchangé) |
| 3 | B2.3 : « Séance tenue sur Meet : marquer présents » en un geste pour l'enseignant | B2.4 : les cinq définitions (actif, à jour, régulier, à surveiller, ponctuel), l'enseignant de chaque élève et l'emploi du temps, calculés par le serveur ; écran de la direction |
| 4 | Communauté : tables, RLS, RPC, adaptateurs ; règle « pas en cours » côté serveur ; mesure agrégée des heures d'affluence | B2.5 : relevé mensuel de la paie par enseignant pour la direction ; B4 : émission des factures le 1er par cron, commentaire faux de `main.dart:341` |

## Décisions du pilote prises pour ce plan

- **PR 50** : on ne la rebase pas. Ce dont la Boucle 3 a besoin est refait sur `main` (file 1,
  ordre 2), et la PR 50 sera fermée ensuite, après inventaire de ce qu'elle seule contient.
- **Paiement** : paiement mensuel par la famille sur Stripe Checkout, avec les relances
  existantes (J-7, J-3, J-1). Pas d'abonnement automatique pour l'instant.
- **Après le paiement**, la direction place l'élève dans sa classe (geste existant). Le
  placement automatique attend que les vraies familles paient en ligne.

## Ce qui ne se code pas (le jour du test du directeur)

- Les deux CSV du classeur des inscrits actuels, importés par le super-admin (double
  authentification).
- La liste réelle classe, enseignant, élèves, jour, heure ; la validation de chaque enseignant.
- Le tri des candidats (jugement du directeur).
- Stripe : compte vérifié, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, adresse du webhook
  déclarée chez Stripe.
