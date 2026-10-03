# VERIF-AD-2, LOT-2 : contrôle adverse

Contrôleur adverse, 03/10/2026. Objet : le rapport LOT-2 (commit pilotage 5d7cec42), qui porte sur AD-7, HL-A-2, HL-A-3, AD-8 et HL-A-4.
Code contrôlé : `D:\RA_TUTEUR\r-ad`, détaché sur ui/admin-v1 @ a8dfcb34ab0403b0debf8658645e3f7c3c444144. HEAD a été vérifié au début et à la fin, et `git status --porcelain` est resté vide.
Je n'ai fait aucune modification de lib/ ou de test/, et je n'ai rien écrit au tableau.

## Tests relancés sous verrou

`controle_tests.log` : `flutter test -r expanded` sur 5 fichiers, decisions_coque, visionneuse_production, revue_dossiers_depuis_validation, revue_dossier et composants_partages.
Verrou acquis à 11:57:55, durée 77 s, code 0, « +70: All tests passed! ». Les tests nommés suivants sont verts : glisser 02D avec motif, glisser 02D vide, clavier ouvert à 390, controle mesure ×4, AD-BR-02 sans RPC, et le lien des vérifications à 390 et à 1440.
Le journal contient aussi le bruit « WARNING (drift): AppDatabase created multiple times » (23 fois ; 31 fois dans tests_lot2.log). C'est du bruit de test, je ne l'attribue à aucune étape et je ne l'ai pas analysé.

## Ce que je confirme (re-vérifié par moi)

- Les 9 commits cités sont ancêtres de a8dfcb3 (`git merge-base --is-ancestor`).
- Les fichier:ligne d'AD-7 sont exacts :
  - app_bottom_sheet.dart:212-267 (225 `barrierDismissible: false`), 548-560 (Échap) ;
  - app_gabarit.dart:63 = 840 ; app_spacing.dart:77 = 800 ; app_mouvement.dart:31/35 = 180/120 ;
  - visionneuse_piece.dart:87-91, 246-276, 284-292, 418-431, 440 et 571.
- `466fdcc^:lib/core/dossier/service_validation.dart:198,221` : la durée de 60 s et `createSignedUrl` existaient avant AD-7. `git diff --name-only 8192bf8 a8dfcb3 -- supabase` est vide.
- « 7 textes sous dossiers.visionneuse pour 9 états » : exact (fr.i18n.json, enum `_Etat`).
- HL-A-3 : `4d0890e:revue_dossier.dart:563` contient `alignerEnFin: true` ; il n'en reste plus aucun à c61d66d. revue_dossier_test.dart:307-308 et 337-344 sont exacts. J'ai ouvert la capture `captures/HL-A-5/verifications_incompletes_telephone_clair.png` : le lien est bien à gauche. `alignerEnFin` n'a plus d'appelant (git grep).
- HL-A-4 : app_bottom_sheet.dart:183-199 et 354-404 sont exacts. Le commit pilotage 68ecbad1 ajoute exactement 26 PNG (statut A) sous captures/AD-8. Le défaut « 30 annoncées, 26 trouvées » tient.
- AD-8 : captures/AD-8 = 110 PNG = 84 (e070fe28) + 26 (68ecbad1).
- Porte de lecture : aucun test ne monte `lectureRequise: true` hors capture (git grep). Le défaut « moyen » du rapport tient.

## Écarts trouvés

### E1 (moyen) : AD-7 est jugé avec deux poids et deux mesures par rapport à HL-A-2

La fiche AD-7 revendique « validation rouverte seulement après une image affichée ». C'est exactement la revendication HL-A-2 n°1, que le rapport déclare fausse à a8dfcb3 et qu'il classe donc en `non_verifie`. Pour AD-7, il donne `verifie_avec_defauts` sans signaler ce point.
Preuves :
- revue_dossier.dart:226-234 (`!validationIndeterminee`) ;
- revue_dossiers_depuis_validation.dart:231 (toujours `indeterminee`) et 317-319 (refus au niveau du port).

Il faut appliquer la même mention aux deux étapes.

### E2 (moyen) : la perte du test de la porte de lecture a une origine datée, que le rapport n'a pas trouvée

À d932248, le test visionneuse_production_test vérifiait réellement la porte de lecture :
- l.133, avant lecture : `expect(_action(tester, t.dossiers.approuver).onPress, isNull)` ;
- l.161-162, après lecture : Valider, puis `service.verdicts.single.approuve, isTrue`.

