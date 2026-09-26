# CL-4 : l'entrée en classe, rapport de recette (CL-4.7)

26/09/2026. Branche `ui/classe-v1`, commit `eb97496`. Démonstration : `/demo/classe`.

## Ce qui a été construit

L'entrée en classe tient en quatre écrans, tous visibles dans la démonstration.

1. **L'Espace Classe de l'élève.** On y voit sa classe, son enseignant, l'heure de la séance dans son fuseau et, au même endroit, soit une phrase d'état (« Cours dans… », « Séance annulée »…), soit le bouton « Rejoindre » quand la salle est ouverte. Dessous : « Avant le prochain cours » (trois actions au plus), la bibliothèque et la progression.
2. **L'Espace Classe de l'enseignant.** Même carte de séance, avec « Préparer l'entrée », la liste des élèves (prénom, niveau, page de reprise, sans photo ni donnée de famille) et le support prévu.
3. **La préparation de l'enseignant.** Il vérifie son micro, sa caméra et sa connexion avant d'entrer, avec le rappel de la classe, du support et des élèves attendus.
4. **La préparation de l'élève.** Presque silencieuse : une seule ligne quand tout va bien, et une aide claire si le micro est bloqué ou la connexion absente.

Corrections de cette étape :

- **L'enseignant de démonstration est désormais un homme**, « Sayyid Ibrahim ». La femme des maquettes reste disponible en variante : ajouter `&titre=sayyida` à l'adresse de la démonstration (« Sayyida Amina »). Les textes français du lot ont été relus : aucun n'est accordé au féminin en dur (« l'enseignant », « le professeur », « prêt » sont employés ; le titre Sayyid ou Sayyida vient toujours d'un choix, jamais d'un texte figé).
- **Micro bloqué, côté élève, sur téléphone** : « Autoriser le micro » et « Continuer sans micro » forment maintenant un seul groupe, tous deux sur toute la largeur, l'un sous l'autre, 8 points d'écart. Sur ordinateur, ils sont côte à côte, le bouton principal à droite (à gauche en arabe).
- **Le focus clavier ne se perd plus** : si le bouton « Rejoindre » qu'on avait sélectionné au clavier disparaît (la séance est annulée, par exemple), le focus revient au titre de la carte de séance. Un bouton qui apparaît ne vole jamais le focus.

## Ce qui a été vérifié

Nouveaux tests automatiques (`test/features/classe_recette/`, 28 vérifications, toutes réussies) :

- **Petit écran et gros texte** : les quatre écrans à 320 points de large, texte agrandi à 200 % : rien ne déborde.
- **Clavier** : la touche Tab parcourt chaque écran dans l'ordre de lecture ; l'élément sélectionné reste visible et n'est jamais caché par le bandeau « Démonstration ».
- **Textes plus longs et arabe** : les quatre écrans en sens de droite à gauche, avec un texte 40 % plus large : rien ne déborde, et les flèches (retour…) s'inversent.
- **Clair et sombre** : les quatre écrans s'affichent dans les deux thèmes.
- **Lecteur d'écran** : la phrase d'état n'est pas annoncée comme un bouton ; le bouton est lu « Rejoindre la séance de Classe An-Nour » ; chaque changement d'état est annoncé une seule fois (le compte à rebours n'est pas répété).
- **Focus** et **groupe de boutons du micro bloqué** : vérifiés par mesure.

Vérifications d'ensemble : `flutter analyze` sans aucun problème ; 2 658 tests réussis, 0 échec (781 sautés, ce sont les captures, qui ne tournent qu'à la demande).

Captures : `10_classe/captures/CL-4.7/` (30 images) : les quatre écrans en 390, 768 et 1440, clair et sombre, avec Sayyid Ibrahim ; le micro bloqué en clair et sombre ; deux captures avec Sayyida Amina ; deux captures en arabe simulé (droite à gauche, textes allongés).

## Ce qui reste pour le branchement du serveur (BR-1)

Tout fonctionne aujourd'hui sur des données de démonstration. À brancher en une fois (détail : `10_classe/CL-4-BR.md`) :

- les heures qui font foi pour chaque séance (début, fin, ouverture et fermeture de la salle) et l'heure du serveur, pour que l'écran ne dépende jamais de l'horloge du téléphone ;
- l'annulation d'une séance, la présence déjà connectée, l'avis de changement d'heure préparé par le serveur ;
- pour l'enseignant : la liste des élèves avec leur page de reprise et leur dernier point, le support prévu, l'objectif ;
- la photo publique de l'enseignant (aujourd'hui ses initiales) ;
- dans les préparations : la vraie qualité de connexion, l'ouverture des réglages du téléphone, le choix du micro ou de la caméra, le vrai test caméra, et la vérification qu'un élève entré « sans micro » n'envoie aucun son.

## Écarts, à reprendre dans l'harmonisation HU-1

- **Pseudo-localisation** : l'outil de traduction du projet ne permet pas de remplacer les textes pendant un test. Les textes 40 % plus longs sont donc simulés en agrandissant le texte de 40 %, ce qui donne la même largeur. Un vrai jeu de textes allongés pourra être ajouté en HU-1.
- **Planche web** prévue au découpage : remplacée pour cette étape par les 30 captures PNG ; la planche pourra être composée à partir d'elles.
- **Clavier** : l'ordre est vérifié sur téléphone (390). Sur ordinateur, l'ordre en rangées de l'Espace Classe élève (revue UX n° 4) reste à contrôler dans la passe HU-1.
- **Focus revenu au titre** : vérifié sur la carte de séance ; les autres écrans de la Classe n'ont pas encore ce comportement.
- Rappels déjà notés : chrono discret de la salle (LIVE-CHRONO-01) et écarts de coque (entrées de navigation, pied de compte).
