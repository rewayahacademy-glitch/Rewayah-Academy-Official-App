# VERIF-AD-2 / LOT-3 : AD-9, AD-10, HL-A-5, HL-A-6, AD-11, AD-R

03/10/2026, agent de vérification lancé par l'orchestratrice 00166a22. Lecture seule sur le code : aucun commit de code.

- Code : worktree détaché `D:\RA_TUTEUR\r-ad`, HEAD = `a8dfcb34ab0403b0debf8658645e3f7c3c444144`, vérifié au début et à la fin.
- Fiches : `yaaden-cache/tableau/etapes/<ID>.json`. `tableau-frais` n'a aucune des six fiches.
- Tous les commits cités par les fiches sont ancêtres de `a8dfcb3` (`merge-base --is-ancestor` = 0) : 15c6cd7, c691a34, 045a035, ff1a933, 1be1150, c61d66d, 80eae2e, b2ecef2, 906d1a3, 797701d, 071d135, 2fac423, f73dd41, 3dd89f4. Pilotage `c3b6d57` (AD-R) est ancêtre de `origin/pilotage/tuteur-v1`.

## Mesures (via flutter-verrou.ps1)

| Passage | Résultat | Journal |
|---|---|---|
| politique_revue_kyc, parcours_ad10, ad11_criteres, decisions_coque, attente, redirection, navigation, tableau_de_bord, dossiers_sans_piece, admin_ad11, comptes, page_shell_etat | verrou acquis 11:38:28, 200 s, code 0 : **« 02:49 +394 ~5: All tests passed! »**. Les 5 sautés sont les cas `_restes` d'admin_ad11 (politique, 4 entrées). | `tests_lot3.log`, `verrou_tests.txt` |
| Captures réelles `CAPTURE_DIR` : `ad9_politique_capture_test` (« indisponible ») et `hl_a5_planche_capture_test` (téléphone et ordinateur, clair : chaîne principale, portail après refus, tuteur attente ouverture) | verrou acquis 11:46:41, 34 s, code 0 : « +12: All tests passed! », 26 PNG | `captures_a8dfcb3.log`, `captures_a8dfcb3/`, `comparaison_hash.txt` |

Tests de capture copiés, non modifiés : `ad9_politique_capture_test.dart.txt`, `hl_a5_planche_capture_test.dart.txt`. Aucun fichier temporaire créé dans le dépôt de code.

Réutilisé de VERIF-AD (même commit) : `analyze` 0 (`VERIF-AD/analyze.log`) et les tests ciblés 164/0, qui couvrent aussi `admin_dossiers` et `admin_configuration`. La suite complète n'est pas rejouée.

Comparaison de mes captures avec `05_recette/AD/captures` : 14 identiques au pixel. Trois écrans diffèrent par la seule graisse ou bordure d'`ActionPrincipale` (fusion CL-4 `739f478`, déjà décrit par VERIF-AD §3) : validation, portail après refus, visionneuse. J'ai ouvert les deux versions de chacun. `ad9_14` diffère vraiment : voir D-AD9-1.

## AD-9 : verifie_avec_defauts

Ce qui tient :
- Port par défaut `PolitiqueRevueKycIndisponible` : `lib/core/capacites/port_politique_revue_kyc.dart:43-61`. `lire()` et `modifier()` lèvent `CapaciteIndisponible` (AD-BR-16 et 17) sans réseau.
- Onglet ajouté seulement si `peutModifier` : `:74-78` et `admin_domaine.dart:186-199`.
- Bascule sans optimisme, relecture dans `finally` : `politique_revue_kyc_page.dart:44-95`. Refus si pas Super Admin : `:99-113`.
- G1 à G13 verts (`tests_lot3.log`). G2/G3 va jusqu'à `nombreDecisions == 1` (`politique_revue_kyc_test.dart:196-245`). G13 monte la vraie coque sans surcharge de démonstration : `:393-447`.

