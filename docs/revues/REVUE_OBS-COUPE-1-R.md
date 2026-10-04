# Revue croisée OBS-COUPE-1-R : barre de la salle d'observation sans mot coupé

- Objet : branche `corrections/c2-obs-coupe`, plage `1910b943..752ede43` (2 commits : 70860c64 code et test, 752ede43 captures).
- Relecteur : session 01KyPAZg, non auteur (auteur : b061fd81).
- Date : 4 octobre 2026.
- Méthode : lecture du diff, contrôles relancés dans `/home/user/rv-obs-coupe`, tests ciblés (jamais la suite complète), deux mutations remises en place, mesure des rectangles sur le rendu de capture, lecture de 6 captures, fusion à blanc.

## Verdict

**REFUSÉE (après contre-vérification).** La première revue concluait « ACCEPTÉE AVEC RÉSERVES ». La contre-vérification trouve un défaut majeur oublié : à 320 px, texte à 100 %, support agrandi, « Son reç/u » et « Réd/uire » sont coupés dans un mot. Voir la section Contre-vérification en fin de rapport. Constat initial, conservé pour mémoire : Le défaut relevé est corrigé et mesuré. « Q/u/i/t/t/e/r », « Agrand/ir » et « Son interr/ompu » ont disparu à 320 et 390 px, texte à 100 % et 200 %, en LTR et RTL. La maquette M4 reste tenue à 390 x1. Les tests sont discriminants. Deux réserves mineures, aucune majeure.

