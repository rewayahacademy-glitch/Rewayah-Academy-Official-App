# Captures de la salle, régénérées par les tests

- `k4-*.png` (régénérées le 26/10/2026) : vue enseignant, page du Coran à 1366×768 et
  1920×1080, tableau à 1366×768 (composition à trois panneaux du plan du 26/10) et 390×844
  (téléphone, plein écran K4). Régénérer par
  `CAPTURE_DIR=<dossier> flutter test test/features/salle_test.dart --plain-name "K4"`.
- `salle-1440-*.png` (26/10/2026) : la salle de l'enseignant à 1440×900 au repos, un élève
  déplié, la Bibliothèque dépliée, le focus, la barre d'outils. Régénérer par
  `CAPTURE_DIR=<dossier> flutter test test/features/salle_ordinateur_test.dart --plain-name "1440"`.
  Données de test (présence sans Classe : « Amina » sans titre, aucune photo).
  Testé localement seulement, pas prouvé en production.
- `salle-390-*.png` (26/10/2026, PR B) : la salle de l'enseignant au téléphone à 390×844 :
  au repos (la page et « Commandes »), au toucher (capsule vidéo, pilule), le tiroir sur
  chacun de ses trois onglets (Support, Outils, Séance), la feuille des élèves. Régénérer
  par `CAPTURE_DIR=<dossier> flutter test test/features/salle_telephone_test.dart
  --plain-name "captures 390"`. Mêmes données de test que ci-dessus. Testé localement
  seulement, pas prouvé en production.