AD-8 (ac796cb) puis HL-A-5 (c61d66d) ont réécrit ce fichier (`git log d932248..a8dfcb3 -- <fichier>`) et ont retiré ces deux assertions.
Le défaut n'est donc pas un manque de départ : AD-8 a affaibli le test. Cela prouve aussi que HL-A-2 n°1 était vrai à son commit (voir le verdict contesté plus bas).

### E3 (mineur) : un commentaire de production périmé contredit Q21

Le commentaire de revue_dossiers_depuis_validation.dart:179-182 (466fdcc) dit : « les verifications deviennent modifiables et la validation se rouvre ». Or l.231 et 317-319 ferment la validation. Le rapport ne le relève pas. À rattacher à AD-NETTOYAGE.

### E4 (mineur) : la fermeture de la validation au niveau du port est attribuée à tort à AD-8

Le rapport écrit, pour AD-8 : « validation fermée [...] côté port (l.317-319) ». Or `git blame -L 314,319` donne f242c061, « AD-RC M3 (m2) », du 27/09 à 09:23, et non AD-8. Seule la fermeture côté interface vient d'AD-8 (ac796cb, revue_dossier.dart:226-227 et 233).

### E5 (mineur) : la preuve AD-8 « production » s'appuie sur des tests qui passent par le port de démonstration

Tous les tests de decisions_coque_test.dart passent par `surchargesDemoAdmin(environnement: 'staging')` (l.98-101) ou par `_PortRetenu(RevueDossiersDemo)` (l.316). Ils prouvent donc la coque et la machine d'état, pas l'adaptateur `decider_dossier`.
Le chemin de production du refus n'est couvert qu'en test unitaire de l'adaptateur (revue_dossiers_depuis_validation_test). Ce n'est pas un défaut du code, mais la formulation du rapport doit le dire.
La revendication de la fiche AD-8 « état conservé même en quittant la page » n'est pas confrontée par le rapport. Elle existe dans decision_dossier_test.dart:79, que je n'ai pas relancé moi-même.

### E6 (mineur) : deux des 9 états de la visionneuse n'ont aucune capture, et l'un d'eux n'a aucun test

`captures/AD-7` (34 PNG, listés) ne contient ni `erreur` ni `indisponible`.
- `erreur` est couvert par le test 404 (dossiers_admin_test.dart:334-367).
- `_Etat.indisponible` (visionneuse_piece.dart:204 et 207-208, texte l.457-459) n'est affiché par aucun test : le seul test qui le cite vérifie son absence (`dossiers_admin_demo_test.dart:45`, `findsNothing`). Il n'apparaît dans aucune capture non plus.

Pour mémoire, le titre de la fiche annonce « 6 états » et la preuve « 9 états ».

### E7 (mineur) : une précision sur les captures

e070fe28 ajoute 20 PNG sous captures/AD-7 et en modifie 8 autres (statut M), ce que le rapport ne dit pas.
f4e4bfae (AD-11, 27/09 à 03:20) a régénéré 78 PNG de captures/AD-8, avant HL-A-5 (c61d66d, 03:57). La conclusion « captures d'avant HL-A-5 » tient, mais les 84 captures d'AD-8 ne sont plus celles du commit AD-8.

## Verdicts contestés

- HL-A-2 : je propose `verifie_avec_defauts` au lieu de `non_verifie`. n°1 était vrai à d932248 (test l.133 et 161-162, E2), puis AD-8/Q21 l'a remplacé. n°2 tient. n°3, n°4 et n°5 sont renvoyés ou suspendus, comme la fiche le déclare. Le classer `non_verifie` confond « remplacé plus tard » et « jamais prouvé ».
- HL-A-3 : je propose `verifie_avec_defauts` au lieu de `non_verifie`. 3 points sur 4 tiennent, et je les ai re-vérifiés. Le quatrième était vrai à 4d0890e (l.563) et HL-A-5 l'a remplacé délibérément.
- AD-7 : le verdict `verifie_avec_defauts` est maintenu, mais il doit porter E1 (même mention que HL-A-2), E2 et E6.

## Non vérifié par moi

- Les contre-épreuves par mutation (porte de lecture, viewInsets, garde du glisser) n'ont pas été faites, puisque lib/ est en lecture seule.
- La suite complète n'a pas été relancée, ni les chiffres 171, 318 et 321.
- Je n'ai ouvert que 2 captures : `captures/AD-7/ad7_acces_retire_390x844@3_light.png` (conforme : le texte d'accès retiré, Fermer, le repère Démonstration) et la capture HL-A-5 citée plus haut.
