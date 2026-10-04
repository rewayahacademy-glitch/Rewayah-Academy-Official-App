## Verdict : ACCEPTÉE AVEC RÉSERVES

Le défaut majeur de la revue précédente est levé : sur tablette et bureau, avec un blocage, « Connecter un appareil » est désormais un bouton primaire. Les trois défauts mineurs que la revue demandait de corriger dans ce lot sont levés aussi. Il ne reste que des mineurs, déjà présents avant le lot ou de couverture.

## Contexte

- **Lot :** `corrections/c2-tut-cta-b`, tête `ab051f5f`. Il part de `origin/corrections/c2-tut-cta` et compte 2 commits : `8b56dc91` (code et tests) et `ab051f5f` (captures).
- **Défauts à lever :** ceux de `docs/revues/REVUE_DASH-TUT-CTA-R.md`, lu sur `origin/revues/2026-10-04-b061fd81`.
- **Fichiers modifiés :**
  - `lib/core/widgets/app_card.dart` (+6)
  - `lib/features/accueil_famille/bandeau_blocage.dart` (+8/-10)
  - `lib/features/accueil_famille/carte_classe_seance.dart` (+9/-4)
  - `test/features/accueil_famille_test.dart` (+149)
  - 6 PNG et le script de capture (.txt)
- **Zones interdites :** aucune n'est touchée (ni supabase/, ni .github/, ni pubspec, ni thème, ni libellés).
- **Commits :** messages en français, terminés exactement par les deux lignes demandées.
- **Méthode :** tout a été vérifié dans un worktree jetable détaché sur `origin/corrections/c2-tut-cta-b`, retiré à la fin (`git worktree list` ne le liste plus). Je n'ai rien poussé ni modifié.

## Commandes et résultats

| Commande | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | No issues found |
| `dart run tool/verifier_revue.dart` | 1627 violations, comme la base de la branche source (1627) |
| `dart run tool/verifier_jetons.dart` | 39 violations, base inchangée |
| `dart format --set-exit-if-changed` sur les fichiers touchés | 0 changement |
| `flutter test --concurrency=2 test/features/accueil_famille_test.dart` | +72, tout passe |
| `flutter test --concurrency=2 test/core test/widgets` (dossier d'AppCard) | +918, tout passe |
| `flutter test --concurrency=2 test/features` | +2550 ~2062, tout passe |

## Défauts de la revue précédente : preuve refaite sur la nouvelle tête

### Défaut 1 (majeur) : levé

- **Code.** Hors téléphone, le bandeau rend maintenant la même `ActionPrincipale` (`NiveauAction.principale`, `pleineLargeur: false`) sous le texte : `if (!actionADroite) ...[Ecart.vMd, action]`. Le `LienFleche` et son import ont disparu.
- **Mutation.** J'ai remis l'ancien `bandeau_blocage.dart`. Les deux nouveaux tests « avec blocage, gabarit 1440 / 900 » échouent alors (-2). Les tests sont donc discriminants.
- **Captures 1440 clair et sombre** (ouvertes) : « Connecter un appareil » est un bouton plein, lavande en clair et violet en sombre. C'est le seul bouton plein de l'écran ; « Voir la classe », « Voir tout » et « Voir l'historique » restent des liens fléchés.
- **Capture 900** (rail de navigation) : même bouton plein.
- **Capture RTL 1440** : le bouton s'aligne à droite sous le texte, et la navigation et les flèches sont en miroir.
- **Test ajouté « bureau sans blocage, aucun bouton plein » :** il passe.

### Défaut 2 (mineur) : levé

- `AppCard` expose `lien` (false par défaut) et le transmet à `Pressable`. La carte classe passe `lien: lien`.
- **Mutation 1** (retrait de `lien: lien` dans la carte) : le test sémantique « annoncee comme lien » (`isLink: true`, `isButton: false`) échoue.
- **Mutation 2** (retrait de la transmission dans AppCard) : le même test échoue aussi.
- Le défaut `false` ne change rien aux autres usages d'AppCard (test/core et test/widgets au vert).

### Défaut 3 (mineur) : levé

- **Tests ajoutés :** classe illisible, séance illisible avec classe connue, classe inconnue.
- **Mutation** (retrait de `!seance.hasError`) : le test « seance illisible » échoue.
- **Réserve :** retirer `!classe.hasError` ne fait échouer aucun test. Le garde est redondant tant que l'erreur est initiale (`value` est null), mais une erreur de relecture qui garde une valeur précédente n'est pas couverte. C'est mineur.

### Défaut 4 (mineur) : levé

- Sur bureau, `ConseilAppareil` est rendu avant l'indice, qui ferme donc la carte.
- **Mutation** (ancienne carte remise) : le test de position échoue.
- **Captures 1440 et 900 :** « Voir la classe → » est en bas de la carte, sous le conseil appareil.

### Défaut 5 (mineur, préexistant, hors lot) : non corrigé, consigné

À 320 px avec texte x2, « Aucune séan » est rogné et « Cours dans 2 h / 59 » est coupé. Les deux sont visibles sur la capture `famille_blocage_320x2_sombre`, dans des composants partagés que ce lot ne touche pas.

## Recherche de régressions

- **Téléphone :** le chemin compact du bandeau est inchangé. La carte ne change sur téléphone que par la sémantique de lien.
- **Captures 390 clair et 320 x2 sombre** (ouvertes) : aucun chevauchement. Le bouton est à droite du texte en 390 et passe sous le texte en x2. Aucun mot nouveau coupé n'est imputable au lot.
- **Captures 1440 et 900 :** aucun mot coupé, aucun élément collé ; mise en miroir RTL correcte.
- **Artefacts bidi en RTL** (point en tête de phrase, « min 45 ») : ils existaient avant le lot, qui ne touche ni les libellés ni ces textes.
- **Règles vérifiées :**
  - Aucun bouton grisé : la carte sans classe n'est simplement pas un lien.
  - Aucun libellé nouveau.
  - Jetons seulement : verifier_jetons est inchangé.
  - Aucun secret.
  - Aucun branchement serveur.

## Réserves

1. Défaut 5 préexistant (sélecteur de profils et BlocSeance à 320 px x2), à traiter dans un lot dédié.
2. Le garde `!classe.hasError` n'est pas couvert par un test discriminant (cas d'une erreur de relecture avec valeur précédente).
3. Observation : les effets bidi sur le texte latin en RTL sont préexistants.

## Verdict

**ACCEPTÉE AVEC RÉSERVES** : aucun défaut majeur ne reste, seuls des mineurs.