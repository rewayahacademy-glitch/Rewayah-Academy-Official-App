-- D1-bis (03/11/2026) : la direction traite un signalement d'enseignant.
--   1. seule une direction au compte valide examine, redige, transmet, clot ;
--   2. l'ordre est tenu : ouvert -> en_examen ; ouvert ou en_examen ->
--      transmis ; tout statut -> clos ; rien apres clos ;
--   3. la file rend, par ligne, ce que la direction peut faire ;
--   4. le motif de cloture suit le reglage (propose : securite d'un enfant) ;
--   5. chaque changement ecrit le journal ;
--   6. la famille garde ce qui lui a ete transmis apres la cloture.
-- Base PostgreSQL jetable apres rejeu des migrations.
begin;

insert into auth.users (id, email) values
  ('d1b00000-0000-0000-0000-000000000001', 'd1b-admin@example.test'),
  ('d1b00000-0000-0000-0000-000000000002', 'd1b-teacher@example.test'),
  ('d1b00000-0000-0000-0000-000000000003', 'd1b-guardian@example.test'),
  ('d1b00000-0000-0000-0000-000000000004', 'd1b-student@example.test'),
  ('d1b00000-0000-0000-0000-000000000005', 'd1b-admin-off@example.test');

insert into public.households (id, timezone)
values ('d1bfffff-0000-0000-0000-000000000001', 'Europe/Paris');

insert into public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
values
  ('d1b00000-0000-0000-0000-000000000001', 'D1BADMIN00001', 'admin',
   'd1bfffff-0000-0000-0000-000000000001', 'Fixture', 'Admin', 'active', 'male'),
  ('d1b00000-0000-0000-0000-000000000002', 'D1BTEACHER001', 'teacher',
   'd1bfffff-0000-0000-0000-000000000001', 'Teacher', 'One', 'provisional_active', 'male'),
  ('d1b00000-0000-0000-0000-000000000003', 'D1BGUARDIAN01', 'guardian',
   'd1bfffff-0000-0000-0000-000000000001', 'Fixture', 'Guardian', 'active', 'female'),
  ('d1b00000-0000-0000-0000-000000000004', 'D1BSTUDENT001', 'student',
   'd1bfffff-0000-0000-0000-000000000001', 'Fixture', 'Student', 'active', 'male'),
  ('d1b00000-0000-0000-0000-000000000005', 'D1BADMIN00002', 'admin',
   'd1bfffff-0000-0000-0000-000000000001', 'Admin', 'Off', 'disabled', 'male');

insert into public.teacher_profiles
  (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
values
  ('d1b00000-0000-0000-0000-000000000002', array['francais'], 10, 'approved', 'Europe/Paris');

update public.households
   set primary_guardian_id = 'd1b00000-0000-0000-0000-000000000003'
 where id = 'd1bfffff-0000-0000-0000-000000000001';

insert into public.student_profiles (profile_id, student_type, interface_mode)
values ('d1b00000-0000-0000-0000-000000000004', 'minor', 'child');

insert into public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
values
  ('d1bfffff-0000-0000-0000-000000000002',
   'd1b00000-0000-0000-0000-000000000002', 'enfant', 5, 'D1B groupe', 1, 10);

insert into public.groupe_membres (groupe_id, student_id)
values ('d1bfffff-0000-0000-0000-000000000002',
        'd1b00000-0000-0000-0000-000000000004');

create temporary table d1b_ids (nom text primary key, id uuid not null);
grant select, insert on d1b_ids to authenticated;

-- ===========================================================================
-- 1. L'enseignant depose trois signalements
-- ===========================================================================
set local role authenticated;
select set_config('test.uid', 'd1b00000-0000-0000-0000-000000000002', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"teacher","household_id":"d1bfffff-0000-0000-0000-000000000001"}}',
  true);

