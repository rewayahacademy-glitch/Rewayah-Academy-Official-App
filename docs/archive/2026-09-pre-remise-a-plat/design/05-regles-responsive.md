# 05 — Responsive et Web

Le Web est ouvert à tous les rôles (ADR-008), et tant que le natif n'est pas
publié, la PWA est le seul chemin d'accès réel. Un écran mal adapté au desktop
n'est donc pas un détail de confort : c'est l'écran que l'opérateur voit.

## 1. Quatre classes de largeur, trois chromes

| Gabarit | Largeur | Chrome de navigation | Gouttière |
| :--- | :--- | :--- | :-: |
| Compact | < 600 | Barre basse | 16 |
| Moyen | 600 à 839 | Rail latéral 80 | 24 |
| Étendu | 840 à 1199 | Rail latéral 80 | 24 |
| Large | ≥ 1200 | Barre latérale permanente 256 | 32 |

**Trois présentations, pas quatre applications.** Les mêmes composants, la même
arborescence de routes, les mêmes données. Ce qui change : le chrome, le nombre
de colonnes, et la manière dont un détail s'ouvre.

Les seuils vivent dans un seul fichier de jetons. Aucun `MediaQuery.of(context).size.width > 700`
dispersé dans un écran : c'est ainsi qu'un produit finit avec quatre seuils
différents et trois d'entre eux faux.

## 2. La règle de l'agrandissement

> **Ne pas agrandir l'application mobile. Réorganiser.**

Un écran mobile étiré sur 1400 pixels donne une colonne de contenu perdue au
milieu d'un désert. Trois remèdes, dans cet ordre de préférence :

1. **Ouvrir le détail à côté, au lieu de naviguer.** Une liste à gauche, le
   détail à droite. C'est le gabarit de `ADM-02`, `TUT-06`, du suivi élève et de
   toute messagerie future.
2. **Passer d'une à plusieurs colonnes.** Une liste de cartes devient une grille
   de deux ou trois, jamais plus de trois : au delà, la carte devient une
   vignette et cesse d'être lisible.
3. **Centrer et borner.** Un contenu qui n'a ni détail ni grille se centre sur
   1200 au maximum, et un texte suivi sur 68 caractères.

## 3. Ce que chaque zone devient

| Écran | Mobile | Tablette | Desktop |
| :--- | :--- | :--- | :--- |
| `ELV-02` accueil enfant | Deux blocs empilés | Deux blocs, plus d'air | Identique, centré et borné. **On n'ajoute rien** : le niveau B ne gagne pas de densité avec la largeur |
| `TUT-01` accueil famille | Une carte enfant par ligne | Deux colonnes | Trois colonnes au maximum, plus la colonne « à confirmer » à droite |
| `TUT-04` / `ENS-06` grille | Semaine défilante horizontalement, un jour visible et demi | Semaine entière, cases compactes | Semaine entière plus le feed d'attente à droite, au lieu d'un onglet |
| `ENS-02` journée | Une colonne, du haut vers le bas | Une colonne large plus le bloc matching à droite | Colonne de journée plus panneau de détail de la séance sélectionnée |
| `ADM-01` centre de commande | Signaux empilés, puis chiffres | Grille de deux | Grille de quatre chiffres, liste « à traiter » pleine largeur en dessous |
| `ADM-02` validation | Une page par dossier | Idem | Liste de la file à gauche, dossier à droite. Le document reste au dessus de la grille de vérification, jamais à côté |
| `ADM-04` journal | Cartes | Cartes | **Tableau dense**, c'est sa forme naturelle |
| `ELV-04` Coran | Plein écran | Plein écran | Colonne de lecture bornée, marges généreuses. Jamais une ligne de texte de 1400 pixels |
| Salle | Vidéo plein écran, commandes en bas | Vidéo plus contenu partagé | Vidéo à gauche, participants et contenu pédagogique à droite. **Le contenu pédagogique doit pouvoir prendre la place de la vidéo**, pas seulement la compléter |

## 4. Les tableaux

Le point le plus souvent raté.

**Sur desktop, à partir du niveau de charge D**, un vrai tableau : en-tête
`surfaceSunken` collé en haut, lignes en densité compacte, tri par colonne,
chiffres tabulaires, dernière colonne d'action alignée à droite.

**Sur mobile, jamais de tableau rétréci.** Chaque ligne devient une carte :

```
Aicha · ID-24
Payé · 300 SAR
Septembre                                    ›
```

