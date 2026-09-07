# 01 — Système visuel

> **Les valeurs sont dans `docs/produit/design-tokens.md`.** Ce document dit
> comment on les emploie. Aucun hex, aucun nom de fichier de police ici : un
> second tableau de valeurs finirait par diverger du premier, et c'est toujours
> le mauvais qui est recopié.

## 1. Le diagnostic, avant les règles

Le premier rendu a été jugé daté. Voici pourquoi, précisément, pour que la
correction ne soit pas cosmétique.

| Symptôme | Cause réelle |
| :--- | :--- |
| Tout paraît plat | Une seule surface. Le fond de page, la carte, le champ de saisie et l'en-tête partagaient la même couleur. Sans deux surfaces, il n'y a pas de hiérarchie possible |
| Les couleurs paraissent brutales | Les couleurs de marque n'existaient qu'en aplats pleins et saturés. Un avertissement occupait un pavé `#FFB703` entier là où il fallait une teinte pâle et une encre foncée |
| Le fond paraît sale, ou jaunâtre | Le fond était le rose pâle de la charte, `#F1E3E4`, teinte 356°. Sur un écran chaud il vire au beige sale, sur un écran froid au mauve |
| Les bordures n'existent pas | Un seul jeton de bordure, mesuré à 1,86:1, donc invisible et pourtant employé pour délimiter |
| Ça date | Aucun crénage optique, aucun rayon systématique, aucune ombre, et une police de titre à graisse unique et terminaisons arrondies, dont le registre appartient au début des années 2010 |

Les cinq se corrigent ensemble ou pas du tout.

## 2. Trois surfaces, pas une

C'est le changement structurant. Une interface se lit par ses plans, pas par ses
traits.

| Plan | Jeton | Ce qui y vit |
| :--- | :--- | :--- |
| Fond | `surfaceCanvas` | La page. Le crème. Rien n'est posé directement dessus sans être dans une carte ou une section |
| Élevé | `surfaceRaised` | Cartes, tuiles Bento, feuilles, menus, barres de navigation. C'est là que vit le contenu |
| Enfoncé | `surfaceSunken` | Champs de saisie, en-têtes de tableau, pistes de barres de progression, cases vides d'une grille de disponibilités |

Règles :

- **Une carte n'est jamais posée sur une carte.** Deux niveaux d'élévation
  suffisent à tout le produit. Un troisième signifierait que la hiérarchie de
  l'écran est fausse.
- **Une surface élevée porte un filet ET une ombre**, jamais l'un des deux seul.
  Le filet tient sur un écran mal calibré et en contraste élevé ; l'ombre donne
  la profondeur. Voir les jetons `borderHairline` et `elevation1`.
- **Le fond ne porte jamais de texte long.** Un paragraphe se lit sur une carte,
  ou dans une colonne de largeur de lecture bornée (§6).

### La bordure, enfin utilisable

Le jeton unique qui mesurait 1,86:1 est remplacé par trois, dont deux sont
mesurés et l'un d'eux porte du sens. La question ouverte 10 du registre est
close par là.

| Jeton | Emploi | Mesure |
| :--- | :--- | :--- |
| `borderHairline` | Séparation entre deux blocs, contour d'une carte | Décoratif. Jamais seul porteur de sens |
| `borderResting` | Contour d'un contrôle au repos : champ, case à cocher | Décoratif, accompagné d'un fond enfoncé |
| `borderStrong` | Contour porteur de sens : sélection, bord de tableau dense, bordure sur photo | **≥ 3:1 mesuré sur les trois surfaces** |

Un focus, une erreur, une sélection passent toujours par `borderStrong` ou par
une couleur sémantique, jamais par `borderResting`.

## 3. La couleur : deux registres pour chaque famille

C'est la réponse au « pas brutal ». Les cinq couleurs de marque sont conservées,
et chacune existe désormais en deux registres.

| Registre | Forme | Quand |
| :--- | :--- | :--- |
| **Plein** | `surfaceX` : fond saturé + encre claire ou noire | Une seule chose par écran, au plus : l'action principale. Un bouton, une pastille « en direct », rien d'autre |
| **Doux** | `washX` + `inkX` : teinte très pâle + encre foncée de la même teinte | Tout le reste : bandeaux d'état, badges, lignes d'alerte, tuiles de statistique, fonds de section |

La règle qui évite le carnaval :

> **Une seule zone pleine par écran.** Si un écran contient deux aplats
> saturés, l'un des deux est un badge et doit passer en registre doux.

Exemples concrets, en remplacement de ce qui existe :

