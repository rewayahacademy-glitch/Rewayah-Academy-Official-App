# VERIF-CORR-1 : vérification du lot 1 des corrections (composants partagés)

- Étape : VERIF-CORR-1 (K-03, K-61), lecture seule.
- Branche : `corrections/revue-directeur-2026-10`, commit **98e3f9d** (dossier `D:\RA_TUTEUR\corrections`, état git inchangé : seuls `windows/flutter/generated_*` modifiés, comme avant).
- Date : 03/10/2026.
- Étapes couvertes : THEME-SW-1, BTN-CENTRE-1, ONGLETS-1, CARTES-ECART-1, MA-NAV-1, HIER-1, PHOTO-LIEN-1, BTN-TESTER-1.
- Production : deux tests de capture TEMPORAIRES (`test/capture/verif_corr1_tmp_capture_test.dart`, `verif_corr1_tmp2_capture_test.dart`), lancés un à la fois par `flutter-verrou.ps1`, puis supprimés. Journaux : `D:\RA_TUTEUR\yaaden-cache\verif-0310\verif-corr-1-captures.log` (18 tests réussis, code 0) et `verif-corr-1-captures-accueil.log` (4 tests réussis, code 0). Vraies polices du dépôt (`chargerPolicesDuDepot`). Écrans isolés par `hoteCapture` ; navigation du Mode Accessibilité sur la vraie route de démonstration `/demo/accessibilite` (vraie coquille `NavShell`, `GoRouter`).

## Ce que montre chaque image (toutes ouvertes, sauf mention « non vue »)

| Fichier | Ce qu'on voit |
|---|---|
| `reglages_320_light_x1.png` (et son double `reglages_compte_320.png`) | Réglages du compte, 320 px, texte ×1 : sous « Apparence », un seul rectangle à trois bascules (soleil Clair, Système sélectionné, lune Sombre), « Système » sur une ligne dans sa pastille. Cartes Accessibilité, encadré « taille du texte », Langue et région séparés d'au moins 16. **Défaut** : ligne Fuseau horaire « Détecté autom / atiquement », mot coupé au milieu. |
| `reglages_320_light_x2.png` | Même écran, texte ×2 : « Système » et « Sombre » tiennent sur une ligne, mais à une taille réduite, alors que « Clair » reste à ×2 : trois tailles différentes dans le même contrôle. **Défaut** : titre « Réglage / s » et « Réduire les anim / ations » coupés au milieu du mot. |
| `reglages_320_dark_x2.png` | Même chose en sombre : mêmes coupures « Réglage / s », « anim / ations » ; mêmes tailles inégales dans le sélecteur. |
| `reglages_320_dark_x1.png` | non vue |
| `reglages_compte_1440.png` | Réglages à 1440 px : le sélecteur de thème s'étend sur toute la largeur du contenu, libellés centrés ; cartes séparées ; « Détecté automatiquement » entier. |
| `apparence_320_light_x1.png` | Apparence (compte), 320 ×1 : titre, « Thème de l'application », sélecteur à trois bascules, « Système » non coupé, légende des trois options (K-58), carte Confort visuel. |
| `apparence_320_dark_x1.png` | Même écran en sombre, mêmes constats, contraste lisible. |
| `apparence_320_light_x2.png` | ×2 : **défaut**, titre d'écran « Appare / nce » coupé au milieu du mot ; sélecteur avec « Clair » plus grand que « Système » et « Sombre ». |
| `apparence_320_dark_x2.png` | non vue |
| `manav_accueil_actif_320_light_x1.png` | Vraie route de démonstration, élève Mariam, onglet Accueil actif (fond plein, icône pleine, gras), trois destinations (Accueil, Ma classe, Mon espace), libellés entiers. |
| `manav_accueil_actif_320_light_x2.png` | ×2 : « Accueil » sur une ligne, non coupé, dans sa pastille pleine (rectangle du texte mesuré : x 17,1 à 100,3 ; il reste à peu près 4 px de chaque côté de la pastille). « Accueil » est affiché plus petit que « Ma classe » et « Mon espace » (échelle réduite par `TexteSansCoupure`). |
| `manav_accueil_actif_320_dark_x2.png` | Même chose en sombre (même rectangle mesuré). |
| `manav_accueil_actif_320_dark_x1.png` | non vue (rectangle mesuré identique au clair ×1 : x 23,2 à 94,1) |
| `manav_demo_320_light_x1.png`, `manav_demo_320_light_x2.png`, `manav_demo_320_dark_x2.png` | Même route, Ma classe active : barre à trois destinations ; à ×2 « Accueil » (inactif) tient sur une ligne. Le contenu passe sous la barre flottante : aucun débordement n'est jugé sous la barre. |
| `manav_demo_320_dark_x1.png` | non vue |
| `accueil_public_320.png`, `accueil_public_1440.png` | HIER-1 : la marque « Rewayah Academy » (petite, violette) est nettement plus petite que le titre « Apprendre le Coran… » (comparée à `docs/current/captures/l1-cartes/avant/accueil_public_320.png`, où la marque, sur deux lignes, était plus grosse que le titre). |
| `tableau_direction_320.png`, `tableau_direction_1440.png` | Centre de commande : tuiles séparées de 16 au moins (grille Bento du lot 2, au-dessus de CARTES-ECART-1), titre d'écran plus grand que « À traiter en premier ». Aucun débordement sur les 4 bords des tuiles. |

## Captures du dépôt ouvertes (docs/current/captures)

- `l1-boutons/` (commit e4f6174, après le changement) : avant/après 320 et 1440 des boutons du core (pilule « Tous les eleves » centrée au lieu de collée à gauche, bouton compact « Tester la camera » à la largeur de son contenu), de la préparation (« Tester la caméra » sur toute la largeur de la carte, en bas, au lieu d'un bouton étroit à gauche), de la photo (« Choisir une photo » passe d'un bouton plein à une ligne de lien avec flèche). Variantes : clair et ×1 seulement.
- `l1-onglets/` (f95dee5) : Pédagogie à 320 en menu (fermé, ouvert avec coche sur la section courante), à 1440 en segmenté en ligne ; Configuration à 390 en menu. Banc synthétique (titre « Pédagogie » écrit dans le test, même pour Configuration), pas l'écran réel ; pas de ×2 ni de sombre.
- `l1-cartes/avant` et `apres` (e14c6ea) : Réglages (cartes collées avant, une carte à lignes après), Centre de commande, accueil public. La capture « après » des Réglages montre encore les trois lignes Radio du thème (branche partie avant THEME-SW-1) : remplacée ici par `reglages_320_*`.
- `MA-NAV-1/` (d6de6d1, AVANT 703ca08) : `manav1_apres_enfant_light_320x2.png` montre « Accueil » collé aux bords de sa pastille pleine, le défaut que 703ca08 a corrigé ; `manav1_avant_enfant_light_320x2.png` montre l'ancienne barre à quatre destinations. Les captures « après » du dépôt ne reflètent donc pas 98e3f9d : remplacées ici par `manav_accueil_actif_320_*`.
