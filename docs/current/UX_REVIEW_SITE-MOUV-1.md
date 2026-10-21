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
| V6 | Directeur (21/10) : « Tu commences à introduire subtilement les arrières plans derrière les objets alors que tout devait flotter », puis : « [le sol] était là depuis le début, ce n'est pas un arrière plan » | Le panneau lavande ajouté derrière la classe vue du dessus (V2) est retiré ; les objets dessinés ne sont plus posés sur un disque ajouté. Le sol lavande des détails en cercle et en arche, présent depuis le début, reste. Les étapes de l'accueil et les cartes de Comment ça marche gardent leurs tuiles (choix du directeur) |
| V7 | Tarifs : le cercle du haut coupe une tête ; Familles : un tiers du cercle « Suivre le parcours » est la tranche de l'arche | Recadrés dans la scène d'origine : l'élève entière devant son pupitre (450 px) ; l'enseignante et la porte, sans le pilier (404 px) |
| V8 | Accueil : « Un horaire fixe, une classe stable. » commence 130 px plus bas que son paragraphe | Le titre et le paragraphe partent de la même ligne |
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
- **La phrase en grand de l'accueil.** Les deux contre-vérificateurs ont lu « Seul, on remet à demain » comme un reproche (manifeste §16.6). Elle devient « Votre classe commence à l'heure. Vous ne tenez plus le rythme seul. », formulation proposée (O-18), assez courte pour tenir sur une ligne au téléphone.
- **Questions ouvertes.** Trois points vont au directeur : O-17 (« groupe » dans les encarts), O-18 (la phrase en grand de l'accueil) et O-19 (trois ou quatre inscrits pour ouvrir une classe).
- **Bilan.** 355 phrases vérifiées, 37 doutes. 33 sont confirmés par les deux contre-vérificateurs, et les 33 sont corrigés. Les 4 doutes qu'un seul contre-vérificateur a retenus sont corrigés aussi.

## Relecture du code (21/10/2026)

Trois relecteurs indépendants ont relu le diff du site depuis le commit du simulateur :
- le Python et la construction du site ;
- le CSS et le JavaScript ;
- l'accessibilité.

Chaque défaut signalé a été soumis à deux contre-vérificateurs. Ils en ont confirmé 11 et partagé 1 ; les 12 sont corrigés :

- **Prix.** Les encarts de la décision suivent la politique affichée. Si la base publie d'autres prix, d'autres âges ou d'autres tailles de classe, les mêmes phrases reprennent ses valeurs, paie comprise. Un test le vérifie.
- **Âge adulte.** Dans la FAQ de l'accueil, il vient de la politique affichée, comme sur les cartes de prix.
- **Blocs insécables des titres.**
  - Ils tiennent en 18 signes au plus : à 320 px, le titre du recrutement débordait de l'écran (WCAG 1.4.10).
  - Un test le vérifie.
- **Débordements à 320 px.** Les adresses e-mail passent à la ligne ; le titre de la bande d'appel ne déborde plus.
- **Mise en page.**
  - Le cercle des chapitres reste rond sur un écran bas.
  - En remontant, la porte agrandie ne réapparaît pas dans les coins arrondis.
  - La bande de la halqa est cachée à l'impression.
- **Accessibilité.**
  - Les interrupteurs du simulateur restent lisibles en contraste élevé (`forced-colors`).
  - Les légendes des étapes prennent la couleur du texte de leur carte : 2,11:1 avant, 4,5:1 au moins après.
  - « 55 $ » est suivi d'une vraie espace dans la zone annoncée.
  - La bande de la halqa n'est plus cachée aux lecteurs d'écran sur téléphone.

Inspection après ces corrections :
- **Les 10 pages qui présentent l'offre** : 0 FAIL.
- **Les 8 pages documents** : un seul FAIL chacune, « few-pictures », défendu plus haut.
- **Débordement horizontal** : aucun à 320, 360 et 1440 px. Tests : 64, OK.

## Recettes face à deux sites faits par des agences (21/10/2026)

**Méthode.** Trois jurés indépendants notent, avec la même grille et ses plafonds, Rewayah et deux sites de référence faits par des agences : Hallow (application de prière) et Waking Up (application de méditation). Chacun répond aussi à la question du directeur : Rewayah se lit-il comme le travail d'une grande agence, au niveau de ces deux sites ?

| | Rewayah | Hallow | Waking Up | Réponse des trois jurés |
|---|---|---|---|---|
| Recette 1 | 7,12 | 6,17 | 6,17 | « presque » |
| Recette 2 | 7,1 | 6,27 | 6,33 | « presque » |
| Recette 3 | 6,5 (7,1 à 7,5 sans plafond) | 6,5 | 6,5 | « presque » |
| Recette 4 | 7,28 | 6,3 | 6,32 | « presque » |
| Recette 5 | 7,28 | 6,4 | 6,33 | « presque » |
| Recette 6 | 7,33 | 6,13 | 6,17 | « presque » |
| Recette 7 | 7,72 | 6,27 | 6,33 | « presque » |
| Recette 8 | 7,67 | 6,12 | 6,17 | « presque » |
| Recette 9 | 6,5 (7,5 sans plafond) | 6,45 | 6,5 | « presque » |
| Recette 10 | 7,8 | 6,57 | 6,5 | « presque » |
| Recette 11 | 7,77 | 6,37 | 6,33 | « presque » |
| Recette 12 | 6,8 (7,35 à 7,5 sans plafond) | 6,07 | 6,17 | « presque » |

Les références sont plafonnées par leur capture : un mur d'inscription pour Hallow, un bandeau de cookies qui ne se ferme pas pour Waking Up. Les jurés le disent eux-mêmes : à note égale, le système de ces deux sites reste plus fini que nos pages intérieures.

**Corrections après la recette 1.**

| # | Relevé | Correction |
|---|---|---|
| L1 | Pages intérieures sur un seul gabarit image et texte | Une bande pleine par page intérieure (titre, grande illustration au centre, texte et tableau en deux colonnes dessous) : cours, familles, tarifs, académie, recrutement |
| L2 | Taches lavande dans la main, éclats sous le Coran (académie) | Les mains tiennent déjà le livre au premier écran ; la tache est retirée du calque des mains |
| L3 | Coupures après les petits mots, deux-points en début de ligne, « Az-Zalzalah » coupé | Espace insécable avant « : ; ? ! » ; noms à trait d'union insécables ; « qui » et « que » liés au mot suivant |
| L4 | Les quatre étapes des bases en cartes de texte | Quatre arches qui montent, de la plus sombre à la plus claire |
| L5 | Simulateur à l'air de formulaire | Champs à gauche, prix à droite, chevron dessiné, exemple d'âge |

**Corrections après la recette 2.**

| # | Relevé | Correction |
|---|---|---|
| M1 | La même arche entière dans presque chaque section | Six recadrages serrés, en cercle, des illustrations (pupitre et coussin, enseignante qui lit, deux élèves vus du dessus, homme et femme au livre, enseignante au pupitre). L'arche entière reste aux hauts de page et aux grandes scènes |
| M2 | Titre de page plus petit que les titres de section | Titres de page de 66 px en grand écran, titres longs compris ; colonne de titre élargie à six colonnes |
| M3 | Illustrations au tiers de l'écran dans de grands champs violets | Images de section sur six colonnes ; espace entre sections réduit d'un tiers. Dans le chapitre « Un enseignant qui écoute et corrige », les mains sont ancrées dans le coin bas gauche de l'écran, 1,6 fois plus grandes |
| M4 | « Les cours en bref » : deux paragraphes denses | Les encarts de la décision du 18/10 sont posés une phrase par ligne, sans changer un mot |
| M5 | Simulateur : âge vide, champ nu, vide dans la colonne du prix | Boutons moins et plus ; un exemple d'âge rempli pour lire le calcul tout de suite |
| M6 | Mains : dalle de sol sous la porte, manches dans une brume, ourlet fantôme | Reflet du sol retiré ; plus de fondu : la manche sort par le bord de l'écran (24 px au-delà) et son ourlet passe sous le bas de l'écran. Les conditions prennent une autre illustration, faute de bord où la manche puisse sortir |

Inspection des 18 pages après ces corrections : 0 FAIL sur les 10 pages de l'offre ; un seul FAIL sur chacune des 8 pages documents (« few-pictures », défendu plus haut). Tous les titres de page tiennent en deux lignes de 840 à 1440 px.

**Recette 3.** La note de Rewayah est plafonnée à 6,5 par une seule règle de la grille : l'ombre douce sous les détails ronds compte comme une ombre sur un élément au repos. Sans ce plafond, les trois jurés donnent 7,45, 7,5 et 7,1. Les points sur lesquels ils s'accordent : les mêmes scènes de page en page, un seul violet du haut en bas, « Les cours en bref » qui répète un tableau, le simulateur, les coupures de ligne, la hiérarchie au téléphone.

**Corrections après la recette 3.**

| # | Relevé | Correction |
|---|---|---|
| N1 | Ombre sous les détails ronds (plafond à 6,5) | Retirée sous tout détail cadré ; seule l'illustration détourée qui flotte garde son ombre au sol |
| N2 | Les mêmes scènes sur deux à cinq pages | Chaque scène entière n'appartient qu'à une page (accueil : le chemin, la halqa, les mains ; Familles : le père et le fils, la mère à la porte ; Cours : l'élève et son enseignante, l'adulte et son enseignante ; Tarifs : l'enseignant qui attend, l'adulte sur son tabouret ; Comment ça marche : l'homme au seuil ; Académie : la boucle, la femme au livre). Ailleurs, des détails serrés, chaque fichier une seule fois. Dix nouveaux détails, chacun recadré par un agent puis relu par un second (personne coupée, aucun éclat d'une autre scène, résolution native) |
| N3 | Toujours le même cercle | Deux cadres : le cercle (la halqa) et l'arche du symbole, pour les personnes en pied |
| N4 | Un seul violet du haut en bas | Une section par page passe sur la lavande de la salle, une autre sur le prune profond ; une bande peut être une phrase seule, en grand, sur son fond |
| N5 | Le mot géant de la bande d'appel sur chaque page | Gardé sur l'accueil ; les pages intérieures ferment sur une bande sobre |
| N6 | « Les cours en bref » répète le tableau du dessus | Le tableau est retiré de Cours. Les encarts restent tels quels (consigne 3 du 18/10), posés sur le prune, une phrase par ligne |
| N7 | Deux mises en page côte à côte d'affilée sur Cours | « Apprendre avec un enseignant » devient une bande pleine sur la lavande |
| N8 | Simulateur : total en petit, tableau à quatre colonnes | Le total en grand, au corps du prix ; une ligne par élève, qui s'empile au téléphone ; l'âge aux boutons moins et plus |
| N9 | Coupures après un petit mot, dernier mot seul | Texte courant : petits mots liés au mot suivant, fourchettes et unités insécables (« 3 à 5 élèves »), dernier mot jamais seul ; une adresse e-mail garde sa place à la ligne |
| N10 | Hiérarchie plate au téléphone, petits textes à 12-14 px | Titres de section à 26 px au téléphone ; petits textes à 15 px au moins |
| N11 | Cartes de prix : un rond décoratif réserve un tiers de la carte | Retiré ; les lignes prennent toute la largeur |
| N12 | Académie au téléphone : panorama coupé, légende posée dessus | La boucle en haut de page, la légende passe dessous au téléphone |

**Corrections après la recette 4.**

| # | Relevé | Correction |
|---|---|---|
| P1 | Toutes les pages intérieures s'ouvrent sur la même composition (titre sur deux lignes à côté d'une porte entière) | Un haut de page par sujet : Cours sur les quatre arches du parcours, Tarifs sur ses deux prix, Comment ça marche sur le titre et les étapes juste dessous, Académie sur la boucle en panorama |
| P2 | Des scènes entières qui reviennent (cercles des chapitres, carte « Accompagné », deux portes entières dans une page) | Sept nouveaux détails serrés, vérifiés par un second agent (main sur l'épaule, famille sur le chemin, désert, mains et livre, deux élèves vus du dessus, fillette et enseignante) |
| P3 | « 1 h / 30 », puces coupées, lignes courtes forcées, quatrième arche sur quatre lignes | Durées et unités insécables ; libellé de la quatrième arche ramené à trois lignes |
| P4 | Tableaux du téléphone sur quatre ou cinq lignes ; « Les cours en bref » en deux murs de puces | Tableaux empilés, une ligne de détail pleine largeur ; une carte à la fois derrière un choix Enfants ou Adultes |
| P5 | Côte-à-côte en chaîne sur Familles et Académie ; colonne vide sous « Les remises » | Familles : deux sections en paire ; remises en deux colonnes sans vide ; phrase de bande centrée |
| P6 | Titres de page à peine plus grands que les titres de section au téléphone ; petits textes à 13-14 px | Titres de page de 36 à 44 px ; petits textes à 15 px |
| P7 | Panorama de l'académie coupé au bord du contenu ; cercle « Accompagné » aplati | Le panorama déborde du bord de l'écran ; le cercle est entier |

**Corrections après la recette 5.** Les trois jurés s'accordent : l'accueil est au niveau des deux sites de référence, les pages intérieures pas encore.

| # | Relevé | Correction |
|---|---|---|
| Q1 | Familles ouvre encore sur une porte entière et en montre une seconde plus bas | Nouveau haut « gros plan » : une grande arche qui déborde du bord droit, avec un recadrage serré du rendu d'origine 12, son fond et sa lumière au sol, arche harmonisée (`plan-pere-fils`, 865 px, résolution native). « Vous choisissez parmi nos horaires » prend un détail serré de la mère à la porte (`gros-plan-famille`). Familles ne montre plus de porte entière |
| Q2 | Les mêmes personnages recadrés sur presque chaque page | Corrigé en partie : il n'y a que treize illustrations. Les dix prompts de scènes nouvelles (O-20) attendent la génération par le directeur |
| Q3 | Lignes courtes forcées, puces coupées à mi-carte, unités séparées, « d'Al-Fatiha » seul | Le texte courant passe en coupure ordinaire : Chrome coupait trop tôt en mode `pretty` (sur l'accueil en grand écran, 38 coupures précoces relevées avant ; 5 après, toutes voulues : titres équilibrés et phrases posées sur deux lignes). Blocs insécables limités à 24 signes. « d'Al-Fatiha » garde son article. Les flèches restent contre leur dernier mot |
| Q4 | Cartes de prix décalées, trou de 120 px dans la carte Adultes | Les deux cartes partagent leurs lignes (sous-grille) : titres, prix, public et listes commencent à la même hauteur |
| Q5 | Titre de page 1,3 à 1,4 fois le titre de section au téléphone ; tablette sur une ligne à 30 px | Titres de section à 24 px au téléphone ; titres de page de 41 à 44 px à 390 px (rapport 1,6 à 1,8) ; Académie à 1,42, son titre de 34 signes devant tenir en deux lignes. Tablette : titre de page de 52 à 64 px |
| Q6 | Toutes les pages intérieures sur la même pile ; côte-à-côte en chaîne sur Cours et Académie | Cours : objectifs et « Enfants et adultes » en paire. Académie : « La famille fait partie du parcours » devient une bande centrée, le cercle au-dessus. Tarifs : le tableau des classes à côté de la porte ; « Question de facturation » rejoint « À savoir », au lieu de deux bandes identiques |
| Q7 | Arches du haut de Cours vides (environ 300 px de vide) | Chaque arche porte ce que l'élève lit à cette étape : ا ب ت ث, puis بَ بِ بُ, puis القُرْآن, puis الفَاتِحَة. Décoratif (`aria-hidden`), en Noto Sans Arabic, police arabe d'interface de la marque, sous licence OFL. Elle est réduite à ces caractères (4,6 Ko) et inscrite dans la feuille de style : le paquet déployé ne gagne aucun fichier, et le contrôle de `.github/` reste juste |
| Q8 | Légendes posées sur l'image (haut de Tarifs, troisième arche des étapes) | Une seule règle : sous le cadre, à 8 px, alignée à droite. Vérifié sur six pages et trois largeurs. Seule la porte de l'accueil garde sa légende dans la partie transparente de sa scène détourée |
| Q9 | Mot géant « Commencer » à 15 px du bouton | 64 px au moins entre le bouton et le mot |
| Q10 | La tablette est un téléphone étiré | De 600 à 839 px : étapes et paires en deux colonnes, image plafonnée à 300 px ; corps de texte à 18 px. Tarifs : le cercle à côté des deux prix. Pas d'ombre sous un haut de page cadré |
| Q11 | Tarifs au téléphone : cercle au bord, légende dessus, prix sous la ligne de flottaison | Les deux prix d'abord, le cercle centré ensuite, la légende dessous |

