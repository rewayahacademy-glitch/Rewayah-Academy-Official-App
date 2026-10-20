# Rewayah Academy : cahier des charges visuel du Brand Book

Version 1.0 du 19/10/2026. Destinataires : Claude Design, tout designer ou prestataire, tout agent qui
compose un support de marque (Brand Book, document, présentation, réseau social, e-mail, page web).

**Objet.** Formaliser l'identité **existante** et proposer des règles d'application. Ce document ne crée
pas une nouvelle identité, ne redessine rien, ne refond pas l'application et n'ouvre pas un second design
system. Le fond (qui est Rewayah, ce qu'elle dit) est dans `MANIFESTE-MARQUE.md`.

Le document est découpé en quatre parties, à ne pas confondre :

- **A. Existant validé** : fichiers et valeurs décidés, à utiliser tels quels.
- **B. Règles d'utilisation** : règles décidées pour ces éléments.
- **C. Recommandations nouvelles** : propositions à évaluer par le directeur. Elles ne valent pas décision.
- **D. Éléments manquants** : ce qui n'existe pas. On le signale, on ne le fabrique pas.

---

## 0. Ce qu'il ne faut jamais faire

1. Redessiner, simplifier, recolorer hors des trois variantes, animer ou recadrer le logo.
2. Inventer une couleur, une police, un rayon, une ombre ou une valeur d'espacement présentée comme
   officielle. Toute valeur vient de la partie A ; une valeur absente va dans la partie D.
3. Reprendre une identité **périmée** ou **étrangère** :
   - l'ancienne palette « vert islamique `#1B6B5A`, or `#C9A84C`, beige `#F7F5F1` »
     (`docs/archive/2026-09-pre-remise-a-plat/architecture/audit-initial.md`, archivé) ;
   - les « cinq couleurs de marque » de l'ancien `docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md` (rose pâle `#F1E3E4`, taupe `#CCBCBC`,
     crème `#F8F4EE`…), archivées ; le crème ne survit que dans `web/manifest.json` (`background_color`),
     écart connu, pas une couleur de marque ;
   - l'identité de PISI (vert fluor, crème, police Syne) : **autre projet, aucun mélange** (M-12) ;
   - les valeurs du site public (`site-public/styles/site.css`, `site-public/DESIGN.md`) : le site est un
     **brouillon** (M-20).
4. Présenter une maquette, une illustration ou une image générée comme une photo réelle ou une capture
   de production.
5. Poser le logo, le symbole ou une signature dans une page du Coran ou un contenu pédagogique.

---

## A. Existant validé

### A.1 Logo (M-13)

Source unique : `assets/brand/logo/`, fichiers du directeur du 10/10/2026, règles dans
`assets/brand/logo/README.md` (obligatoires).

| Fichier | Usage |
|---|---|
| `logo-horizontal.svg` | Logo principal : en-tête, pied de page, documents, e-mails |
| `logo-vertical.svg` | Couverture, connexion, certificats, zones carrées ou étroites |
| `symbole-plein.svg` | Petit format : avatar, favicon, barre mobile |
| `symbole-contour.svg` | Grand format décoratif seulement, jamais sous 64 px |
| `ornement-plein.svg`, `ornement-contour.svg` | Signature discrète (A.2), pas un décor |
| `icone-plein.svg`, `icone-plein-contour.svg` | Doublon et variante ; préférer `symbole-plein` |

Trois couleurs, un dossier chacune : `violet/` `#8652E6` (couleur de marque), `blanc/` `#FFFFFF`,
`encre/` `#17141F` (impression noir et blanc).

### A.2 Ornement (M-14)

`docs/current/BRAND-ORN-1.md`. Signature discrète à trois ou quatre emplacements, taille « petit » (16),
opacité 0,4, une par support au plus, jamais sur un écran de travail. Pour les supports hors app
(section 7 du fichier) : site, e-mails, PDF, une signature centrée au pied, violet sur fond clair, blanc
sur bande violette, encre en impression.

### A.3 Typographie (M-15)

Source : `lib/core/theme/app_typography.dart` et `pubspec.yaml`. Fichiers et licences OFL dans
`assets/fonts/`.

