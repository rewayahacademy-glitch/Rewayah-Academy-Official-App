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
