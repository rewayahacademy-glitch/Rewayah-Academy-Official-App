# SALLE-UX (lot 11, rang 15) : preuves du 06/11/2026

Ce qui n'est pas prouvé, d'abord :

- **UX-011, UX-039, UX-042 : aucune preuve par le robot.** La pile locale a démarré (Supabase,
  LiveKit tiré du miroir `mirror.gcr.io`, Docker Hub refusant l'image en 429), mais le parcours 3
  est rouge : son script cherche « Créer un compte » alors que l'inscription commence maintenant
  par « Pour qui créez-vous ce compte ? ». Sans famille ni élève, pas de tuteur (UX-011, UX-039).
  UX-042 (impasse « Séance terminée » après « Retourner dans la salle ») n'est plus atteignable
  par ce chemin, puisque UX-043 retire « Retourner dans la salle » quand la séance est close.
  Ces trois points sont prouvés par des tests seulement.
- **UX-038, UX-010, FN-018 : tests seulement**, aucune capture.
- Constat relevé, non corrigé : sur la pile locale, la carte du récapitulatif de fin n'affiche
  ni le nom de la classe ni celui de l'enseignant (ligne au livre vide).

## Robot de la pile locale (`robot-1440/`, `robot-390/`)

Script : `robot_salle_ux.mjs` (s'appuie sur `tool/e2e/commun.mjs`), enseignant seul, classe du
parcours 2, FR. Verdict vert aux deux largeurs (`verdict.json`, `journal.txt`).

- `02_..._ux040_enseignant_apres_quitter` : « Vous avez quitté la séance. », ni « Séance
  terminée » ni « Terminée », « Retourner dans la salle » proposé ; à 1440, la barre de
  l'enseignant (Aujourd'hui, Classes, Disponibilités, Profil), plus de rail à part.
- `04_..._ux043_enseignant_seance_close` : séance close en base et salle LiveKit supprimée ;
  « Séance terminée », le cahier est l'action pleine, aucun « Retourner dans la salle », aucune
  pastille « En direct ».

## Rendus de test (`salle_ux_*.png`)

`test/capture/salle_ux_capture_test.dart`, 390 et 1440, FR et AR : UX-039 (Interface guidée
après « Quitter »), UX-040, UX-043. Ce sont des rendus des composants, pas le robot.
