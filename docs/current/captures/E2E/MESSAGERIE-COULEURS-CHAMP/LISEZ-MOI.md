# Champ d'écriture à rayon fixe (MESSAGERIE-COULEURS, 16/11/2026)

Le directeur (capture, sombre, ordinateur) : le champ grandit avec le texte et devient presque un cercle ; les coins mangent le
début et la fin des lignes. Cause : rayon `AppRadius.full` (999), ramené par Flutter à la moitié de la hauteur : 88 à quatre
lignes en texte ×2.

- `avant/` : `main`. `apres/` : rayon fixe `AppRadius.lg` (24), une ligne garde l'aspect d'une pilule puis le rayon ne grandit plus.
- 1 et 4 lignes, ordinateur sombre 1440 et téléphone clair 390, français et arabe.
- Garde de rendu : `test/core/widgets/champ_saisie_rayon_test.dart` (1, 3 et 6 lignes, 390 et 1440, fr et ar, texte ×2 : aucun
  glyphe hors de la zone arrondie, rayon constant au-delà d'une ligne ; échoue avec `AppRadius.arrondiFull`).
