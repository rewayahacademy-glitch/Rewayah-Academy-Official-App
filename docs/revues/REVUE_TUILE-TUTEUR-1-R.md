# Revue croisée TUILE-TUTEUR-1-R : tuile du tuteur en salle d'observation (reste de VIDEO-TUILE-1)

- **Objet revu** : `corrections/c2-tuile-tuteur` @ `1910b943` (base `af20f6c2`, branche commune), 2 commits, 24 fichiers (+152 −18), dont 21 captures.
- **Code touché** : `lib/features/tc_observation_ui/panneau_observation_tuteur.dart` seul. Le composant partagé `lib/core/widgets/avatar_nom.dart` (`TuileSansImage`) n'est pas modifié.
- **Relecteur** : session cloud `01KyPAZg`. Elle n'a pas écrit TUILE-TUTEUR-1 (auteur : `b061fd81`, exclue).
- **Date** : 4 octobre 2026.
- **Références** : fiche VIDEO-TUILE-1 (même composant que la salle et la scène live) ; `lib/CLAUDE.md` ; `docs/design/00-bible-frontend-v2.md`.
- **Méthode** :
  - lecture du diff ;
  - contrôles relancés sur le worktree `/home/user/rv-tuile-tuteur` ;
  - deux mutations ciblées, remises en place ;
  - deux sondes de l'arbre sémantique (branche, puis base `af20f6c2`), remises en place ;
  - captures ouvertes ;
  - fusion à blanc.

## Verdict

