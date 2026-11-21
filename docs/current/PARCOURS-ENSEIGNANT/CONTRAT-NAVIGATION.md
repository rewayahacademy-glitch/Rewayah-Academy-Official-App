# Contrat de navigation et d'interaction (20/11/2026)

Ordre du directeur (20/11/2026) : « ce que tu oublies à chaque fois depuis 3 mois : les
interactions entre les pages, ou les enfants d'une page, d'un bouton. Quand je clique sur une
carte, il se passe quoi ? Comment tout se comporte avec la barre latérale ou la barre du bas ?
Quand le système sélectionne-t-il quelque chose sur la navigation ? Les gestes de retour, les
fils d'Ariane… Tout. »

Ce contrat vaut pour **tout écran, de tout rôle**. Un lot qui ajoute ou modifie un écran dit,
dans sa PR, quelle ligne de ce contrat il applique. Un écran qui n'y entre pas n'est pas fini.
Il s'applique sous `DECISION-DEFILEMENT`, `DECISION-LISTES` et `DECISION-MOUVEMENT`.

## 1. Quatre surfaces, pas une de plus

| Surface | Sert à | Adresse (URL) | Ordinateur | Téléphone |
| :--- | :--- | :--- | :--- | :--- |
| **Page** | Une destination où l'on travaille | Oui, toujours | Dans la zone de contenu | Plein écran |
| **Volet** | Regarder ou agir sur un objet sans quitter sa page | Un paramètre (`?volet=…`), pour qu'un lien ou un rechargement le rouvre | Panneau à droite, par-dessus le contenu, jamais par-dessus la barre latérale | Feuille du bas, 90 % de hauteur au plus, poignée toujours visible |
| **Fenêtre légère** | Un coup d'œil ou une réponse rapide (messages, notifications, menu « … », filtres courts) | Non | Ancrée à l'élément touché | Feuille basse à mi-hauteur |
| **Avis** | Dire qu'une chose est faite, proposer « Annuler » | Non | Flotte en haut, par-dessus | Flotte en haut, par-dessus |

Rien ne pousse la page : ni un avis, ni un bandeau, ni un volet.

## 2. Ce que fait chaque toucher

| On touche | Il se passe | Jamais |
| :--- | :--- | :--- |
| Une case ou une tuile qui porte un nombre (file, compteur) | La **liste de ces personnes, déjà filtrée**, s'ouvre en page (empilée) ; le filtre est dans l'adresse | Une liste non filtrée ; un écran qui ne correspond pas au nombre |
| Une ligne, une personne, un visage, une carte de la pile | Le **volet d'aperçu** de cette personne (toujours le même composant) | Une page différente selon l'endroit d'où l'on vient |
| « Ouvrir le dossier » dans le volet | La **page du dossier** (empilée) ; le volet se ferme | Deux dossiers différents pour une même personne |
| Glisser une carte de la pile | La décision (deux issues, réversible) ; la carte suivante monte | Une décision lourde (accepter, refuser un candidat) sur un simple glissement |
| Le bouton principal d'une case | L'action, tout de suite, avec un avis et « Annuler » ; un volet seulement s'il faut saisir quelque chose | Une navigation vers une autre page pour une action simple |
| Une icône de l'en-tête (messages, notifications) | Une **fenêtre légère** ; « Tout voir » ouvre la page, qui sort de l'icône et y rentre | Une page entière pour un coup d'œil ; une icône qui disparaît quand le compteur est à zéro |
| Une notification | Le **volet de l'objet concerné** (la personne, la conversation, la pièce) | Une liste où il faut encore chercher |
| Un résultat de recherche | Le volet de la personne | Rien, ou une page de rubrique |
| Un lien dans un message ou un courriel | L'objet nommé, après connexion si besoin, sans perdre la destination | L'accueil |

## 3. La sélection dans la navigation (barre latérale, barre du bas)

- **Ce qui est sélectionné = la rubrique qui possède la page affichée**, lue dans l'adresse.
  Le dossier d'un candidat appartient à « Personnes » ; une conversation à « Messages » ; le
  reste à « Plus ». Peu importe d'où l'on est arrivé.
