# P2-07 - Mode démonstration tuteur : entrée et preuves

Branche `ui/tuteur-v1-demo` (worktree `C:\RA\lot-demo`), session B-2026-09-25-coord, 25/09.

## Entrée « Essayer la démonstration »

- `lib/features/demo/racine_demonstrable.dart` : `RacineDemonstrable` (racine de l'application réelle dans `main.dart`) et `EntreeDemonstration`.
- Hors production, la racine fournit un lanceur (`lanceurDemoProvider`) ; un geste sur l'entrée remplace la portée des providers par celle de la démonstration (`surchargesDemoTuteur`) et coiffe l'application du repère « Démonstration ».
- En production (`ENVIRONNEMENT` contenant « prod », ou vide), aucun lanceur : l'entrée ne rend rien et la bascule n'existe pas. `surchargesDemoTuteur` lève toujours une `StateError` en production.
- L'entrée est posée sur `/bienvenue` (sous « J'ai déjà un compte ») et sous la carte de `/connexion`.
- `?demo=tuteur` reste une seconde porte (démarrage direct en démonstration).
- Aucune modification de `lib/core/theme`, `pubspec.yaml`, `supabase/`, `.github/`.

## Tests

`test/features/demo/entree_demonstration_test.dart` :
- hors production : l'entrée est visible, un geste ouvre la démonstration, puis Foyer, Historique, Compte, Accueil sont parcourus avec le repère visible sur chaque page, sans exception ;
- en production : aucune entrée, aucun repère ;
- sans lanceur : l'entrée ne rend rien ;
- 4 tests de capture (sautés sans `CAPTURE_DIR`).

## Captures

`captures/` : `demo_{entree,accueil,foyer,historique,compte}_{390x844,1440x900}_{light,dark}.png` (20 fichiers).

## Limites connues

- Le repère est un `Banner` d'angle (jetons `tertiary`/`onTertiary`) : sur les captures il reste discret dans l'angle haut ; à revoir si le directeur veut un repère plus lisible.
- Les actions encore adossées à Supabase (appairage, auth, parcours_offres, réglages enfant, avatar) et les ports capacités « Indisponible » ne sont pas simulés : dans les tests, les services avatar/réseau sont ceux de l'application ; seul le stockage des préférences et l'horloge sont remplacés en test.
- Contrôle visuel sur l'aperçu déployé (`?demo=tuteur`) non fait (pas de déploiement dans ce périmètre).
