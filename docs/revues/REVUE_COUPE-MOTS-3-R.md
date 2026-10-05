<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Revue adverse COUPE-MOTS-3 : branche `corrections/c2-coupe-mots-3` (7c411acf)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les trois mots coupés relevés par les revues sont corrigés, et je l'ai prouvé par mutation et par mes propres captures. Il ne reste aucun défaut majeur dans le périmètre. Les réserves sont mineures ou de processus.

Statut : **présent dans le code et testé localement** (vérifié par moi). L'étape n'est **ni testée sur staging, ni déployée**.

### 1. La demande est-elle remplie ?

| Point demandé | Constat |
| :--- | :--- |
| « Chapit / re 1 » (Espace Classe enseignant, Interface guidée, 320 px x2) | **Corrigé.** `_ProgressionClasse` mesure le mot le plus long avec `largeurMotLePlusLong`. S'il ne tient pas dans sa moitié de ligne, la barre passe dessous et le texte prend toute la ligne en `TexteSansCoupure`. Sinon, la rangée d'origine reste (vérifié à 390x1 et à 1440). Le pourcentage est insécable (`{pourcentage} %`). La « Préparation » (« compréhension ») passe aussi en `TexteSansCoupure`. |
| « 8,1 / Mo » (espace insécable au point de formatage partagé) | **Corrigé.** Le point de formatage est `lib/core/i18n/taille_fichier.dart`, avec `tailleFichier(nombre, unite)` et `lierTaillesFichier(texte)`. `RessourceDemo.taille` passe par `tailleFichier`, et `BlocBibliotheque` applique `lierTaillesFichier` au `shortTitle`. Les trois messages fr « {taille} Mo » sont insécables. Il n'existe dans `lib/` aucun autre formatage de taille en « Mo/Ko » (grep). |
| Titre `controleur.observation.questionRecap` (« obse / rvation ») | **Corrigé.** Dans `PageParcours`, la question et l'explication passent en `TexteSansCoupure`. Dans `_Souscription`, la notice et le message d'échec font de même : « automatiquement » et « l'administration. » étaient coupés en Interface guidée. |
| Tests 320 x2, LTR/RTL, standard et guidée, avec contre-épreuve | **Présents.** `test/features/coupe_mots_3_test.dart` compte 15 tests, verts. La vraie locale ar est utilisée. |
| Captures avant/après | Le rédacteur en fournit 16, à 320x2 en clair. Je les ai ouvertes. Elles montrent bien le défaut avant et la correction après. |

### 2. Mutations refaites par moi (dans un worktree jetable)

- Tout l'ancien code (lib et i18n de 4207c357, en gardant seulement `taille_fichier.dart`) : **9 échecs**. Ils nomment `observation`, `8,1 Mo`, `Chapitre` et `8 Mo`.
- `empile` forcé à `false` : **2 échecs** (fr et ar guidée) : `['Chapitre 1 · 60 % : Chapitre']`.
- `PageParcours` revenu à `Text` : **4 échecs** sur `observation`.
- `_Souscription` revenu à `Text` : **2 échecs**.
- `_Preparation` revenu à `Text` : **2 échecs** sur `compréhension`.
- Espace ordinaire dans `espaceInsecableTaille` : **4 échecs** sur `8,1 Mo`.
- Espace ordinaire dans `progressionValeur` (fr et ar, slang régénéré) : **2 échecs** sur `60 %`.

Les tests mordent sur chaque correction. Une limite : remplacer `lierTaillesFichier` par l'identité dans `emplacements_groupe.dart` ne ferait échouer aucun test d'écran. La démo pose déjà l'espace insécable en amont, et seul le test unitaire couvre cette fonction (réserve mineure).

### 3. Captures que j'ai produites et ouvertes

J'ai écrit un script jetable, supprimé ensuite. Il couvre 36 cas, tous verts, avec `motsCoupes`, `mesurerTailles` et `verifierEcranSansMotCoupe` :

- **Écrans :** Espace Classe enseignant, cadré sur la Progression puis sur la Préparation, et récapitulatif de l'observation.
- **Formats :** 320x2 sombre (standard et guidée), 390x1 et 390x2 clair guidée, 1440x1 sombre standard, 1440x2 clair guidée.
- **Langues :** fr et ar.

Ce que montrent les captures :

- **320x2 guidée :** « Chapitre 1 · / 60 % » passe à la ligne entre les mots, avec la barre dessous. « Audio, / 8,1 Mo » se lit sans coupure. Le titre « Vérifiez / votre / observation / avant / l'envoi. » ne coupe aucun mot.
- **390x1 et 1440 :** la rangée texte + barre est conservée. Il n'y a ni régression ni débordement, et aucune exception.
- **Thème sombre :** le rendu est correct. Je n'ai relevé aucun bouton grisé ni aucune couleur hors jetons.

### 4. Contrôles

- **`dart run slang` :** OK, sans écart au dépôt.
- **`dart analyze --fatal-infos` :** 0 problème.
- **`verifier_revue` :** 1567 violations, contre 1568 sur la base 4207c357, que j'ai mesurée moi-même. Aucune violation nouvelle.
- **`verifier_jetons` :** 39, comme sur la base. Aucun fichier modifié n'apparaît.
- **`flutter test --concurrency=2` :** passé sur `test/features`, `test/accessibilite`, `test/core`, `test/parcours`, `test/router`, `test/teaching_core` et `test/widgets` : **+5850 ~2231, All tests passed**.
  - Ces dossiers couvrent les autres appelants de `PageParcours` : `parcours_offres`, `complement_rapport` et la galerie.
  - Ils couvrent aussi `RessourceDemo`, `espace_classe_eleve` et les tests de photo et KYC.
- **Règles du dépôt :**
  - Les zones interdites sont intactes : `supabase/`, `.github/`, `pubspec.yaml`, thème, rendu du Coran, `dart_define`.
  - Je n'ai trouvé ni secret, ni lecture de rôle, ni branchement serveur. `serveur: []` est donc cohérent.
  - Les deux commits sont en français et finissent par les deux lignes exactes. Aucun identifiant de modèle n'apparaît ailleurs.

### 5. Réserves

1. **[mineur]** Les captures livrées s'arrêtent à 320x2 clair. Je les ai complétées de mon côté en sombre, à 390 et à 1440, sans trouver de défaut. Je recommande d'archiver un jeu sombre, 390 et 1440 lors d'une prochaine étape.
2. **[mineur]** `lierTaillesFichier` n'est gardé que par un test unitaire. Un test d'écran avec une `LibraryResource` dont le `shortTitle` contient « 8,1 Mo » avec une espace ordinaire protégerait le chemin des données réelles.
3. **[processus]** Quatre libellés (espace insécable seule) attendent la validation du directeur : `kyc.tropVolumineux`, `ficheEleve.informations.tropLourde`, `tuteur.reglages.photoTropLourde` et `classe.entree.progressionValeur`.
4. **[préexistant, hors périmètre, déclaré]** Le texte français est réordonné en RTL (« % 60 », « .l'envoi », « · Élève précis »). Il faut une étape dédiée : clés ar validées ou isolats bidi.

Les worktrees jetables `rv-COUPE-MOTS-3-12` et `rv-cm3-base` ont été retirés. Rien n'a été poussé.