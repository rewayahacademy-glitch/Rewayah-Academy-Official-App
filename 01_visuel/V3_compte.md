# V3 : relevé visuel « Mon compte » du tuteur

Date : 24/09/2026. Agent de relevé visuel, groupe V3_compte. Phase en lecture seule : aucun fichier du dépôt n'a été modifié.
Sources lues : `pilotage-tuteur-v1/BRIEF.md` et le mandat `REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§2, §4, §5 « Mon compte » et « Foyer », §6, §7, §8, §9, « Prompt étape observation tuteur »). J'ai aussi fait deux lectures ciblées dans le dépôt pour confronter la maquette au code : `lib/core/router/routes.dart` et `lib/core/auth/service_auth.dart`.

Les trois images ont été ouvertes avec l'outil Read, en entier puis tuile par tuile. Les tuiles sont dans `01_visuel/tuiles/V3_compte/` : 7 tuiles pour le desktop, 5 par variante mobile et 6 zooms de typographie, de navigation et d'apostrophe. Les couleurs ont été lues avec `System.Drawing.Bitmap.GetPixel`, selon quatre méthodes :
- un point unique pour les aplats ;
- les transitions le long d'une ligne pour les bords ;
- la moyenne des 6 % de pixels les plus sombres (ou les plus clairs en thème sombre) pour l'encre du texte ;
- les inflexions du bord pour les rayons.

Le script de mesure se trouve dans le dossier scratchpad de la session ; il n'est pas livré.

---

## 1. Manifeste

| # | Fichier exact | Taille | Écran réel | Thème | Format | Statut |
|---|---|---|---|---|---|---|
| F1 | `docs de lancement\tutuor image\mon compte tuteur desktop light mode.png` | 1672 × 941 (16:9) | Mon compte, état nominal | Clair | Desktop, rail latéral | Nouveau high-fi |
| F2 | `docs de lancement\tutuor image\mobile\mon compte tuteur mobile light mode.png` | 805 × 1953 | Mon compte, état nominal, capture pleine hauteur (défilement) | Clair | Mobile, barre basse | Nouveau high-fi |
| F3 | `docs de lancement\tutuor image\mobile\mon compte tuteur desktop dark mode.png` | 805 × 1954 | **Mon compte, version MOBILE sombre**. Le nom du fichier est faux | Sombre | **Mobile**, barre basse | Nouveau high-fi |

**Nature réelle de F3.** Malgré « desktop » dans son nom, F3 est la déclinaison sombre de F2, et non un desktop. Quatre mesures le montrent :
- le format est un portrait de 805 px de large, comme F2 ;
- la géométrie est identique au pixel près : titre à x=84 contre 83, cartes en x 81-726 contre 80-727, mêmes ordonnées de cartes à ±2 px (99, 377, 728-730, 1047-1048, 1277, 1533, 1783-1785) ;
- F3 a la même barre de navigation basse à 4 destinations (y 1861-1937) ;
- F3 n'a aucun rail latéral.

Au manifeste, il faut donc l'appeler « Mon compte · mobile · sombre ». **Aucune maquette desktop sombre n'existe** : le desktop sombre est à dériver et sa dérivation à documenter (§9 du mandat).

Les trois fichiers sont horodatés du 24/09/2026 à 00:10. Aucun ne contient d'état vide, d'erreur ou de chargement, ni de barre d'état système.

---

## 2. Échelle

- **Mobile (F2, F3).** L'échelle géométrique imposée est de 805 px pour 390 dp, soit **2,064 px/dp**. À cette échelle, le corps de texte (capitale de 13 px, soit une police d'environ 18,6 px) ressort à 9 dp et la barre de navigation à 37 dp : ce n'est pas réaliste. L'image est plus dense qu'un vrai écran de 390 dp. J'ai donc aussi une **lecture normalisée à 1,33 px/dp**, calée sur un corps de 14 dp (toile équivalente d'environ 605 dp). V1 a utilisé 1,38 ; l'écart vient de la largeur, 845 px contre 805 px. Les deux lectures sont données ci-dessous. Il faut retenir les proportions et la hiérarchie, puis appliquer l'échelle de tokens.
- **Desktop (F1).** Je fais l'hypothèse d'un viewport de 1440 dp, soit **1,161 px/dp**. Elle est cohérente avec le corps mesuré : capitale de 12 px, police d'environ 17 px, soit 15 dp.

---

## 3. Couleurs mesurées (HEX, coordonnées en px source)

### 3.1 Clair : desktop F1 et mobile F2

| Rôle | F1 desktop | F2 mobile | Remarque |
|---|---|---|---|
| Fond de page | **#FBFAF9** (260,500) ; #FAFAF8 (1620,500) ; #FBFBF9 (800,60) | **#FCFBF9** (30,500), (400,20) ; #FBFAF8 (30,1940) | Blanc cassé **chaud**. V1 Accueil mesure au contraire #F6F6F8, un gris froid : incohérence entre maquettes |
| Fond du rail | #FEFEFD (100,600) ; bordure droite de 1 px #F2F3F4 puis #F7F7F6 (x=226-227, y=200) | n/a | Rail presque blanc, séparé par un filet |
| Surface de carte | **#FEFEFE** (1200,200) ; #FDFDFD (640,600) | **#FEFEFD** (400,300), (600,600) | Presque blanc |
| Bordure de carte | **#EDEEEF** (309,200) ; #ECECEE (1300,501) ; #EFEFF1 (309,912) | **#F0F0EF** (79,300) ; #EFEEEE (400,1031) | 1 px ; ombre extérieure quasi nulle |
| Séparateur de lignes | **#F0F0F5** (600,488) ; #EEEFF5 (600,548) | **#EFF0F1** (400,567) ; #EFF0F2 (400,636) | 1 px |
| Texte principal (titres) | ≈ **#010216** (noyau de « Mon compte », 310-545 × 20-65) | ≈ **#0C0F1F** (noyau de « Mon compte ») ; nom #06091A | Quasi-noir bleuté ; 18,9:1 |
| Texte courant (lignes) | #171A2F (« Historique et reçus ») | **#2D303A** (idem) ; téléphone #272A32 | 13:1 |
| Texte secondaire | **#6E7491** (« Actif jusqu'au… ») ; « Tuteur » #6F7491 ; valeur « Email et mot de passe » #6F7591 | **#74778E** (« Tuteur ») ; #747990 ; #777C94 | 4,4 à 4,6:1 sur la carte, **à la limite de l'AA** |
| Légende | #737895 (« Connexion par email ») ; #6D7390 (« Membres, appareils… ») | **#7F8399** ; #7A8097 | **3,7:1, sous l'AA** |
| Accent violet plein (icônes pleines) | **#6F2EFC** (50,316), icône de rail active ; #682BFD (1030,766), « ? » ; #7333FB (1037,380) | **#7041E1 à #7446F5** (648,1876), icône d'onglet actif ; (139,1581), « ? » ; #7244E9 (140,1088) | Violet saturé. **Très différent de l'accent de V1 (#AC88F7)** |
| Accent en texte ou en trait | « Modifier » #5D1AF9 ; chevrons #6116FA ; icônes de ligne #6015F9 | « Modifier » #6439E6 ; chevrons #7446E6 ; icônes de ligne #6B39E5 | 5,7 à 6,7:1 : valable pour du texte |
| Onglet actif du rail | fond **#F2EBFE** (30,307), #F4EDFE (190,307) ; libellé #5815F8 ; icône pleine #6F2EFC | n/a | Pilule x 14-212, y 282-331 |
| Rail inactif | libellé #2F354D ; icône en trait #393E5E | n/a | |
| Barre basse : fond | n/a | **#FFFEFD** (400,1900) ; bordure #F1F2F2 (734,1900), #EEEDED (400,1937) | Flottante, isolée |
| Barre basse : onglet actif | n/a | icône pleine #7448E6 ; libellé **#7C59DD** ; **soulignement #7B48E8** (648,1935) | Trait de 84 × 4-5 px (x 607-691, y 1932-1936) collé au bord bas de la barre |
| Barre basse : onglets inactifs | n/a | libellé #6D7285 à #7C8092 ; icône en trait #676A81 | 3,9 à 4,7:1 |
| CTA doux (« Gérer les paiements ») | fond **#E8D6FE** (400,436), #E7D5FD (700,436) ; libellé #02010C ; pas de bordure | fond **#E2CFFE** (200,505), #E2CEFD (600,530) ; libellé #040315 ; chevron #1B1834 | Lavande. Libellé à 14,4:1 |
| Bouton secondaire en contour (« Modifier ») | fond #FAF9FE (1420,142) ; bordure #BFA0FB à #AE89FA (1406-1410) ; texte #5D1AF9 | fond #FAF5FE (585,133) ; bordure #AD90F3 (572,147) ; texte #6439E6 | Contour violet de 1 px |
| Bouton icône (engrenage) | fond #FCFBFD (1540,30) ; bordure #EDEDF1 (1533,43) ; icône #530FF8 | fond #FDFBFC (690,30) ; bordure #EDEDEF (674,46) ; icône violette | Carré arrondi |
| Avatar d'initiales du titulaire | fond **#E3CAFD** (388,120) ; « FD » #030519 | fond **#E2CEFD** (160,150) | |
| Médaillon d'icône de section | fond #F9F3FE (348,360), #F3EBFE (1020,760) ; anneau de 1 px ≈ #9C79F9 à #9662FD (333-334, y=371) | fond #F5F0FE (120,420) ; anneau **#9974EF** (106,437) | Cercle clair avec anneau violet |
| Pastille verte de statut (fond) | **#E5FCEB** (478,168) ; #E1FEEA (812,356) | **#DFFBE7** (250,200) ; #E0FBE8 (575,408) | « Compte vérifié », « Accès actif » |
| Pastille verte (bordure) | ≈ #A6EDBD à #8AE9AF (x=470-471) ; #9FF1BC (805,363) | **#A3E8BF** (330,189) ; #9DE7B7 (650,399) | 1 px |
| Pastille verte (texte, coche) | texte #099C21 et #089926 ; coche pleine **#00B82E** (488,181) | texte **#0B9442** ; coche #04B758 (586,410) | Texte à **3,5-3,6:1, sous l'AA** |
| Danger (« Se déconnecter ») | texte **#FB264C** ; icône #EE002C (863,913) | texte **#EE2B47** ; icône #EB1E36 (400,1814) | **3,8-4,1:1, sous l'AA** |
| Teintes des membres du foyer | FD #E9D8FE, AM #CBE9FE, YA #FED9D8, SN #DFF4DD (y=585) | #E3D0FE, #C3E6FD, #FCD2D0, #D8EEDA | Violet, bleu, rose, vert, sans signification métier |
| Pastilles orange, rouge, grise ; bandeau d'alerte | **absents** de ces trois maquettes | absents | Voir V1 |

### 3.2 Sombre : mobile F3

| Rôle | HEX (coordonnées) | Remarque |
|---|---|---|
| Fond de page | **#171923** (30,500) ; #181B25 (400,15) ; #161821 (30,1940) | Léger vignettage, négligeable |
| Surface de carte | **#1B1D28** (600,600) ; #1C202A (400,300) | |
| Bordure de carte | **#282B38** (81,300) ; #2D313C (400,99) ; anneau extérieur plus sombre #10121B (400,712) | Filet clair de 1 px et ombre portée courte |
| Séparateur | **#2B2E3C** (400,569) ; #2D3140 (400,637) | |
| Texte principal | **#FFFFFF** (titres) ; lignes #F4F5F7 | 16,8:1 |
| Texte secondaire | « Tuteur » #C2C3E9 ; sous-titre **#B3B5D7** ; valeurs #A6A9C9 | Teinté lavande, 8,4:1 |
| Légende | **#999CB8** ; #9DA1C0 | 6,2:1 |
| Accent en trait (icônes, chevrons) | **#CBABFD** ; chevrons #CDB0F6 ; « Modifier » #C4A7EC | Lavande claire, 8,6:1 |
| CTA « Gérer les paiements » | **plein #B78FF8** (200,505), #B891F8 (600,530) ; libellé **#04010E** | Le CTA doux clair devient un **CTA plein lavande** en sombre (8,2:1) |
| Avatar du titulaire | fond **#C09DFA** (160,150) ; « FD » #090B17 | |
| Médaillon | fond **#2C2842** (120,420) ; anneau #B697F4 (107,437) | |
| « Modifier » | fond #1F1E30 (585,160) ; bordure #4A416F à #3B315C (571-572, y=147) | |
| Engrenage | fond #20222D (690,62) ; bordure #2E303E (700,21) | |
| Pastille verte | fond **#233938** (250,212), #1F342F (575,432) ; bordure #376D55 (330,189) ; texte **#85F2BF** et #74EDB5 ; coche #62F4AC (586,417) | 9:1 |
| Danger | texte **#F06168** ; icône #CA5C5F (400,1818) | 5,2:1 |
| Barre basse | fond **#191D26** (400,1900) ; bordure #292B37 (74,1900) ; onglet actif : soulignement **#B189ED** (648,1935), icône #BE9CF6, libellé #BEA7E7 ; inactifs : libellé #ACB3CB, icône #9FA2C4 | |
| Teintes des membres | #C3A6F5, #A5D2F7, #F5C1C4, #C3DCCB | Plus saturées qu'en clair |

**Dérivation clair vers sombre observée**, à reprendre pour le desktop sombre qui n'a pas de maquette :
- l'accent passe du violet saturé à la lavande ;
- le CTA doux devient un CTA plein lavande, avec un libellé qui reste sombre ;
- les pastilles vert pâle deviennent vert très sombre avec un texte menthe ;
- le rouge est éclairci ;
- les surfaces sont bleu-nuit, sans noir pur.

Ce n'est pas une inversion naïve.

---

## 4. Dimensions

### 4.1 Mobile (F2 et F3 identiques) : px, puis dp à 2,06, puis dp à 1,33

| Élément | px | dp @2,06 | dp @1,33 | Recommandation (tokens) |
|---|---|---|---|---|
| Marge latérale (bord de carte x=80 ; titre x=83) | 80 | 39 | 60 | L'image a des marges très larges. Retenir 20 dp, cohérent avec V1 (20-24). **Un seul alignement** : le titre est bien aligné sur les cartes ici |
| Largeur de carte (x 80-727) | 648 | 314 | 487 | Pleine largeur moins les marges |
| Espace entre cartes (360→377, 711→728, etc.) | 16-17 | 8 | 12-13 | 12 dp |
| Titre → première carte (66→99) | 33 | 16 | 25 | 16-24 dp |
| Padding intérieur (bord → médaillon x=106 ; bord → avatar y=128) | 26-29 | 13-14 | 20-22 | 16-20 dp |
| Filets inset (x 104-704) | 24 de chaque côté | 12 | 18 | Filet inset du padding de la carte |
| Hauteur d'une ligne de liste (567→636) | 69-75 | 33-36 | 52-56 | ≥ 52 dp (cible ≥ 48) |
| CTA doux (x 104-704, y 488-547) | 600 × 59 | 29 | 44 | **48 dp** |
| « Modifier » (x 571-704, y 122-171) | 133 × 49 | 24 | 37 | 40 dp visibles, **48 dp de cible** |
| Engrenage (x 674-727, y 20-71) | 53 × 51 | 26 | 39 | 40 visibles, 48 de cible |
| Avatar du titulaire (x 117-206) | 89 | 43 | 67 | 64 dp |
| Médaillon d'icône (x 106-171) | 66 | 32 | 50 | 48 dp |
| Avatars du foyer (chevauchement d'environ 8 px) | ≈ 48 | 23 | 36 | 32-36 dp, chevauchement d'environ 6 dp |
| Pastille de statut (hauteur) | 37-41 | 18-20 | 28-31 | 28 dp |
| Icônes de ligne | 25 × 28 | 12-14 | 19-21 | 20-24 dp |
| Chevrons | 10 × 18 | 5 × 9 | 8 × 14 | Icône de 16-20 dp |
| Barre basse (x 74-734, y 1860-1937) | 660 × 77 | 320 × 37 | 496 × 58 | Hauteur de 64-80 dp (M3) ; flottante ; 16 px sous la barre |
| Icône de navigation | 26 × 27 | 13 | 20 | 24 dp |
| Soulignement de l'onglet actif | 84 × 4-5 | 41 × 2 | 63 × 3 | 3 dp, arrondi |
| Rayon de carte | ≈ 20 | 10 | 15 | **16 dp** |
| Rayon du CTA doux | ≈ 10-11 | 5 | 8 | 12 dp |
| Rayon des pastilles (pas une pilule) | ≈ 10 | 5 | 7,5 | 8 dp |
| Rayon de « Modifier » | ≈ 11-12 | 6 | 8-9 | 12 dp |
| Rayon de la barre basse | ≈ 22 | 11 | 16 | 16-20 dp |

### 4.2 Desktop F1 : px, puis dp à 1,16

| Élément | px | dp |
|---|---|---|
| Rail (x 0-226, filet à x=226) | 226 de large | 195 |
| Logo (livre violet et « Rewayah ») | icône 28 × 28 à x 30-57 ; mot-symbole en capitales de 18 px | 24 dp ; 22 dp |
| Destinations du rail : pas vertical (y 118, 181, 245, 308) | 63 | 54 |
| Pilule active (x 14-212, y 282-331) | 198 × 50, rayon ≈ 12 | 171 × 43, rayon 10 |
| Zone de contenu (x 309-1581) | 1272 de large | 1096 ; rail → contenu 72 dp ; marge droite 78 dp |
| Colonne gauche (x 309-967) et droite (x 983-1581) | 658 et 598 ; gouttière de 16 | 567 et 515 ; 14 |
| Espaces verticaux entre cartes | 16-23, irréguliers | 14-20 : **à normaliser** |
| Carte d'identité (y 87-307) | 1272 × 220 | 1096 × 190 |
| Rayon de carte | ≈ 12 | 10 |
| CTA doux (x 334-942, y 422-471) | 608 × 49, rayon ≈ 6-8 | 524 × 42 : **sous 48** |
| « Modifier » (x 1407-1548, y 107-152) | 141 × 45, rayon ≈ 10 | 122 × 39 : **sous 48** |
| Engrenage (x 1533-1581, y 21-65) | 48 × 44 | 41 × 38 |
| Avatar du titulaire (x 344-433) | 89 | 77 |
| Médaillon (x 333-395) | 62 | 53 |
| Pastille « Compte vérifié » (x 470-628, y 164-198) | 158 × 35, rayon ≈ 10 | 136 × 30 |
| Hauteur d'une ligne de liste (488→548) | 60 | 52 |
| Carte « Se déconnecter » (y 893-931) | 1272 × 38 | 1096 × **33 : sous 48** |

---

## 5. Typographie observée

- **Famille apparente.** Une grotesque géométrique à `a` à deux étages, à `t` coupé en biais et à chasse assez large, proche de Plus Jakarta Sans, de DM Sans ou d'une géométrique générique. **Une image générée ne permet pas de l'identifier de façon fiable.** Une seule famille semble servir pour les titres comme pour le corps.
- **Graisses.** Titre de page Bold ou ExtraBold (700-800), approche serrée. Nom et titres de carte Bold (700). Libellé du CTA, « Modifier » et pastilles SemiBold (600). Lignes et valeurs Regular (400). Libellés de navigation Medium (500) ; l'onglet actif garde la même graisse et ne change que de couleur.
- **Tailles** (capitale en px, police ≈ capitale / 0,70, puis dp) :

| Niveau | Exemple | Mobile : capitale | Mobile : dp @1,33 (@2,06) | Desktop : capitale | Desktop : dp @1,16 |
|---|---|---|---|---|---|
| Titre de page | « Mon compte » | 25 | **27** (17) | 27 | **33** |
| Nom du titulaire | « Fatoumata Diallo » | 18 | **19-20** (12,5) | 18 | **22** |
| Titre de section (carte) | « Abonnement et accès » | 17 | **18** (12) | 15-16 | **19** |
| Corps (lignes) | « Historique et reçus » | 13 | **14** (9) | 12 | **15** |
| Secondaire | « Tuteur », « Actif jusqu'au… », valeurs à droite | 12-13 | **13-14** | 12 | **14-15** |
| Légende | « Connexion par email », « Membres, appareils… » | 11 | **12** (7,6) | 10 | **12** |
| Pastille, bouton en contour | « Compte vérifié », « Modifier » | 11 | **12** | 11-12 | **13-14** |
| Libellé de navigation | « Accueil » | 10 | **11 → 12 recommandé** | 12 (rail) | **15** |
| Initiales d'avatar | « FD » | 23 | 25 | 23 | 28 |

- **Règle écrite, qui prévaut sur l'image.** Le mandat (étape observation, point 1) impose **DM Sans** pour les titres en français : titre de page, titres de section ou de carte et autres styles de titres. Le nom du titulaire est un style de titre, donc en DM Sans, sous réserve de l'arbitrage du coordinateur. **Plus Jakarta Sans** sert pour tout le reste : lignes, valeurs, légendes, boutons, pastilles, navigation, initiales. Le BRIEF rappelle qu'aucune de ces deux familles n'est encore déclarée dans le dépôt (InstrumentSans et BricolageGrotesque aujourd'hui) : c'est une contradiction avec le mandat, à traiter par le coordinateur.
- **Apostrophe.** Droite dans les deux versions claires (« jusqu'au », F1 et F2) et typographique dans la sombre (« jusqu’au », F3). Le zoom est dans `*_zoom_apostrophe.png`. Il faut utiliser l'apostrophe typographique (’) dans l'i18n française.

---

## 6. Fiches par écran

### Fiche F1 : Mon compte · desktop · clair

- **Fichier** : `tutuor image\mon compte tuteur desktop light mode.png`, écran unique (ce n'est pas une planche).
- **Route logique (§4)** : `/tuteur/compte`. Dans le dépôt existent `/compte`, décrit comme « Portail commun aux comptes actifs » (`routes.dart:291`), ainsi que `/compte/profil` (l.294) et `/compte/reglages` (l.297). Mieux vaut un alias ou une redirection qu'une route concurrente, au choix du coordinateur.
- **État** : nominal, compte actif, accès actif, foyer de 4 membres. **Thème** : clair. **Format** : desktop, rail latéral fixe. **Statut** : nouveau high-fi.
- **Shell** :
  - Rail gauche de 226 px, blanc, séparé par un filet de 1 px.
  - En haut, logo « Rewayah » : icône livre ouvert en trait violet et mot-symbole Bold quasi-noir.
  - **4 destinations** empilées, icône en trait et libellé : Accueil (maison), Foyer (deux personnes), Historique (horloge), **Compte (actif)**. L'onglet actif a une pilule lavande #F2EBFE, une icône personne **pleine** violette et un libellé violet.
  - Ni avatar, ni déconnexion, ni aide dans le rail. Pas de barre supérieure.
- **Composition de haut en bas.**
  1. **En-tête** : « Mon compte » (x 311, y 28-63) aligné sur le bord gauche des cartes ; bouton engrenage carré (x 1533-1581) aligné sur le bord droit des cartes. L'engrenage n'a **pas de libellé**.
  2. **Carte d'identité, pleine largeur** (y 87-307) :
     - avatar d'initiales de 89 px à gauche ;
     - colonne à x=471 : nom (Bold), rôle « Tuteur » (secondaire), pastille verte « Compte vérifié » avec coche pleine ;
     - sous l'avatar, deux lignes de coordonnées avec icônes violettes en trait : téléphone, puis e-mail suivi de la légende « Connexion par email » ;
     - en haut à droite, bouton en contour violet « Modifier » avec icône crayon.
  3. **Grille à deux colonnes, disposition en maçonnerie.** La colonne gauche (658 px) est plus large que la droite (598 px), avec une gouttière de 16 px.
     - **Gauche 1, « Abonnement et accès »** (y 324-612) :
       - médaillon couronne en trait ;
       - titre et sous-titre « Actif jusqu'au 30 octobre 2026 » ;
       - pastille verte « Accès actif » alignée à droite ;
       - **CTA doux pleine largeur** « Gérer les paiements » : icône carte, libellé centré, chevron à droite ;
       - puis 2 lignes séparées par des filets : « Historique et reçus » (icône document) et « Moyen de paiement » (icône carte), chacune avec un chevron violet.
     - **Gauche 2, « Sécurité et connexion »** (y 635-883) :
       - médaillon bouclier plein ;
       - 3 lignes : « Méthode de connexion » avec la valeur à droite « Email et mot de passe » ; « Appareils connectés » avec « 2 appareils » ; « Sécurité et confidentialité ». Filets à y 764 et 821, aucun sous l'en-tête.
     - **Droite 1, « Informations personnelles »** (y 324-500) : médaillon personne pleine ; 2 lignes de résumé secondaire ; filet ; ligne « Modifier mes informations » (icône crayon).
     - **Droite 2, « Mon foyer »** (y 517-714) :
       - médaillon deux personnes pleines ;
       - 4 avatars d'initiales qui se chevauchent (FD violet, AM bleu, YA rose, SN vert) et « 4 membres liés » ;
       - légende « Membres, appareils et disponibilités » ;
       - filet ; ligne « Gérer mon foyer » (icône groupe en trait).
     - **Droite 3, « Aide et support »** (y 733-883) : médaillon « ? » plein ; lignes « Questions fréquentes » (bulle) et « Contacter Rewayah » (casque). **Ces lignes sont indentées sous le titre** (icône à x=1099 contre x≈1013 dans « Mon foyer ») : c'est incohérent avec les autres cartes.
  4. **« Se déconnecter »** : bande pleine largeur (y 893-931), libellé et icône de sortie **rouges**, centrés, dans une carte basse de 38 px. Elle est séparée des autres rubriques.
- **Densité et surfaces.** Des cartes blanches à filet, sans ombre visible, sur un fond chaud. Des lignes à chevron séparées par des filets, plutôt que des cartes imbriquées, ce qui est conforme au §9 du mandat. Un seul CTA doux (paiements) ; les autres actions sont des lignes ou le bouton en contour « Modifier ».
- **Iconographie.** Deux familles :
  - icônes en trait arrondi d'environ 2 px pour les lignes, les coordonnées, la navigation inactive, l'engrenage, le crayon et la sortie ;
  - icônes **pleines** dans les médaillons (bouclier, personne, groupe, « ? ») et pour l'onglet actif. La couronne est l'exception : elle est en trait dans son médaillon.
  Dans le dépôt, cela correspond à Phosphor Regular et Phosphor Fill.
- **Tous les textes lisibles** : « Rewayah » · « Accueil » · « Foyer » · « Historique » · « Compte » · « Mon compte » · « FD » · « Fatoumata Diallo » · « Tuteur » · « Compte vérifié » · « +33 6 12 34 56 78 » · « fatoumata@example.com » · « Connexion par email » · « Modifier » · « Abonnement et accès » · « Actif jusqu'au 30 octobre 2026 » · « Accès actif » · « Gérer les paiements » · « Historique et reçus » · « Moyen de paiement » · « Sécurité et connexion » · « Méthode de connexion » · « Email et mot de passe » · « Appareils connectés » · « 2 appareils » · « Sécurité et confidentialité » · « Informations personnelles » · « Fatoumata Diallo · +33 6 12 34 56 78 » · « France · Paris · Français » · « Modifier mes informations » · « Mon foyer » · « FD » « AM » « YA » « SN » · « 4 membres liés » · « Membres, appareils et disponibilités » · « Gérer mon foyer » · « Aide et support » · « Questions fréquentes » · « Contacter Rewayah » · « Se déconnecter ».
- **États visibles** : nominal uniquement. Les statuts sont doublés d'une icône et d'un texte (coche et libellé), donc ils ne reposent pas sur la seule couleur.

### Fiche F2 : Mon compte · mobile · clair

- **Fichier** : `tutuor image\mobile\mon compte tuteur mobile light mode.png`, écran unique en capture pleine hauteur, avec défilement.
- **Route** : `/tuteur/compte`, comme F1. **État** : nominal. **Thème** : clair. **Format** : mobile. **Statut** : nouveau high-fi.
- **Composition en une seule colonne, de haut en bas.**
  1. En-tête : « Mon compte » (x 83, y 34-66) et engrenage (x 674-727) ; pas de barre d'état.
  2. Carte d'identité (y 99-360) : avatar de 89 px ; nom, « Tuteur », pastille « Compte vérifié » à x=240 ; « Modifier » en haut à droite (x 571-704) ; téléphone, e-mail et légende « Connexion par email » sous l'avatar, texte à x=153.
  3. « Abonnement et accès » (y 377-711) : médaillon et titre ; sous-titre ; pastille « Accès actif » à droite ; CTA doux « Gérer les paiements » (y 488-547) ; filet ; « Historique et reçus » ; filet ; « Moyen de paiement ».
  4. « Sécurité et connexion » (y 728-1031) : « Méthode de connexion » avec « Email et mot de passe » ; filet ; « Appareils connectés » avec « 2 appareils » ; filet ; « Sécurité et confidentialité ».
  5. « Informations personnelles » (y 1047-1261) : résumé sur 2 lignes ; filet (y 1186) ; « Modifier mes informations ».
  6. « Mon foyer » (y 1277-1517) : avatars qui se chevauchent et « 4 membres liés » ; légende ; filet (y 1442) ; « Gérer mon foyer ».
  7. « Aide et support » (y 1533-1766) : « Questions fréquentes » ; filet (y 1692) ; « Contacter Rewayah ». Ici, les lignes sont **alignées** avec celles des autres cartes : cet alignement est à retenir.
  8. « Se déconnecter » : carte isolée (y 1783-1845), rouge, centrée.
  9. **Barre basse flottante** (x 74-734, y 1860-1937) : **4 destinations, dans l'ordre Accueil · Foyer · Historique · Compte**. L'onglet actif Compte combine une icône pleine, un libellé violet et un **trait de soulignement violet collé au bord bas** de la barre. Les onglets inactifs ont une icône en trait et un libellé gris.
- **Ordre des rubriques** : identité → abonnement et accès (avec les paiements) → sécurité → informations personnelles → foyer → aide → déconnexion. C'est conforme à l'ordre du §5 du mandat, à trois manques près : **Préférences** (seul l'engrenage existe), **Informations légales** et **« Créer mon profil élève »**.
- **Textes** : les mêmes que F1, hors rail et hors logo, plus les libellés de la barre basse « Accueil », « Foyer », « Historique », « Compte ». Aucun texte ne diffère entre F1 et F2.
- **États visibles** : nominal uniquement.

### Fiche F3 : Mon compte · mobile · sombre (fichier nommé « desktop dark »)

- **Fichier** : `tutuor image\mobile\mon compte tuteur desktop dark mode.png`. **Route** : `/tuteur/compte`. **État** : nominal. **Thème** : sombre. **Format** : **mobile**. **Statut** : nouveau high-fi.
- **Composition et textes strictement identiques à F2**, mêmes positions à ±2 px, même barre basse à 4 destinations.
- **Différences propres au thème sombre** :
  - CTA « Gérer les paiements » **plein lavande** (#B78FF8) avec libellé sombre ;
  - avatar lavande saturé ;
  - médaillons à fond violet nuit et anneau lavande ;
  - pastilles vertes sombres avec texte menthe ;
  - rouge éclairci ;
  - soulignement actif lavande.
- Apostrophe typographique « jusqu’au ».

---

## 7. Correspondance des rubriques avec l'arbre §4

| Élément de la maquette | Destination du §4 | Remarque |
|---|---|---|
| « Modifier » (carte d'identité) | `…/informations` | Même destination que « Modifier mes informations ». **Doublon** : garder un seul point d'entrée principal, ou différencier la photo et l'identité |
| Engrenage | `…/preferences` | **La rubrique Préférences n'est pas nommée.** Donner un libellé accessible, voire une ligne « Préférences » |
| « Abonnement et accès » (bloc) | `…/acces` | Bénéficiaires, accès et échéances réels |
| « Gérer les paiements » et « Historique et reçus » | `…/paiements` | Deux entrées vers la même destination : doublon |
| « Moyen de paiement » | **aucune route** | Suppose un prestataire et des moyens enregistrés : **hors contrat** (§5) |
| « Méthode de connexion », « Sécurité et confidentialité » | `…/securite` | Titre du mandat : « Connexion et sécurité » |
| « Appareils connectés » | `…/securite` (sessions) **ou** `/tuteur/foyer/appareils` | **Ambigu**, à trancher (voir le piège 6) |
| « Informations personnelles » et « Modifier mes informations » | `…/informations` | |
| « Mon foyer » et « Gérer mon foyer » | `/tuteur/foyer` (existant, `routes.dart:68`) | Raccourci vers le Foyer existant, conforme au §5 |
| « Questions fréquentes », « Contacter Rewayah » | `…/aide` | Seulement si le contenu ou le canal existe |
| « Se déconnecter » | action de déconnexion existante | Séparée, conforme au §5 |
| *(absent)* | `…/informations-legales` | **À ajouter**, en ligne sobre |
| *(absent)* | « Créer mon profil élève » (même flux que le Foyer) | **À ajouter** tant que le titulaire n'a pas de profil élève (§5 et §6) |

---

## 8. Erreurs et incohérences à NE PAS reproduire

| # | Maquette | Règle applicable | Consigne |
|---|---|---|---|
| 1 | Nom « Fatoumata Diallo », initiales FD, AM, YA, SN, « +33 6 12 34 56 78 », « fatoumata@example.com », « France · Paris · Français », « 30 octobre 2026 », « 4 membres liés », « 2 appareils » | §9 : noms, dates, capacités et métriques illustratifs ne deviennent jamais des constantes | Tout vient des données ; l'i18n interpole (`{x}`) ; chaque donnée absente a son repli |
| 2 | « Connexion par email » et « Méthode de connexion : Email et mot de passe » | §4 (sécurité : « méthodes existantes ») | L'auth réelle propose **lien magique** (`signInWithOtp`, `service_auth.dart:52`), **mot de passe** (l.56) et **Google** (l.64). Afficher la ou les méthodes réelles du compte, jamais un libellé figé |
| 3 | Pastille « Compte vérifié » | §5 : n'inventer aucune obligation ni aucun statut KYC | Ne l'afficher que si un statut serveur de vérification existe ; sinon, pas de pastille |
| 4 | « Accès actif · Actif jusqu'au 30 octobre 2026 » sous « Abonnement » | §5 : accès offert, accès daté et paiement externe ne sont pas un abonnement récurrent | Afficher le statut exact et l'échéance réelle ; ne jamais promettre un renouvellement ; prévoir les états expiré, suspendu, offert et en attente |
| 5 | CTA dominant « Gérer les paiements », plus « Historique et reçus » et « Moyen de paiement » | §5 : aucun prestataire, tarif ni faux paiement ; actions financières absentes présentées comme indisponibles. §9 : un seul CTA dominant, pas de doublons | « Moyen de paiement » : masquer, ou état indisponible propre, sauf service réel. Fusionner les deux entrées vers `…/paiements`. **Le paiement ne doit pas être le CTA dominant du compte si le service n'existe pas** |
| 6 | « Appareils connectés · 2 appareils » dans la sécurité | §4 : sessions dans `…/securite` ; appareils partagés dans `/tuteur/foyer/appareils`. §5 Foyer : les limites viennent du contrat, pas d'un « 1/2 » de capture | Choisir explicitement : les sessions de connexion du titulaire, et dans ce cas les nommer ainsi, ou un lien vers les appareils du foyer. Aucun compteur figé |
| 7 | « Membres, appareils et **disponibilités** » | §5 Foyer : les disponibilités ne réintroduisent pas le matching individuel abandonné | Retirer « disponibilités » du résumé, sauf fonction confirmée. La route `/tuteur/disponibilites` existe (`routes.dart:98`) mais relève d'un ancien modèle, à vérifier |
| 8 | « FD » (le titulaire) parmi les avatars et « 4 membres liés » | §5 Foyer : un parent sans profil élève reste titulaire, pas un élève fictif | N'afficher le titulaire comme membre que si son profil élève existe ; compter les profils réels ; initiales en repli de la photo réelle |
| 9 | Rubriques absentes : Préférences (engrenage muet), Informations légales, « Créer mon profil élève » | §5 : ordre et destinations obligatoires | Les ajouter dans le même langage : lignes sobres dans des cartes existantes ou dans une carte « Préférences et informations légales » |
| 10 | Titre « Sécurité et connexion » | §4 : « Connexion et sécurité » | Harmoniser le titre de carte et celui de la sous-page (proposé : « Connexion et sécurité ») |
| 11 | Téléphone affiché deux fois (identité et « Informations personnelles ») ; deux points d'entrée « Modifier » | §9 : pas de CTA doublons | Garder les coordonnées une seule fois ; une seule entrée de modification (ou photo et identité clairement distinctes) |
| 12 | Desktop : lignes d'« Aide et support » indentées sous le titre | Cohérence des composants (§9) | Utiliser l'alignement mobile : lignes au padding de la carte, comme les autres |
| 13 | Desktop : espaces verticaux de 16 à 23 px ; bords de libellés de lignes à +94 / +99 / +101 / +165 px du bord de carte | Tokens sémantiques (§9) | Un seul espacement entre cartes et une seule colonne de libellés |
| 14 | Cibles sous 48 dp : bande « Se déconnecter » (33 dp desktop, 30-47 dp mobile), « Modifier » (39 dp desktop), CTA doux (42 dp desktop, 29-44 dp mobile), engrenage | §9 : cibles d'au moins 48 dp | Hauteur minimale de 48 dp, quitte à garder un visuel plus fin |
| 15 | Contrastes clairs sous l'AA : légendes #7F8399 (3,7:1), texte des pastilles vertes #0B9442 (3,6:1), « Se déconnecter » #EE2B47 (4,1:1) et #FB264C (3,8:1), secondaire #74778E (4,4:1) | §9 : contraste | Assombrir les tokens texte : secondaire ≥ 4,5:1, vert de texte vers #067A36, rouge vers #D11A3A ou équivalent. Le sombre est conforme |
| 16 | Accent et fond **différents de V1 Accueil** : V1 accent #AC88F7 sur fond froid #F6F6F8 ; Compte accent #6A28FC à #7446E6 sur fond chaud #FCFBF9 | §9 : tokens uniques | Le coordinateur fixe un seul jeu. Proposition : violet saturé (≈ #6D35F0) pour le texte et les icônes, lavande (#E2CFFE) pour les fonds doux, un seul fond de page |
| 17 | Navigation : **ces maquettes mobiles montrent 4 onglets**, alors que la maquette mobile Accueil (V1) en montre 3 | §4 : Accueil · Foyer · Historique · Compte, partout | **Ces maquettes confirment le shell à 4 destinations.** La version à 3 onglets est l'écart à corriger. Le BRIEF (« maquette mobile high-fi montre 3 onglets ») doit préciser qu'il s'agit de l'Accueil |
| 18 | Fichier « desktop dark » qui est un mobile sombre ; aucun desktop sombre | §2 : manifeste exact | Renommer au manifeste ; dériver le desktop sombre avec les règles du §3.2 et le documenter |
| 19 | Apostrophe droite (clair) contre typographique (sombre) | Qualité i18n | ’ partout |
| 20 | Desktop : contenu étiré sur 1096 dp | §9 : largeur de lecture raisonnable | Largeur maximale de contenu (par exemple 960-1040 dp), grille 2 colonnes conservée ; **ordre de focus et de lecture d'écran = ordre du §5** et non l'ordre visuel de la maçonnerie |
| 21 | « Contacter Rewayah » et « Questions fréquentes » | §4 : « contact disponible, suivi si existant » | N'activer que les canaux et contenus réels ; sinon, état indisponible explicite |
| 22 | Aucun état de chargement, d'erreur, hors ligne ou de session expirée | §8 | Dériver : squelette des cartes, erreur de bloc (une carte en erreur, le reste reste lisible), erreur globale |
| 23 | Rôle « Tuteur » sous le nom | §5 : le compte concerne le titulaire, qui peut aussi être élève | Rôle issu des données et de l'i18n existante ; si le titulaire a aussi un profil élève, ne pas écrire « élève » sur le compte |

Aucune occurrence de « Cours en cours », « Session », « Ajouter enfant », « réseau Bon » ou « mode enfant » dans ces trois maquettes.

---

## 9. Tokens proposés à partir de V3, à consolider avec V1 et V2 par le coordinateur

| Token | Clair | Sombre | Source |
|---|---|---|---|
| `bg.page` | #FBFAF9 (chaud) *ou* #F6F6F8 (V1) : **à arbitrer** | #171923 | F1, F2 et F3 ; V1 |
| `bg.rail` | #FEFEFD, filet #EEEFF0 | à dériver : #191C26, filet #282B38 | F1 |
| `surface.card` | #FEFEFE | #1B1D28 | F1, F2, F3 |
| `border.card` | #EDEEEF | #2A2D3A | idem |
| `divider` | #EFF0F3 | #2B2E3C | idem |
| `text.primary` | ≈ #0C0F1F | #FFFFFF, corps #F4F5F7 | idem |
| `text.secondary` | #6E7491, à foncer légèrement pour 4,5:1 | #B3B5D7 | idem |
| `text.caption` | #737895 (valeur desktop), à foncer vers #6A6F8A | #999CB8 | idem |
| `accent` (texte et icônes) | ≈ #6D35F0 (desktop #6A28FC, mobile #7043E6) | #CBABFD | idem |
| `accent.container` (CTA doux, avatar) | #E4D1FE | CTA **plein** #B78FF8 ; avatar #C09DFA | idem |
| `on.accent.container` | #040315 | #04010E | idem |
| `nav.active.container` (rail) | #F2EBFE | à dériver : #2C2842 | F1 ; médaillon sombre F3 |
| `medallion` | fond #F7F1FE, anneau #9974EF | fond #2C2842, anneau #B697F4 | F1, F2, F3 |
| `success.container`, `.border`, `.on` | #E1FCEA, #A3E8BF, #0B9442 (à foncer) | #233938, #376D55, #85F2BF | idem |
| `danger` (texte d'action) | #EE2B47 (à foncer pour l'AA) | #F06168 | idem |
| Teintes d'avatars de membres | #E9D8FE, #CBE9FE, #FED9D8, #DFF4DD | #C3A6F5, #A5D2F7, #F5C1C4, #C3DCCB | Attribution stable par profil, sans signification |
| Rayons | carte 16 ; CTA et boutons 12 ; pastille 8 ; barre basse 16-20 ; rail actif 12 | idem | §4 |
| Espacements | marge mobile 20 ; padding de carte 16-20 ; entre cartes 12 ; ligne ≥ 52 | idem | §4 |
| Typographie | titres en DM Sans (page 28, section 18, nom 20, Bold) ; le reste en Plus Jakarta Sans (corps 14-15, secondaire 13-14, légende 12, navigation 12 Medium, boutons 14 SemiBold) | idem | Règle écrite du mandat, avec les proportions de l'image |

---

## 10. Tuiles et fichiers produits

`D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V3_compte\` :
- `D_01` à `D_07` : desktop F1, soit rail, identité, zone en haut à droite, abonnement, sécurité, informations et foyer, aide et déconnexion ;
- `ML_01` à `ML_05` : mobile clair F2 ;
- `MD_01` à `MD_05` : mobile sombre F3 ;
- zooms : `ML_zoom_typo_titre`, `ML_zoom_typo_corps`, `ML_zoom_nav`, `ML_zoom_apostrophe`, `MD_zoom_apostrophe`, `D_zoom_apostrophe`.
