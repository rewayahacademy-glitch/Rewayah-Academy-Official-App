# V9 - Anciennes captures Tuteur mobile (relevé visuel)

Date : 24/09/2026. Agent : relevé visuel V9, lecture seule (aucun fichier du dépôt modifié).
Sources lues : `pilotage-tuteur-v1/BRIEF.md` ; mandat `REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` en entier (§2 références visuelles, §4 arbre, §5, §6, §7, §8, §9 et « Prompt étape observation tuteur ») ; à titre de comparaison seulement, les tokens mesurés par `V1_accueil_mobile.md`, `V2_accueil_desktop.md` et `V3_compte.md`.

Statut des cinq fichiers : **ancienne capture** (mandat §2 : « ne deviennent pas automatiquement les nouvelles références approuvées »). Rang 6 dans l'ordre d'arbitrage du mandat. Elles restent la **seule référence de contenu** pour Foyer, Historique, Classe et la Fiche élève. Elles ne font pas foi pour le rendu (le high-fi « accueil tuteur mobile light mode » remplace `Accueil.png`).

## 0. Méthode et preuves d'ouverture

- Les 5 images ont été ouvertes entières avec l'outil Read (affichage 908×2000, facteur 1,28 vers l'original), puis découpées en 4 tuiles pleine résolution chacune (y 0-700, 620-1320, 1240-1940, 1859-2559) et relues : `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V9\{accueil,foyer,historique,classe,profil}_{1..4}.png`.
- Des agrandissements ×2 ou ×3 (plus proche voisin) ont servi à identifier les polices et à lever les doutes de lecture : `tuiles\V9\zoom_*.png` (en-tête de carte Accueil, titre Foyer, ligne Foyer, ligne Historique, ligne Profil, planning Classe, « Aîcha », CTA Accueil).
- Couleurs : `System.Drawing.Bitmap.GetPixel` sur l'original 1162×2559. Coordonnées **en pixels de l'original**. « Noyau » = pixel le plus clair ou le plus saturé d'une zone de texte ou d'icône (encre sans anticrénelage).
- Géométrie : balayages horizontaux et verticaux des transitions de couleur (seuil 4 à 25) ; rayons estimés par la diagonale depuis le coin (r ≈ t / 0,293) et par l'écart à la première ligne.
- Tailles de texte : hauteur de capitale mesurée en pixels ; taille de police ≈ capitale / 0,70 (proportion des grotesques géométriques de type DM Sans).

### Échelle : deux lectures possibles, à ne pas confondre

Les cinq fichiers font **1162×2559 px**.

| Lecture | Facteur | Justification | Conséquence |
|---|---|---|---|
| Consigne du coordinateur : mobile de 390 dp | **÷ 2,98** | 1162 / 390 | Corps de texte à 8-10 dp, titres de page à 17-20 dp : **illisible si transposé tel quel**, CTA de 33 dp sous la cible de 48 dp |
| Canevas natif probable | **÷ 2** | L'heure « 9:41 » a des chiffres de 24 px de haut, soit une police de 34 px. À ÷2, cela donne **17 pt, la taille exacte de l'horloge iOS**. Le cadre ferait 581×1280 pt, exporté en @2x | Titres de page à 25-29 pt, corps à 12-16 pt, CTA à 49 pt : une échelle iOS plausible |

Les deux colonnes sont données ci-dessous. **Recommandation** : ne pas transposer les valeurs absolues de ces captures. Garder leurs **proportions et leur hiérarchie**, et prendre les tailles dans l'échelle typographique et les tokens des nouveaux high-fi (V1 à V3).

## 1. Manifeste

| Fichier | Écran représenté | Route logique probable (§4) | État | Thème | Format | Statut |
|---|---|---|---|---|---|---|
| `tutuor image\mobile\Accueil.png` | Accueil du tuteur | `/tuteur/accueil` | Nominal, jour J, salle ouverte à T-13 min, blocage « aucun appareil prêt », 4 profils plus ajout | Sombre | Mobile portrait | Ancienne capture, **remplacée** par le high-fi clair `accueil  tuteur mobile light mode.png` (même contenu, voir V1) |
| `tutuor image\mobile\Foyer Member.png` | Foyer : membres, appareil partagé, actions | `/tuteur/foyer` | Nominal : 3 enfants, 1 appareil partagé, « 2 alertes », 1 dossier « Diagnostic à terminer » | Sombre | Mobile portrait | Ancienne capture, **seule référence de contenu** du Foyer |
| `tutuor image\mobile\Historique.png` | Historique des séances d'un élève | `/tuteur/historique` (liste ; le détail `/tuteur/seances/:seanceId` est derrière les chevrons) | Nominal : Mariam sélectionnée, filtres au repos, 4 séances (présente, retard, absente, présente) | Sombre | Mobile portrait | Ancienne capture, seule référence mobile de l'Historique |
| `tutuor image\mobile\Classe Details.png` | Détail de classe vu par le tuteur | `/tuteur/classes/:classeId` (entrée vers `.../observer`, `.../planning`, `.../travail`) | Prochaine séance, salle ouverte à T-13 min, CTA d'observation | Sombre | Mobile portrait | Ancienne capture, seule référence mobile de la Classe |
| `tutuor image\mobile\Profil.png` | **Fiche d'une élève (Mariam)**, pas le compte du tuteur | `/tuteur/foyer/:eleveId`, avec les lignes vers `.../inscription` (Classe), `.../interface`, `.../camera`, `.../acces`, `.../appareils` | Nominal, appareil actuel plus iPad dont le retrait est bloqué « pendant la séance » | Sombre | Mobile portrait | Ancienne capture. **Le nom de fichier est trompeur** (§2) et l'onglet actif affiché est faux (Compte) |

Aucune planche multi-écrans : chaque fichier contient un seul écran, sans zone à découper.

## 2. Tokens mesurés (thème sombre des anciennes captures)

### 2.1 Surfaces et texte

