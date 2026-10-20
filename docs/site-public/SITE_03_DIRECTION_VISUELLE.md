# SITE 03 | Direction visuelle du site public

Date : 8 octobre 2026. Lot UX/UI isolé. Statut : **prototype de direction**, sans validation de publication ni capture réelle intégrée.

> **Périmé en partie (19/10/2026).** Le site est un brouillon, pas une référence de marque. Trois constats ci-dessous ne sont plus vrais : l'app emploie désormais DM Sans et Plus Jakarta Sans (le « conflit typographique » est levé) ; ses fonds viennent de `lib/core/theme/app_palette.dart` (clair `#F1EFF4`, sombre `#16161E`), pas `#F8F7FA` ni `#111014` ; le `viewBox` du logo horizontal de `assets/brand/logo/` est `0 0 1027 287`. Règles de marque : `docs/current/marque/`.

## Intention et composition

Une famille découvre l'offre sur un écran de téléphone en pleine journée, puis revient vérifier le fonctionnement et le prix sur un ordinateur. La première lecture doit être directe et calme. La marque sert à guider l'action ; la preuve vient des écrans réels du produit et du texte HTML, jamais d'un décor religieux ou d'une métrique inventée.

La landing suit les huit séquences A6. Après inspection d'une première capture locale à 1440 px, le H1 a été réduit et le grand cadre blanc sans capture a été remplacé par une annotation éditoriale plus discrète. Cette annotation ne prétend pas montrer le produit.

| Séquence | Composition proposée | Preuve / limite |
|---|---|---|
| Hero | Titre exact A6, texte court à gauche, emplacement de preuve à droite, CTA `/connexion` et lien de fonctionnement | Capture réelle attendue ; ne pas afficher de pseudo-app |
| Foyer | Texte éditorial et liste de profils/fonctions, écran foyer à taille lisible | Capture absente ; aucun nom de famille réelle |
| Cours | Rythme de lignes plutôt que cartes répétées : format, durée, fréquence, effectif | Valeurs commerciales à lire depuis publication administrée |
| Suivi | Capture de suivi en regard des limites réelles d'observation et du rôle du tuteur | Capture absente ; aucune caméra illimitée suggérée |
| Inscription | Quatre étapes numérotées, la préférence de pattern explicitement distincte d'une réservation | Onboarding Flutter via `/connexion` |
| Tarifs | Tableau lisible et exemples seulement si projection publiée | Ne pas coder les prix actifs en CSS ou dans une image |
| Confiance | Identité vérifiée, pédagogie, protection, liens utiles | Aucun badge ou témoignage fictif |
| FAQ / articles | Questions ouvertes à lecture directe, articles réellement publiés, CTA puis footer légal | Aucun article fictif |

Au bureau, la grille alterne une colonne de texte de 5 à 6 unités et une zone visuelle de 6 à 7 unités, avec changements de densité entre les sections. À 768 px, la composition se déroule verticalement en gardant l'image proche de sa légende. À 390 px, le texte essentiel arrive avant le visuel et les CTA passent à la ligne. Les informations commerciales décisives restent du texte HTML. Les captures, quand elles seront disponibles, pourront être inclinées légèrement par transformation CSS, sans changer leur contenu ou leur ratio. Aucun scroll piloté en JavaScript.

## Inventaire des huit SVG fournis

Source : `C:\Users\dell\Downloads\RA logo 2026\RA logo SVG`. Huit fichiers SVG inspectés : `viewBox`, attributs de remplissage, scripts/URL externes et empreinte SHA-256. Aucun script ni URL externe détecté. Le dessin n'a pas été modifié.

| Fichier source | viewBox | SHA-256, 12 premiers caractères | Usage |
|---|---|---|---|
| `RA logo horizontal.svg` | `0 0 1299 340` | `92FE762A25AA` | Copié `site-public/assets/logo-horizontal.svg`, en-tête et footer |
| `RA logo vertical.svg` | `0 0 903 602` | `377188F668E4` | Copié `site-public/assets/logo-vertical.svg`, usage éditorial éventuel |
| `RA symbole full color.svg` | `0 0 716 707` | `03FCD47F2ABB` | Copié `site-public/assets/symbole.svg`, favicon SVG provisoire |
| `RA symbole outsroke.svg` | `0 0 743 734` | `A36083935515` | Copié `site-public/assets/symbole-contour.svg`, variante à évaluer |
| `RA icone full color.svg` | `0 0 716 707` | `03FCD47F2ABB` | Doublon binaire du symbole plein, non copié |
| `RA icone full +outsroke.svg` | `0 0 542 738` | `C9457C495CE4` | Variante verticale, non retenue pour navigation |
| `RA icone ornement full color.svg` | `0 0 457 744` | `83EA6CDC28BD` | Ornement, non retenu pour éviter le décor gratuit |
| `RA icone ornement outsrok.svg` | `0 0 494 777` | `F3D8D5B2D616` | Variante ornementale, non retenue |

