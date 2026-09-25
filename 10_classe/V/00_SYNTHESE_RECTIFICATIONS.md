# Synthèse des rectifications - salle de classe (CLV-04 à CLV-10)

Date : 25/09/2026. Arbitrage des 10 relevés V01 à V10.
Principe : la maquette prime. On corrige les erreurs et on ne redessine rien. Ce qui n'est pas cité ici reste tel quel.

## 1. Invariants (une règle = la même rectification sur toutes les images)

**I-1 Mention légale (R1).** Il n'y a plus de bandeau : pas de fond, pas de bordure, pas d'icône caméra. Le texte est petit (12-13 px, couleur secondaire), précédé d'un point rouge plein de 8 px (même rouge que « Quitter », environ #FD5056). Texte unique : « Cours enregistré, visite de contrôle possible. »
- Sur desktop, il se place sur la ligne du sous-titre, juste après la pastille « En ligne » : « Classe An-Nour · Sayyida Amina  ● En ligne   ● Cours enregistré, visite de contrôle possible. »
- Sur téléphone et en web étroit, il occupe une ligne à lui seul, sous le sous-titre et alignée à gauche sur lui. Cette ligne remplace le bandeau et libère environ 30 px de hauteur.
- Il est présent sur **tous** les écrans de séance en cours, y compris l'interface guidée et la vue enseignant. Il est absent de CLV-10, puisque la séance est terminée.

