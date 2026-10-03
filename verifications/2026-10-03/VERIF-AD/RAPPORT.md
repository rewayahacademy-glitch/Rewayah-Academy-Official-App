# VERIF-AD : vérification de AD-RC (M1 à M5 de REVUE_AD-R)

03/10/2026. Session de vérification (ni A-2026-09-26-service, ni A-27/09-adrc). Lecture seule : aucun commit de code.

- Code : worktree détaché `D:\RA_TUTEUR\r-ad` sur `a8dfcb3` (= `origin/ui/admin-v1`), créé par `git worktree add --detach`.
- Documents : `05_recette/AD/REVUE_AD-R.md` (M1 à M5, l.60-93), `05_recette/AD/AD-RC.md`, fiches du cache `yaaden-cache/tableau/etapes/AD-*.json` (lues le 03/10, cache du 03/10 07:10).
- Leçons relues : `LECONS_DES_ROLES.md` §5, §6, §7, §13, §14.

## 1. Mesure (via `flutter-verrou.ps1`)

| Commande | Résultat | Journal |
|---|---|---|
| `flutter pub get` | « Got dependencies! », code 0 | `pub_get.log` |
| `flutter analyze` | « No issues found! (ran in 175.2s) » | `analyze.log` |
| `flutter test` ciblé : `test/features/admin_dossiers`, `test/features/admin_configuration`, `admin_coque_test.dart`, `dossiers_admin_demo_test.dart`, `dossiers_admin_test.dart`, `dossiers_sans_piece_test.dart`, `comptes_test.dart`, `test/widgets/page_shell_etat_test.dart`, `test/core/capacites/revue_dossiers_depuis_validation_test.dart`, `revue_dossiers_vue_piece_test.dart`, `test/features/demo/dossiers_demo_test.dart` | **+164, 0 échec, 0 ignoré** (« 02:20 +164: All tests passed! ») | `tests_cibles.log` |

Verrou : acquis 07:44:15, libéré après 405 s, code 0. Suite complète NON relancée (hors énoncé) ; le chiffre 3537/1298/0 d'AD-RC n'est donc pas rejoué ici.
Après `pub get`, seuls `windows/flutter/generated_*` étaient modifiés (régénération attendue), restaurés par `git checkout -- windows`.

## 2. M1 à M5 : constat contre correction

Les commits cités par la fiche AD-RC du tableau (`c1d33d8`, `f242c06`, `a8dfcb3`) sont sur `origin/ui/admin-v1`. Ceux cités dans le tableau « Ce qui est fait » de `AD-RC.md` (`dcd85ce`, `23d39a5`, `746fb94`) n'existent que sur les branches locales `adrc/m1`, `adrc/m3`, `adrc/m4` ; `git patch-id --stable` les donne identiques deux à deux aux commits de `ui/admin-v1` (contenu vérifié, référence à corriger : voir défaut D3).

### M1 : tuteur `pending_kyc` compté « attend une décision » : CORRIGÉ

- `lib/core/admin/service_comptes.dart:152-153` (à `a8dfcb3`) : `attendUneDecision => etat == AccountStatus.pendingKyc && role == AppRole.teacher` (diff `c1d33d8`).
- `lib/features/admin_comptes/comptes_page.dart` (diff `c1d33d8`, hunk `@@ -273`) : colonne Pièce « Sans objet » pour `AppRole.guardian`.
- `assets/i18n/fr.i18n.json` : intro « Un enseignant sans pièce… », clé `pieceSansObjet` ; `strings*.g.dart` régénérés.
- n2 (partie fixture) : `GUARDIAN-SR-000002` passé à `EtatPiece.aucune` dans `test/features/comptes_test.dart` (3 occurrences). Le renommage du persona `famille-incomplet` (autre partie de n2) n'est pas fait ; AD-RC ne le revendique pas.
- Tests : `comptes_test.dart` « un tuteur pending_kyc n attend aucune decision, un enseignant si » et « un tuteur seul en attente ne fait apparaitre aucun bandeau », verts dans `tests_cibles.log`. Le premier échouerait sur l'ancien code (attend « 2 personnes », l'ancien getter en donne 3).

