# Revue adverse PAGESHELL-200-1 (branche corrections/c2-pageshell, tête 35356e24)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** La demande est remplie en portrait (320 et 390x844 à 200 %, LTR et RTL) et pour la barre large de 600 à 700 px à 200 et 300 %. Les preuves tiennent, mutations comprises. La seule réserve sérieuse concerne le téléphone en paysage à 200 %, qui débordait déjà sur la base : la correction de PageShell aggrave ce débordement dans trois cas. Aucune configuration réaliste qui était propre sur la base ne casse. Une étape de suivi est nécessaire.

## Ce qui a été vérifié
J'ai travaillé dans un worktree jetable détaché sur origin/corrections/c2-pageshell, retiré à la fin. Rien n'a été poussé.

- **Diff** (3df81930..35356e24) :
  - `page_shell.dart` : nouveau rendu `_TeteEtCorps` / `_RenduTeteEtCorps`, utilisé seulement quand la tête défile et que le corps ne défile pas ;
  - `barre_commandes_observation.dart` : `_barreLargeCoupe`, qui passe la barre large en deux rangées ;
  - `panneau_observation_tuteur.dart` : `_corpsLarge` défile désormais via `CustomScrollView` / `SliverLayoutBuilder` ;
  - nouveaux tests, captures, et un script de capture qui saute sans `CAPTURE_DIR`.
- **Aucune zone interdite touchée** : supabase/, .github/, pubspec.yaml, thème et Coran sont intacts. Aucun libellé nouveau.
- **Outils** :
  - `dart analyze --fatal-infos` : aucun problème ;
  - `verifier_revue` : 1606 violations, autant que la base ;
  - `verifier_jetons` : 39, autant que la base. Aucune violation dans les trois fichiers touchés.
- **Tests** : `flutter test --concurrency=2` sur test/widgets, test/core, test/router, test/features et test/teaching_core : **+5325 ~2144, All tests passed**.

## Mutations (contre-épreuves)
- **page_shell.dart remis à la base** : 10 échecs, que je reproduis.
  - Les 5 cas de `page_shell_hauteur_corps_test` (320 et 390 en LTR et RTL, plus la zone d'action collée).
  - 5 cas du groupe « barre entière au premier affichage » de `salle_observation_test`.
- **Repli AD-11 retiré** (`return math.max(reste, 0)`) : « vue très basse, tête haute » échoue, donc le repli est bien gardé par un test.
- **Barre et panneau** : je n'ai pas rejoué ces contre-épreuves (46, 16 et 10 échecs annoncés par le rédacteur). En revanche, mon test adverse sur la base complète confirme les débordements en mode large que ces corrections suppriment.

## Captures ouvertes
J'ai ouvert 320x844@2 avant et après, 390x844@2 après en LTR et RTL, la barre large 472x360@2 à 300 % en RTL et la salle 700x900 à 300 %.
- **320x844@2** : avant, le bas de la barre est coupé ; après, elle est entière avec une marge sous elle.
- **Barre large à 300 %** : deux rangées, aucun mot coupé.
- **700x900 à 300 %** : une seule rangée. « Son reçu » passe à la ligne entre les mots et « Quitter » est réduit au plancher lisible.
- **RTL** : « .ici » est placé de l'autre côté parce que le texte est français en sens arabe (observation 4, hors étape).

## Tests adverses ajoutés puis supprimés
- **Barre large, la plage demandée par la consigne** : de 600 à 700 px (pas de 20), hauteurs 900 et 700, texte x2 et x3, LTR et RTL, soit 48 cas. Tous passent : aucun débordement, aucun mot coupé, barre dans la vue.
- **Portrait réaliste** : 360x640 (zone sûre 24/48), 320x568 (zone sûre 20), 375x667, 414x896, 360x740 et 320x640 passent. Le sombre 320x844 x2 passe aussi.
- **Paysage à 200 %**, débordement mesuré sur la base complète puis sur la branche :

| Taille (zone sûre) | Base | Branche |
| :--- | :--- | :--- |
| 844x390 (iPhone, 47/47/21) | 89 px | 0 |
| 932x430 (iPhone, 59/59/21) | 51 px | 0 |
| 896x414 (24/48) | 94 px | 2 px |
| 667x375 (sans zone sûre) | 115 px | 45 px |
| 800x360 (24/48) | 32 px | 56 px |
| 800x360 (24/24) | 8 px | 32 px |
| 844x390 (24/48) | 2 px | 26 px |

- **Lecture du tableau** :
  - Le bilan reste positif grâce au panneau, mais trois cas s'aggravent à cause de PageShell : en n'annulant que page_shell.dart, on retrouve 32, 8 et 2 px.
  - En 800x360 (24/48), le bas de la barre descend à 336 pour une zone sûre à 312. Le défileur de la page est à max=0 : la barre ne peut pas remonter.
- **Portrait atypique** : 320x568 avec zone sûre 47/34 (17 px), 320x580 (47/34) et 320x520 (zone sûre 20) débordent alors que la base ne débordait pas. Ce ne sont pas des appareils réels.

## Cause et remède proposé
`_hauteurCorps` donne `vue − tête` dès que ce reste dépasse la moitié de la vue, sans connaître le minimum dont le corps a besoin. Le panneau ne sait pas tenir dans moins de ce minimum : la carte large garde une barre de 96 px avec 48 px de marges, sous un bandeau agrandi. Deux pistes pour une étape suivante, sans changer le résultat en portrait :
1. Rendre la carte large du panneau défilante, barre comprise, quand la hauteur manque.
2. Laisser l'appelant déclarer à PageShell une hauteur minimale de corps.

## Réserves
1. **Moyenne : paysage à 200 % avec barres système Android**, aggravé dans trois cas (voir le tableau). Le défaut existait déjà, il n'entre pas dans la demande explicite, et le paysage s'améliore dans l'ensemble. Je ne bloque donc pas, mais il faut une étape de suivi.
2. **Mineure : nouveau débordement en portrait atypique** autour de 320x520-580 avec une zone sûre haute.
3. **Mineure : preuves visuelles incomplètes** (pas de capture en sombre, à 1440 ni en Interface guidée, pas de vraie langue arabe) et doc-commentaire en double sur `_corpsLarge`.
