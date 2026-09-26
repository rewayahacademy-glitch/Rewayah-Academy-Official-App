# Recette Classe et visio : rapport (T9 de l'orchestration = fiche T10 du plan)

Date : 26/09/2026. Worktree `C:\RA\classe`, branche `ui/classe-v1`, commit de la recette : voir « Commits » en bas. Aucun branchement serveur (K-28).

Captures et planches : `C:\RA\pilotage\10_classe\captures\T9\` (le plan disait `T10` ; l'orchestration a nommé cette tâche T9). Mode d'emploi simple : `OU_TROUVER.md`.

## Ce qui a été fait

- `test/capture/outil_capture.dart` : fonction `plancheRangee` (image retouchée en haut à 1600 px de large, rangée de N captures dessous, réduites sans déformation, tout en `dart:ui` dans `tester.runAsync`).
- `test/features/salle_seance/salle_seance_capture_test.dart` : groupe « recette compléments » (guidée et enseignant au repos et « rien partagé », CLV-09 en web étroit, sortie avant la fin aux trois tailles, garde-fou des polices) et groupe « planches » (dix planches, thème choisi par `PLANCHE_THEME`, clair par défaut ; les planches sombres portent le suffixe `_dark`, comme les images retouchées).
- Correction de mise en page trouvée à la relecture : CLV-07 et CLV-08 desktop, le titre du support tenait sur 3 lignes. Dans l'image, ce titre mesure environ 0,77 fois celui de CLV-06. Quand le panneau ôte l'illustration, le titre passe de `headlineLarge` (36) à `headlineSmall` (28) du thème (`lib/features/salle_seance/zone_support.dart`). La taille est maintenant celle de l'image, mais la coupure reste sur 3 lignes : il manque environ 10 px de largeur à la colonne de titre. Reste à faire : réduire la place réservée à la vignette dans ce cas (image : ≈ 205 px, rendu : ≈ 225 px). Pas fait, faute de temps (tâche de 35 min).

Captures produites (390x844 @3 zone sûre 47/34, 640x1000 @1, 1440x900 @1, clair et sombre) :

| Rôle | États capturés |
|---|---|
| Élève standard | repos, visite, rien partagé (T2) ; fin CLV-09 et sortie avant la fin, 3 tailles |
| Guidée | repos, visite, rien partagé ; fin CLV-09 et sortie avant la fin, 3 tailles |
| Enseignant | repos, visite (« se poursuit »), rien partagé ; panneau Élèves ; panneau Supports ; fin CLV-10 |

## Planches : image -> capture -> écarts -> invariants

| Image retouchée | Capture(s) | Écarts restants | Invariants vérifiés par |
|---|---|---|---|
| CLV-04_eleve_desktop | `cl_04_eleve_visite_1440x900@1` | photos en aplats | I-1, I-2 `chrome_seance_test` (« eleve, visite : Votre parent, jamais Tuteur de »), `salle_seance_widget_test` (notice seulement en visite, point clignotant) ; I-3 `salle_seance_widget_test` (ratio de la vignette) ; I-5 `vue_seance_test` (« indicateur en lecture seule et zoom local, desktop seul ») ; I-10 `vue_seance_test` (« Eleve standard et guidee : jamais ») |
| CLV-05_guidee_desktop | `cl_05_guidee_visite_1440x900@1` | photos en aplats | I-2 `guidee_fin_test` (« le point reste fixe ») ; I-3 `guidee_fin_test` (« video a cote du support, jamais dessus ») ; I-4 `guidee_fin_test` (« disques du dock de meme taille ») ; I-9 `chrome_seance_test` (« guidee desktop : ni theme, ni reglages ») ; I-10 `guidee_fin_test` (« guidee visite … rien de reserve ») |
| CLV-06_enseignant_desktop | `cl_06_enseignant_visite_1440x900@1` | photos en aplats ; « Élèves 1/3 » au lieu de 3/4 (voulu, I-6) | I-2, I-9 `chrome_seance_test` (« enseignant : compte SA, notice tuteur, jamais parent ») ; I-4 `vue_seance_test` (« jamais Agrandir au dock ») ; I-5 `salle_enseignant_test` ; I-9 `salle_enseignant_test` (« rail sans Foyer ») |
| CLV-07_eleves_desktop | `cl_07_eleves_1440x900@1` | photos en aplats ; titre du support ramené à la taille de l'image (28 au lieu de 36), mais encore sur 3 lignes : la colonne de titre est plus étroite d environ 10 px que dans l'image (la place réservée à la vignette est plus large) | I-6 `panneau_eleves_test` (« compteur du bouton = Connecte de la liste »), `vue_seance_test` (« Compteur derive de la liste ») ; I-10 `panneau_eleves_test` (« jamais rendu pour eleve / guidee ») |
| CLV-08_supports_desktop | `cl_08_supports_1440x900@1` | photos en aplats ; « Ouvrir » en contour (une seule action pleine, plan T6) ; rail sans « Séance en direct » (matrice) ; titre réduit, encore 3 lignes (comme CLV-07) | I-4, I-10 `panneau_supports_test` (panneau enseignant seulement, une seule action pleine) |
| CLV-10_fin_desktop | `cl_10_fin_1440x900@1` | rail sans « Séance en direct » (matrice) | I-1 `chrome_seance_test` (« fin : aucune mention ») ; I-6 `fin_enseignant_test` (« le recapitulatif lit la liste du compteur ») |
| CLV-04-05-06_mobile | `cl_04/05/06_*_visite_390x844@3` | photos en aplats ; coupure de l'encadré un mot plus loin (police du dépôt) | I-7 `vue_seance_test` (« aucune pagination active, a aucune largeur ») ; I-3 `guidee_fin_test` (« vignette en coin ») ; I-10 `salle_enseignant_test` (« rien de reserve a l enseignant » par rôle et taille) |
| CLV-07-08-10_mobile | `cl_07_eleves`, `cl_08_supports`, `cl_10_fin` `_390x844@3` | la feuille Élèves défile : Aïcha est sous le bord (police du dépôt plus large que celle de l'image) ; « Ouvrir » en contour | I-8 `panneau_eleves_test` (fermeture en feuille) ; I-6 `fin_enseignant_test` |
| CLV-04-05-06_web_etroit | `cl_04/05/06_*_visite_640x1000@1` | photos en aplats ; le support descend jusqu'au dock (support dominant) | I-8 `chrome_seance_test` (sans débordement aux 3 largeurs) ; I-4 `salle_enseignant_test` (outils absents si `onOutil` nul) |
| CLV-07-08-10_web_etroit | `cl_07_eleves`, `cl_08_supports`, `cl_10_fin` `_640x1000@1` | photos en aplats | I-8 `panneau_eleves_test` (volet par-dessus le support, croix) |

Critère « aucune capture élève ou guidée ne montre Élèves, Supports, Réseau, outils, pagination active, durée restante, « Tuteur de », « Foyer » » : relu sur les planches (colonnes CLV-04 et CLV-05) et garanti par `vue_seance_test` (« Eleve standard et guidee : jamais »), `salle_enseignant_test` (« rien de reserve a l enseignant ») et `guidee_fin_test`.

Garde-fou des polices : test « garde-fou des polices : aucune capture en carres » du groupe recette, vert ; aucune planche relue ne montre de carrés.

## Options Q1-Q8 appliquées (option des images, sans réponse du directeur)

Q1 oui (disques pleins Parler vert et Caméra violet, même diamètre). Q2 : CLV-06 rangée d'outils au-dessus du support ; CLV-07/08 carte « Outils d'enseignement » en colonne droite. Q3 non (compte en haut à droite). Q4 non (« Tuteur de Mariam observe. »). Q5 non (texte complet de la mention). Q6 oui (zoom local élève, « Zoom local, sans effet sur les autres »). Q7 oui (jamais la vidéo des autres élèves). Q8 oui (guidée desktop : vidéo à côté du support). Constantes `optionQ1`… dans `lib/features/salle_seance/vue_seance.dart`.

## Ce qui attend BR-1 (serveur et configuration)

- Support partagé réel (aujourd'hui : contenu de démonstration ; emplacement `contenuSupport` prêt).
- Outils d'enseignement câblés (Pointeur, Marquer, Masquer, Annoter) et pagination qui change vraiment la page.
- Supports réels (bibliothèque de la Classe, « Ouvrir », « Voir toute la bibliothèque »).
- Session persistante dans `/salle` (fusion du moteur de `/tc/classe`) ; le rendu en séance de `/salle` sur `SalleSeance` (fiche T8 du plan) reste à faire.
- Permissions micro et caméra des plateformes (Android, iOS, web).
- Titre Sayyid/Sayyida connu de `/salle` ; « cette semaine » de la présence récente garanti par le serveur.

## Contrôles

- `flutter test` (suite complète, sous verrou, 457 s) : **2938 réussis, 731 sautés (captures sans `CAPTURE_DIR`), aucun échec.** Rien à comparer au commit 3b41b12.
- Après la correction : `flutter test test/features/salle_seance test/features/salle_test.dart test/features/salle_enseignant_test.dart test/teaching_core` : 1175 réussis, aucun échec.
- `flutter analyze` : aucun problème.
- `dart run tool/verifier_jetons.dart` : 10 écarts, tous préexistants et hors de cette tâche (`lib/core/mouvement/mouvement.dart`, `lib/features/demo/repere_demonstration.dart`, `scanner_page.dart`), les mêmes que dans `T8.md`. Aucun dans les fichiers touchés.
- Captures : 107 tests de capture verts, 10 planches claires et 10 sombres ; garde-fou des polices vert.

## Commits

- Code : `05bd26f` sur `ui/classe-v1` (poussé).
- Pilotage : captures, planches, ce rapport, `OU_TROUVER.md` et le tableau simplifié de `10_classe/03_PLAN_CODE.md` §7.
