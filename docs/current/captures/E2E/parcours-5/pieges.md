# Parcours 5 : pièges (salle)

Règle : si l'application laisse faire une erreur sans un mot clair et sans un moyen de revenir, le
parcours est rouge. Script : `tool/e2e/pieges_5.mjs` (séance en cours de la chaîne).

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 5.1 | Salle, enseignant | 1 | « Quitter la séance » par erreur, puis revenir | oui | vert : confirmation « Quitter la séance ? » avec « Rester » ; après « Quitter », l'écran propose « Retourner dans la salle ». Mais cet écran a une autre barre de navigation et dit « Séance terminée » alors que la séance continue → UX-040 |
| 5.2 | Salle, enseignant | 2 | Rechargement de la page en pleine séance | oui | vert : apres rechargement : http://127.0.0.1:8090/#/enseignant/journee ; « h2:Aujourd'hui / flt-semantics:Dimanche 1 novembre / flt-semantics:Prochaine séance » |
| 5.3 | Salle, enseignant | 2 | La salle ouverte dans deux onglets en même temps | oui | rouge : la salle ouverte dans un second onglet fait afficher au premier « La connexion au cours est perdue. Impossible de rétablir la connexion. » sans dire qu'elle est ouverte ailleurs → UX-038 |
| 5.4 | Salle, tuteur | 6 | Caméra et micro refusés par le navigateur | non | non joué : Chromium lancé avec `--use-fake-ui-for-media-stream` accorde toujours micro et caméra ; un refus ne peut pas être simulé dans ce banc |
| 5.5 | Accueil, élève adulte | 1 | « Rejoindre » cherché plus de 20 minutes avant la séance | non | non joué : l'élève adulte de la dernière chaîne n'est placé dans aucune classe (parcours 4 rouge) ; à rejouer |
| 5.6 | Salle, tuteur | 1 | Le tuteur quitte puis revient | oui | rouge : le tuteur qui quitte lit « La séance est terminée. » (elle continue) avec seul « Retour à l'accueil » → UX-039 |
