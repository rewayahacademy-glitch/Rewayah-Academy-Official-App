begin;

alter table public.library_resource
  add column revision integer not null default 1 check (revision > 0),
  add column updated_at timestamptz not null default clock_timestamp();

create or replace function public.cap29_bump_resource_revision()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.revision := old.revision + 1;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;
create trigger cap29_bump_resource_revision
before update on public.library_resource
for each row execute function public.cap29_bump_resource_revision();
revoke all on function public.cap29_bump_resource_revision() from public, anon, authenticated, service_role, agent_ro;

create schema if not exists private;

do $$ begin
  create type private.statut_library_rights_proof as enum ('en_attente', 'confirmee');
exception when duplicate_object then null; end $$;

create table private.library_rights_proofs (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references public.library_resource(id) on delete restrict,
  resource_version_id uuid not null references public.resource_version(id) on delete restrict,
  cle_stockage text not null check (cle_stockage ~ '^private/libraryproof/[0-9a-f-]{36}$'),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  mime text not null check (mime in ('application/pdf','image/jpeg','image/png')),
  taille bigint not null check (taille between 1 and 8388608),
  deposee_par uuid not null references public.profiles(id),
  deposee_le timestamptz not null default clock_timestamp(),
  statut private.statut_library_rights_proof not null default 'en_attente',
  unique (id, resource_version_id, resource_id)
);
alter table private.library_rights_proofs enable row level security;
revoke all on table private.library_rights_proofs from public, anon, authenticated, service_role, agent_ro;

create table public.library_version_rights (
  resource_version_id uuid primary key references public.resource_version(id) on delete cascade,
  source_titre text not null,
  titulaire text not null,
  preuve_id uuid,
  usages text[] not null check (
    cardinality(usages) > 0 and usages <@ array['application','classe','telechargement','hors_ligne']::text[]
  ),
  attribution text not null,
  expire_le timestamptz,
  approuve boolean not null default false,
  revu_par uuid references public.profiles(id),
  revu_le timestamptz,
  resource_id uuid not null references public.library_resource(id) on delete restrict,
  foreign key (preuve_id, resource_version_id, resource_id)
    references private.library_rights_proofs(id, resource_version_id, resource_id) on delete restrict,
  check ((approuve and revu_par is not null and revu_le is not null) or not approuve)
);
alter table public.library_version_rights enable row level security;
grant select on public.library_version_rights to authenticated;
create policy library_version_rights_admin on public.library_version_rights
  for select to authenticated
  using (coalesce(public.app_account_valid() and public.app_role() = 'admin', false))
  ;

create or replace function public.cap29_require_approved_rights()
returns trigger language plpgsql set search_path = '' as $$
declare v_rights public.library_version_rights%rowtype;
begin
  if old.statut = 'brouillon' and new.statut = 'publiee' then
    select * into v_rights from public.library_version_rights r
     where r.resource_version_id = new.id;
    if not found or not v_rights.approuve or v_rights.usages is null
       or cardinality(v_rights.usages) = 0
       or v_rights.expire_le is not null and v_rights.expire_le <= clock_timestamp() then
      raise exception 'CAP-29: droits absents, non approuves ou echus' using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;
create trigger cap29_require_approved_rights
before update of statut on public.resource_version
for each row execute function public.cap29_require_approved_rights();
revoke all on function public.cap29_require_approved_rights() from public, anon, authenticated, service_role, agent_ro;

do $$
declare v_rls boolean;
begin
  select c.relrowsecurity into v_rls
    from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
   where n.nspname='private' and c.relname='library_rights_proofs';
  if coalesce(v_rls,false) is not true
     or has_table_privilege('anon','private.library_rights_proofs','SELECT')
     or has_table_privilege('authenticated','private.library_rights_proofs','SELECT')
     or has_table_privilege('agent_ro','private.library_rights_proofs','SELECT') then
    raise exception 'CAP-29: preuves privees sans RLS ou lisibles par un role client';
  end if;
  if has_table_privilege('anon','public.library_version_rights','SELECT')
     or has_table_privilege('authenticated','public.library_version_rights','INSERT')
     or has_table_privilege('authenticated','public.library_version_rights','UPDATE')
     or has_table_privilege('agent_ro','public.library_version_rights','SELECT') then
    raise exception 'CAP-29: droits client trop larges avant RPC auditee';
  end if;
  if exists (
    select 1 from pg_catalog.pg_trigger t join pg_catalog.pg_proc p on p.oid=t.tgfoid
     where t.tgname in ('cap29_bump_resource_revision','cap29_require_approved_rights')
       and not t.tgisinternal and p.prosecdef
  ) then raise exception 'CAP-29: trigger SECURITY DEFINER interdit'; end if;
end;
$$;

commit;