| Rôle | Famille | Remarque |
|---|---|---|
| Titres latins | **DM Sans** | Variable ; poser `wght` **et** `opsz` (défaut d'`opsz` à 9, trop lâche pour un titre) ; jamais pour des chiffres en colonne (pas de `tnum`) |
| Texte latin, navigation, boutons, **tous les chiffres** | **Plus Jakarta Sans** | Variable, `wght` 200 à 800 ; chiffres tabulaires disponibles |
| Arabe d'interface | **Noto Sans Arabic** | Variable ; RTL, menus, boutons, libellés (`pubspec.yaml`) ; proposé pour la signature arabe (C.6) |
| Arabe de document | **Uthman Taha Naskh** | Documents : Coran hors Mushaf, hadiths, livres, lettres (`pubspec.yaml`) |
| Coran, mise en page du Mushaf | **KFGQPC UthmanicHafs v3.0** | **Uniquement** le texte du Coran, depuis les sources validées de l'app |

Échelle de l'app (px, taille/interligne) : titres 36/44, 32/40, 28/36 (graisse 700), 22/28, 18/26, 16/24
(600) ; texte 16/24, 14/20, 12/16 (400) ; libellés 16/20 (600), 12/16 (500). Interface guidée : ×1,2.
Le mot-marque écrit (« Rewayah Academy ») est toujours plus petit qu'un titre de page.

### A.4 Couleurs (M-16)

**La source fait foi : `lib/core/theme/app_palette.dart`** (dernier changement : commit `4f0286fa`,
17/10/2026). Le tableau ci-dessous est une **copie de lecture** datée du 19/10/2026, pour un outil qui
ne lit pas le dépôt. En cas d'écart, le fichier gagne.

| Rôle (jeton) | Clair | Sombre | Usage |
|---|---|---|---|
| Fond de page (`surfaceCanvas`) | `#F1EFF4` | `#16161E` | Toile |
| Carte, surface (`surfaceRaised`) | `#FFFFFF` | `#272734` | Blocs posés sur la toile |
| Texte principal (`inkStrong`) | `#110E20` | `#F5F2FA` | Titres et corps |
| Texte secondaire (`inkMuted`) | `#655E70` | `#AEB1CE` | Légendes |
| Violet de marque (`surfacePrimary`) | `#8652E6` sur `#FFFFFF` | `#BA98FB` sur `#25113F` | Logo, bande de marque |
| Action dominante (`surfaceActionDouce`) | `#DCCAFD` sur `#110E20` | `#BA98FB` sur `#25113F` | **Une seule par écran ou par page** |
| Accent en texte (`inkAccent`) | `#6538E4` | `#C9AEFF` | Liens, mise en relief |
| Lavis d'accent (`washAccent`) | `#EEE6FA` sur `#4E2983` | `#332643` sur `#E8D8FF` | Encadré discret |
| Filet (`borderHairline`) | `#E3DEE9` | `#32323F` | Séparateurs |
| Page du Coran (`surfaceQuran`) | `#F3EAD9` sur `#1C1D21` | `#2E2417` sur `#F5F1E9` | **Réservé au texte du Coran** |
| États (`pointsStatut`) | succès `#199C55`, attention `#B38000`, alerte `#E0375A` | `#70EE9C`, `#FFB703`, `#F9505E` | Indicateurs, jamais décoratifs |

Principes décidés : thème chrome / violet (K-37), palette calme et presque monochrome, violet de marque
pour la marque et l'action, pas pour remplir des surfaces. Contrastes mesurés par tests : 4,5:1 pour le
texte, 3:1 pour les composants, dans les deux thèmes. Aucun dégradé (logo, ornement, fonds).

### A.5 Formes, espacement, icônes

- Rayons (`app_radius.dart`) : 8, 12, 16, 24, et 999 pour les pastilles. Carte : 16. Bouton principal : 12.
- Espacements (`app_spacing.dart`) : 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Largeur de lecture : 800 ;
  contenu : 1200.
- Icônes : **Phosphor** (régulier et plein) via `lib/core/icons/app_icons.dart`. Aucune autre famille,
  aucun emoji.

### A.6 Actifs réels disponibles

- Captures de l'application : `docs/current/captures/` (177 dossiers de lot) et
  `docs/audit-final/captures/`. Ce sont des **rendus de l'app avec données de démonstration** (noms
  fictifs). Elles se légendent « Capture de l'application, données de démonstration ».
- Ornement en situation : `docs/current/captures/BRAND-ORN-1/`.

---

## B. Règles d'utilisation (décidées)

