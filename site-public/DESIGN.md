# Direction visuelle du site public

Statut : brouillon (M-20), pas une référence de marque. Direction posée par le lot SITE-MOUV-1 du 21/10/2026 ; revue, mesures et dérogations dans `docs/current/UX_REVIEW_SITE-MOUV-1.md`. Règles de marque : `docs/current/marque/`.

## Deux ambiances

`content/direction.json`, clé `ambiance` :
- `clair` : fond blanc et lavande, clair ou sombre selon le système ;
- `violet` : l'essai demandé par le directeur le 21/10/2026, en cours. Fond violet en dégradé léger (lumière en haut à gauche, ombre en bas à droite), illustrations qui flottent sans fenêtre, halo qui suit la souris, texte et logo blancs. La dérogation au « sans dégradé » est inscrite au registre (O-16).

## Le motif

Un seul motif : l'arche du symbole (M-21 : l'arche est le livre, la porte ouverte est l'accès, le cercle est la halqa). Les 13 illustrations fournies par le directeur le 21/10 portent déjà cette arche ; elles sont détourées, l'arche ramenée au lavande des jetons, et légendées « Illustration ». Aucune autre forme décorative ; aucun dégradé dans la version claire.

## Valeurs

- Couleurs, rayons, ombres, durées et courbes : les jetons de l'app (`lib/core/theme/`), recopiés dans `styles/site.css` avec leur nom d'origine en commentaire. Clair par défaut, sombre selon le système (jetons LT-THEME, O-05 ouverte).
- Polices : DM Sans pour les titres, Plus Jakarta Sans pour le reste. Polices locales, quatre fichiers.
- Seuils : 600, 840 et 1200 px, ceux de `app_gabarit.dart`.

## Composition

- La direction de chaque page tient dans `content/direction.json` : image du haut et son côté, champ, cadre (`libre` pour le panorama), gabarit, images de section, bande d'image, bande d'appel finale.
- Le haut des pages alterne droite et gauche d'une page à l'autre ; dans une page, les images de section alternent d'une section à l'autre (`alternance()` dans `build_site.py`).
- Trois hauts de page :
  - **scène**, le texte sur 5 colonnes et l'illustration en grand sur 7 ;
  - **panorama**, le titre et sa phrase sur une ligne, l'illustration sur toute la largeur ;
  - **document**, pour les pages légales : le titre traverse la page.
- Une section sans image garde son titre collé pendant la lecture ; deux sections sans image qui se suivent sont posées côte à côte, en deux champs ; une section avec image pose le texte et la scène côte à côte, dès la tablette.
- Une illustration ne revient pas deux fois dans une page.
- Téléphone : le texte d'abord, l'image ensuite.

## Mouvement

`styles/motion.js`, sans bibliothèque. Le défilement reste natif ; les scènes lisent la position de la page et posent des variables CSS.

- Accueil : la porte. On s'approche de la porte au défilement, puis le cercle de la halqa s'ouvre. La pièce éclairée finit par un bas arrondi, en miroir de la bande d'appel.
- Accueil : les chapitres. La fenêtre reste, les illustrations changent, une seule à la fois.
- Entrées des sections : 220 ms, échelon de 35 ms, au plus 400 ms. Les titres de haut de page montent ligne par ligne.
- Images de section : construites par étages, de gauche à droite.
- En-tête : il s'efface en descendant et revient en remontant.
- Illustrations animées, posées en deux calques (`content/images.json`, clé `calques`) :
  - le tapis du chemin ondule sans fin, avec un bouton pour l'arrêter ;
  - les mains de l'élève montent jusqu'au Coran au défilement.
- Pied de page : en rideau (version claire seulement).

Sans JavaScript, en mouvement réduit et à l'impression, tout le contenu est là, immobile. Le logo ne change jamais.
