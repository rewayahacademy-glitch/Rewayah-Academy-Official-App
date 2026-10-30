# Lots des Boucles 2 à 4, plan du pilote du 30/10/2026

Ordre du directeur du 30/10 : « c'est à toi de faire tout le nécessaire pour que, le jour où je
décide de tester, tout marche ». Ce plan vient d'un relevé de `main` (5fac37a5e) et de la
production en lecture seule, fait le 30/10. Deux agents au plus ; chacun enchaîne sa file ; le
pilote fusionne, applique les migrations et tient ce tableau à jour.

## Ce que le relevé a trouvé de faux (à dire d'abord)

- **B2.1 ne peut pas marcher aujourd'hui.** L'import des inscrits actuels range les élèves dans
  `private.preinscription_*` : ni compte, ni foyer, ni matricule. Ils n'apparaissent pas dans
  Comptes et ne se placent pas en classe.
- **B2.4** (tableau des définitions) et **B3.3** (liste des candidatures) n'ont aucun écran.
- **B2.5** : la vue de la paie par la direction renvoie `CapaciteIndisponible`.
- **PR 50** : 267 commits de retard, 20 conflits ; `prevenir_par_courriel` (en production)
  enverrait le lien d'inscription à toutes les réponses, pas aux seuls retenus.
- **Communauté** : écrans présents, aucune table, aucune RPC ; en production l'écran est mort.
- **Stripe** : fonctions `recharge-payer` et `stripe-webhook` déployées (lu le 30/10) ; la
  présence des secrets est inconnue (illisible pour le pilote).

## Transitions entre lots (consigne du directeur du 30/10)

- **Une session neuve par lot.** Quand un agent a remis sa PR et son bilan, il s'arrête ; le
  pilote archive sa session après la fusion, et le lot suivant part dans une session neuve,
  avec une consigne autonome : le but, les fichiers à lire, la zone (branche, dossiers,
  numéros de migration), ce qui est déjà su (constats du lot précédent), les vérifications,
  et le format du bilan. Le contexte d'un lot ne déborde jamais sur le suivant.
- Toujours deux agents de construction au plus en même temps ; l'i18n à un seul à la fois,
  désigné dans la consigne.
- Le pilote ne lance un lot qui dépend d'un autre qu'après la fusion de celui-ci dans `main`.
- Aucune valeur qui change dans le temps n'est écrite en dur (nombre de candidats, prix,
  pourcentages, dates) : elle est lue en base ou dans un fichier de données versionné.

## Files des agents

| Ordre | Agent 1 (seul sur l'i18n) | Agent 2 |
|---|---|---|
| 0 (prioritaire, après TRANSPARENCE) | **LISTES** : porter sur `main` le socle LISTES-1 et la refonte de Comptes depuis la PR 50 ; toute liste nouvelle ou touchée ensuite l'utilise ; les 30 listes recensées restent la feuille de route | (suite de sa file) |
| 1 | TRANSPARENCE : `politique_commerciale_famille`, page des prix en pourcentages, « Bibliothèque » dans la salle | RELIQUATS-B2 : R9, D5 (adulte élève), D2 (e-mail d'enseignant validé), R3 ; retirer Communauté du menu tant qu'elle n'est pas branchée |
| 2 | **CANDIDATURES** (après LISTES) : porter depuis la PR 50 la liste et la fiche des candidatures, l'import et « Prévenir », puis l'écran « Réponses importées » (toutes les candidatures, nombre jamais écrit en dur : il en arrive chaque jour ; tri, filtre, sélection, « retenu ») sur `lister_formulaires_importes` ; invitation nominative d'un retenu ; `prevenir_par_courriel` limité aux retenus | B2.1 : les pré-inscriptions deviennent foyers, comptes de tuteur, profils d'élèves et matricules, par une fonction serveur appelée à la confirmation de l'import (idempotente, essai à blanc inchangé) |
| 3 | B2.3 : « Séance tenue sur Meet : marquer présents » en un geste pour l'enseignant | B2.4 : les cinq définitions (actif, à jour, régulier, à surveiller, ponctuel), l'enseignant de chaque élève et l'emploi du temps, calculés par le serveur ; écran de la direction |
| 4 | Communauté : tables, RLS, RPC, adaptateurs ; règle « pas en cours » côté serveur ; mesure agrégée des heures d'affluence | B2.5 : relevé mensuel de la paie par enseignant pour la direction ; B4 : émission des factures le 1er par cron, commentaire faux de `main.dart:341` |

## Décisions du pilote prises pour ce plan

- **PR 50 : décision corrigée le 30/10 sur remarque du directeur.** Elle contient seule le lot
  de refonte des listes **LISTES-1** (23/10, `DECISION-LISTES-2026-10-23.md`, socle partagé :
  `DataCollection` dense, `CaseACocher`, `BarreSelection.compacte`, `MenuActions` opaque,
  `RangeeFiltres`, `FiltresActifs`, `PiedDeListe`, pays avec drapeau ; Comptes et Candidatures
  refondues ; inventaire des 30 listes). Rien de cela n'est sur `main`. On ne refait pas ce
  travail : on le **porte sur `main`** en premier, car tous les lots suivants affichent des
  listes (candidatures, tableau de la direction, paie, présences). La PR 50 entière (577
  fichiers) ne se fusionne pas telle quelle : le portage se fait en deux lots, LISTES puis
  CANDIDATURES, puis la PR 50 est fermée.
- **Stripe plutôt qu'un marchand de référence (Creem), avis du pilote demandé par le directeur
  le 30/10** : chez Creem, les « services de toute sorte » sont une catégorie restreinte
  (vérification renforcée), et leur liste d'interdits nomme les services spirituels ; le risque
  d'un compte gelé au démarrage pèse plus que la tenue des taxes. Frais plus élevés, paiement
  au nom de Creem, et Stripe est déjà construit et déployé. Les taxes : avis du comptable, puis
  Stripe Tax si besoin. Creem seulement sur accord écrit de leur support, demandé par le
  directeur.
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
  déclarée chez Stripe. **Le directeur, 30/10 : clés pas encore renseignées.** Tant qu'elles
  manquent, le bouton de paiement doit dire une phrase claire au lieu d'échouer ; le lot B4 le
  vérifie.