| Rôle | HEX mesuré | Coordonnées (px originaux) | Remarque |
|---|---|---|---|
| Fond de page | **#292530** | Accueil (15,700), (15,1500), (580,1440) ; Foyer, Classe, Profil (20,1000) ; Historique (20,1000), (580,2000) | Identique sur les 5 captures. Violet-gris chaud, nettement plus clair que le fond sombre du nouveau high-fi (#171923, V3) |
| Surface de carte | **#33303A** | Accueil (1050,1300), (100,1400) ; Foyer (1000,760), carte de stat (300,420) ; Classe (1070,500) ; Profil (1000,300) | Pas de bordure (Accueil, Foyer, Classe, Profil) |
| Carte liste Historique | #302C38 ; bordure 1 px ≈ #373341 / #363241 | (90,1000), (1080,1500) ; bord x=72 à y=1000, y=770-772 à x=1085 | **Autre surface** que #33303A, et bordée : incohérence entre écrans |
| Surface imbriquée (bloc séance) | **#3D3848** | Accueil (1000,1150), (130,1200) ; Classe (1030,1000) | Bloc dans la carte, sans bordure |
| Encart d'info imbriqué (Foyer) | #3D3A43 | (1000,1960) ; bornes y 1913-2008 | Autre teinte pour le même rôle |
| Conteneur des filtres (Historique) | fond #2F2B37, bordure #363340 | (85,600) ; y=504 à x=250 | Conteneur bordé autour de puces elles aussi bordées (surfaces empilées) |
| Puce de filtre | fond #302C39, bordure #413C50 | (200,560) ; y=538 à x=250 | Forme pilule |
| Filets de séparation | #45434B (planning Classe, (300,1489)) ; #423F48 (actions Foyer, (500,2296)) ; #3A3443 (Historique, (600,904)) ; **≈#2B2A36, plus sombre que la carte** (Profil, (600,807)) | | 4 valeurs, et des filets clairs ou sombres selon l'écran |
| Texte principal | **#FFFFFF** | noyaux « Accueil » (88-272,132-170), « Foyer », « Historique », « Classe An-Nour », « Mariam » | 14,98:1 sur le fond, 12,93:1 sur la carte |
| Texte secondaire | **#C2C1C4** (Foyer « 8 ans », « Accès normal », « 1 appareil associé ») ; #D8D8D8 (Accueil « Règles de lecture », « Votre heure ») ; #D6D5D7 (Profil valeurs de ligne) ; #B6B5B8 (Historique heure et enseignant) | | **4 gris pour un même rôle**. 6,7 à 9,1:1 |
| Sous-titre sous le titre de page | #949298 | Foyer « Membres du foyer » (59-315,196-217) ; Classe « Mariam · Sayyida Amina » | 4,87:1 sur le fond, juste au-dessus de AA |

### 2.2 Accent, CTA, statuts

| Rôle | HEX mesuré | Coordonnées | Remarque |
|---|---|---|---|
| CTA plein lavande | **#C2A5F9** (Accueil) ; #C4A8F6 (Classe) ; **#C09FFF** (Foyer, Profil) | Accueil (200,1325), (1000,1300) ; Classe (160,1155) ; Foyer (760,165) ; Profil (200,1850) | Libellé noir #000000 : 10,0:1. Le nouveau high-fi sombre (V3) utilise #B78FF8 |
| Accent icônes et traits | #AC84F7 (livre Accueil) ; #AB85F3 (planning Classe) ; #BA91FD (icônes de ligne Profil) ; #AE87F6 (lien Foyer) ; #B491FA (icône stat Foyer) | noyaux saturés des icônes | Icônes au trait, sans remplissage, sauf la navigation |
| Anneau du profil sélectionné | #B689F8 | Accueil (92-110,230-300) | Trait d'environ 5-6 px |
| Point de notification | #B28DF9 | Accueil (1065-1085,120-140) | Sur la cloche |
| Lien texte (« Changer la photo ») | #C088FF | Profil (807-1049,362-390) | 5,94:1 sur la carte |
| CTA tonal « Gérer » | fond #3B3848, bordure #403C4F, chevron #C09EFB | Foyer (900,837), x=894 à y=837 | Bouton secondaire bordé |
| Statut vert (point) | **#6EEAAB** (avatar Mariam) ; #6FEFAA (Salle ouverte) ; #62F0A2 (Actif) ; #69F0AF (Présente) ; #66F3A2 (Profil) | Accueil (200-216,312-328), (780-805,805-830) ; Foyer (922-942,650-670) ; Historique (820-840,805-830) ; Profil (240-270,1530-1555) | Un seul rôle, cinq valeurs proches |
| Pastille verte : fond | #384C4B (Salle ouverte) ; #304B41 (Actif) ; #2A4338 (Présente, Accueil) ; #304343 (Présente, Historique) ; **#1C372E** (Appareil actuel) ; #38504C (Salle ouverte, Classe) | Accueil (975,818), (1010,2195) ; Foyer (1025,660) ; Historique (980,815) ; Profil (1060,1515) ; Classe (990,631) | Texte blanc, 9,1 à 12,8:1. **Six fonds verts** |
| Statut orange (point) | **#F6B51B** (Yusuf) ; #FFC131 (Diagnostic) ; #FAC312 (Retard) | Accueil (410-426,309-325) ; Foyer (805-825,1325-1345) ; Historique (790-810,1085-1110) | |
| Pastille orange : fond | #564935 (Diagnostic) ; #493F32 (Retard) | Foyer (1050,1335) ; Historique (990,1098) | |
| Statut rouge (point) | **#ED4660** (Adam) ; #FA4759 (Absente) | Accueil (838-854,310-326) ; Historique (832-852,1363-1385) | |
| Pastille rouge : fond | #4B2D39 | Historique (985,1375) | |
| Statut gris (point) | **#8E8BA6** | Accueil (629,320), Aîcha | Sens non expliqué (« Dernière séance 1 h ») |
| « En séance » sous l'avatar | **#00C4CC** (sarcelle, Accueil) ; **#7ED957** (vert, Historique) | Accueil (105-215,385-408) ; Historique (98-210,405-430) | Même libellé, **deux couleurs** et deux teintes différentes du point vert |
| Bandeau d'alerte (blocage) | fond **#503B28**, icône #FCD46F, titre #FFFFFF, corps #DFCDB1 (6,76:1), bouton fond #704D22 et libellé #FFFFFF (7,57:1) | Accueil (400,1610), (115-165,1520-1575), (197-750,1508-1580), (845,1575) | Brun chaud opaque, sans bordure |
| Bandeau d'information (PIN) | fond #453B33, titre #E5B549 (5,73:1), corps #D9D7D6, bouclier #FBD36D dans un cercle #3D3118 | Profil (600,2150), (260-530,2050-2080), (150-200,2060-2110), (132,2084) | Deuxième brun, pour un message d'information et non de blocage |
| Wi-Fi « Bon » | icône #00FCA0 (Accueil) / #71F3B3 (Historique), texte « Bon » #7ED957 (7,74:1) | Accueil (128-172,2255-2295) ; Historique (110-160,940-975), (186-231,967-992) | |
| Wi-Fi « Moyen » | icône #FCE056, texte #FFDE59 | Historique (640-690,1215-1250), (717-795,1245-1270) | |
| Wi-Fi « Faible » | icône #FB4A62, texte **#FF5757 (4,38:1, sous AA)** | Historique (640-690,1495-1530), (717-790,1522-1545) | |

### 2.3 Navigation et avatars