**Refusée.** Le rendu visuel est juste : cercle, nom centré dessous, plus d'étiquette en double, ondes dans le coin. Mais la sémantique régresse. Le lecteur d'écran lit maintenant le nom **deux fois**, sur **deux arrêts** au lieu d'un. Or la fiche demande « pas de doublon » et « sémantique ». La correction est petite (voir « Pour accepter »).

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang`, `build_runner build` | OK |
| `dart analyze --fatal-infos` | **0 problème** |
| `dart run tool/verifier_jetons.dart \| grep -c "\["` | **39**, le chiffre attendu |
| `flutter test test/teaching_core/g/` | **168 réussis, 59 ignorés (captures), 0 échec** |
| Mutation 1 : `etiquette = true` (l'étiquette du bas revient sans image) | **4 échecs** : « La salle… deux personnes » et les 3 cas TUILE-TUTEUR-1 (390, 320 ×2, 1440). Le test est discriminant sur le doublon visuel |
| Mutation 2 : `coin: null` (les ondes de parole disparaissent sans image) | **0 échec** sur les 168 tests. Les ondes sans image ne sont pas testées |
| Sonde sémantique, branche (Amina parle, caméra fermée) | 2 nœuds : `"Amina parle"`, puis son enfant `"Amina, Caméra fermée"`. Pareil pour Mariam : `"Mariam"` puis `"Mariam, Caméra fermée"` |
| Sonde sémantique, base `af20f6c2` | 1 nœud : `"Amina parle\nCaméra fermée"`. Le nom n'était lu qu'une fois |
| Fusion à blanc `git merge-tree --write-tree origin/corrections/revue-directeur-2026-10 HEAD` | **Aucun conflit** (arbre `f517da4b`). La base `af20f6c2` est un ancêtre de la branche commune |
| `git status` du worktree à la fin | propre |

## Points de la fiche, un par un

1. **Même composant que la salle et la scène live.** ✅ La vignette sans image utilise `TuileSansImage` (`panneau_observation_tuteur.dart:466`), comme `salle_page.dart:1694`, `scene_classe.dart:200` et `vignette_video.dart:120`.
2. **Nom centré sous le cercle.** ✅ Mesuré par le test (`salle_observation_test.dart`, groupe TUILE-TUTEUR-1) : centre du nom à 1 px près du centre du cercle, nom sous le cercle, tout dans le cadre, à 390, 320 ×2 et 1440. Visible sur les captures 390 clair, 390 sombre et 1440.
3. **Pas de doublon avec l'étiquette.** ✅ à l'écran : `etiquette = image != null || p == null` (`:479`). Le nom n'apparaît qu'une fois, et la mutation 1 le prouve. ❌ pour le lecteur d'écran : voir point 5.
4. **Ondes de parole.** ✅ à l'écran : `_OndesParole` dans le coin (`:474`, `:546`), jeton `pointsStatut.succes`, taille `AppSpacing.lg`, signal réel seulement. La sonde compte 1 icône quand Amina parle. ⚠ Aucun test ne le vérifie (mutation 2 survit).
5. **Sémantique.** ❌ Le cadre `_cadre` garde son `Semantics(container: true, label: nom ou « X parle »)` (`:504-507`). La `TuileSansImage` pose son propre nœud `container: true` avec « nom, Caméra fermée » (`avatar_nom.dart:382-388`). Résultat : deux arrêts, nom lu deux fois. La base en avait un seul. Dans la salle et la scène live, le cadre ne pose pas de libellé de nom autour de la tuile, d'où un seul nom lu. Le test ne contrôle que la présence de « Caméra fermée » (`findsNWidgets(2)`), pas l'unicité du nom.
6. **Captures K-61 `o2_sans_image_*`.** Ouvertes :
   - 390 clair : deux tuiles grises, cercles « A » et « M », nom centré dessous, plus de pilule sombre. Mariam a le liseré violet et les ondes vertes dans le coin bas.
   - 390 sombre : même rendu, contraste correct, liseré lilas, ondes vertes lisibles.
   - 1440 : vignettes empilées à droite, même tuile, ondes dans le coin de Mariam.
   - 320 ×2 (`o2_sans_image_texte200_320x844@2_light.png`) : **aucune vignette n'est visible**. La page s'arrête au sous-titre coupé (« Sayyid Ens… » tronqué en bas) puis à la barre de commandes. « Quitter » est cassé lettre par lettre, « Agrandir » en « Agrand / ir ». La capture ne prouve donc rien sur la tuile à 320 ×2. Le défaut existe déjà sur la base : `o2_texte200_390x844@2` montre aussi « Q / uit / te / r ». Le diff ne touche pas cette mise en page.

## Règles du projet

- 5 états : inchangés. Salle vide (« Pas encore dans la salle ») garde l'étiquette (`p == null`), vidéo indisponible et reconnexion ont leurs captures. ✅
- Aucune couleur ou valeur inventée : `surfaceSunken`, `pointsStatut.succes`, `AppSpacing.lg`. Jetons à 39. ✅
- Aucun texte en dur : réutilise `v.cameraFermee`, `v.parle`. ✅
- RTL : `PositionedDirectional` dans la tuile et l'étiquette. ✅
- Capacité, pas rôle : rien de nouveau. ✅
- Bouton plein unique, pas de bouton dans un bouton : non touchés. ✅
- 320 et texte ×2 sans mot coupé : ❌ sur la page (préexistant, hors diff), voir défaut 3.

## Composants partagés

`avatar_nom.dart` n'est pas modifié. Les autres écrans qui utilisent `TuileSansImage` (salle, scène live, vignette de séance) ne sont pas touchés par ce diff. Pas de régression possible de leur côté.

## Défauts retenus

1. **MAJEUR (dans le périmètre)** : doublon sémantique. Sans image, le nom est lu deux fois sur deux nœuds (« Amina parle », puis « Amina, Caméra fermée »). Régression mesurée contre la base. Point « sémantique » de la fiche non tenu.
2. **mineur** : les ondes de parole sans image ne sont couvertes par aucun test (mutation `coin: null` : 0 échec).
3. **mineur, préexistant, hors diff, à ouvrir en lot séparé** : à texte ×2 (320 et 390), la salle d'observation coupe « Quitter » et « Agrandir » au milieu du mot, tronque le sous-titre, et à 320 ×2 les vignettes sortent de l'écran. Le test widget à 320 ×2 passe car il mesure la tuile dans son cadre, pas dans la fenêtre visible.
4. **cosmétique** : la capture `o2_sans_image_texte200_320x844@2` est livrée comme preuve alors qu'elle ne montre aucune tuile.

## Pour accepter

1. Dans `_Vignette`, cas sans image (`image == null && p != null`) : un seul nœud. Par exemple, le `Semantics` du cadre porte « `v.parle(nom)` ou `nom`, `v.cameraFermee` » et exclut la sémantique de la tuile (`ExcludeSemantics` autour de `TuileSansImage`). Ou l'inverse : pas de libellé sur le cadre, et la tuile reçoit le nom parlant. Garder l'information « parle ».
2. Ajouter au test : un seul nœud sémantique par vignette sans image, nom présent une fois (par exemple `find.bySemanticsLabel(RegExp('Amina'))` → `findsOneWidget`), avec et sans `parle: true`.
3. Ajouter un cas `parle: true` sans image qui trouve l'icône d'ondes dans le cadre.
4. Ouvrir un lot séparé pour la salle d'observation à texte ×2 (commandes coupées, vignettes hors écran à 320).

## Contre-vérification

Sceptique indépendant, session `01KyPAZg`, non auteur. But : réfuter chaque majeur et chercher un majeur oublié. Worktree `/home/user/rv-tuile-tuteur`, `1910b943`.

### Ce qui est relancé

| Contrôle | Résultat |
| :--- | :--- |
| Lecture du code | `_cadre` pose `Semantics(container: true, label: parle ? nomQuiParle : nom)` (`panneau_observation_tuteur.dart:504-507`). `TuileSansImage` pose un second `Semantics(container: true, label: "nom, Caméra fermée")` puis `ExcludeSemantics` (`avatar_nom.dart:381-388`). Deux conteneurs imbriqués, donc deux nœuds |
| Sonde sémantique (test temporaire, retiré) | `vignette-enfant` : `"Mariam"` puis enfant `"Mariam, Caméra fermée"`. `vignette-enseignant` : `"Amina"` puis enfant `"Amina, Caméra fermée"`. `find.bySemanticsLabel(RegExp('Amina'))` : 3 nœuds (en-tête compris) |
| Comparaison avec un autre écran du même composant | `vignette_video.dart:98-101` entoure `TuileSansImage` d'un `Semantics(excludeSemantics: true)` : un seul nœud. Le correctif attendu existe donc déjà dans le dépôt |
| Mutation `coin: null` sur `test/teaching_core/g/` | **168 réussis, 59 ignorés, 0 échec**. Confirmé : les ondes sans image ne sont pas testées |
| Capture `o2_sans_image_texte200_320x844@2_light.png` | Ouverte. Aucune vignette visible. « Quitter » cassé lettre par lettre, « Agrandir » en « Agrand / ir », sous-titre coupé. La barre de commandes n'est pas dans le diff (seuls `_Vignette`, `_cadre` et `_OndesParole` changent) |
| `git status` à la fin | propre |

### Majeur 1 (doublon sémantique) : confirmé

Réel et reproduit : deux arrêts, nom lu deux fois. C'est une régression contre la base (un seul nœud), et le test du lot ne compte que « Caméra fermée », pas l'unicité du nom. Le lot porte justement sur ce composant et sur « pas de doublon ». Je ne trouve pas d'argument pour le rétrograder. Le correctif est d'une ligne, sur le modèle de `vignette_video.dart` : `excludeSemantics: true` sur le cadre avec un libellé qui garde « parle » et « Caméra fermée », ou bien pas de libellé de nom sur le cadre sans image.

### Mineurs : confirmés

- Ondes sans image non testées : confirmé par la mutation (0 échec).
- Commandes coupées à texte ×2 : confirmé sur capture, préexistant et hors diff. Il casse la règle « 320 et texte ×2 sans mot coupé », mais pas du fait de ce lot. Je le laisse en mineur hors périmètre, avec un lot séparé obligatoire.
- Capture 320 ×2 sans tuile : confirmé.

### Majeur oublié : aucun

- Bouton dans un bouton : la vignette n'a aucun `InkWell`, `GestureDetector` ni `onTap`. Rien.
- Texte en dur : aucun. `v.cameraFermee`, `v.parle` réutilisés.
- Couleur ou valeur inventée : `surfaceSunken`, `pointsStatut.succes`, `AppSpacing.lg`. Rien.
- Composant partagé : `avatar_nom.dart` non modifié, pas de régression possible ailleurs.
- États : salle vide garde l'étiquette (`p == null`). Rien de perdu.
- Remarque sans gravité : la salle passe `libelleMicroCoupe`, l'observation non. La base ne le faisait pas non plus. Pas une régression.

### Verdict final

**Refusée**, inchangé. Un majeur confirmé (doublon sémantique), aucun rejeté, aucun nouveau.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
