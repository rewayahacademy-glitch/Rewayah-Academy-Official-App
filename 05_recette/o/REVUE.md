# Lot O (Observation) : revue adversariale

Revue du coordinateur B (session B-2026-09-25-coord), 25/09 08 h 22-08 h 45. Cible : `C:\RA\lot-o`, diff `origin/ui/tuteur-v1...HEAD` (24 fichiers, +6884/-240, jusqu'au commit `cb66783`).

## Verifications effectuees

- **Fichiers interdits** : `git diff --stat origin/ui/tuteur-v1...HEAD -- supabase .github vercel.json pubspec.yaml assets/fonts lib/core/theme lib/core/coran lib/core/tc_coran lib/features/tc_mushaf dart_define.json` -> vide. Aucun fichier interdit touche sur l'ensemble des 3 sous-paquets.
- **Tests, reexecutes independamment** (`flutter-verrou.ps1`, hors des chiffres deja fournis par le rapport) : `flutter test test/teaching_core/g/fin_visite_test.dart test/teaching_core/g/salle_observation_test.dart test/teaching_core/g/entree_explication_test.dart` -> `+67 : All tests passed!` en 8 s. Les trois suites tapent reellement les boutons cites (Observer la seance, Observer maintenant, Agrandir/Reduire, Quitter + confirmer, Retour a la classe, Voir mes observations, retour systeme) : confirme par lecture des fichiers, pas seulement par le nom des tests.
- **Commit de reprise `cb66783`** ("validation du wip 9bfbb6a... sans changement de code") : `git diff --stat 9bfbb6a cb66783` -> vide. L'affirmation d'honnete dans le rapport (aucun code ajoute, seulement controle) est exacte.
- **Coupure en production** : `Env.observationTuteurReelleActive` (dans `lib/core/config/env.dart`, fichier hors lot O, deja en place) force l'interrupteur a faux hors `developpement` par liste d'autorisation (pas d'exclusion) ; les trois sous-paquets ne l'ont pas touche et le lisent seulement via `observationTuteurReelleProvider`. Le mandat "Observation pas encore ouverte" en production est donc bien garanti au niveau plateforme, non par une convention locale au lot.
- **Decompte et visites (2 x 2 min, visite ecourtee consommee)** : `moteur_visite_observation.dart`, `compteur_visite.dart`, `explication_premiere_visite.dart` lisent les chiffres depuis la politique effective / le budget serveur (jamais en dur, teste : "3 visites de 1 min 30 s" passe dans `entree_explication_test.dart`). Le conseil "visite ecourtee consommee" est present dans `explication_premiere_visite.dart` (`e.ecourtee`) et documente dans `entree_observation_page.dart` (confirmation de sortie). La salle et le bandeau ne remettent jamais le decompte a zero en reconnexion (teste : "le decompte continue sans remise a zero").
- **Definition de fait (a/b/c)** : (a) atteignabilite verifiee par le rapport via `graphe_imports.ps1` a chaque sous-paquet ; (b) le test `entree_observation_navigation_test.dart` part de la vraie coquille (`lib/main.dart`) et tape Accueil -> Assister -> explication/salle -> fin -> Voir mes observations, confirme par lecture du fichier ; (c) `main.dart.js` servi reste explicitement laisse au coordinateur, non revendique a tort.
- **Fidelite aux planches M2-M5/D1** : le rapport liste des ecarts assumes (typographie de l'en-tete, icones manquantes d'`AppIcons`, disque retour au lieu du chevron, support vide car aucun support partage n'existe dans le produit, bandeau plein largeur au lieu de la pastille "Visite n/N") plutot que de les taire ; chacun est rattache a une demande (O-4, O-9 a O-11) ou a une decision du directeur (bandeau). Aucun ecart trouve en lisant les fichiers qui ne soit pas deja consigne.
- **Honnetete generale** : le rapport distingue clairement "teste en simulation" de "verifie reellement : rien (aucun appareil, aucun Supabase)" a chaque sous-paquet ; aucune ligne ne pretend a une verification sur appareil ou en production reelle. Les chiffres de tests annonces (+15/+280 sous-paquet 1, +277~43/+21 sous-paquet 2, +307~5 sous-paquet 3) sont coherents avec le nombre de fichiers de test livres et avec le sondage independant ci-dessus.

## Constat

Aucun ecart non consigne, aucun fichier interdit, aucune affirmation invalidee par sondage independant. Decompte du volume, visites (2 x 2 min), coupure en production, honnetete du rapport, definition de fait (a/b/c) et fidelite aux planches (ecarts assumes et rattaches a une demande) : conformes.

**Verdict : lot O conforme, RAS.**

Ligne LO-R : fait, verifie_par = B-2026-09-25-coord.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
