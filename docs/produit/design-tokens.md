# Design Tokens — Rewayah Academy App

Référence unique pour l'agent de code. Toute couleur, police, rayon, ombre,
espacement, icône et contrainte visuelle passe par ici.

**Comment employer ces jetons : `docs/design/01-systeme-visuel.md`.** Ce
fichier-ci porte les valeurs, l'autre porte les règles d'emploi. Aucun des deux
ne recopie l'autre.

> Révision du 7 septembre 2026, refonte UX/UI v1.0 (ADR-018). La palette de
> marque est **conservée** dans ses cinq couleurs. Ce qui change : le fond
> général passe au crème, chaque famille reçoit un registre doux en plus de son
> aplat, et la typographie française est remplacée. L'arabe ne change pas.
>
> **Appliqué au code par le lot T, le 7 septembre 2026.** Toutes les valeurs de
> ce fichier sont désormais rejouées par `test/theme/contraste_test.dart`,
> `typographie_test.dart`, `elevation_test.dart` et `mouvement_test.dart` : une
> mesure fausse ici fait échouer la suite. Deux chiffres ont été corrigés à
> cette occasion, et ils sont signalés par la mention **mesuré au lot T**.
>
> **Durci au lot T2, le 11 septembre 2026** (Bible Frontend V2, ADR-019),
> après que le rendu déployé du lot R3 ait été jugé « plus nul que du
> générique ». Trois causes mesurées, signalées par **mesuré au lot T2** :
> les ombres à 5 % d'opacité ne détachaient aucune carte du fond ; les deux
> bordures décoratives, à 1,20:1 et 1,45:1, étaient à peine perceptibles ; le
> bouton `ActionPrincipale` désactivé, peint sur `surfaceSunken` avec le filet
> le plus faible de la rampe, se fondait dans la page et pesait moins qu'un
> bouton secondaire. **Les trois surfaces neutres ne bougent pas** : mesuré,
> le moindre assombrissement de `surfaceSunken` fait chuter `borderStrong`
> sous 3:1 sur cette surface, qui n'avait déjà que 3,21 de marge — chiffré
> avant d'être écarté, pas supposé.

---

## 1. Palette

Le thème expose toujours des **paires** `(fond, encre)`, jamais une couleur
seule. C'est ce qui rend une erreur de contraste structurellement impossible
plutôt que dépendante de la vigilance de qui écrit l'écran.

### 1.1 Les cinq couleurs de marque, et ce qu'elles deviennent

| Nom d'origine | Hex | Rôle avant | Rôle après |
| :--- | :--- | :--- | :--- |
| Violet | `#8652E6` | Accent, actions primaires | **Inchangé.** Plus sa teinte douce et son encre |
| Noir | `#1C1D21` | Texte principal | **Inchangé.** Ancre le bas de la rampe neutre |
| Vert menthe | `#70EE9C` | Succès | **Inchangé.** Plus sa teinte douce et son encre |
| Rose pâle | `#F1E3E4` | **Fond général de tout le produit** | Devient `washFamily`, la teinte du domaine foyer : cartes enfant, avatars, `TUT-05` |
| Taupe | `#CCBCBC` | Bordures | Devient la teinte de référence de la rampe neutre chaude, corrigée en luminance et réchauffée de 356° vers 25° pour s'accorder au crème |

Aucune teinte nouvelle n'est introduite. Ce qui s'ajoute, ce sont les
déclinaisons claires et foncées des teintes déjà là.

### 1.2 Le fond crème, et pourquoi il n'est pas jaune

| Couleur | Hex | R, V, B | Écart max-min | Teinte | Sat. | Clarté |
| :--- | :--- | :--- | :-: | :-: | :-: | :-: |
| **Crème retenu** | `#F8F4EE` | 248, 244, 238 | **10** | 36° | 42 % | 95 % |
| Rose pâle, l'ancien fond | `#F1E3E4` | 241, 227, 228 | 14 | 356° | 33 % | 92 % |
| Un crème jaunâtre, à ne pas faire | `#FBF3D9` | 251, 243, 217 | **34** | 46° | 81 % | 92 % |

