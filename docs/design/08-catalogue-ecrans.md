# 08 — Catalogue des écrans

> **Aucun écran ne s'implémente s'il n'est pas dans ce tableau.**
> Si un écran manque, on l'ajoute ici d'abord, avec sa fiche, et on discute de
> la fiche avant d'ouvrir un fichier `.dart`. Sans cette règle, l'agent
> improvise, et c'est exactement ce qui produit les applications incohérentes.

## 1. Le registre

Colonnes : **Niv.** est le niveau de charge de `03-architecture-information.md`
§3. **Prof.** est la profondeur de navigation. **État** dit ce qu'il y a
réellement dans `lib/`, au 7 septembre 2026.

### Zone Accès

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-00` | Connexion | Tous | A | 0 | `/connexion` | Page | Page centrée | construit |
| `ELV-01` | Connexion élève | Élève | B | 0 | `/connexion/eleve` | Page | Page centrée | construit |
| `TUT-00c` | Création de profil | Tuteur, enseignant | C | 1 | `/inscription` | Parcours | Parcours centré | construit |
| `TUT-00b` | Portail d'attente | Tuteur, enseignant | C | 0 | `/attente` | Page | Page centrée | construit |
| `TUT-00c/a` | Accusé enregistrement et contrôle | Tuteur, enseignant | C | 1 | `/attente/accuse` | Page | Page centrée | construit |
| `TUT-00c/b` | Contrat | Tuteur, enseignant | C | 1 | `/attente/contrat` | Page | Page centrée | construit |
| `TUT-00c/c` | Dépôt de la pièce | Tuteur, enseignant | C | 1 | `/attente/piece` | Page | Page centrée | construit |

### Zone Foyer

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-01` | Accueil famille | Tuteur | C | 0 | `/tuteur` | Liste de `ChildCard` | 2 à 3 colonnes + colonne « à confirmer » | construit, **à reprendre** |
| `TUT-02` | Foyer et appareils | Tuteur | C | 1 | `/tuteur/foyer` | Deux listes denses | Deux colonnes | construit |
| `TUT-02/a` | Ajouter un enfant | Tuteur | C | 2 | `/tuteur/foyer/ajouter-enfant` | Parcours | Feuille latérale | construit |
| `TUT-02/b` | Appairer un appareil | Tuteur | C | 2 | `/tuteur/foyer/appairer/:id` | Page, QR grand format | Page centrée | construit |
| `TUT-05` | Réglages par enfant | Tuteur | C | 1 | `/tuteur/reglages` | Une carte par enfant | 2 colonnes | construit |

### Zone Disponibilités et affectation

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-04` | Disponibilités du foyer | Tuteur | C | 1 | `/tuteur/disponibilites` | Grille défilante | Grille entière | construit |
| `ENS-06` | Disponibilités et matching | Enseignant | D | 1 | `/enseignant/creneaux` | Deux onglets | Grille + feed côte à côte | construit, **onglets à supprimer sur desktop** |
| `ADM-05` | Attribution manuelle | Admin | E | 1 | `/admin/attribution` | Deux listes empilées | Deux listes côte à côte | **à construire** |

### Zone Journée et salle

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ELV-02` | Accueil élève | Élève | B / C | 0 | `/eleve` | Deux blocs | Deux blocs centrés, **rien de plus** | construit, **à reprendre** |
| `ENS-02` | Journée | Enseignant | D | 0 | `/enseignant/journee` | Une colonne | Colonne + panneau de détail | construit, **à reprendre** |
| `CTR-01` | Planning global | Contrôleur | D | 0 | `/controleur` | Liste | Tableau dense | **à construire** |
| `ELV-03` | Salle, élève | Élève | B / C | hors arbre | `/salle` | Plein écran | Vidéo + contenu | **à construire**, étape 5 |
| `ENS-03` | Salle, enseignant | Enseignant | D | hors arbre | `/salle` | Plein écran | Vidéo + contenu + participants | **à construire**, étape 5 |
| `CTR-02` | Observation invisible | Contrôleur | D | hors arbre | `/salle` | Plein écran | Idem, bandeau noir permanent | **à construire**, étape 5 |

### Zone Contenu et transmission

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ELV-04` | Coran | Élève, enseignant | B / C | 1 | `/eleve/coran` | Lecteur plein écran | Colonne de lecture bornée | **à construire**, étape 5 |
| `ENS-04` | Cahier de transmission | Enseignant | D | 2 | depuis la salle | Page, une main, 45 s | Panneau | **à construire**, étape 6 |
| `TUT-06` | Suivi du foyer | Tuteur | C | 1 | `/tuteur/suivi` | Liste par enfant | Liste + détail | **à construire** |
| — | Suivi élève | Élève standard | C | 1 | `/eleve/suivi` | Liste | Liste + détail | **à construire** |

### Zone Administration

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ADM-01` | Centre de commande | Admin | E | 0 | `/admin/tableau-de-bord` | Signaux puis chiffres | 4 chiffres + liste pleine largeur | construit, **à reprendre** |
| `ADM-02` | Validation des dossiers | Admin | E | 1 | `/admin/dossiers` | Un dossier à la fois | File à gauche, dossier à droite | construit |
| `ADM-06` | Demandes et règles | Admin | E | 1 | `/admin/demandes` | Liste de demandes | Liste + feuille de règles | construit |
| `ADM-04` | Journal d'audit | Admin | E | 1 | `/admin/journal` | Cartes | Tableau dense | **à construire** |
| `ENS-05` | Profil enseignant | Enseignant | D | 0 | `/enseignant/profil` | Page | Page + colonnes | **à construire** |
| `CPT-01` | Espace comptable | Comptable | E | 0 | `/comptable` | Cartes | Tableaux | **hors MVP-0** (ADR-003) |