| Rôle | HEX mesuré | Coordonnées | Remarque |
|---|---|---|---|
| Barre de navigation | **#5D5D5D**, gris neutre sans teinte | Accueil (300,2380), (600,2460) ; Foyer (300,2440) ; Historique et Profil y 2339-2452 | Détonne avec les surfaces violacées. Pas de bordure |
| Onglet actif | icône et libellé #CBB0FF / #CAAFFE (Accueil) ; **#B081E5** (Foyer, Classe) ; #C088FF (Historique) ; #AE80E1 (Profil) | Accueil (205-250,2375-2420) ; Foyer (380-475,2425-2520) ; Historique (637-777,2340-2430) ; Profil (955-1025,2345-2405) | Quatre violets. **#B081E5 sur #5D5D5D = 2,23:1** (échec). Pas de pastille derrière l'onglet actif |
| Onglets inactifs | icône #B1B0B0, libellé #C1C1C1 / #C4C4C4 (3,66:1, échec AA) ; « Accueil » inactif en gras #D8D8D8 (4,62:1) | Accueil (540-610,2375-2465) ; Foyer (127-205,2488-2508), (652-760,2485-2505) | L'onglet Accueil inactif garde un style gras que n'ont pas les autres |
| Silhouette par défaut (sélecteur) | figure #77728C sur un cercle plus sombre | Accueil (160,300) | Pas de photo, silhouette générique |
| Bouton « + » (Ajouter enfant) | cercle #302C39, « + » ≈ #9D9BBF | Accueil (990,250) ; y 217-335 à x=1012 | |
| Monogramme de carte (Accueil, Classe) | cercle #514D69 bordé, lettre #C09FFF | Accueil (125,600), (160-205,580-625) | |
| Monogramme de ligne (Foyer, Profil) | cercle **#858389 gris neutre**, lettre #C2C1C1 | Foyer (120,700) ; Profil (130,420) | **Deuxième style d'avatar de repli**, incohérent avec le premier |
| « Ruban » coloré derrière l'avatar | menthe #D4FAE9, rose #F29DF1, lavande #C09FFF | Foyer (150,600), (150,940), (150,1280) ; Profil (180,270) | Rectangle opaque qui dépasse du haut de la carte. Code couleur par enfant sans légende, probable artefact de génération |

## 3. Géométrie (px → dp à 390 dp de large (÷ 2,98) → pt natifs probables (÷ 2))

| Élément | px | dp @390 | pt @2x | Source de la mesure |
|---|---|---|---|---|
| Marge latérale des cartes | 72 (Accueil), 71 (Historique), 74 (Classe), **57-58 (Foyer, Profil)** ; à droite : 81 (Accueil), 68 (Historique), 74 (Classe), 57 (Foyer, Profil) | 24 / 24 / 25 / **19** | 36 / 35 / 37 / **29** | Balayages en x : Accueil y=1400 (72→1081), Foyer y=760 (57→1104), Historique y=1000 (71→1093), Classe y=1000 (74→1087), Profil y=300 (57→1104). **Marges incohérentes, et asymétriques sur l'Accueil** |
| Alignement du titre de page | x=88 (Accueil), 60 (Foyer), 82 (Historique), 108 après le chevron retour (Classe, Profil) | 29,5 / 20 / 27,5 / 36 | 44 / 30 / 41 / 54 | Encre des titres |
| Rayon de carte | 24-27 | **8-9** | 12-13,5 | Accueil (72,502), Foyer (58,591), Profil (58,252) ; carte liste Historique **38 px ≈ 12,6 dp** |
| Rayon du bloc imbriqué | ≈27 | 9 | 13,5 | Accueil (110,746) |
| CTA principal « Voir la classe » / « Observer la session » | h **98-99**, l 925, r ≈31 | **h 33**, l 310, r 10 | **h 49**, r 15,5 | Accueil x 114-1039, y 1274-1372 ; Classe y 1107-1206 |
| CTA pilule « Ajouter un enfant » (en-tête Foyer) | h 82, l 365, pilule complète | h 27,5 | h 41 | Foyer x 740-1104, y 125-206 |
| CTA pilule « Connecter un appareil » (Profil) | h 82, l 956 | h 27,5 | h 41 | Profil x 103-1058, y 1811-1892. **Deux formes de CTA principal** (rectangle arrondi et pilule) |
| Bouton du bandeau « Connecter un appareil » | h 79, l 210, r ≈20 | 26,5 / 70 / 7 | 39,5 / 105 / 10 | Accueil x 827-1037, y 1507-1586 |
| Bouton « Gérer » | h 75, l 168 | 25 / 56 | 37,5 / 84 | Foyer x 893-1060, y 800-874 |
| Bouton « Retirer » (désactivé) | h 74, l 281, r ≈31 | 25 / 94 / 10 | 37 / 140 / 15,5 | Profil x 793-1073, y 1616-1689 |
| Pastilles de statut | « Salle ouverte » 55 ; « Actif » 48 ; « Diagnostic à terminer » 47 ; « Présente » (Historique) 61 ; « Appareil actuel » 60 ; « Présente » (Accueil) ≈42 | 18,5 / 16 / 16 / 20,5 / 20 / 14 | 27,5 / 24 / 23,5 / 30,5 / 30 / 21 | Pilules complètes. **Six hauteurs pour un même composant** |
| Avatar du sélecteur (anneau compris) | 125-131 ; « + » 118 ; point de statut ≈16-18 avec liseré sombre | 42-44 ; 40 ; ≈6 | 63-65 ; 59 ; ≈8,5 | Accueil y 207-338 à x=160, x 311-436 |
| Monogramme de carte Accueil / Classe | 140 | 47 | 70 | Accueil x 111-251 à y=600 |
| Avatar de ligne Foyer | 116 | 39 | 58 | Foyer x 97-213 à y=680 |
| Avatar d'en-tête de la fiche | 173 | 58 | 86,5 | Profil x 101-274 à y=400 |
| Cartes de compteurs Foyer | h 137 ; largeurs 313, 372, 293 | h 46 | h 68,5 | Foyer y 303-440 ; x 57-370, 405-776, 811-1104. Largeurs inégales |
| Barre de navigation | h **131** (Accueil), **112-113** (Foyer, Historique, Profil) ; marges x 38 ; pilule complète ; bas de l'écran à 85-107 px | 44 / 38 ; marges 13 | 65,5 / 56 ; marges 19 | Accueil y 2343-2474 ; Foyer y 2411-2523 ; Historique et Profil y 2339-2452. **Hauteur et position varient d'un écran à l'autre** |
| Icône d'onglet | ≈46×50 | 15,5×17 | 23×25 | Accueil, maison active |
| Espacement entre sections | Accueil 50-62 ; Foyer : en-tête→compteurs 97, compteurs→« Enfants » 88, **entre cartes enfant 16**, cartes→« Appareil familial » 86 ; Classe 79-92 ; Profil 61-70 | 17-21 ; 32,5 / 29,5 / **5,4** / 29 ; 26,5-31 ; 20,5-23,5 | 25-31 ; 48,5 / 44 / **8** / 43 ; 39,5-46 ; 30,5-35 | Balayages verticaux x=1060 (Accueil), 1000 (Foyer), 1070 (Classe), 1090 (Profil) |
| Hauteur d'une ligne de réglage (fiche) | 135 | 45 | 67,5 | Filets de Profil à y 807, 942, 1078 |
| Pas des lignes de tâches / du planning | ≈73 / 79 | 24,5 / 26,5 | 36,5 / 39,5 | Accueil y 1819, 1892, 1966 ; Classe filets à 1489, 1568, 1647 |
| Bloc d'une séance dans l'Historique | ≈288 (ligne principale plus ligne réseau) | 97 | 144 | Historique, dates à y 805 et 1093 |
| Puces de filtre Historique | h 96, l ≈322-340 ; conteneur y 504-662 | 32 | 48 | Historique y 537-633 à x=250 |

## 4. Typographie observée

