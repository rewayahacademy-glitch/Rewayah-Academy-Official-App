# V09 - CLV-04/05/06, salle de classe web étroit, thème sombre : relevé visuel

Date : 25/09/2026. Agent de relevé visuel, groupe `V09_CLV-04-05-06_web_etroit_sombre`. Lecture seule : aucun fichier du dépôt ni du projet Flutter n'a été modifié. Méthode alignée sur `C:\RA\pilotage\01_visuel\V1_accueil_mobile.md` (§0, §4, §5).

## 0. Preuves de lecture

| Élément | Valeur |
|---|---|
| Fichier source | `C:\RA\ressources\lancement\classe image\CLV-04-05-06_web_etroit_sombre.png` |
| Dimensions | 1448 × 1086 px, PNG, 1 431 487 octets |
| Image ouverte | oui, en entier avec l'outil Read, puis découpée en tuiles agrandies (×2, ×3, ×4) et en tuiles avec grille de mesure (grille rouge tous les 50 px, étiquettes en px source, PowerShell `System.Drawing`) |
| Tuiles | `C:\RA\pilotage\10_classe\V\tuiles\` : `s1_full_CLV04.png`, `s2_full_CLV05.png`, `s3_full_CLV06.png` (écrans entiers ×2), `g1b_CLV04.png`/`g2b_CLV05.png`/`g3b_CLV06.png` (grilles de mesure ×1,8), `h1..h3_notice_*` (bandeaux d'en-tête ×3), `v1..v3_video_*` et `chk1..chk6_*` (recadrages de vérification des boîtes de rectification) |
| Échantillonnage | lecture visuelle sur tuiles agrandies + grille de coordonnées en px source ; chaque boîte de rectification a été vérifiée par un recadrage centré dessus (`chk1` à `chk6`) |
| Mesures | approximatives, arrondies à 5 px, lues sur grille de 50 px vérifiée par recadrage ; marge d'erreur ≈ ±10-15 px, comme dans la fiche V1 |

Tous les textes ci-dessous ont été lus sur l'image ou sur les tuiles. Rien n'est déduit d'un nom de fichier.

## 1. Manifeste : trois écrans côte à côte

| Zone | Écran | Rôle / mode | Cadre | Thème |
|---|---|---|---|---|
| x 13-475, y 172-980 | Salle de classe, support partagé | `CLV-04 · Élève standard · Web` | navigateur (macOS), viewport étroit | sombre |
| x 489-963, y 172-980 | Salle de classe, support partagé | `CLV-05 · Interface guidée · Web` | navigateur (macOS), viewport étroit | sombre |
| x 976-1448, y 172-980 | Salle de classe, support partagé | `CLV-06 · Enseignant · Web` | navigateur (macOS), viewport étroit | sombre |

Les trois cadres montrent la même leçon (« Chapitre 1 · Les bonnes manières en classe », Sayyida Amina, Classe An-Nour), sous trois angles : élève standard, élève en interface guidée, enseignant.

## 2. Composition de chaque écran, de haut en bas

### 2.1 CLV-04 · Élève standard · Web (cadre x 13-475, y 172-980)

1. Barre de navigateur macOS (feux, `app.rewayah.academy`, loupe, +) : cadre de maquette, non applicatif.
2. **En-tête** (y 222-285) : flèche retour ; titre « Séance en direct » ; sous-titre « Classe An-Nour · Sayyida Amina » ; à droite, pastille « En ligne » (point vert + texte). Propre, aucun chevauchement.
3. **Bandeau légal** (x 48-462, y 263-312) : fond plein violet foncé arrondi, icône caméra sur pastille violette pleine, texte « Cours enregistré, visite de contrôle possible. » → **non conforme à R1** (voir Rectification 1).
4. **Rangée support + vidéo**, sur toute la hauteur restante (y 322-580) :
   - à gauche, carte blanche du support (x 48-334) : badge « Chapitre 1 », titre « Les bonnes manières en classe », 3 lignes de texte de remplissage, encart violet clair « Être attentif aux explications du professeur. », liste numérotée 1/2/3, 2 lignes de remplissage ;
   - à droite, **vidéo de l'enseignante** (x 338-462, y 322-580, 124 × 258 px) occupant toute la hauteur de la rangée, avec étiquette « Sayyida Amina » et icône de niveau audio (barres vertes) en bas → **non conforme à R3** (Rectification 2).
5. **Bandeau « observation »** (x 338-462, y 590-655), séparé, sous la vidéo : fond brun/or plein, icône œil, texte « Votre parent observe la séance. » sur deux lignes → **non conforme à R2** (Rectification 3).
6. **Barre de contrôle** (x 48-462, y 838-905) : 4 boutons ronds centrés « Micro », « Caméra », « Agrandir » (contour clair), « Quitter » (plein rouge). Style cohérent, un seul système de forme (cercle).
7. Étiquette de plaque « CLV-04 · Élève standard · Web » (hors app, sous le cadre).

### 2.2 CLV-05 · Interface guidée · Web (cadre x 489-963, y 172-980)

1. Barre de navigateur macOS.
2. **En-tête** (y 222-285) : flèche retour ; titre « Ma séance » ; sous-titre « Classe An-Nour · Sayyida Amina » ; pastille « En ligne ».
3. **Aucun bandeau légal** entre le sous-titre et la carte → incohérence avec R1 (Rectification 4).
4. **Carte support** (x 545-940, y 322-780) : badge « Chapitre 1 », titre, 3 lignes, encart violet clair, liste 1/2/3, 2 lignes finales — avec la **vidéo insérée en incrustation dans le coin supérieur droit** de la carte (x 795-940, y 322-555, 145 × 233 px, coins arrondis sur ses 4 côtés, étiquette « Sayyida Amina » + barres audio) : la vidéo est ici en incrustation (plus proche de R3 que CLV-04), mais elle force encore la hauteur de la première rangée (badge + titre + description) → **partiellement non conforme à R3** (Rectification 5).
5. **Bandeau « observation »** séparé, pleine largeur, sous la carte (x 489-963, y 795-850) : fond brun/or plein, icône œil, texte « Ton parent regarde la séance. » → **non conforme à R2** (Rectification 6), et libellé différent de celui de CLV-04 (« Votre parent observe » vs « Ton parent regarde ») → incohérence de vocabulaire à unifier.
6. **Barre de contrôle** (y 798-865) : « Parler » (cercle **plein vert**), « Caméra » (**pilule/stade violet**, plus large qu'un cercle), « Agrandir » (cercle contour clair), « Quitter » (cercle plein rouge) → **deux couleurs et une forme inédites** par rapport à CLV-04/CLV-06 → **non conforme à R5** (Rectification 7).
7. Étiquette « CLV-05 · Interface guidée · Web ».

### 2.3 CLV-06 · Enseignant · Web (cadre x 976-1448, y 172-980)

1. Barre de navigateur macOS.
2. **En-tête** (y 222-285) : flèche retour ; titre « Séance en direct » ; sous-titre « Classe An-Nour · Sayyida Amina » ; pastille « En ligne ».
3. **Bandeau de statut** (x 1000-1445, y 295-340) : fond plein vert, icône barres, texte « La séance se poursuit. » — aucun indicateur d'enregistrement/visite nulle part sur cet écran → incohérence avec R1 (Rectification 8).
4. **Deux puces cliquables** côte à côte (y 350-395) : « Élèves 3/4 › » (x 1000-1215) et « Supports › » (x 1230-1445), fond gris-violet foncé, chevron à droite. Propres, alignées, aucun chevauchement.
5. **Carte support** (x 1013-1288, y 400-780) : mêmes éléments que les deux autres écrans (Chapitre 1, titre, description, encart, liste 1/2/3), avec la **vidéo en incrustation coin supérieur droit** (x 1300-1445, y 400-540, 145 × 140 px) : nettement plus compacte que sur CLV-04/05, mais toujours en flux (elle repousse le bloc de boutons sous elle) → **partiellement non conforme à R3**, dans une moindre mesure (Rectification 9).
6. Sous la vidéo, **grille 2×2 d'outils** (x 1300-1445, y 555-720) : « Pointeur », « Marquer », « Masquer », « Annoter », boutons carrés à coins arrondis, fond gris-violet foncé, icône + libellé — famille de forme différente des boutons ronds de la barre d'appel du bas (voir Rectification 10, cohérence de forme).
7. **Bandeau « observation »** (x 1300-1445, y 730-775) séparé : fond brun/or plein, icône œil, texte « Tuteur de Mariam observe. » → **non conforme à R2** (Rectification 11), troisième libellé différent des deux précédents.
8. **Barre de contrôle** (y 798-865) : « Micro », « Caméra », « Réseau » (icône Wi-Fi verte), « Quitter » (plein rouge) — 4 cercles, style cohérent avec CLV-04.
9. Étiquette « CLV-06 · Enseignant · Web ».

### 2.4 Textes recopiés exactement (les trois écrans)

- `app.rewayah.academy`
- `Séance en direct` (CLV-04, CLV-06) / `Ma séance` (CLV-05)
- `Classe An-Nour · Sayyida Amina`
- `En ligne`
- `Cours enregistré, visite de contrôle possible.` (CLV-04 uniquement)
- `Chapitre 1`
- `Les bonnes manières en classe`
- `Être attentif aux explications du professeur.`
- `1` `Écouter avec calme.`
- `2` `Poser des questions poliment.`
- `3` `Respecter les camarades.`
- `Sayyida Amina` (étiquette vidéo)
- `Votre parent observe la séance.` (CLV-04)
- `Ton parent regarde la séance.` (CLV-05)
- `Tuteur de Mariam observe.` (CLV-06)
- `La séance se poursuit.` (CLV-06)
- `Élèves 3/4` / `Supports` (CLV-06)
- `Pointeur` / `Marquer` / `Masquer` / `Annoter` (CLV-06)
- `Micro` / `Caméra` / `Agrandir` / `Quitter` (CLV-04)
- `Parler` / `Caméra` / `Agrandir` / `Quitter` (CLV-05)
- `Micro` / `Caméra` / `Réseau` / `Quitter` (CLV-06)
- `CLV-04 · Élève standard · Web` / `CLV-05 · Interface guidée · Web` / `CLV-06 · Enseignant · Web`

## 3. À garder tel quel

Conformément au mandat (« la maquette PRIME »), tout ce qui suit est conservé sans modification :

- La disposition générale : en-tête avec retour + titre + sous-titre + pastille « En ligne », carte de support blanche à gauche/centre, colonne d'actions à droite, barre de contrôle en bas.
- La palette sombre de fond, le violet d'accent (badge « Chapitre 1 », icônes, encart de texte), le vert de statut, le rouge de « Quitter », l'or/brun réservé aux notices temporaires.
- Le contenu pédagogique affiché dans la carte (titre, encart, liste numérotée 1-2-3) et sa mise en forme interne.
- La photo de l'enseignante et son cadrage par écran (aucune déformation détectée : proportions du visage cohérentes sur les trois recadrages `chk1`, `chk4`, `chk6` — largeur/hauteur du visage stable, pas d'étirement horizontal ni vertical).
- Les icônes (œil, caméra, Wi-Fi, pointeur, crayon, œil barré, stylo-plus) et le style « outline » du contenu.
- L'idée d'incrustation de la vidéo en coin de carte déjà présente sur CLV-05 et CLV-06 (à garder comme principe, seulement à réduire/détacher du flux — voir R3).
- Les deux puces « Élèves 3/4 » et « Supports » de CLV-06, et la grille d'outils « Pointeur/Marquer/Masquer/Annoter » : bien alignées, pas de chevauchement, pas de surcharge au sens de R7 (peu de boutons, grands, bien espacés).
- L'en-tête des trois écrans : aucun chevauchement entre flèche, titre, sous-titre et pastille « En ligne » — contrairement au reproche fait sur d'autres maquettes, ici le coin supérieur est propre.
- La barre de contrôle de CLV-04 et CLV-06 : un seul style de bouton rond, cohérent entre les deux écrans.

## 4. Rectifications

| # | Écran | Boîte (x, y, w, h px source) | Ce que montre la maquette | Règle | Correction attendue |
|---|---|---|---|---|---|
| 1 | CLV-04 | (48, 263, 414, 49) | Bandeau plein violet avec icône caméra en pastille, « Cours enregistré, visite de contrôle possible. » | R1 | Supprimer le fond en rectangle ; remplacer l'icône caméra par un simple **point rouge**, texte petit et discret à côté ; fusionner avec la notice de visite (une seule mention). Placer où il ne gêne ni le titre, ni la carte |
| 2 | CLV-04 | (338, 322, 124, 258) | Vidéo de l'enseignante occupant toute la hauteur de la carte, en colonne à part entière | R3, R4 | Réduire fortement la vidéo ; la passer en **surimpression (z-index) sur un coin** de la carte de support (ex. coin haut-droit, ~120-150 px de large max, ratio proche de 1:1 ou 4:3, pas 1:2) ; elle ne doit plus réserver de colonne ni imposer la hauteur de la carte. Conserver le cadrage du visage sans le déformer |
| 3 | CLV-04 | (338, 590, 124, 65) | Bandeau séparé brun/or « Votre parent observe la séance. » sous la vidéo | R2 | Supprimer ce bloc séparé. Quand un parent observe : rétracter la mention de l'étape 1 à son seul point rouge (clignotement subtil), et afficher à sa place le texte temporaire « Votre parent observe la séance. » (même emplacement discret que la notice légale, pas de nouveau bandeau) |
| 4 | CLV-05 | zone (545, 295, 395, 25) à insérer | Aucun rappel légal/point rouge entre le sous-titre et la carte | R1 | Ajouter la même mention discrète (point rouge + texte court) que sur CLV-04, pour rester cohérent sur toute la salle |
| 5 | CLV-05 | (795, 322, 145, 233) | Vidéo en incrustation dans le coin de la carte, mais qui force encore la hauteur de la rangée « badge + titre + description » | R3 | Réduire encore la vidéo et la détacher du flux (position absolue en surimpression), pour que la hauteur de la carte dépende du texte, pas de la vidéo |
| 6 | CLV-05 | (489, 795, 474, 55) | Bandeau séparé brun/or pleine largeur « Ton parent regarde la séance. » | R2 | Même correction que la Rectification 3 : rétracter la notice à son point rouge clignotant et afficher le texte temporaire à sa place, pas de bandeau à part. Unifier aussi le libellé avec celui de CLV-04 (« Votre parent observe la séance. ») |
| 7 | CLV-05 | Parler (600, 798, 95, 67) ; Caméra (735, 798, 125, 67) | Bouton « Parler » plein vert (cercle) et bouton « Caméra » plein violet en **pilule/stade** plus large que les autres boutons | R5 | Revenir au même style de bouton que CLV-04/CLV-06 : cercles uniformes, mêmes couleurs neutres (fond sombre, icône claire) sauf état actif documenté ailleurs dans l'app ; pas de nouvelle paire de couleurs (vert/violet plein) ni de nouvelle forme (pilule) propre à l'interface guidée |
| 8 | CLV-06 | zone (1000, 295, 445, 45) actuelle (« La séance se poursuit. ») | Aucun point rouge d'enregistrement sur l'écran enseignant, alors que la séance est enregistrée (cf. CLV-04) | R1 | Ajouter le point rouge discret (avec la mention légale au premier affichage) à côté ou sous le bandeau de statut vert, sans dupliquer un second bandeau plein |
| 9 | CLV-06 | (1300, 400, 145, 140) | Vidéo en incrustation, plus compacte que sur CLV-04/05 mais toujours en flux (repousse la grille d'outils sous elle) | R3 | Détacher la vidéo du flux (surimpression en position absolue) pour qu'elle n'influence plus la position de la grille d'outils en dessous |
| 10 | CLV-06 | Pointeur/Marquer/Masquer/Annoter (1300, 555, 145, 165) vs barre du bas (1000, 798, 445, 67) | Deux familles de boutons différentes dans la même salle : carrés à coins arrondis (outils) vs cercles pleins (appel) | R5 | Harmoniser la forme des boutons d'outils sur le même socle que les boutons d'appel (même rayon de coin, même logique de fond/contour), pour qu'il n'y ait qu'un seul style de bouton dans toute la salle |
| 11 | CLV-06 | (1300, 730, 145, 45) | Bandeau séparé brun/or « Tuteur de Mariam observe. » | R2 | Même correction que 3 et 6 : rétracter la notice à un point rouge clignotant et afficher le texte temporaire à la place de la mention légale, pas de bandeau à part. Unifier le libellé (garder le même gabarit de phrase que pour le parent) |
| 12 | CLV-04, CLV-05, CLV-06 | libellés « Votre parent observe la séance. » / « Ton parent regarde la séance. » / « Tuteur de Mariam observe. » | Trois formulations différentes pour la même idée (quelqu'un observe la séance) | relevé (cohérence de texte) | Adopter un seul gabarit de phrase pour la notice temporaire de visite, décliné seulement par le rôle de l'observateur (parent/tuteur) |

Notes de vérification : chaque boîte listée ci-dessus a été recadrée isolément (`chk1_video_CLV04.png`, `chk2_observe_CLV04.png`, `chk3_notice_CLV04.png`, `chk4_video_CLV05.png`, `chk5_observe_CLV05.png`, `chk6_video_CLV06.png` dans `C:\RA\pilotage\10_classe\V\tuiles\`) pour confirmer qu'elle entoure bien l'élément fautif avant d'être consignée ici.

## 5. Hors périmètre de cette image

- Aucune variante mobile, aucun état vide/chargement/erreur, aucun thème clair n'apparaît dans ce fichier : ces états restent à dériver ailleurs (pas dans cette fiche).
- R8 (défilement au pouce sur mobile) ne s'applique pas : les trois écrans sont des maquettes web, pas mobile.
