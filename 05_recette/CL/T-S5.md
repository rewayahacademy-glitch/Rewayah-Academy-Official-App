# T-S5 : écrans de secours, caméra interdite, séance prolongée, accès retiré (lot CL-7)

Date : 26/09/2026. Branche `ui/classe-v1`, commit `76c938a`. Plan : `10_classe/07_SECOURS.md` §2.4 à §2.6 et §3 T-S5. Aucune maquette (feu vert du directeur) ; références : `UX_REVIEW_CL-7.md`, maquettes retouchées de la classe ; contrats A à E appliqués (lot nouveau).

## Fait

- `dock_seance.dart` : nouveau `StatutCameraInterdite` (clé `statut-camera-interdite`) qui compose la `StatusPill` partagée (ton neutre, aucune copie, aucun `Pressable`, ni survol ni focus, libellé lu dans l'ordre du dock). Rendu seulement si `VueSeance.texteCameraInterdite` ≠ null (élève standard, `cameraAutorisee` faux, `optionQS1`). Q-S1, option par défaut : 390 au-dessus du dock, aligné start, écart 8 ; 768 et 1440 dans la barre, à la place du bouton Caméra (juste après Micro). Largeur bornée à `AppPage.largeurEtatVide` (la pilule desktop n'est pas contrainte).
- IG : ni bouton ni explication ; EN : jamais de statut (caméra toujours présente).
- Prolongée et accès retiré : déjà codés en T-S1 (`HorlogeDepassee`, `IssueSeance.accesRetire`, démo) ; T-S5 ajoute les tests d'écran et les captures. Aucun code nouveau nécessaire.

## Preuves

- `flutter analyze --fatal-infos` : 0 problème.
- `test/features/salle_seance/salle_secours_t_s5_test.dart` (nouveau, 25 tests + 36 captures) : ES caméra interdite aux 3 tailles → pas de bouton Caméra, statut présent, ton neutre, aucun `Pressable` dedans ni autour, taper le statut ne fait rien ; sémantique = texte exact, sans action tap ; 390 au-dessus du dock ; 1440 dans le dock après Micro ; zoom 2,0 à 390 sans débordement ; IG aux 3 tailles ni bouton ni texte ; ES caméra autorisée → bouton, pas de statut ; EN sans statut. Prolongée ES/EN aux 3 tailles « La séance se poursuit. », aucun minuteur négatif ni « restantes » ; IG rien ; aucun « Prolonger », Quitter ouvre « Quitter la séance ? ». Accès retiré ES aux 3 tailles : titre exact en en-tête sémantique, aucun texte reconnexion / présent / absent / enregistrement, pas de dock, taper « Retour à la Classe » sort ; IG « La séance est terminée. » + « Retour à l'accueil » tapé ; EN `FinSeanceEnseignant` + « Ouvrir le cahier » tapé.
- `flutter test test/features/salle_seance/ test/features/demo/` : 416 réussis, 325 sautés (captures sans `CAPTURE_DIR`), 0 échec.
- Captures `10_classe/captures/TS5/` : 36 PNG, `cl7_04_camera_interdite_*`, `cl7_{04,06}_prolongee_*`, `cl7_{09,05,10}_acces_retire_*` aux trois tailles, clair et sombre. Relues : `cl7_04_camera_interdite_390x844@3_light`, `_768x1024@1_light`, `_1440x900@1_dark`.

## Écarts

- `StatusPill` documente « deux mots au plus » ; le texte de la spec en compte cinq. La pilule passe à la ligne à 768 (deux lignes dans sa case du dock). À revoir en HU-1 ou à trancher avec Q-S1 (option « lecteur d'écran seulement »).
- « Focus initial sur le titre » de l'accès retiré : vérifié comme en-tête sémantique (point d'entrée du lecteur) ; `EcranResultat` ne pose pas de focus clavier explicite (composant partagé non modifié, à voir en HU-1).
- Reste du lot : T-S6 (page démo et recette).
