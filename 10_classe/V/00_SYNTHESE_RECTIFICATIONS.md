# Synthèse des rectifications - salle de classe (CLV-04 à CLV-10)

Date : 26/09/2026. Arbitrage des 10 relevés V01 à V10, revu une seconde fois pour séparer strictement les rôles.
Principe : la maquette prime. On corrige les erreurs et on ne redessine rien. Ce qui n'est pas cité ici reste tel quel.
Référence des rôles : `01_MATRICE_ROLES.md` (fait foi). Détail image par image, avec les boîtes : `02_RECTIFICATIONS_PAR_ROLE.json`.

## 0. Ce qui avait été confondu

Les rectifications précédentes appliquaient des règles communes à tous les écrans sans dire à quel rôle elles s'adressaient.
- **Côté élève**, on laissait des éléments de l'enseignant : la pagination active ‹ 1/12 › (elle change la page pour toute la Classe), les barres de signal réseau, la notice de visite affichée sans condition (un élève aurait vu la visite du parent d'un autre enfant). La guidée gardait en plus le sous-titre de Classe, la barre latérale, les réglages et le menu de compte.
- **Côté enseignant** (CLV-06, 07, 08, 10), on laissait un cadre d'élève ou de tuteur : le compte « Mariam », l'entrée « Foyer », la notice « Votre parent observe… » (web étroit), le dock d'élève avec « Agrandir » et sans « Réseau », le sous-titre qui lui montre son propre nom sans la durée restante, et le bandeau vert « La séance se poursuit. ».

Désormais, chaque écran part de la personne qui l'utilise :
- **ES** : élève standard, CLV-04, écran de Mariam ;
- **IG** : interface guidée, CLV-05, écran de Mariam enfant ;
- **EN** : enseignant, CLV-06, 07, 08 et 10, écran de Sayyida Amina.

## 1. Invariants par rôle

