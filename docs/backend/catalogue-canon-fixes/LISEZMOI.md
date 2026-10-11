# Catalogue actif de codex/backend-canon-fixes @ ea1a0da9

Extrait sur un Postgres 16.15 local (loopback) apres `supabase/tests/stub_auth.sql` puis les 102 migrations dans l'ordre du glob, `ON_ERROR_STOP=1`, sans erreur. Schema `public`, 412 fonctions (204 SECURITY DEFINER).

- `INDEX.csv` : signature (`oid::regprocedure`) ; definer (t/f) ; volatilite ; acl (`proacl`) ; md5 de `pg_get_functiondef` ; fichier.
- un `.sql` par fonction : texte complet de `pg_get_functiondef`, nom = signature normalisee (minuscules, non alphanumerique remplace par `_`).
- Analyses : `../F86_GARDES_CANDIDATS.md`, `../SEC_PROD_27.md`.

Documentation seule. Ce n'est pas une migration et ne reflete pas PROD (ledger 0042).
