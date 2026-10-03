# VERIF-AD-2, LOT-1 : AD-S, AD-4, AD-5, AD-6, HL-A-1

03/10/2026. Sous-agent de l'orchestratrice 00166a22. Lecture seule sur le code : aucun commit de code, rien n'est écrit au tableau.

- Code : worktree détaché `D:\RA_TUTEUR\r-ad`, HEAD `a8dfcb34ab04` (= `origin/ui/admin-v1` après `git fetch`). `git status --porcelain` vide en fin de travail (les fichiers `windows/flutter/generated_*`, régénérés par flutter, ont été remis par `git checkout -- windows/`).
- Fiches lues : `yaaden-cache/tableau/etapes/{AD-S,AD-4,AD-5,AD-6,HL-A-1}.json`. Aucune de ces fiches n'est dans `tableau-frais/etapes/`.
- Rapports relus : `05_recette/AD/AD-S.md`, `AD-5.md`, `AD-6.md` ; `verifications/2026-10-03/VERIF-AD/RAPPORT.md`.
- Réutilisé de VERIF-AD : `flutter analyze` à `a8dfcb3` donne « No issues found! » (`VERIF-AD/analyze.log`). Pas relancé ici.

## 1. Mesures (toutes passées par `flutter-verrou.ps1`)

| Commande | Résultat | Journal |
|---|---|---|
| `flutter test` sur 14 fichiers : admin_coque, admin_shell, router/admin_domaine, admin_dossiers/file_dossiers, admin_dossiers/revue_dossier, demo/dossiers_demo, dossiers_admin_demo, dossiers_admin, demo/repere_demonstration, demo/mode_demonstration, capacites/ports_capacites, capacites/capacite_indisponible, core/capacites/revue_dossiers_depuis_validation, accessibilite/admin_ad11 | **+224 ~5 -0**, « All tests passed! ». Les 5 tests sautés sont tous dans `admin_ad11_test.dart` (restes AD-11, aucun ne relève de ce lot) | `tests_lot1.log`, `verrou_tests.txt` (verrou pris à 11:18:08, 152 s) |
| Captures `coque_admin_capture_test`, `ad5_dossiers_capture_test`, `ad6_revue_capture_test` avec `CAPTURE_DIR` | **+57 -4**. Coque et AD-5 tous verts. 4 échecs dans AD-6 (voir D-AD6-1). 64 PNG écrits | `captures_a8dfcb3.log`, `captures_a8dfcb3/` |
| Test temporaire de mesure du focus (hors dépôt une fois fini, copie `zz_verif_lot1_tmp_test.dart.txt`) + `test/widgets/composants_partages_test.dart` | +33 -0 | `tests_complement.log` |

Le test temporaire a été écrit dans `test/features/admin_dossiers/`, lancé, puis supprimé. Il n'a jamais été commité.

## 2. Étape par étape

### AD-S : coque admin. Verdict : vérifiée

