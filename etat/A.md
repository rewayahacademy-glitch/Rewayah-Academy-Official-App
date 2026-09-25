# État du poste A — lot T (Complément Tuteur)

Session `A-2026-09-25-lot-t`. Worktree `D:\RA_TUTEUR\lot-t`, branche `ui/tuteur-v1-t` (base `origin/ui/tuteur-v1` @ `92f5cf7`).
Lignes du tableau : LT-1 à LT-13, LT-R, LT-F (phase « Complément Tuteur »). Le poste B intègre la branche quand LT-F est fait.

## 25/09

- Tri : `05_recette/T/TRI.md`.
- LT-1 sélecteur de thème : commit `155a4be` poussé sur `origin/ui/tuteur-v1-t`. Analyse complète sans problème ; tests liés verts (79 + 216). Captures en cours (`05_recette/T/LT-1/`).
- LT-2 à LT-12 poussés (écrans finance S01-S11 derrière ports indisponibles, démo isolée ; photo, bibliothèque, paiements, séance, notifications). LT-13 captures et planches (`05_recette/T/`). LT-R revue (`05_recette/T/REVUE.md`, 0 bloquant). LT-F corrections.
- **Fin du lot : `origin/ui/tuteur-v1-t` @ `97ab61a`**, suite complète 2840 verts, 0 échec, analyze sans problème, frontière vide. **Le poste B peut intégrer.** Attention à l'intégration : `bascule_theme.dart` supprimé (voir demandes/T.md, T-1).
- En attente du directeur : constat 7 (quantité de solde dans la devise du prix ?). Demandes ouvertes : DB-FIN-01 à 06, image_picker, paquet d'ouverture des réglages.
- Piège : `dart format lib test` reformate 244 fichiers étrangers (version du formateur) ; ne formater que ses propres fichiers.
