# Revue croisée FI-1c-CORR-R : correction des réserves M1 et M2 de FI-1c-R

- **Objet revu** : `docs/revues/FI-1c-CORR.patch` (branche `claude/collaborative-task-tracking-r47ieu`), appliqué par `git am` sur `ui/finance-v1` @ `f58645d1` dans un worktree détaché. Le patch s'applique proprement et donne le commit local `6f581d47`. Il touche 2 fichiers (+164/−34) : `lib/features/demo/finance_demo.dart` et `test/features/finance/finance_demo_test.dart`.
- **Mode** : lecture seule. Rien n'a été poussé, et ni le dépôt distant ni le tableau de suivi n'ont été modifiés. Le worktree a été retiré à la fin.
- **Date** : 4 octobre 2026.

## Verdict

**Acceptée avec réserves.** M1 et M2 sont levés au sens où la revue FI-1c-R les a formulés :

- plus aucun profil payant non financé ne sort en `sansEcheance`, donc plus aucun n'est affiché « Actif » ;
- le revenu et la paie de la vue globale portent sur les mêmes 13 sièges ;
- les deux nouveaux tests échouent sur l'ancien code et passent sur le nouveau.

Le rectificatif sur la fourchette est fondé : le guide V4 §1.5 dit « environ **30 % net** ».

Les réserves ci-dessous sont mineures, sans effet visible aujourd'hui puisqu'aucun écran ne branche ces doubles. Elles sont à porter par les étapes d'écran FI-4 et FI-11a, ou par FI-BR-08.

## Périmètre et commandes (résultats mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `git am FI-1c-CORR.patch` sur `f58645d1` | appliqué sans conflit, commit `6f581d47` |
| `flutter pub get`, `dart run slang`, `build_runner build` | OK (2075 sorties) |
| `dart analyze --fatal-infos` | **No issues found** |
| `flutter test --concurrency=2 test/features/finance` | **31 / 0** (chiffre de l'auteur confirmé) |
| `test/features/finance` + `test/features/compte` + `test/features/foyer/fiche_eleve_test.dart` | **118 / 0** |
| `test/features/admin_finance` + `test/features/finance_recette` | **6 / 0**, 31 ignorés (captures sans `CAPTURE_DIR`) |
| `test/router/navigation_test.dart` (importe la page Accès) | **67 / 0** |
| `grep -rl finance_demo test` | un seul fichier : `finance_demo_test.dart` |
| `dart run tool/verifier_jetons.dart` | 39 violations avec le patch, **39 sur `f58645d1`, listes identiques** |
| `dart run tool/verifier_revue.dart` | 1627 violations avec le patch, **1627 sur `f58645d1`, sorties identiques** |
| **Contre-épreuve** (lib à `HEAD~1`, test du patch) | ne compile pas tel quel, car `finDernierAcces` n'existe pas dans l'ancien code. Une fois cette référence remplacée par la date littérale : **29 verts, 2 échecs**, les deux nouveaux tests. M1 : `Expected expire, Actual sansEcheance`. M2 : `Expected 69000 USD, Actual 14500 USD`. |

Je n'ai pas relancé la suite complète (5356/0 annoncée par l'auteur), parce que d'autres suites Flutter tournaient en même temps.

## Lecture du diff

### M1 : levé

`finance_demo.dart:357-374` dérive maintenant l'état de l'échéance par la règle des écrans, `etatAccesAffiche` (`port_acces_foyer.dart:22`) :

- un profil en essai n'a pas d'échéance (`null`) ;
- un profil avec une période financée prend la fin de cette période ;
- les autres prennent `finDernierAcces`, soit le 30/09/2026 à 23:59 (`:345`), ce qui donne `expire`.

Mesuré par le test : dans les jeux `unARegulariser` et `aucunPaiement`, chaque profil payant non financé est `expire` et `seancesPayantesOuvertes=false`. Les profils financés sont `actif`, avec une fin au 31/10. L'essai est `sansEcheance`.

Les écrans qui lisent cet état :

- `compte/acces_page.dart:64-69` affiche maintenant la pastille « Terminé », au ton alerte, et la légende « Terminé le 30 septembre 2026 » (`:89-91`, `fr.i18n.json:2402-2404`) ;
- `compte_tuteur_page.dart:391-399` affiche « Accès terminé » dès qu'un profil a expiré ;
- `foyer/ligne_membre.dart:86-94` et `foyer/fiche/acces_page.dart:61-76` recalculent à partir de `finAcces` et rendent « expiré ».

Plus aucun « Actif » pour Ibrahim, ni pour Mariam et Ibrahim dans `aucunPaiement`. C'est exactement la première correction que proposait la revue FI-1c-R.

### M2 : levé

`_classesDemo()` (`:455-483`) devient la seule liste des classes. `revenus()` (`:486-504`) et `revenuDemo()` (`:510-520`) la lisent tous les deux :

- revenu : 5×50 + 4×50 + 4×60 = **690 USD** ;
- paie : 56,00 + 51,20 + 36,00 = **143,20 USD** ;
- marge : (69000 − 14320) × 1000 ÷ 69000 = **792 ‰**.

J'ai refait le calcul à la main et il correspond au test (`finance_demo_test.dart:382-407`). Tout est en entiers et en unités mineures, et le calcul vit dans le double de démonstration, jamais dans un widget. `revenuDemo()` n'invente aucune remise de rang (commentaire `:506-509`).

### Rectificatif sur la fourchette : fondé

