# Front-end — Flutter

Avant de créer ou modifier un écran, lis la fiche correspondante dans `docs/produit/parcours-utilisateurs.md`. Chaque écran y est décrit avec ses états, sa direction artistique et les raisons de ses choix, pas seulement son contenu.

Avant de créer un composant, vérifie `docs/architecture/etape-2-core-flutter.md`. Les dix composants partagés (`Pressable`, `BentoTile`, `AvatarTile`, `AudioLabel`, `PermanentNotice`, `PinPad`, `EmptyState`, `OfflineBanner`, `ChoiceCardGroup`, `ActionPrincipale`) sont les seuls points d'entrée de leur fonction respective. **N'en réimplémente jamais un nouveau qui ferait la même chose.**

Pour savoir ce qui existe déjà et quels pièges ont déjà coûté du temps, lis `docs/architecture/etape-2-journal.md` puis `docs/architecture/etape-3-journal.md`.

Ne lis pas `docs/architecture/etape-0-1-fondations.md` pour une tâche d'interface, sauf besoin de comprendre une contrainte du schéma qui affecte ce que l'écran peut afficher.

## Rappels non négociables, valables pour tout fichier de ce dossier

Ces règles ne sont pas des conventions : `dart run tool/verifier_jetons.dart` les applique, en local et en CI.

- **Aucun `onTap` nu** : tout passe par `Pressable`.
- **Aucune couleur littérale** hors de `lib/core/theme/app_palette.dart`. Le thème n'expose jamais une couleur seule, uniquement des paires `AppColorPair` ou des encres `AppInkColor`. Un widget qui prend `background` sans `onBackground` est à corriger avant fusion.
- **Aucun `IconData` construit** hors de `lib/core/icons/app_icons.dart`, et aucun `Icons.` de Material. Une seule iconographie : Phosphor.
- **Aucune valeur d'espacement** hors de l'échelle 4, 8, 12, 16, 20, 24, 32. Utilise `AppSpacing` et `Ecart`. Une valeur dérivée d'un jeton par un calcul est permise, une valeur posée telle quelle ne l'est pas.
- **`PermanentNotice` n'accepte aucun paramètre**, pas même `key`. Si un paramètre de visibilité existait, quelqu'un finirait par s'en servir et l'ADR-011 tomberait.
- **Tout choix proposé à l'utilisateur passe par `ChoiceCardGroup`**, avec sa carte « Autre » systématique.
- **Un seul routeur**, `lib/core/router/app_router.dart`, aucune branche par plateforme. Le mode enfant et le mode standard partagent la même arborescence : c'est ce qu'un écran **affiche** qui change, jamais la structure.
- **Zéro emoji, zéro M-dash**, dans le code comme dans les libellés.
- **Aucune chaîne visible en dur** : tout passe par slang, clés en points (`eleve.accueil.rejoindre`). Un libellé qui doit aussi être parlé passe par `CleAudio`, pour que texte et son ne divergent pas.
- **Le mode d'interface ne se passe pas d'écran en écran** : il est porté par le thème, via `AppMetriques.of(context)`. Un composant qui recevrait le mode en paramètre finirait par le recevoir faux quelque part.

## Rappels nés de l'étape 3

Ceux-ci ne sont pas tous vérifiables par un outil : ce sont des pièges déjà
payés une fois.

- **Une paire dit sur quoi elle s'écrit.** `surfaceAlert.applyTo(...)` écrit en **blanc**, parce que c'est la couleur de texte prévue pour un fond rouge. Un message d'erreur posé sur la page passe par l'encre `textOnLightAlert`. L'employer à l'envers passe la compilation et la relecture, et ne se voit qu'à l'écran.
- **Ne filtre jamais un `AsyncValue` par son type d'exécution.** Riverpod 3 relance un provider en échec tout seul : l'état repasse par `AsyncLoading` en conservant `hasError`. Lis `hasValue`, `hasError`, `isLoading`.
- **Une absence n'est pas un échec.** Une lecture qui aboutit sans rien trouver ouvre l'inscription ; une lecture qui échoue ferme sur le portail d'attente. Voir `LectureProfil`.
- **Un bouton qui ne peut pas aboutir n'est pas rendu**, il n'est pas grisé. La limite s'explique par une phrase à la place du bouton. Un bouton qui échoue après le geste coûte plus cher en confiance qu'un bouton absent.
- **Le code personnel de l'élève ne quitte jamais l'appareil.** Aucun service ne déclare de paramètre pour le recevoir, et `test/appairage/code_local_test.dart` relit toutes les lignes d'appel réseau de `lib/` pour le vérifier.
- **Ce qui décide d'un droit se pose en base, pas à l'écran.** Le genre d'un dossier KYC, le plafond d'appareils, le rôle d'une inscription : tous écrasés ou refusés par la base, quoi que le client envoie.

## Ce que le routeur n'est pas

Le routeur est une **commodité d'expérience**. La barrière de sécurité reste la RLS de l'étape 1 : un compte qui contournerait une redirection ne lirait aucune donnée de plus. N'écris jamais une règle métier dont l'application ne repose que sur une redirection.

## Génération de code

Dans cet ordre, sinon slang échoue :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

Le code généré est **versionné** : `dart analyze` doit fonctionner sans étape préalable, et la CI refuse tout diff après régénération.
