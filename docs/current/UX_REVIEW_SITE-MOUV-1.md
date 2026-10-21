# SITE-MOUV-1 : direction visuelle, images et mouvement du site public (revue UX)

Lot du 21/10/2026, branche `claude/youthful-davinci-raugwe`. Revue exigée par `DESIGN-GOV-2026-09-26.md` §4.2.

**État :** présent dans le code, testé localement (63 tests du site au vert, inspection navigateur à 1440, 768 et 390 px, clair et sombre). Ni testé sur staging, ni déployé. Le site reste un brouillon (M-20) et reste fermé à l'indexation.

## Demande du directeur

- Un site public « moderne, aéré, structuré et bien animé, comme ceux des grandes agences ».
- S'inspirer d'un pin enregistré (Flowty, objet 3D piloté par le défilement), du modèle Webflow Ostack et du pin favori (Shakuro, construction par étages), sans s'y limiter et sans ressembler à personne.
- Détourer et harmoniser les images du dossier Drive « images du site public » ; l'arche doit être lavande, jamais sombre.
- Ne pas poser toutes les scènes du même côté.
- Un texte qui vend selon les usages du métier, pensé pour le référencement, sans jamais « vendre du vent ».

## Ce qui a été fait

1. **Images.** Les 13 illustrations du Drive sont détourées (BiRefNet), l'arche ramenée au lavande des jetons (Lab), l'intérieur rebouché, l'ombre de contact gardée. Elles sont publiées en WebP à 640, 1024 et 1600 px (`site-public/content/images.json`) et légendées « Illustration ».
2. **Un seul motif : l'arche du symbole** (M-21 : l'arche est le livre, la porte ouverte est l'accès, le cercle est la halqa). La direction de chaque page tient dans `site-public/content/direction.json` : image du haut, côté, couleur du champ, cadre, gabarit, images de section, bande d'image, bande d'appel finale.
3. **Composition.**
   - Le haut des pages alterne droite et gauche d'une page à l'autre.
   - Dans une page, les images de section alternent aussi d'une section à l'autre, en partant du côté opposé au haut de page.
   - Deux pages à image panoramique (« Comment ça marche », « L'académie ») prennent un haut « panorama » : le titre et sa phrase sur une ligne, la scène sur toute la largeur.
   - Les pages légales prennent un haut « document » : le titre traverse la page, la scène reste petite.
4. **Mouvement.** Une couche unique, `site-public/styles/motion.js`, sans bibliothèque :
   - le défilement reste natif ;
   - les scènes lisent la position de la page et posent des variables CSS.
5. **Texte.** Titres réécrits sur les faits publiés. Données structurées `EducationalOrganization` sur l'accueil seulement. Balises Open Graph sur chaque page. Indexation toujours fermée.
6. **Académie.** Une section « Trois spécialistes du Coran » publie le récit des fondateurs, tel que M-21 l'autorise : noms, date, lieu de l'idée, sens du nom et du symbole.

## Contrôle par proposition

| # | Proposition contrôlée | Standard ou source consultée (21/10/2026) | Règle utile | Conclusion | Modification |
|---|---|---|---|---|---|
| D1 | Durées des entrées de section et des titres | Contrat E (`DESIGN-GOV` §E) ; `lib/core/theme/app_mouvement.dart` | Durées gelées ; écart d'échelon 35 ms ; plafond 400 ms ; pas de timing local | Ajustée | Entrées à 220 ms (`navigation`), échelon 35 ms, rang plafonné à 5. Mesuré au navigateur : 360 ms au plus sur l'accueil, 400 ms pour l'ouverture de l'arche du haut de page. Avant correction, la revue critique avait mesuré jusqu'à 890 ms |
| D2 | Courbe accentuée | `app_mouvement.dart` (ThreePointCubic) | Courbes du jeton, pas d'approximation | Ajustée | `cubic-bezier(.2,0,0,1)` s'écartait de 0,166 à t = 0,24. Le site utilise maintenant une fonction `linear()` à 21 points, écart ≤ 0,004, avec repli cubic pour les moteurs qui ne la lisent pas |
| D3 | Déplacements | `app_mouvement.dart` | Translations de 8, 12 ou 16 px seulement | Ajustée | 24 et 40 px ramenés à 16 et 12 px |
| D4 | Mouvement réduit | WCAG 2.2, 2.3.3 ; contrat E | Durée 0, translation 0, contenu complet | Conforme | Aucune scène, aucun découpage de titre, aucune bande d'étages ; tout le contenu est visible et immobile |
| D5 | Sans JavaScript | `SITE_07` ; dossier maître §17.5 | Contenu lisible sans script | Conforme | Les états cachés ne s'appliquent que sous la classe `js`, posée en tête et retirée après 2,5 s si `motion.js` ne s'exécute pas |
| D6 | Défilement | Dossier maître §17.5 | Défilement natif, aucune interception de la souris | Conforme | Aucun Lenis, aucun écouteur de molette ; un seul écouteur `scroll` passif et une boucle `requestAnimationFrame` |
| D7 | Titre découpé ligne à ligne | Revue critique du lot (titre déjà peint qui disparaît puis revient) | Un état caché se pose avant le premier rendu, jamais après | Ajustée | Le titre n'est découpé que si les polices sont prêtes dans les 100 ms ; sinon il reste immobile |
| D8 | Impression | WCAG 2.2, 1.3.2 et usage | Tout le texte s'imprime | Ajustée | Règle `@media print`. Mesuré en mode impression : 0 bloc caché (avant : 44 blocs et 3 863 caractères manquants sur la page Confidentialité) |
| D9 | En-tête qui s'efface en descendant | WCAG 2.2, 2.4.11 (focus non masqué) | Un élément qui a le focus n'est jamais caché | Conforme | L'en-tête revient dès qu'on remonte, dès que le focus clavier y entre (`:focus-within`) et quand le menu mobile est ouvert |
| D10 | Un seul logo visible | `assets/brand/logo/README.md` (un logo par écran) | Jamais deux logos à l'écran | Ajustée | L'en-tête s'efface quand le pied de page se découvre. Mesuré : 1 logo visible au bas de 4 pages |
| D11 | Pied de page en rideau | Ostack (modèle Webflow), adapté | Aucun mouvement ajouté | Conforme | Le pied est collé sous le contenu, qui glisse et le découvre. Réservé aux écrans d'au moins 840 × 820 px, où le pied tient en entier |
| D12 | Images de section bâties par étages | Pin favori Shakuro (5 étages, 30 ms d'écart), adapté au plafond | Plafond 400 ms, échelon 35 ms | Conforme | 5 bandes du fond se retirent de gauche à droite : 220 ms + 4 × 35 ms = 360 ms. Absent en mouvement réduit, absent sans JavaScript, absent à l'impression |
| D13 | Porte de l'accueil (agrandissement au défilement) | Pin Flowty (objet épinglé, piloté par le défilement), adapté sans 3D | Lecture possible pendant l'épinglage ; image nette | Ajustée | Agrandissement maximal ramené de 6× à 4,2×. Attribut `sizes` corrigé (58vw déclaré pour 112vw affiché), le navigateur charge le fichier de 1600 px. Sur les écrans bas, la scène descend pour que le ruban ne passe plus sous la phrase de réassurance |
| D14 | Ordre sur téléphone | `site-public/DESIGN.md` (texte puis preuve) | Le titre d'abord | Ajustée | Le titre de l'accueil est à 146 px du haut à 390 px de large ; il était à environ 475 px, sous l'image |
| D15 | Contrastes | WCAG 2.2, 1.4.3 et 1.4.11 | Texte 4,5:1, graphisme 3:1 | Conforme | Calcul WCAG sur les jetons. Clair : encre sur champ 15,65 ; encre douce sur champ 5,12 ; blanc sur violet 4,81 ; contour sur champ 3,39. Sombre : encre douce sur champ 6,66 ; bouton 7,29 ; contour sur champ 4,24 |
| D16 | Seuils de mise en page | `lib/core/theme/app_gabarit.dart` | Seuils 600, 840, 1200 | Ajustée | Le seuil de 900 px, inventé, devient 840 px partout (CSS, `motion.js`, attributs `sizes`) |
| D17 | Thème sombre | O-05 (ouverte) ; cahier visuel : par défaut, les jetons de l'app | Pas de teinte inventée | Conforme au défaut | Clair par défaut, sombre selon la préférence du système, avec les jetons `LT-THEME` (`#16161E`). O-05 reste ouverte |
| D18 | Texte qui vend | Pratiques commerciales trompeuses (directive 2005/29/CE, annexe I, point 7 : fausse urgence) ; règles M-10 et `mots-rewayah` ; principe islamique de l'interdiction de la tromperie (« Celui qui nous trompe n'est pas des nôtres », Muslim) | Des faits vérifiables, une vraie réduction du risque, aucune urgence ni rareté inventée, aucun témoignage ni chiffre inventé | Conforme | Chaque promesse renvoie à une source publiée : 3 à 5 élèves (`DECISION-TARIFS-2026-10-18.md`), classe ouverte dès 3 inscrits et liste d'attente non facturée, première semaine remboursée (page Annulation), observation de 2 minutes, « à horaire fixe » (`UX_REVIEW_PUB-1.md`). Deux phrases trop fortes ont été corrigées (« l'horaire ne change plus » devient « à horaire fixe ») |
| D19 | Référencement | Guide de démarrage SEO de Google Search Central ; schema.org | Un titre descriptif par page, une description, des données structurées exactes, aucun balisage d'avis sans avis réels | Conforme | Titres et descriptions par page ; `EducationalOrganization` sur l'accueil seulement ; aucun balisage d'avis (testé) ; indexation fermée tant que le site est un brouillon |
| D20 | Images légendées | Cahier visuel C.4 ; manifeste (aucune image inventée présentée comme réelle) | « Illustration » sous chaque image | Conforme | Testé sur chaque page (`test_every_illustration_is_captioned_and_described`) |
| D21 | Logo | `assets/brand/logo/README.md` ; M-25, M-28 | Fichiers officiels, jamais animé, blanc sur fond sombre | Conforme | Copies identiques à l'octet (testé). L'en-tête est exclu des transitions de page. Le logo glisse avec l'en-tête quand celui-ci s'efface, sans changer de forme, de taille ni de couleur : interprétation inscrite en O-15 |

