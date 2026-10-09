<!-- verdict : REFUSEE -->
# Relecture adverse : DUREE-INSECABLE-4 (branche `corrections/c2-duree-4`, commit 5b8fa04a)

**Verdict : REFUSÉE.** La réserve (1) n'est pas remplie. Une ancre U+200E reste au milieu d'un libellé sur un écran réel, et la garde présentée comme exhaustive ne la voit pas.

Pour la relecture, j'ai utilisé un worktree jetable détaché sur `origin/corrections/c2-duree-4`. Je l'ai retiré à la fin et je n'ai rien poussé.

## 1. Le point qui bloque

### Ancre de sens au milieu de « heure · durée » sur le Planning de la classe

- `lib/features/accueil_famille/bloc_seance.dart:64` range dans le champ `duree` d'`AffichageSeance` la valeur `LibellesGroupe.dureeSeule(seance.dureePrevue)`, qui est ancrée.
- `lib/features/classe_tuteur/planning_classe_page.dart:274-283` relit `affichage.duree` et l'insère dans deux libellés :
  - `t.classe.pagePlanning.ligne` = « {heure} · {duree} » ;
  - `ligneFuseau` = « {heure} ({fuseau}) · {duree} ».

**Preuve sur l'écran réel.** J'ai posé une sonde temporaire dans `classe_tuteur_test.dart`, sur le parcours qui ouvre la page Planning. Elle imprime :

`SONDE: idx=8 <18:10 · [LRM]45 min>`

La marque est à l'index 8, donc au milieu de la ligne.

**La garde ne la voit pas.** Le test « lib/ : aucune valeur ancree inseree dans un autre libelle » passe sur ce code. `test/support/garde_ancres.dart` ne suit une valeur rangée dans un champ d'objet que lorsque ce champ est joint par `.join` (cas DataCollection). Il ne suit pas une valeur relue par `objet.champ` puis passée à un libellé `t.x(...)`.

La demande exigeait « un test qui trouve tous ces cas ». Elle n'est donc pas remplie, et un défaut visible demeure.

**Correction attendue :**
- passer `dureeEnPhrase` (non ancrée) à `pagePlanning.ligne` et à `ligneFuseau` ;
- étendre la garde aux champs relus puis insérés dans un libellé ;
- ajouter un test rendu de la page Planning.

## 2. Ce qui est fait et prouvé

### Mutations

J'ai annulé chaque correction une par une, puis lancé les tests concernés.

| Mutation | Résultat |
|---|---|
| M1 : DataCollection revient à `.join` | 3 échecs : garde, Comptes, Progression |
| M2 : vue_seance revient à `valeurSeule` | garde et test « Classe · 32 min restantes » en échec |
| M3 : historique_controleur revient à `valeurSeule` | garde en échec |
| M4 : ligne_presence revient à `valeurSeule` | garde et test LignePresence en échec |
| M5 : âge sans `insecable` | garde de source de DUREE-INSECABLE-3 en échec |
| M6 : zoom du Mode Accessibilité sans `insecable` | garde en échec |
| M7 : zoom de la salle nu | garde et test « 150 % » en échec |
| M8 : `fiche_seance` sans `insecable` | test du rappel sur la fiche réelle en échec |
| M9 : `classe_live_page` sans `insecable` | test de `classe_live_page_test` en échec |
| M10 : LocalFeedback sans isolat | test RTL en échec |
| M11 : `_TexteIsole` sans isolat | **reste vert** (mineur, voir plus bas) |
| M12 : CarteSession sans largeur maximale | test 1440 px en échec |

### Réserve (2), unités hors durée

- « {taille} Mo » portait déjà U+00A0 dans les textes.
- « {max} ans », « {valeur} % » et « {pourcent} % » passent maintenant par `LibellesGroupe.insecable`.
- La garde connaît désormais ans, o, Ko, Mo, Go et %.
- Les clés touchées sont consignées dans `tool/libelles_sources.json` avec la mention « validé par délégation le 05/10 ».

### Réserve (3), rappel sur le code réel

Les tests passent par `FicheSeance` et `ClasseLivePage`, et les mutations M8 et M9 sont tuées.

### Réserve (4), CarteSession

- La carte est bornée par `AppPage.largeurLecture` et alignée au bord de début de la page, ce que confirme la capture 1440 px.
- `_LigneEtat`, le titre et LocalFeedback sont isolés en RTL.
- `page_shell.dart` n'est pas touché, et aucun changement serveur n'est fait.

### Captures ouvertes

- `ma_classe_adulte_1440x1_light_ltr` : carte bornée.
- `ma_classe_adulte_320x2_dark_rtl` : aucun mot coupé dans la carte ; « Cours dans 3 h 28 » est correct.
- `fiche_rappel_attente_320x2_light_rtl` : « Déjà appelé. À nouveau dans 30 s », avec le point à sa place.
- `comptes_cartes_320x2_dark_rtl` : « … · 12 jours · 2 », sans ancre au milieu.

Défauts déjà présents avant cette étape, que le rédacteur a lui-même relevés : « .tajwid », « élèves sur 6 places 3 », « .endroit », « .12 jours », et TEACHER-AS-000001 coupé à son tiret.

### Contrôles

- `dart analyze --fatal-infos` : 0 problème.
- `verifier_jetons` : 39 violations, identique à la base.
- `verifier_revue` : 1547 violations, contre 1550 sur la base.

Tests lancés avec `--concurrency=2`, tous verts :

| Dossier | Résultat |
|---|---|
| test/accessibilite | 375 |
| test/core | 681 |
| test/widgets | 298 |
| test/teaching_core | 1377 |
| test/router | 300 |
| test/features | 2866 |

Côté régressions, les 21 appelants de LocalFeedback et les autres appelants de DataCollection restent verts.

## 3. Réserves mineures

1. **L'isolat de `_TexteIsole` n'est couvert par aucun test.** Cela concerne attenteDetail, la notice de changement d'heure, les libellés de `_LigneValeur` et le conseil d'appareil. M11 survit, car aucun moment de démo ne rend ces textes ponctués. Il faut ajouter un cas avec la phase `attenteAvantT0` et le conseil d'appareil.
2. **Le test RTL de LocalFeedback recompose le message lui-même** avec `LibellesGroupe.insecable`. Le contrôle RTL du rappel devrait passer par `FicheSeance` rendue en RTL.

## 4. Pour la reprise

- Corriger `planning_classe_page.dart` en lui passant `dureeEnPhrase`.
- Étendre la garde de `garde_ancres.dart` au chemin « champ d'objet → `x.champ` → argument de libellé ou interpolation ».
- Contre-test : la garde doit relever `planning_classe_page.dart:278` et `planning_classe_page.dart:282` sur le code actuel.
- Ajouter un test rendu de la page Planning, en LTR et en RTL.
- Couvrir `_TexteIsole` (réserve mineure 1).
