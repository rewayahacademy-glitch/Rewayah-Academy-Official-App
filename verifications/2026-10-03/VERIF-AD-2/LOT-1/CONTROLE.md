# VERIF-AD-2, LOT-1 : contrôle adverse du RAPPORT.md

03/10/2026. Contrôleur adverse, sous-agent de l'orchestratrice 00166a22. Je n'ai rien écrit au tableau et je n'ai rien commité dans le code. Worktree `D:\RA_TUTEUR\r-ad`, HEAD `a8dfcb34ab04`, vérifié au début et à la fin. `git status --porcelain` est vide en fin de travail.

## 1. Ce que j'ai relancé (tout par `flutter-verrou.ps1`)

| Commande | Résultat | Journal |
|---|---|---|
| `admin_coque_test`, `file_dossiers_test`, `ad11_criteres_test`, `revue_dossier_test` | **+53 -0** | `controle_echantillon.log`, `verrou_controle_echantillon.txt` |
| `ad6_revue_capture_test --plain-name "nominal Omar, light"` avec `CAPTURE_DIR` (PNG jetés ensuite) | **+2 -1** : 390 échoue, `Bad state: No element` ; 768 et 1440 passent | `controle_capture_ad6.log`, `verrou_controle_capture_ad6.txt` |
| Test temporaire, **hors de `lib/` et de `test/`** (`zz_controle/`, supprimé ensuite, copie `zz_controle_lot1_tmp_test.dart.txt`) : on décide le dernier dossier de la file pendant qu'un autre dossier reste au-dessus | +2 -0, mesures imprimées | `controle_focus.log`, `verrou_controle_focus.txt` |

J'ai relu moi-même toutes les références fichier:ligne citées ci-dessous. J'ai aussi ouvert `ad5_maitre_detail_1440x900@1_light.png`, `ad6_pret_1440x900@1_dark.png` (LOT-1) et `05_recette/AD/captures/AD-6/ad6_nominal_actions_390x844@3_light.png` (pilotage).

## 2. Verdicts, étape par étape

### AD-S : vérifiée. Je confirme, avec deux précisions

- Confirmé dans le code : `admin_shell.dart:112` (288), `:254-255` (info-bulle avec `excludeFromSemantics`), `:451` (`labelType: none`), `:150-157` (tiroir), `:134-144` (Recherche, thème, compte), `:123-130` (Finance inerte). `admin_domaine.dart:92-100,118-128,207-211`. `app_router.dart:1221,1382-1384`. Le test `admin_coque_test` passe dans mon échantillon.
- Précision 1 : sur le rail, `fontWeight: w600` (`:463`) porte sur un libellé qui n'est jamais affiché, puisque `labelType: none` (`:451`). À 768, l'état actif se lit donc par l'indicateur et la couleur de l'icône, pas par la graisse. Ce n'est pas un défaut (l'indicateur est une forme), mais « actif en w600 » ne vaut que pour la barre et le tiroir (`:613`).
- Précision 2 : le commentaire `main.dart:101` dit « Aucun adaptateur serveur des ports de revue n'est branché », alors que `main.dart:35` branche `surchargeRevueDossiersProduction` dans le chemin de production. Le commentaire est juste pour la démo, mais il se lit mal. C'est mineur et ça peut rejoindre AD-NETTOYAGE.

### AD-4 : vérifiée. Je confirme

- Confirmé : `port_revue_dossiers.dart:365-404` (AD-BR-01, 02, 03, 06, 07, provider par défaut indisponible), `port_politique_revue_kyc.dart:48,54` (AD-BR-16, AD-BR-17), `mode_demonstration.dart:63-66,155-168`, `main.dart:100-110`. Je compte 18 `overrideWith` dans `services_admin_demo.dart`, à `5028dac` comme à `a8dfcb3`.
- Le passage de 10 à 9 dossiers vient bien de HL-A-6 (`071d135`, son message de commit le dit). Les captures LOT-1 montrent le repère « Démonstration ».
- Réserve que le rapport signale lui-même et que je maintiens : la « revue adversariale 5 majeurs + 6 mineurs » n'est pas prouvée. Je n'ai pas non plus trouvé de document qui la porte.

