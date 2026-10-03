# VERIF-MA-2 : Mode Accessibilité, fin de vague (MA-8 à MA-TITRE-1)

Session 90248232, 03/10/2026, lecture seule (aucun commit de code). Branche `ui/accessibilite-v1` @ `7885b35`, worktree détaché `D:\RA_TUTEUR\v-ma2`.

## Verdict : VÉRIFIÉ (un mineur, nouvelle étape MA-CORAN-TETE-1)

## Verrou

| Commande | Résultat |
|---|---|
| `flutter pub get` | OK |
| `dart analyze --fatal-infos lib test tool` | No issues found! |
| `flutter test test/accessibilite test/core/accessibilite test/features/accessibilite_recette test/features/salle_seance test/coran test/widgets/setting_row_valeur_test.dart test/router/navigation_test.dart` | +850, ~458 ignorés (captures sans CAPTURE_DIR), All tests passed! (`tests_ma2.log`) |
| `captures_ma_test.dart --plain-name 390` avec CAPTURE_DIR | +42, All tests passed! |

Aucun test sauté pour cacher un défaut : `_sautDebordement` et `_sautLibelle` sont retirés de `ma12_recette_test.dart`.

## Points de REVUE_MA-R.md

| Point | Commit | Constat |
|---|---|---|
| B1 Mon espace 200 % | 53d9ab0 | `page_shell.dart:181` `teteDefile` (> 1,3) ; test rétabli vert ; capture `marc_mon_espace_mariam_390x844_light_texte200.png` sans débordement |
| B2 libellés des interrupteurs | 1591fc8, f8cf5d7 | `MergeSemantics` dans `setting_row.dart:177` et `groupe_reglages.dart:146` ; test rétabli vert |
| M1 salle à texte agrandi | ece10c1, remplacé par MA-CMD-1 (39ebf30) | commandes en icônes avec nom lu, masquables ; décision du directeur du 02/10 (MA-CMD-1) |
| M2 zoom du Coran | 5127c99 | `coran_accessibilite.dart:135` `definirZoom(reprise.zoom)` ; test zoom 1,6 gardé après changement de page vert |
| M3 aide de Mon espace | 357878c | `onAide` branché (`mon_espace_accessibilite.dart:190`, démo l.479) |
| M4 textes du tuteur | a82196c | `guideeDescription` / `standardDescription` conformes à la correction attendue |
| Mineurs 1 à 7 | 513f923, 13a639d, e23babd, 92c5144, 4f418cb, bcb5719, 5e82b86 | présents ; « Reprendre à ta / votre dernière page » ; échec K-59 avec « reste inchangée » |

## Rendu du Coran intact

`git diff --stat 1108a4a..7885b35 -- lib/features/tc_mushaf lib/core/tc_coran lib/core/coran` : vide.

## K-61 : captures 390 × 844, texte ×2

- Salle (Mariam, Idriss) : `salle_*_390_x2_1_visibles` → `_2_masquees` (après 4 s) → `_3_rappelees` (une touche au centre ; fondu de 0,22 s). Les commandes reviennent.
- Coran (verset agrandi et Mushaf) : mêmes trois états. Masquées, la barre du bas s'efface avec elles ; le Coran occupe 83 à 86 % de l'écran ; l'attribution Tanzil tient sur deux lignes.

## Défaut mineur → nouvelle étape

- **MA-CORAN-TETE-1** : à texte ×2, l'en-tête du lecteur du Coran « Al-Faatiha . Page 1 sur 604 » passe sur deux lignes (`coran_mariam_390_x2_*_1_visibles.png`), alors que MA-CMD-1 annonce un en-tête sur une ligne. La limite des 30 % reste tenue. Remède possible : même principe que MA-TITRE-1 (le titre se réduit pour tenir sur une ligne, sans points de suspension).
