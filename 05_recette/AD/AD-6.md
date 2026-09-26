# AD-6 — Revue ADM-02B : corrections de revue

Branche `ui/admin-v1`, worktree `D:\RA_TUTEUR\admin`. Commits AD-6 : `cdc55b0`, `b76d370`, `8192bf8` (corrections), poussés sur `origin/ui/admin-v1`. Ni `main` ni PR. Frontière (supabase, .github, vercel.json, pubspec.yaml, lib/core/theme) : vide.

## Corrections (constats de revue)

- **Bloquant, débordement à 200 % sur 390** : le contrôle de fin de ligne de `GroupeReglages` (« Voir la pièce ») était dans un Row sans être flexible. Il passe maintenant sous le libellé dès 150 % sous 600 de large, dans le composant partagé et sans copie. La boucle de test est rétablie à [1, 2].
- **Bloquant, captures** : le test de capture montait `RewayahApp` (path_provider absent sous runAsync) et écrasait la densité @3. Il monte maintenant `MaterialApp.router` sur le vrai routeur ; à 768, il passe par la route. Résultat : 44 tests verts, 46 PNG.
- **Majeur, production (Q-AD6-1)** : jusqu'à AD-7, la validation est fermée en production (`BlocageRevue.pieceNonConsultable`). Les cases ne sont pas modifiables et le message « Ce dossier n'est pas encore prêt à être validé. » s'affiche. AD-BR-03 est mis à jour. Choix provisoire, à confirmer par le directeur.
- **Majeur, refus en ligne** : quand le motif est ouvert, un seul « Refuser le dossier » reste visible. La dérogation provisoire jusqu'à AD-8 est notée (AD-BR-07).
- **Mineurs** :
  - `libelleVerification` fait correspondre explicitement `validite` ; un identifiant inconnu n'est pas affiché.
  - La carte « Vérifications » est toujours présente, avec les cases inactives quand la pièce est absente ou hors de portée.
  - Après une décision, `actualiserDossiers` invalide les trois caches.
  - Le rôle de lien est porté par `LienFleche(annonceLien)` et `Pressable(lien)`, au lieu d'une enveloppe Semantics.

## Chiffres du dernier passage (sous verrou)

- `flutter analyze --fatal-infos` sur lib/core/capacites, lib/features/demo, lib/core/widgets, lib/features/admin_dossiers, test/features/admin_dossiers, test/core/capacites, les captures AD-5 et AD-6, et test/widgets/composants_partages_test.dart : **No issues found**.
- `flutter test` sur test/features/admin_dossiers, test/core/capacites, test/features/demo, test/widgets/admin_shell_test.dart et les captures AD-5/AD-6 (sans CAPTURE_DIR) : **+85 ~58, All tests passed**.
- Captures AD-6 avec CAPTURE_DIR : **+44, tous verts, 46 PNG** dans `captures\AD-6`.
- Tests des composants partagés touchés (appareils, creneaux, classe_tuteur, catalogue_galerie, composants_partages, composants) : **+177 -1**. Le seul échec, « une rubrique sans icone ni meneur est refusee », existait déjà à HEAD (voir les restes).

## Captures ouvertes

- nominal 1440 sombre ; nominal 390 clair ; nominal 768 clair ;
- prêt (trois cases cochées) 390 sombre ;
- actions à 200 % sur 390 clair ;
- refus non autorisé 1440 clair (carte Vérifications présente, sans case active).

Les autres captures sont vertes au test, mais je ne les ai pas ouvertes.

## Restes (une ligne chacun)

1. Q-AD6-1 : faut-il fermer la validation en production (choix appliqué) ou ouvrir l'aperçu existant dans AppBottomSheet ? À décider par le directeur.
2. Test « une rubrique sans icone ni meneur est refusee » (composants_partages_test.dart:391), déjà rouge avant AD-6 : le contrat de `LigneRubrique` dit « icône ou meneur », mais AD-5 et AD-6 utilisent des lignes sans icône (identité, accords). Il faut décider : remettre l'assert (et donner une icône à ces lignes) ou assouplir le contrat et supprimer le test.
3. À 200 % sur 390, « Terminez les vérifications requises. » est aligné au début alors que les boutons sont alignés à la fin (le lien prend toute la largeur).
4. Le bouton tertiaire inactif « Voir la pièce » garde un contour fort : à comparer à la maquette 02A et 02B.
5. Seuil du repli de contrôle dans `GroupeReglages` : 150 % d'échelle et moins de 600 de large, sans mesurer le contrôle (commentaire ponytail). Un contrôle large pourrait encore déborder sous 150 %.
6. Pas de test qui tape depuis la coque avec l'adaptateur de production pour la validation fermée : le blocage est couvert par le test unitaire de l'adaptateur. Il manque un test de widget, à ajouter.
7. Q-AD6-2 à Q-AD6-8 et les questions déjà ouvertes (Q1, Q2, Q3, Q6, Q9, Q10, Q13, Q17, Q-AD5-1, OfflineBanner) : les défauts restent appliqués.
