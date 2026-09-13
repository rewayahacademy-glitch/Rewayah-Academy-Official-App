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
| `TUT-00` | Connexion | Tous | A | 0 | `/connexion` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `ELV-01` | Connexion élève | Élève | B | 0 | `/connexion/eleve` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c` | Création de profil | Tuteur, enseignant | C | 1 | `/inscription` | Parcours | Parcours centré | construit, fiche §6 |
| `TUT-00b` | Portail d'attente | Tuteur, enseignant | C | 0 | `/attente` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c/a` | Accusé enregistrement et contrôle | Tuteur, enseignant | C | 1 | `/attente/accuse` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c/b` | Contrat | Tuteur, enseignant | C | 1 | `/attente/contrat` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c/c` | Dépôt de la pièce | Tuteur, enseignant | C | 1 | `/attente/piece` | Page | Page centrée | **repris (R0)**, fiche §6 |

### Zone Foyer

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-01` | Accueil famille | Tuteur | C | 0 | `/tuteur` | Liste de `ChildCard` | 2 à 3 colonnes + colonne « à confirmer » | **repris (R2)**, fiche §6 |
| `TUT-02` | Foyer et appareils | Tuteur | C | 1 | `/tuteur/foyer` | Deux listes denses | Deux colonnes | **repris (R4)**, fiche §6 |
| `TUT-02/a` | Ajouter un enfant | Tuteur | C | 2 | `/tuteur/foyer/ajouter-enfant` | Parcours | Feuille latérale | **repris (R4)**, fiche §6 |
| `TUT-02/b` | Appairer un appareil | Tuteur | C | 2 | `/tuteur/foyer/appairer/:id` | Page, QR grand format | Page centrée | **repris (R4)**, fiche §6 |
| `TUT-05` | Réglages par enfant | Tuteur | C | 1 | `/tuteur/reglages` | Une carte par enfant | 2 colonnes | **repris (R4)**, fiche §6 |

### Zone Disponibilités et affectation

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-04` | Disponibilités du foyer | Tuteur | C | 1 | `/tuteur/disponibilites` | Grille défilante | Grille entière | **repris (R4)**, fiche §6 |
| `ENS-06` | Disponibilités et matching | Enseignant | D | 1 | `/enseignant/creneaux` | Deux onglets | Grille + feed côte à côte | **repris (R4)**, fiche §6 |
| `ADM-05` | Attribution manuelle | Admin | E | 1 | `/admin/attribution` | Deux listes empilées | Deux listes côte à côte | **construit (12/09)**, fiche §6 |

### Zone Journée et salle

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ELV-02` | Accueil élève | Élève | B / C | 0 | `/eleve` | Deux blocs | Deux blocs centrés, **rien de plus** | **repris (R1)**, fiche §6 |
| `ENS-02` | Journée | Enseignant | D | 0 | `/enseignant/journee` | Une colonne | Colonne + panneau de détail | **repris (R3)**, fiche §6 |
| `CTR-01` | Planning global | Contrôleur | D | 0 | `/controleur` | Liste | Tableau dense | **construit (13/09)**, fiche §6 |
| `ELV-03` | Salle, élève | Élève | B / C | hors arbre | `/salle` | Plein écran | Vidéo + contenu | **construit (12/09)**, fiche §6 |
| `ENS-03` | Salle, enseignant | Enseignant | D | hors arbre | `/salle` | Plein écran | Vidéo + contenu + participants | **construit (12/09)**, fiche §6 |
| `CTR-02` | Observation invisible | Contrôleur | D | hors arbre | `/salle` | Plein écran | Idem, bandeau de contrôle permanent | **construit (12/09)**, fiche §6 |

### Zone Contenu et transmission

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ELV-04` | Coran | Élève, enseignant | B / C | 1 | `/eleve/coran` | Lecteur plein écran | Colonne de lecture bornée | **construit (13/09)**, lot N5 |
| `ENS-04` | Cahier de transmission | Enseignant | D | 2 | depuis la salle | Page, une main, 45 s | Panneau | **à construire**, étape 6 |
| `TUT-06` | Suivi du foyer | Tuteur | C | 1 | `/tuteur/suivi` | Liste par enfant | Liste + détail | **à construire** |
| — | Suivi élève | Élève standard | C | 1 | `/eleve/suivi` | Liste | Liste + détail | **à construire** |

### Zone Administration

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ADM-01` | Centre de commande | Admin | E | 0 | `/admin/tableau-de-bord` | Signaux puis chiffres | 4 chiffres + liste pleine largeur | **repris (R3)**, fiche §6 |
| `ADM-02` | Validation des dossiers | Admin | E | 1 | `/admin/dossiers` | Un dossier à la fois | File à gauche, dossier à droite | **repris (R4)**, fiche §6 |
| `ADM-06` | Demandes et règles | Admin | E | 1 | `/admin/demandes` | Liste de demandes | Liste + feuille de règles | **repris (R4)**, fiche §6 |
| `ADM-04` | Journal d'audit | Admin | E | 1 | `/admin/journal` | Cartes | Tableau dense | **construit (12/09)**, fiche §6 |
| `ENS-05` | Profil enseignant | Enseignant | D | 0 | `/enseignant/profil` | Page | Page + colonnes | **à construire** |
| `CPT-01` | Espace comptable | Comptable | E | 0 | `/comptable` | Cartes | Tableaux | **hors MVP-0** (ADR-003) |

**Codes nouveaux introduits par ce catalogue** : `ENS-05` et `CPT-01`, qui
existaient comme routes sans code, et les trois sous-écrans `TUT-00c/a`, `/b`,
`/c`, qui étaient décrits sans être nommés. Aucun code existant n'est renommé.

## 2. Ce que le registre révèle

> **Mise à jour du 13 septembre 2026, lot N5.** Le compte ci-dessous datait de
> la refonte. Depuis, `ADM-05` (hors série), `ADM-04`, **la salle**
> (`ELV-03`/`ENS-03`/`CTR-02`, un seul écran pour trois codes) puis **le
> lecteur de Coran** (`ELV-04`) ont été construits. Il reste **quatre** écrans à
> construire : le suivi élève, `TUT-06`, `ENS-05`, et `CPT-01` qui
> est hors MVP-0. L'espace admin n'a plus un seul écran manquant. Le compte se
> lit dans `lib/core/router/app_router.dart`, jamais en parcourant les écrans :
> un `EcranAConstruire` de ce fichier n'est pas un écran manquant mais l'état
> de chargement de la racine.
>
> ✅ **`CTR-01` est construit**, le même jour et par une autre session : sa
> route ne rend plus `EcranAConstruire`, et le compte est donc bien tombé à
> quatre. Fiche §6. **Aucun des quatre restants n'appartient à l'étape 5** : le
> suivi élève et `TUT-06` relèvent de la transmission, étape 6 avec `ENS-04` ;
> `ENS-05` est reporté avec l'ensemble du module finance (ADR-003) ; `CPT-01`
> est hors MVP-0. L'étape 5 n'a donc plus d'écran manquant.

Onze écrans sont encore `EcranAConstruire`, et quatre de ceux qui existent
étaient à reprendre par le lot R. Le lot R les a repris tous les quatre :
`ELV-02` (fait, R1), `TUT-01` (fait, R2), `ENS-02` et `ADM-01` (fait, R3).

Le lot **R0**, le 11 septembre 2026, a repris les six écrans de la zone Accès
qui montaient un `Scaffold` nu (cause n1 mesurée du rejet du 11 septembre,
`docs/HANDOFF.md` section 0 ter) : `TUT-00`, `ELV-01`, `TUT-00b`, `TUT-00c/a`,
`TUT-00c/b`, `TUT-00c/c`. `TUT-00c` n'a pas changé de code : il passait déjà
par `PageParcours`, seule sa fiche manquait.

Le lot **R4**, le même jour, a repris les six derniers écrans construits de la
refonte et leurs deux sous-écrans : `TUT-02`, `TUT-02/a`, `TUT-02/b`, `TUT-04`,
`TUT-05`, `ENS-06`, `ADM-02`, `ADM-06`. Le lot **R** est désormais complet.

Le point qui n'était pas à rater, corrigé au lot R4 : **`ENS-06` employait des
onglets sur desktop alors qu'il a la place d'afficher les deux panneaux**. Un
onglet sur un écran de 1440 pixels cachait la moitié de l'information sans
raison ; à partir de la tablette, la grille et le feed se voient désormais
tous les deux, sans onglet (fiche §6).

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
| **R1** | `ELV-02` | **fait le 7 septembre 2026.** C'est l'écran montré à l'opérateur, et le plus simple : deux blocs. Il sert de preuve du système |
| **R2** | `TUT-01` | **fait le 8 septembre 2026.** Il porte `ChildCard`, composant du domaine famille |
| **R3** | `ENS-02`, `ADM-01` | **fait le 8 septembre 2026.** `TimelineRow` porté par les trois sorties (cours, pause, prière), `StatTile` aux compteurs, `SignalRow` à la liste à traiter. `NavShell` câblé au routeur dans le même lot, voir `etape-2-journal.md` |
| **R4** | `TUT-02`, `TUT-04`, `TUT-05`, `ENS-06`, `ADM-02`, `ADM-06` | Le reste de l'existant. **fait le 11 septembre 2026** |
| **N** | les onze écrans manquants | Chacun avec sa fiche remplie d'abord |

## 6. Fiches des écrans repris

Une fiche par écran, remplie au lot R **à partir du code**, ce qui sert aussi de
relecture. Un champ vide serait une question à poser, pas une case à deviner.

### `ELV-02` Accueil élève

```
CODE              ELV-02
Nom               Accueil eleve
Role              Eleve, en mode enfant et en mode standard
Zone              Journee
Niveau de charge  B en mode enfant, C en mode standard
Ecran parent      aucun : racine du role
Profondeur        0
Question          Quand est mon prochain cours, et comment j'y entre ?

Priorites         P0  l'etat du prochain cours, dans ses six formes
                  P0  l'entree en seance, pendant un cours en direct
                  P1  les interruptions de priere du cours, annoncees avant lui
                  P1  l'acces au Coran, permanent

Action principale     Rejoindre : rendue seulement pendant un cours en direct,
                      inerte hors ligne, jamais absente
Actions secondaires   aucune
Action tertiaire      Ouvrir le Coran : le second bloc, toujours present
Destructif            aucun

Mobile            Deux blocs empiles
Tablette          Deux blocs, gouttiere elargie a 32
Desktop           Identique, colonne centree et bornee a 1200. On n'ajoute
                  rien : le niveau B ne gagne pas de densite avec la largeur

Etats (bloc principal)
  cours plus tard   carte surfaceRaised : haut-parleur, compte a rebours en
                    displayMedium, prenom de l'enseignant
  cours imminent    carte surfacePrimary pleine, pulsation 1200 ms. Seule zone
                    pleine de l'ecran, seule pulsation du produit. Sous
                    mouvement reduit : bordure borderStrong fixe, sans pulsation
                    (04-systeme-mouvement.md section 5)
  cours en direct   carte surfaceRaised, pastille StatusPill verte, haut-parleur,
                    prenom, bouton Rejoindre en surfacePrimary
  aucun cours du jour   EmptyState registre subi, prochain cours exprime en
                        jours et jamais en date
  seance annulee    EmptyState registre subi, aucune explication technique,
                    aucun statut, aucun motif
  offline           identique au cours en direct : le bouton Rejoindre devient
                    inerte et gagne un pictogramme de reseau. Le bandeau
                    OfflineBanner de PageShell coiffe la page
  loading / error   pas d'etat dedie : la lecture des seances qui echoue ou qui
                    tarde retombe sur l'etat "aucun cours". Dette assumee,
                    reportee : concevoir un squelette et un message d'erreur a
                    hauteur d'enfant depasse la reprise

