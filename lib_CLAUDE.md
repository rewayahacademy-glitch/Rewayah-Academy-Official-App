# Front-end — Flutter

Avant de créer ou modifier un écran, lis la fiche correspondante dans `docs/produit/parcours-utilisateurs.md`. Chaque écran y est décrit avec ses états, sa direction artistique et les raisons de ses choix, pas seulement son contenu.

Avant de créer un composant, vérifie `docs/architecture/etape-2-core-flutter.md`. Les composants partagés (`Pressable`, `BentoTile`, `AvatarTile`, `AudioLabel`, `PermanentNotice`, `PinPad`, `EmptyState`, `OfflineBanner`, `ChoiceCardGroup`) sont les seuls points d'entrée de leur fonction respective. **N'en réimplémente jamais un nouveau qui ferait la même chose.**

Ne lis pas `docs/architecture/etape-0-1-fondations.md` pour une tâche d'interface, sauf besoin de comprendre une contrainte du schéma qui affecte ce que l'écran peut afficher.

## Rappels non négociables, valables pour tout fichier de ce dossier

- Aucun `onTap` nu : tout passe par `Pressable`.
- Le thème n'expose jamais une couleur seule, uniquement des paires fond-texte.
- `PermanentNotice` n'accepte aucun paramètre de visibilité conditionnelle.
- Tout choix proposé à l'utilisateur passe par `ChoiceCardGroup`, avec une carte "Autre" en repli.
- Un seul routeur pour toutes les plateformes, aucune branche par plateforme.
