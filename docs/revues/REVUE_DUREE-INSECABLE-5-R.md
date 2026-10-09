<!-- verdict : REFUSEE -->
<!-- verdict : REFUSEE -->
# Relecture adverse : DUREE-INSECABLE-5, branche `corrections/c2-duree-5` (e1a3ea54)

**Verdict : REFUSÉE.**
- Le point (1) est rempli et prouvé.
- Le point (2) ne l'est pas. La garde rate encore le défaut exact de `data_collection.dart` dès qu'il est écrit avec un objet au type inféré (variable locale, lambda ou boucle non typées). Elle rate aussi la valeur rangée dans un champ par affectation.
- La demande disait « la garde doit trouver tous ces cas », « à lever ABSOLUMENT ».

## Méthode

- Deux worktrees jetables, détachés sur `origin/corrections/c2-duree-5` :
  - `rv-DUREE-INSECABLE-5-81` pour la suite de tests ;
  - `rv5-mut` pour les mutations et les fixtures adverses.
- Les deux sont retirés. Rien n'a été poussé ni commité.
- J'ai lu `REVUE_DUREE-INSECABLE-4-R3.md` sur `origin/revues/2026-10-04-b061fd81`.
- Le diff propre à l'étape, `c9c647e5..e1a3ea54`, touche :
  - `lib/core/widgets/data_collection.dart` ;
  - `test/support/garde_ancres.dart` ;
  - `test/accessibilite/duree_insecable_5_test.dart` ;
  - le script de capture et les captures ;
  - la fiche `REVUE-DIRECTEUR-2026-10.md`.
- Aucun fichier interdit n'est touché : ni `supabase/`, ni `.github/`, ni `pubspec`, ni le thème, ni le Coran.
- Les commits se terminent par les deux lignes exactes demandées.

