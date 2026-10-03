# VERIF-AD-2, LOT-2 : AD-7, HL-A-2, HL-A-3, AD-8, HL-A-4

Date : 03/10/2026. Vérificateur : sous-agent de la session 00166a22. Lecture seule : aucun commit de code, rien écrit au tableau.
Code vérifié : worktree détaché `D:\RA_TUTEUR\r-ad`, HEAD = `a8dfcb34ab0403b0debf8658645e3f7c3c444144`, contrôlé au début et à la fin.
Fiches lues : `yaaden-cache/tableau/etapes/{AD-7,HL-A-2,HL-A-3,AD-8,HL-A-4}.json`. Le dossier `tableau-frais/etapes/` n'a aucune fiche pour ces cinq étapes.
Rapports de recette relus : `05_recette/AD/AD-7.md`, `AD-8.md` (section HL-A-3), `AD-9.md` (section HL-A-4, l.26-33), `HL-A-5.md`.
Vérification précédente réutilisée : `verifications/2026-10-03/VERIF-AD/` (RAPPORT.md, CONTROLE.md). Elle portait sur AD-RC ; elle a lancé `test/features/admin_dossiers` en entier (+164, 0 échec) et `composants_partages_test` (+136 ~5). Ces passages couvrent aussi mes étapes, et je les ai rejoués ci-dessous.

## 1. Mesures (toutes par `flutter-verrou.ps1`)

| Passage | Résultat | Journal |
|---|---|---|
| `visionneuse_piece_test`, `visionneuse_production_test`, `revue_dossiers_vue_piece_test`, `revue_dossiers_depuis_validation_test`, `revue_dossier_test`, `decision_dossier_test`, `decisions_coque_test`, `dossiers_admin_test`, `dossiers_admin_demo_test`, `dossiers_sans_piece_test`, `composants_partages_test`, `repere_demonstration_test` | verrou acquis 11:20:40, 92 s, code 0 : « 01:13 +108: All tests passed! » | `tests_lot2.log` |
| Même chose en `-r expanded` pour `revue_dossiers_vue_piece_test`, `revue_dossiers_depuis_validation_test`, `decision_dossier_test`, `composants_partages_test`, `visionneuse_production_test`, `decisions_coque_test`. Le premier journal, en rapporteur compact, ne nomme pas tous les fichiers. | verrou acquis 11:34:18, code 0 : « 00:43 +64: All tests passed! » | `tests_lot2_detail.log` |

Après ces passages, seuls `windows/flutter/generated_*` étaient modifiés. Je les ai restaurés par `git checkout -- windows/`, et `git status --porcelain` est vide.
Suite complète non relancée (consigne). `flutter analyze` non relancé : VERIF-AD l'a fait sur ce même `a8dfcb3` (« No issues found! », `VERIF-AD/analyze.log`).
**Contre-épreuves non faites.** J'avais préparé deux mutations temporaires de `lib/` : porte de lecture neutralisée, puis garde du glisser et `viewInsets` retirés. Je ne les ai pas lancées : l'outil a refusé des actions jugées « modification de ressource partagée » dans ce worktree, et j'ai renoncé à modifier `lib/`, même de façon temporaire. Les deux points concernés sont signalés plus bas comme non prouvés par contre-épreuve.

## 2. Étape par étape

### AD-7 : visionneuse ADM-02C : **vérifié avec défauts**

La fiche revendique les points suivants. Chacun a été confronté au code de `a8dfcb3`.
- Commits `466fdcc`, `37b7430`, `d932248` ancêtres de `a8dfcb3` (`git log`).
- `AppBottomSheet.ouvrirLecture` : `lib/core/widgets/app_bottom_sheet.dart:212-267`.
  - Plein écran sous `AppGabarit.seuilEtendu` = 840 (`app_gabarit.dart:63`), sinon dialogue borné à `AppPage.largeurLecture` = 800 (`app_spacing.dart:77`).
  - `barrierDismissible: false` (l.225).
  - Échap rebranché par `Shortcuts`/`DismissIntent` (l.548-560).
  - Durées 180/120 (`app_mouvement.dart:31,35`), nulles en mouvement réduit (`:105-106`).
