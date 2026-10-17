# L2-03-reprise - « cahier de transmission » dans la confirmation, retour par `LocalFeedback`

Reprise issue de L2-V (défaut D-4). Petit lot.

## 1. But et pourquoi

`enseignant.journee.cahiersEnvoyes` dit « {n} cahier envoyé » : la garde LIB-CAHIER-1 (`test/features/libelles_lot3_test.dart`, aucun libellé enseignant ne dit « cahier » sans « de transmission ») est rouge ; verte sur la base. La confirmation est un `SnackBar` brut (`journee_page.dart:158`), le seul de `lib/` ; DESIGN-GOV contrat C désigne `LocalFeedback` pour le retour local.

## 2. Critère de réussite

1. FR : « {n} cahier de transmission envoyé » / « {n} cahiers de transmission envoyés » ; AR aligné sur le terme arabe déjà employé pour « cahier de transmission » dans `ar.i18n.json` (le chercher, ne pas l'inventer), toutes formes du pluriel (zero à other).
2. La confirmation passe par `LocalFeedback` (`lib/core/widgets/local_feedback.dart`), comme `cahier_page.dart:268`.
3. `libelles_lot3_test.dart` et `rejouer_cahiers_test.dart` verts ; `ar_domaines_test` vert.

## 3. Ce qu'il faut lire

- `lib/features/journee/journee_page.dart` (L2-03), `lib/core/widgets/local_feedback.dart`, un usage (`lib/features/cahier/cahier_page.dart`).
- `test/features/libelles_lot3_test.dart` lignes 200 à 245.

## 4. Fichiers autorisés et interdits

Autorisés : `lib/features/journee/journee_page.dart`, `assets/i18n/fr.i18n.json`, `assets/i18n/ar.i18n.json`, `tool/libelles_sources.json` (source de la clé), `test/features/journee/`. Interdits : `lib/core/**`, `supabase/**`.

## 5. Étapes

1. Changer les deux libellés, `dart run slang`.
2. Remplacer le `SnackBar` par un `LocalFeedback` placé dans la page (état local `_retour`), sans bloquer l'affichage.
3. Adapter `rejouer_cahiers_test.dart` au nouveau texte et au composant.

## 6. Vérifications

Les six commandes ; `flutter test test/features/journee test/features/libelles_lot3_test.dart test/i18n`.

## 7. Pièges connus

- Le libellé allongé doit tenir à 320 px et texte x2 sans mot coupé.

## 8. Quand s'arrêter et demander

- Si `LocalFeedback` ne peut pas vivre dans la Journée sans changer sa composition : s'arrêter et le dire.

## 9. Commit

- Branche : `lots/L2-03R-cahier-transmission`, partie de `lots/V2-candidate`.
- Message : `fix(enseignant): confirmation des cahiers de transmission par LocalFeedback (L2-03-reprise)`.

## 10. Modèle conseillé

Haiku suffit.
