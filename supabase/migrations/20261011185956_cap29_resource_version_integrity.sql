-- CAP-29 §4.2 and §5.1: a published binary/version is immutable, and the
-- resource's current_version_id must identify its own published version.
-- A publication workflow must transition the old version to archivee, publish
-- the prepared draft, then move current_version_id in one transaction.

begin;

do $$
begin
  if exists (
    select 1
      from public.resource_version
     where statut = 'publiee'
     group by resource_id
    having count(*) > 1
  ) then
    raise exception 'CAP-29: plusieurs versions publiees pour une ressource';
  end if;

  if exists (
    select 1
      from public.library_resource r
      left join public.resource_version v
        on v.id = r.current_version_id
       and v.resource_id = r.id
     where (r.current_version_id is not null
            and (v.id is null or v.statut <> 'publiee'))
        or exists (
          select 1
            from public.resource_version published
           where published.resource_id = r.id
             and published.statut = 'publiee'
             and published.id is distinct from r.current_version_id
        )
  ) then
    raise exception 'CAP-29: pointeur de version courante incoherent';
  end if;

  if exists (
    select 1
      from public.library_resource r
     where r.archived_at is null
       and r.current_version_id is null
       and exists (
         select 1 from public.resource_version v
          where v.resource_id = r.id and v.statut = 'archivee'
       )
       and not exists (
         select 1 from public.resource_version v
          where v.resource_id = r.id and v.statut = 'publiee'
       )
  ) then
    raise exception 'CAP-29: une ressource active ne peut perdre sa version publiee';
  end if;
end;
$$;

alter table public.resource_version
  add constraint resource_version_id_resource_key unique (id, resource_id);

alter table public.library_resource
  add constraint library_resource_current_version_same_resource_fk
  foreign key (current_version_id, id)
  references public.resource_version (id, resource_id)
  deferrable initially deferred;

create unique index resource_version_one_published_per_resource_uidx
  on public.resource_version (resource_id)
  where statut = 'publiee';

create or replace function public.cap29_guard_resource_version()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.statut <> 'brouillon'
       or new.publiee_le is not null
       or new.publiee_par is not null then
      raise exception 'CAP-29: une version doit commencer en brouillon'
        using errcode = '23514';
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.statut <> 'brouillon' then
      raise exception 'CAP-29: une version publiee ou archivee ne se supprime pas'
        using errcode = '23514';
    end if;
    return old;
  end if;

  if new.id is distinct from old.id
     or new.resource_id is distinct from old.resource_id
     or new.numero_version is distinct from old.numero_version then
    raise exception 'CAP-29: identite de version immuable'
      using errcode = '23514';
  end if;

  if old.statut = 'brouillon' then
    if new.statut = 'publiee' then
      if auth.uid() is null then
        raise exception 'CAP-29: publication requiert un utilisateur authentifie'
          using errcode = '42501';
      end if;
      -- Publication time and actor are server values, never client claims.
      new.publiee_le := pg_catalog.clock_timestamp();
      new.publiee_par := auth.uid();
    elsif new.statut <> 'brouillon' then
      raise exception 'CAP-29: une version brouillon ne peut etre archivee sans publication'
        using errcode = '23514';
    elsif new.publiee_le is not null or new.publiee_par is not null then
      raise exception 'CAP-29: metadonnees de publication hors transition'
        using errcode = '23514';
    end if;
    return new;
  end if;

  if old.statut = 'publiee'
     and new.statut = 'archivee'
     and row(new.id, new.resource_id, new.numero_version, new.publiee_le,
             new.publiee_par, new.download_asset_id, new.empreinte)
         is not distinct from
         row(old.id, old.resource_id, old.numero_version, old.publiee_le,
             old.publiee_par, old.download_asset_id, old.empreinte) then
    return new;
  end if;

  if new.statut = old.statut
     and row(new.id, new.resource_id, new.numero_version, new.publiee_le,
             new.publiee_par, new.download_asset_id, new.empreinte)
         is not distinct from
         row(old.id, old.resource_id, old.numero_version, old.publiee_le,
             old.publiee_par, old.download_asset_id, old.empreinte) then
    return new;
  end if;

  raise exception 'CAP-29: version publiee ou archivee immuable'
    using errcode = '23514';
end;
$$;

create trigger cap29_resource_version_guard
before insert or update or delete on public.resource_version
for each row execute function public.cap29_guard_resource_version();

create or replace function public.cap29_guard_download_asset()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_statut public.statut_version_ressource;
begin
  if tg_op = 'INSERT' then
    select v.statut into v_statut
      from public.resource_version v
     where v.id = new.resource_version_id
     for update;
    if not found or v_statut <> 'brouillon' then
      raise exception 'CAP-29: un artefact ne peut etre ajoute qu a un brouillon'
        using errcode = '23514';
    end if;
    return new;
  end if;

  select v.statut into v_statut
    from public.resource_version v
   where v.id = old.resource_version_id
   for update;
  if found and v_statut <> 'brouillon' then
    raise exception 'CAP-29: artefact d une version publiee immuable'
      using errcode = '23514';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  if new.resource_version_id is distinct from old.resource_version_id then
    raise exception 'CAP-29: l artefact reste lie a sa version initiale'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger cap29_download_asset_guard