| Cas | Avant | Après |
| :--- | :--- | :--- |
| Rapport en retard | Bandeau `surfaceWarning` plein, ambre saturé sur toute la largeur | `washWarning` en fond, `inkWarning` pour le texte, icône `inkWarning`, filet `borderStrong` à gauche |
| Cours en direct | Bloc `surfaceSuccess` plein | Carte normale, pastille pleine `surfaceSuccess` de 8 pt, et le bouton d'entrée en `surfacePrimary` |
| Erreur de formulaire | Texte `inkAlert` sous le champ | Inchangé, c'était juste. Le champ prend en plus un contour `surfaceAlert` de 2 pt |
| Bloc « cours dans moins de 5 minutes » d'`ELV-02` | Bloc violet plein qui pulse | Conservé plein : c'est la seule zone pleine de cet écran, et c'est son action principale |

### Les couleurs de domaine

Deux teintes ne signifient pas un état mais un lieu du produit. Elles ne se
mélangent jamais aux sémantiques.

- `washFamily`, le rose pâle d'origine, marque le domaine du foyer : cartes
  enfant de `TUT-01`, avatars, `TUT-05`. Il conserve la couleur de la charte et
  lui donne enfin un rôle, au lieu d'être le fond de tout le produit.
- `surfaceQuran`, un parchemin légèrement plus chaud que le crème, marque le
  lecteur. C'est ce que `parcours-utilisateurs.md` demandait pour `ELV-04` :
  « un fond légèrement plus chaud que le reste de l'application ».

### Ce qui reste interdit

- Aucune couleur hors des jetons. `tool/verifier_jetons.dart` le tient déjà.
- Aucune paire inventée : le thème n'expose que des paires `(fond, encre)`, et
  les encres sur fond clair passent par `AppInkColor`, qui ne peut pas servir de
  fond (`design-tokens.md` §1).
- Le violet plein `#8652E6` **ne s'écrit jamais en texte sur une surface claire** :
  mesuré à 4,39:1 sur le crème. C'est pour ça que `inkAccent` existe.

## 4. Élévation et rayons

Trois ombres, cinq rayons, pas davantage. Valeurs dans `design-tokens.md` §9.

| Niveau | Emploi |
| :--- | :--- |
| `elevation0` | Aucune ombre : ce qui est posé à plat sur le fond, sections, séparateurs |
| `elevation1` | Cartes, tuiles Bento, lignes de liste cliquables. C'est le défaut |
| `elevation2` | Ce qui flotte au dessus du contenu : menu, popover, barre de navigation en position collée, carte pressée |
| `elevation3` | Ce qui recouvre : feuille de bas d'écran, boîte de dialogue |

L'ombre est **chaude**, dérivée du noir de la charte tiré vers le brun. Une
ombre grise neutre sur un fond crème se lit comme une salissure.

Rayons : `radiusXs` pour les pastilles et petits contrôles, `radiusSm` pour les
champs et boutons, `radiusMd` pour les cartes, `radiusLg` pour les tuiles Bento
et les feuilles, `radiusFull` pour les avatars et pilules d'état.

**Le rayon d'un enfant est plus petit que celui de son parent.** Une vignette
dans une carte de rayon `radiusMd` prend `radiusSm`. L'inverse produit l'effet de
bulle qui date le produit.

## 5. Typographie

L'arabe ne change pas. Le français change, entièrement.

| Emploi | Famille | Pourquoi |
| :--- | :--- | :--- |
| Arabe, documents | **inchangée** | Coran, hadiths, livres, lettres |
| Arabe, interface | **inchangée** | RTL, menus, boutons, labels |
| Français, titres et chiffres | **nouvelle** | La précédente n'avait qu'une graisse et un registre arrondi de 2012 |
| Français, corps et interface | **nouvelle** | La précédente pesait 2 Mo pour une interface française et n'avait aucune personnalité |

Détail des familles retenues, de leurs axes variables et de leur licence :
`design-tokens.md` §2.

### Ce qui date un texte, et qui manquait

1. **Le crénage optique.** Aucun `letterSpacing` n'était posé nulle part. Les
   grands titres restaient donc à l'espacement d'un corps de texte, ce qui les
   fait paraître lâches et amateurs. Barème dans `design-tokens.md` §10 :
   négatif au dessus de 18 pt, neutre au corps, positif en dessous de 14 pt.
2. **La taille optique.** La police de titre retenue porte un axe `opsz` : il se
   règle sur la taille rendue, jamais laissé à sa valeur par défaut de 14. Une
   police de titre dessinée pour 14 pt et affichée à 40 pt paraît molle.
3. **Les chiffres tabulaires.** Tout chiffre qui vit dans une colonne, un
   compteur, un minuteur ou une tuile de statistique emploie `tnum`. Sans lui,
   un compteur qui passe de 17 à 18 fait bouger la ligne entière.

### Rôles de texte

L'échelle Material existante est conservée dans ses tailles. Ce qui change :
la famille, la graisse, le crénage, et l'interligne des grands corps, resserré.

