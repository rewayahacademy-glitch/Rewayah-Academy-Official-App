-- 0074 — fermer les gardes NULL restantes dans les fonctions SECURITY DEFINER.
-- Les migrations historiques contrôlaient parfois un rôle par
-- « app_role() <> 'admin' ». Sans rôle, NULL <> 'admin' vaut NULL et IF NULL
-- n'entre pas dans la branche de refus. 0067 ne couvrait qu'une liste fermée
-- et une forme de garde; cette migration balaie les fonctions réellement
-- installées, y compris les RPC créées après cette liste.
begin;

do $migration$
declare
  v record;
  v_definition text;
  v_corrigee text;
  v_modifiees integer := 0;
begin
  for v in
    select distinct p.oid
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    join pg_catalog.pg_language lang on lang.oid = p.prolang
    where n.nspname = 'public'
      and p.prokind = 'f'
      and p.prosecdef
      and lang.lanname = 'plpgsql'
      and exists (
        select 1
        from pg_catalog.regexp_split_to_table(p.prosrc, E'\n') as ligne(texte)
        where pg_catalog.btrim(ligne.texte) ~* '^if.*app_role.*(<>|not[[:space:]]+in)'
      )
  loop
    v_definition := pg_catalog.pg_get_functiondef(v.oid);

    -- Un rôle attendu devient une exigence positive. COALESCE transforme le
    -- NULL produit par un JWT sans app_metadata.role en refus certain.
    v_corrigee := pg_catalog.regexp_replace(
      v_definition,
      '(?i)(public[.])?app_role[(][)][[:space:]]*<>[[:space:]]*''([^'']+)''',
      'NOT coalesce(public.app_role() = ''\2'' AND public.app_account_valid(), false)',
      'gi'
    );

    -- Même défaut pour les gardes « NOT IN », notamment admin/controller.
    v_corrigee := pg_catalog.regexp_replace(
      v_corrigee,
      '(?i)(public[.])?app_role[(][)][[:space:]]+NOT[[:space:]]+IN[[:space:]]*[(]([^)]*)[)]',
      'NOT coalesce(public.app_role() IN (\2) AND public.app_account_valid(), false)',
      'gi'
    );

    if v_corrigee = v_definition then
      raise exception 'B2 : garde à rôle négative non réécrite dans la fonction oid=%', v.oid;
    end if;

    execute v_corrigee;
    v_modifiees := v_modifiees + 1;
  end loop;

  if v_modifiees = 0 then
    raise exception 'B2 : aucune fonction SECURITY DEFINER corrigée';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    join pg_catalog.pg_language lang on lang.oid = p.prolang
    where n.nspname = 'public'
      and p.prokind = 'f'
      and p.prosecdef
      and lang.lanname = 'plpgsql'
      and exists (
        select 1
        from pg_catalog.regexp_split_to_table(p.prosrc, E'\n') as ligne(texte)
        where pg_catalog.btrim(ligne.texte) ~* '^if.*app_role.*(<>|not[[:space:]]+in)'
      )
  ) then
    raise exception 'B2 : une garde négative subsiste dans une fonction SECURITY DEFINER';
  end if;

  raise notice 'B2 : % fonctions SECURITY DEFINER mises en garde positive', v_modifiees;
end
$migration$;

commit;