- Zoom de 100 à 400 % par pas de 25 % : `visionneuse_piece.dart:87-91`, `:246-276`, `minScale: 1` (l.440). Touches `=`/`+`/`-`/`0` et pavé numérique (l.284-292). Info-bulle avec la touche (l.536).
- Focus rendu à « Voir la pièce » : `revue_dossier.dart:97-120`. Testé à 1440 : « 1440 : Echap ferme et rend le focus », « fermer rend le focus » (`tests_lot2.log`).
- Pièce dessinée par le code « Document fictif » : `visionneuse_piece.dart:571-668`, aucun asset.
- Aucun appel serveur nouveau.
  - `ServiceValidation.apercu` → `createSignedUrl(cle, 60)` existait déjà avant AD-7 (`git grep 466fdcc^ -- service_validation.dart:219-221`).
  - L'adaptateur l'utilise (`revue_dossiers_depuis_validation.dart:238-290`).
  - Frontière (`supabase .github vercel.json pubspec.yaml lib/core/theme`) entre `8192bf8` et `a8dfcb3` : vide (`git diff --stat`).
- Lecture exigée : `lectureRequise` (`revue_dossiers_depuis_validation.dart:222`), `_lectureFaite` (`revue_dossier.dart:82`). Les cases se referment sur un échec (`revue_dossier.dart:103-111` ; `visionneuse_piece.dart:138-154`). Les formats pdf et heic restent fermés (`typeImage`, l.66-86).
  - Tests verts : `dossiers_admin_test` « signature en échec (404) », « une pièce pdf… rien n'est signé ».
- « 9 états » : l'énumération `_Etat` en compte bien 9 (`visionneuse_piece.dart:50-60`). Sept textes sont sous `dossiers.visionneuse.*`. `indisponible` emprunte `dossiers.revue.pieceIndisponible`, et `contenu` n'a pas de texte. La formulation « 9 états i18n `dossiers.visionneuse.*` » est donc approximative (le titre de la fiche dit « 6 états »), mais rien n'est écrit en dur.
- Captures : `captures/AD-7` contient 34 PNG = 14 (AD-7, `fdf03c21`) + 20 (HL-A-3, `e070fe28`).
  - Ouvertes : `ad7_contenu_390x844@3_light.png` (plein écran, disque retour, « Document fictif », zoom à gauche, « Fermer » à droite) et `ad7_chargement_1440x900@1_dark.png` (dialogue borné, croix, squelette).

Défauts NOUVEAUX :
- **D-L2-1 (moyen, couverture de test)** : la porte de lecture n'a plus aucun test qui puisse échouer. La règle est « cases fermées jusqu'à la première image peinte » (P-ADM-06 pt 5).
  - Aucun test ne construit un `DossierPourRevue` avec `lectureRequise: true`. `git grep lectureRequise -- test` ne trouve que `test/capture/ad7_visionneuse_capture_test.dart:88`.
  - En production, depuis AD-8 (Q21), la validation reste fermée quelle que soit la lecture. Les tests de production (`visionneuse_production_test.dart:130-167`, `dossiers_admin_test.dart:288-367`) tapent les cases puis vérifient que « Valider » est absent : ils passeraient même sans la porte.
  - Le test `visionneuse_production_test.dart:130` dit « cases fermées » sans le vérifier.
  - Non prouvé par contre-épreuve (voir §1).
- **D-L2-2 (mineur, test au titre faux)** : `dossiers_admin_test.dart:288-289` s'intitule « … et la validation se rouvre » alors que son corps vérifie l'inverse (l.328-331 : `approuver` findsNothing). Même chose pour `visionneuse_production_test.dart:55-56` (« … cocher, valider »), qui vérifie l.163-167 que la validation est indisponible.
- Constat sans nouveauté : les captures AD-7 sur fond d'écran 02B montrent le rendu d'avant HL-A-5. Par exemple, `ad7_chargement_1440x900@1_dark` laisse voir « Valider le dossier » en bouton et le lien sous les actions. HL-A-5.md le reconnaît (« Captures des dossiers AD-6 à AD-11 non refaites »). Rattachement possible : AD-NETTOYAGE.

### HL-A-2 : restes d'AD-6 : **non vérifié** (n°1 faux à `a8dfcb3`)

- n°2 : le test `composants_partages_test.dart:391` est réécrit en test positif (diff `d932248`) et passe au vert (`tests_lot2.log`). **Tient.**
- n°3 et n°5 : renvoyés vers HL-A-3, voir plus bas. n°4 : la décision Q-AD7-7 est toujours attendue. Rien à vérifier, et la fiche ne revendique rien sur ces points.
- **n°1 : la revendication « validation rouverte en production après lecture, test depuis la coque `visionneuse_production_test.dart` » est fausse à `a8dfcb3`.**
  - `revue_dossier.dart:226-234` : `peutValider` exige `!validationIndeterminee`, et l'adaptateur de production pose toujours `ConsequenceValidation.indeterminee` (`revue_dossiers_depuis_validation.dart:231`).
  - `decider()` refuse lui-même la validation (`:317-319`, AD-RC m2).
  - Le test cité vérifie désormais l'inverse : `visionneuse_production_test.dart:161-167`, « validation indisponible », `verdicts` vide.
  - Ce n'est pas une régression : AD-8 a refermé la validation, selon la spec l.1115-1119 et Q21, ce que la fiche AD-8 annonce. Mais ce que HL-A-2 revendique n'est plus vrai. Seule partie encore vraie : la consultation par URL signée et l'ouverture des cases après lecture, et celle-ci n'est pas prouvée par un test (D-L2-1).
