<!-- verdict : REFUSEE -->
# Relecture adverse : DUREE-INSECABLE-4, branche `corrections/c2-duree-4` (ad992d25)

**Verdict : REFUSÉE.** Deux défauts majeurs sont prouvés sur la réserve (1). Les réserves (2), (3) et (4) sont remplies, avec des preuves.

Méthode :
- Worktree jetable détaché sur `origin/corrections/c2-duree-4`, base `6e2c91c4`.
- Rien n'a été poussé ; le worktree est retiré (`git worktree list` : 0).

## Contrôles

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `dart run tool/verifier_revue.dart` | 1547 (même chiffre que la base annoncée) |
| `dart run tool/verifier_jetons.dart` | 39 (même chiffre que celui annoncé) |
| `flutter test --concurrency=2` sur test/accessibilite, test/features/classe_tuteur, test/features/salle_seance, classe_live_page_test, formulaire_profil_eleve_test | +993, ~415 sautés, 0 échec |
| `flutter test --concurrency=2` sur test/core, test/widgets et les dossiers admin_comptes, admin_pedagogie_progression, admin_pedagogie_qualite, controleur, tc_espace_groupe, fiche_groupe, accueil_eleve, accueil_famille (régressions sur les autres appelants) | +1191, 0 échec |

## Mutations faites par moi

Chaque correction est annulée, puis les tests visés sont relancés.

| Mutation | Effet |
|---|---|
| M1 : remettre `affichage.duree` dans le Planning | 4 échecs |
| M2 : CarteSession sans largeur maximale de lecture | 1 échec |
| M3 : `_TexteIsole` sans isolat | 1 échec |
| M4 : remettre `valeurSeule` sur la durée de l'historique contrôleur | la garde signale les lignes 344 et 353 |
| M5 : remettre `valeurSeule` sur le retard de `LignePresence` | 2 échecs |

## Demande, point par point

### (1) Ancres au milieu d'un libellé : NON REMPLIE

**Corrigé :**
- Planning, avec `dureeEnPhrase` ;
- `TexteHeureSeance`, avec `sansAncre` ;
- historique contrôleur et `LignePresence` ;
- `VueSeance` : l'ancre seulement quand la durée commence la ligne ;
- repli en cartes de `DataCollection`, avec `enchainer`.

**Défaut majeur restant :**
- `lib/core/widgets/data_collection.dart:361` (`_Cellule`, mode tableau, écrans larges) construit le libellé sémantique `'${colonne.titre} : ${colonne.texte(ligne)}'`.
- Les colonnes « attente » de Comptes et « depuis » de Progression et de Qualité renvoient `LibellesGroupe.valeurSeule(...)`.
- Preuve d'exécution, sur la page Comptes réelle à 1600 px avec l'arbre sémantique activé : « … Inscrit depuis : <LRM>12 jours … ». Le test échoue.
- Le test du rédacteur ne regarde que 800 px (cartes) et que les `Text`.
- Le compte rendu affirme qu'il ne reste « aucune autre ancre au milieu ». C'est faux.

**La garde ne trouve pas tous les cas :**
- Le test sur `lib/` passe alors que le défaut ci-dessus est présent.
- Elle ne suit le champ d'une colonne qu'en contexte `.map(...).join`, pas en interpolation.

Je lui ai aussi donné des fixtures adverses, en appelant `ancresGlissees()` :

| Motif | Résultat |
|---|---|
| Champ relu dans un `Semantics` | détecté |
| Variable ternaire | détecté |
| Record | détecté |
| Getter | détecté |
| Interpolation directe | détecté |
| Argument positionnel ou nommé d'une fonction ordinaire qui interpole | **non détecté** |
| Constructeur positionnel `this.v` | **non détecté** |
| `StringBuffer.write` | **non détecté** |
| `replaceAll` | **non détecté** |
| `list.add` puis `join` | **non détecté** |

Audit manuel des 40 sites d'appel de `valeurSeule`, `dureeSeule`, `ancreSens`, `heureEtVille` et `uniteMinutesRegle` dans `lib/` :
- Seul le cas `DataCollection` reste fautif.
- `LigneCleValeur`, `_LigneValeur`, `SettingRow`, `StatusPill`, `FilterPill`, `OptionChoix`, `ConfigLigneEntiere`, la ligne d'état de la carte de groupe et `bloc_seance` sont corrects.

**À faire :**
- Dans `_Cellule`, appliquer `sansAncre(colonne.texte(ligne))` dans le label, ou passer par `enchainer`.
- Étendre la garde à l'interpolation d'un champ de type fonction (`colonne.texte(...)` dans `'…'`).
- Ajouter un test sémantique à 1440 px sur Comptes, Progression et Qualité.

### (2) Unités hors durée : REMPLIE, avec une réserve consignée

- « {max} ans » : `insecable`.
- « {valeur} % » de la salle : `valeurSeule`, affiché seul.
- « % » du Mode Accessibilité : `insecable`.
- « Mo » : déjà U+00A0 dans le texte source, plus le formatage partagé `taille_fichier.dart`.
- La garde connaît `ans`, `o`, `Ko`, `Mo`, `Go` et `%`.
- Les entrées de `libelles_sources.json` portent « validé par délégation le 05/10 ».
- Réserve : le zoom de `tc_mushaf` reste sécable (zone interdite). La garde l'exclut et le point est consigné.

### (3) Test du rappel par le code réel : REMPLIE

- `FicheSeance` réelle, avec un tap sur Rappel et un refus cooldown du faux port, en LTR et en RTL.
- `classe_live_page_test` : un rappel trop proche, « 45 s » insécable.
- L'ancien test qui appelait `insecable` lui-même est retiré.

### (4) Ponctuation RTL et largeur à 1440 px : REMPLIE

- Isolats FSI…PDI sur les cartes touchées :
  - date de la carte ;
  - texte d'attente en tutoiement et en vouvoiement ;
  - avis de changement d'heure ;
  - conseil d'appareil ;
  - intitulés ;
  - ligne d'état ;
  - Planning.
- La largeur maximale de la CarteSession et de son squelette vient du jeton `AppPage.largeurLecture` (800), alignée au bord de début.
- Les mutations M2 et M3 font échouer les tests.
- `page_shell.dart`, `supabase/`, le thème et le rendu du Coran ne sont pas touchés.

## Captures ouvertes

- `planning_classe_320x2_light_rtl` : jour, « 18:10 · 45 min » et phrase finale dans le bon ordre ; aucun mot coupé.
- `carte_session_attente_dst_320x2_light_rtl` : ponctuation à sa place, rien de coupé.
- `ma_classe_adulte_1440x1_light_ltr` : la carte est bornée, elle ne s'étire plus sur toute la largeur.

Il manque une capture des tableaux d'administration à 1440 px, qui aurait montré le contexte du défaut restant. Il est sémantique, donc invisible à l'image.

## Conclusion

Le travail avance nettement. Mais la demande (1) dit « ancre seulement là où la valeur commence le libellé ; test qui trouve tous ces cas ». Un cas réel subsiste dans un composant partagé utilisé par trois écrans, et la garde ne le voit pas. **Refus. À reprendre sur ces deux seuls points.**
