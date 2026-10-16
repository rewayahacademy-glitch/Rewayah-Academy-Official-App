-- Scénarios négatifs B-18 / 0044.
-- À exécuter après toutes les migrations sur PostgreSQL jetable seulement.
begin;
select set_config('request.jwt.claims', '{}', true);
REVOKE SELECT ON public.kyc_documents FROM authenticated;

set local role anon;
do $$
begin
  if pg_catalog.has_function_privilege('anon', 'public.comptes_admin()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.read_kyc_documents()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.eleves_sans_enseignant()', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.enseignants_pour(uuid)', 'execute') then
    raise exception 'B-18: anon retains EXECUTE on a protected RPC';
  end if;
end $$;
reset role;

set local role authenticated;
do $$
declare
  v_rows integer;
begin
  select count(*) into v_rows from public.comptes_admin();
  if v_rows <> 0 then
    raise exception 'B-18: comptes_admin exposed rows with no app role';
  end if;
  begin
    perform public.creer_groupe(null::uuid, null::text, null::text, null::smallint, null::smallint, null::smallint, null::text, null::smallint);
    raise exception 'B-18: long creer_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'creation de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.creer_groupe(null::uuid, null::text, null::text, null::smallint, null::smallint, null::smallint);
    raise exception 'B-18: short creer_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'creation de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.modifier_groupe(null::uuid, null::text, null::smallint, null::smallint, null::smallint, null::text, null::smallint);
    raise exception 'B-18: long modifier_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform public.modifier_groupe(null::uuid, null::text, null::smallint, null::smallint, null::smallint);
    raise exception 'B-18: short modifier_groupe overload accepted missing claims';
  exception when raise_exception then
    if sqlerrm <> 'modification de groupe reservee a l''administration' then raise; end if;
  end;
  begin
    perform 1 from public.read_kyc_documents();
    raise exception 'B-18: read_kyc_documents accepted missing claims';
  exception when insufficient_privilege then
    null;
  when raise_exception then
    if sqlerrm <> 'acces KYC refuse' then raise; end if;
  end;
end $$;
reset role;

set local role agent_ro;
do $$
begin
  if pg_catalog.has_function_privilege('agent_ro', 'public.comptes_admin()', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.creer_groupe(uuid,text,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint,text,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.modifier_groupe(uuid,text,smallint,smallint,smallint)', 'execute')
     or pg_catalog.has_function_privilege('agent_ro', 'public.read_kyc_documents()', 'execute') then
    raise exception 'B-18: agent_ro retains EXECUTE on a protected RPC';
  end if;
end $$;
-- B2 / I-18 : un compte Auth sans profil ne lit ni n'écrit via les RPC
-- administratives SECURITY DEFINER. Ces six fonctions avaient une garde
-- négative; NULL <> 'admin' laissait passer l'appel.
set local role authenticated;
do $b2$
declare
  v_test record;
  v_uid constant uuid := 'b1800000-0000-0000-0000-000000000001';
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('test.uid', v_uid::text, true);
  perform set_config('request.jwt.claims', '{}', true);
  perform set_config('test.jwt', '{}', true);

  if auth.uid() <> v_uid or public.app_account_valid() then
    raise exception 'B2 ECHEC : le fixture doit avoir auth.uid sans profil applicatif';
  end if;

  for v_test in
    select * from (values
      ('eleves_sans_enseignant', 'select * from public.eleves_sans_enseignant()', 'attribution manuelle reservee a l''administration'),
      ('enseignants_pour', 'select * from public.enseignants_pour(null::uuid)', 'attribution manuelle reservee a l''administration'),
      ('indicateurs_admin', 'select * from public.indicateurs_admin()', 'centre de commande reserve a l''administration'),
      ('demandes_en_attente', 'select * from public.demandes_en_attente()', 'file des demandes reservee a l''administration'),
      ('journal_audit_filtres', 'select public.journal_audit_filtres()', 'journal d''audit reserve a l''administration'),
      ('maj_eleve_pedagogie', 'select public.maj_eleve_pedagogie(null::uuid, ''inconnu'', ''inconnu'')', 'seul un administrateur modifie le niveau ou la riwaya'),
      ('decider_dossier', 'select public.decider_dossier(null::uuid, true)', 'seul un administrateur decide d''un dossier'),
      ('attribuer_eleve', 'select public.attribuer_eleve(null::uuid, null::uuid, 1, 1, null)', 'attribution manuelle reservee a l''administration')
    ) as tests(nom, commande, refus_attendu)
  loop
    begin
      execute v_test.commande;
      raise exception 'B2 ECHEC : % a accepté un JWT sans profil', v_test.nom;
    exception when raise_exception then
      if sqlerrm <> v_test.refus_attendu then
        raise;
      end if;
    end;
  end loop;

  raise notice 'B2 ok : compte Auth sans profil refusé par les huit RPC sensibles';
end
$b2$;
reset role;

-- B-06 / SEC-04 : Direction active seulement, et aucun SELECT direct sur KYC.
insert into auth.users (id, email) values
  ('b1800000-0000-0000-0000-000000000002', 'b06-controller@example.test'),
  ('b1800000-0000-0000-0000-000000000003', 'b06-admin@example.test');
insert into public.profiles
  (id, immutable_id, role, gender, first_name, last_name, account_status)
values
  ('b1800000-0000-0000-0000-000000000002', 'B06CONTROLLER0002', 'controller',
   'female', 'Fixture', 'Controller', 'active'),
  ('b1800000-0000-0000-0000-000000000003', 'B06ADMIN0000003', 'admin',
   'female', 'Fixture', 'Admin', 'active');

-- F86: an existing admin role must not bypass an invalid/suspended account.
UPDATE public.profiles SET account_status='disabled'
 WHERE id='b1800000-0000-0000-0000-000000000003';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'b1800000-0000-0000-0000-000000000003', true);
SELECT set_config('test.uid', 'b1800000-0000-0000-0000-000000000003', true);
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
SELECT set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
DO $f86_suspended_admin$
BEGIN
  BEGIN
    PERFORM * FROM public.eleves_sans_enseignant();
    RAISE EXCEPTION 'F86: disabled admin read the student assignment queue';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'attribution manuelle reservee a l''administration' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM * FROM public.enseignants_pour(NULL::uuid);
    RAISE EXCEPTION 'F86: disabled admin read teacher assignment candidates';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'attribution manuelle reservee a l''administration' THEN RAISE; END IF;
  END;
END
$f86_suspended_admin$;
RESET ROLE;
UPDATE public.profiles SET account_status='active'
 WHERE id='b1800000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('test.uid', 'b1800000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', '{"app_metadata":{"role":"controller"}}', true);
select set_config('test.jwt', '{"app_metadata":{"role":"controller"}}', true);
do $b06_controller$
declare
  v_rows integer;
begin
  begin
    perform 1 from public.read_kyc_documents();
    raise exception 'B-06 ECHEC: le contrôleur lit la RPC KYC';
  exception when insufficient_privilege then
    null;
  when raise_exception then
    if sqlerrm <> 'acces KYC refuse' then raise; end if;
  end;
  begin
    perform public.autoriser_lecture_piece_identite(
      'b1800000-0000-0000-0000-000000000099'
    );
    raise exception 'B-06 ECHEC: le contrôleur obtient une signature de pièce';
  exception when insufficient_privilege then
    null;
  end;
  begin
    perform 1 from public.kyc_documents;
    raise exception 'B-06 ECHEC: direct KYC table read unexpectedly succeeded';
  exception when insufficient_privilege then
    null;
  end;
end
$b06_controller$;

select set_config('test.uid', 'b1800000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
do $b06_admin$
begin
  perform 1 from public.read_kyc_documents();
end
$b06_admin$;
reset role;

do $b06_storage$
begin
  if to_regclass('storage.objects') is not null
     and exists (
       select 1 from pg_catalog.pg_policies
       where schemaname = 'storage'
         and tablename = 'objects'
         and policyname = 'kyc_lecture_admin'
     ) then
    raise exception 'B-06 ECHEC: la lecture directe Storage KYC subsiste';
  end if;
end
$b06_storage$;

-- M2 : scanner persistant sur tous les SECURITY DEFINER applicatifs et
-- fixtures adversariales couvrant IF/ELSIF, opérateurs et retours à la ligne.
do $b18_scanner$
declare
  v record;
begin
  for v in
    select nom, source
    from (values
      ('if_inequality', 'IF app_role() <> ''admin'' THEN'),
      ('elsif_not_equal_multiline', E'ELSIF\n public.app_role() != ''admin'' THEN'),
      ('not_in_multiline', E'IF public.app_role()\n NOT IN (''admin'', ''controller'') THEN'),
      ('reversed_inequality', 'IF ''admin'' <> public.app_role() THEN'),
      ('if_not_parenthesized_or', 'IF NOT (public.app_role() = ''admin'' OR public.app_role() = ''controller'') THEN'),
      ('elsif_not_parenthesized_multiline', E'ELSIF NOT (public.app_role() = ''admin''\n OR public.app_role() = ''controller'') THEN'),
      ('unary_not_app_role', 'IF NOT public.app_role() = ''admin'' THEN')
    ) as samples(nom, source)
  loop
    if not app_private.has_unsafe_role_guard(v.source) then
      raise exception 'M2 ECHEC: scanner aveugle à %', v.nom;
    end if;
  end loop;

  if app_private.has_unsafe_role_guard(
    'IF NOT coalesce(public.app_role() = ''admin'' AND public.app_account_valid(), false) THEN'
  ) then
    raise exception 'M2 ECHEC: le scanner rejette la garde positive canonique';
  end if;

  if app_private.has_unsafe_role_guard(
    'IF public.app_role() = ''teacher'' AND p_genre_classe NOT IN (''hommes'', ''femmes'') THEN'
  ) then
    raise exception 'M2 ECHEC: NOT IN sur p_genre_classe est attribue a tort a app_role()';
  end if;

  if app_private.has_unsafe_role_guard(
    'IF p_genre_classe NOT IN (''hommes'', ''femmes'') THEN'
  ) then
    raise exception 'M2 ECHEC: NOT IN autonome sur p_genre_classe est une fausse garde app_role()';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'app_private')
      and p.prokind = 'f'
      and p.prosecdef
      and app_private.has_unsafe_role_guard(p.prosrc)
  ) then
    raise exception 'M2 ECHEC: garde négative résiduelle dans une fonction SECURITY DEFINER applicative';
  end if;
end
$b18_scanner$;

-- Fixtures actives dans un même foyer : un JWT sans rôle rendrait la branche
-- guardian NULL avec l'ancienne condition NOT (...), laquelle laissait passer.
insert into auth.users (id, email) values
  ('b1840000-0000-0000-0000-000000000004', 'b18-null-role-guardian@example.test'),
  ('b1840000-0000-0000-0000-000000000005', 'b18-null-role-child@example.test');
insert into public.households (id, timezone)
values ('b1840000-0000-0000-0000-000000000010', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, gender, first_name, last_name, account_status, household_id)
values
  ('b1840000-0000-0000-0000-000000000004', 'B18NROLEGUARD0004', 'guardian',
   'female', 'Fixture', 'Guardian', 'active', 'b1840000-0000-0000-0000-000000000010'),
  ('b1840000-0000-0000-0000-000000000005', 'B18NROLECHILD005', 'student',
   'female', 'Fixture', 'Child', 'active', 'b1840000-0000-0000-0000-000000000010');

set local role authenticated;
select set_config('test.uid', 'b1840000-0000-0000-0000-000000000004', true);
select set_config(
  'request.jwt.claims',
  '{"app_metadata":{"household_id":"b1840000-0000-0000-0000-000000000010"}}',
  true
);
do $m1_no_role$
begin
  if public.app_role() is not null or not public.app_account_valid()
     or not public.est_du_foyer('b1840000-0000-0000-0000-000000000005') then
    raise exception 'M1 fixture invalide: compte actif sans rôle, même foyer attendu';
  end if;

  begin
    perform public.etat_presence(
      'b1840000-0000-0000-0000-000000000099'::uuid,
      'b1840000-0000-0000-0000-000000000005'::uuid
    );
    raise exception 'M1 ECHEC: etat_presence accepte le JWT sans rôle';
  exception when insufficient_privilege then
    null;
  end;
end
$m1_no_role$;
reset role;

-- M4 : le trigger voit le rôle Postgres effectif (SECURITY INVOKER); un
-- utilisateur authentifié sans claim de rôle est refusé, tandis que l'admin
-- actif et service_role conservent leurs usages.
do $m4_catalog$
declare
  v_security_definer boolean;
begin
  select p.prosecdef into v_security_definer
  from pg_catalog.pg_proc p
  where p.oid = 'public.guard_profile_privileged_columns()'::regprocedure;
  if v_security_definer is distinct from false then
    raise exception 'M4 ECHEC: guard_profile_privileged_columns doit être SECURITY INVOKER';
  end if;
end
$m4_catalog$;

create temporary table profile_guard_fixture on commit drop as
select role, household_id, account_status, access_until, gender
from public.profiles
where id = 'b1840000-0000-0000-0000-000000000004';
create trigger profile_guard_fixture_trigger
before update on pg_temp.profile_guard_fixture
for each row execute function public.guard_profile_privileged_columns();
grant select, update on pg_temp.profile_guard_fixture to authenticated, service_role;

set local role authenticated;
select set_config('test.uid', 'b1840000-0000-0000-0000-000000000004', true);
select set_config(
  'request.jwt.claims',
  '{"app_metadata":{"household_id":"b1840000-0000-0000-0000-000000000010"}}',
  true
);
do $m4_no_role$
begin
  if public.app_role() is not null or not public.app_account_valid() then
    raise exception 'M4 fixture invalide: compte actif sans rôle attendu';
  end if;

  begin
    update pg_temp.profile_guard_fixture
       set access_until = now() + interval '1 day';
    raise exception 'M4 ECHEC: compte sans rôle a modifié access_until';
  exception when insufficient_privilege then
    null;
  end;
end
$m4_no_role$;

select set_config(
  'request.jwt.claims',
  '{"app_metadata":{"role":"admin","household_id":"b1840000-0000-0000-0000-000000000010"}}',
  true
);
update pg_temp.profile_guard_fixture
   set access_until = now() + interval '2 days';
reset role;

set local role service_role;
update pg_temp.profile_guard_fixture
   set access_until = now() + interval '3 days';
reset role;

rollback;
