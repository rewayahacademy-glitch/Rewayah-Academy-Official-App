# Audit et plan de reprise visuelle du 9 octobre 2026

## 1. Périmètre et preuves

Demande : analyser la version précédente, établir un plan détaillé, puis appliquer la direction des maquettes. Aperçu local uniquement. Branche `codex/site-public-2026-10-08`, base `19ec3dced0c34b2a63ecd4aa02c393e0fec3b06c`. Les fichiers du site et sa documentation sont déjà non suivis ; le workflow a une modification préexistante. La reprise porte sur `site-public/` et ce rapport. Aucun fichier Flutter, Finance, migration ou workflow ne fait partie des corrections.

Sources : les deux plans du directeur actualisés le 9 octobre ; neuf images `exec-...` présentes dans Downloads/RA logo 2026/visuels site public, toutes ouvertes ; pack autonome de trois personnes ; SVG officiels. Les illustrations ne sont pas des photos de clients ni des captures de production.

Captures de départ : `captures/reprise-finale/before-1440-*.png`, produites dans Chrome par CDP. Les captures hors écran initiales ne déclenchent pas toutes les images lazy : leur absence dans ces captures ne prouve pas une panne réseau. Les constats de placement, contenu et styles sont corroborés par le générateur HTML et la CSS.

## 2. Écarts constatés

| Priorité | Zone | Constat | Cause | Correction |
|---|---|---|---|---|
| P1 | Header | Inscription dupliquée, navigation décalée vers le centre | Bouton supplémentaire dans le template | Supprimer ce bouton, conserver cinq liens alignés à droite |
| P1 | Hero | Titre trop étroit, scène réduite et éloignée des actions | `20ch`, max-width image 65rem, transparence interne non prise en compte | Titre sur deux lignes à grande largeur, scène large, ajuster l'espace d'après les pixels utiles |
| P1 | Global | Mauvaises teintes surface/action/texte | Empilement de palettes puis overrides | Une seule palette exacte : #1A1A25 / #22222E / #F5F2FA / #BA98FB / #25113F |
| P1 | Global | Alternance mécanique sans lien avec maquettes | `nth-of-type(even)` | Composition explicite par section ; seul Suivi inverse les colonnes |
| P1 | Foyer | Deux cartes génériques séparées sans anatomie Foyer | Démonstration trop simplifiée | Un fragment Foyer, deux lignes de profils, perspective légère, légende illustrative |
| P1 | Cours | Carte sombre textuelle, portrait sans masque, titre modifié, données non structurées | Composant générique | Support clair dominant, exemple linguistique HTML, portrait circulaire secondaire, tableau enfants/adultes |
| P1 | Suivi | Image seule, historique absent, position opposée à la maquette | Composition manquante | Mère à gauche, fragment historique à proximité, texte/observation/action à droite |
| P1 | Inscription | Étapes à gauche et texte à droite, petits numéros | Alternance et styles génériques | Texte gauche, grandes étapes à droite ; aucun horaire disponible inventé |
| P1 | Tarifs | Petit encadré remplace tableau/exemples | Source tarifaire absente, gabarit incomplet | Retrouver la structure titre/tableau/explication, état indisponible honnête, modal conservé |
| P1 | Académie | Date géante isolée et titre en colonne | Mauvaise hiérarchie | Date discrète au-dessus du titre centré, deux arguments, action centrale |
| P1 | FAQ | Colonne vide, aucune question déroulante | Aucun composant rendu | Quatre `details/summary`, première réponse ouverte, ressources existantes à gauche |
| P1 | Dernier CTA | Titre inscription suivi de contacts | Liens inadaptés | Deux boutons inscription/connexion vers parcours canonique |
| P1 | Footer | Siège absent, liens légaux mélangés aux liens découverte | Gabarit incomplet | Trois colonnes puis ligne légale et crédits séparés |
| P2 | Mobile | Risque de tailles et ordre visuel hérités du desktop | Breakpoints cumulés | Une colonne, texte avant preuve, largeurs fluides, actions et tableaux lisibles |
| P2 | Aperçu | URLs propres des sous-pages non servies par http.server standard | Rewrites Vercel non émules | Serveur local qui résout uniquement les pages générées, vrai 404 ailleurs |

## 3. Inventaire et placement des images

