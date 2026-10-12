-- RECH-BACK-2: caller-scoped D1 search projections with short-lived,
-- single-use opaque keyset cursors. Table RLS remains the row authority.
begin;

create schema if not exists private;

create table private.rech_d1_curseurs (
  token uuid primary key default gen_random_uuid(),
  caller_id uuid not null,
  domaine text not null check (domaine in ('classes', 'supports')),
  query_hash text not null check (query_hash ~ '^[0-9a-f]{32}$'),
  after_kind text not null,
  after_id uuid not null,
  authorization_version bigint not null,
  expires_at timestamptz not null
);
create index rech_d1_curseurs_expiration_idx
  on private.rech_d1_curseurs (expires_at);
revoke all on private.rech_d1_curseurs from public, anon, authenticated, service_role;

create or replace function private.rech_d1_curseur_lire(
  p_token uuid,
  p_domaine text,
  p_query_hash text,
  p_authorization_version bigint
)
returns table (after_kind text, after_id uuid)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_cursor private.rech_d1_curseurs%rowtype;
begin
  if auth.uid() is null or not public.rech_session_autorisee() then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;
  select c.* into v_cursor
    from private.rech_d1_curseurs c
   where c.token = p_token and c.caller_id = auth.uid()
     and c.domaine = p_domaine and c.query_hash = p_query_hash
     and c.authorization_version = p_authorization_version
     and c.expires_at > pg_catalog.statement_timestamp()
   for update;
  if not found then
    raise exception 'RechercheCurseurInvalide' using errcode = '22023';
  end if;
  delete from private.rech_d1_curseurs c where c.token = p_token;
  return query select v_cursor.after_kind, v_cursor.after_id;
end;
$function$;

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
begin
  if auth.uid() is null or not public.rech_session_autorisee() then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;
  delete from private.rech_d1_curseurs c
   where c.caller_id = auth.uid()
     and c.expires_at <= pg_catalog.statement_timestamp();
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

revoke all on function private.rech_d1_curseur_lire(uuid, text, text, bigint)
  from public, anon, authenticated, service_role;
revoke all on function private.rech_d1_curseur_creer(text, text, text, uuid, bigint)
  from public, anon, authenticated, service_role;
-- Keep column allowlists for direct invoker-side consumers. The D1 RPCs below
-- read index candidates with explicit caller visibility inside DEFINER code.
grant select (id, libelle, type_public, weekday, hour_local, timezone_iana, ended_at)
  on public.groupes to authenticated;
grant select (id, type_public, langue_code, jours, heure_locale,
               duree_minutes, fuseau_iana, etat)
  on public.offres_horaires to authenticated;
grant select (id, title, short_title, resource_type, edition, language,
               category, archived_at, current_version_id)
  on public.library_resource to authenticated;
grant select (id, resource_id, statut)
  on public.resource_version to authenticated;
grant select (resource_id, groupe_id)
  on public.library_resource_groupe to authenticated;create index if not exists groupes_actifs_recherche_trgm_idx
  on public.groupes using gin (lower(libelle) extensions.gin_trgm_ops)
  where ended_at is null;
create index if not exists offres_horaires_publiees_recherche_trgm_idx
  on public.offres_horaires using gin
    (lower(langue_code || ' ' || type_public) extensions.gin_trgm_ops)
  where etat = 'publiee';

