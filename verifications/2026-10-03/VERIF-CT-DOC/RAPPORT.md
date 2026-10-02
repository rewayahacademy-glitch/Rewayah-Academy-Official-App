# VERIF-CT-DOC (K-03) : Contrôleur, documents et juridique

Date : 03/10/2026. Lecture seule. Pilotage `D:\RA_TUTEUR\pilotage-git`, branche `pilotage/tuteur-v1` @ `7ea7971`. Code lu par `git show 1108a4a:<fichier>` dans `D:\RA_TUTEUR\corrections` (branche `corrections/revue-directeur-2026-10` @ `98e3f9d`, rien modifié). Fiches lues dans le cache `yaaden-cache\tableau\etapes\` (instantané du 02/10 22:49), pas le tableau en direct. Aucune commande Flutter.

Étapes couvertes (champ `couvre` de la fiche) : CT-0, CT-1a, CT-1m, CT-10, CT-BLQ-06, PT-B-20260927-f33e8cac, JUR-SUITE-1.

## Commits cités : tous trouvés

`37d781e` (CT-1a), `8041607` (CT-1m), `8ed739e` (CT-0), `c811ab0` et `1fb3c8f` (CT-10), `7a705ae9`, `b3e3b976`, `c810a19a`, `4817adc0`, `6d0921d8`, `bb4d0ce`, `abefadf` dans le pilotage. `d7f19e5` dans le dépôt de code, sur `origin/ui/controleur-v1`.

## Verdict par étape

| Étape | Verdict | Ce qui a été contrôlé |
|---|---|---|
| CT-0 | vérifiée | `14_controleur/00_REPRISE.md`, `02_DECOUPAGE.md` (CT-0 à CT-RC, l. 20-36), `V/00_MAQUETTES_CONTROLEUR.md` et `V/PLANCHE-1..5.png` présents (commit `8ed739e`, 27/09). Règles C1 à C21 : `ressources-git/memoire/CONTROLEUR-2026-09-27.md`, les 21 codes y figurent. Images des planches non ouvertes (non vues). |
| CT-1a | vérifiée, avec un défaut | `UX_REVIEW_08_CONTROLEUR.md` @ `37d781e` (inchangé depuis). Sources datées du 27/09, l. 23-43 : ICO-MW, ICO-DPIA, ICO-AADC, ICO-AADC-11, OWASP-AZ, OWASP-LOG, NIST-AC, W-334, WCAG, M3, Flutter, HIG, NN/g, Baymard, avec URL et mode de vérification. GOV.UK exclu (l. 17). RGPD UE non relu, dit l. 45. 20 lignes (l. 53-72), contrats A à E (l. 74 et suiv.), 13 questions (l. 96-108), une seule BLOQUANTE et seulement pour la production (l. 104). **Défaut** : la preuve dit « 2 gardées, 18 adaptées », mais le fichier en compte 3 à « Garder » (l. 53, 69, 70) et 17 à « Adapter ». |
| CT-1m | vérifiée | `CONTROLEUR_EXISTING_MAPPING.md` @ `8041607`. Citations ouvertes à `1108a4a`, toutes exactes : `service_controle.dart:16-22` (`graceApresFin` 15 min, ADR-005) et `:34-72` (`ServiceControle`, `mes_seances_v`, `serviceControleProvider`, `planningGlobalProvider`) ; `vue_salle.dart:56-63` (`'masked_controller' => RoleSalle.controleur`, l. 60) ; `salle_page.dart:726-731` (`_Rappel`, `t.salle.bandeauControle`) et `:1388-1390` (controleur ou incognito, libellé vide) ; `routes.dart:332-335`, `:556`, `:567` ; `app_router.dart:793-799` (`PlanningControleurPage`) ; `nav_shell.dart:151-163` (« une seule destination, qui ne monte pas de barre ») ; `pre_vol_classe.dart:65-89` (`DetailPreCours.aucun`, l. 76) ; `enums.dart:9` ; `session_controleur.dart:23-39`. `planning_page.dart` a 498 lignes et `vue_planning.dart` 255. Aucun fichier `controleur` dans `lib/features/demo/`. |
| CT-10 | vérifiée | `LEXIQUE_CONTROLEUR.md` @ `c811ab0`, l. « Chiffres » : 219 textes = 81 « Document 08 » + 112 « Proposé par un agent (P1 à P112) », tous distincts + 26 déjà en place (E1 à E26). Recompté dans les tableaux. Les 23 lignes en plus sont la revue des messages d'erreur (§10), sans nouveau texte. Une suite P113 à P137 a été ajoutée ensuite (`08c85e9`, CT-RC), hors de CT-10. `BLOQUANTS_ET_IMPACTS.md` @ `1fb3c8f` : 40 identifiants (CT-BLQ-01 à 15, CT-IMP-EN-01 à 05, CT-IMP-AD-01 à 18, CT-IMP-TU-01 et 02). Au tableau, ils sont depuis regroupés dans CT-BLQ-06, PAQ-CT-BR1 (16), PAQ-CT-ADX (14), PAQ-CT-DIR (7) et HU-1 (EN-04, TU-01) : les 40 sont retrouvés, par le cache. `CT-BR.md` l. 21-25 : BR-CT-14 à 17. `d7f19e5` existe. Les « 241 tests verts » n'ont pas été relancés (non vu). |
| CT-BLQ-06 | vérifiée, avec un défaut | `DPIA_CONTROLEUR.md` (`b3e3b976`, plus `c810a19a`) : 17 risques R1 à R17 (l. 177-193), mesures (l. 205-221), relecture juridique par un agent (l. 284 et suiv.). Signature : `juridique/SIGNATURES_2026-10-02.md:7` « je signe » (commit `6d0921d8`). **Défaut** : le fichier lui-même dit toujours « (projet) » (l. 1, 3) et sa ligne de signature est vide (l. 254). L'artefact source du directeur n'a pas été ouvert (non vu). |
| PT-B-20260927-f33e8cac | vérifiée | `juridique/` @ `c810a19a` : `LIA_CONTROLE.md`, `ART9_RELIGION.md`, `POLITIQUE_CONTROLE_ENSEIGNANTS.md` (clause, Partie A l. 9), `INFO_ELEVES_PARENTS.md` (E-1, E-2, P-1, chacun en français et en anglais), `RGPD_UE.md`. Relecture en fin de DPIA (`DPIA_CONTROLEUR.md:284`). Signatures et validations : `SIGNATURES_2026-10-02.md:7-13`. Les points restants (représentant UE, ICO, référents, service vidéo, volumes) sont écrits l. 18 et dans la preuve. |
| JUR-SUITE-1 | vérifiée, même défaut que CT-BLQ-06 | `4817adc0` : `DOCUMENT_POLITIQUE_APPROPRIEE.md`, `CHARTE_CONTROLEUR.md` (fr et en), `DPIA_CLASSE.md`, `CORRECTIONS_A0_A3.md`. DPIA_CLASSE : 12 risques C1 à C12, bilan l. 97. Deux risques moyens restants, C2 et C9 (l. 116, 162). LIA réussie sous 5 conditions (l. 155). « Aucun vrai cours enregistré avant BR-1 » (l. 116). CORRECTIONS_A0_A3 : propositions, « rien n'est appliqué » (l. 3) ; A0 religion (l. 11, 32) ; A3 image et « qui a écouté » contre B15 (l. 69-70). Validation : `SIGNATURES_2026-10-02.md:8-14`. **Même défaut** : `DPIA_CLASSE.md` reste « (projet) » (l. 1), avec « à signer » et une signature vide (l. 161-166). |

## Défauts (à ouvrir comme étapes nouvelles, K-38 ; rien n'est corrigé ici)

1. **CT-1a, chiffre faux dans la preuve.** La preuve au tableau dit « 2 gardées, 18 adaptées ». `UX_REVIEW_08_CONTROLEUR.md` @ `37d781e` a 3 lignes « Garder » (l. 53, 69, 70) et 17 « Adapter ».
2. **Pièces signées toujours marquées « projet ».** `SIGNATURES_2026-10-02.md:16` dit que les pièces deviennent « adoptées ». Pourtant `DPIA_CONTROLEUR.md` (l. 1, 3, 254) et `DPIA_CLASSE.md` (l. 1, 161-166) gardent « projet », « à signer » et une ligne de signature vide. Les autres pièces de `juridique/` gardent aussi leur statut « projet » ou « à valider » (l. 3 de chacune). Celui qui lit une pièce seule la croit non signée.

## Non vu

- Le tableau YAADEN en direct (seul le cache du 02/10 a été lu).
- L'artefact du directeur (`S2xbA2J7cEQb2V4GAoBaxQ`).
- Les images des planches.
- Les 241 tests de `d7f19e5`.
- Le contenu de `fr.i18n.json` pour les textes du lexique.
