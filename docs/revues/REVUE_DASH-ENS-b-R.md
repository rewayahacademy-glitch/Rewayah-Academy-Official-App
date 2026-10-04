# Contre-revue du lot DASH-ENS-b (`corrections/c2-ens-b`, tête ae2d03bc) : acceptée avec réserves

## Verdict

**Acceptée avec réserves.** Le seul défaut majeur des deux rapports est levé : l'état vide d'« À terminer » coupait le mot « transmission ». J'ai refait la preuve d'origine sur la nouvelle tête, puis j'ai cherché d'autres coupures. Le nouveau test du lot couvre déjà 320 px avec texte à 200 %. Mon test jetable ajoute 320, 390 et 1440 px, aux échelles 1 et 2, en LTR et en RTL, en clair et en sombre, sur les trois pages et dans tous les états, soit 360 cas : aucun mot coupé.

Les six corrections mineures annoncées sont réelles. Les nouveaux tests sont discriminants : ils échouent dès qu'on annule la correction qu'ils couvrent. Il ne reste que des réserves mineures (voir « Défauts restants »).

## Contexte

- Lot relu : `origin/corrections/c2-ens-listes..origin/corrections/c2-ens-b`. Il compte deux commits :
  - a3bbbbc1 (code, tests, libellés) ;
  - ae2d03bc (10 captures et leur script).
- Fichiers lib et outils touchés :
  - `lib/features/journee/journee_page.dart` (`_EchecLecture`, commentaire de la page) ;
  - `assets/i18n/fr.i18n.json`, avec `strings*.g.dart` régénérés ;
  - `tool/libelles_sources.json`.
- Tests touchés :
  - `test/features/journee/listes_journee_test.dart` (nouveau) ;
  - `test/router/parcours_enseignant_test.dart` (4 tests ajoutés).
- Hors périmètre : rien n'a changé dans supabase/, .github/, vercel.json, pubspec.yaml ni lib/core/theme. Aucun branchement serveur, aucune lecture de rôle.
- Les deux messages de commit se terminent exactement par les deux lignes demandées.
- Défauts à lever :
  - **REVUE_DASH-ENS-ROUTE-R** : 1 majeur, la coupure de « transmission » relevée en contre-revue, et 3 mineurs.
  - **REVUE_DASH-ENS-LISTES-R** : 3 mineurs du premier relecteur et 2 mineurs de la contre-revue.

## Commandes et résultats

Tout a été fait dans le worktree jetable `rv-ENS`, détaché sur ae2d03bc. Il est retiré.

| Commande | Résultat |
| :--- | :--- |
| `flutter pub get`, puis `dart run slang` | Aucun écart : le code généré est à jour |
| `dart analyze --fatal-infos` | No issues found |
| `dart run tool/verifier_revue.dart` | 1627 sur la tête comme sur la base `c2-ens-listes` ; une fois les numéros de ligne retirés, les deux listes sont identiques |
| `dart run tool/verifier_jetons.dart` | 39 |
| `test/features/journee/` + `parcours_enseignant_test.dart` | +77 ~30 tous passent ; les 30 sautés sont des captures, CAPTURE_DIR étant absent |
| Tests qui montent la Journée : journee_test, rtl_echelle_texte_ecrans, q01, navigation_reelle, mes_classes, demo_enseignant, plus test/features/journee | +202 tous passent |
| `test/router` + `test/accessibilite` | +613 tous passent |

Toutes les suites ont tourné avec `--concurrency=2`, une seule à la fois.

## Défaut majeur : preuve d'origine refaite

**Sur l'ancien libellé.** J'ai remis le `fr.i18n.json` de la base, régénéré avec slang, puis lancé les tests. Ils échouent :
- `A terminer ltr vide` et `A terminer rtl vide`, avec `Actual: ['Aucun cahier de transmission à terminer. : transmission']`. C'est exactement la preuve de la contre-revue.
- Le nouveau test trouve aussi `Remplacements ltr/rtl vide`, avec `Actual: ['Aucun remplacement confirmé pour le moment. : remplacement']`. C'est un second défaut du même type, réel lui aussi, que le rédacteur a corrigé.
- Le test WCAG 2.5.3 échoue, avec `Actual: 'Voir les 5 remplacements confirmés'`.

**Sur la tête.** Tous ces tests passent.

**Recherche élargie.** J'ai écrit un test jetable `test/zz/rv_ens_test.dart` avec les vraies polices (`chargerPolicesDuDepot`) et `motsCoupes` :
- pages : À terminer, Remplacements, Alertes ;
- états : chargement, contenu, vide, erreur, hors ligne ;
- largeurs : 320, 390, 1440 ;
- échelles : 1 et 2 ;
- sens : LTR et RTL ;
- thèmes : clair et sombre.

Résultat : **+360, tous passent**. Il n'y a ni mot coupé, ni exception de rendu.

## Contre-épreuves : chaque correction annulée pour de vrai

