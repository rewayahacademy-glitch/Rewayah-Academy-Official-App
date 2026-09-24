# V5 - Onboarding mobile portrait : relevé visuel

Agent de relevé V5, 24/09/2026, lecture seule. Aucun fichier du dépôt n'a été modifié.
Sources lues : `pilotage-tuteur-v1/BRIEF.md` ; mandat `REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§2, §4, §5, §6, §7, §9 et « Prompt étape observation tuteur ») ; code existant cité pour les écarts (`lib/features/inscription/inscription_page.dart`, `lib/core/widgets/page_parcours.dart`, `lib/core/widgets/choice_card_group.dart`, `lib/core/theme/*.dart`, `assets/i18n/fr.i18n.json`).

## 0. Réponse à l'indication du coordinateur

- **« d » ne veut pas dire « dark ».** Les deux fichiers sont **en thème sombre** et montrent **deux étapes différentes** du même questionnaire : `onboarding Mble.png` = étape « 2 sur 5 » (type de compte / usage), `onboarding Mble d.png` = étape « 3 sur 5 » (genre). **Aucune variante claire** dans ce groupe : le thème clair devra être dérivé et documenté (§9), sauf si un autre groupe (ex. `onboarding mobile 1.png`, `Onboarding mobile 2.png`) en fournit une.
- **Ce ne sont pas des planches de direction.** Chaque fichier est un écran unique plein cadre (barre d'état iOS « 9:41 », indicateur d'accueil iOS en bas), sans légende, sans échantillon, sans annotation. Statut : **nouveau high-fi** (image générée, voir artefacts §6).

## 1. Manifeste

| Id | Fichier exact | Zone | Écran représenté | Route logique (§4) | Route / code existant | État | Thème | Format | Statut |
|---|---|---|---|---|---|---|---|---|---|
| V5-A | `D:\RA _APP\docs de lancement\tutuor image\onboarding Mble.png` (941×1672 px) | image entière | Choix d'usage : « Quel type de compte souhaitez-vous créer ? » | `/onboarding/usage` (« Pour qui souhaitez-vous utiliser Rewayah ? ») | **Absent** : aucune clé ni page d'usage ; l'étape 1 actuelle est le choix de rôle (`inscription_page.dart:127-173`, `fr.i18n.json:159-162`) | Nominal, option 2 **sélectionnée**, CTA actif | Sombre | Mobile portrait | Nouveau high-fi |
| V5-B | `D:\RA _APP\docs de lancement\tutuor image\onboarding Mble d.png` (941×1672 px) | image entière | Question d'identité : « Quel est votre genre ? » | `/onboarding/...` (Questionnaire, identité du titulaire) | `/inscription`, page 3/4 `_pageGenre` (`inscription_page.dart:208-240`, textes `fr.i18n.json:168-171`) | Nominal, « Homme » **sélectionné**, CTA actif | Sombre | Mobile portrait | Nouveau high-fi |

Tuiles d'inspection (agrandies ×2, toutes ouvertes) : `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V5_A_t1.png`, `V5_A_t2.png`, `V5_A_t3.png`, `V5_B_t1.png`, `V5_B_t2.png`, `V5_B_t3.png` (bandes 0-600, 560-1160, 1120-1672 px).

## 2. Méthode et échelle

- Échantillonnage par PowerShell/System.Drawing (lecture en `LockBits`), couleurs = **mode** des pixels de la zone (quantification 5 bits) sauf mention contraire ; coordonnées en px de l'image source.
- **Échelle retenue : 941 px = 390 dp, soit 2,413 px/dp.** Contrôle : l'indicateur d'accueil iOS mesure 330 px × 11 px = 137 × 4,6 dp (nominal iOS 134 × 5 pt), cohérent à 2 % près.
- **Attention au cadre 16:9** : 1672 px = **693 dp de haut** seulement, alors qu'un mobile courant fait 390 × 844 dp. Les espacements verticaux ci-dessous sont donc comprimés : en implémentation, contenu en haut, CTA ancré en bas au-dessus de la zone sûre, espace flexible entre les deux. Ne pas copier les distances verticales absolues.

## 3. Tokens mesurés

### 3.1 Couleurs (HEX mesurés)

| Rôle | V5-A (coordonnées) | V5-B (coordonnées) | Proposition de jeton sombre |
|---|---|---|---|
| Fond de page | `#161621` (300-700, 230-270) ; `#151520` (300-700, 575-605) ; coin haut gauche `#1C1C2A`, coin haut droit `#13131E` | `#181824` (300-700, 520-580) ; `#161621` (300-700, 1590-1620) | `#161622`, aplat (léger vignettage facultatif, plus clair en haut à gauche) |
| Surface carte (non sélectionnée) | `#1C1C29` (560-760, 630-660) ; `#1C1D2A` (560-860, 850-890) | `#1E1E2B` (510-780, 620-660) ; `#1E1E2A` (510-870, 1050-1100) | `#1C1D2A` |
| Bordure carte (non sélectionnée), ~1 dp | `#3C3D54` (48, 760) ; `#393B4E` (470, 615) | `#3B3B50` (482, 860) ; `#38384C` (680, 605) | `#3B3C52` |
| Surface carte sélectionnée | `#242139` haut (560-760, 945-980) vers `#28233E` bas (560-860, 1290-1320) | `#2D2845` (80-350, 620-660) ; `#2B2643` (80-430, 1050-1100) | `#28233F` (dégradé vertical léger facultatif) |
| Bordure sélectionnée, ~2 dp | `#D1B0FF` (47, 1130) ; `#DCBAFF` (470, 930) | `#D8ABFE` (49, 860) ; `#C99EF8` (250, 605) | `#CFA8FC` |
| Halo de sélection (fond voisin) | `#1B192B` à gauche de la carte sélectionnée (20-40, 1100-1160) contre `#14141E` à côté de la carte non sélectionnée (20-40, 730-790) | `#201D34` sous la carte « Homme » (80-430, 1125-1145) contre `#161721` sous « Femme » | Ombre portée accent ~15 % d'opacité, flou ~16 dp |
| Texte principal | `#FCFBFC` titre (62-480, 295-440, L>200) ; `#FCFCFD` titres de carte | `#FBFBFC` titre ; `#FCFCFC` « Homme »/« Femme » | `#FCFCFD` |
| Texte secondaire (page) | `#A9ADCB` sous-titre (62-810, 478-565) | `#AAADD2` sous-titre (62-505, 430-470) | `#AAAECE` |
| Texte secondaire (dans carte) | `#B4BBDA` (278-705, 760-840) ; `#BCC2E3` (278-760, 1120-1280) | - | `#B8BFDE` |
| Compteur d'étape | `#BBC2E3` (775-885, 145-182) | `#BCC2EB` (770-880, 145-182) | = texte secondaire carte |
| Accent texte (mot du titre) | mode `#D4BAFB`, cœur saturé `#C29AF9` @588,344 (« compte ») | mode `#CAABFB`, cœur `#C39DFF` @661,376 (« genre ») | `#C9A8FB` (≈ `inkAccent` sombre existant `#C9AEFF`) |
| **CTA plein** | `#BC99FA` (mode 100-880, 1440-1560) ; haut `#BF9DFB` (y 1440-1446), bas `#B794FC` (y 1555-1561) | `#BA93FB` (mode) ; haut `#C29CFB`, bas `#B78FFC` | `#BC98FA` (dégradé vertical `#C09CFB` vers `#B893FB` facultatif) |
| Texte sur CTA | `#010103` (355-595, 1480-1520, L<60) | `#020102` | `#0B0A10` ou noir ; contraste mesuré ≈ 7,8:1 |
| Barre de progression remplie | `#BA94FB` (270-420, 157-167) | `#B58DFC` (270-470, 157-167) | = CTA plein |
| Piste de progression | `#3A3B4E` (450-680, 157-167) | `#39394D` (510-680, 157-167) | `#3A3B4E` |
| Bouton retour (fond) | `#2D2E3E` (66-84, 150-170), liseré `#36374C` (57, 160) | `#303042` | `#2E2F40` |
| Cercle d'icône non sélectionné | `#2B2C3C` (100-118, 745-780), liseré `#343749` (91, 763) | `#2E2E40` (590-610, 800-870), liseré `#3B3C51` (582, 835) | `#2D2E3F` |
| Cercle d'icône sélectionné | `#5A4593` (97-112, 1075-1100), liseré `#6851AE` (91, 1090) | `#3D3166` (155-175, 800-870), liseré `#564091` (147, 835) | **Incohérent entre les deux écrans** : choisir un seul jeton (proposition `#4A3A80`) |
| Pictogramme | non sélectionné `#D3D2F3` (140-190, 730-795) ; sélectionné `#E4DDFC` ; icône famille bicolore : centre `#CDC3F8`, côtés `#B294FB`/`#BBA2FA` | `#DCD3FC` (H), `#DDD9FC` (F) | `#DCD6FA` + accent pour la bicolorie |
| Radio vide (anneau ~1,5 dp) | `#636582` (785-845, 690-750) | `#636482` (802-862, 638-698) | `#636582` (contraste ≈ 3,0:1 sur la carte, limite basse) |
| Radio pleine (anneau + point) | `#BC9AFA` (800-830, 1012-1042) | `#BB93FB` (383-413, 653-683) | = CTA plein |
| Indicateur d'accueil | `#F9F9FA` (470, 1636) | `#F6F6F7` | Système iOS, **ne pas reproduire** |

**Non mesurables sur ces deux écrans** (absents) : pastilles de statut vert/orange/rouge/gris, bandeau d'alerte, onglet actif de navigation. L'onboarding n'a pas de barre de navigation : c'est normal, aucun shell Tuteur ne doit apparaître dans l'admission.

### 3.2 Dimensions (px mesurés, puis dp à 2,413 px/dp)

| Élément | V5-A | V5-B | Proposition |
|---|---|---|---|
| Gouttière du texte (titre, sous-titre) | titre x=62 px = 25,7 dp (approche du « Q » incluse) | x=63 px | **24 dp** (existant `gouttiereMobile` = 16 dp, `app_spacing.dart:65`) |
| Gouttière cartes et CTA | cartes x=47 et 893 px = 19,5 dp de chaque côté ; CTA x=45-894 px = 18,6 dp | cartes x=48 et 894 px | **20 dp** |
| Bouton retour | cercle 100 × 97 px = **41 × 40 dp**, x 57-157 (23,6 dp du bord), y 110-207 | idem (58-158, 111-208) | visuel 40 dp dans une **cible de 48 dp** (§9) |
| Barre de progression | x 252-687 = 180 dp de large, y 152-171 = **8 dp** de haut, centrée ; remplissage 253-431 = 41 % (2/5) | remplissage 253-489 = 54 % (≠ 60 % attendu pour 3/5) | pilule 8 dp, rayon 4 dp ; largeur flexible entre retour et compteur |
| Compteur « n sur N » | x 781-877, bord droit à 26,5 dp ; chiffres 23 px = 9,5 dp de haut | x 774-874 | texte 14 dp, aligné à droite sur la gouttière 24 dp |
| Centre vertical de l'en-tête | y=160 px = 66 dp (barre d'état système au-dessus) | idem | en-tête ~48 dp sous la zone sûre |
| En-tête vers titre | 207 → 296 px = 37 dp | 208 → 331 px = 51 dp | 32-40 dp |
| Titre | 2 lignes, y 296-428 ; capitale 48 px = 20 dp ; x-height 36 px = 15 dp ; interligne 82 px = **34 dp** | 1 ligne, y 331-397 | **28-30 dp**, graisse 800, interligne 1,15 |
| Titre vers sous-titre | ~12 dp entre boîtes (base 427 → haut 481) | ~15 dp | 12 dp |
| Sous-titre | capitale 28 px = 11,6 dp ; x-height 8,1 dp ; interligne 50 px = 20,7 dp | capitale 28 px | **16 dp**, 400, interligne 1,3 |
| Sous-titre vers premières cartes | 57 px = 24 dp | 136 px = 56 dp | 24-32 dp |
| Carte liste (A) | 847 × 290 px = **351 × 120 dp** (carte 1) ; 848 × 411 px = 351 × 170 dp (carte 2) ; écart 24 px = **10 dp** | - | hauteur au contenu (existant `hauteurChoix` = 112 dp), écart 12 dp |
| Rayon carte | début du segment droit à 33-36 px = **14-15 dp** | 29-30 px = **12 dp** | un seul jeton : **16 dp** (`AppRadius.md`) |
| Bordure carte | ~2-3 px = 1 dp (non sél.) ; ~4 px = 1,5-2 dp (sél.) | idem | 1 dp / 2 dp |
| Marges internes carte liste | cercle à 43 px = 18 dp du bord gauche ; texte à 233 px = 96,5 dp du bord ; 17 dp entre cercle et texte ; bloc texte centré verticalement (~30 dp haut/bas) | - | 18-20 dp horizontal, ≥ 24 dp vertical |
| Cercle d'icône | 150 px = **62 dp** ; pictogramme ~66 px = 27 dp | 216 px = **89 dp** ; pictogramme ~44 dp | 64 dp (liste) / 88 dp (grille) |
| Radio | anneau 57-59 px = **24 dp**, point intérieur 37 px = 15 dp ; à 20,7 dp du bord droit, aligné sur la 1re ligne du titre de carte (pas centré) | 24 dp, point 15 dp ; en coin haut droit, à 14,5 dp du haut et du bord | 24 dp visuel |
| Carte grille (B) | - | 413 × 518 px = **171 × 215 dp** chacune, écart 20 px = **8 dp**, deux colonnes | colonnes égales, écart 12 dp |
| Libellé sous le cercle (B) | - | 18 dp sous le cercle ; libellé centré | - |
| CTA | 850 × 133 px = **352 × 55 dp**, pilule (rayon 27,5 dp) ; libellé + flèche centrés, flèche 15 dp à 14 dp du libellé | 850 × 134 px | **56 dp** de haut (existant `hauteurBouton` = 52 dp, `app_spacing.dart:80`), `AppRadius.full` |
| CTA vers bas d'écran | 106 px = 44 dp (inclut l'indicateur d'accueil) | 122 px = 51 dp | 16 dp + zone sûre |

### 3.3 Tailles de texte approximatives par niveau

| Niveau | Mesure | Taille estimée | Graisse observée |
|---|---|---|---|
| Titre de page (question) | capitale 20 dp, x-height 15 dp | 28-30 dp | ExtraBold (~800) |
| Titre d'option (carte liste) | capitale 11,2 dp (« Moi », y 705-732) | 16-17 dp | Bold (700) |
| Libellé d'option (grille) | capitale 13,3 dp (« H », y 986-1018) | 18-19 dp | Bold (700) |
| Corps / sous-titre | capitale 11,6 dp | 16 dp | Regular (400) |
| Description d'option | capitale 9,1 dp, x-height 6,2 dp, interligne 17,5 dp | 13-14 dp | Regular (400) |
| Compteur d'étape | chiffres 9,5 dp | 13-14 dp | Regular/Medium |
| Libellé CTA | capitale 12,8 dp | 18 dp | Bold (700) |

## 4. Fiche V5-A - « Quel type de compte souhaitez-vous créer ? »

- **Fichier** : `onboarding Mble.png`, image entière, écran unique.
- **Écran** : choix d'usage de l'admission, étape 2 d'un parcours à 5 étapes (total illustratif).
- **Route logique** : `/onboarding/usage`. N'existe pas aujourd'hui : l'inscription actuelle enchaîne rôle, identité, genre, récapitulatif (`inscription_page.dart:119-124`, `_pages = 4` ligne 49).
- **État** : nominal, option « Moi et les membres de ma famille » sélectionnée, CTA actif. L'état initial (rien de sélectionné, CTA désactivé) n'est pas dessiné.
- **Thème / format / statut** : sombre ; mobile portrait ; nouveau high-fi.

**Composition, de haut en bas (une seule colonne)** :
1. Barre d'état système iOS (« 9:41 », réseau, wifi, batterie) : système, ne pas dessiner.
2. En-tête de parcours sur une ligne : bouton retour circulaire (flèche gauche blanche, trait ~2 dp, fond `#2D2E3E`) à gauche ; barre de progression pilule centrée ; compteur « 2 sur 5 » aligné à droite, couleur secondaire.
3. Titre sur deux lignes, aligné à gauche, très gras, blanc, **un mot en accent** (« compte » en `#C9A8FB`), espace insécable avant « ? ».
4. Sous-titre sur deux lignes, gris lavande, régulier.
5. Liste verticale de deux cartes de choix pleine largeur (gouttière 20 dp), chacune : cercle d'icône à gauche (centré verticalement), bloc texte (titre gras + description), radio en haut à droite alignée sur le titre.
   - Carte 1 non sélectionnée : surface `#1C1D2A`, bordure 1 dp `#3C3D54`, cercle gris `#2B2C3C`, pictogramme personne pleine lavande clair.
   - Carte 2 sélectionnée : surface violette sombre `#28233F`, bordure 2 dp lilas `#CFA8FC` avec halo extérieur, cercle violet `#5A4593`, pictogramme groupe de trois personnes bicolore (centre clair, côtés violets), radio pleine lilas.
6. Espace libre flexible.
7. CTA pilule pleine largeur « Continuer » + flèche droite, fond lilas `#BC99FA`, texte presque noir.
8. Indicateur d'accueil iOS : système.

**Densité et style** : très aéré, une question par écran, un seul CTA dominant, aucune carte imbriquée, aucun séparateur. Iconographie **pleine** (remplie), arrondie, proche des variantes « Fill » de Phosphor (`User`, `UsersThree`) déjà présentes dans le dépôt. Pas d'ombre sur les cartes non sélectionnées ; halo coloré uniquement sur la sélection.

**Textes lisibles (recopiés exactement)** :
- « 9:41 » (système)
- « 2 sur 5 »
- « Quel type de compte souhaitez-vous créer ? » (« compte » en accent)
- « Choisissez l’option qui correspond le mieux à votre situation. »
- « Moi uniquement »
- « Convient à une personne qui s’inscrit pour elle-même. » (rendu « per sonne » avec un blanc parasite, artefact)
- « Moi et les membres de ma famille » (retour à la ligne après « membres »)
- « Convient aux familles qui veulent inscrire plusieurs membres et centraliser le suivi, les appareils et les paiements. » (le mot « familles » est rendu plus clair que le reste, artefact)
- « Continuer » + flèche

**Erreurs métier ou incohérences à ne pas reproduire** :
1. **Titre « Quel type de compte souhaitez-vous créer ? »** : laisse croire à deux types de compte figés. Le mandat (§6) dit que le compte gestionnaire existe séparément des profils élèves et que le choix initial n'est pas un verrou. Le §4 donne le titre « Pour qui souhaitez-vous utiliser Rewayah ? ». Garder la composition (mot en accent), changer le texte.
2. **Libellé « Moi et les membres de ma famille »** : le mandat dit « Moi et ma famille » ; « Moi et… » suggère que le parent sera élève lui-même. La description imposée lève l'ambiguïté.
3. **Descriptions de la maquette à remplacer** par les textes du directeur (§6) :
   - Moi uniquement : « Je souhaite suivre les cours avec mon propre profil élève. »
   - Moi et ma famille : « Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment. »
   La maquette promet de « centraliser … les paiements » et parle de « plusieurs membres » (un seul enfant est aussi un usage familial) : ne pas promettre de fonction financière non vérifiée.
4. **Pas de troisième carte** « Mes enfants uniquement » (§6). Mais l'**inscription enseignant** doit rester atteignable (§4 : « sans oublier inscription enseignant » ; rôle existant `roleEnseignant`, `fr.i18n.json:162`) : prévoir un lien secondaire discret, pas une troisième grande carte.
5. **Carte « Autre » systématique** : `ChoiceCardGroup` ajoute toujours une carte « Autre » (ADR-013, `choice_card_group.dart:46-52`). La maquette n'en montre pas, et une saisie libre n'a pas de sens pour ce choix. Contradiction à trancher par le coordinateur, pas en silence.
6. **Sélection préremplie** : l'option 2 sélectionnée illustre l'état « choisi ». L'état initial est vide, avec le CTA désactivé (comportement actuel `onAction: … == null ? null`, `inscription_page.dart:134`).
7. **« 2 sur 5 »** : total illustratif. Le total dépend des branches (§6) ; clé existante « Étape {n} sur {total} » (`fr.i18n.json:157`). Ne pas écrire 5 en dur.
8. Choisir l'usage familial **ne crée pas** de profil élève pour le parent et ne l'engage à rien pour lui-même (§6).
9. Artefacts d'image : « per sonne », « familles » surligné, liseré sombre autour des glyphes (pixels `#000000` mesurés dans les lettres, ex. @92,409) : pas d'ombre de texte à reproduire.

## 5. Fiche V5-B - « Quel est votre genre ? »

- **Fichier** : `onboarding Mble d.png`, image entière, écran unique.
- **Écran** : question d'identité du titulaire (genre), étape 3 sur 5 (illustratif).
- **Route logique** : `/onboarding/...` (Questionnaire, identité). Existant : page 3/4 de `/inscription` (`_pageGenre`, `inscription_page.dart:208-240`).
- **État** : nominal, « Homme » sélectionné, CTA actif. État initial (aucun choix, CTA désactivé) non dessiné.
- **Thème / format / statut** : sombre ; mobile portrait ; nouveau high-fi.

**Composition, de haut en bas** :
1. Barre d'état système.
2. En-tête identique à V5-A (retour circulaire, progression, « 3 sur 5 »).
3. Titre sur une ligne « Quel est votre genre ? », « genre » en accent.
4. Sous-titre une ligne.
5. **Grille de deux cartes côte à côte** (171 × 215 dp, écart 8 dp), contenu centré : grand cercle (89 dp) avec pictogramme plein, libellé gras centré dessous, radio en coin haut droit.
   - « Homme » sélectionné : surface `#2B2643`, bordure lilas 2 dp + halo, cercle `#3D3166` à liseré `#564091`, radio pleine.
   - « Femme » non sélectionné : surface `#1E1E2B`, bordure `#3B3B50`, cercle `#2E2E40`, radio vide `#636482`.
6. Grand espace libre.
7. CTA « Continuer » + flèche identique à V5-A.
8. Indicateur d'accueil système.

**Textes lisibles (recopiés exactement)** : « 9:41 » ; « 3 sur 5 » ; « Quel est votre genre ? » (« genre » en accent) ; « Sélectionnez une option. » ; « Homme » ; « Femme » ; « Continuer » + flèche.

**Erreurs métier ou incohérences à ne pas reproduire** :
1. **Raison de la question supprimée** : l'existant explique « Cette réponse ne sert qu'à confier votre pièce d'identité à un membre du personnel du même genre. » (`fr.i18n.json:171`, affichée par `inscription_page.dart:214`). La maquette la remplace par « Sélectionnez une option. », un texte de remplissage. **Garder la raison** à la place du sous-titre.
2. **Pour qui la question est posée** : ici le titulaire (vérification de sa pièce). En usage familial, le genre éventuel d'un élève se demande dans le formulaire élève avec son prénom en contexte (§6). Ne pas recopier la réponse du parent sur un enfant.
3. **« Homme » présélectionné** : ne jamais présélectionner un genre. État initial vide, CTA désactivé (`inscription_page.dart:216`).
4. **Carte « Autre »** : l'existant affiche une carte « Autre » qui mène à un refus (`_horsParcours`, `inscription_page.dart:217-220, 237`). La maquette n'en a pas. À trancher (même point que V5-A n°5).
5. **Grille à deux colonnes à 390 dp** : le seuil actuel `seuilChoixDouble = 560` (`app_gabarit.dart:70`) empilerait les deux cartes sur mobile. Le high-fi impose deux colonnes à 390 dp ; prévoir le repli en pile quand le texte est agrandi (200 %) ou sur très petit écran.
6. **Pictogramme féminin** (personne avec coupe au carré, cheveux visibles) : son adéquation au public de l'académie est à faire arbitrer par le directeur. Phosphor n'a pas d'équivalent « femme » rempli ; ne pas importer une illustration ad hoc sans décision.
7. Libellés : maquette « Homme » / « Femme » et « Quel est votre genre ? » contre l'existant « Un homme » / « Une femme » et « Vous êtes ». Choix éditorial, pas une erreur ; garder une seule source i18n.
8. **« 3 sur 5 »** : même remarque que V5-A. De plus, le remplissage mesuré (54 %) ne correspond pas à 3/5 (60 %) : la valeur visuelle de l'image n'est pas une référence.

## 6. Composants communs dérivés

| Composant | Anatomie relevée | Écart avec l'existant |
|---|---|---|
| En-tête de parcours | bouton retour icône seule 40 dp · barre continue 8 dp · « n sur N » à droite | Existant : bouton texte « Retour » tertiaire et barre **segmentée** (`page_parcours.dart:88-110`, commentaire « Des segments plutôt qu'une barre continue », ligne 151). Le high-fi montre une barre continue : contradiction à trancher (ordre d'arbitrage §2 : high-fi n°3 avant bible n°5). Garder `Semantics(label: « Étape n sur N »)` et le libellé « Retour » en sémantique ; cible de 48 dp. |
| Titre à mot accentué | titre blanc, un mot en accent | Nécessite un texte riche i18n (slang) ; la couleur est décorative, elle ne porte pas de sens. |
| Carte de choix en liste | cercle d'icône 64 dp · titre + description · radio 24 dp en haut à droite | `ChoiceCardGroup` existant (hauteur 112 dp) ; ajouter le style « liste avec description ». |
| Carte de choix en grille | carte haute, cercle 88 dp centré, libellé centré, radio en coin | Nouveau style ; deux colonnes dès 390 dp. |
| Radio | anneau 24 dp, 1,5 dp ; sélectionné : anneau + point 15 dp accent | La sélection est aussi portée par la bordure, la surface et le halo : pas seulement la couleur (§9). |
| CTA principal | pilule 56 dp, fond accent, libellé gras presque noir + flèche droite | Existant 52 dp (`app_spacing.dart:80`) ; `onPrimary` sombre existant `#25113F` contre `#010103` ici. |
| Absent du high-fi | « Environ {minutes} min » sous le CTA (`page_parcours.dart:123-129`) | Garder ou retirer : à trancher. |

**Écart de palette avec le thème sombre actuel** (`app_palette.dart:115-182`) : l'existant est violet chaud (canvas `#111014`, raised `#1A181F`, sunken `#24212B`, `inkMuted` `#BAB3C5`, primaire `#C9AEFF` / `#25113F`). Le high-fi est **bleu-violet** (fond `#161622`, surface `#1C1D2A`, secondaire `#AAAECE`) avec un primaire plus saturé `#BC98FA`. Seul `inkAccent` `#C9AEFF` correspond déjà (≈ `#C9A8FB` mesuré). Ces valeurs relèvent du coordinateur (propriétaire unique des jetons).

## 7. Typographie

- **Observée** : une sans géométrique moderne, proche de Plus Jakarta Sans ou d'une grotesque géométrique ; sur une image générée, la famille exacte **ne peut pas être identifiée de façon fiable**. Graisses : titre ExtraBold (~800) ; titres d'option, libellés de grille et CTA Bold (700) ; sous-titre, descriptions et compteur Regular (400). Apostrophes typographiques (’) et espace avant « ? » visibles : utiliser U+2019 et une espace fine insécable U+202F.
- **Règle écrite (prévaut)** : **DM Sans** pour les titres en français (ici les deux questions, style titre de page) ; **Plus Jakarta Sans** pour tout le reste (sous-titre, titres et descriptions d'option, compteur, CTA). Point à trancher au niveau des jetons : si le titre d'option (« Moi uniquement ») est traité comme style « titre », il passe en DM Sans ; comme « libellé », il reste en Jakarta. Selon le BRIEF, ni DM Sans ni Jakarta ne sont présentes dans le dépôt (polices actuelles `InstrumentSans` et `BricolageGrotesque`).

## 8. Thème clair

Aucune maquette claire dans ce groupe. D'après §9, la variante claire se dérive sans inverser naïvement : fond clair légèrement lavande, cartes blanches à bordure fine, accent assombri pour le texte (≥ 4,5:1), CTA accent plein avec texte foncé ou blanc selon le contraste mesuré, halo de sélection très atténué. Documenter cette dérivation et vérifier d'abord si un autre groupe fournit un high-fi clair de l'onboarding.

## 9. Points ouverts pour le coordinateur

1. Titre de l'étape d'usage : texte du §4 (« Pour qui souhaitez-vous utiliser Rewayah ? ») plutôt que « Quel type de compte… », en gardant la composition.
2. Accès à l'inscription enseignant depuis l'étape d'usage (lien secondaire) : placement à décider.
3. Carte « Autre » d'ADR-013 contre des maquettes à deux options sans « Autre » (usage et genre).
4. Barre continue (high-fi) contre barre segmentée (existant documenté).
5. Gouttières 20/24 dp contre 16 dp ; CTA 56 dp contre 52 dp ; rayon unique 16 dp.
6. Grille deux colonnes à 390 dp contre `seuilChoixDouble = 560`.
7. Pictogramme féminin : décision du directeur.
8. Cercle d'icône sélectionné incohérent entre les deux images (`#5A4593` contre `#3D3166`) : un seul jeton.
