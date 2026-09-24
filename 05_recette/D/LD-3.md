# LD-3 : Appareil partage et listes d'appareils (lot D, sous-paquet 3)

Commit : `5bd6814` sur `ui/tuteur-v1-d` (base `cefab7f`, apres LD-1 `0fc023d` et LD-2 `2278f0f`). Statut : UI realisee, branchee aux services existants (`profils_du_foyer_v`, `mes_appareils_v`, RPC `revoquer_appareil`, Edge `session-enfant` par jeton d'appareil, coffre et base locale), testee en simulation. Non verifie reellement : retrait et ouverture par jeton sur staging.

## Carte des fonctions

| Fonction | Ecran unique | Route | Place |
|---|---|---|---|
| Voir les appareils du foyer | Appareils du foyer | `/tuteur/foyer/appareils` (et la destination Foyer tant que le STUB du lot B la rend) | UN groupe « Profils eleves » : prenom, appareils actifs nommes, chevron ; explication de l'appareil partage (a droite sur bureau) |
| Gerer les appareils d'un profil | Appareils d'un profil eleve | `/tuteur/foyer/:eleveId/appareils` | ligne du profil dans Appareils du foyer ; fiche eleve (lot B, ligne « Appareils », a relier avec `?retour=`) |
| Retirer un appareil | Appareils d'un profil eleve | idem | bouton « Retirer » dans la ligne de l'appareil, confirmation (feuille ou dialogue bureau) |
| Connecter un appareil | Appareils d'un profil eleve -> emetteur QR (LD-1) | `/tuteur/foyer/appairer/:eleveId?retour=...` | action dominante sous la liste |
| Choisir son profil sur un appareil partage | ELV-01 | `/connexion/eleve` | grille de deux colonnes de cartes (pile a 150 % de texte) |
| Ajouter un 2e eleve sur l'appareil | ELV-01 -> saisie (LD-2) | `/connexion/eleve/code?depuis=profils` | action secondaire sous la grille ; le retour de la saisie ramene au choix |
| Code personnel (creation, saisie) | ELV-01 | `/connexion/eleve` (etat interne, jamais d'URL) | pave `PinPad` sous l'avatar ; « Code oublie ? », « Changer de profil » |

Supprime (une fonction, un seul endroit) : « Ajouter un profil eleve » et « Ajouter un appareil » de l'ancienne liste du foyer (le premier vit au Foyer, le second sur la page du profil) ; la regle « deux appareils, un seul en cours » et le message de limite codee (DB-APP-04, DB-APP-10).

## Etats et preuves

- `test/features/appareils_test.dart` : foyer (contenu, tri par prenom, appareil retire non compte, aucune limite ni compteur, vide avec invitation, chargement, erreur + Reessayer, hors ligne sans donnees, bureau 2 colonnes, navigation profil et retours) ; profil (tri croissant explicite par date de connexion, dates lisibles, retrait confirme -> service -> liste relue -> message DB-APP-03, retrait annule, retrait en attente sans second retrait puis echec dit, hors ligne sans bouton Retirer, vide, trois appareils sans limite, introuvable, chargement puis erreur puis Reessayer, emetteur ouvert avec `retour`, retour valide ou rejete, bureau 2 colonnes) ; test pur du tri.
- `test/features/appareils/appareil_partage_test.dart` (vrai routeur, gestes) : onglet Foyer -> ligne du profil -> Retirer -> confirmer -> disque retour -> Appareils du foyer -> disque retour -> Foyer ; connexion -> « Connecter l'appareil d'un eleve » -> « Saisir le code » -> choix -> carte -> code faux (dit) -> bon code -> ouverture par le jeton du profil ; 2e eleve (Ajouter un profil -> saisie -> retour au choix -> code -> creation deux fois -> connexion sans redemande, empreinte scellee) ; codes differents ; appareil retire (profil, jeton, empreinte oublies, message) ; dernier profil retire (vide -> Saisir un code) ; jeton absent ; refus hors ligne, trop d'essais, echec ; code oublie ; changer de profil ; retours ; texte 200 % en pile ; bureau panneau <= 560 centre.
- `test/features/appareils/emetteur_qr_test.dart` (LD-1) mis a jour : le parcours de navigation passe par la page du profil ; « Voir les appareils » du plafond mene a la page du profil.
- `test/appairage/code_local_test.dart` : vert (le code personnel ne quitte pas l'appareil).

Resultats (poste B, sous verrou) : `flutter test test/features/appareils_test.dart test/features/appareils test/features/eleve_connexion_test.dart test/appairage` : +116 ~211 All tests passed ; non-regression `test/router test/accessibilite test/i18n test/config test/features/connexion_test.dart test/features/compte_galerie_test.dart` : +355 All tests passed ; `dart analyze --fatal-infos lib/features/appareils lib/features/eleve_connexion lib/features/connexion lib/features/_dev test/features/appareils test/features/appareils_test.dart test/features/eleve_connexion_test.dart` : No issues found ; `verifier_jetons` : 423 fichiers, aucune violation ; `dart run slang` regenere ; `graphe_imports -Ref 5bd6814` : `appareils_page`, `appareils_eleve_page`, `liste_appareils_eleve`, `eleve_connexion_page` atteignables ; frontiere `cefab7f...HEAD` (supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets) vide ; aucun STUB du lot D restant (`appareils_eleve_page.dart` remplace).

## Tri

`service_appairage.dart:212` (COORD) lit `mes_appareils_v` avec `.order('paired_at')` sans sens (demande D-2 toujours ouverte). Les ecrans ne dependent plus de ce sens : `appareilsActifsDe` trie en croissant explicite (date, puis id) et `elevesParPrenom` par prenom croissant ; teste avec des donnees rendues dans le desordre.

## Captures (captures/)

`appareils_<etat>_390x844@3_<light|dark>.png` et `_1440x900@1_` pour foyer_{contenu, vide, chargement, erreur, hors_ligne} et eleve_{contenu, vide, chargement, erreur, hors_ligne, introuvable, confirmation_retrait, retire, retrait_echec} ; `appareil_<etat>_...` pour choix, pin, pin_faux, creation, codes_differents, ouverture, hors_ligne, retire, vide.
Planches (sombre, 390 logiques) : `appareils_eleve_contre_profil.png` (ancienne capture « Profil » #33, contenu), `appareils_foyer_contre_foyer_member.png` (#30, contenu), `appareil_choix_contre_genre.png` (cartes #11), `appareil_pin_contre_E3.png` (E3 #14, `onboarding mobile 1.png` x 1194-1656, y 55-839).

Ecarts corriges apres planche : titre du choix et du pave place DANS le panneau sur tablette et bureau (il flottait a gauche du panneau centre) ; consigne « Entre ton code personnel » retiree en saisie (doublon de la consigne parlee du `PinPad`).
Ecarts assumes : « Connecter un appareil » sous le groupe et non dans la carte (le `GroupeReglages` partage n'a pas de pied, COORD) ; pas de pastille « Appareil actuel » ni de nom « iPad de Mariam » (la vue ne rend ni empreinte ni nom ecrivable, DB-APP-05) ; icone profil au lieu de l'initiale en tete de ligne (demande B-1) ; pas de compteurs « 1/2 appareils » (limite non lisible par le tuteur, DB-APP-04) ; le « Retirer indisponible pendant la seance » de l'ancienne capture n'a aucune regle serveur : non reproduit.

## Hors perimetre / constats
Voir `etat/B.md`, section Lot D, sous la ligne LD-3.
