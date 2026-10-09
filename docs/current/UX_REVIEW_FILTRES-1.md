# FILTRES-1 et FILTRES-1b : rangée unique de filtres (revue UX, DESIGN-GOV §4.2)

Étapes FILTRES-1 (branche `corrections/c2-filtres`) et FILTRES-1b (branche
`corrections/c2-filtres-b`, réserves de la relecture `REVUE_FILTRES-1-R.md`).
Règle permanente DIR-REP-1 : aucune question au directeur ; chaque choix ci-dessous est
**décidé par délégation le 09/10**, selon la recommandation de la relecture ou l'option la
plus prudente.

Statut : présent dans le code, testé localement. Ni staging, ni déploiement.

## Sources consultées et date

Consultation le 09/10/2026.

| Source | Accès | Usage |
| :--- | :--- | :--- |
| Material Design 3, « Chips, guidelines » (m3.material.io) | **inaccessible** depuis la machine (résolution DNS refusée, `ENOTFOUND`) : non relue ce jour, rien n'en est cité | aucun |
| W3C, WCAG 2.2, « Understanding 1.4.10 Reflow » (w3.org) | **inaccessible** (même cause) ; la règle est citée de la spécification déjà reprise dans `03_DESIGN_SYSTEM_ET_UX.md` (320 px, texte x2) | critère 1.4.10 |
| Nielsen Norman Group, « Horizontal scrolling » (nngroup.com) | **inaccessible** (même cause) : non relue ce jour, rien n'en est cité | aucun |
| SDK Flutter 3.47.6 installé, `packages/flutter/lib/src/material/scrollbar.dart` | lu localement | couleur par défaut d'une barre de défilement Material |
| `docs/current/03_DESIGN_SYSTEM_ET_UX.md` et `lib/CLAUDE.md` | lus | règles du dépôt (filtres à côté du contenu, une seule `RangeeFiltres`, 320 px texte x2 sans mot coupé) |
| `docs/current/DESIGN-GOV-2026-09-26.md` | lu | format de cette preuve, jetons seulement |

Faute des sources web, les conclusions s'appuient sur les règles écrites du dépôt et sur le
code du SDK. Une relecture des trois pages web reste à faire quand le réseau le permettra ;
elle ne bloque pas le lot, car aucune règle ci-dessous n'en dépend seule.

## Propositions contrôlées

### 1. Une seule rangée de filtres qui défile, jamais un `Wrap` de puces

- **Règle utile.** `03` : « les filtres à côté du contenu » ; `lib/CLAUDE.md` : un filtre est
  une `FilterPill` posée dans **une seule** `RangeeFiltres`. WCAG 1.4.10 : à 320 px, le
  contenu se lit sans défilement en deux dimensions, **sauf** les parties dont l'usage
  exige une mise en page en deux dimensions ; une rangée de commandes qui défile seule
  sur un axe, la page défilant sur l'autre, reste dans la règle tant que chaque libellé
  est entier et atteignable.
- **Conséquence concrète.** Avant : 2 à 6 lignes de puces à 320 px texte x2, qui
  repoussaient la liste hors de l'écran. Après : une rangée, puces de même hauteur,
  libellés jamais coupés en milieu de mot.
- **Conclusion : conforme.** Contrôle automatique ajouté (FILTRES-1b) :
  `dart run tool/verifier_revue.dart --regle=wrap-filtres` ; un choix de formulaire en
  `Wrap` se déclare par un commentaire « Choix de formulaire, pas un filtre : <raison> ».
  Total de `verifier_revue` inchangé (1533).

### 2. Le signal « il y a d'autres filtres »

- **Règle utile.** `03` / `RangeeFiltres` : rien de caché sans le dire. Sur ordinateur, la
  molette ne fait pas défiler une rangée horizontale : il faut une barre qu'on tire. Le
  SDK Flutter colore par défaut une barre Material à partir de `onSurface` (gris), pas de
  la couleur d'accent : une barre d'accent n'est pas l'usage de la plateforme.
- **Constat de la relecture.** Le curseur violet, posé juste sous les puces, se lisait
  comme le soulignement d'un onglet actif : la sélection devenait ambiguë.