| Section | Maquette | Média autonome | Placement cible |
|---|---|---|---|
| Hero | exec-3b598c8f-26e9-41d1-9027-7ef27904b608.png | hero-enfant-cours.png | Sous les deux CTA ; enfant droite, écran enseignant gauche ; proportion intacte, aucun cadre |
| Foyer | exec-1eef2cc4-4eb0-4df5-bfb1-6b89e3b1a819.png | Aucun | Fragment HTML à droite ; deux profils illustratifs, pas d'identités réelles |
| Cours | exec-47ac8c87-7385-4cc0-b5fc-f691454bd8d0.png | enseignant-portrait.png | Petit cercle dans l'angle supérieur gauche du support ; aucun portrait grandeur colonne |
| Suivi | exec-89b54e29-a443-4d46-a843-d40a136fb5d7.png | suivi-parent-tablette.png | Grande scène à gauche ; historique en haut/droite de la scène sans cacher visage ni tablette |
| Inscription | exec-c18e9384-1629-45d7-a9dd-aea39436d380.png | Aucun | Trois étapes éditoriales à droite |
| Tarifs | exec-91cf3535-3338-491f-b970-56457db4a70a.png | Aucun | Tableau HTML, aucun prix aplati dans une image |
| Académie | exec-75f86658-4c22-42a9-a8e5-2ac02b5357d9.png | Aucun | Composition typographique centrée |
| FAQ | exec-86abbb6c-5a89-47b1-83be-574ce3690c6b.png | Aucun | Listes et accordéons HTML |
| Footer | exec-78e3b1f6-7c39-4290-9f1e-de864a2156cd.png | logo-horizontal-white.svg | Logo complet dans colonne identité ; icône seule au header selon instruction récente |

Les PNG originaux sont conservés. Aucun découpage des personnes dans une maquette, aucune génération d'asset supplémentaire. Les ajustements de cadrage utilisent les dimensions et la transparence observées, avec CSS ; les textes de démonstration restent accessibles. Les extraits HTML portent une légende d'exemple et ne sont pas déclarés captures de l'application.

## 4. Plan d'exécution détaillé

### Lot A : socle visuel

1. Conserver les quatre fonts locales et leurs licences.
2. Remplacer les palettes contradictoires par les cinq tokens validés ; distinguer contour décoratif et contour de contrôle.
3. Définir largeur maximale, marges fluides, échelle titres/corps/boutons ; reprendre l'échelle des maquettes sans réduire les textes sur mobile.
4. Supprimer bordures entre toutes les sections, alternance automatique, fond différent de footer, vieux styles inutilisés.
5. Header icône 48 px environ, lien nommé pour lecteur d'écran, nav à droite ; menu mobile natif à moins de 800 px.
6. Vérifier contrastes calculés, fonts chargées et fond réel dans Chrome.

### Lot B : hero et trois démonstrations

1. Hero : titre centré, largeur suffisante pour deux lignes desktop, nom Rewayah Academy 11-12 px, corps limité, deux boutons même hauteur.
2. Donner à la scène une largeur qui rend écran distant et enfant lisibles ; compenser seulement le vide transparent supérieur. Pas de visage coupé.
3. Foyer : titre d'interface, sous-titre, deux lignes avec initiales ; angle fixe faible. Reprendre séparément la phrase sur le parcours adulte. Bouton plein.
4. Cours : titre exact ; tableau effectifs/durées et fréquence ; langues sous le CTA. Support clair avec trois exemples de voyelles de la maquette, jamais un verset. Portrait masqué circulairement et discret. Légende explicite.
5. Suivi : histoire visuelle en deux plans. Historique compact avec catégories de suivi et durée cohérente ; aucun score ni résultat pédagogique inventé. Observation complète à proximité du texte.
6. Mobile : supprimer perspective si elle nuit à la lecture, scène après texte, fragment historique dans le flux s'il masque le sujet.

### Lot C : sections éditoriales et conversion

1. Inscription : étapes 01/02/03 avec numéros lavande à gauche de chaque texte, séparateurs entre étapes ; CTA plein et secondaire bordé.
2. Tarifs : gabarit pleine largeur, tableau accessible sans prix inventé, zone latérale d'explication et bouton de simulation. Source Finance manquante explicitement séparée de la fidélité graphique.
3. Académie : date au-dessus du titre, intro centrée, deux arguments alignés, CTA central, identité discrète.
4. FAQ : quatre questions exactes du plan ; interaction clavier native, marque d'expansion CSS ; liens vers pages existantes, aucun article fictif.
5. Dernier CTA : inscription puis connexion, texte familial ; les contacts retournent au footer.
6. Footer : logo complet, entreprise et siège ; liens découverte ; quatre aliases ; navigation légale distincte ; Facebook et crédit approuvés.

### Lot D : interactions et pages secondaires

1. Conserver les URLs des 17 pages et l'entrée `/connexion` existante.
2. Harmoniser leurs gabarits, titres, listes, marges et footer avec la landing.
3. Corriger fermeture du modal au clic dans ses marges : seul le vrai backdrop doit fermer.
4. Vérifier Escape, restitution du focus, erreur de répartition, accès clavier.
5. Ajouter transitions brèves non récurrentes ; contenu visible sans JS, réduction du mouvement respectée. Pas de scroll forcé.
6. Servir les URLs propres dans l'aperçu local ; ne pas simuler une connexion réussie quand le bundle Flutter n'est pas servi.

