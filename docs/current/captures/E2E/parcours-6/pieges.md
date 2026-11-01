# Parcours 6 : pièges (cahier de transmission)

Règle : si l'application laisse faire une erreur sans un mot clair et sans un moyen de revenir, le
parcours est rouge. Script : `tool/e2e/pieges_6.mjs`, joué le 01/11 à 03:16 UTC sur le premier cahier de « À terminer » (classe d'enfants) ;
6.2 rejoué à 03:19 sur le cahier des adultes (`tool/e2e/pieges_6b.mjs`), validé ensuite.

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 6.1 | Cahier | 4 | « Valider le cahier de transmission » sans avoir choisi où la classe s'est arrêtée | oui | vert : « Valider » sans position n'enregistre rien ; le champ passe en rouge avec « Indiquez où la Classe s'est arrêtée : un remplaçant reprendra ici. » (cahier de la classe d'enfants, captures pieges/01) |
| 6.2 | Cahier | 4 | Texte saisi, puis « Retour » avant de valider, puis réouverture du cahier | oui | défaut Gênant, pas rouge par la règle (un moyen de revenir existe) : la position « Sourate 109, verset 6 » est perdue sans un mot après Retour ; rouverte, la fiche redemande « Choisir la sourate et le verset » → UX-041 (cahier des adultes, captures pieges-adultes/02 et 04). Revenir reste possible : on choisit de nouveau, sans rien d'autre de perdu |
| 6.3 | Cahier | 3 | Texte très long (3 000 caractères) dans un champ libre | non | non joué : le cahier n'a aucun champ de texte libre, seulement la position (sourate et verset) ; piège sans objet |
| 6.4 | Cahier | 2 | Double clic sur « Valider le cahier de transmission » | oui | vert : double clic sur « Valider » : une seule confirmation « Cahier de transmission enregistré. L'académie l'a reçu. », aucune erreur (captures pieges/02). Nombre de cahiers en base non vérifié : la requête du script visait la mauvaise table |
