# Lire d'abord : la charte pédagogique de Rewayah Academy

> **EN VIGUEUR par arbitrage de l'architecte pédagogique (12/11/2026), sur délégation du directeur. Le directeur peut corriger toute règle à tout moment ; une correction datée de sa part l'emporte.**

C'est la référence unique de la pédagogie de Rewayah Academy. Aucune question n'est posée au directeur : il a demandé le 12/11/2026 que l'architecte arbitre, et tout ce qui restait ouvert est arbitré (`ARBITRAGES.md`). Un audit indépendant a trouvé des erreurs le même jour ; leurs corrections, et les arbitrages précédents qu'elles annulent, sont dans `ARBITRAGES.md`, partie 8.

## La règle en cas d'écart

**En cas d'écart entre deux fichiers, la charte (`CHARTE-ECOLE.md`) et la table des réglages (`REGLAGES.md`) font foi.** Une valeur chiffrée n'existe qu'une fois, dans la table des réglages ; ailleurs, elle est citée à l'identique ou on y renvoie. Un écart trouvé est une erreur à corriger, jamais une seconde règle.

Au-dessus de ces fichiers : les décisions datées du directeur (compétences `programme-rewayah` et `mots-rewayah`, registre du 14/10). Une correction datée du directeur l'emporte toujours sur un arbitrage.

## L'ordre de lecture