create or replace function public.rech_d1_rechercher_classes(
  p_recherche text,
  p_curseur uuid default null,
  p_limite integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_query text := lower(btrim(coalesce(p_recherche, '')));
  v_hash text;
  v_authz bigint;
  v_after_kind text;
  v_after_id uuid;
  v_items jsonb;
  v_count integer;
  v_last_kind text;
  v_last_id uuid;
  v_next uuid;
begin
  v_query := replace(replace(replace(v_query, E'\\', ''), '%', ''), '_', '');
  if auth.uid() is null or not public.rech_session_autorisee() then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;
  if length(v_query) < 3 or length(v_query) > 120
     or p_limite is null or p_limite not between 1 and 50 then
    raise exception 'RechercheParametresInvalides' using errcode = '22023';
  end if;
  select p.authorization_version into v_authz
    from public.profiles p where p.id = auth.uid();
  v_hash := pg_catalog.md5(v_query || ':' || p_limite::text);
  if p_curseur is not null then
    select c.after_kind, c.after_id into v_after_kind, v_after_id
      from public.rech_d1_curseur_lire(p_curseur, 'classes', v_hash, v_authz) c;
  end if;

  with appelant as materialized (
    select auth.uid() as uid, public.app_household_id() as household_id,
           public.app_role() as role, public.app_account_valid() as account_valid
  ), groupes_visibles as materialized (
    select g.id
      from public.groupes g
      cross join appelant a
     where a.account_valid
       and (a.role = 'admin' or g.teacher_id = a.uid)
    union
    select gm.groupe_id
      from public.groupe_membres gm
      join public.profiles p on p.id = gm.student_id
      cross join appelant a
     where a.account_valid
       and gm.left_at is null
       and (p.id = a.uid or p.household_id = a.household_id)
  ), groupes_candidats as materialized (
    select g.id
      from public.groupes g
     where g.ended_at is null
       and lower(g.libelle) like '%' || v_query || '%'
  ), offres_candidates as materialized (
    select o.id
      from public.offres_horaires o
     where o.etat = 'publiee'
       and lower(o.langue_code || ' ' || o.type_public) like '%' || v_query || '%'
  ), lignes as (
    select 'groupe'::text as kind, g.id,
           g.libelle as titre,
           pg_catalog.jsonb_build_object(
             'typePublic', g.type_public, 'weekday', g.weekday,
             'hourLocal', g.hour_local, 'timezone', g.timezone_iana
           ) as metadata
      from groupes_candidats c
      join public.groupes g on g.id = c.id
      join groupes_visibles v on v.id = g.id
    union all
    select 'offre'::text, o.id,
           o.langue_code || ' · ' || o.type_public,
           pg_catalog.jsonb_build_object(
             'typePublic', o.type_public, 'langueCode', o.langue_code,
             'jours', o.jours, 'heureLocale', o.heure_locale,
             'dureeMinutes', o.duree_minutes, 'fuseau', o.fuseau_iana
           )
      from offres_candidates c
      join public.offres_horaires o on o.id = c.id
  ), page as (
    select l.* from lignes l
     where v_after_kind is null or (l.kind, l.id) > (v_after_kind, v_after_id)
     order by l.kind, l.id
     limit p_limite + 1
  ), selected as (
    select * from page order by kind, id limit p_limite
  )
  select
    (select pg_catalog.count(*)::integer from page),
    coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'kind', s.kind, 'id', s.id, 'title', s.titre, 'metadata', s.metadata
    ) order by s.kind, s.id) from selected s), '[]'::jsonb),
    (select s.kind from selected s order by s.kind desc, s.id desc limit 1),
    (select s.id from selected s order by s.kind desc, s.id desc limit 1)
  into v_count, v_items, v_last_kind, v_last_id;

  if v_count > p_limite and v_last_id is not null then
    v_next := public.rech_d1_curseur_creer(
      'classes', v_hash, v_last_kind, v_last_id, v_authz
    );
  end if;
  return pg_catalog.jsonb_build_object(
    'items', v_items, 'has_more', v_count > p_limite, 'next_cursor', v_next
  );
end;
$function$;