Le jaunissement se lit sur l'écart entre les canaux, pas sur la teinte : le
crème retenu a un écart de 10 contre 34 pour le témoin jaunâtre, soit un peu
plus du tiers de sa chromaticité. Sa teinte reste à 36°, donc franchement chaude,
et à dix degrés du jaune.

### 1.3 La rampe neutre chaude

Elle relie le crème au noir de la charte, en passant par la taupe réchauffée.

| Jeton | Hex | Emploi | Contraste sur le crème |
| :--- | :--- | :--- | :-: |
| `surfaceRaised` | `#FFFFFF` | Cartes, tuiles, feuilles, menus, barres de navigation | 1,10 |
| `surfaceCanvas` | `#F8F4EE` | **Fond général** | — |
| `surfaceSunken` | `#F3EDE7` | Champs, en-têtes de tableau, pistes, cases vides de grille | 1,06 |
| `borderHairline` | `#DCD2C8` | Filet entre deux blocs, contour de carte | 1,36 *(mesuré au lot T2, était 1,20 sur `#E7DFD8`)* |
| `borderResting` | `#C9BCB1` | Contour d'un contrôle au repos | 1,69 *(mesuré au lot T2, était 1,45 sur `#D6CBC3`)* |
| `borderStrong` | `#8F8279` | **Contour porteur de sens** : sélection, focus, bord de tableau | **3,40** |
| `inkFaint` | `#756B63` | Texte tertiaire, métadonnées | **4,74** |
| `inkMuted` | `#5E564F` | Texte secondaire | **6,56** |
| `inkStrong` | `#1C1D21` | Texte principal | **15,37** |

⚠ **`inkFaint` est interdit sur `surfaceSunken`** : il y mesure 4,48, sous le
seuil de 4,5. Sur une surface enfoncée, le texte secondaire passe à `inkMuted`,
qui y mesure 6,19. C'est le seul jeton de la rampe qui a une surface interdite.

Le lot T a rendu cette interdiction structurelle plutôt que mémorielle :
`AppPalette.encreSecondaireSur(surface)` rend `inkMuted` sur la surface
enfoncée et `inkFaint` ailleurs. Un écran qui passe par là ne peut pas se
tromper ; un écran qui lit `inkFaint` directement le peut encore, et c'est
pourquoi la fonction existe.

`borderStrong` est le seul filet mesuré au dessus de 3:1, et il l'est **sur les
trois surfaces**, ce que le lot T a vérifié plutôt que supposé : 3,40 sur le
crème, 3,73 sur une carte blanche, 3,21 sur la surface enfoncée. C'est la marge
la plus mince des trois qui compte, et elle passe.

### 1.4 Les paires pleines

Un aplat saturé et son encre. **Une seule zone pleine par écran**
(`01-systeme-visuel.md` §3).

| Jeton | Fond | Encre | Mesure | Emploi |
| :--- | :--- | :--- | :-: | :--- |
| `surfacePrimary` | `#8652E6` | `#FFFFFF` | 4,81 | L'action principale |
| `surfaceSuccess` | `#70EE9C` | `#1C1D21` | 11,55 | Pastille « en direct ». **Jamais de texte blanc** |
| `surfaceWarning` | `#FFB703` | `#1C1D21` | 9,64 | Réservé aux pastilles. **Jamais de texte blanc** |
| `surfaceAlert` | `#B01B3C` | `#FFFFFF` | 6,84 | Contour de champ en erreur, pastille critique |
| `surfaceInverse` | `#1C1D21` | `#F8F4EE` | 15,37 | Le bandeau permanent de la salle |

### 1.5 Les paires douces

