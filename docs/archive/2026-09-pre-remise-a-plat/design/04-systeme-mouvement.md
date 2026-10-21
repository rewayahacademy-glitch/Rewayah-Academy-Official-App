# 04 — Système de mouvement

Le mouvement a une fonction : expliquer un changement, donner un retour,
maintenir la continuité dans l'espace. Un mouvement qui ne fait aucun des trois
se retire.

## 1. Le budget de durée

Une interaction fréquente doit rester rapide. C'est la règle qui empêche un
système de mouvement de devenir un handicap au bout de trois semaines d'usage.

| Classe | Durée | Ce qui l'emploie |
| :--- | :--- | :--- |
| Retour tactile | **120 ms** | La pression d'un élément. Déjà tenu par `Pressable` |
| Micro-interaction | **160 ms** | Bascule, case cochée, pastille qui change d'état, survol |
| Apparition, disparition | **200 ms** | Une ligne qui entre ou sort d'une liste, un bandeau, un retour local |
| Navigation | **240 ms** | Passage d'une page à l'autre |
| Feuille de bas d'écran | **280 ms** | Ouverture. Fermeture à 200 ms |
| Transition qui explique | **400 ms maximum** | Uniquement si elle montre d'où vient quelque chose : conteneur partagé, saut vers une référence du Coran |

**Rien au dessus de 400 ms.** Une animation plus longue que ça n'explique plus,
elle fait attendre.

## 2. Les courbes

Trois, pas davantage.

| Courbe | Emploi |
| :--- | :--- |
| `easeOutCubic` | Tout ce qui entre. Rapide au départ, s'installe doucement |
| `easeInCubic` | Tout ce qui sort. La sortie est toujours **plus courte** que l'entrée, d'environ un tiers |
| Ressort léger, amorti | Uniquement les feuilles et le conteneur partagé. Amortissement élevé : aucun rebond visible, seulement une arrivée qui n'est pas mécanique |

Interdit : `linear` pour autre chose qu'une rotation continue ou une barre de
progression indéterminée. `bounceOut` et `elasticOut` n'existent pas dans ce
produit, y compris en mode enfant. Un rebond sur une interface d'enfant paraît
enfantin aux adultes qui paient et lent aux enfants qui l'utilisent trois fois
par jour.

## 3. Les six motifs

Tout ce qui bouge dans Rewayah relève de l'un de ces six. Un septième motif se
discute avant de s'écrire.

### Ajout

```
opacité      0 → 1
translation  Y +8 → 0
durée        200 ms, easeOutCubic
```

En liste, les éléments suivants se décalent dans le même temps, pas après.

### Suppression

```
opacité      1 → 0        120 ms
hauteur      h → 0        200 ms, easeInCubic, en chaîne
```

L'opacité part d'abord, la hauteur ensuite : l'inverse donne l'impression que la
ligne est aspirée. Et la ligne disparue laisse un retour local court à sa place
(`02-regles-ux.md` §7).

### Modification

**Le composant reste à sa place, seule la valeur change.** Un compteur qui passe
de 17 à 18 anime son chiffre, pas sa carte. Un état qui passe de « à venir » à
« en direct » anime sa pastille et son libellé, pas l'écran.

C'est le motif le plus souvent raté : recharger l'écran entier pour un champ qui
change fait clignoter tout ce qui n'a pas bougé, et fait perdre la position de
lecture.

### Navigation

```
page sortante   opacité 1 → 0,6, translation X -16
page entrante   opacité 0 → 1, translation X +16 → 0
durée           240 ms
```

**Le sens s'inverse en RTL.** Une page qui entre par la droite en français entre
par la gauche en arabe, y compris son ombre portée.

Le retour joue le mouvement inverse, pas le même.

### Feuille de bas d'écran

```
translation  Y +hauteur → 0
voile        0 → 0,32 d'opacité
durée        280 ms à l'ouverture, 200 ms à la fermeture, ressort amorti
```

La feuille suit le doigt pendant le glissement, et ne se referme que si la
vitesse ou la distance dépasse le seuil. Une feuille qui se referme sur un
effleurement est une feuille qu'on n'ose plus toucher.

### Retour local

```
apparition   opacité 0 → 1, translation Y +12 → 0, 200 ms
maintien     3 s, ou jusqu'à l'action suivante
disparition  opacité 1 → 0, 160 ms
```

Il se pose près de ce qui a changé, jamais au centre de l'écran, et il n'empêche
jamais de continuer.

## 4. Ce que le mouvement ne fait pas

- Il ne remplace pas un état de chargement. Un squelette n'est pas une
  animation d'attente, c'est la forme de ce qui arrive.
- Il ne récompense pas. Une seule exception, écrite dans les parcours : la sortie
  de séance de l'élève enfant, « moins d'une seconde », et elle reste un
  encouragement, pas une fête.
- Il n'attire pas l'attention sur ce qui n'en demande pas. Un seul élément peut
  pulser à l'écran, et un seul : le bloc « cours dans moins de 5 minutes »
  d'`ELV-02`. Deux pulsations simultanées annulent le sens des deux.
- Il ne cache pas la lenteur. Si une opération prend deux secondes, on le dit ;
  on ne l'habille pas.

## 5. Réduction du mouvement

Non négociable, et c'est un cas à tester, pas une case à cocher.

Quand le système signale la préférence (`MediaQuery.disableAnimations`) :

| Motif | Ce qui reste |
| :--- | :--- |
| Ajout, suppression | L'opacité seule, 120 ms. Aucune translation, aucune variation de hauteur |
| Navigation | Un fondu de 120 ms. Aucun glissement |
| Feuille | Apparition immédiate avec le voile en fondu |
| Modification | Inchangée : elle est déjà minimale |
| Pulsation | **Remplacée par une bordure fixe** `borderStrong`, jamais simplement supprimée : l'information portée par la pulsation doit survivre |
| Retour local | Inchangé, sans translation |

La dernière ligne est celle qu'on rate : supprimer une animation qui portait du
sens supprime le sens avec elle.

## 6. Haptique

Rare, et jamais décoratif. Trois usages, pas plus :

- `mediumImpact` à la pression d'un élément interactif. Déjà tenu par `Pressable`.
- `selectionClick` au passage d'un cran : une case de la grille de
  disponibilités, un chiffre du pavé PIN.
- Un motif court à l'entrée en séance et à l'alerte de prière imminente, parce
  que ces deux là comptent même quand l'appareil est posé.

Aucun retour haptique sur un défilement, une apparition ou une erreur de saisie.

## 7. Ce qui se vérifie

- Aucune `Duration` littérale dans `lib/features/` : elles viennent toutes du
  fichier de mouvement, comme les couleurs viennent de la palette.
- Aucune `Curve` littérale hors de ce même fichier.
- Un test de widget par motif, qui mesure la durée et non l'existence de
  l'animation. Le piège est déjà connu : chercher un type de widget ne prouve
  rien quand un composant partagé emploie le même type pour autre chose. Le test
  de la pulsation d'`ELV-02` trouvait les `ScaleTransition` du retour tactile de
  `Pressable` et serait resté vert sans aucune pulsation. Chaque animation
  porteuse de sens porte donc une clé nommée.
