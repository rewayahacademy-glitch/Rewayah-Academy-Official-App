# Demandes du lot O (observation)

## O-INT-1 (25/09, INT-O suite, session B-2026-09-25-coord) : 5 echecs neufs sur `entree_observation_navigation_test.dart` apres integration a la base

- **Fichier test** : `test/teaching_core/g/entree_observation_navigation_test.dart`.
- **Constat** : en isolation sur `ui/tuteur-v1-o` (05_recette/o/REVUE.md, e45963e) la suite complete etait verte (+2313 ~284, 0 echec). Apres fusion locale de `e45963e` dans `ui/tuteur-v1` (merge `b817b7f`, aucun fichier hors perimetre du lot O touche par la fusion elle-meme), la suite complete sous verrou (`04_phase0/integration_lotO_tests.log`) donne `+2670 ~568 -7`, dont **5 nouveaux** echecs tous dans ce fichier :
  - `telephone : Assister, l'explication, Pas maintenant, retour a l'accueil`
  - `telephone : Assister, Observer maintenant, la salle, Agrandir, Quitter et sa confirmation`
  - `telephone : fin de visite, « Voir mes observations » ouvre l'Historique, segment Observations`
  - `bureau : Assister, l'explication, Observer maintenant, la visite`
  - `le disque retour de l'explication ramene aussi a l'accueil`
- **Erreur** : `StateError: Bad state: No element` dans `WidgetController.ensureVisible` (`_presser`, ligne ~198 du test) — le bouton attendu n'est pas trouve dans l'arbre apres navigation depuis la vraie coquille (`lib/main.dart`). Cause probable : interaction entre les routes/widgets d'un ou plusieurs autres lots deja integres (A, C, E) et l'entree d'observation du lot O — a diagnostiquer (ecran different rendu a cette route, ou callback de navigation non declenche dans le contexte complet). Non reproduit en isolation, donc pas une regression du code du lot O lui-meme mais de la combinaison.
- **Non lie** : les 2 autres echecs de la suite (`appareil_partage_test.dart`, `emetteur_qr_test.dart`) sont la regression **B-5 deja connue** (cf. `P2-02`, route perimee `/tuteur/foyer`), hors perimetre COORD, pas nouveaux ici.
- **Preuve** : `C:\RA\pilotage\04_phase0\integration_lotO_tests.log` (recherche `[E]` pour les 7 echecs).
- **Bloquant pour** : le push de `origin/ui/tuteur-v1` (INT-O). Pas corrige faute de temps (limite 35 min) — necessite de rejouer le test en isolant l'interaction avec la navigation reelle (main.dart) pour identifier quel autre lot masque le bouton attendu.