Une teinte pâle et une encre foncée de la **même famille**. C'est le registre par
défaut de tout ce qui informe : bandeaux, badges, lignes d'alerte, fonds de
section.

| Jeton | Teinte | Encre | Encre sur teinte | Teinte sur le crème |
| :--- | :--- | :--- | :-: | :-: |
| `washAccent` / `inkAccent` | `#E9E0FC` | `#5B36B0` | 6,36 | 1,16 |
| `washSuccess` / `inkSuccess` | `#C6F0D9` | `#0F5F35` | 6,23 | 1,14 |
| `washWarning` / `inkWarning` | `#FCE7B8` | `#6B4A00` | 6,63 | 1,11 |
| `washAlert` / `inkAlert` | `#FBE3E9` | `#B01B3C` | 5,63 | 1,11 |
| `washFamily` | `#F1E3E4` | `#1C1D21` | 13,51 | 1,14 |
| `surfaceQuran` | `#F3EAD9` | `#1C1D21` | 14,10 | 1,09 |

Les quatre encres posées directement sur le crème : `inkAccent` 7,37,
`inkSuccess` 7,08, `inkWarning` 7,36, `inkAlert` 6,25. Sur une carte blanche,
respectivement 8,08, 7,75, 8,06 et 6,84.

⚠ **Le violet plein ne s'écrit jamais en texte sur une surface claire** : il
mesure 4,39 sur le crème et 4,14 sur la surface enfoncée. C'est la raison d'être
d'`inkAccent`.

### 1.6 Règles d'API

Le thème expose `AppColorPair` avec `.background` et `.onBackground`. Un widget
qui prend une seule des deux valeurs sans l'autre est un signal de revue de code
à corriger avant fusion.

Les jetons sans fond, les six encres et les trois bordures, passent par
`AppInkColor`, qui n'expose aucune couleur brute : seulement `applyTo` pour un
texte, `asBorderSide` pour un trait et `asIconTheme` pour une icône. Ils sont
ainsi inutilisables comme fond, ce qui recréerait la paire illisible que la
règle cherche à empêcher.

**Le piège déjà payé** : `surfaceAlert.applyTo(...)` posé sur la page écrivait en
blanc, puisque le blanc est l'encre du fond rouge. Blanc sur le fond général
mesure **1,10** : le message existait dans l'arbre et n'existait pas à l'écran.
D'où les quatre encres de la section 1.5.

⚠ **Mesuré au lot T** : cette ligne annonçait 1,19. C'était la mesure d'un fond
qui n'existe plus. Sur le crème, blanc sur fond vaut 1,10, exactement la même
valeur que `surfaceRaised` sur le crème en section 1.3 : c'est la même paire,
elle ne pouvait pas valoir deux chiffres. La conclusion, elle, ne bouge pas.

### 1.7 Méthode de mesure

Toutes les valeurs ci-dessus sont calculées, pas relues : luminance relative
WCAG 2.1, `(L1 + 0,05) / (L2 + 0,05)`, arrondi à deux décimales. Le calcul est
reproductible et doit l'être : **aucun jeton n'entre dans la palette sans sa
mesure inscrite dans ce tableau.**

Ce qui disparaît par rapport à la version précédente : le jeton unique
`borderDefault`, mesuré à 1,86, qui servait à la fois de décor et de sens.
Il est remplacé par les trois bordures de la section 1.3, dont une seule porte du
sens et passe le seuil. La question ouverte 10 du registre est close par là.

### 1.8 Correspondance des anciens noms — renommage fait au lot T

Le renommage a été fait en une passe, sur 29 fichiers de `lib/` et de `test/`,
et **`tool/verifier_jetons.dart` refuse désormais les anciens noms** sous la
règle `vocabulaire-perime` : les deux vocabulaires ne peuvent plus cohabiter.
Le tableau reste ici pour lire un ancien commit ou une ancienne note.

