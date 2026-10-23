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
| Recette 13 | 7,77 | 6,2 | 6,3 | « presque » |
| Recette 14 | 7,72 | 6,2 | 6,17 | « presque » |
| Recette 15 | 7,42 | 6,07 | 6,17 | « presque » |
| Recette 16 | 7,7 | 6,33 | 6,33 | « presque » |
| Recette 17 | 7,4 | 6,5 | 6,5 | « presque » |
| Recette 18 | 7,43 | 6,37 | 6,33 | « presque » |
| Recette 19 (jurés Sonnet) | 7,72 | 6,95 | 6,93 | « presque » |
| Recette 20 (jurés Sonnet) | 7,53 | 7,07 | 7,23 | « presque » |
| Recette 21 (jurés Sonnet) | 7,70 | 6,33 | 6,17 | « presque » |
| Recette 22 (jurés Sonnet) | 7,67 | 6,73 | 6,33 | « presque » |
| Recette 23 (jurés Sonnet) | 7,57 | 7,18 | 6,50 | « presque » |
| Recette 24 (jurés Sonnet) | 7,63 | 6,87 | 6,50 | « presque » |
| Recette 25 (jurés Sonnet) | 7,53 | 6,63 | 6,57 | « presque » |
| Recette 26 (jurés Sonnet) | 7,59 | 7,22 | 7,22 | « presque » |
| Recette 27 (jurés Sonnet) | 6,50 | 6,87 | 6,50 | « presque » (plafond : titres des chapitres sur trois lignes) |
| Recette 28 (jurés Sonnet) | 7,73 | 7,00 | 6,50 | « presque », sans plafond |
| Recette 29 (jurés Sonnet) | 7,70 | 7,00 | 7,20 | « presque », sans plafond |
| Recette 30 (jurés Sonnet) | 7,57 | 6,93 | 6,73 | « presque », sans plafond |
| Recette 31 (jurés Sonnet) | 7,57 | 6,97 | 6,77 | « presque » (un juré applique le plafond « moins de quatre vraies photos ») |
| Recette 32 (jurés Sonnet) | 7,18 | 7,08 | 6,73 | « presque » (les trois jurés appliquent le plafond « moins de quatre vraies photos ») |
| Recette 33 (jurés Sonnet) | 7,70 | 6,57 | 6,33 | « presque », sans plafond (les rendus comptés comme images raster, définition du skill rappelée aux jurés) |
| Recette 34 (jurés Sonnet) | 7,77 | 6,67 | 6,80 | « presque », sans plafond |
| Recette 35 (jurés Sonnet) | 7,77 | 6,57 | 6,33 | « presque », sans plafond |
| Recette 36 (jurés Sonnet) | 7,77 | 6,80 | 6,50 | « presque », sans plafond |
| Recette 37 (jurés Sonnet) | 7,77 | 6,75 | 6,50 | « presque », sans plafond |
| Recette 38 (jurés Sonnet) | 7,90 | 6,92 | 6,90 | « presque », sans plafond |
| Recette 39 (jurés Sonnet) | 7,90 | 6,57 | 6,33 | « presque », sans plafond |
| Recette 40 (jurés Sonnet) | 7,78 | 6,78 | 6,50 | « presque », sans plafond ; dernière recette (directeur, 23/10 : « il faut en finir ») |

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

**Corrections après la recette 13.** Plus aucun plafond. Les trois jurés répètent que ce qui retient leur « oui » est la répétition des mêmes personnages d'une page à l'autre et le petit nombre de rendus : c'est la question O-20 (nouvelles scènes), que le site ne peut pas régler seul.

| # | Relevé | Correction |
|---|---|---|
| Y1 | Tarifs : le détail en arche à côté de « Ce que coûte une famille » se lit comme un panneau vide | Le haut de l'arche faite de pages, sans personne, qui s'efface dans la bande lavande |
| Y2 | Accueil : la scène du haut finit sur une coupe nette, le tapis coupé | Le bas de la scène s'efface dans la page |
| Y3 | Cours, tablette : les quatre arches serrées, libellés sur quatre lignes | Deux arches par rangée ; chaque libellé tient sur une ligne, deux pour les sourates avec leur précision |
| Y4 | Accueil : la fenêtre des chapitres change d'image trop tard | L'image change quand le titre du chapitre suivant passe 60 % de la hauteur de l'écran |
| Y5 | Les mêmes personnages reviennent sur trois ou quatre pages (la fillette au pupitre, la mère, l'enseignante aux lunettes, la classe vue du dessus, l'homme au livre) | Quatre recadrages sans personne, cherchés dans les rendus d'origine avec leur décor et vérifiés par un second agent : la boucle du tapis (Académie, « La famille fait partie du parcours »), le tapis qui ondule (haut de Tarifs), l'arche vue d'en haut (Cours, « Trois séances par semaine »), l'arche sombre vue d'en haut (Tarifs, « Le prix de chaque formule »). Chaque groupe de personnages ne paraît plus que sur deux pages au plus ; chaque page garde quatre images |

Le texte courant est déjà en blanc plein sur le violet (contraste 6,5:1, le plus haut possible sur ce violet). Inspection des six pages après ces corrections : 0 FAIL. Tests : 64, OK.

