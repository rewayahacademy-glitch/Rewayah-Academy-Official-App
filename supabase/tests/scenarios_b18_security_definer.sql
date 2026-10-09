-- Scénarios négatifs B-18 / 0044.
-- À exécuter après toutes les migrations sur PostgreSQL jetable seulement.
begin;
select set_config('request.jwt.claims', '{}', true);

set local role anon;
do $$
begin
  if pg_catalog.has_function_privilege('anon', 'public.comptes_admin()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.read_kyc_documents()', 'execute') then
    raise exception 'B-18: anon retains EXECUTE on a protected RPC';
  end if;
end $$;
reset role;

set local role authenticated;
do $$
declare
  v_rows integer;
begin
  select count(*) into v_rows from public.comptes_admin();
  if v_rows <> 0 then
    raise exception 'B-18: comptes_admin exposed rows with no app role';
  end if;
  begin
    perform public.creer_groupe(null::uuid, null::text, null::text, null::smallint, null::smallint, null::smallint, null::text, null::smallint);
    raise exception 'B-18: long creer_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'creation de groupe reservee a l''administration' then raise; end if;
  end;
  -- PostgreSQL ne peut pas résoudre l'appel à 6 arguments: la surcharge
  -- longue accepte aussi ces arguments grâce à ses deux paramètres DEFAULT.
  -- Vérifie donc la garde sur la signature courte exacte dans pg_proc.
  if position(
       'if not coalesce(public.app_role() = ''admin'' and public.app_account_valid(), false)'
       in pg_catalog.pg_get_functiondef(
         'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)'::regprocedure
       )
     ) = 0 then
    raise exception 'B-18: short creer_groupe overload lacks the admin guard';
  end if;
  begin
    perform public.modifier_groupe(null::uuid, null::text, null::smallint, null::smallint, null::smallint, null::text, null::smallint);
    raise exception 'B-18: long modifier_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.modifier_groupe(null::uuid, null::text, null::smallint, null::smallint, null::smallint);
    raise exception 'B-18: short modifier_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform 1 from public.read_kyc_documents();
    raise exception 'B-18: read_kyc_documents accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'acces KYC refuse' then raise; end if;
  end;
end $$;
reset role;

set local role agent_ro;
do $$
begin
  if pg_catalog.has_function_privilege('agent_ro', 'public.comptes_admin()', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'execute') then
    raise exception 'B-18: agent_ro retains EXECUTE on a protected RPC';
  end if;
end $$;
reset role;
rollback;