| Ancien nom | Ancienne valeur | Devient |
| :--- | :--- | :--- |
| `surfaceBase` | `#F1E3E4` | `surfaceCanvas` `#F8F4EE`. La valeur d'origine devient `washFamily` |
| `borderDefault` | `#B8A6A6` | Éclaté en `borderHairline`, `borderResting`, `borderStrong` |
| `textOnLightAccent` | `#5B36B0` | `inkAccent`, **valeur inchangée** |
| `textOnLightAlert` | `#B01B3C` | `inkAlert`, **valeur inchangée** |
| `surfacePrimary` | `#8652E6` | inchangé |
| `surfaceSuccess` | `#70EE9C` | inchangé, plus `washSuccess` et `inkSuccess` |
| `surfaceWarning` | `#FFB703` | inchangé, plus `washWarning` et `inkWarning` |
| `surfaceAlert` | `#B01B3C` | inchangé |

Deux endroits hors de `lib/` portaient aussi l'ancien fond, et sont repris :
`web/manifest.json` (`background_color`) et `web/index.html` (couleur de fond du
chargeur). Sans eux, l'écran de démarrage serait resté rose et le produit
clignoterait au lancement. **Aucun outil ne tient ces deux valeurs** : elles
sont hors de `lib/`, donc hors de portée du vérificateur, et un commentaire les
rattache au jeton dans chacun des deux fichiers.

Les **vignettes PWA** de `web/icons/`, elles, n'étaient pas concernées : leurs
quatre PNG ont un fond blanc, vérifié au pixel, et le blanc est `surfaceRaised`.
Rien à y reprendre.

---

## 2. Polices

**Toutes les polices sont des fichiers versionnés dans `assets/fonts/`, jamais un
CDN.** Une police chargée au réseau ferait tomber à la fois le budget de
démarrage à froid et le mode hors ligne.

### 2.1 Arabe — inchangé

| Police | Fichier | Usage | Source |
| :--- | :--- | :--- | :--- |
| **KFGQPC Uthman Taha Naskh** | `UthmanTahaNaskh-Regular.otf` | Tout contenu arabe de type document : Coran, hadiths, livres, lettres, textes pédagogiques | Complexe du Roi Fahd, fichier fourni par l'opérateur. **Pas sur Google Fonts** |
| **Noto Sans Arabic** | `NotoSansArabic-Variable.ttf` | Affichage RTL, menus, boutons, labels, navigation, tout élément d'interface en arabe | Google Fonts, OFL |

### 2.2 Français — remplacé

| Police | Fichier | Axes, et leur **valeur par défaut** | Usage |
| :--- | :--- | :--- | :--- |
| **Bricolage Grotesque** | `BricolageGrotesque-Variable.ttf` | `opsz` 12 à 96 (**défaut 96**), `wght` 200 à 800 (**défaut 800**), `wdth` 75 à 100 (défaut 100) | Titres, en-têtes, chiffres de tuile, tout ce qui est au dessus de 18 pt |
| **Instrument Sans** | `InstrumentSans-Variable.ttf` | `wght` 400 à 700 (défaut 400), `wdth` 75 à 100 (défaut 100) | Corps de texte, labels, navigation, boutons, tableaux |

Les deux sont sous licence OFL, texte versionné dans
`assets/fonts/LICENSE-BricolageGrotesque.txt` et `LICENSE-InstrumentSans.txt`.

⚠ **Mesuré au lot T** : les axes ci-dessus sont lus dans la table `fvar` des
binaires, pas relevés sur une fiche. Les **valeurs par défaut** en sont la
partie qui compte, et elles sont des pièges : un titre qui ne déclare ni `wght`
ni `opsz` sort en extra-gras dessiné pour 96 points. `AppTypography` pilote donc
les deux, sur tous les rôles, et `test/theme/typographie_test.dart` le vérifie
rôle par rôle.