Inspection des six pages après ces corrections, à 1440, 768 et 390 px : 0 FAIL. Restent des WARN : texte blanc sur violet à 6,5:1, aucune vidéo, texte fixe sur l'image de l'accueil (la porte), marges inégales à 768 px. Aucun texte sous 15 px. Tous les titres de page tiennent en deux lignes de 360 à 1440 px ; à 320 px, celui de l'académie en prend trois. Tests : 64, OK.

**Corrections après la recette 6.** Pour les trois jurés, l'accueil est au niveau des références ; les pages intérieures, pas encore.

| # | Relevé | Correction |
|---|---|---|
| R1 | Tablette : le cercle de la première étape de l'accueil remonte sur les deux liens d'action (défaut introduit en recette 5, quand la tuile a cessé de couper ce qui dépasse) | Chaque cercle est plafonné à la hauteur de sa tuile. Un détecteur de recouvrement passe maintenant à chaque largeur : plus aucun lien ni titre sous une image, hors la porte de l'accueil, qui couvre le texte par conception pendant qu'on la traverse |
| R2 | Unités coupées dans les tableaux de Tarifs (« 6 à / 17 ans », « 5 / min », « 3 / à 5 », « 5 % de / remise ») | Chaque cellule de tableau et chaque remise passe par la même liaison : fourchettes, durées, pourcentages et montants restent avec leur unité |
| R3 | « d'Al-Fatiha » seul sur une ligne dans la quatrième arche | La précision après la virgule passe dessous, plus petite et d'un seul tenant |
| R4 | Ligne courte forcée dans les cartes d'étapes ; puces de prix coupées | Texte des cartes d'étapes à 18 px sur une colonne plus large ; puces des cartes de prix à 18 px, la première tient sur une ligne |
| R5 | Le mot géant « Commencer » répète le bouton juste au-dessus | Sur l'accueil, le mot géant devient lui-même le bouton, avec sa flèche ; le libellé reste pour les lecteurs d'écran |
| R6 | Tablette : téléphone étiré (images de 650 à 750 px, titres de section à 30 px, pied de page sur une colonne) | Titres de section à 38 px ; images plafonnées à 420 ou 440 px ; les trois étapes de l'accueil côte à côte ; pied de page en trois colonnes |
| R7 | Arches de Cours : 150 à 250 px de vide entre l'arabe et le libellé | Marches de 50 px au lieu de 70 ; l'arabe se pose juste au-dessus du libellé |
| R8 | Familles : seconde porte et enseignante aux lunettes deux fois | « Vous choisissez parmi nos horaires » montre « La petite classe » (lot 2, scène 5 : la classe vue du dessus, chacun chez soi), à côté du texte |
| R9 | Académie : les deux élèves vus du dessus, déjà sur l'accueil et Familles | Les trois fondateurs, leurs noms en grand, repris du texte (le build vérifie qu'ils y figurent). La bande « Transmettre le savoir tel qu'il a été reçu » prend un détail sans personne : le haut de l'arche faite de pages et la porte ouverte, ce que le texte des fondateurs décrit |
| R10 | Titre de l'Académie à 1,3 fois un titre de section au téléphone | Titre ramené à « Une académie du Coran » : la date est dans la phrase juste dessous. 1,88 fois à 390 px, deux lignes dès 320 px |

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Corrections après la recette 7.** Les jurés placent l'accueil au-dessus des deux références ; ce qui retient encore leur « oui » : les mêmes personnages d'une page à l'autre, le rendu en style figurine sur Familles, quelques coupures, la tablette.

