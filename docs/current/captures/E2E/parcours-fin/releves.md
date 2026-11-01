# Parcours « fin de séance » : relevés

Demande du directeur, relayée par le garde-cap le 01/11 à 02:31 UTC. Script : `tool/e2e/parcours_fin.mjs <étiquette>`.
Séance observée : « E2E Classe adultes 10312330 », prévue de 01:00 à 02:30 UTC, avec un élève adulte.
Les défauts relèvent des lignes du pilote, publiées au registre, et je n'ouvre aucune ligne en double. Les renvois : FN-023 (aucun temps restant en salle,
non vu ici, voir la limite) ; FN-024 et FN-025 (rien ne dit que la séance est finie : refus à fin + 15 min avec le motif générique) ; FN-026 (le texte dit
« dix minutes avant ») ; FN-027 (carte de classe : plus rien sur la séance du jour, ni « terminée ») ; FN-028 (aucune notification de fin).
Le nouveau relevé : à fin + 15 min, « Aujourd'hui » propose encore « Rejoindre la salle » alors que la salle refuse l'entrée. C'est FN-006 vu par l'autre bout.

| Moment | Rôle | Observé | Captures |
|---|---|---|---|
| fin + 2 min (02:32 UTC), séance `in_progress` | Élève adulte | Sa carte d'Accueil montre déjà la séance du dimanche 8 novembre (« Cours dans 166 h 27 »). Plus de « Rejoindre », et rien ne dit que la séance du jour est finie ni qu'elle continue. La seule notification est « Vous êtes inscrit dans une classe. » ; aucune notification de fin. | [fin+3](fin+3/) |
| fin + 2 min | Enseignant | « Aujourd'hui » : « Séance en direct · Temps prévu écoulé » et « Rejoindre la salle de la Classe E2E Classe adultes 10312330 ». Le bouton ouvre `/salle` : « Votre élève n'est pas encore arrivé. Restez sur cet écran. » Ni temps restant, ni temps dépassé, ni écran de fin. L'élève y est marqué « Connexion interrompue ». | [fin+3](fin+3/) |
| fin + 15 min (02:45 UTC), séance toujours `in_progress` | Élève adulte | Comme à fin + 2 min : sa carte montre la séance du 8 novembre, pas de « Rejoindre », pas de notification de fin. | [fin+15](fin+15/) |
| fin + 15 min | Enseignant | « Aujourd'hui » propose toujours « Rejoindre la salle de la Classe E2E Classe adultes 10312330 » sous « Séance en direct · Temps prévu écoulé ». Le bouton ouvre la salle, qui refuse l'entrée : « Ce cours ne vous est pas ouvert en ce moment. La salle s'ouvre dix minutes avant l'heure du cours, et se ferme un quart d'heure après sa fin. » avec « Revenir à mon accueil ». Le motif est clair, mais l'Accueil continue de proposer une salle fermée. | [fin+15](fin+15/) |
| après la clôture automatique (03:15 UTC, séance `ended` ; la pile était arrêtée de ~02:55 à 03:10) | Élève adulte | La carte montre la séance du 8/11 ; « Dernières séances » apparaît sur l'Accueil. Aucune notification de fin. | [close](close/) |
| après la clôture | Enseignant | « Aujourd'hui » montre « Dernière séance » et « Obligatoire : le cahier de transmission d'E2E Classe adultes… ». Plus de « Rejoindre ». Aucune notification de fin (les dernières : « Un élève rejoint une de vos classes. », « Une de vos classes est fermée. »). | [close](close/) |

Non joué, limite connue : le temps restant affiché en salle **avant** la fin. Ce relevé demande d'être en salle pendant les
dernières minutes d'une séance ; celle-ci était déjà finie quand la demande est arrivée. Prochaine séance utilisable :
une nouvelle classe créée avec `horaireProche`, ou la séance du 8 novembre.
