-- IMM-BACK-2: codes EV-NNNN des evaluations publiees. Base neuve, fixtures synthetiques.
-- Chaque garde a un refus qui lui est propre ; un mutant qui retire la garde doit rougir.
begin;

create temporary table ev_controles (label text primary key) on commit drop;
grant all on pg_temp.ev_controles to public;

create function pg_temp.ev_ok(p_label text, p_ok boolean) returns void
language plpgsql as $f$
begin
  if p_ok is not true then raise exception 'IMM-BACK-2 %: controle rouge', p_label; end if;
  insert into pg_temp.ev_controles values (p_label);
end;
$f$;

create function pg_temp.ev_as(p_uid uuid, p_role text, p_household uuid default null)
returns void language plpgsql as $f$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_uid::text, ''), true);
  perform set_config('request.jwt.claims',
    case when p_uid is null then '{}'
      else jsonb_build_object('sub', p_uid, 'role', 'authenticated',
        'app_metadata', jsonb_build_object('role', p_role, 'household_id', p_household))::text end,
    true);
end;
$f$;

-- Rend le message d'erreur d'un appel fait en authenticated, ou 'accepte'.
create function pg_temp.ev_essai(p_uid uuid, p_role text, p_household uuid, p_sql text)
returns text language plpgsql as $f$
begin
  perform pg_temp.ev_as(p_uid, p_role, p_household);
  begin
    set local role authenticated;
    execute p_sql;
    raise exception '__accepte__';
  exception when others then
    return sqlerrm;
  end;
end;
$f$;

insert into auth.users (id, email)
select ('e2000000-0000-0000-0000-00000000000' || n)::uuid, 'ev' || n || '@example.test'
  from generate_series(1, 9) as n;