### AD-5 : je conteste « vérifiée » et propose « vérifiée avec réserve »

- Confirmé : `dossiers_page.dart:20,23,26`, `:198-204`, `:175-181`, `:214-242`. `revue_dossiers_depuis_validation.dart:402`. `service_validation.dart:261`. `file_dossiers_test` passe dans mon échantillon.
- **Oubli du rapport** : la fiche revendique 7 états de file (actualisation, prolongé, indisponible, accès, hors ligne, sélection retirée, aucune sélection). Le rapport n'en dit rien.
  - Le code les porte tous : `file_dossiers.dart:51-52` (accès), `:60-61` (indisponible), `:69-72` (hors ligne), `:213` (prolongé).
  - J'en ai vérifié deux par exécution, avec `ad11_criteres_test` (vert dans `controle_echantillon.log`) : « Actualisation des dossiers… » (`ad11_criteres_test.dart:330-354`) et « sélection retirée » (`:365-371`). « Aucune sélection » est capturé (`ad5_aucune_selection_*`).
  - « Prolongé », « accès » et « hors ligne » **sur la file 02A** ne sont couverts par aucun des tests lancés par le rapport ni par moi. Le hors-ligne testé (`revue_dossier_test.dart:400`) est celui de la revue 02B, pas celui de la file.
  - Ces trois états ne sont donc pas prouvés.
- **Défaut nouveau, voir D-CTL-1** : le focus est perdu sur mobile aussi.

### AD-6 : vérifiée avec défauts. Je confirme D-AD6-1 et D-AD6-2, avec un correctif de citation et la cause de D-AD6-1

- Confirmé : quatre cartes (`revue_dossier.dart:277-311`), `_faites` vide (`:61-62`), `_allerPremiere` (`:140-157`), ordre au bureau (`:412-429`), mobile (`:394-406`). Libellés `fr.i18n.json:1231-1233`, identiques à `73f12c8:913-915`.
- **Citation fausse dans le rapport** : « remises à zéro … sur échec de lecture (`detail_dossier.dart:107-110`) ». Les lignes 107-110 construisent `RevueDossier` et ses rappels ; elles ne remettent rien à zéro. La remise à zéro sur échec n'est qu'implicite : `BlocAsynchrone` (`detail_dossier.dart:62-97`) remplace la revue par l'état d'erreur, l'état est détruit, et `_faites` repart vide à la relecture. Aucun test lancé ne l'exerce explicitement. Le fond est plausible, mais il n'est pas prouvé par la ligne citée.
- **D-AD6-1 confirmé par exécution** (`controle_capture_ad6.log` : 390 en échec, 768 et 1440 verts).
- **D-AD6-1 : le commit fautif est identifié par lecture**, ce que le rapport n'avait pas cherché. Il s'agit de `c61d66d` (HL-A-5, 27/09 03:57 +0300).
  - Son diff retire `onPress: peutValider ? … : null` et le remplace par `if (peutValider) valider` (`git show c61d66d -- lib/features/admin_dossiers/revue_dossier.dart`).
  - Le test de capture n'a plus été modifié depuis `8192bf8` (AD-6) : `git log -- test/capture/ad6_revue_capture_test.dart`.
  - Les 46 PNG du pilotage `captures/AD-6` datent du 27/09, de 02:45 à 02:46, une heure **avant** `c61d66d`.
  - Conséquence que le rapport n'a pas vue : les PNG du pilotage `ad6_nominal_actions_390x844@3_*` et `ad6_actions_390x844@3_texte200_*` montrent encore un « Valider le dossier » inactif rendu sous « Refuser » (je l'ai ouvert). Cet état n'existe plus. Ces 4 captures sont donc **obsolètes et trompeuses** comme preuve de recette.
  - Ce n'est pas une preuve par bissection exécutée.
