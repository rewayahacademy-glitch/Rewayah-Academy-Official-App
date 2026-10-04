# DASH-ADM-ECHUS : verdict REFUSEE

## Verdict
**REFUSEE**, à cause d'un défaut majeur : l'état du filtre ne suit pas l'adresse. Le reste du lot est propre :
- la définition `accesEchu` est identique au compteur SQL de la migration 0015 (`provisional_active`, `access_until` non nul et `access_until < now()`, sur le même ensemble `deleted_at is null` que `comptes_admin()`) ;
- les jetons sont respectés et aucun libellé nouveau n'est introduit (`t.admin.tableau.comptes`, « Accès échus », est réutilisé) ;
- la pastille est absente quand il n'y a aucun échu, et elle n'est jamais grisée ;
- dans la tuile, Incidents reste un rapport et seule la moitié « Accès échus » devient un lien ;
- les tests tombent bien sur l'ancien code.

## Périmètre et commandes
Périmètre : `f6ac3658..origin/corrections/c2-adm-echus`, soit 2 commits (76f994b5, 7e7a41be). Fichiers lib touchés : service_comptes.dart, app_router.dart, routes.dart, comptes_page.dart, tableau_de_bord_page.dart, tuiles_compteur.dart. Tests touchés : comptes_test.dart et tableau_de_bord_test.dart.

| Contrôle | Tête | Base |
|---|---|---|
| dart analyze --fatal-infos | 0 problème | - |
| verifier_revue | 1627 | 1627, diff vide |
| verifier_jetons | 39 | 39 |
| comptes_test + tableau_de_bord_test | +59, tout passe | - |
| rtl_echelle, admin_coque, grille_bento, cartes_collees | +122, tout passe | - |

Contre-épreuves :
- tableau et tuile d'origine : 4 échecs ;
- filtre neutralisé : 2 échecs ;
- `accesEchu` sans la condition provisoire : 3 échecs.

## Défauts
1. **Majeur**, `lib/features/admin_comptes/comptes_page.dart:57`. `late bool _echus = widget.echusSeulement` n'est lu qu'à la création du State, et il n'y a pas de `didUpdateWidget`. Or go_router 18.0.1 clé la page sur le chemin sans la requête (`match.dart:231`). Sur un GoRouter réel, de `?filtre=echus` vers l'adresse sans filtre, l'écran reste filtré : je l'ai prouvé par un test jetable, qui a échoué. Le cas se produit en vrai avec l'entrée « Comptes » de la navigation admin (`admin_domaine.dart:210`).
   - Correction : recaler `_echus` dans `didUpdateWidget` quand `echusSeulement` change, et ajouter un test de non-régression sur un GoRouter réel.
2. **Mineur**, `comptes_page.dart:219-229`. « Tous 3 » et « Accès échus 2 » sont retenues ensemble pour 2 lignes affichées, et « Tous » ne relâche pas le filtre des échus. Visible sur les captures 390, 1440 et 320 x2.
3. **Mineur**, `app_router.dart:930-935`. Le câblage réel de `?filtre=echus` n'est pas testé : le test du tableau duplique la lecture de la requête dans sa propre route.
4. **Mineur**. Relâcher la pastille ne met pas l'adresse à jour : elle garde `?filtre=echus`.

## Captures vues
Les 6 PNG du lot ont été ouverts : tableau et comptes, en 390 clair, 1440 clair et 320 x2 sombre. Aucun mot coupé dans le texte nouveau, aucun chevauchement, aucun élément collé, et les libellés de la tuile restent lisibles à 200 %. Seul point visuel : la double sélection Tous / Accès échus (défaut 2).

## Pour accepter
- Corriger le défaut 1 (`didUpdateWidget`) et le prouver par un test sur un GoRouter réel qui échoue sur 7e7a41be.
- De préférence, régler aussi le défaut 2. Deux options : sortir « Accès échus » de la rangée à choix unique, ou faire relâcher les échus par « Tous ».
- Les défauts 3 et 4 peuvent rester en réserves.

Aucun branchement serveur dans ce lot, rien à consigner côté serveur.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

Le refus tient, et son défaut majeur est réel et reproductible. Vérification faite dans un worktree détaché sur origin/corrections/c2-adm-echus (7e7a41be), retiré ensuite.

1) Défaut majeur : le filtre ne suit pas l'adresse.
- Ce que dit le code : dans lib/features/admin_comptes/comptes_page.dart:57, `late bool _echus = widget.echusSeulement;` n'est lu qu'une fois, à la création, et le fichier n'a aucun `didUpdateWidget` (vérifié par grep).
- Pourquoi l'écran garde son ancien état : dans go_router 18.0.1 (pubspec.lock), match.dart:231 donne à la page la clé `ValueKey<String>(newMatchedPath)`, qui ne tient compte que du chemin, pas de `?filtre=`. Passer de `?filtre=echus` à l'adresse sans filtre garde donc le même State.
- Où ça se voit : l'entrée « Comptes » de la navigation admin (admin_domaine.dart:210) et tableau_de_bord_page.dart:154 ouvrent toutes deux `Routes.adminPersonnesComptes` sans filtre.
- Reproduction : test jetable avec hoteRoutant (vrai GoRouter), départ sur `/c?filtre=echus`, puis `GoRouter.of(...).go('/c')`. L'attente `find.textContaining('Encore'), findsWidgets` échoue à la ligne 351.
- Contre-épreuve : avec un `didUpdateWidget` qui recale `_echus` ajouté dans comptes_page.dart, ce même test passe (+1). Le défaut vient donc bien de l'absence de ce recalage.

2) Défauts mineurs, confirmés à la lecture du code sans test dédié :
- La pastille « Tous » appelle seulement `onEtat(null)` (lignes 205-209), tandis que la pastille des échus a son propre état `retenue: echus` (lignes 223-229). Les deux peuvent donc être retenues en même temps, et « Tous » ne relâche pas le filtre des échus.
- `onEchus` ne fait qu'un `setState` : l'adresse garde `?filtre=echus` après qu'on a relâché le filtre.
- Aucun test n'utilise `adminPersonnesComptesEchus` ni `filtre=echus` avec routeurProvider. Le câblage dans app_router.dart:930-935 n'est donc couvert par aucun test.

Je n'ai trouvé aucun défaut que le premier relecteur aurait manqué et qui changerait le verdict, et aucun de ses défauts n'est infondé. Verdict REFUSEE confirmé. Avant d'accepter le lot, il faut au minimum un `didUpdateWidget` dans comptes_page.dart et un test de non-régression sur un vrai GoRouter.

Commandes lancées : flutter pub get, dart run slang, puis flutter test --concurrency=2 test/features/comptes_test.dart --plain-name JETABLE (échec sur le code du lot, réussite avec le correctif). Fichiers restaurés avec git checkout, puis git worktree remove --force.