Mouvement         pulsation du bloc imminent : 1200 ms, hors budget de
                  transition ; remplacee par une bordure fixe sous mouvement
                  reduit

Invariants        deux blocs, rien d'autre, quel que soit l'etat
                  une seule zone pleine : le bloc imminent
                  les interruptions de priere sont annoncees avant le cours,
                  jamais decouvertes pendant (ADR-017), et sans condition d'etat
                  en mode enfant, chaque decision porte un libelle parle
                  (AudioLabel) ; l'heure et le nom de la priere ne s'y lisent pas
                  le prochain cours se dit en jours pour l'enfant, jamais en date
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44 en standard, 72 en mode enfant
                  libelles parles sur le prochain cours, le cours en direct et
                  la pause priere
                  les deux blocs se lisent de droite a gauche en arabe
                  a 200 % de taille de texte, les blocs grandissent, aucun texte
                  rogne
```

Reprise faite le 7 septembre 2026, sous-lot R1. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold` avec sa gouttière et son `OfflineBanner`.
  Il passe par `PageShell`, qui borne aussi la colonne à 1200 et la centre sur
  desktop, ce que le catalogue demandait pour le desktop du niveau B ;
- le cours en direct et le hors ligne étaient des aplats `surfacePrimary`
  pleins : trois zones pleines possibles sur un même écran. Seul l'imminent le
  reste ; les deux autres redeviennent des cartes, avec pastille verte et bouton
  d'entrée en `surfacePrimary` ;
- la pastille « en direct » était un `Container` décoré posé dans l'écran. Elle
  passe par `StatusPill`, comme sur `TUT-01` ;
- les états vides prenaient le registre « actionnable » par défaut, avec son
  icône d'accent. Ils passent au registre « subi » : l'enfant ne peut rien y
  faire, son enseignant prépare le prochain cours ;
- sous mouvement réduit, la pulsation était simplement arrêtée. Elle est
  désormais **remplacée** par une bordure `borderStrong` fixe, portée par une
  nouvelle prise `contourFort` de `BentoTile`, jumelle de celle d'`AppCard`.

### `TUT-01` Accueil famille

```
CODE              TUT-01
Nom               Accueil famille
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      aucun : racine du role
Profondeur        0
Question          Comment va chacun de mes enfants aujourd'hui, et qu'ai-je a
                  confirmer ?

Priorites         P0  l'etat en direct de chaque enfant, une carte par enfant
                  P0  l'entree en observateur muet pendant une seance en cours
                  P1  la date de fin d'acces de chaque enfant, qui tient lieu de
                      portefeuille en MVP-0
                  P1  l'acces aux appareils et aux reglages par enfant

Action principale     Assister : rendue seulement pendant une seance en cours de
                      l'enfant. Entre en observateur muet, et l'enseignant le
                      voit arriver
Actions secondaires   Proposer des heures : sur la seule carte "aucune heure
                      proposee"
Action tertiaire      aucune
Destructif            aucun

Mobile            Liste de ChildCard, puis section "Gerer le foyer"
Tablette          Identique, gouttiere du gabarit
Desktop           Identique, colonne centree et bornee a 1200. La mise en deux ou
                  trois colonnes et la colonne "a confirmer" du paragraphe 1 ne
                  sont pas implementees : reporte, comme le desktop multi-colonnes
                  d'ELV-02. Le lot R porte le langage des lots T et C, pas les
                  presentations de 05-regles-responsive.md

Etats (carte d'un enfant, cinq phases decidees par phaseEnfant, fonction pure)
  en cours              ChildCard posee surfaceRaised, pastille StatusPill verte
                        "En direct", prenom de l'enseignant, minuteur ecoule,
                        bouton "Assister" en surfacePrimary. Jamais un aplat
                        plein : deux enfants en cours ne font pas deux zones
                        pleines (01-systeme-visuel.md section 3)
  cours a venir         ChildCard posee, "Aujourd'hui a {heure}, avec {prenom}",
  aujourd'hui           aucune action
  rien aujourd'hui      ChildCard posee, le prochain rendez-vous date ("{jour} a
                        {heure}, avec {prenom}"), ou, quand la semaine n'est pas
                        encore posee, "Aucun cours programme pour l'instant". Le
                        preambule "Rien aujourd'hui" de l'ecran d'avant est
                        retire : la carte dit directement le prochain rendez-vous,
                        ce que le catalogue nomme "Rien aujourd'hui : prochain
                        cours date"
  en recherche          ChildCard posee, encre inkMuted, pastille neutre "En
                        recherche d'un enseignant", "Demande deposee le {date}"
                        ou, sans date datable, "Un enseignant prendra {prenom} en
                        charge parmi les heures proposees"
  aucune heure          ChildCard washWarning + contour borderStrong, "Aucune
  proposee              heure proposee pour {prenom}", bouton "Proposer des
                        heures". La phrase de consequence de l'ecran d'avant
                        ("Sans creneau, aucun enseignant ne peut...") n'est plus
                        rendue : l'etat scelle EnfantSansPlanning ne porte que
                        ce que 07-catalogue-composants.md section 3 lui fixe
  seance annulee        ChildCard washAlert, pastille alerte "Annule", motif en
                        une phrase ("Le cours de {heure} n'aura pas lieu", ou
                        "Seance annulee peu avant l'heure" pour une annulation
                        tardive), et ce qui est propose. Le libelle de statut
                        "Seance annulee" de l'ecran d'avant est porte par la
                        pastille, plus par une ligne
  loading / error       pas d'etat dedie : une lecture en echec des enfants, des
                        seances ou des affectations affiche une phrase d'alerte
                        sous les cartes ; une lecture qui tarde retombe sur
                        l'etat nominal, y compris le transitoire "en recherche ->
                        aucune heure" pendant que les creneaux se chargent. Meme
                        dette assumee qu'ELV-02
  hors ligne            le bandeau OfflineBanner de PageShell coiffe la page.
                        L'etat hors ligne par carte de ChildCard n'est pas cable :
                        distinguer donnee volatile et donnee stable par enfant
                        depasse la reprise

Mouvement         aucun propre a l'ecran. La carte imminente de ChildCard ne
                  pulse pas : une seule zone pulse par produit, c'est ELV-02

Invariants        une carte par enfant, aucune statistique decorative : le tuteur
                  n'a pas le tableau de bord d'un gestionnaire (03 section 6)
                  "Assister" entre en observateur muet, et l'enseignant le voit
                  arriver
                  "Assister" n'est rendu que pendant une seance en cours
                  une seule zone pleine par ecran : aucune carte n'est un aplat
                  surfacePrimary, seul le bouton "Assister" l'est
                  le motif d'une annulation est une phrase humaine, jamais la
                  valeur SQL du statut
                  rien ne se ferme sur minuterie
                  la carte n'est pas cliquable : TUT-01 n'a pas d'ecran de detail
                  par enfant, et 07 section 4 interdit une affordance qui ne mene
                  nulle part. Le chevron de la ligne "Normal" du catalogue 07
                  section 3 est une prise du composant, honoree le jour ou un
                  ecran de suivi par enfant existera

Accessibilite     cibles a 44 en mode standard
                  chaque ChildCard porte un libelle parle : prenom, etat, detail
                  les cartes se lisent de droite a gauche en arabe
                  a 200 % de taille de texte, les cartes grandissent, aucun texte
                  rogne
```

Reprise faite le 8 septembre 2026, sous-lot R2. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold` avec `OfflineBanner`, `RefreshIndicator`
  et `ListView`. Il passe par `PageShell` : fond crème, gouttière du gabarit,
  colonne centrée et bornée à 1200, titre d'écran, bandeau hors ligne ;
- ses lignes d'enfant étaient un `BentoTile` portant un `switch` d'états dans
  l'écran. Elles passent par `ChildCard` : l'écran ne décide plus que **quelle**
  phase, par la fonction pure `phaseEnfant` (renommage de l'ancien `etatEnfant`,
  pour éviter la collision avec le `EtatEnfant` scellé de `ChildCard`), et un
  mapper traduit la phase en état visuel avec les phrases mises en forme ;
- la pastille « en direct » était un `Container` décoré posé dans l'écran. Elle
  passe par `StatusPill`, portée par la carte. Conséquence de fond, la même qu'à
  `ELV-02` : le cours en direct n'est plus un aplat `surfacePrimary` plein mais
  une carte posée, seul son bouton porte l'aplat ;
- une `SectionHeader` « Gérer le foyer » sépare les cartes des blocs secondaires
  (appareils, réglages, accès), qui restent des `BentoTile` comme le bloc Coran
  d'`ELV-02`. Nouvelle clé `t.tuteur.accueil.gererLeFoyer` ;
- deux règles ajoutées à `verifier_jetons.dart` avec la reprise, comme le lot C
  l'avait prévu : aucun `Container` décoré dans `lib/features/`, aucun
  `showDialog` hors de `ConfirmDestructive`. Zéro occurrence de l'un et de
  l'autre après la reprise.

Dettes assumées et écarts reportés, sur le modèle de la dette loading/error
d'`ELV-02` :

- **le tirage-pour-rafraîchir disparaît.** L'ancien écran portait un
  `RefreshIndicator` qui invalidait les trois providers ; `PageShell` ne porte
  volontairement pas d'état de données, et l'envelopper dans un `RefreshIndicator`
  réintroduirait la tuyauterie par écran que le lot R retire. `seancesProvider`
  et `affectationsProvider` ne sont alors relus qu'au démarrage de l'application,
  ou après édition des disponibilités, chemin hors du parcours tuteur. Un
  rétablissement propre est une **prise `onRafraichir` optionnelle de
  `PageShell`** : évolution de composant à trancher explicitement, puisqu'elle
  touche la frontière « ni les états de données » de son en-tête, et utile aussi
  à `ELV-02` et aux écrans R3/R4 ;
- desktop multi-colonnes et colonne « à confirmer » du §1 : non implémentés,
  reportés, comme pour `ELV-02` ;
- **`NavShell` n'est toujours pas câblé au routeur**, comme R1 l'avait laissé.
  Après R2, la racine du rôle tuteur est refondue mais n'offre toujours aucune
  navigation de premier niveau vers Disponibilités, Réglages ou Suivi. Le câblage
  demande un `StatefulShellRoute` couvrant tous les rôles à barre : c'est son
  propre sous-lot, à traiter avec `ENS-02` / `ADM-01` (R3) ou après.

### `ENS-02` Journée

```
CODE              ENS-02
Nom               Journee
Role              Enseignant
Zone              Journee
Niveau de charge  D
Ecran parent      aucun : racine du role
Profondeur        0
Question          Quel est mon prochain cours, et qui attend un enseignant ?

Priorites         P0  l'etat du cours : en cours ou prochain, en une carte
                      dominante
                  P0  la colonne de la journee, cours, pauses et prieres
                      comme entrees de meme nature
                  P1  le feed des eleves en attente, porte vers la grille
                      des creneaux (ENS-06)

Action principale     aucune : le lancement d'une seance est l'etape 5, et une
                      phrase prend sa place. Meme la porte vers la grille est
                      un bloc secondaire, pas une action
Actions secondaires   Ouvrir la grille des creneaux, par le bloc matching
Action tertiaire      aucune
Destructif            aucun

Mobile            carte dominante, colonne, puis bloc matching
Tablette          identique, gouttiere du gabarit
Desktop           la colonne et un panneau de detail cote a cote (registre) ne
                  sont pas implementes : reporte, comme les multi-colonnes
                  d'ELV-02. Le lot R porte le langage, pas les presentations
                  de 05-regles-responsive.md

