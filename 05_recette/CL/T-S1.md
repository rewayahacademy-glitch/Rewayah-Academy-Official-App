# T-S1 : écrans de secours, modèle, textes, démo (lot CL-7)

Date : 26/09/2026. Branche `ui/classe-v1`, commit `be4bb79`. Plan : `10_classe/07_SECOURS.md` §3 T-S1. Aucune capture prévue par la tâche.

## Fait

- `vue_seance.dart` : `ConnexionSeance { enLigne, reseauFaible, reconnexion, retablie, echec, horsLigne }` + `etablie` ; getters purs `texteBandeau`, `sousTexteBandeau`, `texteRetabli`, `voitBlocEchec`, `titreEchec`, `echecPermetQuitter`, `libelleQuitterEchec`, `commandesPublicationActives`, `libelleIndisponible(commande)`, `texteCameraInterdite`, `texteMicroBloque` ; constante `optionQS1 = true` ; `texteConnexion` = « En ligne » en réseau faible et rétablie ; `copyWith(connexion:)`.
- `HorlogeRestante` : `assert(minutes >= 0)` ; `depuis_classe_live.dart` borne à 0.
- `resultat_seance.dart` : `IssueSeance.accesRetire` (titre « Votre accès à cette séance a pris fin. », aucune phrase).
- `actions_seance.dart` : `onReessayerConnexion`, `onContinuerSansMicro`, `onOuvrirReglages` (null = non rendu).
- Adaptateurs : `DepuisSalle.connexionDe` (instable → reseauFaible, reconnexion → reconnexion, retabli → retablie), repris par `depuis_classe_live.dart`.
- `chrome_seance.dart` : la pastille lit `connexion.etablie` (une ligne).
- Slang `salle.secours.*` (fr + ar), `salle.fin.accesRetireTitre`, `salle.seance.demo.etats.*` pour les 9 états.
- Démo : `EtatDemoSalle` + reseauFaible, reconnexion, retablie, echec, horsLigne, microBloque, cameraInterdite, prolongee, accesRetire ; `DonneesSeanceDemo.connexion(etat)`, `issueEleve(etat)` ; la page démo ouvre `ResultatSeance(accesRetire)` (ES) et CLV-10 (EN).

## Preuves

- `flutter analyze --fatal-infos` : 0 problème.
- `test/features/salle_seance/vue_seance_secours_test.dart` : 20 tests (un par ligne des tableaux §2, IG sans caméra ni explication, EN sans statut caméra, minutes jamais négatives, jamais « hors ligne » en réseau faible ; boutons tapés : `Retour à la Classe` en accès retiré ES, `Ouvrir le cahier` en EN, `Quitter` puis `Quitter et ouvrir le cahier` dans 7 états de secours).
- `flutter test test/features/salle_seance/ test/features/demo/` : 266 réussis, 175 sautés (captures sans `CAPTURE_DIR`), 0 échec.
- `verifier_jetons` : aucun nouveau signalement (les signalements restants existaient avant).

## Écarts

- Tests dans un nouveau fichier `vue_seance_secours_test.dart` au lieu de `vue_seance_test.dart` (lisibilité ; même dossier).
- Pastille en `echec` et `horsLigne` : « Reconnexion » (aucune clé « Hors ligne » courte dans la spec) ; le bloc d'erreur dit l'état exact. À revoir en T-S3 si besoin.
- La page démo liste déjà les 9 états pour tous les rôles (filtrage par rôle prévu en T-S6) ; `microBloque` et `cameraInterdite` n'ont pas encore de rendu propre (T-S4, T-S5).
- Rien de rendu à l'écran pour les bandeaux, le bloc d'erreur et la feuille : T-S2 à T-S4.
