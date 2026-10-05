Les dépôts avaient été posés en *, mais le fichier .md n'a pas été écrit (consigne). Voici le rapport complet.

# Revue adverse de PAGESHELL-200-1 (branche corrections/c2-pageshell, tête 35356e24)

**Verdict : ACCEPTEE_AVEC_RESERVES**

La demande principale (réserve 1 d'OBS-COUPE-1b) est remplie et prouvée : sur téléphone à 200 %, le corps non défilant de PageShell reçoit la hauteur réellement disponible sous la tête, et la barre de la salle d'observation est entière dans la zone sûre au premier affichage. Je n'ai trouvé aucune régression sur les autres écrans en coquille. Le mineur (barre large à 300 %) est nettement amélioré mais pas entièrement résorbé quand l'écran est bas. Les réserves ci-dessous ne bloquent pas la fusion.

Le relecteur a travaillé dans un worktree jetable détaché sur origin/corrections/c2-pageshell, en lecture seule. Il n'a rien poussé, et le worktree a été retiré.

## 1. Ce qui a été vérifié dans le code

- **`lib/core/widgets/page_shell.dart`**
  - Dans `_Bascule`, la branche « tête défilante » avec un corps non défilant passe désormais par `_TeteEtCorps` / `_RenduTeteEtCorps`. Ce rendu à deux enfants donne au corps `hauteurVue − tête`.
  - Si ce reste est inférieur à la moitié de la vue, le corps reçoit toute la vue, comme avant. C'est le repli AD-11.
  - La page défilante et la branche « tête fixe » sont inchangées.
  - Le test de collisions (hit-test), la peinture et les dimensions intrinsèques sont implémentés.
- **`barre_commandes_observation.dart`** : la nouvelle fonction `_barreLargeCoupe` fait passer la barre large en deux rangées quand une seule rangée couperait un mot. Aucun libellé n'est ajouté.
- **`panneau_observation_tuteur.dart`** : `_corpsLarge` défile, via un `CustomScrollView`, avec un support d'au moins `_hauteurMinSupport`.
- Règles : aucun jeton, thème, couleur ou secret touché, et aucun fichier interdit (supabase/, .github/, pubspec, Coran).

## 2. Contre-épreuves (mutations) refaites par le relecteur

| Mutation | Résultat |
|---|---|
| `page_shell.dart` remis à la base 3df81930 | 5 échecs dans page_shell_hauteur_corps_test (320/390, LTR/RTL, zone d'action) et 5 dans « barre entière au premier affichage » (320/390 x2 LTR/RTL, 360x800 x2) |
| Repli AD-11 supprimé (`return reste;`) | Le test « vue très basse, tête haute » échoue |
| `barre_commandes_observation.dart` remis à la base | Plus de 60 échecs (barre_observation_large_test et salle) |
| `panneau_observation_tuteur.dart` remis à la base | Environ 10 échecs dans le groupe salle |

Chaque correction est donc nécessaire et couverte par au moins un test.

## 3. Tests, analyse, vérificateurs (refaits)

- `dart analyze --fatal-infos` : aucun problème.
- Tests ciblés `test/widgets/page_shell_hauteur_corps_test.dart` + `test/teaching_core/g/` : +594, ~76 sautés, 0 échec.
- `test/widgets`, `test/core`, `test/router`, `test/features` : +3990, ~2068 sautés, **0 échec**.
- Tous les autres dossiers (hors capture, fixtures, support) : +2122, ~76 sautés, **0 échec**.
- `verifier_jetons` : 39, autant que le compte rendu, et aucune violation dans les fichiers touchés.
- `verifier_revue` : 1606 violations, et aucune dans les fichiers touchés.

## 4. Captures ouvertes

- **390x844 x2, LTR et RTL, après** : la barre est entière (bas vers 794 pour une zone sûre à 810), le support est visible, et aucun mot n'est coupé dans la barre.
- **320x844 x2, avant et après** : avant, le bas de la barre est rogné. Après, la barre est entière.
  - En contrepartie, le support visible tombe à environ 65 points et sa ligne de texte est tranchée par le défilement interne (réserve 3).
- **Barre large de 440 px à 300 %, RTL** : deux rangées, « Son interrompu » coupé entre les mots, « Quitter » en pleine largeur. Correct.
- **Salle 700x900 à 300 %** : la barre tient sur une rangée. « Son reçu » passe sur deux lignes, entre les mots, et « Quitter » est réduit au plancher lisible. Rien n'est coupé.

## 5. Sondes adverses du relecteur (fichiers temporaires, supprimés)

**Largeurs 600 à 900, texte x1.5 à x3, LTR et RTL :**
- **900 de haut** : 96 sur 96 réussis.
- **640 de haut** : 20 échecs, tous à x3 et de 600 à 750 px, avec un débordement de 38 px du panneau. La base en avait 44. C'est la **réserve 1**.

**Paysage téléphone, x1 et x2 :**
- 844x390 et 932x430 sont maintenant corrects (ils échouaient sur la base).
- 667x375 x2 déborde encore de 45 px, comme sur la base. C'est la **réserve 2**.

## 6. Réserves (non bloquantes)

1. Le mineur n'est corrigé qu'à 900 de haut. À 640 de haut et 300 %, de 600 à 750 px, le panneau déborde encore de 38 px.
2. En paysage 667x375 à 200 %, le panneau déborde de 45 px. Le défaut existait déjà.
3. À 320x844 x2, le support visible au premier affichage est très réduit (environ 65 points).
4. Il n'y a aucune capture en sombre, à 1440, en Interface guidée ni en vraie langue arabe. Le risque est faible, car seule la géométrie change.
5. Info : `computeDryLayout` de `_RenduTeteEtCorps` pourrait lever une assertion avec une tête contenant un LayoutBuilder, si un parent demandait une mise en page à blanc. Aucun appelant actuel ne le fait.

## 7. Bilan des statuts

| Statut | Où en est le lot |
|---|---|
| Spécifié | La réserve 1 et le mineur sont décrits dans REVUE_TUILE-TUTEUR-1b_OBS-COUPE-1b-R. |
| Présent dans le code | Oui, sur corrections/c2-pageshell. |
| Testé localement | Oui : suites complètes vertes, mutations confirmées, captures ouvertes. |
| Testé sur staging | Non. |
| Déployé | Non. |
