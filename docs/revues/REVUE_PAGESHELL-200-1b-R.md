# Revue adverse PAGESHELL-200-1b (branche corrections/c2-pageshell-b, tête 2bf10b54)

**Verdict : ACCEPTÉE AVEC RÉSERVES (mineures).** Les trois réserves de la revue PAGESHELL-200-1 sont levées, preuves à l'appui :
- plus aucun débordement en paysage 200 % sous les barres Android ;
- plus aucun débordement en portrait 320x568, 320x580 et 320x520 ;
- captures en sombre, à 1440 et en Interface guidée présentes ;
- commentaire de `_corpsLarge` nettoyé.

Aucune régression trouvée dans les suites. Aucun défaut majeur prouvé.

Statut : présent dans le code et testé localement. Ni testé sur staging, ni déployé.

## Périmètre vérifié
- Worktree jetable détaché sur origin/corrections/c2-pageshell-b, retiré à la fin. Rien n'a été poussé.
- Diff 29a4fc83..2bf10b54 : `lib/core/widgets/page_shell.dart`, `lib/features/tc_observation_ui/panneau_observation_tuteur.dart`, deux fichiers de test, le script de capture, et des captures sous `docs/current/captures/PAGESHELL-200-1b/`.
- Aucune zone interdite touchée : supabase/, .github/, vercel.json, pubspec.yaml, thème, Coran et dart_define sont intacts. Aucun libellé nouveau.
- Messages de commit : en français, avec les deux lignes d'attribution exactes.

## Mécanisme relu
1. `ColonneCorps` (un Column) mesure son besoin : enfants sans flex à leur hauteur naturelle, plus `minimumEtire` pour les enfants flexibles, plus l'espacement.
2. Elle signale l'écart à un `_ManqueCorps` transmis par un InheritedWidget.
3. `_RenduTeteEtCorps` part de `_hauteurCorps` (règle AD-11 inchangée), puis ajoute le manque. Il remet le corps en page jusqu'à 4 fois.
4. Une colonne remise en page seule relance la page après l'image. Elle ne peint pas l'indicateur de débordement pour cette image-là.

Hors PageShell, ou en tête fixe, la colonne se comporte comme un Column (`_relancer` rend faux). Le mécanisme est stable : mon test adverse vérifie `hasScheduledFrame == false` après pumpAndSettle dans 52 cas, donc il n'y a pas de boucle de relance.

## Outils
- `dart analyze --fatal-infos` : aucun problème.
- `tool/verifier_revue.dart` : 1573 violations, autant que la base annoncée.
- `tool/verifier_jetons.dart` : 39, autant que la base.

## Tests (--concurrency=2)
- test/widgets, test/core et test/router : **+1260, All tests passed**.
- test/features et test/teaching_core : **+4144 ~2164, All tests passed**.

## Mutations rejouées
| Mutation | Résultat |
| :--- | :--- |
| Manque ignoré (`if (true \|\| …)` dans la boucle de `performLayout`) | 13 échecs : les 4 tests « minimum utile » de PageShell (320x568 LTR et RTL, colonnes imbriquées, bandeau qui grandit) et les 9 cas de défaut de la matrice de géométrie (320x568 LTR et RTL, 320x580, 320x520, 800x360 24/48 LTR et RTL, 800x360 24/24, 844x390 24/48, 896x414). Les 5 cas de non-régression passent. |
| Ancien panneau (29a4fc83) avec le nouveau PageShell | 13 échecs : les 9 cas de défaut, plus les 4 tests « en-tête sans mot coupé » (standard et guidé, LTR et RTL). |

Les tests protègent donc bien la correction des deux côtés : PageShell et panneau.

## Test adverse ajouté puis supprimé
Matrice de 52 cas : Interface standard et guidée × clair et sombre × 13 géométries à texte x2, plus 1024x600 à x3, 768x1024 à x3 et 1440x900 à x1. Pour chaque cas : aucune exception, défilement à 0, 25, 50, 75 et 100 % sans exception, puis barre et libellés dans la zone sûre en bout de page.

- **Branche : 48 cas sur 52 passent.** Exemples :
  - 320x568 (47/34) guidé : max=237, barre à 314–518 pour une zone à 534 ;
  - 800x360 (24/48) standard : barre à 184–280 pour une zone à 312 ;
  - 640x360 (24/48) guidé : barre à 36–296 pour une zone à 312.
  - Les 4 échecs sont 667x375 sans zone sûre (standard 45 px, guidé 213 px), en clair et en sombre.
- **Base 29a4fc83, même matrice : 22 échecs** (17 à 268 px), dont 320x568 guidé (189 px), 640x360 et 800x360. La branche corrige donc aussi de nombreux cas en Interface guidée que la demande ne citait pas.
- **667x375** : débordement identique sur 3df81930 et sur 29a4fc83 (45 et 213 px). Il est préexistant, non aggravé, et déclaré non fait (tête fixe).

## Captures ouvertes
J'ai ouvert les captures suivantes :
- 800x360@2 en bout de page (clair) et en haut de page (sombre) ;
- 320x568@2 en sombre ;
- 320x568 en Interface guidée, bout de page ;
- 320x844 et 390x844 en Interface guidée ;
- 1440x900 en sombre.

Ce qu'elles montrent :
- Barre entière, dans la zone sûre, en bout de page.
- « Classe fictive / A » passe à la ligne entre les mots, sans « Class / e ».
- Le sombre est correct et le 1440 est propre (support, vignettes, barre).
- Le script archivé est identique au fichier de test.

## Réserves (mineures, non bloquantes)
1. **Le minimum utile vaut 48 px.** Petits écrans concernés : 800x360 et 320x568 à 200 %. En bout de page, la zone du support n'est qu'une fenêtre défilante d'environ 48 px : le support n'y est pas visible, et la pastille « En direct » est coupée par le bord de la fenêtre. Le support reste atteignable par un défilement imbriqué. C'est mieux que la base, qui débordait, mais c'est un minimum pour la saisie, pas pour regarder. À arbitrer si l'observation doit montrer une part de vidéo à 200 % sur ces écrans.
2. **667x375 sans zone sûre à 200 %** : 45 px en standard et 213 px en Interface guidée. Préexistant, en tête fixe. Le cas guidé n'est pas mentionné dans le compte rendu.
3. **Aucune capture RTL pour 1b**, alors que l'en-tête passe à un Wrap. Le RTL est couvert par les tests. Petit défaut de forme : le commentaire de `_corpsLarge` est fusionné sur une ligne d'environ 120 colonnes.

## Compte rendu du rédacteur
Il est vérifié sur les points suivants : mutations, matrice, suites de tests, outils et captures. Le tableau des cas de défaut et de non-régression est conforme à ce que j'ai mesuré.