L'italique d'Instrument Sans est un **fichier séparé**, pas un axe : il n'est
pas embarqué, aucun style du produit ne le demande, et l'ajouter coûterait
190 Ko. Le jour où un style en aura besoin, c'est un second `asset` sous la même
famille, pas une cinquième famille.

**Ce qu'elles remplacent, et pourquoi.**

| Sortante | Raison |
| :--- | :--- |
| Varela Round, titres | Une seule graisse, donc aucune hiérarchie possible à l'intérieur d'un titre, et des terminaisons arrondies dont le registre appartient au début des années 2010. C'est la police qui datait le produit |
| Noto Sans, corps | Aucune personnalité, et 2 Mo pour une interface française. C'est la question ouverte 11 du registre |

⚠ **Instrument Sans commence à la graisse 400.** Il n'y a pas de « light » dans
ce produit : la hiérarchie du texte se fait par la **couleur**, avec les trois
encres neutres, jamais par un gris clair obtenu en amaigrissant la police. Un
texte gris clair est un texte qui échoue au contraste.

⚠ **L'axe `opsz` de Bricolage Grotesque se règle sur la taille rendue**, jamais
laissé à sa valeur par défaut. Une police de titre dessinée pour une taille et
affichée à une autre paraît molle ou fragile : c'est exactement l'effet « pas
fini » du premier rendu.

⚠ **Mesuré au lot T** : cette ligne annonçait un défaut de 14. Le fichier a un
défaut de **96**, donc le risque est l'inverse de celui décrit : un petit titre
laissé au défaut serait dessiné pour 96 points, trop fin et trop serré. La règle
ne change pas, sa raison si.

### 2.3 Règles

- Quatre familles, pas une de plus. Si un style manque, on étend l'une des
  quatre par une variation d'axe, on n'en ajoute pas une cinquième.
- Les polices arabes sont prioritaires : l'application est bilingue et l'arabe
  est la langue principale. Les styles latins déclarent Noto Sans Arabic en
  repli, pour qu'un texte mixte reste lisible sans que l'écran ait à choisir sa
  police.
- La graisse des polices variables se pilote par l'axe `wght`, jamais par un
  faux gras synthétisé.
- **Chiffres tabulaires obligatoires** partout où un chiffre vit dans une
  colonne, un compteur, un minuteur ou une tuile de statistique. Sans eux, un
  compteur qui passe de 17 à 18 fait bouger toute la ligne.
- Sous-ensembles réduits aux glyphes réellement utilisés. **Toujours pas fait** :
  l'élagage de Flutter ne concerne que les polices d'icônes. Le gain est
  désormais chiffré, voir la section 2.4.

### 2.4 Le lot typographique, et ce qu'il a trouvé

Les quatre points de la liste d'origine, avec leur résultat au 7 septembre 2026.

1. **Fichiers récupérés depuis `fonts.google.com`**, par son API de listing
   (`fonts.google.com/download/list?family=...`), qui donne l'URL du fichier
   variable sur `fonts.gstatic.com`. ⚠ Deux impasses à ne pas repayer :
   `fonts.google.com/download?family=...` ne rend plus une archive mais la page
   HTML de l'application, et l'API CSS `css2` ne sert que des **instances
   statiques**, une par graisse, jamais le fichier variable. Le dépôt
   `google/fonts` reste inatteignable en TLS depuis ce poste.
2. **Poids mesuré.** Les deux entrantes pèsent ensemble 587 Ko, les deux
   sortantes en pesaient 2 131 : **1 544 Ko de gagnés, soit 72 %**, avant tout
   sous-ensemblage. Détail dans `etape-2-journal.md`.
3. **Accord avec l'arabe : non vérifié.** C'est le seul point de cette liste qui
   reste ouvert, et il ne se ferme pas sans un rendu à l'œil, sur un écran, avec
   un échantillon mixte. La galerie l'affiche désormais, l'opérateur tranche.