Revendication de la fiche (à `ab1101c`) confrontée au code de `a8dfcb3` :
- Barre latérale de 288 : `lib/core/widgets/admin_shell.dart:112`. Mot « Rewayah » : `_TeteNavigation` `:258-276`. 7 entrées : `lib/core/admin/admin_domaine.dart:118-128`, Direction masquée tant que `voitDirection` est faux. Routes existantes : `:92-100`. Finance inerte (`chemin` nul, `:99`, et rien ne se passe au tap, `admin_shell.dart:123-130`). Actif en w600 : `:463` (rail) et `:613` (tiroir et barre).
- Rail de 80 en icônes seules (`labelType: none`, `:451`), avec info-bulle hors sémantique (`:254-255`). Tiroir sous 600 : `:150-157`. Seuils : `app_gabarit.dart:60,66`.
- En-tête : Recherche, thème et compte (`:134-144`). Pied utilisateur : `:283-333`. Retour vers /admin : `app_router.dart:1221` et `:1382-1384`. Onglets Personnes : `admin_domaine.dart:207-211`. La cloche n'est plus utilisée : aucun `ClocheNotifications` dans la coque, seulement en commentaire (`:628`).
- Frontière : `git diff --stat d3cb857^..ab1101c -- supabase .github vercel.json pubspec.yaml lib/core/theme` est vide.
- Tests : `admin_coque_test.dart`, 12 tests, tous verts dans `tests_lot1.log` (barre 288 entrée par entrée, rail 768, tiroir 390, thème, Mon compte jusqu'à « Se déconnecter » à 1440 et à 390, pied, Retour, Personnes, Accueil, Recherche).
- Capture réelle : `captures_a8dfcb3/coque_admin_dossiers_768x1024@1_dark.png`, ouverte. On voit le rail en icônes, l'actif lilas, l'en-tête avec Recherche, thème et compte, et le repère Démonstration. La capture du pilotage `05_recette/AD/captures/AD-S/coque_admin_dossiers_1440x900@1_light.png` et la capture de tiroir 390 sombre ont aussi été ouvertes.
- Précision, sans défaut : à 768 et à 390, les tests tapent seulement Personnes et Accueil. Toutes les entrées ne sont tapées qu'à 1440. La formule « tape chaque entrée … (1440, 768, 390) » de la fiche est donc large. Le test vérifie que « Se déconnecter » est visible, mais ne le tape pas.
- Remarque : les captures du pilotage `captures/AD-S` datent du 27/09 02:44. Elles montrent encore 10 dossiers, dont des tuteurs, ce qui est antérieur à HL-A-6 (K-47). À `a8dfcb3`, la file compte 9 dossiers, tous enseignants (capture 768 ci-dessus). La coque elle-même est inchangée.

### AD-4 : socle de démonstration. Verdict : vérifiée

- Ports neutres par défaut. `port_revue_dossiers.dart:365-404` : `RevueDossiersIndisponible` renvoie `CapaciteIndisponible` AD-BR-01, 02, 03, 06 et 07, et le provider par défaut vaut `:403-404`. `port_politique_revue_kyc.dart:43-60` : AD-BR-16 et AD-BR-17.
- `?demo=admin` : `mode_demonstration.dart:155-168`. La garde `environnementAutoriseDemo` (`:63-66`) est la même que celle du tuteur. Le branchement est dans `main.dart:100-109`.
- 18 services admin neutralisés : `services_admin_demo.dart:130-151`. J'ai compté 18 `overrideWithValue`, aussi bien à `5028dac` qu'à `a8dfcb3`.
- Jeu synthétique : à `5028dac`, 10 dossiers `DEMO-D01` à `D10`, dont `tuteurDocumentaire` (D02) et `familleDispensee` (D03), relevés par `git show 5028dac:lib/features/demo/dossiers_demo.dart`. La revendication est donc exacte à son commit. À `a8dfcb3`, il reste 9 dossiers, tous enseignants (`dossiers_demo.dart:196-206`, commentaire K-47 `:197-198`). Le retrait est fait par HL-A-6 (`071d135`), sur décision K-47. Ce n'est pas un défaut d'AD-4. Les autres cas sont présents : pièce absente, conflit, réponse perdue, lien expiré, politique de genre (`horsPorteeSiPolitique`, `:57,93-97`), Super Admin simulé (`:110-145`, `:648-670`).
- Pilotage `b92ad51` (`11_admin/AD-BR.md`) : il existe et c'est un ancêtre d'`origin/pilotage/tuteur-v1`. Commits `b2d53fe` et `5028dac` : ancêtres de `a8dfcb3`. Frontière `b2d53fe^..5028dac` : vide.
- Tests verts : `dossiers_demo_test`, `mode_demonstration_test`, `repere_demonstration_test`, `ports_capacites_test`, `capacite_indisponible_test`, `dossiers_admin_demo_test`.
- Écran porté : le repère « Démonstration » est visible sur toutes les captures ouvertes.
- Non revérifié : « revue adversariale 5 majeurs + 6 mineurs corrigés » (aucun document de revue AD-4 trouvé hors de la fiche), ainsi que les chiffres de passage d'origine (+346).

### AD-5 : file ADM-02A. Verdict : vérifiée

- Maître-détail 336/24/728 : `dossiers_page.dart:20,23,26`. Bascule à 1088 de largeur utile, et jamais à 200 % : `:198-204`. Repli séquentiel avec `PopScope` : `:175-181`, `:214-242`.
- Adaptateur de production : `surchargeRevueDossiersProduction` (`revue_dossiers_depuis_validation.dart:402`), branché dans `main.dart:35`.
- Correctif Riverpod : `retry: null` dans `service_validation.dart:261` (commentaire `:248`). Le même réglage existe sur la revue, `etat_file_dossiers.dart:135`.
- Tests verts dans `tests_lot1.log` : « 1440 : Personnes, maître-détail 336/24/728 » (positions x=320 et x=680, largeurs 336 et 728), « repli séquentiel » à 768, à 1200 et à 1440 en 200 %, décisions et focus à 390, coches remises à zéro.
- Commits `c7c6555`, `7694c84`, `15c306b`, `e636017` : ancêtres de `a8dfcb3`. Frontière : vide.
- Captures réelles : `ad5_maitre_detail_1440x900@1_light.png` (file 336, détail, 9 dossiers, « Pièce hors de votre portée » sur la ligne d'Adam) et `ad5_squelette_1440x900@1_light.png` (squelette et « Chargement des dossiers… »), ouvertes. Les 14 PNG AD-5 sont produits sans échec.

### AD-6 : revue ADM-02B. Verdict : vérifiée avec défauts

- Quatre cartes. Identité : `revue_dossier.dart:277`. Pièce : `:279-283`. Vérifications : `:285-301`. Accords, si au moins un est accepté : `:302-311`.
- Cases jamais précochées : `_faites` est vide à chaque création d'état (`:61-62`). Remise à zéro par la clé `id#revision` (`detail_dossier.dart:106`) et sur échec de lecture (`:107-110`). Lien vers la première case manquante : `_allerPremiere`, `:140-157`.
- Libellés des vérifications : `fr.i18n.json:1231-1233`, identiques mot pour mot à ceux qu'AD-1 cite (`git show 73f12c8:assets/i18n/fr.i18n.json`, lignes 913-915).
- Ordre au bureau : Refuser (destructif) puis Valider, au bord de fin, en largeur naturelle (`:412-429`). Sur mobile, les deux boutons sont en pleine largeur, Valider puis Refuser (`:394-406`). Ce changement vient de HL-A-5 (`c61d66d`, style de référence) et n'est pas un défaut d'AD-6.
- Aucune `Image.network` ni URL signée dans `lib/features/admin_dossiers/` (grep vide).
- Huit états, couverts par le test de capture : chargement, hors ligne, accès perdu, vérifications incomplètes, accord manquant, décision indisponible, dossier modifié, refus non autorisé. Les 8 sont verts à 390 et à 1440, dans les deux thèmes (`captures_a8dfcb3.log`).
- Captures réelles ouvertes : `ad6_pret_1440x900@1_dark.png` (3 cases cochées, Refuser puis Valider au bord de fin) et `ad6_verifications_incompletes_390x844@3_light.png` (« Terminez les vérifications requises. », aucun Valider rendu, Refuser seul).
- Commits `cdc55b0`, `b76d370`, `8192bf8` : ancêtres de `a8dfcb3`. Frontière : vide.

**D-AD6-1 (nouveau, mineur) : le test de capture AD-6 ne passe plus à `a8dfcb3` (4 échecs sur 61).** Les cas « 390 nominal Omar » (clair et sombre) et « 390, actions à 200 % » (clair et sombre) échouent avec `Bad state: No element` (`ad6_revue_capture_test.dart:167` et `:337`). Le test cherche `find.text('Valider le dossier')` sur Omar, dont les vérifications sont incomplètes. Or, depuis le style de référence HL-A-5, un bouton qui ne peut pas être pressé n'est plus rendu (`revue_dossier.dart:369-372`, `:399`). La capture `ad6_verifications_incompletes_390…` le montre. Les PNG `ad6_nominal_actions_*` et `ad6_actions_390x844@3_texte200_*` ne peuvent donc plus être régénérés. La suite complète ne le voit pas, parce que ces tests sont sautés sans `CAPTURE_DIR`. Aucune trace de ce défaut au pilotage : grep « ad6_revue_capture » sur `*.md`, seul `13_fusion/PLAN_FUSION_ADMIN_ENSEIGNANT.md:212` le cite, comme test à rejouer. Je n'ai pas cherché par bissection le commit exact qui l'a cassé. Remède proposé : viser « Refuser le dossier », ou la ligne d'état, au lieu de « Valider ».

**D-AD6-2 (nouveau, mineur, document) : la fiche contredit le rapport sur l'échec préexistant.** La fiche dit « composants partagés +177 (1 échec préexistant corrigé) ». `05_recette/AD/AD-6.md` dit « +177 -1 » et range cet échec dans les restes (reste 2 : « déjà rouge avant AD-6 … Il faut décider »). Le test « une rubrique sans icône ni meneur » n'a été réécrit qu'en AD-7 (`d932248`, blame `composants_partages_test.dart:391-394`). À `a8dfcb3`, il passe (`tests_complement.log`, +33 -0). L'état actuel est sain, mais le texte de la fiche est inexact pour AD-6.

### HL-A-1 : restes d'AD-5 et d'AD-S. Verdict : vérifiée avec défauts

- Squelette capturé à 390 et à 1440, dans les deux thèmes : 4 PNG `ad5_squelette_*`, régénérés au vert ici. Celui de 1440 en clair a été ouvert.
- Pastille au même endroit sur toute la file : `file_dossiers.dart:228-243` et `pastilleSousLeNom` `:334-376`. Test « pastille au même endroit » vert à 390 et à 1440.
- « Pièce hors de votre portée » sur la ligne : `file_dossiers.dart:321-324`. Le port porte `etatPiece` ; l'adaptateur de production le lit sans appel nouveau (`revue_dossiers_depuis_validation.dart:125-128,161`). Test à 390 vert. Visible sur les captures 768 et 1440.
- Barre latérale sans débordement à 200 % : `admin_shell.dart:514-528,576-585`. Test « 1440 à 200 % : Personnes tapé dans la barre latérale » vert, avec `takeException` nul.
- Focus au titre quand la file se vide : `dossiers_page.dart:117-131`. Test à 390 vert. Mon test temporaire donne `MESURE 390 : focus=adm02a-titre`.
- Commit `0d5bda5` : ancêtre de `a8dfcb3`. Frontière : vide. « Captures AD-5 (14) et AD-S (8) refaites » : 14 et 8 PNG dans le pilotage, datés du 27/09 02:44-02:45 (refaits en AD-11 après HL-A-1).

**D-HLA1-1 (nouveau, moyen, accessibilité) : en maître-détail, quand la dernière décision vide la file, le focus est perdu.** Mesure dans `tests_complement.log` : `MESURE 1440 : aucun=1 focus=_ModalScopeState<dynamic> Focus Scope`. Le focus retombe donc sur la portée de la route : aucun élément n'est focalisé. À 390, il va bien au titre. Cause dans le code : `_apresDecision` ne demande le focus du titre que dans la branche du panneau unique (`dossiers_page.dart:117-131`). La branche maître-détail sans suivant fait seulement `selection.retirer()` (`:115-116`), et la revue n'y reprend pas la main (`revue_dossier.dart:178-180`, `_decide`). Le reste 4 d'AD-5 parlait du mobile, mais le titre de la fiche HL-A-1 ne le limite pas. Au clavier, au bureau, le parcours reprend au début de la page. Remède proposé : dans la branche `maitreDetail` sans suivant, focus sur `_focusTitre` comme sur mobile, avec un test à 1440.

## 3. Rattachements à des étapes déjà au tableau

- AD-M3-PROD : sans effet sur ce lot. Le refus, toujours ouvert en production, n'est pas une revendication d'AD-6.
- AD-M4-DEFIL et HU-1 (jetons à la main, dont `FontWeight.w600` à `admin_shell.dart:463,613` et `file_dossiers.dart:361`) : déjà portés. Je ne les compte pas ici.
- En 02B à 390, le titre « Pièce d'identité » passe sous les onglets fixes au cadrage (capture `ad6_verifications_incompletes_390…`). C'est déjà relevé par VERIF-AD §3 ; je ne le compte pas.

## 4. Questions pour le directeur

1. D-AD6-1 et D-HLA1-1 : faut-il les ranger dans AD-NETTOYAGE, ou ouvrir une étape à part (proposition : AD-FOCUS-MD pour D-HLA1-1) ?
2. D-AD6-2 : faut-il corriger le texte de la fiche AD-6 (« échec préexistant laissé rouge, corrigé en AD-7 d932248 ») ?
