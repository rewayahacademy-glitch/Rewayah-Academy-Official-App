# LB-3 : fiche eleve et sous-pages (`/tuteur/foyer/:eleveId`)

Branche `ui/tuteur-v1-b`, commit `d7b006f` (base cefab7f, LB-1 d8f77c9, LB-2 2ccb990).

## Ecrans livres

| Ecran | Fichier | Statut |
|---|---|---|
| Fiche `/tuteur/foyer/:eleveId` | `lib/features/foyer/fiche_eleve_page.dart` | UI realisee, branchee (`profils_du_foyer_v` via K1, `PortClassesFoyer` K6), testee |
| Informations `.../informations` | `lib/features/foyer/fiche/informations_page.dart`, `photo_eleve.dart` | branchee (`ServiceAvatar.televerser` seau `avatars` + `majReglages(cleAvatar:)`), testee en simulation ; DB-FOY-07 (prenom non modifiable), DB-ADM-05 (age, naissance) |
| Parcours et inscription `.../inscription` | `lib/features/foyer/fiche/inscription_page.dart` | synthese branchee (`v_parcours_onboarding` 0043 non appliquee en production : phrase honnete, DB-ADM-01 ; classes K6 sans service : DB-TRV-07), renvoie au questionnaire (lot A) et au choix de classe / a la classe (lot C) |
| Interface `.../interface` | `lib/features/foyer/fiche/interface_page.dart` | branchee (`majReglages(mode:)`), testee ; demande de l'eleve DB-FOY-04 ; risque serveur DB-TRV-01 non masque |
| Camera en cours `.../camera` | `lib/features/foyer/fiche/camera_page.dart` | branchee (`majReglages(camera:)`, effet au prochain jeton `0033:1723-1730`), testee |
| Acces Rewayah `.../acces` | `lib/features/foyer/fiche/acces_page.dart` | branchee (`access_until`, `etatAccesAffiche` K6, expire calcule pour l'affichage) ; debut, statut, motif : DB-FOY-05 |

Les six STUB « propriete du lot B » de la fiche sont remplaces. `service_avatar.dart` (lot B) envoie desormais le `contentType` de la photo.

## Carte des fonctions

| Fonction | Ecran unique | Route | Place |
|---|---|---|---|
| Ouvrir la fiche | Foyer, ligne du membre | `/tuteur/foyer/:eleveId` | groupe « Profils eleves » (LB-1) |
| Identite (photo, prenom, classe connue) | fiche | idem | carte d'identite en tete |
| Informations, photo | fiche -> Informations | `.../informations` | 1re ligne des parametres ; photo : bloc de droite (bureau) |
| Changer la photo (choisir, apercu, envoyer, reprendre, annuler) | Informations | idem | bloc Photo (une seule place ; l'ancienne capture la mettait dans l'en-tete de fiche, retiree pour ne pas doubler la fonction) |
| Parcours et inscription | fiche -> synthese | `.../inscription` | 2e ligne |
| Questionnaire | synthese -> lot A | `/tuteur/parcours/:eleveId` | ligne « Questionnaire » |
| Classe / choix de classe | synthese -> lot C | `/tuteur/classes/:id?eleve=` ou `/tuteur/classes/catalogue?eleve=` | ligne « Classe » |
| Interface guidee / standard | Interface | `.../interface` | 3e ligne ; deux cartes a radio |
| Camera en cours | Camera | `.../camera` | 4e ligne ; ligne a interrupteur |
| Acces Rewayah | Acces | `.../acces` | 5e ligne ; ligne a pastille |
| Appareils de l'eleve | fiche -> ecran du lot D (aucun import) | `.../appareils` | groupe « Appareils » (colonne droite sur bureau) |
| Retour | chaque page | fiche -> Foyer ; sous-page -> fiche | disque retour 48 |
| Solde par eleve | place reservee, rien construit | - | ligne ou groupe sous les appareils |

## Etats

Toutes les pages : chargement (squelette, disque retour visible), contenu, erreur (Reessayer relit le foyer), hors ligne, introuvable (identifiant hors foyer, « Retour au foyer »). Photo : trop lourde (refus avant envoi), echec d'envoi (reprise), echec d'enregistrement (reprise sans renvoi du fichier), hors ligne (envoi non pressable, phrase). Interface et camera : echec d'ecriture dit, aucun etat optimiste. Inscription : lecture en cours, parcours illisible, classes indisponibles, sans classe. Acces : sans echeance, en cours, expire.

Tri : aucun `.order(...)` ecrit ; lectures consommees sans `.order` (`profils_du_foyer_v`, trie cote client par K1 ; `v_parcours_onboarding`). Constat hors perimetre : `service_offres.dart:115,125` `.order('ordre')` sans `ascending` (lot A, non consomme ici).

## Tests (sous verrou)

- `flutter test test/features/foyer/fiche_eleve_test.dart` : +28 All tests passed (taps depuis la barre basse : onglet Foyer -> membre -> fiche -> chaque ligne -> sous-page -> disque retour ; Appareils ; questionnaire ; classe ; cartes d'interface ; interrupteur ; actions de photo).
- Non-regression `flutter test test/features/foyer test/router test/accessibilite test/features/reglages_enfant_test.dart test/i18n test/config test/foyer test/features/appareils_test.dart` : +440 ~35 All tests passed.
- `dart analyze --fatal-infos lib/features/foyer lib/core/appairage/service_avatar.dart test/features/foyer` : No issues found.
- `dart run tool/verifier_jetons.dart` : 421 fichiers, aucune violation. `dart run slang` regenere.
- `graphe_imports.ps1 -Ref d7b006f` : fiche_eleve_page, photo_eleve et les cinq pages `fiche/*` atteignables depuis `lib/main.dart`.
- Frontiere `git diff --stat cefab7f...HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme lib/core/router lib/core/widgets` : vide.

## Captures et planches

`captures/fiche_*` : fiche, informations, apercu photo, inscription (classes connues et indisponibles), interface, camera, acces, chargement, erreur, hors ligne, introuvable ; 390x844@3 et 1440x900@1, clair et sombre. Planches : `fiche_mobile_contre_profil.png` (ancienne capture, sombre, contenu), `fiche_mobile_contre_compte_mobile.png`, `fiche_bureau_contre_compte_bureau.png` (rendu des groupes). Ecarts assumes : pas d'age (non enregistre), « Changer la photo » dans Informations et non dans l'en-tete, titre de groupe au-dessus de la surface (composant partage), ligne « Classe » regroupee dans « Parcours et inscription », aucun bandeau « Choix du profil + PIN » (hors perimetre). Les sous-pages n'ont pas de maquette propre : rendus derives (Apparence, Confort visuel, carte Acces du Compte, recapitulatif E6).

## Demandes et constats

- B-4 (demandes/B.md) : rediriger `/tuteur/reglages` vers `/tuteur/foyer` (C6) : photo, camera et interface existent maintenant dans la fiche, l'ancienne page les double.
- Le sujet du commit d7b006f commence par un BOM (message ecrit par Set-Content) : sans effet sur le code, non reecrit (pas de force push).