## Contrôles

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_revue` | 1530, identique à la base mesurée avec le `data_collection.dart` de c9c647e5 |
| `verifier_jetons` | 37, identique à la base |
| `duree_insecable_5_test` et `duree_insecable_4_test` | +26, 0 échec |
| `flutter test --concurrency=2` sur test/core, test/widgets et test/accessibilite | rc=0 sur les trois |
| `flutter test --concurrency=2` sur test/features | +2402, 2017 sautés, **0 échec** quand je l'ai arrêté, inachevé |
| Autres dossiers de test | non lancés |

Appelants de `DataCollection` (13 fichiers de `lib/`) : aucun n'est sous `IntrinsicHeight` ou `IntrinsicWidth`, donc le `LayoutBuilder` ajouté ne pose pas de risque.

## Mutations faites par moi

| Mutation | Effet |
|---|---|
| M1 : remettre le libellé fautif dans `_Cellule` | 8 échecs |
| M2 : remettre la garde de DUREE-4 | 2 échecs (contre-épreuve et fixtures) |
| M3 : `data_collection.dart` sans le correctif de hauteur, avec `sansAncre` gardé | 3 échecs (Qualité) |

Ces chiffres sont conformes au compte rendu du rédacteur.

## Point (1) : REMPLI

- `_Cellule` produit maintenant `'${colonne.titre} : ${sansAncre(colonne.texte(ligne))}'`. Le texte affiché, seul dans sa cellule, garde son ancre.
- La correction est faite dans le composant partagé. Elle vaut donc pour tous les appelants en mode tableau.
- Les colonnes « Depuis » et « Attente » sont `secondaire` : en cartes, elles passent par `enchainer`.
- L'arbre sémantique est vérifié à 1600 px, en LTR et en RTL, sur les vraies pages Comptes, Progression et Qualité.
- Correctif annexe sur la hauteur non bornée de Qualité : il est justifié, prouvé par M3 et sans régression observée.

## Point (2) : NON REMPLI

Les motifs listés par la R3 sont maintenant détectés :
- fonction avec argument positionnel ou nommé ;
- `this.v` positionnel ;
- `StringBuffer` ;
- `replaceAll` ;
- `add` puis `join` ;
- `copyWith`, Map, record.

Les 11 fixtures du rédacteur passent. Mes propres fixtures détectées :
- variable locale typée ;
- liste d'initialisation `: duree = d` ;
- `Map.values.join` ;
- record positionnel ;
- concaténation par `+` ;
- champ nullable `colonne?.texte` ;
- constructeur positionnel vers un champ privé.

**Mais la garde ne reconnaît un objet de la classe que par un type écrit** (`ColonneDonnees<T> x`), par `final x = Classe(` ou par `widget`. Preuves sur le vrai `data_collection.dart`, `analyze` restant à 0 problème à chaque fois :

| Variante du défaut | Garde sur lib/ | Autres tests |
|---|---|---|
| V3b `final col = colonne;` puis `'${col.titre} : ${col.texte(ligne)}'` | **RIEN** | 7 échecs sémantiques |
| V5 `for (final col in <ColonneDonnees<T>>[colonne]) libelle = '${col.titre} : ${col.texte(ligne)}'` | **RIEN** | 7 échecs sémantiques |
| V4b carte : `secondaires.map((col) => col.texte(ligne)).where(...).join(' · ')` | **RIEN** | duree_insecable_5 passe entièrement ; seul duree_insecable_4 échoue (2) |

- Avec le nom `c`, ces variantes sont détectées, mais seulement parce que `ColonneDonnees<T> c` est déclaré ailleurs dans le fichier. La détection dépend donc du nom de la variable.
- Fixtures isolées non détectées :
  - E : `final c = colonnes().first; '...${c.texte(l)}'` ;
  - L1 : lambda non typée dans `map` ;
  - L2 : `for (final c in cs)` ;
  - R : `s.duree = dureeSeule(...); 'Duree : ${s.duree}'`, c'est-à-dire une valeur rangée dans un champ par affectation.
- Ce sont des formes ordinaires et permises par `analysis_options.yaml` (pas d'`always_specify_types`). `lib/` contient déjà des lambdas non typées, par exemple `(s) => s.profileId`.
- La demande exigeait que la garde trouve « tous ces cas : valeur rangée dans un champ d'objet (... ColonneDonnees ...) puis insérée dans une interpolation ». Ce n'est pas le cas.

## Captures ouvertes

| Capture | Constat |
|---|---|
| `qualite_tableau_1440x1_light_ltr` | Correcte : deux tableaux, « 8 jours » et « 15 jours ». |
| `comptes_tableau_1440x1_dark_rtl` | Lisible. Mais « TEACHER-AS-000001 » se coupe sur deux lignes dans la colonne Identifiant. Le défaut existait avant ce lot et n'est pas consigné. Le point final déplacé (« .montre », « .Une personne… ») est consigné. |
| `qualite_cartes_390x1_light_ltr` | Correcte, la page s'affiche (le correctif de hauteur fonctionne). |
| `qualite_cartes_320x2_dark_rtl` | Aucun mot coupé. « .Sofia B » est consigné. Les puces de filtre défilent à l'horizontale, ce qui est attendu. |

- Il n'y a pas de capture en Interface guidée. Pour des écrans d'administration, ce n'est pas nécessaire.
- Le zoom « 150 % » de `tc_mushaf` est hors périmètre et consigné.

## À faire pour lever le refus (point 2 seulement)

1. Dans `_suivreChamp`, reconnaître aussi les objets dont le type n'est pas écrit. Deux options :
   - plus prudent : suivre tout accès `x.champ(` ou `x.champ` pour un champ de type fonction ou chaîne déclaré par `this.champ` dans la classe, quel que soit le type de `x` ;
   - ou propager le type depuis `final x = <expr de type Classe>`, les paramètres de lambda dans un `map` ou `where` sur une `List<Classe>`, et `for (final x in`.
2. Faire de même dans `champsJoints` pour une lambda non typée.
3. Suivre les affectations `objet.champ = valeurAncree` jusqu'aux lectures `objet.champ`.
4. Ajouter des fixtures E, L1, L2, R et une contre-épreuve V3b sur la vraie copie de `data_collection.dart`.
5. Fournir la suite complète par dossier avec 0 échec.

Le point (1), le correctif de hauteur et les captures sont acquis : ne pas les défaire.