**Codes nouveaux introduits par ce catalogue** : `ENS-05` et `CPT-01`, qui
existaient comme routes sans code, et les trois sous-écrans `TUT-00c/a`, `/b`,
`/c`, qui étaient décrits sans être nommés. Aucun code existant n'est renommé.

## 2. Ce que le registre révèle

Onze écrans sont encore `EcranAConstruire`, et trois de ceux qui existent sont à
reprendre par le lot R : `TUT-01`, `ELV-02`, `ENS-02` et `ADM-01`.

Le point à ne pas rater : **`ENS-06` emploie des onglets sur desktop alors qu'il
a la place d'afficher les deux panneaux**. Un onglet sur un écran de 1440 pixels
cache la moitié de l'information sans raison.

## 3. La fiche d'écran

Chaque écran a la sienne, dans ce fichier, en dessous du registre. Elle se
remplit **avant** l'implémentation. Un champ vide est une question à poser, pas
une case à deviner.

```
CODE              ENS-06
Nom               Disponibilités et matching
Rôle              Enseignant
Zone              Disponibilités et affectation
Niveau de charge  D
Écran parent      ENS-02
Profondeur        1
Question          Quand suis-je libre, et qui attend un enseignant ?

Priorités         P0  la grille de mes disponibilités
                  P0  le feed des élèves en attente, trié par ancienneté
                  P1  le nombre de places restantes sur mon plafond
                  P2  l'accès à la demande d'augmentation de plafond

Action principale     Prendre un élève
Actions secondaires   Poser ou retirer un créneau
Action tertiaire      Demander une augmentation de plafond
Destructif            aucun

Mobile            deux onglets
Tablette          grille au dessus, feed en dessous
Desktop           grille à gauche, feed à droite, pas d'onglet

États             loading   squelette de grille + trois lignes de feed
                  content   nominal
                  empty     « Aucune famille en attente sur vos créneaux »,
                            sans bouton : l'enseignant ne peut rien y faire
                  error     message sur le feed seul, la grille reste utilisable
                  offline   grille consultable, prise impossible et dite

Mouvement         prise d'un élève : la carte sort par le motif « suppression »,
                  retour local « Aicha vous est affectée »
                  créneau posé : la case change d'état, 160 ms

Invariants        le tri est par ancienneté d'attente, jamais alphabétique
                  la base tranche la concurrence, jamais l'écran
                  le feed rend une ligne par créneau, pas par élève :
                  compter les lignes annoncerait quatre familles pour une

Accessibilité     cases de grille à 44 minimum, label parlé « Lundi 17 heures,
                  disponible », grille lisible de droite à gauche en arabe
```

Les fiches des écrans à construire se remplissent au moment de leur lot. Les
fiches des écrans déjà construits se remplissent au lot R, **à partir du code
existant**, ce qui sert aussi de relecture.

## 4. Invariants déjà acquis, à ne pas casser en reprenant un écran

Ces règles ont chacune coûté un défaut. Elles sont détaillées dans les journaux
d'étape ; elles sont rappelées ici parce que le lot R touchera les écrans qui
les portent.

| Écran | Invariant |
| :--- | :--- |
| `ELV-03`, `ENS-03`, `CTR-02` | Le bandeau permanent ne change **jamais**, y compris pendant une visite de contrôle. Son composant n'accepte aucun paramètre de visibilité |
| `ELV-03` | Micro et caméra fermés à l'entrée, un tap les ouvre. Vrai pour tous les rôles |
| `ELV-03` | Quand la politique du profil interdit la caméra, le bouton **n'existe pas**, il n'est pas grisé |
| `ENS-03` | La sortie mène obligatoirement à `ENS-04`. Aucun autre chemin |
| `ENS-06` | Tri par ancienneté d'attente. `order()` de postgrest trie en descendant par défaut : le sens s'écrit toujours |
| `ENS-02` | Pauses et prières sont des entrées de la même colonne, pas un bloc séparé |
| `ADM-01` | Le zéro s'affiche comme les autres valeurs |
| `ADM-02` | Constat et jugement séparés : document en haut, vérification au milieu, verdicts en bas |
| `TUT-02` | À la limite de deux appareils, le bouton d'ajout est **remplacé par une phrase** |
| `TUT-01` | « Assister » entre en observateur muet, et l'enseignant le voit arriver |
| Tous | Rien ne se ferme sur minuterie |

## 5. Ordre de reprise

| Lot | Écrans | Pourquoi cet ordre |
| :--- | :--- | :--- |
| **T** | aucun | Jetons, thème, typographie, mouvement. Reprendre un écran avant obligerait à le reprendre deux fois |
| **C** | aucun | Les douze composants P0 de `07-catalogue-composants.md`, et leur galerie |
| **R1** | `ELV-02` | C'est l'écran montré à l'opérateur, et le plus simple : deux blocs. Il sert de preuve du système |
| **R2** | `TUT-01` | Il porte `ChildCard`, composant du domaine famille |
| **R3** | `ENS-02`, `ADM-01` | Les deux tableaux de bord denses, une fois que `StatTile`, `SignalRow` et `TimelineRow` existent |
| **R4** | `TUT-02`, `TUT-04`, `TUT-05`, `ENS-06`, `ADM-02`, `ADM-06` | Le reste de l'existant |
| **N** | les onze écrans manquants | Chacun avec sa fiche remplie d'abord |
