# Front-end — Flutter

**Avant tout : `docs/design/00-bible-frontend-v2.md`.** C'est le contrat frontend
(ADR-019), 61 chapitres, adopté le 11 septembre 2026. `docs/design/README.md`
§4 BIS dit ce qui en est déjà tenu, ce qui est tranché autrement pour une raison
écrite, et ce qui reste un écart ouvert avec son lot. Ne redérive jamais une
règle de ce fichier depuis une intuition : la Bible existe précisément parce que
deux refontes successives ont montré que sans elle, chaque écran invente son
propre rayon, sa propre carte, son propre bouton.

Avant de créer ou modifier un écran, lis la fiche correspondante dans `docs/produit/parcours-utilisateurs.md`. Chaque écran y est décrit avec ses états, sa direction artistique et les raisons de ses choix, pas seulement son contenu.

Avant de créer un composant, vérifie `docs/architecture/etape-2-core-flutter.md`. Les dix composants partagés (`Pressable`, `BentoTile`, `AvatarTile`, `AudioLabel`, `PermanentNotice`, `PinPad`, `EmptyState`, `OfflineBanner`, `ChoiceCardGroup`, `ActionPrincipale`) sont les seuls points d'entrée de leur fonction respective. **N'en réimplémente jamais un nouveau qui ferait la même chose.**

Pour savoir ce qui existe déjà et quels pièges ont déjà coûté du temps, lis `docs/architecture/etape-2-journal.md` puis `docs/architecture/etape-3-journal.md`.

Ne lis pas `docs/architecture/etape-0-1-fondations.md` pour une tâche d'interface, sauf besoin de comprendre une contrainte du schéma qui affecte ce que l'écran peut afficher.

## Rappels non négociables, valables pour tout fichier de ce dossier

Ces règles ne sont pas des conventions : `dart run tool/verifier_jetons.dart` les applique, en local et en CI.

- **Aucun `onTap` nu** : tout passe par `Pressable`.
- **Aucune couleur littérale** hors de `lib/core/theme/app_palette.dart`. Le thème n'expose jamais une couleur seule, uniquement des paires `AppColorPair`, des encres `AppInkColor` ou l'ombre `AppShadowColor`. Un widget qui prend `background` sans `onBackground` est à corriger avant fusion.
- **Aucun `IconData` construit** hors de `lib/core/icons/app_icons.dart`, et aucun `Icons.` de Material. Une seule iconographie : Phosphor.
- **Aucune valeur d'espacement** hors de l'échelle 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Utilise `AppSpacing` et `Ecart`. Une valeur dérivée d'un jeton par un calcul est permise, une valeur posée telle quelle ne l'est pas.
- **Aucun rayon littéral** : `BorderRadius.circular(20)` est refusé. Passe par `AppRadius`, et souviens-toi que **le rayon d'un enfant est plus petit que celui de son parent** (`AppRadius.enfantDe`).
- **Aucune `BoxShadow` construite** hors de `app_elevation.dart`. Une surface élevée porte **un filet ET une ombre**, jamais l'un des deux seul : `AppElevation.avecFilet` compose les deux en une fois.
- **Aucun `letterSpacing`** hors d'`app_typography.dart`. Le crénage se calcule à partir de la taille rendue, il ne se pose pas à la main.
- **Aucune `Duration(milliseconds: ...)` ni `Curves.`** hors d'`app_mouvement.dart`. Les durées métier, en minutes ou en heures, restent libres : elles ne sont pas du mouvement.
- **Aucun nom de jeton d'avant la refonte** : `surfaceBase`, `borderDefault`, `textOnLightAccent`, `textOnLightAlert`, `NotoSans` et `VarelaRound` sont refusés. La correspondance est dans `design-tokens.md` section 1.8.
- **`PermanentNotice` n'accepte aucun paramètre**, pas même `key`. Si un paramètre de visibilité existait, quelqu'un finirait par s'en servir et l'ADR-011 tomberait.
- **Tout choix proposé à l'utilisateur passe par `ChoiceCardGroup`**, avec sa carte « Autre » systématique.
- **Un seul routeur**, `lib/core/router/app_router.dart`, aucune branche par plateforme. Le mode enfant et le mode standard partagent la même arborescence : c'est ce qu'un écran **affiche** qui change, jamais la structure.
- **Zéro emoji, zéro M-dash**, dans le code comme dans les libellés.
- **Aucune chaîne visible en dur** : tout passe par slang, clés en points (`eleve.accueil.rejoindre`). Un libellé qui doit aussi être parlé passe par `CleAudio`, pour que texte et son ne divergent pas.
- **Le mode d'interface ne se passe pas d'écran en écran** : il est porté par le thème, via `AppMetriques.of(context)`. Un composant qui recevrait le mode en paramètre finirait par le recevoir faux quelque part.

