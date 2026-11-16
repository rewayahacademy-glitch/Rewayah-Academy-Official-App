# ENTRETIEN-ATTENTE (directeur, 16/11/2026)

Page « Faisons connaissance » du candidat retenu quand aucun moment d'entretien n'est ouvert :
une phrase dit qu'il n'a rien à faire et que l'académie l'informera ; aucun bouton « Réessayer ».
La notification « retenu pour un entretien » ne dit plus « choisissez votre horaire ».

- `fr_360_aucun_moment.png`, `ar_360_aucun_moment.png` : le vrai écran `EntretienCandidatPage`,
  360 de large, données de test (`entretien_candidat_page_test.dart`, groupe de capture,
  `CAPTURE_DIR=docs/current/captures/E2E/ENTRETIEN-ATTENTE`).
- Limite connue : la phrase d'introduction au-dessus de la carte (« Choisissez un moment... »)
  n'a pas été changée dans ce lot ; elle dit encore de choisir.
- Limite connue : la capture arabe vient du harnais de test, dont la mise en page reste de gauche à droite.
