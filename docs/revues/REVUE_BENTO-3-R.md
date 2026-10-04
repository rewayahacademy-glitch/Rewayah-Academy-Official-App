# Revue croisée BENTO-3-R : `origin/corrections/c2-bento3` (04/10/2026)

Revue en lecture seule. Worktree détaché sur `714b09e6`. Aucun commit poussé, aucune modification
de la branche revue. Le tableau de suivi n'a pas été touché.

## Verdict

**ACCEPTÉE AVEC RÉSERVES.** Aucun défaut bloquant. Le code de la grille est conforme à §3.7, D12
et D14 : jetons seulement, aucune couleur ni aucun espacement en dur, aucun rôle lu. Les cinq
états restent en place, et le squelette resté en colonnes est déclaré (D11 « à faire »).
L'analyse et les 263 tests ciblés passent. La contre-épreuve est faite. La fusion avec la branche
commune est propre : aucun conflit textuel, et 353 tests passent après fusion. Deux réserves
majeures, faciles à lever : l'encodage cassé du fichier de test (M1) et des captures à refaire
après la fusion (M2).

## Périmètre et commandes lancées

Périmètre : `fa64a6ad..714b09e6`, soit 7 commits, dont la reprise de c2-dash1 `fd86f452`.
Fichiers hors captures :
- `lib/features/accueil_adulte/accueil_adulte_page.dart` (+91/−36)
- `test/features/accueil_adulte/accueil_adulte_page_test.dart` (+266)
- `test/support/aucun_mot_coupe.dart` (+29)
- `docs/current/DASH_STRATEGIE.md` (+488)
- `docs/current/BENTO_RECENSEMENT.md`
- `docs/current/REPRISE-CORRECTIONS-REVUE.md`

Les fichiers `controle_page.dart` et `mon_espace_adulte_page.dart` ne sont pas modifiés : la
décision « pas de Bento » n'est que documentaire, et c'est conforme à D14 et §3.6.

| Commande | Résultat |
|---|---|
| `flutter pub get` | OK |
| `dart analyze --fatal-infos` (branche) | No issues found |
| `flutter test` : accueil_adulte, controleur/controle_page_test, mon_espace_adulte, core/grille_bento_test, accueil_famille_test, journee_test | **263 réussis, 0 échec** |
| `dart run tool/verifier_jetons.dart` | code 1, 39 constats, **identiques à la base fa64a6ad** (diff vide), aucun dans accueil_adulte |
| `dart run tool/verifier_revue.dart --detail` | code 1, 1610 violations, **identiques à la base fa64a6ad** (diff vide), aucune dans accueil_adulte |
| `dart format --set-exit-if-changed` (3 dossiers touchés) | 1 fichier à reformater : `accueil_adulte_page_test.dart`. La CI ne contrôle pas le format. |
| Contre-épreuve : page de fa64a6ad, tests de la branche | **12 échecs**, dont « vrai routeur … grille Bento » et « 1440 px sans Avant … » (voir plus bas) |
| Helper de la base avec le code de la branche | 6 échecs : `['Classe An‑Nour : An‑Nour']` à ×2, faux positif du glyphe U+2011. Le changement du helper est donc nécessaire. |
| Sonde jetable (fichier supprimé) : nouveau helper sur « Anticonstitutionnellement », « Classe An‑Nour » et « Mamadou Diallo » à 40, 70 et 400 px | Coupure détectée à 40 et 70 px, rien signalé à 400 px : le helper détecte encore une vraie coupure |
| Fusion à blanc, puis analyse | No issues found |
| Après fusion, tests : tous les fichiers qui emploient le helper, plus grille_bento, controle, mon_espace | **353 réussis, 74 sautés (captures sans CAPTURE_DIR), 0 échec** |
| Après fusion, sonde `verifierEcranSansMotCoupe` (écran ENTIER, en-tête compris) sur l'accueil adulte 320×2, 768×1/×2, 1440×1/×2, LTR et RTL | **10/10 réussis** |

### Contre-épreuve (point 3)

J'ai remis `accueil_adulte_page.dart` dans son état de fa64a6ad et lancé les tests de la branche.
Ces tests échouent :
- `vrai routeur : depuis /demo/adulte … grille Bento` ;
- `1440 px sans « Avant » : la seance seule dans sa bande …` ;
- les 10 cas « aucun mot coupe ». Ils échouent sur `find.byType(GrilleBento)` et non sur une
  coupure.

La grille est donc protégée. Les tests d'ordre « 390 px », « 768 px » et « 1440 px ltr/rtl »
réussissent aussi sur l'ancien code : ils ne distinguent pas l'ancienne disposition de la
nouvelle (m3).

## Défauts

### Bloquants

Aucun.

### Majeurs