### M2 : `planche.json` en retard sur HL-A-5 / HL-A-6 : CORRIGÉ

- Pilotage `d5fdd94` (sur `origin/pilotage/tuteur-v1`) : `dernier_commit` = `2fac423`, écrans `tuteur_apres_inscription` et `tuteur_attente_ouverture` (6 captures chacun, 14 occurrences `tuteur_`), `attente_famille_dispensee` marqué `"perime": "K-47 …"`, note n5 sur l'écran 16.
- 84 chemins de capture listés sur 20 écrans : 84 présents sous `05_recette/AD/captures/` (Test-Path rejoué le 03/10).
- `AD-RC.md` cite `a73ace1` (même sujet, même date), qui n'est PAS ancêtre de `origin/pilotage/tuteur-v1` (commit d'avant rebase) : défaut D3.

### M3 : refus et aperçu ouverts en production, `decider()` sans défense : CORRIGÉ POUR LA PARTIE SANS ARBITRAGE, RESTE NON TRAITÉ

- `lib/core/capacites/revue_dossiers_depuis_validation.dart:314-319` (diff `f242c06`) : `decider()` lève `CapaciteIndisponible('AD-BR-02')` pour `DecisionDossier.valider` avant toute lecture ou RPC.
- Test `revue_dossiers_depuis_validation_test.dart` « valider : AD-BR-02, sans lecture de file ni appel RPC » (compte `appels == 0`, `lectures == 0`), vert.
- **Reste** : le directeur a tranché le 27/09, réponse définitive (champ `decisions_directeur` de la fiche AD-RC) : « S1 → a. Oui, fermer les deux comme la validation, jusqu'à BR-1 ». À `a8dfcb3` ET sur `origin/corrections/revue-directeur-2026-10`, le refus reste ouvert (`revue_dossiers_depuis_validation.dart:192` `peutRefuser = d.documentId != null` ; `:322` seul garde `AD-BR-06` si la RPC manque) et l'aperçu par URL signée aussi (`:37`). Aucune étape du tableau ne porte cette décision (grep « fermer les deux », « aperçu des pièces », « peutRefuser » sur `tableau/` : seules la fiche AD-RC et la question `A-q-20260927-c6379fd5`, encore « nouveau »). Défaut D1.

### M4 : `PageShell` démonte le corps à la bascule : CORRIGÉ

- `lib/core/widgets/page_shell.dart` (diff `a8dfcb3`) : `_Bascule` (StatefulWidget) tient deux `GlobalKey` (`PageShell.tete`, `PageShell.corps`) via `KeyedSubtree` ; une seule branche rendue à la fois.
- Test `test/widgets/page_shell_etat_test.dart` : 3 tests verts sur `a8dfcb3` (`tests_cibles.log`).
- Contre-épreuve (page_shell de `739f478` remis temporairement, puis rétabli par `git checkout`) : voir §3.

### M5 : conflits avec `ui/enseignant-v1` : PARTIE CL-4 CORRIGÉE, PARTIE ENSEIGNANT HORS AD-RC

- `739f478` : fusion à deux parents `2fac423` + `d44710a` ; `d44710a` et `2fac423` ancêtres de `a8dfcb3` (`merge-base --is-ancestor` = 0).
- Aucun marqueur de conflit dans `lib/`, `test/`, `assets/` (`git grep '<<<<<<<'` : seuls deux fichiers de police binaires correspondent).
- `AppIcons.moins` défini `lib/core/icons/app_icons.dart:374`, utilisé `lib/features/admin_dossiers/visionneuse_piece.dart:358` ; `reduire` (CL-4) reste `:251`.
- `LigneRubrique` (`groupe_reglages.dart:26-82`) porte `pastille`, `pastilleSousLibelle`, `libelleSemantique`, `focusNode`.
- La partie enseignant (`0b01297` / `1108a4a`) est explicitement laissée hors AD-RC (titre de la fiche : « M5 partie CL-4 ») ; elle relève de l'intégration (INTEG-RC-1, hors périmètre de cette vérification).

## 3. Captures réelles contre la planche (artefact P1VXFZvw6ioS9cFerhgPAm)

