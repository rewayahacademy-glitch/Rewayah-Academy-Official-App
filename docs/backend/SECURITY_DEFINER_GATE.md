# Gate SECURITY DEFINER fail-closed (F79)

`tool/security_definer_gate/catalog.sql` lit le catalogue PostgreSQL; il ne modifie aucune donnée. Sa sortie JSON doit être transmise directement sur stdin à `verify_allowlist.py`, sans écrire les corps `prosrc` dans un fichier ni dans une feuille partagée.

Le vérificateur exige un manifeste versionné (`manifest_version` positive), lié au projet et au nom de la base, marqué `APPROVED_ALLOWLIST`, qui couvre exactement toutes les signatures SECURITY DEFINER de `public` et `app_private`. Pour chaque entrée, il compare l'empreinte MD5 du corps, la classification, le propriétaire `postgres`, `search_path` vide, les privilèges effectifs des rôles app, l'ACL EXECUTE directe complète (y compris PUBLIC) et tous les rôles ayant EXECUTE par héritage. Toute fonction manquante, ajoutée, surchargée ou modifiée échoue. Les fonctions classées `ROLE_POSITIVE_TEMPLATE` doivent commencer par un garde positif null-safe reconnu; les `NO_GUARD_HELPER` exigent une justification revue. Les fonctions trigger SECURITY DEFINER font échouer le gate.

Le scanner n'accepte qu'une grammaire étroite: premier statement exécutable `IF NOT COALESCE(...) THEN RAISE EXCEPTION`, avec `app_account_valid()` et `app_role()` comparé par égalité ou par `IN` à des littéraux, et fallback `false`. Les commentaires et chaînes ne comptent pas comme code. Toute autre forme nécessite un nouveau gabarit explicitement testé avant approbation.

Lancement prévu sur une base PostgreSQL jetable après application des migrations candidates:

```powershell
psql -X -A -t -v ON_ERROR_STOP=1 -v project_ref=<ref-attendu> `
  -f tool/security_definer_gate/catalog.sql |
  python tool/security_definer_gate/verify_allowlist.py `
    --manifest <manifeste-revu.json> --catalog - --project-ref <ref-attendu>
python -m unittest discover -s tool/security_definer_gate/tests -v
```

Le test unitaire du scanner couvre P02–P24 de F71; le vérificateur couvre les signatures inconnues, hash modifiés, grants PUBLIC/inherited, owner inattendu, manifeste non revu et triggers SECURITY DEFINER. Ces tests unitaires ne prouvent pas que la requête SQL s'exécute sur PostgreSQL, ni que l'inventaire reflète PROD.

## État de livraison

L'inventaire snapshot du 11/10/2026 sur la branche candidate `codex/backend-sec-prod-allowlist` est `INVENTORY_ONLY_NOT_ALLOWLIST`, avec 141 fonctions `UNREVIEWED` et sans l'ACL complète ajoutée par ce gate. Il ne peut pas passer et doit être réexporté puis revu. La CI/postflight n'est pas branchée ici: le dépôt courant réserve `.github/` au flux propriétaire CI. Le gate est donc un composant testé en local, pas un feu vert pour ajouter ou modifier une fonction SECURITY DEFINER. Pas de rejeu PG17, aucun accès distant effectué par ce lot, et aucune donnée STAGING/PROD modifiée.
