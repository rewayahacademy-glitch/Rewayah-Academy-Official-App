# VERIF-AD-2, LOT-3 : contrôle adverse

Date : 03/10/2026. Objet : rapport LOT-3 (AD-9, AD-10, HL-A-5, HL-A-6, AD-11, AD-R) sur `ui/admin-v1` @ `a8dfcb3`.
Worktree `D:\RA_TUTEUR\r-ad` : HEAD = `a8dfcb34ab0403b0debf8658645e3f7c3c444144`, vérifié avant et après. Rien n'a été écrit au tableau.

## Conclusion

Le rapport est confirmé pour l'essentiel. Toutes les références fichier:ligne que j'ai rejouées sont exactes, les commits cités sont ancêtres de `a8dfcb3`, et les quatre défauts relevés sont réels. Je conteste un verdict (AD-10). J'ajoute quatre écarts que le rapport n'a pas vus ou qu'il a sous-estimés, plus une affirmation inexacte sur `windows/`.

## Tests relancés par le verrou

`controle_verrou_tests.txt` : verrou acquis à 11:55:23, 152 s, code 0.
`controle_tests.log` : 5 fichiers (politique_revue_kyc, parcours_ad10, admin_ad11, attente, dossiers_sans_piece) donnent `+116 ~5: All tests passed!`. Les 5 sautés sont bien les entrées `AD-9_politique` de `_restes` (admin_ad11_test.dart:85-90) : 320x640, 1280x1024_400pc, 390x844_200pc, 1440x900_200pc (même entrée) et Tab 320x640.

Ce passage en `--no-pub` a régénéré `windows/flutter/generated_plugin_registrant.cc`, `.h` et `generated_plugins.cmake`. Je les ai remis par `git checkout -- windows/`. `git status --porcelain` est maintenant vide, et `zz_controle/` du LOT-1 n'y figure plus.

## Contrôle étape par étape

