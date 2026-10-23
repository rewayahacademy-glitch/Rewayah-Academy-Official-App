-- CAP29 correctif : library_get_catalogue et library_get_catalogue_facettes.
--
-- Defaut bloquant signale sur STAGING et reproduit ici sur base neuve :
-- library_get_catalogue levait 42P01 (« missing FROM-clause entry for table
-- d ») : dans 20261011112956_cap29_catalogue_read.sql, l'alias d manquait
-- apres « from dernier ». Une fois l'alias pose, l'appel levait 42501 :
-- les colonnes level_scope, access_policy et updated_at de library_resource
-- (et resource_version) ne sont accordees a aucun client, et les deux
-- lectures etaient INVOKER. Elles n'ont donc jamais pu repondre.
--
-- Correctif : memes corps, alias pose, SECURITY DEFINER avec search_path
-- vide (meme modele que library_get_detail). La garde positive existante
-- (direction active, auth.uid() non nul) est la seule porte ; elle est
-- inchangee. Aucune cle de stockage ni URL n'est rendue (inchange).
begin;

create or replace function public.library_get_catalogue(
  p_filtre jsonb default '{}'::jsonb,
  p_curseur text default null,
  p_limite integer default 25
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_etat text := coalesce(p_filtre ->> 'etat', 'tous');
  v_type text := p_filtre ->> 'type';
  v_niveau text := p_filtre ->> 'niveau';
  v_langue text := p_filtre ->> 'langue';
  v_recherche text := nullif(btrim(p_filtre ->> 'recherche'), '');
  v_cursor jsonb;
  v_cursor_date timestamptz;
  v_cursor_id uuid;
  v_items jsonb;
  v_has_more boolean;
  v_next_cursor text;
begin
  if auth.uid() is null
     or not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'BibliothequeNonAutorisee' using errcode = '42501';
  end if;
  if p_filtre is null
     or jsonb_typeof(p_filtre) <> 'object'
     or exists (
       select 1 from jsonb_object_keys(p_filtre) as keys(key)
        where key not in ('etat', 'type', 'niveau', 'langue', 'recherche')
     ) then
    raise exception 'BibliothequeFiltreInvalide' using errcode = '22023';
  end if;
  if v_etat not in ('tous', 'brouillons', 'aVerifier', 'publies', 'retires', 'droitsExpires')
     or (v_type is not null and not exists (
       select 1 from pg_catalog.pg_enum e
       join pg_catalog.pg_type t on t.oid = e.enumtypid
       join pg_catalog.pg_namespace n on n.oid = t.typnamespace
       where n.nspname = 'public' and t.typname = 'library_resource_type'
         and e.enumlabel = v_type
     ))
     or coalesce(length(v_niveau), 0) > 80
     or coalesce(length(v_langue), 0) > 16
     or coalesce(length(v_recherche), 0) > 120
     or (v_recherche is not null and length(v_recherche) < 3) then
    raise exception 'BibliothequeFiltreInvalide' using errcode = '22023';
  end if;
  if v_etat = 'droitsExpires' then
    raise exception 'BibliothequeControleDroitsIndisponible'
      using errcode = '0A000';
  end if;
  if p_limite is null or p_limite < 1 or p_limite > 100 then
    raise exception 'BibliothequeLimiteInvalide' using errcode = '22023';
  end if;

  if p_curseur is not null then
    if length(p_curseur) > 256 or p_curseur !~ '^[A-Za-z0-9_-]+$' then
      raise exception 'BibliothequeCurseurInvalide' using errcode = '22023';
    end if;
    begin
      v_cursor := convert_from(
        decode(
          translate(p_curseur, '-_', '+/')
            || repeat('=', (4 - length(p_curseur) % 4) % 4),
          'base64'
        ),
        'UTF8'
      )::jsonb;
      v_cursor_date := (v_cursor ->> 'updated_at')::timestamptz;
      v_cursor_id := (v_cursor ->> 'id')::uuid;
    exception when others then
      raise exception 'BibliothequeCurseurInvalide' using errcode = '22023';
    end;
    if jsonb_typeof(v_cursor) <> 'object'
       or v_cursor_date is null or v_cursor_id is null then
      raise exception 'BibliothequeCurseurInvalide' using errcode = '22023';
    end if;
  end if;

  with lignes as materialized (
    select
      r.id,
      r.title,
      r.short_title,
      r.resource_type::text as resource_type,
      r.language,
      r.category,
      r.level_scope,
      r.access_policy::text as access_policy,
      r.updated_at,
      r.archived_at,
      v.id as version_id,
      v.numero_version,
      v.statut::text as statut_version,
      v.publiee_le
    from public.library_resource r
    left join lateral (
      select rv.id, rv.numero_version, rv.statut, rv.publiee_le
        from public.resource_version rv
       where rv.resource_id = r.id
       order by rv.numero_version desc
       limit 1
    ) v on true
    where (v_type is null or r.resource_type::text = v_type)
      and (v_niveau is null or r.level_scope @> array[v_niveau]::text[])
      and (v_langue is null or r.language = v_langue)
      and case v_etat
        when 'brouillons' then coalesce(v.statut::text, 'brouillon') = 'brouillon'
        when 'publies' then r.archived_at is null and v.statut::text = 'publiee'
        when 'retires' then r.archived_at is not null
        else true
      end
      and (
        v_recherche is null
        or concat_ws(
          ' ', lower(r.title), lower(r.short_title),
          lower(coalesce(r.edition, '')), lower(r.category)
        ) operator(extensions.%) lower(v_recherche)
      )
      and (
        v_cursor_date is null
        or (r.updated_at, r.id) < (v_cursor_date, v_cursor_id)
      )
    order by r.updated_at desc, r.id desc
    limit p_limite + 1
  ), page as (
    select * from lignes order by updated_at desc, id desc limit p_limite
  ), dernier as (
    select updated_at, id from page order by updated_at asc, id asc limit 1
  )
  select
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'titre', p.title,
        'type', p.resource_type,
        'langue', p.language,
        'categorie', p.category,
        'niveau', p.level_scope[1],
        'numeroVersion', p.numero_version,
        'statutVersion', coalesce(p.statut_version, 'brouillon'),
        'revueDroits', 'aVerifier',
        'visibilite', p.access_policy,
        'modifieLeUtc', p.updated_at,
        'retire', p.archived_at is not null
      ) order by p.updated_at desc, p.id desc)
      from page p
    ), '[]'::jsonb),
    (select count(*) > p_limite from lignes),
    (select jsonb_build_object('updated_at', d.updated_at, 'id', d.id)::text from dernier d)
  into v_items, v_has_more, v_next_cursor;

  if v_has_more and v_next_cursor is not null then
    v_next_cursor := rtrim(translate(
      encode(convert_to(v_next_cursor, 'UTF8'), 'base64'), E'\n', ''
    ), '=');
    v_next_cursor := translate(v_next_cursor, '+/', '-_');
  else
    v_next_cursor := null;
  end if;

  return jsonb_build_object(
    'elements', v_items,
    'curseur', v_next_cursor
  );