| # | Relevé | Correction |
|---|---|---|
| S1 | Les mêmes personnes sur plusieurs pages (l'enseignante aux lunettes, l'homme assis à la porte, les mains, la mère et la fille) | Quatre détails sans personne, chacun recadré par un agent et vérifié par un second (aucune personne, aucune écriture, résolution native) : le haut d'une porte dans la lumière (accueil, étape 2), la poignée d'une porte entrouverte et la porte ouverte sur la pièce (Comment ça marche, étapes 2 et 4), les dunes au-delà du seuil (Académie). L'enseignante aux lunettes ne reste que sur Cours et Familles, l'homme assis que sur Tarifs, les mains que sur l'accueil. Un cinquième détail, une courbe du chemin, est écarté : seul, il se lisait comme une lettre. La mère et la fille restent sur Tarifs en attendant les nouveaux rendus |
| S2 | « La petite classe » (lot 2) en style figurine, en grand sur la bande pâle | Posée dans un cercle comme les autres détails, plus petite, sur le violet, étalonnée un peu plus chaud |
| S3 | Coupures : « 5 % de / remise », « ne convient / pas. », « vous- / même », « n° / 16624644 », « des / cours », « de / 3 à 5 élèves » | Liaison des unités devenue indifférente aux espaces déjà insécables ; préposition liée au nombre qui suit ; dernier mot lié dans les tableaux, les remises et les encarts ; « vous-même » insécable ; petit mot lié à la flèche d'un lien |
| S4 | Chapitres de l'accueil, au téléphone et à la tablette : l'image flotte entre deux chapitres | L'image se pose juste au-dessus de son titre, alignée sur le texte ; 80 px entre deux chapitres |
| S5 | Cours, tablette : les arches deviennent des barres | Les quatre arches restent des arches, sur une rangée, avec l'arabe et le libellé ; la précision passe sur deux lignes entre les deux noms |
| S6 | Académie : les noms plus grands que le titre de section, qui ne mène pas | Le titre passe au-dessus des deux colonnes ; les noms, un cran plus petits que lui, à gauche ; le texte à droite |
| S7 | Tablette : cartes de prix empilées ; 280 px de vide avant « Commencer » | Cartes de prix côte à côte dès 600 px ; bande d'appel sans hauteur minimale sous 840 px |

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Corrections après la recette 8.** Ce qui retient encore le « oui » des jurés : la répétition des personnages, limite connue des rendus fournis.

