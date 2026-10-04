# Revue croisée DASH-ADM-1-R : Centre de commande selon DASH_STRATEGIE §3.1

- **Objet revu** : `corrections/c2-adm1` @ `85906d0a` (base `af20f6c2`, branche commune), 3 commits, 22 fichiers (+760 −454), dont 10 captures.
- **Relecteur** : session cloud `01KyPAZg` (téléphone du directeur). Elle n'a pas écrit DASH-ADM-1 (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Références** : `docs/current/DASH_STRATEGIE.md` §3.1, D1 à D14 et l'annexe A ADM-01, lus sur `origin/corrections/c2-dash1`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés sur un worktree propre (Flutter 3.47.6, Dart 3.13.5) ;
  - trois mutations ciblées, remises en place ;
  - captures ouvertes.

## Verdict

**Acceptée.** DASH-ADM-1 peut passer à « fait ». La fusion de `c2-adm1` dans la branche commune revient à la voie CORR-2.

Tout ce que demande le §3.1 est tenu :

- la liste « À traiter en premier » est retirée ;
- la tuile Dossiers est grande partout, et chaque nom de l'aperçu ouvre **son** dossier ;
- une seule tuile « Incidents et accès » ;
- le raccourci Groupes ;
- une phrase calme, sur les seules quatre files d'action ;
- un squelette en grille ;
- une erreur par source.

Aucun bouton n'est imbriqué dans un autre, et les tests adaptés ne sont pas affaiblis. Trois remarques mineures ou cosmétiques ne bloquent rien.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `tableau_de_bord_test`, `admin_coque_test`, `test/features/admin_dossiers`, `test/core/cartes_collees_test` | **144 réussis, 0 échec** |
| Mutation 1 : l'aperçu ouvre la file sans `extra` | échec de « un nom de l'aperçu ouvre SON dossier, pas la file » |
| Mutation 2 : la phrase calme oublie « élèves sans enseignant » | échec de « phrase calme : tue (0, 0, 1, 0, 0, 0) » |
| Mutation 3 : l'erreur de la file n'est plus dite | échec de « une file de dossiers illisible n'emporte que les noms » |
| Ancienne page (af20f6c2) avec les nouveaux tests | Ne compile pas : `LigneApercu` et la nouvelle tuile n'existent pas. Contre-épreuve non probante, d'où les mutations ci-dessus |
| `dart run tool/verifier_jetons.dart` | **39 relevés**, le chiffre de la base |
| Fusion à blanc `git merge-tree` avec la branche commune, `c2-bento2c` et `c2-bento3` | Aucun conflit |
| Fichiers interdits | Aucun |
| Suite complète, un dossier à la fois | **5395 réussis, 0 échec**, le même chiffre que l'auteur |

## Points de la fiche, un par un

| Point demandé | Constat |
| :--- | :--- |
| Noms cliquables sans bouton dans un bouton | ✅ Dès qu'une ligne d'aperçu a son appui, la tuile perd le sien : l'`AppCard` est sans `onPress`. L'en-tête (chiffre et libellé) devient un `Pressable` (« 3 Dossiers à valider ») vers la file, et chaque ligne a son propre `Pressable`, à côté de l'en-tête, avec la cible de 48 par défaut, vers `adminPersonnesDossiers` avec `extra: profilId`. Ce sont deux frères, jamais imbriqués |
| Sémantique | ✅ L'en-tête est lu « valeur libellé ». La tuile double est lue « Incidents et accès, 2 Incidents (24 h), 5 Accès échus » |
| Squelette | ✅ `_SqueletteCompteurs` reprend les cinq étendues de la grille (une seule source, `_etendues`), en `Skeleton.tuileBento`. Test « le squelette a la forme de la grille » |
| Phrase calme | ✅ Elle n'apparaît que si dossiers, demandes, élèves sans enseignant et cahiers manquants valent tous 0. Incidents et accès n'y comptent pas, et rien n'est dit sur une lecture en échec. Tests paramétrés, et la mutation 2 est prise. Capture `390_calme` |
| Tuile double | ✅ Une seule tuile, quelles que soient les valeurs (D3 : 5 indicateurs dans tous les cas), avec son titre. Rapport sans appui (D9) |
| Groupes | ✅ Premier raccourci, vers `/admin/operations/groupes`. Aucun lien Planning (Q2) |
| Erreur par source (D10, D11) | ✅ Si les compteurs échouent, une phrase remplace toute la grille, jamais des tuiles à 0. Si la file échoue, le chiffre reste et « La liste n'a pas pu être lue. » remplace les noms. Capture `390_erreurliste` |
| Tests AD-11 et coquille admin adaptés, pas affaiblis | ✅ `ad11` : la tuile se trouve par l'`AppCard` **ou** le `Pressable` qui porte « valeur libellé ». `admin_coque` : les lignes se trouvent par « Prénom · ancienneté », avec la même exigence de deux prénoms distincts. `cartes_collees` : minimum ramené de 8 à 6, justifié par les 3 lignes-cartes de la liste retirée |
| Les 10 captures (K-61) | Ouvertes : `1440_clair`, `320x2_sombre`, `390_erreurliste_clair`, `390_calme_clair`. Aucun débordement ni mot coupé dans la grille (texte x2 en une colonne), et le mode sombre est sombre |

## Remarques (non bloquantes)

- **r1 (mineur) : le libellé de la tuile Dossiers change de place selon l'état.**
  - Avec des noms (ou l'erreur de liste), « Dossiers à valider » suit le chiffre en haut de la tuile (branche « lignes actives » de `TuileCompteur`).
  - Sans nom (0 dossier), il reste en bas, comme les autres tuiles.
  - Le choix est commenté (« les noms suivent l'en-tête »), mais d'un état à l'autre le libellé saute : comparer `1440_clair` et `390_calme_clair`.
  - À trancher au moment de DASH-LIB ou d'une passe Bento, rien à faire dans ce lot.
- **r2 (cosmétique) : à 320 px et texte x2, les trois noms de l'aperçu se suivent sans écart.** Chaque ligne fait trois lignes de texte et dépasse donc la cible de 48, sans `Ecart.vXs`, alors que les lignes non cliquables en ont un. Les trois personnes se distinguent mal (capture `320x2_sombre`). Remède : un `Ecart.vXs` entre les lignes cliquables.
- **r3 (cosmétique) : la phrase calme est posée en `textes.bodyMedium` sans encre de la palette.** Les autres textes de la page passent par `palette.ink*.applyTo`. Le rendu est correct dans les deux thèmes (couleur du thème par défaut).
- **Rappel (écart déjà connu).** Le compteur serveur des dossiers compte encore les tuteurs, alors que l'aperçu ne montre que les enseignants (K-47, BR-1.c), d'où un chiffre possiblement plus grand que les noms. C'est documenté dans le code et dans `DASH_STRATEGIE.md`.

## Suite par dossiers (un dossier à la fois)

```
test/core 648 · test/features 2501 (~2062) · test/router 277 · test/widgets 270
test/teaching_core 912 (~55) · test/accessibilite 314 · test/theme 70 · test/video 43
test/parcours 44 · test/capacites 37 · test/tool 32 · test/coran 25 · test/seance_famille 25
test/planning 23 · test/presence 20 · test/tc_observation 19 · test/agent 18 · test/foyer 18
test/suivi 16 · test/priere 15 · test/mouvement 13 · test/appairage 12 · test/cache 11
test/config 11 · test/observabilite 10 · test/i18n 7 · test/icons 4 · test/capture 0 (~657)
Total : 5395 verts, 0 échec.
```