**D-AD9-1 (nouveau, mineur).** Sur la route en production, la page affiche l'onglet réservé.
- Depuis HL-A-5 (`c61d66d`, « en-tête gardé au chargement et en erreur »), l'état « Pas encore disponible » passe par `avecEntete`. Cet en-tête porte le titre « Politique de genre pour la revue KYC » et `ongletsConfiguration(politiqueRevueKyc: true)` : `politique_revue_kyc_page.dart:154-167`.
- En production, tout administrateur qui tape l'adresse voit donc un 4e onglet. La fiche dit pourtant « 4e onglet seulement avec la capacité Super Admin », et le commentaire de la page dit « on ne montre pas l'onglet réservé à qui n'y a pas droit » (`:152-153`).
- Capture réelle à `a8dfcb3` : `captures_a8dfcb3/ad9_14_indisponible_1440x900@1_light.png` et `_390x844@3_light.png`, ouvertes : titre et 4 onglets. La capture de recette `05_recette/AD/captures/AD-9/ad9_14_indisponible_1440x900@1_light.png` (045a035, ouverte) n'a ni titre ni onglet. Elle est donc périmée.
- G12 et G13 ne contrôlent l'absence d'onglet que sur la page Configuration, pas sur la route (`:386`, `:440`).
- Aucune donnée n'est exposée : le défaut tient à la règle d'affichage. Étape proposée : **AD-9-ONGLET-PROD**. En production, rendre l'état « indisponible » sans en-tête d'onglets (comme l'accès refusé), ajouter un test sur la route et refaire `ad9_14`. On peut la rattacher à AD-M3-PROD (même chemin de production).

## AD-10 : verifie (deux points remplacés par K-47, traçables)

- P-ADM-09 : refus avec motif sur /attente, phrase `refuseDetail` qui suit le premier élément (`attente_page.dart:303-330`). « Corriger » mène au premier élément manquant (`:198-205`). T5 (refus, correction, retour en file en révision nouvelle, cases vides), T6 (`refuse-fige`, sans Corriger) et la double resoumission sont verts.
- P-ADM-11 : relecture au retour par `AppLifecycleListener` (`attente_page.dart:46-55`, `_relire` `:65-68`), bouton Actualiser (`:145-159`). T8 et sa variante Actualiser sont verts.
- Pièce absente : la raison est dite une fois et Valider est absent (T2 vert, `revue_dossier.dart:288-290`, `:660-663`). Aucune promesse d'audit : T3/T4 verts.
- **Remplacés par K-47 (HL-A-6, `071d135`)**, vrais à `1be1150` et retirés volontairement ensuite :
  - « famille dispensée validable, Aucune pièce requise pour ce dossier » : à `1be1150`, `ExigencePiece { requise, dispensee }` (`port_revue_dossiers.dart:19`) et la clé `pieceNonRequise` (`fr.i18n.json:950`). À `a8dfcb3`, `enum ExigencePiece { requise }` (`:22`) et la clé n'existe plus.
  - « retour après validation vers /tuteur » : `parcours_ad10_test.dart` attendait `Routes.tuteurAccueil` à `1be1150` (l.296, 316, 408). Il attend `'/enseignant'` à `a8dfcb3` (l.273, 292).
  - La fiche AD-10 ne le dit pas. C'est une annotation de fiche, pas un défaut de code.
- Défauts déjà connus, encore présents (non comptés) : m7 (Actualiser centré, `attente_page.dart:149-158` sans `_AuContenu`), m6, m8, m11 → AD-NETTOYAGE.

## HL-A-5 : verifie_avec_defauts

Ce qui tient dans le code :
- 02B : un seul emplacement de décision. Une ligne d'état remplace les boutons grisés (`revue_dossier.dart:611-683`).
- Politique KYC : colonne bornée à `AppPage.largeurReglages = 760` (`app_spacing.dart:76`, `politique_revue_kyc_page.dart:122-127`).
- /attente : action placée 16 sous la carte (`Ecart.vLg`), au bord de fin (`attente_page.dart:126-143`). Le pied ne garde que Se déconnecter (`:106-110`).
- Les 4 commits sont ancêtres.

Captures :
- `05_recette/AD/captures/HL-A-5` compte 102 fichiers, soit 17 groupes × 6. Il inclut les anciens `retour_apres_validation_*` (périmés, comme le dit HL-A-5.md l.30-31) et les 12 PNG tuteur de HL-A-6.
- Ouvertes : `verifications_incompletes_ordinateur_clair` (recette), `portail_apres_refus_ordinateur_clair` et `visionneuse_ordinateur_clair` (recette et réel).

**D-HL5-1 (nouveau, mineur) : « Fiche du dossier » et « Vérifications incomplètes » sont la même image.**
- Les 6 paires `fiche_dossier_*` / `verifications_incompletes_*` sont identiques octet pour octet dans `05_recette/AD/captures/HL-A-5`. Exemples : ordinateur clair 20E6C53F9A7CD747 = 20E6C53F9A7CD747, téléphone sombre F02E1FBC… = F02E1FBC…
- C'est aussi le cas dans la planche publiée P1VXFZvw6ioS9cFerhgPAm : mêmes tailles d'octets pour les 6 paires.
- Je l'ai reproduit à `a8dfcb3` : `captures_a8dfcb3/fiche_dossier_*_clair.png` = `verifications_incompletes_*_clair.png`.
- Cause : `hl_a5_planche_capture_test.dart:205-219`. Le test touche le lien « Terminez les vérifications requises. » après avoir déjà défilé jusqu'à l'emplacement de décision, rien ne bouge à l'écran, et aucune assertion ne vérifie un changement.
- Conséquence : la planche montre au directeur « 15 écrans » dont 14 distincts. Le point « Le lien mène directement à la case à cocher » de l'écran 3 n'est pas montré.
- Étape proposée : **AD-PLANCHE-DOUBLON**. Capturer l'écran 2 avant le défilement, ou l'écran 3 après un effet visible du lien (focus ou défilement vers la première case). Ajouter une assertion de différence, puis republier la planche. Elle peut rejoindre AD-M2-PLANCHE.

## HL-A-6 : verifie

- Pièce exigée de l'enseignant seulement : `etat_dossier.dart:125` (`pieceExigee => pieceRequise && role == AppRole.teacher`). L'état tuteur `accesEnPreparation` est défini `:101-111`.
- /attente/piece est fermé au tuteur : `redirection.dart:127-133`.
- Écran honnête : `fr.i18n.json:493-497`. Rendu `attente_page.dart:294-302`.
- Capture réelle `captures_a8dfcb3/tuteur_attente_ouverture_ordinateur_clair.png` (ouverte) : « Votre compte est créé », aucun document à envoyer, Actualiser, Se déconnecter. Identique au pixel à la recette.
- File ADM-02 enseignants seulement : `revue_dossiers_depuis_validation.dart:94-104`. Lignes « À traiter » de l'Accueil : `tableau_de_bord_page.dart:139`. T1 « enseignants seulement, aucun tuteur » vert.
- Famille dispensée et type Tuteur retirés : `ExigencePiece { requise }` seul. `git grep` de « Aucune pièce requise » et de `pieceNonRequise` ne trouve rien à `a8dfcb3`.
- Chiffres : 2973/892 lus dans `05_recette/AD/suite_complete_hl_a6.log` (« 14:43 +2973 ~892: All tests passed! »).
- Planche : 16 écrans × 6 présents dans `captures/HL-A-5`.
- Réserves connues, non comptées : n5 (repère Démonstration sur l'écran 16), m5, m6, m7, m8, m1 (BR-1.c).

## AD-11 : verifie_avec_defauts

Ce qui tient :
- `_restes` contient exactement les 4 cas d'onglet de la politique (`admin_ad11_test.dart:85-90`). On en tire les 5 sautés (`tests_lot3.log` ~5).
- `ad11_7_politique_320x640@1_dark.png` (ouverte) montre l'onglet entier avec les vraies polices.
- Critères prouvés : la tuile compteur, les états 02A et la purge (`ad11_criteres_test.dart:282-615`), la garde pour chaque rôle (`redirection_test.dart:233`). Tous verts.
- `f73dd41` est ancêtre. Les 32 captures AD-11 sont présentes.
- La planche P1VXFZvw6ioS9cFerhgPAm a 91 fichiers : 15 écrans × 6 + index, au format CL-4 (bascules, 3 points par écran, cas particuliers en bas).

Défauts :
- D-HL5-1 s'applique à la planche AD-11 : les écrans 2 et 3 sont identiques.
- **D-AD11-1 (nouveau, mineur, document) : `05_recette/AD/RAPPORT.md` se contredit.**
  - Le §4 (l.80) dit que la garde est vérifiée pour chaque rôle et que la tuile compteur mène à la bonne route.
  - La matrice du §7 garde « non prouvé » pour « Compteur Accueil → même route » (l.112), « Enseignant sans habilitation » (l.113) et « Contrôleur/comptable » (l.116). Les tests existent pourtant et sont verts (`redirection_test.dart:233`, `ad11_criteres_test.dart:282`).
  - Le rapport annonce aussi encore `f73dd41` et +2967 ~844 (l.40, l.50). Il n'a pas été mis à jour après HL-A-5 et HL-A-6, alors que la fiche cite 2fac423 et +2973 ~892.
  - Correction du document à faire, à verser dans AD-NETTOYAGE.

## AD-R : verifie_avec_defauts

Ce qui tient :
- `c3b6d57` ajoute `05_recette/AD/REVUE_AD-R.md`.
- Les 4 points au directeur sont M3, m4, m5 et n4 (l.135-142).
- 5 majeurs : confrontés au code par VERIF-AD et CONTROLE (M1 à M5 réels à 2fac423, corrigés ensuite par AD-RC). Je réutilise ces preuves.
- Mineurs et notes, échantillon rejoué par `git show 2fac423:<fichier>` : M1 (`service_comptes.dart:148`), m1 (`tableau_de_bord_page.dart:277`), m3 (`redirection.dart:117-120`), m4 (`donnees_compte.dart:106`), m10 (`fr.i18n.json:1031-1032`), m13 (`env.dart:97-100`), m16 (`groupe_reglages.dart:163-169`), m17 (les 4 clés ne sont lues nulle part, à 2fac423 comme à a8dfcb3), n4 (`fr.i18n.json:1329-1330`). Tous exacts.
- « Suite complète refaite sur 2fac423 : 2973 réussis, 0 échec » : le journal propre d'AD-R (`C:\RA\admin-revue\build\suite_adr.txt`) n'existe plus (`C:\RA` est absent). Je ne peux donc pas le revérifier. Le chiffre est corroboré par `suite_complete_hl_a6.log` sur le même commit (2973/892/0), qui est le journal d'une autre session.

**D-ADR-1 (nouveau, mineur, document) : les comptes de constats sont faux.**
- REVUE_AD-R.md contient m1 à m17, soit **17 mineurs**, et n1 à n13, soit **13 notes** (tableaux l.97-115 et l.119-133).
- Le bilan (l.56), le titre du commit `c3b6d57` et la fiche AD-R disent pourtant « 16 mineurs, 14 notes ». Le total de 35 est juste.
- À corriger dans la fiche et dans le document, à verser dans AD-NETTOYAGE.

## Fin de travail

- `git -C D:\RA_TUTEUR\r-ad status --porcelain` : seul `?? zz_controle/` (`zz_controle_lot1_tmp_test.dart`, 11:45:48) apparaît. Il appartient au LOT-1, je n'y ai pas touché. Aucun fichier suivi n'est modifié, `windows/` n'a pas été régénéré (passages en `--no-pub`).
- HEAD est toujours `a8dfcb3`.
