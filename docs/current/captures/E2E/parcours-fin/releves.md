# Parcours « fin de séance » : relevés

Demande du directeur, relayée par le garde-cap le 01/11 à 02:31 UTC. Script : `tool/e2e/parcours_fin.mjs <étiquette>`.
Séance observée : « E2E Classe adultes 10312330 », prévue de 01:00 à 02:30 UTC, avec un élève adulte.
Les défauts relèvent des lignes FN-023 à FN-028, que le pilote ouvre au registre. Je n'ouvre aucune ligne en double ;
les renvois seront ajoutés quand ces lignes seront publiées.

| Moment | Rôle | Observé | Captures |
|---|---|---|---|
| fin + 2 min (02:32 UTC), séance `in_progress` | Élève adulte | Sa carte d'Accueil montre déjà la séance du dimanche 8 novembre (« Cours dans 166 h 27 »). Plus de « Rejoindre », et rien ne dit que la séance du jour est finie ni qu'elle continue. La seule notification est « Vous êtes inscrit dans une classe. » ; aucune notification de fin. | [fin+3](fin+3/) |
| fin + 2 min | Enseignant | « Aujourd'hui » : « Séance en direct · Temps prévu écoulé » et « Rejoindre la salle de la Classe E2E Classe adultes 10312330 ». Le bouton ouvre `/salle` : « Votre élève n'est pas encore arrivé. Restez sur cet écran. » Ni temps restant, ni temps dépassé, ni écran de fin. L'élève y est marqué « Connexion interrompue ». | [fin+3](fin+3/) |
| fin + 15 min (02:45 UTC) | les deux | à relever (script lancé) | fin+15/ |
| après la clôture automatique (fin + 30 min) | les deux | à relever | close/ |

Non joué, limite connue : le temps restant affiché en salle **avant** la fin. Ce relevé demande d'être en salle pendant les
dernières minutes d'une séance ; celle-ci était déjà finie quand la demande est arrivée. Prochaine séance utilisable :
une nouvelle classe créée avec `horaireProche`, ou la séance du 8 novembre.
