# VERIF-CT-1 : Contrôleur, début de vague (CT-1b à CT-5, CT-9, CT-11, PR n°4)

Session 90248232, 03/10/2026, lecture seule (aucun commit de code). Branche `ui/controleur-v1` @ `39a702a`, worktree détaché `D:\RA_TUTEUR\v-ct1` (propre en fin de vérification : `git status` vide).

## Verdict : VÉRIFIÉ AVEC DÉFAUTS (4 moyens, 1 mineur, nouvelles étapes proposées)

- Le majeur CT-4 (transmission rattachée à la mission courante) est réglé par `c44241c` et testé.
- La PR n°4 est bien fusionnée dans `18892c2`, qui est contenu dans `39a702a`.
- Les **trois majeurs CT-3 de la revue cloud du 27/09 ne sont ni corrigés ni renvoyés à BR-1** : « Son reçu », « Agrandir », pré-vol micro. Pour « Son reçu », la décision du directeur C5 = a (« Retirer le bouton jusqu'à BR-1 ») n'est pas appliquée.
- Le test de frontière compte **99** cas verts au commit vérifié, et non 89. Les 89 cas valaient au commit de CT-11 (`4f34498`). Les 10 cas en plus viennent de l'extension demandée par CT-11 lui-même, faite dans `18892c2`. L'écart est expliqué ; ce n'est pas un défaut.

## Verrou

Dernier passage. Journaux copiés ici.

| Commande | Résultat |
|---|---|
| `flutter pub get` | OK, code 0 (`pubget.log`) |
| `dart analyze --fatal-infos lib test tool` | **No issues found!**, code 0 (`analyze.log`). Le fichier de mesure temporaire était sorti du dépôt pendant l'analyse. |
| `flutter test test/features/controleur test/features/controleur_recette test/features/demo/demo_controleur_page_test.dart` | **+174, ~180 ignorés** (captures sans CAPTURE_DIR), **All tests passed!**, code 0 (`tests_controleur.log`) |
| `flutter test test/features/controleur/frontiere_donnees_controleur_test.dart --reporter expanded` | **+99, All tests passed!**, code 0 (`frontiere.log`) |
| Mesure temporaire `test/zz_verif_ct1/salle_sans_micro_test.dart` (sans CAPTURE_DIR) | +1, sortie `VERIF-CT-1 MESURE refusMateriel=true zoneControle=false` (`temporaire_sans_micro.log` ; source copiée dans `mesure_sans_micro_test.dart.txt`) |
| `captures_ct_test.dart --name "CT-1b, coquille\|CT-2, CTR-01\|CT-3, CTR-02\|CT-5, CTR-03A\|CT-9, espaces"` avec CAPTURE_DIR | +104, All tests passed! (`captures_ct.log`) |
| Captures temporaires de la salle (`test/zz_verif_ct1/captures_salle_temp_test.dart`) avec CAPTURE_DIR | +6, All tests passed! (`captures_temp.log`) |

Les deux fichiers temporaires sont supprimés et n'ont jamais été commités. `flutter pub get` avait réécrit trois fichiers générés suivis (`windows/flutter/generated_plugin_registrant.cc`, `.h`, `generated_plugins.cmake`), avec un diff vide (fins de ligne seulement). Ils sont remis à l'état du commit par `git checkout --`.

## PR n°4 dans `18892c2` (PT-B-20261001-e14d420a)

| Contrôle | Résultat |
|---|---|
| `git show 18892c2` | Fusion, parents `0690c6b` et `fe4bdd0`, « Fusion de la PR n°4 (session cloud : CT-6, CT-9, CT-11, corrections de revue) dans ui/controleur-v1 » |
| Tête de la PR | `origin/claude/great-curie-50duvi` = `fe4bdd0` = second parent de `18892c2` (référence locale, pas de fetch) |
| `git merge-base --is-ancestor 18892c2 39a702a` | code 0 (contenu) |
| `git merge-base --is-ancestor fe4bdd0 39a702a` | code 0 ; `git log 39a702a..fe4bdd0` vide : aucun commit de la PR laissé dehors |
| Commits cités par CT-9, CT-11 et la revue (`967404f`, `2451ece`, `f17111d`, `4f34498`, `388230a`, `fcd0425`) | tous ancêtres de `39a702a` (code 0) |

Aucune PR ouverte ni modifiée.

## Majeurs de la revue cloud du 27/09

Source : champs « releves » des étapes CT-2 à CT-5 (« REVUE CLOUD 27/09 »). Aucun fichier séparé n'existe dans le pilotage. Décisions du directeur : feuille `5hqpCULEK4Hwchu7D4BVtg`, lue en lecture seule.

| Point de la revue | Commit | Constat (fichier:ligne à `39a702a`) |
|---|---|---|
| CT-3 (1) « Son reçu » ne coupe rien | **aucun** | `salle_page.dart:145-147` : `bool _sonRecu = true;`, avec le commentaire « Bascule locale ; le réglage du moteur se branche à BR-1 ». `:562` : `onSon: () => setState(() => _sonRecu = !_sonRecu)`. `:873-884` : le bouton est rendu. Le test `salle_controleur_test.dart:65, 94-98` exige ce bouton. La **décision C5 = a, « Retirer le bouton jusqu'à BR-1 »**, n'est pas appliquée. Aucune ligne dans `14_controleur/CT-BR.md`. Capture `verifct1_salle_son_coupe_390_light` : le mot « Son coupé » s'affiche, et rien d'autre ne change. **Non réglé.** |
| CT-3 (2) « Agrandir le support » agrandit l'enseignant | **aucun** | `salle_page.dart:902-920` : `_SupportAgrandi` rend `vue.dominant`, c'est-à-dire l'enseignant. Aucun support n'est rendu dans `/salle` (grep « support » dans `vue_salle.dart` : rien). L'action lue est « Agrandir le support » (`salle.visiteControle.agrandir`). Captures `verifct1_salle_agrandie_390_light` et `_1440_light` : « Sayyid Ibrahim » en plein écran. Aucun renvoi BR-1. **Non réglé.** |
| CT-3 (3) Un contrôleur sans micro ne peut pas entrer | **aucun** | `salle_page.dart:215-222` : le pré-vol passe avant le billet, pour tous les rôles, et donne `CauseImpasse.materiel` si `!preVol.peutEntrer`. Pourtant, `pre_vol_classe.dart:75-79` exempte le contrôleur. Message affiché : `fr.i18n.json:408-409`, « Aucun micro utilisable sur cet appareil… Un cours de Coran se fait à la voix ». La démo le masque (`salle_controleur_demo.dart:191-196`, `microDisponible: true`). **Mesuré** par un test temporaire (salle de la démo, pré-vol sans micro) : `refusMateriel=true zoneControle=false`. Aucun renvoi BR-1. **Non réglé.** |
| CT-4 Transmission et « à terminer » rattachés à la mission courante | `c44241c` (revue CT-R B1) | La visite est notée à l'entrée (`controle_page.dart:336-339`). La salle sort vers `?seance=` (`salle_page.dart:328-332`), et la route le lit (`app_router.dart:1110-1124`). Le compte rendu ne lit plus `missionControleProvider` : il appelle `visiteDeSeance` (`compte_rendu_controle_page.dart:107-117`, `compte_rendu_controle.dart:330-334`). Le port est identifié par séance (`compte_rendu_controle.dart:134-144`). Les visites à terminer sont indexées par séance (`:225-243`). Tests verts : `compte_rendu_controleur_test.dart:452` (mission B, puis mission vide), `:491` (séance inconnue : aucune transmission), `:506` et `:530` (deux visites). **Réglé.** |
| CT-4 Faits par Pressable ; impasse « mission indisponible » | `388230a`, `fcd0425` (PR n°4) | `compte_rendu_controle_page.dart:507-511` : `Pressable`. Capture `ct9_compte_rendu_indisponible_390_light` : le compte rendu reste utilisable. **Réglé.** |
| CT-5 Le choix porté par `extra` seul | `388230a` (PR n°4) | `compte_rendu_controle.dart:115-126` : `choixObservationDepuis` lit d'abord `?choix=`. Test vert `observation_controleur_test.dart:382` et suivantes. **Réglé.** |
| CT-2 « BLOQUANT BR-1 À NE PAS OUBLIER » : `observerEnControle` | **aucun** | `service_video.dart:58, 125` déclare `observerEnControle`, mais **aucun appel dans `lib/`** (grep). `controle_page.dart:236-241` va à `/salle` avec le billet seul. Aucune ligne dans `CT-BR.md` ni dans `BLOQUANTS_ET_IMPACTS.md` (grep « observerEnControle », « rejoindre_observation » : vide dans tout le pilotage). Le bloquant n'est cité que dans la feuille du directeur (D1). **Renvoi BR-1 absent.** |
| CT-2 « Votre prochaine mission » en direct ; « non annoncée » | `0703d80`, `91f31eb` | `fr.i18n.json:3343-3344, 3350` : « Classe à observer maintenant » en direct, « Votre prochaine Classe à observer » avant, et « Votre présence n'est pas annoncée en temps réel. ». Captures `ct2_controle_enDirect_390_light` et `ct2_controle_pasEncoreEnDirect_390_light`. **Réglé.** |

Les défauts trouvés sont aussi présents sur la branche commune : `corrections/revue-directeur-2026-10` @ `7c61287` contient `39a702a`, avec `salle_page.dart:151, 223, 572, 1056-1063` identiques.

## frontiere_donnees_controleur_test

- **À `39a702a` : 99 cas verts** (`frontiere.log`, « +99: All tests passed! »). Le compte : 47 écrans × 2 largeurs (390, 1440) = 94, plus 5 tests isolés (liens de la liste, filtre, noms de famille, et deux tests de la recette 32). La liste est dans `frontiere_donnees_controleur_test.dart:398-511`.
- **À `4f34498` (CT-11) : 89 cas**, recomptés dans la source. Il y avait 42 écrans × 2 = 84, plus 5 = 89, ce qui est conforme à la preuve de CT-11.
- La différence est de 5 écrans × 2 : « historique-detail » (2) et « complement » (3), ajoutés dans `18892c2`. C'est ce que demandait le relevé de CT-11 (« ajouter Historique et Détail à `_ecrans()` »). Le nombre de liens reste 24 (`:564`), et le test passe.

## Captures (K-61, ouvertes une par une, 4 bords regardés)

Copiées dans `captures/`. Aucune bande jaune et noire d'erreur Flutter, aucun débordement sur les 23 images.

| Fichier | Ce qu'on voit |
|---|---|
| `ct2_controle_enDirect_390_light` / `_dark` | Une seule carte : « Classe à observer maintenant », Classe An-Nour, « Votre présence n'est pas annoncée en temps réel. » et « Commencer le contrôle ». Barre à 4 destinations. Le ruban « Démonstration » est coupé en diagonale dans le coin haut droit, comme voulu. |
| `ct2_controle_pasEncoreEnDirect_390_light` | « Votre prochaine Classe à observer » et une ligne calme : « Le contrôle s'ouvrira dès que la séance sera en direct. ». Aucun bouton. |
| `ct2_controle_indisponible_390_light` | Message générique seul. Les deux-points commencent la 2e ligne (« : la séance a été annulée… »), voir les remarques. |
| `ct2_controle_enDirect_1440_light` | Rail latéral à 4 destinations ; la carte est à gauche, rien n'est coupé. |
| `ct3_salle_390_light` / `_dark`, `ct3_salle_1440_light` | Zone haute « Contrôle Rewayah », « En direct », « Quitter ». Quatre tuiles en initiales, rappel et bandeau permanent. En bas : **« Son reçu » et « Agrandir »**. À 1440 : colonne « Présence 4 ». En sombre, la salle reste claire en haut et en bas (question déjà posée par la revue). |
| `verifct1_salle_son_coupe_390_light` | Après un toucher, le mot devient « Son coupé » et l'icône passe en contour. Le code ne coupe rien. |
| `verifct1_salle_agrandie_390_light` / `_1440_light` | « Agrandir » donne l'enseignant « Sayyid Ibrahim » seul en plein écran ; le bouton devient « Réduire ». Aucun support. |
| `ct3_compte_rendu_390_light` | « Compte rendu », « Classe An-Nour · 18:00 », relevé automatique replié, notice de transmission, trois cartes avec la ligne « Quand… ». Le bas de page continue sous le pli (page défilante, pas un débordement). |
| `ct5_observation_nature_390_light` | Étape 1 sur 5, trois natures, « Intervention de l'administration souhaitée » choisie, « Continuer ». |
| `ct5_observation_personne_390_light` | Étape 3 sur 5. La liste montre **« Mariam », « Yusuf », « Aïcha » en prénom seul**. La question est passée sous l'en-tête après le défilement (m7, déjà suivi). |
| `ct5_observation_texte_requis_390_light` | Étape 4 sur 5, champ en erreur : « Écrivez ce que vous avez observé pour continuer. ». |
| `ct5_observation_recapitulatif_390_light`, `_1440_dark` | Étape 5 sur 5 : Nature, Domaine, Personne (« Élève précis · Mariam »), Remarque ; notice « Ce compte rendu est transmis automatiquement à l'administration. » ; « Envoyer le compte rendu ». À 1440, l'en-tête est décalé et le bouton occupe toute la largeur (m6 et m8, renvoyés à HU-1). |
| `ct1b_coquille_compte_390_light`, `ct1b_coquille_historique_768_dark` | Coquille à 4 destinations (barre en bas à 390, rail à 768). Le Compte du contrôleur n'a pas de ligne Foyer. L'identifiant de démo s'affiche (relevé CT-9 connu). |
| `ct9_feuille_espaces_390_light` | Feuille « Espaces » : Enseignant et Contrôle « Actif ». La description de Contrôle tient sur 4 lignes (relevé HU-1 connu). |
| `ct9_compte_mission_en_cours_390_light` | Compte en mission, avec le raccourci d'espaces en haut à droite. |
| `ct9_compte_rendu_indisponible_390_light` | Le compte rendu reste utilisable quand la mission est devenue indisponible (`fcd0425`). |
| `ct9_acces_revoque_390_dark` | « Votre accès au contrôle n'est plus actif. » et « Revenir à mon espace ». |

## Défauts → étapes proposées (aucune réouverture, K-38)

1. **CTRL-SON-1, moyen, voie CORR-1, dépend de INTEG-RC-1.** Appliquer la décision du directeur C5 = a : retirer « Son reçu » de la salle du contrôleur jusqu'à BR-1.
   - Fichiers : `salle_page.dart:145-147, 559-563, 873-884` (`7c61287` : `:151, 572`).
   - Test à adapter : `salle_controleur_test.dart:65, 94-98`.
   - Lexique : P12 et P13 de `LEXIQUE_CONTROLEUR.md` à marquer « retiré ».
   - Ajouter une ligne BR dans `CT-BR.md` : couper la lecture des pistes reçues dans le moteur.
   - Preuve : capture `verifct1_salle_son_coupe_390_light`.
   - À enchaîner avec SALLE-CORR-3, qui touche le même fichier ; son point 3 (disque de « Son reçu » invisible) devient sans objet.
2. **CTRL-PREVOL-1, moyen, voie CORR-1, dépend de INTEG-RC-1.** Un contrôleur sans micro est bloqué à l'entrée de `/salle`.
   - Cause : `salle_page.dart:215-222` applique le pré-vol micro à tous les rôles.
   - Remède : sauter l'exigence du micro pour les rôles qui n'en ouvrent pas, comme le fait déjà `pre_vol_classe.dart:75-79`. Le rôle de session est lu dans `salle_page.dart:175`.
   - Test à ajouter : le test de mesure de cette vérification, inversé (`mesure_sans_micro_test.dart.txt`).
   - Contraire à P-CTR-03 point 4, R8 et R13 (revue cloud). Le même chemin touche probablement le tuteur observateur et l'administration : non mesuré ici.
3. **CTRL-AGRANDIR-1, moyen, voie CORR-1, dépend de INTEG-RC-1.** « Agrandir le support » agrandit l'enseignant, et `/salle` n'affiche aucun support (`salle_page.dart:902-920`).
   - Captures : `verifct1_salle_agrandie_390_light` et `_1440_light`.
   - Remède : retirer la commande tant qu'aucun support partagé n'est rendu dans `/salle`, comme pour C5. Ou bien la renommer, par exemple « Agrandir la vidéo » ; ce libellé est une question au directeur (C16).
4. **CTRL-BR-OBS-1, moyen, voie BR-1 (ligne de `CT-BR.md`, pilotage).** Ajouter une ligne BR-CT-19 : « Commencer le contrôle » doit appeler `observerEnControle(seanceId)` (RPC `rejoindre_observation`) avant `/salle`.
   - Sans cet appel, le jeton de salle est refusé en réel, et le passage n'est pas journalisé alors que le bandeau le promet.
   - Constat : aucun appel dans `lib/` (`service_video.dart:58, 125` ; `controle_page.dart:236-241`). Relevé CT-2 « BLOQUANT BR-1 À NE PAS OUBLIER », absent de `CT-BR.md` et de `BLOQUANTS_ET_IMPACTS.md`.
   - Ajouter aussi un test du chemin par défaut de « Commencer », sans surcharge.
5. **CTRL-ROSTER-C7-1, mineur, voie CORR-2 probable, dépend de INTEG-RC-1, à enchaîner après CTRL-SEANCE-1 (même fournisseur).** Appliquer la décision C7 = a (élèves présents, prénom et initiale du nom) à la liste de l'observation.
   - Constat : `EleveRoster` n'a que `prenom` (`observation_controle.dart:63-72`), et la démo donne des prénoms seuls (`controleur_demo.dart:357-359`). Capture `ct5_observation_personne_390_light`.
   - L'Historique applique déjà la décision (`historique_controleur.dart:115-117`, `historique_controleur_demo.dart:97` : « Aïcha N., Mariam S., Yusuf B. »).
   - `CT-BR.md` (BR-CT-12) dit encore « prénom seul, C8 ».

## Remarques (sans étape)

- `fr.i18n.json:3348` : une espace simple précède les deux-points, donc « : » peut passer seul en début de ligne (`ct2_controle_indisponible_390_light`). Une espace insécable suffit. La clé est déjà touchée par CTRL-MSG-1.
- C2 = a demande un bouton vers les missions quand la séance est finie avant l'entrée. Sur l'écran Contrôle, qui est lui-même la page des missions, le message s'affiche sans bouton (test « mission indisponible : le message générique seul »). Ce choix paraît cohérent, mais il reste **non prouvé** au regard de la décision : à confirmer par le directeur.
- CTRL-SALLE-1 (vérifiée : notice « Visite de contrôle » retirée chez le contrôleur, avatars) n'est pas dans `ui/controleur-v1` : la capture `ct3_salle_*` montre encore la notice. C'est attendu, la correction vit sur la branche commune.
- m6, m7 et m8 (en-tête de `PageParcours` décalé à 1440, question passée sous l'en-tête, bouton pleine largeur) sont visibles. Ils sont déjà renvoyés à HU-1.

## Étapes couvertes

| Étape | Résultat | Pourquoi |
|---|---|---|
| CT-1b | vérifiée | Coquille à 4 destinations (`nav_shell.dart:157` et suivantes ; captures `ct1b_*`), route de démo fermée en production (recette 32, verte), `controleur_demo.dart` présent, `CT-BR.md` présent. |
| CT-2 | vérifiée | Une seule carte, « Commencer » seulement en direct, entrée en salle testée (`controle_page_test` : « en direct : on tape Commencer… »), aucun planning, C1 et S2 appliquées (`0703d80`, `91f31eb`). Le renvoi BR-1 manquant d'`observerEnControle` est proposé en CTRL-BR-OBS-1. |
| CT-3 | **non vérifiée** | Les trois majeurs de la revue cloud (Son reçu, Agrandir, pré-vol micro) ne sont ni corrigés ni renvoyés à BR-1, et la décision C5 = a n'est pas appliquée. Étapes proposées : CTRL-SON-1, CTRL-PREVOL-1, CTRL-AGRANDIR-1. |
| CT-4 | vérifiée | Majeur réglé par `c44241c` (tests verts aux lignes 452, 491, 506 et 530) ; Pressable `388230a` ; impasse retirée `fcd0425`. |
| CT-5 | vérifiée | Cinq étapes, texte obligatoire, notice, récapitulatif (captures `ct5_*`), majeur réglé `388230a`, tests verts. La décision C7 = a n'est pas appliquée à la liste : mineur proposé en CTRL-ROSTER-C7-1. |
| CT-9 | vérifiée | Tests `espaces_controleur_test` verts (externe, Enseignant-Contrôleur, mission en cours, accès révoqué) ; Foyer retiré (`compte_page.dart:689`) ; captures `ct9_*`. |
| CT-11 | vérifiée | 89 cas à `4f34498`, recomptés dans la source ; 99 cas verts à `39a702a` après l'extension demandée par CT-11 (`18892c2`) ; filtre et recette 32 verts. |
| PT-B-20261001-e14d420a | vérifiée | `18892c2` = fusion de `fe4bdd0` (tête de la PR n°4), ancêtre de `39a702a` ; aucun commit de la PR laissé dehors. |