**Familles** (agrandissements `zoom_*.png`) :
- Accueil, Classe, l'en-tête de Profil et les libellés de navigation : grotesque géométrique au « a » à deux étages, au « y » à jambage droit et au « M » large, **très proche de DM Sans**, utilisée **pour tout le texte**, corps compris. Graisses : Bold ou SemiBold pour les titres, Regular pour le corps.
- Foyer, et les lignes de réglage de Profil (« Classe », « Interface guidée ») : autre grotesque, plus étroite, aux terminaisons droites, **proche de Manrope ou de Plus Jakarta Sans**. Identification impossible avec certitude sur une image.
- Historique : **police arrondie proche de Quicksand** (terminaisons rondes, « y » de « Sayda » à queue courbe, « 1 » caractéristique) pour le titre, les dates, les classes et les puces.
- La navigation mélange elle-même les familles : le libellé « Foyer » actif est plus grand et dans une autre police que « Historique ».

**Règle écrite qui prévaut** (complément observation §1) : **DM Sans pour les titres en français, Plus Jakarta Sans pour tout le reste** (paragraphes, libellés, boutons, champs, navigation, légendes, statuts). Aucune des cinq captures ne la respecte : trois familles s'y mélangent et DM Sans y sert aussi au corps. Rappel du BRIEF : le dépôt ne déclare aujourd'hui ni DM Sans ni Jakarta (InstrumentSans et BricolageGrotesque), contradiction déjà consignée par le coordinateur.

**Tailles relevées** (hauteur de capitale → police ≈ capitale / 0,70) :

| Niveau | Exemples | Capitale (px) | dp @390 | pt @2x |
|---|---|---|---|---|
| Horloge de la barre d'état | « 9:41 » | 24 | 11,5 | **17** (horloge iOS) |
| Titre de page | « Accueil » 37 ; « Foyer » 35 ; « Historique » 41 ; « Classe An-Nour » ≈35-37 ; « Mariam » (fiche) 41 | 35-41 | **17-20** | **25-29** |
| Nom dans une carte | « Mariam » (Accueil) 31 ; « Salam » 33 ; « Mariam » (fiche) 31 | 31-33 | 15-16 | 22-23,5 |
| Titre de section (sous-page) | « Enfants », « Appareil familial », « Actions utiles » 30 ; « Paramètres de l'enfant » 29 | 29-30 | 14-14,5 | 21 |
| Titre de carte | « Session dans 13 min » 27 ; « Appareils » 27 ; « Prochaine séance » 25 ; « Lundi 21 septembre » 25 ; « Planning habituel » 23 ; « Avant / Après la séance » 21 ; « Dernière séance » 21 | 21-27 | 10-13 | 15-19 |
| Sous-titre de carte | « Classe An-Nour » (Accueil) 24 ; « Sayyida Amina » 23 | 23-24 | 11-11,5 | 16,5-17 |
| Corps | libellé de ligne (fiche) 22 ; date Historique 22 ; valeur de ligne 21 ; « Classe Al-Fajr » 20 ; « Tablette ou ordinateur… » 19 ; « Réviser pages 24 à 26 » 17 | 17-22 | **8-10,5** | 12-15,5 |
| Légende | « Réseau élève » 16 ; « Session 18:00 » 16 ; « Dans le foyer » 16 ; « Voir tout » 16 ; « Règles de lecture » 15 ; libellés de navigation ≈17 | 15-17 | **7-8** | 10,5-12 |
| Libellé de CTA | « Ajouter un enfant » 28 ; « Observer la session » 25 ; « Voir la classe » 23 ; « Connecter un appareil » (fiche) 22 | 22-28 | 10,5-13,5 | 16-20 |

Constats : la hiérarchie n'est pas stable. Le titre de page va de 35 à 41 px de capitale selon l'écran. Le nom dans la carte d'Accueil est presque aussi grand que le titre de page. Les titres de section de l'Accueil (21 px) sont plus petits que ceux du Foyer (30 px). À 390 dp, corps et légendes tomberaient sous 11 dp : les tailles viennent de l'échelle typographique des tokens, pas de ces captures.

## 5. Fiches par écran

### 5.1 `Accueil.png` : Accueil du tuteur (ancienne capture, remplacée par le high-fi clair)

