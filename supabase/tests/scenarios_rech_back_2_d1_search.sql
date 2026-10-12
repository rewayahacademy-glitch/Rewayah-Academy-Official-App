-- RECH-BACK-2: synthetic caller-scoped D1 search, keyset and projections.
begin;

insert into auth.users (id, email) values
  ('d1200000-0000-0000-0000-000000000001', 'rech-d1-teacher@example.test'),
  ('d1200000-0000-0000-0000-000000000002', 'rech-d1-outsider@example.test');
insert into public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
values
  ('d1200000-0000-0000-0000-000000000001', 'D1-TEACHER', 'teacher',
   'D1', 'Teacher', 'active'::public.account_status, 'male'),
  ('d1200000-0000-0000-0000-000000000002', 'D1-OUTSIDER', 'teacher',
   'D1', 'Outsider', 'active'::public.account_status, 'female');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('d1200000-0000-0000-0000-000000000101',
   'd1200000-0000-0000-0000-000000000001', 'enfant', 5, 'Alpha D1 A', 1, 9),
  ('d1200000-0000-0000-0000-000000000102',
   'd1200000-0000-0000-0000-000000000001', 'adulte', 6, 'Alpha D1 B', 2, 10),
  ('d1200000-0000-0000-0000-000000000103',
   'd1200000-0000-0000-0000-000000000002', 'enfant', 5, 'Alpha D1 Secret', 3, 11);

insert into public.library_resource
  (id, title, short_title, resource_type, edition, language, category,
   access_policy, offline_policy, capabilities)
values
  ('d1200000-0000-0000-0000-000000000201', 'Astronomie niveau 1',
   'Astronomie', 'lesson', 'D1', 'fr', 'science', 'inscrits', 'jamais', '{}'),
  ('d1200000-0000-0000-0000-000000000202', 'Astronomie brouillon',
   'Brouillon', 'lesson', 'D1', 'fr', 'science', 'inscrits', 'jamais', '{}');
insert into public.resource_version
  (id, resource_id, numero_version, statut, publiee_le, publiee_par)
values
  ('d1200000-0000-0000-0000-000000000211',
   'd1200000-0000-0000-0000-000000000201', 1, 'brouillon', null, null),
  ('d1200000-0000-0000-0000-000000000212',
   'd1200000-0000-0000-0000-000000000202', 1, 'brouillon', null, null);

select set_config('request.jwt.claim.sub', 'd1200000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'd1200000-0000-0000-0000-000000000001',
  'app_metadata', jsonb_build_object('role', 'teacher', 'authorization_version', 1)
)::text, true);
update public.resource_version
   set statut = 'publiee'
 where id = 'd1200000-0000-0000-0000-000000000211';
update public.library_resource
   set current_version_id = 'd1200000-0000-0000-0000-000000000211'
 where id = 'd1200000-0000-0000-0000-000000000201';

set local role authenticated;

do $scenario$
declare
  v_page jsonb;
  v_page_two jsonb;
  v_replay_denied boolean := false;
  v_bad_query_denied boolean := false;
  v_foreign_cursor_denied boolean := false;
  v_query_cursor_denied boolean := false;
  v_token uuid;
