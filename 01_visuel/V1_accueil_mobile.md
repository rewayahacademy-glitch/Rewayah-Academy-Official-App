# V1 - Accueil tuteur mobile, thème clair : relevé visuel

Date : 24/09/2026. Agent de relevé visuel, groupe `V1_accueil_mobile`. Lecture seule : aucun fichier du dépôt n'a été modifié.

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `D:\RA _APP\docs de lancement\tutuor image\mobile\accueil  tuteur mobile light mode.png` (deux espaces entre « accueil » et « tuteur ») |
| Dimensions | 845 × 1862 px, 24 bpp RGB, 96 dpi, 1 103 199 octets |
| Image ouverte | oui, en entier avec l'outil Read, puis en 6 tuiles agrandies ×2 |
| Tuiles | `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V1_accueil_mobile\t1.png` à `t6.png` (bandes horizontales y 0-340, 330-710, 700-1040, 1030-1330, 1310-1610, 1500-1862, agrandies ×2 en bicubique) |
| Échantillonnage | `System.Drawing.Bitmap.GetPixel`. Méthodes : point unique, médiane d'une zone pour les aplats, moyenne des 8 % de pixels les plus sombres pour l'encre du texte, moyenne des 15 % les plus saturés pour les accents. Contraste WCAG calculé sur les HEX mesurés. |

Tous les textes ci-dessous ont été lus sur l'image ou sur les tuiles. Rien n'est déduit d'un nom de fichier.

## 1. Manifeste

