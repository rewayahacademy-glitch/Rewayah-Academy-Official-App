# Design Tokens — Rewayah Academy App

Référence unique pour l'agent de code. Toute couleur, police, icône et contrainte visuelle passe par ici.

---

## 1. Palette

Couleurs issues du Coolors `RA_APP colors`. Le thème expose toujours des **paires** `(background, onBackground)`, jamais une couleur seule.

### Palette brute

| Nom | Hex | Usage |
| :--- | :--- | :--- |
| Violet | `#8652E6` | Accent principal, actions primaires |
| Noir | `#1C1D21` | Texte principal, fond sombre |
| Taupe | `#CCBCBC` | Bordures (non corrigé — voir §1.1) |
| Rose pâle | `#F1E3E4` | Fond général clair |
| Vert menthe | `#70EE9C` | Succès, validation |

### Paires accessibles (à implémenter)

Le thème Flutter n'expose que ces paires. Les couleurs brutes ne sont jamais utilisées directement dans les widgets.

| Token | Fond | Texte | Usage |
| :--- | :--- | :--- | :--- |
| `surfaceBase` | `#F1E3E4` | `#1C1D21` | Fond général |
| `surfacePrimary` | `#8652E6` | `#FFFFFF` | Actions principales |
| `surfaceSuccess` | `#70EE9C` | `#1C1D21` | Jamais de texte blanc (1.46:1 mesuré) |
| `surfaceWarning` | `#FFB703` | `#1C1D21` | Jamais de texte blanc (1.75:1 mesuré) |
| `surfaceAlert` | `#B01B3C` | `#FFFFFF` | Rouge assombri, l'original `#FF385C` échoue à 3.51:1 |
| `borderDefault` | - | `#B8A6A6` | Bordure remontée, l'original `#CCBCBC` échoue à 1.47:1 |
| `textOnLightAccent` | - | `#5B36B0` | Violet assombri sur fond clair, l'original échoue à 3.83:1 |

**Règle d'API** : le thème expose `AppColorPair` avec `.background` et `.onBackground`. Un widget qui prend une seule des deux valeurs sans l'autre est un signal de revue de code à corriger avant fusion.

---

## 2. Polices

### Arabe — documents, Coran, livres, lettres

| Police | Usage | Source |
| :--- | :--- | :--- |
| **KFGQPC Uthman Taha Naskh** | Tout contenu arabe de type document : Coran, hadiths, livres, lettres, textes pédagogiques | Google Fonts / CDN |

### Arabe — interface utilisateur

| Police | Usage | Source |
| :--- | :--- | :--- |
| **Noto Sans Arabic** | Affichage RTL, menus, boutons, labels, navigation, tout élément d'interface en arabe | Google Fonts / CDN |

### Français

| Police | Usage | Source |
| :--- | :--- | :--- |
| **Noto Sans** | corps de texte, labels, navigation, tout élément d'interface en français | Google Fonts / CDN |
| **Varela Round** | titres, headings, éléments d'accent en français | Google Fonts / CDN |

### Règles

- Aucune autre police. Si un style manque, étendre l'une des quatre existantes (variations de poids/graisses).
- Les polices arabes sont prioritaires : l'app est bilingue arabe/français, l'arabe est la langue principale.
- Sous-ensembles réduits aux glyphes réellement utilisés (français + arabe), pas de chargement complet.

---

## 3. Icônes

| Librairie | Choix | Raison |
| :--- | :--- | :--- |
| **Phosphor Icons** (`phosphor_flutter`) | Icônes uniques, modernes, 6 poids (thin → duotone), esthétique arrondie cohérente avec le style Storyset/Rafiki | Pas Material (trop générique), pas Font Awesome (daté), pas d'emojis |

### Règles strictes

- **Zéro emoji** dans toute l'app — pas dans le code, pas dans les libellés, pas dans les notifications, pas dans les emails.
- **Pas de M-dash** (`—`) dans le texte utilisateur. Utiliser des deux-points ou une ponctuation classique.
- Une seule librairie d'icônes dans tout le projet. Pas de mélange Material + Phosphor + autre.
- Les icônes Phosphor sont utilisées en `regular` par défaut, `fill` pour les états actifs/sélectionnés.

---

## 4. Illustrations

### Style

- **Storyset / Rafiki** (freepik) : illustrations flat, colorées, personnages stylisés.
- Chaque illustration doit respecter les exigences islamiques (voir §5).

### Contraintes

- Illustrations vectorielles (SVG) privilégiées pour la scalabilité.
- Pas de photos réelles pour les illustrations décoratives — les photos sont réservées aux profils utilisateurs (ADR-012).
- Les illustrations de la bibliothèque Storyset sont sous licence Freepik : vérifier les conditions d'utilisation pour un usage commercial.

---

## 5. Éthique islamique — règles visuelles

L'app traite du Coran et de l'éducation islamique. Chaque élément visuel doit respecter ces règles :

### Obligatoire

- **Pas de femmes non voilées** dans les illustrations, avatars ou images décoratives.
- **Pas d'idoles** ni de représentations de divinités.
- **Pas de caricatures obscènes ou malsaines** — ni dans les illustrations, ni dans le texte, ni dans les emojis.
- **Pas de représentation de prophètes** ni de compagnons du Prophète (durood).
- **Pas de symboles religieux non-musulmans** (croix, étoile à six branches, etc.) dans les illustrations.

### Recommandé

- Personnages masculins avec barbe et/ou kufi/turban quand approprié.
- Personnages féminins avec hijab obligatoire.
- Motifs géométriques et calligraphiques islamiques pour la décoration.
- Couleurs vertes et dorées pour les accents religieux (vert = couleur de l'Islam, or = sacredité).

### Sources d'illustrations

- **Storyset / Rafiki** (freepik) — vérifier chaque illustration contre les règles ci-dessus.
- **Custom SVG** — créer des illustrations sur mesure si aucune librairie ne satisfait les contraintes.
- **Pas de génération IA** d'images — les illustrations sont manuelles ou issues de banques d'images vérifiées.

---

## 6. Règles de copywriting — anti-IA génétique

L'expérience utilisateur ne doit **jamais** ressembler à du contenu généré par IA. Claude et tout rédacteur doivent respecter ces règles :

### Bannis

- Tournures comme « Dans le monde numérique d'aujourd'hui… », « Il est important de noter que… », « Révolutionnez votre… », « Sans plus attendre… », « Chemin de vie… », « Découvrez… ».
- Listes à puces excessives (> 5 éléments) dans le texte utilisateur.
- Em-dash (`—`) — remplacer par des deux-points ou une tournure naturelle.
- Emojis dans le texte, les notifications, les emails, les libellés d'interface.
- Superlatifs exagérés (« incroyable », « exceptionnel », « unique en son genre »).
- Phrases creuses de transition (« En ce qui concerne… », « Passons maintenant à… »).

### Préférer

- Phrases courtes, directes, actionnables.
- Vocabulaire concret (« 3 leçons ce week-end » plutôt que « progressez dans votre parcours »).
- Ton bienveillant mais jamais infantilisant — même en mode enfant.
- Arabe naturel, pas de traduction mot-à-mot du français.

---

## 7. Espacement

Échelle fixe : 4, 8, 12, 16, 20, 24, 32. Aucune valeur ponctuelle en dehors de cette échelle.

---

## 8. Dark mode

Le dark mode n'est pas implémenté à l'étape 2. Les tokens ci-dessus sont pour le light mode uniquement. Le dark mode sera ajouté quand l'interface sera stabilisée.
