# BRAND-ORN-1 : l'ornement, signature discrète de la marque

Décision du directeur relayée le 11/10/2026 : faire de l'ornement la signature
discrète de la marque, partout, de façon persistante et mémorable, sans gêner.
Cette page est la règle d'usage ; elle complète `assets/brand/logo/README.md`
(qui autorise l'ornement comme « motif décoratif, pas une signature de marque »
et interdit le logo dans une page du Coran). Statut des preuves : règle
spécifiée ici ; application dans l'app et tests locaux dans le lot (voir §6).

## 1. Ce que c'est, et d'où ça vient

- Le dessin est celui des fichiers du directeur
  `assets/brand/logo/violet/ornement-plein.svg` et `ornement-contour.svg`.
- **Même méthode que le logo** : `tool/generer_ornement.dart` recopie les
  attributs `d` mot pour mot dans `lib/core/marque/ornement_traces.g.dart`
  (versionné ; `--verifier` échoue s'il n'est pas à jour) ; le dessin est peint
  par `peindreOrnement` (`lib/core/marque/peinture_ornement.dart`), un
  `CustomPainter` sans asset. Aucun fichier n'est chargé à l'exécution,
  `pubspec.yaml` n'est pas modifié.
- Le contour est livré avec un `<mask>` : sa forme est recopiée aussi, et le
  rendu retire du trait épais la forme pleine, comme le fichier.
- **Un seul point d'entrée** pour un écran : `OrnementMarque` et
  `SeparateurOrnement` (`lib/core/widgets/ornement_marque.dart`). Jamais un
  `CustomPaint` d'ornement recomposé dans un écran, jamais l'ornement chargé
  comme image.

## 2. Où il vit (l'ornement signe, il ne remplit pas)

| Lieu | Forme | Remarque |
| :--- | :--- | :--- |
| Séparateur de section | `SeparateurOrnement` : filet, ornement, filet | à la place d'un `Divider` entre deux blocs de contenu de même rang ; jamais entre deux lignes d'une liste |
| État vide | un ornement contour entre l'illustration et le constat | dans l'écart existant : la hauteur de l'état vide ne change pas ; absent sur la salle en direct (surface inverse) |
| Connexion | un ornement entre le logo et la carte de connexion | dans l'espace de respiration existant ; le logo garde sa zone de protection de 25 % |
| Accueil (élève) | un séparateur entre le bloc principal et le bloc du Coran | dans l'écart existant (20) ; une fois par écran |
| Écran de chargement | un ornement entre la marque et l'indicateur | statique ; l'animation de l'écran de démarrage reste une décision du directeur |
| Page du Coran (MUSHAF-15L) | cadre C : un ornement plein entre deux contours en haut et en bas de la page, cartouche de sourate orné | décision du directeur du 11/10 (« plus c'est simple et moins chargé mieux c'est ») |
| Attestations, certificats | aucun écran de ce type dans l'app aujourd'hui | quand il existera : un ornement plein centré au pied, en encre d'impression sur le PDF |

Un écran porte **au plus un séparateur ornemental visible et un ornement de
signature** : au-delà, l'ornement n'est plus une signature mais un motif de
fond, et la règle du README (« motif décoratif ») ne s'applique plus.

## 3. Taille

Les hauteurs viennent de l'échelle d'espacement (`AppSpacing`), jamais d'une
valeur libre : `petit` 16, `moyen` 24, `grand` 32. Proportions verrouillées
(largeur et hauteur ensemble). L'ornement n'est pas le héros de l'écran : au
plus 32 de haut hors cadre de page ; le cadre du Coran prend 2 % de la hauteur
de la page en haut et en bas (4 % en tout).

## 4. Couleur