Etats
  en cours          carte posee surfaceRaised, pastille StatusPill verte
                    "En direct", prenom, identifiant immuable, "jusqu'a
                    {heure}". Jamais un aplat sature : une seule zone pleine
                    par ecran, et l'etat se dit par la pastille, pas par la
                    couleur de fond
  a venir           carte posee, "Prochain cours", minuteur en heures et
                    minutes, sans date
  autre jour        carte posee, "{jour} a {heure}" : le jour long nomme
                    l'instant, une date seule n'y ajoute rien
  aucun cours       EmptyState registre subi : l'enseignant ne quitte pas
                    l'ecran pour agir, le bloc matching en dessous le fait
  journee finie     une phrase sous la colonne, singulier ou pluriel
  loading / error   pas d'etat dedic : une lecture qui tarde retombe sur la
                    colonne vide, une lecture en echec dit une phrase d'erreur
                    sous la carte dominante. Meme dette qu'ELV-02
  hors ligne        le bandeau OfflineBanner de PageShell coiffe la page

Mouvement         aucun propre a l'ecran

Invariants        pauses et prieres sont des entrees de la meme colonne,
                  jamais un bloc separe : l'interruption se lit a sa place
                  dans le deroule
                  une seule colonne, une entree par evenement, aucune
                  statistique decorative
                  la colonne est portee par TimelineRow, qui decide lui-meme
                  du libelle et de l'icone de chaque sorte
                  les heures affichees sont celles de l'appareil, sans
                  mention de fuseau : les seances sont des instants absolus,
                  et mon_fuseau dit ou l'enseignant pose ses creneaux
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44
                  chaque ligne de la colonne porte son libelle parle
                  la colonne se lit de droite a gauche en arabe
                  a 200 % de taille de texte, aucun texte rogne
```

Reprise faite le 8 septembre 2026, sous-lot R3. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, un `OfflineBanner`, un tirage-pour-
  rafraîchir et un `ListView` avec sa gouttière. Il passe par `PageShell` :
  fond crème, titre d'écran, gouttière du gabarit, colonne bornée et centrée,
  bandeau hors ligne ;
- le bloc dominant était un aplat `surfacePrimary` plein quand un cours était
  en cours : une zone pleine de plus sur un écran qui n'a aucune action à
  promouvoir. Il devient une carte posée, et l'état « en cours » se dit par
  une pastille `StatusPill` verte, la même que sur `ELV-02` et `TUT-01` ;
- les lignes de la colonne étaient un `BentoTile` local `_LigneJournee`. Elles
  passent par `TimelineRow` (nouveau composant, `07` §2) : un seul gabarit pour
  les trois sorties, l'icône `AppIcon.cours` ou `AppIcon.pause`, le libellé et
  la durée décidés par le composant lui-même, pour que la colonne reste une
  seule liste homogène ;
- l'état vide « aucun cours » prenait le registre actionnable par défaut. Il
  passe au registre « subi », comme sur `ELV-02` : l'enseignant ne peut rien y
  faire ici, le bloc matching est en dessous.

Dettes assumées et écarts reportés :

- **le tirage-pour-rafraîchir disparaît**, comme sur `TUT-01` et `ADM-01`
  (même format de dette, voir la fiche `TUT-01`). `seancesProvider`,
  `reglagesPriereProvider` et `valeurRegleProvider` ne sont alors relus qu'au
  démarrage de l'application ; la sortie de la grille des créneaux (ENS-06)
  reste un chemin de relecture honnête. Rétablissement propre = prise
  **`onRafraichir` optionnelle de `PageShell`**, à trancher explicitement ;
- le panneau de détail desktop du registre : non implémenté, reporté.

### `ADM-01` Centre de commande

```
CODE              ADM-01
Nom               Centre de commande
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      aucun : racine du role
Profondeur        0
Question          Qu'est-ce qui attend une decision ce matin ?

Priorites         P0  les six compteurs, zeros compris (invariant I9)
                  P0  ce qui se traite d'un tap : dossiers et demandes,
                      ordonnes par anciennete
                  P1  la portee de la liste, dite en une phrase

Action principale     aucune : chaque signal EST son propre bouton, il n'y a
                      pas d'action qui prime sur les autres
Actions secondaires   Ouvrir la validation des dossiers (ADM-02), ouvrir les
                      demandes et regles (ADM-06) : depuis le compteur comme
                      depuis la ligne
Action tertiaire      aucune
Destructif            aucun

Mobile            six compteurs en deux colonnes, puis la liste a traiter
Tablette          identique, gouttiere du gabarit
Desktop           la liste pleine largeur (registre) : les compteurs restent
                  deux par deux, denses et recurrents. Reporte avec le desktop
                  multi-colonnes

Etats
  compteurs         toujours six, zeros compris (I9) : rendus des que la
                    lecture aboutit
  compteurs         une phrase d'alerte, jamais six zeros inventes : l'admin
  en echec          verrait une ruche vide et croirait tout traite
  liste a traiter   une SignalRow par cas, triee par anciennete de depose,
                    jamais par nature : un dossier depose hier passe devant
                    une demande de ce matin
  rien a traiter    EmptyState "tout est traite", sans bouton : il n'y a rien
                    a ouvrir
  liste en echec    une phrase sous la liste, et les compteurs restent :
                    dossiers et demandes passent par deux fonctions
                    differentes, l'echec de l'une n'emporte pas l'autre
  loading           "chargement" sous le titre, avant les compteurs

Mouvement         aucun propre a l'ecran

Invariants        le zero s'affiche comme les autres valeurs, jamais masque
                  le tri est par anciennete d'attente, jamais alphabetique
                  deux compteurs menent a leur ecran (dossiers, demandes) ;
                  les quatre autres sont des rapports sans onPress, jusqu'a
                  ce qu'ADM-05 et le journal existent
                  un signal mene directement a son ecran d'action, jamais a
                  un menu (02-regles-ux.md section 2)
                  l'anciennete se lit en jours, tous les jours lus sur le
                  meme instant, jamais recolores dans une meme liste
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44
                  chaque tuile et chaque ligne porte un libelle parle, chiffre
                  et libelle ensemble
                  chiffres tabulaires : passer de 17 a 18 ne fait pas bouger
                  la ligne
                  la page se lit de droite a gauche en arabe
```

Reprise faite le 8 septembre 2026, sous-lot R3. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, un `OfflineBanner`, un tirage-pour-
  rafraîchir (`RefreshIndicator` invalidant trois providers) et son `ListView`.
  Il passe par `PageShell`, comme `ELV-02`, `TUT-01` et `ENS-02` ;
- les compteurs étaient un `BentoTile` local `_Compteur` qui teintait la tuile
  en discret quand la valeur passait au-dessus de zéro — une couleur portée
  par la seule valeur, que le catalogue de composants interdit (« le ton ne se
  lit pas sur la valeur », `stat_tile.dart`). Ils passent par `StatTile` :
  chiffres tabulaires, libellé parlé, et le ton neutre partout. Deux d'entre
  eux tiennent des compteurs actionnables (dossiers → `ADM-02`, demandes →
  `ADM-06`) ; les quatre autres sont des rapports sans `onPress`, jusqu'à ce
  que `ADM-05` et le journal existent ;
- les lignes à traiter étaient un `BentoTile` local `_Ligne`. Elles passent
  par `SignalRow` : icône, phrase, ancienneté, chevron, et un libellé parlé
  qui lie la phrase à l'ancienneté.

Deux écarts du registre à trancher, révélés par la relecture de la fiche, et
retenus **sans rien déplacer** dans le code, qui suit `parcours-utilisateurs.md`
(cadre du haut dans `docs/design/README.md` §3) :

- **six compteurs**, là où `parcours-utilisateurs.md` §5 et le README §7 en
  écrivent cinq : `demandes`, `ADM-06`, figure dans le code mais pas dans la
  liste produit. Choisir si le sixième reste, ou si le coup de pouce vers les
  demandes est porté par la liste à traiter seule ;
- **l'ordre** : le registre dit « Signaux puis chiffres » et `02-regles-ux.md`
  §2 place « ce que je dois traiter » en premier ; `parcours-utilisateurs.md`
  dit « Cinq indicateurs en haut, sous les chiffres une liste ». Le code rend
  les compteurs d'abord. Si la règle « les signaux d'abord » l'emporte, les
  compteurs passent sous la liste, et c'est une fiche refaite.

Dettes assumées :

- **le tirage-pour-rafraîchir disparaît**, même format et même sort que sur
  `TUT-01` et `ENS-02` : les trois providers d'`ADM-01` ne sont relus qu'au
  démarrage. Rétablissement propre = prise `onRafraichir` optionnelle de
  `PageShell`, à trancher explicitement. C'est le troisième écran qui la
  demande, le lot R en fait une dette commune ;
- **desktop pleine largeur de la liste** : non implémenté, la liste garde la
  gouttière du gabarit. Reporté, comme les autres multi-colonnes du lot R.

### `TUT-00` Connexion

```
CODE              TUT-00
Nom               Connexion
Role              Tous
Zone              Acces
Niveau de charge  A
Ecran parent      aucun : racine, seul ecran atteignable sans session
Profondeur        0
Question          Comment entrer, sans mot de passe a creer ni a retenir ?

Priorites         P0  envoyer un lien de connexion par courriel
                  P0  se connecter avec Google
                  P1  rejoindre l'entree eleve (ELV-01), un parcours different,
                      jamais une variante de celui-ci

Action principale     Envoyer le lien : inerte tant que l'adresse saisie n'est
                      pas plausible, jamais grisee sans raison dite
Actions secondaires   Se connecter avec Google ; entrer un code eleve
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             saisie      carte avec le champ courriel, bouton inerte tant
                              que l'adresse n'est pas plausible
                  envoi       bouton en cours
                  lien envoye la carte est remplacee par la confirmation et un
                              bouton "changer d'adresse". Ne se ferme jamais
                              tout seul et ne compte pas a rebours
                  erreur      message sous le champ, avant l'envoi si le format
                              est invalide, apres l'envoi si le service refuse

Mouvement         aucun propre a l'ecran

Invariants        aucun mot de passe nulle part dans ce parcours
                  l'etat "lien envoye" ne se ferme jamais sur minuterie
                  seul ecran du produit atteignable sans session

Accessibilite     champ courriel avec l'autofill hint email, action clavier
                  "go" pour envoyer sans quitter le clavier
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, sans carte, sans ombre, sans marque :
  la cause n1 mesurée du rejet du 11 septembre (`docs/HANDOFF.md` section
  0 ter), parce que c'est le seul écran visible sans compte. Il passe par
  `PageShell` ;
- le formulaire flottait à même le fond crème. Il est posé sur `AppCard`
  (`surfaceRaised`, filet et ombre) ;
- une zone de marque (`MarquePage`, nouveau composant partagé) précède la
  carte : le nom du produit seul, en `inkAccent`, faute d'un asset de logo
  dans le dépôt.

### `ELV-01` Connexion élève