La source est le guide Finance V4 §1.5 (pilotage `17_finance/V/REWAYAH_FINANCE_FRONTEND_GUIDE_V4_2026-10-02.md:152-168`) : « environ **30 % net** : objectif de pilotage raisonnable ; 35 % performance forte ; 40 % stretch ». Le texte ajoute qu'aucun widget ne doit en faire une sanction.

`docs/current/07` §5 parle d'un « résultat net visé de 2 000 USD … après frais et salaires ». Il ne fixe aucun pourcentage. Une marge calculée sur la seule paie ne peut donc pas être forcée dans 300-400 ‰. Le test qui vérifie la dérivation, plutôt qu'une fourchette, est le bon choix.

### Invariants

- Aucun calcul de référence côté client présenté comme vrai : les calculs restent dans `lib/features/demo/finance_demo.dart`, et les ports réels restent neutres.
- Aucun widget n'est touché.
- Aucune donnée de démonstration n'apparaît hors démonstration : seul le fichier de test importe `finance_demo.dart`.

## Défauts

**Bloquant** : aucun. **Majeur** : aucun.

**Mineurs**

- **m1 : « Marge projetée » de 792 ‰ face à une référence nette de 300 ‰.** `VueGlobaleFinance.margeProjeteePourMille` (`port_finance_direction.dart:84-85`) est documentée comme « La marge projetée » tout court. La précision « marge sur la seule paie, jamais nette » n'existe que dans le commentaire du double (`finance_demo.dart:522-525`). Si FI-11a affiche ce KPI à côté de `margeReferencePourMille` (30 % net, `politique_commerciale.dart:128-131`), elle comparera une marge sur la paie à une marge nette : 79 % paraîtra très au-dessus de l'objectif. C'est l'erreur inverse de l'ancien 1,2 %.
  → Préciser la nature de cette marge dans le contrat, ou dans le libellé de FI-11a, avant de brancher l'écran.
- **m2 : « Terminé » au lieu de « Accès à régulariser ».** Le guide §1.7 (`:237`, `:257`) demande « À régulariser » pour le tuteur. La page Accès du compte dira « Terminé le 30 septembre 2026 ». C'est juste et non trompeur, mais ce n'est pas le libellé du guide, et `EtatAccesAffiche` ne connaît pas cet état.
  → FI-BR-08 / FI-4, comme l'avait déjà signalé la revue FI-1c-R.
- **m3 : date de fin inventée pour `aucunPaiement`.** Dans ce jeu (« Aucun paiement encore : rien n'est financé », `finance_demo.dart:46`), Mariam et Ibrahim reçoivent quand même « fin de la dernière période 30/09 » (`:345`, `:360`). Ils n'ont jamais eu de période. L'écran dira « Terminé le 30 septembre » pour un accès qui n'a peut-être jamais existé. Le commentaire invoque « ou celle de son essai (FIN4-13) » sans que le jeu porte d'essai.
  → Acceptable pour la démonstration, mais à documenter dans le jeu.
- **m4 : l'essai en cours est affiché « Actif », « Sans date de fin ».** Aïcha dans `unEnEssai` (`:358-359`) a `seancesPayantesOuvertes=false` et un essai à 1/2. La revue FI-1c-R la citait parmi les cas M1. Le correctif la garde volontairement en `sansEcheance`, et `compte/acces_page.dart:64-69` montre alors « Actif », au ton succès, avec « Sans date de fin ». Pour un essai limité à 2 séances, c'est discutable.
  → À trancher par le directeur. L'écran FI-4 devra afficher les essais.
- **m5 : vue globale, populations encore mêlées.** `encaisse = revenu = 690` (`:533-534`), alors que `impayes` (8 USD), `soldesCrediteurs` et `alertes` viennent toujours des jeux du foyer (`:538-551`), une autre population. Le guide §5.6 demande de « toujours distinguer encaissement / revenu » : un impayé de 8 avec une encaisse égale au revenu se contredit. Ce défaut existait avant le patch et sort du périmètre M2 strict.
  → FI-11a.
- **m6 : As-Salam, classe d'adultes ou d'enfants ?** La classe As-Salam est adulte dans `_classesDemo` (`:474-481`, facturée 60 USD le siège). Pourtant, Youssef (12 ans) et Khadija (13 ans), du jeu `cinqProfils`, y sont inscrits comme enfants (`estAdulte: false`, `:164-177`, `:226`) et facturés au tarif enfant. C'est une incohérence interne, antérieure au patch, mais que `revenuDemo()` rend désormais chiffrée.
  → Renommer la classe des enfants, ou la rattacher à An-Nour ou Al-Huda.

## Pour accepter (lever les réserves)

1. Avant FI-11a : préciser dans le contrat `VueGlobaleFinance` (ou dans le libellé de l'écran) que la marge projetée est calculée sur la paie, et ne jamais l'afficher sans cette précision à côté de la référence de 30 % net (m1). Distinguer l'encaisse du revenu en démonstration (m5).
2. Avant FI-4 : décider du libellé « À régulariser » (FI-BR-08) et de l'affichage d'un essai en cours sur la page Accès (m2, m4).
3. Documenter `finDernierAcces` pour le jeu `aucunPaiement` (m3) et corriger la classe As-Salam de Youssef et Khadija (m6).

Aucune de ces réserves n'empêche de passer FI-1c-CORR à « fait » ni de l'appliquer sur `ui/finance-v1` (après accord du directeur pour pousser sur la branche du rôle).