| # | Relevé | Correction |
|---|---|---|
| T1 | Académie, tablette : le titre des fondateurs tombe sous les noms | Le titre passe au-dessus des deux colonnes dès 600 px |
| T2 | Tablette : chapitres de l'accueil empilés ; images de Tarifs décalées | Chaque chapitre pose son image à gauche et son texte à droite ; les images des grandes sections de Tarifs sont centrées |
| T3 | Bord droit du texte trop irrégulier | Seuls les mots d'une ou deux lettres se lient au mot suivant ; « Société n° 16624644 » et « ne convient pas » restent d'un seul tenant |
| T4 | La mère et la fille sur l'accueil et sur Tarifs | « Ce que coûte une famille » montre la tranche d'un livre fermé, courbée en arche, sans personne (recadrage vérifié par un second agent) |
| T5 | Une dizaine de tailles de texte ; le milieu de l'échelle se brouille (49, 55, 60 px) | Titres de section, énoncés et phrases de bande sur une seule taille (50 px à 1440 ; 48 px pour les chapitres de l'accueil, dont la colonne est plus étroite) ; titres des cartes à la taille moyenne. Un titre de page vaut 1,32 fois un titre de section (1,2 avant) |
| T6 | Bord droit irrégulier : la liaison du dernier mot laisse des lignes courtes | Le dernier mot ne se lie plus que si l'ensemble fait 14 signes au plus. Lignes remplies à moins de 75 % : 6 % à 1440, 14 % à 768, 15 % à 390 (9, 17 et 18 % avant) |
| T7 | « Les cours en bref » : les deux fiches finissent à des hauteurs différentes | Fiches de même hauteur, texte tel quel |
| T8 | Familles : deux cercles décalés en hauteur ; « La petite classe » en style figurine, trop grande | Les deux cercles sur la même ligne ; « La petite classe » à la taille d'un détail (420 px, 280 px au téléphone), réglée dans `images.json` (`taille : detail`) |
| T9 | Le sable pêche des dunes rompt le lavande des autres images | Sable et ciel ramenés au lavande des jetons sur les six images aux dunes ; la peau, la barbe et le livre restent intacts (zones saturées protégées) |
| T10 | Tarifs : cinq blocs image et texte à la suite | « Une classe, un enseignant attitré » devient une bande pleine : titre, image et tableau sur un même axe |
| T11 | Directeur (21/10, commentaire sur la planche) : « la première image était meilleure », ni la petite classe du lot 2, ni le schéma dessiné | Familles, « Vous choisissez parmi nos horaires » : le haut de la première scène vue du dessus (l’enseignant et les deux élèves des côtés), sans l’élève au bonnet violet déjà montré sur la page. Le schéma dessiné reste désactivé |

