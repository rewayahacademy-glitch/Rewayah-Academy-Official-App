# Parcours 4 : pièges (direction pressée)

Règle : si l'application laisse faire une erreur sans un mot clair et sans un moyen de revenir, le
parcours est rouge. Script : `tool/e2e/pieges_4.mjs`.

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 4.1 | Ajouter un élève | 1 | Ajouter un élève déjà dans une autre classe active | oui | rouge : prouvé par le passage de la chaîne du 31/10 23:35 UTC (capture `captures/E2E/constats/UX-019_ajout_eleve_deja_en_classe.png` : « L'ajout n'a pas abouti : cet eleve appartient deja a un groupe actif, code: P0001, details: Bad Request, hint: null ») ; le passage du piège lui-même n'a pas pu rouvrir la boîte → UX-019 |
| 4.2 | Ajouter un élève | 1 | « Ajouter » sans motif | oui | vert : sans motif, rien n'est ajouté (0 membre) ; la phrase « Un motif est requis » est toujours affichée sous les motifs |
| 4.3 | Ajouter un élève | 1 | Un élève adulte dans une classe d'enfants | oui | vert : l'eleve adulte n'est pas propose dans une classe d'enfants (proposes : aucun) |
| 4.4 | Ajouter un élève | 1 | Une fille dans une classe de garçons | non | non joué : aucune eleve fille |
| 4.5 | Ajouter un élève | 1 | Une classe déjà complète (seuil d'un élève atteint) | non | non joué : « Modifier le seuil » non abouti par le script |
| 4.6 | Ajouter un élève | 2 | Double clic sur « Ajouter » | non | non joué : aucun eleve libre a ajouter deux fois (le seul garcon est deja en classe) |
| 4.7 | Classes | 1 | La direction cherche « Ajouter un élève » dans la fiche de la classe (là où elle voit « Membres ») | oui | rouge : la fiche de la classe montre « Membres » et « Aucun élève dans cette classe pour l'instant » sans « Ajouter un élève » (l'action est dans le menu de la ligne) → UX-008 |
