# Captures du harnais Flutter (L1 des listes, 01/11/2026)

Ces images ne sont pas des captures R3 du robot sur la pile locale : elles
viennent de `test/capture/listes_classes_capture_test.dart` (vraie application,
vrai routeur, démonstration d'administration de 630 classes fictives, vraies
polices). Elles complètent les captures R3 du dossier parent pour les
combinaisons que le parcours `tool/e2e/l1_listes_classes.mjs` ne joue pas :
arabe (RTL), texte x2, sombre au téléphone, 1366 x 768, et la page après
défilement.

Mesures lues par ce test (première ligne, lignes entières visibles, nombre de
défilements verticaux qui débordent) :

| Vue | Mesure |
| :--- | :--- |
| 1440 x 900 clair, sombre, arabe | y = 112, 12 lignes, 1 défilement |
| 1366 x 768 | y = 112, 10 lignes, 1 défilement |
| 1440 x 900 texte x2 | y = 180, 6 lignes, 1 défilement |
| 390 x 844 clair, sombre | y = 284, 6 lignes, 1 défilement |
| 390 x 844 arabe | y = 286, 7 lignes, 1 défilement |
| 390 x 844 texte x2 | y = 462, 1 ligne, 1 défilement |
| 1440 et 390 après défilement | 1 défilement |
