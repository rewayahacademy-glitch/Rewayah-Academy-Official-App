-- F70 / C-15 / C-16: serve and record the exact current teacher contract.
-- Published text is intentionally not seeded here: the validated full legal
-- text is not present in this checkout. Until an approved body is inserted by
-- a migration, contrat_courant has no row and signing remains unavailable.

create table public.contract_texts (
  contract_kind text not null check (contract_kind = 'teacher_nda'),
  version text not null check (length(version) between 1 and 80),
  locale text not null check (locale = 'fr'),
  body text not null check (length(body) > 0),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (contract_kind, version, locale),
  check (
    sha256 = encode(extensions.digest(convert_to(body, 'UTF8'), 'sha256'), 'hex')
  )
);

create unique index contract_texts_one_current_per_locale
  on public.contract_texts (contract_kind, locale)
  where is_current;

alter table public.contract_texts enable row level security;
create policy contract_texts_published_read on public.contract_texts
  for select to authenticated using (is_current and locale = 'fr');

revoke all on public.contract_texts from public, anon, authenticated, service_role, agent_ro;
grant select on public.contract_texts to authenticated;

alter table public.contract_acceptances
  add column signed_sha256 text,
  add column signer_name text;

-- Keep the historical read path and legacy guardian/notice inserts. For the
-- teacher contract, only an active published French version can be accepted.
drop policy contract_acceptances_self_insert on public.contract_acceptances;
create policy contract_acceptances_self_insert on public.contract_acceptances
  for insert to authenticated with check (
    profile_id = auth.uid()
    and (
      contract_kind <> 'teacher_nda'
      or exists (
        select 1 from public.contract_texts t
        where t.contract_kind = 'teacher_nda'
          and t.version = contract_acceptances.version
          and t.locale = 'fr'
          and t.is_current
      )
    )
  );

-- Column grants prevent clients from choosing the signed body hash or the
-- server timestamp. The BEFORE INSERT trigger fills the hash from the active
-- immutable-by-client contract text and normalizes the supplied name.
revoke insert on public.contract_acceptances
  from public, anon, authenticated, service_role, agent_ro;
grant insert (profile_id, contract_kind, version, signer_name)
  on public.contract_acceptances to authenticated;

create function public.completer_contract_acceptance()
returns trigger
language plpgsql security invoker set search_path = ''
as $$
declare
  v_texte public.contract_texts%rowtype;
begin
  if new.contract_kind <> 'teacher_nda' then
    new.signer_name := null;
    new.signed_sha256 := null;
    return new;
  end if;

  if new.signer_name is null or length(btrim(new.signer_name)) = 0 then
    raise exception using errcode = 'P0001', message = 'nom_vide';
  end if;
  if char_length(btrim(new.signer_name)) > 120 then
    raise exception using errcode = 'P0001', message = 'nom_trop_long';
  end if;

  select t.* into v_texte
  from public.contract_texts t
  where t.contract_kind = 'teacher_nda'
    and t.version = new.version
    and t.locale = 'fr'
    and t.is_current;

  if not found then
    raise exception using errcode = 'P0001', message = 'contrat_version_non_courante';
  end if;

  new.signer_name := btrim(new.signer_name);
  new.signed_sha256 := v_texte.sha256;
  return new;
end;
$$;

create trigger contract_acceptances_complete_signature
before insert on public.contract_acceptances
for each row execute function public.completer_contract_acceptance();

revoke execute on function public.completer_contract_acceptance()
  from public, anon, authenticated, service_role, agent_ro;

create function public.signer_contrat(
  p_version text,
  p_nom_saisi text
) returns public.contract_acceptances
language plpgsql security invoker set search_path = ''
as $$
declare
  v_courant public.contract_texts%rowtype;
  v_signature public.contract_acceptances%rowtype;
  v_uid uuid := auth.uid();