## Inspection finale (skill de direction `design-taste-frontend`, `inspect.mjs`, 1440, 768 et 390 px)

- **0 FAIL sur les 9 pages qui présentent l'offre** : accueil, familles, cours, comment ça marche, tarifs, académie, articles, avis, recrutement.
- **Pages documents et outils** : aide, contact, protection des enfants, les 5 pages légales et accessibilité. Un seul FAIL chacune, « few-pictures » (une image par page), défendu ci-dessous.
- **WARN restants, tous défendus ci-dessous** :
  - aucune vidéo ;
  - marges à 768 px ;
  - texte épinglé sur l'image de l'accueil ;
  - peu de mouvement sur les pages documents.

## Dérogations et exceptions défendues

- **Bouton principal violet plein** au lieu de l'action douce de l'app. Raison : le site pose ses boutons sur des champs lavande où l'action douce (`#DCCAFD`) se confond avec le fond. Inscrit en O-11.
- **Animations liées au défilement** : elles n'ont pas de durée. Elles suivent la position de la page, sans courbe de temps. Inscrit en O-12.
- **Pages légales, aide, contact, protection des enfants et accessibilité.** Une seule image par page, alors que l'inspecteur du skill de direction demande quatre images par page. Ce sont des documents et des outils : des images entre les clauses gêneraient la lecture.
- **Aucune vidéo.** Il n'existe aucune séquence authentique d'un cours ; une vidéo générée ou prise dans une banque montrerait ce que l'académie n'a pas filmé.
- **Marges inégales à 768 px.** L'inspecteur mesure le bord des lignes de texte, alignées à gauche avec une mesure de 60 caractères. Le cadre (en-tête, images, tuiles) tient 24 px des deux côtés.
- **Texte épinglé sur l'image de l'accueil.** C'est la scène de la porte, voulue. La phrase épinglée est `aria-hidden`, car elle est dite ailleurs dans la page.

