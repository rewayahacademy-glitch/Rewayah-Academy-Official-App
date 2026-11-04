# Le code non branché, décision du directeur du 01/11/2026

Décision écrite par le pilote, sur ordre du directeur relayé par le garde-cap le 01/11/2026 vers
05:40 (GMT+3). Elle s'ajoute à `INVENTAIRE-NON-BRANCHE-2026-10-31.md`, qui décrit et n'empêche
rien.

## 1. Ce que le directeur a dit

« Le problème des implémentations non branchées revient encore et encore, aucune stratégie
claire pour le régler une fois pour toutes. »

Vérité, dite telle quelle : jusqu'à ce jour, il n'y avait aucune stratégie. L'inventaire du 31/10
décrit, il n'empêche rien, et le garde-fou ne vérifie pas le branchement.

## 2. Trois règles, toutes vérifiées par une machine

### R1. Aucun code sans écran

Un fichier de `lib/` que l'application n'atteint pas depuis `lib/main.dart` fait échouer la
vérification. On suit les imports, les exports et les `part`, de proche en proche, y compris les
imports conditionnels.

- Vérificateur : `dart run tool/verifier_branchement.dart`. C'est du Dart pur, sans dépendance
  (`pubspec.yaml` appartient au directeur).
- La démonstration (`lib/features/demo/`, compilée hors production par `Env.demoCompilee`) et la
  galerie (`lib/features/_dev/`) sont des outils. On ne les suit pas : un module atteint
  **seulement** par la démonstration n'a pas d'écran en production, et il sort comme non atteint.
- Les fichiers tolérés pour un temps sont listés dans `tool/branchement_tolere.txt`. Cette liste
  ne fait que rétrécir. Trois cas font échouer :
  - une ligne ajoutée ;
  - une ligne absente de la liste de `main` ;
  - un dépassement du plafond écrit en tête du fichier.

  Quand un fichier toléré est branché ou supprimé, le vérificateur exige qu'on retire sa ligne et
  qu'on baisse le plafond dans la même PR.
- Le vérificateur est appelé :
  - dans la liste « Vérifier avant de dire que c'est fait » de `CLAUDE.md` ;
  - dans `tool/e2e/pile.sh`, quand la pile E2E (PR 107) sera dans `main` ;
  - dans `.github/workflows/ci.yml`, ligne à coller par le directeur (`.github/` lui appartient) :

    ```yaml
          # Branchement (decision du directeur du 01/11/2026, R1 et R2) : aucun
          # fichier de lib/ sans chemin depuis lib/main.dart hors de la liste
          # toleree, qui ne fait que retrecir par rapport a main.
          - name: Verifie le branchement
            if: matrix.target == 'web'
            run: |
              git fetch --no-tags --depth=1 origin main:refs/remotes/origin/main || true
              dart run tool/verifier_branchement.dart
    ```

    Elle se place dans `.github/workflows/ci.yml`, juste après l'étape « Verifie les invariants
    de l'etape 2 » (`dart run tool/verifier_jetons.dart`). Le `git fetch` sert la comparaison avec
    la liste de `main` : la copie de la CI n'a qu'un commit.

### R2. Une issue datée par ligne tolérée

Chaque ligne de `tool/branchement_tolere.txt` porte une issue et une échéance : « branché à
l'étape X » ou « supprimé le JJ/MM ». Pas de « plus tard ». Le vérificateur refuse toute autre
forme.

Premier relevé, le 01/11/2026 (sur `main` après les PR 100 et 108) : **50 fichiers non atteints**.

- 2 sont branchés à l'étape 3 de la Boucle 1, pour l'élève adulte (FN-112), au plus tard le
  15/11/2026.
- 14 sont branchés à l'étape « Listes », après la Boucle 1. Ce sont les moteurs de recherche par
  domaine : la recherche de toute vue de gestion est exigée par
  `DECISION-LISTES-2026-10-23.md`. Ces moteurs ne doublonnent rien : l'écran de recherche est
  branché, mais `moteursRechercheProvider` est vide en production et l'écran dit « Recherche
  indisponible pour le moment. » (`lib/core/recherche/port_recherche.dart`). Leur échéance, le
  30/11/2026, est **proposée par le pilote** : la Boucle 1 n'a pas de date de fin écrite.
- 34 sont **proposés à la suppression** pour le 08/11/2026. Ce sont :
  - des doublons de modules branchés (inventaire du 31/10) ;
  - des données de démonstration rangées hors de `features/demo`, à y déplacer ;
  - des interfaces sans usage.

  **Seul le directeur décide** d'une suppression, sur la liste précise du fichier. S'il en garde
  un, sa ligne prend une issue « branché à l'étape X » avec une date.

### R3. La preuve d'écran, pour ce que R1 ne voit pas

R1 ne voit pas un fichier importé dont un paramètre n'est jamais passé. Exemple : le chrono de
la salle (FN-023). `chrome_seance.dart` est atteint, mais `depuis_salle.dart` ne lui donne jamais
`chrono:`.

- La fiche d'écran du lot dit ce qui doit être visible.
- Toute PR de construction joint la capture du parcours robot sur la pile locale. Le robot vérifie
  le texte attendu (par exemple « min restantes »).
- **Pas de capture, pas de fusion.** Le pilote ne fusionne aucune PR de construction sans son
  dossier `docs/current/captures/E2E/<lot>/`. La règle s'applique dès le 01/11, à commencer par
  la PR FN-023 et FN-026.

## 3. La limite, dite telle quelle au directeur

- R1 attrape les modules morts entiers.
- R3 attrape le reste, à condition qu'une fiche d'écran l'ait demandé.
- **Aucune règle n'attrape ce qu'aucune fiche d'écran n'a demandé.** Exemple : un fournisseur
  atteint dont la valeur en production reste un bouchon (`CapaciteIndisponible`). Il est importé,
  donc R1 le voit branché. Ces bouchons restent listés dans l'inventaire du 31/10, section B et
  suivantes.