Trois objets seuls étaient demandés pour Tarifs ; un seul existe dans les rendus. Le pupitre a toujours une personne derrière lui et un livre ouvert dont les lignes se lisent comme du texte. La couverture du livre est tenue par des mains aux quatre coins, et son médaillon porte une écriture. D'où la proposition du 21/10 : dessiner en code les objets et les schémas, et garder les rendus pour les personnes. Une planche de style est soumise au directeur ; rien ne passe sur le site avant son accord.

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Corrections après la recette 9.** Les trois jurés plafonnent Rewayah à 6,5 pour une seule raison : au téléphone, l'énoncé de l'accueil prend quatre lignes et finit sur « seul. ». Sans ce plafond, la note pondérée est de 7,5.

| # | Relevé | Correction |
|---|---|---|
| U1 | Accueil, téléphone : « Votre classe commence à l'heure. Vous ne tenez plus le rythme seul. » sur quatre lignes, « seul. » isolé | Sous 840 px, une phrase par ligne, à la taille qui la fait tenir (22 px à 390, 20 px à 360, 18 px à 320) : deux lignes partout, sans débordement |
| U2 | Fiches et cartes de prix : « ne convient / pas. », « chaque fin / de semaine. » | Puces composées sans mot seul en fin de puce ; aucun mot isolé mesuré à 1440, 768 et 390 px |
| U3 | Familles : « La petite classe » du lot 2 dans un autre style | Remplacée par la première scène vue du dessus, sur décision du directeur (T11) |
| U4 | Familles, ordinateur : « Les cours en bref » absent des captures | Le titre est bien là au défilement réel ; la révélation part désormais dès qu'un pixel entre à l'écran, pour que les captures par écran entier le montrent aussi |
| U5 | Accueil, téléphone : trois étapes de hauteurs différentes | Au téléphone, les trois tuiles et les trois cercles ont la même taille |
| U6 | Cours : l'arche et le cercle côte à côte, titres décalés ; un bord de porte dans le cercle | Même boîte pour les deux images, posées en bas : les titres partagent une ligne. Le cercle est recadré sans le pilier de l'arche |
| U7 | Téléphone : les détails sans personne prennent tout l'écran ; notes à 15 px | Au téléphone, une arche fait 260 px au plus et un cercle 300 px. Notes et légendes à 16 px |

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Corrections après la recette 10.** Aucun plafond ne s'applique plus ; les trois jurés donnent 7,8 et placent l'accueil et le haut de Cours au-dessus des deux références. Ce qui retient leur « oui » : les mêmes personnes d'une page à l'autre (limite des rendus), et des détails agrandis ou trop grands.

