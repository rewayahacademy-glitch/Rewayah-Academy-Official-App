# LA-4 — Questionnaire par eleve /tuteur/parcours/:eleveId

Preuve de la tache 3/3 (captures et statut). Code : e356cd3, 8c0216b. Captures :
dd82e7f puis 750aab9 (`test/capture/la4_parcours_capture_test.dart`, 1440x900
ajoute pour les 8 ecrans restants).

## Atteignabilite (graphe_imports, -Repo C:\RA\lot-a -Ref dd82e7f)

`lib/features/parcours_offres/parcours_offres_page.dart` et `bloc_parcours.dart`
sont dans les 361 fichiers atteignables depuis `lib/main.dart`
(`r1_atteignables_dd82e7f.txt`). Le bouton qui y mene est `BlocParcours`
depuis `/tuteur/accueil` (test « le parcours s'atteint par un geste depuis
l'accueil, pas par go() », `test/parcours/parcours_offres_test.dart:655-737`,
vert).

## Carte des fonctions du sous-paquet

| Fonction | Fichier | Route |
|---|---|---|
| Bloc d'entree (accueil) | `lib/features/parcours_offres/bloc_parcours.dart` | `/tuteur/accueil` |
| Questionnaire + horaires | `lib/features/parcours_offres/parcours_offres_page.dart` | `/tuteur/parcours/:eleveId` |
| Libelles (n sur N, prenom) | `lib/features/parcours_offres/libelles_parcours.dart` | — |
| Brouillon (retour sans perte) | `lib/core/offres/service_offres.dart` (`BrouillonParcours`, `brouillonsParcoursProvider`) | — |
| Classement panne (indisponible/hors ligne/erreur) | `lib/core/offres/service_offres.dart` (`classerPanneParcours`) | — |
| Fin d'admission -> Foyer | bouton "Ajouter un profil eleve" -> `Routes.tuteurAjouterEnfant` (route seule) | `/tuteur/foyer/ajouter` |

Une seule fonction, un seul endroit : aucune duplication constatee.

## Statut par ecran (390x844 ET 1440x900, clair et sombre)

| Ecran | 390x844 | 1440x900 | Maquette rapprochee |
|---|---|---|---|
| Bloc accueil | fait | fait | aucune (composant interne, pas de maquette dediee) |
| Chargement (squelette) | fait | fait | — |
| Question (age, prenom en contexte) | fait | fait | `onboarding mobile 1.png` (03/Age) — gabarit respecte : retour, barre de progression, "Étape n sur N", question, cartes, CTA pilule bas ; en 1440x900 la question reste en colonne centrale (largeur ~1135px sur 1440, non pleine largeur), conforme V5/V6. Ecart : cartes sans icone ronde ni bouton radio explicite (`ChoiceCardGroup` existant, partage par tout le lot A, hors perimetre de cette tache 3/3, pas un defaut introduit par LA-4) |
| Offres (ScheduleOption) | fait | fait | pas de maquette horaires dediee dans le lot |
| Fin d'admission (statut diagnostic serveur) | fait | fait | aucune maquette dediee |
| Indisponible (PGRST205, 0043 absent) | fait | fait | — |
| Hors ligne | fait | fait | — |
| Erreur (Reessayer) | fait | fait | — |
| Profil introuvable (retour Foyer) | fait | fait | — |

Fichiers : `C:\RA\pilotage\05_recette\A\captures\la4_*.png` (36 PNG : 9 ecrans
x 2 tailles x clair/sombre).

Les autres maquettes de reference (`onboarding Mble.png`, `onboarding Mble
d.png`, `Onboarding mobile 2.png`, `mobile/tuteur observation mobile
light.png` M6) concernent LA-1/LA-2/LA-3 et l'ecran observation du lot D, pas
LA-4 : aucun de leurs ecrans ne figure dans ce sous-paquet, donc aucune
planche maquette|capture supplementaire n'etait possible au-dela de la
question/age deja rapprochee du gabarit d'`onboarding mobile 1.png` (03/Age).

## Tests et resultats exacts

- `flutter test test/capture/la4_parcours_capture_test.dart` (CAPTURE_DIR
  defini, sous verrou, commit 750aab9) : **36 tests, All tests passed**
  (duree 19 s, code 0).
- `flutter test test/parcours test/i18n` : deja verts a 8c0216b (49 + 8 tests,
  documente dans `etat/B.md`, non rejoue ici car aucun fichier de `lib/` n'a
  change dans cette tache — seul le fichier de capture a ete etendu).
- `dart analyze --fatal-infos test/capture/la4_parcours_capture_test.dart` :
  No issues found.
- `graphe_imports.ps1 -Repo C:\RA\lot-a -Ref 750aab9` : `parcours_offres_page.dart`
  et `bloc_parcours.dart` dans les 361 fichiers atteignables depuis
  `lib/main.dart` (`r1_atteignables_750aab9.txt`).

## Reste

Aucun pour ce sous-paquet. Point hors perimetre, deja consigne et a confirmer
par COORD (non traite ici) : la branche debutant (niveau debut_lettres ->
objectif apprendre_a_lire) est une regle appliquee cote client sur une valeur
serveur ; 0043 (regles_academie:548-569) ne rend aucune regle de branchement
explicite.

Statut retenu sur le tableau : **fait** (390x844 et 1440x900, clair et
sombre, pour les 9 etats du sous-paquet ; atteignabilite confirmee ; tests
verts ; ecart visuel mineur assume et documente, hors perimetre).
