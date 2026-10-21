# Backend — Supabase

Contrat : `docs/current/02_ARCHITECTURE_ET_SECURITE.md`. Avant toute migration,
inspecter le schéma et les données réels (`list_tables`, `list_migrations`) ; ne pas
réappliquer mécaniquement un ancien plan SQL. Vérifier `get_project_url` avant toute
écriture : le MCP a déjà visé un autre projet.

## Rappels non négociables

- RLS activée sur toutes les tables, sans exception. Une UI cachée ne remplace jamais
  une policy. La RLS borne les lignes, pas les colonnes.
- Toute fonction `SECURITY DEFINER` fixe `search_path = ''` et qualifie chaque objet.
  Le garde dit qui entre ; il ne rejoue pas la policy de la table.
- Une porte SQL s'écrit en exigence positive (`if not autorise then raise`), jamais
  `if role <> 'x'` : NULL ne déclenche pas le `if`.
- `EXECUTE` arrive par deux chemins : `revoke ... from public` **et** `from anon`.
  Seul `has_function_privilege` le prouve. `agent_ro` n'a jamais de droit d'écriture.
- Le rôle et le foyer se lisent depuis le JWT, jamais par une sous-requête sur
  `profiles`. Le hook de jeton ne doit jamais rendre `null` (`to_jsonb`/`jsonb_set`
  sont stricts).
- L'argent est un entier en unité mineure. `audit_logs` est append-only.
- Migrations additives et numérotées ; jamais modifier une migration déjà appliquée.
  Attention aux collisions de numéro entre branches : `0043_offres_horaires` est sur
  `main`, une autre `0043` (jeton vidéo, correctif de `0042`) reste non intégrée et
  archivée hors dépôt.
- Une fonction Edge s'ouvre par fonction dans `config.toml`, jamais par
  `--no-verify-jwt` global.
- Mesurer une RPC en production sans laisser de ligne : bloc `DO` qui monte la
  fixture, appelle, puis annule par un `raise` final.