- **Modification (FILTRES-1b).** Barre **neutre** : piste visible sur toute la largeur
  (`borderHairline`) et curseur gris (`borderStrong`), épaisseur `AppSpacing.xs`, jetons
  seulement. La puce retenue (fond et bord d'accent) reste la seule marque de sélection.
  Le fondu de bord est gardé : il dit la suite sur téléphone, la barre la dit et se tire
  sur ordinateur.
- **Choix entre les deux options de la consigne** (barre discrète ou retrait de
  `thumbVisibility`) : barre discrète gardée, décidé par délégation le 09/10. Option la
  plus prudente : le fondu seul ne se tire pas à la souris, la retirer aurait rendu des
  filtres inatteignables sur ordinateur sans clavier.
- **Conclusion : ajustée.**

### 3. Ouverture quand le filtre retenu n'est pas le premier

- **Règle utile.** Le filtre en cours doit se voir à l'ouverture, et le début de la vue ne
  doit pas montrer un libellé coupé.
- **Constat.** La rangée se centrait sur le filtre retenu : la première puce visible était
  coupée au milieu de son libellé (Qualité, Journal).
- **Modification (FILTRES-1b).** La rangée défile du moins possible ; si elle doit défiler,
  la vue s'arrête **au début d'une puce**, placée juste après le fondu d'avant, et la
  puce retenue se voit entière hors des fondus. Si tout tient sans défiler, rien ne bouge
  (la première puce reste au bord). Un filtre nouvellement retenu (personne choisie dans
  Observations) est amené dans la vue de la même façon.
- **Conclusion : ajustée.** À 320 px texte x2 sur Qualité, « Toutes » et « Ouvertes » ne
  tiennent pas ensemble : la vue commence à « Ouvertes », le seul bord de « Toutes » reste
  sous le fondu pour dire qu'une puce précède, sans lettre coupée.

### 4. Observations (admin) dès 600 px

- **Constat.** Un tuteur ou un élève retenu formait une seconde rangée de puces sous les
  menus.
- **Modification.** Dès 600 px, menus et personnes retenues sont dans **la même**
  `RangeeFiltres`, à côté de la recherche (captures 1024 texte x1 et 1440 texte x2).
- **Conclusion : ajustée.**

### 5. Aucun mot coupé à 320 px texte x2 (Observations, Qualité, écrans à liste)

- **Règle utile.** `03` et lot COUPE-MOTS : à 320 px texte x2, en LTR comme en RTL, aucun
  mot n'est coupé ; la page défile au lieu de déborder.
- **Constats.** Observations : « Fatoumata » et « 23/09/2026 » coupés. Qualité : plantage
  de la liste dès qu'une anomalie est ouverte (hauteur non bornée), à 320 x2 et
  1440 x2. Comptes, Classes, Évaluations, Programmes, Progression : à 320x568 texte x2,
  plus de hauteur pour la liste sous l'intro et la rangée.
- **Modifications.** Observations : la ligne empile date et noms quand un mot ne tiendrait
  pas ; noms composés avec trait d'union insécable. Qualité : chaque groupe d'anomalies
  est une section de la liste de la page. Écrans à liste : colonnes de corps avec un
  minimum lisible commun (`DataCollection.minimumLisible`), la page défile.
- **Conclusion : ajustée.** Tests à 320x568, 320x640, 390x844 texte x2, LTR et RTL, et
  Qualité à 320 et 1440 texte x2 avec anomalies ; contre-épreuves faites sur l'ancien code.

## Dérogations

Aucune. Hors lot, constaté sur les captures RTL : en sens forcé de droite à gauche, les
heures et durées françaises s'affichent en ordre bidirectionnel inversé (« 18:14 - 18:12 »,
« min 2 ») ; c'est un artefact d'une chaîne française dans une vue RTL, pas un mot coupé,
déjà antérieur au lot.

## Preuves

Captures : `docs/current/captures/FILTRES-1b/` (320 px texte x2 LTR et RTL, 390, 1440,
sombre, Interface guidée, Observations avec personnes retenues à 1024 texte x1 et 1440 texte x2) ; script
archivé `filtres1b_capture_test.dart.txt`.