### Lot E : recette et preuves

1. Reconstruire le site, exécuter les contrôles existants et contrôler le diff.
2. Capturer dans Chrome en 390, 768, 1440 et 1920 ; contrôler aussi 320 et reflow à 200 %.
3. Déclencher le chargement des médias par défilement avant la capture ; attendre les fonts et les images utiles.
4. Examiner hero, Foyer, Cours, Suivi, Inscription, Tarifs, Académie, FAQ, Footer séparément ; comparer aux neuf références.
5. Mesurer débordement, images cassées, erreurs JS, couleur effective, navigation et interactions.
6. Vérifier pages Cours, Familles, Tarifs, Aide et Mentions en plus de la landing ; vérifier tous les liens internes générés.
7. Rendre l'aperçu local accessible et livrer ce rapport complété des preuves réelles.

## 5. Critères d'acceptation et limites

- Identité et fonds fidèles ; aucun titre raster ou frame décoratif autour des personnes.
- Les trois scènes ont l'importance et le placement de leur maquette ; chaque section possède sa propre composition.
- Aucun débordement horizontal à 320/390/768/1440/1920 ; éléments interactifs utilisables au clavier et texte agrandi.
- Les informations importantes restent lisibles sans animation ; une seule direction artistique sur toutes les pages.
- La ressemblance ne doit pas masquer les dépendances : prix/remises dynamiques et simulateur demeurent bloqués par l'absence de projection Finance ; les vrais extraits Flutter anonymisés restent à fournir pour remplacer les démonstrations HTML. Pas de prétention à une conformité visuelle et fonctionnelle intégrale tant que ces dépendances existent.

## 6. Résultat de la reprise

### Réalisé

Les lots A, B et C sont intégrés au générateur et à la feuille de styles. Header corrigé, titre élargi, scène hero rapprochée, palette exacte, ordre des colonnes explicite, fragment Foyer, support clair et portrait circulaire, mère et historique, étapes, gabarit tarifaire, académie centrée, quatre FAQ natives, CTA final et footer avec siège. Les PNG et SVG d'origine sont conservés. Les textes publics ont été alignés sur le plan.

Lot D : styles communs appliqués aux 17 routes ; fermeture accidentelle du dialog au clic dans son padding corrigée ; serveur local `preview_site.py` ajouté pour les URL sans extension. `/connexion` reste une dépendance au bundle de l'application, absent de cet aperçu ; aucun faux parcours de connexion n'est fourni.

### Testé localement

- `python -m unittest site-public/tests/test_build_site_qa.py` : 9 tests réussis, 17 routes reconstruites.
- Chrome 390, 768 et 1440 : largeur du document égale au viewport, aucun élément débordant relevé, aucune image cassée après défilement, aucune exception JavaScript relevée.
- Pages Familles et Tarifs en URL propre : HTTP 200. `git diff --check` sans erreur de whitespace.
- Deux familles typographiques locales chargées ; fond calculé `rgb(26, 26, 37)`, équivalent exact de #1A1A25.
- Captures par section dans `captures/reprise-finale/after-{largeur}-{section}.png`. Hero, Cours, Suivi, Académie et FAQ inspectés visuellement en comparaison avec les maquettes ouvertes.
- Aperçu avec URL propres : `http://127.0.0.1:8766/fr/`.

### Écarts restants et contrôles non revendiqués

Le tarif connecté et les exemples chiffrés restent bloqués par la projection Finance manquante. Le tableau montre donc un état sans montants inventés. Foyer et Historique sont des démonstrations HTML légendées ; de véritables extraits Flutter anonymisés restent nécessaires pour fermer la fidélité des preuves produit. Les scènes autonomes diffèrent légèrement des personnes des maquettes, conformément au pack livré.

La recette clavier complète, lecteur d'écran, zoom 200 %, mesure de performance et validation contractuelle ne sont pas certifiées par ces captures. Aucun staging ni déploiement n'a été effectué. La demande d'accélération du directeur a conduit à privilégier les vérifications visuelles et les tests existants avant remise de l'aperçu.

### Parcours audité après correction

1. Hero : hiérarchie et marque corrigées, scène distante visible.
2. Foyer : composition corrigée ; démonstration, pas capture de production.
3. Cours : support dominant, portrait secondaire et informations pédagogiques lisibles.
4. Suivi : placement corrigé et règles d'observation conservées.
5. Inscription : étapes à droite sur ordinateur, après le texte sur mobile.
6. Tarifs : présentation corrigée ; calcul et montants bloqués.
7. Académie : hiérarchie centrée et ancienneté corrigées.
8. FAQ : contenu et accordéons présents ; ressources liées à des pages existantes.
9. Footer : inscription, identité, siège, contacts et liens légaux réorganisés.
