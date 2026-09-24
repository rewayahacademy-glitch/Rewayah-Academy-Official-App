# V8 - Relevé visuel « Observation tuteur » (planches 01 et 02)

Agent : V8_observation_ecrans. Date : 24/09/2026. Phase lecture seule : aucun fichier du dépôt modifié.

## 0. Méthode et preuves

- Images ouvertes en entier avec l'outil Read :
  - `D:\RA _APP\docs de lancement\tutuor image\tuteur observation desktop light.png` (1536 × 1024 px, 96 dpi)
  - `D:\RA _APP\docs de lancement\tutuor image\mobile\tuteur observation mobile light.png` (1536 × 1024 px, 96 dpi)
  - Pour trouver la planche 3, j'ai aussi ouvert `tutor observation map.png` (1972 × 2106). C'est un logigramme, voir §1.
- Tuiles agrandies ×2 à ×8, toutes ouvertes, dans `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V8\` :
  - Mobile : `M_e1_haut/bas`, `M_e2_haut/bas`, `M_e3_haut/bas`, `M_e4_haut/bas`, `M_e5_haut/bas`, `M_e6_haut/bas`.
  - Loupes sur l'arabe : `M_zoom_arabe_e3`, `M_zoom_arabe_e4`, `M_zoom_tha_e4`, `M_zoom_ba_e3`.
  - Bureau : `D_entete`, `D_p1_haut_gauche/haut_droite/bas_gauche/bas_droite`, `D_p2_haut/bas`, `D_p3_gauche/droite`, `D_p4`.
  - Loupes bureau : `D_zoom_arabe_lignes`, `D_zoom_aicha`.
- Couleurs mesurées avec System.Drawing (`GetPixel`) :
  - **mode** : couleur la plus fréquente d'une zone, pour les fonds.
  - **pixel extrême** : pixel le plus sombre ou le plus saturé, qui donne le cœur du glyphe.
  - **cœur médian** : médiane des 8 à 30 % de pixels les plus « encrés ».
  - Les coordonnées sont en pixels de la planche d'origine (x, y).
  - Le texte fin est éclairci par l'anticrénelage. Pour une couleur de texte, le pixel extrême est plus proche de la vraie teinte que le cœur médian.
- Scripts de mesure hors dépôt, dans le scratchpad de session : `crop_v8.ps1`, `sample_v8.ps1`, `scan_v8.ps1`, `measure_v8.ps1`, `robust_v8.ps1`.

## 1. Correspondance planches ↔ fichiers et manifeste

| Planche du mandat (observation §2) | Fichier | Titre imprimé sur la planche | Constat |
|---|---|---|---|
| 1. Parcours mobile et consentement | `mobile\tuteur observation mobile light.png` | « Rewayah · Observation tuteur » / « 01 • Parcours mobile » | Correspond. 6 écrans mobiles, dont 1 en thème sombre malgré « light » dans le nom du fichier |
| 2. Observation sur ordinateur et historique | `tuteur observation desktop light.png` | « Rewayah · Observation et historique » / « 02 · Ordinateur et suivi des visites » | Correspond. 4 panneaux numérotés : 1 bureau, 1 mobile sombre, 1 admin bureau, 1 mobile clair |
| 3. États particuliers et notices de présence | **introuvable** | - | Aucun fichier du dossier ne représente cette planche. `tutor observation map.png` est un logigramme beige du parcours (V7 s'en occupe), pas une planche high-fi. Il ne montre ni notice enseignant/enfant ni état particulier. **Fichier à demander au directeur.** |

Manifeste (statut : tous « nouveau high-fi », sauf mention contraire) :

| ID | Fichier / zone (px) | Écran représenté | Route logique probable (§4) | État | Thème | Format |
|---|---|---|---|---|---|---|
| M1 | mobile, x 196-551, y 79-593 | Classe de l'enfant, entrée d'observation | `/tuteur/classes/:classeId` | Séance en direct, enfant présente, 2 visites disponibles | clair | mobile |
| M2 | mobile, x 590-947, y 79-593 | Explication de première utilisation « Un aperçu de son apprentissage » | `/tuteur/classes/:classeId/observer` (étape préalable, aussi ouverte par « Comment ça marche ? ») | Nominal, avant connexion, compteur non démarré | clair | mobile |
| M3 | mobile, x 985-1342, y 79-593 | Salle d'observation | `.../observer` | En direct, visite 1/2 | **sombre** | mobile |
| M4 | mobile, x 196-551, y 612-1005 | Salle d'observation | `.../observer` | En direct, visite 2/2 | clair | mobile |
| M5 | mobile, x 590-947, y 612-1005 | Fin de visite | `.../observer` (état de sortie) puis retour classe | Première visite terminée, 1 visite restante | clair | mobile |
| M6 | mobile, x 985-1342, y 612-1005 | Consentement « Les visites des parents » | `/onboarding/...` (étape consentement) | Case non cochée, CTA désactivé | clair | mobile |
| D1 | bureau, panneau 1, x 22-1075, y 85-630 | Observation en direct sur ordinateur | `/tuteur/classes/:classeId/observer` | En direct, visite 1/2 · 01:42 | clair | desktop |
| D2 | bureau, panneau 2, x 1088-1520, y 68-635 | Historique, onglet Observations | `/tuteur/historique` (segment Observations) | Nominal, 3 lignes | **sombre** | mobile |
| D3 | bureau, panneau 3, x 22-1075, y 645-1020 | Historique des observations (administration) | route admin existante (hors arbre tuteur §4, observation §8) | Nominal, 3 lignes | clair | desktop |
| D4 | bureau, panneau 4, x 1088-1520, y 645-1020 | Détail d'une observation | absente de §4 ; proposer `/tuteur/historique/observations/:id` ou un sous-niveau de `/tuteur/seances/:seanceId` (au coordinateur de trancher) | Nominal, 2 visites | clair | mobile |

## 2. Échelle et mesures

### 2.1 Mobile (planche 01)

- Téléphone M1 : bords x 196 → 551, soit **356 px pour 390 dp**. Donc **1 px ≈ 1,095 dp**.
- Hauteur du cadre : y 79 → 593 (515 px ≈ 564 dp). Les écrans sont **tronqués** et ne font pas 844 dp : la composition est condensée.

| Mesure | px (planche) | dp estimés | Source |
|---|---|---|---|
| Marge latérale écran → carte | 13-14 (196→209, 537→551) | 14-15 (arrondir à **16**) | scan y=300 |
| Retrait du contenu dans la carte | 12 (209→221) | ~13 (≈ 12-16) | avatar à x 221 |
| Retrait du CTA dans la carte | 7 (209→216) | ~8 | CTA x 216-530 |
| Espace entre cartes | 11 (422→433) | ~12 | scan x=300 |
| Rayon des cartes | ~10 | **~12** | coin carte, y 152-158 |
| Rayon des CTA | 7-9 | **~8-10** | coin CTA M1 y 328-332, M5 y 889-895 |
| Rayon des encarts lavande | ~8 | ~9-10 | coin encart M2 y 476-480 |
| Pastilles / chips | hauteur/2 | pilule | visuel |
| Hauteur du CTA « Observer la séance » | 37 (y 328-364) | **~40** (sous la cible 48 dp du mandat §9) | scan x=260 |
| Largeur du CTA | 315 | ~345 | x 216-530 |
| Bandeau « Séance en direct » | 27 (y 241-268) | ~30 | scan x=300 |
| Avatar de l'enseignant (anneau lavande inclus) | 69 × 69 | **~76** | x 221-290, y 163-232 |
| Cercle d'icône (M2) | 50 × 49 | ~54 ; glyphe ~24 | x 612-661 |
| Cercle héros (M5, badge inclus) | 89 × 84 | ~92-97 | x 724-812 |
| Ligne de liste (Planning / Avant-Après) | 40 | ~44 | séparateur y 472-473 |
| Barre de navigation (zone d'accueil incluse) | ~63 (y 530-593) | ~69 ; icônes 20 px ≈ 22 dp | scan x=300 |
| Barre de commandes de la salle (M3) | 335 × 68 | ~367 × 74 | x 996-1330, y 503-570 |
| Bouton « Quitter » plein (M3) | 90 × 45 | ~98 × 49 | x 1235-1324 |
| Tuiles vidéo (M3) | ~161 × 115 chacune, écart ~10 | ~176 × 126, écart ~11 | visuel |
| Carte du support (M3) | ~333 × 203 | ~365 × 222 | visuel |

Tailles de texte. La hauteur mesurée est celle de l'encre. Le corps est estimé ainsi : hauteur ÷ 0,72 sans jambage, ÷ 0,95 avec jambage, puis × 1,095.

| Niveau | Exemple | Hauteur d'encre | Corps estimé | Graisse apparente |
|---|---|---|---|---|
| Titre héros | « Votre première visite est terminée » (M5, 2 lignes, 38 px) | ~14 par ligne | **~21-22 dp**, interligne ~26 dp | 700 |
| Titre de page | « Classe An-Nour » en-tête M1 (13 px) ; « Un aperçu de son apprentissage » (16 px, jambages) ; « Les visites des parents » (16 px) | 13-16 | **~18-20 dp** | 700 |
| Titre de carte / section | « Classe An-Nour » carte M1 (11 px) ; « 2 visites de 2 minutes » (10 px) | 10-11 | **~15-17 dp** | 600-700 |
| Corps / libellé de ligne | « Planning habituel » (14 px, jambage) ; valeur « 18:00 – 19:00 » (10 px, chiffres) | 10-14 | **~15-16 dp** | 500-600 |
| Libellé de CTA | « Observer la séance » (10 px) | 10 | ~15 dp | 600 |
| Légende / méta | « Règles de lecture • Niveau 1 » (11) ; « Aujourd'hui » (11) ; « 2 visites disponibles • 2 min par visite » (12) | 11-12 | **~12-14 dp** | 400 |
| Libellé de navigation | « Foyer » (10, jambage) | 10 | ~11-12 dp | 500 (actif 600) |

### 2.2 Bureau (planche 02)

- Panneaux 1 et 3 (desktop) : l'échelle est inconnue.
  - Hypothèse de travail : **1 px ≈ 1,22 dp**, si la carte d'observation de 1037 px représente une fenêtre d'environ 1280 dp.
  - Cette hypothèse est cohérente avec les boutons de commande : 39 px ≈ 48 dp.
  - Les valeurs en dp de cette section sont indicatives.
- Téléphones des panneaux 2 et 4 : écran ~401-406 px pour 390 dp, soit **1 px ≈ 0,96 dp**.

| Élément (D1) | px | dp (hyp. ×1,22) |
|---|---|---|
| Carte d'observation | x 31-1067, y 131-622 ; marge interne 16 | marge interne ~20 |
| En-tête (titre, chip, visite) | y 131-195 (64) | ~78 |
| Support pédagogique | x 47-816 (770 = **~77 % de la largeur utile**), y 196-544 (349) | ~940 × 425 |
| Colonne vidéos | x 827-1049 (223, **~22 %**) ; enseignant y 195-358 (164) ; enfant y 363-537 (175), bordure violette 3 px ; écart 5-10 | ~272 de large |
| Barre de commandes | x 47-1050, y 558-613 (56) | ~68 |
| Boutons « Agrandir » / « Quitter » | 126-128 × 39 | ~155 × **48** |
| Rayons | support ~10 ; vidéo ~8 ; boutons ~9-10 ; barre ~12 | ~12 / 10 / 12 / 15 |
| Texte | titre « Classe An-Nour » 14 px (≈ 24 dp) ; sous-titre 13 px (≈ 17 dp) ; « Visite 1/2 » 13 px ; « 01:42 » 11 px chiffres, gras (≈ 18 dp) ; « Son reçu » 12 px (≈ 16 dp) ; titre du support 22 px (contenu partagé, pas un style d'UI) | |

| Élément (D2 / D3 / D4) | px | dp |
|---|---|---|
| D2 titre « Historique » | 22 (jambage q) | ~22-24 |
| D2 avatars | 65 × 65 | ~62 |
| D2 segment Séances/Observations | hauteur 34 (y 303-337) ; segment actif x 1301-1496 ; rayon ≥ 14 | ~33, quasi pilule |
| D2 chips de filtre | 38 (y 348-386) | ~37 |
| D2 ligne d'historique | ~60 (400→460→520→580) ; rayon de la carte liste ~13 | ~58 |
| D3 barre latérale | largeur 170 (x 28-197) ; élément actif 38 de haut (y 875-913) | ~207 / ~46 |
| D3 champ de recherche / en-tête de tableau / ligne | 35 / 30 / 37-39 ; rayon du tableau ~10 | ~43 / 37 / 46 |
| D3 titre « Historique des observations » | 22 (jambage q) | ~28 |
| D4 CTA « Retour à l'historique » | 30 (y 979-1008), rayon ~11 | **~29 dp, sous 48 dp** |
| D4 chips de motif | 22 de haut | ~21 |

## 3. Tokens mesurés

### 3.1 Clair

| Rôle | HEX mesuré | Coordonnées / méthode | Remarque |
|---|---|---|---|
| Fond de planche (pas un token d'app) | #FBFAFE (M) ; #F8F7FE (D) | M (90-110, 490-510) mode ; D (3-15, 500-540) mode | fond de présentation |
| Fond d'écran de l'app | **#F9F9FB** | M (330-350, 425-428) mode | entre deux cartes, M1 |
| Fond d'écran « plein blanc » | #FEFEFE | M4 (205-217, 690-700) ; D4 (1300-1360, 690-696) | écrans sans cartes |
| Fond principal admin | #FBFBFD | D (600-800, 990-1005) mode | |
| Surface carte | **#FEFEFE / #FFFFFF** | M (480-510, 160-170) ; D (600-800, 170-182) | |
| Bordure de carte (1 px) | **#EEF0F5 - #F0F1F5** | M scan y=300 : x 209 #F0F1F5, x 537 #EEF0F5 ; D (46,302) #EEF0F6 ; D4 (1123,830) #EFF0F6 | très discrète |
| Bordure de bouton contour | #EDEFF5 | D (488,583) | « Agrandir » |
| Bordure de champ | #E6E9F1 | D (224,790) | recherche admin |
| Séparateur de liste | #F3F3F8 ; #F1F3F7 | M (300,472) ; D (700,877) | |
| En-tête de tableau | #F6F6FB | D (900-1000, 815-833) mode | |
| Texte principal | **cœur #000012 - #01031B**, pixel #000000 | M (311,118) ; D (145,154) #000001 ; D3 titre cœur #01031B | encre quasi noire, légèrement bleutée |
| Texte secondaire | **#5B5789** (pixel) / cœur #8684A8 (mobile, gris violacé) ; #213157 / cœur #6E7392 (bureau, ardoise) | M (399,216) ; M (290,136) #453C76 ; D (163,174) ; D3 (228,734) #3C4066 | le mobile tire vers le violet, le bureau vers l'ardoise |
| Texte tertiaire / placeholder | #8E94AC / cœur #A6ACC1 | D (443,777) | |
| Libellé gris de ligne d'info | #555F7D / cœur #747B94 | D4 (1188,816) | « Tuteur », « Durée totale » |
| **Accent violet (plein)** | **#753BFB** ; #742DF9 ; #6C2DF8 ; cœurs #844DFC / #7A38F6 / #7A46F6 | M icône Accueil active (237,558) ; lettre ب M3 (1076,240) ; icône Planning (233,446) | icônes, lettre surlignée, onglet actif |
| Violet des liens | #5D25F2 ; #5311F6 ; #4E0BFC ; #3E0FFD (cœurs #845DEE, #7E53F3, #5D2BF3, #672EF6) | M (421,400) ; M (788,578) ; D (106,892) ; D (1229,727) | « Comment ça marche ? », « Pas maintenant », item admin actif, « Observations » |
| Violet profond (lettre du support, bureau) | #4A06AC / cœur #4F10A1 | D (212,342) | contenu, pas un token d'UI |
| **CTA doux (principal)** fond | **#D6C5FC** (M1/M2) ; #CFBCFB (M5) ; #E6DCFD (D4) | M (220-300, 330-362) mode ; M (615-695, 895-920) ; D (1135-1215, 982-1004) | **aucun CTA violet plein** dans ces planches |
| CTA doux, texte | #00000C / cœur #070428 (encre foncée) ; D4 texte violet #3E0BF9 / cœur #6A39F3 | M (338,347) ; D (1324,992) | deux variantes : texte noir ou texte violet |
| CTA désactivé | fond **#E2DCFB**, texte #8C80D2 / cœur #9D90DC | M (1005-1065, 905-940) ; M (1149,921) | M6 « Continuer » |
| Teinte lavande (cercles d'icône) | #F3EFFE ; #F4EFFE | M (218-248, 285-310) ; M (612-628, 160-190) | |
| Encart d'info lavande | #EFEAFD ; #F2F0FD | M2 (612-642, 480-510) ; M5 (880-920, 830-870) | |
| Carte de lettre sélectionnée | #F0E9FD (M) ; #ECE5FE (D) ; bordure #C4A3FC | M (1015,205) ; D (128,312) ; M (1015,200) | |
| Chip « Visite 2/2 · 01:18 » | fond #F0EBFE, texte #633BB8 / cœur #7159AD | M (447,650) ; M (525,660) | |
| Bandeau de section (planche) / item admin actif / avatar placeholder | #EBE9FD / #EFE8FD / #EDE6FD | D (500-700, 92-108) ; D (160-188, 880-908) ; D (50-62, 140-165) | |
| Pastille de notification | #A173FE | M (527,119) | point sur la cloche |
| **Vert « en direct »** fond | **#DEFDE9** (bandeau M1, chip M4) ; #DBFDE3 (chip D1) | M (225-515, 243-265) mode ; D (268-294, 146-163) | |
| Vert, point | #1FD069 ; #08C346 (cœur #09B940) | M (234,253) ; D (282,157) | |
| Vert, texte | #08713C (cœur #199156) ; #003F0D (cœur #186D32) ; M4 #068A39 | M (278,257) ; D (296,157) ; M (427,657) | |
| « Son reçu » (bureau) | cercle #E4FDEB, icône #0BC238 | D (70-80, 572-582) ; D (87,585) | |
| Chip « Départ volontaire » | fond #DAFCE3, texte #0B441A (cœur #1C6D38) | D (855-870, 888-904) ; D (938,899) | |
| Coche de succès (M5) | #05DD61 | M (790,707) | |
| Barres de niveau audio | #5AF182 (D) ; #46E8B1 (M3) | D (1030,513) ; M (1140,470) | |
| **Orange** chip « Limite atteinte » | fond **#FEEBC4** / #FEECC9, texte #563611 (cœur #7B5728) | D (855-870, 850-866) ; D4 (1392,884) ; D (906,857) | |
| **Rouge** « Quitter » doux | fond **#FEEBF1** (D) / #FEE0E6 (M4) ; texte #F80113 (cœur #F10C26) / #FD0527 (cœur #F12847) | D (1015-1031, 572-598) ; M (452-464, 962-984) ; D (981,586) ; M (476,971) | |
| Navigation claire | fond #FEFEFE ; actif icône #753BFB, libellé #7A43FA ; inactif icône #9192A7, libellé #8F8EB0 | M (360-390, 578-588) ; (237,558) ; (249,569) ; (320,558) ; (329,572) | |

### 3.2 Sombre (D2 Historique et M3 Salle)

| Rôle | HEX | Coordonnées |
|---|---|---|
| Fond d'écran | **#23202C** (D2) ; #272633 (M3) | D (1250-1360, 290-296) ; M (1140-1200, 360-368) |
| Surface de liste | #2D2A38 | D (1190-1230, 450-455) |
| Piste de segment / segment actif | #2A2734 / **#514871** | D (1130-1170, 312-326) ; D (1310-1350, 312-326) |
| Texte de segment actif / inactif | cœur #CCB8F0 / #B9B8C5 | D (1358-1443, 312-326) ; D (1180-1230, 312-326) |
| Chip de filtre | fond #292633, icône cœur #A37CEB | D (1116-1126, 360-378) ; D (1126-1152, 357-379) |
| Cercle d'avatar / anneau actif | #302D3B / #BD94F2 (cœur #A181C9) | D (1232-1240, 190-210) ; D (1134,205) |
| Texte principal / secondaire | #FFFFFF / cœur #B0AFBB - #B3B3BF | D (1131,166) ; D (1225-1295, 270-282) |
| Statut « En séance » | texte #5AE961 (cœur #65C05C), point #6FF59B | D (1137,275) ; D (1187,237) |
| Point jaune (séance à venir) / gris (inactif) | #FFDC06 / #8380A0 | D (1286,237) ; D (1375-1380, 236-241) |
| Chip « Terminée(s) » | fond #283D3A, point #59EB90, texte #D7E1DD | D (1440-1460, 423-439) |
| Chip « Interrompue » | fond #58293B, point #FB5451 | D (1440-1460, 543-559) ; D (1391,549) |
| Navigation sombre | fond **#4B4B4B (gris neutre, rompt la palette violacée)** ; actif icône #8A57E5, libellé cœur #8179BC ; inactif libellé #ACAEB1 | D (1180-1210, 604-612) ; D (1345,587) ; D (1328-1383, 613-625) |
| Pastille de notification | #9B59F6 | D (1473,152) |
| Salle M3 : barre de commandes / bouton rond | #2C2B36 / #3C3C4C | M (1000-1020, 555-575) ; M (1030-1040, 520-542) |
| Salle M3 : chip « En direct » | fond #3A5F5B, point #31CA80, texte #A1F6C7 | M (1158-1170, 115-137) ; M (1171,126) ; M (1214,125) |
| Salle M3 : chip « Visite 1/2 · 01:42 » | fond #312F40, texte #FAFAFE | M (1235-1325, 112-117) ; M (1302,123) |
| Salle M3 : « Quitter » plein | **#E9454E**, libellé #F03E46 | M (1250-1300, 516-526) ; M (1268,566) |
| Salle M3 : étiquette du nom sur la vidéo | #3D3B43 (translucide) | M (1000-1012, 458-480) |
| Salle M3 : support | reste blanc #FEFEFE, carte de lettre sélectionnée #F0E9FD | M (1200-1300, 168-180) |

Dérivation sombre : les deux écrans sombres ne partagent pas exactement le même fond (#23202C contre #272633). La barre de navigation sombre est d'un gris neutre (#4B4B4B), étranger au reste de la palette. Il faut normaliser dans les tokens et ne pas reproduire ces deux valeurs telles quelles.

## 4. Fiches écrans

### M1 - Classe de l'enfant, séance en direct (mobile, clair)

- Zone : mobile, x 196-551, y 79-593.
- Composition de haut en bas :
  1. Barre système « 9:41 ».
  2. En-tête : chevron retour, titre « Classe An-Nour », sous-titre « Mariam · Sayyida Amina », cloche avec pastille violette à droite.
  3. **Carte principale** (blanche, bordure fine, rayon ~12 dp) :
     - Avatar rond de l'enseignante (~76 dp, anneau lavande) à gauche.
     - À droite, le bloc texte « Classe An-Nour » / « Sayyida Amina » / « Règles de lecture • Niveau 1 ».
     - Bandeau vert pleine largeur : point vert et « Séance en direct » à gauche, « Mariam est présente » à droite.
     - Deux colonnes séparées par un filet vertical : icône calendrier (cercle lavande) « Aujourd'hui » / « 18:00 – 19:00 » ; icône horloge « Temps restant » / « 1 h 00 ».
     - CTA doux lavande pleine largeur « Observer la séance → ».
     - Ligne centrée grise « 2 visites disponibles • 2 min par visite ».
     - Lien violet souligné avec icône info « Comment ça marche ? ».
  4. **Carte liste** à 2 lignes séparées par un filet, icônes violettes au trait et chevrons : « Planning habituel », « Avant / Après la séance ».
  5. **Barre de navigation à 4 destinations** : Accueil (actif, icône pleine violette), Foyer, Historique, Compte.
- Iconographie : icônes au trait violet (calendrier, horloge, livre), icône de navigation active pleine, inactives grises pleines.
- États visibles : en direct, enfant présente, 2 visites disponibles.
- Textes exacts : « 9:41 », « Classe An-Nour », « Mariam · Sayyida Amina », « Classe An-Nour », « Sayyida Amina », « Règles de lecture • Niveau 1 », « Séance en direct », « Mariam est présente », « Aujourd'hui », « 18:00 – 19:00 », « Temps restant », « 1 h 00 », « Observer la séance », « 2 visites disponibles • 2 min par visite », « Comment ça marche ? », « Planning habituel », « Avant / Après la séance », « Accueil », « Foyer », « Historique », « Compte ».
- À ne pas reproduire :
  - Les valeurs « 2 visites », « 2 min », « 1 h 00 », « 18:00 – 19:00 », « Niveau 1 » sont des données illustratives. Elles viennent de la politique effective et des données de séance (mandat §9 et observation §4).
  - « Temps restant » désigne la séance, pas la visite. Il faut un libellé non ambigu pour ne pas le confondre avec le chronomètre de visite.
  - « Niveau 1 » peut ressembler à un code interne : vérifier le libellé réel du parcours (§6 « aucun code académique interne »).
  - La liste ne montre que Planning et « Avant / Après la séance ». Le mandat §5 Classe exige aussi préparation, ressources, progression et historique accessibles. « Avant / Après la séance » doit être rattaché aux destinations existantes (Travail à préparer, Bibliothèque, Progression) et ne crée pas une route nouvelle.
  - « Mariam est présente » vient seulement d'une présence réelle. Présence incertaine : « vérification ». Enfant absent : observation indisponible avec motif (observation §4).
  - Le CTA mesure ~40 dp : porter à 48 dp minimum (§9).

### M2 - Explication de première utilisation (mobile, clair)

- Zone : x 590-947, y 79-593.
- Composition :
  - En-tête avec chevron et titre « Un aperçu de son apprentissage » aligné à gauche, sans sous-titre.
  - 3 éléments icône + texte : cercle lavande ~54 dp avec icône violette au trait, titre gras, corps gris violacé sur 2-3 lignes.
  - Un filet horizontal.
  - 2 conseils plus discrets : petite icône grise dans un cercle clair, corps gris.
  - Un encart lavande centré avec bouclier.
  - CTA doux pleine largeur, lien texte violet centré.
  - Pas de barre de navigation.
- Textes exacts :
  - « Un aperçu de son apprentissage »
  - « 2 visites de 2 minutes » / « Observez brièvement la séance de votre enfant. »
  - « Écoutez l'enseignant et les élèves » / « Vous entendez l'enseignant et les élèves quii prennent la parole, y compris votre enfant. »
  - « Sans micro ni caméra » / « Votre micro et votre caméra restent désactivés pendant l'observation. »
  - « Revenez plus tard si votre enfant ne récite pas lors de votre première visite. »
  - « Pour préserver la concentration, vous observez sans intervenir. »
  - « Votre enfant et son enseignant sont informés. »
  - « Observer maintenant → », « Pas maintenant ».
- À ne pas reproduire :
  - **Coquille « quii »** : écrire « qui ».
  - Chiffres codés en dur « 2 visites de 2 minutes » : les adapter à la politique effective (observation §6).
  - Le texte de référence du mandat (« Vous disposez de deux visites de deux minutes par séance. Si un autre élève récite… Votre micro et votre caméra restent désactivés pour ne pas interrompre la classe. ») doit être couvert en entier, même découpé en éléments.
  - Le compteur ne démarre pas sur cet écran (observation §5).
  - « Pas maintenant » ramène à la classe avec le contexte de l'enfant.
  - Formulation « son enseignant » : utiliser Sayyid/Sayyida et le prénom si connus.

### M3 - Salle d'observation, visite 1/2 (mobile, sombre)

- Zone : x 985-1342, y 79-593. Thème sombre, sans barre de navigation.
- Composition :
  1. En-tête : chevron, « Classe An-Nour » / « Mariam · Sayyida Amina » ; à droite deux chips, « ● En direct » (vert sombre) et « Visite 1/2 · 01:42 » (contour gris).
  2. **Carte du support**, blanche même en sombre, qui domine : « Lecture · Les lettres », puis 3 cartes de lettres (ب « ba » sélectionnée en lavande à bordure violette, ت « ta », ث « tha »). Chacune a une ligne de 3 variantes vocalisées sous un filet.
  3. Deux **vignettes vidéo** côte à côte, secondaires : enseignante et enfant, étiquette de nom translucide et barres audio vertes.
  4. **Barre de commandes** arrondie : 3 commandes (icône dans un cercle au-dessus du libellé) « Son reçu », « Agrandir », « Quitter » (bouton rouge plein, libellé rouge).
- Textes exacts : « 9:41 », « Classe An-Nour », « Mariam · Sayyida Amina », « En direct », « Visite 1/2 · 01:42 », « Lecture · Les lettres », « ba », « ta », « tha », « Sayyida Amina », « Mariam », « Son reçu », « Agrandir », « Quitter ».
- À ne pas reproduire :
  - Le support n'est pas une UI. Le contenu est le document partagé par l'enseignant, issu des ressources vérifiées (observation §7, « aucune fausse page »).
  - **Erreur d'arabe** : sous ب, la troisième variante n'a pas de kasra visible (« بَ بُ ب ») (loupe `M_zoom_ba_e3`).
  - Le chronomètre « 01:42 » est ambigu, décompte ou temps écoulé. Mandat : « Visite 1/2 · 01:42 » correspond à la visite actuelle, et §5 Classe demande d'afficher le **temps restant** : trancher, puis ajouter une étiquette accessible.
  - Le chevron retour doit se comporter comme « Quitter », avec la sortie existante, et pas comme une navigation qui laisserait la connexion ouverte.
  - L'état « Son reçu » coupé ou rétabli ne doit pas être encodé que par la couleur.
  - Le thème de la salle n'est pas fixé : M3 est sombre, M4 et D1 sont clairs. Les deux thèmes sont à livrer.

### M4 - Salle d'observation, visite 2/2 (mobile, clair)

- Zone : x 196-551, y 612-1005.
- Même composition que M3, avec les variations suivantes :
  - Chips « ● En direct » (vert clair #DEFDE9) et « Visite 2/2 · 01:18 » (lavande #F0EBFE, texte violet).
  - Support dans une carte à bordure fine.
  - **Commandes en ligne horizontale** (icône dans un cercle lavande, libellé à droite) : « Son reçu », « Agrandir », et « Quitter » en pilule rouge doux (#FEE0E6) avec icône de sortie.
- Textes exacts : « 9:41 », « Classe An-Nour », « Mariam · Sayyida Amina », « En direct », « Visite 2/2 · 01:18 », « Lecture · Les lettres », « ba », « ta », « tha », « Sayyida Amina », « Mariam », « Son reçu », « Agrandir », « Quitter ».
- À ne pas reproduire :
  - **Trois styles différents de barre de commandes** pour le même écran : M3 (vertical, Quitter plein), M4 (horizontal, Quitter doux), D1 (Son reçu dans un cercle vert, Agrandir en contour, Quitter doux avec icône de combiné raccroché). En choisir un par format et le centraliser.
  - L'icône « Quitter » varie aussi : flèche de sortie sur mobile, combiné sur bureau.
  - Même défaut de kasra sous ب (loupe `M_zoom_arabe_e4`).

### M5 - Première visite terminée (mobile, clair)

- Zone : x 590-947, y 612-1005. Écran de résultat centré, sans en-tête ni barre de navigation.
- Composition :
  - Grand cercle lavande (~92 dp) avec un œil violet et un badge de coche verte.
  - Titre héros sur 2 lignes (~22 dp, 700).
  - Sous-titre gris.
  - Encart lavande : icône horloge dans un cercle, texte sur 2 lignes.
  - CTA doux pleine largeur.
  - Lien violet souligné.
- Textes exacts : « Votre première visite est terminée », « La séance continue pour Mariam. », « Il vous reste une visite de 2 minutes. Revenez plus tard pour l'écouter. », « Retour à la classe → », « Voir mes observations ».
- À ne pas reproduire :
  - « une visite de 2 minutes » vient du nombre réel de visites restantes renvoyé par le serveur (observation §5 « Après : afficher le nombre réel »).
  - Variantes absentes à dériver : visites épuisées, durée atteinte, fin de séance, sortie volontaire, interruption.
  - « Voir mes observations » mène à Historique, segment Observations (D2).

### M6 - Consentement « Les visites des parents » (mobile, clair, onboarding)

- Zone : x 985-1342, y 612-1005.
- Composition :
  - En-tête avec chevron et titre.
  - Groupe de 2 éléments (cercle lavande avec icône violette, titre gras, corps gris), dans une surface très discrète.
  - Ligne-carte avec case à cocher **non cochée**, bordure #F0F1F5-ish et fond #F9FAFC.
  - CTA « Continuer » **désactivé** (#E2DCFB, texte #8C80D2).
  - Lien « Retour ».
  - Pas de barre de navigation.
- Textes exacts : « Les visites des parents », « Les parents des élèves présents peuvent observer brièvement la séance. », « Ils entendent l'enseignant et les élèves qui prennent la parole, y compris votre enfant. Leur micro et leur caméra restent désactivés. », « Pour suivre l'apprentissage sans interrompre la classe. », « J'accepte ces modalités pour mon enfant », « Continuer », « Retour ».
- À ne pas reproduire :
  - Le texte diffère du texte exigé (observation §6 : « … Ces visites permettent de suivre l'apprentissage sans interrompre la classe : les observateurs ne peuvent ni parler ni activer leur caméra. »). C'est le texte du mandat qui prime.
  - La case parle de « pour mon enfant » : prévoir aussi les formulations « responsable légal » et « élève adulte ».
  - L'accord passe par le mécanisme existant.
  - Les comptes existants ne sont pas considérés comme ayant accepté.
  - Le CTA et la case mesurent moins de 48 dp.

### D1 - Observation en direct sur ordinateur (desktop, clair)

- Zone : panneau 1, x 22-1075, y 85-630. Libellé de planche « 1 OBSERVATION EN DIRECT · ORDINATEUR ».
- Composition :
  1. En-tête de carte :
     - Avatar placeholder lavande (~40 px).
     - « Classe An-Nour » suivi de la chip verte « ● Séance en direct ».
     - Sous-titre « Mariam · Sayyida Amina ».
     - Aligné à droite, « Visite 1/2 · 01:42 », avec « 01:42 » en gras.
  2. Corps en 2 colonnes :
     - **Support à ~77 %** (carte blanche à bordure) : titre centré « Lecture · Les lettres », sous-titre « Lisons ensemble les lettres avec les voyelles. », 3 grandes lettres (ب surlignée lavande en violet profond), chacune avec une carte de variantes dessous.
     - **Colonne vidéos à ~22 %** : enseignante en haut, enfant en bas avec bordure violette de 3 px et barres audio vertes (elle parle). Étiquettes de nom avec icône de personne.
  3. Barre de commandes pleine largeur :
     - « Son reçu » à gauche (icône d'ondes dans un cercle vert pâle, texte sans bouton).
     - « Agrandir » au centre (bouton contour avec icône de cadre).
     - « Quitter » à droite (bouton rouge doux, icône de combiné).
- Textes exacts : « 1 », « OBSERVATION EN DIRECT · ORDINATEUR », « Classe An-Nour », « Séance en direct », « Mariam · Sayyida Amina », « Visite 1/2 · 01:42 », « Lecture · Les lettres », « Lisons ensemble les lettres avec les voyelles. », « Sayyida Amina », « Mariam », « Son reçu », « Agrandir », « Quitter ». En-tête de planche : « Rewayah », « Rewayah · Observation et historique », « 02 · Ordinateur et suivi des visites ».
- Conforme au mandat :
  - Seulement 3 commandes tuteur (observation §7), sans micro, caméra, chat ni réactions.
  - Vignettes secondaires qui ne couvrent pas le support.
  - Mise en page bureau réelle, pas une feuille mobile étirée.
- À ne pas reproduire :
  - **Erreur d'arabe** : dans la carte ث, la variante du milieu est « تِ » (ta) au lieu de « ثِ » (loupe `D_zoom_arabe_lignes`).
  - L'ordre des voyelles diffère entre bureau (ُ ِ َ lu de droite à gauche) et mobile (َ ُ ِ). Le contenu vient de ressources vérifiées.
  - L'avatar placeholder générique remplace à tort le portrait réel de l'enfant ou son fallback.
  - L'effet « elle parle » (bordure et barres audio) ne doit s'afficher que sur un signal réel.

### D2 - Historique, onglet Observations (mobile, sombre)

- Zone : panneau 2, x 1088-1520, y 68-635. Libellé « 2 HISTORIQUE · MOBILE (MODE SOMBRE) ».
- Composition :
  1. Titre « Historique » (grand, 700) et cloche avec pastille.
  2. **Sélecteur de profils horizontal** : 3 avatars ronds (~62 dp), un point d'état en bas à droite (vert, jaune, gris), prénom et état. L'actif a un anneau violet. Un 4e rond « + ».
  3. **Contrôle segmenté** pleine largeur « Séances | Observations » (actif violet sombre).
  4. 3 chips de filtre avec icônes violettes et chevrons : Classe, Période, Statut.
  5. **Liste en carte unique à lignes séparées**. Chaque ligne a une colonne date en gras et une méta grise, un filet vertical, la colonne classe et l'élève, une chip de statut (point, texte) et un chevron.
  6. **Barre de navigation à 4 destinations** : Accueil, Foyer, Historique (actif, icône pleine violette), Compte.
- Textes exacts : « 9:41 », « Historique », « Mariam », « En séance », « Yusuf », « Session 18:00 », « Aicha » (tréma incertain à la loupe), « Dernière séance 1 h », « Ajouter enfant », « Séances », « Observations », « Classe », « Période », « Statut », « 23 sept. 2026 », « 2 visites · 3 min 42 s », « Classe An-Nour », « Mariam », « Terminées », « 21 sept. 2026 », « 1 visite · 2 min », « Terminée », « 18 sept. 2026 », « 1 visite · 48 s », « Interrompue », « Accueil », « Foyer », « Historique », « Compte ».
- À ne pas reproduire :
  - **« Ajouter enfant »** : écrire « Ajouter un profil élève » (§4). Le parent qui a son propre profil n'est pas un « enfant ».
  - **« Session 18:00 »** : écrire « Séance ».
  - « Dernière séance 1 h » est ambigu (il y a 1 h ? durée ?) : à éviter.
  - « Terminées » au pluriel contre « Terminée » : harmoniser.
  - Le fuseau n'est pas indiqué dans la liste (observation §8 : fuseau explicite).
  - La barre de navigation sombre gris neutre #4B4B4B est hors palette.
  - Prénoms, dates et durées sont illustratifs.
  - La ligne 18/09 « Interrompue · 48 s » est absente du tableau admin D3 : jeu de démo incohérent.

### D3 - Historique des observations, administration (desktop, clair)

- Zone : panneau 3, x 22-1075, y 645-1020. Libellé « 3 HISTORIQUE DES OBSERVATIONS · ADMINISTRATION (ORDINATEUR) ».
- Composition :
  - Barre latérale blanche (~170 px) séparée par un filet : logo « Rewayah », 4 entrées icône + libellé, l'active sur fond lavande avec texte violet.
  - Zone principale :
    - Titre et sous-titre.
    - Champ de recherche avec loupe, puis 3 filtres déroulants à droite.
    - **Tableau** à en-tête gris très pâle et 3 lignes séparées par des filets : chip de motif de fin, chevron violet.
    - Note de fuseau en pied.
- Textes exacts : « 3 », « HISTORIQUE DES OBSERVATIONS · ADMINISTRATION (ORDINATEUR) », « Rewayah », « Vue d'ensemble », « Personnes », « Classes », « Historique », « Historique des observations », « Administration », « Rechercher un tuteur ou un élève », « Classe », « Période », « Statut ». Colonnes : « Date », « Tuteur », « Élève », « Classe », « Entrée », « Sortie », « Durée », « Fin ». Lignes :
  - « 23/09/2026 · Fatoumata Diallo · Mariam · An-Nour · 18:12:00 · 18:14:00 · 2 min · Limite atteinte »
  - « 23/09/2026 · Fatoumata Diallo · Mariam · An-Nour · 18:35:00 · 18:36:42 · 1 min 42 s · Départ volontaire »
  - « 21/09/2026 · Fatoumata Diallo · Mariam · An-Nour · 18:10:00 · 18:12:00 · 2 min · Limite atteinte »
  - Pied : « Heures affichées : Europe/Paris ».
- À ne pas reproduire :
  - La barre latérale « Vue d'ensemble / Personnes / Classes / Historique » n'est pas une spec. Réutiliser la navigation admin existante (observation §8).
  - Le filtre « Statut » ne correspond à aucune colonne « Statut » (seulement « Fin ») : clarifier.
  - Le mandat demande des filtres par tuteur, élève, classe, période et statut. Ici tuteur et élève ne passent que par la recherche.
  - Pas d'action d'édition ni de suppression. Aucune ne doit être ajoutée (observation §8).
  - Les noms (« Fatoumata Diallo ») sont illustratifs.

### D4 - Détail d'une observation (mobile, clair)

- Zone : panneau 4, x 1088-1520, y 645-1020. Libellé « 4 DÉTAIL D'UNE OBSERVATION · MOBILE (MODE CLAIR) ».
- Composition :
  - Lien retour violet « ‹ Observations ».
  - Titre « Classe An-Nour », sous-titre « Mariam · 23 septembre 2026 », légende « Sayyida Amina ».
  - Carte d'infos à 2 lignes (icône violette, libellé gris, valeur à droite).
  - Carte de visites à 2 lignes. Chaque ligne : « Visite n » en gras et plage horaire dessous, durée et chip de motif à droite.
  - Note « Heure de Paris ».
  - CTA doux pleine largeur avec flèche gauche.
- Textes exacts : « 9:41 », « Observations », « Classe An-Nour », « Mariam · 23 septembre 2026 », « Sayyida Amina », « Tuteur », « Fatoumata Diallo », « Durée totale », « 3 min 42 s », « Visite 1 », « 18:12 – 18:14 », « 2 min », « Limite atteinte », « Visite 2 », « 18:35 – 18:36:42 », « 1 min 42 s », « Départ volontaire », « Heure de Paris », « Retour à l'historique ».
- Conforme : contenu exigé par observation §8 (tuteur, enfant, enseignant, entrée/sortie par visite, durée, motif de fin, fuseau).
- À ne pas reproduire :
  - Format horaire incohérent « 18:35 – 18:36:42 » (secondes d'un seul côté) : unifier.
  - Fuseau en « Heure de Paris » ici et « Europe/Paris » en D3 : un seul format localisé, dérivé de l'IANA.
  - Apostrophe droite dans « l'historique » et « Vue d'ensemble », contre l'apostrophe typographique ailleurs.
  - Le CTA mesure ~29 dp : porter à 48 dp.
  - Seuls 2 motifs de fin sont dessinés. Il manque « Fin de séance » et « Interrompue » (vus en D2), à styliser de la même façon.

## 5. Synthèse des pièges (confrontés au mandat)

1. **Planche 3 absente** (états particuliers et notices de présence). Aucune référence visuelle pour :
   - les états : enfant absent, présence en vérification, visites épuisées, séance non commencée ou terminée, observation désactivée, connexion prolongée, échec, reconnexion, caméra désactivée, aucun support ;
   - les notices enseignant/enfant (« Votre maman… » / « Votre parent… »).
   Il faut dériver ces écrans des composants de M1-M5 et consigner la dérivation (mandat §2). Ou obtenir le fichier.
2. **Contenu arabe faux** dans les supports (ث/ت confondus sur bureau, kasra manquante sous ب sur mobile, ordres de voyelles différents). Le support est un document partagé réel, jamais une constante.
3. **Constantes illustratives** : 2 visites, 2 min, 01:42, 01:18, 1 h 00, 3 min 42 s, dates, noms (Mariam, Yusuf, Aicha, Sayyida Amina, Fatoumata Diallo), « Niveau 1 », Europe/Paris. Tout vient de la politique effective et des données (observation §2 et §4).
4. **Anciennes appellations en D2** : « Ajouter enfant » (→ « Ajouter un profil élève »), « Session » (→ « Séance »). « Dernière séance 1 h » est ambigu.
5. **Libellé interdit** : « Cours en cours » n'apparaît nulle part (vérifié). Les planches emploient « Séance en direct », « En direct », « En séance », conformes.
6. **Navigation** : M1 et D2 ont bien 4 destinations dans l'ordre Accueil · Foyer · Historique · Compte, conforme. En sombre, la barre gris neutre est à normaliser.
7. **Incohérences de composants** : 3 styles de barre de commandes, 2 icônes « Quitter », 2 fonds sombres, 2 couleurs de texte de CTA doux (noir en M1/M2/M5, violet en D4).
8. **Cibles tactiles sous 48 dp** : CTA de ~40 dp (M1), ~29 dp (D4), lignes de liste ~44 dp, case à cocher.
9. **Ambiguïté du chronomètre** : décompte ou temps écoulé, à trancher (observation §5 et mandat §5 « temps restant »).
10. **Coquille « quii »** en M2. Textes de consentement et d'aide à aligner mot pour mot sur le mandat (observation §6).
11. Aucun écran ne montre de CTA violet **plein** : tous les CTA principaux sont « doux » (lavande, texte foncé). Le seul bouton plein est « Quitter » rouge en sombre.

## 6. Typographie observée

- Une seule famille apparente sur les deux planches : une sans-serif géométrique à « a » double étage, « y » droit et chiffres tabulaires propres, proche de **Plus Jakarta Sans** ou **DM Sans**. L'image générée ne permet pas de trancher entre les deux.
- Graisses apparentes :
  - 800 : titres de planche (« Rewayah · Observation tuteur »).
  - 700 : titres de page et héros.
  - 600 : titres de carte, CTA, dates de ligne, valeurs.
  - 500 : libellés de liste et de navigation.
  - 400 : corps et légendes.
  - Les libellés de section de planche sont en capitales 700 violet foncé (#2D277D) et violet (#6E58CF). C'est de la présentation, pas un style d'app.
- Règle écrite qui prime (observation §1 et §2) : **DM Sans pour les titres français** (titre de page, section, héros, titre de carte) et **Plus Jakarta Sans pour tout le reste** (corps, libellés, boutons, champs, navigation, légendes, statuts, chronomètre).
- Rappel BRIEF : aucune des deux polices n'est présente dans le dépôt (InstrumentSans et BricolageGrotesque). C'est une dépendance du coordinateur.
- L'arabe du support garde ses polices dédiées (NotoSansArabic, UthmanTahaNaskh).
- Chiffres du chronomètre : chiffres tabulaires recommandés, pour éviter le tremblement de « 01:42 ».

## 7. Points ouverts pour le coordinateur

- Obtenir la planche 3 (« États particuliers et notices de présence »), ou valider une dérivation.
- Route du détail d'observation (D4) absente de §4 : décider d'une sous-route sans créer un second système d'historique.
- Thème de la salle d'observation : les deux thèmes sont montrés (M3 sombre, M4/D1 clair). Suivre le thème de l'app.
- Style unique de la barre de commandes par format (mobile/bureau) et icône « Quitter » unique.
- Chronomètre en décompte ou en temps écoulé.
