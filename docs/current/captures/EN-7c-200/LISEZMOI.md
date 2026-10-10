# Captures de la feuille « Ajuster » du cahier à 200 % de texte (EN-7c-200, EN-7c-MINEURS)

- Date : 04/10/2026. Branche `corrections/enseignant-mineurs-1`.
- Production : `test/features/cahier/captures_en7c_test.dart`, groupe `texte200`, lancé sous le verrou avec
  `CAPTURE_DIR=docs/current/captures/EN-7c-200` (4 tests : 390 et 320 de large, clair et sombre).
- Données de la démonstration : l'élève Nour, devoir précédent « Réviser la sourate 78, versets 1 à 11. ».

## Nommage

| Fichier | Contenu |
|---|---|
| `en7c_cahier_texte200_<largeur>.png` | Le cahier avant d'ouvrir la feuille, thème clair. |
| `en7c_feuille_texte200_<largeur>_pNN.png` | La feuille de Nour par pages qui se chevauchent (le défilement avance de 80 % de la hauteur visible) : p01 en haut, la dernière page au bouton « Enregistrer pour cet élève ». 320 : p01 à p11 ; 390 : p01 à p09. Thème clair. |
| `en7c_feuille_texte200_<largeur>_devoir_saisi.png` | Le devoir saisi, enregistré, la feuille rouverte : la phrase « Vous avez déjà noté ce devoir… ». Thème clair. |
| mêmes noms avec le suffixe `_sombre` | Les mêmes vues en thème sombre (24 images ajoutées par EN-7c-MINEURS). |

## Ce qui a été vérifié

- Chaque image sombre a été ouverte : 320 p01, p08, p11, `devoir_saisi` et 390 p05 relues une à une.
- Aucun mot coupé au milieu ; « Sîn / Sâd (ص / س) » garde sa paire arabe entière ; les titres « Objectif de Nour » et « Devoir de Nour » sont sans label flottant coupé.
- Les pages se terminent parfois au milieu d'une carte (« En progrès », « Tâ / Tâ emphatique ») : c'est la coupe de la page de défilement, reprise en haut de la page suivante, pas une troncature.
- Texte et surfaces lisibles en sombre ; le bouton « Enregistrer pour cet élève » garde son contraste.
- Les images claires sont celles de EN-7c-200, inchangées.

## Hors de ce dossier

- Le contrôle `didExceedMaxLines` (aucun paragraphe tronqué) tourne dans `test/features/cahier/cahier_en7c_test.dart`, à l'ouverture de la feuille et de nouveau après la saisie du long devoir.
- Restent des questions au directeur : la translittération « Hâ / Ḥâ » des lettres ه et ح, et la phrase `enseignant.cahier.travailMaisonSaisi`.