**I-1 Mention d'enregistrement (R1).** Elle n'est affichée que si le serveur confirme l'enregistrement. Style commun : pas de fond, pas de bordure ni d'icône caméra, un point rouge plein de 8 px (≈ #FD5056), puis un texte de 12-13 px en couleur secondaire.
- ES : « Cours enregistré, visite de contrôle possible. ». Sur desktop, ce texte suit « En ligne » sur la ligne « Classe An-Nour · Sayyida Amina ». Sur téléphone et web étroit, il forme une ligne seule sous le sous-titre.
- IG : même texte, directement sous « Ma séance », qui n'a pas de sous-titre. « Le cours est enregistré. » ne s'affiche que si Q5 = oui.
- EN : même texte, sur sa ligne d'état « Classe An-Nour · … ».
- CLV-10 : aucune mention.

**I-2 Notice de visite (R2).** Aucun bloc ocre, pour aucun rôle. Pendant une visite, le texte de la mention se rétracte au point rouge et la notice prend sa place, dans la même taille et sans fond.

| Rôle | Qui la voit | Texte | Point rouge |
|---|---|---|---|
| ES | seulement l'élève dont le parent observe | « Votre parent observe la séance. » | clignote doucement (100 % → 40 %, ≈ 2 s) |
| IG | seulement l'enfant concerné | « Ton parent observe la séance. » + icône œil | fixe, sans clignotement (S l.781 : jamais anxiogène) |
| EN | toujours, pendant la visite | « Tuteur de Mariam observe. » (S l.855) ; « Le tuteur de Mariam observe la séance. » seulement si Q4 = oui | clignote |

Jamais « Tuteur de… » chez l'élève ou en guidée. Jamais « Votre parent… » ni « Ton parent… » chez l'enseignant. Aucun rôle ne voit un contrôleur ou un admin incognito.

**I-3 Vignette vidéo (R3, R4).**
- ES : vignette de l'enseignante en surimpression dans le coin supérieur droit du support, retrait de 12 px, ratio ≈ 1,1:1. Taille ≈ 136×124 px sur téléphone et web étroit, ≈ 208×190 px sur desktop. Étiquette du nom, **sans barres de signal** : le texte « Réseau faible. L'audio est prioritaire. » s'affiche seulement si le réseau faiblit. Pas de vidéo d'autres élèves (Q7).
- IG : grande vignette, jamais sur le texte. Environ 160×150 px sur téléphone et 180×164 px en web étroit ; sur desktop, vidéo latérale d'environ 300×275 px à côté du support (S l.730, 737 ; Q8). Sans barres de signal : « Le réseau est faible. » seulement si besoin.
- EN : sa propre vignette, seulement si sa caméra est active, mêmes tailles que l'élève, **avec** l'indicateur de signal.

**I-4 Boutons et dock (R5).** Tous les boutons d'appel sont des cercles de même diamètre.
- ES : Micro, Caméra (si autorisée), Agrandir, Quitter.
- IG : Parler, Caméra (si autorisée, sinon aucun bouton), Agrandir, Quitter.
- EN : Micro, Caméra, Réseau, Quitter. Pas de bouton Agrandir, ni dans le dock ni à côté du zoom.
- Réservés à l'enseignant, jamais sur CLV-04 ni CLV-05 : « Élèves x/y », « Supports », les tuiles Pointeur, Marquer, Masquer et Annoter (qui restent telles quelles), Réseau, les panneaux CLV-07 et CLV-08.

**I-5 Barre flottante et pagination (R6).** Pour tous les rôles sur desktop : 16 à 24 px entre le bas du support et la barre.
- EN : pagination active ‹ 1/12 › alignée sous le support, jamais sous un panneau, et zoom local.
- ES : aucune flèche qui change la page (S l.1366). Au plus un indicateur « 1 / 12 » en lecture seule. Le zoom local dépend de Q6.
- IG : ni pagination, ni indicateur, ni zoom.

**I-6 Données cohérentes (relevé).** Le compteur « Élèves x/y », la liste et le récapitulatif de fin viennent d'une même source. On écrit « connectés », jamais « présents » ni « absents » avant la consolidation par le serveur (S l.1148). « Pas encore connecté » est jaune partout. Les dates sont en septembre 2026. Ces données ne s'affichent qu'à l'enseignant.

**I-7 Téléphone (R8).** Aucune pagination à boutons sur mobile, quel que soit le rôle.

**I-8 Web étroit.**
- ES : en-tête de CLV-04 web.
- IG : en-tête de CLV-05 web, sans sous-titre.
- EN, sur CLV-06, 07 et 08 : en-tête de CLV-06 web, dock Micro, Caméra, Réseau, Quitter, notice « Tuteur de Mariam observe. ». Si un compte est affiché, c'est « SA ».
- Les panneaux Élèves et Supports (EN seulement) s'ouvrent en volet par-dessus le support, comme sur mobile.
- Aucune barre d'application empilée au-dessus, pour aucun rôle.

**I-9 Cadre par rôle.**

| | ES | IG | EN |
|---|---|---|---|
| Titre | « Séance en direct » | « Ma séance » | « Séance en direct » |
| Ligne d'état | « Classe An-Nour · Sayyida Amina » | aucun sous-titre : « En ligne » et la mention seulement | « Classe An-Nour · 32 min restantes », puis « Classe An-Nour · La séance se poursuit. » après l'heure de fin (état des maquettes) ; jamais son propre nom |
| « La séance se poursuit. » | texte simple si prolongée | non | texte simple, jamais de bandeau vert (DV D4) |
| Compte | « Mariam » (le sien) | avatar et prénom de Mariam, sans menu, sans thème, cloche ni réglages | « Sayyida Amina » (SA) |
| Barre latérale | masquée en salle ; hors salle : Accueil, Classes, Progression, Compte | aucune | masquée en salle ; hors salle : Journée, Classes, Ressources, Profil |

« Foyer » (destination du tuteur) n'apparaît sur aucun de ces écrans.

**I-10 Ce qu'un rôle ne voit jamais.**
- ES et IG : compteur ou liste d'élèves, fiches, notes, boutons Élèves, Supports et Réseau, outils d'enseignement, pagination active, durée restante, récapitulatif de fin, cahier, « Tuteur de… », visite du parent d'un autre enfant, « Foyer », compte d'une autre personne. La guidée ne voit pas non plus le zoom, l'indicateur de page, le signal réseau, les réglages ni le sous-titre de Classe.
- EN : « Votre parent observe… », le bouton Agrandir de l'élève, le compte ou la navigation d'un élève ou d'un tuteur (« Mariam », « Foyer », Accueil, Historique, Bibliothèque), un contrôleur incognito, les coordonnées des familles.

## 2. Écarts de rôle corrigés, par image

- **CLV-04 desktop (ES)** : « Foyer » et la barre latérale retirés. Pagination active ramenée à « 1 / 12 » en lecture seule. Barres de signal retirées. Zoom soumis à Q6. Le compte « Mariam » est gardé, car c'est celui de l'élève.
- **CLV-05 desktop (IG)** : barre latérale, « Foyer », thème, cloche, réglages et menu de compte retirés. Sous-titre retiré. Barres de signal retirées. Vidéo latérale à la place de la colonne pleine (Q8).
- **CLV-06, 07, 08 desktop (EN)** : compte Sayyida Amina. Barre latérale enseignant ou masquée. Bandeau vert remplacé par du texte. Ligne d'état « Classe An-Nour · … » sans son nom. Bouton plein écran « Agrandir » retiré. Notice « Tuteur de Mariam observe. ».
- **CLV-10 desktop (EN)** : compte Sayyida Amina, navigation enseignant, sous-titre « Classe An-Nour ». « Connectés » à la place de « présents ».
- **Mobile CLV-04-05-06** : barres de signal retirées sur CLV-04 et CLV-05. Sous-titre de la guidée retiré. Grande vignette guidée qui ne coupe plus le titre. CLV-06 : ligne d'état enseignant, bandeau vert retiré.
- **Mobile CLV-07-08-10 (EN)** : ligne d'état enseignant sur CLV-07 et CLV-08. Le cadre caché sous le volet reste celui de CLV-06 mobile. « Connectés » sur CLV-10.
- **Web étroit CLV-04-05-06** : mêmes corrections qu'en mobile, et la condition « seulement l'élève concerné » pour la notice de CLV-04.
- **Web étroit CLV-07-08-10 (EN)** : notice « Votre parent… » remplacée par « Tuteur de Mariam observe. ». Dock : Agrandir remplacé par Réseau. Ligne d'état enseignant. Barre d'application retirée, avec sa navigation « Accueil · Mes classes » et l'avatar « AA ».

Remarque sur la matrice §7.4 : sur mobile, le volet CLV-07 masque tout le cadre et aucun élément d'élève n'y est visible. L'inversion (cadre d'élève sous un panneau enseignant) ne concerne donc que le web étroit.