do $depot$
begin
  insert into d1b_ids values
    ('pedago', (public.deposer_student_concern(
      'pedagogique', 'd1bfffff-0000-0000-0000-000000000002', null,
      'D1BSTUDENT001', 'D1B note pedagogique', null) ->> 'id')::uuid),
    ('securite', (public.deposer_student_concern(
      'securite_enfant', 'd1bfffff-0000-0000-0000-000000000002', null,
      'D1BSTUDENT001', 'D1B note securite', null) ->> 'id')::uuid),
    ('presence', (public.deposer_student_concern(
      'presence', 'd1bfffff-0000-0000-0000-000000000002', null,
      'D1BSTUDENT001', 'D1B note presence', 'D1B message presence') ->> 'id')::uuid);

  -- L'enseignant ne traite pas.
  begin
    perform public.examiner_student_concern((select id from d1b_ids where nom = 'pedago'));
    raise exception 'D1B: un enseignant a examine un signalement';
  exception when raise_exception then
    if sqlerrm <> 'traitement de signalement reserve a un admin actif' then raise; end if;
  end;
  begin
    perform public.clore_student_concern((select id from d1b_ids where nom = 'pedago'), 'x');
    raise exception 'D1B: un enseignant a clos un signalement';
  exception when raise_exception then
    if sqlerrm <> 'traitement de signalement reserve a un admin actif' then raise; end if;
  end;
  begin
    perform public.rediger_resume_student_concern((select id from d1b_ids where nom = 'pedago'), 'x');
    raise exception 'D1B: un enseignant a redige le resume';
  exception when raise_exception then
    if sqlerrm <> 'traitement de signalement reserve a un admin actif' then raise; end if;
  end;
  -- Et la table ne s'ecrit pas directement.
  begin
    update public.student_concern set statut = 'clos';
    raise exception 'D1B: la table a ete ecrite directement';
  exception when insufficient_privilege then null;
  end;
end
$depot$;

-- ===========================================================================
-- 2. Ni la famille, ni une direction au compte desactive
-- ===========================================================================
select set_config('test.uid', 'd1b00000-0000-0000-0000-000000000003', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d1bfffff-0000-0000-0000-000000000001"}}',
  true);
do $famille$
begin
  begin
    perform public.examiner_student_concern((select id from d1b_ids where nom = 'pedago'));
    raise exception 'D1B: un tuteur a examine un signalement';
  exception when raise_exception then
    if sqlerrm <> 'traitement de signalement reserve a un admin actif' then raise; end if;
  end;
end
$famille$;

select set_config('test.uid', 'd1b00000-0000-0000-0000-000000000005', true);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);
do $desactive$
begin
  begin
    perform public.examiner_student_concern((select id from d1b_ids where nom = 'pedago'));
    raise exception 'D1B: une direction desactivee a examine';
  exception when raise_exception then
    if sqlerrm <> 'traitement de signalement reserve a un admin actif' then raise; end if;
  end;
  begin
    perform public.clore_student_concern((select id from d1b_ids where nom = 'pedago'), 'x');
    raise exception 'D1B: une direction desactivee a clos';
  exception when raise_exception then
    if sqlerrm <> 'traitement de signalement reserve a un admin actif' then raise; end if;
  end;
end
$desactive$;

-- ===========================================================================
-- 3. La direction : file, capacites, examen, resume, transmission, cloture
-- ===========================================================================
select set_config('test.uid', 'd1b00000-0000-0000-0000-000000000001', true);
select set_config('test.jwt', '{"app_metadata":{"role":"admin"}}', true);

do $direction$
declare
  v_pedago uuid := (select id from d1b_ids where nom = 'pedago');
  v_securite uuid := (select id from d1b_ids where nom = 'securite');
  v_presence uuid := (select id from d1b_ids where nom = 'presence');
  v_ligne jsonb;
  v_n integer;