La règle de transformation : la colonne identifiante devient le titre, deux à
trois colonnes deviennent la ligne secondaire, le reste passe dans le détail.
Une carte qui reprend les douze colonnes n'est plus une carte.

C'est un composant unique, `DataCollection`, qui rend un tableau ou une liste de
cartes selon le gabarit, à partir de la même définition de colonnes. Deux
implémentations séparées divergeraient au premier ajout de colonne.

## 5. Interaction selon l'entrée

Le survol n'existe pas au doigt, et le clavier n'existe pas au téléphone. Un
état ne doit jamais reposer sur un seul des deux.

| Entrée | Ce qui doit exister |
| :--- | :--- |
| Doigt | État pressé, cible de 44 minimum, 72 en mode enfant |
| Souris | État de survol distinct de l'état pressé, curseur adapté |
| Clavier | Anneau de focus visible sur `borderStrong` ou `surfacePrimary`, ordre de tabulation qui suit l'ordre de lecture, `Échap` qui ferme, `Entrée` qui valide |

Sur desktop, quatre raccourcis au maximum, et ils doublent toujours un bouton
visible. Un raccourci sans bouton n'existe pas pour la personne qui ne l'a pas
appris.

## 6. Le registre éditorial

Un écran de lecture n'a pas le gabarit d'un écran de travail. S'il apparaît un
jour dans l'application (annonces, page de contenu long), il prend :

- une colonne de 68 caractères, centrée ;
- une image en tête, pleine largeur de colonne ;
- pas de carte, pas d'ombre, pas de barre d'outils flottante ;
- la police de titre en grande taille, avec l'axe optique réglé en conséquence.

## 7. RTL

L'arabe n'est pas un cas particulier de ce produit, c'est sa langue principale.
Tout ce qui précède se lit en miroir.

- Aucun `EdgeInsets.only(left:)` ni `Alignment.centerLeft` : uniquement les
  variantes directionnelles. C'est vérifiable par un outil, et ça doit l'être.
- La barre latérale passe à droite, le rail aussi, les chevrons de liste aussi.
- Le sens des transitions de navigation s'inverse (`04-systeme-mouvement.md` §3).
- Une grille de semaine se lit de droite à gauche : le lundi est à droite.
- Les chiffres et les heures ne se miroitent pas, la progression du temps non plus.

**Un écran se relit en arabe avant d'être déclaré fini**, pas après. Un
`Directionality` posé dans un test de widget suffit à le vérifier, et coûte
moins cher que la reprise.

## 8. Ce qui se vérifie

1. Un même écran rendu à 390, 768 et 1440 ne provoque aucun débordement.
2. Aucun seuil de largeur littéral hors du fichier de gabarits.
3. Aucun `EdgeInsets` non directionnel dans `lib/features/`.
4. Chaque écran du catalogue a une capture aux trois largeurs, en français et en
   arabe, dans la galerie de composants (`/_galerie`).

## 9. Zoning physique d'un écran

Ajouté au lot B0 (Bible Frontend V2 §6). Un « zoning » différent de celui de la
section 3 : la section 3 dit comment une zone se redispose selon la largeur, le
zoning ci-dessous dit ce qu'une zone du haut vers le bas de l'écran a le droit
de contenir, quelle que soit la largeur. Les deux se lisent ensemble, jamais
l'un à la place de l'autre.

| Zone | Autorisé | Interdit |
| :--- | :--- | :--- |
| **AppBar / en-tête** | Navigation, contexte, titre, une action primaire, une action contextuelle, identité, statut bref | Formulaire complexe, longue liste, plusieurs actions critiques concurrentes, information secondaire massive |
| **Contenu principal** | L'objet de la tâche de l'écran, avec la plus grande priorité visuelle | Être partagé avec un deuxième objet de même poids (`02-regles-ux.md` §1, « un seul bloc dominant ») |
| **Zone secondaire** | Metadata, informations auxiliaires, outils secondaires, navigation contextuelle | Contenu qui devrait être l'objet principal d'un autre écran |
| **Zone d'action basse** | Une action primaire persistante si nécessaire, un CTA contextuel, une navigation secondaire | Empiler toutes les actions disponibles (`02-regles-ux.md` §4) |
| **Desktop à panneaux** | `Navigation \| Contenu primaire \| Contexte / outils`, le panneau de contexte restant secondaire | Un panneau de contexte qui rivalise en largeur ou en poids visuel avec le contenu primaire |

Chaque fiche d'écran de `08-catalogue-ecrans.md` §3 doit pouvoir se lire selon
ce zoning avant d'être codée : c'est l'étape 3 du protocole avant codage de la
Bible (§44).
