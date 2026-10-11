# Inventaire PROD des fonctions SECURITY DEFINER

`SECURITY_DEFINER_INVENTORY_PROD_2026-10-11.json` conserve un relevé en lecture seule du catalogue PROD `gggmtelinlpseweouyav`, observé le 11 octobre 2026. Il contient 141 fonctions du schéma `public`, leur signature SQL, `md5(prosrc)`, propriétaire, `search_path` et privilèges effectifs de `anon`, `authenticated` et `agent_ro`.

## État de validation

Ce fichier est un inventaire, **pas une allowlist approuvée**. Les 141 entrées portent `classification: UNREVIEWED`, `reviewer: null` et `reviewed_at: null`. Aucun RPC nouveau ou modifié ne peut être considéré comme accepté sur cette base. Le contrôle doit échouer pour chaque entrée non revue, signature absente, surcharge inconnue, empreinte différente, propriétaire incorrect ou `search_path` non fixé.

L’inventaire ne contient pas les corps de fonctions ni une conclusion de sécurité. Une signature dont l’empreinte est inchangée n’est pas pour autant une approbation. La revue doit classer la garde réelle (`ROLE_POSITIVE_TEMPLATE`, `NO_GUARD_HELPER` avec justification, ou `TRIGGER_INVOKER`) et renseigner relecteur et date après inspection du corps exact.

## Conditions minimales du gate F79

- Comparer toutes les fonctions `SECURITY DEFINER` de `public` et `app_private` par signature et `md5(prosrc)`; tout ajout, retrait, surcharge ou changement de hash échoue par défaut.
- Les fonctions `ROLE_POSITIVE_TEMPLATE` doivent commencer par l’un des gabarits positifs et null-safe approuvés par F79. Le scanner doit masquer commentaires et chaînes, et refuser les gardes après un DML, dans une branche morte ou hors du premier bloc exécutable.
- Les fonctions classées `NO_GUARD_HELPER` exigent une justification spécifique à leur rôle. Les triggers doivent rester `SECURITY INVOKER`.
- `search_path` doit être explicitement fixé et l’owner attendu contrôlé. Chaque signature exige classification, relecteur et date non vides.
- Les tests négatifs P02–P19 et P21–P24, signatures inconnues/surcharges/hash modifiés, et triggers SECURITY DEFINER doivent échouer. P00/P25/P29–P32, les helpers approuvés et les exceptions exactes `etat_presence` et `ressources_du_groupe` doivent réussir.

F79 a demandé un contrôle en CI et en postflight. L’ajout de ces fichiers ne livre pas encore ce contrôle exécutable, ne corrige pas les 20 gardes négatives restant dans le candidat SEC-PROD, et ne lève pas le verdict `NON PRÊT`. Aucun SQL n’a été exécuté sur PROD ou STAGING.

## Gate local de comparaison (composant partiel)

`tool/security_definer_gate/catalog.sql` exporte en lecture seule les fonctions `SECURITY DEFINER` de `public` et `app_private`, leurs hashes, corps `prosrc`, propriétaires, `search_path`, ACL effectives, ainsi que les fonctions trigger. Le flux JSON inclut les corps pour l’analyse locale : le passer directement par stdin à `verify_allowlist.py`, sans le rediriger dans un fichier. `verify_allowlist.py` compare signature/hash/ACL/propriétaire/search_path au manifeste et, pour `ROLE_POSITIVE_TEMPLATE`, vérifie que le premier statement PL/pgSQL est exactement le garde positif et null-safe reconnu, avant un `RAISE EXCEPTION`. Il ignore les commentaires et traite les littéraux comme opaques. Il refuse les corps absents, les DML antérieurs, les gardes imbriqués, les gardes dans des chaînes/commentaires, les fallbacks non `false`, les formes de rôle non reconnues, et les fonctions trigger `SECURITY DEFINER`. Le script ne se connecte pas à la base et ne contient aucune clé.

Exemple après application du lot candidat sur une base PostgreSQL jetable :

```powershell
psql -X -A -t -v ON_ERROR_STOP=1 -v project_ref=gggmtelinlpseweouyav `
  -f tool/security_definer_gate/catalog.sql |
  python tool/security_definer_gate/verify_allowlist.py `
    --manifest docs/backend/SECURITY_DEFINER_INVENTORY_PROD_2026-10-11.json `
    --catalog - --project-ref gggmtelinlpseweouyav
python -m unittest discover -s tool/security_definer_gate/tests -v
```

Le scanner reconnaît volontairement une grammaire étroite : `IF NOT COALESCE(...) THEN RAISE EXCEPTION`, avec `public.app_account_valid()` ET `public.app_role()` comparé par `=` à un littéral ou par `IN` à des littéraux, dans l’un ou l’autre ordre. Une garde valide exprimée autrement échoue jusqu’à ajout explicite d’un gabarit et de cas de test; aucune approbation n’est déduite par heuristique. Les fixtures testées ne prouvent pas la correction du catalogue distant ni l’exhaustivité de tous les motifs P02–P32.

Le manifeste actuel est `INVENTORY_ONLY_NOT_ALLOWLIST` et chaque entrée est `UNREVIEWED`; le gate doit donc refuser son utilisation. Cette comparaison ne remplace ni la revue manuelle des corps hashés, ni les scénarios positifs/négatifs du scanner de gardes, ni le branchement CI/postflight exigé par F79. Ce composant est partiel et ne change rien à distance.