insert into public.households (id, timezone) values
  ('e2f00000-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('e2f00000-0000-0000-0000-000000000002', 'Europe/Paris');
insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
values
  ('e2000000-0000-0000-0000-000000000001', null, 'admin', null, 'Admin', 'Fixture', 'active'),
  ('e2000000-0000-0000-0000-000000000002', null, 'teacher', null, 'Prof', 'Fixture', 'pending_kyc'),
  ('e2000000-0000-0000-0000-000000000003', null, 'guardian', 'e2f00000-0000-0000-0000-000000000001', 'Tuteur', 'Un', 'active'),
  ('e2000000-0000-0000-0000-000000000004', null, 'student', 'e2f00000-0000-0000-0000-000000000001', 'Eleve', 'Un', 'active'),
  ('e2000000-0000-0000-0000-000000000005', null, 'student', 'e2f00000-0000-0000-0000-000000000001', 'Eleve', 'Deux', 'active'),
  ('e2000000-0000-0000-0000-000000000006', null, 'student', 'e2f00000-0000-0000-0000-000000000002', 'Eleve', 'Trois', 'active'),
  ('e2000000-0000-0000-0000-000000000007', null, 'guardian', 'e2f00000-0000-0000-0000-000000000002', 'Tuteur', 'Deux', 'active'),
  ('e2000000-0000-0000-0000-000000000008', null, 'admin', null, 'Admin', 'Attente', 'pending_kyc'),
  ('e2000000-0000-0000-0000-000000000009', null, 'student', 'e2f00000-0000-0000-0000-000000000002', 'Eleve', 'Parti', 'active');
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('e2800000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000002', 'enfant', 5, 'EV groupe A', 1, 10),
  ('e2800000-0000-0000-0000-000000000002', 'e2000000-0000-0000-0000-000000000002', 'enfant', 5, 'EV groupe vide', 2, 10),
  ('e2800000-0000-0000-0000-000000000003', 'e2000000-0000-0000-0000-000000000002', 'enfant', 5, 'EV groupe cloture', 3, 10);
insert into public.groupe_membres (groupe_id, student_id) values
  ('e2800000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000004'),
  ('e2800000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000005'),
  ('e2800000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000006');
insert into public.groupe_membres (groupe_id, student_id, left_at, left_by, left_reason)
values ('e2800000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000009',
        now(), 'e2000000-0000-0000-0000-000000000001', 'depart fixture');
update public.groupes
   set ended_at = now(), ended_by = 'e2000000-0000-0000-0000-000000000001', end_reason = 'fixture'
 where id = 'e2800000-0000-0000-0000-000000000003';

-- EV-01 : ACL et empreintes F86.
do $acl$
declare
  v_sig text;
  v_oid oid;
  v_public boolean;
begin
  foreach v_sig in array array[
    'private.tirer_nombre_evaluation()',
    'private.attribuer_codes_evaluation(uuid,uuid)',
    'public.publier_evaluation(uuid,text,text)',
    'public.changer_affichage_evaluation(uuid,text)',
    'public.evaluation_publiee_lignes(uuid)'
  ] loop
    v_oid := v_sig::regprocedure::oid;
    v_public := v_sig like 'public.%';
    perform pg_temp.ev_ok('EV-01 ACL ' || v_sig,
      not has_function_privilege('anon', v_oid, 'EXECUTE')
      and not has_function_privilege('service_role', v_oid, 'EXECUTE')
      and not has_function_privilege('agent_ro', v_oid, 'EXECUTE')
      and has_function_privilege('authenticated', v_oid, 'EXECUTE') = v_public);
    perform pg_temp.ev_ok('EV-01 F86 ' || v_sig,
      exists (select 1 from pg_proc p
               where p.oid = v_oid and p.prosecdef
                 and pg_get_userbyid(p.proowner) = 'postgres'
                 and p.proconfig @> array['search_path=""']
                 and strpos(obj_description(p.oid, 'pg_proc'),
                       'md5_functiondef=' || md5(pg_get_functiondef(p.oid)) || ';') > 0));
  end loop;
  perform pg_temp.ev_ok('EV-01 RLS tables',
    (select relrowsecurity from pg_class where oid = 'public.evaluation_publications'::regclass)
    and (select relrowsecurity from pg_class where oid = 'private.evaluation_codes'::regclass)
    and not has_table_privilege('authenticated', 'private.evaluation_codes', 'SELECT')
    and not has_table_privilege('service_role', 'private.evaluation_codes', 'SELECT')
    and not has_table_privilege('anon', 'public.evaluation_publications', 'SELECT')
    and not has_table_privilege('authenticated', 'public.evaluation_publications', 'INSERT'));
end
$acl$;

-- EV-02 : refus de la garde admin, un cas par appelant.
do $refus_admin$
declare
  v_g text := 'e2800000-0000-0000-0000-000000000001';
  v_sql text := 'select public.publier_evaluation(''' || 'e2800000-0000-0000-0000-000000000001' || ''', ''Test'', ''code'')';
  v_msg text := 'publication d''une evaluation reservee a l''administration';
begin
  perform pg_temp.ev_ok('EV-02 sans session',
    pg_temp.ev_essai(null, null, null, v_sql) = v_msg);
  perform pg_temp.ev_ok('EV-02 tuteur',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000003', 'guardian', 'e2f00000-0000-0000-0000-000000000001', v_sql) = v_msg);
  perform pg_temp.ev_ok('EV-02 eleve',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000004', 'student', 'e2f00000-0000-0000-0000-000000000001', v_sql) = v_msg);
  perform pg_temp.ev_ok('EV-02 enseignant',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000002', 'teacher', null, v_sql) = v_msg);
  perform pg_temp.ev_ok('EV-02 admin compte non valide',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000008', 'admin', null, v_sql) = v_msg);
  perform pg_temp.ev_ok('EV-02 aucune ligne creee',
    (select count(*) from public.evaluation_publications) = 0
    and (select count(*) from private.evaluation_codes) = 0);
end
$refus_admin$;

-- EV-03 : refus de validation (admin valide).
do $validation$
declare
  v_admin uuid := 'e2000000-0000-0000-0000-000000000001';
begin
  perform pg_temp.ev_ok('EV-03 titre vide',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.publier_evaluation(''e2800000-0000-0000-0000-000000000001'', ''  '', ''code'')')
      = 'un titre est requis pour publier une evaluation');
  perform pg_temp.ev_ok('EV-03 affichage invalide',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.publier_evaluation(''e2800000-0000-0000-0000-000000000001'', ''T'', ''matricule'')')
      = 'affichage invalide : code, nom ou les_deux');
  perform pg_temp.ev_ok('EV-03 affichage nul',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.publier_evaluation(''e2800000-0000-0000-0000-000000000001'', ''T'', null)')
      = 'affichage invalide : code, nom ou les_deux');
  perform pg_temp.ev_ok('EV-03 groupe inconnu',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.publier_evaluation(''e2800000-0000-0000-0000-0000000000ff'', ''T'', ''code'')')
      = 'ce groupe n''existe pas ou est cloture');
  perform pg_temp.ev_ok('EV-03 groupe cloture',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.publier_evaluation(''e2800000-0000-0000-0000-000000000003'', ''T'', ''code'')')
      = 'ce groupe n''existe pas ou est cloture');
  perform pg_temp.ev_ok('EV-03 groupe sans eleve actif',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.publier_evaluation(''e2800000-0000-0000-0000-000000000002'', ''T'', ''code'')')
      = 'ce groupe n''a aucun eleve actif');
  perform pg_temp.ev_ok('EV-03 rien d''ecrit',
    (select count(*) from public.evaluation_publications) = 0
    and (select count(*) from private.evaluation_codes) = 0);
end
$validation$;

-- EV-04 : publication nominale, trois eleves actifs, l'ancien membre exclu.
select pg_temp.ev_as('e2000000-0000-0000-0000-000000000001', 'admin');
set local role authenticated;
select public.publier_evaluation('e2800000-0000-0000-0000-000000000001', 'Evaluation un', 'code') as pub1 \gset
reset role;
do $nominal$
declare
  v_pub uuid := (select id from public.evaluation_publications where titre = 'Evaluation un');
begin
  perform pg_temp.ev_ok('EV-04 une ligne par eleve actif',
    (select count(*) from private.evaluation_codes where publication_id = v_pub) = 3
    and not exists (select 1 from private.evaluation_codes
                     where student_id = 'e2000000-0000-0000-0000-000000000009'));
  perform pg_temp.ev_ok('EV-04 format EV-NNNN',
    not exists (select 1 from private.evaluation_codes where code !~ '^EV-[0-9]{4}$'));
  perform pg_temp.ev_ok('EV-04 codes distincts',
    (select count(distinct code) from private.evaluation_codes where publication_id = v_pub) = 3);
  perform pg_temp.ev_ok('EV-04 distinct du matricule',
    not exists (select 1 from private.evaluation_codes c
                  join public.profiles p on p.id = c.student_id
                 where c.code = p.immutable_id));
  perform pg_temp.ev_ok('EV-04 audit',
    exists (select 1 from public.audit_logs a where a.action = 'evaluation_publiee'));
end
$nominal$;

-- EV-05 : collisions forcees, le tirage reessaie et les codes restent uniques.
create or replace function private.tirer_nombre_evaluation()
returns integer language plpgsql security definer set search_path = '' as $forced$
declare
  v_n integer;
begin
  v_n := coalesce(nullif(current_setting('ev.tirages', true), '')::integer, 0) + 1;
  perform set_config('ev.tirages', v_n::text, true);
  return case when v_n <= 3 then 7 when v_n <= 5 then 8 else 8 + v_n end;
end;
$forced$;
select pg_temp.ev_as('e2000000-0000-0000-0000-000000000001', 'admin');
set local role authenticated;
select public.publier_evaluation('e2800000-0000-0000-0000-000000000001', 'Evaluation collision', 'code');
reset role;
do $collision$
declare
  v_pub uuid := (select id from public.evaluation_publications where titre = 'Evaluation collision');
begin
  perform pg_temp.ev_ok('EV-05 collisions absorbees',
    (select count(*) from private.evaluation_codes where publication_id = v_pub) = 3
    and (select count(distinct code) from private.evaluation_codes where publication_id = v_pub) = 3
    and exists (select 1 from private.evaluation_codes where publication_id = v_pub and code = 'EV-0007')
    and current_setting('ev.tirages')::integer > 3);
  -- Un meme code peut exister dans deux publications differentes.
  perform pg_temp.ev_ok('EV-05 unicite limitee a la publication',
    (select count(*) from private.evaluation_codes where code = 'EV-0007') >= 1);
  begin
    insert into private.evaluation_codes (publication_id, student_id, code)
    values (v_pub, 'e2000000-0000-0000-0000-000000000009', 'EV-0007');
    raise exception 'EV-05: doublon accepte';
  exception when unique_violation then
    perform pg_temp.ev_ok('EV-05 contrainte unique en base', true);
  end;
  begin
    insert into private.evaluation_codes (publication_id, student_id, code)
    values (v_pub, 'e2000000-0000-0000-0000-000000000004', 'EV-1111');
    raise exception 'EV-05: deuxieme code pour le meme eleve accepte';
  exception when unique_violation then
    perform pg_temp.ev_ok('EV-05 un seul code par eleve et par publication', true);
  end;
end
$collision$;

-- EV-06 : affichage choisi par l'administration, filtre par le serveur.
do $affichage$
declare
  v_admin uuid := 'e2000000-0000-0000-0000-000000000001';
  v_pub uuid := (select id from public.evaluation_publications where titre = 'Evaluation un');
  v_n integer;
begin
  perform pg_temp.ev_ok('EV-06 changement refuse au tuteur',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000003', 'guardian', 'e2f00000-0000-0000-0000-000000000001',
      'select public.changer_affichage_evaluation(''' || v_pub || ''', ''nom'')')
      = 'choix de l''affichage reserve a l''administration');
  perform pg_temp.ev_ok('EV-06 changement refuse sans session',
    pg_temp.ev_essai(null, null, null,
      'select public.changer_affichage_evaluation(''' || v_pub || ''', ''nom'')')
      = 'choix de l''affichage reserve a l''administration');
  perform pg_temp.ev_ok('EV-06 valeur invalide',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.changer_affichage_evaluation(''' || v_pub || ''', ''tout'')')
      = 'affichage invalide : code, nom ou les_deux');
  perform pg_temp.ev_ok('EV-06 publication inconnue',
    pg_temp.ev_essai(v_admin, 'admin', null,
      'select public.changer_affichage_evaluation(''e2900000-0000-0000-0000-0000000000ff'', ''nom'')')
      = 'publication introuvable');
  perform pg_temp.ev_ok('EV-06 affichage inchange apres refus',
    (select affichage from public.evaluation_publications where id = v_pub) = 'code');

  perform pg_temp.ev_as(v_admin, 'admin');
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub)
   where code is not null and first_name is null and last_name is null;
  perform pg_temp.ev_ok('EV-06 mode code : codes sans nom', v_n = 3);

  perform public.changer_affichage_evaluation(v_pub, 'nom');
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub)
   where code is null and first_name is not null and last_name is not null;
  perform pg_temp.ev_ok('EV-06 mode nom : noms sans code', v_n = 3);

  perform public.changer_affichage_evaluation(v_pub, 'les_deux');
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub)
   where code is not null and first_name is not null and last_name is not null;
  perform pg_temp.ev_ok('EV-06 mode les deux', v_n = 3);
  perform pg_temp.ev_ok('EV-06 admin lit les publications',
    (select count(*) from public.evaluation_publications) = 2);
  reset role;
  perform pg_temp.ev_ok('EV-06 audit du changement',
    exists (select 1 from public.audit_logs a where a.action = 'evaluation_affichage_change'));
  update public.evaluation_publications set affichage = 'code' where id = v_pub;
end
$affichage$;

-- EV-07 : lecture par les non-admins, bornee a soi et au foyer.
do $lecture$
declare
  v_pub uuid := (select id from public.evaluation_publications where titre = 'Evaluation un');
  v_n integer;
  v_names integer;
begin
  perform pg_temp.ev_as('e2000000-0000-0000-0000-000000000004', 'student', 'e2f00000-0000-0000-0000-000000000001');
  set local role authenticated;
  select count(*), count(first_name) into v_n, v_names from public.evaluation_publiee_lignes(v_pub);
  reset role;
  perform pg_temp.ev_ok('EV-07 eleve : son seul code',
    v_n = 1 and v_names = 0
    and (select count(*) from private.evaluation_codes
          where publication_id = v_pub and student_id = 'e2000000-0000-0000-0000-000000000004') = 1);

  perform pg_temp.ev_as('e2000000-0000-0000-0000-000000000003', 'guardian', 'e2f00000-0000-0000-0000-000000000001');
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub);
  reset role;
  perform pg_temp.ev_ok('EV-07 tuteur : les deux enfants du foyer', v_n = 2);

  perform pg_temp.ev_as('e2000000-0000-0000-0000-000000000007', 'guardian', 'e2f00000-0000-0000-0000-000000000002');
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub);
  reset role;
  perform pg_temp.ev_ok('EV-07 autre foyer : un seul enfant', v_n = 1);

  perform pg_temp.ev_as('e2000000-0000-0000-0000-000000000002', 'teacher');
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub);
  reset role;
  perform pg_temp.ev_ok('EV-07 enseignant : aucune ligne', v_n = 0);

  perform pg_temp.ev_as(null, null);
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub);
  reset role;
  perform pg_temp.ev_ok('EV-07 sans session : aucune ligne', v_n = 0);

  perform pg_temp.ev_as('e2000000-0000-0000-0000-000000000008', 'admin');
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publiee_lignes(v_pub);
  reset role;
  perform pg_temp.ev_ok('EV-07 admin non valide : aucune ligne', v_n = 0);

  perform pg_temp.ev_as('e2000000-0000-0000-0000-000000000003', 'guardian', 'e2f00000-0000-0000-0000-000000000001');
  set local role authenticated;
  select count(*) into v_n from public.evaluation_publications;
  reset role;
  perform pg_temp.ev_ok('EV-07 RLS : tuteur ne lit pas les publications', v_n = 0);

  perform pg_temp.ev_ok('EV-07 lecture directe des codes refusee',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000003', 'guardian', 'e2f00000-0000-0000-0000-000000000001',
      'select * from private.evaluation_codes') like 'permission denied%');
  perform pg_temp.ev_ok('EV-07 ecriture directe des publications refusee',
    pg_temp.ev_essai('e2000000-0000-0000-0000-000000000001', 'admin', null,
      'insert into public.evaluation_publications (groupe_id, titre) values (''e2800000-0000-0000-0000-000000000001'', ''x'')')
      like 'permission denied%');
end
$lecture$;

do $bilan$
begin
  raise notice 'IMM-BACK-2: % controles verts', (select count(*) from pg_temp.ev_controles);
end
$bilan$;

rollback;
