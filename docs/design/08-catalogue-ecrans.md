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
| `TUT-01` | Accueil famille | Tuteur | C | 0 | `/tuteur` | Liste de `ChildCard` | 2 à 3 colonnes + colonne « à confirmer » | **repris (R2)**, fiche §6 |
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
| `ELV-02` | Accueil élève | Élève | B / C | 0 | `/eleve` | Deux blocs | Deux blocs centrés, **rien de plus** | **repris (R1)**, fiche §6 |
| `ENS-02` | Journée | Enseignant | D | 0 | `/enseignant/journee` | Une colonne | Colonne + panneau de détail | **repris (R3)**, fiche §6 |
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
| `ADM-01` | Centre de commande | Admin | E | 0 | `/admin/tableau-de-bord` | Signaux puis chiffres | 4 chiffres + liste pleine largeur | **repris (R3)**, fiche §6 |
| `ADM-02` | Validation des dossiers | Admin | E | 1 | `/admin/dossiers` | Un dossier à la fois | File à gauche, dossier à droite | construit |
| `ADM-06` | Demandes et règles | Admin | E | 1 | `/admin/demandes` | Liste de demandes | Liste + feuille de règles | construit |
| `ADM-04` | Journal d'audit | Admin | E | 1 | `/admin/journal` | Cartes | Tableau dense | **à construire** |
| `ENS-05` | Profil enseignant | Enseignant | D | 0 | `/enseignant/profil` | Page | Page + colonnes | **à construire** |
| `CPT-01` | Espace comptable | Comptable | E | 0 | `/comptable` | Cartes | Tableaux | **hors MVP-0** (ADR-003) |

**Codes nouveaux introduits par ce catalogue** : `ENS-05` et `CPT-01`, qui
existaient comme routes sans code, et les trois sous-écrans `TUT-00c/a`, `/b`,
`/c`, qui étaient décrits sans être nommés. Aucun code existant n'est renommé.

## 2. Ce que le registre révèle

Onze écrans sont encore `EcranAConstruire`, et quatre de ceux qui existent
étaient à reprendre par le lot R. Le lot R les a repris tous les quatre :
`ELV-02` (fait, R1), `TUT-01` (fait, R2), `ENS-02` et `ADM-01` (fait, R3).

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
| **R1** | `ELV-02` | **fait le 7 septembre 2026.** C'est l'écran montré à l'opérateur, et le plus simple : deux blocs. Il sert de preuve du système |
| **R2** | `TUT-01` | **fait le 8 septembre 2026.** Il porte `ChildCard`, composant du domaine famille |
| **R3** | `ENS-02`, `ADM-01` | **fait le 8 septembre 2026.** `TimelineRow` porté par les trois sorties (cours, pause, prière), `StatTile` aux compteurs, `SignalRow` à la liste à traiter. `NavShell` câblé au routeur dans le même lot, voir `etape-2-journal.md` |
| **R4** | `TUT-02`, `TUT-04`, `TUT-05`, `ENS-06`, `ADM-02`, `ADM-06` | Le reste de l'existant |
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
