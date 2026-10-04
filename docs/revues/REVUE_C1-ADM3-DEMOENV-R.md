# Revue croisée AD-M3-PROD-R et C1-DEMOENV-R : `origin/corrections/c1-adm3` et `origin/corrections/c1-demoenv` (04/10/2026)

Revue faite par la session cloud 01MrLWqB, en lecture seule. Les deux branches viennent de la
session 268bd1ef et partent de la branche commune `af20f6c2`.

- **c1-adm3** : périmètre `af20f6c2..e68aad98`, 3 commits (`bf8c9972` AD-M3-PROD, `2c565f68`
  CTRL-BR-OBS-1, `e68aad98` AD-T-LECTURE), 9 fichiers.
- **c1-demoenv** : périmètre `af20f6c2..f6e6bf48`, 4 commits (`9a56b333` DEMO-ENV-1, `05462a11`
  AD-FOCUS-MD, `5a9a797f` AD-9-ONGLET-PROD, `f6e6bf48` AD-M4-DEFIL), 9 fichiers.

Aucun commit ni push sur les branches revues. Le tableau de suivi est tenu par la session
principale. Les worktrees de contrôle (`/home/user/wt/b3b`, `mut-ordre`, `ctrl`, `mut-helper`,
`defil`, `capt`, `fusion`) ont fini avec un `git status --short` vide. Les worktrees des
contre-vérifications ont été supprimés. `/home/user/wt/base-af20` (base `af20f6c2` générée) est
laissé en place.

## Verdicts

### AD-M3-PROD-R (`corrections/c1-adm3` @ `e68aad98`) : **ACCEPTÉE**, avec des mineurs à suivre

- La décision S1 -> a du 27/09 est tenue : en production, refus et aperçu de la pièce sont
  fermés comme la validation. Zéro `decider_dossier`, zéro `createSignedUrl`, et
  `CapaciteIndisponible` est levée avant toute lecture (0 lecture mesurée par les tests).
- Les deux contre-épreuves refusées à l'auteur sont faites et tenues : rebrancher l'aperçu ou
  la décision fait échouer 3 tests de production (dans les 3 variantes), forcer
  `_lectureFaite` à vrai fait échouer les 2 tests AD-T-LECTURE.
- Suite complète sur `e68aad98` : 5366 réussis, 2774 sautés, 0 échec. analyze 0, format
  propre, jetons identiques à la base, revue 1627 -> 1626 (une violation `bouton-grise` en
  moins, aucune en plus).
- Aucun constat bloquant ni majeur. Deux mineurs ont tenu : commentaires périmés (B3B-6) et
  test CTRL-BR-OBS-1 aveugle aux paramètres d'URL (CTRL-OBS-01). Un cosmétique (CTRL-OBS-02).
- Reste déclaré par l'auteur, toujours ouvert dans le dépôt : captures de la revue en
  production non commitées. Cette revue a produit et regardé 15 captures locales (voir
  « Captures vues »), sans défaut lié à la branche.

### C1-DEMOENV-R (`corrections/c1-demoenv` @ `f6e6bf48`) : **ACCEPTÉE**, avec des mineurs à suivre

- Les quatre fiches tiennent. Les contre-épreuves non faites par l'auteur (focus,
  défilement) sont faites : la version `af20f6c2` fait échouer 3 des 4 nouveaux tests de focus
  et le test de défilement (60 attendu, 0 obtenu).
- La garde DEMO-ENV-1 ne change rien en debug et en test (même expression qu'à `af20f6c2`
  quand `publication` est faux). Aucune page défilante ne dépend du `PrimaryScrollController`
  (0 occurrence dans `lib/`).
- Suite complète sur `f6e6bf48` : 5366 réussis, 2774 sautés, 0 échec. analyze 0, format
  propre, jetons et revue identiques à la base (diff vide).
- Aucun constat bloquant ni majeur. Trois mineurs ont tenu : branchement réel de la garde non
  testé (DEMO-ENV-1-M1), libération des défileurs non testée (DEFIL-1), état hors ligne absent
  de la page de politique (AD9-M1, antérieur à la branche).
- Reste déclaré par l'auteur : capture `ad9_14_indisponible_1440` non refaite (confirmé).

Tous les contrôles ont rendu un résultat. Aucun n'a manqué.

## Exigences des fiches point par point

### AD-M3-PROD (`bf8c9972`)

