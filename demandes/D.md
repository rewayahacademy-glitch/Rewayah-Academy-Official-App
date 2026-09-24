# Demandes du lot D (Appareils) au coordinateur

## D-1 (LD-1) : paire de couleurs dediee au QR
- Fichier : `lib/core/theme/app_palette.dart`
- Besoin : une paire `contenuQr` (fond blanc, modules quasi noirs) identique en clair et en sombre (manifeste §3.5 : « le QR reste noir sur blanc pour le scan »).
- Signature voulue : `final AppColorPair contenuQr;` (clair et sombre : background `#FFFFFF`, onBackground `#110E20`).
- Contournement actuel : `EmetteurQr.paire => AppPalette.claire().surfaceRaised` (`lib/features/appareils/emetteur_qr.dart`), sans couleur litterale.

## D-2 (LD-1, constat) : tri sans sens explicite
- Fichier : `lib/core/appairage/service_appairage.dart:212`
- Besoin : `.order('paired_at', ascending: true)` (ou `false`, a decider) avec un test d'ordre (03 §1 ter bis-2). Consomme par la liste des appareils (LD-3).

## D-3 (LD-1) : retour de l'emetteur
- Fichier : aucun changement demande. L'emetteur lit un parametre `retour` valide par `cheminRetourValide` (defaut `/tuteur/foyer/appareils`). La fiche eleve (lot B) peut appeler `Routes.appairerPour(id)` + `?retour=<chemin de la fiche>`.