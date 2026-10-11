-- F79: keep KYC completion within the authenticated insert's RLS boundary.
-- The trigger needs only the caller's visible profile row and the existing
-- typed retention helper; it must not execute as its owner.
create or replace function public.completer_kyc_document()
returns trigger
language plpgsql security invoker set search_path = ''
as $$
declare
  v_genre public.gender;
begin
  if new.purge_at is null then
    new.purge_at := now() + make_interval(days =>
      public.app_config_int('kyc_retention_days', 90));
  end if;

  select p.gender into v_genre
  from public.profiles p
  where p.id = new.profile_id and p.deleted_at is null;

  if v_genre is null then
    raise exception 'genre du titulaire inconnu : impossible de classer ce dossier';
  end if;

  new.gender := v_genre;
  return new;
end;
$$;

-- Trigger invocation itself does not require a client EXECUTE grant. Keep the
-- function internal; CREATE TRIGGER was established by the owning role in 0004.
revoke execute on function public.completer_kyc_document()
  from public, anon, authenticated, service_role, agent_ro;

do $verification$
begin
  if (select p.prosecdef
      from pg_catalog.pg_proc p
      where p.oid = 'public.completer_kyc_document()'::regprocedure) then
    raise exception '0049 incomplete: KYC trigger is still SECURITY DEFINER';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_proc p
    where p.oid = 'public.completer_kyc_document()'::regprocedure
      and p.proconfig @> array['search_path=""']
  ) then
    raise exception '0049 incomplete: KYC trigger search_path is not empty';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_trigger t
    where t.tgrelid = 'public.kyc_documents'::regclass
      and t.tgname = 'kyc_documents_completer'
      and t.tgenabled <> 'D'
  ) then
    raise exception '0049 incomplete: KYC completion trigger is missing or disabled';
  end if;

  if has_function_privilege('anon', 'public.completer_kyc_document()', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.completer_kyc_document()', 'EXECUTE')
     or has_function_privilege('service_role', 'public.completer_kyc_document()', 'EXECUTE')
     or has_function_privilege('agent_ro', 'public.completer_kyc_document()', 'EXECUTE') then
    raise exception '0049 incomplete: a client/service role can execute the KYC trigger function';
  end if;
end
$verification$;
