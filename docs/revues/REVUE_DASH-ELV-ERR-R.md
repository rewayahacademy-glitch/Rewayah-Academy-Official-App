# Revue croisée DASH-ELV-ERR-R : `origin/corrections/c2-elv-err` (04/10/2026)

Revue en lecture seule par la session cloud 016vrpQr (voie VERIF). Elle n'est autrice ni de
DASH-ELV-ERR ni de DASH-1. Les worktrees sont détachés sur `4d01d6b9` (branche) et `af20f6c2` (base).
Aucun commit n'a été fait ni poussé sur la branche revue. Méthode : un workflow orchestré de
5 contrôles en parallèle (code, tests et mutations, outils, captures, suite et fusion à blanc),
puis un sceptique indépendant par constat défavorable (16 contre-vérifications). Les sévérités
ci-dessous sont celles qui restent **après** contre-vérification.

## Verdict

**ACCEPTÉE AVEC RÉSERVES.** Aucun défaut bloquant ni majeur. Le changement fait ce que dit la fiche :
- une lecture ratée n'affiche plus jamais « Pas de cours aujourd'hui » (D10) ;
- Réessayer relit vraiment le fournisseur ;
- le bloc Coran reste à l'écran dans l'état d'erreur ;
- le libellé est au tutoiement ;
- l'ajout de « réessaie » dans `verifier_revue.dart` n'affaiblit pas la règle.

Quatre réserves mineures sont regroupées dans une étape **DASH-ELV-ERR-b** (voie CORR-2), à faire
avant ou pendant la fusion. La plus importante est m1 : le test ne couvre pas le chemin réel d'une
panne réseau.

## Périmètre

`af20f6c2..4d01d6b9`, trois commits :
- `aaff7b09` : code et test ;
- `bb555474` : 5 captures et leur script ;
- `4d01d6b9` : regex de `verifier_revue`.

13 fichiers, +122/−12. Fichiers hors captures et hors fichiers générés :
- `lib/features/accueil_eleve/accueil_eleve_page.dart` (+25/−6) ;
- `test/features/accueil_eleve_test.dart` (+40) ;
- `assets/i18n/fr.i18n.json` (+1) ;
- `tool/libelles_sources.json` ;
- `tool/verifier_revue.dart`.

## Commandes et mesures

Les lourdes ont été lancées sous verrou (un seul Flutter à la fois), avec Flutter 3.47.5 et Dart 3.13.4.

| Commande | Résultat |
|---|---|
| `flutter test test/features/accueil_eleve_test.dart` (branche) | **19 réussis, 0 échec** |
| Contre-épreuve : page de `af20f6c2` avec les tests de la branche | **18/1** : le nouveau test échoue à `:682`, sur « Found 1 widget with text "Pas de cours aujourd'hui" ». Annonce de l'auteur confirmée |
| 8 mutations de la page | **6 tuées** : condition à `false`, `onAction` vide, relecture d'un autre fournisseur, Coran retiré, mauvaise phrase, deux blocs rendus ensemble. **2 survivantes** : `ref.refresh` au lieu de `invalidate` (équivalente) ; `hasError` seul au lieu de `hasError && !hasValue` (trou de test, m3) |
| `dart analyze --fatal-infos` (branche et base) | No issues found, des deux côtés |
| `dart run tool/verifier_jetons.dart` | 39 des deux côtés, **listes identiques ligne à ligne** (rc=1 préexistant) |
| `dart run tool/verifier_revue.dart --detail` | 1627 des deux côtés, **listes identiques ligne à ligne** |
| `verifier_revue.dart` de la base exécuté sur le code de la branche | 1628. Une seule ligne de plus : `[erreur-sans-action] eleve.accueil.erreurCours`. L'ajout de la regex ne fait donc passer que le nouveau libellé, qui contient bien une action. **Pas un affaiblissement** |
| Libellés fr contenant « réessaie » | 3 : `eleveConnexion.pin.horsLigne`, `eleveConnexion.pin.echec` et `eleve.accueil.erreurCours`. Les deux premiers ne portent pas une clé `erreur*` : la règle ne les examine pas |
| Regex `réessaie\|reessaie`, `caseSensitive: false` | Reconnaît « Réessaie », « RÉESSAIE », « REESSAIE », « reessaie » |
| `dart run slang` dans un worktree propre | Fichiers générés identiques à ceux commités (`git status` vide) |
| `dart format --set-exit-if-changed` sur les 5 `.dart` modifiés | 0 fichier changé |
| `tool/libelles_sources.json` | JSON valide, 63 clés, `eleve.accueil.erreurCours` présente avec sa source |
| Captures régénérées depuis `dash_elv_err_capture_test.dart.txt` (`CAPTURE_DIR`) | **5/5 identiques octet pour octet** aux fichiers commités |
| Sonde jetable (fichier supprimé ensuite) : état d'erreur à 320 px, texte ×2, polices du dépôt, LTR et RTL, clair et sombre | 4/4 : 0 débordement, 0 mot coupé. Bloc à 16 px de chaque bord |
| Fusion à blanc de `4d01d6b9` dans la branche commune `f6ac3658` | 4 fichiers en conflit, **tous i18n et triviaux** : `strings.g.dart`, `strings_fr.g.dart`, `libelles_sources.json`, et `fr.i18n.json` fusionné automatiquement. Résolus en gardant les deux côtés, puis `dart run slang` : stable à la deuxième passe |
| Sur la fusion : `dart analyze --fatal-infos` | No issues found |
| Sur la fusion : `flutter test` par dossiers, `--concurrency=2` | core **648/0/0**, router **277/0/0**, widgets **270/0/0**, features **2541/2062/0**, autres dossiers **1699/712/0** (réussis/sautés/échecs). Total **5435 réussis, 2774 sautés (captures), 0 échec** |
| Fin de revue | Tous les worktrees de revue sont propres (`git status` vide) ; `merge --abort` sur la fusion à blanc |

