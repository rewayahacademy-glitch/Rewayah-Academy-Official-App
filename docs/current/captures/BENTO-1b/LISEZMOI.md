# Captures « après » de BENTO-1b : le Centre de commande

- Date : 03/10/2026, 03 h 39.
- Branche `corrections/c2-bento1b`, commit `7079b79` (code de BENTO-1b au commit `5f79925`, plus le test de capture étendu).
- Production : `test/capture/bento_capture_test.dart`, lancé par le verrou avec
  `CAPTURE_DIR=docs\current\captures\BENTO-1b` (9 tests réussis).
- Données fictives : 3 dossiers, 4 demandes, 2 élèves sans enseignant, 1 cahier manquant, 0 incident, 0 accès échu.

## Ce que montre chaque image

| Image | Largeur, texte, thème | Grille des compteurs |
|---|---|---|
| `centre_commande_320_clair.png` | 320 px, ×1, clair | 2 colonnes. « Dossiers à valider » sur toute la largeur, « Demandes à trancher » en tuile haute à gauche, « 2 » et « 1 » empilés à droite, tuile double « Incidents / Accès échus » en bas. |
| `centre_commande_320_sombre.png` | 320 px, ×1, sombre | Même disposition que la version claire. |
| `centre_commande_390_sombre.png` | 390 px, ×1, sombre | 2 colonnes, même disposition qu'à 320 px, libellés sur une seule ligne. |
| `centre_commande_320x2_clair.png` | 320 px, ×2, clair | 1 colonne. Les tuiles ont des hauteurs différentes selon leur contenu ; « Incidents / Accès échus » reste une tuile à deux compteurs. |
| `centre_commande_320x2_sombre.png` | 320 px, ×2, sombre | Même disposition que la version claire. |
| `centre_commande_1440_clair.png` | 1440 px, ×1, clair | 4 colonnes. « Dossiers à valider » sur 2 colonnes, avec les trois noms en attente ; « Demandes à trancher » en tuile haute ; « 2 » et « 1 » empilés ; « Incidents / Accès échus » sur toute la largeur. |
| `centre_commande_1440_sombre.png` | 1440 px, ×1, sombre | Même disposition que la version claire. |
| `centre_commande_1440x2_clair.png` | 1440 px, ×2, clair | 4 colonnes conservées, mêmes tailles variées qu'à ×1, libellés repliés entre les mots. |
| `centre_commande_1440x2_sombre.png` | 1440 px, ×2, sombre | Même disposition que la version claire. |

## Ce qui a été vérifié sur les images

- Aucune image ne montre un damier de tuiles identiques : chaque largeur combine des tuiles larges, hautes et simples.
- Aucun débordement sur les quatre bords et aucune bande jaune et noire.
- Aucun mot coupé dans la grille : les libellés passent à la ligne entre les mots, par exemple « Incidents / (24 h) » et « Accès / échus » à 320 px ×2.
- Hors grille, pour COUPE-MOTS-1 et non compté contre BENTO : à 320 px ×2, le titre de page est coupé en « Centre / de com / mande ».
- À 320 et 390 px, la carte « Comptes » s'arrête au bas de l'image parce que la hauteur de capture est fixe. Ce n'est pas un débordement.