| Fichier | Zone | Écran | Route logique (§4) | État | Thème | Format | Statut |
|---|---|---|---|---|---|---|---|
| `accueil  tuteur mobile light mode.png` | image entière (0,0)-(845,1862), un seul écran | Accueil du tuteur | `/tuteur/accueil` | nominal, jour J, salle ouverte à T-13 min, profil « Mariam » sélectionné, bannière bloquante « appareil non prêt » | clair | mobile, cadre iPhone (barre d'état « 9:41 ») | nouveau high-fi |

L'image ne contient qu'un seul écran. Elle ne montre ni état vide, ni chargement, ni erreur, ni séance prolongée, ni variante sombre.

## 2. Échelle : lecture honnête

- Échelle géométrique imposée : 845 px pour 390 dp, soit **2,167 px/dp**.
- Avec cette échelle, le texte courant ressort à environ **9 dp** (hauteur de capitale mesurée 13-14 px, donc un corps d'environ 19-20 px) et le CTA à **33 dp** de haut. Ce n'est pas réaliste : **l'image générée est environ 1,4 fois plus dense qu'un vrai écran de 390 dp**.
- Pour chaque mesure, j'indique donc deux colonnes :
  - **@2,17** : géométrie brute à 390 dp.
  - **@1,38** : lecture normalisée, calée sur un texte courant de 14 dp. Cela revient à une toile d'environ 612 dp.
- Recommandation : garder les **proportions et la hiérarchie relative**, puis appliquer une échelle de tokens lisible. Titre ≈ 2,0 × corps, nom de l'élève ≈ 1,6 ×, classe et titres de section ≈ 1,2-1,3 ×, légendes ≈ 0,9 ×. CTA ≥ 48 dp, cibles tactiles ≥ 48 dp (§9).
- Conséquence de mise en page : cinq pastilles de profils de 72 dp (lecture normalisée) ne tiennent pas dans 390 dp. **Le sélecteur doit défiler horizontalement.**

## 3. Tokens mesurés

### 3.1 Couleurs (HEX mesurés, coordonnées en px source)

| Rôle | HEX | Mesure et coordonnées | Remarque |
|---|---|---|---|
| Fond de page | **#F6F6F8** | médiane (5,320)-(45,360) ; points #F6F7F8 (10,70), #F7F6F8 (15,700), #F7F7F9 (830,1050), #F6F6F8 (420,1045) | gris très légèrement violacé |
| Surface carte | **#FEFDFE** | médiane (560,440)-(780,530) ; #FDFDFD (600,470), #FDFCFE (500,1300), #FDFDFE (400,1610) | presque blanc |
| Bordure carte | **#EDEDF1** | (795,700), #EEEEF2 (50,700), #ECECF1 (420,1026), #EDEDF1 (420,1521) | 1 px, plus une ombre ambiante très faible (#F2F1F4 à y=1027, #F3F3F6 à x=49) |
| Surface imbriquée (bloc séance) | **#F4F3F6** | médiane (250,700)-(400,730) ; #F3F2F5 (300,620) | sans bordure, x 80-765, y 544-889 |
| Texte principal | **≈ #0D0820** | noyau d'encre : « Lundi 21 septembre » #0B061C, « Accueil » #110A21, « Session dans 13 min » #080418, « Avant / Après » #060415 ; icône cloche #0B071A (756,99) | quasi-noir teinté violet, contraste 19,3:1 sur la carte |
| Texte secondaire | **#5A5863** | noyau « Sayyida Amina » (208-360, 465-488) ; « Votre heure » #686673 ; légende sous l'avatar #626168 | 6,9:1 sur la carte |
| Texte tertiaire et liens | **#74727F** | noyau « Tablette ou ordinateur… » (168-624, 828-848) ; tâches #73727D ; « Règles de lecture » #787781 ; « Voir tout » #767480 ; « Voir l'historique » #72707B | 4,64:1 sur la carte mais **4,26:1 sur #F4F3F6** (sous AA) |
| Accent violet (icônes, onglet actif, point de notification, initiale) | **≈ #AC88F7** | noyaux saturés : initiale « M » #AC88F7, point de notification #AC89F5 (781,95), livre #AE8AF7, histogramme #AE89F8, icône d'onglet actif #B592F8, libellé d'onglet actif #AF89F5 ; pixels les plus saturés #A076F8 (141,1779), #9E74F4 (116,423) | 2,7:1 sur blanc : **à assombrir pour tout texte** |
| Anneau du profil sélectionné | #BEA1F6 | noyau (66-172, 150-175) ; points #BE99F9 (70,200), #BB94FC (165,200) | trait d'environ 4-5 px |
| CTA doux (fond) | **#DAC7FD** | médiane (150,930)-(300,990) ; #D9C7FC (200,958) | lavande. Le libellé #030207 donne 13,4:1 |
| CTA plein | **absent** | aucun bouton plein sur cet écran | le seul aplat violet saturé est l'icône d'onglet actif |
| Fond d'avatar teinté | #F2EDFD | médiane (88,400)-(110,470) | pastille d'initiale |
| Silhouette par défaut | fond #F3F1F8, figure #D9D3ED | (232-250,160-180) ; (245-300,170-230) | |
| Bouton « Ajouter » | fond #F5F4F6, contour #E8E8ED (693,200), « + » #8D8B9C (737,200) | | |
| Statut vert (point) | **#22CA6B** | noyau (143-159, 223-239) ; point de pastille #0CC360 (581-596, 586-602) | |
| Pastille verte « Salle ouverte » | fond **#D8F9E4**, texte #1A4F2D | médiane (620,580)-(660,608) | 8,5:1 |
| Pastille verte « Présente » | fond #E3FDEC, texte #284E39 | médiane (655,1590)-(668,1612) | 8,7:1. Deux verts pâles différents pour le même rôle |
| Texte « En séance » (sous Mariam) | **#139694** (sarcelle) | noyau (75-157, 281-298) | **pas le même vert** que le point #22CA6B ; 3,3:1 sur le fond, sous AA |
| Statut orange (point) | **#EFA60F** | (297-313, 223-239) | |
| Statut rouge (point) | **#E0375A** | (608-624, 223-239) | |
| Statut gris (point) | **#A7A4BC** | (458,232) | |
| Bandeau d'alerte : fond | **#FEF6E7** | médiane (250,1150)-(590,1175) ; #FEF7E8 (300,1165) | |
| Bandeau d'alerte : bordure | #F8ECD9 | (420,1064), #FBEDD8 (420,1180), #F7EDD9 (50,1120) | 1 px chaud |
| Bandeau d'alerte : icône | **#D18C0A** | noyau (81-121, 1103-1143) | point d'exclamation cerclé |
| Bandeau d'alerte : bouton doux | fond #FEE9BB, texte #6E6A61 | médiane (612-624, 1098-1148) ; texte (628-742, 1102-1145) | 4,51:1, à la limite |
| Bandeau d'alerte : titre et corps | titre #202025 ; corps #7E7C7A | (145-460, 1100-1118) ; (145-550, 1128-1146) | corps à 3,87:1, **sous AA** |
| Wi-Fi « Bon » | #10D560 | (90-125, 1647-1673) | voir le piège n° 8 |
| Séparateurs de liste | ≈ #EFEFF4 | (420,1346), #F1F1F6 (420,1401), #EFEEF5 (420,1455) ; séparateur vertical « Durée » #A9A8AF (426,675) | le séparateur vertical « Votre heure / Durée » est bien plus foncé |
| Barre de navigation : fond | **#FDFCFD** | médiane (250,1715)-(350,1795) | flottante, en forme de pilule |
| Barre de navigation : bordure | #EDEEF1 (420,1706), #EEEEF2 (25,1755), #EBEBF0 (820,1755) | | 1 px |
| Onglet actif | icône #B592F8, libellé #AF89F5 | (147-183, 1728-1766) ; (135-196, 1777-1791) | **aucun indicateur en pilule** derrière l'onglet actif ; libellé à 2,66:1 |
| Onglets inactifs | icône #C1C1C1 à #C5C7C6 (420,1755) ; libellé #ABABAE | encre (398-443, 1776-1794) | gris neutre, non teinté ; **2,24:1, sous AA** |

### 3.2 Dimensions (px source, puis dp @2,17 / @1,38)

| Élément | px | dp @2,17 | dp @1,38 |
|---|---|---|---|
| Marge latérale des cartes (bord à x=50 et x=795) | 50 | 23 | 36 |
| Retrait du titre « Accueil » (x=64) | 64 | 30 | 46 |
| Largeur d'une carte | 746 | 344 | 541 |
| Padding horizontal de la carte vers le bloc interne (x=80) | 30 | 14 | 22 |
| Padding du bloc interne vers le texte (x=102) | 22 | 10 | 16 |
| Padding haut de la carte principale (avatar « M » à y=384) | 20 | 9 | 14 |
| Rayon des cartes (deux méthodes : bord droit et diagonale) | 14-24 (≈ 18) | 7-11 (≈ 8) | 10-17 (≈ 13) |
| Rayon du bloc interne, du bandeau et de la carte « Avant / Après » | 12-17 | 6-8 | 9-12 |
| Rayon du CTA | 15-20 | 7-9 | 11-15 |
| CTA « Voir la classe » (x 81-764, y 922-993) | 684 × 72 | 316 × 33 | 496 × 52 |
| Bouton doux « Connecter un appareil » (x 605-763, y 1093-1151) | 159 × 59 | 73 × 27 | 115 × 43 |
| Pastille « Salle ouverte » (x 563-737, y 574-614) | 175 × 41, rayon complet | 81 × 19 | 127 × 30 |
| Pastille « Présente » (x 648-753, y 1585-1618) | 106 × 34, rayon complet | 49 × 16 | 77 × 25 |
| Anneau de l'avatar sélectionné, diamètre (x 69-167) | 99 | 46 | 72 |
| Autres avatars, diamètre (≈ 225-319) | ≈ 94 | 43 | 68 |
| Bouton « Ajouter », diamètre (693-781) | 89 | 41 | 64 |
| Pas entre les centres d'avatars (118, 272, 428, 583, 737) | 155 | 72 | 112 |
| Point de statut, diamètre, avec liseré blanc | 20 | 9 | 14 |
| Avatar d'initiale « M » de la carte (80-181) | 102 | 47 | 74 |
| Icônes de ligne (horloge 40, appareil 37, livre 32, histogramme 30, Wi-Fi 34, alerte 39) | 30-40 | 14-18 | 22-29 |
| Cloche (750-780 × 91-127) et point de notification (16) | 31 × 37 ; 16 | 14 × 17 ; 7 | 22 × 27 ; 12 |
| Pas des lignes de la liste « Avant / Après » (1322, 1376, 1431) | 54 | 25 | 39 (**sous 48**) |
| Barre de navigation (x 25-820, y 1706-1803) | 796 × 98, rayon ≈ 48 (stade) | 367 × 45, marge de 12 | 577 × 71 |
| Espace entre le bas de la barre de navigation et le bas de l'écran | 58 | 27 | 42 |

Espacements verticaux entre sections :

| Intervalle | px | @2,17 | @1,38 |
|---|---|---|---|
| Ligne de base du titre (123) → haut des anneaux (151) | 28 | 13 | 20 |
| Nom de l'avatar → sous-libellé | ≈ 29 (ligne à ligne) | 13 | 21 |
| Bas du sélecteur (≈ 297) → carte principale (364) | 67 | 31 | 49 |
| Bloc interne (889) → CTA (922), puis CTA (993) → bas de la carte (1026) | 33 et 33 | 15 | 24 |
| Carte principale (1026) → bandeau (1064) | 38 | 18 | 28 |
| Bandeau (1180) → carte « Avant / Après » (1225) | 45 | 21 | 33 |
| Carte « Avant / Après » (1477) → carte « Dernière séance » (1522) | 45 | 21 | 33 |

Le rythme est constant : environ 40-45 px entre cartes et environ 67 px entre le sélecteur et la première carte.

### 3.3 Typographie (hauteur de capitale mesurée, taille estimée = capitale / 0,70)

| Niveau | Exemple | Capitale (px) | Taille @2,17 | Taille @1,38 | Graisse observée |
|---|---|---|---|---|---|
| Titre de page | « Accueil » | 27 | 18 dp | **28 dp** | Bold (700) |
| Nom de l'élève dans la carte | « Mariam » | 22 | 14,5 | **23** | Bold (700) |
| Nom de classe | « Classe An-Nour » | 18 | 12 | **18-19** | SemiBold ou Bold (600-700) |
| Titres de section et de bloc | « Lundi 21 septembre », « Session dans 13 min », « Avant / Après la séance », « Dernière séance » | 16-18 | 11-12 | **17-18** | SemiBold (600) |
| Libellé du CTA | « Voir la classe » | 18 | 12 | **18** | SemiBold (600) |
| Valeur forte | « 13:45 Paris », « 1 h 30 » | 18 | 12 | **18** | SemiBold ou Bold |
| Enseignant (secondaire) | « Sayyida Amina » | 16 | 10,5 | **16-17** | Regular (400) |
| Corps | « Votre heure », « Tablette ou ordinateur… », tâches, date de la dernière séance, titre et corps du bandeau | 13-14 | 9 | **14** | Regular ; titre du bandeau en SemiBold |
| Légende | noms et sous-libellés d'avatar, « Règles de lecture • Niveau 1 », « Réseau élève », libellés de navigation | 12 | 8 | **12-13** | Medium pour les noms d'avatar et « Bon », Regular sinon |

Famille apparente : une **seule grotesque géométrique de type DM Sans** pour tout l'écran. Indices : « a » à deux étages, « y » droit, « M » large, chiffres à chasse proportionnelle. Rien n'y ressemble à Plus Jakarta Sans pour le corps.

**Règle écrite prioritaire** (prompt « observation », §1) : **DM Sans pour les titres français** (« Accueil », « Mariam », « Classe An-Nour », « Lundi 21 septembre », « Avant le prochain cours », « Dernière séance »), **Plus Jakarta Sans pour tout le reste** (corps, libellés, boutons, pastilles, navigation, légendes, statuts).

Le BRIEF signale en outre qu'**aucune des deux polices n'est présente dans le dépôt** (InstrumentSans et BricolageGrotesque y sont déclarées). Cette contradiction reste à consigner côté coordinateur.

## 4. Fiche d'écran : Accueil tuteur (mobile, clair)

### 4.1 Composition, de haut en bas (une seule colonne)

1. **Barre d'état iOS** (y 0-60) : « 9:41 », réseau, Wi-Fi, batterie. Cadre de maquette, à ne pas implémenter.
2. **En-tête** (y ≈ 90-130) : titre « Accueil » aligné à gauche (x=64) ; cloche en contour à droite (750-780), avec un point violet plein en haut à droite (non-lus).
3. **Sélecteur de profils élèves** (y 151-297), rangée horizontale de 5 éléments centrés :
   - avatar circulaire (silhouette violet pâle par défaut) ;
   - point de statut coloré en bas à droite, cerclé de blanc ;
   - prénom en Medium sombre ;
   - sous-libellé de statut en gris ; il est coloré (sarcelle) uniquement pour le profil sélectionné.
   - Le profil sélectionné (Mariam) porte un **anneau violet** d'environ 2 dp.
   - Le 5ᵉ élément est un cercle clair avec « + » et le libellé sur deux lignes « Ajouter enfant ».
   - Pas de carte autour de la rangée : elle est posée sur le fond.
4. **Carte principale « prochaine séance »** (x 50-795, y 364-1026, surface #FEFDFE, bordure de 1 px, rayon ≈ 8-13 dp), dans l'ordre :
   - rangée d'identité :
     - à gauche, avatar d'initiale « M » (violet sur fond teinté) ;
     - au centre, pile de texte : « Mariam » (H), « Classe An-Nour » (H plus petit), « Sayyida Amina » (secondaire, Regular), « Règles de lecture • Niveau 1 » (légende) ;
     - en haut à droite, lien discret avec icône appareil photo « fournir une photo » (gris, sans soulignement) ;
   - **bloc imbriqué** (surface #F4F3F6, sans bordure, rayon ≈ 6-12 dp) :
     - ligne 1 : date « Lundi 21 septembre » à gauche et pastille verte « Salle ouverte » (point + texte) à droite ;
     - ligne 2 : deux colonnes séparées par un filet vertical, « Votre heure / 13:45 Paris » et « Durée / 1 h 30 » (libellé gris au-dessus, valeur forte en dessous) ;
     - ligne 3 : icône horloge (contour) + « Session dans 13 min » (SemiBold, grand) ;
     - ligne 4 : icône ordinateur et téléphone (contour) + « Tablette ou ordinateur conseillé. Téléphone accepté. » (tertiaire) ;
   - **CTA doux pleine largeur** « Voir la classe → » : fond lavande #DAC7FD, texte quasi-noir, flèche à droite du libellé, centré.
5. **Bandeau d'action bloquante** (x 50-795, y 1064-1180, fond crème #FEF6E7, bordure chaude de 1 px) :
   - icône d'alerte orange cerclée ;
   - titre « Aucun appareil prêt pour Mariam » (SemiBold) et corps « Connectez un appareil pour éviter tout problème. » ;
   - à droite, bouton doux ocre « Connecter un appareil » qui **passe sur deux lignes**.
6. **Carte « Avant / Après la séance »** (y 1225-1477) :
   - en-tête : icône livre violette (contour) + titre, et lien « Voir tout → » aligné à droite (gris) ;
   - 3 lignes-tâches : cercle vide (contour gris violacé) + libellé ;
   - séparateurs pâles qui démarrent sous le texte (x ≈ 143) et non sous l'icône ;
   - pas de séparateur après l'en-tête.
7. **Carte « Dernière séance »** (y 1522 → masquée par la barre de navigation vers 1700) :
   - en-tête : icône histogramme violette + « Dernière séance » ; dessous « Jeudi 18 septembre • 1 h 30 » ;
   - à droite, lien « Voir l'historique → » et, en dessous, pastille verte « Présente » ;
   - puis deux colonnes séparées par un filet : icône Wi-Fi verte + « Réseau élève / Bon » et icône Wi-Fi verte + « Réseau enseignant / Bon » ;
   - un séparateur (y ≈ 1696) laisse supposer du contenu en dessous, caché sous la navigation.
8. **Barre de navigation flottante** (pilule de 45-71 dp de haut, marges de 12 dp, fond blanc, bordure de 1 px) : **3 destinations** « Accueil » (active : icône maison pleine violette, libellé violet), « Foyer » (icône groupe pleine grise), « Compte » (icône personne pleine grise). Pas d'indicateur de sélection.

### 4.2 Alignements, proportions, densité

- Grille : un bord commun pour les cartes (x=50/795) et un second bord de contenu (x=80 à 102). Le titre « Accueil » (x=64) n'est aligné ni sur le bord des cartes ni sur leur contenu, et le premier avatar est à x=69. Recommandation : **un seul alignement de contenu** (marge de page = marge des cartes) dans les tokens.
- Répartition verticale : sélecteur ≈ 8 %, carte principale ≈ 36 %, bandeau ≈ 6 %, préparation ≈ 14 %, dernière séance ≈ 10 % visibles, navigation ≈ 5 %. La carte principale domine, conformément au mandat (un objectif et un CTA dominant, §9).
- Densité moyenne et aérée : grands intervalles entre cartes, peu de filets.
- **Seule imbrication** : bloc séance dans la carte principale. Il ne faut pas la multiplier (§9 : « moins de cartes imbriquées »).

### 4.3 Surfaces, iconographie, CTA

- Surfaces : 4 cartes blanches à bordure de 1 px et ombre quasi nulle ; un bloc imbriqué gris-lavande ; un bandeau d'alerte crème. Listes à séparateurs à l'intérieur des cartes.
- Icônes de contenu **au trait** (outline) : horloge, appareil, livre, appareil photo, cloche. Icônes violettes pour identifier une section (livre, histogramme). Icônes de navigation **pleines** (filled). Le style correspond à Phosphor, déjà présent dans le dépôt, en regular pour le contenu et fill pour la navigation.
- CTA de l'écran :

  | Libellé exact | Style | Destination (§4) |
  |---|---|---|
  | « Voir la classe → » | doux, pleine largeur, dominant | `/tuteur/classes/:classeId` |
  | « Connecter un appareil » | doux ocre, dans le bandeau | `/appareils/connexion` |
  | « fournir une photo » | lien avec icône | fiche élève `…/informations` (photo) |
  | « Voir tout → » | lien gris | `…/travail` de la classe |
  | « Voir l'historique → » | lien gris | `/tuteur/historique` |
  | « + Ajouter enfant » | élément du sélecteur | `/tuteur/foyer/ajouter` |
  | Cloche | icône | `/tuteur/notifications` |
  | 3 onglets | navigation | destinations principales |

### 4.4 États visibles

- Sélecteur, 4 statuts :
  - vert + « En séance » (texte sarcelle) ;
  - orange + « Session 18:00 » ;
  - gris + « Dernière séance 1 h » ;
  - rouge + « Absente ».
- Salle ouverte, compte à rebours de 13 min, présence confirmée « Présente », réseau « Bon », notification non lue, blocage « appareil non prêt », photo manquante.
- Chaque statut du sélecteur est doublé d'un texte, ce qui est conforme (§9 : ne pas coder un statut par la seule couleur). Les points de statut, eux, n'ont pas d'équivalent accessible visible : il faut une étiquette sémantique.

### 4.5 Textes lisibles, recopiés exactement

- `9:41`
- `Accueil`
- `Mariam` / `En séance`
- `Yusuf` / `Session 18:00`
- `Aïcha` / `Dernière séance 1 h`
- `Adam` / `Absente`
- `Ajouter` / `enfant` (sur deux lignes)
- `M` (initiale)
- `Mariam`
- `Classe An-Nour`
- `Sayyida Amina`
- `Règles de lecture • Niveau 1`
- `fournir une photo`
- `Lundi 21 septembre`
- `Salle ouverte`
- `Votre heure` / `13:45 Paris`
- `Durée` / `1 h 30`
- `Session dans 13 min`
- `Tablette ou ordinateur conseillé. Téléphone accepté.`
- `Voir la classe` (suivi d'une flèche →)
- `Aucun appareil prêt pour Mariam`
- `Connectez un appareil pour éviter tout problème.`
- `Connecter un` / `appareil` (bouton sur deux lignes)
- `Avant / Après la séance`
- `Voir tout` (→)
- `Réviser pages 24 à 26`
- `Écouter la récitation`
- `Mémoriser la partie Hifz`
- `Dernière séance`
- `Jeudi 18 septembre • 1 h 30`
- `Voir l'historique` (→)
- `Présente`
- `Réseau élève` / `Bon`
- `Réseau enseignant` / `Bon`
- `Accueil` · `Foyer` · `Compte` (navigation)

### 4.6 Ordre du mandat (§5 Accueil)

L'ordre exigé est : titre et notifications, sélecteur, prochaine séance, action bloquante éventuelle, préparation, dernière séance. **La maquette le respecte.** Seul écart : un second blocage (« fournir une photo ») est logé dans la carte principale (voir le piège n° 6).

## 5. Erreurs et incohérences de la maquette à ne PAS reproduire

| # | Ce que montre la maquette | Règle applicable | Correction attendue |
|---|---|---|---|
| 1 | **Navigation à 3 onglets** : Accueil, Foyer, Compte | §4 et BRIEF : **Accueil · Foyer · Historique · Compte**, même ordre partout (la maquette desktop en a 4) | 4 destinations ; conserver le style de la pilule flottante |
| 2 | « **Ajouter enfant** » dans le sélecteur | §4 « Ajouter un profil élève » ; §5 le profil du parent ne s'appelle pas « enfant » ; §5 ne pas dupliquer le Foyer | Libellé « Ajouter un profil élève » (ou forme courte non genrée, avec étiquette sémantique complète), ouvrant le **même** flux `/tuteur/foyer/ajouter`. Le dépôt contient encore `fr.i18n.json:224` « Ajouter un enfant » et `:1159` `ajouterEnfant` « Ajouter un enfant », deux libellés hérités à ne pas réutiliser ici |
| 3 | « **Session** dans 13 min », « **Session** 18:00 » | Vocabulaire « Séance » et « Cours » ; §5 : « Cours dans 3 h 28 » ; i18n existant `tc.groupe.temps.dansMinutes` « Cours dans {minutes} min » (`fr.i18n.json:1690`) et `dansHeures` (:1691) | « Cours dans 13 min » ; sous-libellé du type « Séance à 18:00 » ; ne jamais écrire « Session » à l'écran |
| 4 | **États contradictoires** : Mariam est « En séance » dans le sélecteur, mais la carte dit « dans 13 min » avec « Salle ouverte » | Un seul état temporel dérivé des données (§5 ; recette §11.5) | Le statut du sélecteur et celui de la carte proviennent de la même source ; à T-13, pas de « En séance ». « En séance » ou « En direct » seulement si la séance a réellement commencé |
| 5 | « Salle ouverte » à T-13 | Ouverture selon la **fenêtre existante et configurable**, généralement T-20 (§5) ; pas de constante | Consommer la politique. i18n existant : `salleOuverte` « Salle ouverte · {reste} » (:1693), `salleOuverteCourt` (:1694) |
| 6 | **Deux blocages simultanés** : « fournir une photo » dans la carte et le bandeau « Aucun appareil prêt » | §5 : « éventuelle action bloquante… seulement si confirmé par les données. **Action unique** contextualisée » | Un seul blocage prioritaire à la fois, et seulement s'il est confirmé (règle photo réelle, appareil réellement non prêt). Lien photo en minuscule initiale : écrire « Fournir une photo » si on le conserve |
| 7 | La carte montre l'**initiale de l'élève** et « Sayyida Amina » **sans photo d'enseignant** | §5 : « nom **ET photo publique** de l'enseignant, titre Sayyid/Sayyida. Ne confonds pas portrait élève et photo enseignant » | Ajouter la photo publique de l'enseignant (avec repli) à côté de son nom. Le portrait de l'élève reste distinct |
| 8 | « Réseau élève **Bon** » et « Réseau enseignant **Bon** » avec icônes Wi-Fi vertes | §5 : « réseau bon » seulement si une donnée réelle l'établit ; §Historique : qualité réseau secondaire et **seulement si mesurée** ; aucune télémétrie brute | Masquer par défaut. N'afficher une qualité que si elle est mesurée et autorisée. La mesure du **réseau de l'enseignant** n'a pas à être exposée au tuteur sans décision explicite |
| 9 | « **Avant / Après la séance** » | §5 et `docs/current/07` l.12 : « **Avant le prochain cours** », au plus 3 actions ; i18n existant `avantProchainCours` (:1723) | Titre « Avant le prochain cours ». Les cases à cocher n'attestent aucune maîtrise ; pas de coche locale sans service (pas de faux succès) |
| 10 | Dates « **Lundi 21 septembre** » et « **Jeudi 18 septembre** » | Vérifié : en 2026, le 21/09 est un lundi mais le 18/09 est un **vendredi** ; en 2025, le 18/09 est un jeudi mais le 21/09 un dimanche | Dates illustratives incohérentes entre elles : toujours formater depuis la date réelle (locale fr, fuseau IANA) |
| 11 | « **Absente** » pour « Adam » (prénom masculin) et point rouge | Accord à tirer des données ; §5 : aucune absence déduite d'une simple déconnexion | Libellés d'accord générés correctement (ou forme neutre). « Absent·e » seulement si la présence est validée ; sinon « En cours de vérification » |
| 12 | « Dernière séance 1 h » (sous Aïcha) | Formulation ambiguë (il y a 1 h ? durée ?) | Libellé explicite dérivé des données, par exemple « Séance terminée il y a 1 h » si c'est le sens retenu (à arbitrer, pas de constante) |
| 13 | « Tablette ou ordinateur conseillé. Téléphone accepté. » | Texte existant `tc.groupe.session.conseilAppareil` (`fr.i18n.json:1719`) : « Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge. » | Réutiliser la clé existante plutôt que le texte de la maquette |
| 14 | Prénoms (Mariam, Yusuf, Aïcha, Adam), « Classe An-Nour », « Sayyida Amina », « Règles de lecture • Niveau 1 », « 13:45 Paris », « 1 h 30 », « 13 min », « pages 24 à 26 », « Hifz » | §9 : noms, dates, capacités et métriques illustratifs ≠ constantes | Tout provient des services. « Paris » doit venir du fuseau IANA de l'utilisateur (clé `heureEtVille` « {heure} {ville} », :1710) |
| 15 | Point violet sur la cloche | Doit refléter de vrais non-lus (`/tuteur/notifications`) | Pas de point décoratif |
| 16 | Carte « Dernière séance » tronquée sous la barre flottante | Pas de contenu masqué | Réserver un padding bas égal à la hauteur de la barre plus la zone sûre |
| 17 | Bouton « Connecter un appareil » qui passe sur deux lignes ; ligne-tâche de 25-39 dp | §9 : cibles ≥ 48 dp, texte agrandi sans coupure | Bouton sous le texte ou libellé sur une ligne ; lignes de 48 dp minimum |
| 18 | Libellés d'onglets inactifs #ABABAE (2,24:1), libellé actif #AF89F5 (2,66:1), « En séance » #139694 (3,34:1), corps du bandeau #7E7C7A (3,87:1), tertiaire sur bloc interne (4,26:1) | §9 : accessibilité | Garder les teintes, mais **assombrir les tokens de texte** pour atteindre AA (4,5:1) |
| 19 | Deux verts différents pour « en direct » (#22CA6B pour le point, #139694 pour le texte) et deux fonds verts (#D8F9E4, #E3FDEC) | Tokens sémantiques uniques (§9) | Un token `success` (point, icône) et un token `successContainer` / `onSuccessContainer` |
| 20 | Libellé interdit **« Cours en cours »** : absent de la maquette, mais présent dans le dépôt : `fr.i18n.json:1700` `tc.groupe.temps.enCours` = « Cours en cours · {reste} » | Prompt observation §2 : « Cours en cours » est interdit | Signalement au coordinateur (clé à ne pas consommer sur l'Accueil tuteur). Pour une séance en cours : « En direct » (:1701) ou « En séance » ; pour une séance prolongée : « Cours toujours en cours » (:1702, conforme au §5) |

## 6. États à dériver (absents de l'image)

À composer avec les mêmes composants, sans nouvelle direction artistique :

- **Vide** : aucun profil ou aucune classe. Invitation à ajouter un profil élève ou à s'inscrire, jamais une fausse classe.
- **Chargement** : squelette de la carte principale.
- **Erreur de bloc** : la carte garde son cadre avec « Impossible de charger… » et « Réessayer ».
- **Hors ligne.**
- **Séance en direct** : « En direct » ou « En séance ».
- **Séance prolongée** : « Cours toujours en cours », sans compteur négatif.
- **Séance terminée, séance annulée ou reportée**, et changement d'heure (clés `dst.*` existantes, :1712-1716).
- **Profil du parent** dans le sélecteur, sans le mot « enfant ».
- **Thème sombre** : aucune maquette mobile sombre dans ce groupe ; il faudra le dériver et documenter la dérivation (§9).

## 7. Synthèse des tokens proposés (valeurs de départ, à centraliser)

| Token | Clair (mesuré) | Note |
|---|---|---|
| `background` | #F6F6F8 | |
| `surface` / `card` | #FEFDFE, bordure #EDEDF1 1 dp | ombre quasi nulle |
| `surfaceContainer` (imbriqué) | #F4F3F6 | |
| `onSurface` | ≈ #0D0820 | |
| `onSurfaceVariant` | #5A5863 | |
| `textTertiary` | #74727F → **à assombrir** vers ≈ #6A6875 pour AA sur #F4F3F6 | |
| `primary` (accent) | ≈ #AC88F7 pour icônes et indicateurs ; version texte **à assombrir** | |
| `primaryContainer` (CTA doux) / `onPrimaryContainer` | #DAC7FD / ≈ #0D0820 | |
| `primarySoft` (fond d'avatar) | #F2EDFD | |
| `success` / `successContainer` / `onSuccessContainer` | #22CA6B / #D8F9E4 / #1A4F2D | |
| `warning` / `warningContainer` / bordure / bouton | #D18C0A / #FEF6E7 / #F8ECD9 / #FEE9BB | |
| `danger` | #E0375A | |
| `neutralStatus` | #A7A4BC | |
| `navBar` / `navInactive` / `navActive` | #FDFCFD / #C1C1C1 (icône), libellé à assombrir / accent | |
| Rayons | carte ≈ 12-16 dp ; bloc et bandeau ≈ 10-12 dp ; CTA ≈ 12-14 dp ; pastilles et navigation : complets | déduits de la lecture normalisée |
| Espacements | marge de page = marge des cartes (≈ 20-24 dp) ; padding de carte ≈ 16-20 dp ; espace entre cartes ≈ 24-32 dp ; sélecteur → carte ≈ 32-48 dp | à caler sur l'échelle d'espacement existante |
| Hauteurs | CTA ≥ 48-52 dp ; lignes de liste ≥ 48 dp ; avatar du sélecteur ≈ 56-72 dp (défilement horizontal) | |
| Typographie | titre de page 28 / 700 DM Sans ; nom 22-24 / 700 DM Sans ; section 18 / 600 DM Sans ; corps 14-15 / 400 Plus Jakarta Sans ; légende 12-13 / 400-500 Plus Jakarta Sans ; CTA 16-18 / 600 Plus Jakarta Sans | |
