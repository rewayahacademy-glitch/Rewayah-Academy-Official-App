# BRAND-ORN-1 : l'ornement, signature discrète de la marque

Décision du directeur relayée le 11/10/2026 : faire de l'ornement la signature
discrète de la marque, de façon persistante et mémorable, sans gêner : à trois ou
quatre emplacements, petit et à faible opacité, jamais sur un écran de travail.
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
  `OrnementMarque.signature` (`lib/core/widgets/ornement_marque.dart`). Jamais un
  `CustomPaint` d'ornement recomposé dans un écran, jamais l'ornement chargé
  comme image.

## 2. Où il vit : trois ou quatre signatures, pas plus

Précision du directeur (11/10/2026) : « pas partout… discret et subtil, ancrer
sans encombrer ». L'ornement n'est **pas** un séparateur de liste ni un décor
d'écran : c'est une signature, à trois ou quatre emplacements.

| # | Emplacement | Forme | Remarque |
| :--- | :--- | :--- | :--- |
| 1 | Démarrage et accueil de l'élève | `OrnementMarque.signature()` : sous la marque pendant le chargement ; une fois au pied de l'accueil | dans l'écart existant au démarrage ; au pied du contenu, jamais entre deux blocs |
| 2 | Page du Coran (MUSHAF-15L) | cadre C : un ornement plein entre deux contours en haut et en bas de la page, cartouche de sourate orné | décidé par le directeur (« plus c'est simple et moins chargé mieux c'est ») ; seule exception de taille et d'opacité |
| 3 | Fin d'une confirmation (le « reçu ») | `EcranResultat` de ton succès : la signature ferme l'écran | jamais sur une erreur, une attente ni un état hors ligne |
| 4 | Marketing, e-mails, PDF | à appliquer par Codex (§7) | hors des zones de Claude |

Jamais sur un **écran de travail** : listes, formulaires (connexion comprise),
tableaux, états vides, salle en direct, écrans d'enseignant et d'administration.
Un écran porte **au plus une signature**.

## 3. Taille et opacité

- Une seule taille de signature : `petit`, 16 (échelle d'espacement
  `AppSpacing.lg`). `moyen` (24) et `grand` (32) existent pour les cas
  exceptionnels décidés par le directeur, jamais pour décorer.
- **Faible opacité** : la signature se peint à `OrnementMarque.opaciteSignature`
  (0,4), valeur unique fixée dans le composant, jamais choisie écran par écran.
  Elle est décorative : le contraste de texte ne s'applique pas, mais elle ne
  porte aucune information.
- Proportions verrouillées (largeur et hauteur ensemble). Le cadre du Coran
  prend 2 % de la hauteur de la page en haut et en bas (4 % en tout), en
  opacité pleine.

## 4. Couleur

- Par défaut, le violet de marque : `BrandLogo.couleur(FondLogo.page)`
  (#8652E6, aussi en thème sombre).
- Sur une bande violette : blanc (`FondLogo.violet`). Impression noir et
  blanc, tampon : encre (`FondLogo.impression`).
- Exception décidée : le cadre du Coran suit le jeton `surfacePrimary.background`
  de la palette, en opacité pleine, comme vu et choisi par le directeur.
- Jamais de dégradé, d'ombre, de lueur, de contour ajouté, d'autre teinte de
  violet. Une seule couleur par ornement, peinte en une passe.

## 5. Interdits

- **Jamais derrière du texte**, ni sur une photo, ni sur une zone non unie.
- **Jamais le logo, le symbole ni la signature dans une page du Coran ou un
  contenu pédagogique** : l'ornement seulement. Un test lit le cadre du Coran
  et refuse toute référence à `BrandLogo` et aux traces du logo.
- **Jamais inversé** : ni rotation ni miroir (vertical ou horizontal), en LTR
  comme en RTL ; le dessin garde le sens du SVG. Un test espion le vérifie.
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

Appliqué par les composants partagés, jamais écran par écran : `EcranDemarrage`
(l'écart de 24 entre la marque et l'indicateur), l'accueil de l'élève (au
pied du contenu), `EcranResultat` de ton succès. L'état vide, la page de
connexion et les séparateurs de section n'en portent pas : ce sont des écrans
de travail (un premier essai les avait ornés ; retiré sur la précision du
directeur). Aucune attestation ni aucun certificat n'existe dans l'app.

Tests : `test/core/widgets/ornement_marque_test.dart` (tailles dans l'échelle,
proportions, couleurs par fond, signature petite et à l'opacité fixée, jamais
de rotation ni de miroir en LTR et RTL, aucun texte ni sémantique,
confirmation signée et erreur non, état vide non signé) ;
`test/core/marque/ornement_traces_test.dart` (traces octet pour octet,
générateur à jour) ; `test/widgets/catalogue_galerie_test.dart` (entrée de
galerie `OrnementMarque`). Captures, une par emplacement, en clair et en sombre :
`docs/current/captures/BRAND-ORN-1/`.

## 7. À appliquer par Codex (hors des zones de Claude)

Ces surfaces ne sont pas dans le périmètre des sessions Claude. Même règle,
mêmes fichiers source (`assets/brand/logo/<couleur>/ornement-*.svg`), mêmes
interdits :

- **Site public** (`site-public/`) : une signature en SVG, violet sur fond
  clair, blanc sur bande violette, petite et à faible opacité (0,4) ; une par
  page au plus ; jamais derrière un texte ni sur une photo.
- **E-mails transactionnels** : un ornement plein centré au pied, en PNG
  exporté depuis le SVG violet (les clients mail ne rendent pas tous le SVG),
  jamais le logo à côté.
- **Documents et PDF serveur** (attestations, reçus, certificats) : ornement
  plein centré au pied, encre d'impression sur fond blanc.
- **Icônes web, PWA et favicon** : inchangées (elles viennent du symbole).
- **Vitrine des offres publiques** : la même signature que le site public.