before insert or update or delete on public.download_asset
for each row execute function public.cap29_guard_download_asset();

create or replace function public.cap29_guard_current_resource_version()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_statut public.statut_version_ressource;
begin
  if new.current_version_id is null then
    return new;
  end if;

  select v.statut into v_statut
    from public.resource_version v
   where v.id = new.current_version_id
     and v.resource_id = new.id;
  if not found then
    raise exception 'CAP-29: la version doit appartenir a la ressource'
      using errcode = '23503';
  end if;
  if v_statut <> 'publiee' then
    raise exception 'CAP-29: current_version_id doit viser une version publiee'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger cap29_current_resource_version_guard
before insert or update of current_version_id on public.library_resource
for each row execute function public.cap29_guard_current_resource_version();

-- Deferred because publication changes the old status, new status and current
-- pointer in one transaction. This is invoker-only; the server mutation path
-- owns the transaction and no client has direct write grants on these tables.
create or replace function public.cap29_assert_published_resource_version()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_resource_id uuid;
  v_current_version_id uuid;
  v_published_version_id uuid;
  v_archived_at timestamptz;
begin
  if tg_table_name = 'library_resource' then
    if tg_op = 'DELETE' then
      v_resource_id := old.id;
    else
      v_resource_id := new.id;
    end if;
  else
    if tg_op = 'DELETE' then
      v_resource_id := old.resource_id;
    else
      v_resource_id := new.resource_id;
    end if;
  end if;

  select r.current_version_id, r.archived_at
    into v_current_version_id, v_archived_at
    from public.library_resource r
   where r.id = v_resource_id;
  if not found then
    return null;
  end if;

  select v.id into v_published_version_id
    from public.resource_version v
   where v.resource_id = v_resource_id
     and v.statut = 'publiee';

  if v_current_version_id is distinct from v_published_version_id then
    raise exception 'CAP-29: une ressource doit pointer vers son unique version publiee'
      using errcode = '23514';
  end if;
  if v_published_version_id is null
     and v_archived_at is null
     and exists (
       select 1 from public.resource_version v
        where v.resource_id = v_resource_id and v.statut = 'archivee'
     ) then
    raise exception 'CAP-29: une ressource active conserve une version publiee'
      using errcode = '23514';
  end if;
  return null;
end;
$$;

create constraint trigger cap29_resource_published_pointer_check
after insert or update or delete on public.library_resource
deferrable initially deferred
for each row execute function public.cap29_assert_published_resource_version();

create constraint trigger cap29_version_published_pointer_check
after insert or update or delete on public.resource_version
deferrable initially deferred
for each row execute function public.cap29_assert_published_resource_version();

revoke all on function public.cap29_guard_resource_version() from public, anon, authenticated, service_role, agent_ro;
revoke all on function public.cap29_guard_download_asset() from public, anon, authenticated, service_role, agent_ro;
revoke all on function public.cap29_guard_current_resource_version() from public, anon, authenticated, service_role, agent_ro;
revoke all on function public.cap29_assert_published_resource_version() from public, anon, authenticated, service_role, agent_ro;

do $$
begin
  if exists (
    select 1 from pg_catalog.pg_trigger t
    join pg_catalog.pg_proc p on p.oid = t.tgfoid
    where t.tgname in (
      'cap29_resource_version_guard',
      'cap29_download_asset_guard',
      'cap29_current_resource_version_guard',
      'cap29_resource_published_pointer_check',
      'cap29_version_published_pointer_check'
    ) and p.prosecdef
  ) then
    raise exception 'CAP-29: SECURITY DEFINER trigger is forbidden';
  end if;
  if not exists (
    select 1 from pg_constraint
     where conname = 'library_resource_current_version_same_resource_fk'
       and conrelid = 'public.library_resource'::regclass
       and convalidated
  ) then
    raise exception 'CAP-29: contrainte de parent de version absente/non valide';
  end if;
  if not exists (
    select 1 from pg_trigger
     where tgname = 'cap29_version_published_pointer_check'
       and not tgisinternal
  ) then
    raise exception 'CAP-29: verification differee version/pointeur absente';
  end if;
  if has_function_privilege('anon', 'public.cap29_assert_published_resource_version()', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.cap29_assert_published_resource_version()', 'EXECUTE')
     or has_function_privilege('service_role', 'public.cap29_assert_published_resource_version()', 'EXECUTE')
     or has_function_privilege('agent_ro', 'public.cap29_assert_published_resource_version()', 'EXECUTE') then
    raise exception 'CAP-29: fonction trigger interne exposable directement';
  end if;
end;
$$;

commit;
