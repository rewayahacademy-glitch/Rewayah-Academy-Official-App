# LB-2 : ajout d'un profil eleve (`/tuteur/foyer/ajouter`)

Branche `ui/tuteur-v1-b`, commit `2ccb990` (base cefab7f, LB-1 d8f77c9).

## Ecran livre

`/tuteur/foyer/ajouter` : `lib/features/appareils/ajouter_enfant_page.dart` (branchement a la navigation) rend `lib/features/foyer/formulaire_profil_eleve.dart` (widget du contrat K3). `?pour=moi` reste l'ecran indisponible de LB-1 (`creer_mon_profil_indisponible.dart`, DB-FOY-01).

Statut : UI realisee, branchee au service existant (`portCreationProfilEleveProvider` -> `ServiceAppairage.creerEnfant` -> Edge `creer-profil-enfant`), testee en simulation. Dependances : DB-FOY-01 (moi-meme), DB-FOY-02 (proche adulte), DB-FOY-06 (idempotence), DB-ADM-04 (compte non actif), DB-ADM-05 (bornes et date de naissance : `BornesAge.clientActuelle` 3-18 reste la borne client).

## Carte des fonctions

| Fonction | Ecran unique | Route | Place (gabarit V6 #12 / #14) |
|---|---|---|---|
| Ajouter un profil eleve (entree) | Foyer (en-tete) ; Accueil, Compte, fin d'admission : meme route | `/tuteur/foyer/ajouter` | action d'en-tete du Foyer (LB-1) |
| Choisir pour qui | formulaire, etape 1 | idem | cartes E1 empilees sous la question |
| Proche adulte, moi-meme | formulaire, etape 1 (desactives, expliques) | idem | cartes E1 2 et 3 |
| Prenom, nom, age | formulaire, etape 2 | idem | champs E3 empiles |
| Creer le profil | formulaire, etape 2 | idem | pilule ancree en bas |
| Retour (etape 2 -> 1 sans perte, etape 1 -> Foyer) | formulaire | idem | disque retour de la rangee d'etape |
| Reponse perdue : voir le foyer / reessayer | formulaire, etape 2 | idem -> `/tuteur/foyer` | bloc au-dessus des champs |
| Enchainement vers la fiche | apres creation | `/tuteur/foyer/:eleveId` | - |

## Etats

contenu (etapes 1 et 2), vierge (aucune preselection, action inactive), chargement (envoi en cours, action occupee, champs en lecture seule), erreurs sous les champs, refus du serveur (dossier non valide, age), reponse perdue, hors ligne, compte non actif. Aucun `.order(...)` ecrit ni consomme.

## Planches

`captures/ajout_pour_qui_contre_E1.png`, `captures/ajout_identite_contre_E3.png` (panneaux E1 et E3 decoupes de `onboarding mobile 1.png`, rendu sombre 390). Ecarts restants : ligne de cloche de la coquille au-dessus de la rangee d'etape (COORD, demande B-3) ; pastille 48 au lieu de 67 (V6 §9 propose 48) ; champ age au style de champ du theme (valeur non agrandie). Bureau : colonne centree 560 (V6 §8.13).