### Captures ouvertes (K-61)

Ouvertes par l'orchestrateur lui-même, en plus de l'agent : `elv_err_320x2_sombre.png` et
`elv_err_1440_clair.png`. Elles montrent le même écran (`/eleve`, accueil standard) dans le même
état (lecture des séances en échec) :
- carte « Impossible de charger ces informations », avec la phrase et le bouton « Réessayer » ;
- puis la carte « Le Coran / À lire quand tu veux » ;
- aucun « Pas de cours aujourd'hui », aucun mot coupé ;
- aucun débordement sur les quatre bords à 320 ×2.

Les trois autres captures ont été lues par l'agent : 320 ×2 clair, 390 clair, 390 sombre.

## Défauts

### Bloquants

Aucun.

### Majeurs

Aucun. Deux constats d'abord classés majeurs ont été ramenés à mineur par leurs sceptiques (m1, m2).

### Mineurs (réserves, étape DASH-ELV-ERR-b)

- **m1. Le test ne couvre pas une vraie panne réseau. Sur ce chemin, l'erreur n'apparaît
  qu'après environ 38 s de squelette.**
  - Le mécanisme : le test lève `StateError('reseau')` (`accueil_eleve_test.dart:672`). C'est une
    `Error`, que la relance par défaut de Riverpod 3.4.3 ne relance pas. Une vraie panne lève une
    `Exception` (`SocketException`, ou `PostgrestException`, qui implémente `Exception`).
    `seancesProvider` (`service_planning.dart:364`) n'a pas de `retry`. Riverpod le relance donc
    10 fois, avec des délais de 200 ms à 6400 ms (`provider_container.dart:983-997`).
  - Pendant ces relances, l'état vaut `AsyncLoading(error, retrying: true)`. La condition du
    squelette (`accueil_eleve_page.dart:173`, `!hasValue && isLoading`) passe avant la nouvelle
    branche d'erreur. La page entière reste donc en squelette, Coran compris.
  - Mesure par la sonde jetable, avec une `SocketException` à chaque lecture : squelette de t=0 à
    37 s (10 lectures) ; erreur et Coran à 40 s, à la 11e lecture.
  - Ce qui est préexistant et ce qui ne l'est pas : l'attente existait à l'identique sur la base,
    qui affichait ensuite « Pas de cours aujourd'hui ». La branche ne l'aggrave pas et corrige
    bien l'état final. En revanche, la preuve D10 ne vaut que pour une `Error`. Le bouton
    Réessayer relance lui aussi, au besoin, un cycle de relances.
  - Correction, une ligne, déjà employée dans le dépôt (`service_validation.dart:261`) :
    `retry: (int n, Object e) => null` sur `seancesProvider`. Le test doit aussi lever une
    `Exception` (`throw Exception('reseau')`) et vérifier que l'erreur s'affiche sans attente.
