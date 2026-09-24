# LD-2 : Scanner camera et saisie du code (lot D, sous-paquet 2)

Commit : `2278f0f` sur `ui/tuteur-v1-d` (base `cefab7f`, apres LD-1 `0fc023d`). Statut : UI realisee, branchee au service existant (Edge `session-enfant` via `ServiceEnfant.appairer`), testee en simulation. Non verifie reellement : camera sur un vrai telephone et un vrai navigateur (aucun appareil ni emulateur sur le poste B), refus serveur sur staging.

## Carte des fonctions

| Fonction | Ecran unique | Route | Place |
|---|---|---|---|
| Entree appareil eleve | Connexion > « Connecter l'appareil d'un eleve » > feuille > « Saisir le code » | `/connexion` puis `/connexion/eleve` (sans profil local : renvoi vers la saisie) | lien discret de la connexion (lot A), feuille du lot D |
| Saisir le code | Saisie du code | `/connexion/eleve/code` | champ unique (E3), action ancree en bas sur telephone, panneau centre sur tablette et bureau |
| Scanner le QR | Scanner | `/connexion/eleve/scanner` | bouton secondaire « Scanner le QR code » sous le champ (absent sur Windows et Linux) |
| Revenir a la saisie depuis le scanner | Scanner | disque retour et « Saisir le code » (zone d'action) | en-tete et bas d'ecran |
| Code personnel apres connexion | ELV-01 | `/connexion/eleve` (profil en `extra`, jamais dans l'adresse) | ecran existant, LD-3 |

La saisie inline de `/connexion/eleve` (moment `saisieCode`) est retiree : une fonction, un seul endroit.

## Etats et preuves (`test/features/appareils/scanner_saisie_test.dart`, `test/features/eleve_connexion_test.dart`)
- Parcours par gestes sur le vrai routeur : connexion -> feuille -> saisie -> « Scanner le QR code » -> QR lu -> code personnel ; disques retour scanner -> saisie -> connexion ; « Saisir le code » du scanner ; saisie tapee -> code personnel.
- Scanner : demarrage (autorisation demandee, viseur monte), lecture, contenu non valide (adresse web dite, jamais ouverte, aucun appel), verification, refus serveur pour les 8 motifs + « Scanner a nouveau », camera refusee -> « Autoriser la camera » -> refus durable (aucun bouton qui ne peut aboutir), occupee, absente, non supportee, erreur ; plateforme sans lecteur (aucun demarrage) ; lectures suspendues apres la premiere detection valide (1 appel, camera arretee) ; reponse tardive apres la sortie ignoree ; arriere-plan (camera arretee) puis reprise (relancee) ; camera rendue a la sortie ; hors ligne ; bureau 1440 en panneau centre <= 560 ; telephone en plein cadre sombre.
- Saisie : vide (action inactive), filtre de l'alphabet serveur (ni I, O, 0, 1 ; 6 caracteres), 8 refus dits sous le champ et effaces a la correction, double envoi bloque, hors ligne, aucun bouton scanner sans lecteur, bureau 1440 en panneau.
- Regles pures : `FormatCodeAppairage.normaliser`, `MotifRefusAppairage` (textes de `0004:671-691`, `:808`, statut 429, `FunctionsFetchException`, `FunctionsHttpException`), `connecterCetAppareil` (jeton range, profil retenu, aucune session ; refus = rien range), plateformes du lecteur.
- « Chargement / contenu / vide / erreur / hors ligne » : demarrage de camera et verification (chargement), lecture et champ rempli (contenu), champ vide (vide), etats camera et refus (erreur), bandeau + phrase + motif horsLigne (hors ligne).

## Decisions a relire
- `ServiceEnfant.appairer` n'ouvre plus la session (plus de `verifyOTP` a l'appairage) : le routeur quittait `/connexion/eleve` avant l'ecriture du jeton (C05 3.1 point 1). La session s'ouvre par le jeton d'appareil apres le code personnel, chemin deja existant (`ouvrirSession`).
- Refus durable : sans `permission_handler`, un deuxieme refus dans la meme visite du scanner est traite comme durable (iOS, macOS et web ne rouvrent plus la fenetre, commentaire de `MobileScannerController.start`). « Occupee » n'est distinguable que sur le web (`NotReadableError`).
- Un code remplace est dit `code inconnu` par le serveur (`deleted_at`, `0004:668`) : un seul message couvre les deux cas.

## Captures (captures/)
`scanner_<etat>_390x844@3_<light|dark>.png` et `_1440x900@1_` pour lecture, demarrage, contenu_invalide, verification, refus_expire, refus_hors_ligne, hors_ligne, camera_{refusee, refuseeDurablement, occupee, absente, nonSupportee, erreur} ; `saisie_<etat>_...` pour vide, code, verification, refus_inconnu, hors_ligne (76 fichiers).
Planches : `scanner_lecture_contre_M3.png` (plein cadre sombre de la salle M3, `tuteur observation mobile light.png` x 985-1342, y 79-593) et `saisie_code_contre_E3.png` (champ E3, `onboarding mobile 1.png` x 1194-1656, y 55-839). Aucun des deux ecrans n'a de maquette propre (manifeste section 2). Ecarts assumes : titre a cote du disque retour (en-tete partage `EntetePage`), etiquette du champ sur le contour (decoration du theme, COORD), action en rayon 12 et non en pilule (pilule reservee a l'admission, 03 section 3.2). La camera n'existe pas sous `flutter test` : le viseur montre son fond et son carre de visee.

## Hors perimetre / constats
Voir `etat/B.md`, section Lot D, sous la ligne LD-2.