- Par défaut, le violet de marque : `BrandLogo.couleur(FondLogo.page)`
  (#8652E6, aussi en thème sombre : 3,58:1 sur `#1A1A25`, au-dessus du 3:1
  d'un élément graphique).
- Sur une bande violette : blanc (`FondLogo.violet`). Impression noir et
  blanc, tampon : encre (`FondLogo.impression`).
- Exception décidée : le cadre du Coran suit le jeton `surfacePrimary.background`
  de la palette (violet de marque au clair, violet clair au sombre), comme
  vu et choisi par le directeur sur les captures du 11/10.
- Jamais de dégradé, d'ombre, de lueur, de contour ajouté, de transparence,
  d'autre teinte de violet. Une seule couleur par ornement.

## 5. Interdits

- **Jamais derrière du texte**, ni sur une photo, ni sur une zone non unie.
- **Jamais le logo, le symbole ni la signature dans une page du Coran ou un
  contenu pédagogique** : l'ornement seulement. Un test lit le cadre du Coran
  et refuse toute référence à `BrandLogo` et aux traces du logo.
- Jamais cliquable, jamais porteur de sens : il est décoratif, retiré de
  l'arbre sémantique (`ExcludeSemantics`).
- Jamais à l'intérieur d'un bouton, d'un champ, d'une carte de cours, d'une
  liste ; jamais répété en motif.
- Jamais animé par défaut ; tout mouvement passe par les durées gelées
  (`AppMouvement`) et s'arrête quand « réduire les animations » est actif.
- Jamais d'effet sur le défilement : un `RepaintBoundary` à lui, repeint
  seulement quand sa taille ou sa couleur change.
- Jamais en arabe retourné par `Directionality` : l'ornement est symétrique en
  usage centré ; posé au début de ligne, il suit `start`, comme le logo.

## 6. Application et preuves

Appliqué dans ce lot, par les composants partagés (jamais écran par écran) :
`EmptyState` (contour petit dans l'écart de 20 entre l'illustration et le
constat, absent si l'état vide porte sa propre encre, donc sur la salle), la
page de connexion (plein petit dans la respiration entre le logo et la carte),
l'écran de démarrage (plein petit dans l'écart de 24 entre la marque et
l'indicateur) et l'accueil de l'élève (`SeparateurOrnement` petit entre les deux
blocs). Aucune hauteur d'écran ne change : l'ornement prend la place d'un écart
qui existait. Les `Divider(` restants (listes, tableaux) ne sont pas touchés :
l'ornement ne sépare pas deux lignes d'une liste.

Aucune attestation ni aucun certificat n'existe dans l'app : rien à poser, la
règle du §2 s'appliquera quand l'écran existera.

Tests : `test/core/widgets/ornement_marque_test.dart` (tailles dans l'échelle,
proportions, couleurs par fond, contraste 3:1, aucun texte ni sémantique,
LTR et RTL de même taille, état vide : ornement présent, absent sur surface
inverse, hauteur inchangée) ; `test/core/marque/ornement_traces_test.dart`
(traces octet pour octet, générateur à jour) ;
`test/core/marque/peinture_ornement_test.dart` (jamais de rotation ni de miroir) ;
`test/widgets/catalogue_galerie_test.dart` (entrée de galerie `OrnementMarque`).
Captures : `docs/current/captures/BRAND-ORN-1/`.

## 7. À appliquer par Codex (hors des zones de Claude)

Ces surfaces ne sont pas dans le périmètre des sessions Claude. Même règle,
mêmes fichiers source (`assets/brand/logo/<couleur>/ornement-*.svg`), mêmes
interdits :

- **Site public** (`site-public/`) : séparateur de section en SVG, violet sur
  fond clair, blanc sur bande violette ; un par section au plus ; jamais
  derrière un texte ni sur une photo.
- **E-mails transactionnels** : un ornement plein centré au pied, en PNG
  exporté depuis le SVG violet (les clients mail ne rendent pas tous le SVG),
  jamais le logo à côté.
- **Documents et PDF serveur** (attestations, reçus, certificats) : ornement
  plein centré au pied, encre d'impression sur fond blanc.
- **Icônes web, PWA et favicon** : inchangées (elles viennent du symbole).
- **Vitrine des offres publiques** : mêmes séparateurs que le site public.