4. **`tnum` est présent dans les trois polices d'interface**, lu dans la table
   `GSUB` de chaque binaire : Bricolage Grotesque, Instrument Sans et Noto Sans
   Arabic le déclarent. Rien n'a donc été écrit en espérant.

---

## 3. Icônes

| Librairie | Choix | Raison |
| :--- | :--- | :--- |
| **Phosphor Icons**, polices intégrées en assets | Icônes uniques, modernes, esthétique arrondie | Pas Material (trop générique), pas Font Awesome (daté), pas d'emojis |

**Le paquet `phosphor_flutter` n'est pas utilisé.** Sa version 2.1.0, la dernière
publiée, ne compile plus avec Flutter 3.47 : elle étend `IconData`, devenue une
classe `final`. Deux graisses seulement sont embarquées,
`Phosphor-Regular.ttf` et `Phosphor-Fill.ttf`, licence MIT conservée dans
`assets/fonts/LICENSE-Phosphor.txt`. Les points de code sont déclarés dans
`lib/core/icons/app_icons.dart`, seul fichier du dépôt autorisé à construire un
`IconData`.

Les glyphes Material et Cupertino restent embarqués, mais **uniquement pour le
chrome interne de Flutter** : la flèche de retour d'`AppBar`, les affordances de
`TextField`. L'iconographie de l'application reste Phosphor et rien d'autre, et
c'est `tool/verifier_jetons.dart` qui tient la règle en refusant tout `Icons.`
hors d'`AppIcons`. L'élagage ramène les quatre polices d'icônes à 28,7 Ko au
total.

### Règles strictes

- **Zéro emoji** dans toute l'app : ni dans le code, ni dans les libellés, ni
  dans les notifications, ni dans les emails.
- **Pas de M-dash** (`—`) dans le texte utilisateur. Utiliser des deux-points ou
  une ponctuation classique.
- Une seule librairie d'icônes dans tout le projet.
- Phosphor en `regular` par défaut, `fill` pour les états actifs et sélectionnés.
- **Une icône ne porte jamais seule un état.** Pastille, icône, mot : au moins
  deux des trois.
- Les icônes directionnelles se miroitent en RTL. L'horloge, la progression du
  temps et les icônes de média ne se miroitent pas.

---

## 4. Illustrations

### Style

- **Storyset / Rafiki** (freepik) : illustrations flat, colorées, personnages
  stylisés.
- Chaque illustration doit respecter les exigences islamiques (voir §5).

### Contraintes

- Illustrations vectorielles (SVG) privilégiées pour la scalabilité.
- Pas de photos réelles pour les illustrations décoratives : les photos sont
  réservées aux profils utilisateurs (ADR-012).
- Les illustrations de la bibliothèque Storyset sont sous licence Freepik :
  vérifier les conditions d'utilisation pour un usage commercial.
- **Recolorisation** : une illustration importée est ramenée à la palette. Une
  illustration qui garde ses couleurs d'origine se voit immédiatement comme une
  pièce rapportée, et c'est l'un des signes les plus nets d'un produit assemblé.

---

## 5. Éthique islamique — règles visuelles

L'app traite du Coran et de l'éducation islamique. Chaque élément visuel doit
respecter ces règles :

### Obligatoire

- **Pas de femmes non voilées** dans les illustrations, avatars ou images
  décoratives.
- **Pas d'idoles** ni de représentations de divinités.
- **Pas de caricatures obscènes ou malsaines.**
- **Pas de représentation de prophètes** ni de compagnons du Prophète (durood).
- **Pas de symboles religieux non-musulmans** (croix, étoile à six branches,
  etc.) dans les illustrations.

### Recommandé