## Questions ouvertes inscrites au registre

O-10 (arche dessinée en CSS), O-11 (couleur du bouton), O-12 (mouvement lié au défilement), O-13 (les illustrations comme banque d'images), O-14 (le mushaf dans une illustration), O-15 (l'en-tête qui s'efface emporte le logo), O-16 (fond violet en dégradé). O-05 (teinte sombre) reste ouverte.

## Version violette et illustrations animées (21/10/2026, demande du directeur)

**Demande.** Le directeur trouve la version claire « trop féminine ». Il demande :
- un fond violet en dégradé léger, qui crée de la lumière et de l'ombre ;
- des illustrations qui flottent, comme dans les affiches qu'il a envoyées (la mise en page seulement, pas leurs couleurs) ;
- un halo lumineux qui suit la souris ;
- des textes et un logo blancs ;
- un tapis qui bouge doucement et sans fin derrière la mère et la fille ;
- des mains et un Coran qui se rejoignent au défilement.

| # | Proposition contrôlée | Standard ou source | Règle utile | Conclusion | Modification |
|---|---|---|---|---|---|
| V1 | Ambiance violette | Jetons de `app_palette.dart` ; cahier visuel (pas de dégradé) | Aucune teinte inventée | Dérogation demandée par le directeur (O-16) | `direction.json` → `ambiance: violet`. Teintes : `#6538E4` fond, `#8652E6` lumière, `#4E2983` ombre, `#25113F` nuit (pied de page et panneau), `#BA98FB`, `#E8D8FF`, blanc. La version claire reste disponible avec `ambiance: clair` |
| V2 | Contrastes sur le violet | WCAG 2.2, 1.4.3 | 4,5:1 pour le texte | Conforme | Blanc sur `#6538E4` 6,48 ; blanc sur la zone la plus claire (`#8652E6`) 4,81 ; `#4E2983` sur le bouton blanc 10,67 ; `#25113F` sur `#BA98FB` 7,29 (troisième marche des étapes) |
| V3 | Logo | M-25 (logo blanc sur fond sombre) | Fichier officiel blanc | Conforme | L'en-tête utilise `logo-horizontal-white.svg`, et `symbole-white.svg` sur téléphone ; testé |
| V4 | Illustrations flottantes | Affiches de référence du directeur | — | Appliquée | Plus de fenêtre en arche derrière les illustrations : le fond éclairé seul, et une ombre portée dessous. Les puits de lumière du premier essai ont été retirés (l'inspecteur les lisait comme un dégradé décoratif) |
| V5 | Halo qui suit la souris | WCAG 2.2.2 (mouvement autonome) | Un mouvement déclenché par l'utilisateur n'est pas autonome | Conforme | Halo de 960 px, déplacé par `transform`. Souris seulement ; rien sur écran tactile ni en mouvement réduit |
| V6 | Tapis en mouvement continu | WCAG 2.2.2 (pause, arrêt, masquage) | Un mouvement de plus de 5 s, lancé seul, doit pouvoir s'arrêter | Conforme | Onde douce qui court vers la porte : périodes de 7 s et 4,3 s, amplitude d'environ 6 px. Un bouton « Arrêter l'animation du tapis » s'affiche dès que le tapis est à l'écran, et le choix est gardé sur l'appareil. Rien en mouvement réduit ni sans JavaScript |
| V7 | Mains et Coran au défilement | Contrat E ; O-12 | Le mouvement suit la position du défilement, sans durée | Conforme au principe d'O-12 | Les mains de l'élève montent jusqu'au Coran : en haut de page, sur le premier tiers d'écran défilé ; plus bas, sur la demi-hauteur d'écran qui suit l'entrée de l'image. Le livre et les mains de l'enseignant ne bougent pas, pour ne rien inventer derrière le livre |
| V8 | Calques des illustrations | Cahier visuel C.4 (une illustration reste légendée comme telle) | L'image au repos est l'image fournie | Conforme | Le tapis est découpé par couleur. Les mains de l'élève sont séparées par GrabCut, et la zone découverte est bouchée par LaMa. Au repos, fond et calque redonnent l'image publiée : écart moyen de 0,17 sur 255 pour les mains (après le retrait du faisceau, K2), 0 pour le tapis |
| V9 | Pied de page en rideau | — | Le rideau demande un contenu opaque | Retiré en violet | Le dégradé doit rester visible sous le contenu |
| V10 | Inspection | Skill de direction (`inspect.mjs`) | — | 0 FAIL sur l'académie et les tarifs ; « gradient » signalé sur l'accueil et la page familles | Le FAIL « gradient » est la demande du directeur (O-16). WARN « grey-body » : le texte est blanc sur violet à 6,48:1, au-dessus du seuil AA |

## Jury à l'aveugle et comparaison (21/10/2026)

**Méthode.** La grille du skill de direction (`references/critique.md`) : design 40 %, utilisabilité 30 %, créativité 20 %, contenu 10 %, avec ses plafonds. Trois jurés indépendants par tour, sur des captures à 1440, 768 et 390 px. Quatre sites primés, notés avec la même grille, servent de référence.

| | Note | Design | Utilisabilité | Créativité | Contenu |
|---|---|---|---|---|---|
| Tour 1 | 6,07 | 6,33 | 5 | 7 | 6,33 |
| Tour 2 | 6,12 | 6,43 | 5 | 7 | 6,33 |
| Tour 3 | 7,02 | 6,5 | 7,33 | 7,33 | 7,5 |
| Hallow, Endel, Waking Up, Seasats (références) | 6,0 chacun | | | | |

**Plafond de structure.** Le site n'emploie que des illustrations : aucune photo d'élève réel (règle de marque). La grille plafonne alors le design à 6,5. La note la plus haute qu'on puisse viser est d'environ 7,5.

**Corrections après le tour 2.**

| # | Relevé du jury | Correction |
|---|---|---|
| J1 | Légende coupée en « Illustrati » sur l'académie, au téléphone | Le décalage au défilement passe de la scène à son cadre. La légende se place dans la bande, et la grande bande tient dans l'écran sous 840 px |
| J2 | Les liens de l'introduction posés sur la première tuile des étapes (accueil) | L'en-tête des étapes prend sa propre ligne : le titre à gauche, le texte et les liens à droite. Les tuiles suivent dessous |
| J3 | La même illustration deux fois dans une page | Une source par page. Accueil : étapes (`place`, `eleve-enseignante-b`, `adulte-femme`) et panneau (`gros-plan-enseignant`). Cours : méthode (`eleve-enseignante-b`). Familles : profils (`eleve-enseignante-b`) |
| J4 | Écrans presque vides | L'énoncé devient une phrase en grand sur deux lignes : la promesse de rigueur (programme §0). Deux sections de texte qui se suivent sont posées côte à côte en deux champs. Les cartes de prix montent le prix et listent ce qu'il comprend. La pièce lavande de la porte finit par un bas arrondi |
| J5 | Un texte qui sonne comme une spécification | Pages familles, cours, comment ça marche, académie, tarifs, articles et recrutement réécrites à la deuxième personne, sans fait nouveau. Le mot interdit qui restait sur la page Cours est retiré (`mots-rewayah`) |
| J6 | Texte courant petit et léger | Corps à 17 px au téléphone, 18 px vers 1280 px, 19 px en grand |
| J7 | La même promesse répétée six fois sur l'accueil | La promesse « trois séances, le même enseignant » reste en haut de page et dans les prix. Ailleurs, chaque bloc dit autre chose (le tuteur, l'horaire, l'application) |
| J8 | Cartes des étapes (comment ça marche) de hauteurs irrégulières, une seule image | Une image par étape. Les bas s'alignent et les hauts montent d'une marche à chaque étape |
| J9 | Illustrations superposées dans la fenêtre des chapitres | Une seule illustration à la fois : elle change au milieu du passage, avec un fondu de 220 ms |
| J10 | Fragment d'arche et anneau pâle autour de la halqa | Le fragment est retiré, l'anneau du sol aussi (l'ombre sous chaque personne est gardée), et l'image est recadrée sur le cercle |
| J11 | Titres coupés après un article | Espace insécable après les petits mots des titres (`titre_html`). Le découpage des titres en lignes garde cet espace |
| J12 | Énoncé sur quatre lignes au téléphone | Trois lignes à 24 px |

**Tour 3 (dernier tour permis par la grille).** Les trois jurés répondent « presque » à la question du niveau d'une grande agence. Ce qu'ils retiennent : le premier écran et la traversée de la porte sont « de niveau agence ». Ce qui manque encore, selon eux : des pages intérieures qui reprennent trop le même gabarit image et texte. Ils ont corrigé, ou en partie, les douze points du tour 2.

**Corrections après le tour 3.**

| # | Relevé du jury | Correction |
|---|---|---|
| K1 | L'élève et son enseignante (sources 03 et 05) se lisent comme une seule image, vue deux fois dans une page | Cours, méthode : `place`. Comment ça marche, étape 4 : les mains et le Coran. Accueil, étape 3 : `adulte-homme-livre` |
| K2 | Un éclat de lumière lavande sous le Coran, des manches dans une brume | Le faisceau est retiré du calque de fond, ainsi que la trace laissée sous les mains. Au repos, fond et mains redonnent l'image entière à 0,17 sur 255 près (mesuré sur le violet) |
| K3 | Sous l'arrondi de la pièce lavande, la porte agrandie se voit encore | L'arrondi passe sur le disque ; sous lui, le fond de la page |
| K4 | « Le même enseignant » dit cinq fois sur l'accueil | Gardé en haut et dans la pièce seulement. Les cartes de prix listent ce que comprend le prix (encarts du 18/10), le panneau dit « Un programme qui avance » |
| K5 | Coupures « deux / minutes », « 3 à 5 / enfants », « Rewayah / Academy », « Accompagné à / » | Les petits mots se lient au mot suivant, les nombres à leur unité, et le nom de l'académie ne se coupe pas. L'énoncé met une phrase par ligne |
| K6 | Texte courant encore petit et léger | Corps de 18 à 20 px, graisse 500 sur le violet, pied de page à 15 px |
| K7 | Bords gauches dispersés sur l'accueil | Prix, panneau et questions sur les colonnes 1 et 7 ; étapes en trois tiers |
| K8 | Simulateur des tarifs à l'air inachevé | Interrupteurs à la place des cases. Tant qu'un âge manque, le prix publié s'affiche en grand |
| K9 | Accueil au téléphone : pas d'image au premier écran, et la halqa jamais vue | L'illustration passe sous les boutons. La pièce et la halqa forment une bande fixe sous le haut de page |
| K10 | Phrases de bande sans texte dessous | Une ligne d'appui sous chaque phrase, tirée d'un fait publié |

## Vérification des textes, phrase par phrase (21/10/2026)

Chaque phrase visible réécrite a été vérifiée contre les décisions écrites, par des agents indépendants : 355 phrases en tout. Chaque phrase douteuse a ensuite été soumise à deux contre-vérificateurs chargés de lui trouver une source. Corrigé à la suite :

- **Le parcours d'inscription.** La famille ne reçoit pas de « proposition de classe » à confirmer. La direction crée la classe et l'élève y est inscrit. L'application annonce ensuite l'enseignant, puis la date du premier cours (`DECISION-OFFRES-GROUPES-2026-10-09.md`, §3 et §4). Le regroupement se fait sur les jours, l'heure, le public et la langue.
- **Des fonctions pas encore livrées.** Le support affiché pendant la séance et les exercices guidés sont retirés des promesses. Restent les engagements des encarts du 18/10 : compte rendu de l'enseignant chaque fin de semaine, observation de deux minutes par séance, séance annulée par l'académie remplacée.
- **Les encarts du 18/10.** Ils sont publiés tels quels sur les cours, les familles et le recrutement (décision tarifaire, consigne 3), avec une espace insécable avant « $ » et « % ».
- **Le programme.** « Le temps que cela prend dépend de chaque élève » contredisait la décision du 14/10 (une date limite par étape) : la phrase est remplacée.
- **D'autres corrections.**
  - Les monnaies du paiement : euros, livres ou dollars canadiens.
  - « Travail à préparer » au lieu de « travail à reprendre ».
  - « Un enfant ne rejoint jamais un cours sans tuteur » se lisait comme « un adulte assiste au cours » : la phrase dit maintenant qui inscrit l'enfant.
  - Le lien « Lire les avis » renvoyait vers une page encore vide.
- **Questions ouvertes.** Trois points vont au directeur : O-17 (« groupe » dans les encarts), O-18 (la phrase en grand de l'accueil) et O-19 (trois ou quatre inscrits pour ouvrir une classe).

## Hors de portée de l'agent

- `.github/workflows/flutter-deploy.yml` vérifie la présence de 8 fichiers du site, mais pas de `motion.js`. Le garde du dépôt interdit à l'agent d'écrire dans `.github/`. Le test `test_only_approved_public_assets_are_copied` couvre ce fichier côté tests.
- L'outil REA (Reverse Engineer Anything) n'est installé qu'en ligne de commande, dans l'espace de travail de la session. Son inscription comme serveur MCP et comme skill demande une règle de permission du directeur.
