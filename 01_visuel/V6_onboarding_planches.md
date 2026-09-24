# V6 - Planches onboarding mobile (sombre) : relevé visuel

Agent : relevé visuel V6, phase lecture seule. Date : 24/09/2026.
Sources lues : `pilotage-tuteur-v1\BRIEF.md`, mandat `REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§2, §4, §5, §6, §7, §9 et « Prompt étape observation tuteur »). Pour confronter les maquettes au questionnaire réel : `assets/i18n/fr.i18n.json` l. 155-176 et 965-1004, `lib/core/widgets/page_parcours.dart` l. 80-174, `lib/features/parcours_offres/parcours_offres_page.dart` l. 245-289. Aucun fichier du dépôt n'a été modifié.

## 0. Preuves d'ouverture et méthode

| Élément | Détail |
|---|---|
| Images ouvertes avec Read | `onboarding mobile 1.png` et `Onboarding mobile 2.png`, 1806 × 871 px, 24 bits, 96 dpi, ouvertes en entier. |
| Tuiles ouvertes (agrandissement × 2, bicubique) | `01_visuel\tuiles\V6_p1_e1_haut.png`, `V6_p1_e1_bas.png`, `V6_p1_e2_haut.png`, `V6_p1_e2_bas.png`, `V6_p1_e3_haut.png`, `V6_p1_e3_bas.png`, `V6_p2_e1_haut.png`, `V6_p2_e1_bas.png`, `V6_p2_e2_haut.png`, `V6_p2_e2_bas.png`, `V6_p2_e3_haut.png`, `V6_p2_e3_bas.png`. Toutes ouvertes. |
| Zooms typographiques ouverts | `V6_zoom_typo_titre_age.png` (× 3), `V6_zoom_typo_carte1.png` (× 4), `V6_zoom_lien_prochaine.png` (× 3). |
| Couleurs | `System.Drawing.Bitmap.GetPixel` : point unique, médiane d'une zone (pas de 2 px) pour les aplats, moyenne des 4 % de pixels les plus clairs (texte clair) ou les plus sombres (texte sur CTA) pour le cœur d'encre. Contraste WCAG calculé sur les HEX mesurés. |
| Géométrie | Balayages de luminance par ligne et par colonne (segments au-dessus d'un seuil), boîtes englobantes du texte, détection d'arrondi aux coins. |

Notation : `p1` = `onboarding mobile 1.png`, `p2` = `Onboarding mobile 2.png`. Coordonnées en pixels de l'image source.

## 1. Manifeste

Chaque planche contient trois écrans mobiles côte à côte, chacun dans un cadre de téléphone, avec une étiquette violette au-dessus (« 01 / Compte », etc.). Ces étiquettes sont des annotations de planche, pas de l'interface.

| # | Fichier | Zone (cadre) | Écran représenté | Route logique (§4) | État | Thème | Format | Statut |
|---|---|---|---|---|---|---|---|---|
| E1 | p1 | x 149-612, y 54-839 ; étiquette y 20-36 | « 01 / Compte » : choix d'usage « Pour qui créez-vous ce compte ? » | `/onboarding/usage` | nominal rempli, « Moi uniquement » sélectionné, étape 1 sur 6 | sombre | mobile | nouveau high-fi (sur planche) |
| E2 | p1 | x 674-1132, y 54-839 | « 02 / Genre » : « Quel est votre genre ? » | `/onboarding/...` (identité, actuellement étape genre de `/inscription`) | nominal rempli, « Homme » sélectionné, 2 sur 6 | sombre | mobile | nouveau high-fi |
| E3 | p1 | x 1194-1656, y 54-839 | « 03 / Âge » : « Quel âge avez-vous ? » (champ numérique) | `/onboarding/...` (âge, actuellement page âge de `parcours_offres`) | nominal rempli, valeur « 28 », 3 sur 6 | sombre | mobile | nouveau high-fi |
| E4 | p2 | x 149-612, y 54-839 | « 04 / Langue » : « Quelle langue préférez-vous ? » (langue de l'application) | `/onboarding/...` ; en réalité relève de Compte > Préférences (voir pièges) | nominal rempli, « Français » sélectionné, 4 sur 6 | sombre | mobile | nouveau high-fi |
| E5 | p2 | x 674-1132, y 54-839 | « 05 / Objectif » : « Quel est votre objectif principal ? » | `/onboarding/...` (objectif) | nominal rempli, « Lire le Coran avec fluidité » sélectionné, 5 sur 6 | sombre | mobile | nouveau high-fi |
| E6 | p2 | x 1194-1656, y 54-839 | « 06 / Continuité » : récapitulatif « Tout commence ici. » | `/onboarding/recapitulatif` | nominal, 6 sur 6, barre pleine | sombre | mobile | nouveau high-fi |

Non représentés dans ces deux planches : état vide ou initial (rien de sélectionné), CTA désactivé, erreur sous champ, chargement, envoi en cours, erreur réseau, reprise, thème clair, tablette, desktop, branche familiale, branche enseignant, consentements, identité (prénom, nom), niveau, élèves, choix de classe.

## 2. Échelle

- Cadres mesurés : 462-463 px de large (p1 : bords x=149/611,5 ; 674/1132 ; 1194/1656), 785 px de haut (y=54 à 838,5).
- Échelle retenue : 390 dp pour 462 px, soit **0,844 dp/px** (1 dp = 1,185 px).
- Le cadre est **aplati** : rapport hauteur/largeur 1,70, contre 2,16 pour un écran 390 × 844. Sa hauteur équivaut à 663 dp seulement. Les mesures horizontales et les tailles de texte sont donc fiables à l'échelle ; les distances verticales longues (vide entre contenu et CTA) ne le sont pas : sur un vrai 390 × 844, le CTA reste ancré en bas et le vide grandit.
- À cette échelle, les tailles obtenues sont réalistes (titre ≈ 30 dp, corps ≈ 16 dp, CTA ≈ 55 dp). Contrairement à V1 (Accueil, densité 1,4 fois trop forte), aucune correction de densité n'est nécessaire ici.

## 3. Tokens de couleur mesurés (thème sombre)

| Rôle | HEX retenu | Mesures (fichier, coordonnées) | Remarque |
|---|---|---|---|
| Fond de page (écran) | **#1A1923** | médiane p1 (180,670)-(580,700) #1A1923 ; p1 (720,560)-(1100,690) #1A1923 ; points #1B1923 (400,690), #1B1824 (900,620), #1A1924 (1400,600) | identique au fond de planche #1A1823 (médiane p1 (20,300)-(120,600)) : l'écran n'est délimité que par le trait du cadre |
| Trait du cadre téléphone | #37354A | p1 (149,600) ; #323043 (380,54) | cadre de maquette, pas un composant |
| Surface carte / ligne non sélectionnée | **#201F2B** | médiane p1 (420,640)-(530,660) #201F2B ; carte genre non sél. #201E2A (930,290)-(960,320) ; champ âge #201E2A (1300,340)-(1500,360) ; carte récap p2 #201E2A (1450,320)-(1600,330) ; ligne objectif non sél. p2 #1F1D29 (1000,350)-(1050,400) | écart de luminance très faible avec le fond : la bordure porte la séparation |
| Surface sélectionnée | **#292438** | médiane p1 (420,440)-(530,470) #292438 ; genre sél. #282337 ; ligne objectif sél. p2 #282337 ; ligne langue sél. p2 (420,390) #282337 | teinte lavande très sombre |
| Bordure non sélectionnée | **≈ #333342** | p1 (380,492) #333342 ; (380,666) #353343 ; p2 (380,427) #30303F ; carte récap p2 (1600,309) #333441 | 1-2 px ; contraste 1,40:1 sur le fond (décoratif) |
| Bordure sélectionnée | **≈ #C8B0FD** | p1 (380,349) #C4AAFD ; (169,420) #CEBBFF ; p2 (380,314) #D2B3FF | environ 2 px (≈ 2 dp) ; 8,7:1 |
| Séparateur interne (carte récap) | #2D2C3B | p2 (1500,387) ; ligne x 1238-1619, y 386-387 | inset ≈ 16 dp de chaque côté |
| Séparateur vertical du champ âge | #464559 | cœur p1 (1540-1550, 360-395) ; trait x=1544-1545, y 367-397 | |
| Texte principal | **#FFFFFF** | cœur titres p1 (177-510, 210-285), valeurs récap p2 (1320-1470, 350-372), libellés d'option | 17,3:1 sur le fond |
| Texte secondaire | **≈ #A9B0CA** | cœurs : sous-titre p1 (177-514, 303-324) #A9B2CD ; description carte (294-484, 415-450) #ADB3CE ; aide champ (1223-1458, 437-455) #A5ADC8 ; « Prochaine étape » p2 (1250-1610, 678-697) #A6ADC6 ; description carte 2 #A9B0C8 | gris bleuté froid ; 8,2:1 sur le fond, 7,2:1 sur carte sélectionnée |
| Texte tertiaire (légende récap) | **#8C91A8** | cœur p2 (1320-1390, 322-340) « Compte » | 5,4:1 sur #1F1C29 |
| Accent / CTA plein | **#BA9FFC** | médiane p1 (290,720)-(310,765) #BA9FFC et (470,720)-(560,765) #BA9FFC ; points (250,744) #BA9FFC, (560,744) #BAA0FC ; p2 (1300,745) #B99CFC | aplat uniforme ; un point central p2 (1426,745) #C5A5FE suggère une légère surbrillance, à ignorer |
| Texte et flèche sur CTA | **≈ #010002** (quasi-noir) | cœur sombre p1 (320-440, 730-760) | 9,4:1 sur #BA9FFC |
| Remplissage progression | #B99FFC | médiane p1 (272,138)-(310,144) ; p2 (1400,141) #B99AFB | = accent |
| Piste progression | #3D3B4F | médiane p1 (420,138)-(490,144) ; (470,141) #3E3B4F ; p2 (1080,141) #484653 | 1,6:1, décoratif (le texte « n sur 6 » porte l'information) |
| Radio sélectionné (point + anneau) | #B599FD | p1 (560,389) ; genre (793,470) #B79CFB ; p2 (1078,461) #B999FC | point plein dans un anneau, séparés par un liseré sombre |
| Radio non sélectionné (anneau) | #535369 | cœur p2 (1062-1095, 360-392) | **2,17:1 sur la carte : sous le seuil 3:1 des composants non textuels**, à éclaircir |
| Bouton retour (fond) | #312F3E | médiane p1 (180,128)-(196,155) ; point (183,141) #2F2D3C | flèche #FFFFFF |
| Pastille d'icône sélectionnée | #48396B | médiane p1 (196,395)-(210,430) ; p2 langue (198,362) #513D7A ; **p2 objectif (725,463) #947FCA** | trois teintes différentes pour le même rôle : à unifier |
| Pastille d'icône neutre | #393748 | médiane p1 (196,540)-(210,570) ; p2 (198,475) #373547 ; (725,375) #3F3D50 ; récap (1250,330) #353345 | |
| Icône sur pastille sélectionnée | #CEBBFD | p1 (229,403) ; homme (780-806,325-400) #C5AFFC ; livre sél. p2 #D6C1FD | |
| Icône sur pastille neutre | #E3DDF9 | p1 (229,560) ; livre non sél. p2 #E4E0FE ; globe récap #E4E3FB | |
| Icône non sélectionnée (pictogramme genre) | #8E90AF | cœur p1 (1000-1025, 330-400) « Femme » | 5,2:1 |
| Lien « Modifier mes réponses » | ≈ #D7C8F8 (cœur), souligné | p2 (1340-1515, 640-662) | lavande pâle, 11,2:1 |
| Annotation de planche « 0n / … » | #D2C4FC (cœur) | p1 (330-435, 20-36) ; p2 (350-440, 15-40) #D3C0FA | hors interface |
| Barre d'accueil iOS | #FEFEFE | p1 (381,817), 177 × 9 px | chrome système, ne pas dessiner |

**Absents de ces planches** (à prendre dans V1 à V5) : pastilles de statut vert, orange, rouge, gris ; bandeau d'alerte ; onglet actif de navigation ; CTA doux. Aucune barre de navigation n'apparaît, ce qui est normal pour un parcours d'admission plein écran.

Cohérence avec le thème clair de V1 (Accueil) : même famille lavande (V1 accent ≈ #AC88F7, CTA doux #DAC7FD ; ici accent #BA9FFC). Le sombre de l'onboarding peut servir de source pour dériver la variante sombre des écrans tuteur, et inversement, sans inversion naïve.

## 4. Géométrie (px → dp à 0,844)

| Élément | Mesure px | ≈ dp | Remarque |
|---|---|---|---|
| Marge latérale CTA et cartes | 19-20 px (CTA p1 x 168-594,5 ; p2 x 1213-1636) | **16** | |
| Retrait du titre et du sous-titre | x=177 soit 28 px | **24** | titre plus rentré que les cartes : deux alignements |
| Retrait du champ âge et de la carte récap | 25 px à gauche, 18-25 px à droite | 15-21 | incohérent avec les cartes (16) ; proposer une marge unique |
| Bouton retour | Ø 61 px (x 174-234, y 111-171), centre y=141 | **Ø 51** | rond ; bord à 21 dp du cadre ; cible ≥ 48 dp respectée |
| Barre de progression | 225 × 11 px (x 268-493, y 135-145) | 190 × **9**, rayon plein | écart ≈ 29 dp avec le bouton et avec le compteur |
| Compteur « n sur 6 » | chiffres 13 px, fin à x≈578 | texte ≈ 16 | bord droit à 29 dp du cadre |
| Bouton retour → titre | bas 171 → hauteur de capitale 212 : 41 px | ≈ 35 (≈ 32 de boîte de ligne) | |
| Ligne de base du titre → capitale du sous-titre | 28 px (p1 E3 241 → 269) | ≈ 24 | |
| Sous-titre → première option | 18-28 px selon l'écran | 15-24 | E1 21, E4 24, E5 18, E6 15 |
| Carte d'usage (E1) | 426 × 128 px (sélectionnée), 426 × 175 px (description sur 3 lignes) | 360 × 108 et 360 × 148 | |
| Rayon des cartes et champs | arc ≈ 13-15 px | **≈ 12** | cartes E1, E2, champ E3 |
| Rayon des lignes (langue, objectif) et carte récap | arc ≈ 9-12 px | ≈ 8-10 | moins arrondi que les cartes |
| Bordure | sélectionnée ≈ 2 px ; neutre 1-2 px | 2 et 1 | |
| Écart entre options empilées | E1 13-14 px ; E4 16 px ; E5 8-10 px | 12 ; 13 ; 8 | trois valeurs pour la même liste : unifier (12 proposé) |
| Padding interne carte | bord → pastille 20 px ; pastille → texte 27 px ; radio → bord droit 18 px | 17 ; 23 ; 15 | |
| Pastille d'icône | E1 79 px ; E4 69 px ; E5 ≈ 58 px ; E6 55 px | 67 ; 58 ; 49 ; 46 | quatre tailles : unifier (48 pour les lignes, 56 max pour les cartes) |
| Radio | anneau 33-35 px, point 23 px, trait 3 px ; E2 38 px | 28-30 ; 19 ; 2,5 ; 32 | |
| Cartes genre (E2) | 202 × 236 px chacune, écart 18 px ; pictogramme 27 × 46 px | 170 × 199 ; 15 ; 23 × 39 | grille à deux colonnes |
| Champ âge (E3) | 413 × 90 px ; séparateur 31 px de haut à x=1545 | 348 × 76 ; 26 | |
| Lignes langue (E4) | 96-98 px | 81-83 | |
| Lignes objectif (E5) | 74-85 px | 62-72 | |
| Carte récap (E6) | 420 × 318 px, 4 rangées de 77-80 px | 355 × 268 ; rangées 65-67 | séparateurs inset 16 dp |
| CTA | 426 × 65 px (p1), 424 × 64 px (p2) | 360 × **55**, pilule (rayon ≈ 27) | libellé centré + flèche à droite du libellé |
| CTA → bas du cadre | 62 px | 52 (dont ≈ 34 de zone système) | |
| Lien → texte « Prochaine étape » → CTA (E6) | 36 px de base à base ; 16 px avant le CTA | 30 ; 13,5 | |

## 5. Typographie observée

- Une seule famille pour tout l'écran : sans géométrique, « a » à deux étages, « g » à un étage, « Q » à queue traversante, capitales larges. Elle ressemble à Plus Jakarta Sans ou à une famille proche (Figtree) ; l'identification n'est pas certaine sur une image générée. Les titres ne présentent pas de dessin distinct de DM Sans.
- **Règle écrite qui prévaut** : DM Sans pour les titres français (questions, « Tout commence ici. »), Plus Jakarta Sans pour tout le reste (sous-titres, options, descriptions, compteur, champ, lien, CTA). Le brief signale que ni DM Sans ni Jakarta ne sont présentes dans le dépôt (actuel : InstrumentSans et BricolageGrotesque) : contradiction déjà consignée par le coordinateur.
- Le libellé « العربية » (E4) doit rester en NotoSansArabic, en direction RTL.

| Niveau | Hauteur de capitale mesurée | Taille estimée | Graisse apparente | Couleur |
|---|---|---|---|---|
| Titre de question | 25-26 px (p1 « P » y 212-237 ; « Q » 214-241 ; p2 « Q » 214-238, « T » 215-240) | **≈ 30 dp**, interligne ≈ 1,13 (≈ 34 dp) | Bold 700 | #FFFFFF |
| Sous-titre (consigne) | ≈ 16 px (« C » 17 px avec dépassement) | ≈ 18-19 dp | Regular 400 | #A9B2CD |
| Libellé d'option (carte) | 14-15 px (« M » 381-395 ; « Homme » 410-424) | ≈ 17-18 dp | SemiBold 600 | #FFFFFF |
| Libellé de ligne (langue, objectif) | 15 px (« F » 355-369 ; « E » 467-481) | ≈ 17-18 dp | Medium 500 | #FFFFFF |
| Description d'option | 13 px | ≈ 16 dp, interligne ≈ 1,2 | Regular 400 | #ADB3CE |
| Légende de récap (« Compte ») | ≈ 12-13 px | ≈ 14-15 dp | Regular 400 | #8C91A8 |
| Valeur de récap | 14 px | ≈ 17 dp | Medium 500 | #FFFFFF |
| Compteur « n sur 6 » | 13 px | ≈ 16 dp | Regular 400 | #FFFFFF |
| Valeur du champ (« 28 ») | chiffres 24 px | ≈ 28 dp | Regular 400 | #FFFFFF |
| Étiquette flottante du champ (« Âge ») | ≈ 13 px | ≈ 14-15 dp | Regular 400 | ≈ #EDEFF8 |
| Suffixe (« ans ») | hauteur d'x 12 px | ≈ 18 dp | Regular 400 | #FFFFFF |
| Lien (« Modifier mes réponses ») | 15 px | ≈ 17-18 dp | SemiBold 600, souligné | ≈ #D7C8F8 |
| Texte d'aide (« Prochaine étape… », « Pour adapter… ») | 13 px | ≈ 16 dp | Regular 400 | #A6ADC6 |
| CTA | 14 px (« S » 738-751) | ≈ 17 dp | SemiBold 600 à Bold 700 | #010002 |

## 6. Gabarit commun des étapes

Ordre de haut en bas, identique sur les six écrans :

1. Barre d'état iOS « 9:41 » (chrome système, à ne pas reproduire).
2. Rangée d'étape sur une seule ligne : bouton retour rond (Ø 51 dp, fond #312F3E, flèche blanche) ; barre de progression continue (9 dp, piste #3D3B4F, remplissage #B99FFC) ; compteur « n sur 6 » aligné à droite.
3. Titre de question, 1 ou 2 lignes, aligné à gauche (retrait 24 dp).
4. Sous-titre gris d'une ligne (absent sur E2).
5. Contenu : cartes de choix empilées (E1), grille 2 colonnes (E2), champ (E3), lignes de choix (E4, E5), carte récapitulative (E6).
6. Vide flexible.
7. CTA plein pilule pleine largeur « Suivant → » (« Continuer → » sur E6), ancré en bas.
8. Barre d'accueil iOS (chrome).

Composant de choix : surface #201F2B, bordure 1 px #333342, rayon ≈ 12 dp ; à la sélection, surface #292438, bordure 2 dp lavande, pastille d'icône teintée, radio plein. La sélection est portée par trois signaux (bordure, fond, radio), pas seulement par la couleur : conforme à §9. Sémantique attendue : groupe radio exclusif.

Écarts avec le gabarit actuel (`lib/core/widgets/page_parcours.dart` l. 80-145) :

| Point | Actuel | High-fi |
|---|---|---|
| Retour | `ActionPrincipale` tertiaire avec libellé « Retour » (l. 90-98) | bouton rond icône seule, sur la même ligne que la progression ; prévoir un libellé sémantique « Retour » |
| Compteur | « Étape {n} sur {total} » au-dessus de la barre (l. 102) | « n sur N » à droite de la barre, même ligne |
| Progression | barre segmentée, un segment par page (l. 149-174, choix commenté « trois traits sur cinq ») | barre continue ; l'ordre d'arbitrage §2 place le high-fi (3) avant l'existant (5) ; garder le `Semantics` et la directionnalité RTL |
| Temps restant | « Environ {minutes} min » sous le CTA (l. 123-130) | absent ; à conserver discrètement ou retirer, décision à consigner |
| Explication | `explication` en `bodyMedium` sous la question (l. 137-140) | sous-titre gris d'une ligne ; les « raisons » existantes sont plus longues que les sous-titres de la maquette |

## 7. Fiches par écran

### E1 - « 01 / Compte » : choix d'usage (p1, x 149-612)

- Route : `/onboarding/usage`. État : nominal, première option sélectionnée. Sombre, mobile, nouveau high-fi.
- Composition : gabarit commun ; titre sur 2 lignes ; sous-titre ; deux grandes cartes empilées (pastille ronde de 67 dp à gauche avec icône pleine personne ou groupe ; bloc texte titre SemiBold + description sur 2-3 lignes ; radio en haut à droite, aligné sur le titre et non centré verticalement) ; écart de 12 dp ; vide ; CTA.
- Textes exacts : « 01 / Compte » (annotation), « 9:41 », « 1 sur 6 », « Pour qui créez-vous ce compte ? », « Choisissez ce qui vous correspond. », « Moi uniquement », « Pour apprendre et suivre mes cours. », « Moi et les membres de ma famille », « Les cours, les appareils et les paiements de la famille, au même endroit. », « Suivant ».
- À ne pas reproduire :
  - Le mandat (§6) fixe les descriptions : « Moi uniquement » = « Je souhaite suivre les cours avec mon propre profil élève. » ; « Moi et ma famille » = « Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment. » La description familiale de la maquette ne dit pas « avec ou sans vous » : c'est précisément l'ambiguïté que le mandat veut lever. Titre de l'option : « Moi et ma famille » (et non « Moi et les membres de ma famille »).
  - Le titre « Pour qui créez-vous ce compte ? » laisse croire que le compte peut appartenir à quelqu'un d'autre ; le compte est toujours celui du titulaire. Le mandat donne « Pour qui souhaitez-vous utiliser Rewayah ? » (§4). §6 autorise un titre légèrement différent à condition d'assurer exactement cette compréhension : le titre du mandat est plus sûr.
  - « les paiements de la famille » promet une fonction de paiement ; §5 interdit tout faux paiement ou prestataire inventé.
  - Aucune entrée enseignant, alors que §4 l'exige (« sans oublier inscription enseignant ») et que le code actuel la prévoit (`inscription.roleEnseignant` + `inscription.autreAide`, fr.i18n.json l. 161-163). Ajouter une sortie discrète (lien sous les cartes), sans troisième grande carte ni empilement de rectangles (§4 : KYC « trop de CTA et trop de rectangles » à bannir).
  - Pas de troisième choix « Mes enfants uniquement » (§6).
  - Pré-sélection : ne pas présélectionner d'usage ; CTA désactivé ou erreur sous le groupe (« Cette réponse est nécessaire pour continuer. », `inscription.champRequis`).
  - Le choix familial ne crée pas de profil élève pour le parent et ne l'engage pas dans les questions pédagogiques pour lui-même (§6).
- Correspondance actuelle : question de rôle « Vous inscrivez-vous comme parent ou comme enseignant ? » avec « Parent ou tuteur », « Élève adulte, pour moi-même », « Enseignant » (fr.i18n.json l. 159-162 ; `inscription_page.dart:132`).

### E2 - « 02 / Genre » (p1, x 674-1132)

- Route : étape identité de l'admission (actuellement `inscription_page.dart:213`). État : nominal, « Homme » sélectionné. Sombre, mobile, nouveau high-fi.
- Composition : gabarit commun ; titre sur 1 ligne ; **pas de sous-titre** (seul écran dans ce cas) ; deux cartes carrées côte à côte (170 × 199 dp, écart 15 dp) avec pictogramme plein centré (violet si sélectionné, gris #8E90AF sinon), libellé SemiBold centré, radio centré en bas ; vide ; CTA.
- Textes exacts : « 02 / Genre » (annotation), « 2 sur 6 », « Quel est votre genre ? », « Homme », « Femme », « Suivant ».
- À ne pas reproduire :
  - Absence de justification : le dépôt explique pourquoi la question est posée (« Cette réponse ne sert qu'à confier votre pièce d'identité à un membre du personnel du même genre. », `inscription.genreRaison`, l. 171). La garder en sous-titre.
  - Libellés actuels « Vous êtes » / « Un homme » / « Une femme » (l. 168-170) : choisir une formulation et la consigner, sans changer le sens.
  - Pictogrammes genrés stéréotypés (silhouette à robe) : préférer des icônes Phosphor sobres et cohérentes, ou aucun pictogramme.
  - Pas de présélection.
  - La question concerne le titulaire (vérification de pièce). Dans la branche familiale, ne pas la reposer pour chaque enfant sans règle existante.
  - L'étape identité (prénom, nom : `inscription.identiteQuestion`, l. 164-167) est absente des planches et doit rester.
- Adaptation : la grille à deux colonnes doit passer en pile à 200 % de texte.

### E3 - « 03 / Âge » (p1, x 1194-1656)

- Route : étape âge (actuellement page 1 de `parcours_offres_page.dart:249`). État : nominal, valeur saisie « 28 ». Sombre, mobile, nouveau high-fi.
- Composition : gabarit commun ; titre sur 1 ligne ; sous-titre ; champ encadré pleine largeur (348 × 76 dp, rayon ≈ 12) avec étiquette flottante « Âge » en haut à gauche, valeur grande (≈ 28 dp), séparateur vertical et suffixe « ans » à droite ; texte d'aide sous le champ ; vide ; CTA.
- Textes exacts : « 03 / Âge » (annotation), « 3 sur 6 », « Quel âge avez-vous ? », « Votre âge, en années. », « Âge », « 28 », « ans », « Pour adapter votre parcours. », « Suivant ».
- À ne pas reproduire :
  - **Contradiction métier à consigner, sans trancher** : la maquette demande un âge exact libre. Le code actuel propose une **tranche** fournie par le serveur (`cohortesAgeProvider`, `ChoiceCardGroup`, `autoriserSaisieLibre: false`, l. 250-280) et affiche « Nous ne demandons pas de date de naissance : une tranche suffit. » (`parcours.ageRaison`, l. 975). Le mandat (§6) parle de cohortes 6-9, 10-13, 14-17, 18+, de date de naissance, d'anniversaire pendant le flux et interdit de deviner un âge. Le formulaire enfant actuel valide « Indiquez un âge entre 3 et 18 ans. » (l. 228). Si la tranche est conservée, reprendre le style « carte de choix » d'E1 plutôt que ce champ.
  - « 28 » est illustratif.
  - L'aide « Pour adapter votre parcours. » est plus vague que la raison réelle (« L'âge décide de la durée des séances et du nombre d'élèves par groupe. »).
  - Question posée au « vous » : dans la branche familiale elle devient « Quel âge a {prenom} ? » (`parcours.ageQuestion`) et n'est pas posée au parent sans profil élève.
- États à dériver : champ vide, erreur sous le champ (hors bornes, non numérique), clavier numérique qui ne masque pas le CTA, chargement des tranches (squelette).

### E4 - « 04 / Langue » (p2, x 149-612)

- Route : étape de la maquette ; son contenu relève en réalité de Compte > Préférences (`.../preferences`, §4). État : nominal, « Français » sélectionné. Sombre, mobile, nouveau high-fi.
- Composition : gabarit commun ; titre sur 1 ligne ; sous-titre ; trois lignes de choix (81-83 dp, écart ≈ 13 dp) : pastille ronde 58 dp avec icône personne, libellé Medium, radio à droite centré verticalement ; vide ; CTA.
- Textes exacts : « 04 / Langue » (annotation), « 4 sur 6 », « Quelle langue préférez-vous ? », « Pour les menus de l'application. », « Français », « English », « العربية », « Suivant ».
- À ne pas reproduire :
  - **Langue de l'interface ≠ langue du cours.** Le questionnaire actuel demande la langue **du cours** (« Dans quelle langue le cours doit-il être donné ? ») et précise qu'elle est « indépendante de la langue de l'application » (`parcours.langueQuestion`/`langueRaison`, l. 977-978 ; liste serveur `languesCoursProvider`, `parcours_offres_page.dart:287-289`). Cette étape ne doit pas remplacer la question de langue du cours.
  - Le dépôt n'a qu'un fichier de traduction (`fr.i18n.json`, voir brief) : proposer English ou العربية pour les menus promettrait une interface non traduite. N'afficher que les langues réellement disponibles.
  - Icône « personne » pour une langue : sémantique fausse (globe, ou pas d'icône).
  - « العربية » : police arabe et direction RTL pour ce libellé.
  - Pas de présélection arbitraire ; au mieux, proposer la langue de l'appareil si elle est disponible.

### E5 - « 05 / Objectif » (p2, x 674-1132)

- Route : étape objectif (actuellement dans `parcours_offres`). État : nominal, « Lire le Coran avec fluidité » sélectionné. Sombre, mobile, nouveau high-fi.
- Composition : gabarit commun ; titre sur 2 lignes ; sous-titre ; quatre lignes compactes (62-72 dp, écart ≈ 8 dp, plus serré que E1 et E4) : pastille 49 dp avec icône au trait (livre ouvert, livre ouvert plein si sélectionné, marque-page, mosquée), libellé Medium sur 1-2 lignes, radio à droite ; CTA.
- Textes exacts : « 05 / Objectif » (annotation), « 5 sur 6 », « Quel est votre objectif principal ? », « Choisissez votre priorité. », « Apprendre à lire l'arabe », « Lire le Coran avec fluidité », « Mémoriser le Coran », « Apprendre les bases de l'islam », « Suivant ».
- À ne pas reproduire :
  - Options actuelles : « Apprendre à lire », « Lire plus couramment », « Mémoriser », « Je ne sais pas encore », question « Que souhaitez-vous d'abord ? » et raison « Vous pourrez changer d'objectif plus tard… » (l. 992-997). La maquette supprime « Je ne sais pas encore » et ajoute « Apprendre les bases de l'islam ». Ne pas créer d'option sans parcours réel au catalogue : à confronter aux décisions Classes V2 et au catalogue.
  - La question de **niveau** (`parcours.niveauQuestion`, 5 réponses, l. 984-990) et la branche débutant ou non-débutant (§6) sont absentes des planches et doivent être ajoutées dans ce langage visuel.
  - Aucun code académique interne ne doit apparaître à l'écran (§6).
  - Question posée « pour qui » : dans la branche familiale, par élève nommé, avec le prénom.
  - Pastille sélectionnée #947FCA, plus claire que sur E1 et E4 (#48396B, #513D7A) : unifier.

### E6 - « 06 / Continuité » : récapitulatif (p2, x 1194-1656)

- Route : `/onboarding/recapitulatif`. État : nominal, 6 sur 6, barre de progression pleine. Sombre, mobile, nouveau high-fi.
- Composition : gabarit commun ; titre sur 1 ligne ; sous-titre ; **une seule carte** récapitulative (355 × 268 dp) de quatre rangées séparées par des filets inset : pastille 46 dp (personne pleine, personne pleine, globe au trait, cible au trait), légende grise, valeur blanche ; lien centré souligné ; phrase centrée ; CTA « Continuer → ».
- Textes exacts : « 06 / Continuité » (annotation), « 6 sur 6 », « Tout commence ici. », « Vos préférences sont prêtes. », « Compte », « Moi uniquement », « Profil », « Homme · 28 ans », « Langue », « Français », « Objectif », « Lire le Coran avec fluidité », « Modifier mes réponses », « Prochaine étape : découvrir votre parcours. », « Continuer ».
- À ne pas reproduire :
  - « Vos préférences sont prêtes. » affirme un enregistrement ; ne l'afficher qu'après confirmation du service, jamais comme faux succès (§3).
  - Le mandat attend au récapitulatif : modifier, confirmer, **état du dossier**, **prochaine action réelle** (§4). « Prochaine étape : découvrir votre parcours. » doit refléter l'action réelle suivante (consentement, ajout d'élève, choix de classe, dossier en attente).
  - Un seul lien global « Modifier mes réponses » (clé existante `parcours.modifier`, l. 970) : prévoir aussi la correction par rangée (§6 « correction depuis le récapitulatif »), sans perdre les autres réponses.
  - Valeurs illustratives (« Homme · 28 ans », etc.). En branche familiale : un bloc par élève nommé, et le titulaire sans questions pédagogiques s'il n'étudie pas.
  - La barre pleine et « 6 sur 6 » figent un questionnaire à 6 étapes (voir §8).
  - Empêcher la double soumission sur « Continuer » (état « en cours » du CTA, déjà prévu par `ActionPrincipale.enCours`).

## 8. Pièges transversaux

1. **Nombre d'étapes figé à 6.** Le mandat interdit de réduire le questionnaire au nombre d'images (§6). Le vrai parcours comprend aussi : identité (prénom, nom), consentements et contrat, dont le nouveau texte d'observation parentale (« Les parents des élèves présents peuvent observer brièvement la séance… », accord explicite, non précoché), élèves pour la branche familiale, niveau, lieu et fuseau (`parcours.lieuQuestion`), moments (`parcours.momentsQuestion`), choix de classe avec toutes les séances. Le total « n sur N » dépend de la branche.
2. **Aucune étape de consentement dans ces deux planches**, alors que le « Prompt étape observation » annonce une planche « Parcours mobile et consentement ». Si elle n'est pas dans un autre groupe, la demander au directeur.
3. **Présélections** sur tous les écrans : l'état initial doit être vide, avec CTA désactivé ou erreur sous le groupe.
4. **Usage** : textes et titre à remplacer par ceux du mandat ; sortie enseignant manquante ; pas de promesse de paiements.
5. **Âge exact contre tranches serveur** : contradiction métier à consigner, non à trancher dans l'UI.
6. **Langue de l'application** confondue avec la langue du cours ; une seule langue d'interface existe aujourd'hui.
7. **Questions au « vous »** : dans la branche familiale, chaque question pédagogique vise un élève nommé ; le parent sans profil élève n'y répond pas pour lui-même.
8. **Thème sombre seul** : dériver le clair (§9) en s'appuyant sur les tokens clairs relevés par V1, sans inverser naïvement.
9. **Accessibilité** : anneau radio non sélectionné à 2,17:1 (viser ≥ 3:1, par exemple #6E6D86 environ) ; bouton retour icône seule, prévoir un libellé sémantique ; grille genre et titres sur 2 lignes à tester à 200 % ; ordre de lecture et RTL pour l'arabe.
10. **Iconographie mélangée** (pictogrammes pleins pour les personnes, trait pour livre, marque-page, mosquée, globe, cible) : le dépôt utilise Phosphor ; proposer le style « regular » au repos et « fill » à la sélection.
11. **Tailles incohérentes dans la maquette** (pastilles 46 à 67 dp, écarts 8 à 13 dp, marges 16 à 24 dp) : les ramener à des tokens uniques plutôt que de copier chaque valeur.
12. **Chrome système** (« 9:41 », icônes réseau et batterie, barre d'accueil) et étiquettes « 0n / … » : ne pas les dessiner.
13. **Desktop et tablette** : colonne centrée de largeur de lecture raisonnable (≈ 480-560 dp), pas d'écran mobile étiré ; CTA en bas de la colonne.

## 9. Tokens proposés (à rapprocher des tokens existants, sans doublon)

| Token (rôle) | Sombre mesuré | Proposition |
|---|---|---|
| fond de page | #1A1923 | tel quel |
| surface d'option | #201F2B | tel quel |
| surface d'option sélectionnée | #292438 | tel quel |
| contour neutre | #333342 | tel quel (décoratif) |
| contour sélectionné | #C8B0FD, 2 dp | tel quel |
| texte principal | #FFFFFF | tel quel ou #F7F6FB pour adoucir |
| texte secondaire | #A9B0CA | tel quel (8,2:1) |
| texte tertiaire | #8C91A8 | tel quel (5,4:1) |
| accent / CTA plein | #BA9FFC | tel quel ; texte #010002 à #0D0820 (voir V1) |
| piste de progression | #3D3B4F | tel quel |
| radio neutre | #535369 | éclaircir vers ≥ 3:1 |
| rayon d'option | ≈ 12 dp | un seul rayon pour cartes, lignes et champs |
| CTA | 55 dp, pilule | ≥ 48 dp, pilule |
| marge de page | 16 (options) et 24 (titres) | une seule marge (≈ 20 dp), alignée sur la décision V1 |
| pastille d'icône | 46-67 dp | 48 dp |
| écart entre options | 8-13 dp | 12 dp |
| titre de question | ≈ 30 dp Bold | DM Sans 700, 28-30 dp |
| corps / options | 16-18 dp | Plus Jakarta Sans 400 / 500 / 600 |
