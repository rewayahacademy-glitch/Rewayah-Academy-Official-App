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

## Demande LT-6 (25/09) : codes de nature et de statut des mouvements (DB-FIN-02)

S07/S08 traduisent `natureServeur` et `statutServeur` depuis une liste FERMÉE (`libelleNature`, `libelleStatut` dans `lib/features/compte/mouvements_page.dart`). Aujourd'hui seuls les codes de la démonstration y figurent (`demo_recharge`, `demo_consommation`, `demo_remise_seance`, `demo_confirme`) ; tout autre code se dit « Mouvement » (nature) ou n'est pas affiché (statut), jamais brut. Besoin : la liste réelle des codes `nature` et `statut` de `wallet_entries` que DB-FIN-02 rendra, avec leur libellé validé, pour compléter la table sans rien inventer.
## Demande LT-7 (25/09) : devise de la quantité d'une offre de recharge (DB-FIN-03)

`OffreRecharge` porte `prixMineur` + `devise` (prix) et `quantiteMineure` (solde obtenu, distinct du prix, F4), mais **aucune devise pour la quantité**. S04 (`lib/features/compte/recharge_page.dart`, `_OffresProfil`) écrit donc provisoirement la quantité dans la devise de l'offre (commentaire `ponytail:`). Besoin : que DB-FIN-03 rende l'unité/devise du solde de chaque offre (ou confirme qu'elle est toujours celle du prix), pour afficher la quantité sans rien supposer.
## Demande LT-11 (25/09) : ouvrir les réglages de l'app et prendre une photo

1. **Scanner, caméra refusée** : aucun paquet présent n'ouvre les réglages de l'application (`permission_handler`/`openAppSettings`, `app_settings` absents ; `url_launcher` seulement transitif dans `pubspec.lock`, non déclaré). Le bouton « Ouvrir les réglages » n'est donc PAS ajouté ; la phrase actuelle (`appairage…refuseeDurablementPhrase`) renvoie aux réglages. Besoin : accord pour une dépendance (`app_settings` ou `permission_handler`), puis le bouton dans l'état « caméra refusée durablement » de `lib/features/appareils` (scanner).
2. **Fiche élève, « Prendre une photo »** : `file_picker` (seul sélecteur présent) n'ouvre pas l'appareil photo ; l'option est visible mais indisponible, raison dite (`ficheEleve.informations.sourcePrendreIndisponible`). Besoin : accord pour `image_picker` (+ `NSCameraUsageDescription` iOS, permission caméra Android déjà là pour le scanner à vérifier), puis rendre l'option disponible dans `lib/features/foyer/photo_eleve.dart` (`_demanderSource`).