begin
  v_page := public.rech_d1_rechercher_classes('alpha', null, 1);
  if jsonb_array_length(v_page -> 'items') <> 1
     or v_page ->> 'has_more' <> 'true'
     or v_page ->> 'next_cursor' is null then
    raise exception 'RECH-D1: première page ou curseur absent';
  end if;
  v_token := (v_page ->> 'next_cursor')::uuid;
  v_page_two := public.rech_d1_rechercher_classes('alpha', v_token, 1);
  if jsonb_array_length(v_page_two -> 'items') <> 1
     or v_page_two ->> 'has_more' <> 'false'
     or v_page -> 'items' -> 0 ->> 'id' = v_page_two -> 'items' -> 0 ->> 'id' then
    raise exception 'RECH-D1: pagination keyset non stable';
  end if;
  begin
    perform public.rech_d1_rechercher_classes('alpha', v_token, 1);
  exception when invalid_parameter_value then
    v_replay_denied := true;
  end;
  if not v_replay_denied then
    raise exception 'RECH-D1: rejeu de curseur accepté';
  end if;

  v_page := public.rech_d1_rechercher_classes('alpha', null, 1);
  v_token := (v_page ->> 'next_cursor')::uuid;
  perform set_config('request.jwt.claim.sub', 'd1200000-0000-0000-0000-000000000002', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'd1200000-0000-0000-0000-000000000002',
    'app_metadata', jsonb_build_object('role', 'teacher', 'authorization_version', 1)
  )::text, true);
  begin
    perform public.rech_d1_rechercher_classes('alpha', v_token, 1);
  exception when invalid_parameter_value then
    v_foreign_cursor_denied := true;
  end;
  if not v_foreign_cursor_denied then
    raise exception 'RECH-D1: curseur d''un autre compte accepté';
  end if;
  perform set_config('request.jwt.claim.sub', 'd1200000-0000-0000-0000-000000000001', true);
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', 'd1200000-0000-0000-0000-000000000001',
    'app_metadata', jsonb_build_object('role', 'teacher', 'authorization_version', 1)
  )::text, true);
  begin
    perform public.rech_d1_rechercher_classes('beta', v_token, 1);
  exception when invalid_parameter_value then
    v_query_cursor_denied := true;
  end;
  if not v_query_cursor_denied then
    raise exception 'RECH-D1: curseur réutilisé avec une autre requête';
  end if;

  v_page := public.rech_d1_rechercher_classes('alpha', null, 50);
  if exists (
    select 1 from jsonb_array_elements(v_page -> 'items') i
     where i ->> 'id' = 'd1200000-0000-0000-0000-000000000103'
  ) then
    raise exception 'RECH-D1: un groupe hors périmètre est visible';
  end if;

  v_page := public.rech_d1_rechercher_supports('astronomie', null, 20);
  if jsonb_array_length(v_page -> 'items') <> 1
     or v_page -> 'items' -> 0 ->> 'id' <> 'd1200000-0000-0000-0000-000000000201'
     or (v_page -> 'items' -> 0) ?| array['storage_key', 'signed_url', 'content', 'cover_asset'] then
    raise exception 'RECH-D1: support non publié ou champ interne exposé';
  end if;

  begin
    perform public.rech_d1_rechercher_classes('ab', null, 20);
  exception when invalid_parameter_value then
    v_bad_query_denied := true;
  end;
  if not v_bad_query_denied then
    raise exception 'RECH-D1: requête trop courte acceptée';
  end if;
end;
$scenario$;

reset role;

do $acl$
begin
  if has_function_privilege('anon',
       'public.rech_d1_rechercher_classes(text,uuid,integer)', 'EXECUTE')
     or has_function_privilege('anon',
       'public.rech_d1_rechercher_supports(text,uuid,integer)', 'EXECUTE') then
    raise exception 'RECH-D1: endpoint accessible à anon';
  end if;
  if (select prosecdef from pg_proc where oid =
       'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure)
     or (select prosecdef from pg_proc where oid =
       'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure) then
    raise exception 'RECH-D1: un endpoint contourne la RLS';
  end if;
  if has_schema_privilege('authenticated', 'private', 'USAGE')
     or has_function_privilege('authenticated',
       'private.rech_d1_curseur_lire(uuid,text,text,bigint)', 'EXECUTE')
     or has_function_privilege('authenticated',
       'private.rech_d1_curseur_creer(text,text,text,uuid,bigint)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.rech_d1_curseur_lire(uuid,text,text,bigint)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.rech_d1_curseur_creer(text,text,text,uuid,bigint)', 'EXECUTE') then
    raise exception 'RECH-D1: ACL des wrappers de curseur trop large ou inaccessible';
  end if;
end;
$acl$;

rollback;