| Étape | Rapport | Contrôle | Preuve rejouée |
|---|---|---|---|
| AD-9 | vérifié avec défauts | **confirmé** | port_politique_revue_kyc.dart:43-61 et :74-78 exacts. politique_revue_kyc_page.dart:44-95 : la bascule est sans optimisme et `finally` relit la valeur. :154-167 : l'état « indisponible » passe par `avecEntete` avec `ongletsConfiguration(politiqueRevueKyc: true)`. Capture `ad9_14_indisponible_1440x900@1_light.png` ouverte : le 4e onglet « Politique de genre pour la revue KYC » est visible et sélectionné. À 045a035, `CapaciteIndisponible` rendait un `EtatSysteme` sans `avecEntete` : la régression vient bien de c61d66d. G13 (test:436-446) ne vérifie l'absence du titre que sur la page Configuration ; sur la route, il ne contrôle que l'état indisponible. |
| AD-10 | vérifié | **contesté → vérifié avec défauts** (voir plus bas) | attente_page.dart:46-55, :145-159, :198-205 et :303-330 exacts. Ancêtres ff1a933 et 1be1150 confirmés. `git grep dispensee\|pieceNonRequise` dans lib/ à a8dfcb3 ne trouve que des commentaires (dossiers_demo.dart:198, plus des tests). |
| HL-A-5 | vérifié avec défauts | **confirmé** | Ancêtres c61d66d, 80eae2e, b2ecef2 et 906d1a3. Doublon recalculé en MD5 sur les 6 paires `fiche_dossier_*` et `verifications_incompletes_*` de 05_recette : identiques (par exemple C66BF71C… pour ordinateur clair). Les tailles sont aussi identiques dans l'artefact publié (136919, 138570, 70585, 72471, 165650 et 168310 octets). Test :205-219 conforme à la description. 739f478 (fusion CL-4) est ancêtre et modifie `action_principale.dart` (89 lignes), ce qui rend plausible l'explication par la graisse. Je n'ai pas comparé ces images moi-même. |
| HL-A-6 | vérifié | **confirmé, une formule à corriger** | etat_dossier.dart:101-111 et :125, redirection.dart:127-133, fr.i18n.json:493-497 (assets/i18n) et revue_dossiers_depuis_validation.dart:94-104 sont exacts. tableau_de_bord_page.dart:135-141 l'est aussi, mais le commentaire de :137 dit « le compteur serveur compte encore les tuteurs (BR-1.c) ». Le rapport écrit « l'Accueil ne montre que des enseignants », ce qui est faux pour la tuile compteur (m1 d'AD-R, renvoyé à BR-1.c). Seules les lignes « À traiter » sont filtrées, comme le dit la fiche. |
| AD-11 | vérifié avec défauts | **confirmé** | `_restes` exact. Artefact P1VXFZvw6ioS9cFerhgPAm listé : 91 fichiers (15 écrans × 6, plus index.html). index.html relu : 9 écrans principaux et 6 cas particuliers. 05_recette/AD/RAPPORT.md:40, 50, 80 et 112/113/116 sont conformes à D-AD11-1. |
| AD-R | vérifié avec défauts | **confirmé, une précision** | c3b6d57 est un commit du dépôt **pilotage** (ancêtre de pilotage/tuteur-v1), pas d'`ui/admin-v1` : `git merge-base --is-ancestor c3b6d57 a8dfcb3` donne 1 dans r-ad. Le rapport ne nomme pas le dépôt, ce n'est pas faux. REVUE_AD-R.md : m1 à m17 (l.99-115) et n1 à n13 (l.121-133), contre « 16 mineurs, 14 notes » à la l.56, dans le message de c3b6d57 et dans la fiche. D-ADR-1 est confirmé. |

## Verdict contesté

**AD-10 : « vérifié » → « vérifié avec défauts ».** Le rapport reconnaît lui-même que deux revendications de la fiche sont fausses à a8dfcb3 : « famille dispensée validable » et « retour après validation vers /tuteur ». Elles ont été retirées par K-47 (HL-A-6). Le retrait est voulu et traçable, mais la fiche reste fausse telle qu'elle est écrite. Un verdict « vérifié » sans défaut ne peut pas couvrir une fiche dont deux affirmations sur trois parcours sont périmées. Il faut un défaut documentaire mineur (annoter la fiche AD-10 en renvoyant à K-47), à verser dans AD-NETTOYAGE. C'est d'ailleurs déjà la première question que le rapport pose au directeur.

## Écarts oubliés par le rapport

1. **Moyen : D-AD9-1 est plus large que la seule production.** `avecEntete` sert aussi au chargement (:180, squelette) et à l'échec serveur (:172-177). Dès qu'un vrai port sera branché (démonstration ou BR-1), un administrateur **sans** la capacité Super Admin verra donc le 4e onglet réservé et son titre pendant le chargement, puis à chaque échec serveur, avant d'arriver à l'accès refusé. Le commentaire de :151-153 (« on ne montre pas l'onglet réservé à qui n'y a pas droit ») est faux dans ces deux états, car le droit n'est pas encore connu. Le remède d'AD-9-ONGLET-PROD doit couvrir les trois états (indisponible, chargement, échec), pas seulement l'indisponible. Je déconseille de le rattacher à AD-M3-PROD : ce dernier porte sur le refus et l'aperçu des pièces, pas sur la garde de l'onglet. Une étape propre, ou un rattachement à AD-NETTOYAGE, serait plus juste.
2. **Mineur : l'écran 16 de la planche n'est pas publié et les comptes d'écrans divergent.** À a8dfcb3, le test de capture produit 16 écrans (`git grep "fichier('"` : … `retour_apres_validation_hors_portee` à :387, `tuteur_apres_inscription` à :408, `tuteur_attente_ouverture` à :445). La fiche HL-A-6 annonce « planche 16 écrans » et planche.json dit « écrans 1 à 16 ». L'artefact publié n'en montre que 15 : `retour_apres_validation_hors_portee` est absent de la liste des fichiers et de index.html. La fiche AD-11 dit 15, la fiche HL-A-5 dit 14 (84 captures). En retirant le doublon de D-HL5-1, la planche publiée n'a que 14 écrans distincts. À rattacher à AD-M2-PLANCHE.
3. **Mineur : des captures périmées restent dans 05_recette.** `05_recette/AD/captures/HL-A-5/retour_apres_validation_*` (6 fichiers du 27/09 à 04:22) n'est plus produit par le test à a8dfcb3 : c'était le retour du tuteur après validation, supprimé par K-47. Le dossier contient donc 17 groupes × 6 = 102 fichiers. Le rapport donne bien ce chiffre, sans voir qu'un groupe est mort. À rattacher à AD-M2-PLANCHE.
4. **Mineur, sur le rapport lui-même** : il dit « windows/ n'a pas été régénéré (passages en --no-pub) ». Mon passage en `--no-pub` sur le même worktree a pourtant régénéré les trois fichiers `windows/flutter/generated_*`. Si le contrôleur les a trouvés propres, c'est peut-être qu'un autre agent les avait remis. L'explication « --no-pub » n'est donc pas une garantie.

Non revérifié par moi : la suite complète (2973/892/0), analyze, les captures portail, validation et visionneuse ouvertes une à une, et la suite propre d'AD-R, dont le journal a disparu (le rapport le dit déjà).