1. **Fond et couleur du logo** (`assets/brand/logo/README.md`) : fond clair → violet ; fond violet ou
   photo sombre unie → blanc ; impression noir et blanc → encre ; photo chargée ou dégradé → interdit
   (poser une plaque unie ou s'abstenir).
2. **Zone de protection** : 25 % de la hauteur du logo, de chaque côté. **Tailles minimales à l'écran** :
   horizontal 28 px de haut, vertical 56 px, symbole 24 px.
3. **Proportions verrouillées** ; ni rotation, ni miroir, ni ombre, ni lueur, ni contour, ni transparence.
4. **Un seul logo par page ou écran visible** ; deux variantes de couleur seulement sur deux bandes
   distinctes.
5. **Sens de lecture** : en arabe, le logo se place en début de ligne (à droite) mais ne se retourne
   jamais. L'ornement non plus.
6. **Une seule action dominante pleine** par zone ; les autres actions sont secondaires.
7. **Le Coran** : fond `surfaceQuran`, police UthmanicHafs, cadre d'ornement seulement ; jamais le logo.
8. **Accessibilité** : WCAG 2.2 AA visé ; une information n'est jamais portée par la seule couleur ;
   texte réel plutôt que texte dans une image pour toute information décisive (prix, conditions).

---

## C. Recommandations nouvelles à évaluer [PROPOSITION P-07]

### C.1 Direction artistique

Éditoriale, sereine, contemporaine. Elle s'appuie sur ce qui existe déjà : beaucoup de toile claire,
une typographie qui hiérarchise, le violet en accent rare, l'ornement comme seule signature. Trois tests
pour chaque page : la sérénité (respiration, une idée par page), la confiance (des preuves réelles), la
progression (un parcours lisible, des étapes).

À éviter : l'esthétique « logiciel éducatif » générique (illustrations isométriques, mascotte,
dégradés), l'accumulation de motifs islamiques (arabesques, croissants, mosquées de banque d'images),
la sobriété qui devient froide (que des aplats gris sans visage ni geste d'apprentissage).

### C.2 Hiérarchie éditoriale

1. Un titre court en DM Sans, une seule idée.
2. Un paragraphe d'introduction en Plus Jakarta Sans, bénéfice d'abord.
3. Une preuve : capture réelle légendée, règle décidée, ou rien.
4. Une action, si la page en appelle une.

### C.3 Grilles et composition

- Écran et web : reprendre les largeurs de l'app (lecture 800, contenu 1200) et ses gouttières (16 en
  mobile, 24 en tablette, 32 en bureau).
- Documents A4 et Brand Book : grille de 12 colonnes, marges et gouttières prises dans l'échelle
  d'espacement existante, lue en points (marges 48, gouttière 24, respiration de section 64). Texte en
  colonne de 5 à 7 unités, preuve visuelle en regard.
