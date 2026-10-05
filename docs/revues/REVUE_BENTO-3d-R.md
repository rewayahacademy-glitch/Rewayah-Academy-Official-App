# Revue adverse BENTO-3d : bascule côte à côte du squelette de l'accueil adulte

**Verdict : ACCEPTÉE**

- Branche relue : `origin/corrections/c2-bento3d` @ `cbe9b090`, relue dans un worktree jetable détaché, retiré à la fin.
- Rien n'a été poussé.

## La demande

BENTO-3c-R avait laissé une réserve : le seuil côte à côte du squelette de chargement de l'accueil adulte n'était gardé par aucun test. Ce seuil est `largeurMinCarteClasse × math.max(1, echelle)`. La demande était d'ajouter un test de bascule et de faire une contre-épreuve.

## Ce qui a changé (diff `HEAD~1..HEAD`)

- **Un seul fichier de code modifié :** `test/features/accueil_adulte/accueil_adulte_page_test.dart` (+82 lignes, plus un import `skeleton.dart`).
- **Documentation ajoutée :** 8 PNG et le script de capture archivé, dans `docs/current/captures/BENTO-3d/`.
- **Rien touché ailleurs :** aucun fichier de `lib/`, `supabase/`, `.github/`, `pubspec.yaml`, ni thème, ni i18n. La commande `git diff --name-only` ne renvoie aucun fichier hors `test/` et `docs/`.
- **Trailer du commit :** il est exact. L'identifiant de modèle n'apparaît que dans la ligne Co-Authored-By.

## Le test

Le groupe « squelette : bascule cote a cote (BENTO-3d) » monte `SqueletteAccueilAdulte` seul, dans une place de largeur fixée, en ltr puis en rtl. Il couvre six cas, donc 12 tests :

| Largeur | Texte | Attendu |
| ---: | ---: | :--- |
| 735 px | x1 | empilées |
| 736 px | x1 | côte à côte |
| 735 px | x0,85 | empilées |
| 1120 px | x2 | empilées |
| 1455 px | x2 | empilées |
| 1456 px | x2 | côte à côte |

Ce qui est vérifié :
- **Côte à côte :** même `top`, ordre selon le sens de lecture, largeurs de moitié.
- **Empilé :** pleine largeur.
- **Tous les cas :** « Mon parcours » est sous les deux premières tuiles.
- **Contexte :** 4 colonnes, seuil de 736 px à texte x1, 5 blocs.

Les assertions sont pertinentes : elles portent sur la géométrie réelle, pas sur une valeur recopiée.

## Contre-épreuve refaite par le relecteur (`lib/features/accueil_adulte/accueil_adulte_page.dart`, l.620-622)

Chaque mutation a été appliquée, le groupe relancé, puis le fichier restauré.

| Mutation | Résultat |
| :--- | :--- |
| M1 : sans le facteur d'échelle | +8 −4, tuée |
| M2 : `>` au lieu de `>=` | +8 −4, tuée |
| M3 : sans le plancher `max(1, …)` | +10 −2, tuée (cas x0,85) |
| M4 : toujours côte à côte | +4 −8, tuée |
| M5 : jamais côte à côte | +8 −4, tuée |
| M6 : moitié sans l'écart de la grille | +6 −6, tuée |

Toutes les mutations sont tuées. Cela confirme le compte rendu du rédacteur, et va au-delà avec M4, M5 et M6.

## Contrôles

- **`dart analyze --fatal-infos` :** aucun problème.
- **`verifier_jetons` :** 39 violations, le chiffre de référence attendu.
- **`verifier_revue` :** 1573 violations avec le lot, et 1573 sans lui (test remis à sa version d'avant). Aucune nouvelle violation.
- **`dart format` :** aucun changement.
- **`flutter test --concurrency=2 test/features/accueil_adulte/` :** 92 réussis, 0 échec.
- **`test/accessibilite` et `test/core/widgets` :** 490 réussis. Ils servent de garde-fou, même si aucun code applicatif n'a été modifié, donc aucun autre appelant ne peut régresser.

## Captures ouvertes

J'ai ouvert 4 des 8 PNG : 735 x1 sombre, 736 x1 clair, 1120 x2 sombre, 1456 x2 clair.

- À 735 et 1120 px, les tuiles sont empilées, en pleine largeur.
- À 736 et 1456 px, elles sont côte à côte, en moitiés égales.
- Il n'y a aucun débordement.
- Le rendu en sombre et en clair est cohérent.

## Réserve, information seulement

Les captures sont limitées au squelette seul, en LTR, aux quatre largeurs de bascule. Il n'y en a ni dans la coquille réelle, ni à 320, 390 ou 1440, ni en RTL. Le squelette ne contient aucun texte, et l'ordre en RTL est garanti par le test : cela ne bloque pas la fusion.

## Statut

Présent dans le code et testé localement. Rien n'est déployé.
