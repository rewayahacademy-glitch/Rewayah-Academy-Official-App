# X2-18 — BLOQUÉ

Le port Claude `PortExportRapports` et son consommateur `ActionExport` ne
peuvent rendre qu'une `reference` et un nombre de `lignes`. Le parcours
affiche ensuite « export prêt », mais ne reçoit aucun contenu de ligne ni
aucun moyen de le télécharger. La décision X2-18 demande maintenant une RPC
qui renvoie les lignes et ne stocke pas de fichier. Une implémentation
`*_supabase.dart` qui lit puis jette ces lignes présenterait un export prêt
sans livrer les données; les mettre en cache localement ne donne pas non plus
au consommateur de moyen de les récupérer.

Le rapport n'a pas de période ni de colonnes définies dans l'interface, et la
sélection n'identifie pas explicitement le type de ligne au-delà du commentaire
« paiements à effectuer ». Il manque donc le contrat des données exportées,
les limites attendues et la forme de livraison côté UI. Les fichiers `port_*`
et le parcours UI étant détenus par Claude selon la feuille, ce lot ne modifie
pas leurs interfaces et n'invente pas un export incomplet.

À arbitrer : fournir les lignes dans une interface de port révisée (et le
contrat de période/colonnes/limites), ou conserver un fichier côté serveur et
remplacer la référence par un lien de téléchargement contrôlé. Aucun export
financier ni journal métier incomplet n'a été ajouté.
