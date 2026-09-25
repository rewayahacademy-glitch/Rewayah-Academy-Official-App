# LA-4 — Questionnaire par eleve /tuteur/parcours/:eleveId

Preuve de la tache 3/3 (captures et statut). Code : e356cd3, 8c0216b. Captures :
dd82e7f (`test/capture/la4_parcours_capture_test.dart`).

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

## Statut par ecran (captures 390x844 clair/sombre ; 1440x900 fait pour
l'ecran principal seulement — voir "Reste")

| Ecran | 390x844 clair/sombre | 1440x900 | Maquette rapprochee |
|---|---|---|---|
| Bloc accueil | fait | non fait | aucune (composant interne, pas de maquette dediee) |
| Chargement (squelette) | fait | non fait | — |
| Question (age, prenom en contexte) | fait | **fait** | `onboarding mobile 1.png` (03/Age) — gabarit respecte : retour, barre de progression, "Étape n sur N", question, cartes, CTA pilule bas. Ecart : cartes sans icone ronde ni bouton radio explicite (`ChoiceCardGroup` existant, hors perimetre de cette tache 3/3, pas un defaut introduit par LA-4) |
| Offres (ScheduleOption) | fait | non fait | pas de maquette horaires dediee dans le lot |
| Fin d'admission (statut diagnostic serveur) | fait | non fait | aucune maquette dediee |
| Indisponible (PGRST205, 0043 absent) | fait | non fait | — |
| Hors ligne | fait | non fait | — |
| Erreur (Reessayer) | fait | non fait | — |
| Profil introuvable (retour Foyer) | fait | non fait | — |

Fichiers : `C:\RA\pilotage\05_recette\A\captures\la4_*.png` (19 PNG : 9 ecrans
x clair/sombre 390x844, + 1 paire 1440x900 pour l'ecran question).

## Tests et resultats exacts (relance sous verrou, commit dd82e7f)

- `flutter test test/capture/la4_parcours_capture_test.dart` (CAPTURE_DIR
  defini) : **20 tests, All tests passed** (voir sortie du run, VERROU
  03:44:19, duree 16 s, code 0).
- `flutter test test/parcours test/i18n` : deja verts a 8c0216b (49 + 8 tests,
  documente dans `etat/B.md`, non rejoue dans cette tache car aucun fichier de
  `lib/` n'a change ici — seul un fichier de test a ete ajoute).
- `dart analyze --fatal-infos test/capture/la4_parcours_capture_test.dart` :
  No issues found (apres correction de l'import `InterfaceMode` et de
  l'import inutilise `harnais.dart`).

## Reste (definition de "fait" non entierement remplie)

- 1440x900 clair/sombre non captures pour 8 des 9 ecrans (seul "question age"
  les a). Point non couvert par le budget de cette tache (limite de temps
  poste).
- Les autres maquettes de reference (`onboarding Mble.png`, `onboarding Mble
  d.png`, `Onboarding mobile 2.png`, `mobile/tuteur observation mobile
  light.png`) concernent LA-1/LA-2/LA-3, pas LA-4 (aucun ecran du questionnaire
  n'y figure) : aucune planche maquette|capture supplementaire n'etait
  possible pour ce sous-paquet au-dela de la question/age deja rapprochee du
  gabarit d'`onboarding mobile 1.png` (03/Age).
- Ecart visuel note (cartes sans icone/radio) laisse en l'etat : composant
  partage `ChoiceCardGroup`/carte de choix deja utilise par tout le lot A,
  changement hors perimetre de la tache 3/3 (captures et preuve).

Statut retenu sur le tableau : **en_cours** (captures faites pour tous les
etats requis en 390x844 clair/sombre + reachabilite confirmee ; 1440x900
incomplet empeche "fait" au sens strict de la definition).