## Rappels nés de la refonte

- **`inkFaint` est interdit sur `surfaceSunken`** : il y mesure 4,48, juste sous le seuil. Passe par `AppPalette.encreSecondaireSur(surface)`, qui choisit à ta place.
- **Une seule zone pleine par écran.** Un aplat saturé, c'est l'action principale, et rien d'autre. Un bandeau d'avertissement, un badge, une ligne d'alerte prennent le registre doux : `washX` en fond, `inkX` en encre.
- **Une police variable a une valeur par défaut par axe, et ce n'est pas celle qu'on croit.** Bricolage Grotesque est livrée à `wght` 800 et `opsz` 96. Un style qui ne déclare que `fontSize` sort faux, sans que rien ne le signale avant l'écran.
- **Le mouvement réduit ne se traite pas en supprimant l'animation.** Une pulsation supprimée emporte l'information qu'elle portait : elle devient une bordure `borderStrong` fixe. Passe par `AppMouvement.duree` et `AppMouvement.translation`.

## Rappels nés de l'étape 3

Ceux-ci ne sont pas tous vérifiables par un outil : ce sont des pièges déjà
payés une fois.

- **Une paire dit sur quoi elle s'écrit.** `surfaceAlert.applyTo(...)` écrit en **blanc**, parce que c'est la couleur de texte prévue pour un fond rouge. Un message d'erreur posé sur la page passe par l'encre `inkAlert`. L'employer à l'envers passe la compilation et la relecture, et ne se voit qu'à l'écran.
- **Ne filtre jamais un `AsyncValue` par son type d'exécution.** Riverpod 3 relance un provider en échec tout seul : l'état repasse par `AsyncLoading` en conservant `hasError`. Lis `hasValue`, `hasError`, `isLoading`.
- **Une absence n'est pas un échec.** Une lecture qui aboutit sans rien trouver ouvre l'inscription ; une lecture qui échoue ferme sur le portail d'attente. Voir `LectureProfil`.
- **Un bouton qui ne peut pas aboutir n'est pas rendu**, il n'est pas grisé. La limite s'explique par une phrase à la place du bouton. Un bouton qui échoue après le geste coûte plus cher en confiance qu'un bouton absent.
- **Le code personnel de l'élève ne quitte jamais l'appareil.** Aucun service ne déclare de paramètre pour le recevoir, et `test/appairage/code_local_test.dart` relit toutes les lignes d'appel réseau de `lib/` pour le vérifier.
- **Ce qui décide d'un droit se pose en base, pas à l'écran.** Le genre d'un dossier KYC, le plafond d'appareils, le rôle d'une inscription : tous écrasés ou refusés par la base, quoi que le client envoie.

## Tags de conformité (Bible V2 §45)

Un vocabulaire **fermé**, vérifié par `tool/verifier_jetons.dart` (règle
`tag-conformite`) : tout tag entre crochets ressemblant à un tag de conformité
dans `lib/` doit être l'un de ceux-ci, jamais un tag inventé à la volée.

- `[M3-COLOR]` — usage d'un rôle sémantique de `ColorScheme` ou d'`AppPalette`,
  aucune couleur hardcodée.
- `[A11Y]` — décision d'accessibilité : semantics, focus, cible tactile, texte
  agrandi.
- `[RESPONSIVE]` — choix de présentation dépendant du gabarit (`AppGabarit`).
- `[QURAN-STAGE]` — séparation entre état partagé de la salle et état personnel
  de lecture (Bible §24, spécifié à l'étape 5 par ADR-020).

Ne pas mettre de commentaire évident partout : le tag documente une **décision**
structurante, pas un fait déjà visible dans le code qui l'entoure.

## Ce que le routeur n'est pas

Le routeur est une **commodité d'expérience**. La barrière de sécurité reste la RLS de l'étape 1 : un compte qui contournerait une redirection ne lirait aucune donnée de plus. N'écris jamais une règle métier dont l'application ne repose que sur une redirection.

## Génération de code

Dans cet ordre, sinon slang échoue :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

Le code généré est **versionné** : `dart analyze` doit fonctionner sans étape préalable, et la CI refuse tout diff après régénération.
