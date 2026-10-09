<!-- verdict : REFUSEE -->
<!-- verdict : REFUSEE -->
# Relecture adverse : DUREE-INSECABLE-5, branche `corrections/c2-duree-5` (581923a8)

**Verdict : REFUSÉE.**
- Le point (1), le libellé parlé des cellules de `DataCollection`, est corrigé et prouvé.
- Le point (2) n'est pas rempli. La garde laisse passer le défaut de data_collection quand l'interpolation est écrite en littéraux adjacents. C'est justement la forme que produit `dart format` pour un libellé long.

## Méthode
- Worktree jetable détaché sur `origin/corrections/c2-duree-5` (581923a8).
- Pour isoler ce lot, j'ai comparé avec la fusion `c9c647e5`, dont `ad992d25` (DUREE-INSECABLE-4) est un ancêtre.
- Fichiers touchés dans `lib/` : `lib/core/widgets/data_collection.dart` et `lib/features/admin_comptes/comptes_page.dart`. Aucun fichier interdit n'est touché : supabase, .github, pubspec, thème, Coran.
- Rien n'a été poussé. Mes fichiers de mutation étaient temporaires ; le worktree est retiré (`git worktree list` : 0).

## Contrôles
| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `dart run tool/verifier_revue.dart` | 1530, égal à la base annoncée |
| `dart run tool/verifier_jetons.dart` | 37 (lot 4 : 39), aucune hausse |
| `flutter test --concurrency=2` sur duree_insecable_4 et duree_insecable_5 | +36, 0 échec |
| Régressions sur les appelants de `DataCollection` et des écrans d'administration (fichiers de test qui les citent, test/core/widgets, test/widgets, test/accessibilite) | +1009, 0 échec |

## Point (1) : libellé parlé de `_Cellule`, REMPLI
- `label: '${colonne.titre} : ${sansAncre(colonne.texte(ligne))}'` est corrigé dans le composant partagé. La correction couvre donc tous les appelants en mode tableau.
- Audit des 11 écrans appelants :
  - seules les colonnes « Inscrit depuis » (Comptes) et « Depuis » (Progression, Qualité) portent `valeurSeule` ;
  - `suivi_eleve` et `observations_admin` construisent leur propre `Semantics` avec des valeurs non ancrées ;
  - `acces_agents` ancre un `FilterPill` affiché seul.
- `_Carte` garde `enchainer`.
- **Mutation M1** : j'ai retiré `sansAncre` dans `_Cellule`. Résultat : 14 échecs, dont les tests sémantiques à 1600 px en LTR et en RTL sur Comptes, Progression et Qualité, et la garde sur lib/.
- Ajouts annexes vérifiés :
  - repli en cartes à texte ×1,5 et plus (seuil existant `AppGabarit.seuilTexteColonne`) ;
  - `insecable` sur l'identifiant de Comptes ;
  - défilement intégré pour Qualité.
  - Aucune régression dans les suites lancées.

## Point (2) : garde `test/support/garde_ancres.dart`, NON REMPLI
J'ai écrit mes propres mutations sur une copie de data_collection et lancé `ancresGlissees()` sur tout lib/ :

| Mutation | Détectée |
|---|---|
| variable locale `final v = colonne.texte(ligne)` puis `'$titre : $v'` | oui |
| concaténation `+` | oui |
| `[titre, valeur].join(' : ')` | oui |
| fonction d'aide qui interpole | oui |
| `colonne.texte.call(ligne)` | oui |
| `.trim()`, `?? ''`, ternaire dans l'interpolation | oui |
| guillemets doubles | oui |
| `replaceFirst` en chaîne | oui |
| `StringBuffer` en cascade | oui |
| tear-off `final f = colonne.texte` | oui |
| argument d'une clé de traduction | oui |
| **littéraux adjacents sur deux lignes** `'${colonne.titre} : '` + `'${colonne.texte(ligne)}'` | **non** |
| **littéraux adjacents sur une ligne** | **non** |
| **`'Valeur : ' '${colonne.texte(ligne)}'`** | **non** |
| `${this.colonne.texte(ligne)}` | **non** |
| `Semantics(label: titre, value: valeur)` | non, ce qui est légitime (valeur séparée) |

Sur une fixture directe, sans champ d'objet :
- `'Duree : ' '${LibellesGroupe.dureeSeule(d)}'` n'est pas détecté, sur une ligne comme sur deux.
- `'Duree : ${this.duree}'` n'est pas détecté.
- Seule l'interpolation dans un littéral unique l'est.

La garde traite un littéral qui commence par `${` comme un début de libellé, même s'il suit un autre littéral que Dart lui concatène. Or ce découpage est la forme normale de `dart format` sur une ligne longue ; on le trouve partout dans lib/ (appairage_page.dart:901-902, detail_observations_page.dart:117-118…). Je n'ai trouvé dans lib/ aucune ancre réelle masquée ainsi aujourd'hui. Mais la demande exige que la garde trouve tous ces cas, et la contre-épreuve la plus probable lui échappe.

Les autres apports de la garde sont réels et je les ai vérifiés :
- type inféré ;
- lambda et boucle non typées ;
- affectation de champ ;
- autre fichier ;
- `copyWith`, Map, record ;
- arguments positionnels et nommés ;
- tampon, remplacement, `list.add`.

## Captures ouvertes
- `comptes_tableau_1440x1_dark_rtl` : l'identifiant « TEACHER-AS-000001 » tient sur une ligne ; « 12 jours » est entier.
- `comptes_texte_agrandi_1440x2_dark_rtl` : la page est repliée en cartes, sans mot coupé.
- `qualite_cartes_320x2_dark_rtl` : aucun mot coupé.
- `progression_tableau_1440x1_light_ltr` : correcte.
- Constats antérieurs au lot, sans rapport avec le défaut :
  - le point final passe en tête des phrases françaises rendues en RTL (« .montre ») ;
  - les en-têtes de Progression sont légèrement décalés par rapport à leurs valeurs.

## À faire (seul point restant)
1. Dans la garde, traiter une suite de littéraux adjacents comme une seule chaîne. Une interpolation qui ouvre le second littéral est « au milieu » si le précédent n'est pas vide.
2. Suivre aussi `this.champ` dans les interpolations.
3. Ajouter une contre-épreuve qui réintroduit le défaut de data_collection sur deux littéraux adjacents. Cette contre-épreuve doit faire échouer la garde.

Le zoom « 150 % » de tc_mushaf reste hors périmètre (zone interdite) ; il est consigné.
