# Lot D (Appareils) : rapport de fin de lot

Branche `ui/tuteur-v1-d` @ `f799ade` (poussée), base `origin/ui/tuteur-v1` @ `cefab7f` (aucune nouvelle base annoncée dans ETAT_A.md au 24/09 22:25). Commits du lot : `0fc023d` (LD-1), `2278f0f` (LD-2), `5bd6814` (LD-3), `f799ade` (LD-F, corrections de la revue LD-R).
Rapports des sous-paquets : `LD-1.md`, `LD-2.md`, `LD-3.md` ; revue : `REVUE.md`. Ce rapport les consolide et les remplace là où ils divergent.

## 1. Écrans livrés

| Écran | Route | Fichier | Remplace |
|---|---|---|---|
| Émetteur QR du tuteur | `/tuteur/foyer/appairer/:eleveId` (`?retour=`) | `lib/features/appareils/appairage_page.dart`, `emetteur_qr.dart` | ancien émetteur |
| Scanner (appareil élève) | `/connexion/eleve/scanner` | `lib/features/eleve_connexion/scanner_page.dart` | nouveau |
| Saisie du code (appareil élève) | `/connexion/eleve/code` (`?depuis=profils`) | `lib/features/eleve_connexion/saisie_code_page.dart` | saisie inline de ELV-01 (retirée) |
| Choix du profil et code personnel (ELV-01) | `/connexion/eleve` (profil en `extra`) | `lib/features/eleve_connexion/eleve_connexion_page.dart` | refonte |
| Appareils du foyer | `/tuteur/foyer/appareils` | `lib/features/appareils/appareils_page.dart` | refonte |
| Appareils d'un profil élève | `/tuteur/foyer/:eleveId/appareils` (`?retour=`) | `lib/features/appareils/appareils_eleve_page.dart`, `liste_appareils_eleve.dart` | STUB de phase 0 (remplacé) |
| Feuille « Connecter l'appareil d'un élève » | depuis `/connexion` | `lib/features/connexion/feuille_appareil_eleve.dart` | textes réalignés |

Ports et adaptateurs : `lib/core/appairage/lecteur_qr.dart` (+ `lecteur_qr_mobile_scanner.dart`), `statut_code_appairage.dart`, `service_enfant.dart` (`connecterCetAppareil`).

## 2. Carte des fonctions (une fonction, un seul endroit)

