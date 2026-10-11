# Captures des modes « Lecture agrandie » et « Focus » (MUSHAF-MODES)

Page 293 (sourate 17, versets 105 à 112 environ, puis 18:1 à 4), mise en page de Médine.

- `avant_*` : état de `claude/mushaf-15l` @ `001a325e` (branche `claude/mushaf-15l-captures`).
- `apres_<mode>_<largeur>_<zoom>_<thème>.png` : cette branche (`claude/mushaf-modes`), mode
  `agrandie` ou `focus`, largeur 1440 ou 390, zoom `100` ou `max` (400 %, que la colonne tient ou
  non), thème `clair` ou `sombre`. Texte KFGQPC en UthmanicHafs, texte continu, rosace en ligne,
  interligne fixe de 2 fois le corps, alignement à droite, crédits hors de l'écran, ni barre ni
  compteur, flèches symétriques à 1440, menu et réglage de taille en en-tête.
- `*_sans_police.png` : la même page quand UthmanicHafs manque : texte Tanzil simple, police arabe de
  l'application, jamais le texte KFGQPC en police générique.
- Les captures `apres_*` sont prises avec le pubspec de Codex (`e2625561`) fusionné **en local
  seulement** (merge abandonné ensuite) ; il n'est pas dans cette branche.
- Le texte vient du jeu de la mise en page de l'édition (UthmanicHafs v3.0, riwaya Hafs) ; le texte
  « Tanzil simple » des captures sans police est ce même jeu privé des signes propres à l'écriture
  uthmanie, comme le serait le corpus de la base (non atteint hors ligne).
- Script : `test/capture/mushaf_modes_capture_test.dart` (saute sans `CAPTURE_DIR`).
