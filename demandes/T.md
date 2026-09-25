# Demandes du lot T (Complément Tuteur, poste A)

Branche `ui/tuteur-v1-t` (depuis `origin/ui/tuteur-v1` @ `92f5cf7`). Tri : `05_recette/T/TRI.md`.

## T-1 — Suppression de `BasculeTheme` (information, pas de réponse attendue)

- Fichier : `lib/core/widgets/bascule_theme.dart` **supprimé** au commit `155a4be` (LT-1).
- Remplacé par `lib/core/widgets/selecteur_theme.dart` : `SelecteurTheme()` (carte, pilule verticale soleil · lune · système) et `SelecteurTheme.entete()` (pilule horizontale de l'en-tête, tablette et bureau).
- Décision du directeur (25/09) : un seul sélecteur, icônes, « Selon le système » par défaut.
- À l'intégration : toute branche qui importe encore `bascule_theme.dart` doit passer à `selecteur_theme.dart`. Libellés : `t.commun.theme.clair`, `.sombre`, `.systeme` (nouvelle clé).
- Web : le thème est désormais gardé par le `localStorage` du navigateur (`lib/core/preferences/stockage_navigateur*.dart`, `dart:js_interop`, aucune dépendance ajoutée).

## Dépendances serveur à déclarer (lot finance, LT-2)

`DB-FIN-01` lecture des soldes · `-02` mouvements · `-03` devis de recharge · `-04` paiement et attribution · `-05` aperçu des conséquences d'annulation · `-06` annulation d'accès. Détail à LT-2.

## Dépendances finance (LT-2)

Port `PortFinanceFoyer` (`lib/core/capacites/port_finance_foyer.dart`, commit `4c09fd6`), branché par défaut sur `FinanceFoyerIndisponible`. Tables `wallets`, `wallet_entries`, `payouts` en schéma seulement (ADR-003) : aucune RPC, aucune fonction Edge. Montants en unités mineures + code ISO 4217 arrêtés par le serveur ; aucune règle (prix, remise, conséquence) n'est fixée côté Flutter. Libellés `nature`, `statut`, `motif`, `conséquences` : liste de codes à fixer par le serveur, jamais affichés bruts.

- `DB-FIN-01` soldes (S01, S02) : entrée = session du tuteur ; sortie = un solde par profil autorisé (montant mineur ou inconnu, devise, dernière remise liée à une séance), sous-totaux par devise rendus par le serveur, indicateur « total complet », date de lecture.
- `DB-FIN-02` mouvements (S07, S08) : entrée = profil facultatif (puis période, type, pagination à définir) ou identifiant d'écriture ; sortie = écritures autorisées (id, profil, nature, statut, montant signé mineur, devise, date, séance liée éventuelle).
- `DB-FIN-03` offres et devis (S03 à S05) : entrée = profils choisis, puis choix d'offre par profil ; sortie = offres réellement proposées (prix, devise, quantité de solde distincte) puis devis (référence, lignes par profil avec prix, remise et quantité, total à payer, devise, date de validité).
- `DB-FIN-04` paiement et attribution (S05, S06) : entrée = référence de devis + clé d'idempotence ; sortie = référence de paiement, état du paiement, état d'attribution par profil (confirmé, en attente, échoué). Contrat de paiement collectif à confirmer (F4).
- `DB-FIN-05` aperçu d'annulation (S09, S10) : entrée = profils choisis ; sortie = référence d'aperçu et, par profil, éligibilité et motif, date d'effet réelle, conséquences (séances, réservations, solde), solde conservé, possibilité de reprise.
- `DB-FIN-06` annulation d'accès (S11) : entrée = référence d'aperçu + profils + clé d'idempotence ; sortie = issue par profil (confirmée, demande en attente, refusée) et motif.