end;
$$;

create or replace function public.library_get_catalogue_facettes()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
     or not coalesce(public.app_role() = 'admin' and public.app_account_valid(), false) then
    raise exception 'BibliothequeNonAutorisee' using errcode = '42501';
  end if;
  return (select jsonb_build_object(
    'niveaux', coalesce((
      select jsonb_agg(distinct niveau order by niveau)
        from public.library_resource r
        cross join lateral unnest(r.level_scope) as niveau
    ), '[]'::jsonb),
    'langues', coalesce((
      select jsonb_agg(distinct r.language order by r.language)
        from public.library_resource r
    ), '[]'::jsonb)
  ));
end;
$$;

revoke all on function public.library_get_catalogue(jsonb, text, integer) from public, anon, agent_ro, service_role;
revoke all on function public.library_get_catalogue_facettes() from public, anon, agent_ro, service_role;
grant execute on function public.library_get_catalogue(jsonb, text, integer) to authenticated;
grant execute on function public.library_get_catalogue_facettes() to authenticated;

-- @@F86_DEBUT_CATALOGUE@@
comment on function public.library_get_catalogue(jsonb, text, integer) is
  'F86: signature=public.library_get_catalogue(jsonb,text,integer); md5_functiondef=4293e30b8dc41ca1df8f11d3b6751659; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active. Correctif alias d (42P01) et DEFINER (colonnes non accordees).';
comment on function public.library_get_catalogue_facettes() is
  'F86: signature=public.library_get_catalogue_facettes(); md5_functiondef=d4ba22bc1b32631ecedd52578f362100; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-16. Garde: direction active. DEFINER (level_scope non accordee).';
DO $postflight$
BEGIN
  IF EXISTS (
    SELECT 1 FROM (VALUES
      ('public.library_get_catalogue(jsonb,text,integer)'::regprocedure, '4293e30b8dc41ca1df8f11d3b6751659'),
      ('public.library_get_catalogue_facettes()'::regprocedure, 'd4ba22bc1b32631ecedd52578f362100')
    ) AS e(oid, attendu)
    JOIN pg_catalog.pg_proc p ON p.oid = e.oid
    WHERE pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) <> e.attendu
       OR NOT p.prosecdef OR NOT (p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '') NOT LIKE '%' || e.attendu || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', p.oid, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'CAP29 correctif catalogue : empreinte F86, DEFINER ou ACL invalide';
  END IF;
END;
$postflight$;
-- @@F86_FIN_CATALOGUE@@

commit;