begin
  if not coalesce(
    v_uid is not null
    and public.app_role() = 'teacher'::public.app_role,
    false
  ) then
    raise exception using errcode = '42501', message = 'acces_signature_refusee';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid and p.role = 'teacher'::public.app_role
      and p.deleted_at is null
      and p.account_status in (
        'pending_kyc'::public.account_status,
        'provisional_active'::public.account_status,
        'active'::public.account_status
      )
  ) then
    raise exception using errcode = '42501', message = 'acces_signature_refusee';
  end if;

  if p_nom_saisi is null or length(btrim(p_nom_saisi)) = 0 then
    raise exception using errcode = 'P0001', message = 'nom_vide';
  end if;
  if char_length(btrim(p_nom_saisi)) > 120 then
    raise exception using errcode = 'P0001', message = 'nom_trop_long';
  end if;

  select t.* into v_courant
  from public.contract_texts t
  where t.contract_kind = 'teacher_nda'
    and t.locale = 'fr'
    and t.is_current;

  if not found then
    raise exception using errcode = 'P0002', message = 'contrat_introuvable';
  end if;
  if p_version is distinct from v_courant.version then
    raise exception using
      errcode = 'P0001',
      message = 'version_perimee:' || v_courant.version;
  end if;

  insert into public.contract_acceptances (
    profile_id, contract_kind, version, signer_name
  ) values (
    v_uid, 'teacher_nda', v_courant.version, btrim(p_nom_saisi)
  )
  on conflict (profile_id, contract_kind, version) do nothing
  returning * into v_signature;

  if not found then
    select c.* into v_signature
    from public.contract_acceptances c
    where c.profile_id = v_uid
      and c.contract_kind = 'teacher_nda'
      and c.version = v_courant.version;
  end if;

  if v_signature.id is null or v_signature.signed_sha256 is null
     or v_signature.signer_name is null then
    raise exception 'signature enseignant incomplete';
  end if;
  return v_signature;
end;
$$;

revoke execute on function public.signer_contrat(text, text)
  from public, anon, service_role, agent_ro;
grant execute on function public.signer_contrat(text, text) to authenticated;

comment on table public.contract_texts is
  'Versions françaises publiées des contrats; le sha256 est calculé sur le texte UTF-8 exact.';
comment on column public.contract_acceptances.signed_sha256 is
  'Empreinte SHA-256 du texte courant au moment de la signature; NULL pour les anciennes signatures non prouvées.';
comment on column public.contract_acceptances.signer_name is
  'Nom saisi et normalisé lors de la signature du contrat enseignant; NULL pour les anciennes signatures.';

do $$
begin
  if not (select c.relrowsecurity from pg_class c
          where c.oid = 'public.contract_texts'::regclass) then
    raise exception 'F70 postflight: RLS absente sur contract_texts';
  end if;
  if not has_table_privilege('authenticated', 'public.contract_texts', 'SELECT')
     or has_table_privilege('authenticated', 'public.contract_texts', 'INSERT')
     or has_table_privilege('authenticated', 'public.contract_texts', 'UPDATE')
     or has_table_privilege('authenticated', 'public.contract_texts', 'DELETE') then
    raise exception 'F70 postflight: droits contract_texts inattendus';
  end if;
  if has_column_privilege(
       'authenticated', 'public.contract_acceptances', 'signed_sha256', 'INSERT'
     ) then
    raise exception 'F70 postflight: client peut choisir signed_sha256';
  end if;
  if not has_function_privilege(
       'authenticated', 'public.signer_contrat(text,text)', 'EXECUTE'
     ) or has_function_privilege(
       'anon', 'public.signer_contrat(text,text)', 'EXECUTE'
     ) or has_function_privilege(
       'service_role', 'public.signer_contrat(text,text)', 'EXECUTE'
     ) or has_function_privilege(
       'agent_ro', 'public.signer_contrat(text,text)', 'EXECUTE'
     ) then
    raise exception 'F70 postflight: ACL signer_contrat inattendue';
  end if;
  if has_function_privilege(
       'authenticated', 'public.completer_contract_acceptance()', 'EXECUTE'
     ) or has_function_privilege(
       'anon', 'public.completer_contract_acceptance()', 'EXECUTE'
     ) then
    raise exception 'F70 postflight: le trigger est directement executable';
  end if;
end;
$$;