Le logo horizontal est violet `#8652E6`. En sombre, le CSS place le SVG sur un petit fond clair pour conserver la marque sans en recolorer le dessin. Le rendu à tailles favicon, Apple touch icon, Open Graph et sur fonds variés reste **NON TESTÉ**. Ne pas promettre ces dérivés à partir d'un SVG sans recette de netteté et contraste.

## Captures du produit

Recherche par noms exacts `Accueil.png`, `Foyer Member.png`, `Classe Details.png`, `Profil.png`, `Historique.png` dans le worktree, le dépôt principal et Downloads : **aucun de ces cinq fichiers retrouvé**. `C:\Users\dell\Downloads\Accueil2.png` existe, mais l'inspection visuelle montre `Mariam`, `Sayyida Amina`, une classe et un écran qui ressemble à une maquette. Il n'est ni prouvé comme capture de l'application en exécution ni expurgé de noms. **Aucune capture n'a été copiée ou publiée.** Les zones `.proof-visual--pending` sont un état de prototype, à remplacer avant le site final par des captures réelles vérifiées ou par une composition éditoriale sans fausse interface. Chaque image intégrée exigera un texte HTML qui explique la fonction montrée.

## Tokens et typographie

`site-public/styles/site.css` centralise les valeurs publiques. Les couleurs de base reprennent `lib/core/theme/app_palette.dart` observé : toile claire `#F8F7FA`, toile sombre `#111014`, surface sombre `#1A181F`, encre claire `#211E28`, encre sombre `#F5F2FA`, action claire `#8652E6`, action sombre `#C9AEFF`. L'ombre est réservée à la future capture principale, pas répétée dans une grille de cartes.

**CONFLIT typographique.** A7 impose DM Sans pour les titres et Plus Jakarta Sans pour le reste. `lib/core/theme/app_typography.dart` utilise Instrument Sans et Bricolage Grotesque. A7, décision plus récente du directeur, gouverne ici le site public. Flutter n'est pas modifié ; le raccord entre moteurs doit être jugé sur capture d'aperçu.

