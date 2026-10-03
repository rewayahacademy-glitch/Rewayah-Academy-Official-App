# VERIF-AD : contrôle adverse

03/10/2026, session 00166a22 (contrôleur adverse, ni A-2026-09-26-service, ni A-27/09-adrc, ni l'auteur de VERIF-AD). Aucun code modifié.

**Verdict : rapport NON confirmé.** Les mesures tiennent (commits, tests, captures, jetons). En revanche, deux majeurs sont dits « CORRIGÉS » alors qu'une partie de ce que REVUE_AD-R leur demandait reste ouverte, et AD-RC est proposée à « vérifié » sans défaut.

## 1. Ce qui tient (revérifié)

- `git ls-remote origin ui/admin-v1` = `a8dfcb34…` ; `c1d33d8`, `f242c06`, `739f478`, `d44710a`, `2fac423` sont ancêtres de `a8dfcb3` (merge-base = 0). `739f478` a pour parents `2fac4236 d44710ae`.
- Pilotage `dc4d2fdd` est ancêtre de `origin/pilotage/tuteur-v1` ; ses 15 fichiers sont présents.
- `dcd85ce`, `23d39a5`, `746fb94` ne sont que sur `adrc/m1`, `adrc/m3`, `adrc/m4`. `a73ace1` n'est pas ancêtre du pilotage poussé (code 1), `d5fdd94` l'est (D3 du rapport exact).
- Code à `a8dfcb3` : `service_comptes.dart:152-153`, `comptes_page.dart:278-280`, `revue_dossiers_depuis_validation.dart:192` (`peutRefuser = d.documentId != null`), `:317-318` (AD-BR-02), `:322` (AD-BR-06), `page_shell.dart:291-327` (`_Bascule`, deux `GlobalKey`, `KeyedSubtree`), `app_icons.dart:374` (`moins`). Sur `origin/corrections/revue-directeur-2026-10` (`7c61287`), le même fichier a toujours `peutRefuser = d.documentId != null` (l.192) et l'aperçu (l.184, 242) : D1 confirmé.
- Planche P1VXFZvw6ioS9cFerhgPAm relue (91 fichiers) ; les 3 images téléchargées par moi ont les mêmes SHA-256 que `planche/img/` (04533500…, F02E1FBC…, B9CFADA0…). Les deux captures 02E ouvertes : seule la graisse de « Valider le dossier » diffère.
- `planche.json` : 84 chemins PNG, 0 manquant (Test-Path rejoué).
- Jetons : mon grep indépendant (mêmes fichiers) redonne exactement les 11 lignes de `jetons_a_la_main.txt`. Sur les 49 fichiers `lib/` changés depuis `d44710a`, les seuls ajouts sont des épaisseurs de filet dans `action_principale.dart` et `entete_page.dart`, absentes du diff `d44710a..a8dfcb3` (préexistantes).

## 2. Tests relancés (verrou, worktree `D:\RA_TUTEUR\r-ad` @ `a8dfcb3`)

| Passage | Résultat | Journal |
|---|---|---|
| `revue_dossiers_depuis_validation_test`, `comptes_test`, `page_shell_etat_test`, `test/features/admin_configuration`, `dossiers_admin_test` | verrou acquis 09:39:52, 61 s, code 0 : « 00:33 +47: All tests passed! » | `controle_tests.log` |
| Contrôle M5 que VERIF-AD n'a pas fait (REVUE_AD-R l.92 : « rejouer les tests des composants partagés, CL-4 ») : `composants_partages_test`, `repere_demonstration_test`, `accessibilite/admin_ad11_test`, `fiche_groupe_test`, `test/core/tc_horloge`, `teaching_core/a/routes_tc_a_test` | verrou acquis 09:40:53, code 0 : « 01:16 +136 ~5: All tests passed! » (les 5 ignorés sont dans `admin_ad11_test`) | `controle_m5.log` |

Après ces passages, seuls `windows/flutter/generated_*` étaient modifiés dans `r-ad` ; restaurés par `git checkout`, `git status --porcelain` vide.
EN-3 et EN-12 (aussi cités l.92) relèvent de la partie enseignant de M5, hors AD-RC : non lancés.

## 3. Écarts trouvés

### E1 (moyen) : M2 dit « CORRIGÉ », mais la planche montre toujours les écrans /attente d'AD-10

REVUE_AD-R l.69 range dans M2 : « Les écrans /attente restés dans la planche sont ceux d'AD-10 (`ad10_4_attente_refus`, `ad10_8_retour_valide`), donc d'avant K-42 et d'avant K-47 », et l.71 demande de « régénérer `planche.json` à partir de `captures/HL-A-5` ».
À `d5fdd94`, `planche.json` pointe encore `AD-10\ad10_4_attente_refus_*` (écran `attente_refuse`) et `AD-10\ad10_8_retour_valide_*` (écran `retour_apres_validation`). Pourtant, `captures/HL-A-5/portail_apres_refus_*` et `retour_apres_validation_{telephone,tablette,ordinateur}_{clair,sombre}.png` existent (6 + 6 fichiers). AD-RC.md l.36 le reconnaît comme mineur restant.
VERIF-AD n'a contrôlé que la présence des fichiers (Test-Path), pas qu'ils soient à jour. M2 n'est corrigé qu'en partie.

### E2 (moyen) : M4 dit « CORRIGÉ », mais la position de défilement est encore perdue et le test n'utilise pas une vraie page

REVUE_AD-R l.83 : la bascule fait perdre « le focus, la saisie en cours et la position de défilement ». La correction attendue (l.85) est un test sur « un `TextField` saisi dans une page d'un autre rôle ».
AD-RC.md l.34 : « une page défilante repart encore du haut quand la structure change […] Le test doit aussi être fait sur une vraie page d'un autre rôle ».
`test/widgets/page_shell_etat_test.dart:22` monte un `PageShell` synthétique (aucune page de rôle importée, l.1-7). Le troisième test ne couvre qu'un « corps non défilant ».
La contre-épreuve 0/3 puis 3/3 est exacte, mais elle prouve la partie saisie et focus, pas tout M4 (leçons 7 et 13).

### E3 (moyen) : la liste des étapes AD-* couvertes est trop étroite et n'est pas justifiée face à l'énoncé

L'énoncé demande les tests `admin_dossiers`, `admin_configuration`, `admin_coque_test`, `dossiers_*` et les écrans 02A, 02B, 02E. Il exclut aussi la session A-2026-09-26-service, autrice d'AD-S, AD-4 à AD-11, qui ne sont qu'au statut « fait ».
Le rapport écarte toutes ces étapes (« non couvertes, énoncé limité à M1-M5 », RAPPORT.md l.101), sans dire, étape par étape, ce qui manquerait pour les vérifier. Ses propres preuves en couvrent pourtant une partie :
- 02A et `file_dossiers_test` pour AD-5 ;
- 02B et `revue_dossier_test` pour AD-6 ;
- 02E et `decisions_coque_test` pour AD-8 ;
- `admin_coque_test` pour AD-S ;
- `politique_revue_kyc_test` pour AD-9.

Pour AD-8, le défaut D1 (refus resté ouvert après S1 → a) aurait dû être rattaché explicitement. La ligne mélange aussi « AD-4 à AD-11, AD-5 ».
C'est à l'orchestratrice de trancher. En l'état, l'énoncé (« liste exacte ») n'est pas rempli de façon vérifiable.

### E4 (mineur) : le grep « aucune étape ne porte la décision » est incomplet

`yaaden-cache/tableau/depots/C-decisions-directeur-2026-09-27.json` (consigne, statut « nouveau ») cite aussi `A-q-20260927-c6379fd5`. La conclusion ne change pas : aucune étape ne porte S1 → a.

## 4. Étapes nouvelles proposées (K-38, rien rouvert)

- **AD-M2-PLANCHE** : remplacer, dans `planche.json`, les écrans `attente_refuse` et `retour_apres_validation` par les captures HL-A-5 (`portail_apres_refus_*`, `retour_apres_validation_*`), puis republier la planche.
- **AD-M4-DEFIL** : conserver la position de défilement d'un corps défilant à la bascule de `PageShell`. Ajouter un test sur une vraie page d'un autre rôle (saisie, focus et défilement, de 800 à 300 puis 800 de haut, et texte à 200 %).
- Garder AD-M3-PROD (D1) comme le propose VERIF-AD, et la rattacher aussi à AD-8.

## 5. Conséquence pour le tableau

- AD-RC ne peut pas passer à « vérifié » sans défaut : M2 et M4, revendiqués en entier par son titre, ne sont corrigés qu'en partie (E1, E2).
- Les autres constats de VERIF-AD (M1, M3 partie sans arbitrage, M5 partie CL-4, D1, D3, jetons, captures) sont confirmés.
