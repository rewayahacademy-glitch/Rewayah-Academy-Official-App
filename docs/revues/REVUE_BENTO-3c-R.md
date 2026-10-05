# Revue adverse BENTO-3c : `origin/corrections/c2-bento3c` (51b1f98a)

**Verdict : ACCEPTÉE.** Les 7 points de la demande sont remplis, et chacun est prouvé par une mutation tuée. Aucun défaut majeur. Statut du lot : présent dans le code et testé localement, rien de déployé.

J'ai travaillé en lecture seule dans un worktree détaché sur 51b1f98a, retiré ensuite (`git worktree remove`, puis `prune`). Rien n'a été poussé. La base de comparaison est 3df81930 (branche commune).

## Ce qui a changé
- Code : 3 fichiers.
  - `grille_bento.dart` reçoit la constante `largeurMinCarteClasse` (360) et sa doc.
  - `accueil_famille_page.dart` ne la définit plus.
  - `accueil_adulte_page.dart` n'importe plus la page famille.
- Tests : `accueil_adulte_page_test.dart` (+78 lignes) et `aucun_mot_coupe_test.dart` (+161 lignes).
- Captures : 6 PNG et le script archivé en `.txt`.
- Aucun fichier interdit n'est touché : supabase, .github, vercel, pubspec, thème, rendu du Coran, `emplacements_groupe.dart`.
- Les commits sont en français et finissent par les deux lignes de signature exactes. Aucun autre identifiant de modèle.

## Vérification point par point (par mutation)
Pour chaque point, j'ai remis l'ancien comportement dans le code et vérifié que les nouveaux tests échouent.

| Point | Mutation | Résultat |
|---|---|---|
| 1. ORD-2 | M9 : seuil sans `× math.max(1, echelle)` (contenu, l.430) | **Tué** : les 2 tests « 1440 px, texte ×2 », en ltr et en rtl, échouent. Le test exige bien `a.top > s.bottom` et la pleine largeur (grille de 1120 px). |
| 2. ORD-3 | `>` au lieu de `>=` | **Tué** : le cas 864 px, grille de 736 px, côte à côte, échoue. |
| 2. ORD-3 | `largeurMinCarteClasse` = 350 | **Tué** : les cas adulte 863 et 864 échouent, ainsi que le cas famille 863. |
| 3. M8-1 | Ancien critère `{b.top.round()}.length > 1` | **Tué** : les 2 tests « vraie police » (ltr et rtl) et les 2 tests « deux tailles » échouent. Le contexte est vérifié par assertion : au moins 2 boîtes, à des top différents. Style : DMSans, repli NotoSansArabic, 16 px, hauteur 1.3. |
| 4. M8-2 | d1 : intervalle du milieu élargi | **Tué** : le cas « Remplacement » sur exactement 2 lignes échoue. Contexte vérifié : 2 boîtes, et `boites[1].top == boites[0].bottom`. |
| 4. M8-2 | d3 : `milieu = b.top` | **Tué** : même cas. |
| 4. M8-2 | d2 : clause symétrique retirée | **Tué** : le cas du mot en deux tailles (16 et 64 px, ltr et rtl) échoue. La clause est gardée et a maintenant son propre cas, ce que la demande autorisait. |
| 5. M8-3 | c2 : mot découpé au U+2011 | **Tué** : le test qui attend `contains('Classe An‑Nour : An‑Nour')` échoue. |
| 6. m5 | Constante déplacée | La famille et l'adulte lisent bien la constante dans `core/widgets/grille_bento.dart`. `dart analyze --fatal-infos` ne signale rien, et l'adulte n'importe plus la page famille. |
| 7. ORD-1 | Contre-épreuve de la fiche | Elle est corrigée dans le champ « fait » du compte rendu : +14 −16, et « 768 passe encore » est déclaré faux. C'est le même résultat que la revue BENTO-3b-R (« +14 −16 »). C'est acceptable : la fiche n'existait que dans le rapport de l'auteur. |

**Écart vertical de 16 entre bandes (ORD-3).** La demande disait « bascule à texte ×1 **ou** écart de 16 ». La bascule est couverte, avec en plus la vérification de la largeur de la grille et du seuil 736. La piste de l'écart a été écartée avec une justification mesurée. Je n'y vois pas de manque.

## Contrôles
- `dart analyze --fatal-infos` : aucun problème.
- Tests : `flutter test --concurrency=2` sur 25 fichiers, soit tous ceux qui utilisent `GrilleBento`, `largeurMinCarteClasse`, `motsCoupes`, `verifierAucunMotCoupe` ou la page famille. Résultat : **943 réussis, 0 échec**.
- `verifier_jetons` sort en code 1, mais ses 39 violations sont les mêmes avant et après le lot (diff vide).
- `verifier_revue` sort en code 1, avec 1606 violations avant comme après le lot. Rien de nouveau.

## Captures ouvertes
- 864 px clair : séance et « Avant » côte à côte.
- 863 px sombre : empilés, et lisibles.
- 1440 px texte ×2 clair : empilés, grille d'environ 1120 px.
- Je n'ai vu ni débordement ni mot coupé. « Mon espace » et « Ressources de la classe » passent à la ligne entre deux mots, sans couper de mot.
- Le lot ne change pas le rendu (seul le déplacement de la constante touche `lib`). Il n'y avait donc pas lieu de refaire les captures 320 ×2 et 390, ni celles de l'Interface guidée. Le cas rtl à 1440 ×2 est couvert par un test, pas par une capture.

## Remarque hors demande
Dans la même page, le squelette de chargement compare ses moitiés au même seuil (l.611-613), mais aucun test de bascule ne le garde. À prévoir dans un lot suivant ; cela ne bloque pas la fusion.
