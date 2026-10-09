<!-- verdict : REFUSEE -->
# Relecture adverse de RTL-ISOL-1 (corrections/c2-rtl-isol, 15ce96f4)

## Verdict : REFUSÉE

Les corrections à l'écran sont justes : mes mutations et les captures le prouvent. Mais l'isolat ajouté dans `EmptyState` fait échouer **6 tests existants**. Pousser sur `main` déclenche la CI, et une suite rouge bloque la fusion. Ce défaut est majeur et il est prouvé. Le rédacteur ne l'a pas vu, car il n'a lancé ni `test/core` ni la totalité de `test/features`.

## Méthode

J'ai travaillé en lecture seule, dans un worktree détaché sur `origin/corrections/c2-rtl-isol` (15ce96f4), que j'ai retiré à la fin. Rien n'a été poussé.

- Le commit unique est bien posé sur 5a52ff30.
- Aucun fichier interdit n'est touché : supabase, .github, vercel, pubspec, thème, Coran, page_shell, feuille_carte_classe, bloc_cartes_classe.
- Le commit se termine par les deux lignes exactes. Aucun autre identifiant de modèle n'apparaît dans le diff.

## Contrôles

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `verifier_revue` | 1533, contre 1533 sur la base (lib/ remis à HEAD~1) |
| `verifier_jetons` | 37 signalements, dont aucun sur les fichiers modifiés |
| `rtl_isol_1_test.dart` | 19 sur 19 passent |
| **test/features**, `--concurrency=2` | **+3052 ~2166 -4** |
| **test/core et tous les autres dossiers** (sauf capture, fixtures, support), `--concurrency=2` | **+3576 ~199 -2** |

## Défaut majeur : régression dans les tests

Les tests en échec cherchent le texte exact par `find.text(...)`. Avec l'isolat (FSI…PDI), le texte rendu en RTL ne correspond plus, et la recherche ne trouve rien.

- `test/core/widgets/empty_state_sans_coupure_test.dart` : cas « standard, 320 px, texte x2, rtl » et « enfant, 320 px, texte x2, rtl ». Erreur `Bad state: No element`, ligne 54, `find.text(_message)`.
- `test/features/accueil_eleve_test.dart:1341` : ELV-02, cas standard et enfant, à 320 px x2 et à 1440 px x1, en RTL. Erreur `Found 0 widgets with text "Pas de cours aujourd'hui"`.

**Preuve de la cause :** j'ai remis **seulement** `lib/core/widgets/empty_state.dart` à l'état de 5a52ff30. Les deux fichiers passent alors en entier (+60, All tests passed).

**Correction attendue :** adapter ces assertions, par exemple chercher le texte isolé ou passer par `find.textContaining`, comme l'a fait COUPE-MOTS-3b pour `coupe_mots_3_test.dart`. Relancer ensuite toute la suite, dossier par dossier.

## Ce qui est bien fait (prouvé)

### Mutations faites par moi

J'ai remis un seul fichier à l'état de la base à la fois. Chaque fois, le cas arabe correspondant échoue :

| Fichier remis à la base | Test qui échoue |
| :--- | :--- |
| `emplacement_entree` | durée |
| `empty_state` | fiche de séance |
| `bloc_seance` | conseil d'appareil |
| `comptes_page` | introduction |
| `fiche_groupe_page` | ligne des élèves |
| `ma_classe_adulte_page` | À propos |

Dans `observation_controle_page`, j'ai retiré un à un les isolats de la nature, du domaine, de l'explication et de l'échec. Chaque retrait fait échouer son test.

### Captures ouvertes

- **Avant / après, ar, 320 x2 :**
  - « h 28 3 » devient « 3 h 28 » ;
  - « .l'enseignant » devient « l'enseignant. » ;
  - « .tajwid » devient « tajwid. » ;
  - « .endroit » devient « montre. ».
- **Pages entières 320 x2 de l'Espace Classe, enseignant et élève :** la pastille « 3 élèves sur 6 places », le conseil d'appareil et la progression « 1 · 60 % » sont visibles et justes. La réserve 1 de COUPE-MOTS-3b est donc levée.
- **Ligne des élèves :** à 320 x2 et à 1440, elle se lit dans l'ordre « Niveau 1 · الاستئناف: Page 24 », avec le séparateur et les deux-points à leur place.
- **390 sombre :** vérifié.
- **1440 clair et sombre, fr et ar :** le rédacteur n'en avait pas fourni. Je les ai produites moi-même, avec une copie jetable de son script de capture, et elles sont justes.
- **Interface guidée :** sans objet pour ce lot.
- **Hors périmètre :** dans Comptes, « GUARDIAN- / FB-000003 » est coupé à son tiret. Ce défaut existait déjà avant et ne relève pas de cette étape.

## Réserves mineures, à traiter avec la reprise

1. Aucun test ne vérifie les variantes salleOuverte et attente (dont le tutoiement), l'invitation d'EmptyState, ni la ligne de progression de Ma classe.
2. La décision DIR-REP-1 sur la ligne des élèves n'est consignée dans aucune fiche de `docs/current/`.

## Pour lever le refus

1. Adapter `empty_state_sans_coupure_test.dart` et `accueil_eleve_test.dart` (ELV-02) au texte isolé.
2. Chercher d'autres `find.text` qui visent un message d'EmptyState en RTL.
3. Relancer **toute** la suite avec `--concurrency=2`, dossier par dossier, et la donner verte.

Statut : testé localement seulement, et pas vert. Pas testé sur staging, pas déployé.
