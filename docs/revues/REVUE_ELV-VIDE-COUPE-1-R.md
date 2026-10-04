## Revue adverse ELV-VIDE-COUPE-1 (commit 4f073673, branche corrections/c2-elv-vide)

**Verdict : acceptée avec réserves.** Je n'ai trouvé aucun défaut majeur. Il reste une réserve mineure sur la hiérarchie typographique en Interface guidée.

J'ai travaillé en lecture seule, dans un worktree jetable détaché sur `origin/corrections/c2-elv-vide`. Je l'ai retiré et purgé à la fin, puis j'ai vérifié qu'il ne restait aucune entrée `rv-elv-vide` dans la liste des worktrees.

Tout ce qui suit a été testé localement. Rien n'a été testé sur staging, rien n'est déployé.

### Périmètre du commit
- Fichiers touchés :
  - `lib/core/widgets/empty_state.dart` (+9/-3) ;
  - `test/features/accueil_eleve_test.dart` ;
  - nouveau `test/core/widgets/empty_state_sans_coupure_test.dart` ;
  - 3 PNG et le script `.dart.txt` dans `docs/current/captures/ELV-VIDE-COUPE-1`.
- Aucune zone interdite n'est touchée : ni `main`, ni PR, ni `supabase/`, ni `.github/`, ni `pubspec`, ni thème, ni rendu du Coran.
- Le message de commit est en français et se termine exactement par les deux lignes demandées.
- La correction est faite à la source, dans l'`EmptyState` partagé. Le constat et l'invitation passent de `Text` à `TexteSansCoupure`, le même mécanisme que celui de SettingRow. Le style, le `textAlign: center` et le centrage restent les mêmes.

### Vérifications rejouées

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_jetons` | 39 violations, comme attendu |
| `verifier_revue` | 1627 sur la branche, 1627 avec `empty_state.dart` de la base : égal à la base |
| `dart format` sur les 3 fichiers Dart | 0 modifié |
| Tests ciblés (les 2 fichiers) | 55 réussis |
| Suite `core` | 660 réussis, 0 échec |
| Suite `router` | 277 réussis, 0 échec |
| Suite `widgets` | 270 réussis, 0 échec |
| Autres dossiers (hors capture, fixtures, support) | 1699 réussis, 55 ignorés, 0 échec |
| Suite `features` | 2497 réussis, 2062 ignorés, 0 échec |

Toutes les suites ont tourné avec `--concurrency=2`. Les chiffres sont identiques à ceux du compte rendu.

### Contre-épreuve (mutation)
J'ai remis `empty_state.dart` dans son état de la base `origin/corrections/c2-coran-carte`, puis relancé les deux fichiers de test.
- Résultat : 8 échecs, 4 par fichier, exactement sur les cas 320 px x2 (standard et Interface guidée, LTR et RTL).
- Les messages nomment `aujourd'hui` et `enseignant`.
- Le nouveau test de page, qui s'appuie sur `verifierEcranSansMotCoupe`, détecte donc bien la coupure de l'état vide, que l'ancien contrôle limité à la carte laissait passer.
- J'ai restauré le fichier ensuite : le worktree est revenu propre.

### Tests ajoutés
- **Accueil élève.** Le test couvre maintenant toute la page avec `verifierEcranSansMotCoupe` sur chaque Scaffold.
  - Il vérifie aussi que l'état vide est bien affiché, avec `find.text(aucunCours)`.
  - Il garde les contrôles de la carte Coran.
  - Il tourne en standard et en Interface guidée, à 320 px x2 et 1440 px x1, en LTR et en RTL.
- **Composant partagé.** Le nouveau test couvre :
  - aucun mot coupé à 320 px x2, dans les deux modes et les deux sens ;
  - une échelle qui ne descend pas sous 0,85 ;
  - à l'échelle 1, une échelle de l'appareil égale à 1 et un alignement centré ;
  - à 390 px x2, une échelle gardée à 2.

### Autres appelants (58 fichiers de `lib/` utilisent EmptyState)
- `TexteSansCoupure` garde exactement l'échelle de l'appareil dès que le mot le plus long tient dans la largeur.
- Je l'ai mesuré sur le composant seul, à 320 et 390 px, dans les deux modes : à l'échelle 1, l'échelle reste 1,000. Les tailles restent identiques (22/14 en standard, 28/20 en Interface guidée).
- Toutes les suites passent (`features`, `core`, `widgets`, etc.), et le dépôt ne contient aucun golden.
- À l'échelle 1, je n'ai constaté aucun rendu dégradé. Seule exception théorique : un mot plus large que son conteneur serait réduit, au plus jusqu'à 0,85, au lieu d'être coupé. C'est le comportement voulu.

### Captures (ouvertes toutes les trois)
- `elv_vide_320x2_clair.png` : « Pas de cours / aujourd'hui » s'affiche entier, l'invitation aussi, sans débordement.
- `elv_vide_320x2_enfant.png` : tous les mots sont entiers, y compris « enseignant ». Le titre de l'état vide paraît toutefois aussi petit, voire plus petit, que l'invitation (voir la réserve).
- `elv_vide_320x2_rtl_sombre.png` : le texte est entier et la carte est en miroir. Le point final apparaît en tête (« .prochain »). C'est un effet du texte français rendu en RTL dans le harnais, pas une coupure. Le défaut existait avant ce lot et le compte rendu le signale.
- Le script `elv_vide_capture_test.dart.txt` est présent et cohérent avec les captures. Je l'ai réutilisé pour mes mesures.

### Réserve (mineure)
En Interface guidée à 320 px x2, la largeur utile de l'état vide dans la carte n'est que de 190 px. Chaque `TexteSansCoupure` réduit son texte de son côté :
- le titre, `fs` 28 à l'échelle 1,31, mesure 36,7 px effectifs ;
- l'invitation, `fs` 20 à l'échelle 1,79, mesure 35,7 px effectifs ;
- le titre de la carte Coran mesure 44 px.

La hiérarchie constat > invitation est donc quasi aplatie. Ce n'est ni une coupure ni un débordement, et cela ne bloque pas la demande. Deux pistes pour un lot suivant :
- coordonner les deux échelles, par exemple garder l'échelle de l'invitation au plus égale à celle du titre, ou passer les voisins à `TexteSansCoupure` ;
- revoir la double marge intérieure de l'état vide dans la carte.

En standard, la hiérarchie est conservée : 41,8 px contre 28 px.

### Conclusion
La correction est faite à la source, elle est prouvée par la contre-épreuve, et elle ne change pas le rendu à l'échelle 1 pour les autres appelants. Toutes les vérifications demandées sont vertes. Je l'accepte avec la réserve mineure de hiérarchie en Interface guidée. La fusion dans `main` reste soumise aux contrôles CI, migrations et sécurité.