begin
  -- La securite d'un enfant en tete ; capacites par ligne.
  select s into v_ligne from public.signalements_ouverts_direction() s limit 1;
  if (v_ligne ->> 'id')::uuid <> v_securite then
    raise exception 'D1B: la securite d un enfant doit etre en tete: %', v_ligne;
  end if;
  if (v_ligne ->> 'peut_rediger')::boolean or (v_ligne ->> 'peut_transmettre')::boolean
     or not (v_ligne ->> 'peut_examiner')::boolean or not (v_ligne ->> 'peut_clore')::boolean
     or not (v_ligne ->> 'motif_cloture_requis')::boolean then
    raise exception 'D1B: capacites de la securite d un enfant fausses: %', v_ligne;
  end if;

  select s into v_ligne from public.signalements_ouverts_direction() s
   where (s ->> 'id')::uuid = v_pedago;
  if v_ligne ->> 'cible' <> 'tuteur_du_mineur'
     or (v_ligne ->> 'peut_transmettre')::boolean
     or not (v_ligne ->> 'peut_rediger')::boolean
     or (v_ligne ->> 'motif_cloture_requis')::boolean
     or v_ligne ->> 'statut' <> 'ouvert' then
    raise exception 'D1B: capacites du signalement pedagogique fausses: %', v_ligne;
  end if;

  -- Examiner : une fois, depuis ouvert seulement.
  perform public.examiner_student_concern(v_pedago);
  begin
    perform public.examiner_student_concern(v_pedago);
    raise exception 'D1B: double examen accepte';
  exception when raise_exception then
    if sqlerrm <> 'seul un signalement ouvert passe en examen' then raise; end if;
  end;
  begin
    perform public.examiner_student_concern('00000000-0000-0000-0000-000000000000');
    raise exception 'D1B: signalement inconnu examine';
  exception when raise_exception then
    if sqlerrm <> 'signalement introuvable' then raise; end if;
  end;

  -- Resume : refuse pour la securite d'un enfant, refuse vide.
  begin
    perform public.rediger_resume_student_concern(v_securite, 'Un message');
    raise exception 'D1B: resume accepte pour la securite d un enfant';
  exception when raise_exception then
    if sqlerrm <> 'signalement de securite d''un enfant sans message famille' then raise; end if;
  end;
  begin
    perform public.rediger_resume_student_concern(v_pedago, '   ');
    raise exception 'D1B: resume vide accepte';
  exception when raise_exception then
    if sqlerrm <> 'resume famille vide' then raise; end if;
  end;
  perform public.rediger_resume_student_concern(v_pedago, '  D1B resume pour la famille ');

  select s into v_ligne from public.signalements_ouverts_direction() s
   where (s ->> 'id')::uuid = v_pedago;
  if v_ligne ->> 'statut' <> 'en_examen'
     or v_ligne ->> 'family_summary' <> 'D1B resume pour la famille'
     or not (v_ligne ->> 'peut_transmettre')::boolean
     or (v_ligne ->> 'peut_examiner')::boolean then
    raise exception 'D1B: apres examen et resume, ligne fausse: %', v_ligne;
  end if;

  -- Transmettre (la fonction existante), puis plus de resume ni d'examen.
  perform public.transmettre_student_concern(v_pedago, 'tuteur_du_mineur');
  begin
    perform public.rediger_resume_student_concern(v_pedago, 'Autre');
    raise exception 'D1B: resume modifie apres transmission';
  exception when raise_exception then
    if sqlerrm <> 'resume modifiable avant transmission seulement' then raise; end if;
  end;
  begin
    perform public.examiner_student_concern(v_pedago);
    raise exception 'D1B: examen apres transmission';
  exception when raise_exception then
    if sqlerrm <> 'seul un signalement ouvert passe en examen' then raise; end if;
  end;
  select s into v_ligne from public.signalements_ouverts_direction() s
   where (s ->> 'id')::uuid = v_pedago;
  if v_ligne ->> 'statut' <> 'transmis' or (v_ligne ->> 'peut_transmettre')::boolean
     or (v_ligne ->> 'peut_rediger')::boolean or not (v_ligne ->> 'peut_clore')::boolean then
    raise exception 'D1B: ligne transmise fausse: %', v_ligne;
  end if;

  -- Clore la securite d'un enfant : motif exige par le reglage propose.
  begin
    perform public.clore_student_concern(v_securite, '  ');
    raise exception 'D1B: securite d un enfant close sans motif';
  exception when raise_exception then
    if sqlerrm <> 'motif de cloture requis' then raise; end if;
  end;
  begin
    perform public.clore_student_concern(v_securite, pg_catalog.repeat('x', 1001));
    raise exception 'D1B: motif trop long accepte';
  exception when raise_exception then
    if sqlerrm <> 'motif de cloture trop long' then raise; end if;
  end;
  perform public.clore_student_concern(v_securite, 'D1B motif securite');
  begin
    perform public.clore_student_concern(v_securite, 'encore');
    raise exception 'D1B: double cloture acceptee';
  exception when raise_exception then
    if sqlerrm <> 'signalement deja clos' then raise; end if;
  end;
  begin
    perform public.examiner_student_concern(v_securite);
    raise exception 'D1B: examen apres cloture';
  exception when raise_exception then
    if sqlerrm <> 'seul un signalement ouvert passe en examen' then raise; end if;
  end;

  -- Clore un signalement transmis, sans motif : permis hors securite.
  perform public.clore_student_concern(v_pedago, null);

  -- Clore un signalement ouvert qui a un message, puis la transmission est refusee.
  perform public.clore_student_concern(v_presence);
  begin
    perform public.transmettre_student_concern(v_presence, 'tuteur_du_mineur');
    raise exception 'D1B: signalement clos transmis';
  exception when raise_exception then
    if sqlerrm <> 'signalement clos, transmission refusee' then raise; end if;
  end;

  -- Un signalement clos sort de la file.
  select count(*) into v_n from public.signalements_ouverts_direction() s
   where (s ->> 'id')::uuid in (v_pedago, v_securite, v_presence);
  if v_n <> 0 then
    raise exception 'D1B: un signalement clos reste dans la file (%)', v_n;
  end if;