- **m2. Le libellé ne donne pas la cause probable (K-59, `lib/CLAUDE.md:75`).**
  - « Tes cours n'ont pas pu être lus. Réessaie dans un instant. » dit ce qui manque et quoi
    faire, mais pas la cause. Le titre par défaut, « Impossible de charger ces informations », ne
    la donne pas non plus.
  - L'auteur a fidèlement repris l'annexe B de DASH_STRATEGIE (ligne 462), qui l'omettait déjà. Le
    libellé est déclaré « à faire valider (DASH-LIB) ».
  - Les autres messages tutoyés de l'élève donnent pourtant la cause : `eleveConnexion.pin.echec`
    dit « La connexion n'a pas abouti ».
  - Hors ligne, le bandeau « Pas de réseau » s'affiche déjà : la cause est visible ailleurs sur
    la page. Mais le bloc garde `NatureEtat.echecServeur`.
  - Proposition à soumettre au directeur avec DASH-LIB : « Tes cours n'ont pas pu être lus : la
    connexion ou le serveur n'a pas répondu. Réessaie dans un instant. » Et `NatureEtat.horsLigne`
    quand `horsLigneProvider` est vrai.
- **m3. La condition `hasError && !hasValue` n'est fixée par aucun test.**
  - La mutation `hasError` seul survit (19/19). Aucun test ne produit une erreur après une valeur
    déjà lue.
  - Le comportement retenu, garder la valeur précédente sans signal, était déjà celui de la base
    (`seances.value ?? []`) et n'est pas une régression.
  - Correction : un test « 1re lecture `[]`, `invalidate`, 2e lecture en échec » qui fige ce
    choix.
- **m4. Il manque la capture 1440 sombre.** Le message du commit `bb555474` annonce « clair et
  sombre », mais le script n'a qu'un tuple à 1440, en clair (l.32). Sévérité cosmétique pour le
  sceptique, car le sombre du même `EtatSysteme` est montré à 390 et à 320 ×2. Ajouter le tuple
  `(Size(1440, 900), ThemeMode.dark, 'elv_err_1440_sombre', 1)`.

### Info, préexistants, hors périmètre (aucune action demandée à cette étape)

- **i1.** Pendant la relecture lancée par Réessayer, la page entière passe un instant en squelette :
  le message et le Coran disparaissent le temps d'une lecture. Ce mécanisme est préexistant
  (`:173`). Il n'y a jamais de « aucun cours » transitoire, et une seconde erreur réaffiche bien
  l'erreur (mesuré). La correction n'est pas exigée ici : faire passer la condition d'erreur
  avant le squelette et donner `actionEnCours` à `EtatSysteme` le réglerait en même temps que m1.
- **i2.** En 1440, la carte d'erreur est bornée à environ 800 px (largeur de lecture), et la carte
  Coran fait environ 1136 px. C'est préexistant (`EtatSysteme`) : à porter à HU-1 si le directeur
  le relève.
- **i3.** Les réglages de prière en échec donnent silencieusement « aucune interruption » (D11,
  erreur par source). Le squelette de blocs des l.206-217 est du code mort. Les deux sont
  préexistants, hors fiche.
- **i4.** En arabe, `eleve.accueil.*` retombe en entier sur le français
  (`fallback_strategy: base_locale`, 98 clés en ar). C'est préexistant (étape LG-1).
- **i5.** Le Mode Accessibilité (`accueil_accessibilite.dart`) et l'accueil adulte ne sont pas
  touchés. L'auteur l'a déclaré (DASH-MA-PROD, DASH-EA-PROD).

## Pour fusionner

1. Fusionner `corrections/c2-elv-err` dans `corrections/revue-directeur-2026-10`. C'est le rôle
   de la voie CORR-2, après `c2-elv-err` et avant `c2-coran-carte`, selon l'ordre du tableau.
   Résoudre les 4 conflits i18n en gardant les deux côtés :
   - dans `libelles_sources.json`, les lignes `admin.tableau.*` et `eleve.accueil.erreurCours` ;
   - puis `dart run slang`.

   La fusion est mesurée verte : 5435/0.
2. DASH-ELV-ERR-b (m1 à m4) peut se faire avant la fusion, sur la même sous-branche, ou juste
   après. m1 et m3 sont du code et des tests. m2 attend le directeur (DASH-LIB). m4 est une
   capture.