| Rôle Material | Famille | Emploi |
| :--- | :--- | :--- |
| `displayLarge` à `displaySmall` | Titre | Le chiffre géant d'`ELV-02`, le nombre d'une tuile de statistique |
| `headlineLarge` à `headlineSmall` | Titre | Titre d'écran, titre de section |
| `titleLarge` à `titleSmall` | Corps, graisse 600 | Titre de carte, en-tête de ligne |
| `bodyLarge` à `bodySmall` | Corps, graisse 400 | Texte courant, légendes |
| `labelLarge` à `labelSmall` | Corps, graisse 600 | Boutons, onglets, pastilles, métadonnées |

Les deux échelles, standard et enfant, restent construites au même endroit et
au facteur 1,2 (`app_typography.dart`). Aucun écran n'applique de multiplicateur.

## 6. Rythme, grille et largeur de lecture

L'échelle d'espacement est étendue vers le haut : les paliers courts servaient
l'intérieur des composants, il manquait ceux du rythme de page.

| Usage | Palier |
| :--- | :--- |
| Intérieur d'un contrôle, écart icône/texte | 4, 8, 12 |
| Intérieur d'une carte, écart entre deux lignes de liste | 16, 20, 24 |
| Écart entre deux cartes | 12 sur mobile, 16 au dessus |
| Écart entre deux sections | 32, 40 |
| Marge haute d'un titre d'écran | 48 |
| Respiration d'un écran vide ou d'un accueil enfant | 64 |

**Gouttières de page** : 20 sur mobile, 32 sur tablette, 48 sur desktop.
**Largeur maximale de contenu** : 1200. Au delà, la colonne se centre.
**Largeur de lecture** : 68 caractères pour tout texte suivi, annonces
comprises. Un paragraphe sur 1200 pixels ne se lit pas, il se survole.

## 7. Densité

Trois densités, choisies par le niveau de charge de l'écran
(`03-architecture-information.md` §3), jamais par le goût de qui construit.

| Densité | Hauteur de ligne de liste | Où |
| :--- | :--- | :--- |
| Aérée | 88 et plus | Élève mode enfant, accueil famille, écrans à une seule décision |
| Standard | 64 à 72 | Tout le reste |
| Compacte | 48 à 56 | Tableaux d'administration et de comptabilité, journal d'audit, sur desktop uniquement |

La densité compacte **n'existe pas sur mobile**. Sur mobile, une ligne de tableau
devient une carte (`05-regles-responsive.md` §4).

## 8. Iconographie et illustration

Inchangées : Phosphor en `regular`, `fill` pour les états actifs, zéro emoji,
règles islamiques et style d'illustration dans `design-tokens.md` §3, §4 et §5.

Deux précisions que la refonte ajoute :

- **L'icône ne porte jamais seule un état.** Une pastille de couleur, une icône
  et un mot : au moins deux des trois. Un daltonien lit le mot, un lecteur
  d'écran lit le label.
- **Les icônes directionnelles se miroitent en RTL**, y compris celle de retour,
  celle de « suivant » et les chevrons de liste. La flèche de progression du
  temps, elle, ne se miroite pas. Détail dans `06-accessibilite.md` §5.

## 9. Ce qui se vérifie automatiquement

Une règle de style qui n'est pas vérifiée par un outil n'est pas une règle :
c'est un souhait, et l'étape suivante la contredit.

Les cinq règles demandées au lot T sont dans `tool/verifier_jetons.dart`, et
deux de plus s'y sont ajoutées en cours de route.

| Règle | Nom de la violation | État |
| :--- | :--- | :--- |
| Aucun `BorderRadius.circular` littéral hors des jetons de rayon | `rayon-litteral` | tenu |
| Aucun `BoxShadow` construit hors du fichier d'élévation | `ombre-hors-echelle` | tenu |
| Aucun `letterSpacing` littéral hors du fichier de typographie | `crenage-litteral` | tenu |
| Aucun `Color` littéral hors d'`app_palette.dart` | `couleur-nue` | tenu depuis l'étape 2 |
| Aucune valeur d'espacement hors de l'échelle | `espacement-hors-echelle` | tenu depuis l'étape 2 |
| Aucune durée d'animation ni courbe nommée hors du fichier de mouvement | `duree-litterale`, `courbe-litterale` | ajouté au lot T |
| Aucun nom de jeton d'avant la refonte | `vocabulaire-perime` | ajouté au lot T |

Les deux dernières lignes viennent de `04-systeme-mouvement.md` section 7 et de
`design-tokens.md` section 1.8. La règle de mouvement ne vise que
`Duration(milliseconds: ...)` : une durée métier en minutes ou en heures n'est
pas du mouvement, et l'interdire aurait fait une règle fausse.

**Ces sept règles ont été vérifiées en les faisant échouer**, sur un fichier
piège écrit puis retiré : une règle qu'on n'a jamais vue refuser quelque chose
n'est pas une règle prouvée.
