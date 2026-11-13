# Le programme des bases, séance par séance

> **ARBITRÉ le 13/11/2026 par l'architecte pédagogique, sur la décision du directeur du même jour. À relire par le directeur.** Le directeur peut corriger toute ligne à tout moment ; une correction datée de sa part l'emporte.
> Ce fichier est **la commande du livre de lecture** (`CONTENUS-ATTENDUS.md`, partie 2) : le livre se rédige leçon par leçon dans cet ordre, et la colonne « Plage » se remplit quand il existe.
> **Police (DÉCIDÉ 13/11).** Tout l'arabe de ce programme, et de tout écran qui l'affiche (plan, point de fin de séance, chemin), est de l'arabe de contenu : il s'affiche dans la police du Coran, UthmanicHafs ; seule l'interface garde Noto Sans Arabic (charte, partie 11). Le ya isolé s'y dessine sans points, comme dans le Mushaf : pour la leçon du ya (étape 1), à trancher par le directeur.
> Toutes les valeurs (séances par semaine, leçons avant une consolidation, durée prévue de chaque étape, écart libre) sont dans `REGLAGES.md` ; ce fichier les applique.

## 1. La décision et ses règles

**DÉCIDÉ (directeur, 13/11/2026).** Le programme est découpé « au jour près » : l'enseignant et l'élève savent, pour chaque séance, quelle partie est prévue (« le 25 décembre, la classe A fait de cette ligne à cette ligne »), parce que c'est découpé à l'avance ; s'il y a une exception, l'enseignant la précise (ajout ou manque). C'est ce découpage qui permet au système de suivre.

