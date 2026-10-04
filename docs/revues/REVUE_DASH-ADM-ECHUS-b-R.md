## Verdict : ACCEPTEE_AVEC_RESERVES (DASH-ADM-ECHUS-b)

Le défaut majeur est levé et les trois mineurs aussi. J'ai refait la preuve d'origine et chaque nouveau test échoue quand on retire la correction qu'il couvre. Il ne reste que des réserves mineures : la matrice de captures est incomplète, et deux défauts de rendu sont antérieurs au lot.

### Contexte
- **Branche revue :** `origin/corrections/c2-adm-echus-b`, tête 00653305 (vérifiée avec `git rev-parse`).
- **Base :** 7e7a41be, soit `corrections/c2-adm-echus`.
- **Rapport traité :** `REVUE_DASH-ADM-ECHUS-R.md`, sur `origin/revues/2026-10-04-b061fd81`.
- **Fichiers lib modifiés :** uniquement `lib/features/admin_comptes/comptes_page.dart`.
- **Tests :** `test/features/comptes_test.dart` et `test/router/support_routeur.dart`. Ce dernier reçoit un paramètre `surcharges`, qui est additif.
- **Captures :** 8 PNG et un script archivé.
- Le lot ne touche ni supabase/, ni .github/, ni pubspec, ni le thème, et n'ajoute aucun branchement serveur.

Le travail s'est fait dans un worktree détaché jetable `scratchpad/rv-ADM-ECHUS`. Il était propre à la fin et je l'ai retiré avec `git worktree remove --force` puis `prune`. Je n'ai rien poussé.

### Commandes et résultats
- **Préparation :** `flutter pub get` puis `dart run slang`.
- **Tests ciblés :** `flutter test --concurrency=2 test/features/comptes_test.dart` donne **+15, tout passe**.
- **Analyse :** `dart analyze --fatal-infos` ne trouve **aucun problème**.
- **`verifier_jetons` :** **39 violations**, comme sur la base. Aucune ne porte sur comptes_page.
- **`verifier_revue` :** **1627 violations**, comme sur la base. Aucune ne porte sur comptes_page.
- **`test/router` :** **+277, tout passe**.
- **`test/features` et `test/accessibilite` :** **+2863, 2062 sautés, 0 échec**.

### Défaut majeur 1 : le filtre ne suivait pas l'adresse
**Ce qui est corrigé.** Un `didUpdateWidget` recale `_echus` quand `echusSeulement` change. Quand le filtre passe à vrai, il remet aussi `_etat` à null.

**Preuve d'origine refaite.** Le test « le filtre suit l adresse sur un vrai GoRouter » reprend exactement le test jetable du premier relecteur :
- il passe par `hoteRoutant` ;
- il part de `/c?filtre=echus` ;
- il fait `go('/c')` et attend « Encore ».

Il passe sur la tête. Le test « le vrai routeur ouvre Comptes filtre sur les echus » fait le même aller-retour sur `routeurProvider` réel, avec une session admin.

**Mutations.**
- **Fichier remis comme sur 7e7a41be :** 4 échecs, un sur chacun des 4 nouveaux tests.
- **`didUpdateWidget` neutralisé (`if (false)`) :** 2 échecs, sur les deux tests de routeur.

**Défaut levé.**

### Défauts mineurs
**2. Une seule pastille retenue.**
- Dans le code, « Tous » n'est retenue que si `etat == null && !echus`, et `_choisir` rend les choix exclusifs.
- Avec l'ancienne condition `retenue: etat == null` remise, le test échoue.
- Les captures le confirment : en filtré, seule « Accès échus 2 » est allumée ; après Tous, seule « Tous 3 » l'est.
- **Levé.**

**3. Câblage de `?filtre=echus` dans le routeur.**
- J'ai remplacé la lecture de la requête dans `app_router.dart` par `false` : le test du vrai routeur échoue.
- **Levé.**

**4. L'adresse après avoir relâché la pastille.**
- `_ecrireAdresse` passe par `GoRouter.maybeOf` et un `go` qui garde le chemin et les autres paramètres de la requête.
- Avec l'appel commenté, le test « relacher ou reprendre » échoue.
- **Levé.**

### Essais adverses en plus (test jetable, retiré ensuite)
Le test part de `/c?filtre=echus` :
1. un tap sur la pastille d'un état donne l'adresse `/c`, avec cette seule pastille retenue ;
2. reprendre les échus donne `?filtre=echus`, avec « Accès échus » seule retenue ;
3. puis `go('/c')` laisse « Tous » seule retenue ;
4. un deuxième `go('/c')` sur la même adresse ne change rien.

Il passe (+1).

Toutes les navigations vers Comptes passent par `go` (tableau de bord lignes 154 et 278, `admin_domaine` ligne 210). Aucun `push` ne pourrait donc être écrasé par le `go` de `_ecrireAdresse`. Je n'ai trouvé aucune régression.

### Captures
J'ai ouvert les 8 PNG (390 clair LTR et RTL, 320 x2 sombre, 1440 clair, chacune en état filtré puis après Tous). Aucun mot coupé, aucun chevauchement, aucun élément collé, et aucun bouton grisé. En RTL, l'ordre des pastilles et des onglets est bien inversé. À 320 x2, les pastilles passent à la ligne proprement et la sous-navigation devient un menu déroulant.

### Réserves (mineures)
1. **Matrice de captures incomplète.** Il manque 390 et 1440 en sombre, RTL en sombre, et 320 x2 en RTL. Le correctif ne change que l'état de sélection de composants déjà validés en DASH-ADM-ECHUS, donc le risque est faible.
2. **Identifiant coupé au trait d'union** (« GUARDIAN- / AD-000001 ») à 1440 et à 320 x2. C'est le rendu de `DataCollection`, antérieur au lot.
3. **Point final de l'intro française en tête de ligne en RTL.** C'est l'effet bidi d'un texte latin, antérieur au lot.

### Serveur
Aucun besoin serveur.

### Verdict
**ACCEPTEE_AVEC_RESERVES.** Aucun défaut majeur ne subsiste, et les réserves ne portent que sur la couverture des captures et sur des rendus antérieurs au lot.