```
CODE              ELV-01
Nom               Connexion eleve
Role              Eleve
Zone              Acces
Niveau de charge  B
Ecran parent      aucun : racine, parcours distinct de TUT-00 (ADR-005)
Profondeur        0
Question          Qui est-ce, et avec quel code personnel ?

Priorites         P0  sur un appareil deja appaire, retrouver son profil sans
                      ressaisir le code d'appairage
                  P0  creer ou saisir son code personnel, qui ne quitte jamais
                      l'appareil (ADR-005)
                  P1  premier appairage : saisir le code recu du tuteur

Action principale     Valider (appairage), ou le pave numerique lui-meme
                      (creation et saisie du code personnel)
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, le contenu change selon le moment
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats (moments successifs, jamais deux a la fois)
  chargement        texte de chargement, le temps de lire les profils connus
                    de l'appareil
  saisie du code    aucun profil connu : champ code (6 caracteres, majuscules),
                    bouton Valider inerte avant 6 caracteres
  choix du profil   des profils existent : une tuile par profil, composition
                    volontairement asymetrique
  creation du code  premier usage du profil sur cet appareil : le pave
                    numerique demande le code deux fois, un ecart efface la
                    premiere saisie et le dit
  saisie du code    le profil a deja un code : le pave numerique le demande.
  personnel         Une erreur du pave le dit sans relancer de saisie ailleurs
  code expire       le jeton d'appareil a ete revoque par le tuteur : le
                    profil disparait de la liste et un message le dit

Mouvement         aucun propre a l'ecran

Invariants        le code personnel ne quitte jamais l'appareil : aucun
                  service ne declare de parametre pour le recevoir (ADR-005)
                  sur un appareil deja appaire, l'ecran de saisie du code
                  d'appairage ne reapparait jamais
                  la comparaison du code personnel est locale, aucun appel
                  reseau ne recoit la saisie

Accessibilite     cibles larges sur les tuiles de profil (AvatarTile)
                  le pave numerique dit l'erreur sans redemander une saisie
                  de plus
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, cause n1 avec `TUT-00`. Il passe par
  `PageShell` ;
- chaque moment (saisie du code, choix du profil, pave numerique) flottait
  directement sur le fond crème. Le contenu du moment courant est posé sur une
  seule `AppCard`, comme sur `TUT-00` ;
- la même `MarquePage` que `TUT-00` précède la carte : les deux écrans du
  tunnel d'entrée partagent la même identité visuelle.

### `TUT-00c` Création de profil

```
CODE              TUT-00c
Nom               Creation de profil
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00 (atteint apres une premiere connexion sans profil)
Profondeur        1
Question          Qui es-tu, et quel role joues-tu dans le foyer ou l'ecole ?

Priorites         P0  le role (tuteur, eleve adulte qui est son propre tuteur,
                      ou enseignant) : ADR-009
                  P0  l'identite (prenom, nom)
                  P1  le genre, qui decide en base qui pourra lire une piece
                      d'identite plus tard (audit 1.3)
                  P1  un recapitulatif avant l'envoi

Action principale     Continuer (pages 1 a 3), Creer mon profil (page 4)
Actions secondaires   Retour (pages 2 a 4)
Action tertiaire      aucune
Destructif            aucun

Mobile            Parcours en quatre pages courtes, une question par page
                  (ADR-013), coquille PageParcours (retour, progression,
                  temps restant estime)
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             page 1 (role)      trois cartes cliquables + "Autre", qui
                                     renvoie vers l'academie sans inventer de
                                     role (ChoiceCardGroup)
                  page 2 (identite)  deux champs, Continuer inerte tant que
                                     les deux ne sont pas remplis
                  page 3 (genre)     deux cartes + "Autre", meme registre que
                                     la page 1
                  page 4 (recap)     trois lignes libelle/valeur, erreur
                                     d'envoi dite sous le bouton
                  envoi              bouton en cours

Mouvement         la barre de progression segmentee de PageParcours, pas de
                  mouvement propre a l'ecran

Invariants        le role declare ici n'accorde rien : la base ecrit
                  pending_kyc en dur, quoi que le client envoie
                  l'eleve adulte n'est pas un role de plus, c'est son propre
                  tuteur, un foyer d'une personne (ADR-009)
                  la carte "Autre" ne devine jamais un role ou un genre, elle
                  dit que le parcours ne convient pas

Accessibilite     une question par page : jamais un formulaire qui empile les
                  champs (ADR-013)
                  temps restant estime a chaque page, pour que l'incertitude
                  ne coute pas plus cher que la longueur
```

Aucune reprise : cet écran passait déjà par `PageParcours` avant le lot R0.
Seule sa fiche manquait, écrite ici à partir du code existant, comme le
demande la section 3.

### `TUT-00b` Portail d'attente

```
CODE              TUT-00b
Nom               Portail d'attente
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00 (session valide, profil cree, dossier incomplet)
Profondeur        0
Question          Qu'est-ce qui manque encore avant d'entrer dans l'app ?

Priorites         P0  dire exactement ce que l'administration voit, jamais un
                      calcul divergent recalcule a l'ecran (etat_dossier() en
                      base)
                  P0  l'action pour chaque piece manquante, une a une
                  P1  se deconnecter

Action principale     Selon la piece manquante : lire la carte d'accuse
                      (TUT-00c/a), signer le contrat (TUT-00c/b), deposer la
                      piece (TUT-00c/c)
Actions secondaires   Se deconnecter
Action tertiaire      Reessayer, seulement quand la lecture du dossier echoue
Destructif            aucun