**Composition de haut en bas** (colonne unique, marges 72 / 81 px) :
1. Barre d'état « 9:41 ».
2. En-tête : titre « Accueil » à gauche (x 88) ; cloche au trait à droite (1029-1086, 119-176) avec un point lavande.
3. Sélecteur horizontal de profils : 4 avatars à silhouette grise, chacun avec un point de statut en bas à droite ; l'avatar sélectionné a un anneau lavande. Prénom en gras dessous, puis une ligne d'état. En dernier, un cercle « + » « Ajouter enfant ». Les prénoms et états sont centrés sous chaque avatar.
4. **Carte principale** (#33303A, y 502-1417) :
   - En-tête : monogramme « M » (cercle #514D69, lettre lavande), empilement « Mariam » (gras, grand) / « Classe An-Nour » (gras) / « Sayyida Amina » (regular, gris clair) / « Règles de lecture • Niveau 1 » (légende). En haut à droite, lien discret « fournir une photo » avec une icône d'appareil photo.
   - **Bloc imbriqué** (#3D3848, y 746-1222) : « Lundi 21 septembre » (gras) et pastille « Salle ouverte » (point vert) sur la même ligne. En dessous, deux colonnes séparées par un filet vertical : « Votre heure / 13:45 Paris » et « Durée / 1 h 30 ». Puis une ligne avec une horloge au trait et « Session dans 13 min » (gras). Puis une icône d'écran et de téléphone avec « Tablette ou ordinateur conseillé. Téléphone accepté. ».
   - CTA plein lavande pleine largeur « Voir la classe → » (y 1274-1372). **Artefact** : un texte fantôme effacé apparaît derrière le libellé (`zoom_accueil_cta.png`).
5. **Bandeau de blocage** (brun #503B28, y 1467-1626) : icône « ! » cerclée jaune, titre « Aucun appareil prêt pour Mariam », corps « Connectez un appareil pour éviter tout problème. », bouton tonal brun « Connecter un appareil » à droite, sur deux lignes.
6. **Carte « Avant / Après la séance »** (y 1686-2027) : icône de livre lavande, titre, lien « Voir tout → » à droite. Trois lignes avec une case ronde vide et un filet dessous.
7. **Carte « Dernière séance »** (à partir de y 2089, coupée par la navigation) : icône d'histogramme, titre, « Jeudi 18 septembre • 1 h 30 ». À droite, « Voir l'historique → » et une pastille « Présente ». Dessous, une ligne en deux colonnes, Wi-Fi vert « Réseau élève / Bon » et Wi-Fi vert « Réseau enseignant / Bon ».
8. **Navigation flottante à 3 onglets** : Accueil (actif : icône maison pleine lavande et libellé gras lavande), Foyer, Compte. **Pas d'Historique.**

**Textes lisibles** (exacts) : « 9:41 » · « Accueil » · « Mariam » « En séance » · « Yusuf » « Session 18:00 » · « Aîcha » « Dernière séance 1 h » · « Adam » « Absente » · « Ajouter enfant » · « M » · « Mariam » · « Classe An-Nour » · « Sayyida Amina » · « Règles de lecture • Niveau 1 » · « fournir une photo » · « Lundi 21 septembre » · « Salle ouverte » · « Votre heure » · « 13:45 Paris » · « Durée » · « 1 h 30 » · « Session dans 13 min » · « Tablette ou ordinateur conseillé. Téléphone accepté. » · « Voir la classe » · « Aucun appareil prêt pour Mariam » · « Connectez un appareil pour éviter tout problème. » · « Connecter un appareil » · « Avant / Après la séance » · « Voir tout » · « Réviser pages 24 à 26 » · « Écouter la récitation » · « Mémoriser la partie Hifz » · « Dernière séance » · « Jeudi 18 septembre • 1 h 30 » · « Voir l'historique » · « Présente » · « Réseau élève » « Bon » · « Réseau enseignant » « Bon » · « Accueil » « Foyer » « Compte ».

**Contenu utile** : l'ordre de lecture est déjà celui du §5 (sélecteur, prochaine séance, blocage, préparation, dernière séance). Heure locale avec ville de fuseau, durée, recommandation d'appareil. Le high-fi clair V1 reprend exactement cette structure : c'est lui qui fait foi pour le rendu.

**À ne pas reproduire** :
- « Ajouter enfant » → « Ajouter un profil élève » (§4, §5). Le profil du parent ne s'appelle pas « enfant ».
- « Session 18:00 », « Session dans 13 min » → vocabulaire **Séance / Cours** (§5 : « Cours dans 3 h 28 »).
- Contradiction temporelle dans le même écran : Mariam est « En séance » dans le sélecteur, mais sa carte annonce le début dans 13 min.
- « Adam » « Absente » : faute d'accord, et une absence ne se déduit pas d'une déconnexion (§5). Le statut est porté par un point de couleur, que le texte doit accompagner (§9).
- « Aîcha » avec un accent circonflexe (`zoom_accueil_aicha.png`) : coquille pour « Aïcha ». « Dernière séance 1 h » est ambigu (il y a 1 h ? durée 1 h ?).
- Dates incohérentes : le lundi 21 septembre existe en 2026, mais le 18 septembre 2026 est un **vendredi**, pas un jeudi. En 2025, le 18 est bien un jeudi, mais le 21 est un dimanche. Aucune année ne rend l'écran cohérent. De plus, le jeudi ne figure pas dans le planning Lundi, Mercredi, Samedi de `Classe Details.png`.
- « Réseau élève / Bon » et « Réseau enseignant / Bon » : à n'afficher que sur une mesure réelle (§5) ; la qualité réseau de l'enseignant n'a pas à être exposée au tuteur (§5 détail : pas de télémétrie brute).
- Deux actions de blocage concurrentes (« fournir une photo » et « Aucun appareil prêt ») : le §5 demande une action unique contextualisée, affichée seulement si les données la confirment.
- « Avant / Après la séance » → « Avant le prochain cours », trois actions au plus et un lien vers le travail complet (§5). « Hifz » : terme à valider avec les specs de contenu (pas de jargon interne, §9).
- Navigation à 3 onglets : le mandat en exige 4, dans le même ordre partout (§4).
- Libellés d'onglet sous AA (#CAAFFE sur #5D5D5D : 3,47:1) ; icônes en silhouette générique au lieu d'un portrait ou d'un repli par initiale.
- Aucun portrait d'enseignant : le bloc classe exige le nom ET la photo publique de l'enseignant (§5).

### 5.2 `Foyer Member.png` : Foyer

**Composition de haut en bas** (marges 57 px, nettement plus étroites que sur les autres écrans) :
1. En-tête : « Foyer » (gras, x 60) et sous-titre gris « Membres du foyer ». À droite, CTA pilule plein lavande « + Ajouter un enfant » (h 82 px).
2. **Rangée de 3 cartes de compteurs** (y 303-440, largeurs inégales). Chacune porte une icône dans un cercle teinté, un chiffre en gras et une légende : « 3 enfants / Dans le foyer » (icône de personnes lavande), « 1 appareil familial / Partagé » (tablette lavande), « 2 alertes / À traiter » (cloche **jaune** sur un cercle brun).
3. Titre de section « Enfants » ; à droite, lien gris « Gérer tous les enfants → ».
4. **Trois cartes enfant empilées**, séparées de 16 px seulement. Chacune contient : un ruban coloré (menthe, rose, lavande) qui dépasse du haut de la carte ; un avatar monogramme gris (S, M, F) ; le prénom (gras, grand), l'âge et la classe ; à droite, une pastille de statut et une légende dessous ; une ligne appareils (icône écran et téléphone, « 1/2 appareils » en gras, « 1 appareil associé ») ; un bouton tonal « Gérer › » en bas à droite. La carte de Fatimah n'a pas de ligne appareils : un grand vide la remplace.
5. Titre « Appareil familial ». Carte contenant : l'icône de téléphone dans un cercle, « iPhone de Mariam » (gras), « Disponible pour Salam, Mariam, Fatimah », un bouton « Gérer › », puis un **encart imbriqué** (#3D3A43) avec une icône « i » : « Sur cet appareil partagé, chaque enfant sélectionne son profil et saisit son code PIN pour accéder à ses contenus. »
6. Titre « Actions utiles ». Liste dans une carte, avec un filet entre les deux lignes, chacune avec une icône au trait, un titre en gras, une description et un chevron lavande : « Connecter un appareil » et « Disponibilités du foyer ».
7. Navigation à 4 onglets : Accueil · Foyer (actif : icône pleine lavande plus grande et libellé plus grand dans une autre police) · Historique · Compte.

**Textes lisibles** (exacts) : « Foyer » · « Membres du foyer » · « Ajouter un enfant » · « 3 enfants » « Dans le foyer » · « 1 appareil familial » « Partagé » · « 2 alertes » « À traiter » · « Enfants » · « Gérer tous les enfants » · « S » « Salam » « 8 ans » « Classe Al-Fajr » « Actif » « Accès normal » « 1/2 appareils » « 1 appareil associé » « Gérer » · « M » « Mariam » « 10 ans » « Classe An-Nour » « Actif » « Accès normal » « 1/2 appareils » « 1 appareil associé » « Gérer » · « F » « Fatimah » « 6 ans » « Classe Al-Badr » « Diagnostic à terminer » « Configure un appareil » « Gérer » · « Appareil familial » · « iPhone de Mariam » · « Disponible pour Salam, Mariam, Fatimah » · « Gérer » · « Sur cet appareil partagé, chaque enfant sélectionne son profil et saisit son code PIN pour accéder à ses contenus. » · « Actions utiles » · « Connecter un appareil » « Ajouter une tablette ou un téléphone pour un enfant » · « Disponibilités du foyer » « Définir les moments d'accès pour tous les enfants » · « Accueil » « Foyer » « Historique » « Compte ».

**Contenu utile** : par membre, identité, âge, classe, état d'accès et appareils (§5 Foyer) ; la section « Appareils partagés » avec les profils autorisés et un lien de gestion (§5) ; l'explication du choix de profil et du PIN sur l'appareil partagé (§7 « Après association ») ; l'entrée « Connecter un appareil » vers `/appareils/connexion`.

**À ne pas reproduire** :
- « Ajouter un enfant » → **« Ajouter un profil élève »** (§4, §5). « Enfants » et « Gérer tous les enfants » → un vocabulaire de membres ou de profils élèves : un proche adulte ou le parent lui-même peuvent être élèves (§5).
- Il manque l'option discrète **« Créer mon profil élève »** pour le titulaire (§5, §6).
- **Compteurs décoratifs** « 3 enfants », « 1 appareil familial », « 2 alertes » (§5 : « Évite les compteurs décoratifs »). « 2 alertes » ne mène nulle part.
- **« 1/2 appareils »** : quota illustratif. Les limites viennent du contrat, pas du « 1/2 » d'une capture (§5).
- « Gérer tous les enfants » **fait doublon** avec les trois boutons « Gérer » (§5 : pas de CTA doublons).
- « Diagnostic à terminer » : jargon et étape que les décisions récentes suppriment pour un débutant (§6 : parcours débutant direct, suppression du diagnostic inutile). Une fillette de 6 ans déjà « Classe Al-Badr » tout en ayant un diagnostic « à terminer » est incohérent.
- « Configure un appareil » : faute de conjugaison (→ « Configurez un appareil »), et consigne sans action associée.
- « iPhone de Mariam » présenté comme l'**appareil familial** partagé entre trois enfants : le nom d'un appareil personnel contredit son rôle d'appareil partagé.
- « Disponibilités du foyer / Définir les moments d'accès pour tous les enfants » : à ne rendre que si la politique existe (§5 : ne pas réintroduire le matching individuel ni confondre disponibilité d'appareil et disponibilité de cours).
- Rubans colorés : code couleur par enfant sans légende ni équivalent textuel (§9), et artefact de rendu.
- Jeu de données différent de l'Accueil : Salam, Mariam et Fatimah ici, contre Mariam, Yusuf, Aîcha et Adam sur l'Accueil. Rien à en tirer comme constante.
- Cartes enfant très hautes (324 px, soit 109 dp à 390), avec un bouton « Gérer » redondant alors que la carte entière pourrait mener à la fiche. Préférer des lignes sobres (§5, §9 : moins de cartes).

### 5.3 `Historique.png` : Historique des séances

**Composition de haut en bas** (marges 71 / 68 px) :
1. En-tête : « Historique » (police arrondie, x 82) et cloche avec point de notification à droite.
2. Le **même sélecteur de profils** que sur l'Accueil (Mariam sélectionnée avec son anneau ; Yusuf ; Aîcha ; Adam ; « + Ajouter enfant »). Ici, « En séance » est en vert #7ED957, et non plus en sarcelle.
3. **Conteneur de filtres** bordé (y 504-662) avec trois puces pilules bordées, chacune avec une icône lavande, un libellé et un chevron bas : « Classe » (toque), « Période » (calendrier), « Statut » (liste).
4. Espace vide d'environ 100 px, puis **une seule carte bordée** (y 770-1861) qui contient 4 séances séparées par des filets. Chaque séance se lit ainsi :
   - Ligne principale en deux colonnes séparées par un filet vertical : à gauche la date (gras) et la plage horaire (gris) ; au milieu la classe (gras) et l'enseignant (gris) ; à droite la pastille de présence et un chevron « › ».
   - Ligne secondaire en deux colonnes : icône Wi-Fi colorée, « Réseau élève » et la qualité (colorée) ; filet vertical ; icône Wi-Fi, « Réseau enseignant » et la qualité.
5. Grand vide jusqu'à la navigation (y 1861-2339).
6. Navigation à 4 onglets : Accueil · Foyer · Historique (actif : icône pleine de deux carrés empilés et libellé lavande plus grand) · Compte.

**Textes lisibles** (exacts) : « Historique » · « Mariam » « En séance » · « Yusuf » « Session 18:00 » · « Aîcha » « Dernière séance 1 h » · « Adam » « Absente » · « Ajouter enfant » · « Classe » · « Période » · « Statut » ·
- « Lun 21 sept. 2024 » « 13:45 - 15:15 » « Classe An-Nour » « Sayda Amina » « Présente » · « Réseau élève » « Bon » · « Réseau enseignant » « Bon »
- « Jeu 18 sept. 2024 » « 10:00 - 11:30 » « Classe Al-Fatiha » « Sayyid Omar » « Retard 8 min » · « Réseau élève » « Bon » · « Réseau enseignant » « Moyen »
- « Mar 16 sept. 2024 » « 15:30 - 17:00 » « Classe An-Nour » « Sayda Amina » « Absente » · « Réseau élève » « Bon » · « Réseau enseignant » « Faible »
- « Ven 13 sept. 2024 » « 09:00 - 10:30 » « Classe Al-Ikhlass » « Ustadh Bilal » « Présente » · « Réseau élève » « Bon » (icône et texte **jaunes**) · « Réseau enseignant » « Bon »
- « Accueil » « Foyer » « Historique » « Compte ».

**Contenu utile** : titre, sélecteur d'élève, filtres Classe, Période et Statut, lignes avec date, horaire, classe, enseignant et présence ou retard validé, accès au détail par chevron. C'est exactement la liste du §5 Historique, et le style auquel le complément observation §8 demande de rattacher « Séances / Observations ».

**À ne pas reproduire** :
- Il manque la **bascule « Séances / Observations »**, obligatoire (complément §8). Il n'y a ni état vide, ni état filtré, ni état de chargement.
- **Dates fausses** : en 2024, le 21 septembre est un samedi (et non un lundi), le 18 un mercredi (et non un jeudi), le 16 un lundi (et non un mardi). Seul « Ven 13 » est juste. L'**année 2024 est figée**. La séance du « Lun 21 » est au passé « Présente » alors que l'Accueil la place dans 13 min.
- **« Sayda Amina »** : coquille pour « Sayyida ». **« Ustadh Bilal »** : titre hors convention, le mandat emploie Sayyid et Sayyida (§9).
- Trois classes et trois enseignants différents pour la même élève en huit jours : contraire au modèle d'une classe au même enseignant permanent (§5 Classe, catalogue).
- La qualité réseau est au premier plan et **occupe une ligne sur deux**, alors qu'elle doit rester secondaire et n'apparaître que si elle est mesurée (§5). Le réseau de l'enseignant n'est pas une donnée familiale.
- « Absente » avec un « Réseau élève Bon » : contradiction (une connexion mesurée pour une élève absente). « Bon » est affiché en jaune sur la dernière séance : couleur et valeur incohérentes. Il manque l'état « En cours de vérification » (§5).
- Le point de la 4ᵉ pastille « Présente » est flou (#54923F, artefact de génération).
- Police arrondie de type Quicksand, qui ne fait pas partie du système (règle DM Sans et Jakarta).
- Surfaces empilées : puces bordées dans un conteneur bordé, puis une grande carte bordée qui contient toutes les lignes (§9 : moins de cartes imbriquées, lignes et séparateurs).
- Rouge « Faible » #FF5757 à 4,38:1, sous AA.

### 5.4 `Classe Details.png` : Classe An-Nour (vue tuteur)

**Composition de haut en bas** (marges 74 px) :
1. En-tête avec un chevron retour blanc (36-66, 110-160), le titre « Classe An-Nour » (gras) et le sous-titre gris « Mariam · Sayyida Amina ».
2. **Carte principale** (y 318-1234), qui **recopie la carte de l'Accueil** : monogramme « M » de l'élève, « Mariam / Classe An-Nour / Sayyida Amina / Règles de lecture • Niveau 1 », « fournir une photo ». Puis un bloc imbriqué : « Prochaine séance » avec la pastille « Salle ouverte » ; deux colonnes, « Lundi 21 septembre / 13:45 Paris » (la date en petit gras, l'heure en gris clair) et « Durée / 1 h 30 » ; « Session dans 13 min » ; « Tablette ou ordinateur conseillé. Téléphone accepté. ». Enfin un CTA plein lavande « Observer la session → » (y 1107-1206), avec le même artefact de texte fantôme que sur l'Accueil.
3. **Carte « Planning habituel »** (y 1326-1689) : icône de calendrier, titre, « Voir tout → ». Trois lignes séparées par des filets : le jour en capitales à gauche, puis deux colonnes « 13 : 45 – Paris » et « 11 : 45 – Abidjan » (heure en gras, ville en regular).
4. **Carte « Avant / Après la séance »** (y 1768-2106) : les trois mêmes tâches que sur l'Accueil, avec leur case ronde.
5. Grand vide, puis la navigation à 4 onglets avec **Foyer actif**, ce qui laisse penser qu'on arrive depuis le Foyer.

**Textes lisibles** (exacts) : « Classe An-Nour » · « Mariam · Sayyida Amina » · « M » · « Mariam » · « Classe An-Nour » · « Sayyida Amina » · « Règles de lecture • Niveau 1 » · « fournir une photo » · « Prochaine séance » · « Salle ouverte » · « Lundi 21 septembre » · « 13:45 Paris » · « Durée » · « 1 h 30 » · « Session dans 13 min » · « Tablette ou ordinateur conseillé. Téléphone accepté. » · « Observer la session » · « Planning habituel » · « Voir tout » · « LUNDI » « 13 : 45 – Paris » « 11 : 45 – Abidjan » · « MERCREDI » « 13 : 45 – Paris » « 11 : 45 – Abidjan » · « SAMEDI » « 13 : 45 – Paris » « 11 : 45 – Abidjan » · « Avant / Après la séance » · « Voir tout » · « Réviser pages 24 à 26 » · « Écouter la récitation » · « Mémoriser la partie Hifz » · « Accueil » « Foyer » « Historique » « Compte ».

**Contenu utile** : l'en-tête « nom de classe et élève concerné » (§5 Classe) ; la prochaine séance et l'action contextuelle ; le planning habituel sur plusieurs jours avec heure locale ; la préparation. Deux fuseaux affichés, par exemple pour une famille et un enseignant sur des fuseaux différents : idée utile si les données l'exigent.

**À ne pas reproduire** :
- « Observer la session » → **« Observer la séance »** (§4, §5). Proposé **à T-13 min, avant le début** : le complément observation n'autorise l'observation que si l'enfant est présent dans une séance en cours (« Séance non commencée » est un état d'indisponibilité). Avant l'entrée, il faut afficher les visites disponibles et leur durée (2 × 2 min par défaut, politique effective), et le lien « Comment ça marche ? ». Rien de tout cela n'apparaît.
- **Photo de l'enseignant absente**, remplacée par le monogramme de l'élève : le §5 demande « enseignant avec photo » et interdit de confondre portrait de l'élève et photo de l'enseignant.
- Carte recopiée de l'Accueil, dont « fournir une photo » et « Règles de lecture • Niveau 1 », au lieu d'une zone Classe propre.
- **Décalage fixe Paris / Abidjan de 2 h** : juste en été seulement (1 h en hiver). La conversion doit passer par des fuseaux IANA datés, jamais par un décalage fixe (§5). Le planning n'indique pas de durée.
- Deux formats d'heure : « 13:45 » dans la carte, « 13 : 45 » avec des espaces dans le planning.
- Il manque les ressources, la progression, l'accès à l'historique, les exceptions datées (annulation, report, remplacement) et l'état « Séance en direct ». Le libellé **« Cours en cours » est interdit** : il n'apparaît pas ici, mais ne doit pas être introduit.
- « Session dans 13 min » → vocabulaire Séance ou Cours.

### 5.5 `Profil.png` : fiche de l'élève Mariam (et non le compte du tuteur)

**Composition de haut en bas** (marges 57 px) :
1. Chevron retour et titre « Mariam » (gras, x 108).
2. **Carte d'en-tête** (y 252-488) : grand avatar monogramme gris « M » avec un ruban rose qui dépasse ; « Mariam » (gras), « 10 ans », « Classe An-Nour ». À droite, le lien lavande avec icône « Changer la photo ».
3. **Carte « Paramètres de l'enfant »** (y 552-1217) : titre, puis quatre lignes à icône lavande au trait, libellé en gras, valeur en gris et chevron « › » aligné en bas à droite. Les lignes sont séparées par des filets sombres :
   - livre, « Classe » / « Classe An-Nour » ;
   - tablette, « Interface » / « Interface guidée » ;
   - caméra, « Caméra » / « Autorisée à la séance suivante » ;
   - bouclier, « Accés Rewayah » / « Actif jusqu'au 30 octobre ».
4. **Carte « Appareils »** (y 1287-1918) : icône de deux appareils, titre et sous-titre « Gérez les appareils autorisés pour Mariam. ». Deux lignes :
   - téléphone, « Cet appareil familial », point vert et « Disponible pour Mariam », pastille verte foncée « Appareil actuel » ;
   - tablette, « iPad de Mariam », « Dernière utilisation : 18 septembre, 14:20 », bouton brun désaturé **désactivé** « Retirer » (icône de corbeille), et sous le bouton la légende « Indisponible pendant la séance ».
   - Enfin le CTA pilule plein lavande « + Connecter un appareil » (y 1811-1892).
5. **Bandeau d'information** brun (y 1979-2191) : bouclier jaune dans un cercle, titre jaune « Choix du profil + PIN », corps « pour éviter l'accès à la séance d'un autre enfant. ».
6. Navigation à 4 onglets avec **Compte actif**.

**Textes lisibles** (exacts) : « Mariam » · « M » · « Mariam » · « 10 ans » · « Classe An-Nour » · « Changer la photo » · « Paramètres de l'enfant » · « Classe » « Classe An-Nour » · « Interface » « Interface guidée » · « Caméra » « Autorisée à la séance suivante » · « Accés Rewayah » « Actif jusqu'au 30 octobre » · « Appareils » · « Gérez les appareils autorisés pour Mariam. » · « Cet appareil familial » · « Disponible pour Mariam » · « Appareil actuel » · « iPad de Mariam » · « Dernière utilisation : 18 septembre, 14:20 » · « Retirer » · « Indisponible pendant la séance » · « Connecter un appareil » · « Choix du profil + PIN » · « pour éviter l'accès à la séance d'un autre enfant. » · « Accueil » « Foyer » « Historique » « Compte ».

**Contenu utile** : c'est la meilleure base de la fiche élève du §5. En-tête (prénom, photo, âge, classe) ; lignes groupées Classe, Interface, Caméra en cours et Accès ; section Appareils avec l'appareil actuel, la dernière utilisation, le retrait conditionné et la connexion d'un nouvel appareil ; rappel du choix de profil et du PIN (§7). La liste à filets, icône au trait, libellé, valeur et chevron, est le composant « ligne de réglage » attendu (§5 Mon compte et Fiche : « lignes ou groupes sobres »).

**À ne pas reproduire** :
- **Onglet actif « Compte »** : faux. La fiche élève relève du **Foyer** (§4 : `/tuteur/foyer/:eleveId`). Le nom du fichier `Profil.png` ne détermine pas la route (§2).
- « **Accés** Rewayah » → « **Accès** Rewayah » (accent). « Paramètres de l'enfant » → « Paramètres de l'élève » ou « Réglages de [prénom] » : un proche adulte n'est pas un enfant (§5).
- « Actif jusqu'au 30 octobre » : date sans année, illustrative ; à lire dans le service d'accès.
- Il manque les rubriques **Informations de l'élève** (`.../informations`) et **Parcours et inscription** (`.../inscription`) de l'arbre §4. « Classe » peut mener à la classe, mais le parcours et le dossier restent nécessaires.
- « Indisponible pendant la séance » : restriction de retrait à n'appliquer **que si la politique l'établit** (§5 Foyer). Le bouton désactivé doit rester lisible (le libellé #D7D5D4 l'est) et expliqué.
- « Cet appareil familial » avec la pastille « Appareil actuel » : l'appareil de consultation du tuteur n'est pas forcément un appareil associé à l'élève. Ne rien afficher que le service ne confirme.
- « Interface guidée » : libellé correct (§5, §9). La politique (demande de standard à partir de 10 ans, activation par le tuteur) doit venir du dépôt, sans bascule locale.
- Rubans et avatar gris : même remarque que pour le Foyer.
- Le bandeau PIN ne mène nulle part ; son titre jaune #E5B549 est un deuxième code couleur « avertissement » pour une simple information.

## 6. Incohérences transverses entre les cinq captures

1. **Navigation** : 3 onglets sur l'Accueil, 4 sur les autres écrans ; onglet actif faux sur la fiche (Compte au lieu de Foyer) ; hauteur de barre de 131 px sur l'Accueil contre 112-113 ailleurs ; libellé actif en taille et en police différentes selon l'onglet ; inactifs à 3,66:1 et actif Foyer à 2,23:1. La cible est **Accueil · Foyer · Historique · Compte**, partout et dans le même ordre (§4).
2. **Polices** : trois familles (proche de DM Sans ; grotesque proche de Manrope ou Jakarta ; arrondie proche de Quicksand). La règle est DM Sans pour les titres et Plus Jakarta Sans pour le reste.
3. **Données** : deux jeux d'enfants incompatibles ; dates et jours de semaine faux, année 2024 figée ; Mariam à la fois « en séance » et « dans 13 min » ; la même séance du 21 à venir sur l'Accueil et passée dans l'Historique ; trois classes pour une élève.
4. **Tokens** : cinq verts de statut, six fonds de pastille verte, quatre gris secondaires, quatre violets d'onglet actif, trois lavandes de CTA, deux styles d'avatar de repli, deux formes de CTA principal (rectangle à r ≈ 10 dp et pilule), six hauteurs de pastille, marges de 19 à 25 dp.
5. **Vocabulaire** : « Session » au lieu de Séance ; « Ajouter enfant » et « Ajouter un enfant » au lieu de « Ajouter un profil élève » ; « Ustadh » et « Sayda » au lieu de Sayyid et Sayyida ; « Diagnostic à terminer » ; « Accés ».

## 7. Réinterprétation dans le langage des nouveaux high-fi

Pour Foyer, Historique, Classe et Fiche élève, sans high-fi mobile dédié : **garder le contenu et l'ordre relevés ci-dessus** (corrigés selon §5 et §6), et **emprunter le rendu** aux high-fi approuvés.

| Élément des anciennes captures | Traduction proposée | Référence du rendu |
|---|---|---|
| Fond #292530 / carte #33303A sans bordure | Clair : fond #F6F6F8, carte #FEFDFE avec bordure de 1 px #EDEDF1, bloc imbriqué #F4F3F6. Sombre dérivé : fond #171923, carte #1B1D28 | V1 (Accueil clair), V3 (Compte sombre) |
| CTA lavande #C2A5F9 / #C09FFF, rectangle ou pilule | Clair : CTA doux #DAC7FD avec libellé quasi noir. Sombre : CTA plein #B78FF8. **Une seule forme**, cible ≥ 48 dp | V1, V3 |
| Barre de navigation grise #5D5D5D, 3 ou 4 onglets | Barre claire flottante (#FDFCFD, bordure #EDEEF1) sur mobile ; rail sur desktop ; 4 destinations ; libellés assombris pour atteindre AA | V1, V2 |
| Cartes enfant très hautes avec ruban et « Gérer » | Lignes sobres (avatar ou initiale, prénom, classe ou inscription, statut textuel et chevron) dans un groupe à filets, la ligne entière menant à la fiche | §5 Foyer, §9 ; composant « ligne de réglage » de la fiche |
| Compteurs « 3 enfants / 1 appareil / 2 alertes » | Supprimés, ou remplacés par une action utile réelle | §5 Foyer |
| Historique en une grande carte bordée, réseau sur une ligne sur deux | Liste à filets ; ligne unique avec date, horaire, classe, enseignant et présence ; réseau seulement dans le détail et seulement s'il est mesuré ; bascule « Séances / Observations » | §5, complément §8 |
| Carte Classe recopiée de l'Accueil | En-tête de classe avec l'élève concerné ; zone Enseignant avec photo et titre Sayyid ou Sayyida ; prochaine séance ; action contextuelle (« Voir la classe » ou « Observer la séance » avec les visites restantes) ; planning, travail, ressources et progression en lignes | §5 Classe ; V7 pour l'observation |
| Statuts de couleurs multiples | Tokens uniques `success`/`warning`/`danger`/`neutral`, avec leurs conteneurs et un libellé toujours présent | V1 §19 |
| Bandeaux bruns opaques (#503B28, #453B33) | Bandeau d'action bloquante unique, avec un fond d'avertissement clair et une bordure chaude de 1 px (V1 : #FEF6E7 / #F8ECD9), et une variante sombre dérivée ; le bandeau d'information garde une teinte neutre | V1 |

## 8. Pièges principaux (synthèse)

1. **Contenu métier obsolète** à ne pas recopier : « Ajouter (un) enfant », « Session », « Observer la session » avant le début et sans quota de visites, « Diagnostic à terminer », « 1/2 appareils », compteurs décoratifs, qualité réseau (surtout celle de l'enseignant) sans mesure, « Ustadh », « Sayda », « Accés », absence déduite.
2. **Navigation et routes** : 3 onglets sur l'Accueil ; onglet actif faux sur la fiche élève (Compte au lieu de Foyer) ; `Profil.png` n'est pas `/tuteur/compte` ; la bascule Séances / Observations manque dans l'Historique.
3. **Valeurs illusoires** : dates et jours faux, année 2024, décalage fixe Paris / Abidjan, jeux d'enfants incompatibles, tailles de texte non transposables (canevas probablement en @2x : à 390 dp, le corps tomberait à 8-10 dp), trois polices au lieu de DM Sans et Plus Jakarta Sans, contrastes de navigation sous AA.