- Personnages masculins avec barbe et/ou kufi/turban quand approprié.
- Personnages féminins avec hijab obligatoire.
- Motifs géométriques et calligraphiques islamiques pour la décoration.
- Couleurs vertes et dorées pour les accents religieux (vert = couleur de
  l'Islam, or = sacralité).

### Sources d'illustrations

- **Storyset / Rafiki** (freepik) — vérifier chaque illustration contre les
  règles ci-dessus.
- **Custom SVG** — créer des illustrations sur mesure si aucune librairie ne
  satisfait les contraintes.
- **Pas de génération IA** d'images.

---

## 6. Règles de copywriting — anti-IA générique

L'expérience utilisateur ne doit **jamais** ressembler à du contenu généré par
IA.

### Bannis

- Tournures comme « Dans le monde numérique d'aujourd'hui… », « Il est important
  de noter que… », « Révolutionnez votre… », « Sans plus attendre… », « Chemin de
  vie… », « Découvrez… ».
- Listes à puces excessives (> 5 éléments) dans le texte utilisateur.
- Em-dash (`—`) : remplacer par des deux-points ou une tournure naturelle.
- Emojis dans le texte, les notifications, les emails, les libellés d'interface.
- Superlatifs exagérés (« incroyable », « exceptionnel », « unique en son genre »).
- Phrases creuses de transition.

### Préférer

- Phrases courtes, directes, actionnables.
- Vocabulaire concret (« 3 leçons ce week-end » plutôt que « progressez dans
  votre parcours »).
- Ton bienveillant mais jamais infantilisant, même en mode enfant.
- Arabe naturel, pas de traduction mot-à-mot du français.
- Un libellé de bouton qui est un verbe et son objet : « Poser un créneau »,
  jamais « Valider ».
- Un titre d'écran qui nomme, jamais qui accueille : « Aujourd'hui », pas
  « Bienvenue sur votre tableau de bord ».

---

## 7. Espacement

Échelle fixe, étendue vers le haut par la refonte : les paliers courts servaient
l'intérieur des composants, ceux du rythme de page manquaient.

```
4   8   12   16   20   24   32   40   48   64
```

Aucune valeur ponctuelle en dehors de cette échelle.

| Usage | Palier |
| :--- | :--- |
| Intérieur d'un contrôle, écart icône/texte | 4, 8, 12 |
| Intérieur d'une carte, écart entre deux lignes | 16, 20, 24 |
| Écart entre deux cartes | 12 sur mobile, 16 au dessus |
| Écart entre deux sections | 32, 40 |
| Marge haute d'un titre d'écran | 48 |
| Respiration d'un écran vide ou d'un accueil enfant | 64 |

Gouttières de page : **20** sur mobile, **32** sur tablette, **48** sur desktop.
Largeur maximale de contenu : **1200**. Largeur de lecture : **68 caractères**.

---

## 8. Rayons

```
radiusXs    8     pastilles, petits contrôles, vignettes
radiusSm   12     champs, boutons
radiusMd   16     cartes
radiusLg   24     tuiles Bento, feuilles de bas d'écran
radiusFull 999    avatars, pilules d'état
```

**Le rayon d'un enfant est plus petit que celui de son parent.** Une vignette
dans une carte `radiusMd` prend `radiusSm`. L'inverse produit l'effet de bulle
qui date le produit.

---

## 9. Élévation

Trois ombres, pas davantage. La couleur d'ombre est **chaude**, `#3A302A` : une
ombre grise neutre sur un fond crème se lit comme une salissure.

| Jeton | Composition | Emploi |
| :--- | :--- | :--- |
| `elevation0` | aucune | Ce qui est posé à plat : sections, séparateurs |
| `elevation1` | `0 1 2 rgba(58,48,42,0.10)` + `0 2 6 rgba(58,48,42,0.09)` | Cartes, tuiles, lignes cliquables. Le défaut |
| `elevation2` | `0 2 4 rgba(58,48,42,0.08)` + `0 8 20 rgba(58,48,42,0.14)` | Menu, popover, barre collée, carte pressée |
| `elevation3` | `0 12 32 rgba(58,48,42,0.22)` | Feuille de bas d'écran, boîte de dialogue |

*(Opacités remontées au lot T2, 11 septembre 2026 : à 5-8 %, une carte ne se
détachait pas du fond sur un écran en plein jour, cause n3 mesurée du rejet du
rendu déployé après le lot R3. `elevation0` à `elevation3` dans ce tableau sont
les noms de jetons ; le code les expose comme `AppElevation.niveau0` à
`niveau3`.)*

Une surface élevée porte **un filet et une ombre**, jamais l'un des deux seul :
le filet tient en contraste élevé et sur un écran mal calibré, l'ombre donne la
profondeur.

Dans le code : `AppElevation.niveau0` à `niveau3`, plus `AppElevation.avecFilet`
qui compose fond, arrondi, filet et ombre en une fois. C'est le seul fichier
autorisé à construire une `BoxShadow`, avec `app_color_pair.dart` qui porte le
type `AppShadowColor`. Ce type n'expose aucune couleur brute : une ombre ne peut
donc pas être posée en fond ni en texte.

---

## 10. Crénage optique

Aucun `letterSpacing` n'était posé nulle part, ce qui laissait les grands titres
à l'espacement d'un corps de texte. C'est l'un des deux détails qui datent le
plus un écran, avec l'absence d'élévation.

| Taille rendue | Crénage |
| :--- | :--- |
| 32 et plus | −0,02 em |
| 24 à 31 | −0,015 em |
| 18 à 23 | −0,01 em |
| 15 à 17 | 0 |
| 14 et moins | +0,01 em |
| Libellé en capitales, 12 et moins | +0,06 em |

Le crénage se calcule dans le fichier de typographie, à partir de la taille.
Aucune valeur littérale ailleurs, et `tool/verifier_jetons.dart` refuse tout
`letterSpacing` posé hors d'`app_typography.dart`.

Le barème est en **em**, l'API Flutter attend des **pixels logiques** :
`AppTypography.crenage(taille)` fait la conversion, et la fait sur la taille
**rendue**, donc après le facteur du mode enfant. Un crénage calculé sur la
taille de base serait trop lâche de 20 % sur tout l'écran d'un enfant.

---

## 11. Mouvement

Durées, courbes et motifs : `docs/design/04-systeme-mouvement.md`. Résumé des
valeurs, pour que le fichier de jetons reste complet :

```
120 ms   retour tactile
160 ms   micro-interaction
200 ms   apparition, disparition, retour local
240 ms   navigation
280 ms   ouverture de feuille   (fermeture 200 ms)
400 ms   plafond absolu
```

Courbes : `easeOutCubic` à l'entrée, `easeInCubic` à la sortie, ressort amorti
sans rebond visible pour les feuilles et le conteneur partagé. `linear` réservé
aux progressions indéterminées.

Dans le code : `AppMouvement`, seul fichier autorisé à poser un
`Duration(milliseconds: ...)` ou à nommer une `Curves.`. Les durées **métier**
restent libres : une pause de prière en minutes ou un cache de vingt-quatre
heures ne sont pas du mouvement, et la règle ne les touche pas.

Une valeur s'ajoute à ce tableau, et elle est **hors budget** : la pulsation
d'`ELV-02` bat sur **1 200 ms**. Le plafond de 400 ms borne ce qui explique un
changement, pas ce qui signale une imminence en continu ; un battement de 400 ms
serait une alarme. C'est la seule pulsation du produit, et elle reste seule.

---

## 12. Mode sombre

Toujours pas implémenté. Les jetons ci-dessus valent pour le mode clair.

⚠ Quand le mode sombre arrivera, **toutes les mesures de la section 1 sont à
refaire** : aucune ne se transpose. En particulier, les quatre encres foncées de
la section 1.5 deviendront des encres claires, et les teintes douces deviendront
des fonds sombres désaturés, jamais les mêmes valeurs assombries.
