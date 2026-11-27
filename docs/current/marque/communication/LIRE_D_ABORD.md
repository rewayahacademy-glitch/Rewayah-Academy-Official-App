# Communication extérieure de Rewayah Academy : où en est le travail

Version du 27/11/2026. Chantier ouvert par le directeur le 27/11/2026 : vidéos, publications, WhatsApp,
imprimables, en vue de trouver des clients. Décisions datées : registre de marque, lignes **M-34 à M-38**.

## Ce qui est décidé (27/11/2026)

- Aucun interdit de style hérité pour la communication (M-34) ; outils gratuits, sans compte (M-35).
- La porte du logo est centrale ; dans une scène en perspective, l'arche tourne sur l'axe vertical pour suivre la route, avec une lumière cohérente (M-36).
- Pas de dégradé sur les affiches ; permis en animation (M-37).
- Praxis acteur, en dialogue avec le directeur filmé ; discret sur les imprimables (M-38).

## Ce qui n'est pas encore décidé

La direction visuelle définitive (trois directions explorées, page de comparaison publiée le 27/11), la voix de
Praxis, les sons à hauteur définie fabriqués sans instrument, un compte par langue ou un seul. Tant que le
directeur n'a pas choisi, aucune compétence de style ni aucun `DESIGN.md` n'est écrit.

## Les fichiers

| Fichier | Contenu |
| :--- | :--- |
| `recherche/A-references-psychologie.md` | Mémoire et actifs distinctifs, BD et animation, références, vidéo courte, stratégie de contenu (sources étiquetées lues, extraits, mémoire) |
| `recherche/B-son-voix.md` | Effets sonores, banques et licences, voix du directeur, voix de Praxis, synchronisation de la bouche |
| `recherche/C-technique-3d-imprimables.md` | Outils 3D sans carte graphique (Three.js retenu), intégration des plans filmés, PDF avec l'arabe |
| `PLANS-A-FILMER.md` | Réglages de tournage et trois épisodes filmables par le directeur |
| `outils/maquettes-2d/` | Générateur des maquettes fixes et des premiers tests de mouvement (Chromium, GSAP, FFmpeg) |
| `outils/scene-3d/` | Maquette Three.js : arche extrudée du tracé officiel, tournée sur l'axe vertical, route, lumière (construire avec `npm i three esbuild` puis `npx esbuild scene.js --bundle --format=iife --outfile=bundle.js`) |
| `outils/son/` | Scripts d'essai : effets procéduraux, voix de synthèse, changement de voix |

Les fichiers de banques de sons ne sont jamais versionnés : la licence Sonniss interdit de les redistribuer.
