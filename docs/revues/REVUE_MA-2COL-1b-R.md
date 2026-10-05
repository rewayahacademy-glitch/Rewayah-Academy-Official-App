# Revue adverse MA-2COL-1b : le bloc asynchrone n'est plus recréé quand la page franchit le seuil des deux colonnes

**Branche** : `origin/corrections/c2-ma-2col-b` @ `1dcf66e4`
**Méthode** : lecture seule, dans un worktree jetable détaché, retiré à la fin. Rien n'a été poussé.
**Verdict** : **ACCEPTÉE**

## 1. La demande
Demande : quand la largeur ou le facteur de texte franchit le seuil des deux colonnes, le `BlocAsynchrone` de l'Accueil Mode Accessibilité ne doit pas être recréé. Il faut un test qui le prouve et une contre-épreuve.

## 2. Le correctif (lu dans le code)
`lib/features/accueil_eleve/accueil_accessibilite.dart`, fonction `_composer` : le `if (deuxColonnes) return haut;` a disparu. Il reste une seule `Column` :
- `haut` est toujours le premier enfant ;
- `Ecart.vSection` et `coranEtAide` ne s'ajoutent qu'en une colonne.

Le `BlocAsynchrone` garde donc la même place et le même type sous le `LayoutBuilder`, et son élément est réutilisé.

Le rendu ne change pas :
- en une colonne, l'arbre est strictement le même qu'avant ;
- en deux colonnes, le bloc était déjà dans le flux vertical de `PageShell`. L'envelopper dans une `Column` d'un seul enfant ne change pas ses contraintes de largeur.

Pour placer le Coran et l'aide, le bloc garde son propre mécanisme (`aCote`, `piedEchec`), qui n'a pas changé.

La correction suit la piste proposée par la revue MA-2COL-1 (« garder une Column dans les deux cas »). Le diff ne contient aucun libellé nouveau, aucun jeton, aucune couleur ni aucune lecture de rôle.

## 3. Les tests, vérifiés
Groupe « Franchir le seuil ne recree pas le bloc (MA-2COL-1b) », trois tests :
1. **Largeur 390 → 1440 → 390**, réessais épuisés : « Réessayer » ne revient pas, la phrase « réessais épuisés » reste, et `identical(tester.state(bloc), avant)` tient.
2. **Facteur de texte 1 → 2 → 1 à 1440**, via un `ValueNotifier`, sans remonter l'application. Le test vérifie aussi que le seuil est vraiment franchi (une colonne à 200 %).
3. **Chargement en cours** : le seuil est franchi à mi-attente. La tentative est déclarée perdue à l'échéance d'origine, ce qui montre que la minuterie n'a pas été relancée. Le State est le même.

Ces tests vérifient ce que l'utilisateur voit (« Réessayer » absent, squelette parti à l'échéance) et aussi l'identité du State. Ils ne se contentent pas d'un compte de widgets.

## 4. Mutations faites par le relecteur
| Mutation | Résultat |
| :--- | :--- |
| Ancien `_composer` remis tel quel (`git show HEAD~1`) | les 3 tests du groupe échouent (`+9 -3`) |
| Mutation maison : `Column` gardée, mais un `SizedBox.shrink()` placé avant `haut` en deux colonnes (le bloc change de rang) | les 3 tests échouent |
| Code du lot | 12 tests sur 12 verts, et 61 sur 61 avec accueil_ma_prod_test |

La contre-épreuve que le rédacteur a archivée (`contre_epreuve.log.txt`) donne les mêmes résultats que les miennes.

## 5. Contrôles
- `dart analyze --fatal-infos` : aucun problème.
- `dart format` sur les 2 fichiers : rien à reformater.
- `verifier_revue` : 1573 violations, autant qu'avant le lot (mesuré sur `HEAD~1`).
- `verifier_jetons` : 39 violations, inchangé ; le diff n'ajoute aucun jeton.
- Les 17 fichiers de test qui citent `AccueilAccessibilite`, `accueil_accessibilite`, `accessibilite_demo` ou `BlocAsynchrone` couvrent les autres appelants du composant : 368 réussis, 101 sautés (captures et golden), 0 échec.
- `test/router` : 299 réussis.
- Tous les lancements de tests ont utilisé `--concurrency=2`. Je n'ai lancé ni pkill ni killall.
- Le script de capture n'a pas été laissé dans `test/capture` : il est archivé en `.txt`.

## 6. Captures ouvertes
- `ma_2col_b_erreur_epuisee_1_390_rtl_sombre.png` : une colonne. L'erreur affiche la phrase des réessais épuisés et aucun bouton grisé. Le Coran et l'aide sont dessous.
- `ma_2col_b_erreur_epuisee_2_1440_rtl_sombre.png` : même état en deux colonnes ; le bouton « Réessayer » n'est pas revenu.
- `ma_2col_b_erreur_epuisee_3_1440x2_ltr_clair.png` : facteur de texte x2, une colonne. L'état est gardé et aucun mot n'est coupé.
- `ma_2col_b_contenu_2_1440_ltr_clair.png` : deux colonnes rétablies (« Avant le prochain cours » à côté de « Lire le Coran » et de l'aide), sans changement par rapport à MA-2COL-1.

Aucune capture n'a été refaite à 320 px x2 pour ce lot. C'est justifié : le rendu en une colonne est le même arbre qu'avant, et les tests « Aucun mot coupé » à 320 x2, en LTR et en RTL, passent. L'Interface guidée ne s'applique pas ici : l'écran est déjà l'Accueil Mode Accessibilité.

## 7. Réserves restantes (antérieures, hors lot, inchangées)
- Coupure entre deux mots de « Cours dans 3 h 28 » à 320 x2 (`tc_horloge`).
- RTL testé avec un texte français au lieu de la locale arabe.

## 8. Besoin côté serveur
Aucun.

## Conclusion
La demande est entièrement remplie. Les trois tests prouvent le correctif, les deux mutations les font échouer, et aucune régression n'apparaît. **ACCEPTÉE.**