- Un volet, une fenêtre légère ou un avis **ne changent pas** la sélection.
- **Toucher une rubrique** : on va à la dernière page où l'on était dans cette rubrique, à la
  même position de défilement (chaque rubrique garde sa pile).
- **Toucher la rubrique déjà sélectionnée** : retour à sa racine, en haut de page.
- La barre du bas ne bouge pas au défilement. Elle se cache seulement : clavier ouvert, feuille
  ouverte, salle de cours. La barre latérale ne se cache jamais sur ordinateur.
- Une pastille de nombre sur une rubrique dit « quelque chose vous attend ici » ; elle roule
  quand le nombre change.

## 4. Le retour (flèche, glissement, touche du navigateur, Échap)

Un seul ordre, pour les quatre moyens de revenir. On ferme d'abord ce qui est le plus proche :

1. le clavier, une fenêtre légère ;
2. un volet ou une feuille ;
3. la page empilée : on revient à la page précédente, **à la même position, avec les mêmes
   filtres et la même sélection** ;
4. à la racine d'une rubrique : on revient à l'Accueil ;
5. à l'Accueil : au téléphone on quitte ; sur ordinateur il ne se passe rien.

- Ce qu'on vient de fermer ne se rouvre jamais par un geste de retour.
- Le glissement depuis le bord et la flèche font exactement la même chose.
- Une feuille se ferme en la tirant vers le bas ; un volet par Échap, la croix, ou un toucher
  à côté.
- Après une connexion, un rechargement ou un lien direct, la pile est reconstruite : le retour
  mène au parent logique (dossier, puis liste, puis accueil), jamais dans le vide.

## 5. Empiler ou remplacer

- **Empiler** (la page s'ajoute, le retour la retire) : tout ce qui descend vers un détail.
- **Remplacer** : seulement pour changer de rubrique, et pour les redirections de connexion.
- L'adresse dit toujours : la page, ses filtres, son tri, et le volet ouvert. Recharger la page
  rend le même écran.

## 6. Le fil d'Ariane

- Sur ordinateur et tablette, sur toute page plus profonde que la racine d'une rubrique :
  `Rubrique › Liste (avec le nom du filtre) › Personne`. Chaque maillon se touche et ramène à
  cette page **dans l'état où on l'a laissée**.
- Au téléphone : la flèche de retour et le titre, pas de fil.
- Le fil décrit le chemin logique, pas l'historique : il est le même quel que soit le chemin.

## 7. Après une action

- On reste où l'on est. La ligne traitée s'en va, la suivante prend sa place, les compteurs
  changent partout où ils sont affichés, un avis propose « Annuler ».
- Dans un dossier ouvert depuis une file : après la décision, le dossier suivant de la file
  arrive, avec « précédent » et « suivant ».
- Une action sensible (argent, compte, droits, suppression) attend la réponse du serveur, avec
  un état d'attente sur le bouton et un délai maximal ; les autres s'affichent tout de suite et
  reviennent en arrière si le serveur refuse.
- Un bouton ne reste jamais figé : après le délai, il dit « résultat inconnu » et propose de
  vérifier.

## 8. Les états d'une surface

Chargement (un squelette à la place du contenu, sans saut de page), contenu, vide (une phrase
qui dit quoi faire), erreur (une phrase vraie et « Réessayer »), hors connexion. Tirer vers le
bas actualise toute page qui défile, sans perdre la position.

## 9. Clavier (ordinateur)

Échap ferme la surface du dessus. Ctrl+K ouvre la recherche. Dans un dossier ouvert depuis une
file : flèches gauche et droite pour le précédent et le suivant.

## 10. Vérification d'un lot

Pour chaque écran touché, la PR répond à ces cinq questions : d'où y arrive-t-on, et que
sélectionne la navigation ? Que fait le retour, par les quatre moyens ? Que reste-t-il dans
l'adresse après un rechargement ? Que se passe-t-il après chaque action ? Comment se ferme
chaque surface secondaire ?
