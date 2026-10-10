# Logo Rewayah Academy 2026 : règles d'usage (obligatoires pour tous les agents)

Source unique : ce dossier. Source d'origine : `RA logo 2026/RA logo SVG` (livraison du directeur, 10/10/2026).
Ne jamais redessiner, redessiner "à la main", exporter en PNG pour l'embarquer, ni utiliser un logo trouvé ailleurs.

## Fichiers

Trois dossiers de couleur, mêmes noms dedans. Les SVG sont des aplats à un seul `fill` : changer de couleur = prendre le dossier voulu.

| Fichier | Origine | Usage |
|---|---|---|
| `logo-horizontal.svg` | RA logo horizontal | **Logo principal** : en-tête web, barre de navigation large, pied de page, documents, e-mails |
| `logo-vertical.svg` | RA logo vertical | Écran d'accueil / connexion, splash, couverture, certificats, zones carrées ou étroites |
| `symbole-plein.svg` | RA symbole full color | Petit format : avatar, favicon, barre mobile, filigrane de carte |
| `symbole-contour.svg` | RA symbole outsroke | Grand format décoratif seulement (fond, filigrane très grand, état vide). Jamais sous 64 px |
| `icone-plein.svg` | RA icone full color | Même dessin que `symbole-plein` (doublon livré) : préférer `symbole-plein` |
| `icone-plein-contour.svg` | RA icone full +outsroke | Variante pleine avec contour, grand format |
| `ornement-plein.svg` | RA icone ornement full color | Motif décoratif (arrière-plan, séparateur de section), pas une signature de marque |
| `ornement-contour.svg` | RA icone ornement outsrok | Idem, version contour |

Dossiers : `violet/` (#8652E6, couleur de marque), `blanc/` (#FFFFFF), `encre/` (#17141F).

## Quelle couleur selon le fond (contraste graphique minimum 3:1)

| Fond | Variante |
|---|---|
| Thème sombre de l'app (#1A1A25), surfaces sombres | `violet/` (ou `blanc/` si le violet est déjà très présent à l'écran) |
| Fond clair (#FFFFFF, #F7F6FA) | `violet/` ; `encre/` pour impression noir et blanc, tampon, fax |
| Fond violet de marque, bandeau coloré, photo sombre unie | `blanc/` |
| Photo chargée, dégradé, zone non uniforme | Interdit. Poser le logo sur une plaque unie, ou ne pas le mettre |

Un seul `fill` à changer si une autre couleur du design system devient nécessaire : remplacer `#8652E6` (jamais d'autre teinte de violet, jamais de dégradé, d'ombre portée, de lueur, de contour ajouté, de transparence).

## Placement

- **En-tête web / app bar** : `logo-horizontal`, aligné au début de ligne (gauche en français, droite en arabe RTL : le logo suit le sens de lecture, il ne se retourne jamais). Un seul logo par écran visible.
- **Mobile, barre étroite** : `symbole-plein` seul.
- **Connexion, splash, onboarding** : `logo-vertical`, centré, dans un espace dégagé.
- **Pied de page, documents, e-mails** : `logo-horizontal`, petit, une fois.
- **Jamais** : à l'intérieur d'un bouton, d'un champ, d'une carte de cours, d'une liste ; répété en motif de texte ; sur une photo de personne ; collé à un bord de l'écran ; derrière du texte ; dans un contenu pédagogique ou une page du Coran.
- Le logo n'est pas cliquable sauf en en-tête (retour accueil) ; il porte alors un libellé d'accessibilité ("Rewayah Academy, accueil"). Ailleurs il est décoratif (masqué aux lecteurs d'écran) si le nom de marque est déjà écrit en texte.

## Zone de protection et tailles minimales

- Zone de protection : au moins 25 % de la hauteur du logo (ou du symbole) libre de tout texte, bord, image ou autre élément, de chaque côté.
- Taille minimale à l'écran : `logo-horizontal` 28 px de haut ; `logo-vertical` 56 px de haut ; `symbole-plein` 24 px de haut. En dessous, passer au symbole seul.
- Proportions verrouillées : mise à l'échelle homogène uniquement (largeur ET hauteur ensemble). Ni étirement, ni rotation, ni miroir, ni recadrage, ni lissage qui floute.
- Ne pas mélanger deux variantes de couleur dans le même écran sauf bande de couleur distincte (ex. logo violet en en-tête, logo blanc dans le pied de page sombre).

## Intégration technique (Flutter)

- Les SVG sont déclarés dans `pubspec.yaml` (`assets/brand/logo/violet/`, `blanc/`, `encre/`).
- Les rendre avec un widget SVG vectoriel. **`flutter_svg` n'est pas une dépendance du dépôt** : l'ajouter est une décision à faire valider (voir `docs/current/02`), ne pas l'ajouter dans le dos du directeur. D'ici là, aucun écran n'embarque le logo en dur : demander l'étape.
- Ne jamais coder la couleur du logo en dur dans un écran : passer par un composant unique (`BrandLogo(variante, couleur)`) qui choisit le fichier d'après le thème.
- Le web (`web/`) : favicon et icônes PWA se génèrent depuis `symbole-plein` (violet, marge de sécurité 10 %), jamais depuis le logo horizontal.
