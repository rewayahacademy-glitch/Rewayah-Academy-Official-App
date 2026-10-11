# Captures des modes « Lecture agrandie » et « Focus » (MUSHAF-MODES)

Page 293 (sourate 17, versets 105 à 108), mise en page de Médine, thèmes clair et sombre.

- `avant_*` : état de `claude/mushaf-15l` @ `001a325e` (branche `claude/mushaf-15l-captures`).
- `apres_*` : cette branche (`claude/mushaf-modes`). Crédits hors de l'écran, ni barre ni compteur,
  flèches symétriques à 1440, menu et réglage de taille en en-tête, texte en UthmanicHafs, plus de
  note de zoom borné, focus hors classe sans phrase d'aide.
- `agrandie_1440_max_*` : zoom maximal de la colonne (« Agrandir » grisé).
- Le texte vient du jeu de la mise en page de l'édition (UthmanicHafs v3.0, riwaya Hafs), servi par
  un corpus de test, pas du corpus Tanzil de la base.
- Script : `test/capture/mushaf_modes_capture_test.dart` (saute sans `CAPTURE_DIR`).
