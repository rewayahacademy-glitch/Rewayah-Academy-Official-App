# AD-M2-PLANCHE : planche admin sur les captures HL-A-5

Date : 04/10/2026. Passage fait dans le pilotage seulement, sans relancer Flutter ni refaire de capture.
Sources : REVUE_AD-R.md (M2, l.69-71), verifications/2026-10-03/VERIF-AD-2/LOT-3 (CONTROLE.md, comparaison_hash.txt, hl_a5_planche_capture_test.dart.txt).

## Ce qui est fait ici

1. `planche.json`, entrée `attente_refuse` : `AD-10\ad10_4_attente_refus_*` (4 chemins) remplacés par `HL-A-5\portail_apres_refus_{telephone,tablette,ordinateur}_{clair,sombre}.png` (6 chemins).
2. `planche.json`, entrée `retour_apres_validation` : `AD-10\ad10_8_retour_valide_*` (4 chemins) remplacés par `HL-A-5\retour_apres_validation_hors_portee_*` (6 chemins). C'est le nom actuel de cet écran dans le test de capture (écran 14, `fichier('retour_apres_validation_hors_portee')` à :387) : un enseignant validé revient sur `/enseignant`. Titre et gabarit de l'entrée corrigés en ce sens.
3. Doublon dans la planche : `AD-S\coque_admin_dossiers_390x844@3_light.png` et `AD-5\ad5_file_390x844@3_light.png` sont identiques (sha256 7940547e42a15abf…). Seule la seconde reste listée (entrée `02A_file`), une note l'explique dans l'entrée `coque`. Le fichier AD-S reste sur le disque.
4. Doublon HL-A-5 : les 6 paires `fiche_dossier_*` et `verifications_incompletes_*` de `captures/HL-A-5` sont identiques octet à octet (sha256 recalculé, par exemple 20e6c53f9a7cd747… pour ordinateur clair). `planche.json` ne liste aucune de ces deux séries : la fiche et les vérifications incomplètes y sont montrées par les captures AD-6, qui sont distinctes. Une note le dit dans l'entrée `02B_verifications_incompletes`. Les fichiers HL-A-5 restent sur le disque : seule une nouvelle capture peut les corriger.
5. Captures périmées retirées (`git rm`, 10 fichiers), après avoir vérifié qu'aucune planche (`05_recette/AD/planche.json`, `05_recette/EA/planche.json`) ne les cite :
   - `captures/HL-A-5/retour_apres_validation_{telephone,tablette,ordinateur}_{clair,sombre}.png` (6), plus produites depuis K-47 (HL-A-5.md l.30-31 les disait déjà périmées) ;
   - `captures/AD-6/ad6_nominal_actions_390x844@3_{light,dark}.png` et `captures/AD-6/ad6_actions_390x844@3_texte200_{light,dark}.png` (4), d'avant c61d66d (VERIF-AD-2 LOT-1, CONTROLE.md l.48 : elles montrent un « Valider le dossier » inactif sous « Refuser », état qui n'existe plus).
   `captures/HL-A-5` passe de 102 à 96 fichiers (16 écrans × 6).
6. Contrôle final : 20 écrans, 87 chemins dans `planche.json`, 0 manquant, 0 doublon (script Python, sha256).

## Ce qui reste, côté code (branche des corrections `ui/admin-v1`)

1. **Doublon fiche / vérifications incomplètes** : dans `hl_a5_planche_capture_test.dart`, l'écran 3 (:211-219) défile jusqu'au lien « Terminez les vérifications requises. » puis le touche, alors que l'écran 2 a déjà défilé jusqu'à l'emplacement de décision (:205-209) : l'image ne change pas. Il faut que la capture 3 montre l'effet du lien (la carte Vérifications, avec les cases non cochées, amenée à l'écran), puis refaire les 12 captures `fiche_dossier_*` et `verifications_incompletes_*`, vérifier par hash qu'elles diffèrent, et republier la planche.
2. **Écran 16 de la planche publiée** : à a8dfcb3 le test produit 16 écrans, dont `retour_apres_validation_hors_portee` (:387). L'artefact publié (P1VXFZvw6ioS9cFerhgPAm, 91 fichiers, 15 écrans) ne le contient pas, ni dans ses fichiers ni dans index.html. Il faut le publier. Une fois le doublon corrigé (point 1), la planche publiée doit montrer 16 écrans distincts ; aujourd'hui elle n'en montre que 14 distincts.
3. **Comptes des fiches à aligner** : HL-A-5.md dit 84 captures (14 écrans), AD-11 dit 15 écrans pour l'artefact, HL-A-6.md dit 16 écrans (96 PNG). Après les points 1 et 2, corriger HL-A-5.md et AD-11.md pour qu'ils donnent le même compte que le test (16 écrans, 96 PNG).
4. **Fraîcheur des captures HL-A-5 de 05_recette** : `portail_apres_refus_*` diffère entre 05_recette et la capture refaite à a8dfcb3 (comparaison_hash.txt, téléphone et ordinateur clair). Les captures de la planche ne sont donc pas celles d'a8dfcb3 pour cet écran. À refaire avec le point 1.
5. `AD-RC.md` l.36 signale encore les captures AD-10 dans la planche : ce constat est levé par ce passage, la fiche n'a pas été réécrite ici.