- **M1. Texte cassé par un mauvais encodage dans le test.** Fichier :
  `test/features/accueil_adulte/accueil_adulte_page_test.dart`, lignes 2, 185, 281, 300, 352,
  370, 402, 470, 495, 512, 525 et 559. Les « » et § y sont devenus `آ«`, `آ»` et `آ§` : de
  l'UTF‑8 relu en cp1256. Le commit 99ba0ea1 a cassé des noms de tests et des commentaires qui
  existaient déjà, et les nouveaux sont nés cassés. Preuve : `git diff fa64a6ad..714b09e6`
  montre `-… « Accueil » …` / `+… آ« Accueil آ» …`. On compte 0 occurrence dans fa64a6ad et 12
  dans 714b09e6. Les noms de tests affichés en CI sont illisibles.
  - Correction : `sed -i 's/آ«/«/g; s/آ»/»/g; s/آ§/§/g'` sur ce fichier.
  - Le même défaut existe déjà, hors périmètre, dans
    `test/features/adulte_recette/captures_ea2_test.dart:7`, sur la branche commune.
- **M2. La capture 320×2 montre un mot coupé sur l'écran livré, et l'auteur ne l'a pas
  déclaré.** Fichiers : `docs/current/captures/BENTO-3/adulte_320x2_clair.png` et
  `adulte_320x2_sombre.png`. La salutation s'affiche « Bonjour Mamado / u ». Elle est dans
  l'en-tête `EntetePage`, hors grille, sur l'accueil adulte lui-même. Le point 2 de l'auteur ne
  cite que le Contrôle et Mon espace.
  - La branche n'a pas causé ce défaut : `entete_page.dart` n'est pas modifié.
  - COUPE-MOTS-1 le corrige. Après la fusion à blanc, `verifierEcranSansMotCoupe` sur l'écran
    entier réussit à 320×2, LTR et RTL.
  - Reste à faire : les captures BENTO-3 à 320×2 deviennent fausses après la fusion. Il faut les
    refaire sur le résultat de la fusion.

### Mineurs

- **m1. Captures tronquées.** Le test de capture fixe la vue à `Size(l, l < 600 ? 2600 : 1500)`
  (`bento3_capture_test.dart.txt:83`).
  - À 320×2, la capture s'arrête sur le titre « Dernières » derrière la barre basse :
    « Dernières séances » et « Ressources » ne sont pas visibles.
  - À 1440×2, elle s'arrête sur la première ligne de « Dernières séances ».
  - Pour ces deux tailles, l'affirmation « aucun mot coupé dans la grille » repose donc sur le
    test seulement, pas sur la capture.
- **m2. Ressources décalée en 1440.** Le titre « Ressources de la classe » est environ 12 px plus
  bas que « Dernières séances » (`adulte_1440_*.png`, y≈733 contre y≈721). Cause : l'en-tête de
  `BlocBibliotheque` porte « Voir tout » avec une cible de 48 px. Point déclaré par l'auteur (5).
- **m3. Tests d'ordre non discriminants.** Fichier `accueil_adulte_page_test.dart` : tests
  « 390/768 px : une tuile par bande » (l.468-489) et « 1440 px ltr/rtl » (l.493-520). Ils
  réussissent aussi sur fa64a6ad. Il faudrait ajouter `findsOneWidget` sur `GrilleBento` et,
  à 1440, une assertion qui échoue sur `ColonnesParRangees`. Par exemple : `p` occupe toute la
  largeur, `p.width ≈ s.width + a.width + 16`.
- **m4. Mise en forme.** `accueil_adulte_page_test.dart:517-519` : le commentaire et l'`expect`
  sont mal indentés, et `dart format` modifie le fichier.
- **m5. Constante prise dans une autre fonctionnalité.**
  `accueil_adulte_page.dart:55-56` importe `largeurMinCarteClasse` depuis
  `features/accueil_famille`. La règle BENTO-2b est désormais partagée : elle aurait sa place
  dans `core/widgets/grille_bento.dart`. Le seuil de 360 n'a pas de source (point 4 de
  l'auteur, déjà écrit dans DASH §3.7).
- **m6. Squelette resté en colonnes.** `accueil_adulte_page.dart:181` charge
  `SqueletteGroupe`, toujours en colonnes. D11 demande un squelette « fidèle aux tuiles ».
  Point déclaré par l'auteur (3) et noté « à faire » dans la fiche EA-ACCUEIL de
  DASH_STRATEGIE.
- **m7. Enseignant au-dessus du nom de la classe à 320.** À 320 (×1 et ×2) et à 1440×2,
  l'avatar et « Sayyid Ibrahim » passent au-dessus de « Classe An‑Nour ». Le trait d'accent
  violet du nom de classe reste seul, à gauche, à mi-hauteur des deux lignes du titre
  (`adulte_320x2_*.png`). Cela vient d'`IdentiteGroupe`, pas de cette branche. Point déclaré
  par l'auteur (5).
