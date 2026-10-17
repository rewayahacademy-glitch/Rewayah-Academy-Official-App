# L4-05-reprise - le bouton de l'alerte d'appareil redevient un bouton pour les lecteurs d'écran

Reprise issue de L4-V (défaut D-1). Petit lot.

## 1. But et pourquoi

Depuis L4-05 (`c8b7d8b4`, `1f18bdb6`), l'alerte « Aucun appareil prêt pour Aïcha » de l'Accueil tuteur est un `BandeauAttention` dont l'action est un `ActionPrincipale` (`lib/features/accueil_famille/bandeau_blocage.dart`). Le bandeau pose `Semantics(container: true, liveRegion: true)` et son titre `Semantics(header: true)` (`lib/core/widgets/bandeau_attention.dart:57-90`) ; l'action n'a pas de frontière sémantique propre. Résultat mesuré par L4-V :

- sonde widget (hors dépôt, `scratchpad/L4-V/sonde_alerte_semantique_test.dart`) : le nœud du bouton et le nœud de l'alerte sont le même (`meme_noeud=true`), à la fois titre et bouton, libellé « Aucun appareil prêt pour Aïcha / Sans appareil connecté, Aïcha ne pourra pas entrer en classe. / Connecter un appareil » ;
- construction web locale (`?demo=tuteur`, 390 et 1440) : l'alerte entière est rendue comme un seul `h2` de 358 x 160, sans `role="button"` ; avant L4-05, « Connecter un appareil » était un nœud `button` distinct (148 x 64).

Un lecteur d'écran web n'annonce donc plus le bouton plein de l'écran (D5) comme un bouton. WCAG 4.1.2 (nom, rôle, valeur).

## 2. Critère de réussite

1. Dans l'arbre sémantique, « Connecter un appareil » est un nœud distinct, bouton, avec l'action « toucher », et n'est pas un titre ; le titre de l'alerte reste un titre ; le message reste lu.
2. Un test widget de `test/features/accueil_famille_test.dart` (ou un fichier voisin) le vérifie : `tester.getSemantics(find.byType(ActionPrincipale))` différent du nœud de `BandeauBlocage.cleAlerte`, drapeau bouton vrai, drapeau titre faux.
3. Rendu inchangé au pixel (même clé, même largeur 212 à 390 et à 1440, un seul bouton plein, D5) ; les trois tests DASH-TUT-CTA restent dans leur sens.

## 3. Ce qu'il faut lire

- `lib/features/accueil_famille/bandeau_blocage.dart` (L4-05).
- `lib/core/widgets/bandeau_attention.dart` lignes 40 à 110.
- `docs/audit-final/verifications/L4-V-2026-10.md`, défaut D-1.

## 4. Fichiers autorisés et interdits

Autorisés : `lib/features/accueil_famille/bandeau_blocage.dart`, `test/features/accueil_famille_test.dart`. Interdits : `lib/core/widgets/bandeau_attention.dart` (appelé par une dizaine d'écrans : sa correction générale est une autre décision, à signaler), jetons, `supabase/**`.

## 5. Étapes

1. Envelopper l'action dans `Semantics(container: true, child: ...)` dans `bandeau_blocage.dart` (le plus simple qui sépare le nœud).
2. Écrire le test du critère 2 ; le voir échouer sans l'étape 1.
3. `dart analyze --fatal-infos`, `flutter test test/features/accueil_famille_test.dart test/features/demo/l4_05_demo_coherente_test.dart`.

## 6. Vérifications

Les six commandes ; une capture 390 inchangée ; sur construction web locale, « Connecter un appareil » apparaît comme `flt-semantics` de rôle `button`.

## 7. Pièges connus

- Les autres usages de `BandeauAttention` avec une action (`acces_finance.dart`, `recevoir_paiements_page.dart`, `catalogue_page.dart`) ont probablement le même défaut : les lister dans le commit, ne pas les corriger ici.
- `liveRegion` sur le conteneur : garder l'annonce de l'alerte, ne pas la retirer.

## 8. Quand s'arrêter et demander

- Si la séparation du nœud change l'ordre de lecture ou casse un test d'accessibilité existant hors de `accueil_famille` : s'arrêter et le dire.

## 9. Commit

- Branche : `lots/L4-05R-alerte-semantique`, partie de `lots/V34-candidate`.
- Message : `fix(tuteur): le bouton de l alerte d appareil garde son role de bouton (L4-05-reprise)`.

## 10. Modèle conseillé

Haiku suffit.
