# Parcours 2 : pièges (direction pressée, non technique)

Règle : si l'application laisse faire une erreur sans un mot clair et sans un moyen de revenir, le
parcours est rouge. Familles : (1) mauvais choix, (2) détour, (3) saisie libre, (4) arrêt en cours,
(5) lecture, (6) mauvais appareil. Script : `tool/e2e/pieges_2.mjs` (seconde enseignante, créneaux
du mercredi matin, pour ne pas gêner la chaîne des parcours).

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 2.1 | Nouvelle classe | 1 | « Créer la classe » sans choisir d'enseignant | oui | vert (jugé sur la capture 01 : le détecteur du script lisait la phrase d'introduction) : « Il manque l'enseignant : choisissez-le dans la liste. », aucune classe créée |
| 2.2 | Nouvelle classe | 3 | Nom de la classe vidé, puis « Créer la classe » | oui | vert (capture 02) : « Il manque le nom de la classe : écrivez-le dans le dernier champ. » |
| 2.3 | Nouvelle classe | 1 | Deux créneaux identiques (même jour, même heure) | oui | vert (capture 03) : « Deux créneaux tombent le même jour à la même heure : changez-en un. », aucune classe créée |
| 2.4 | Nouvelle classe | 2 | Double clic sur « Créer la classe » | oui | vert : 1 classe(s) creee(s) par un double clic |
| 2.5 | Nouvelle classe | 3 | Nom très long (120 caractères) et en arabe | oui | vert : nom de 120 caracteres en arabe : accepte |
| 2.6 | Nouvelle classe | 4 | Fermer la boîte (Échap) au milieu de la saisie, puis rouvrir : la saisie est-elle gardée ou perdue sans prévenir ? | oui | rouge : Échap en pleine saisie ferme la boîte sans un mot ; à la réouverture, tout est vide → UX-031 |
| 2.7 | Nouvelle classe | 1 | « Filles » choisi après l'enseignant (un homme) : la liste se met-elle à jour, l'écran le dit-il ? | oui | vert (capture 08) : l'enseignant homme reste coché mais sa carte dit « Classe de filles : seule une enseignante peut la prendre. » |
| 2.8 | Nouvelle classe | 6 | La direction au téléphone (390 px) : la boîte tient-elle, « Créer la classe » est-il atteignable ? | oui | vert : au telephone (390 px) : formulaire ouvert, « Créer la classe » atteignable |
| 2.9 | Nouvelle classe | 5 | Lecture des libellés (« Seuil maximal », « Public », « Créneau ») par un nouveau venu | oui | oui : « Heures lues dans le fuseau America/St_Johns, celui de l'enseignant. » : nom de fuseau brut → UX-030 ; « Seuil maximal » expliqué sous le titre (vert) |
