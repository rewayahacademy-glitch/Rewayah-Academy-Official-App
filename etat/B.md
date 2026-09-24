# Avancement du poste B

(aucune ligne pour l'instant)

## Lot D

LD-1 | fait | 0fc023d (ui/tuteur-v1-d) | Emetteur QR /tuteur/foyer/appairer/:eleveId : QR noir sur blanc dans les deux themes, code manuel tabulaire, consigne « Sur l'autre appareil », heure de fin reelle ; etats preparation, code deja valable (aucun code recree en silence), actif, verification, confirme (QR et code retires de l'etat, de l'ecran et de l'arbre semantique), expire, remplace, erreur (plafond, hors foyer, compte, generale), hors ligne ; arriere-plan et reseau : code masque puis reverifie ; mouvement reduit ; bureau en deux colonnes ; port PortStatutCodeAppairage (lib/core/appairage/statut_code_appairage.dart) sur mes_codes_appairage_v, lecture refusee = « Cet ecran ne peut pas confirmer la connexion » (DB-APP-02) | flutter test test/features/appareils test/features/appareils_test.dart : +34 All tests passed (dont parcours nav Foyer -> tap « Ajouter un appareil » -> emetteur -> tap disque retour, vrai routeur) ; non-regression test/appairage test/router/navigation_test.dart test/accessibilite/rtl_echelle_texte_ecrans_test.dart test/i18n test/config : +142 All tests passed ; dart analyze --fatal-infos lib/features/appareils lib/core/appairage test/features/appareils : No issues found ; verifier_jetons : 420 fichiers, aucune violation ; graphe_imports -Ref 0fc023d : appairage_page, emetteur_qr, statut_code_appairage atteignables ; frontiere cefab7f...HEAD vide | 05_recette/D/captures/ (9 etats x 390x844 et 1440x900 x clair/sombre + planches emetteur_confirme_contre_M5, emetteur_actif_contre_M5 ; detail 05_recette/D/LD-1.md)

Constats hors perimetre (LD-1) :
- `lib/core/appairage/service_appairage.dart:212` : `.order('paired_at')` sans `ascending` (fichier COORD, consomme par la liste des appareils, LD-3). Demande dans demandes/D.md.
- `assets/i18n/fr.i18n.json` `connexion.feuilleAppareil.etape3` affirme « valable dix minutes » (duree en dur, DB-APP-04) : a traiter en LD-2 (meme lot, autre sous-paquet).
- `appareils.regle` et `appareils.limiteAtteinte` figent « deux appareils » et « un seul en cours a la fois » (DB-APP-04, DB-APP-10) : a traiter en LD-3.
- DB-APP-02 : le droit select de `authenticated` sur `mes_codes_appairage_v` reste a mesurer sur staging ; sans lui l'ecran affiche honnetement que la connexion ne peut pas etre confirmee (teste en simulation).