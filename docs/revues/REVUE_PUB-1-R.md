<!-- verdict : REFUSEE -->
## Relecture adverse de PUB-1 (branche `corrections/c2-pub`, commit `a29fcfc1`)

### Verdict : REFUSEE

PUB-1 est presque entièrement fait, mais il reste un défaut majeur, prouvé par un test : **sur ordinateur, le défilement automatique ne marche pas pour un visiteur à la souris.**

### Le défaut qui bloque la fusion

- **Ce qui se passe.** La pause au survol de la souris a été ajoutée par la session ; le directeur ne l'avait pas demandée. Elle s'applique à toute la surface de la page.
- **La conséquence.** Sur ordinateur (1440), dès que le curseur est dans la fenêtre, la présentation ne défile pas et la petite ligne d'état ne se charge pas. Un visiteur à la souris ne voit donc jamais le défilement automatique demandé.
- **La preuve.** Un test ajouté pour la relecture, en 1440x900, pose une souris au centre de la page puis laisse passer 30 s. La présentation reste sur la page 1 et la ligne d'état ne bouge pas. Sans souris, elle va jusqu'à la page 5. Aucun test du rédacteur ne vérifie le survol.
- **La correction attendue.**
  - Soit supprimer la pause au survol, pour s'en tenir à la liste du directeur : toucher, focus, réduire les animations.
  - Soit la limiter à une petite zone (par exemple la ligne d'état et les flèches).
  - Dans les deux cas, ajouter un test « souris posée sur la page : la présentation défile quand même ».

### Ce qui est conforme (vérifié par moi)

**Le contenu**
- 5 pages, une idée chacune :
  1. le Coran en classe, en visio ;
  2. une classe stable à horaire fixe ;
  3. un enseignant attitré ;
  4. un parcours selon le niveau ;
  5. le suivi de la famille.
- Les textes viennent de l'ancien accueil et de `01_PRODUIT_ET_PARCOURS.md` (§19 et §35). Aucun prix, aucun chiffre.
- Les pictogrammes viennent du design system ; aucun nouvel asset.

**Le défilement et la navigation**
- Rythme de 6 s.
- Pause au toucher et au focus.
- Aucun défilement automatique si « réduire les animations » est actif ou si un lecteur d'écran est ouvert.
- Le défilement s'arrête à la dernière page, sans recommencer.
- Glissement manuel, aussi dans le sens arabe ; flèches à l'écran et flèches du clavier.
- Aucune flèche grisée : au début et à la fin, la flèche n'est pas affichée.

**La croix et la sortie**
- La croix est nommée « Passer la présentation » et c'est le premier arrêt au clavier.
- La croix et « Commencer » mènent à la connexion et notent la visite.

**Vu une seule fois et routeur**
- À la racine, un visiteur sans session va vers la présentation la première fois, puis vers la connexion. Tant que l'appareil n'a pas été lu, l'écran de démarrage reste affiché, sans clignotement.
- Le lien « Découvrir » de la connexion ouvre toujours la présentation.

**Fiche et suivi**
- La fiche et la revue UX sont dans `UX_REVIEW_PUB-1.md`, avec les décisions D1 à D9 « décidé par délégation le 05/10 ».
- La ligne a été ajoutée dans `REVUE-DIRECTEUR-2026-10.md`.
- Aucun branchement serveur. Aucun fichier interdit touché (supabase/, .github/, vercel.json, pubspec.yaml, thème, rendu du Coran).

### Mutations (j'ai cassé chaque comportement, un à la fois)

Sur `presentation_test.dart`, chaque mutation sauf la dernière fait échouer un test :

| Mutation | Résultat |
|---|---|
| Pause au toucher supprimée | échec |
| Pause au focus supprimée | échec |
| « Réduire les animations » ignoré | échec |
| Lecteur d'écran ignoré | échec |
| Visite non notée | échec |
| Redirection de première visite vers la connexion | échec |
| Glissement qui ne rend pas la main | échec |
| Rythme de 9 s | échec |
| `MarquePage` revenue à `Text` | échec (320 x2 RTL) |
| Boucle à la dernière page | aucun échec, mais cette mutation ne change pas le comportement (la fonction appelée refuse déjà d'aller au-delà de la dernière page) |

### Contrôles lancés

- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : aucune nouvelle violation par rapport à la base `6e2c91c4`.
- `verifier_revue` : 1550 violations sur la base, 1540 sur la branche. Il y en a 10 de moins (libellés sans source) et aucune nouvelle.
- `flutter test --concurrency=2` sur `test/features` (en entier, ce que le rédacteur n'avait pas refait après sa dernière correction), `test/router`, `test/widgets`, `test/theme`, `test/accessibilite`, `test/agent` et `vue_classe_live_test` : **3954 tests réussis, 0 échec.** Cela couvre les autres écrans qui utilisent `MarquePage`, `BarrePrecedentSuivant` et `BoutonIcone`.

### Captures ouvertes

J'ai ouvert :
- 320 x2 en clair (LTR) ;
- 320 x2 en sombre (RTL) ;
- 390 en RTL ;
- 1440 en clair et en sombre.

Aucun mot coupé, aucun débordement. Un seul bouton plein, qui sur ordinateur fait la largeur de son libellé.

### Défauts mineurs, à corriger dans la même reprise

1. **Mention des libellés.** Les 13 libellés portent « … validé par délégation le 05/10, à faire valider par le directeur ». C'est contradictoire, et ce n'est pas la formule exacte demandée.
2. **Ponctuation en RTL.** Le texte reste en français faute de clés arabes, et le point final s'affiche en tête de ligne (capture 390 en RTL).
3. **Fin de page cachée à 320 x2.** La fin du texte et, sur la dernière page, les deux boutons sont hors de l'écran. Rien n'indique qu'il faut faire défiler vers le bas.
4. **Web non prouvé.** Le stockage dans le navigateur (localStorage) n'est ni testé ni compilé pour le web : la règle « vu une seule fois » de la PWA n'est pas prouvée. La revue UX cite en outre les règles WCAG et Apple de mémoire.

### Statut de preuve

- Spécifié : oui.
- Présent dans le code : oui.
- Testé localement : oui, sauf le survol et la PWA.
- Testé sur staging : non.
- Déployé : non.

Je n'ai rien poussé. Les worktrees jetables ont été retirés.