end
$direction$;

-- ===========================================================================
-- 4. La famille garde ce qui lui a ete transmis
-- ===========================================================================
select set_config('test.uid', 'd1b00000-0000-0000-0000-000000000003', true);
select set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"d1bfffff-0000-0000-0000-000000000001"}}',
  true);
do $vue$
declare
  v_n integer;
begin
  select count(*) into v_n from public.concern_famille_v
   where id = (select id from d1b_ids where nom = 'pedago')
     and family_summary = 'D1B resume pour la famille';
  if v_n <> 1 then
    raise exception 'D1B: la famille a perdu le message transmis apres cloture (%)', v_n;
  end if;
  -- Jamais ce qui n'a pas ete transmis, ni la securite d'un enfant.
  select count(*) into v_n from public.concern_famille_v
   where id in (select id from d1b_ids where nom in ('securite', 'presence'));
  if v_n <> 0 then
    raise exception 'D1B: la famille lit un signalement non transmis (%)', v_n;
  end if;
end
$vue$;

-- ===========================================================================
-- 5. Le journal, et le reglage
-- ===========================================================================
reset role;
do $journal$
declare
  v_n integer;
  v_motif text;
begin
  select count(*) into v_n from public.audit_logs
   where table_name = 'student_concern'
     and row_id in (select id::text from d1b_ids)
     and action in ('student_concern_en_examen', 'student_concern_resume_redige',
                    'student_concern_transmis', 'student_concern_clos');
  -- examen, resume, transmission (pedago) ; trois clotures.
  if v_n <> 6 then
    raise exception 'D1B: journal incomplet (% lignes, 6 attendues)', v_n;
  end if;
  select payload ->> 'motif' into v_motif from public.audit_logs
   where action = 'student_concern_clos'
     and row_id = (select id::text from d1b_ids where nom = 'securite');
  if v_motif is distinct from 'D1B motif securite' then
    raise exception 'D1B: motif absent du journal (%)', v_motif;
  end if;

  -- Le reglage refuse une categorie inconnue ou en double.
  begin
    update public.app_config set value = '["inconnue"]'::jsonb
     where key = 'signalements.motif_cloture_obligatoire';
    raise exception 'D1B: categorie inconnue acceptee dans le reglage';
  exception when raise_exception then
    if sqlerrm <> 'reglage du motif de cloture : categorie inconnue' then raise; end if;
  end;
  begin
    update public.app_config set value = '["autre","autre"]'::jsonb
     where key = 'signalements.motif_cloture_obligatoire';
    raise exception 'D1B: doublon accepte dans le reglage';
  exception when raise_exception then
    if sqlerrm <> 'reglage du motif de cloture : categorie en double' then raise; end if;
  end;
  begin
    update public.app_config set value = '"securite_enfant"'::jsonb
     where key = 'signalements.motif_cloture_obligatoire';
    raise exception 'D1B: reglage hors liste accepte';
  exception when raise_exception then
    if sqlerrm <> 'reglage du motif de cloture : une liste de categories est attendue' then raise; end if;
  end;

  -- Le reglage est lu, jamais en dur.
  update public.app_config set value = '["pedagogique"]'::jsonb
   where key = 'signalements.motif_cloture_obligatoire';
  if private.d1bis_motif_cloture_requis('securite_enfant')
     or not private.d1bis_motif_cloture_requis('pedagogique') then
    raise exception 'D1B: le reglage n est pas lu';
  end if;

  -- Les fonctions privees ne sont pas appelables.
  if pg_catalog.has_function_privilege('authenticated',
       'private.d1bis_motif_cloture_requis(text)', 'EXECUTE')
     or pg_catalog.has_function_privilege('authenticated',
       'private.d1bis_cible_transmission(uuid)', 'EXECUTE')
     or pg_catalog.has_function_privilege('anon',
       'public.clore_student_concern(uuid,text)', 'EXECUTE') then
    raise exception 'D1B: droits trop larges';
  end if;
end
$journal$;

rollback;