## 3. Rectifications écartées (redessin ou goût)

- V01 « désalignement vidéo/bloc parent » : sans objet une fois R2 et R3 appliquées.
- V03 R7 « coin supérieur droit surchargé » : renvoyé à Q3. En guidée, le coin est allégé d'office (règle de rôle).
- V09 R5 « tuiles d'outils carrées contre cercles d'appel » : cela redessinerait un élément gardé (I-4).
- V07 « Eleves sans accent » : c'est faux, l'image affiche bien « Élèves 3/4 ».
- V02 « garder le code couleur par fonction » contre V07/V09 « supprimer vert/violet » : renvoyé à Q1.
- Audit « volet mobile CLV-07/08 qui masque le dock » : écarté. Ce n'est pas une fuite de rôle, et le volet mobile est la référence de I-8. On précise seulement que le cadre caché dessous est celui de l'enseignant.

## 4. Coordonnées vérifiées

- CLV-04 desktop : vidéo 1128,248,403,297 ; bloc parent 1131,560,399,56 ; « Foyer » 52,256,220,46 ; pagination 298,862,203,58 ; signal 1466,498,40,28.
- Chevauchement de la barre flottante sur desktop : CLV-06, support jusqu'à y≈832 et barre à partir de y=820 ; CLV-04, support ≈845 et barre ≈831 ; CLV-08, support ≈835 et barre ≈825 ; CLV-07, contact à 0-3 px.
- CLV-06 desktop : la vidéo seule mesure 1140,274,366,262. Le plein écran « Agrandir » est à 1226,858,46,44.
- Nouvelles boîtes de signal ES et IG, vérifiées au pixel : mobile CLV-04 422,378,24,20 ; mobile CLV-05 894,353,24,20 ; web étroit CLV-04 429,529,22,22 ; web étroit CLV-05 911,537,22,22.
- Web étroit CLV-07/08 : dock « Agrandir » à 388,838,46,64 et 884,838,54,64 ; notices « Votre parent… » à 275,782,218,36 et 769,782,225,36.
- Fautes de frappe : mobile CLV-04 « enegistré », CLV-07 « erregistré », CLV-08 « enegistré ».

