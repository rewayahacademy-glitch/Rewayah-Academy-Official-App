# UX_REVIEW_DEPOT-SIMPLE : « Ajouter un document », le strict nécessaire (13/11/2026)

Lot DEPOT-SIMPLE (`docs/current/pedagogie/lots/LOT-DEPOT-SIMPLE.md`). Demande du directeur du
13/11/2026 : le formulaire était « immense », sans couleur ni message clair pour dire si un dépôt
avait marché.

**Ce qui n'est pas prouvé.** Les captures viennent du double de démonstration, par le vrai routeur.
Rien n'a été essayé en production ni avec un vrai lecteur d'écran.

| Règle | Source | Date | Conclusion | Modification |
| :-- | :-- | :-- | :-- | :-- |
| Déduit > choisi > saisi | K-57 (`lib/CLAUDE.md`) | 01/10/2026 | Le type, la langue et le nom se déduisent du fichier ; l'accès et le rayon se choisissent ; seuls le nom (corrigé) et la description se saisissent | Type, langue, catégorie et niveau retirés du formulaire |
| Divulgation progressive : ne montrer que ce qui sert à la tâche | Nielsen, heuristique 8 (« Aesthetic and minimalist design ») ; Material 3, « Progressive disclosure » | consultées de mémoire le 13/11/2026 | Douze champs sur quinze ne servent pas à la tâche courante | « Plus de réglages », replié par défaut, sans rien d'obligatoire |
| Visibilité de l'état du système | Nielsen, heuristique 1 | idem | « Fichier vérifié » ne disait pas si le dépôt avait marché | Trois états par dépôt : barre et pourcentage, bandeau de succès, bandeau d'alerte |
| L'information ne passe jamais par la couleur seule | WCAG 2.2, 1.4.1 ; règle du dépôt (« Un état ne se signale jamais par la couleur seule ») | idem | Chaque état a une icône, un titre et une phrase en plus de sa teinte | `BandeauAttention` : la coche pour le succès (ajoutée au composant partagé) |
| Les messages d'état sont annoncés sans déplacer le focus | WCAG 2.2, 4.1.3 | idem | Chaque bandeau et chaque phrase d'état est une région vivante | `Semantics(liveRegion: true)` (déjà dans `BandeauAttention`) |
| Un message d'échec dit ce qui manque, la cause probable et quoi faire | K-59 ; Nielsen, heuristique 9 | idem | « La connexion s'est interrompue » couvrait douze causes | Une phrase par cause ; le réglage du serveur en cause est nommé |
| Un seul bouton plein, jamais grisé | K-56 | 01/10/2026 | Tenu : le bouton n'est rendu que s'il peut aboutir, une phrase dit ce qui manque | « Enregistrer le document » ; choisir un fichier ou une vignette sont des actions secondaires ou des liens |
| Tout choix s'explique ; une conséquence irréversible se dit avant | K-58 | 01/10/2026 | « Téléchargement permis » dit qu'un fichier téléchargé ne se reprend pas | Deux cartes par choix, chacune avec sa conséquence (`ChoiceCardGroup`) |
| Le contenu arabe prend sa police et son sens | directeur, 13/11/2026 (`styleContenuArabe`) | 13/11/2026 | Le nom d'un fichier et le nom d'un document sont du contenu | Nom du fichier en police de contenu arabe ; champs en sens de la première lettre |
| Contrastes | paires de jetons (`AppPalette.paireDe`) | sans objet | Aucune couleur choisie par l'écran : les tons de succès et d'alerte sont ceux des jetons, clair et sombre | aucune |

Limite : la validation UX n'a changé aucune permission. Le dépôt direct et sa trace viennent d'une
décision (fiche du lot, §Décisions), pas d'un standard.