Les deux fontes sont auto-hébergées par `site.css` depuis `site-public/assets/`, avec `font-display: swap`, sous-ensembles Latin et Latin étendu, et fallback `system-ui`. Sources exactes des notices : [licence DM Sans](https://github.com/google/fonts/blob/main/ofl/dmsans/OFL.txt) et [licence Plus Jakarta Sans](https://github.com/google/fonts/blob/main/ofl/plusjakartasans/OFL.txt). Les quatre WOFF2 viennent des URL `fonts.gstatic.com` retournées le 8 octobre par la [CSS officielle Google Fonts](https://fonts.googleapis.com/css2?family=DM+Sans:wght@400..700&family=Plus+Jakarta+Sans:wght@400..700&display=swap) pour Chrome, familles DM Sans et Plus Jakarta Sans, poids 400 à 700. Les projets [DM Sans](https://github.com/googlefonts/dm-fonts) et [Plus Jakarta Sans](https://github.com/tokotype/PlusJakartaSans) publient ces fontes sous SIL Open Font License. Chaque WOFF2 porte la signature `wOF2` ; les fichiers TTF téléchargés pour l'essai initial ont été retirés du livrable après vérification des WOFF2.

| Asset WOFF2 | Octets | SHA-256 |
|---|---:|---|
| `dm-sans-latin.woff2` | 36 932 | `9FEA608A947E67020C33CAD9A6FE3D60C54119DFB8CFF87768A8117A15ED7543` |
| `dm-sans-latin-ext.woff2` | 18 228 | `A5D38FE99F930275684999B462C7123FAA063D9E44E73B4B241723D884AA0F49` |
| `plus-jakarta-sans-latin.woff2` | 27 348 | `153FC85B70298BEEB1D61A5F723331649E7F23BB77302A66E61CB3E2FBDB5E79` |
| `plus-jakarta-sans-latin-ext.woff2` | 21 728 | `38E3B8FD8045048EB311D90170A4429ED2C8F405852DC3D91B5AF8452758703F` |

Total WOFF2 : 104 236 octets, avant HTTP. La vérification CDP locale a confirmé `document.fonts.check(...) = true` pour les deux familles sur l'accueil ; les variantes Latin étendu restent non chargées sur ce contenu qui n'emploie pas leurs glyphes.

**CONFLIT couleur sombre.** A7 cite `#1A1A25` ; la palette Flutter réelle donne `#111014` pour toile et `#1A181F` pour surface. La feuille du site reprend les tokens réels, suivant SITE_00, et isole les noms CSS pour ajustement contrôlé après comparaison high-fi.

## Contrat CSS et mouvement

Classes de raccordement : `.site-header`, `.site-nav`, `.site-main`, `.site-footer`, `.hero`, `.section`, `.cta`, `.eyebrow`, `.proof-visual`. Helpers : `.site-header__inner`, `.site-header__brand`, `.site-footer__inner`, `.site-footer__bottom`, `.hero__copy`, `.hero__proof`, `.section__intro`, `.lead`, `.action-row`, `.cta--secondary`, `.editorial-grid`, `.fact-list`, `.step-list`, `.proof-visual--pending`. Les classes réellement émises par le générateur (`.header-inner`, `.footer-inner`, `.hero-inner`, `.section-inner`, `.section-copy`, `.preview-note`, `.section-links`) sont également stylées. Le logo du générateur en `.brand img` reçoit sa taille propre sur mobile et bureau ; le footer aussi. Sous 700 px, `<details class="mobile-menu">` sert de menu natif, les liens de navigation de bureau et le CTA d'en-tête sont masqués.

La transformation d'une capture est discrète, limitée à `transform`, retirée sous 600 px et sous `prefers-reduced-motion: reduce`. L'état réduit supprime aussi les transitions et le défilement fluide. Le contenu, les liens et la navigation n'en dépendent pas. Les focus clavier sont visibles. La CSS prévoit les deux thèmes par `prefers-color-scheme`, et des attributs `data-theme='light|dark'` si une préférence vérifiée est ensuite raccordée. Aucun stockage de préférence inventé ici.

## Recette encore nécessaire

- Chrome headless lancé avec permission renforcée uniquement pour une recette locale. CDP a imposé des viewports réels à 390, 768 et 1440 px, avec tests clair, sombre et mouvement réduit. Sur l'accueil, `innerWidth=390` et `documentElement.scrollWidth=390` ; à 768 et 1440, les largeurs de document étaient respectivement 753 et 1425 avec la barre de défilement de 15 px. **Aucun débordement horizontal détecté sur l'accueil testé.** La première image « mobile » coupée provenait du minimum de largeur de la fenêtre Chrome headless sans émulation CDP.
- Captures finales suivies dans Git du premier écran : [1440 px clair](captures/1440-clair.png) et [390 px sombre](captures/390-sombre.png). Elles incluent le lien secondaire « Voir comment ça marche » ajouté au générateur, et montrent les polices locales. Sur 1440 px, ce lien mène à `/fr/comment-ca-marche` ; l'action principale mène à `/connexion`. Sur 390 px, `innerWidth=390` et `scrollWidth=390`. Ces images ne contiennent aucune capture de l'app et ne prouvent ni parcours complet ni déploiement. Les captures intermédiaires et les copies ignorées de `styles/previews/` ont été retirées.
- Menu mobile testé avec CDP à 390 px : navigation par Tab jusqu'au `<summary>`, focus visible avec contour solide de 3 px, ouverture par barre d'espace, foyer de focus conservé sur « Menu ». L'essai d'activation avec Entrée via injection CDP n'a pas ouvert le menu ; ce résultat reste à confirmer par une interaction clavier humaine dans un navigateur normal avant d'affirmer la couverture complète du clavier.
- Page tarifs ouverte directement en local à 390 px sombre : H1 « Les tarifs doivent être confirmés avant tout paiement », avertissement « Cette page est en préparation. Les éléments contractuels non vérifiés ne sont pas publiés. », `robots=noindex,nofollow`, aucun débordement horizontal (`scrollWidth=390`).
- Contraste des contrôles et images compositées, zoom 200 %, clavier, lecteur d'écran et RTL si une langue arabe est publiée.
- Vérifier que les SVG s'affichent via `/fr/assets/`, que les fontes se chargent, que le focus ne sort pas du viewport et que la navigation ne déborde pas.
- Mesurer LCP/INP/CLS sur un aperçu servi ; les cibles A8 ne sont pas des mesures actuelles.