- Ce défaut reste mineur, puisqu'il touche le test et la preuve, pas le produit.

### HL-A-1 : vérifiée avec défauts. Je confirme D-HLA1-1 et j'en élargis la portée

- Confirmé : `file_dossiers.dart:228-245` et `:321-328` ; `revue_dossiers_depuis_validation.dart:125-129,161` ; `admin_shell.dart:514-528,576-585` ; `dossiers_page.dart:106-133`. Les tests « pastille », « Pièce hors de votre portée », « 1440 à 200 % » et « la décision qui vide la file rend le focus au titre » passent dans mon échantillon. « Pièce hors de votre portée » est visible sur la ligne d'Adam (capture 1440 claire).
- D-HLA1-1 (maître-détail, file vidée) : la cause est confirmée dans le code (`dossiers_page.dart:115-116`). La mesure du rapport est cohérente (`tests_complement.log:14`).

## 3. Défauts que le rapport a manqués

**D-CTL-1 (moyen, accessibilité, nouveau) : décider le dernier dossier de la file pendant qu'il en reste d'autres perd le focus, à 390 comme à 1440.**
- Preuve : `controle_focus.log`. Omar est placé en dernier, un autre dossier reste en attente, et on valide Omar :
  - `CONTROLE 390 : omarVisible=0 aucun=0 focus=_ModalScopeState<dynamic> Focus Scope`
  - `CONTROLE 1440 : … aucun=0 focus=_ModalScopeState<dynamic> Focus Scope`
- Cause sur mobile : `dossiers_page.dart:119-131`. Quand il n'y a pas de suivant et que `avant.length > 1`, le code fait seulement `selection.retirer()`. Le focus n'est demandé ni au titre ni à une ligne, et `FileDossiers` ne pose `autofocus` que sur `d.dossierId == selection` (`file_dossiers.dart:247-248`), qui est nul ici.
- Le test « 390 : après une décision, le focus va à la ligne suivante » ne couvre que le cas où un suivant existe.
- D-HLA1-1 n'est donc qu'un cas particulier d'un défaut plus large : dès qu'il n'y a **pas de suivant**, le focus est perdu sur les deux gabarits, sauf sur mobile quand la file est entièrement vide.
- Remède : sans suivant, donner le focus à la ligne précédente, ou au titre, dans les deux branches. Il faut un test à 390 et un à 1440.
- Rattachement proposé : une seule étape, avec D-HLA1-1 (par exemple AD-FOCUS-MD élargie à « focus sans suivant »).

**D-CTL-2 (mineur, document, nouveau) : 4 captures AD-6 du pilotage sont obsolètes** (voir AD-6 ci-dessus). On peut le rattacher à AD-NETTOYAGE, en même temps que D-AD6-1, parce que corriger le test permet de régénérer ces captures.

## 4. Points que je n'ai pas pu vérifier

- La revue adversariale d'AD-4.
- Les chiffres de passage d'origine (+341, +346, +345, +85, +89).
- Les états 02A « prolongé », « accès » et « hors ligne » par exécution.
- Une bissection exécutée pour D-AD6-1 : `c61d66d` est établi par lecture du diff et par la chronologie.
- `analyze` n'a pas été relancé ; il est repris de VERIF-AD.

## 5. Verdicts proposés

| Étape | Rapport | Contrôle |
|---|---|---|
| AD-S | vérifiée | vérifiée (précisions w600 sur le rail, commentaire `main.dart:101`) |
| AD-4 | vérifiée | vérifiée (réserve sur la revue adversariale, non prouvée) |
| AD-5 | vérifiée | **vérifiée avec défauts** : 3 états de file non prouvés, et D-CTL-1 |
| AD-6 | vérifiée avec défauts | vérifiée avec défauts : citation `:107-110` fausse, D-AD6-1 imputé à `c61d66d`, D-CTL-2 |
| HL-A-1 | vérifiée avec défauts | vérifiée avec défauts : D-HLA1-1 élargi par D-CTL-1 |