- Proposition : que l'orchestratrice note HL-A-2 n°1 « remplacé par AD-8/Q21 » plutôt que « vérifié ».

### HL-A-3 : **non vérifié** (alignement du lien faux à 390 sur `a8dfcb3`)

- GroupeReglages placé par mesure : `groupe_reglages.dart:325-459` (`_RangeeMesuree`). Le contrôle reste à côté du libellé si mot le plus long + 8 + largeur naturelle du contrôle ≤ largeur disponible, sinon il passe dessous à 4. Il ne reste aucun seuil fixe.
  - Tests « GroupeReglages controle mesure, … » (`composants_partages_test.dart:422-460`), verts. **Tient.**
- Captures AD-7 manquantes : 20 PNG ajoutés par `e070fe28` (chargement, format, accès retiré, hors ligne, aucune pièce, en 390 et 1440, clair et sombre). Squelette borné : `visionneuse_piece.dart:418-431`. **Tient.**
- Repère « Démonstration » par clé i18n : `repere_demonstration.dart:11` (`t.commun.demonstration.repere`) ; `repere_demonstration_test` vert. **Tient.**
- **Lien « Terminez les vérifications requises. » aligné en fin « (100 %, 200 %, 390, 1440) » : faux à 390 sur `a8dfcb3`.**
  - HL-A-5 (`c61d66d`) a retiré l'unique appel `alignerEnFin: true`. `git grep alignerEnFin a8dfcb3 -- lib test` ne le trouve plus que dans sa définition (`lien_fleche.dart:29,36,74,93`) ; en `4d0890e`, il était appelé à `revue_dossier.dart:563`.
  - À `a8dfcb3`, le lien est dans `_LigneEtat`, aligné `centerStart` (`revue_dossier.dart:557-577`). Sur mobile, il est au bord de DÉBUT. Le test le vérifie : `revue_dossier_test.dart:307-308`, `lien.left ≈ 16 + 4`.
  - Capture ouverte : `captures/HL-A-5/verifications_incompletes_telephone_clair.png`, où le lien est à gauche.
  - À 1440, il est en fin, dans la rangée de Refuser (`revue_dossier_test.dart:337-344`).
  - C'est un choix délibéré de HL-A-5 (ligne d'état à la place de Valider), pas une régression. La revendication de HL-A-3 n'est donc plus vraie partout.
- Défaut NOUVEAU **D-L2-3 (mineur)** : le paramètre `LienFleche.alignerEnFin` (`lien_fleche.dart:29-36`, `:74`, `:93`) est désormais du code mort dans un composant partagé, sans appelant ni test.

### AD-8 : ADM-02D refus, ADM-02E validation : **vérifié avec défauts**

- Commits `ac796cb`, `33e80e1`, `bba3293` ancêtres de `a8dfcb3`.
- Production par `decider_dossier` existant : `revue_dossiers_depuis_validation.dart:305-360` et `:402-413` (`ServiceValidation.decider`). Aucun nouvel appel.
- Validation fermée hors démonstration (Q21) :
  - côté interface, `revue_dossier.dart:226-234` et `:658-659` ;
  - côté port, `revue_dossiers_depuis_validation.dart:317-319` ;
  - test « valider : AD-BR-02, sans lecture de file ni appel RPC », vert (`tests_lot2_detail.log`, +64).
