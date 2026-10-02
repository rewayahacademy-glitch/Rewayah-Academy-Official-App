# Décisions déléguées à l'orchestrateur (02/10/2026)

Le 02/10, le directeur a répondu aux points qu'il pouvait trancher sur la planche du Contrôleur. Pour le reste, il a écrit : « le reste tu te débrouilles pour le bien de l'académie et de ses élèves ».

Les choix ci-dessous sont donc **définitifs pour le travail en cours**. Le directeur peut les reprendre à tout moment, par une décision datée. Le critère est toujours le même : ce qui protège le mieux les élèves, puis ce qui coûte le moins de travail refait.

## Contrôleur (CT)

| Question | Choix | Raison |
|---|---|---|
| Les 137 textes du lexique (P1 à P137) | **Gardés**, avec deux corrections demandées par le directeur : « mission » devient « Classe à observer » ou « visite » ; « faits automatiques » devient « relevé automatique de la séance (heures, élèves présents, reconnexions) ». Commit `ui/controleur-v1` 91f31eb6. | Le directeur a relu la liste et n'a commenté que ces textes. |
| Le complément redemande-t-il nature, domaine et personne ? | **Non** : motif facultatif et texte seulement. | Minimisation : le rapport d'origine porte déjà ces informations, et un complément court est plus vite écrit. |
| Le complément en plein écran ? | **Non** : il s'ouvre dans l'Historique, avec la barre du bas. | Tâche courte. Le retour au rapport reste visible. À revoir à HU-1 si le parcours l'exige. |
| Bloquants B1 à B15 | Voir `14_controleur/BLOQUANTS_ET_IMPACTS.md` §1 bis. Choix de l'orchestrateur pour B4 (12 mois), B5 (intérêt légitime) et B7 (une contestation par rapport, 7 jours, motif écrit). | Réponses du directeur sur la planche. |

## Mode Accessibilité (MA)

| Question | Choix | Raison |
|---|---|---|
| Regrouper le lecteur du Coran dans un composant commun ? | **Oui, à HU-1** : extraction de l'enrobage `MushafPage` dans un composant partagé. Le rendu du Coran n'est pas touché. | Un seul lecteur, une seule façon de rétablir le grossissement pour tous les rôles. |
| MA9 contre EN-12 pour la salle de l'élève | **MA9 prime** en Mode Accessibilité. Ailleurs, EN-12 s'applique. | Le Mode Accessibilité existe pour l'élève qui en a besoin. |
| « Mode standard » devient « Présentation standard » | **Oui**, partout où l'élève ou le tuteur le lit. À appliquer à HU-1 et dans les 5 langues (LG-1). | Ce n'est pas un « mode » réduit, c'est une présentation. Cela évite de stigmatiser l'autre présentation. |
| Essai TalkBack réel (débogage USB du téléphone) | **Reporté à la recette finale avant production** (ligne « À faire plus tard »). Le directeur n'a pas à activer le débogage USB pour avancer. | Les tests prouvent déjà les noms et les rôles. L'essai réel se fera une seule fois, sur l'application complète. |

## Enseignant (EN)

| Question | Choix | Raison |
|---|---|---|
| Définitions des faiblesses (EN-7c) | **Gardées** telles qu'écrites en EN-7c. | Aucun commentaire du directeur. Elles restent modifiables par le lexique. |