| # | Relevé | Correction |
|---|---|---|
| V1 | Des détails agrandis au-delà de leur fichier, donc flous (Cours, Tarifs, Académie, chapitres de l'accueil : jusqu'à 1,67 fois) | Le build pose la largeur du fichier sur chaque détail cadré ; il ne s'affiche jamais plus grand. Plus aucune image agrandie à 1440, 768 et 390 px |
| V2 | Familles : la classe vue du dessus, petite, flotte sur le violet | Posée sur un panneau lavande, comme un sol, à la largeur de la colonne (540 px à 1440) |
| V3 | Académie : le cercle des dunes occupe tout l'écran du téléphone | 260 px au plus au téléphone, 450 px (sa taille réelle) ailleurs |
| V4 | Téléphone : la légende « Illustration » colle au titre qui suit | Au moins 30 px entre une légende et le titre suivant, sur toutes les pages, aux trois largeurs |
| V5 | Téléphone : le pied de page prend un écran et demi | Même contenu, resserré : 1 120 px au lieu de 1 307 |
| V6 | Directeur (21/10) : « Tu commences à introduire subtilement les arrières plans derrière les objets alors que tout devait flotter » | Le panneau lavande posé derrière la classe vue du dessus (V2) est retiré. Les cadres en cercle et en arche ne peignent plus de fond : ils découpent seulement, et une figure détourée flotte sur la page. Les objets dessinés sont refaits sans disque |

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Corrections après la recette 11.** Les jurés placent l'accueil au-dessus des deux références ; ce qui retient leur « oui » reste la répétition des personnages (limite des rendus, O-20) et des pages intérieures plus sages que l'accueil.