## 5. Web : ce que le directeur a aimé (planche « Enseignant · Desktop navigateur · Clair · Bibliothèque ouverte depuis la salle »)

Source : `scratchpad/cl1/sec-web.html`, lignes 412-470. C'est une planche **enseignant** :
1. **La sobriété.** Fond clair, beaucoup d'air, un seul titre fort. Chaque ligne porte une information et une action discrète (« Présenter »).
2. **Des coins supérieurs vides.** Le compte de l'enseignante est en bas d'une barre latérale de 4 destinations enseignant (Journée, Classes, Ressources, Profil).
3. **Un seul rappel de séance.** Une ligne fine pour l'enseignant : « Séance en direct · Classe An-Nour », « 3 élèves connectés sur 4 · Reste 24 min », « Revenir à la séance ». Le compteur et la durée restante sont des données d'enseignant, à ne pas reprendre côté élève.
4. **Le contenu occupe toute la largeur.**

Conséquences (sans redessiner) : en web étroit, les panneaux enseignant CLV-07/08 s'ouvrent en volet par-dessus le support, dans le cadre enseignant de CLV-06 web. CLV-10 web reprend l'en-tête de CLV-10 desktop rectifié.

## 6. Questions fermées au directeur (chacune précise son rôle)

1. **Interface guidée (CLV-05) uniquement** : garder les disques pleins vert (Parler) et violet (Caméra), ramenés à la même forme et au même diamètre (oui), ou revenir au style sombre commun (non) ?
2. **Enseignant, desktop (CLV-06, 07, 08) uniquement** : une fois la vidéo en vignette, garder la carte « Outils d'enseignement » dans une colonne droite d'environ 340 px (oui), ou la passer en rangée sous le support (non) ?
3. **Élève standard (CLV-04) et enseignant (CLV-06 à 08, 10), desktop** : retirer le compte du coin supérieur droit de la salle et le ranger en bas de la barre latérale hors salle (oui / non) ? Chacun ne voit que son propre compte : Mariam pour l'élève, Sayyida Amina pour l'enseignante. La guidée n'est pas concernée.
4. **Enseignant uniquement** : remplacer « Tuteur de Mariam observe. » (texte de la spec) par « Le tuteur de Mariam observe la séance. » (oui / non) ? Aucun élève ne voit jamais cette phrase.
5. **Interface guidée uniquement** : afficher « Le cours est enregistré. » à la place de « Cours enregistré, visite de contrôle possible. », qui reste alors dans le libellé d'accessibilité (oui / non) ?
6. **Élève standard uniquement** : garder le zoom local (−, 100 %, +), sans effet pour les autres (oui / non) ? L'enseignant le garde, la guidée ne l'a jamais.
7. **Élève standard uniquement** : ne jamais afficher la vidéo des autres élèves (oui / non) ? La guidée ne les voit jamais, l'enseignant les voit quand rien n'est partagé.
8. **Interface guidée desktop uniquement** : grande vidéo de l'enseignante à côté du support, jamais par-dessus (oui), ou vignette superposée comme l'élève standard (non) ?
