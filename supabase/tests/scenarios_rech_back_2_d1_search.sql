-- RECH-BACK-2: synthetic caller-scoped D1 search, keyset and projections.
begin;

insert into auth.users (id, email) values
  ('d1200000-0000-0000-0000-000000000001', 'rech-d1-teacher@example.test'),
  ('d1200000-0000-0000-0000-000000000002', 'rech-d1-outsider@example.test'),
  ('d1200000-0000-0000-0000-000000000003', 'rech-d1-rights-admin@example.test');
insert into public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
values
  ('d1200000-0000-0000-0000-000000000001', 'D1-TEACHER', 'teacher',
   'D1', 'Teacher', 'provisional_active'::public.account_status, 'male'),
  ('d1200000-0000-0000-0000-000000000002', 'D1-OUTSIDER', 'teacher',
   'D1', 'Outsider', 'provisional_active'::public.account_status, 'female'),
  ('d1200000-0000-0000-0000-000000000003', 'D1-RIGHTS-ADMIN', 'admin',
   'D1', 'Rights', 'active'::public.account_status, 'female');

-- 0089 requires both current teacher contracts before activation.
do $fixture_teacher_contracts$
declare
  v_teacher record;
  v_teacher_version text;
  v_notice_version text;
begin
  select version into v_teacher_version
    from public.contract_texts
   where contract_kind = 'teacher_nda' and locale = 'fr' and is_current;
  select version into v_notice_version
    from public.contract_required_versions
   where contract_kind = 'recording_and_control_notice';
  for v_teacher in
    select id from public.profiles
     where role = 'teacher' and account_status = 'provisional_active'
  loop
    perform set_config('request.jwt.claim.sub', v_teacher.id::text, true);
    perform set_config('test.uid', v_teacher.id::text, true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"teacher"}}', true);
    perform set_config('test.jwt', '{"app_metadata":{"role":"teacher"}}', true);
    perform public.signer_contrat(v_teacher_version, 'Fixture RECH-D1');
    insert into public.contract_acceptances(profile_id, contract_kind, version)
    values (v_teacher.id, 'recording_and_control_notice', v_notice_version)
    on conflict (profile_id, contract_kind, version) do nothing;
    perform set_config('request.jwt.claim.sub', 'd1200000-0000-0000-0000-000000000003', true);
    perform set_config('test.uid', 'd1200000-0000-0000-0000-000000000003', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
    perform set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
    update public.profiles set account_status = 'active' where id = v_teacher.id;
  end loop;
end
$fixture_teacher_contracts$;

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('d1200000-0000-0000-0000-000000000101',
   'd1200000-0000-0000-0000-000000000001', 'enfant', 5, 'Alpha D1 A', 1, 9),
  ('d1200000-0000-0000-0000-000000000102',
   'd1200000-0000-0000-0000-000000000001', 'adulte', 6, 'Alpha D1 B', 2, 10),
  ('d1200000-0000-0000-0000-000000000103',
   'd1200000-0000-0000-0000-000000000002', 'enfant', 5, 'Alpha D1 Secret', 3, 11);

insert into public.offres_horaires
  (id, type_public, langue_code, fuseau_iana, jours, heure_locale,
   duree_minutes, etat, created_by, publiee_at, publiee_par)
values
  ('d1200000-0000-0000-0000-000000000301', 'enfant', 'francais', 'Europe/Paris',
   array[1]::smallint[], 9, 45, 'publiee',
   'd1200000-0000-0000-0000-000000000003', statement_timestamp(),
   'd1200000-0000-0000-0000-000000000003'),
  ('d1200000-0000-0000-0000-000000000302', 'enfant', 'francais', 'Europe/Paris',
   array[2]::smallint[], 10, 45, 'brouillon',
   'd1200000-0000-0000-0000-000000000003', null, null);

insert into public.library_resource
  (id, title, short_title, resource_type, edition, language, category,
   access_policy, offline_policy, capabilities)
values
  ('d1200000-0000-0000-0000-000000000201', 'Astronomie niveau 1',
   'Astronomie', 'lesson', 'D1', 'fr', 'science', 'inscrits', 'jamais', '{}'),
  ('d1200000-0000-0000-0000-000000000202', 'Astronomie brouillon',
   'Brouillon', 'lesson', 'D1', 'fr', 'science', 'inscrits', 'jamais', '{}'),
  ('d1200000-0000-0000-0000-000000000203', 'Astronomie autre groupe',
   'Astronomie privée', 'lesson', 'D1', 'fr', 'science', 'groupe_assigne', 'jamais', '{}');
insert into public.resource_version
  (id, resource_id, numero_version, statut, publiee_le, publiee_par)
values
  ('d1200000-0000-0000-0000-000000000211',
   'd1200000-0000-0000-0000-000000000201', 1, 'brouillon', null, null),
  ('d1200000-0000-0000-0000-000000000212',
   'd1200000-0000-0000-0000-000000000202', 1, 'brouillon', null, null),
  ('d1200000-0000-0000-0000-000000000213',
   'd1200000-0000-0000-0000-000000000203', 1, 'brouillon', null, null);

insert into public.library_version_rights
  (resource_version_id, source_titre, titulaire, usages, attribution,
   approuve, revu_par, revu_le)
values
  ('d1200000-0000-0000-0000-000000000211', 'Support synthétique D1',
   'Académie de test', array['application', 'classe']::text[],
   'Fixture de test, aucune licence réelle', true,
   'd1200000-0000-0000-0000-000000000003', statement_timestamp()),
  ('d1200000-0000-0000-0000-000000000213', 'Support synthétique privé D1',
   'Académie de test', array['application', 'classe']::text[],
   'Fixture de test, aucune licence réelle', true,
   'd1200000-0000-0000-0000-000000000003', statement_timestamp());

select set_config('request.jwt.claim.sub', 'd1200000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', 'd1200000-0000-0000-0000-000000000001',
  'app_metadata', jsonb_build_object('role', 'teacher', 'authorization_version', 2)
)::text, true);
update public.resource_version
   set statut = 'publiee'
 where id in (
   'd1200000-0000-0000-0000-000000000211',
   'd1200000-0000-0000-0000-000000000213'
 );