L'artefact est lisible. C'est une planche de captures (et non de maquettes dessinées), sans libellés 02A/02B/02E ; correspondance établie par `11_admin/V/00_MAQUETTES.md:16` et :297-305 : 02A = `coque_et_file`, 02B = `fiche_dossier`, 02E = `validation`. Images de la planche téléchargées dans `planche/img/` (sha256 dans le journal de la session).

Rendu réel produit sur `a8dfcb3` par le test de capture existant (copie : `hl_a5_planche_capture_test.dart.txt`, non modifié), vraie coque admin, vrai routeur, démonstration :
`CAPTURE_DIR=…\captures_reelles flutter test test/capture/hl_a5_planche_capture_test.dart --name "(ordinateur, clair|telephone, sombre|telephone, clair), chaine principale"` → « +3: All tests passed! » (`captures_reelles.log`, verrou acquis 08:31:42, 54 s). Un premier essai avec trois `--plain-name` n'a lancé aucun test (filtres cumulés en ET, « No tests match », journal écrasé par le second passage).

| Écran | Planche | Réel `a8dfcb3` | SHA-256 (16 premiers) | Constat après ouverture des deux images |
|---|---|---|---|---|
| 02A file, 1440 clair | `planche/img/coque_et_file_ordinateur_clair.png` | `captures_reelles/coque_et_file_ordinateur_clair.png` | 04533500E1B59F13 = 04533500E1B59F13 | **Identique au pixel.** |
| 02B revue, 390 sombre | `planche/img/fiche_dossier_telephone_sombre.png` | `captures_reelles/fiche_dossier_telephone_sombre.png` | F02E1FBC13F4865A = F02E1FBC13F4865A | **Identique au pixel.** |
| 02E validation, 390 clair | `planche/img/validation_telephone_clair.png` | `captures_reelles/validation_telephone_clair.png` | B9CFADA03C6B1306 ≠ 598E0D3D9C3A2FE1 | Même composition, mêmes textes, même ordre (titre, « Omar Haddad · Enseignant », conséquence, Valider plein, Annuler). Seule différence visible : la graisse du libellé « Valider le dossier », un peu plus forte. C'est le rendu `ActionPrincipale` de CL-4 apporté par la fusion `739f478`, annoncé par AD-RC.md l.27 (« les captures admin ne sont pas rejouées »). |

Conséquence : M1, M3 et M4 ne changent rien à ces trois écrans ; la fusion CL-4 change seulement la graisse du bouton principal en 02E. La planche du directeur reste fidèle à `a8dfcb3` pour ces trois écrans, à cette graisse près.

Remarques déjà enregistrées ailleurs, sans changement à `a8dfcb3` (non comptées comme défauts de cette vérification) : en 02E, « Le dossier de Omar Haddad » n'a pas de variante élidée (m10 de REVUE_AD-R) ; en 02B à 390, le titre de section « Pièce d'identité » passe sous les onglets fixes au cadrage de la capture (identique au pixel à la planche) ; disposition empilée de 02E (Valider plein au-dessus d'Annuler), différente de `00_MAQUETTES.md:303-304`, qui relève de l'harmonisation HU-1 (AD-S et AD-5 renvoyés en HU-1, REVUE_AD-R l.23).

### Contre-épreuve M4

Dans le même worktree, `lib/core/widgets/page_shell.dart` remplacé par la version de `739f478` (avant M4), puis rétabli par `git checkout` :
- avant M4 : `00:03 +0 -3: Some tests failed.` Les 3 tests de `page_shell_etat_test.dart` échouent (`m4_contre_epreuve_avant.log`) ;
- après rétablissement : `00:02 +3: All tests passed!` (`m4_apres.log`).
La revendication d'AD-RC (« échoue sur le code d'avant (0 sur 3) et passe après ») est confirmée. `git status --porcelain` est vide en fin de vérification.

## 4. Jetons écrits à la main (à remonter vers HU-1)