| Exigence | État | Preuve |
|---|---|---|
| Refus fermé en production comme la validation | **Tenue** | `revue_dossiers_depuis_validation.dart:193-247` : `peutRefuser = documentId != null && decisionBranchee`, `peutValider = consultable && decisionBranchee`, `BlocageRevue.decisionIndisponible` dans `blocagesValidation` et `blocagesRefus`. `surchargeRevueDossiersProduction` (l.424-429, posée par `main.dart:35`) ne passe plus `apercu`, `deciderExistant` ni `relire`. |
| `decider()` lève avant toute lecture | **Tenue** | l.332-338 : `AD-BR-02` (valider) puis `AD-BR-06` (refuser), avant `_lire()`. Test « sans RPC branchee » : 0 lecture. Mutation 3d (lecture avant `AD-BR-06`) tuée (-1). |
| Aperçu fermé, zéro `createSignedUrl` | **Tenue** | `peutVoirPiece = apercu != null && ...` (l.233-237). `demanderVuePiece` lève `AD-BR-03` avant lecture (test : 0 lecture ; mutation 3d' tuée). grep `lib/` : `createSignedUrl` seulement dans `service_validation.dart:223` (atteint par `apercu`, non branché) et `service_avatar.dart:167` (hors KYC). `decider_dossier` seulement dans `service_validation.dart:231`. Autres appelants : démo et playground `_dev` seulement. |
| Aucun autre chemin après fusion (Centre de commande) | **Tenue** | `tableau_de_bord_page.dart:44-72` ne fait que lire `dossiersEnAttenteProvider` et naviguer vers `DossiersPage` (FUS-3). |
| « La consultation de la pièce est indisponible pour le moment. » à la place de « Voir la pièce », sans bouton grisé | **Tenue** | `revue_dossier.dart:527-544`. Le diff retire `onPress: dossier.peutVoirPiece ? onVoirPiece : null`. `verifier_revue` : `bouton-grise` 32 -> 31. Mutations 3c et 3c' (bouton grisé remis) tuées (-3). |
| « Refuser » retiré, pas grisé | **Tenue** | Bouton construit seulement `if (peutRefuser)` (l.401, 420). Mutation 3a tuée (-4). |
| « La décision est indisponible pour le moment. » dite une seule fois | **Tenue** | `_RaisonsDecision` (l.641-700). Tests `findsOneWidget`. Mutation 3b (phrase dite deux fois) tuée (-3, trouvée 2 fois). Captures : 1 occurrence dans les 5 cas. |
| Démonstration inchangée (refus et pièce possibles) | **Tenue** | `RevueDossiersDemo` non touché. `test/features/admin_dossiers/` 75/75. Mutation 3e (refus fermé en démo) tuée par 51 tests. |
| Couverture gardée par l'adaptateur « comme à BR-1 » | **Tenue** | `test/support/dossiers_production.dart:20-34` identique ligne à ligne à l'ancien `surchargeRevueDossiersProduction` de `af20f6c2`. AD-8 (refus avec motif) et les tests de visionneuse y tournent toujours. |
| Commentaire « à BR-1, rebrancher » | **Tenu** | l.416-423, les trois paramètres nommés sont ceux retirés. Mais trois autres commentaires décrivent encore l'ancien état (B3B-6, mineur). |
| Contre-épreuve 1 (rebrancher en production -> tests rouges) | **Tenue** | -3 en rebranchement complet, -3 aperçu seul, -3 décision seule. |
| Captures 390/1440 clair/sombre | **Non tenue dans le dépôt** | Reste déclaré par l'auteur. Captures locales faites par cette revue, conformes (voir plus bas), non commitées. |

### CTRL-BR-OBS-1 (`2c565f68`)

| Exigence | État | Preuve |
|---|---|---|
| Test qui fixe « Commencer le contrôle » -> `/salle` avec le billet | **Tenue** | `controle_page_test.dart` +62 lignes, 9/9. Mutations sans billet, billet d'une autre séance, sans navigation : tuées (-1 chacune). |
| « Billet seul » | **Partiellement tenue** | Un paramètre de requête ajouté (`/salle?observer=1`) passe : +9, tous verts. Le test ne compare que `uri.path` (CTRL-OBS-01, mineur). Le code actuel, lui, est correct (`controle_page.dart:243-247`, billet par `extra`). |
| `observerEnControle` jamais appelé | **Tenue** | grep `lib/` : 0 appel (déclaration `service_video.dart:58`, RPC `:125-126`, stub vide de démo). Mutation « appel de `observerEnControle` » tuée (`observations = ['demo-seance-an-nour-0928']`). |
| Aucun code de `lib/` changé | **Tenue** | `git show --stat 2c565f68` : 1 fichier de test. |
| Renvoi au pilotage BR-CT-19 | **Tenu** | `5c703347` : `14_controleur/CT-BR.md` cite le titre exact du test et la branche. Le fichier de test ne dit pas qu'il faudra inverser l'assertion à BR-1 (CTRL-OBS-02, cosmétique). |

### AD-T-LECTURE (`e68aad98`)

| Exigence | État | Preuve |
|---|---|---|
| Test qui échoue si la porte est neutralisée | **Tenue** | Contre-épreuve 2 : `_lectureFaite => true` (l.82) donne -2, les deux tests AD-T-LECTURE (attendu false, obtenu true). Variante `_modifiable` sans la porte (l.126) : -2, les mêmes. |
| Cases fermées avant lecture, ouvertes après | **Tenue** | `dossiers_admin_test.dart:383-414` : `pressable` faux et non cochée avant `_voirEtFermer`, vrai et cochée après, pour les 3 points. |
| États « indisponible » et « erreur » de la visionneuse | **Tenus** | Signature 500 : la visionneuse dit `pieceIndisponible`, case non pressable. Erreur : test 404 conservé. |
| Titres de test et commentaire remis d'accord | **Tenus** | Titres « Valider reste fermé (Q21) », commentaire de l'adaptateur l.178-183 à jour (vérifié par la synthèse et l'audit, pas par un contrôle). |

### DEMO-ENV-1 (`9a56b333`)

| Exigence | État | Preuve |
|---|---|---|
| Démos fermées en publication sans ENVIRONNEMENT | **Tenue** | `env.dart:105` `environnementDeclare = bool.hasEnvironment('ENVIRONNEMENT')`. `mode_demonstration.dart:70-80` : `if (publication && !declare) return false;` avec `publication = kReleaseMode`. Release sans ENVIRONNEMENT : fermées. Release `staging` : ouvertes. Release `production` ou vide : fermées. |
| Rien ne change en debug et en test | **Tenue** | Quand `publication` est faux, l'expression est celle de `af20f6c2`. `test/features/demo` : +107 ~10, 0 échec. |
| Garde partagée pour toutes les démos | **Tenue** | 11 points d'appel, tous avec les paramètres par défaut, aucune garde locale (sur `f6e6bf48` et sur `f6ac3658`). |
| Test injectable | **Tenu, partiel** | Logique couverte : mutations « `kReleaseMode` ignoré » (-73) et « bloc supprimé » (-1) tuées. Le branchement réel n'est pas testé : `environnementDeclare = true` et `publication = false` par défaut survivent (+329 ~10, 0 échec). DEMO-ENV-1-M1, mineur. |
| CI déclare ENVIRONNEMENT | **Tenue** | `flutter-deploy.yml:130` passe `production` ou `staging`. `ci.yml:304` compile sans, mais ne déploie pas. |
| Commentaires corrigés | **Tenus** pour `mode_demonstration.dart`. `demo_finance_page.dart` est hors branche (reste déclaré, voie FIN). |

Note : une compilation `--profile` sans ENVIRONNEMENT ouvre les démos (`kReleaseMode` faux en
profile). La fiche ne vise que la publication et aucun workflow ne déploie en profile (info).

### AD-FOCUS-MD (`05462a11`)

| Exigence | État | Preuve |
|---|---|---|
| Sans dossier suivant, focus au titre dans les deux mises en page | **Tenue** | `_focusAuTitre()` dans les deux branches (`dossiers_page.dart:113-125`). |
| Tests 390 et 1440, file vidée et dernier d'une file non vide | **Tenue** | 4 nouveaux tests, `file_dossiers_test` +17, 0 échec. |
| Contre-épreuve (non faite par l'auteur) | **Faite** | `dossiers_page.dart` de `af20f6c2` : +14 -3. Les 3 cas sans code de focus échouent ; « 390 file vidée » passe, attendu (l'ancien code le traitait). Mutations : focus jamais demandé -5, seulement à 390 -2, seulement à 1440 -3. |

### AD-9-ONGLET-PROD (`5a9a797f`)

| Exigence | État | Preuve |
|---|---|---|
| Ni titre ni 4e onglet tant que la capacité n'est pas connue et vraie (chargement, indisponible, échec) | **Tenue** | `politique_revue_kyc_page.dart:151-174` : titre et sous-navigation seulement si `lue.hasValue && p.peutModifier`. Tests sur la route (G11, G11 bis, G12, G13) : +12. 6 mutations sur 6 tuées (-1, -1, -3, -3, -4, -2). |
| Commentaire :151-153 remplacé | **Tenu** | |
| Capacité lue, jamais un rôle ; aucun bouton grisé introduit | **Tenu** | grep : seul le commentaire Q40 l.25 parle de rôle. |
| États de l'écran | **Partiel, antérieur** | Pas d'état hors ligne distinct : toute erreur autre que capacité ou accès donne `echecServeur` (l.167-170), déjà à `af20f6c2`. Atténué par l'`OfflineBanner` de `PageShell` (AD9-M1, mineur). |
| Capture `ad9_14_indisponible_1440` | **Non tenue** | Reste déclaré par l'auteur, non refaite. |

### AD-M4-DEFIL (`f6e6bf48`)

| Exigence | État | Preuve |
|---|---|---|
| Position gardée à la bascule de structure | **Tenue** | `page_shell.dart:330-420` : un `ScrollController` par branche, recréé avec l'offset de l'ancien, l'ancien libéré après l'image. `page_shell_etat_test` +4. |
| Test sur une vraie page d'un autre rôle | **Tenu** | `AProposForfaitFamillePage` (élève adulte), 420 -> 300 -> 420 de haut. |
| Contre-épreuve (non faite par l'auteur) | **Faite** | `page_shell.dart` de `af20f6c2` : +3 -1 (60 attendu, 0 obtenu). Mutations sur l'offset tuées. |
| Aucune page défilante ne dépend du `PrimaryScrollController` | **Tenue** | grep `PrimaryScrollController\|primary: true` dans `lib` et `test` : 0. `Scrollable.ensureVisible` (`file_dossiers.dart:153`, `revue_dossier.dart:149`) passe par le défileur parent ; `fil_discussion.dart:155` a son propre contrôleur. Chemin `defilante: false` inchangé. |
| Autres rôles non cassés | **Tenu** | `test/widgets` +271 ; accueil_adulte 13, admin_dossiers 78, dossiers_admin 12, journee_test 61, journee 10, tableau_de_bord 12, foyer 273, page_shell_test 3 : 0 échec. |
| Libération des défileurs | **Saine, non gardée** | Suivi des fuites activé à titre temporaire : 0 fuite sur le code réel, mais 3 mutations sur 3 de la libération survivent à la suite livrée (DEFIL-1, mineur). |

Reste déclaré par l'auteur, confirmé : le « tap sur la barre d'état » d'iOS natif ne remonte
plus les pages défilantes ; sans effet sur la PWA (DEFIL-2, info).

## Commandes lancées

Toutes les suites avec `--concurrency=2`.

### Branche A, `corrections/c1-adm3` @ `e68aad98` (`/home/user/wt/b3b`)

| Commande | Résultat |
|---|---|
| `dart analyze --fatal-infos` (dépôt entier) | No issues found |
| `dart format --output=none --set-exit-if-changed` (9 `.dart` du diff) | 0 changé |
| `dart run tool/verifier_jetons.dart` (branche et base `af20f6c2`) | code 1 des deux côtés, 44 lignes, diff vide |
| `dart run tool/verifier_revue.dart --detail` (branche et base) | code 1. Base 1627, branche 1626. Seule ligne retirée : `revue_dossier.dart:536 [bouton-grise]`. Aucune ajoutée |
| `flutter test test/features` | +2471, ~2062 sautés, 0 échec |
| `flutter test test/core` | +649, 0 échec |
| `flutter test test/router` | +277, 0 échec |
| `flutter test test/widgets` | +270, 0 échec |
| `flutter test` sur les autres dossiers de `test/` | +1699, ~712 sautés, 0 échec |
| **Total branche A** | **5366 réussis, 2774 sautés, 0 échec** (le contrôle avait écrit 4366 : erreur d'addition, la somme de ses 5 lots fait 5366) |
| 6 fichiers de test du diff | +51, 0 échec, 0 sauté (rapporteur json : 51 succès `skipped=false`) |
| `test/features/admin_dossiers/` | +75, 0 échec |
| `controle_page_test.dart` | +9, 0 échec |
| `git grep -c 'skip:' -- test`, `af20f6c2` et `e68aad98` | 165 et 165 |

### Branche B, `corrections/c1-demoenv` @ `f6e6bf48` (`/home/user/wt/capt`, `mut-helper`, `defil`)

| Commande | Résultat |
|---|---|
| `dart analyze --fatal-infos` (dépôt entier) | No issues found |
| `dart format --output=none --set-exit-if-changed` (9 `.dart` du diff) | 0 changé |
| `dart run tool/verifier_jetons.dart` (branche et base) | code 1, 44 lignes, diff vide |
| `dart run tool/verifier_revue.dart --detail` (branche et base) | code 1, 1627 = 1627, diff vide |
| `flutter test test/features` | +2471, ~2062 sautés, 0 échec |
| `flutter test test/core` | +648, 0 échec |
| `flutter test test/router` | +277, 0 échec |
| `flutter test test/widgets` | +271, 0 échec |
| `flutter test` sur les 26 autres dossiers | +1699, ~712 sautés, 0 échec |
| **Total branche B** | **5366 réussis, 2774 sautés, 0 échec** |
| `test/features/demo` | +107 ~10, 0 échec |
| `politique_revue_kyc_test.dart` | +12, 0 échec |
| `file_dossiers_test.dart` | +17, 0 échec |
| `page_shell_etat_test.dart` | +4, 0 échec |
| `git merge-tree --write-tree HEAD origin/corrections/revue-directeur-2026-10` | sans conflit |

### Fusion à blanc (`/home/user/wt/fusion`, `f8898980`, locale, jamais poussée)

| Commande | Résultat |
|---|---|
| Fichiers modifiés des deux côtés (`comm -12`) pour `e18485f4` et `f8898980` | 0 et 0 |
| `git diff f6ac3658 f8898980 --stat` | 18 fichiers, +682 / -179, union exacte des 9 + 9, lignes identiques (md5 par fichier) |
| `dart analyze --fatal-infos` | No issues found (6,6 s) |
| `flutter test test/features` | +2550, ~2062 sautés, 0 échec |
| `flutter test test/core` | +649, 0 échec (23 suites, dont `revue_dossiers_depuis_validation_test` 14 et `revue_dossiers_vue_piece_test` 8) |
| `flutter test test/router` | +277, 0 échec |
| `flutter test test/widgets` | +271, 0 échec |
| `flutter test` sur les 26 autres dossiers | +1699, ~712 sautés, 0 échec |
| **Total fusion** | **5446 réussis, 2774 sautés, 0 échec**. Les 2773 lignes « Skip: » relevées portent toutes le motif « CAPTURE_DIR absent » |
| `mode_demonstration_test.dart` | +15, 0 échec |
| `dart run slang` puis `git status --short` | vide |
| `dart run tool/verifier_jetons.dart` | code 1, 39 violations, aucune dans les 18 fichiers fusionnés (non recomptées sur `f6ac3658` seul) |

## Contre-épreuves et mutations

### Contre-épreuves obligatoires de la branche A (`/home/user/wt/mut-ordre`, référence 42/42 sur les 5 fichiers de production)

| Mutation | Tests qui échouent | Verdict |
|---|---|---|
| **CE1** `surchargeRevueDossiersProduction` rebranchée (`apercu` + `deciderExistant` + `relire`, comme à `af20f6c2`) | -3 : `visionneuse_production_test` « production depuis la coque », `dossiers_admin_test` « AD-M3-PROD », `dossiers_sans_piece_test` « en production, aucun verdict avant BR-1 » (« Voir la pièce » et « Refuser le dossier » trouvés 1 fois) | **tuée** |
| CE1 aperçu seul rebranché | -3, les mêmes (« Voir la pièce » trouvé 1 fois) | **tuée** |
| CE1 décision seule rebranchée | -3, les mêmes (« Refuser le dossier » trouvé 1 fois) | **tuée** |
| **CE2** `revue_dossier.dart:82` `_lectureFaite => true` | -2 : les deux tests AD-T-LECTURE (attendu false, obtenu true) | **tuée** |
| CE2 bis `revue_dossier.dart:126` `_modifiable` sans la porte | -2, les mêmes | **tuée** |

### Autres mutations, branche A

| Mutation | Tests qui échouent | Verdict |
|---|---|---|
| 3a `peutRefuser = d.documentId != null` | -4 (AD-6 + les 3 de production) | tuée |
| 3b phrase de décision dite deux fois | -3 (trouvée 2 fois) | tuée |
| 3c « Voir la pièce » grisé, sans légende | -3 | tuée |
| 3c' bouton grisé avec légende gardée | -3 | tuée |
| 3d `_lire()` avant `AD-BR-06` | -1 (attendu 0 lecture, obtenu 1) | tuée |
| 3d' `_lire()` avant `AD-BR-03` | -1 | tuée |
| 3e démo : `peutRefuser: false` | -51 au compteur (répartition relevée : admin_ad11 39, decisions_coque 7, parcours_ad10 2, demo/dossiers_demo 4, soit 52 ; écart d'une unité non résolu) | tuée |
| 3e2 écran : `refusIndisponible = true` | -2 mesuré par la contre-vérification (`dossiers_sans_piece_test` et `revue_dossier_test` « 390 : Adam ») | tuée |
| 3f `peutValider: consultable` | 0 | **survit**, équivalente en production (`apercu` nul, donc `consultable` faux) |
| 3g `blocagesValidation` sans `blocagesDecision` | -1 | tuée |
| CTRL a : `_commencer` appelle `observerEnControle` | -1 | tuée |
| CTRL b1 : sans billet | -1 | tuée |
| CTRL b2 : billet d'une autre séance | -1 | tuée |
| CTRL b3 : `go('/salle?observer=1')` avec le billet | 0 | **survit** (CTRL-OBS-01) |
| CTRL c : plus de navigation | -1 | tuée |

### Branche B

| Mutation | Tests qui échouent | Verdict |
|---|---|---|
| DEMO a : `environnementDeclare = true` | 0 (+329 ~10) | **survit** (DEMO-ENV-1-M1) |
| DEMO b : `if (!declare)` (`kReleaseMode` ignoré) | -73 | tuée |
| DEMO c1 : défaut `publication = false` | 0 (+329 ~10) | **survit** (DEMO-ENV-1-M1, non testable sous `flutter test`) |
| DEMO c2 : `if (false)` à la place de la garde | -1 | tuée |
| AD9 onglet réservé pendant le chargement | -1 | tuée |
| AD9 titre pendant le chargement | -1 | tuée |
| AD9 titre dans toutes les erreurs | -3 | tuée |
| AD9 onglet dans toutes les erreurs | -3 | tuée |
| AD9 fichier remis à `af20f6c2` | -4 | tuée |
| AD9 `CapaciteIndisponible` traitée comme vraie | -2 | tuée |
| FOCUS contre-épreuve `dossiers_page.dart` de `af20f6c2` | -3 | tuée |
| FOCUS a : `_focusAuTitre` ne demande plus le focus | -5 | tuée |
| FOCUS b : seulement à 390 | -2 | tuée |
| FOCUS c : seulement à 1440 | -3 | tuée |
| FOCUS d : `_focusAuTitre()` aussi quand il reste un suivant | -1 (seul le test 390) | tuée à 390, invisible à 1440 (FOCUS-1, info) |
| DEFIL contre-épreuve `page_shell.dart` de `af20f6c2` | -1 (60 attendu, 0 obtenu) | tuée |
| DEFIL a : sans `initialScrollOffset` | -1 | tuée |
| DEFIL b : `initialScrollOffset` toujours 0 | -1 | tuée |
| DEFIL c : `ancien.dispose()` immédiat | 0 | survit (effet non observable) |
| DEFIL d : retrait de `_defileur?.dispose()` | 0 ; avec suivi des fuites : détectée | **survit** à la suite livrée (DEFIL-1) |
| DEFIL e : ancien jamais libéré | 0 ; avec suivi des fuites : 3 `ScrollController` détectés | **survit** à la suite livrée (DEFIL-1) |

## Défauts

### Bloquants

Aucun.

### Majeurs

Aucun.

### Mineurs

- **B3B-6 (c1-adm3). Commentaires faux depuis AD-M3-PROD.**
  `lib/features/admin_dossiers/revue_dossier.dart:30-31` (« `decider_dossier` en production »)
  et `lib/core/capacites/revue_dossiers_depuis_validation.dart:36-38` (« en production,
  ServiceValidation.apercu : le createSignedUrl »). L.8 de l'en-tête décrit le mécanisme du
  port, exact quand l'adaptateur est branché. Vrais à `af20f6c2`, rendus faux par `bf8c9972`
  dans des fichiers que la branche modifie. Coquille antérieure l.39 :
  « utoriser_lecture_piece_identite ». Correction : « à partir de BR-1 » ou renvoi à
  `surchargeRevueDossiersProduction`.
- **CTRL-OBS-01 (c1-adm3). « Billet seul » non verrouillé côté URL.**
  `test/features/controleur/controle_page_test.dart:192`. Le test ne compare que
  `routeur.state.uri.path` ; la mutation `go('/salle?observer=1')` passe (+9). Or
  `controle_page.dart:245` pose la règle « jamais par l'URL (ADR-005) ». Correction :
  `expect(routeur.state.uri.queryParameters, isEmpty)` ou comparer `uri.toString()`.
- **DEMO-ENV-1-M1 (c1-demoenv). Branchement réel de la garde non testé.**
  `lib/core/config/env.dart:105`, `lib/features/demo/mode_demonstration.dart:72-73`.
  `environnementDeclare = true` et `publication = false` par défaut survivent (0 échec). Le
  test injecte `declare` et `publication` en dur. Correction : `expect(Env.environnementDeclare,
  isFalse)` sous `flutter test` sans `--dart-define` (tue la mutation a). Le branchement sur
  `kReleaseMode` ne peut pas être testé en debug (`expect(kReleaseMode, isFalse)` serait une
  tautologie) : l'écrire dans la fiche comme gardé par la relecture, ou par une compilation
  `--release` sans ENVIRONNEMENT.
- **DEFIL-1 (c1-demoenv). Libération des défileurs non gardée par un test.**
  `lib/core/widgets/page_shell.dart:349-361`, `test/widgets/page_shell_etat_test.dart:132-167`.
  Mutations d et e survivent à la suite livrée ; le suivi des fuites (activé à titre
  temporaire, `LeakTesting.enable()`) les détecte et ne trouve aucune fuite sur le code réel.
  Code ajouté par la branche, dans un widget rendu par toutes les pages. Correction : un test
  de fuite ciblé, ou une configuration de suivi des fuites pour `test/widgets`.
- **AD9-M1 (c1-demoenv, antérieur). Pas d'état hors ligne distinct sur la page de politique.**
  `lib/features/admin_configuration_politique_kyc/politique_revue_kyc_page.dart:167-170`. Toute
  autre erreur donne `echecServeur`. Déjà à `af20f6c2`, atténué par l'`OfflineBanner`
  (`page_shell.dart:211`). Ne compte pas contre la branche ; à traiter dans le lot des états
  hors ligne admin.

### Cosmétiques

- **CTRL-OBS-02 (c1-adm3). Le test ne dit pas qu'il faudra l'inverser à BR-1.**
  `test/features/controleur/controle_page_test.dart:139-143`. Le commentaire dit « état
  actuel », « à brancher à BR-1 », et le pilotage (`CT-BR.md`) décrit le comportement attendu,
  mais le fichier ne dit pas que `observations, isEmpty` deviendra `equals([seanceId])`.

### Écartés ou reclassés par la contre-vérification

- **MUT-A-4** (proposé mineur, écarté) : « la phrase de refus non autorisé n'est vérifiée par
  aucun test de démo » est faux. `revue_dossier_test.dart:350-360` (cas « 390 : Adam », démo)
  vérifie le texte littéral ; la mutation 3e2 fait échouer 2 tests, pas 1. Les scénarios cités
  (politique hors portée, accord manquant) ne ferment pas le refus en démo
  (`dossiers_demo.dart:432-436`).
- **R-A-3** (proposé mineur, écarté) : aucun test de la branche A n'est sauté (51 succès,
  `skipped=false`) ; le nombre de `skip:` est identique à la base (165 = 165).
- **FOCUS-1** (proposé mineur, ramené à info) : le test « 1440 : valider passe au dossier
  suivant » et la branche de code avec suivant sont identiques à `af20f6c2`, et le cas sort de
  la fiche. Trou de couverture antérieur, à combler plus tard.
- **CAPT-4** (proposé cosmétique, ramené à info) : la pastille de statut étirée à 320×2 (point
  au bord, texte centré) vient de `StatusPill` (PASTILLE-COUPE-1, `284cd2b7`, règle K-54),
  inchangée par la branche. Le contre-vérificateur a cherché l'image au mauvais chemin
  (`/tmp/adm3_320x2_clair.png`) ; elle existe à `docs/revues/captures/C1-ADM3-DEMOENV-R/adm3_320x2_clair.png`. Son
  analyse repose sur le code et reste valable.

### Vérifié sans défaut (info)

- B3B-1 à B3B-5, B3B-7 à B3B-11 : fermeture en production, aucun autre chemin, démo inchangée,
  écran sans bouton grisé, adaptateur BR-1 fidèle, porte de lecture réelle, langue arabe en
  repli fr (antérieur), états de la file inchangés.
- MUT-A-1, MUT-A-2, MUT-A-5 : contre-épreuves et mutations tuées. MUT-A-3 : survivant
  équivalent en production.
- CTRL-OBS-03, 04, 05 : périmètre CTR-01, chemin par défaut exercé, pilotage cohérent (plage
  citée `service_video.dart:121-123` au lieu de `:120-123`).
- DEMO-ENV-1-I1 (profile), I2 (debug et CI), I3 (reste finance hors branche).
- AD9-I1, I2, I3. DEFIL-2, DEFIL-3. FOCUS-2 (titre sans anneau de focus visible, antérieur).
- R-A-1, R-A-2, B-INFO-1 à 3, FUS-1 à FUS-5.

## Captures vues

Ouvertes aussi par la session principale (K-61) : `adm3_1440_sombre_piece.png` (phrase de la pièce à la place de « Voir la pièce », « La décision est indisponible pour le moment. » une seule fois en bas, aucun bouton Refuser ni Valider, contraste lisible) et `adm3_320x2_clair_piece.png` (retours à la ligne entre les mots, aucun mot coupé, rien hors cadre).

Captures faites par cette revue avec un test temporaire (supprimé ensuite, `git status` vide)
sur `e68aad98` : vraie coque admin, vrai routeur, `surchargeRevueDossiersProduction`, polices du
dépôt, dossier de Moussa ouvert depuis Personnes / Dossiers. 15 PNG dans `docs/revues/captures/C1-ADM3-DEMOENV-R/`
(locaux, non commités) : pour chacun des cas 390 clair, 390 sombre, 1440 clair, 1440 sombre et
320 à texte ×2 clair, le haut de page, le bloc Pièce d'identité et le bas de page.

- **Pièce d'identité** (les 5 cas) : la ligne « Carte d'identité » porte « La consultation de
  la pièce est indisponible pour le moment. ». Aucun bouton « Voir la pièce » (`find.text` = 0).
- **Décision** (les 5 cas) : « La décision est indisponible pour le moment. » une seule fois,
  en bas de page sous les vérifications à 390 et 320×2, en pied de colonne à 1440. Ni
  « Refuser » ni « Approuver », actif ou grisé (`find.text` = 0). Les trois vérifications
  sont visibles.
- **Mise en page** : aucun mot coupé, chevauchement ni débordement à 390, 1440 et 320×2. À
  320×2 les mots passent à la ligne entiers (« indisponible / pour le moment. »). Titre sur
  2 lignes et sous-titre sur 4 à 320×2 : lisible, voulu par l'échelle.
- **Sombre** : cartes sur fond plus foncé, texte clair et libellé secondaire lisibles.
- **Pastille de statut à 320×2** : étirée, point au bord, texte centré (CAPT-4, antérieur).
- Limite : session admin de démonstration (repère absent car montée par `RewayahApp`) avec la
  revue et la pièce sur la vraie surcharge de production ; à 320×2, captures par
  `ensureVisible`, pas en continu ; file à un seul dossier.

Aucune capture de la branche B n'a été produite (10 tests de capture sautés sans
`CAPTURE_DIR`) : `ad9_14_indisponible_1440` reste à refaire.

## Fusion dans la branche commune

**Prête, pour les deux branches.** Base commune avec
`origin/corrections/revue-directeur-2026-10` @ `f6ac3658` : `af20f6c2`.

- Aucun fichier modifié des deux côtés : 0 pour `c1-adm3` contre `f6ac3658`, 0 pour
  `c1-demoenv` contre la première fusion. `c1-adm3` et `c1-demoenv` n'ont aucun fichier commun.
- `f6ac3658` (51 fichiers, dont le Centre de commande) ne touche ni `page_shell.dart` ni
  `lib/features/admin_dossiers`. Le Centre de commande ne fait que lire la file et naviguer
  vers `DossiersPage` : il n'ouvre ni aperçu ni décision en production.
- Fusion à blanc locale, HEAD détachée, jamais poussée : `e18485f4` (c1-adm3 dans
  `f6ac3658`) puis `f8898980` (c1-demoenv). `git diff f6ac3658 f8898980` : 18 fichiers,
  +682 / -179, union exacte des deux branches.
- Sur `f8898980` : analyze 0, `dart run slang` sans écart, suite complète **5446 réussis,
  2774 sautés, 0 échec** (features 2550, core 649, router 277, widgets 271, autres 1699).
- `verifier_jetons` : code 1, 39 violations, toutes hors des 18 fichiers fusionnés (dette de
  la branche commune).
- Ordre conseillé : `c1-adm3` d'abord (bloquant D1 avant toute fusion admin vers main), puis
  `c1-demoenv`. L'ordre inverse est sans risque de conflit (aucun fichier commun).

## Suivi proposé

Étapes proposées à la session principale (rien n'est créé par cette revue) :

1. **C1-ADM3-SUITE** (voie admin / corrections, petit) : B3B-6, corriger les commentaires
   `revue_dossier.dart:30-31` et `revue_dossiers_depuis_validation.dart:36-38` (et la coquille
   l.39). Facultatif (MUT-A-3) : assertion `peutValider == false` avec `apercu` branché et
   `deciderExistant` nul, pour figer la règle à BR-1.
2. **CTRL-BR-OBS-1b** (voie contrôleur, petit) : CTRL-OBS-01, ajouter
   `expect(routeur.state.uri.queryParameters, isEmpty)` ; CTRL-OBS-02, une phrase « à BR-1,
   inverser : observations == [seanceId] avant /salle, un refus reste sur CTR-01 ».
   Corriger aussi la plage en `service_video.dart:120-123` dans `CT-BR.md` (pilotage).
3. **AD-M2-PLANCHE** (voie admin, déjà prévue par l'auteur) : commiter les captures 390/1440
   clair/sombre de la revue en production. Les 15 PNG de `docs/revues/captures/C1-ADM3-DEMOENV-R/` montrent le rendu
   attendu et peuvent servir de référence.
4. **DEMO-ENV-1b** (voie corrections, petit) : DEMO-ENV-1-M1, test
   `expect(Env.environnementDeclare, isFalse)` sous `flutter test` ; écrire dans la fiche que
   le branchement sur `kReleaseMode` n'est gardé que par la relecture, ou ajouter une
   vérification CI sur une compilation `--release` sans ENVIRONNEMENT.
5. **AD-M4-DEFIL-b** (voie socle, petit) : DEFIL-1, test de fuite ciblé sur
   `page_shell_etat_test` (ou configuration du suivi des fuites pour `test/widgets`), qui
   fasse échouer les mutations d et e.
6. **AD9-CAPTURE** (voie admin) : refaire `ad9_14_indisponible_1440` (reste déclaré).
7. **ADMIN-HORS-LIGNE** (voie admin, lot des états hors ligne) : AD9-M1, état
   `NatureEtat.horsLigne` sur la page de politique de genre.
8. Hors lot, à garder en tête : FOCUS-1 (assertion de focus au test « 1440 : valider passe au
   dossier suivant ») ; CAPT-4 (pastille étirée, composant `StatusPill`) ; DEMO-ENV-1-I1
   (`!kDebugMode` si l'on veut fermer aussi le profile).


## Audit du rapport

Un auditeur en contexte neuf a relu chaque chiffre contre les résultats bruts et revérifié dans le dépôt les affirmations clés (fermeture de `surchargeRevueDossiersProduction`, aucun appel à `observerEnControle`, 2c565f68 sans `lib/`, totaux 5366 / 5366 / 5446). Verdicts jugés conformes à la règle. Cinq écarts de détail relevés (numéros de ligne, décompte de dossiers, une somme) : tous corrigés dans cette version.

## Fusion réelle dans la branche commune (04/10, session 01MrLWqB)

Sur demande du directeur (étape menée de A à Z), `c1-adm3` puis `c1-demoenv` ont été fusionnées dans
`corrections/revue-directeur-2026-10`, partie de `ddd24db7` (qui avait avancé depuis la fusion à blanc
sur `f6ac3658` : c2-elv-err, c2-coupe2, c2-bento3b).

| Contrôle | Résultat |
|---|---|
| Fusions | `336b4297` (c1-adm3), `08a27c2e` (c1-demoenv), aucun conflit |
| Fichiers des deux branches identiques à leur source dans la fusion | oui (aucun fichier touché des deux côtés) |
| Fichiers de la branche commune conservés | 246 contrôlés, aucune perte |
| `dart analyze --fatal-infos` | No issues found |
| `tool/verifier_jetons.dart` | 39 relevés, identique à `ddd24db7` |
| `tool/verifier_revue.dart` | 1609 |
| `flutter test` (suite complète) | 5470 réussis, 0 échec, 2774 sautés |

Poussé en avance rapide (`ddd24db7..08a27c2e`), sans forcer.
Les captures de la revue sont versionnées dans `docs/revues/captures/C1-ADM3-DEMOENV-R/` (15 PNG).
