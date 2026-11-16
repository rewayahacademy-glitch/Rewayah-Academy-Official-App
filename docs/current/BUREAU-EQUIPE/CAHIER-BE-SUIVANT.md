# Cahier BE-SUIVANT : passer d'un dossier à l'autre sans revenir à la liste (lot BE-1b)

Demande d'origine du directeur (15/11/2026) : « Après confirmation, je ne peux pas enchaîner,
je dois revenir sur la liste et la plupart du temps, là où j'étais, je me perds. » Et le
16/11 : « Il doit être facile de passer d'un dossier à l'autre. »

Le serveur sait déjà le faire : `voisins_candidature(reference, filtre, tri)` (PR 505, en
production) rend précédent, suivant, rang et total **dans le même filtre et le même tri que
la liste**. Le port Dart existe (`lib/core/candidature/port_candidatures_direction.dart`,
`voisins`).

## Zone

`lib/features/admin_candidature` seulement, ses tests, clés i18n `recrutement.suivant`. La
liste (`admin_candidatures`) est à l'agent BE-LISTE : n'y touche pas. Le filtre et le tri de
la liste arrivent au dossier par les paramètres de l'adresse déjà posés par la PR 506 ; si
le dossier ne les reçoit pas, ajoute-les à l'ouverture du dossier côté routeur (par ajout
seulement) et dis-le.

## À faire

1. Dans l'étage 1 du dossier, à côté du nom : « 3 sur 176 », et deux flèches « Précédent » et
   « Suivant ». Sans filtre connu (dossier ouvert depuis un message), rien ne s'affiche.
2. Après une décision (accepter, demander une précision, refuser, valider la pièce), une
   phrase courte confirme le geste avec « Annuler » quelques secondes (DECISION-FLUIDITE),
   puis **le dossier suivant s'ouvre seul**. Un réglage « Passer au suivant après une
   décision », activé par défaut, mémorisé sur l'appareil.
3. Sur ordinateur : touches ← et → pour précédent et suivant ; jamais quand le curseur est
   dans un champ de texte.
4. Le dossier suivant remplace le dossier courant dans la pile (`replace`) : « retour »
   ramène toujours à la liste, à la place du dernier dossier vu.
5. Fin de file : « C'était le dernier dossier de cette file » et un bouton vers la liste.
6. Tests : voisins au début, au milieu, à la fin ; décision puis passage au suivant ;
   « Annuler » ; réglage désactivé ; touches ; dossier ouvert sans filtre. Captures 360 et 1366,
   français et arabe (en arabe les flèches s'inversent).

Phrase à rendre vraie : « Je traite les 176 dossiers en examen à la suite, sans revenir une
seule fois à la liste. »