| Mutation | Tests qui échouent |
| :--- | :--- |
| Anciens libellés remis | 4 tests de mot coupé (vide, LTR et RTL, deux pages), plus le test WCAG 2.5.3 |
| `_EchecLecture` forcé en `echecServeur` avec sa phrase | « A terminer : hors ligne » et « Alertes : hors ligne » |
| `AlignmentDirectional.topStart` remplacé par `Alignment.topLeft` sur les 3 pages | les 3 tests du miroir RTL |
| `onRetour: () {}` | « ouverte directement… » et « ouverte par un push… » |
| Pluriel forcé (`voirAutresAlertes(nombre: "1")`) | « trois alertes : Voir l autre alerte, au singulier » |
| Branche `else go(Journée)` de `_retourVersJournee` retirée | **aucun** (voir le mineur 3) |

Après chaque mutation, j'ai restauré le fichier et vérifié avec `git status` qu'il était propre.

## Défauts mineurs des rapports : où ils en sont

**DASH-ENS-ROUTE-R**
- **Mineur 1, état hors ligne** : levé. `_EchecLecture` lit `horsLigneProvider`. Sans réseau, la page affiche `NatureEtat.horsLigne` avec « Réessayer » ; avec réseau, elle garde l'échec serveur et sa phrase K-59. Une lecture ratée n'est jamais présentée comme « rien à afficher » (D10).
- **Mineur 2, couverture de test** : levé. Il y a maintenant un test `aucun_mot_coupe` à 320 px ×2, en LTR et RTL, dans tous les états. Il y a aussi un test du retour et des captures RTL et de chargement. Une limite reste : voir le mineur 3 ci-dessous.
- **Mineur 3, libellés à valider** : toujours ouvert. Seul le directeur peut le lever.

**DASH-ENS-LISTES-R**
- **Libellé orphelin `autresAbsences`** : levé. Il est retiré, il ne reste aucune référence dans lib ni dans test, et `ar.i18n.json` n'avait pas cette clé.
- **Source des remplacements en mémoire de session, et remplacements passés non filtrés** : toujours ouverts. Ils dépendent du serveur et d'une décision produit, et le rédacteur les a correctement consignés.
- **WCAG 2.5.3** : levé. Le nom accessible est « Voir tout : les N remplacements confirmés ».
- **Pas de test du singulier ni du RTL** : levé, avec des tests discriminants.

## Captures

J'ai ouvert les 10 PNG de `docs/current/captures/DASH-ENS-b/` :
- `a_terminer_vide` à 320×2, en LTR clair et en RTL sombre ;
- `remplacements_vide` à 320×2, en LTR clair et en RTL sombre ;
- `a_terminer_horsLigne`, à 390 en clair et à 320×2 en sombre ;
- `alertes_horsLigne` à 320×2, en RTL clair ;
- `alertes_contenu` à 320×2, en RTL sombre ;
- `a_terminer_contenu` à 320×2, en RTL clair ;
- `a_terminer_chargement` à 390, en clair.

Ce que j'y vois :
- Aucun mot coupé et aucun chevauchement.
- En RTL, la mise en page est bien en miroir : disque de retour à droite, flèche vers la droite.
- Hors ligne, le bandeau « Pas de réseau » et la carte « Vous êtes hors ligne » avec « Réessayer » ne se contredisent pas.
- En RTL, le point final passe en tête de ligne (« .terminés »). C'est le comportement bidi normal pour du texte français sans traduction arabe ; ce n'est pas un défaut.

## Défauts restants (tous mineurs)

1. **Libellés à valider.** `aTerminerVide`, `aTerminerErreur`, `remplacementsVide` et `voirTousRemplacements` ont été rédigés par l'agent et attendent la validation du directeur.
2. **Remplacements (serveur, BR-1).** La source n'est qu'une mémoire de session qui repart vide après un rechargement, et les remplacements passés ne sont pas filtrés. Défaut antérieur au lot et consigné.
3. **Branche `go(Journée)` non testée.** Dans `_retourVersJournee`, cette branche n'est couverte par aucun test et ne sert sans doute jamais : la sous-route empile toujours la Journée, donc `canPop()` vaut vrai. Le comportement attendu est vérifié quand même, puisque le retour ramène bien à la Journée.
4. **Observations sur des composants partagés, hors du lot.**
   - À 320×2, le titre « Remplacements confirmés » s'affiche nettement plus petit que « À terminer » : le titre semble se réduire, sans doute sous 200 %. C'est à vérifier dans PageShell.
   - La carte hors ligne dit « Ce qui est déjà affiché reste consultable » alors que la liste n'affiche rien.

## Conclusion

Il ne reste aucun défaut majeur prouvé. Les corrections sont réelles et discriminantes, et elles n'introduisent ni régression ni nouveau mot coupé. Le verdict est donc **ACCEPTEE_AVEC_RESERVES**.
