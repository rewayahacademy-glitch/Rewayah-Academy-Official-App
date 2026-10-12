-- RECH-BACK-3: exact RA lookup with one account-wide quota shared across D1 searches.
-- The quota never stores search input.
begin;

create or replace function private.rech_recherche_quota_ok()
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_bucket text;
  v_available real;
  v_updated_at timestamptz;
begin
  if auth.uid() is null then
    return false;
  end if;

  -- Proposal pending product confirmation: burst 10, then one token per minute.
  -- Hash the actor id so the shared limiter does not persist a direct identifier.
  v_bucket := 'rech:all:' || pg_catalog.md5(auth.uid()::text);

  insert into public.rate_limits (bucket, tokens, updated_at)
  values (v_bucket, 10.0, pg_catalog.statement_timestamp())
  on conflict (bucket) do nothing;

  select r.tokens, r.updated_at
    into v_available, v_updated_at
    from public.rate_limits r
   where r.bucket = v_bucket
   for update;

  v_available := least(
    10.0::real,
    greatest(
      0.0::real,
      v_available + greatest(
        0.0::real,
        (pg_catalog.date_part('epoch',
          pg_catalog.statement_timestamp() - v_updated_at) / 60.0)::real
      )
    )
  );

  if v_available < 1.0 then
    -- Persist both the partial refill and its new anchor. Keeping only one
    -- would count the same elapsed interval again on each denied request.
    update public.rate_limits r
       set tokens = v_available
         , updated_at = pg_catalog.statement_timestamp()
     where r.bucket = v_bucket;
    return false;
  end if;

  update public.rate_limits
     set tokens = v_available - 1.0
       , updated_at = pg_catalog.statement_timestamp()
   where bucket = v_bucket;
  return true;
end;
$function$;

alter function private.rech_recherche_quota_ok() owner to postgres;
revoke all on function private.rech_recherche_quota_ok()
  from public, anon, authenticated, service_role;

create or replace function public.rechercher_personne_par_matricule(p_saisie text)
returns table (
  profile_id uuid,
  matricule text,
  first_name text,
  last_name text,
  role public.app_role
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_compact text;
  v_saisie text;
  v_matricule text;
begin
  if auth.uid() is null or not public.rech_session_autorisee() then
    return;
  end if;

  -- Consume before parsing so malformed guesses are charged identically.
  if not private.rech_recherche_quota_ok() then
    return;
  end if;

  v_saisie := pg_catalog.upper(pg_catalog.regexp_replace(
    coalesce(p_saisie, ''), '^[[:space:]]+|[[:space:]]+$', '', 'g'
  ));
  if v_saisie !~ '^RA[-[:space:]]?[0-9]{2}[-[:space:]]?[0-9]{4,5}$' then
    return;
  end if;
  v_compact := pg_catalog.regexp_replace(v_saisie, '[-[:space:]]', '', 'g');
  v_matricule := 'RA-' || pg_catalog.substr(v_compact, 3, 2) || '-'
    || pg_catalog.substr(v_compact, 5);

  return query
    select p.id, r.matricule, p.first_name, p.last_name, p.role
      from private.person_registrations r
      join public.profiles p on p.id = r.profile_id
     where r.matricule = v_matricule
       and p.deleted_at is null
       and public.partie_concernee(p.id);
end;
$function$;

-- Use the same actor bucket for the existing D1 class and support RPCs.
-- The checked replacement point keeps the deployed response shape unchanged.
do $inject_d1_quota$
declare
  v_signature regprocedure;
  v_definition text;
  v_guard text := $guard$
  if auth.uid() is null or not public.rech_session_autorisee() then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;$guard$;
  v_replacement text;
begin
  v_replacement := v_guard || E'
    if not private.rech_recherche_quota_ok() then
      return pg_catalog.jsonb_build_object(
        ''items'', ''[]''::jsonb, ''has_more'', false, ''next_cursor'', null
      );
    end if;';

  foreach v_signature in array array[
    'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure,
    'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure
  ] loop
    v_definition := pg_catalog.pg_get_functiondef(v_signature);
    if position('private.rech_recherche_quota_ok()' in v_definition) > 0 then
      raise exception 'RECH-BACK-3: D1 quota already present before migration';
    end if;
    if position(v_guard in v_definition) = 0 then
      raise exception 'RECH-BACK-3: unexpected D1 session guard; refusing rewrite';
    end if;
    v_definition := pg_catalog.replace(v_definition, v_guard, v_replacement);
    if position('private.rech_recherche_quota_ok()' in v_definition) = 0 then
      raise exception 'RECH-BACK-3: failed to inject the shared D1 quota';
    end if;
    execute v_definition;
  end loop;
end;
$inject_d1_quota$;

alter function public.rechercher_personne_par_matricule(text) owner to postgres;
revoke all on function public.rechercher_personne_par_matricule(text)
  from public, anon, service_role;
grant execute on function public.rechercher_personne_par_matricule(text)
  to authenticated;
comment on function public.rechercher_personne_par_matricule(text) is
  'Exact authorized RA lookup; unknown, invalid, out-of-scope and quota-denied inputs return the same empty result. One actor quota is shared with RECH-D1 classes and supports searches; raw input is never stored.';

do $verification$
begin
  if has_function_privilege('anon', 'private.rech_recherche_quota_ok()', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.rech_recherche_quota_ok()', 'EXECUTE')
     or has_function_privilege('service_role', 'private.rech_recherche_quota_ok()', 'EXECUTE')
     or has_function_privilege('anon', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or has_function_privilege('service_role', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.rechercher_personne_par_matricule(text)', 'EXECUTE')
     or exists (
       select 1 from pg_catalog.pg_proc p
        where p.oid in (
          'private.rech_recherche_quota_ok()'::regprocedure,
          'public.rechercher_personne_par_matricule(text)'::regprocedure,
          'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure,
          'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure
        )
          and (not p.prosecdef
            or p.proowner <> 'postgres'::regrole
            or not (p.proconfig @> array['search_path=""']))
     ) then
    raise exception 'RECH-BACK-3: lookup, D1 RPC or quota ACL/definer configuration is incorrect';
  end if;
  if exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid in (
       'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure,
       'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure
     )
       and position('private.rech_recherche_quota_ok()' in pg_catalog.pg_get_functiondef(p.oid)) = 0
  ) then
    raise exception 'RECH-BACK-3: D1 RPC is missing the shared account quota';
  end if;
end;
$verification$;

commit;