## Contrôles relancés (chiffres mesurés)

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` + `build_runner` | OK |
| `dart analyze --fatal-infos` | No issues found |
| `verifier_jetons.dart \| grep -c "\["` | 39 (attendu 39) |
| `flutter test test/teaching_core/g/ tuteur_k_echelle_texte_test.dart observation_groupe_admin_test.dart` | +209, 59 sautés (captures sans CAPTURE_DIR), 0 échec |
| Nouveau test `barre_observation_coupe_test.dart` | 16/16 |
| Mutation 1 : retrait de `_troisTropEtroits` de la condition `empile` | 4 échecs (les 4 cas 320 px x1) |
| Mutation 2 : retour à l'ancien rendu empilé (Quitter dans un tiers, `Expanded`) | 12 échecs sur 16 |
| Fusion à blanc sur `origin/corrections/revue-directeur-2026-10` | sans conflit (arbre 2451965c) |
| Sonde de rendu (capture 320x844 @2 et 390x844 @2, texte 200 %) | barre 654 à 818 px logiques, soit 164 px (19 % de 844) ; Quitter 758 à 798 ; aucune exception |
| `git status` du worktree à la fin | propre |

## Points de la fiche, un par un

1. **Règle de passage en deux rangées (mot le plus long au plancher 0,85).** ✅ `barre_commandes_observation.dart:73-88` : le tiers disponible, moins le médaillon et l'écart, est comparé au mot le plus long des libellés affichés multiplié par `echelleMinimaleLisible` (0,85, `texte_sans_coupure.dart:133`). Le libellé suit l'état (son reçu ou interrompu, agrandir ou réduire). La mutation 1 prouve que la règle porte le cas 320 x1.
2. **Deux rangées : son et agrandir, puis Quitter pleine largeur.** ✅ `:134-150`. Capture 320 @2 : « Son reçu », « Agrandir », puis « Quitter » sur une pilule pleine largeur. Aucun mot coupé. La barre passe d'environ 310 px logiques (capture TUILE-TUTEUR-1) à 164 px.
3. **M4 gardée à 390 x1.** ✅ Le test vérifie que Quitter et Agrandir sont sur la même rangée (centre à 4 px près). Captures 390 @3 clair, sombre et agrandi : une seule rangée, pilule à sa largeur.
4. **Libellés en `TexteSansCoupure`.** ✅ `:256` et `:297`. Aucun nouveau texte en dur, aucune nouvelle clé i18n, aucune valeur inventée (jetons : 39).
5. **Test 16 cas et contre-épreuve.** ✅ 320/390 x x1/x2 x LTR/RTL x son reçu/interrompu. Il vérifie la présence des trois libellés, `verifierAucunMotCoupe`, M4 à 390 x1, et une hauteur de barre sous un tiers de l'écran. Les deux mutations le font échouer.
6. **Captures `docs/current/captures/OBS-COUPE-1` (K-61).** ✅ 21 captures. Lues : `o2_sans_image_texte200_320x844@2_light` (deux rangées, rien de coupé, en-tête « Classe fictive A » passe à la ligne par mots entiers, sous-titre complet), `o2_texte200_390x844@2_light` (idem, support lisible, haut des vignettes visible, la salle défile), `o2_salle_390x844@3_dark` (M4 intacte en sombre, vignettes visibles), `o2_agrandi_390x844@3_light` (« Réduire » sur une rangée), `o2_salle_1440x900@1_dark` (barre large inchangée). Comparée à `TUILE-TUTEUR-1/o2_sans_image_texte200_320x844@2_light` : l'ancien « Q/u/i/t/t/e/r » et « Agrand/ir » sont bien partis.
7. **Fiche de l'étape : en-tête rogné, vignettes hors de la vue.** ✅ en partie par effet de bord. L'en-tête n'est plus rogné à 320 @2 (le sous-titre « Enseignant X » était coupé à mi-hauteur, il est entier). Les vignettes restent sous le pli à 320 @2, mais la salle défile (`SingleChildScrollView`, `panneau_observation_tuteur.dart:188`) : on les atteint. Aucun test ne vérifie qu'elles sont atteignables (voir réserve 2).

## Règles du projet

- 5 états : la barre n'est pas un écran ; les états de la salle (vide, vidéo indisponible, reconnexion, sans image) sont capturés et inchangés.
- 320 px et texte x2 sans mot coupé : ✅ mesuré. RTL : ✅ (8 cas du test).
- Un seul bouton plein : la pilule Quitter reste tonale. Pas de bouton dans un bouton.
- Aucun rôle lu, aucun port touché.
- Composants partagés : seul `BarreCommandesObservation` change ; son unique usage est `panneau_observation_tuteur.dart:117`. `TexteSansCoupure` n'est pas modifié. Les tests de la salle, de la fin de visite, de l'entrée et de l'échelle de texte tuteur passent.

## Défauts retenus

Aucun défaut majeur.

Mineurs :

1. **Bas de la barre sous l'indicateur d'accueil à 200 %.** Mesuré : la barre finit à 818 px logiques, la zone sûre du bas commence à 810 (844 - 34). Sur les deux captures @2, le bord bas et le rembourrage de la barre sont coupés net. Le défaut existait déjà avant (même coupe sur la capture TUILE-TUTEUR-1), il n'est pas introduit ici. À 390 @3, la barre finit avant la zone sûre.
2. **Couverture du test.** Le cas `agrandi: true` (« Réduire ») n'est pas dans les 16 cas, alors que la règle lit ce libellé. Aucun test ne dit que les vignettes restent atteignables par défilement à 320 @2.

## Pour accepter

Rien de bloquant : la branche peut entrer dans la fusion. À reporter dans une étape suivante : (a) faire respecter la zone sûre du bas par la colonne du panneau téléphone et mesurer `barre.bottom <= hauteur - zoneSure.bottom` à 320 et 390 @2 ; (b) ajouter `agrandi: true` à la boucle du test et un contrôle de défilement jusqu'aux vignettes.


## Contre-vérification

- Relecteur : session 01KyPAZg, sceptique indépendant, non auteur. Date : 4 octobre 2026.
- Méthode : relecture du diff `1910b943..752ede43`, sonde de test temporaire, capture temporaire, puis remise en place (`git checkout --`, fichier sonde supprimé). `git status` du worktree : propre.

### Majeurs de la première revue

La première revue n'a retenu aucun majeur. Rien à réfuter.

### Mineurs de la première revue

1. Zone sûre du bas à 200 % : confirmé comme mineur. Le défaut est antérieur à la branche.
2. Cas `agrandi: true` absent du test : **confirmé, et plus grave qu'un mineur**. Ce trou cache un vrai mot coupé (voir ci-dessous).

### Nouveau majeur : mot coupé à 320 px, texte à 100 %, support agrandi

- Sonde : copie du test `barre_observation_coupe_test.dart` avec `agrandi: true`, largeurs 300, 320, 360, 390, texte x1, x1,3, x1,5, x2, x3, LTR et RTL, son reçu et interrompu. Résultat : 76 réussis, **4 échecs** : 320 x1 LTR et RTL son reçu, 360 x1 LTR et RTL son reçu (largeur de test 360 moins 32 de marge). Message : `['Son reçu : reçu', 'Réduire : Réduire']`, « Un mot coupe ou tronque ».
- Dans la vraie salle (capture temporaire ajoutée au test de capture, 320x844 @2, texte 100 %, après appui sur « Agrandir ») : `motsCoupes` rend `[Son reçu : reçu, Réduire : Réduire]`. La capture montre « Son / reç / u » et « Réd / uire ». Preuve gardée : `/tmp/claude-0/revues/OBS-COUPE-1-R_contre_reduire_320x844@2.png`. À 360x800 dans la vraie salle, rien de coupé (le panneau laisse plus de largeur que la sonde).
- Cause : `_troisTropEtroits` (`barre_commandes_observation.dart:73-88`) suppose que chaque commande dispose d'un tiers de la barre. Or, sur une seule rangée, « Quitter » garde sa largeur propre (M4, `:151-158`), plus large qu'un tiers à 320 px. Son et agrandir n'ont donc que la moitié du reste, nettement moins qu'un tiers. Avec « Agrandir » (8 lettres) ou « Son interrompu », le seuil bascule par chance en deux rangées. Avec « Réduire » et « Son reçu », le mot le plus long est plus court, la règle croit que tout tient, la barre reste sur une rangée et coupe les deux mots.
- Pourquoi majeur : c'est exactement le défaut que l'étape prétend corriger (mot coupé à 320 px), dans un état ordinaire (l'utilisateur vient d'appuyer sur « Agrandir »). Règle du projet cassée : « 320 px sans mot coupé ». Le test de 16 cas ne le voit pas, car il fixe `agrandi: false`.

### Autres pistes vérifiées, sans défaut

- Bouton dans un bouton : non. `_Agrandir` est un `Pressable` sans bouton enfant ; `_Quitter` est un `ActionPrincipale` seul ; `_TemoinSon` n'est pas pressable.
- Texte en dur : aucun. Libellés lus dans `t.tc.observation.visite`.
- Un seul bouton plein : « Quitter » reste en registre doux.
- Composant partagé : seul `BarreCommandesObservation` change ; `TexteSansCoupure` n'est pas modifié.
- Texte x1,3, x1,5 et x3 : rien de coupé dans la sonde (hors les 4 cas ci-dessus).

### Correction proposée

1. Dans `_troisTropEtroits`, mesurer la place réelle : `(largeur - 2 * AppSpacing.sm - 2 * AppSpacing.xs - largeurDeQuitter) / 2`, où `largeurDeQuitter` est la largeur propre de la pilule (ou, plus simple et stable, prendre le mot le plus long parmi TOUS les libellés possibles : son reçu, son interrompu, agrandir, réduire, pour que la barre ne change pas de forme quand on appuie).
2. Ajouter `agrandi` (vrai et faux) à la boucle du test, soit 32 cas, et montrer que le cas 320 x1 « Réduire » échoue sur 752ede43.
3. Ajouter une capture `o2_agrandi_320x844@2_light`.

### Verdict final

**REFUSÉE.** Un majeur nouveau (mot coupé à 320 px, support agrandi). Les deux mineurs de la première revue sont confirmés. Après la correction ci-dessus et le test élargi, la branche peut être revue de nouveau.

## Fusion d'essai des douze branches CORR-2 (relu par 01KyPAZg)

Branche locale `integ-c2-essai`, jamais poussée, sur `corrections/revue-directeur-2026-10` @ f6ac3658. Ordre : elv-err, bento3b, ea-prod, tuile-tuteur, obs-coupe, coupe2, ens-route, ens-listes, ma-prod, tut-cta, adm-echus, hors-ligne.

- Conflits : chaînes i18n et `libelles_sources.json` (triviaux, régénérés par `dart run slang`) ; routeur `/eleve` entre DASH-EA-PROD et DASH-MA-PROD, composable : la redirection adulte d'EA-PROD (`redirectionAccueilEleve(capaciteAccueilAdulte: …)`) est gardée, le constructeur devient `AccueilEleveSelonPresentation` de MA-PROD, suivi de `...routesAccueilAdulte()`.
- Mesures sur la fusion (df122065) : `dart analyze --fatal-infos` 0 problème ; jetons 39 ; suite dossier par dossier 5573 réussis, 0 échec (27 dossiers ; captures ignorées 657).
