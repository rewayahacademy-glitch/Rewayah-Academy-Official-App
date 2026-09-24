# LD-1 : Emetteur QR (lot D, sous-paquet 1)

Commit : `0fc023d` sur `ui/tuteur-v1-d` (base `cefab7f`). Statut : UI realisee, branchee au service existant (RPC `creer_code_appairage`, vue `mes_codes_appairage_v`), testee en simulation. Non verifie reellement (staging) : lecture de la vue (DB-APP-02).

## Carte des fonctions

| Fonction | Ecran unique | Route | Place |
|---|---|---|---|
| Afficher QR + code d'un eleve | Emetteur QR | `/tuteur/foyer/appairer/:eleveId` | colonne centree (M5) ; bureau : QR a gauche, consigne et code a droite |
| Entree (REMPLACEE en LD-3, voir RAPPORT.md section 2) | ~~Foyer > ligne eleve > « Ajouter un appareil »~~ : bouton et cle supprimes en LD-3. Entree actuelle : Appareils d'un profil eleve > « Connecter un appareil » | `/tuteur/foyer/:eleveId/appareils` vers `/tuteur/foyer/appairer/:eleveId?retour=...` | action sous la liste (`appareils_eleve_page.dart`) |
| Regenerer un code | Emetteur QR (etats expire, remplace, deja valable) | meme route | action dominante de l'ecran resultat |
| Retour | disque retour 48 de l'en-tete | `retour` valide sinon `/tuteur/foyer/appareils` | en-tete |

## Etats et preuves (test/features/appareils/emetteur_qr_test.dart)
preparation (squelette, aucun faux QR) ; actif ; deja valable (aucun code cree sans geste) ; verification (retour d'arriere-plan) ; confirme (QR et code absents de l'arbre semantique) ; expire ; remplace ; erreur plafond / generale ; hors ligne (avec et sans code) ; suivi indisponible (DB-APP-02) ; mouvement reduit ; bureau 1440.
« Validation en cours cote appareil » n'est pas detectable (le serveur ne le signale pas, C05 §4) : non simule.

## Captures (captures/)
`emetteur_<etat>_390x844@3_<light|dark>.png` et `emetteur_<etat>_1440x900@1_<light|dark>.png` pour actif, preparation, hors_ligne, confirme, expire, remplace, deja_actif, plafond, erreur.
Planches : `emetteur_confirme_contre_M5.png`, `emetteur_actif_contre_M5.png`. L'emetteur n'a pas de maquette propre ; reference approuvee la plus proche = ecran resultat M5 (manifeste §2), panneau decoupe de `tuteur observation mobile light.png` (x 590-947, y 612-1005). Ecart assume : en-tete avec disque retour conserve (retour visible obligatoire sur une tache focalisee). Ecart corrige : double cadre du QR sur bureau retire ; QR borne a 256 sur telephone.