- Pages de couverture : logo vertical centré, une signature au plus, l'ornement en pied.
- Alternance des densités entre sections ; jamais plusieurs blocs de même taille et de même style côte à
  côte (même principe que les cartes de l'app, `DECISION-ENTREE-2026-10-17`).

### C.4 Photographie et illustration

- **Photographie** : seulement des situations réelles d'apprentissage (un enfant à son bureau, un
  enseignant à l'écran, un parent à côté), lumière naturelle, décor domestique simple. Aucun enfant réel
  sans accord écrit du tuteur. Aucune photo de banque d'images présentée comme une famille Rewayah.
- **Illustration ou image générée** : permise si elle est légendée comme telle (« Illustration »). Aucun
  écran d'application inventé dans une illustration.
- **Captures d'app** : la meilleure preuve. Données de démonstration seulement, légende obligatoire,
  aucune retouche du contenu affiché ; inclinaison légère permise sur le web, jamais sur un document de
  référence.

### C.5 Iconographie et langage graphique

Phosphor uniquement, en régulier ; le plein pour un état actif. Schémas institutionnels (parcours de
l'élève, déroulé d'une semaine) en filets `borderHairline`, pastilles aux rayons existants, une seule
couleur d'accent par schéma.

### C.6 Usage des signatures (dépend de O-02)

- Jamais dans le logo ni dans sa zone de protection. Toujours en dehors, alignée sur le début de ligne du
  logo ou centrée sous le logo vertical.
- Française : Plus Jakarta Sans, graisse régulière, couleur `inkMuted` ou `inkStrong`, taille inférieure
  au titre de la page.
- Arabe : Noto Sans Arabic, alignée à droite, même rang typographique que la française quand elle est la
  signature principale du support.
- Une seule signature principale par support (recommandation du manifeste, section 14.4).

### C.7 Exemples de communication institutionnelle à produire

Couverture du Brand Book, page « qui nous sommes », lettre d'accueil d'une famille, attestation des
bases (sans le Coran, avec l'ornement en pied), annonce de recrutement, publication de réseau social
(carré et vertical), signature d'e-mail. Chaque exemple porte la mention « Maquette » tant qu'il n'est
pas validé.

### C.8 Applications numériques

L'app est la référence de l'expression numérique : le Brand Book la **décrit** à partir de captures, il
ne la redessine pas. Le site public sera repris plus tard sur la base de ce cahier (O-05). Les favicons
et icônes PWA viennent du symbole, jamais du logo horizontal.

---

## D. Éléments manquants (à signaler, pas à fabriquer)

| Manque | Conséquence | Qui débloque |
|---|---|---|
| Photographies authentiques avec accords d'usage (O-04) | Le Brand Book montre des captures et des illustrations légendées | Directeur |
| Équivalents d'impression du violet (CMJN, Pantone) | Aucune valeur d'impression officielle ; épreuve à faire par un imprimeur à partir de `#8652E6` | Directeur ou imprimeur |
| Signatures adoptées (O-02) et leur mise en page validée | Les maquettes de signature restent marquées « proposition » | Directeur |
| Origine du nom (O-01) | La page « le nom » s'en tient au sens lexical | Directeur |
| Modèles de documents (lettre, attestation, présentation) | À produire comme maquettes à valider | Claude Design, puis directeur |
| Règle d'écriture du nom en arabe (O-08) | Les supports arabes gardent le nom en latin en attendant | Directeur |
| Style d'illustration décidé | Aucun style n'est imposé ; C.4 en donne le cadre | Directeur |

---

## E. Contrôle de cohérence avant livraison

- [ ] Chaque couleur vient de A.4 et de `app_palette.dart` ; aucun dégradé.
- [ ] Polices : DM Sans, Plus Jakarta Sans, Noto Sans Arabic, Uthman Taha Naskh, UthmanicHafs, et rien d'autre.
- [ ] Logo issu de `assets/brand/logo/`, bonne variante pour le fond, zone de protection, taille minimale.
- [ ] Ornement : au plus une signature par support, jamais derrière un texte.
- [ ] Aucun élément de PISI, du site brouillon ou des archives.
- [ ] Chaque image est légendée : capture de démonstration, illustration, ou photo réelle avec accord.
- [ ] Textes conformes à `mots-rewayah` et au manifeste ; aucune affirmation interdite (manifeste, section 17).
- [ ] Chaque proposition porte la mention « Proposition » ou « Maquette ».
- [ ] Contraste 4,5:1 sur le texte, 3:1 sur les éléments graphiques utiles.

## F. Validation et mise à jour

- Seul le directeur valide. Une validation s'inscrit dans `REGISTRE-DECISIONS-MARQUE.md` avec sa date.
- Un changement de jeton se fait d'abord dans l'app (`lib/core/theme/`), jamais dans le Brand Book.
  La copie de lecture A.4 se met alors à jour dans le même commit.
- Un nouvel actif du directeur entre dans `assets/brand/` et met à jour A.1.

## G. Texte d'amorçage pour Claude Design

À coller au début d'une session Claude Design, avec les fichiers de `assets/brand/logo/`, les polices
de `assets/fonts/` et quelques captures de `docs/current/captures/` :

> Tu mets en page le Brand Book de Rewayah Academy, une académie d'enseignement du Coran en ligne. Tu ne
> crées pas d'identité : tu documentes l'existante. Lis d'abord `MANIFESTE-MARQUE.md` et
> `CAHIER-DES-CHARGES-VISUEL.md`. Le logo se pose tel quel, depuis les SVG fournis. Couleurs : uniquement
> la table A.4. Polices : DM Sans pour les titres, Plus Jakarta Sans pour le reste, Noto Sans Arabic pour
> l'arabe, UthmanicHafs seulement pour un extrait du Coran. Aucune autre valeur. Ce qui manque, tu le
> listes au lieu de l'inventer. Tu marques « Proposition » ou « Maquette » tout ce qui n'est pas validé.
> Aucune signature n'est encore adoptée. Aucun élément d'un autre projet (PISI) ni du site public, qui
> est un brouillon.
