# Revue indépendante du lot E (LE-R)

Revue adversariale de `origin/ui/tuteur-v1...origin/ui/tuteur-v1-e` (44 fichiers,
+10630/-1083) contre `05_recette/e/RAPPORT.md` et les maquettes V3/V4/V8 D2-D4.
Worktree `C:\RA\lot-e`, branche recréée depuis `origin/ui/tuteur-v1-e`
(commits identiques à ceux du rapport : `65cbcee`…`d33aca4`).

## Méthode

- Frontière fichiers interdits : `git diff --stat` de la base vers la branche
  sur `supabase .github vercel.json web/vercel.json .firebaserc pubspec.yaml
  lib/core/theme lib/core/router lib/core/widgets lib/core/coran
  lib/core/tc_coran lib/features/tc_mushaf dart_define.json assets/fonts` :
  **vide** — confirmé, aucun fichier gelé touché.
- `windows/flutter/*` : absent du diff — confirmé.
- STUB restants (`grep "STUB PHASE 0 : propriete du lot E"`) : **0** — confirmé.
- `lib/features/compte/compte_page.dart` (écrans des autres rôles) : absent du
  diff — confirmé non modifié.
- Définition de fait (bouton tapé) : les 5 fichiers de test de parcours
  (`compte_tuteur_test.dart`, `historique_test.dart`,
  `notifications_test.dart`, `admin_observations_test.dart`,
  `journal_admin_test.dart`) naviguent via les helpers `toucher` /
  `toucherDestination` (`test/features/historique/support_historique.dart:285-301`,
  motif repris dans les autres `support_*.dart`), qui appellent réellement
  `tester.tap(...)` puis `stabiliser`. Le faible nombre d'occurrences
  littérales de `tester.tap(` dans `historique_test.dart` (2) s'explique par
  cette indirection (34 appels `toucher`/`toucherDestination` dans ce seul
  fichier) — pas un raccourci qui contournerait le tap réel. Vérifié aussi sur
  les autres fichiers (9, 4, 8, 5 taps directs + helpers). Aucun test de
  parcours ne navigue par un `context.go`/`push` direct sans passer par un tap
  d'un élément de l'UI.
- Honnêteté : recherche de `catch (_) {}` silencieux et de textes de « succès »
  fabriqués dans les fichiers modifiés du lot — aucun trouvé. Les écrans à
  dépendance backend non branchée (identité/accès du compte, historique des
  observations, historique admin des observations, notifications, paiements,
  aide) affichent un message d'indisponibilité explicite en production, sans
  bouton mort ni faux succès, conformément au rapport et à la charte.
- Fidélité aux planches : le rapport documente 5 (compte) + 3 (historique) +
  1 (notifications/admin) planches maquette|rendu avec corrections
  postérieures listées (filet recouvert, valeur non calée, titre coupé,
  débordement à 390, colonnes de durée trop étroites, etc.) — cohérent avec
  les fichiers de capture présents (`05_recette/e/captures/`, ~71 PNG) et les
  images de maquette recadrées présentes dans `05_recette/e/maquettes/`.
  Comparaison pixel par pixel des 9 planches non refaite dans le temps imparti
  (35 min) ; aucune incohérence trouvée entre le rapport et les fichiers
  présents sur le disque.
- Doublons de fonction : la carte des fonctions du rapport revendique
  « aucune fonction rendue deux fois » ; spot-check code — déconnexion à un
  seul endroit (pied de `compte_tuteur_page.dart`), `informations-legales`
  non dupliquée, `CarteRubriques` est un composant local assumé et motivé
  par la demande E-2 (doublon temporaire déclaré, pas caché) en attendant
  l'extension de `GroupeReglages` gelé — accepté.

## Bloquants

Aucun.

## Majeurs

Aucun.

## Mineurs

1. `05_recette/e/RAPPORT.md` — le rapport indique un worktree source
   `D:\RA_TUTEUR\lot-e` (poste A, ancienne machine) ; la branche relue ici
   provient uniquement de `origin/ui/tuteur-v1-e`, donc la correspondance
   commit-à-commit avec le rapport n'a pu être vérifiée que par les hash
   (identiques), pas par une relecture des logs de test cités
   (`e1_tests_compte.log` etc., non présents dans `05_recette/e/`) — à
   demander si une preuve brute est nécessaire au-delà des hash et des
   captures.
2. `test/features/historique/historique_test.dart:52-56` — le helper
   `_filtrer` local dans ce fichier fait doublon fonctionnel avec
   `choisirFiltre` de `support_historique.dart:304` (mêmes étapes : ouvrir le
   menu, taper l'entrée). Sans impact sur le produit (code de test
   uniquement) ; simplification possible côté lot E si retouché.

## Verdict

Lot E conforme à la définition de fait et honnête sur les dépendances non
branchées. Aucun fichier interdit touché, aucun STUB restant. Les 9 demandes
au coordinateur (E-1 à E-10, hors E-6/E-8/E-10 informatives) restent
nécessaires pour brancher identité/accès du compte, historique des
observations (tuteur et admin) en production — c'est le comportement attendu
tant que COORD n'a pas branché les ports, pas un défaut du lot.

## Suite donnee (LE-F, poste B coordinateur, 25/09)

- Bloquants / majeurs : aucun, rien a corriger.
- Fusion de origin/ui/tuteur-v1 dans ui/tuteur-v1-e (conflit strings.g.dart : union fr.i18n.json + dart run slang).
- Consequence de la fusion : LigneRubrique.icone devenu nullable (meneur, demande B-1) ; carte_rubriques.dart rend le meneur sinon l'icone.
- compte_page.dart : le reglage du profil enfant pousse Routes.ficheElevePour(enfant.id) (fiche du Foyer) au lieu de Routes.tuteurReglages ; test compte_test.dart qui TAPE la ligne et arrive sur la fiche.
- Mineur 2 (doublon _filtrer, code de test) : laisse en l'etat. Mineur 1 : note, sans action.
- analyze --fatal-infos vert ; suite complete verte (2334 tests, log LE-F_suite.log). Aucune capture touchee (pas de changement visuel).
- Commit bc6b0b3 pousse sur origin/ui/tuteur-v1-e.