**I-2 Visite en cours (R2).** Le bloc ocre séparé disparaît partout. Au même emplacement que I-1, le texte se rétracte et seul le point rouge reste ; il clignote doucement (opacité 100 % → 40 %, cycle d'environ 2 s). La notice temporaire apparaît à la place du texte, dans la même taille, sans fond. Tant que dure la visite, on peut garder une touche d'ocre sur le texte. Le gabarit est le même partout : « [Qui] observe la séance. »
- Élève standard : « Votre parent observe la séance. »
- Interface guidée : « Ton parent observe la séance. » (on garde le tutoiement de la maquette et on unifie le verbe)
- Enseignant : « Le tuteur de Mariam observe la séance. »

**I-3 Vignette vidéo (R3, R4).** La vidéo de l'enseignante se place dans le **coin supérieur droit** de la zone du support, en surimpression (z-index au-dessus), avec un retrait de 12 px. Elle ne réserve aucune colonne et n'impose aucune hauteur. Le cadrage et les proportions sont ceux de la vignette de CLV-07/08 mobile (≈ 1,1:1, jamais étirée). L'étiquette du nom et l'indicateur de signal sont conservés.
- Téléphone et web étroit : ≈ 136 × 124 px, comme dans CLV-07/08 mobile, qui est déjà conforme.
- Desktop : ≈ 208 × 190 px.
- Le support récupère toute la largeur libérée et domine l'écran.

**I-4 Boutons (R5).** Toutes les commandes de la barre d'appel ont la même forme : des cercles de même diamètre, en mode normal comme en mode guidé. La « Caméra » en forme de pilule ou d'ovale de CLV-05 web et mobile redevient un cercle. Les tuiles d'outils enseignant (Pointeur, Marquer, Masquer, Annoter) restent telles quelles, comme sur toutes les maquettes : c'est une barre d'outils, pas un second style de bouton d'appel.

**I-5 Marge de la barre flottante (R6).** Sur desktop, un espace de 16-24 px sépare le bas du support du haut de la barre Micro/Caméra/Quitter. La pagination « ‹ 1/12 › » s'aligne sous le support, jamais sous un panneau.

**I-6 Données cohérentes (relevé).**
- Le compteur « Élèves x/y », la liste du panneau et le récapitulatif de fin viennent de la même source.
- Le compte affiché en haut à droite de la vue enseignant est celui de Sayyida Amina, pas celui de Mariam.
- Un statut n'a qu'une couleur : « Pas encore connecté » est jaune partout.
- Les dates sont plausibles : la dernière séance se situe en septembre 2026.

**I-7 Téléphone (R8).** Aucune pagination par petits boutons n'apparaît sur les maquettes mobiles ; la règle est donc respectée. En implémentation, le support défile au pouce.

## 2. Rectifications écartées (redessin ou goût)

- V01 « désalignement vidéo/bloc parent » : sans objet une fois R2 et R3 appliquées.
- V03 R7 « coin supérieur droit surchargé » (thème, cloche, réglages, compte) : cet en-tête est identique sur tous les desktops, espacé et sans chevauchement, et V01, V02, V04 et V06 le gardent. Le coin s'allège déjà quand I-1 sort la mention de la rangée de pastilles. Voir la question Q3.
- V09 R5 « tuiles d'outils carrées contre cercles d'appel » : cela redessinerait un élément gardé sur desktop et sur mobile (I-4).
- V07 « Eleves sans accent » : c'est faux, l'image affiche bien « Élèves 3/4 ».
- V02 « garder le code couleur par fonction » contre V07/V09 « supprimer vert/violet » : cette contradiction est renvoyée à la question Q1. Seule la forme est corrigée d'office.

## 3. Coordonnées corrigées après vérification

- CLV-04 desktop : la vidéo mesure 1128,248,403,297 et le bloc parent 1131,560,399,56.
- CLV-06, CLV-04 et CLV-08 desktop : la barre flottante **chevauche** le bas du support d'environ 10 à 13 px ; ce n'est pas un simple contact. Mesures au pixel :
  - CLV-06 : le support est visible jusqu'à y≈832 et la barre commence à y=820 en x=717.
  - CLV-04 : le support va jusqu'à y≈845 et la barre commence à y≈831.
  - CLV-08 : le support va jusqu'à y≈835 et la barre commence à y≈825.
  - CLV-07 : contact à 0-3 px.
- CLV-06 desktop : la vidéo seule mesure 1140,274,366,262. La boîte du relevé englobait aussi les outils.
- Web étroit CLV-04-05-06 : toutes les boîtes ont été recalées. Par exemple, le bandeau CLV-04 mesure 27,277,435,43, la vidéo CLV-04 304,334,158,222, la vidéo CLV-05 787,289,158,282 et la vidéo CLV-06 1253,382,170,168.
- Mobile CLV-04 : la faute « enegistré » est aussi présente ; mobile CLV-07 affiche « erregistré » et CLV-08 « enegistré ».

## 4. Web : ce que le directeur a aimé (planche « Enseignant · Desktop navigateur · Clair · Bibliothèque ouverte depuis la salle »)

Source : `scratchpad/cl1/sec-web.html`, lignes 412-470. Ce qui plaît probablement dans cette planche :
1. **La sobriété.** Un fond clair, beaucoup d'air, un seul titre fort (« Bibliothèque de la Classe An-Nour »). Chaque ligne porte une seule information et une seule action discrète (« Présenter »). Les statuts sont de petites pastilles de texte.
2. **Des coins supérieurs vides.** Pas de thème, de cloche, de réglages ni d'avatar en haut à droite : le compte est en bas de la barre latérale, qui ne compte que 4 destinations (Journée, Classes, Ressources, Profil).
3. **Un seul rappel de séance.** Une ligne fine : point vert, « Séance en direct · Classe An-Nour », « 3 élèves connectés sur 4 · Reste 24 min », et un seul bouton « Revenir à la séance ». Il n'y a pas de pile de bandeaux.
4. **Le contenu occupe toute la largeur.** Rien ne le rogne : ni colonne vidéo, ni panneau latéral.

Conséquences pour les rectifications web (sans redessiner) :
- En web étroit, les panneaux Élèves et Supports de CLV-07/08 s'ouvrent en **volet par-dessus le support**, exactement comme les maquettes mobiles CLV-07/08 (volet avec poignée, support visible au-dessus). Aujourd'hui, ils écrasent le support à ~225 px.
- En web étroit, les écrans de salle CLV-07/08 reprennent l'en-tête de CLV-04/05/06 web (retour, titre, sous-titre, « En ligne »), sans la barre d'application empilée au-dessus. CLV-10 web reprend l'en-tête de CLV-10 desktop rectifié (« Séance terminée »), à la place de la barre de liens écrasée à ~9 px.

## 5. Questions fermées au directeur

1. Interface guidée : garde-t-on les disques pleins **vert (Parler) et violet (Caméra)**, ramenés à la même forme et au même diamètre que les autres, ou les remet-on au style sombre commun (R5 strict) ? oui = garder les couleurs, non = style commun
2. Desktop enseignant : une fois la vidéo en vignette, la carte « Outils d'enseignement » reste-t-elle seule dans une colonne droite étroite (≈ 340 px), telle quelle ? oui = colonne gardée, non = rangée sous le support comme sur mobile
3. Desktop : déplace-t-on le compte (avatar et nom) en bas de la barre latérale, comme dans la planche claire appréciée, pour vider le coin supérieur droit ? oui / non
4. Vue enseignant, notice de visite : « Le tuteur de Mariam observe la séance. » vous convient-il, plutôt que « Le parent de Mariam… » ? oui / non