| Ordre | Fichier | Son rôle |
|---|---|---|
| 1 | `LIRE-D-ABORD.md` | Cette page : l'ordre, le rôle de chaque fichier, le statut |
| 2 | `CHARTE-ECOLE.md` | La référence : promesse, rôles, programme, année, séance, mesure, suivi, système vivant, responsabilités, qui voit quoi, bibliothèque et lecteur, protection des mineurs, données |
| 3 | `REGLAGES.md` | La seule table des valeurs : chaque réglage, à quoi il sert, sa valeur, son statut (DÉCIDÉ avec date, ou ARBITRÉ), qui peut le changer ; y compris les valeurs du moteur |
| 4 | `SCENARIOS-ELEVES.md` | Chaque type d'élève et chaque situation, avec une seule réponse ; la stratégie pour rattraper seul. Le directeur a lu la version du 12/11/2026 (commit 531441aa5) et a dit : c'est bien. Les corrections faites depuis sont listées au registre |
| 5 | `MOTEUR-DE-SUIVI.md` | Ce que l'application fait seule, sans IA : les faits lus, les états, les 35 règles (quoi, comment, quand, à qui ; la règle 35 est le point de fin de séance), les garde-fous, ce que voit chacun, la partie pour les développeurs |
| 6 | `EVALUATIONS.md` | Comment on mesure : les quatre moments, la grille commune, chaque étape des bases, les neuf règles du tajwid des bases et leurs endroits dans les 17 sourates (4.1 bis), l'examen de fin des bases, l'après-bases (PROPOSÉ), les cas particuliers, la publication |
| 7 | `ARBITRAGES.md` | Le registre de tous les arbitrages, avec leur raison et leur origine, la clôture de chacune des 53 anciennes questions, les corrections après audit (partie 8) et les décisions et arbitrages du 13/11/2026 (partie 9) |
| 8 | `CONTENUS-ATTENDUS.md` | Ce que le directeur déposera ou relira (livre de lecture, enregistrements, relecture de la prière et des ablutions, invocations, illustrations, adab), ce que l'école fait en attendant, où les déposer ; le cahier des charges du livre de lecture (partie 2) |
| 9 | `PLAN-DE-CONSTRUCTION.md` | Les treize lots, dans l'ordre (dont POINT-DE-SEANCE, RETRAIT-CAHIER et CHEMIN, ajoutés le 13/11), pour passer de l'existant à la charte ; qui livre en tête (l'architecte ouvre la pull request et fusionne, CI verte exigée, après revue indépendante ; le directeur installe les migrations) |
| 10 | `ANGLES-MORTS.md` | Le registre des sujets que la charte ne couvre pas encore (19 fiches en trois groupes), tenu par l'architecte ; il se complète à chaque sujet nouveau |
| 11 | `STRATEGIE-FORMATION-DES-CLASSES.md` | La stratégie des classes vitrines (l'ancien « matching des classes ») : ce qui existe, ce qui a été perdu, les règles F1 à F16, les angles morts et les quatre lots |
| 12 | `CONTENU-PRIERE-ET-ABLUTIONS.md` | Les ablutions dans l'ordre et la prière pas à pas, chaque parole en arabe vocalisé, translittérée et traduite, selon ce qui est enseigné en Arabie saoudite ; l'ordre où l'élève les apprend. RÉDIGÉ, en service après la relecture du directeur |

## Les marques

- **DÉCIDÉ (date)** : décision datée du directeur ; elle ne change que par une décision plus récente.
- **ARBITRÉ** : décision de l'architecte pédagogique (12/11/2026), en vigueur, avec sa raison au registre ; le directeur peut la corriger à tout moment.
- **PROPOSÉ** : réservé au programme d'après les bases (lire tout le Coran, mémoriser le Coran, le tajwid d'après les bases), qui n'est pas mis en service tant que le directeur et ses associés détenteurs d'ijaza ne l'ont pas validé.
- **RÉDIGÉ** : un texte écrit par l'architecte sur ordre du directeur, qui entre en service après sa relecture (`CONTENU-PRIERE-ET-ABLUTIONS.md`, 13/11/2026). Ce qui y est marqué « à vérifier par le directeur » ou « à relire » n'est pas certain.

## Les décisions du directeur du 12/11/2026 qui encadrent tout

1. La classe n'attend jamais un élève absent : il rattrape seul, avec la voix enregistrée du directeur (lettres, paroles de la prière et invocations, sourates courtes).
2. Le système reconnaît seul chaque situation et sait quoi faire, comment, quand et à qui, automatiquement, sans IA ; les humains n'interviennent presque pas.
3. L'architecture est fixe ; les valeurs sont réglables par la direction.
4. L'interdiction de nouveaux écrans (Boucle 1) ne s'applique pas à ce projet.
5. Dans la page du programme, l'élève voit son niveau, les objectifs à atteindre pour chaque niveau, les dates importantes ; il ne voit jamais les valeurs d'une autre tranche d'âge ni rien d'un autre élève.
6. « Je ferai les migrations, pour le reste c'est à toi, y compris les fusions. »
7. L'espace de l'élève, « Apprendre », a trois onglets : la Bibliothèque (documents de l'académie en haut, autres en bas, grille ou liste, filtre par type ; le Coran est un document, pas la bibliothèque), le Programme, « Mon livret » (résultats, attestations, rapports) ; un lecteur performant pour texte, audio et vidéo.
8. Un hub et des raccourcis, jamais de doublons.
9. La vente n'est pas pour maintenant : on prépare seulement la place du second rayon.

## Les décisions du directeur du 13/11/2026

1. Les règles élémentaires du tajwid sont réparties pour que l'élève les maîtrise avant ou pendant les 17 sourates ; pas les règles avancées, pas trop de règles. L'architecte en a retenu neuf (`EVALUATIONS.md`, 4.1 bis).
2. Les livres seront rédigés par des agents après la validation du programme, découpés selon lui (`CONTENUS-ATTENDUS.md`, partie 2).
3. Les paroles de la prière et les ablutions sont publiques et connues ; pas d'école juridique pour des débutants ; la référence est ce qui est enseigné en Arabie saoudite (`CONTENU-PRIERE-ET-ABLUTIONS.md`).
4. « Le cahier me fatigue » : le cahier à remplir est remplacé par le point de fin de séance (charte, partie 5 ; arbitrage n° 96).
5. Un système de gamification pour que tout le monde comprenne le programme : le chemin (charte, partie 10 bis ; arbitrage n° 98).