- Le refus reste ouvert (`:192`, `peutRefuser = d.documentId != null`), comme la fiche l'annonce (« ne pas fusionner dans main sans décision du directeur »). C'est le sujet d'**AD-M3-PROD** (déjà au tableau, décision S1 → a) : rattachement, pas un nouveau défaut.
- Refus sans motif, Annuler, Échap, Entrée qui n'envoie pas, double tap = un seul appel, réponse perdue (07) sans double décision, validation par 02E : 8 tests de `decisions_coque_test`, verts dans les deux journaux.
- Résultat inconnu sans boutons, « Vérifier le résultat » sur geste : `revue_dossier.dart:316-348`.
- Captures : `captures/AD-8` contient 110 PNG = 84 (AD-8, `e070fe28`, conforme à « 84 PNG ») + 26 (HL-A-4).
  - Ouverte : `ad8_hors_ligne_clic_1440x900@1_light.png` (02D en dialogue, « Vous êtes hors ligne. Le refus n'a pas été envoyé. », motif conservé).
- Constat sans nouveauté : les captures AD-8 datent d'avant HL-A-5 (régénérées par `f4e4bfae`, AD-11). Dans la capture ouverte, la file montre encore des tuteurs (« Amina Benali, Tuteur »), ce qui est antérieur à K-47 (HL-A-6). Elles ne reflètent donc pas `a8dfcb3`. HL-A-5.md le reconnaît. Rattachement : AD-NETTOYAGE.
- Défaut NOUVEAU pour cette étape : aucun au-delà de D-L2-1 et D-L2-2, qui touchent aussi les tests de production d'AD-8.

### HL-A-4 : restes d'AD-8 : **vérifié avec défauts**

- Correction dans le composant partagé : `app_bottom_sheet.dart:183-199`. Le retrait `viewInsets` est appliqué au `builder` de la feuille. `_GardeGlissement` et `_GlissementRetenu` (l.354-404) font passer un glisser vers le bas par `maybePop` quand `popDisposition == doNotPop`.
- Tests depuis la vraie coque (`decisions_coque_test.dart:87-121` : `RewayahApp`, vrai routeur, Personnes, ligne), verts :
  - « 390 : glisser 02D vers le bas avec un motif pose la question d'abandon (PopScope), sans rien envoyer » ;
  - « 390 : glisser 02D vide la ferme, sans question » ;
  - « 390, clavier ouvert : ni le champ ni les actions sous le clavier, et Refuser se tape » (`FakeViewPadding(bottom: 336)`, l.276-310).
- Revendication « test rouge puis corrigé » : je n'ai pas pu la rejouer (contre-épreuve non faite, §1). Le diff `3dd89f4` ne touche que `app_bottom_sheet.dart` côté `lib/` et ajoute ces tests. C'est cohérent, mais le « rouge » n'est pas prouvé ici.
- Captures : 26 PNG ajoutés par le commit pilotage `68ecbad1` (hors ligne au clic ×6, 02E inconnu ×6, 02E plus prêt ×6, `refus_saisi_200` ×4, `validation_200` ×4).
  - Ouvertes : `ad8_validation_inconnu_390x844@3_light.png` (« Le résultat de la validation n'est pas encore confirmé. », seulement « Fermer » et « Vérifier le résultat ») et `ad8_refus_saisi_200_390x844@3_dark.png`.
- « Dernier passage 318 réussis » : non rejoué tel quel (suite non relancée). Les fichiers liés sont verts ici.
- Défaut NOUVEAU **D-L2-4 (mineur, document)** : la fiche annonce « 30 captures », mais le commit pilotage `68ecbad1` n'ajoute que 26 PNG sous `captures/AD-8` (`git show --stat`), et aucun autre commit n'en ajoute pour HL-A-4. Le chiffre 30 n'est pas retrouvé.

## 3. Synthèse

| Étape | Verdict | Motif |
|---|---|---|
| AD-7 | vérifié avec défauts | Tout tient. D-L2-1 (porte de lecture sans test qui puisse échouer) et D-L2-2 (titres de test faux). |
| HL-A-2 | non vérifié | n°1 (« validation rouverte en production ») est faux à `a8dfcb3`, refermée par AD-8/Q21 ; le test cité vérifie l'inverse. n°2 tient. |
| HL-A-3 | non vérifié | L'alignement en fin du lien est faux à 390 depuis HL-A-5 (`c61d66d`). Mesure GroupeReglages, captures, squelette et clé i18n tiennent. D-L2-3 (`alignerEnFin` mort). |
| AD-8 | vérifié avec défauts | Tout tient. Refus ouvert en production = AD-M3-PROD (déjà au tableau). D-L2-1 et D-L2-2 touchent aussi ses tests de production. |
| HL-A-4 | vérifié avec défauts | Correction et tests tiennent. « Rouge d'abord » non rejoué. D-L2-4 (30 captures annoncées, 26 trouvées). |

Étapes nouvelles possibles, à trancher par l'orchestratrice (K-38, rien rouvert) :
- **AD-T-LECTURE** : un test de la porte de lecture qui échoue si `_lectureFaite` est neutralisé. Il passe par un port de démonstration ou un faux port avec `lectureRequise: true` et `ConsequenceValidation` connue : cases inactives avant l'image, actives après, refermées sur une erreur. Corriger aussi les titres de test (D-L2-2).
- D-L2-3 et D-L2-4 peuvent rejoindre **AD-NETTOYAGE**.
