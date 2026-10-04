# Revue croisée BENTO-2c-R : corrections de BENTO-2b-R

- **Objet revu** : `corrections/c2-bento2c` @ `c427e551` (base `af20f6c2`, branche commune), 3 commits, 29 fichiers (+633 −195), dont 22 PNG.
- **Relecteur** : session cloud `01KyPAZg` (téléphone du directeur). Elle n'a écrit ni BENTO-2, ni BENTO-2b, ni BENTO-2c. Sessions exclues : `b061fd81`, `0c20e592`, `00166a22`.
- **Date** : 4 octobre 2026.
- **Référence** : pilotage `verifications/2026-10-04/BENTO-2b-R/RAPPORT.md`, section « Pour accepter ».
- **Méthode** :
  - lecture du diff ligne à ligne ;
  - contrôles relancés sur un worktree propre (Flutter 3.47.6, Dart 3.13.5) ;
  - deux contre-épreuves, avec l'ancien code remis en place ;
  - deux sondes jetables, supprimées après usage ;
  - captures ouvertes.

## Verdict

**Acceptée.** BENTO-2c peut passer à « fait ». La fusion dans la branche commune reste à faire par la voie CORR-2.

- Le majeur M1 de BENTO-2b-R est levé et prouvé par contre-épreuve.
- Les mineurs exigés (m1, m2, m3, m4, m6) et ceux qui étaient recommandés (m5, m7, m8, m9) sont levés.
- La fusion à blanc est propre, avec la branche commune comme avec `c2-bento3`.
- Il reste un constat hors du lot, non bloquant : n1 ci-dessous.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `accueil_famille_test`, `journee_test`, `test/core/grille_bento_test` | **185 réussis, 0 échec** |
| Contre-épreuve d2 : ancien `journee_page.dart` (af20f6c2), nouveaux tests | **2 échecs** (4 cahiers, 320 x2, LTR et RTL), qui nomment le mot : `['À terminer : terminer']` |
| Contre-épreuve d3 : ancien `bloc_seance.dart`, nouveaux tests | **7 échecs**. 600 x2 : `['Durée : Durée', '45 min : min']` ; 620 x2 : `['Durée : Durée']` (LTR et RTL) ; plus 3 tests de bascule (320 x1 et 390 x2 « durée à droite », 600 x2 « sous l'heure ») |
| Fusion à blanc `git merge-tree` avec `origin/corrections/revue-directeur-2026-10` (af20f6c2) | Aucun conflit |
| Fusion à blanc `git merge-tree` avec `origin/corrections/c2-bento3` | Aucun conflit |
| Fichiers interdits | Aucun : ni pubspec, ni supabase, ni .github, ni vercel.json, ni thème, ni Coran |
| Suite complète, un dossier à la fois | **5399 réussis, 0 échec**, le même chiffre que l'auteur |

## Points « Pour accepter », un par un

| Point | Constat |
| :--- | :--- |
| **M1** : « À terminer » à 320 x2 et 390 x2, avec 2 et 4 cahiers, LTR et RTL, et un test qui mesure toute la ligne | ✅ Un `OverflowBar` remplace la `Row` : « Voir tout » se met au bout de la ligne quand tout tient, et passe dessous sinon. Le test mesure toute la `Column` du bloc. Il vérifie la présence du titre, de « Obligatoire » et, avec 4 cahiers, de « Voir tout », ainsi que ses bornes. Le commentaire faux de la l.844 est réécrit. La capture `journee4_320x2` montre « À terminer » et « Obligatoire » entiers, avec « Voir tout » dessous |
| **m1** : famille 600-630 x2 | ✅ `_HeuresLarges` mesure ses libellés (TextPainter, à l'échelle du texte) et passe la durée sous l'heure quand elle ne tient pas. Les cas (600, 2) et (620, 2) sont ajoutés, et la contre-épreuve d3 les fait échouer. La capture `famille_600x2` est propre |
| **m2** : doc « 1024 : pleine » | ✅ Les deux commentaires disent maintenant : grille de 736 px x échelle, écran de 864 px avec le rail, 1040 px avec la barre dépliée |
| **m3** : limite des 360 px | ✅ Cas de mots coupés (864, 1), (900, 1), (1200, 1), (1280, 1). Assertions de placement à 768, 863 et 1440 x2 (pleine largeur) et à 864, 1024 et 1440 (côte à côte) |
| **m4** : garde de présence | ✅ `findsOneWidget` sur `GrilleBento` et sur « Durée » avant la mesure |
| **m5** : mesurer depuis un ancêtre indépendant du correctif | ✅ La mesure part de la `Column` de « À terminer ». La contre-épreuve d2 nomme le mot coupé, et non plus « Bad state » |
| **m6** : contradiction de `BENTO_RECENSEMENT.md` | ✅ La phrase est restreinte au palier à 3 colonnes, et le partage à 4 colonnes est décrit. Le titre et l'en-tête sont mis à jour (c4 levé au passage) |
| **m7** : point de rappel seul en tête de ligne | ✅ Le titre et le point forment un seul enfant du `Wrap` (`Row` en `mainAxisSize.min`, titre dans un `Flexible`) |
| **m8** : seuil de 96 px | ✅ Le seuil fixe est retiré. La mesure porte sur la largeur réelle de chaque colonne : la durée perd le filet et ses deux marges, via `_ColonneFiletee.retrait`. Des tests de bascule existent |
| **m9** : 320 x1 | ✅ Les deux colonnes reviennent à 320 x1 (test « durée à droite »), et la doc décrit le repli à 320 x2 |

### Points de lecture vérifiés

- **Rendu intrinsèque.** `_HeuresLarges` et `_HeuresCompactes` sont des `LayoutBuilder`. Aucun parent ne leur demande une dimension intrinsèque : `BlocSeance` n'est monté que par `CarteClasseSeance`, et `GrilleBento` n'utilise pas d'`IntrinsicHeight`.
- **Mesure des mots.** `_motLePlusLong` découpe sur `\s` (Dart : les espaces insécables comptent aussi). Les gabarits fr (`{date} · {fuseau}`, `{heure} {ville}`) ne contiennent aucune espace insécable, donc aucune sous-estimation aujourd'hui.
- **Dates et fuseaux.** La date et le fuseau ne sont mesurés qu'au mot le plus long. La durée et « Durée » sont mesurées sur une ligne, ce qui est plus strict et voulu.
- **Captures.** Ouvertes : `journee4_320x2_clair`, `journee4_1440_sombre`, `famille_600x2_sombre`, `famille_864_clair`.
  - Aucune bande de débordement, et le mode sombre est réellement sombre.
  - À 864 x1, la carte en demi-largeur pose la durée sous l'heure : la colonne d'un quart est trop étroite. C'est conforme à la règle documentée (« ou dessous si elle n'y tient pas entière »).

## Constats nouveaux

- **n1 (mineur, hors du lot) : titres de cahier coupés au trait d'union à texte intermédiaire.**
  - **Mesure.** Sonde jetable, 4 cahiers, de 320 à 480 px par pas de 20, texte x1,3, x1,5, x1,75 et x2, LTR et RTL : 34 cas sur 72 signalés par `verifierAucunMotCoupe`.
  - **Ce qui est coupé.** Seulement les titres des lignes de cahier, au trait d'union : `Cahier de transmission d'Al-Ikhlas : d'Al-Ikhlas`, de même pour `d'Al-Fatiha` et `d'As-Salam`.
  - **Pourquoi ce n'est pas un défaut du lot.** Rien dans l'en-tête que BENTO-2c corrige. Le composant de ligne n'est pas modifié par le lot. Les cas 320 x2 et 390 x2 du test passent, parce que les noms tiennent entiers sur leur ligne.
  - **Précédent.** BENTO-2b-R avait écarté « Classe An-/Nour » comme coupe légitime au trait d'union.
  - **À trancher par le directeur.** Une coupe au milieu d'un nom propre translittéré est-elle admise ? Si non, à porter dans COUPE-MOTS-2, par exemple avec un trait d'union insécable U+2011 dans les noms de classe.
- **n2 (cosmétique).** `test/features/accueil_famille_test.dart`, le commentaire du groupe « durée à droite / sous l'heure » est en désordre : « tant que (mesure, plus de seuil fixe de 96 px) « Duree » et sa valeur… ». À remettre dans l'ordre à la prochaine retouche du fichier.
- **n3 (cosmétique).** Les tests de bascule de la durée ne tournent qu'en LTR : `dx > centre` n'aurait pas de sens en RTL sans inverser le test. Les tests de mots coupés couvrent déjà RTL.
- **Cosmétiques c1, c2, c3, c5 de BENTO-2b-R.** Non traités, à la discrétion du directeur, comme le prévoyait le rapport.

## Suite par dossiers (un dossier à la fois)

```
test/core 648 · test/features 2505 (~2062) · test/router 277 · test/widgets 270
test/teaching_core 912 (~55) · test/accessibilite 314 · test/theme 70 · test/video 43
test/parcours 44 · test/capacites 37 · test/tool 32 · test/coran 25 · test/seance_famille 25
test/planning 23 · test/presence 20 · test/tc_observation 19 · test/agent 18 · test/foyer 18
test/suivi 16 · test/priere 15 · test/mouvement 13 · test/appairage 12 · test/cache 11
test/config 11 · test/observabilite 10 · test/i18n 7 · test/icons 4 · test/capture 0 (~657)
```

Somme des dossiers : 5383 verts, 0 échec. Les dossiers `test/fixtures` et `test/support` ne contiennent aucun test. Lancés seuls, ils ont fait tourner toute la suite, deux fois, l'une après l'autre : **5399 verts, 0 échec**. C'est le chiffre de l'auteur ; les 16 tests de plus sont posés à la racine de `test/`.
