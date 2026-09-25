# LA-3 — Dossier /attente refondu, texte signe (observation), consentements

Sous-paquet 3 du lot A (05_LOTS_PHASE1.md §0/section A). Trois taches :
1/3 code (9a5c3a6, complete en 3439536) ; 2/3 tests de widget par gestes
(e7a3741) ; 3/3 (ici) captures, planches, preuve.

## Ecrans et carte des fonctions

| Ecran | Fichier | Route | Atteignable depuis main.dart |
|---|---|---|---|
| Portail d'attente | `lib/features/dossier/attente_page.dart` | `/attente` | oui (r1_atteignables_efda469.txt) |
| Texte signe (contrat) | `lib/features/dossier/signature_page.dart` (`ContratPage`) | `/attente/contrat` | oui |
| Consentements du compte | `lib/features/consentements/consentement_observation_page.dart` | `/tuteur/compte/consentements` | oui |
| Invite (compte) | `InviteConsentementObservation` (meme fichier) | pose dans `/tuteur/compte` | oui, mais **aucun bouton reel n'y mene encore** depuis `lib/main.dart` (route du coordinateur, A-3) |

Une fonction, un seul endroit : le texte signe (`texte_observation.dart`,
paragraphe d'observation §1 bis-3) n'existe qu'en un point, lu par
`ContratPage` ; les cles `consentement.comment.*` sont lues depuis
`GuardianObservationPolicy` (aucune valeur figee).

## Statut de chaque ecran

- **/attente** : fait. Statut exact + une carte groupee (pieces manquantes),
  UNE action pleine, deconnexion tertiaire visible, retour non applicable
  (portail racine du parcours). Variante `?pour=moi` verifiee par test
  (attente_test.dart) et par le code (3439536).
- **/attente/contrat** : fait. Texte existant conserve + paragraphe
  d'observation, case non precochee, enregistrement par `accepterContrat`.
  Variantes responsable legal / eleve adulte testees par gestes
  (attente_test.dart, groupe « variante eleve adulte »).
- **/tuteur/compte/consentements** : fait cote ecran (lecture, aucune
  acceptation presumee, etats charge/vide/erreur/hors-ligne/deja-signe,
  23505 relu). **Partiel cote acces** : aucun bouton du routeur reel n'y mene
  (A-3, blocage du coordinateur, deja signale en tache 1/3 et 2/3).
- **InviteConsentementObservation** : composant fait, prouve par un test qui
  tape « Lire » depuis un hote isole (hoteRoutant), pas depuis la vraie
  navigation de l'application (meme blocage A-3).

## Tests (gestes depuis la navigation)

`flutter test test/features/attente_test.dart test/features/dossier
test/features/consentements_test.dart test/features/inscription
test/features/dossiers_sans_piece_test.dart --reporter expanded` (deja
lance en e7a3741) : **60/60 verts** (49 dans e7a3741 + 11 de non-regression
dossier/inscription comptees dans ce total). Couvre : case non cochee ne
signe rien ; variante `?pour=moi` depuis `/attente` apres « Moi uniquement » ;
`/tuteur/compte/consentements` (lecture avant tout affichage, squelette,
accepter, 23505 relu, echec ecrit affiche, hors ligne distinct, lecture en
echec, deja signe, Retour tape depuis la navigation) ; invite (tap reel,
invisible si deja signe).

Cette tache (3/3) n'a pas relance la suite complete (limite de temps) ; le
code n'a pas change depuis e7a3741, seul un fichier de test de capture a ete
ajoute.

## Captures

`C:\RA\pilotage\05_recette\A\captures\` (test/capture/la3_dossier_capture_test.dart,
14 captures, `flutter test` : **14/14 verts**) :

- `la3_attente_{390x844,1440x900}_{light,dark}.png` (dossier incomplet)
- `la3_contrat_{390x844,1440x900}_{light,dark}.png` (variante responsable legal)
- `la3_consentements_{390x844,1440x900}_{light,dark}.png` (accord non signe)
- `la3_consentements_signe_390x844_light.png` (deja signe, date affichee)
- `la3_consentements_contre_M6.png` (planche maquette | capture, contre
  `mobile/tuteur observation mobile light.png`)

## Planche contre M6 et ecarts

M6 (`tuteur observation mobile light.png`) est une carte de six ecrans du
parcours d'observation live (Foyer, aperçu, session, etc.), pas un mockup
dedie a la seule case de consentement : le seul panneau pertinent pour LA-3
est celui en bas a droite, « Les visites des parents » (titre, paragraphe,
case « J'accepte ces modalites pour mon enfant », Continuer, Retour).

Compare a ce panneau, le rendu `/tuteur/compte/consentements` reprend le
meme schema (titre, paragraphe explicatif, case a cocher, action pleine,
lien retour) ; les textes exacts different volontairement (le contenu vient
de `GuardianObservationPolicy`/`consentement.*`, pas d'un texte fige repris
du mockup mot a mot) — conforme a 03_DECISIONS §1 ter.1 (le haut-fidelite
fait autorite pour le layout, pas pour le texte fige ni la palette). Aucun
ecart de placement a corriger : ordre titre -> paragraphe -> case -> action
-> retour respecte, carte groupee = un rectangle (03_DECISIONS §1 ter.3).

## Constats hors perimetre (LA-3, tache 3/3)

- A-3 (demandes/A.md) toujours ouverte : aucun bouton du routeur reel ne
  mene a `/tuteur/compte/consentements` depuis `lib/main.dart`. Le tableau
  d'atteignabilite (r1_atteignables_efda469.txt) confirme que le FICHIER est
  atteignable (importe), mais aucune navigation UI n'y conduit encore.
- P2 (directeur) : le texte signe (paragraphe des visites d'observation)
  reste a valider avant toute fusion vers la base.