**ARBITRÉ (13/11/2026).**
1. **L'unité est la séance, pas la date.** Pour chaque étape et chaque tranche d'âge, le programme fixe la suite numérotée des séances : 3 par semaine, soit 2 leçons nouvelles puis 1 consolidation (réglages de `REGLAGES.md`). Nombre de séances d'une étape = sa durée prévue en semaines (tableau 1 bis) × 3. Chaque séance dit : leçon ou consolidation, son contenu, sa plage dans le livre (page, ligne de, ligne à), les objectifs touchés, la règle de tajwid touchée.
2. **La date de chaque séance est calculée par le serveur**, pour chaque classe : jours de la classe, fermetures de l'académie, pauses de la classe. Elle n'est jamais saisie à la main. Une fermeture décale tout le plan.
3. **Le plan appartient à la classe ; l'état appartient à chaque élève** (« A suivi », « À renforcer », « Rattraper ce cours »).
4. **Le point de fin de séance** affiche la séance prévue et propose trois réponses : « Vu comme prévu » (par défaut), « On a vu moins » (l'enseignant touche l'endroit où la classe s'est vraiment arrêtée), « On a vu plus ». Le plan glisse seul, sans rien ressaisir (charte, partie 5).
5. **Ce que l'enseignant fait sans demander** : ralentir ou avancer jusqu'à l'écart libre avec le plan (réglage : 2 leçons) ; changer l'ordre à l'intérieur de la semaine ; ajouter une révision ; choisir sa méthode (DÉCIDÉ 13/10). **Jamais** : sauter un objectif. Au-delà de l'écart libre, rien n'est bloqué : la direction le voit, pour le pilotage, sans message de reproche. La marge entre la durée prévue et la date limite absorbe les glissements ; quand la marge restante tombe à zéro, la règle de la date limite s'applique (soutien, jamais de passage automatique ; moteur, règle 36).
6. **Tout est tracé par le système** : séance prévue, séance faite, écart, qui, quand, sans saisie de plus.

## 2. Comment lire les tableaux

- **Une ligne par séance**, numérotée dans l'étape. « Leçon » : une leçon nouvelle. « Consolidation » : relire ensemble les leçons de la semaine et la matière secondaire. À chaque séance, leçon ou consolidation, le système tire aussi un élève présent, à tour de rôle, et un passage déjà vu, hors de la leçon du jour : c'est l'observation non préparée, avec le toucher obligatoire de l'enseignant (`REGLAGES.md`).
- **Le contenu est le même pour toutes les tranches d'âge.** Il est découpé au rythme des 6 à 9 ans (une leçon du livre = une leçon nouvelle des 6 à 9 ans) ; les autres tranches en regroupent plusieurs par séance (« · » sépare les leçons regroupées). L'étape 1 des 6 à 9 ans reprend le découpage déjà montré au directeur.
- **Plage** : « à fixer par le livre » tant que le livre n'est pas écrit ; pour une sourate ou une lecture dans le Mushaf, la sourate et les versets.
- **Objectifs** : les codes de `EVALUATIONS.md`, parties 4.2 à 4.5 (l'objectif 1.3, par exemple, est le 3ᵉ objectif de l'étape 1). Étape 1 : 1.1 reconnaître les lettres dans le désordre et distinguer les formes proches ; 1.2 au début, au milieu, à la fin du mot ; 1.3 le point de sortie (règle 1) ; 1.4 épaisses et fines (règle 2). Étape 2 : 2.1 les voyelles brèves, le soukoun, le tanwin ; 2.2 brève ou longue (règle 3) ; 2.3 la chadda et la nasalisation (règle 4) ; 2.4 la qalqala (règle 5) ; 2.5 lire sans épeler. Étape 3 : 3.1 la fin du livre ; 3.2 une page du Mushaf ; 3.3 l'arrêt en fin de verset (règle 6) ; 3.4 le lam du nom d'Allah (règle 7). Étape 4 : 4.1 réciter de mémoire ; 4.2 garder les sourates apprises ; 4.3 les règles 1 à 7 en récitant ; 4.4 le noun sans voyelle et le tanwin (règle 8) ; 4.5 les allongements longs (règle 9).
- **Règles** : les neuf règles du tajwid des bases (`EVALUATIONS.md`, 4.1 bis). « Imitée » : l'élève la répète sans qu'elle soit nommée ; « nommée » : elle reçoit son nom ce jour-là ; un chiffre seul : elle est pratiquée. Une règle n'est jamais interrogée en théorie.
- **Matière secondaire** : selon la charte (partie 3.1) et `CONTENU-PRIERE-ET-ABLUTIONS.md`. Pour les 6 à 9 ans, rien avant la chadda ; puis Al-Fatiha, An-Nâs, Al-Falaq, Al-Ikhlâs, puis les paroles de la prière et les ablutions, en cinq groupes, du plus court au plus long. Dès 10 ans, Al-Fatiha dès la première semaine, puis le même ordre (durées plus courtes : elles sont laissées à l'enseignant, DÉCIDÉ 13/10 ; celles du tableau sont un repère). Elle se travaille surtout en consolidation, avec un court rappel à la fin des leçons ; elle ne bloque pas les étapes 1 à 3. Quand tout est appris : révision, invocations et adab (contenus attendus du directeur).
- **« Coche prévue »** : la séance où l'enseignant devrait pouvoir cocher la sourate. Une sourate non cochée à cette séance est l'une des cinq sources de « À renforcer » (charte, partie 5).
- **« Petit bilan »** : placé à la dernière séance des étapes 1 à 3. Le système le propose plus tôt si les objectifs de l'étape sont acquis ; l'enseignant le confirme.
- **Choix de contenu à relire par le directeur** : l'ordre des voyelles et des règles de l'étape 2 ; les sourates du juz 30 lues dans le Mushaf à l'étape 3 (87, 88, 93 à 98 : hors des 17 sourates, pour garder celles-ci à l'étape 4) ; la coupe d'Al-'Âdiyât en deux leçons pour les 6 à 9 ans.
- **Les dates** : jamais dans ce fichier. Le serveur les calcule pour chaque classe ; l'enfant de 6 à 9 ans ne voit ni date de séance ni durée (charte, partie 10 bis).

## 6-9 ans


### Étape 1 · Les lettres : 24 séances (16 leçons, 8 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | ا ب : les lettres, seules ; leur point de sortie | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 2 | Leçon 2 | ت ث | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 1.1, 1.3 | 1 imitée | Aucune : le livre seul jusqu'à la chadda |
| 4 | Leçon 3 | ج ح | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 5 | Leçon 4 | خ, puis ج ح خ ensemble (même forme, sons différents) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Aucune : le livre seul jusqu'à la chadda |
| 7 | Leçon 5 | د ذ | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 8 | Leçon 6 | ر ز | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 1.1, 1.3 | 1 imitée | Aucune : le livre seul jusqu'à la chadda |
| 10 | Leçon 7 | س ش | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 11 | Leçon 8 | ص ض (près de س et د : fines et épaisses côte à côte) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 12 | Consolidation | Consolidation : fines et épaisses ; la règle 2 reçoit son nom | Leçons de la semaine | 1.3, 1.4 | 2 nommée | Aucune : le livre seul jusqu'à la chadda |
| 13 | Leçon 9 | ط ظ (près de ت et ذ) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 14 | Leçon 10 | ع غ (près de ء et خ) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Aucune : le livre seul jusqu'à la chadda |
| 16 | Leçon 11 | ف ق (ق près de ك) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 17 | Leçon 12 | ك ل | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 18 | Consolidation | Consolidation : relire les leçons 11, 12 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Aucune : le livre seul jusqu'à la chadda |
| 19 | Leçon 13 | م ن | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 20 | Leçon 14 | ه و ي (ه près de ح) | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 21 | Consolidation | Consolidation : les 28 lettres dans le désordre, par familles de points de sortie ; la règle 1 reçoit son nom | Leçons de la semaine | 1.1, 1.3, 1.4 | 1 nommée | Aucune : le livre seul jusqu'à la chadda |
| 22 | Leçon 15 | La lettre au début, au milieu, à la fin du mot | à fixer par le livre | 1.2 |  | |
| 23 | Leçon 16 | Les lettres qui se ressemblent (ب ت ث, ج ح خ, د ذ, ر ز, س ش, ص ض, ط ظ, ع غ, ف ق) | à fixer par le livre | 1.1 |  | |
| 24 | Consolidation | Révision générale et petit bilan | Toute l'étape | 1.1 à 1.4 | 1, 2 | Aucune : le livre seul jusqu'à la chadda |

### Étape 2 · Lire avec les voyelles : 42 séances (28 leçons, 14 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Fatha (a) : ا à خ | à fixer par le livre | 2.1 |  | |
| 2 | Leçon 2 | Fatha : د à ش | à fixer par le livre | 2.1 |  | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 2.1 |  | Aucune : le livre seul jusqu'à la chadda |
| 4 | Leçon 3 | Fatha : ص à ي | à fixer par le livre | 2.1 |  | |
| 5 | Leçon 4 | Kasra (i) : ا à ش | à fixer par le livre | 2.1 |  | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 2.1 |  | Aucune : le livre seul jusqu'à la chadda |
| 7 | Leçon 5 | Kasra : ص à ي | à fixer par le livre | 2.1 |  | |
| 8 | Leçon 6 | Damma (ou) : ا à ش | à fixer par le livre | 2.1 |  | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 2.1 |  | Aucune : le livre seul jusqu'à la chadda |
| 10 | Leçon 7 | Damma : ص à ي | à fixer par le livre | 2.1 |  | |
| 11 | Leçon 8 | Les trois voyelles brèves mélangées | à fixer par le livre | 2.1 |  | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 2.1 |  | Aucune : le livre seul jusqu'à la chadda |
| 13 | Leçon 9 | Syllabes et mots de deux lettres | à fixer par le livre | 2.1, 2.5 |  | |
| 14 | Leçon 10 | Mots de trois lettres, voyelles brèves | à fixer par le livre | 2.1, 2.5 |  | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 2.1, 2.5 |  | Aucune : le livre seul jusqu'à la chadda |
| 16 | Leçon 11 | L'alif d'allongement (â) : deux temps | à fixer par le livre | 2.2 | 3 imitée | |
| 17 | Leçon 12 | Le ya d'allongement (î) | à fixer par le livre | 2.2 | 3 imitée | |
| 18 | Consolidation | Consolidation : relire les leçons 11, 12 | Leçons de la semaine | 2.2 | 3 imitée | Aucune : le livre seul jusqu'à la chadda |
| 19 | Leçon 13 | Le waw d'allongement (oû) | à fixer par le livre | 2.2 | 3 imitée | |
| 20 | Leçon 14 | Brève ou longue, côte à côte (مَلِكِ et مَٰلِكِ) ; la règle 3 reçoit son nom | à fixer par le livre | 2.2 | 3 nommée | |
| 21 | Consolidation | Consolidation : relire les leçons 13, 14 | Leçons de la semaine | 2.2 | 3 nommée | Aucune : le livre seul jusqu'à la chadda |
| 22 | Leçon 15 | Le soukoun : syllabes fermées | à fixer par le livre | 2.1 |  | |
| 23 | Leçon 16 | Le soukoun sur ق ط ب ج د : le rebond | à fixer par le livre | 2.1, 2.4 | 5 imitée | |
| 24 | Consolidation | Consolidation : relire les leçons 15, 16 | Leçons de la semaine | 2.1, 2.4 | 5 imitée | Aucune : le livre seul jusqu'à la chadda |
| 25 | Leçon 17 | La qalqala ; la règle 5 reçoit son nom | à fixer par le livre | 2.4 | 5 nommée | |
| 26 | Leçon 18 | Le tanwin « an » | à fixer par le livre | 2.1 |  | |
| 27 | Consolidation | Consolidation : relire les leçons 17, 18 | Leçons de la semaine | 2.1, 2.4 | 5 nommée | Aucune : le livre seul jusqu'à la chadda |
| 28 | Leçon 19 | Le tanwin « in » et « oun » | à fixer par le livre | 2.1 |  | |
| 29 | Leçon 20 | Le tanwin dans des mots | à fixer par le livre | 2.1, 2.5 |  | |
| 30 | Consolidation | Consolidation : relire les leçons 19, 20 | Leçons de la semaine | 2.1, 2.5 |  | Aucune : le livre seul jusqu'à la chadda |
| 31 | Leçon 21 | La chadda : la lettre doublée | à fixer par le livre | 2.3 | 4 imitée | |
| 32 | Leçon 22 | La chadda avec les voyelles longues | à fixer par le livre | 2.2, 2.3 | 3, 4 imitées | |
| 33 | Consolidation | Consolidation : relire les leçons 21, 22 | Leçons de la semaine | 2.2, 2.3 | 3, 4 imitées | Aucune : le livre seul jusqu'à la chadda |
| 34 | Leçon 23 | Le noun et le mim doublés : la nasalisation de deux temps | à fixer par le livre | 2.3 | 4 imitée | |
| 35 | Leçon 24 | La chadda et la nasalisation ; la règle 4 reçoit son nom | à fixer par le livre | 2.3 | 4 nommée | |
| 36 | Consolidation | Consolidation : relire les leçons 23, 24 | Leçons de la semaine | 2.3 | 4 nommée | Aucune : le livre seul jusqu'à la chadda |
| 37 | Leçon 25 | Mots longs (plusieurs syllabes) | à fixer par le livre | 2.5 | 3, 4, 5 | |
| 38 | Leçon 26 | Mots longs mélangeant toutes les règles | à fixer par le livre | 2.5 | 3, 4, 5 | |
| 39 | Consolidation | Consolidation : relire les leçons 25, 26 | Leçons de la semaine | 2.5 | 3, 4, 5 | Al-Fatiha, versets 1 à 4 |
| 40 | Leçon 27 | Lignes de mots, sans épeler | à fixer par le livre | 2.5 | 3, 4, 5 | |
| 41 | Leçon 28 | Révision : une ligne de chaque leçon de l'étape | à fixer par le livre | 2.1 à 2.5 | 3, 4, 5 | |
| 42 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 2.1 à 2.5 | 1 à 5 | Al-Fatiha, versets 5 à 7 |

### Étape 3 · Lire dans le Coran : 24 séances (16 leçons, 8 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | L'article ال : lam lu, ou lam muet devant la lettre doublée | à fixer par le livre | 3.1 | 4 | |
| 2 | Leçon 2 | La hamza de liaison (ٱ), qui ne se lit pas dans la suite | à fixer par le livre | 3.1 |  | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 3.1 | 4 | Al-Fatiha entière ; coche prévue |
| 4 | Leçon 3 | Les petites lettres du Mushaf (alif suscrit, petits waw et ya) | à fixer par le livre | 3.1, 3.2 | 3 | |
| 5 | Leçon 4 | Les signes du Mushaf : fin de verset, soukoun, signe d'allongement | à fixer par le livre | 3.2 |  | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 3.1, 3.2 | 3 | An-Nâs, versets 1 à 3 |
| 7 | Leçon 5 | S'arrêter en fin de verset : soukoun, « an » lu « â », ة lu « h » | à fixer par le livre | 3.3 | 6 imitée | |
| 8 | Leçon 6 | L'arrêt en fin de verset ; la règle 6 reçoit son nom | à fixer par le livre | 3.3 | 6 nommée | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 3.3 | 6 nommée | An-Nâs, versets 4 à 6 ; coche prévue |
| 10 | Leçon 7 | Le lam du nom d'Allah, épais ou fin | à fixer par le livre | 3.4 | 7 imitée | |
| 11 | Leçon 8 | Le lam du nom d'Allah ; la règle 7 reçoit son nom | à fixer par le livre | 3.4 | 7 nommée | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 3.4 | 7 nommée | Al-Falaq, versets 1 à 3 |
| 13 | Leçon 9 | Dernières pages du livre : phrases | à fixer par le livre | 3.1 | 1 à 7 | |
| 14 | Leçon 10 | Dernières pages du livre : textes longs, sans épeler | à fixer par le livre | 3.1 | 1 à 7 | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 3.1 | 1 à 7 | Al-Falaq, versets 4 et 5 ; coche prévue |
| 16 | Leçon 11 | Mushaf : lecture d'Ad-Duhâ et d'Ash-Sharh | Mushaf : sourates 93 et 94 | 3.2 | 1 à 7 | |
| 17 | Leçon 12 | Mushaf : lecture d'At-Tîn et d'Al-'Alaq | Mushaf : sourates 95 et 96 | 3.2 | 1 à 7 | |
| 18 | Consolidation | Consolidation : relire les leçons 11, 12 | Leçons de la semaine | 3.2 | 1 à 7 | Al-Ikhlâs, versets 1 et 2 |
| 19 | Leçon 13 | Mushaf : lecture d'Al-Qadr et d'Al-Bayyina | Mushaf : sourates 97 et 98 | 3.2 | 1 à 7 | |
| 20 | Leçon 14 | Mushaf : lecture d'Al-A'lâ | Mushaf : sourate 87 | 3.2 | 1 à 7 | |
| 21 | Consolidation | Consolidation : relire les leçons 13, 14 | Leçons de la semaine | 3.2 | 1 à 7 | Al-Ikhlâs, versets 3 et 4 ; coche prévue |
| 22 | Leçon 15 | Mushaf : lecture d'Al-Ghâshiya | Mushaf : sourate 88 | 3.2 | 1 à 7 | |
| 23 | Leçon 16 | Mushaf : une page tirée au hasard dans le juz 30, déjà lue ou non | Mushaf : juz 30 | 3.2, 3.3, 3.4 | 1 à 7 | |
| 24 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 3.1 à 3.4 | 1 à 7 | Prière, groupe 1 (« Allâhu akbar », « Âmîn », « Bismillâh ») ; gestes des ablutions et de la prière |

### Étape 4 · Les sourates courtes : 21 séances (14 leçons, 7 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Al-Masad : mémoriser | Mushaf : sourate 111, versets 1 à 5 | 4.1, 4.3, 4.4, 4.5 | 8, 9 imitées | |
| 2 | Leçon 2 | An-Nasr : mémoriser | Mushaf : sourate 110, versets 1 à 3 | 4.1, 4.3, 4.5 | 9 imitée | |
| 3 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Prière, groupe 1 (« Allâhu akbar », « Âmîn », « Bismillâh ») ; gestes des ablutions et de la prière (suite) |
| 4 | Leçon 3 | Al-Kâfirûn : mémoriser | Mushaf : sourate 109, versets 1 à 6 | 4.1, 4.3, 4.4, 4.5 | 8, 9 nommées | |
| 5 | Leçon 4 | Al-Kawthar : mémoriser | Mushaf : sourate 108, versets 1 à 3 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 6 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Prière, groupe 2 (inclinaison, redressement, prosternation, assise, salut) |
| 7 | Leçon 5 | Al-Mâ'ûn : mémoriser | Mushaf : sourate 107, versets 1 à 7 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 8 | Leçon 6 | Quraysh : mémoriser | Mushaf : sourate 106, versets 1 à 4 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 9 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Prière, groupe 3 (protection et basmala, attestation après les ablutions, ouverture) |
| 10 | Leçon 7 | Al-Fîl : mémoriser | Mushaf : sourate 105, versets 1 à 5 | 4.1, 4.3, 4.4 | 8 nommée | |
| 11 | Leçon 8 | Al-Humaza : mémoriser (dont le seul « changé en mim » des 17 sourates) | Mushaf : sourate 104, versets 1 à 9 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 12 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Prière, groupe 4 (le tachahhoud) |
| 13 | Leçon 9 | Al-'Asr : mémoriser | Mushaf : sourate 103, versets 1 à 3 | 4.1, 4.3, 4.4 | 8 | |
| 14 | Leçon 10 | At-Takâthur : mémoriser | Mushaf : sourate 102, versets 1 à 8 | 4.1, 4.3, 4.4 | 8 | |
| 15 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Prière, groupe 5 (la prière sur le Prophète ﷺ) ; prière complète |
| 16 | Leçon 11 | Al-Qâri'a : mémoriser | Mushaf : sourate 101, versets 1 à 11 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 17 | Leçon 12 | Al-'Âdiyât : mémoriser | Mushaf : sourate 100, versets 1 à 6 | 4.1, 4.3, 4.4 | 8 | |
| 18 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 19 | Leçon 13 | Al-'Âdiyât : mémoriser (suite) | Mushaf : sourate 100, versets 7 à 11 | 4.1, 4.3, 4.4 | 8 | |
| 20 | Leçon 14 | Az-Zalzalah : mémoriser | Mushaf : sourate 99, versets 1 à 8 | 4.1, 4.3, 4.4 | 8 | |
| 21 | Consolidation | Révision générale des 17 sourates ; prêt pour l'examen de fin des bases | Les 17 sourates | 4.1 à 4.5 | 1 à 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

## 10-13 ans


### Étape 1 · Les lettres : 18 séances (12 leçons, 6 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | ا ب : les lettres, seules ; leur point de sortie | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 2 | Leçon 2 | ت ث | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 1.1, 1.3 | 1 imitée | Al-Fatiha, versets 1 à 4 |
| 4 | Leçon 3 | ج ح · خ, puis ج ح خ ensemble (même forme, sons différents) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 5 | Leçon 4 | د ذ | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Fatiha, versets 5 à 7 ; coche prévue |
| 7 | Leçon 5 | ر ز | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 8 | Leçon 6 | س ش · ص ض (près de س et د : fines et épaisses côte à côte) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | An-Nâs ; coche prévue |
| 10 | Leçon 7 | ط ظ (près de ت et ذ) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 11 | Leçon 8 | ع غ (près de ء et خ) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Falaq ; coche prévue |
| 13 | Leçon 9 | ف ق (ق près de ك) · ك ل | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 14 | Leçon 10 | م ن | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Ikhlâs ; coche prévue |
| 16 | Leçon 11 | ه و ي (ه près de ح) | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 17 | Leçon 12 | La lettre au début, au milieu, à la fin du mot · Les lettres qui se ressemblent (ب ت ث, ج ح خ, د ذ, ر ز, س ش, ص ض, ط ظ, ع غ, ف ق) | à fixer par le livre | 1.1, 1.2 |  | |
| 18 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 1.1 à 1.4 | 1, 2 | Prière, groupe 1 (« Allâhu akbar », « Âmîn », « Bismillâh ») ; gestes des ablutions et de la prière |

### Étape 2 · Lire avec les voyelles : 33 séances (22 leçons, 11 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Fatha (a) : ا à خ | à fixer par le livre | 2.1 |  | |
| 2 | Leçon 2 | Fatha : د à ش | à fixer par le livre | 2.1 |  | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 2.1 |  | Prière, groupe 2 (inclinaison, redressement, prosternation, assise, salut) |
| 4 | Leçon 3 | Fatha : ص à ي | à fixer par le livre | 2.1 |  | |
| 5 | Leçon 4 | Kasra (i) : ا à ش · Kasra : ص à ي | à fixer par le livre | 2.1 |  | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 2.1 |  | Prière, groupe 3 (protection et basmala, attestation après les ablutions, ouverture) |
| 7 | Leçon 5 | Damma (ou) : ا à ش | à fixer par le livre | 2.1 |  | |
| 8 | Leçon 6 | Damma : ص à ي | à fixer par le livre | 2.1 |  | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 2.1 |  | Prière, groupe 4 (le tachahhoud) |
| 10 | Leçon 7 | Les trois voyelles brèves mélangées | à fixer par le livre | 2.1 |  | |
| 11 | Leçon 8 | Syllabes et mots de deux lettres · Mots de trois lettres, voyelles brèves | à fixer par le livre | 2.1, 2.5 |  | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 2.1, 2.5 |  | Prière, groupe 5 (la prière sur le Prophète ﷺ) ; prière complète |
| 13 | Leçon 9 | L'alif d'allongement (â) : deux temps | à fixer par le livre | 2.2 | 3 imitée | |
| 14 | Leçon 10 | Le ya d'allongement (î) | à fixer par le livre | 2.2 | 3 imitée | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 2.2 | 3 imitée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 16 | Leçon 11 | Le waw d'allongement (oû) · Brève ou longue, côte à côte (مَلِكِ et مَٰلِكِ) ; la règle 3 reçoit son nom | à fixer par le livre | 2.2 | 3 nommée | |
| 17 | Leçon 12 | Le soukoun : syllabes fermées | à fixer par le livre | 2.1 |  | |
| 18 | Consolidation | Consolidation : relire les leçons 11, 12 | Leçons de la semaine | 2.1, 2.2 | 3 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 19 | Leçon 13 | Le soukoun sur ق ط ب ج د : le rebond | à fixer par le livre | 2.1, 2.4 | 5 imitée | |
| 20 | Leçon 14 | La qalqala ; la règle 5 reçoit son nom | à fixer par le livre | 2.4 | 5 nommée | |
| 21 | Consolidation | Consolidation : relire les leçons 13, 14 | Leçons de la semaine | 2.1, 2.4 | 5 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 22 | Leçon 15 | Le tanwin « an » · Le tanwin « in » et « oun » | à fixer par le livre | 2.1 |  | |
| 23 | Leçon 16 | Le tanwin dans des mots | à fixer par le livre | 2.1, 2.5 |  | |
| 24 | Consolidation | Consolidation : relire les leçons 15, 16 | Leçons de la semaine | 2.1, 2.5 |  | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 25 | Leçon 17 | La chadda : la lettre doublée | à fixer par le livre | 2.3 | 4 imitée | |
| 26 | Leçon 18 | La chadda avec les voyelles longues | à fixer par le livre | 2.2, 2.3 | 3, 4 imitées | |
| 27 | Consolidation | Consolidation : relire les leçons 17, 18 | Leçons de la semaine | 2.2, 2.3 | 3, 4 imitées | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 28 | Leçon 19 | Le noun et le mim doublés : la nasalisation de deux temps · La chadda et la nasalisation ; la règle 4 reçoit son nom | à fixer par le livre | 2.3 | 4 nommée | |
| 29 | Leçon 20 | Mots longs (plusieurs syllabes) | à fixer par le livre | 2.5 | 3, 4, 5 | |
| 30 | Consolidation | Consolidation : relire les leçons 19, 20 | Leçons de la semaine | 2.3, 2.5 | 3, 5 ; 4 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 31 | Leçon 21 | Mots longs mélangeant toutes les règles | à fixer par le livre | 2.5 | 3, 4, 5 | |
| 32 | Leçon 22 | Lignes de mots, sans épeler · Révision : une ligne de chaque leçon de l'étape | à fixer par le livre | 2.1 à 2.5 | 3, 4, 5 | |
| 33 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 2.1 à 2.5 | 1 à 5 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

### Étape 3 · Lire dans le Coran : 18 séances (12 leçons, 6 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | L'article ال : lam lu, ou lam muet devant la lettre doublée | à fixer par le livre | 3.1 | 4 | |
| 2 | Leçon 2 | La hamza de liaison (ٱ), qui ne se lit pas dans la suite | à fixer par le livre | 3.1 |  | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 3.1 | 4 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 4 | Leçon 3 | Les petites lettres du Mushaf (alif suscrit, petits waw et ya) · Les signes du Mushaf : fin de verset, soukoun, signe d'allongement | à fixer par le livre | 3.1, 3.2 | 3 | |
| 5 | Leçon 4 | S'arrêter en fin de verset : soukoun, « an » lu « â », ة lu « h » | à fixer par le livre | 3.3 | 6 imitée | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 3.1, 3.2, 3.3 | 3 ; 6 imitée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 7 | Leçon 5 | L'arrêt en fin de verset ; la règle 6 reçoit son nom | à fixer par le livre | 3.3 | 6 nommée | |
| 8 | Leçon 6 | Le lam du nom d'Allah, épais ou fin · Le lam du nom d'Allah ; la règle 7 reçoit son nom | à fixer par le livre | 3.4 | 7 nommée | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 3.3, 3.4 | 6, 7 nommées | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 10 | Leçon 7 | Dernières pages du livre : phrases | à fixer par le livre | 3.1 | 1 à 7 | |
| 11 | Leçon 8 | Dernières pages du livre : textes longs, sans épeler | à fixer par le livre | 3.1 | 1 à 7 | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 3.1 | 1 à 7 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 13 | Leçon 9 | Mushaf : lecture d'Ad-Duhâ et d'Ash-Sharh · Mushaf : lecture d'At-Tîn et d'Al-'Alaq | Mushaf : sourates 93 et 94 ; Mushaf : sourates 95 et 96 | 3.2 | 1 à 7 | |
| 14 | Leçon 10 | Mushaf : lecture d'Al-Qadr et d'Al-Bayyina | Mushaf : sourates 97 et 98 | 3.2 | 1 à 7 | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 3.2 | 1 à 7 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 16 | Leçon 11 | Mushaf : lecture d'Al-A'lâ | Mushaf : sourate 87 | 3.2 | 1 à 7 | |
| 17 | Leçon 12 | Mushaf : lecture d'Al-Ghâshiya · Mushaf : une page tirée au hasard dans le juz 30, déjà lue ou non | Mushaf : sourate 88 ; Mushaf : juz 30 | 3.2, 3.3, 3.4 | 1 à 7 | |
| 18 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 3.1 à 3.4 | 1 à 7 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

### Étape 4 · Les sourates courtes : 15 séances (10 leçons, 5 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Al-Masad : mémoriser | Mushaf : sourate 111, versets 1 à 5 | 4.1, 4.3, 4.4, 4.5 | 8, 9 imitées | |
| 2 | Leçon 2 | An-Nasr : mémoriser | Mushaf : sourate 110, versets 1 à 3 | 4.1, 4.3, 4.5 | 9 imitée | |
| 3 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 4 | Leçon 3 | Al-Kâfirûn : mémoriser · Al-Kawthar : mémoriser | Mushaf : sourate 109, versets 1 à 6 ; Mushaf : sourate 108, versets 1 à 3 | 4.1, 4.3, 4.4, 4.5 | 8, 9 nommées | |
| 5 | Leçon 4 | Al-Mâ'ûn : mémoriser | Mushaf : sourate 107, versets 1 à 7 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 6 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 7 | Leçon 5 | Quraysh : mémoriser · Al-Fîl : mémoriser | Mushaf : sourate 106, versets 1 à 4 ; Mushaf : sourate 105, versets 1 à 5 | 4.1, 4.3, 4.4, 4.5 | 9 ; 8 nommée | |
| 8 | Leçon 6 | Al-Humaza : mémoriser (dont le seul « changé en mim » des 17 sourates) | Mushaf : sourate 104, versets 1 à 9 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 9 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 10 | Leçon 7 | Al-'Asr : mémoriser | Mushaf : sourate 103, versets 1 à 3 | 4.1, 4.3, 4.4 | 8 | |
| 11 | Leçon 8 | At-Takâthur : mémoriser · Al-Qâri'a : mémoriser | Mushaf : sourate 102, versets 1 à 8 ; Mushaf : sourate 101, versets 1 à 11 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 12 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 13 | Leçon 9 | Al-'Âdiyât : mémoriser | Mushaf : sourate 100, versets 1 à 6 | 4.1, 4.3, 4.4 | 8 | |
| 14 | Leçon 10 | Al-'Âdiyât : mémoriser (suite) · Az-Zalzalah : mémoriser | Mushaf : sourate 100, versets 7 à 11 ; Mushaf : sourate 99, versets 1 à 8 | 4.1, 4.3, 4.4 | 8 | |
| 15 | Consolidation | Révision générale des 17 sourates ; prêt pour l'examen de fin des bases | Les 17 sourates | 4.1 à 4.5 | 1 à 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

## 14-17 ans


### Étape 1 · Les lettres : 15 séances (10 leçons, 5 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | ا ب : les lettres, seules ; leur point de sortie | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 2 | Leçon 2 | ت ث · ج ح | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 1.1, 1.3 | 1 imitée | Al-Fatiha, versets 1 à 4 |
| 4 | Leçon 3 | خ, puis ج ح خ ensemble (même forme, sons différents) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 5 | Leçon 4 | د ذ · ر ز | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Fatiha, versets 5 à 7 ; coche prévue |
| 7 | Leçon 5 | س ش · ص ض (près de س et د : fines et épaisses côte à côte) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 8 | Leçon 6 | ط ظ (près de ت et ذ) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | An-Nâs ; coche prévue |
| 10 | Leçon 7 | ع غ (près de ء et خ) · ف ق (ق près de ك) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 11 | Leçon 8 | ك ل | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Falaq ; coche prévue |
| 13 | Leçon 9 | م ن · ه و ي (ه près de ح) | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 14 | Leçon 10 | La lettre au début, au milieu, à la fin du mot · Les lettres qui se ressemblent (ب ت ث, ج ح خ, د ذ, ر ز, س ش, ص ض, ط ظ, ع غ, ف ق) | à fixer par le livre | 1.1, 1.2 |  | |
| 15 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 1.1 à 1.4 | 1, 2 | Al-Ikhlâs ; coche prévue |

### Étape 2 · Lire avec les voyelles : 27 séances (18 leçons, 9 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Fatha (a) : ا à خ | à fixer par le livre | 2.1 |  | |
| 2 | Leçon 2 | Fatha : د à ش · Fatha : ص à ي | à fixer par le livre | 2.1 |  | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 2.1 |  | Prière, groupe 1 (« Allâhu akbar », « Âmîn », « Bismillâh ») ; gestes des ablutions et de la prière |
| 4 | Leçon 3 | Kasra (i) : ا à ش | à fixer par le livre | 2.1 |  | |
| 5 | Leçon 4 | Kasra : ص à ي · Damma (ou) : ا à ش | à fixer par le livre | 2.1 |  | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 2.1 |  | Prière, groupe 2 (inclinaison, redressement, prosternation, assise, salut) |
| 7 | Leçon 5 | Damma : ص à ي | à fixer par le livre | 2.1 |  | |
| 8 | Leçon 6 | Les trois voyelles brèves mélangées · Syllabes et mots de deux lettres | à fixer par le livre | 2.1, 2.5 |  | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 2.1, 2.5 |  | Prière, groupe 3 (protection et basmala, attestation après les ablutions, ouverture) |
| 10 | Leçon 7 | Mots de trois lettres, voyelles brèves | à fixer par le livre | 2.1, 2.5 |  | |
| 11 | Leçon 8 | L'alif d'allongement (â) : deux temps · Le ya d'allongement (î) | à fixer par le livre | 2.2 | 3 imitée | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 2.1, 2.2, 2.5 | 3 imitée | Prière, groupe 4 (le tachahhoud) |
| 13 | Leçon 9 | Le waw d'allongement (oû) · Brève ou longue, côte à côte (مَلِكِ et مَٰلِكِ) ; la règle 3 reçoit son nom | à fixer par le livre | 2.2 | 3 nommée | |
| 14 | Leçon 10 | Le soukoun : syllabes fermées | à fixer par le livre | 2.1 |  | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 2.1, 2.2 | 3 nommée | Prière, groupe 5 (la prière sur le Prophète ﷺ) ; prière complète |
| 16 | Leçon 11 | Le soukoun sur ق ط ب ج د : le rebond · La qalqala ; la règle 5 reçoit son nom | à fixer par le livre | 2.1, 2.4 | 5 nommée | |
| 17 | Leçon 12 | Le tanwin « an » | à fixer par le livre | 2.1 |  | |
| 18 | Consolidation | Consolidation : relire les leçons 11, 12 | Leçons de la semaine | 2.1, 2.4 | 5 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 19 | Leçon 13 | Le tanwin « in » et « oun » · Le tanwin dans des mots | à fixer par le livre | 2.1, 2.5 |  | |
| 20 | Leçon 14 | La chadda : la lettre doublée | à fixer par le livre | 2.3 | 4 imitée | |
| 21 | Consolidation | Consolidation : relire les leçons 13, 14 | Leçons de la semaine | 2.1, 2.3, 2.5 | 4 imitée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 22 | Leçon 15 | La chadda avec les voyelles longues · Le noun et le mim doublés : la nasalisation de deux temps | à fixer par le livre | 2.2, 2.3 | 3, 4 imitées | |
| 23 | Leçon 16 | La chadda et la nasalisation ; la règle 4 reçoit son nom | à fixer par le livre | 2.3 | 4 nommée | |
| 24 | Consolidation | Consolidation : relire les leçons 15, 16 | Leçons de la semaine | 2.2, 2.3 | 3 imitée ; 4 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 25 | Leçon 17 | Mots longs (plusieurs syllabes) · Mots longs mélangeant toutes les règles | à fixer par le livre | 2.5 | 3, 4, 5 | |
| 26 | Leçon 18 | Lignes de mots, sans épeler · Révision : une ligne de chaque leçon de l'étape | à fixer par le livre | 2.1 à 2.5 | 3, 4, 5 | |
| 27 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 2.1 à 2.5 | 1 à 5 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

### Étape 3 · Lire dans le Coran : 15 séances (10 leçons, 5 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | L'article ال : lam lu, ou lam muet devant la lettre doublée | à fixer par le livre | 3.1 | 4 | |
| 2 | Leçon 2 | La hamza de liaison (ٱ), qui ne se lit pas dans la suite · Les petites lettres du Mushaf (alif suscrit, petits waw et ya) | à fixer par le livre | 3.1, 3.2 | 3 | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 3.1, 3.2 | 3, 4 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 4 | Leçon 3 | Les signes du Mushaf : fin de verset, soukoun, signe d'allongement | à fixer par le livre | 3.2 |  | |
| 5 | Leçon 4 | S'arrêter en fin de verset : soukoun, « an » lu « â », ة lu « h » · L'arrêt en fin de verset ; la règle 6 reçoit son nom | à fixer par le livre | 3.3 | 6 nommée | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 3.2, 3.3 | 6 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 7 | Leçon 5 | Le lam du nom d'Allah, épais ou fin · Le lam du nom d'Allah ; la règle 7 reçoit son nom | à fixer par le livre | 3.4 | 7 nommée | |
| 8 | Leçon 6 | Dernières pages du livre : phrases | à fixer par le livre | 3.1 | 1 à 7 | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 3.1, 3.4 | 1 à 7 ; 7 nommée | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 10 | Leçon 7 | Dernières pages du livre : textes longs, sans épeler · Mushaf : lecture d'Ad-Duhâ et d'Ash-Sharh | à fixer par le livre ; Mushaf : sourates 93 et 94 | 3.1, 3.2 | 1 à 7 | |
| 11 | Leçon 8 | Mushaf : lecture d'At-Tîn et d'Al-'Alaq | Mushaf : sourates 95 et 96 | 3.2 | 1 à 7 | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 3.1, 3.2 | 1 à 7 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 13 | Leçon 9 | Mushaf : lecture d'Al-Qadr et d'Al-Bayyina · Mushaf : lecture d'Al-A'lâ | Mushaf : sourates 97 et 98 ; Mushaf : sourate 87 | 3.2 | 1 à 7 | |
| 14 | Leçon 10 | Mushaf : lecture d'Al-Ghâshiya · Mushaf : une page tirée au hasard dans le juz 30, déjà lue ou non | Mushaf : sourate 88 ; Mushaf : juz 30 | 3.2, 3.3, 3.4 | 1 à 7 | |
| 15 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 3.1 à 3.4 | 1 à 7 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

### Étape 4 · Les sourates courtes : 15 séances (10 leçons, 5 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Al-Masad : mémoriser | Mushaf : sourate 111, versets 1 à 5 | 4.1, 4.3, 4.4, 4.5 | 8, 9 imitées | |
| 2 | Leçon 2 | An-Nasr : mémoriser | Mushaf : sourate 110, versets 1 à 3 | 4.1, 4.3, 4.5 | 9 imitée | |
| 3 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 4 | Leçon 3 | Al-Kâfirûn : mémoriser · Al-Kawthar : mémoriser | Mushaf : sourate 109, versets 1 à 6 ; Mushaf : sourate 108, versets 1 à 3 | 4.1, 4.3, 4.4, 4.5 | 8, 9 nommées | |
| 5 | Leçon 4 | Al-Mâ'ûn : mémoriser | Mushaf : sourate 107, versets 1 à 7 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 6 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 7 | Leçon 5 | Quraysh : mémoriser · Al-Fîl : mémoriser | Mushaf : sourate 106, versets 1 à 4 ; Mushaf : sourate 105, versets 1 à 5 | 4.1, 4.3, 4.4, 4.5 | 9 ; 8 nommée | |
| 8 | Leçon 6 | Al-Humaza : mémoriser (dont le seul « changé en mim » des 17 sourates) | Mushaf : sourate 104, versets 1 à 9 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 9 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 10 | Leçon 7 | Al-'Asr : mémoriser | Mushaf : sourate 103, versets 1 à 3 | 4.1, 4.3, 4.4 | 8 | |
| 11 | Leçon 8 | At-Takâthur : mémoriser · Al-Qâri'a : mémoriser | Mushaf : sourate 102, versets 1 à 8 ; Mushaf : sourate 101, versets 1 à 11 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 12 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 13 | Leçon 9 | Al-'Âdiyât : mémoriser | Mushaf : sourate 100, versets 1 à 6 | 4.1, 4.3, 4.4 | 8 | |
| 14 | Leçon 10 | Al-'Âdiyât : mémoriser (suite) · Az-Zalzalah : mémoriser | Mushaf : sourate 100, versets 7 à 11 ; Mushaf : sourate 99, versets 1 à 8 | 4.1, 4.3, 4.4 | 8 | |
| 15 | Consolidation | Révision générale des 17 sourates ; prêt pour l'examen de fin des bases | Les 17 sourates | 4.1 à 4.5 | 1 à 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

## Adultes


### Étape 1 · Les lettres : 9 séances (6 leçons, 3 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | ا ب : les lettres, seules ; leur point de sortie · ت ث | à fixer par le livre | 1.1, 1.3 | 1 imitée | |
| 2 | Leçon 2 | ج ح · خ, puis ج ح خ ensemble (même forme, sons différents) · د ذ | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Fatiha, versets 1 à 4 |
| 4 | Leçon 3 | ر ز · س ش · ص ض (près de س et د : fines et épaisses côte à côte) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 5 | Leçon 4 | ط ظ (près de ت et ذ) · ع غ (près de ء et خ) | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 1.1, 1.3, 1.4 | 1, 2 imitées | Al-Fatiha, versets 5 à 7 ; coche prévue |
| 7 | Leçon 5 | ف ق (ق près de ك) · ك ل · م ن | à fixer par le livre | 1.1, 1.3, 1.4 | 1, 2 imitées | |
| 8 | Leçon 6 | ه و ي (ه près de ح) · La lettre au début, au milieu, à la fin du mot · Les lettres qui se ressemblent (ب ت ث, ج ح خ, د ذ, ر ز, س ش, ص ض, ط ظ, ع غ, ف ق) | à fixer par le livre | 1.1, 1.2, 1.3 | 1 imitée | |
| 9 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 1.1 à 1.4 | 1, 2 | An-Nâs ; coche prévue |

### Étape 2 · Lire avec les voyelles : 18 séances (12 leçons, 6 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Fatha (a) : ا à خ · Fatha : د à ش | à fixer par le livre | 2.1 |  | |
| 2 | Leçon 2 | Fatha : ص à ي · Kasra (i) : ا à ش | à fixer par le livre | 2.1 |  | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 2.1 |  | Al-Falaq ; coche prévue |
| 4 | Leçon 3 | Kasra : ص à ي · Damma (ou) : ا à ش · Damma : ص à ي | à fixer par le livre | 2.1 |  | |
| 5 | Leçon 4 | Les trois voyelles brèves mélangées · Syllabes et mots de deux lettres | à fixer par le livre | 2.1, 2.5 |  | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 2.1, 2.5 |  | Al-Ikhlâs ; coche prévue |
| 7 | Leçon 5 | Mots de trois lettres, voyelles brèves · L'alif d'allongement (â) : deux temps | à fixer par le livre | 2.1, 2.2, 2.5 | 3 imitée | |
| 8 | Leçon 6 | Le ya d'allongement (î) · Le waw d'allongement (oû) · Brève ou longue, côte à côte (مَلِكِ et مَٰلِكِ) ; la règle 3 reçoit son nom | à fixer par le livre | 2.2 | 3 nommée | |
| 9 | Consolidation | Consolidation : relire les leçons 5, 6 | Leçons de la semaine | 2.1, 2.2, 2.5 | 3 nommée | Prière, groupe 1 (« Allâhu akbar », « Âmîn », « Bismillâh ») ; gestes des ablutions et de la prière |
| 10 | Leçon 7 | Le soukoun : syllabes fermées · Le soukoun sur ق ط ب ج د : le rebond | à fixer par le livre | 2.1, 2.4 | 5 imitée | |
| 11 | Leçon 8 | La qalqala ; la règle 5 reçoit son nom · Le tanwin « an » | à fixer par le livre | 2.1, 2.4 | 5 nommée | |
| 12 | Consolidation | Consolidation : relire les leçons 7, 8 | Leçons de la semaine | 2.1, 2.4 | 5 nommée | Prière, groupe 2 (inclinaison, redressement, prosternation, assise, salut) |
| 13 | Leçon 9 | Le tanwin « in » et « oun » · Le tanwin dans des mots · La chadda : la lettre doublée | à fixer par le livre | 2.1, 2.3, 2.5 | 4 imitée | |
| 14 | Leçon 10 | La chadda avec les voyelles longues · Le noun et le mim doublés : la nasalisation de deux temps | à fixer par le livre | 2.2, 2.3 | 3, 4 imitées | |
| 15 | Consolidation | Consolidation : relire les leçons 9, 10 | Leçons de la semaine | 2.1, 2.2, 2.3, 2.5 | 3, 4 imitées | Prière, groupe 3 (protection et basmala, attestation après les ablutions, ouverture) |
| 16 | Leçon 11 | La chadda et la nasalisation ; la règle 4 reçoit son nom · Mots longs (plusieurs syllabes) | à fixer par le livre | 2.3, 2.5 | 3, 5 ; 4 nommée | |
| 17 | Leçon 12 | Mots longs mélangeant toutes les règles · Lignes de mots, sans épeler · Révision : une ligne de chaque leçon de l'étape | à fixer par le livre | 2.1 à 2.5 | 3, 4, 5 | |
| 18 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 2.1 à 2.5 | 1 à 5 | Prière, groupe 4 (le tachahhoud) |

### Étape 3 · Lire dans le Coran : 9 séances (6 leçons, 3 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | L'article ال : lam lu, ou lam muet devant la lettre doublée · La hamza de liaison (ٱ), qui ne se lit pas dans la suite | à fixer par le livre | 3.1 | 4 | |
| 2 | Leçon 2 | Les petites lettres du Mushaf (alif suscrit, petits waw et ya) · Les signes du Mushaf : fin de verset, soukoun, signe d'allongement · S'arrêter en fin de verset : soukoun, « an » lu « â », ة lu « h » | à fixer par le livre | 3.1, 3.2, 3.3 | 3 ; 6 imitée | |
| 3 | Consolidation | Consolidation : relire les leçons 1, 2 | Leçons de la semaine | 3.1, 3.2, 3.3 | 4 ; 3, 6 imitées | Prière, groupe 5 (la prière sur le Prophète ﷺ) ; prière complète |
| 4 | Leçon 3 | L'arrêt en fin de verset ; la règle 6 reçoit son nom · Le lam du nom d'Allah, épais ou fin · Le lam du nom d'Allah ; la règle 7 reçoit son nom | à fixer par le livre | 3.3, 3.4 | 6, 7 nommées | |
| 5 | Leçon 4 | Dernières pages du livre : phrases · Dernières pages du livre : textes longs, sans épeler | à fixer par le livre | 3.1 | 1 à 7 | |
| 6 | Consolidation | Consolidation : relire les leçons 3, 4 | Leçons de la semaine | 3.1, 3.3, 3.4 | 1 à 7 ; 6, 7 nommées | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 7 | Leçon 5 | Mushaf : lecture d'Ad-Duhâ et d'Ash-Sharh · Mushaf : lecture d'At-Tîn et d'Al-'Alaq · Mushaf : lecture d'Al-Qadr et d'Al-Bayyina | Mushaf : sourates 93 et 94 ; Mushaf : sourates 95 et 96 ; Mushaf : sourates 97 et 98 | 3.2 | 1 à 7 | |
| 8 | Leçon 6 | Mushaf : lecture d'Al-A'lâ · Mushaf : lecture d'Al-Ghâshiya · Mushaf : une page tirée au hasard dans le juz 30, déjà lue ou non | Mushaf : sourate 87 ; Mushaf : sourate 88 ; Mushaf : juz 30 | 3.2, 3.3, 3.4 | 1 à 7 | |
| 9 | Consolidation | Révision générale de l'étape et petit bilan | Toute l'étape | 3.1 à 3.4 | 1 à 7 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |

### Étape 4 · Les sourates courtes : 9 séances (6 leçons, 3 consolidations)

| Séance | Type | Contenu | Plage (page, ligne de, ligne à) | Objectifs | Règles | Matière secondaire (travaillée surtout en consolidation) |
|---|---|---|---|---|---|---|
| 1 | Leçon 1 | Al-Masad : mémoriser · An-Nasr : mémoriser | Mushaf : sourate 111, versets 1 à 5 ; Mushaf : sourate 110, versets 1 à 3 | 4.1, 4.3, 4.4, 4.5 | 8, 9 imitées | |
| 2 | Leçon 2 | Al-Kâfirûn : mémoriser · Al-Kawthar : mémoriser | Mushaf : sourate 109, versets 1 à 6 ; Mushaf : sourate 108, versets 1 à 3 | 4.1, 4.3, 4.4, 4.5 | 8, 9 nommées | |
| 3 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 4 | Leçon 3 | Al-Mâ'ûn : mémoriser · Quraysh : mémoriser · Al-Fîl : mémoriser | Mushaf : sourate 107, versets 1 à 7 ; Mushaf : sourate 106, versets 1 à 4 ; Mushaf : sourate 105, versets 1 à 5 | 4.1, 4.3, 4.4, 4.5 | 9 ; 8 nommée | |
| 5 | Leçon 4 | Al-Humaza : mémoriser (dont le seul « changé en mim » des 17 sourates) · Al-'Asr : mémoriser | Mushaf : sourate 104, versets 1 à 9 ; Mushaf : sourate 103, versets 1 à 3 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 6 | Consolidation | Consolidation : réciter les sourates de la semaine ; coche prévue ; révision des sourates déjà cochées | Sourates de la semaine | 4.1, 4.2, 4.3 | 8, 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
| 7 | Leçon 5 | At-Takâthur : mémoriser · Al-Qâri'a : mémoriser | Mushaf : sourate 102, versets 1 à 8 ; Mushaf : sourate 101, versets 1 à 11 | 4.1, 4.3, 4.4, 4.5 | 8, 9 | |
| 8 | Leçon 6 | Al-'Âdiyât : mémoriser · Al-'Âdiyât : mémoriser (suite) · Az-Zalzalah : mémoriser | Mushaf : sourate 100, versets 1 à 6 ; Mushaf : sourate 100, versets 7 à 11 ; Mushaf : sourate 99, versets 1 à 8 | 4.1, 4.3, 4.4 | 8 | |
| 9 | Consolidation | Révision générale des 17 sourates ; prêt pour l'examen de fin des bases | Les 17 sourates | 4.1 à 4.5 | 1 à 9 | Révision : les sourates et les paroles déjà apprises ; invocations et adab (contenus attendus) |