**Après la recette 14.** Les cinq groupes de personnages visés ne paraissent plus que sur deux pages au plus. Les jurés relèvent alors deux autres groupes sur quatre pages (le père et le garçon, l'enseignant barbu), et lisent les recadrages sans personne comme du remplissage. Le jeu de rendus ne permet pas mieux : chaque personnage retiré d'une page doit être remplacé par un décor, et les décors disponibles sont presque tous des arches et des portes. Seules de nouvelles scènes lèvent cette réserve (O-20). La génération à partir des rendus, acceptée par le directeur le 21/10, est bloquée par la sécurité de l'environnement : elle demande que la session passe en mode « Accept edits », ou que le modèle soit autorisé dans le connecteur Hugging Face.

Le directeur a changé le mode de la session le 21/10. Le rendu part bien vers le modèle (FLUX.1 Kontext, Space Hugging Face), mais le calcul est refusé : le Space tourne sur des cartes graphiques partagées (ZeroGPU) qui demandent un compte, et la session n'a pas de jeton Hugging Face. Le connecteur Hugging Face consulte les modèles mais ne peut pas les lancer (`gradio=none`). Aucun Space d'édition d'images en service ne tourne sur une carte dédiée. Deux voies : un jeton Hugging Face en lecture ajouté aux réglages de l'environnement (variable `HF_TOKEN`, lue par une nouvelle session ; un compte gratuit donne 5 minutes de calcul par jour), ou des scènes générées par le directeur avec le fichier `marque/PROMPTS-ILLUSTRATIONS-2026-10-21.md`.

**Corrections après la recette 14, sans nouveau rendu.**

| # | Relevé | Correction |
|---|---|---|
| Z1 | Accueil : l'énoncé « Votre classe commence à l'heure… » petit, aligné à gauche, second vers en retrait, un tiers d'écran vide ensuite | Centré, sans retrait, à la taille qui remplit la mesure (64 px à 1440, 48 px à 840) ; la fenêtre des chapitres suit 160 px plus bas au lieu de 280 |
| Z2 | Accueil : « Une petite classe. Un enseignant attitré. » trop petit à l'arrivée du zoom | 62 px au lieu de 49 ; la classe vue du dessus se décale (54vw) et passe de 46 à 41vw de large pour garder l'écart |
| Z3 | Accueil : la dernière image des chapitres part pendant qu'on lit son texte | Le dernier chapitre a la hauteur de la fenêtre et se centre sur elle : texte et image quittent l'écran ensemble. L'image change quand le titre du chapitre suivant passe 60 % de l'écran (le titre, et non plus le haut de l'article) |
| Z4 | Accueil : la fenêtre des chapitres change de cadre à chaque chapitre ; texte des chapitres sur une autre colonne que les autres paires | Une seule forme, l'arche : le père et le fils sont recadrés en arche dans le même rendu (380 × 475, taille réelle) ; seules les mains restent détourées. Le texte part de la colonne 7, comme les autres paires (732 px à 1440) |
| Z5 | Accueil : la moitié basse en pièces de kit, dont deux cartes de prix à puces | Les deux prix se lisent en grand, sans carte (150 px à 1440, 64 px au téléphone) ; le public et ce que le prix comprend se posent dessous |
| Z6 | Tarifs : les deux prix dits trois fois ; cinq écrans de tableaux et de cartes | La grille « Le prix de chaque formule » est retirée. Ses mentions (date d'effet, monnaies, taxes) passent sous les deux prix du haut, présentés sans boîte, et le simulateur les suit. Le libellé adulte reprend la décision : « 18 ans et plus » |
| Z7 | Tarifs : un cercle de tapis en haut de page qui se lit comme un échantillon de tissu | L'arche sombre vue d'en haut passe en haut de page ; le tapis va aux remises. Quatre images, chacune une seule fois |
| Z8 | Comment ça marche : petites images dans de grandes cartes, cartes décalées en escalier | Deux cartes par rangée, de même hauteur et alignées en haut ; l'image prend la moitié de la carte |
| Z9 | « Les cours en bref » : des encarts en petits caractères, sans ligne qui mène | Mot pour mot. La ligne du prix se lit en grand, sans puce (46 px à 1440), et s'aligne d'un encart à l'autre ; les autres lignes respirent davantage |

Non repris : la taille du texte courant. Il est à 19,6 px sur un écran de 1 440 px ; les captures des jurés réduisent quatre écrans à 800 px de large, ce qui le fait paraître à 11 px. Le voile au bout du disque blanc de la scène du haut est dans le rendu lui-même.

Inspection des six pages après ces corrections : 0 FAIL (un recouvrement introduit par les grands prix, l'interligne de 0,9 du chiffre empiétant sur le titre au-dessus, a été corrigé avant l'envoi). Aucune image agrandie, aucun texte coupé au bord de l'écran, aucun mot seul en fin de puce. Tests : 64, OK.

Contraintes que la recette ne pouvait pas lever : le directeur a fourni treize illustrations, presque toutes des portes (question O-20) ; les encarts du 18/10 se publient tels quels.

Inspection des six pages de la recette après ces corrections : 0 FAIL. Tous les titres de page tiennent en deux lignes de 840 à 1440 px et à 390 px ; à 360 et 320 px, le titre de l'accueil prend quatre lignes, ceux de l'académie et des conditions trois (déjà le cas avant ce lot). Tests : 64, OK.

**Corrections après la recette 15, sans nouveau rendu.** Les trois jurés placent l'accueil au-dessus des deux références. Ils retiennent leur « oui » à cause des pages intérieures : blocs de kit (cartes, tableaux, pastilles, accordéon), recadrages sans personne lus comme du remplissage, cadres mêlés dans une même rangée, huit à dix tailles de texte.

| # | Relevé | Correction |
|---|---|---|
| AA1 | Tarifs : sept écrans de blocs (simulateur, pastilles de remises, trois tableaux, bande des conditions) et trois recadrages sans personne | Une seule image : la scène entière de la place qui attend, à droite des deux prix. Les remises en grands chiffres, chacune avec ce à quoi elle s'applique, sans tableau ni cartes. Le tableau de la famille (décision du 18/10) sans cases ni bandes. Le tableau d'organisation, qui redisait « Les cours en bref », est retiré |
| AA2 | Portes, coins d'arche et tapis sans personne lus comme du remplissage (accueil, Comment ça marche, Cours, Académie) | Recadrages avec des personnes, taillés dans les rendus du directeur à leur taille réelle. Tuiles de l'accueil : trois moments du chemin de la boucle (on avance, les chemins se croisent autour d'un enseignant, on passe la porte). Comment ça marche : la femme au tabouret, l'enseignant assis, la fillette et son enseignante. Cours : la femme et l'homme au livre, côte à côte, puis deux élèves vus d'en haut. Familles : l'élève à son pupitre, l'enseignante. Académie : les mains qui tendent le Coran, la mère et sa fille. Plus aucune porte ni aucun tapis seul |
| AA3 | Cadres mêlés dans une même rangée | Un cadre par rôle : l'arche pour les personnes, le cercle pour la seule classe vue d'en haut (la halqa), la scène entière détourée sans cadre. Deux arches côte à côte ont la même taille |
| AA4 | Accueil : la phrase du zoom plus petite que le titre, à gauche | À la taille du titre (78 px à 1440), centrée au-dessus de la classe vue d'en haut |
| AA5 | Accueil : la fenêtre des chapitres change de cadre (arche de 380 px, mains détourées dans le coin, arche de 540 px) | Une seule arche pour les trois chapitres, de même taille (540 px à 1440 × 900, 435 px à 1280 × 720) ; le père et le fils sont recadrés plus large dans le même rendu, sans agrandissement ; les mains entrent dans la même arche, sur le sol lavande de leur rendu, et montent toujours vers le Coran |
| AA6 | Accueil : la moitié basse en kit (carte sombre arrondie avec une image, accordéon en boîtes) | « Accompagné à chaque étape » devient une bande sombre sur toute la largeur, sans image : la date en grand, les trois engagements côte à côte. Les six questions sont ouvertes, sur deux colonnes, sans boîte ni signe plus |
| AA7 | « Les cours en bref » : une carte violette à côté d'une carte blanche, puces à 15-16 px | Mot pour mot. Deux colonnes égales sur le même fond, sans carte ; les lignes de même rang se font face ; texte à 20 px, ligne du prix à 56 px |
| AA8 | Huit à dix tailles de texte | Cinq tailles : affiche (96 px), section (56), sous-titre (28), texte (20), petit (15), plus les chiffres des prix. Puces, encarts, étapes, légendes et notes y sont ramenés ; au téléphone, six à huit tailles par page au lieu de dix ou onze |

Chaque rendu ne paraît plus que sur deux des six pages, sauf la classe vue d'en haut (accueil, Familles, Cours), chaque fois sous un autre angle. L'enseignant barbu et l'enseignante aux lunettes violettes figurent dans presque tous les rendus : leur répétition ne se lèvera qu'avec de nouvelles scènes (O-20).

Non repris :
- Tarifs n'a qu'une image, comme le demandaient les trois jurés. L'inspecteur, qui veut quatre images par page, la signale (FAIL « few-pictures ») : c'est voulu.
- Les six questions de l'accueil restent six (un juré en proposait trois) : chacune répond à une question des familles.
- Le simulateur garde son panneau sombre : c'est l'outil de la page.
- La phrase seule proposée pour « Transmettre le savoir » (Académie) : la page tomberait à trois images ; les mains qui tendent le Coran disent cette phrase.

Inspection des six pages après ces corrections : 0 FAIL hors Tarifs (ci-dessus). Avertissements déjà présents avant ce lot : texte blanc sur le violet à 6,5:1, aucune vidéo, marges inégales à 768 px sur Comment ça marche, et la phrase du zoom comptée « sur une image » (la classe vue d'en haut est détourée : son cadre est transparent autour des personnes). Aucune image agrandie, aucun texte coupé au bord de l'écran, aucun mot seul en fin de puce, de 390 à 1440 px. Tests : 64, OK.

**Relecture du code et des textes, puis recette 16.** La relecture du lot de la recette 15 n'a trouvé aucun défaut bloquant (64 tests, 18 pages, toutes les images et tous les liens). Elle a confirmé six défauts, corrigés :
- les deux prix du haut de Tarifs décalés de 10 à 20 px entre 840 et 1 060 px ;
- les mains de l'accueil servies dans un fichier deux fois trop petit pour leur cadrage dans l'arche, donc floues ;
- « 6 mois » coupé en fin de ligne ;
- la ligne de la bourse, qui allait au-delà de l'encart des remises et redisait le non-cumul ;
- la phrase « Les remises sont calculées par élève », fausse pour le parrainage (un crédit par famille) ;
- cinq descriptions d'images qui disaient autre chose que l'image.

Les trois jurés de la recette 16 jugent réglés : les recadrages sans personne, les cadres mêlés dans une rangée, la fenêtre des chapitres, « Les cours en bref ». Leurs relevés communs :

| # | Relevé | Correction |
|---|---|---|
| BB1 | Comment ça marche : à côté de l'image, le texte des cartes n'a que 250 px (quatre mots par ligne) | L'image au-dessus du texte à toutes les largeurs ; le texte prend toute la carte (45 à 55 signes) |
| BB2 | Accueil, tablette et téléphone : la phrase du zoom reste à gauche, en sous-titre | Centrée, à la taille du titre quand chaque vers tient sur une ligne (57 px à 768, 33 px à 390 au lieu de 24) |
| BB3 | Académie : quatre sections sur le même gabarit ; les mains reprises de l'accueil ; deux cartes empilées en bas | « Transmettre le savoir tel qu'il a été reçu » devient une phrase seule sur la bande sombre ; la société et le contact sont posés sur le fond, sans carte ; le mot du directeur et les profils des fondateurs changent le rythme de la page |
| BB4 | Tarifs : le simulateur dans une carte sombre, libellés à 15 px | Posé sur le violet, sans carte ; libellés et texte à 20 px |
| BB5 | Encore huit à dix tailles de texte | L'énoncé de l'accueil passe à la taille du titre (une taille de moins) |

Non repris : une fin de page à grand mot sur chaque page intérieure (le grand mot reste la signature de l'accueil). La répétition des personnages (O-20) demeure.

**Le mot du directeur et les fondateurs (directeur, 21/10/2026).** Sur la page Académie :
- **Mot de bienvenue.** Il est reformulé à la demande du directeur (doux, sérieux, simple, court) et relu par trois jurés. Il garde ses idées : l'apprentissage ouvert à chacun, le présentiel encouragé quand il est possible, l'académie en ligne comme une solution parmi d'autres.
- **Photo du directeur.** Elle est calée au bord gauche de l'écran, où elle est coupée, et arrondie en demi-arche en haut à droite. Elle est désaturée vers le noir et blanc : ombres à l'encre de l'app (#110E20), clairs lavande (#F4EEFF), 15 % de gris neutre. Les trois jurés ont classé ce traitement premier parmi quatre. Ses métadonnées sont retirées.
- **Profils.** Les trois fondateurs ont chacun leur profil, avec leur rôle et leurs diplômes. Le nom du troisième fondateur s'écrit Ahmad Diallo, et non plus Ahmadou.
- **Arabe.** Les noms et diplômes en arabe sont inscrits au registre de marque (M-29) pour le futur site en arabe, sans être mêlés au français.
- **Photos des deux autres fondateurs.** Elles sont annoncées mais ne sont pas encore arrivées dans la session.

`site-public/police_arabe.py` refait la police arabe inscrite dans la feuille de style après tout ajout de texte arabe.

Inspection des six pages après ces corrections : 0 FAIL hors Tarifs (une image, voulu). Aucun texte coupé, aucune image agrandie, aucun mot seul. Tests : 64, OK.

**Après la recette 17.** La relecture du code et les trois jurés relèvent la même faute : sur l'Académie, les blocs « La société exploitante » et « Écrire à Rewayah Academy » avaient perdu leur marge intérieure mais gardé leur fond (une règle de l'ambiance violette l'emportait). C'est la cause de la baisse de la note. Corrections :

| # | Relevé | Correction |
|---|---|---|
| CC1 | Académie : deux rectangles de couleur, texte collé aux bords | Plus de fond, même dans l'ambiance violette : deux rangées titre à gauche, texte à droite |
| CC2 | Les cinq pages intérieures finissent sur la même petite bande | Chaque page principale finit sur un grand mot qui est le lien, comme l'accueil : « S'inscrire », « Continuer », « Découvrir » |
| CC3 | Comment ça marche : un vide à côté de l'image de chaque carte ; sur tablette, le texte de nouveau étroit | L'arche au centre de la carte, à 380 px ; l'image au-dessus du texte dès 600 px |
| CC4 | Accueil : la photo du directeur sans nom ; la même photo que sur l'Académie | Une phrase de son mot, signée de son nom et de son rôle ; un cadrage plus serré que sur l'Académie |
| CC5 | Accueil, tablette : le texte de la bande « Accompagné » décalé de 54 à 174 px | Aligné sur la marge de la page |
| CC6 | Accueil, tablette : les mains débordent d'une petite arche jusqu'au bord de l'écran | Les mains dans une arche, comme au bureau, et servies dans le grand fichier |
| CC7 | Accueil, tablette et téléphone : l'énoncé à gauche, en sous-titre | Centré, une phrase par ligne, à la plus grande taille qui tient (44 px à 768) |
| CC8 | Notes, légendes et pied de page à 13-16 px | Tous au petit pas de l'échelle : 17 px |
| CC9 | Tarifs : focus du clavier invisible dans les champs du simulateur | Contour de 3 px |
| CC10 | Tarifs : la scène du haut petite, entourée de vide | Agrandie (560 px au plus), sur la hauteur du haut de page |

La relecture note aussi : un doublon pour les lecteurs d'écran (la légende cachée de la photo redisait son texte alternatif ; retirée), une image sans usage (les mains de l'Académie ; retirée), aucun test des nouveaux chemins (trois tests ajoutés : la photo n'est jamais légendée « Illustration » et a son texte alternatif ; les profils sont les trois fondateurs et aucune ligne arabe n'est sur une page française ; un mot sans photo ou un extrait qui n'en vient pas est refusé).

Inspection des six pages : 0 FAIL hors Tarifs (une image, voulu). Aucun texte coupé, aucune image agrandie, aucun mot seul. Tests : 67, OK.

**Après la recette 18.** Les trois jurés placent Rewayah au-dessus des deux références (7,43 contre 6,37 et 6,33) et répondent encore « presque ». Ils relèvent tous trois la même fin de page partout, la bande du directeur sur l'accueil, l'adresse coupée dans le pied de page, l'énoncé trop petit au téléphone et le nombre de tailles de texte. La relecture du code ajoute un défaut d'accessibilité : le grand mot « S'inscrire » était caché aux lecteurs d'écran et absent du nom du lien (WCAG 2.5.3). Corrections :

| # | Relevé | Correction |
|---|---|---|
| DD1 | Six pages finissent sur la même ellipse blanche et un grand verbe ; au téléphone, 150 à 230 px de blanc vide ; « Continuer » ne dit pas la suite | Seul l'accueil garde la bande blanche et son grand mot. Les pages principales (et Avis) se referment sur leur propre titre, à la taille de leur titre d'ouverture, posé sur le fond. Ce titre est le lien : « Inscrivez votre enfant. », « Commencez par les bases. », « Votre inscription commence ici. », « Commencez votre inscription. », « Découvrez les cours. ». Au bureau, le titre est à gauche et sa phrase à droite. Au téléphone, le vide de la bande de l'accueil est retiré |
| DD2 | Le grand mot hors du nom du lien (relecture) | Le mot visible ouvre le libellé du lien (« Commencer » + « mon inscription » pour les lecteurs d'écran) ; le build refuse un mot qui n'ouvre pas le libellé ; test ajouté |
| DD3 | Accueil, bande « Accompagné » : la photo commence bas, le coin haut gauche est vide, une douzaine d'éléments dans la colonne de droite ; même cadrage qu'à l'Académie ; au téléphone, la photo tout en bas sous la ligne de la société | Le visage, cadré en largeur (5:4, de la calotte au col), en haut, à la hauteur du titre, calé au bord gauche. À côté : la date, la phrase signée, « Lire le mot du directeur ». Dessous, les trois engagements côte à côte. La ligne de la société est retirée (elle est au pied de page). Au téléphone : le titre, le visage, puis la phrase signée juste dessous. La signature est hors de la citation (`figure` et `figcaption`) |
| DD4 | La photo, un mur gris à côté des rendus lavande | Un pas de plus vers le violet, sur les deux cadrages : clairs au lavande des cadres (#EEE6FA), 8 % de gris au lieu de 15. Une marque du mur (un clou et son ombre) est retirée de la photo d'origine ; le visage n'est pas retouché |
| DD5 | Pied de page : « recrutement@rewayahacademy.c / om » coupé au milieu du mot à 1280 px et plus ; l'ornement en contour lu comme un reste ; au téléphone, les libellés sans leur adresse | L'ornement est retiré, la colonne des contacts prend sa place ; une adresse ne se coupe qu'après « @ » ; au téléphone, chaque adresse sous son libellé, sur une colonne ; sous 380 px, la navigation du pied sur une colonne |
| DD6 | Accueil, téléphone : l'énoncé à 21 px, plus petit que les titres qui l'entourent | La première phrase en grand sur deux lignes (35 px à 390, la taille de la phrase du zoom), la seconde dessous à la taille des intertitres ; moins de vide dessous |
| DD7 | Neuf ou dix tailles de texte par page | Une échelle courte : affiche géante (prix de l'accueil et grand mot, 150 px), affiche (titres d'ouverture et de fin, prix de Tarifs, 66 px), titre de section, intertitre, texte, notes. Mesuré à 1440 px : accueil 6 tailles ; Familles, Cours, Comment ça marche, Tarifs et Académie 5 tailles. Les phrases d'ouverture passent à la taille du texte (500) ; les notes des arches de Cours à 17 px |
| DD8 | Tarifs : la colonne de gauche encombrée, la scène flottante | Une seule action et un lien « Simuler mon tarif » ; la scène plus grande (600 px au plus) sur la droite ; les deux prix à 66 px sous le texte, au niveau du bas de la scène ; leurs mentions sur toute la largeur |
| DD9 | Accueil, sous 840 px : l'arche des mains plus large et collée à la marge, à la différence des deux autres arches (relecture) | Même marge intérieure que les autres arches |
| DD10 | Erreurs HTML anciennes : un titre dans un `span`, un identifiant en double sur l'Aide, des libellés qui contenaient plusieurs boutons dans le simulateur (relecture) | Corrigées : 0 erreur sur les 18 pages (validateur Nu 26.10.12). Les boutons moins et plus sont hors du libellé, qui nomme son champ par son identifiant |
| DD11 | Règles CSS sans effet (cartes de l'Académie, ancienne grille des étapes sur tablette) ; test de l'arabe incomplet (relecture) | Règles retirées, sans changement de position mesuré ; le test cherche aussi dans les textes alternatifs et sur toutes les plages de l'arabe |

**Photos des deux autres fondateurs (22/10/2026).** Le directeur les a déposées sur le Drive (« Alim & Ahmad ») : Mamadou Alimou Diallo sur fond blanc, Ahmad Diallo de nuit sous des arches éclairées, en pied. Les trois profils de la page Académie ont maintenant chacun leur portrait, traités ensemble pour aller ensemble :
- détourage (BiRefNet), puis pose sur le mur clair de la photo du directeur ;
- cadrage tête et épaules en 4:5, la tête faisant 60 % de la hauteur ; le directeur, coupé à gauche par sa photo d'origine, regarde vers les deux autres ;
- peau éclaircie à la luminosité de celle du directeur, les tons clairs (une tunique claire) protégés ;
- même étalonnage A3, même demi-arche que la photo du directeur, 300 px au plus.

Aucun visage n'est retouché. La photo d'Ahmad Diallo, en pied, ne donne que 338 px de large pour le portrait : il n'est jamais affiché plus grand que son fichier. Un test vérifie que chaque profil porte le portrait de la personne qu'il nomme.

Non repris : la répétition des personnages d'une page à l'autre (O-20). Les jurés proposent des recadrages sans personne, mais la recette 15 les avait refusés (« jamais une porte ou un tapis sans personne »). La réponse reste les nouvelles scènes demandées au directeur.

Inspection des six pages : 0 FAIL hors Tarifs (une image, voulu). Comment ça marche garde un avertissement de marges (120 et 142 px) : l'inspecteur ne compte que l'étendue du texte, et l'ornement retiré du pied de page touchait la marge droite. Les cartes et la grille vont bien de 120 à 1320 px. Aucun texte coupé. Aucune image agrandie à 390, 1024 et 1440 px. À 1920 px, l'image du haut de Familles est agrandie de 10 %, comme avant ce lot. Aucun mot seul. Simulateur vérifié : 3 élèves de 8, 12 et 30 ans donnent 159,55 $, sans erreur dans la console. Tests : 68, OK.

**Après la recette 19.** Pour ménager le quota hebdomadaire (demande du directeur, 22/10), les jurés et le relecteur tournent désormais sur Sonnet ; leurs notes ne se comparent pas point par point avec celles des recettes précédentes. Les trois jurés relèvent la fin blanche restée seule sur l'accueil, la photo du directeur montrée deux fois sur l'Académie, le premier écran de Tarifs encore chargé, le titre de l'Académie isolé à gauche et, à l'œil, trop de tailles de texte. Corrections :

| # | Relevé | Correction |
|---|---|---|
| EE1 | L'accueil seul finit encore sur la bande blanche et son grand mot | L'accueil se referme comme les autres pages, sur une phrase qui est le lien : « Pour votre enfant ou pour vous-même. », à la taille de son titre. Le grand mot disparaît du site, et avec lui l'écart entre le nom du lien et le mot montré (relecture) |
| EE2 | Le directeur montré deux fois sur l'Académie (grande photo et petit portrait) | Son parcours passe sous sa signature, à côté de sa photo ; la section des fondateurs présente les deux autres, portrait à gauche et texte à droite. Le portrait du directeur recadré pour la carte est retiré |
| EE3 | Académie : le titre isolé en bas à gauche, la phrase et le bouton en haut à droite | Titre, phrase et bouton dans une seule colonne à gauche, la boucle dessous |
| EE4 | Tarifs : la colonne de gauche encore chargée | La mention des monnaies et des taxes passe sous le simulateur ; seule une date d'effet, s'il y en a une, resterait sous les prix |
| EE5 | Trop de tailles à l'œil ; prix de l'accueil à 150 px | Prix de l'accueil à la taille de son titre : 5 tailles mesurées sur l'accueil au bureau, 6 au téléphone (la phrase du zoom, l'énoncé et la fin partagent la même) |
| EE6 | Titre d'ouverture et de fin : 64 px à 839 px, 40 px à 840 px (relecture) | L'affiche des pages part de 52 px dès 840 px |
| EE7 | Simulateur de l'accueil (feuille) : champs de 37 px, chiffres invisibles (relecture, défaut ancien) | Champs d'au moins 220 px par colonne : 118 px pour le nombre d'élèves, 238 px pour le paiement |
| EE8 | Accueil, bande « Accompagné » : la photo avant le titre pour un lecteur d'écran (relecture) | Le titre vient d'abord dans le document ; la grille place la photo à gauche |
| EE9 | Le libellé de l'action absent du lien de fin (relecture) | Quand il diffère du titre, il suit pour les lecteurs d'écran ; test étendu à l'accueil |

**Transitions entre les pages (demande du directeur, 22/10).** D'une page à l'autre, le contenu s'efface vers le haut et le suivant monte en place (transitions de vue entre documents) ; l'en-tête et le logo ne bougent pas. Rien ne bouge en mouvement réduit ; un navigateur qui ne connaît pas ces transitions change de page comme avant.

**Textes internes retirés du site (directeur, 22/10).** Le paragraphe « Le nom dit le projet… Le symbole le montre aussi… » de l'Académie, la phrase « Le nom Rewayah dit ce projet » et la mention « Les illustrations du site sont présentées comme telles » du pied de page recopiaient le registre de marque. Ils sont réécrits pour les familles : « C'est le sens de notre nom : « Rewayah » veut dire transmission. Nous enseignons le Coran tel qu'il nous a été transmis, sans rien y changer. » et « Notre logo raconte la même chose : un cercle, comme celui que forment les élèves autour de leur enseignant ; un livre, le Coran, dessiné en arche ; et dans ce livre, une porte ouverte, parce que cet enseignement est ouvert à chacun. » La mention du pied de page est retirée (chaque illustration porte déjà sa légende).

Une relecture de tout le texte visible des 18 pages a suivi. Ont été réécrites pour les familles : la réponse de l'aide sur le choix d'un horaire (« proposition horaire », « intentions » remplacés par « Choisir un horaire indique votre préférence, sans réserver de place… »), « Ouvrez la connexion Rewayah » (« l'application »), les phrases contradictoires sur l'enregistrement (Conditions, Protection des enfants : « Les cours ne sont pas enregistrés aujourd'hui ; si cela change, nous vous le dirons avant »), la page Accessibilité écrite comme un cahier des charges (« doivent ») devenue une suite d'engagements vérifiés, « Canaux de contact » (« Comment nous joindre »), la note de rédaction « Cette partie précise la loi… » (retirée), une ligne de contact en double (retirée), « Le rang suit l'ordre d'inscription » dans le simulateur, la note d'affichage des avis et une répétition sur les remises à l'accueil. Gardés volontairement : la légende « Illustration » (règle de marque), « matière secondaire » (vocabulaire décidé), le message sans JavaScript du simulateur (testé). À trancher par le directeur : le numéro de version des textes juridiques (« Version 2026-10-v1 ») affiché en tête de chaque texte ; « Représentant dans l'Union européenne : Rewayah Academy » (Confidentialité) ; la page Annulation renvoie à des dates « de la politique tarifaire en vigueur (page Tarifs) » que la page Tarifs ne donne pas.

**Structure (après la recette 19, suite).** Les colonnes de droite partaient de cinq bords différents (732, 744, 834, 1038 et 630 px à 1440). Elles partent toutes de la 7e colonne de la grille : texte des sections, seconde carte des duos, tableau de Tarifs, phrase des fins de page et des hauts de page en texte (ces deux derniers dès 1100 px, pour que les titres d'affiche tiennent en deux lignes plus bas). L'Académie pose « La société exploitante » et « Écrire à Rewayah Academy » côte à côte ; Familles donne à son aide, juste avant la fin, la forme d'un aparté (un intertitre, une phrase, deux liens) ; les champs du simulateur de Tarifs prennent les formes du site (pilules, boutons ronds).

**Après la recette 20.** Les trois jurés relèvent encore la coupe titre-texte trop fréquente, deux colonnes de prix décalées (752 px), le haut de l'Académie (un quart vide en haut à droite, la scène coupée par le bas de l'écran) et le haut de Cours et de Comment ça marche (la phrase sous la ligne du titre). Corrections : sur l'accueil, « Un horaire fixe » et les questions des familles posent leur titre au-dessus de leur texte, et les liens de la FAQ tiennent sur une ligne ; les deux prix de l'accueil et les deux fiches « Les cours en bref » partent de la 7e colonne ; Tarifs pose « À savoir avant de commander » sur toute la largeur, son texte en deux colonnes ; l'Académie remonte la boucle dans le premier écran, à côté du titre, entière ; la phrase des hauts de page en texte part de la ligne du titre. La mention des monnaies placée sous le simulateur est retirée : « À savoir avant de commander » la donne déjà. Les jurés demandaient aussi de retirer la phrase de fondation du haut de l'accueil : elle reste, car le nom de l'académie doit être dit dans le premier écran (l'en-tête du téléphone ne montre que le symbole ; un test le garde).

Ensuite : la porte du haut de l'accueil, un peu plus petite au bureau, ne touche plus l'en-tête ; au téléphone, la porte et la famille sont cadrées en grand. L'accueil se referme sous le haut d'une arche (« arche-haut », jusqu'ici sans usage), centré, comme il s'ouvre sur une porte : sa fin ne ressemble plus à celle des autres pages.

**Légende des illustrations (décision du directeur, 22/10/2026, registre M-30).** La légende « Illustration » sous chaque image est retirée de tout le site. Une seule mention la remplace, dans les mentions légales, section « Les images du site » : « Les images de ce site sont des illustrations, sauf les photos des fondateurs. » Chaque image garde son texte alternatif. Les règles de mise en page qui ne servaient qu'aux légendes sont retirées. Le test qui exigeait la légende vérifie maintenant son absence et la présence de la mention.

**Après la recette 21.** Les trois jurés relèvent cinq pages qui finissent pareil, la fin de l'accueil posée sur le bas de son arche, et le haut de Cours et de Comment ça marche encore coupé en deux. Corrections : chaque page finit à sa façon (direction.json, fin.forme) — l'accueil sous son arche, l'arche dégagée au-dessus du titre ; Familles, Comment ça marche et Tarifs sur un bandeau lavande centré, le titre, la phrase et un bouton ; l'Académie sur une bande sombre de bord à bord ; Cours sur le violet, le titre étant le lien. Les hauts de Cours et de Comment ça marche posent titre, phrase et bouton dans une colonne. Sur Cours, « Apprendre avec un enseignant » n'est plus en bande pleine (le titre et son texte étaient séparés d'un écran). Tarifs : le résultat du simulateur part de la 7e colonne. Académie : portraits des deux fondateurs à 300 px, noms sur deux lignes réservées, rôles et parcours alignés. Accueil : le bout gauche du tapis s'efface au lieu de s'arrêter net ; le bouton pause passe en bas à droite du premier écran.

**Après la recette 22.** Les trois jurés relèvent encore des fins de page de la même famille (trois bandeaux lavande centrés, et deux fins à la suite sur Comment ça marche), un quart vide en haut à droite de Cours et de Comment ça marche, la même vue du dessus sur trois pages, un haut d'accueil chargé (deux petites phrases, « 2024 » dit deux fois, le bouton pause hors de la marge) et l'encart « Les cours en bref » lu comme un mur de puces.

| # | Relevé | Correction |
|---|---|---|
| FF1 | Trois pages finissent sur le même bandeau lavande centré | Tarifs se referme sur ses deux prix, en grand, à côté du titre et de son bouton ; Familles sur une porte ouverte (recadrage sans personne) ; Comment ça marche garde seule le bandeau centré |
| FF2 | Comment ça marche : deux fins à la suite, et un haut de page vide à droite | « Des classes de 3 à 5 enfants, ou de 3 à 6 adultes » monte dans le haut de page, en grands chiffres tirés de la grille tarifaire, à côté du titre ; la bande plus bas disparaît |
| FF3 | Cours : un quart vide au-dessus de l'escalier | Au bureau, l'escalier monte dans le haut de page : les deux premières arches sous le texte, les deux dernières à sa hauteur, à droite, le mot arabe au milieu de l'arche |
| FF4 | La vue du dessus de la classe sur l'accueil, Familles et Cours | Elle ne reste qu'à l'accueil. Familles montre un « 3 » dans une arche (les trois séances de la semaine) ; Cours, l'arche vue d'en haut, sans personne |
| FF5 | Haut de l'accueil : deux petites phrases, « 2024 » deux fois, bouton pause à 44 px du bord | Le nom de l'académie passe dans la phrase sous le titre (« Chez Rewayah Academy, chaque élève suit… ») ; la date et les fondateurs ne sont dits qu'une fois, dans le bandeau « Accompagné » ; le bouton pause se pose sous le texte, sur sa marge (120 px) |
| FF6 | « Les cours en bref » : deux colonnes de puces, prix dans une phrase | Une fiche à la fois à toutes les largeurs (choix Enfants / Adultes) ; le montant en grand chiffre à gauche, les autres lignes à droite sur la 7e colonne. Les mots de l'encart du 18/10 ne changent pas |
| FF7 | Portraits des fondateurs à une autre échelle que le directeur ; un nom sur deux lignes | Recadrés plus serré (la tête fait 68 % de la hauteur), mur légèrement dégradé comme le sien ; chaque nom sous son portrait, sur une ligne |
| FF8 | La fin de l'accueil lue comme un tube | Le haut d'arche fondu est remplacé par une vraie porte sous son arche, dans un cercle |
| FF9 | Zoom de la porte jusqu'aux visages | La scène grandit deux fois au plus (au lieu de 2,7) et la classe apparaît plus tôt |
| FF10 | Académie : le bout du chemin coupé net (tablette, téléphone) | Il s'efface vers la droite |
| FF11 | Accueil, « Un horaire fixe » : le titre et son texte à gauche, la moitié droite vide | À partir de 1 100 px, le texte et les liens passent dans la colonne de droite |

**Lettres arabes des arches (directeur, 22/10/2026, registre M-31).** Le directeur trouve les inscriptions arabes de Cours peu jolies et demande une police d'ornement, koufi ou diwani, avec les voyelles. Comparaison faite sur les arches elles-mêmes : la seule diwani libre trouvée (Layla Diwani, OFL) est trop fine et place mal ses voyelles ; Reem Kufi (koufi, OFL) et Aref Ruqaa (roqaa, OFL) les placent bien. Reem Kufi est posée, réduite aux seize lettres du contenu et inscrite dans la feuille de style comme l'ancienne police (aucun fichier de plus à déployer) ; le directeur a laissé le choix le 22/10 : Reem Kufi reste (M-31).

**Demandes du directeur du 22/10 (suite).**
- *Tuile « La classe commence » (accueil).* L'arche du livre de l'image était coupée par l'arche de la fenêtre. Le rendu 02 est recadré plus large (680 × 850, marge transparente au-dessus) : l'arche du livre tient entière dans la fenêtre, et les deux courbes s'emboîtent.
- *Lettres arabes des arches (Cours).* Elles s'écrivent, arche après arche, en 3 s environ, une seule fois : les lettres séparées paraissent une à une de droite à gauche ; un mot lié s'écrit d'un trait de droite à gauche, sans être découpé (ses lettres restent liées). Au survol, l'arche s'écrit de nouveau. En mouvement réduit ou sans JavaScript, les lettres sont là, immobiles.
- *Changer une police.* Le site ne nomme plus ses polices qu'une fois, dans `:root` (`--police-titre`, `--police-corps`, `--police-arabe-ornement`) ; un test refuse tout autre nom de police dans la feuille. Rendu vérifié identique, élément par élément, sur huit pages. L'application avait déjà ce principe : `lib/core/theme/app_typography.dart` porte les cinq familles.

**Après la recette 23.** Les trois jurés tiennent pour corrigés les fins identiques, le haut vide de Cours et de Comment ça marche, la vue du dessus sur trois pages et le haut de l'accueil. Restent, en commun : le zoom de la porte (leur capture datait de la veille, refaite), l'arabe trop petit dans ses arches, la double fin de Comment ça marche, les disques de porte qui se lisent comme des tubes, les portraits des fondateurs petits à côté du directeur, et les puces de « Les cours en bref ».

| # | Relevé | Correction |
|---|---|---|
| GG1 | Comment ça marche finit encore sur deux bandes à la suite | Une seule fin : le titre et son bouton à gauche, l'inscription d'un enfant à droite, dans un encart (`fin.forme` « note ») ; la section n'est plus posée plus haut |
| GG2 | Disques de porte lus comme des tubes (fins de l'accueil et de Familles, Cours) | Des arches entières : la jeune élève au pupitre (fin de l'accueil), l'élève qui passe la porte (fin de Familles), la place qui attend, coussin et pupitre (Cours, « Trois séances par semaine ») |
| GG3 | Académie : la fin sombre se confond avec le pied de page | Elle finit sur l'homme au seuil de l'arche ouverte sur les dunes, l'arche à gauche du titre |
| GG4 | L'arabe des arches petit et ses voyelles trop fines | Mots liés à la taille des grands chiffres du site (environ 70 % de l'arche) ; police d'ornement en graisse 600 |
| GG5 | Zoom de la porte sur des visages agrandis | La scène grandit d'une fois et demie au plus, la classe s'ouvre plus tôt ; captures du mouvement refaites |
| GG6 | « Les cours en bref » : puces petites | La première ligne sert de sous-titre, le montant en très grand, les autres lignes sans puce ; sur l'accueil, ce qui vaut pour les enfants et les adultes n'est dit qu'une fois, sous les deux prix |
| GG7 | Portraits des fondateurs à la moitié de celui du directeur | Affichés à 336 px, sans agrandir leurs fichiers (cadrage plus large, la tête à 60 %), netteté légèrement relevée. Une photo plus nette d'Ahmad Diallo permettrait d'aller plus loin |

**Photos et parcours des fondateurs (22/10, suite).** Ahmad Diallo a choisi une autre photo de lui, plus nette : elle remplace la première, traitée comme les deux autres (détourée, mur du directeur, tête et épaules, même étalonnage, visage non retouché). Les deux fondateurs s'affichent à 400 px sans agrandir leurs fichiers. Leurs parcours suivent leurs propres textes : « Institut des qiraat (lectures du Coran) » en République de Guinée pour les deux ; Université du roi Abdelaziz à Djeddah pour Ahmad Diallo ; Mamadou Alimou Diallo est étudiant à l'Université islamique de Médine (la « licence » publiée jusque-là est retirée). L'arabe est gardé au registre (M-29).

**Après la recette 24.** Les trois jurés relèvent les arches de Cours vides sur les captures (prises pendant l'écriture), le bloc de prix de l'accueil encore en petites puces, les chapitres de l'accueil (texte petit et vide autour) et la fin de Tarifs qui redit les prix une troisième fois.

| # | Relevé | Correction |
|---|---|---|
| HH1 | Arches 3 et 4 vides sur les captures | Chaque mot est là en filigrane (18 %) dès le premier affichage, l'écriture le remplit ; elle dure 2 s ; police en graisse 700 (voyelles plus épaisses) ; la dernière arche en lavande |
| HH2 | Bloc de prix de l'accueil en petites puces | Ce qui vaut pour tous en quatre tuiles, sans puce ; l'observation d'une séance en phrase sous le prix des enfants |
| HH3 | Questions des familles : six réponses en deux colonnes | Un accordéon sur une colonne (details et summary), la première question ouverte, le titre et ses liens à gauche |
| HH4 | Chapitres de l'accueil : texte petit, beaucoup de vide | La première phrase de chaque chapitre plus grande ; chapitres moins hauts |
| HH5 | Tarifs finit sur ses prix une troisième fois | Le bandeau centré, sans prix (le seul de ce type sur le site) |
| HH6 | Académie redit le titre « Apprendre avec un enseignant » de Cours | « Ce que nous enseignons », comme le dit son texte |
| HH7 | Fin du zoom de la porte décentrée | La scène grandit d'un quart au plus |

**Après la recette 25.** Arches, tuiles de prix et accordéon tenus pour corrigés. Restent, en commun : les chapitres de l'accueil (petites puces à côté d'une grande arche), le rythme des pages (une image à côté d'un texte, six fois de suite), la fin de l'accueil sans bouton, l'arabe petit sur tablette et téléphone, « Trois spécialistes » au-dessus de deux portraits, et une tache au pied du socle du haut de l'accueil.

| # | Relevé | Correction |
|---|---|---|
| II1 | Chapitres : petites puces | Les points en pastilles sur une ligne |
| II2 | Une image à côté d'un texte, six fois de suite | Une bande pleine par page : Cours, « Trois séances par semaine » (la place qui attend, en grand) ; Académie, « Ce que nous enseignons » |
| II3 | Fin de l'accueil sans bouton | Titre, phrase et bouton « Commencer mon inscription » sous une arche plus grande |
| II4 | Arabe petit sur tablette et téléphone | À la mesure de l'arche (unités de conteneur) sur tablette ; 36 et 44 px au téléphone |
| II5 | « Trois spécialistes » au-dessus de deux portraits | Une ligne au-dessus d'eux : « Aux côtés du directeur, Abdoulaye Mouhidine Sow : » |
| II6 | Tache au pied du socle (haut de l'accueil) | Le bout droit du sol s'efface, comme le bout gauche du tapis |
| II7 | « Les cours en bref » : bande calme | Les lignes de l'encart en tuiles, deux par rangée, de même hauteur (mots inchangés) |
| II8 | « Un horaire fixe » : titre et texte décalés | Alignés par le haut |
| II9 | L'accueil ne montre qu'une photo ; « trois spécialistes » pour un seul visage | Les deux autres fondateurs, en petit, dans la bande « Accompagné à chaque étape », sous le lien vers le mot du directeur |
| II10 | « Une petite classe » : l'écran le plus vide | La classe vue du dessus un peu plus grande |

**Après la recette 26 (dernier lot, 22/10/2026).** Les jurés tiennent pour corrigés les arches, la fin de l'accueil et le rythme des pages. Restent, en commun : un reste de socle au pied du haut de l'accueil, les chapitres (titre petit, pastilles qui redisent le texte), « Les cours en bref » (une tuile seule, le prix loin de sa phrase), les deux fondateurs trop petits sur l'accueil, le texte secondaire à 17 px. Le directeur demande de finir sans nouvelle image (« ne me demande plus de générer encore des images ») : la variété des rendus, que les trois jurés citent encore, ne bougera plus dans ce lot.

| # | Relevé | Correction |
|---|---|---|
| JJ1 | Reste de socle à droite du haut de l'accueil | Nettoyé dans l'image elle-même (le bout du sol s'efface, les points isolés sont retirés) ; le masque CSS ne garde que le fondu de gauche |
| JJ2 | Chapitres : titre petit, pastilles qui redisent le texte | Titre à la taille des en-têtes de section dès 840 px ; les pastilles ne sont plus posées (le texte reste) |
| JJ3 | « Les cours en bref » : une tuile seule, le prix loin de sa phrase | La phrase sur toute la largeur, le prix juste dessous ; une dernière tuile seule prend la rangée entière (mots inchangés) |
| JJ4 | Fondateurs trop petits sur l'accueil | Sous la photo du directeur, 200 px chacun, nom et rôle dessous ; au téléphone, après le lien |
| JJ5 | Texte secondaire à 17 px | 18 px partout (`--t-petit`) |

Inspection des six pages : 0 FAIL hors Tarifs (une image, voulu). Aucun texte coupé au bord, de 390 à 1440 px. Aucune image agrandie à 390, 1024 et 1440 px. Tests : 69, OK.

**Représentant dans l'Union européenne.** Le réglage existe dans l'application (console d'administration, Protection des enfants, clé `conformite.representant_ue`), avec « Rewayah Academy » par défaut. Le site public, construit sans compte, ne peut pas le lire : le scénario `scenarios_pe_code_conduite_v2.sql` interdit la lecture anonyme. Il affiche donc la valeur par défaut. Quand l'administration aura saisi un autre nom, une ligne du contenu du site suffira à le reprendre.

**Version des textes juridiques et dates du paiement (le directeur laisse la décision à Claude, 22/10/2026).** « Version 2026-10-v1, texte du 18 octobre 2026 » reste en tête de chaque texte : c'est la ligne que l'application affiche (`VersionsJuridiques`, `juridique.version`) et la version qu'elle enregistre à chaque accord ; le site ne s'en écarte pas. La page Annulation renvoie à la page Tarifs pour les dates exactes, que Tarifs ne donnait pas : Tarifs a maintenant « Les dates du paiement », lues dans la décision du 18/10 (`calendrier_paiement` et `premiere_semaine_remboursee_jours` de `tarifs-2026-10-18.json`) : 7 jours après la première séance, renouvellement le 1er, rappels 7, 3 et 1 jour avant, délai de grâce du 1er au 3, suspension le 4, place gardée jusqu'au 15, libérée le 16 (décision du 23/10/2026, voir ci-dessous). Le build refuse un calendrier incohérent. Le texte juridique n'est pas modifié, sa version non plus. La base garde ces jours hors de `tarifs_publics()` : si la direction les change dans la base, la décision publiée doit changer avec eux. Deux relectures indépendantes ont confirmé les valeurs et resserré les mots : « des rappels », envoyés seulement si le paiement n'est pas passé ; « à partir du 4 » (la décision dit « le 4 au plus tôt ») ; l'impayé s'affiche chez le tuteur ou chez l'élève adulte ; la première semaine vaut pour toutes les formules, les dates du mois pour l'abonnement mensuel ; le droit de rétractation de 14 jours est rappelé ; si la politique affichée n'est pas encore en vigueur, la page dit à partir de quand.

**Date de libération de la place : écart levé (directeur, 23/10/2026).** La décision du 18/10 disait « gardée 14 jours après la suspension du 4, libérée le 18 » ; la base garde la place jusqu'au 15 inclus (`supabase/migrations/20261017171000_fac_b_01_factures_mensuelles.sql`, `v_conservation := v_mois + jours_conservation_place`). Le directeur a confié le choix à Claude, dans l'intérêt de l'académie : la règle de la base, la plus stricte, est retenue (gardée jusqu'au 15, libérée le 16). La décision des tarifs, ses valeurs et le site sont alignés ; la base ne change pas. **Reste à faire dans le lot FAC (spécifié, pas encore dans le code)** : aucune tâche ne libère encore la place le 16, et les relances et la suspension (FAC-F) attendent l'accord du directeur ; la politique 2.0.0 prend effet le 1er novembre 2026.

**Après la recette 27.** Les trois jurés plafonnent Rewayah à 6,5 pour une seule raison commune : les titres des chapitres de l'accueil, agrandis au tour précédent, tenaient sur trois lignes. Ils relèvent aussi un vide sous le prix de « Les cours en bref », les deux fondateurs encore petits avec un vide à leur droite, le reste du socle au pied de l'arche, le texte secondaire à 18 px et le bouton d'arrêt du tapis sans mot.

| # | Relevé | Correction |
|---|---|---|
| KK1 | Titres des chapitres sur trois lignes | La fenêtre de l'arche cède une colonne au texte (5 colonnes sur 12) ; les titres gardent leur taille et tiennent sur deux lignes de 1024 à 1920 px |
| KK2 | « Les cours en bref » : vide sous le prix, tuile étirée, dernière tuile seule | Le prix et sa phrase sur une rangée, puis les cinq tuiles sur toute la largeur : trois, puis deux, de même hauteur par rangée (mots inchangés) |
| KK3 | Fondateurs petits, vide à leur droite | À droite, sous le lien vers le mot du directeur, 300 px chacun ; à gauche, sous la photo, les trois engagements les uns sous les autres : les deux colonnes finissent ensemble ; au téléphone, les noms sur deux lignes alignés |
| KK4 | Reste du socle au pied de l'arche | Le bout du disque s'arrondit et s'efface dans l'image avant le bord de l'écran |
| KK5 | Texte secondaire à 18 px | 20 px au bureau, 18 px en dessous ; pied de page à 18 px |
| KK6 | Bouton d'arrêt du tapis sans mot | Il dit « Arrêter l'animation du tapis » en toutes lettres |
| KK7 | (relevé en vérifiant) Fin de Comment ça marche plus large que l'écran à 360 px | La colonne ne s'élargit plus à la mesure de l'adresse e-mail |

**Après la recette 28.** Plus aucun plafond : titres sur deux lignes, bande des fondateurs et bouton du tapis tenus pour corrigés. Restent, en commun : le reste de sol au pied de l'arche du haut de l'accueil, le texte secondaire encore petit, le bas de Tarifs qui se lit comme un document, les tuiles inégales de « Les cours en bref », et (deux jurés) l'image seule entre deux vides de « Ce que nous enseignons » sur Académie.

| # | Relevé | Correction |
|---|---|---|
| LL1 | Reste de sol à droite du pied de l'arche | Dans l'image, le sol s'arrête au ras de la face droite de l'arche, et sous l'arche son bord recule en biais et s'efface dans le violet |
| LL2 | Texte secondaire petit | Texte courant à 21 px à 1440 (`--t-corps`), petit texte à 20 px |
| LL3 | Tarifs : trois blocs de chiffres et de petites lignes à la suite | Les dates du paiement sur une rangée de cinq étapes, chacune marquée d'une petite arche, sur fond prune ; « À savoir avant de commander » repasse sur le violet de la page |
| LL4 | « Les cours en bref » : tuiles à moitié vides | Chaque tuile est large à la mesure de son texte (douze colonnes réparties au build au prorata du nombre de lettres) : les longues sur une rangée, les courtes sur la suivante ; un test vérifie que chaque rangée remplit ses douze colonnes |
| LL5 | Académie, « Ce que nous enseignons » : une image seule entre deux vides | Le titre centré, l'arche au milieu, un paragraphe de chaque côté (dès 1100 px) |
| LL6 | Bouton d'arrêt du tapis aussi visible qu'un bouton d'action | Un texte avec son signe, sans bord, en 16 px |

**Après la recette 29.** Toujours sans plafond. Restent, en commun : le bas de Tarifs qui se lit comme un document, « Les cours en bref » (bords de tuiles qui ne tombent pas sur une même grille, phrase loin du prix), « Ce que nous enseignons » (deux paragraphes dans des coins opposés), le dernier reste de sol sous la face droite de l'arche, le bouton du tapis disjoint au téléphone, et, pour deux jurés, le titre du chapitre suivant qui entre dans l'image épinglée.

| # | Relevé | Correction |
|---|---|---|
| MM1 | Tarifs, remises : six chiffres sur des légendes | Chaque remise dans une tuile coiffée d'une arche, le chiffre au centre |
| MM2 | Tarifs, dates du paiement : cinq colonnes de texte | Les cinq étapes sur un même rail, chacune posée sur sa petite arche ; légendes raccourcies (les mots de la décision gardés : rappels 7, 3 et 1 jour avant, place gardée 14 jours) |
| MM3 | « Les cours en bref » | Le prix, puis sa phrase juste dessous ; les tuiles sur six colonnes, de même largeur dans une rangée (trois puis deux) ; le choix Enfants / Adultes en haut à droite |
| MM4 | « Ce que nous enseignons » | L'arche à gauche ; à droite, le titre et les deux paragraphes l'un sous l'autre, à 23 px |
| MM5 | Reste de sol sous la face droite de l'arche | Le flanc du disque s'efface vers le bas et vers la droite dans l'image ; il ne reste que le sol devant la porte |
| MM6 | Bouton du tapis disjoint (tablette, téléphone) | Le signe et le mot ensemble, au bord du texte |
| MM7 | Le titre du chapitre suivant entre dans l'image | Chaque chapitre a la hauteur de la fenêtre de l'arche ; le second paragraphe passe à 22 px |
| MM8 | Familles, téléphone : la tuile du « 3 » à moitié vide | À la hauteur de son contenu |

**Après la recette 30.** Restent, en commun : le bas de Tarifs (tuiles de remises de hauteurs inégales, dates en colonnes étroites, tableau et puces), « Les cours en bref » (bords de tuiles sur deux grilles), le second paragraphe des chapitres plus petit que le premier et le titre suivant visible à 1280 × 720, un dernier voile sous le sol à droite de l'arche (vu en double résolution).

| # | Relevé | Correction |
|---|---|---|
| NN1 | Remises : rangées de hauteurs inégales, tuile du 10 % vide | Quatre colonnes ; les deux remises aux longues légendes prennent deux colonnes chacune ; chiffre et légende alignés à gauche |
| NN2 | Dates du paiement en colonnes étroites | Au bureau, une frise verticale : la date à gauche, le texte à droite, les petites arches sur un même fil, la phrase d'introduction à côté |
| NN3 | Ce que coûte une famille : des lignes de tableau | Les quatre totaux en tuiles blanches coiffées d'une arche, deux par rangée (rôles ARIA ajoutés pour garder la lecture en tableau) |
| NN4 | À savoir avant de commander : une liste à puces | Les cinq points sur deux colonnes, chacun avec sa puce |
| NN5 | « Les cours en bref » : bords de tuiles sur deux grilles | Les phrases courtes ne sont plus des tuiles mais des lignes marquées de la petite arche ; la grille occupe toute la largeur |
| NN6 | Chapitres : second paragraphe plus petit, titre suivant visible | Les deux paragraphes à la même taille ; chaque chapitre occupe un écran entier |
| NN7 | Voile sous le sol à droite de l'arche | Dans l'image, sous le bord du sol blanc, le flanc du disque s'efface vers la droite (bord du sol trouvé colonne par colonne) |

**Après la recette 31.** Un juré compte les rendus comme des dessins et applique le plafond « moins de quatre vraies photos » : c'est la limite des images, que le directeur a close le 22/10. Restent, en commun : les deux phrases courtes de « Les cours en bref » sur une autre grille que les tuiles, le bas de Tarifs (« À savoir » en puces, le coût d'une famille en tableau au téléphone, les remises en colonne au téléphone), le bloc des prix de l'accueil.

| # | Relevé | Correction |
|---|---|---|
| OO1 | « Les cours en bref » : deux phrases courtes sur une autre grille | Chacune en pastille calée sur le bord gauche des tuiles, une par rangée ; au téléphone, tuiles et pastilles aussi |
| OO2 | Tarifs, « À savoir » en puces | Le titre, les deux paragraphes côte à côte, puis les cinq points en tuiles coiffées d'une arche, trois puis deux |
| OO3 | Tarifs au téléphone : remises en colonne, famille en tableau | Les quatre remises courtes deux par rangée, les deux longues pleine largeur ; le coût d'une famille en tuiles à toutes les largeurs |
| OO4 | Accueil, le prix : un bloc de fiche technique | Les deux montants plus grands ; les quatre points communs en tuiles coiffées d'une arche |
| OO5 | Académie : trois bandes « image à gauche » de suite | « Ce que nous enseignons » passe l'arche à droite |
| OO6 | (relevé par l'inspecteur) Dix tailles de texte sur l'accueil | Les paragraphes des chapitres à la taille des sous-titres, le mot du bouton du tapis à 18 px : huit tailles |

**Après la recette 32.** Les trois jurés comptent désormais les rendus comme des illustrations et plafonnent le dessin à 6,5 : le site n'a que trois vraies photographies (les fondateurs). C'est la limite des images, close par le directeur le 22/10 ; seule une vraie photographie de plus (une séance, une famille, un écran réel de l'application) la lèverait. Ils relèvent aussi un vrai défaut, introduit au tour précédent : au téléphone, dans « Ce que coûte une famille », le nombre d'enfants et le montant se superposaient.

| # | Relevé | Correction |
|---|---|---|
| PP1 | Téléphone : « 2 enfa105,60 $ » | Dans chaque tuile, le nombre d'enfants au-dessus du montant ; un contrôle de chevauchement des textes est ajouté à la vérification (360 à 1440 px) |
| PP2 | « À savoir » en puces sur tablette et téléphone | Des tuiles à toutes les largeurs : une colonne au téléphone, deux sur tablette, trois puis deux au bureau |
| PP3 | « Les cours en bref » : deux pastilles hors de la grille | Deux tuiles de même largeur sous les trois (une et demie chacune), même aspect |
| PP4 | Quatre formes de tuiles | Deux seulement : l'arche pour les chiffres (remises, coût d'une famille), l'angle arrondi pour les notes |
| PP5 | Accueil, questions des familles : colonne de gauche vide | Elle reste à l'écran le long des questions |

**Après la recette 33.** Les jurés appliquent la définition du skill (photographies et images raster comptent, dessins SVG non) : plus de plafond. Restent, en commun : plusieurs formes de tuiles (arrondis en pourcentage qui changent avec la largeur), la bande des dates avec une colonne vide, et une bavure au pied de l'arche du haut de l'accueil, laissée par le nettoyage du tour 29 (le bas de la face droite de l'arche était estompé).

| # | Relevé | Correction |
|---|---|---|
| QQ1 | Formes de tuiles qui changent avec la largeur | Une seule forme pour les tuiles d'information, chiffres compris : l'angle arrondi de 24 px ; l'arche reste aux images. Remises et notes à la hauteur de leur texte |
| QQ2 | Dates du paiement : colonne vide à droite | Le titre et sa phrase en haut, puis la frise sur toute la largeur, chaque date suivie de sa phrase sur une ligne |
| QQ3 | Bavure au pied de l'arche | Image refaite depuis la source propre : la face de l'arche est gardée entière, seul le sol qui dépasse est retiré, le long du bord bas de la face et du bord du sol blanc |
| QQ4 | Téléphone : phrase « Rien n'est facturé… » sous l'image | Elle suit les deux boutons, avant l'image |
| QQ5 | Pied de page long au téléphone | Les liens sur deux colonnes |

**Après la recette 34.** Restent, en commun : le pied de page sur tablette (deux colonnes qui se touchaient, défaut introduit au tour précédent), le pied de page encore long au téléphone, des tuiles de hauteurs inégales ou au bas vide, et l'action principale absente de l'en-tête.

| # | Relevé | Correction |
|---|---|---|
| RR1 | Tablette : « L'académie » contre « Assistance » | La règle à deux colonnes du tour précédent est retirée ; la liste « Découvrir » reste en une colonne sur tablette |
| RR2 | Téléphone : pied de page long | Les liens « Découvrir » et les liens légaux en lignes qui se suivent, sans coupure dans un lien |
| RR3 | Tuiles de hauteurs inégales | Dans une rangée, une même hauteur ; remises : le chiffre en haut, la phrase en bas ; notes et cours en bref : le texte au milieu |
| RR4 | Familles, téléphone : la tuile du « 3 » en dôme aplati | Une tuile carrée au sommet en demi-cercle |
| RR5 | En-tête : l'action principale absente | Dès 1100 px, « Commencer mon inscription » en bouton plein (vers la connexion à l'application, comme les autres boutons d'inscription) ; « Se connecter » devient un lien |

**Après la recette 35.** Les trois jurés s'accordent sur quatre points : pas d'action d'inscription dans l'en-tête sur tablette et téléphone, un pied de page encore long au téléphone, Tarifs en murs de tuiles, et un vide à droite de l'arche épinglée entre deux chapitres de l'accueil.

| # | Relevé | Correction |
|---|---|---|
| SS1 | En-tête sans action sous 1100 px | « S'inscrire » en bouton plein à côté du menu (mot ajouté au vocabulaire) ; « Commencer mon inscription » au-delà |
| SS2 | Chapitres : colonne vide pendant le passage d'un chapitre à l'autre | Le texte de chaque chapitre reste à l'écran à côté de l'arche jusqu'à ce que le suivant le pousse |
| SS3 | Tarifs, remises en tuiles | Une liste sans boîtes sur deux colonnes : le chiffre en grand, sa phrase à côté |
| SS4 | Tarifs, « À savoir » en tuiles | Une liste à puces sur deux colonnes |
| SS5 | Dates du paiement : un fil vertical | Les petites arches seules, sans fil |
| SS6 | Pied de page : identité serrée sur tablette, long au téléphone | Tablette : l'identité sur toute la largeur, liens et adresses côte à côte ; téléphone : adresses sur une ligne chacune, liens Facebook en petit et sans soulignement |

**Après la recette 36.** Les trois jurés s'accordent sur deux points : le pied de page encore long au téléphone (1,38 écran) et presque un écran sur tablette, et, sous le simulateur de Tarifs, quatre sections bâties de la même façon. Deux jurés ajoutent : au téléphone, la famille du haut de l'accueil sous le premier écran, et sous chaque texte de chapitre un vide d'un tiers d'écran. En cherchant, un défaut de notre fait : entre 840 et 1099 px, le pied de page plaçait « Découvrir » hors de sa colonne.

| # | Relevé | Correction |
|---|---|---|
| TT1 | Téléphone : pied de page de 1,38 écran | 0,76 écran : l'adresse en une phrase ; « Découvrir » et « Nous contacter » en volets qui se replient au téléphone (ouverts sans script et au-delà de 599 px) ; liens légaux en lignes qui se suivent |
| TT2 | Tablette : pied de page d'un écran ; 840-1099 px : colonnes décalées | Identité et adresses côte à côte, « Découvrir » en lignes qui se suivent dessous (0,77 écran à 768 px) ; les règles éparses des tours précédents réunies en un seul bloc |
| TT3 | Tarifs : quatre sections pareilles | Dates du paiement : une frise de cinq dates en grand, côte à côte, chacune sous sa petite arche ; coût d'une famille : les quatre totaux sur une rangée, en grands chiffres ; « À savoir » : la règle « pas d'essai » en phrase de titre |
| TT4 | Téléphone : la famille sous le premier écran | La phrase « Rien n'est facturé… » passe sous l'image (comme avant QQ4) : la mère, sa fille et la classe entrent dans le premier écran |
| TT5 | Chapitres : un tiers d'écran vide sous le texte | Le texte se tient au milieu de l'arche épinglée ; le premier chapitre descend un peu (son texte ne couvre plus la phrase qui le précède) ; le dernier se centre sans épinglage et part avec l'image |
| TT7 | Trouvé en refaisant les captures : dans la fenêtre épinglée, les mains ne montaient plus vers le Coran (l'image ne bouge pas, le calcul suivait sa position) | Les mains montent pendant que le titre de leur chapitre passe de 60 % à 30 % de la hauteur de l'écran |
| TT6 | Point-virgule en début de ligne, apostrophes droites | Espace insécable avant « : ; ? ! » dans les textes des tarifs ; apostrophes typographiques dans « À savoir » |

**Après la recette 37.** Les trois jurés s'accordent : le pied de page reste lourd sur tablette (ouvert, 0,77 écran) ; sous le simulateur de Tarifs, les dates du paiement et « À savoir » gardent la même ossature (titre, puis petites colonnes). Deux jurés relèvent le passage d'un chapitre à l'autre (l'arche change d'image alors que l'ancien texte se lit encore) et, sur Cours, la bande « Trois séances par semaine » (titre à gauche, image centrée, texte dessous, vide de part et d'autre). Deux jurés, sur deux tours, trouvent que la ligne « Arrêter l'animation du tapis » fait outil de développeur. Un juré a vu trois captures périmées : le script de capture ne vidait pas le dossier ; il le vide désormais.

| # | Relevé | Correction |
|---|---|---|
| UU1 | Tablette : pied de page ouvert, 0,77 écran | Volets jusqu'à 1099 px : identité à gauche, « Découvrir » et « Nous contacter » à droite, fermés (0,51 écran à 768 px) |
| UU2 | Bureau : pied de page de 0,77 écran | « Découvrir » sur deux colonnes ; la langue, la page Facebook et l'auteur sur une ligne qui se replie (0,67 écran) |
| UU3 | Tarifs : les remises en petits chiffres | Six grands chiffres sur deux rangées de trois, leur phrase dessous |
| UU4 | Tarifs : les dates en petites colonnes | Cinq arches qui montent, comme les étapes de Cours, chacune portant sa date en grand, la phrase dessous |
| UU5 | Tarifs : « À savoir » en liste à puces | La règle « pas d'essai » d'abord, en grande phrase ; les autres points sur deux colonnes, sans puces ; les deux paragraphes ensuite |
| UU6 | Chapitres : deux textes à la fois au passage | Le texte qui sort s'efface pendant que le titre suivant monte de 75 % à 60 % de l'écran ; l'arche change quand il n'est plus lisible ; un lien qui reçoit le focus reste visible |
| UU7 | Cours : « Trois séances par semaine » éparpillée | L'arche à gauche, le titre, le texte et les deux liens à droite |
| UU8 | Accueil : la ligne « Arrêter l'animation du tapis » | Un rond de 44 px avec son seul signe ; son nom reste lu par les lecteurs d'écran et s'affiche au survol |

Relecture adverse de ce tour (trois relecteurs, chaque relevé vérifié par un second agent chargé de le réfuter) : six défauts confirmés, tous corrigés et vérifiés en rejouant les scripts des relecteurs.

| # | Relevé confirmé | Correction |
|---|---|---|
| UU9 | Chapitres : un texte effacé restait cliquable (un lien invisible ouvrait une page) | Effacé, le texte ne prend plus les clics ; il les reprend s'il reçoit le focus |
| UU10 | Chapitres : en passant au mouvement réduit page ouverte, un texte effacé restait invisible | L'effacement ne joue qu'à l'écran et sans mouvement réduit |
| UU11 | Impression en paysage : le texte des chapitres déjà passés manquait | Même règle : rien n'est effacé à l'impression |
| UU12 | Impression en portrait depuis un ordinateur : les volets du pied de page se fermaient (adresses perdues) | À l'impression, les volets restent ouverts ; ils retrouvent leur état ensuite |
| UU13 | Tarifs : la phrase « pas d'essai » sur trois lignes ; onze tailles de texte sur la page | Deux lignes ; tailles réunies (les dates, la phrase et les totaux d'une famille ensemble, les remises à la taille des titres de section) |

**Après la recette 38.** Rewayah monte à 7,90. Les trois jurés s'accordent : le pied de page reste lourd au bureau (0,67 écran) et au téléphone (0,7) ; sur tablette, « Trois séances par semaine » est encore empilée ; au changement de chapitre, l'arche montre un instant la nouvelle image seule, le nouveau texte encore bas. Un juré demande les arches des dates aussi sous 1100 px, un autre un bouton pause plus visible.

| # | Relevé | Correction |
|---|---|---|
| VV1 | Bureau : pied de page de 0,67 écran | Des rangées : le logo et l'adresse sur une ligne, les pages, les quatre adresses, les liens légaux, la langue et les crédits (0,47 écran) |
| VV2 | Téléphone et tablette : liens légaux toujours ouverts | Troisième volet « Informations légales », fermé sous 1100 px (ouvert sans script et à l'impression) : 0,62 écran au téléphone, 0,40 sur tablette |
| VV3 | Tablette : « Trois séances par semaine » empilée | Deux colonnes dès 700 px, l'arche à gauche |
| VV4 | Chapitres : l'image nouvelle seule, le texte encore bas | L'arche change quand le titre suivant passe 43 % de la hauteur de l'écran ; le texte qui sort s'efface avant (58 % à 45 %), celui qui entre apparaît presque à sa place (43 % à 35 %) ; les mains montent à partir du changement |
| VV5 | Tarifs sous 1100 px : les dates sans arches | Les cinq arches, de plus en plus hautes, l'une sous l'autre, la phrase à côté |
| VV6 | Bouton pause peu visible | Contour blanc |

**Après la recette 40, la dernière.** Rewayah à 7,78, devant Hallow (6,78) et Waking Up (6,50) ; les trois jurés
répondent encore « presque ». Ils confirment réglés le passage d'un chapitre à l'autre (un seul texte à la fois)
et « À savoir » à la taille du texte ; le pied de page a baissé (0,43 écran au téléphone, 0,30 sur tablette) mais
reste à 0,41 au bureau. Le directeur arrête les recettes le 23/10/2026 (« il faut en finir, il reste beaucoup
d'autres choses à faire ») et garde les rendus actuels. Points communs non traités, à reprendre seulement sur sa
demande :

| # | Relevé (jurés) | Piste |
|---|---|---|
| WW1 | Pied de page au bureau : cinq rangées de texte de 16 px, 0,41 écran (3 jurés) | Trois colonnes (pages, adresses, informations légales), le crédit dessous : 0,25 écran |
| WW2 | « Les cours en bref » : cinq pastilles qui ressemblent à des boutons (3 jurés) | La première phrase en grand, les quatre autres en lignes simples sur deux colonnes, texte inchangé |
| WW3 | Même module de section répété (arche, titre, paragraphe, petit lien) (2 jurés) | Une section par page en grande arche plein écran, une autre en bande de phrase |
| WW4 | Chapitres de l'accueil : arche modeste (62 % de la hauteur) (2 jurés) | Arche à 80 % de la hauteur de l'écran |
| WW5 | Titres de section à 2,4 fois le texte, hiérarchie plate sous le premier écran (2 jurés) | Titres de section plus grands |
| WW6 | Liens fléchés secondaires de 16 px, faibles à côté des titres (2 jurés) | 18 à 20 px, soulignés, 44 px de hauteur touchable |
| WW7 | Tarifs : une seule image sur la page (inspecteur) | Un détail sans personne à côté d'« À savoir » et en fin de page, sans casser les mises en page des dates et des règles |

## Hors de portée de l'agent

- `.github/workflows/flutter-deploy.yml` vérifie la présence de 8 fichiers du site, mais pas de `motion.js`. Le garde du dépôt interdit à l'agent d'écrire dans `.github/`. Le test `test_only_approved_public_assets_are_copied` couvre ce fichier côté tests.
- L'outil REA (Reverse Engineer Anything) n'est installé qu'en ligne de commande, dans l'espace de travail de la session. Son inscription comme serveur MCP et comme skill demande une règle de permission du directeur.
