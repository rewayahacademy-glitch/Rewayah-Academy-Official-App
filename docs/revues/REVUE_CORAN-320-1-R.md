<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse CORAN-320-1 (branche corrections/c2-coran-320, aca8fcba)

Worktree jetable détaché sur `origin/corrections/c2-coran-320`, retiré à la fin. Rien n'a été poussé ni modifié. Base de comparaison : 6e2c91c4.

## Verdict : ACCEPTÉE AVEC RÉSERVES

Pour le constat de la fiche (mode par défaut « Page du mushaf », route réelle), la demande est remplie et prouvée.

- À 320 x 568 x2, les versets prennent 53 % de la hauteur, contre 0 % avant avec un débordement de 69 px.
- À 390 x 844 x2, ils prennent 67 %, contre 37 % avant.
- Le rendu des versets est inchangé.
- Le diff ne touche que l'en-tête, les mentions et la pagination.

Les réserves portent sur les deux autres modes de la même page, non testés par le rédacteur, et sur un effet de seuil.

## Périmètre du diff (vérifié)

- `lib/features/tc_mushaf/mushaf_page.dart`, seul fichier de `lib/` modifié. Changements :
  - `_EnteteCompact` : une ligne, bouton « Mode de lecture » toujours actif, état déplié annoncé.
  - `_Attribution` en mode compact, qui réutilise `AttributionCoranCompacte` sans la modifier.
  - `_Commandes` en mode compact.
  - Plafond `MushafPage.plafonner` à 1,3.
  - En-tête et commandes déplacés dans le contenu quand le texte est agrandi.
- Non touchés : `vue_page_mushaf.dart`, `core/coran`, `core/tc_coran`, thème, i18n, `pubspec.yaml`, `supabase/`, `.github/`.
- Autres fichiers modifiés :
  - nouveau test `test/features/tc_mushaf/mushaf_texte_agrandi_test.dart` ;
  - script de capture `test/capture/coran_320_1_capture_test.dart` et sa copie `.txt` ;
  - 15 PNG ;
  - fiche dans `docs/current/REVUE-DIRECTEUR-2026-10.md`.
- Aucun libellé nouveau.

## Preuves rejouées

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `flutter test test/features/tc_mushaf` | 9/9 |
| `test/teaching_core`, `accueil_adulte`, `core/accessibilite`, `tc_mushaf`, `router` | +1844, 0 échec (188 sautés) |
| `verifier_jetons` | 39, identique avant/après, 0 dans tc_mushaf |
| `verifier_revue` | 1550, identique avant/après, 0 dans mushaf_page |

Les dossiers testés couvrent les appelants de `MushafPage` : `mushaf_ecran_test`, `coran_adulte_test`, `coran_ma7_test` et le routeur.

## Mutations

1. **Correction annulée** (`compact = false`) : 6 échecs. Ce sont les 4 tests de géométrie, le test de dépliage et la contre-épreuve à 320, qui échoue sur le débordement. La géométrie est donc bien gardée par les tests.
2. **Versets placés sous le plafond** (`plafonner(VuePageMushaf)`) : les contre-épreuves 320 x2 et 390 x2 échouent. La contre-épreuve détecte donc un changement du rendu des versets.
3. **Attribution compacte retirée** : les 4 tests de géométrie échouent.
4. **Contre-épreuve indépendante.** J'ai écrit ma propre sonde de signature, sans les clés du rédacteur, et je l'ai exécutée sur l'ancien `mushaf_page.dart` (6e2c91c4) puis sur le nouveau. Les signatures sont identiques à 320 x2, 390 x2 et 1440 x1 : largeur du cadre, échelle x2, sens rtl, versets, taille 20,945 et 26,036, interligne, police UthmanTahaNaskh, rosace. Les constantes du test sont donc authentiques.

## Captures ouvertes

- **320 x2 avant et après, clair.** Avant : en-tête, sélecteur et mention envahissants, bandes de débordement. Après : une ligne d'en-tête, un cadre de versets, l'attribution sur deux lignes, puis la pagination et l'icône « Aller à une page ».
- **320 options dépliées.** Le sélecteur et la mention réapparaissent, sans mot coupé.
- **390 x2 sombre RTL avant et après.**
- **1440 sombre après.** Identique à avant : même taille d'octets, et le rédacteur affirme une identité au pixel près.

## Réserves, dans l'ordre de priorité

1. **Mode « Lecture agrandie » à 320 x 568 x2 : versets à 32 %**, contre 0 % avant. La commande de taille passe sur deux rangées, et la zone des commandes en prend trois. La phrase « pagination sur une ligne » ne vaut qu'en mode mushaf. Or la mention de la page elle-même renvoie les lecteurs à grand texte vers ce mode. À 390 x2, ce mode atteint 53 %, contre 14 % avant. Les tests ne couvrent que le mode mushaf.
   - À faire dans une étape suivante, si le directeur considère que la commande de taille appartient à la pagination : la ramener sur la même rangée (icônes nommées) ou la replier derrière « Mode de lecture ».
   - Ajouter un test de géométrie par mode.
2. **Mode « Focus » à 320 x 568 : débordement de 29 px**, à x1 comme à x2, et de 98 px à x1,3. Le message de l'état vide est recouvert. Le défaut existait avant (69 px à x2). Il relève de l'état vide (MA-CORAN-X2-1), hors de cette étape, mais il reste visible sur la page.
3. **Effet de seuil à exactement 130 %** : le mode compact n'est pas actif. Les versets n'ont que 9 % (mushaf) ou 0 % (lecture agrandie) de la hauteur à 320 x 568, contre 54 % dès 131 %. Le défaut existait avant et sort du périmètre x2.
4. **Juz absent** à texte agrandi en lecture agrandie et en focus. Il n'est conservé, en pied de page, qu'en mode mushaf.
5. **Position « 604 / 1 » en RTL.** Le défaut existait avant et vient de `BarrePrecedentSuivant` ; il est consigné.

Les trois choix « décidés par délégation le 05/10 » sont correctement inscrits dans la fiche : plafond de 130 %, mention repliée, choix du rendu replié.

Statut : présent dans le code, testé localement. Ni staging ni déploiement.

## Fichiers cités

- `lib/features/tc_mushaf/mushaf_page.dart`
- `test/features/tc_mushaf/mushaf_texte_agrandi_test.dart`
- `docs/current/captures/CORAN-320-1/`
- `docs/current/REVUE-DIRECTEUR-2026-10.md`
- Captures du relecteur, hors dépôt : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/b061fd81-57c1-57e8-a2c0-47584b70c9bf/scratchpad/caprv/zz_versetAgrandi_320.png` et `zz_focus_320.png`
