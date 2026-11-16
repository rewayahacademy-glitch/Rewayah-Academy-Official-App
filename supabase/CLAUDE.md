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


## Installer une migration en production (directeur, 16/11/2026, consigne 21)

L'agent installe lui-même (`apply_migration`, projet de production `gggmtelinlpseweouyav`), avec
une rigueur absolue : « Make no mistakes in the data base ». Dans cet ordre, sans en sauter une :

1. **Le fichier est dans `main`** (PR fusionnée, CI verte) ; on installe ce fichier-là, mot pour mot,
   jamais une version retouchée à la main.
2. **Relire le fichier en entier.** Refuser et s'arrêter si on y trouve : `DROP`, `DELETE`,
   `TRUNCATE` (seule exception : la réécriture d'un CHECK), `BEGIN` ou `COMMIT` seuls, une
   modification d'une migration déjà installée, un `UPDATE` ou `INSERT` sur des données de personnes
   sans décision écrite du directeur, une table nouvelle sans `ENABLE ROW LEVEL SECURITY`, une
   fonction `SECURITY DEFINER` sans `search_path = ''`, un `GRANT` à `anon` non justifié.
3. **L'horodatage est libre** : aucune autre migration de `supabase/migrations/` ni de
   `supabase_migrations.schema_migrations` ne porte la même version.
4. **Ce qui précède est installé** : les migrations plus anciennes du lot, et leurs dépendances, sont
   présentes en production (lire `supabase_migrations.schema_migrations` et les objets attendus).
5. **Rejouée sur un Postgres nu** (stub_auth, puis toutes les migrations, puis le scénario du lot)
   avant l'installation, ou CI « Migrations applicables » verte sur le commit fusionné.
6. **Installer**, une migration à la fois, dans l'ordre.
7. **Vérifier en production**, en lecture seule : chaque objet créé ou retouché existe (table, colonnes,
   RLS active, politiques, fonctions, droits), et `anon` n'a que ce qu'il doit avoir.
8. **Rendre compte** au directeur et dans la PR : ce qui est installé, ce qui a été vérifié.
9. **En cas d'échec** : ne rien réessayer à l'aveugle, ne jamais « réparer » à la main en production ;
   lire l'erreur, corriger par une nouvelle migration dans une PR, puis reprendre au point 1.
