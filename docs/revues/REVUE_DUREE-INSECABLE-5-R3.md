<!-- verdict : REFUSEE -->
<!-- verdict : REFUSEE -->
# Relecture adverse : DUREE-INSECABLE-5, branche `corrections/c2-duree-5` (a134118b)

**Verdict : REFUSÉE.**
- Le point (1), la correction dans `lib/`, est rempli, avec des preuves.
- Le point (2) n'est pas rempli : la garde ne trouve pas une valeur ancrée rangée dans un **record** placé dans une liste, puis relue par destructuration ou par lambda. La demande nomme pourtant le record, et c'est l'idiome du dépôt pour les lignes libellé/valeur.

Méthode :
- Worktree jetable détaché sur `origin/corrections/c2-duree-5`.
- Rien n'a été poussé ; le worktree est retiré (`git worktree list` : 0).
- Mon fichier de fixtures est gardé hors dépôt : `scratchpad/rv58_adverse_test.dart`.

## Contrôles

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `dart run tool/verifier_revue.dart` | 1530 (base 1530) |
| `dart run tool/verifier_jetons.dart` | 37 (chiffre annoncé) |
| `flutter test --concurrency=2` sur `test/accessibilite`, `test/widgets`, `test/core`, `comptes_test`, `admin_observations`, `admin_pedagogie_programmes`, `journal_admin_test`, `admin_coque_test` (autres appelants de `DataCollection` compris) | +1506, 0 échec |

## Point (1) : libellé parlé de `_Cellule`, REMPLI

- `data_collection.dart:406` : `label: '${colonne.titre} : ${sansAncre(colonne.texte(ligne))}'`. La correction est faite à la source, dans le composant partagé. Elle couvre donc tous les appelants qui passent par `texte` en mode tableau :
  - Comptes, Progression, Qualité ;
  - Groupes, Journal, Évaluations, Programmes, Observations, Agents, Suivi élève, galerie.
- J'ai relu les appelants qui ont leur propre `rendu` (`suivi_eleve_page.dart:216`, `observations_admin_page.dart:729`, `acces_agents_page.dart:418`, etc.). Aucun ne porte une valeur ancrée au milieu d'un libellé.
- Audit des 42 sites d'appel de `valeurSeule`, `dureeSeule`, `ancreSens` et `heureEtVille` : aucun nouveau depuis `c2-duree-4`, et la garde trouve 0 faute sur `lib/`.
- **Mutation faite par moi** : `sansAncre` retiré, à l'endroit même. 20 tests échouent ou plus :
  - les 6 tests sémantiques à 1600 px (Comptes, Progression, Qualité, en LTR et en RTL) ;
  - la garde sur `lib/`, dans les tests de DUREE-INSECABLE-4 et de DUREE-INSECABLE-5 ;
  - la contre-épreuve ;
  - les groupes 3 et 4.
- Les acquis de DUREE-INSECABLE-4 ne sont pas défaits.

## Point (2) : complétude de la garde, NON REMPLI

### Ce qui marche

**15 mutations de `data_collection.dart`**, chacune avec 1 faute à la ligne 406 :
- concaténation `+` ;
- interpolation puis `+` ;
- `join` ;
- variable locale ;
- `.call` ;
- tear-off ;
- guillemets doubles ;
- `?? ''` ;
- `StringBuffer` ;
- libellé `t.` ;
- `(colonne.texte)(ligne)` ;
- `replaceAll` ;
- `'''` ;
- variable inférée et `+`.

**Fixtures trouvées :**
- Map : index, `values`, `entries.map`, Map passée à un constructeur ;
- record local, nommé et positionnel ;
- record passé à une fonction ou rendu par une fonction ;
- `copyWith`, y compris avec un type inféré ;
- constructeur nommé lu sous un autre nom ;
- tear-off de fonction en `texte:` ;
- getter de classe ;
- `s!.duree` et `s?.duree` ;
- `widget.duree` dans un `State` ;
- liste d'objets puis `map`.

La contre-épreuve du rédacteur est réelle : elle échoue avec la mutation du libellé.

### Ce qui ne marche pas (fixtures adverses, 0 faute à chaque fois)

| Motif | Résultat |
|---|---|
| H1, idiome du dépôt : `List<(String, String)> lignes = [('Duree', valeurSeule(x))]`, puis `for (final (String libelle, String valeur) in lignes) b.write('$libelle : $valeur')` | **non détecté** |
| H2 : même forme, avec `Semantics(label: '$libelle : $valeur')` | **non détecté** |
| F15 : liste de records nommés, `l.map((r) => '${r.t} : ${r.v}')` | **non détecté** |
| G5 : records positionnels en liste, `'${r.$1} : ${r.$2}'` | **non détecté** |
| G2 : record dans un `for-in` non typé | **non détecté** |
| F12 : destructuration d'objet, `final Seance(:duree) = s; '... $duree'` | non détecté (mineur) |
| F18 : constructeur positionnel à liste d'initialisation, `Seance(String d) : duree = d`, puis `'${s.duree}'` | non détecté (mineur) |
| F16 : champ statique `K.d` interpolé | non détecté (mineur) |

Le cas H1/H2 n'est pas un cas d'école. C'est exactement la forme de `fiche_groupe_page.dart:566-575` et de `preparation_enseignant.dart:648-657`, qui construisent des lignes libellé/valeur par records puis destructuration. La demande dit : « la garde doit trouver tous ces cas : valeur rangée dans un champ d'objet (… Map, record) puis insérée dans une interpolation ». Le record en collection en fait partie.

## Captures ouvertes

- `comptes_tableau_1440x1_light_ltr` : tableau lisible, identifiant sur une ligne, rien de coupé.
- `qualite_cartes_320x2_dark_rtl` : cartes, aucun mot coupé ; « 8 jours » et « 15 jours » insécables.
- Il n'y a aucun changement d'écran dans cette reprise, donc les captures n'avaient pas à être régénérées.
- Défaut sémantique : il est invisible à l'image et il est prouvé par les tests.
- Restent consignés, hors périmètre :
  - le point final en tête en RTL avec des données françaises (« .Sofia B ») ;
  - le zoom « 150 % » de `tc_mushaf` (zone interdite).

## À faire, et seulement cela

1. **La garde doit suivre une valeur ancrée qui est élément d'un record placé dans une collection** (liste ou ensemble, littéral ou `for`), jusqu'à :
   - une destructuration dans un `for-in` (`for (final (a, b) in l)` ou `for (final (:t, :v) in l)`) ;
   - une lambda `map` (`r.t`, `r.$2`) ;
   - un `for-in` non typé.

   Puis elle doit relever son interpolation ailleurs qu'en tête.
2. Elle doit couvrir aussi :
   - la destructuration d'objet (`final C(:champ) = o`) ;
   - le constructeur positionnel à liste d'initialisation (`C(String d) : champ = d`) ;
   - le champ statique.
3. Ajouter les fixtures H1, H2, F15, G5, G2, F12, F18 et F16 au test, avec leur contre-épreuve sur la garde actuelle.

Statut constaté : la correction est présente dans le code et testée localement ; ni staging ni déploiement.
