# Cause du « démarrage à 390 » (garde-cap, 06/11/2026)

Même robot (`tool/e2e/photos_comptes.mjs`), session ouverte à 390, pile locale :

| Arbre | mon_horloge | Envoi photo enfant | Photo dans Comptes (390) |
| :--- | ---: | :--- | :--- |
| `main` 5cbe8bec seul (`journal_arbre-main.txt`) | 5 869 appels | réussi | non, aucune URL signée |
| `main` + seul correctif de mon_horloge, 97332736 (`journal_arbre-horloge.txt`) | 1 appel | réussi | non, aucune URL signée |
| `claude/photos-a` fusionné avec PHOTOS-B (`../2026-11-06/journal.txt`) | 1 appel | réussi | oui |

Conclusion : la boucle de mon_horloge est un défaut réel (FUSEAUX, en production), mais
elle n'est pas la cause de l'absence de photo dans Comptes au téléphone. Cette cause est
que la carte de Comptes, au téléphone, ne posait aucun portrait sur `main` (le rendu avec
la photo n'existait qu'au bureau) ; PHOTOS-B la corrige. L'échec de l'envoi au téléphone
n'est reproduit dans aucun des trois arbres.
