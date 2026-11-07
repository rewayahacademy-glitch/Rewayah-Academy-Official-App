# UX_REVIEW LINK-CHOIX (22 o), 06/11/2026

Lot : la page de paiement de la famille. Ordre du directeur (06/11, 21:45 UTC, transmis par le
garde-cap) : « je t'ai pas dit paiement sans link, mais de donner le choix aux users ». Transfert
de zone : le garde-cap a confié la page de paiement Flutter (`lib/core/finance`) à ce lot pour la
soirée, point (c) de WEB-BUREAU compris (sortie en haut, Échap, page d'ordinateur).

## Ce qui ne se règle pas dans la forme actuelle

| Règle | Source | Date de lecture | Conclusion | Modification |
|---|---|---|---|---|
| Link ne se règle, dans une session Checkout intégrée, que par `wallet_options.link.display` : `auto` (montré) ou `never` (caché) | SDK officiel `stripe` 22.6.2, `Checkout.SessionCreateParams.WalletOptions.Link.display` | 06/11/2026 | Aucun réglage du type « montrer Link sans qu'il s'ouvre de lui-même » | Session en `ui_mode: elements` |
| Link reconnaît la personne par son adresse, son téléphone ou un cookie, puis envoie un code | docs.stripe.com/payments/link, « Link authentication » | 06/11/2026 | Dans le formulaire intégré, le code peut partir avant tout choix | Aucune adresse donnée à Stripe à l'ouverture ; Link en bouton |
| Dans Checkout, Link ne se coupe qu'au tableau de bord | docs.stripe.com/payments/link/checkout-link, « Disable » | 06/11/2026 | Le réglage du tableau de bord est un geste du directeur, non présumé fait | Rien côté code |
| Express Checkout Element et Payment Element sur la même session Checkout ; une seule confirmation passe | docs.stripe.com/payments/elements/build-a-payment-page | 06/11/2026 | Link et les portefeuilles en boutons en haut, la carte dessous, « Payer » | Montés par `initCheckoutElementsSdk` |
| L'adresse est exigée pour confirmer une session `elements` | docs.stripe.com/payments/payment-element/migration-ewcs (« You must provide a valid customer email ») | 06/11/2026 | L'adresse du compte, passée à `actions.confirm` seulement | Rendue par `recharge-payer`, jamais à l'ouverture |

## Disposition

| Règle | Source | Conclusion | Modification |
|---|---|---|---|
| Un contenu tiers (paiement) prend la colonne de la page, sortie en haut et Échap | `DEFINITION-PAGE-ORDINATEUR-2026-11-06.md` B9 (branche `claude/web-bureau`) | Sortie en haut, collée au haut de la page quand elle défile ; Échap sort | Barre haute collante ; écoute de la touche Échap |
| Barre latérale permanente du rôle à partir de 1200 | même définition, B1 | La page couvre la zone de contenu de la route, jamais la barre latérale | Cadre calé sur le navigateur de la route |
| Réorganiser, ne pas agrandir ; deux colonnes au plus | Bible 05 §2 ; même définition B4 | Deux colonnes à partir de 1200 : texte à gauche, formulaire à droite ; une colonne en dessous | Grille CSS au seuil `AppGabarit.seuilDesktop` |
| Aucun bouton plein au-delà de 640 px sur ordinateur | même définition B5 | « Payer » prend la largeur de la colonne du formulaire, environ 620 px à 1440 | Rien de plus |
| Une seule barre de défilement, celle de la page | `DECISION-DEFILEMENT-2026-11-01.md` | La page de paiement défile d'elle-même ; aucun cadre de hauteur fixe | Inchangé |

## Non prouvé

- Que le vrai Link n'envoie aucun code avant un clic dans l'élément de paiement : aucune clé de test
  Stripe dans l'environnement, et la création d'un bac à sable demande d'ouvrir un compte au nom
  d'une adresse. Le banc ne prouve que notre page (aucune adresse avant la confirmation).
- Le rendu réel de Stripe : au banc, le faux Stripe.js peint des cadres marqués « faux ».
- Le temps réel d'affichage (le directeur a vu près d'une minute) : seul notre temps est mesuré
  au banc, Stripe.js servi avec un délai simulé.