Mobile            Page centree, une carte
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats (etat.etape, calcule en base par etat_dossier())
  incomplet         une BentoTile par piece manquante (accuse, contrat, piece
                    d'identite), chacune avec son bouton
  en verification   icone, "en cours d'examen", date de depot si connue, delai
                    indicatif
  refuse            le motif de refus en clair (la base ne renvoie jamais un
                    refus sans motif), bouton pour corriger
  suspendu          icone d'alerte, detail, "contacter l'academie"
  loading           texte de chargement
  error (lecture)   phrase d'erreur, bouton Reessayer : un etat de dossier
                    illisible ne se devine pas

Mouvement         aucun propre a l'ecran

Invariants        ne montre jamais l'application derriere un voile : dit ce
                  qui manque et rien d'autre
                  le calcul de l'etape vient de la base, jamais recalcule ici
                  une lecture qui echoue dit une phrase et laisse reessayer,
                  elle ne ferme jamais la deconnexion

Accessibilite     le message d'erreur de lecture est en liveRegion
                  la carte se lit de droite a gauche en arabe
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` et son propre tirage-pour-rafraîchir
  (`RefreshIndicator` invalidant `etatDossierProvider`). Il passe par
  `PageShell` ;
- le contenu (les quatre états `_Contenu`, `_Indisponible`, `_Patience`)
  flottait sur le fond crème. Il est posé sur une seule `AppCard` ;
- la même `MarquePage` que `TUT-00` et `ELV-01` précède la carte.

Dette assumée : **le tirage-pour-rafraîchir disparaît**, même sort que sur
`TUT-01`, `ENS-02` et `ADM-01` (voir leurs fiches) — `RefreshIndicator` posé
autour d'un `ListView` a besoin d'être l'enfant direct d'un `Expanded` pour ne
pas planter (hauteur non bornée), et `PageShell` en mode `defilante: false` ne
donne pas cette garantie à son `child`. C'est le quatrième écran qui la
demande. Le bouton « réessayer » de l'état d'erreur reste le seul moyen de
relire le dossier avant le prochain démarrage de l'application.

### `TUT-00c/a` Accusé enregistrement et contrôle

```
CODE              TUT-00c/a
Nom               Accuse enregistrement et controle
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00b (une des pieces manquantes du dossier)
Profondeur        1
Question          Que faut-il savoir du dispositif d'enregistrement et de
                  controle, avant de l'accepter ?

Priorites         P0  les deux points en clair : enregistrement audio, visite
                      de controle possible (ADR-011)
                  P1  revenir au portail sans accepter

Action principale     "Compris" : accepte l'accuse et retourne au portail
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, action collee en bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             nominal    titre, deux points illustres (BentoTile + icone),
                              bouton dans la zone d'action
                  envoi      bouton en cours
                  erreur     message sous le titre, dans la zone d'action

Mouvement         aucun propre a l'ecran

Invariants        vient avant le contrat, jamais apres : un dispositif decouvert
                  apres coup est un litige (ADR-011)
                  courte pour etre lue : deux points, pas un texte long

Accessibilite     le message d'erreur est en liveRegion
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé (partagé avec `TUT-00c/b`, meme coquille
`_PageASigner` dans `signature_page.dart`) :

- l'écran montait son propre `Scaffold`, avec une zone d'action reimplementee
  a la main (`Padding` + `Column` + message d'erreur). Il passe par
  `PageShell`, dont c'est exactement le role (`actions:`) ;
- les points en clair flottaient dans un `ListView` a meme le fond crème. Ils
  sont poses sur une `AppCard` ;
- une `MarquePage` précède la carte.

### `TUT-00c/b` Contrat

```
CODE              TUT-00c/b
Nom               Contrat
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00b (une des pieces manquantes du dossier)
Profondeur        1
Question          Quelles sont mes conditions, et les accepter ?

Priorites         P0  les points du contrat propre au role : enregistrement et
                      controle pour tous, occultation des coordonnees en plus
                      pour l'enseignant (ADR-008)
                  P1  revenir au portail sans accepter

Action principale     "Accepter" : accepte le contrat et retourne au portail
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, action collee en bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             nominal    titre, introduction, une BentoTile par point,
                              bouton dans la zone d'action
                  envoi      bouton en cours
                  erreur     message sous le titre, dans la zone d'action

Mouvement         aucun propre a l'ecran

Invariants        le contenu depend du role (SorteContrat.pour(role)) : le
                  point sur l'occultation des coordonnees n'existe que pour
                  l'enseignant, c'est le controle anti-pillage de l'ADR-008
                  meme coquille que TUT-00c/a : deux ecrans du meme type de
                  page, pas deux implementations

Accessibilite     le message d'erreur est en liveRegion
```

Reprise faite le 11 septembre 2026, sous-lot R0, même changement que
`TUT-00c/a` : `Scaffold` et zone d'action manuelle remplacés par `PageShell` et
sa prise `actions:`, contenu posé sur `AppCard`, `MarquePage` en tête.

### `TUT-00c/c` Dépôt de la pièce

```
CODE              TUT-00c/c
Nom               Depot de la piece d'identite
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00b (une des pieces manquantes du dossier)
Profondeur        1
Question          Quelle piece, et laquelle envoyer ?

Priorites         P0  le type de piece (carte d'identite, passeport, titre de
                      sejour)
                  P0  choisir un fichier, borne a la taille maximale acceptee
                  P1  revenir au portail sans envoyer

Action principale     Envoyer : inerte tant qu'aucun fichier n'est choisi
Actions secondaires   Choisir un fichier : inerte tant qu'aucun type n'est
                      choisi
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, action collee en bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             nominal          titre, intro, ChoiceCardGroup des trois
                                    types, bouton secondaire "choisir un
                                    fichier"
                  fichier trop lourd  message sous le titre, avant meme la
                                    tentative d'envoi
                  fichier choisi   le bouton secondaire dit "Fichier choisi",
                                    le bouton Envoyer devient actif
                  envoi            bouton en cours, dans la zone d'action
                  erreur d'envoi   message dans la zone d'action

Mouvement         aucun propre a l'ecran

Invariants        le genre transmis avec la piece vient du profil, jamais
                  d'une saisie de plus : il decide quel membre du personnel
                  pourra la regarder (audit 1.3)
                  la borne de taille est verifiee avant l'envoi, jamais apres
                  plusieurs minutes de televersement

Accessibilite     les deux messages d'erreur (taille, envoi) sont en
                  liveRegion
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, avec une zone d'action reimplementee
  a la main. Il passe par `PageShell` et sa prise `actions:`, comme
  `TUT-00c/a` et `TUT-00c/b` ;
- le contenu (question du type, `ChoiceCardGroup`, bouton "choisir un
  fichier") flottait dans un `ListView` a meme le fond crème. Il est pose sur
  une `AppCard` ;
- une `MarquePage` précède la carte.

### `TUT-02` Foyer et appareils

```
CODE              TUT-02
Nom               Foyer et appareils
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      TUT-01 (lien direct depuis l'accueil famille)
Profondeur        1
Question          Qui vit dans ce foyer, et quels appareils leur sont appaires ?

Priorites         P0  un bloc par enfant : ses appareils actifs
                  P0  revoquer un appareil
                  P1  ajouter un enfant
                  P1  ajouter un appareil, tant que la limite (ADR-010, deux
                      par enfant) n'est pas atteinte

Action principale     Ajouter un enfant (bas de liste) ; par enfant, Ajouter
                      un appareil
Actions secondaires   Revoquer un appareil (par ligne)
Action tertiaire      aucune
Destructif            aucun -- revoquer coupe l'acces de l'appareil, ca ne
                      supprime rien ; niveau secondaire, pas destructif

Mobile            Liste dense, un bloc par enfant
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "deux colonnes" au bureau ; non
                  implemente, ecart anterieur a ce lot, hors scope d'une
                  reprise de coquille

Etats             content         nominal
                  empty           aucun enfant dans le foyer (EmptyState,
                                  bouton "Ajouter un enfant")
                  limite atteinte le bouton "Ajouter un appareil" est
                                  remplace par une phrase, jamais desactive
                                  (invariant deja acquis, section 4)
                  aucun appareil  phrase seule, pas de liste vide dessinee

Mouvement         aucun propre a l'ecran

Invariants        a la limite de deux appareils, le bouton d'ajout est
                  remplace par une phrase (deja acquis, section 4)
                  la photo reelle ou le repli sur initiales, jamais une icone
                  d'erreur (ADR-012)

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, un `OfflineBanner` posé à la main et
  un tirage-pour-rafraîchir (`RefreshIndicator` invalidant les deux providers
  du foyer) autour de son `ListView`. Il passe par `PageShell` ;
- **Dette assumée** : le tirage-pour-rafraîchir disparaît, même sort et même
  raison que sur `TUT-00b`, `TUT-01`, `ENS-02` et `ADM-01` (voir leurs
  fiches) — un `RefreshIndicator` autour d'un `ListView` a besoin d'être
  l'enfant direct d'un `Expanded` pour ne pas planter en hauteur non bornée,
  et `PageShell` ne donne pas cette garantie à son `child`. C'est le
  cinquième écran qui la demande.

### `TUT-02/a` Ajout d'un enfant

```
CODE              TUT-02/a
Nom               Ajout d'un enfant
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      TUT-02 (bouton "Ajouter un enfant"), aussi atteint depuis
                  TUT-05 quand le foyer est vide
Profondeur        2
Question          Qui est cet enfant, et quel age a-t-il ?

Priorites         P0  le prenom et le nom
                  P0  l'age, qui fixe en base le mode d'interface et la
                      politique camera initiale (ADR-009) -- jamais calcule
                      ici
                  P1  dire l'erreur si la creation echoue

Action principale     Creer (PageParcours), inerte tant que les trois champs
                      ne sont pas valides
Actions secondaires   Retour
Action tertiaire      aucune
Destructif            aucun

Mobile            Page unique de PageParcours (question, action, retour) ;
                  numero 1 sur 1, pas de barre de progression segmentee
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             saisie          nominal
                  age invalide    message d'erreur sous le champ age (hors
                                  3-18 ans), bouton Creer reste inerte
                  envoi           bouton en cours
                  erreur d'envoi  message en liveRegion sous l'action

Mouvement         coquille de PageParcours, aucun mouvement propre

Invariants        l'age ne decide de rien ici : le mode d'interface et la
                  politique camera sont derives en base depuis app_config,
                  jamais dans ce code
                  le seuil d'age est un reglage d'academie, pas une constante
                  d'application

Accessibilite     le message d'erreur d'envoi est en liveRegion
```

Aucune reprise : cet écran passait déjà par `PageParcours` avant le lot R4.
Seule sa fiche manquait, écrite ici à partir du code existant, même cas que
`TUT-00c` au lot R0.

### `TUT-02/b` Appairer un appareil

```
CODE              TUT-02/b
Nom               Appairer un appareil
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      TUT-02 (bouton "Ajouter" d'un enfant)
Profondeur        2
Question          Comment cet appareil rejoint-il le foyer ?

Priorites         P0  le QR grand format et le code en clair, lisibles a
                      distance
                  P0  le delai de validite qui s'ecoule, annonce en clair
                  P1  pouvoir regenerer un code expire

Action principale     aucune sur le QR lui-meme -- Regenerer (code expire) ou
                      Reessayer (erreur), seuls boutons du corps
Actions secondaires   Retour, dans la zone d'action collee en bas
                      (PageShell.actions)
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, QR grand format, retour colle en
                  bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             chargement   texte de chargement, le temps de creer le code
                  code actif   QR + code en clair + compte a rebours
                               (Semantics liveRegion)
                  code expire  message + bouton Regenerer
                  erreur       message + bouton Reessayer

Mouvement         aucun propre a l'ecran

Invariants        le code n'existe qu'a l'ecran, la base n'en garde que
                  l'empreinte -- quitter l'ecran le perd, comportement attendu
                  le QR ne porte que le code, ni identifiant de foyer ni
                  adresse

Accessibilite     le compte a rebours est en liveRegion ; le code en clair a
                  un libelle parle, espace lettre par lettre
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`. Il passe par `PageShell` ;
- le bouton de retour, collé en bas à la main dans un `Padding` hors
  `Scaffold`, passe par la prise `actions:` de `PageShell` — même correction
  que les feuilles d'accueil du lot R0 (`TUT-00c/a`, `TUT-00c/b`,
  `TUT-00c/c`).

### `TUT-04` Disponibilités du foyer

```
CODE              TUT-04
Nom               Disponibilites du foyer
Role              Tuteur
Zone              Disponibilites et affectation
Niveau de charge  C
Ecran parent      aucun : onglet de la navigation tuteur, atteint depuis la
                  barre
Profondeur        1
Question          Quand chaque enfant du foyer est-il disponible pour un
                  cours ?

Priorites         P0  une grille de semaine par enfant, case par case
                  P0  dire ce que la grille produit (elle alimente le
                      matching inverse)
                  P1  le repli quand le foyer n'a aucun enfant

Action principale     aucune globale -- chaque case de GrilleSemaine est
                      l'action elementaire (tap = pose ou retire un creneau)
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Une carte par enfant, une grille par carte, la page defile
                  verticalement
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "grille entiere" au bureau ; GrilleSemaine
                  ne defile jamais horizontalement (pas de Viewport), la
                  distinction n'a jamais eu de code a elle

Etats             content    nominal
                  empty      aucun enfant dans le foyer (EmptyState)
                  error      erreur d'enregistrement d'une case (message sous
                             la grille, la grille reste utilisable)
                  en cours   une case en ecriture n'accepte plus de tap

Mouvement         retour haptique de la case (Pressable), aucun mouvement
                  propre a l'ecran

Invariants        GrilleSemaine est le meme composant, au sens litteral, que
                  celui d'ENS-06 -- deux grilles jumelles finiraient par ne
                  plus afficher la meme chose (ADR-017)
                  l'etat d'ecriture ne se filtre jamais par type d'execution
                  de l'AsyncValue

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` et son `ListView`. Il passe par
  `PageShell` ; pas de tirage-pour-rafraîchir à perdre ici, il n'y en avait
  pas.

### `TUT-05` Réglages par enfant

```
CODE              TUT-05
Nom               Reglages par enfant
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      aucun : onglet de la navigation tuteur, atteint depuis la
                  barre
Profondeur        1
Question          Que faut-il changer pour cet enfant avant la prochaine
                  seance ?

Priorites         P0  une carte par enfant : photo, camera, mode d'interface
                  P0  le texte dit la consequence en clair, avec le prenom
                      (jamais un libelle abstrait)
                  P1  les trois demandes que le tuteur peut deposer
                      (reaffectation, duree, minimum payable)

Action principale     par carte : Ajouter/Changer la photo ; Autoriser/
                      Retirer la camera ; Passer standard/enfant
Actions secondaires   Demander une reaffectation (si un enseignant suit
                      l'enfant), la duree de seance, le minimum payable --
                      chacune ouvre une feuille
Action tertiaire      aucune
Destructif            aucun

Mobile            Une carte par enfant, verticale
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "2 colonnes" au bureau ; non implemente,
                  ecart anterieur a ce lot, hors scope d'une reprise de
                  coquille

Etats             content   nominal
                  empty     aucun enfant dans le foyer (EmptyState, bouton
                            "Ajouter un enfant")
                  error     par geste (photo, reglage, demande), message sous
                            le bouton concerne, jamais un etat de page

Mouvement         aucun propre a l'ecran

Invariants        ces reglages s'appliquent a la seance suivante, jamais
                  pendant un cours en direct (dit une fois en tete, pas
                  repete par carte)
                  aucune copie locale optimiste : ce que la base a accepte
                  est ce qui s'affiche
                  la carte "reaffectation" n'apparait que si un enseignant
                  suit deja l'enfant

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` et son `ListView`. Il passe par
  `PageShell` ;
- la feuille `FeuilleDemandeTuteur` (bottom sheet) garde son `Padding` manuel
  dupliqué — dette déjà connue depuis le lot B0 (`docs/HANDOFF.md` section
  0 ter, point 3), pas traitée ici, hors scope.

### `ENS-06` Disponibilités et matching

```
CODE              ENS-06
Nom               Disponibilites et matching
Role              Enseignant
Zone              Disponibilites et affectation
Niveau de charge  D
Ecran parent      aucun : onglet de la navigation enseignant, atteint depuis
                  la barre (aussi depuis ENS-02, bloc matching)
Profondeur        1
Question          Quand suis-je libre, et qui attend un enseignant ?

Priorites         P0  la grille de mes disponibilites
                  P0  le feed des eleves en attente, trie par anciennete
                  P1  le nombre de places restantes sur mon plafond
                  P1  l'acces a la demande d'augmentation de plafond

Action principale     Prendre un eleve
Actions secondaires   Poser ou retirer un creneau (case de GrilleSemaine)
Action tertiaire      Demander une augmentation de plafond
Destructif            aucun

Mobile            deux onglets (Heures, Eleves), un seul panneau visible,
                  PageShell.entete porte le TabBar -- pas de balayage au
                  doigt entre onglets : le contenu bascule sur l'index du
                  TabController au tap (voir Invariants)
Tablette          pas d'onglet : la grille puis le feed, empiles dans une
                  seule colonne defilante
Desktop           pas d'onglet : la grille a gauche, le feed a droite, cote a
                  cote dans une Row

Etats             loading         texte de chargement, le temps que la
                                  session livre l'identifiant
                  content         nominal
                  empty           aucune famille en attente sur vos creneaux,
                                  sans bouton (l'enseignant ne peut rien y
                                  faire)
                  error           message sur le feed ou sous la grille,
                                  chaque panneau reste utilisable
                                  independamment de l'autre
                  offline         grille consultable, prise impossible et
                                  dite (OfflineBanner, deja porte par
                                  PageShell)
                  plafond atteint le bouton Prendre n'est pas rendu, une
                                  phrase l'explique, avec l'acces a la
                                  demande d'augmentation

Mouvement         retour haptique de la case (Pressable) ; aucun mouvement
                  propre a la bascule d'onglet (pas de PageView, donc pas de
                  transition animee entre panneaux)

Invariants        le tri est par anciennete d'attente, jamais alphabetique
                  le feed rend une ligne par creneau compatible, pas par
                  eleve : compter les lignes annoncerait quatre familles la
                  ou une seule attend
                  pas de TabBarView : il s'appuie sur un PageView, qui exige
                  une hauteur bornee, et PageShell ne borne jamais la hauteur
                  de son child -- c'est la page entiere qui defile, meme
                  mecanique que le reste du produit
                  a partir de la tablette, la grille et le feed se voient a
                  la fois : un onglet sur un ecran large cacherait la moitie
                  de l'information sans raison

Accessibilite     cases de grille a 44 minimum, label parle "Lundi 17 heures,
                  disponible"
                  grille lisible de droite a gauche en arabe (a revoir au lot
                  A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé — **l'écart du registre (section 2), corrigé** :

- l'écran montait un `DefaultTabController` et un `Scaffold` propres, avec un
  `TabBar` et un `TabBarView` fixes, quel que soit le gabarit. À partir de la
  tablette, la grille et le feed se voient désormais tous les deux, sans
  onglet ;
- sur mobile, les deux onglets restent, mais sans `TabBarView` : `PageShell`
  ne borne jamais la hauteur de son `child`, condition que `TabBarView` (un
  `PageView`) exige. Le panneau bascule directement sur l'index du
  `TabController`, ce qui coûte le balayage au doigt entre onglets, gardé au
  tap seul ;
- `CreneauxPage` passe de `ConsumerWidget` à `StatelessWidget` : elle ne lit
  plus aucun provider elle-même, elle choisit seulement la présentation selon
  `AppGabarit.de(context)` ;
- les deux onglets internes (`_OngletHeures`, `_OngletEleves`) passaient
  chacun par leur propre `ListView`. Ils passent par `Column`, comme les
  autres écrans de ce lot : c'est désormais la page entière (ou la colonne du
  panneau, sur tablette et desktop) qui défile, jamais un `Viewport` imbriqué.

### `ADM-02` Validation des dossiers

```
CODE              ADM-02
Nom               Validation des dossiers
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      aucun : onglet de la navigation admin, atteint depuis la
                  barre (aussi depuis le compteur "dossiers" de ADM-01)
Profondeur        1
Question          Ce dossier est-il complet et lisible, et faut-il
                  l'approuver ?

Priorites         P0  un dossier a la fois, jamais une grille (attention
                      sequentielle)
                  P0  la checklist des trois constats avant tout jugement
                      (lisible, nom, validite)
                  P0  le motif obligatoire d'un refus
                  P1  combien de dossiers restent apres celui-ci

Action principale     Approuver (inerte tant que les trois constats ne sont
                      pas coches)
Actions secondaires   Refuser (ouvre le champ de motif)
Action tertiaire      Reessayer (lecture de la file en erreur, ou genre du
                      lecteur inconnu)
Destructif            Refuser un dossier (niveau destructif, motif
                      obligatoire)

Mobile            Colonne unique : apercu du document, checklist, verdict,
                  dans cet ordre
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "file a gauche, dossier a droite" ; non
                  implemente, ecart anterieur a ce lot, hors scope d'une
                  reprise de coquille

Etats             content   nominal (dossier en cours)
                  empty     aucun dossier en attente (EmptyState)
                  error     genre du lecteur inconnu (message specifique,
                            pas de bouton Reessayer : ce n'est pas
                            transitoire) ou erreur de lecture generique
                            (bouton Reessayer)
                  loading   texte de chargement

Mouvement         aucun propre a l'ecran

Invariants        constat -> checklist -> verdict, jamais melanges : le
                  verdict reste dans le corps defilant de PageShell et
                  jamais dans sa zone actions: -- une zone actions collee en
                  bas detacherait le jugement du constat qu'il suit
                  (section 4 de ce document)
                  le cloisonnement de genre n'est pas applique ici : il vit
                  dans read_kyc_documents(), en base
                  Riverpod 3 : lire hasError/hasValue par getter, jamais le
                  type d'execution de l'AsyncValue

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` autour du même `switch` sur
  `AsyncValue`. Il passe par `PageShell` ;
- la zone de verdict (checklist puis approuver/refuser) reste délibérément
  dans le corps défilant, **pas** dans `PageShell.actions` : contrairement
  aux écrans à action unique du lot R0, la séquence constat→checklist→verdict
  doit rester lisible de haut en bas en une seule colonne (invariant déjà
  noté section 4, "Constat et jugement séparés").

### `ADM-06` Demandes et règles

```
CODE              ADM-06
Nom               Demandes et regles
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      ADM-01 (compteur "demandes")
Profondeur        1
Question          Cette demande doit-elle etre accordee, et que dit la regle
                  du profil concerne ?

Priorites         P0  une demande a la fois, la plus ancienne en premier
                  P0  la feuille de regles du sujet, plateforme et effective
                      cote a cote
                  P0  le motif obligatoire d'un refus
                  P1  changer ou clore une regle a la volee, sans qu'une
                      demande existe

Action principale     Accorder
Actions secondaires   Refuser (ouvre le motif) ; Changer / Clore une regle
                      depuis la feuille
Action tertiaire      Reessayer (lecture de la file en erreur)
Destructif            Refuser une demande (motif obligatoire)

Mobile            Colonne unique : constat de la demande, feuille de regles,
                  verdict
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "liste + feuille de regles" ; non
                  implemente, meme ecart et meme raison qu'ADM-02

Etats             content   nominal
                  empty     aucune demande en attente
                  error     lecture hors ligne (bouton Reessayer)
                  loading   texte de chargement

Mouvement         aucun propre a l'ecran

Invariants        meme sequence constat -> jugement qu'ADM-02, meme raison de
                  garder le verdict dans le corps defilant plutot que dans
                  PageShell.actions
                  chaque regle vient de la meme ligne de regles_profil_v,
                  jamais deux lectures separees qui finiraient par diverger
                  une surcharge close ne se supprime jamais (historique)

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` autour du même `switch` sur
  `AsyncValue`. Il passe par `PageShell` ;
- la zone de verdict reste, pour la même raison qu'`ADM-02`, dans le corps
  défilant et pas dans `PageShell.actions` ;
- `FeuilleRegle` (bottom sheet) garde aussi son `Padding` manuel dupliqué,
  même dette que `TUT-05`.

### `ADM-05` Attribution manuelle

```
CODE              ADM-05
Nom               Attribution manuelle
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      ADM-01 (compteur "foyers sans enseignant")
Profondeur        1
Question          A quel enseignant confier cet enfant que personne n'a pris ?

Priorites         P0  deux listes, jamais un formulaire : eleves a gauche,
                      enseignants a droite, confirmation dessous
                  P0  l'anciennete d'attente ordonne la colonne de gauche
                  P0  l'eleve sans creneau reste visible ET non selectionnable,
                      avec la raison ecrite
                  P0  l'enseignant qui ne partage aucune heure reste dans la
                      liste, apres les autres : sans lui l'ecran serait vide le
                      jour ou l'on en a besoin
                  P0  le motif obligatoire hors disponibilite (ADR-021)
                  P1  l'heure evidente est preselectionnee : deux taps

Action principale     Attribuer X a Y
Actions secondaires   Choisir un autre eleve (repli mobile) ; choisir l'heure
                      quand plusieurs sont possibles
Action tertiaire      Reessayer (lecture en erreur)
Destructif            aucun -- une affectation se defait par ADM-06, jamais ici

Mobile            Deux listes empilees. La file cede la place des qu'un eleve
                  est choisi : empiler deux listes longues obligerait a
                  chercher sous le pli ce que le premier tap vient de faire
                  apparaitre
Tablette          Deux colonnes cote a cote
Desktop           Identique

Etats             content   nominal
                  empty     aucun eleve sans enseignant ; aucun eleve choisi
                            (colonne de droite)
                  error     lecture hors ligne des deux cotes, separement
                  loading   Skeleton.liste -- premier ecran du produit a
                            employer le composant (bible section 18)

Mouvement         aucun propre a l'ecran

Invariants        l'heure vient TOUJOURS des creneaux de la famille, jamais de
                  l'enseignant ni de l'administration
                  un enseignant au plafond n'est pas selectionnable, il n'est
                  pas grise apres le geste
                  changer d'eleve remet a zero enseignant, heure et motif
                  aucune ecriture directe dans teacher_student_assignments :
                  ADM-05 appelle attribuer_eleve(), comme ENS-06 appelle
                  prendre_eleve()

Accessibilite     cartes selectionnables via AppCard (Pressable : focus,
                  survol, cible tactile), libelle semantique porte le nom
```

Construit le 12 septembre 2026, hors série, pendant que le lot N2 de l'étape 5
attendait la décision du fournisseur vidéo. Sept tests de widget et neuf
contrôles SQL (`supabase/tests/scenarios_adm05.sql`) le tiennent.

Deux conséquences hors de l'écran lui-même :

- le compteur « Foyers sans enseignant » d'`ADM-01` mène désormais ici. Il ne
  menait nulle part depuis le lot L3, faute d'écran d'action ;
- `parcours-utilisateurs.md` §5 annonçait « attribution en deux taps ». Elle
  l'est quand une seule heure est possible, et **seulement** dans ce cas : avec
  deux heures communes, choisir à la place de l'administration reviendrait à
  poser une heure de cours par défaut.

### `ADM-04` Journal d'audit

```
CODE              ADM-04
Nom               Journal d'audit
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      aucun. Quatrieme destination du menu admin
Profondeur        1
Question          Qui a fait quoi, quand -- et personne n'y a-t-il touche depuis ?

Priorites         P0  la liste, la plus recente d'abord, paginee
                  P0  trois filtres : acteur, type d'evenement, periode
                  P0  AUCUN bouton qui ecrive, nulle part
                  P0  l'etat de la chaine de hachage, en tete
                  P1  le detail de l'entree, borne a trois couples
                  P2  charger les entrees plus anciennes

Action principale     AUCUNE. Seul ecran du produit dans ce cas, et c'est le
                      sujet : la seule chose qu'on puisse faire d'un journal
                      immuable, c'est le lire
Actions secondaires   filtrer ; charger la suite
Action tertiaire      effacer les filtres (depuis l'etat vide seulement)
Destructif            aucun, et par construction : audit_logs refuse update et
                      delete par declencheur depuis 0001

Mobile            Cartes : le type d'evenement en titre, quand/qui/role/cible
                  sur la ligne secondaire, le detail sur sa propre ligne
Tablette          Cartes, identique
Desktop           Tableau dense, en-tete collee en haut. C'est sa forme
                  naturelle (05-regles-responsive.md section 3)

Etats             loading   Skeleton.liste -- deuxieme ecran du produit a
                            employer le composant, apres ADM-05
                  content   nominal
                  empty     aucun evenement : registre BONNE NOUVELLE, sans
                            bouton. Sous filtre : registre actionnable, avec
                            « effacer les filtres »
                  error     message + reessayer. Une page SUIVANTE en echec
                            n'efface pas ce qui est deja lu
                  offline   bandeau de PageShell

Mouvement         aucun propre a l'ecran

Invariants        l'ordre est chronologique inverse, jamais autre chose
                  un changement de filtre relit depuis le debut : garder les
                  entrees deja lues melangerait deux filtres dans une liste
                  la pagination est un keyset (created_at, id), jamais un
                  offset : le journal recoit des lignes pendant qu'on le lit
                  un type d'evenement inconnu s'affiche TEL QUEL, jamais
                  masque : le vocabulaire vit en base et grandira
                  une entree sans acteur humain est nommee « Le systeme », un
                  compte clos « Compte supprime ». Jamais une case vide
                  la verification de chaine ne voyage pas avec la liste, elle
                  a sa propre lecture (voir ADR-022)

Accessibilite     chaque cellule du tableau porte le titre de sa colonne dans
                  son libelle parle : Flutter n'associe pas un en-tete a ses
                  cellules comme le ferait un <th>
                  chaque carte se lit comme un seul element (MergeSemantics)
                  les pilules de filtre portent l'etat « selectionne »
```

Construit le 12 septembre 2026. Treize tests de widget, trois tests unitaires
et neuf contrôles SQL (`supabase/tests/scenarios_adm04.sql`) le tiennent.

Trois conséquences hors de l'écran lui-même :

- **`DataCollection` existe enfin.** Il était au catalogue des composants en P1
  depuis la refonte, « nécessaire avant l'étape 5 », et n'avait jamais été
  construit faute d'écran dont la forme naturelle soit un tableau. `ADM-04`
  était cet écran ;
- **`FilterPill` est né ici**, hors de la liste d'origine, et a été inscrit au
  catalogue comme `MarquePage` avant lui ;
- **la chaîne de hachage de `audit_logs` est relue pour la première fois.**
  Elle existait depuis l'étape 1, et chaque écriture payait un `lock table`
  pour la tenir : le prix était payé, la garantie jamais constatée. Détail et
  arbitrage : **ADR-022**.

### `ELV-03` / `ENS-03` / `CTR-02` La salle

**Les trois codes sont un seul écran, et c'est la première décision de la
fiche.** Ce qui les distingue ne vient pas du rôle de session, que le client
porte, mais du **jeton** émis par `create-room-token` : son champ `role` et ses
capacités signées (`can_publish`, `can_publish_video`, `hidden`). Un écran qui
choisirait sa vue d'après `sessionProvider.role` déciderait d'après une valeur
que le client peut avoir mal lue ; le jeton, lui, est ce que le serveur LiveKit
fera respecter de toute façon. Trois écrans séparés auraient par ailleurs
divergé sur le bandeau permanent, qui est exactement ce que l'ADR-011 interdit.

Le jeton porte **quatre** rôles, pas trois : `participant_role` vaut `teacher`,
`student`, `guardian_observer` ou `masked_controller`. Le quatrième code manquait
au registre : le tuteur qui presse « Assister » depuis `TUT-01` entre en
observateur muet et **visible**, là où le contrôleur entre invisible. Il n'a pas
de code d'écran propre parce qu'il n'a pas d'écran propre : c'est `ELV-03` sans
aucune commande de publication.

```
CODE              ELV-03, ENS-03, CTR-02
Nom               La salle
Role              Eleve, enseignant, tuteur observateur, controleur
Zone              Journee et salle
Niveau de charge  B / C (eleve), D (enseignant, controleur)
Ecran parent      aucun. HORS ARBRE : ni barre basse, ni rail, ni retour
Profondeur        hors arbre
Question          Mon cours a lieu maintenant : est-ce que j'y suis, est-ce que
                  l'autre y est, et qu'est-ce que j'entends ?

Priorites         P0  le flux de l'autre, en grand
                  P0  micro, camera, quitter -- selon ce que le jeton permet
                  P0  le bandeau permanent, jamais masque (ADR-011)
                  P0  dire l'etat de la connexion en mots, jamais en couleur
                  P1  la liste des participants (enseignant, controleur)
                  P2  le document partage et les controles de page (lot N5)

Action principale     AUCUNE au sens du bouton plein : la salle est un lieu, pas
                      un formulaire. Les commandes sont des controles egaux
Actions secondaires   ouvrir ou fermer le micro ; ouvrir ou fermer la camera
Action tertiaire      aucune
Destructif            quitter, et c'est le seul geste confirme de l'ecran

Mobile            Une seule scene : le flux dominant plein cadre, la vignette
                  locale posee dessus, en bas de la zone. Bandeau puis
                  commandes sous la scene
Tablette          Idem, plus la colonne des participants pour l'enseignant et
                  le controleur
Desktop           Idem tablette, vignette locale plus grande

Etats             loading   demande de jeton en cours, puis pre-vol : un mot par
                            etape, jamais un squelette -- il n'y a aucune forme
                            de contenu a preparer
                  content   connecte. Sous-etat : seul en salle, qui se dit
                  empty     seul en salle : « n'est pas encore arrive »
                  error     quatre refus distincts, un message par cause
                  offline   AUCUN bandeau hors ligne : c'est LiveKit qui sait,
                            et deux signaux concurrents se contrediraient

Mouvement         aucun propre a l'ecran. Le mouvement d'encouragement de la
                  sortie (fiche produit) attend le lot de la presence : il
                  annoncerait un cours fini, ce que N3 ne sait pas encore

Invariants        le bandeau permanent est le MEME pour les quatre roles, sans
                  parametre : PermanentNotice n'en accepte aucun
                  micro et camera FERMES a l'entree, pour TOUS les roles. Un
                  tap les ouvre
                  un controle que le jeton refuse N'EST PAS RENDU, jamais grise
                  le controleur ne figure PAS dans sa propre liste de
                  participants : il voit deux personnes, comme l'enseignant.
                  C'est le test visuel de l'invisibilite
                  la qualite du lien se dit en mots. Une pastille seule ne
                  represente jamais un etat critique
                  aucune URL LiveKit, aucun import du SDK hors de
                  livekit_session_provider.dart

Accessibilite     chaque commande porte le libelle de son ACTE (« Ouvrir le
                  micro »), jamais celui de son etat
                  chaque vignette se lit comme un element unique : nom, role,
                  micro, image
                  cible tactile du mode courant, 72 en mode enfant
```

**Le bandeau permanent est en bas, sous la scène.** Les deux sources se
contredisaient : la fiche produit dit « bandeau permanent en bas de salle »,
`etape-5-salle-coran-presence.md` §7 dit « en haut ». La fiche produit tranche,
pour une raison matérielle : en haut, le bandeau entre en concurrence avec la
zone média dominante et, sur téléphone, avec l'encoche et le geste de retour.
En bas, il touche les commandes, c'est-à-dire l'endroit que l'on regarde quand
on décide d'ouvrir son micro.

**Ce que N3 ne construit pas, et pourquoi ce n'est pas un oubli :**

- **le document partagé et les contrôles de page de niveau 1.** Ils n'ont ni
  contenu à paginer (le Coran est le lot N5, et son jeu de données n'est pas
  importé) ni canal de diffusion tranché (question `e` du §10 de la spécification
  d'étape : LiveKit data, Supabase Realtime, autre). Les livrer maintenant
  donnerait à l'enseignant des boutons qui tournent des pages que l'élève ne
  verrait pas : un produit qui ment. La zone n'est donc pas rendue du tout, et
  le bouton « Ouvrir le Coran » **n'existe pas** plutôt que d'être grisé, par la
  règle déjà appliquée au bouton caméra ;
- **les quatorze états de présence.** C'est le lot N4. La salle dit l'état de sa
  **connexion** temps réel, ce que LiveKit sait, et rien de ce que la base
  dérive. L'invariant J3 (« un état de présence indisponible s'affiche comme
  inconnu ») n'a donc encore rien à borner ici ;
- **`ENS-03` vers `ENS-04`.** L'invariant du §4 exige que la sortie de
  l'enseignant mène au cahier de transmission, et rien d'autre. `ENS-04` est
  l'étape 6 : aucune route n'existe. La sortie mène donc à `ENS-02`, et **cet
  écart est ouvert**, nommé ici plutôt que masqué par une route vide qui
  prétendrait tenir l'invariant.

Construit le 12 septembre 2026, lot N3. Il remplace le plus gros
`EcranAConstruire` du routeur : il reste **six** écrans à construire.

#### Ce que le lot `N4` y ajoute, le 13 septembre 2026

La fiche ci-dessus ne change pas : **N4 étend la salle, il ne la réécrit pas.**
Trois ajouts, et une correction.

```
Priorites   P0  l'etat de presence personnel de l'eleve, permanent (section 6.6)
            P1  le tableau de presence des inscrits (enseignant, controleur)

Mobile      L'eleve : sa presence sous la pastille de connexion, en mots.
            L'enseignant : un bouton « Presence » dans l'entete, qui ouvre
            la liste en feuille -- consultable, jamais imposee
Tablette    La colonne laterale porte la presence, et non plus la seule liste
            des participants connectes
```

**La liste change de nature, et c'est la décision du lot.** Elle était bâtie sur
les participants que le moteur temps réel publie ; elle est désormais bâtie sur
les **inscrits**, avec l'état de chacun. La raison est celle qui justifiait N4 :
celui qui n'est jamais arrivé n'a aucune piste LiveKit, donc aucune ligne côté
moteur — et c'est précisément de lui que l'enseignant a besoin de savoir quelque
chose. L'état du micro reste affiché, mais seulement pour qui est réellement
dans la salle : un micro barré à côté de « Pas encore là » dirait deux fois la
même chose, et la deuxième serait fausse.

**Deux faits distincts, deux lignes.** La pastille du haut dit l'état de la
**connexion** temps réel, ce que le moteur sait ; celle de la présence dit ce
que la base dérive. On peut être parfaitement connecté et noté « en retard », et
avoir perdu le lien depuis dix secondes sans être encore noté « déconnecté ».
Les confondre en une seule pastille aurait été faux.

**Le tuteur observateur ne lit ni l'un ni l'autre.** Il assiste : il n'a pas
d'état pédagogique à consulter, et la liste ne lui est pas due. Le suivi d'un
enfant est `TUT-06`, à l'étape 6.

**Invariants ajoutés à la fiche :**

```
Invariants  un etat de presence indisponible s'affiche INCONNU, jamais
            « absent » -- les deux ne disent pas la meme chose, et l'un
            compte pour le suivi quand l'autre ne compte pour rien (J3)
            une couleur seule ne represente jamais un etat de presence : la
            pastille porte toujours son mot, et sa duree quand il y en a
            une (J7)
            l'eleve ne lit QUE son propre etat -- la borne est en base, pas
            dans l'ecran
            une visite de controle ne laisse AUCUNE ligne de presence
            lisible, pas meme a l'interesse (ADR-011)
```

**La correction.** `presence_seance_v`, posée au lot N1, n'avait **aucun filtre
d'appelant** — alors que les trois vues d'exposition de `0001` en portent toutes
un. Une vue appartenant à `postgres` sans `security_invoker` ne voit pas la RLS
des tables qu'elle lit : tout compte authentifié y aurait lu la présence de
toutes les séances de la plateforme. Mesuré sur les fixtures de
`scenarios_n4.sql` : un élève inscrit à aucune des deux séances y lisait **6
lignes sur 6** ; il en lit **0** depuis la migration `0011`. Rien n'a fuité — il
n'existe aucune séance en base — et le défaut n'avait jamais été exercé parce
qu'aucun écran ne lisait la vue. **Une vue sans écran est une vue non testée**,
c'est la leçon de N3 une seconde fois.

**Ce que N4 ne construit pas :** le **geste** de correction manuelle
(`corrigee_manuel`) et le marquage `excusee`. La table et ses policies existent
depuis `0007`, mais l'écran qui les déclenche demande une confirmation, un motif
obligatoire et une entrée de journal — c'est un lot, pas une ligne, et la
spécification d'étape §6.5 laisse d'ailleurs ce mécanisme explicitement ouvert.
N4 **affiche** la consolidation ; il ne la prononce pas.

Deux conséquences hors de l'écran :

- **`PageImmersive` existe**, dans `lib/core/widgets/`, et rejoint le catalogue
  des composants. C'est la coquille des écrans qui n'ont ni titre, ni gouttière,
  ni page : la salle aujourd'hui, `ELV-04` au lot N5. Sans elle, la salle aurait
  monté un `Scaffold` nu, c'est-à-dire exactement le défaut mesuré sur le tunnel
  d'entrée le 11 septembre ;
- **un défaut de `N2` est corrigé.** `LiveKitSessionProvider.rejoindre()` ouvrait
  le micro dès l'entrée « la voix d'abord ». C'était contraire à l'invariant du
  §4, présent au catalogue depuis la refonte et écrit deux fois dans la fiche
  produit : à l'entrée, rien ne publie tant que personne n'a tapé. Le défaut
  était invisible sans écran pour l'exercer.

---

### `ELV-04` Le Coran

**Le premier écran du produit dont le contenu n'est pas de l'interface.** Tous
les autres présentent des données de l'application ; celui-ci présente un texte
qui existait avant elle, et cela renverse trois habitudes du dépôt.

La première est visuelle : le motif « carte sur fond crème », pris à tous les
écrans des lots R, **s'inverse ici délibérément**. La Bible §22 l'impose,
`CONTENT > CHROME`, et §5.3 de la spécification d'étape l'écrit sans détour : le
Coran ne se traite jamais comme une `AppCard` entourée de contrôles. L'écran
passe donc par `PageImmersive`, registre `lecture`, le parchemin plus chaud que
`parcours-utilisateurs.md` réclamait pour cet écran.

La deuxième est le sens de lecture. Le `PageView` des 604 pages vit dans un
`Directionality.rtl`, **quelle que soit la langue de l'interface autour** : on
tourne les pages d'un mushaf de la droite vers la gauche, et ce n'est pas une
préférence d'affichage, c'est le document.

La troisième est l'écriture. **L'écran n'enregistre la position de lecture
qu'après un geste de navigation de l'élève.** Ouvrir le Coran ne doit jamais
écraser le marque-page par la page d'ouverture : ce serait le défaut que
l'invariant J2 interdit à l'enseignant, commis par l'écran lui-même.

```
CODE              ELV-04
Nom               Le Coran
Role              Eleve (enseignant au lot N6, en document partage)
Zone              Contenu et transmission
Niveau de charge  B / C
Ecran parent      ELV-02, et la barre basse de l'eleve
Profondeur        1
Question          Ou en etais-je, et qu'est-ce que je lis maintenant ?

Priorites         P0  le texte, en grand, sans rien par-dessus
                  P0  savoir ou l'on est : sourate, page sur 604, juz
                  P0  reprendre la ou l'on s'etait arrete
                  P1  tourner la page, au doigt comme au bouton
                  P2  la taille du texte, et la provenance du corpus

Action principale     AUCUNE au sens du bouton plein : lire n'est pas valider.
                      « Reprendre » est la seule action mise en avant, et elle
                      disparait des qu'elle ne menerait nulle part
Actions secondaires   page precedente, page suivante
Action tertiaire      reduire ou agrandir le texte
Destructif            aucun

Mobile            Le texte plein cadre, balayage lateral pour tourner la page.
                  Entete de reperage en haut, commandes de page en bas
Tablette          Idem, texte plus grand
Desktop           Idem, colonne de lecture bornee par la coquille

Etats             loading   le texte arrive
                  content   la page, decoupee par sourate
                  empty     AUCUN etat vide legitime : une page du mushaf porte
                            toujours du texte. Une page vide signifie que le
                            corpus n'est pas importe, et se dit comme tel
                  error     lecture impossible, avec « Reessayer »
                  offline   celui de la coquille

Mouvement         le glissement d'une page a l'autre, et rien d'autre : un
                  texte sacre ne s'anime pas

Invariants        J6 : aucun identifiant de fichier nulle part. L'ecran lit des
                  versets et compose lui-meme
                  J2 : la position de lecture ne s'ecrit qu'apres un geste de
                  l'eleve, et aucun enseignant ne peut l'ecrire (borne en base)
                  le texte ne se modifie jamais : aucune ecriture hors admin
                  la provenance du corpus est visible AU PIED DE CHAQUE PAGE,
                  jamais reléguee dans un ecran « a propos »
                  une sourate ne porte son titre que la ou elle COMMENCE

Accessibilite     le texte reste selectionnable et lisible par un lecteur
                  d'ecran : c'est ce que le rendu Unicode achete, et c'est la
                  raison de ne pas etre passe aux glyphes d'une edition
                  les numeros de verset sont MUETS : ce sont des reperes de mise
                  en page, pas du texte a epeler au milieu d'une phrase
                  les commandes de page portent un verbe, pas une fleche
```

**Ce que la navigation de page n'est pas.** §5.3 demande que les contrôles
secondaires soient masqués et révélés par un tap. Tourner la page **n'est pas
un contrôle secondaire** : c'est le geste du lecteur. Le masquer laisserait le
clavier et les technologies d'assistance sans aucun moyen d'avancer, le
balayage étant le seul recours. Sont donc masqués, derrière le bouton de
réglages de l'en-tête : la taille du texte, et rien d'autre pour l'instant.

**Ce que `N5` ne construit pas, et qui est écrit plutôt que masqué :**

- **le mode suivi enseignant** (§4.4) et le document partagé. C'est le lot N6,
  et il attend toujours la question `e` du §10 : le canal de diffusion de l'état
  partagé de séance n'est pas tranché. Le bouton « Ouvrir le Coran » de la salle
  n'existe donc toujours pas ;
- **le découpage en quinze lignes par page.** La colonne `verset.ligne` reste
  nulle : les deux sources disponibles ne segmentent pas les mots de la même
  façon (83 668 contre 77 881, mesuré), et une correspondance devinée sur un
  texte sacré n'est pas acceptable. Rien à l'écran n'en dépend (ADR-024) ;
- **le lien cliquable vers tanzil.net.** L'URL est affichée en clair ;
  `url_launcher` n'est pas au `pubspec.yaml`, qu'une autre session modifiait au
  moment du lot.

Construit le 13 septembre 2026, lot N5. Le composant `RosaceVerset` rejoint le
catalogue des composants a cette occasion.

### `CTR-01` Planning global

**La seule destination du rôle**, et c'est la première contrainte de la fiche :
un contrôleur n'a qu'un travail (modèle de navigation, `parcours-utilisateurs.md`),
donc pas de barre basse, pas de rail, pas de menu. L'écran répond à une seule
question, celle que `02-regles-ux.md` lui assigne : **qu'est-ce qui nécessite une
vérification ?** L'ordre des lignes est la réponse, et il ne se règle pas.

```
CODE              CTR-01
Nom               Planning global
Role              Controleur
Zone              Journee et salle
Niveau de charge  D
Ecran parent      aucun : c'est la racine du role
Profondeur        0
Question          Qu'est-ce qui a lieu maintenant, qu'est-ce qui a mal tourne,
                  et ou dois-je entrer ?

Priorites         P0  les seances en cours, en tete, avec leur bouton d'entree
                  P0  l'heure locale ET l'heure UTC de chaque seance
                  P0  le rappel permanent que la visite est journalisee
                  P1  les seances a venir, du plus proche au plus lointain
                  P1  les filtres par etat et par enseignant
                  P2  ce que la lecture n'a pas montre, en pied de liste

Action principale     AUCUNE au sens du bouton plein : l'ecran est une liste, et
                      « Observer » se pose sur une LIGNE, pas sur l'ecran. Vingt
                      cours en direct feraient vingt zones pleines, ce que la
                      regle de la zone pleine unique interdit. Niveau secondaire
Actions secondaires   retenir un etat, retenir un enseignant, tout afficher
Action tertiaire      reessayer une lecture qui a echoue
Destructif            aucun

Mobile            Une carte par seance : enseignant en titre, eleve, heure et
                  etat sur la ligne secondaire, heure UTC en dessous, bouton
                  d'entree en dernier
Tablette          Idem mobile : un tableau dense retreci est precisement ce que
                  `05-regles-responsive.md` section 3 interdit
Desktop           Tableau dense, en-tete de colonnes collee en haut, la liste
                  defile dessous

Etats             loading   squelette de liste, jamais le mot « Chargement »
                  content   la liste, triee : en cours, incidents, a venir
                  empty     aucune seance : un constat, pas une panne, et aucun
                            bouton -- il n'y a rien a relacher
                  empty+    aucune seance SOUS FILTRE : une impasse dont on sort,
                            avec « Tout afficher »
                  error     la lecture a echoue, avec « Reessayer ». Une
                            relecture qui echoue n'efface jamais la liste deja
                            affichee
                  offline   le bandeau hors ligne de PageShell, rien de plus

Mouvement         aucun propre a l'ecran. Le seul mouvement est le retour local
                  d'un refus d'entree

Invariants        « en cours » se mesure sur les HEURES, jamais sur
                  `sessions.status` : rien dans le produit ne fait passer une
                  seance a `in_progress`, et un bouton conditionne a ce statut
                  ne s'afficherait jamais
                  le bouton d'entree n'existe QUE sur une seance en cours. Hors
                  de la, pas de bouton grise : pas de bouton
                  l'inscription precede la navigation. On n'ouvre la salle
                  qu'apres que la base a accepte la visite
                  l'heure locale et l'heure UTC sont TOUTES LES DEUX affichees
                  le rappel de journalisation est permanent, comme le bandeau
                  de la salle : ni conditionnel, ni au premier passage
                  prenom ET identifiant immuable des deux cotes, jamais le nom
                  de famille ni la photo (ADR-008, ADR-012)

Accessibilite     chaque cellule porte le titre de sa colonne dans son libelle
                  parle : Flutter n'associe pas un en-tete a ses cellules
                  la carte se lit comme un seul element (MergeSemantics)
                  l'etat porte toujours son mot, jamais la seule pastille
```

**Ce que le lot a trouvé, et qui ne se voyait pas.** `CTR-02`, l'observation
invisible, était **inatteignable** depuis sa construction : rien n'inscrivait
jamais de ligne `masked_controller` dans `session_participants`, et
`autoriser_jeton_video()` refuse tout appelant qui n'y figure pas. Pire, le
plafond de participants du MVP-0 — deux — comptait les témoins comme des élèves :
un cours 1-to-1 était **plein**, donc fermé à toute visite, et le bouton
« Assister » de `TUT-01`, en production depuis l'étape 4, échouait de la même
façon sans rien dire. La migration `0012` ouvre les deux portes et rend au
plafond son sens : il borne le **groupe pédagogique**, pas l'assistance. La
spécification d'étape 5 §9 l'écrivait déjà — « le 1-to-1, **le contrôleur en
plus** ».

**Et l'invisibilité ne tenait que sur deux surfaces.** `N4` l'avait fermée sur la
présence ; restaient `session_peers_v`, la table `session_participants`
elle-même (policies enseignant et foyer) et `session_events`, toutes trois
lisibles depuis un navigateur authentifié. Aucune n'avait jamais été exercée,
faute de ligne à y lire. **Une invisibilité se vérifie sur chaque surface où la
personne peut apparaître** — la leçon de N4, une seconde fois, et il a fallu la
mesurer pour la croire : le premier correctif écrivait la borne directement dans
la policy de `session_events`, où elle ne voyait rien, parce qu'une policy qui
interroge une table protégée par RLS ne voit que ce que l'appelant voit.

**Ce que la fiche ne construit pas, et pourquoi ce n'est pas un oubli :**

- **les trois signalements automatiques de l'ADR-011** (visites répétées sur un
  même enseignant, volume anormal sur une journée, concentration sur un élève).
  Ils surveillent le surveillant, et leur place est l'espace admin, pas l'écran
  du contrôleur : les lui montrer lui dirait exactement quel seuil ne pas
  franchir. Le journal porte déjà la matière (`controller_observation_started`) ;
- **`CTR-03`, la grille d'audit.** Reportée par la fiche produit elle-même : en
  MVP-0 le contrôleur observe et signale, il ne note pas ;
- **le signalement d'incident à l'administrateur.** Il figure dans le tableau
  « peut / ne peut pas » de l'ADR-011, mais aucun écran, aucune table et aucun
  canal ne le portent aujourd'hui. Le construire ici en aurait fait un formulaire
  sans destinataire.

Construit le 13 septembre 2026, lot `CTR-01`, en parallèle du lot N5.