Relevé par motif (`Color(0x`, `Colors.`, `FontWeight.wN`, `fontSize:`, `letterSpacing:`, rayons, `EdgeInsets` chiffrés, largeurs/hauteurs fixes) sur `lib/features/admin_dossiers`, `admin_comptes`, `admin_configuration`, `admin_shell.dart`, `page_shell.dart`, `groupe_reglages.dart`, `repere_demonstration.dart`, `dossier/attente_page.dart` : 11 lignes, liste complète dans `jetons_a_la_main.txt`.

- Graisses `FontWeight.w600` à la main : `admin_shell.dart:463`, `:613` ; `groupe_reglages.dart:301` ; `file_dossiers.dart:361` ; `repere_demonstration.dart:42`.
- `repere_demonstration.dart:41-46` : `fontSize: 9`, `height: 1`, `letterSpacing: 0`.
- Largeurs fixes : `detail_dossier.dart:204` (`width: 160`) ; `visionneuse_piece.dart:659-660` (`320`, `320 / ratio`).
- Aucune couleur littérale. Aucune de ces lignes n'est introduite par les commits AD-RC (`c1d33d8`, `f242c06`, `a8dfcb3`). Concorde avec le relevé déjà porté dans la preuve de la fiche AD-RC.

## 5. Défauts et étapes proposées (K-38 : aucune étape rouverte)

- **D1 (bloquant pour toute fusion vers `main`, pas pour AD-RC tel que délimité)** : décision définitive du directeur S1 → a (27/09) non appliquée : refus d'un dossier enseignant et aperçu des pièces encore ouverts en production à `a8dfcb3` et sur `corrections/revue-directeur-2026-10`. Étape proposée **AD-M3-PROD** : `peutRefuser: false` + `BlocageRevue.decisionIndisponible` hors démonstration, `decider()` lève `CapaciteIndisponible` pour le refus, aperçu (`createSignedUrl`) fermé hors démonstration, tests qui comptent zéro appel RPC et zéro URL signée ; à faire sur `corrections/revue-directeur-2026-10`. Passer aussi la question `A-q-20260927-c6379fd5` à « traité ».
- **D2 (mineur)** : les 8 mineurs « relevés par les relectures » d'AD-RC.md (l.28-36) et m1, m3 à m17, notes : aucune étape ne les porte au tableau sous un identifiant AD (à vérifier par l'orchestratrice ; proposer **AD-NETTOYAGE**).
- **D3 (mineur, document)** : `AD-RC.md` cite des commits locaux (`dcd85ce`, `23d39a5`, `746fb94`) et un commit pilotage d'avant rebase (`a73ace1`) au lieu de `c1d33d8`, `f242c06`, `a8dfcb3`, `d5fdd94`. Contenu identique (patch-id). Correction de document à faire par l'auteur.

## 6. Étapes AD-* couvertes (cache `tableau/etapes/AD-*.json`, 03/10 07:10)

- **AD-RC** (`fait`, session A-27/09-adrc) : objet direct de cette vérification. Tout ce que sa fiche revendique est confirmé (M1, M2, M3 partie sans arbitrage, M4, M5 partie CL-4 ; analyze 0 ; tests ciblés 164/0). Proposée à « vérifié ».
- **AD-R** (`fait`) : seuls ses 5 majeurs ont été confrontés au code (diffs `c1d33d8`, `f242c06`, `a8dfcb3`, `739f478`, contre-épreuve M4). Ses 16 mineurs et 14 notes ne l'ont pas été : AD-R n'est PAS proposée à « vérifié » par cette session.
- AD-4 à AD-11, AD-5, AD-S, AD-G0 (`fait`) : non couvertes (énoncé limité à M1-M5 / AD-RC). AD-X (`a_faire`, attend le directeur) : non concernée. AD-1, AD-2, AD-3, AD-3R, AD-BR, AD-G1 : déjà « vérifié ».

## 7. Verdict

**Accepté pour AD-RC** dans le périmètre que sa fiche délimite. Le défaut D1 n'est pas un manque d'AD-RC (la décision S1 → a est arrivée après, et AD-RC ne traitait que la « partie sans arbitrage » de M3). Il reste bloquant pour toute fusion vers `main` et passe par l'étape nouvelle AD-M3-PROD (K-38).
