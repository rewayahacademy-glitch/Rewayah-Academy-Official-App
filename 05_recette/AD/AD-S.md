# AD-S : coque admin, corrections de revue (26/09/2026)

Branche `ui/admin-v1`, worktree `D:\RA_TUTEUR\admin`. Commits : `d3cb857` (coque AD-S) et `ab1101c` (« admin(AD-S): corrections de revue »). Les deux sont poussés (`5028dac..ab1101c`). Pas de PR, pas de `main`.

## Ce qui a changé (ab1101c)

- **Rail 80 (majeur)** : le rail n'affiche plus que les icônes (`NavigationRailLabelType.none`). Le libellé complet passe en info-bulle (`Tooltip`, hors sémantique) et reste dans la sémantique de la destination. Aucun libellé n'est coupé et aucun libellé court n'a été inventé. La largeur de 80 est gardée.
- **Repère Démonstration (majeur)** : `lib/features/demo/repere_demonstration.dart` (composant antérieur à AD-S). Le style part maintenant de `textTheme.labelSmall`, pour la famille de police. Un `TextStyle` nu dessinait des carrés. Autres réglages : taille 9, graisse w600, interlettrage 0, hauteur 1. Les couleurs ne changent pas. Le mot « Démonstration » est lisible en entier sur les 8 captures, et la bande ne touche plus le bouton profil à 768.
- **Pied (majeur)** : commentaire corrigé. L'écart est soumis au directeur (voir plus bas). Aucune clé n'a été créée.
- **Tests (mineurs)** : dans `test/features/admin_coque_test.dart` :
  - nouveau test à 1440 : il tape « Recherche » depuis la vraie coque, saisit « Sécurité et audit », valide et vérifie la route ;
  - le test Retour atteint Personnes en tapant l'entrée de la barre 288 (il n'utilise plus `routeur.go`) ;
  - le test Accueil vérifie que le titre du dossier ouvert commence par le prénom de la 2e ligne, que celui du 1er est absent et qu'un seul `DEMO-Dxx` est affiché ;
  - le test du rail vérifie les 7 libellés invisibles, la sémantique et le tap par info-bulle.
- **Taille d'icône (mineur)** : aucun jeton de taille d'icône n'existe dans `lib/core/theme`. `AppSpacing.xxl` est laissé tel quel et noté.

## Chiffres (dernier passage, après toutes les corrections)

- `flutter analyze --fatal-infos` sur les 5 fichiers lib et test touchés : **No issues found**.
- `flutter test` sur admin_coque, admin_shell, test/router, test/features/demo, dossiers_admin_demo, dossiers_admin, page_shell et coque_admin_capture : **+341 ~11, All tests passed**. Les 11 tests sautés sont des captures, sautées sans CAPTURE_DIR.
- Captures `coque_admin_capture_test.dart` avec CAPTURE_DIR : **+7, All tests passed**.
- Frontière : `git diff --stat 5028dac..HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme` est **vide**.

## Captures (refaites et ouvertes) : `captures/AD-S/`

- coque_admin_dossiers_390x844@3_light.png / _dark.png
- coque_admin_dossiers_768x1024@1_light.png / _dark.png : rail avec icônes seules
- coque_admin_dossiers_1440x900@1_light.png / _dark.png
- coque_admin_tiroir_390x844@3_light.png / _dark.png

## Écarts soumis au directeur

1. **Rail en icônes seules** (libellé en info-bulle et en sémantique) plutôt que des libellés coupés. Autre possibilité : des libellés courts, mais il faudrait des clés i18n que le directeur fournit.
2. **Repère Démonstration** : le correctif touche un composant partagé antérieur à AD-S (police du thème, taille 9 au lieu de 10). En sombre, la bande `tertiary` est claire et le texte petit : il reste lisible, et le thème n'est pas modifié. Question Q-S8 en suspens : garder topEnd, passer en topStart ou le mettre dans l'en-tête.
3. **Pied** : « A · Administrateur · Administration » (clé existante `t.compte.roles.admin`) au lieu de « AD · Admin · Administration » (02A, relevé AD-3R l.25 et l.99). Ajouter une clé « Admin » ? (Q-S4)
4. **Bouton thème absent sous 600** : la barre mobile porte seulement Menu, Recherche et compte. Faut-il ajouter BasculeTheme dans le tiroir ou la barre mobile ?
5. **Fond de l'entrée active** : `washAccent` lilas et icône pleine violette, contre un gris neutre sur 02A. Le thème est figé (K-37). La graisse w600 est appliquée et vérifiée par admin_shell_test. (Q-S10)
6. **Taille d'icône** : le jeton `AppSpacing.xxl` sert de taille d'icône faute de jeton dédié. Faut-il créer un jeton de taille d'icône ?
7. Les questions Q-S1 à Q-S10 du concepteur restent ouvertes (défauts appliqués).
8. **Hors portée de la coque** : les boutons de décision de Dossiers sont en pleine largeur sur ordinateur (contrat B), à traiter dans le lot 02A.