create or replace function public.rech_d1_rechercher_supports(
  p_recherche text,
  p_curseur uuid default null,
  p_limite integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_query text := lower(btrim(coalesce(p_recherche, '')));
  v_hash text;
  v_authz bigint;
  v_after_kind text;
  v_after_id uuid;
  v_items jsonb;
  v_count integer;
  v_last_id uuid;
  v_next uuid;
begin
  v_query := replace(replace(replace(v_query, E'\\', ''), '%', ''), '_', '');
  if auth.uid() is null or not public.rech_session_autorisee() then
    raise exception 'RechercheSessionInvalide' using errcode = '42501';
  end if;
  if length(v_query) < 3 or length(v_query) > 120
     or p_limite is null or p_limite not between 1 and 50 then
    raise exception 'RechercheParametresInvalides' using errcode = '22023';
  end if;
  select p.authorization_version into v_authz
    from public.profiles p where p.id = auth.uid();
  v_hash := pg_catalog.md5(v_query || ':' || p_limite::text);
  if p_curseur is not null then
    select c.after_kind, c.after_id into v_after_kind, v_after_id
      from public.rech_d1_curseur_lire(p_curseur, 'supports', v_hash, v_authz) c;
  end if;

  with supports_candidats as materialized (
    select r.id
      from public.library_resource r
     where r.archived_at is null
       and (
         lower(r.title) || ' ' || lower(coalesce(r.short_title, '')) || ' ' ||
         lower(coalesce(r.edition, '')) || ' ' || lower(r.category)
       ) like '%' || v_query || '%'
  ), lignes as (
    select r.id, r.title, r.short_title, r.resource_type::text as resource_type,
           r.edition, r.language, r.category
      from supports_candidats c
      join public.library_resource r on r.id = c.id
      join public.resource_version v
        on v.resource_id = r.id and v.id = r.current_version_id
       and v.statut = 'publiee'
     where r.archived_at is null
       and public.app_account_valid()
       and (
         public.app_role() = 'admin'
         or (
           r.current_version_id is not null
           and (
             r.access_policy in ('publique', 'inscrits')
             or (
               r.access_policy in ('groupe_assigne', 'enseignant_seul')
               and exists (
                 select 1
                   from public.library_resource_groupe lrg
                  where lrg.resource_id = r.id
                    and (
                      (
                        public.app_role() = 'teacher'
                        and exists (
                          select 1 from public.mes_groupes_v mg
                           where mg.groupe_id = lrg.groupe_id
                        )
                      )
                      or (
                        public.app_role() in ('guardian', 'student')
                        and r.access_policy = 'groupe_assigne'
                        and exists (
                          select 1 from public.mes_groupes_famille_v mg
                           where mg.groupe_id = lrg.groupe_id
                        )
                      )
                    )
               )
             )
           )
         )
       )
  ), page as (
    select l.* from lignes l
     where v_after_id is null or l.id > v_after_id
     order by l.id limit p_limite + 1
  ), selected as (
    select * from page order by id limit p_limite
  )
  select
    (select pg_catalog.count(*)::integer from page),
    coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', s.id, 'title', s.title, 'shortTitle', s.short_title,
      'type', s.resource_type, 'edition', s.edition,
      'language', s.language, 'category', s.category
    ) order by s.id) from selected s), '[]'::jsonb),
    (select s.id from selected s order by s.id desc limit 1)
  into v_count, v_items, v_last_id;

  if v_count > p_limite and v_last_id is not null then
    v_next := public.rech_d1_curseur_creer(
      'supports', v_hash, 'support', v_last_id, v_authz
    );
  end if;
  return pg_catalog.jsonb_build_object(
    'items', v_items, 'has_more', v_count > p_limite, 'next_cursor', v_next
  );
end;
$function$;

revoke all on function public.rech_d1_rechercher_classes(text, uuid, integer)
  from public, anon, service_role;
revoke all on function public.rech_d1_rechercher_supports(text, uuid, integer)
  from public, anon, service_role;
grant execute on function public.rech_d1_rechercher_classes(text, uuid, integer)
  to authenticated;
grant execute on function public.rech_d1_rechercher_supports(text, uuid, integer)
  to authenticated;
alter function public.rech_d1_rechercher_classes(text, uuid, integer) owner to postgres;
alter function public.rech_d1_rechercher_supports(text, uuid, integer) owner to postgres;

comment on function public.rech_d1_rechercher_classes(text, uuid, integer) is
  'D1 caller-scoped published class/offers projection; fresh authorization and explicit visibility on every page; indexed candidates are selected before caller visibility.';
comment on function public.rech_d1_rechercher_supports(text, uuid, integer) is
  'D1 caller-scoped current published resource metadata; explicit visibility per page; no storage keys, URLs, or content.';

commit;
