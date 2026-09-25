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