| # | Relevé | Correction |
|---|---|---|
| W1 | Tarifs : l'homme aux dunes coupé au cou dans « Le prix de chaque formule » | Gros plan voulu : les mains et le livre fermé contre la tunique, sans visage (260 px, sa taille réelle) ; sable ramené au lavande |
| W2 | Académie : le cercle des dunes se lit comme un morceau de mur | Le haut de l'arche faite de pages, sans personne, qui s'efface vers le bas, posé en grand sans fond ajouté |
| W3 | Académie : la bande « Transmettre le savoir tel qu'il a été reçu » est la section la plus maigre | La phrase passe en taille d'affiche (64 px, deux lignes) à côté du cercle à sa taille réelle |
| W4 | Familles : la classe vue du dessus, petite ; minuscule à la tablette | 690 px à 1440 ; à la tablette, elle passe sous son texte, à toute la largeur |
| W5 | Téléphone : le pied de page fait encore 1,3 écran | Les quatre contacts tiennent en deux colonnes (le libellé est le lien ; l'adresse reste visible à partir de 600 px) ; mentions et crédits à 13 px : 941 px au lieu de 1 307 au départ |
| W6 | La légende « Illustration » change de place d'une image à l'autre | Une seule règle : 13 px, alignée sur le bord droit de son image, à 32 px au moins du titre suivant |

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Corrections après la recette 12.** Les trois jurés plafonnent l'utilisabilité à 5 pour une régression : au téléphone, la légende du haut de l'accueil était coupée au bord de l'écran (« Illus »), après le changement de la règle des légendes (W6).

| # | Relevé | Correction |
|---|---|---|
| X1 | Accueil : la légende du haut coupée au bord de l'écran du téléphone, illisible à la tablette, hors de la marge sur ordinateur | La légende sort de l'image qui déborde : elle est posée dans la colonne du contenu, sous la scène, alignée sur le bord droit (374 px à 390, 744 à 768, 1 320 à 1 440) ; elle s'efface quand on passe la porte. Nouveau contrôle : aucun texte visible coupé par le bord de l'écran, sur les six pages, à 390, 768 et 1 440 px |
| X2 | Familles : la classe vue du dessus flotte, sans sol | La première image du directeur, telle quelle : la classe dans son cercle de lumière, sur son sol, recadrée en cercle (le rendu d'origine) |
| X3 | Familles : l'élève au bonnet violet deux fois sur la page | « Un profil pour chaque élève » montre la mère et sa fille qui partent main dans la main |
| X4 | Académie : la même arche dans deux sections de suite | « La famille fait partie du parcours » montre la mère à la porte qui regarde sa fille apprendre avec l'enseignante ; un cercle en bande pleine fait 520 px au plus |

Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

Contraintes que la recette ne pouvait pas lever : le directeur a fourni treize illustrations, presque toutes des portes (question O-20) ; les encarts du 18/10 se publient tels quels.

Inspection des six pages de la recette après ces corrections : 0 FAIL. Tous les titres de page tiennent en deux lignes de 840 à 1440 px et à 390 px ; à 360 et 320 px, le titre de l'accueil prend quatre lignes, ceux de l'académie et des conditions trois (déjà le cas avant ce lot). Tests : 64, OK.

## Hors de portée de l'agent

- `.github/workflows/flutter-deploy.yml` vérifie la présence de 8 fichiers du site, mais pas de `motion.js`. Le garde du dépôt interdit à l'agent d'écrire dans `.github/`. Le test `test_only_approved_public_assets_are_copied` couvre ce fichier côté tests.
- L'outil REA (Reverse Engineer Anything) n'est installé qu'en ligne de commande, dans l'espace de travail de la session. Son inscription comme serveur MCP et comme skill demande une règle de permission du directeur.
