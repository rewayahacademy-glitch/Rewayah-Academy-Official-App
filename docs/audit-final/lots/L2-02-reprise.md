# L2-02-reprise - Tests de la revue des dossiers alignés sur la porte `piece-identite-acces`, erreurs de la fonction traduites

Reprise issue de L2-V (défaut D-2). Petit lot, `lib/core/capacites/` et `test/` seulement.

## 1. But et pourquoi

L2-02 fait passer l'aperçu par `functions.invoke('piece-identite-acces', {document_id})`. Trois tests de `test/features/dossiers_admin_test.dart` attendent encore l'ancien contrat (clé d'objet `p1/piece.webp`, `StorageException` 404 et 500) et sont rouges ; verts sur la base. Côté code, `revue_dossiers_depuis_validation.dart` ne traduit que `StorageException` : une `FunctionException` 404 (document introuvable) ou 500 tombe dans le cas générique.

## 2. Critère de réussite

1. Les trois tests (« AD-7 : ni journalisation ni URL ... », « AD-7 : une signature en echec (404) ... », « AD-T-LECTURE : signature indisponible (500) ... ») attendent l'identifiant de document et des `FunctionException` (statuts 404 et 500), et sont verts.
2. `revue_dossiers_depuis_validation.dart` traduit `FunctionException` : 403 reste `ApercuRefuse`, 400 et 404 deviennent `CodeErreurRevue.introuvable`, le reste `indisponibleTemporairement` ; la branche `StorageException`, devenue morte, est retirée.
3. `flutter test test/features/dossiers_admin_test.dart test/core/capacites test/core/dossier` vert, puis `flutter test` complet sans ces rouges.

## 3. Ce qu'il faut lire

- `test/features/dossiers_admin_test.dart` lignes 430 à 500.
- `lib/core/capacites/revue_dossiers_depuis_validation.dart` lignes 255 à 310.
- `supabase/functions/piece-identite-acces/index.ts` (codes de retour).

## 4. Fichiers autorisés et interdits

Autorisés : `lib/core/capacites/revue_dossiers_depuis_validation.dart`, `test/features/dossiers_admin_test.dart`, `test/core/capacites/`. Interdits : `supabase/**`, autres écrans.

## 5. Étapes

1. Remplacer `StorageException(..., statusCode: '404')` par `FunctionException(status: 404, ...)` dans les faux ; attendre `['doc1']` (l'identifiant) là où le test attendait la clé.
2. Ajouter le `on FunctionException catch (e)` avec la table du critère 2.
3. Lancer les commandes du critère 3.

## 6. Vérifications

Les six commandes du dépôt ; `verifier_jetons` 18 ; `verifier_revue` sans clé nouvelle.

## 7. Pièges connus

- Ne jamais réintroduire la clé d'objet dans le client (la fonction Edge refuse `object_key`).
- Lire le constructeur de `FunctionException` dans la version de `pubspec.lock`.

## 8. Quand s'arrêter et demander

- Si un test exige que l'URL ou la clé apparaisse dans le détail : s'arrêter, c'est contraire à AD-7.

## 9. Commit

- Branche : `lots/L2-02R-tests-porte`, partie de `lots/V2-candidate`.
- Message : `fix(dossiers): erreurs de piece-identite-acces traduites, tests alignes sur le document_id (L2-02-reprise)`.

## 10. Modèle conseillé

Haiku suffit.
