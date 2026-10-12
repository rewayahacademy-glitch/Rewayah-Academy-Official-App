begin;

alter table private.preinscription_households
  add column linked_auth_user_id uuid references auth.users(id) on delete set null,
  add column linked_at timestamptz;

create unique index preinscription_households_linked_auth_user_uq
  on private.preinscription_households(linked_auth_user_id)
  where linked_auth_user_id is not null;

create or replace function public.reclamer_preinscription_apres_preuve()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_email text;
  v_email_confirmed_at timestamptz;
  v_household_id uuid;
  v_linked_uid uuid;
  v_welcome text;
  v_patience text;
  v_people jsonb;
  v_newly_linked boolean := false;
begin
  -- A missing/unconfirmed Auth identity receives the same shape whether or not
  -- its email exists in the pre-registration import. Do not query that table yet.
  if v_uid is null then
    return pg_catalog.jsonb_build_object('email_prouve', false, 'inscription_connue', false);
  end if;
  select lower(btrim(u.email)), u.email_confirmed_at
    into v_email, v_email_confirmed_at
    from auth.users as u
   where u.id = v_uid;
  if not found or v_email is null or v_email_confirmed_at is null then
    return pg_catalog.jsonb_build_object('email_prouve', false, 'inscription_connue', false);
  end if;

  select h.id, h.linked_auth_user_id, h.mot_accueil, h.mot_patience
    into v_household_id, v_linked_uid, v_welcome, v_patience
    from private.preinscription_households as h
   where h.email_normalise = v_email
   for update;
  if not found or (v_linked_uid is not null and v_linked_uid <> v_uid) then
    return pg_catalog.jsonb_build_object('email_prouve', true, 'inscription_connue', false);
  end if;

  if v_linked_uid is null then
    begin
      update private.preinscription_households
         set linked_auth_user_id = v_uid,
             linked_at = pg_catalog.statement_timestamp()
       where id = v_household_id;
      v_newly_linked := true;
    exception when unique_violation then
      -- One Auth account must not claim a second pre-registration household.
      return pg_catalog.jsonb_build_object('email_prouve', true, 'inscription_connue', false);
    end;
  end if;

  select coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', p.id,
        'prenom', p.first_name,
        'type', p.person_kind,
        'etat', 'a_completer'
      ) order by p.source_row, p.id
    ), '[]'::jsonb
  ) into v_people
    from private.preinscription_persons as p
   where p.household_id = v_household_id;

  if v_newly_linked then
    perform public.log_sensitive_access(
      'preinscription_claimed', 'preinscription_households', null,
      pg_catalog.jsonb_build_object('persons_revealed', pg_catalog.jsonb_array_length(v_people))
    );
  end if;

  return pg_catalog.jsonb_build_object(
    'email_prouve', true,
    'inscription_connue', true,
    'message_accueil', case when v_newly_linked then v_welcome else null end,
    'message_patience', case when v_newly_linked then v_patience else null end,
    'personnes', v_people
  );
end;
$function$;
alter function public.reclamer_preinscription_apres_preuve() owner to postgres;
revoke all on function public.reclamer_preinscription_apres_preuve()
  from public, anon, service_role;
grant execute on function public.reclamer_preinscription_apres_preuve() to authenticated;
comment on function public.reclamer_preinscription_apres_preuve() is
  'Rattache le foyer pré-inscrit à auth.uid() seulement après confirmation Auth de son adresse email; aucune donnée pré-inscrite avant preuve.';

do $verification$
begin
  if has_function_privilege('anon', 'public.reclamer_preinscription_apres_preuve()', 'execute')
     or has_function_privilege('service_role', 'public.reclamer_preinscription_apres_preuve()', 'execute')
     or not has_function_privilege('authenticated', 'public.reclamer_preinscription_apres_preuve()', 'execute') then
    raise exception 'IMM-ACCUEIL phase 3: claim RPC ACL incorrecte';
  end if;
  if exists (
    select 1 from pg_catalog.pg_proc p
     where p.oid = 'public.reclamer_preinscription_apres_preuve()'::regprocedure
       and (not p.prosecdef or p.proowner <> 'postgres'::regrole
         or not (p.proconfig @> array['search_path=""']))
  ) then
    raise exception 'IMM-ACCUEIL phase 3: claim RPC definer configuration incorrecte';
  end if;
end;
$verification$;

commit;
