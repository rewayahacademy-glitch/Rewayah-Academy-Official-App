-- RECH-BACK-2 follow-up: keep private schema closed and expose only the two
-- caller-bound cursor operations required by the SECURITY INVOKER searches.
begin;

revoke usage on schema private from authenticated;

create or replace function public.rech_d1_curseur_lire(
  p_token uuid,
  p_domaine text,
  p_query_hash text,
  p_authorization_version bigint
)
returns table (after_kind text, after_id uuid)
language sql
volatile
security definer
set search_path = ''
as $function$
  select c.after_kind, c.after_id
    from private.rech_d1_curseur_lire(
      p_token, p_domaine, p_query_hash, p_authorization_version
    ) c;
$function$;

create or replace function public.rech_d1_curseur_creer(
  p_domaine text,
  p_query_hash text,
  p_after_kind text,
  p_after_id uuid,
  p_authorization_version bigint
)
returns uuid
language sql
volatile
security definer
set search_path = ''
as $function$
  select private.rech_d1_curseur_creer(
    p_domaine, p_query_hash, p_after_kind, p_after_id, p_authorization_version
  );
$function$;

alter function private.rech_d1_curseur_lire(uuid, text, text, bigint) owner to postgres;
revoke all on function private.rech_d1_curseur_lire(uuid, text, text, bigint)
  from public, anon, authenticated, service_role;

create or replace function private.rech_d1_curseur_creer(
  p_domaine text,
  p_query_hash text,
  p_after_kind text,
  p_after_id uuid,
  p_authorization_version bigint
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_token uuid;
  v_authorization_version bigint;
begin
  if auth.uid() is null or not public.rech_session_autorisee()
     or p_domaine is null or p_domaine not in ('classes', 'supports')
     or p_query_hash is null or p_query_hash !~ '^[0-9a-f]{32}$'
     or p_after_id is null
     or p_authorization_version is null
     or (p_domaine = 'classes' and p_after_kind not in ('groupe', 'offre'))
     or (p_domaine = 'supports' and p_after_kind <> 'support') then
    raise exception 'RechercheCurseurInvalide' using errcode = '22023';
  end if;
  select p.authorization_version into v_authorization_version
    from public.profiles p where p.id = auth.uid();
  if v_authorization_version is distinct from p_authorization_version then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('rech-d1-cursor:' || auth.uid()::text, 0)
  );
  delete from private.rech_d1_curseurs c
   where c.caller_id = auth.uid()
     and c.expires_at <= pg_catalog.statement_timestamp();
  if (select pg_catalog.count(*) from private.rech_d1_curseurs c
       where c.caller_id = auth.uid()) >= 20 then
    raise exception 'RechercheCurseurQuota' using errcode = '54000';
  end if;
  insert into private.rech_d1_curseurs
    (caller_id, domaine, query_hash, after_kind, after_id,
     authorization_version, expires_at)
  values
    (auth.uid(), p_domaine, p_query_hash, p_after_kind, p_after_id,
     p_authorization_version, pg_catalog.statement_timestamp() + interval '5 minutes')
  returning token into v_token;
  return v_token;
end;
$function$;

alter function private.rech_d1_curseur_creer(text, text, text, uuid, bigint) owner to postgres;
revoke all on function private.rech_d1_curseur_creer(text, text, text, uuid, bigint)
  from public, anon, authenticated, service_role;

do $rewrite$
declare
  v_definition text;
begin
  select pg_catalog.pg_get_functiondef(
    'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure
  ) into v_definition;
  if position('private.rech_d1_curseur_' in v_definition) = 0 then
    raise exception 'RECH-D1: definition classes inattendue pendant la correction';
  end if;
  v_definition := pg_catalog.replace(v_definition,
    'private.rech_d1_curseur_lire', 'public.rech_d1_curseur_lire');
  v_definition := pg_catalog.replace(v_definition,
    'private.rech_d1_curseur_creer', 'public.rech_d1_curseur_creer');
  execute v_definition;

  select pg_catalog.pg_get_functiondef(
    'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure
  ) into v_definition;
  if position('private.rech_d1_curseur_' in v_definition) = 0 then
    raise exception 'RECH-D1: definition supports inattendue pendant la correction';
  end if;
  v_definition := pg_catalog.replace(v_definition,
    'private.rech_d1_curseur_lire', 'public.rech_d1_curseur_lire');
  v_definition := pg_catalog.replace(v_definition,
    'private.rech_d1_curseur_creer', 'public.rech_d1_curseur_creer');
  execute v_definition;
end;
$rewrite$;

alter function public.rech_d1_curseur_lire(uuid, text, text, bigint) owner to postgres;
alter function public.rech_d1_curseur_creer(text, text, text, uuid, bigint) owner to postgres;
revoke all on function public.rech_d1_curseur_lire(uuid, text, text, bigint)
  from public, anon, service_role;
revoke all on function public.rech_d1_curseur_creer(text, text, text, uuid, bigint)
  from public, anon, service_role;
grant execute on function public.rech_d1_curseur_lire(uuid, text, text, bigint)
  to authenticated;
grant execute on function public.rech_d1_curseur_creer(text, text, text, uuid, bigint)
  to authenticated;

do $postflight$
begin
  if has_schema_privilege('authenticated', 'private', 'USAGE')
     or has_function_privilege('authenticated',
       'private.rech_d1_curseur_lire(uuid,text,text,bigint)', 'EXECUTE')
     or has_function_privilege('authenticated',
       'private.rech_d1_curseur_creer(text,text,text,uuid,bigint)', 'EXECUTE')
     or has_function_privilege('anon',
       'public.rech_d1_curseur_lire(uuid,text,text,bigint)', 'EXECUTE')
     or has_function_privilege('service_role',
       'public.rech_d1_curseur_creer(text,text,text,uuid,bigint)', 'EXECUTE') then
    raise exception 'RECH-D1: ACL de curseur expose private ou schema interne';
  end if;
  if not has_function_privilege('authenticated',
       'public.rech_d1_curseur_lire(uuid,text,text,bigint)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.rech_d1_curseur_creer(text,text,text,uuid,bigint)', 'EXECUTE') then
    raise exception 'RECH-D1: wrappers de curseur manquants';
  end if;
end;
$postflight$;

commit;