- **m8. Aucun test propre au helper.** `test/support/aucun_mot_coupe.dart:46-64` : le nouveau
  critère du « milieu vertical » n'a aucun test unitaire. La sonde de la revue montre qu'il
  détecte encore une coupure, mais rien ne le garantit dans le dépôt.
- **m9. Description « Aujourd'hui » périmée.** `DASH_STRATEGIE.md` §3.7 décrit encore « Deux
  colonnes par rangées (l.349-356) » alors que le « Fait (BENTO-3) » suit. C'est acceptable
  comme historique, mais les numéros de ligne ne correspondent plus au fichier actuel.

Points vérifiés sans défaut :
- Ordre de §3.7 et D2 : sans « Avant », la séance prend toute sa bande.
- D14 : 2 tuiles ou moins donnent une colonne avec un écart de 16, via `GrilleBento.ecart`.
- Aucune couleur ni aucun espacement en dur dans le diff (`GrilleBento.ecart`, `Ecart.*`).
- Aucun test de rôle dans le widget.
- États : contenu, erreur, indisponible, hors ligne et vide « aucune classe » restent couverts
  par les tests existants, qui réussissent.

## Captures vues

J'ai ouvert les images en entier ou par tranches de 870 px :
- `adulte_320x2_clair` et `adulte_320x2_sombre` : M2, m1 et m7. Ailleurs, aucun mot coupé dans
  la grille ni chevauchement. Le thème sombre est cohérent.
- `adulte_320_clair`, bas de l'image : « Ressources de la classe » et « Voir tout » passent
  sur 2 lignes, entiers, sans coupure.
- `adulte_768_clair` : une tuile par bande, conforme à BENTO-2b (moitié < 360). RAS.
- `adulte_1440_clair` et `adulte_1440_sombre` : séance et « Avant » côte à côte, parcours en
  pleine largeur, dernières séances et ressources côte à côte. Seul défaut : le décalage de
  m2. La tuile « Avant » est courte, d'où un vide à droite sous elle, ce qui est attendu en
  hauteur de contenu.
- `adulte_1440x2_clair` : une tuile par bande (moitié < 720), conforme. On y voit aussi m1 et
  m7. « Reway… » est tronqué dans la barre latérale, hors périmètre ; COUPE-MOTS-1 le corrige
  sur la branche commune.

## Fusion à blanc

Base commune : `fa64a6ad`. La branche commune `origin/corrections/revue-directeur-2026-10` a
avancé de 7 commits : COUPE-MOTS-1 parts 1 et 2, PASTILLE-COUPE-1, CORR-SUITE-2, et la reprise
af20f6c2.

- `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` donne l'arbre
  `2571b11d`, code 0, **aucun conflit**.
- Le seul fichier modifié des deux côtés est `test/support/aucun_mot_coupe.dart`. Les blocs
  modifiés sont disjoints :
  - la branche commune ajoute `traitDUnionPermis`, `exceptions`, `verifierEcranSansMotCoupe`
    et le filtre `hasSize/attached` ;
  - BENTO-3 remplace le critère « même `top` arrondi » par `_lignesDistinctes`.
- Git les combine seul, et le résultat garde les deux : le nouveau critère s'applique aussi
  aux nouveaux appelants.
- La fusion a été faite localement dans le worktree détaché (commit local `020c8616`, jamais
  poussé). Après fusion, l'analyse ne trouve rien et les 353 tests réussissent, dont
  `coupe_mots1_test`, `coupe_mots1_part2_test`, `mes_classes_test` et
  `nav_shell_accessibilite_test`.
- Résolution : rien à faire à la main. Le conflit annoncé par l'auteur (point 1) n'a pas lieu.
  Il faut seulement refaire les captures BENTO-3 à 320×2 après la fusion (M2).

## Pour accepter

1. Corriger l'encodage de `test/features/accueil_adulte/accueil_adulte_page_test.dart` (M1).
   Vérifier avec `grep -c 'آ'`, qui doit répondre 0.
2. Fusionner la branche commune (sans conflit), puis refaire au minimum
   `adulte_320x2_{clair,sombre}` sur le résultat. Allonger la vue pour que « Ressources »
   apparaisse à 320×2 et 1440×2 (M2, m1).
3. Lancer `dart format` sur le fichier de test (m4).
4. Recommandé :
   - rendre les tests d'ordre discriminants (m3) ;
   - ajouter un test unitaire de `_lignesDistinctes`, via `motsCoupes` sur un U+2011 et sur un
     mot réellement coupé (m8) ;
   - déplacer `largeurMinCarteClasse` dans `grille_bento.dart` (m5).
5. Laisser ouverts et suivis : squelette D11 (m6), seuil de 360 sans source, IdentiteGroupe à 320
   et décalage de Ressources (m2, m7).