update public.library_resource
   set current_version_id = 'd1200000-0000-0000-0000-000000000211'
 where id = 'd1200000-0000-0000-0000-000000000201';
update public.library_resource
   set current_version_id = 'd1200000-0000-0000-0000-000000000213'
 where id = 'd1200000-0000-0000-0000-000000000203';
insert into public.library_resource_groupe (resource_id, groupe_id)
values ('d1200000-0000-0000-0000-000000000203',
        'd1200000-0000-0000-0000-000000000103');

set local role authenticated;

do $scenario$
declare
  v_page jsonb;
  v_page_two jsonb;
  v_replay_denied boolean := false;
  v_bad_query_denied boolean := false;
  v_foreign_cursor_denied boolean := false;
  v_query_cursor_denied boolean := false;
  v_quota_denied boolean := false;
  v_token uuid;
  v_item jsonb;
  v_cursor_number integer;
begin
  v_page := public.rech_d1_rechercher_classes('alpha', null, 1);
  if jsonb_array_length(v_page -> 'items') <> 1
     or v_page ->> 'has_more' <> 'true'
     or v_page ->> 'next_cursor' is null then
    raise exception 'RECH-D1: première page ou curseur absent';
  end if;
  v_item := v_page -> 'items' -> 0;
  if (select count(*) from pg_catalog.jsonb_object_keys(v_item)) <> 4
     or not (v_item ?& array['kind', 'id', 'title', 'metadata'])
     or (select count(*) from pg_catalog.jsonb_object_keys(v_item -> 'metadata')) <> 4
     or not (v_item -> 'metadata' ?& array[
       'typePublic', 'weekday', 'hourLocal', 'timezone'
     ]) then
    raise exception 'RECH-D1: projection groupe non bornée';
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
    'app_metadata', jsonb_build_object('role', 'teacher', 'authorization_version', 2)
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
    'app_metadata', jsonb_build_object('role', 'teacher', 'authorization_version', 2)
  )::text, true);
  begin
    perform public.rech_d1_rechercher_classes('beta', v_token, 1);
  exception when invalid_parameter_value then
    v_query_cursor_denied := true;
  end;
  if not v_query_cursor_denied then
    raise exception 'RECH-D1: curseur réutilisé avec une autre requête';
  end if;
  -- The foreign and wrong-query attempts must not consume another caller's token.
  -- Consume it as its owner before measuring the exact per-caller quota.
  perform public.rech_d1_rechercher_classes('alpha', v_token, 1);

  for v_cursor_number in 1..20 loop
    perform public.rech_d1_curseur_creer(
      'classes', pg_catalog.md5('quota-' || v_cursor_number::text),
      'groupe', pg_catalog.gen_random_uuid(), 2
    );
  end loop;
  begin
    perform public.rech_d1_curseur_creer(
      'classes', pg_catalog.md5('quota-overflow'), 'groupe',
      pg_catalog.gen_random_uuid(), 2
    );
  exception when sqlstate '54000' then
    v_quota_denied := true;
  end;
  if not v_quota_denied then
    raise exception 'RECH-D1: le 21e curseur dépasse le quota';
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
  v_item := v_page -> 'items' -> 0;
  if (select count(*) from pg_catalog.jsonb_object_keys(v_item)) <> 7
     or not (v_item ?& array['id', 'title', 'shortTitle', 'type', 'edition', 'language', 'category']) then
    raise exception 'RECH-D1: projection support non bornée';
  end if;

  begin
    perform public.rech_d1_rechercher_classes('ab', null, 20);
  exception when invalid_parameter_value then
    v_bad_query_denied := true;
  end;
  if not v_bad_query_denied then
    raise exception 'RECH-D1: requête trop courte acceptée';
  end if;

  v_page := public.rech_d1_rechercher_classes('enfant', null, 20);
  if jsonb_array_length(v_page -> 'items') <> 1
     or v_page -> 'items' -> 0 ->> 'id' <> 'd1200000-0000-0000-0000-000000000301'
     or v_page -> 'items' -> 0 ->> 'kind' <> 'offre'
     or v_page -> 'items' -> 0 -> 'metadata' ? 'rythme' then
    raise exception 'RECH-D1: vitrine doit exposer uniquement l''offre publiée et les colonnes autorisées';
  end if;
  v_item := v_page -> 'items' -> 0;
  if (select count(*) from pg_catalog.jsonb_object_keys(v_item -> 'metadata')) <> 6
     or not (v_item -> 'metadata' ?& array[
       'typePublic', 'langueCode', 'jours', 'heureLocale', 'dureeMinutes', 'fuseau'
     ]) then
    raise exception 'RECH-D1: projection offre non bornée';
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
  if not (select prosecdef from pg_proc where oid =
       'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure)
     or not (select prosecdef from pg_proc where oid =
       'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure) then
    raise exception 'RECH-D1: endpoint DEFINER requis pour filtrer les candidats avant visibilité';
  end if;
  if not exists (
       select 1 from pg_proc p
        where p.oid = 'public.rech_d1_rechercher_classes(text,uuid,integer)'::regprocedure
          and p.proowner = 'postgres'::regrole
          and p.proconfig @> array['search_path=""']
     )
     or not exists (
       select 1 from pg_proc p
        where p.oid = 'public.rech_d1_rechercher_supports(text,uuid,integer)'::regprocedure
          and p.proowner = 'postgres'::regrole
          and p.proconfig @> array['search_path=""']
     ) then
    raise exception 'RECH-D1: DEFINER sans owner postgres ou search_path vide';
  end if;
  if has_function_privilege('service_role',
       'public.rech_d1_rechercher_classes(text,uuid,integer)', 'EXECUTE')
     or has_function_privilege('service_role',
       'public.rech_d1_rechercher_supports(text,uuid,integer)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.rech_d1_rechercher_classes(text,uuid,integer)', 'EXECUTE')
     or not has_function_privilege('authenticated',
       'public.rech_d1_rechercher_supports(text,uuid,integer)', 'EXECUTE') then
    raise exception 'RECH-D1: ACL des endpoints trop large ou inaccessible';
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