| Fonction | Écran unique | Route | Place dans la maquette |
|---|---|---|---|
| Voir les appareils du foyer | Appareils du foyer | `/tuteur/foyer/appareils` | UN groupe « Profils élèves » (lignes #6 : prénom, appareils actifs, chevron) ; explication de l'appareil partagé à droite sur bureau. Entrée : ligne « Appareils partagés » du Foyer (lot B) ; sur la branche D seule, l'onglet Foyer rend encore cet écran (STUB du lot B) |
| Gérer les appareils d'un profil | Appareils d'un profil élève | `/tuteur/foyer/:eleveId/appareils` | ligne du profil dans Appareils du foyer ; ligne « Appareils » de la fiche élève (lot B, sans import) |
| Retirer un appareil | Appareils d'un profil élève | idem | bouton « Retirer » dans la ligne de l'appareil, confirmation (feuille, dialogue sur bureau) ; DB-APP-03 dit |
| Connecter un appareil (entrée de l'émetteur) | Appareils d'un profil élève | idem, vers `/tuteur/foyer/appairer/:eleveId?retour=...` | action « Connecter un appareil » sous la liste (le groupe partagé n'a pas de pied, COORD). **Remplace** l'entrée « Ajouter un appareil » de LD-1 (bouton et clé supprimés en LD-3) |
| Afficher le QR et le code | Émetteur QR | `/tuteur/foyer/appairer/:eleveId` | colonne centrée (M5 #22) ; bureau : QR à gauche, consigne et code à droite |
| Générer un nouveau code | Émetteur QR (états expiré, remplacé, déjà valable) | même route | action dominante de l'écran résultat |
| Voir les appareils depuis le plafond | Émetteur QR (erreur plafond) | vers `/tuteur/foyer/:eleveId/appareils` | action de l'écran résultat |
| Entrée appareil élève | Connexion > « Connecter l'appareil d'un élève » > feuille > « Saisir le code » | `/connexion` puis `/connexion/eleve` (sans profil : saisie) | lien discret de la connexion (lot A), feuille du lot D |
| Saisir le code d'appairage | Saisie du code | `/connexion/eleve/code` | champ unique (E3 #14) ; téléphone : action ancrée en bas ; bureau : panneau centré |
| Scanner le QR | Scanner | `/connexion/eleve/scanner` | « Scanner le QR code » sous le champ de la saisie (absent sur Windows et Linux) ; téléphone : plein cadre sombre (M3 #20) ; bureau : panneau centré (D1 #24) |
| Revenir à la saisie depuis le scanner | Scanner | disque retour et « Saisir le code » | barre haute et barre basse posées sur le cadre |
| Choisir son profil (appareil partagé) | ELV-01 | `/connexion/eleve` | grille de deux colonnes (cartes #11/#13), pile à 150 % |
| Ajouter un 2e élève sur l'appareil | ELV-01 vers Saisie | `/connexion/eleve/code?depuis=profils` | action secondaire sous la grille |
| Créer, saisir le code personnel | ELV-01 | `/connexion/eleve` (état interne) | pavé `PinPad` sous l'avatar |
| Code oublié | ELV-01 vers Saisie | « Code oublié ? » puis « Saisir un nouveau code » (`?depuis=profils`) | sous le pavé ; le nouveau code d'appairage efface l'ancien code personnel (R-01) |
| Changer de profil | ELV-01 | même route | sous le pavé (s'il y a plusieurs profils) |

Aucune fonction n'est présente deux fois ; aucun doublon entre lots (le Foyer et la fiche du lot B mènent aux routes D par des lignes, sans import).

## 3. Statut de chaque écran

| Écran | UI réalisée | Branchée au service existant | Testée en simulation | Vérifiée réellement | Dépendances backend |
|---|---|---|---|---|---|
| Émetteur QR | oui | RPC `creer_code_appairage`, vue `mes_codes_appairage_v` | oui | non (pas de staging sur le poste B) | DB-APP-01 (pas d'annulation), DB-APP-02 (droit de lecture de la vue), DB-APP-04 |
| Scanner | oui | Edge `session-enfant` via `connecterCetAppareil` ; `mobile_scanner` | oui (faux lecteur) | non (aucun téléphone ni émulateur) | DB-APP-06 (codes d'erreur non stables) |
| Saisie du code | oui | idem | oui | non | DB-APP-06 |
| ELV-01 | oui | Edge `session-enfant` par jeton d'appareil, coffre, base locale | oui | non | DB-APP-07 (429), plafond d'essais du pavé (COORD) |
| Appareils du foyer | oui | `profils_du_foyer_v`, `mes_appareils_v` | oui | non | DB-APP-05, D-2 |
| Appareils d'un profil | oui | `mes_appareils_v`, RPC `revoquer_appareil` | oui | non | DB-APP-03, DB-APP-05, D-2 |

Chaque écran a ses états chargement, contenu, vide, erreur et hors ligne (détail dans LD-1.md, LD-2.md, LD-3.md et section 5).

## 4. Tests lancés (poste B, sous verrou, 24/09 après `f799ade`)

- `flutter test --no-pub test/features/appareils test/features/appareils_test.dart test/features/eleve_connexion_test.dart test/appairage` : **« 00:17 +134 ~211: All tests passed! »** (211 sautés = captures sans `CAPTURE_DIR`).
- Non-régression `flutter test --no-pub test/router test/accessibilite test/i18n test/config test/features/connexion_test.dart test/features/compte_galerie_test.dart` : **« 00:22 +355: All tests passed! »**.
- Captures `CAPTURE_DIR=05_recette/D/captures` (+ `CAPTURE_MAQUETTE_M3`, `CAPTURE_MAQUETTE_E3`) sur `scanner_saisie_capture_test.dart`, `emetteur_qr_capture_test.dart`, `appareils_capture_test.dart` : **« 00:30 +206 ~5: All tests passed! »** (5 planches sautées faute de variable, voir section 6).
- `dart analyze --fatal-infos lib/features/appareils lib/features/eleve_connexion lib/features/connexion lib/core/appairage test/features/appareils test/features/appareils_test.dart test/features/eleve_connexion_test.dart test/appairage` : **« No issues found! »**.
- `dart run tool/verifier_jetons.dart` : **« Jetons verifies : 423 fichiers, aucune violation. »**
- `dart run slang` régénéré, fichiers générés commités.
- `graphe_imports.ps1 -Repo C:\RA\lot-d -Ref f799ade` : `service_enfant`, `appairage_page`, `appareils_eleve_page`, `appareils_page`, `feuille_appareil_eleve`, `eleve_connexion_page`, `saisie_code_page`, `scanner_page` atteignables depuis `lib/main.dart`.
- Frontière `git diff --stat origin/ui/tuteur-v1...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` : vide. Aucun STUB « lot D » dans `lib/`.
- Parcours par gestes sur le vrai routeur : `emetteur_qr_test.dart` (onglet Foyer, ligne, « Connecter un appareil », disque retour), `appareil_partage_test.dart` (Retirer confirmé et retours ; connexion, feuille, choix, code ; 2e élève ; code oublié de bout en bout), `scanner_saisie_test.dart` (connexion, feuille, saisie, scanner, QR lu, code personnel ; disques retour).

## 5. Suite donnée à chaque constat de REVUE.md

| N° | Gravité | Suite | Preuve |
|---|---|---|---|
| R-01 | majeur | **Corrigé.** `connecterCetAppareil` efface l'empreinte du code personnel du profil dès que le nouveau jeton est rangé ; « Code oublié ? » propose « Saisir un nouveau code » (saisie, retour au choix) ; `oubliePhrase` décrit ce parcours réel. | `service_enfant.dart` (`effacerEmpreintePin` après `enregistrerJetonAppareil`) ; tests `appareil_partage_test.dart` « code oublie de bout en bout » (code du tuteur saisi, puis « Choisis ton code personnel », code de Yusuf conservé) et `scanner_saisie_test.dart` « un nouveau jeton efface l ancien code personnel » |
| R-02 | majeur | **Corrigé.** Échec du coffre après un code accepté = `AppairageRefuse(MotifRefusAppairage.nonEnregistre)` ; message « Connexion non enregistrée » (le code a sans doute déjà servi, en demander un nouveau) ; filet `on Object` dans les deux écrans. | tests « scanner : coffre qui refuse le jeton » (état refus, « Scanner à nouveau » et « Saisir le code »), « saisie : coffre qui refuse le jeton » (message sous le champ, champ actif), test pur `nonEnregistre` |
| R-03 | mineur | **Corrigé.** Lecture du coffre sous try (pavé, message d'échec, retour) ; jeton absent = message `profils.jetonAbsent`, qui n'accuse pas le tuteur ; `profils.retire` reste réservé au refus serveur `revoque`. Même garde ajoutée à la lecture de l'empreinte. | tests « coffre illisible a l ouverture », « jeton absent : ... n accuse pas le tuteur » |
| R-04 | mineur | **Corrigé.** `ouvrirSession(...).timeout(EleveConnexionPage.delaiOuverture)` (20 s) dans l'écran ; à l'expiration, pavé, message d'échec et retour reviennent. Le retour reste masqué pendant l'attente (quitter pendant qu'une session s'ouvre pourrait ouvrir le compte d'un autre profil choisi entre-temps). | test « serveur muet a l ouverture » |
| R-05 | mineur | **Corrigé.** Lecture du code vivant en échec (autre que DB-APP-02) : état d'erreur avec « Réessayer » (relit), aucun code créé ; hors ligne : état hors ligne. | `appairage_page.dart` `_demarrer` ; test « lecture du code vivant en echec » |
| R-06 | mineur | **Corrigé.** Ce rapport (carte unique à jour) ; ligne d'entrée de `LD-1.md` marquée remplacée. | section 2 ; `LD-1.md` |
| R-07 | mineur | **Corrigé.** `PanneauAppareilEleve` (dans `saisie_code_page.dart`) : une seule composition tablette et bureau pour la saisie, le scanner et ELV-01, disque retour et titre alignés sur le panneau de 560. | tests « bureau 1440 (...) : retour et titre alignes sur le panneau » (scanner, saisie, ELV-01) ; captures `scanner_lecture_1440x900@1_*`, `saisie_vide_1440x900@1_*`, `appareil_*_1440x900@1_*` ; planches `scanner_lecture_bureau_contre_D1.png`, `saisie_bureau_contre_D1.png` |
| R-08 | mineur | **Corrigé, avec un écart assumé.** Téléphone : la caméra occupe tout le corps de la page, le disque retour 48 et le titre, puis la consigne et « Saisir le code », sont posés sur le cadre (plus de zone d'action séparée ni de carte à marges). Écart assumé : le cadre s'arrête à la gouttière de `PageShell` (20) et sous sa marge haute, parce que `verifier_jetons` interdit un `Scaffold` nu (`page-sans-coquille`) et que `PageShell` (COORD) n'a pas de mode bord à bord. Le contenu de M3 a lui aussi des marges. À valider par le coordinateur. | test « telephone : camera sur tout le corps » ; capture `scanner_lecture_390x844@3_*` ; planche `scanner_lecture_entier_contre_M3.png` |
| R-09 | mineur | **Corrigé.** Planches refaites, écran rendu **en entier**, à l'échelle de la maquette (même nombre de pixels par point, sans déformation ni recadrage) : `emetteur_actif_contre_M5.png`, `emetteur_confirme_contre_M5.png` ; planches bureau contre D1 (#24) : `scanner_lecture_bureau_contre_D1.png`, `saisie_bureau_contre_D1.png`, `emetteur_actif_bureau_contre_D1.png`. | fichiers dans `captures/` |
| R-10 | mineur | **Corrigé.** Texte à 200 % en 390x844 pour le scanner, la saisie (`scanner_saisie_test.dart`) et les appareils d'un élève (`appareils_test.dart`) : aucune exception, action principale et retour touchables, puis touchés. | tests « texte a 200 % » |
| R-11 | mineur | **Corrigé.** `libelleQr` sans position (« Le même code est aussi écrit sur cet écran... ») ; test sémantique à 390 et à 1440. | test « libelle du QR (...) : sans position » |
| R-12 | mineur | **Corrigé.** `appareils.eleve.partage` sans promesse de sécurité (« son propre code personnel, gardé sur cet appareil »). La limite d'essais du pavé reste un besoin COORD (`pin_pad.dart`), déjà consigné. | `fr.i18n.json` |
| R-13 | mineur | **Corrigé.** Clé `appareils.erreur` supprimée, slang régénéré. | diff `f799ade` |
| R-14 | mineur | **Corrigé.** Commentaire de `feuille_appareil_eleve.dart` à jour (scanner là où la plateforme le permet, saisie qui vouvoie). | diff `f799ade` |

Aucun constat refusé.

## 6. Captures

`05_recette/D/captures/` : tous les écrans du lot à 390x844@3 et 1440x900@1, clair et sombre, régénérés après `f799ade` (206 fichiers réécrits). Planches maquette | rendu : `emetteur_actif_contre_M5.png`, `emetteur_confirme_contre_M5.png`, `emetteur_actif_bureau_contre_D1.png`, `scanner_lecture_contre_M3.png` (régénérée), `scanner_lecture_entier_contre_M3.png`, `scanner_lecture_bureau_contre_D1.png`, `saisie_code_contre_E3.png` (régénérée), `saisie_bureau_contre_D1.png`, et celles de LD-3 (`appareils_eleve_contre_profil`, `appareils_foyer_contre_foyer_member`, `appareil_choix_contre_genre`, `appareil_pin_contre_E3`), non régénérées : les écrans téléphone concernés n'ont pas changé de composition (seule l'aide « Code oublié ? » gagne une action). Les fichiers `emetteur_*_contre_M5_capture.png` sont ceux de LD-1 (rendu recadré) et ne servent plus de preuve.
Aucun de ces écrans n'a de maquette propre (manifeste section 2) : les références sont les maquettes approuvées les plus proches (M5 #22, M3 #20, D1 #24, E3 #14, cartes #11, captures de contenu #30 et #33).

## 7. Demandes au coordinateur (`demandes/D.md`)

- D-1 : paire de couleurs dédiée au QR (`app_palette.dart`), contournement sans couleur littérale en place.
- D-2 : `.order('paired_at')` sans `ascending` dans `service_appairage.dart:212` ; les écrans trient eux-mêmes en croissant explicite, testé.
- D-3 : information (paramètre `retour` de l'émetteur), aucun changement demandé.
- À valider (R-08) : pas de mode bord à bord dans `PageShell` ; le scanner téléphone s'arrête à la gouttière.
- Toujours ouvert (consigné en LD-3) : aucun plafond d'essais dans `pin_pad.dart`.

## 8. Défauts hors périmètre consignés (`etat/B.md`, section Lot D)

Commentaire devenu faux dans `test/features/connexion_test.dart` (lot A) et clés `eleveConnexion.entrerCode` / `eleveConnexion.scanner` conservées pour lui ; macOS et Linux déclarés `windows` au serveur ; caméra réelle et zxing web non vérifiés sur appareil ; `?retour=` à passer par la fiche du lot B ; `GroupeReglages` sans pied ; DB-APP-03, DB-APP-05 ; D-2.
Hypothèse, à vérifier sur staging : après « Code oublié ? », le nouvel appairage du même appareil crée une nouvelle ligne d'appareil côté serveur ; l'ancienne reste active tant que le tuteur ne la retire pas, et peut compter dans le plafond (le message de plafond renvoie alors à la page des appareils du profil).
