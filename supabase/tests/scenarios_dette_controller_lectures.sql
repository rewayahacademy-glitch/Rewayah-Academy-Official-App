-- DETTE-CONTROLLER (migration 20261129800000) : un controleur ne lit que ce que sa capacite
-- de controle justifie. Sur neuf tables :
--   rouge avant la migration : un controleur SANS capacite lisait tout ;
--   vert apres : 0 ligne ; avec capacite et mission, seulement la seance de sa mission
--   (sessions, participants, evenements, enregistrements) ; rien sur les cinq autres tables ;
--   admin, comptable, famille et enseignant inchanges.
-- La fixture reprend celle de N3-D (scenarios_n3_compte_rendu_controleur.sql).
--      etape de connexion sont refuses (envoi et roster).
-- La fixture reprend celle de B-12 (scenarios_b12_control_mission.sql).
BEGIN;

INSERT INTO auth.users(id,email) VALUES
 ('dc700000-0000-0000-0000-000000000001','dc7-admin@test.invalid'),
 ('dc700000-0000-0000-0000-000000000002','dc7-controller@test.invalid'),
 ('dc700000-0000-0000-0000-000000000003','dc7-other@test.invalid'),
 ('dc700000-0000-0000-0000-000000000004','dc7-teacher@test.invalid'),
 ('dc700000-0000-0000-0000-000000000005','dc7-student@test.invalid'),
 ('dc700000-0000-0000-0000-000000000099','dc7-admin-no-profile@test.invalid');
INSERT INTO public.households(id,timezone)
VALUES ('dc740000-0000-0000-0000-000000000001','Europe/Paris');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender)
VALUES
 ('dc700000-0000-0000-0000-000000000001','DC7-ADMIN-0001','admin',NULL,'Direction','DC7','active','female'),
 ('dc700000-0000-0000-0000-000000000002','DC7-CTRL-00001','controller',NULL,'Controleur','DC7','active','male'),
 ('dc700000-0000-0000-0000-000000000003','DC7-CTRL-00002','controller',NULL,'Autre','DC7','active','female'),
 ('dc700000-0000-0000-0000-000000000004','DC7-TEACH-0001','teacher',NULL,'Enseignant','DC7','provisional_active','male'),
 ('dc700000-0000-0000-0000-000000000005','DC7-STUD-00001','student','dc740000-0000-0000-0000-000000000001','Élève','Présent','active','female');
INSERT INTO public.teacher_profiles(profile_id,kyc_status)
VALUES ('dc700000-0000-0000-0000-000000000004','approved');

DO $fixture_teacher_contract$
DECLARE
  v_teacher_version text;
  v_notice_version text;
BEGIN
  SELECT version INTO v_teacher_version
  FROM public.contract_texts
  WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
  SELECT version INTO v_notice_version
  FROM public.contract_required_versions
  WHERE contract_kind='recording_and_control_notice';
  PERFORM set_config('request.jwt.claim.sub','dc700000-0000-0000-0000-000000000004',true);
  PERFORM set_config('test.uid','dc700000-0000-0000-0000-000000000004',true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant DC7');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('dc700000-0000-0000-0000-000000000004',
          'recording_and_control_notice',v_notice_version);
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES ('dc700000-0000-0000-0000-000000000004','teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active'
  WHERE id='dc700000-0000-0000-0000-000000000004';
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_teacher_contract$;
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('dc710000-0000-0000-0000-000000000001','dc700000-0000-0000-0000-000000000004',
        'enfant',5,'Classe DC7',1,9,'Europe/Paris');
INSERT INTO public.groupes(id,teacher_id,type_public,seuil_max,libelle,weekday,hour_local,timezone_iana)
VALUES ('dc710000-0000-0000-0000-000000000002','dc700000-0000-0000-0000-000000000004',
        'enfant',5,'Classe DC7 scope autre',2,10,'Europe/Paris');
-- Horloge : une classe active avec son enseignant recoit, a sa creation, ses
-- prochaines seances hebdomadaires (tc_materialiser_apres_creation_groupe). Selon
-- l'heure a laquelle la CI tourne, l'une d'elles chevauche une seance que ce scenario
-- fixe a now() + ... (sessions_no_teacher_overlap, 23P01) : il echouait a certains
-- creneaux de la semaine. Il pose ses propres seances ; celles de l'horaire recurrent
-- n'ont rien a faire ici et se retirent, ce qui le rend independant de l'heure sans
-- changer un seul de ses controles (meme correction que scenarios_fn025_motif_refus_salle).
DELETE FROM public.sessions
 WHERE groupe_id IN ('dc710000-0000-0000-0000-000000000001', 'dc710000-0000-0000-0000-000000000002');

INSERT INTO public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,session_type)
VALUES ('dc720000-0000-0000-0000-000000000001','dc700000-0000-0000-0000-000000000004',
        'dc710000-0000-0000-0000-000000000001',now()-interval '1 hour',now()+interval '1 hour',
        'planned','standard');
INSERT INTO public.session_participants(session_id,profile_id,role,entered_at)
VALUES ('dc720000-0000-0000-0000-000000000001',
        'dc700000-0000-0000-0000-000000000005','student',now()-interval '30 minutes');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('dc700000-0000-0000-0000-000000000002','dc700000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',true,'{}','{}',
        'dc730000-0000-0000-0000-000000000001');
INSERT INTO private.controle_capacites
 (profile_id,approved_by,active_from,expires_at,scope_all_groups,scope_group_ids,
  scope_teacher_ids,grant_idempotency_key)
VALUES ('dc700000-0000-0000-0000-000000000003','dc700000-0000-0000-0000-000000000001',
        now()-interval '1 day',now()+interval '1 day',false,
        ARRAY['dc710000-0000-0000-0000-000000000002'::uuid],'{}',
        'dc730000-0000-0000-0000-000000000002');

DO $fixture_control_rules$
BEGIN
  PERFORM set_config('request.jwt.claim.sub','dc700000-0000-0000-0000-000000000001',true);
  PERFORM set_config('test.uid','dc700000-0000-0000-0000-000000000001',true);
  PERFORM set_config('request.jwt.claims','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
  PERFORM set_config('test.jwt','{"aal":"aal2","app_metadata":{"role":"admin"}}',true);
  PERFORM public.enregistrer_regles_tirage(
    '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"},"cibles":[{"id":"dc700000-0000-0000-0000-000000000004","type":"enseignant"}]}'::jsonb,
    'dc730000-0000-0000-0000-000000000020'
  );
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('test.uid','',true);
  PERFORM set_config('request.jwt.claims','',true);
  PERFORM set_config('test.jwt','',true);
END
$fixture_control_rules$;

-- La mission est créée par le trigger serveur du cycle de séance, jamais par
-- insertion directe dans controle_missions; son démarrage passe par la RPC.
UPDATE public.sessions SET status='preflight'
 WHERE id='dc720000-0000-0000-0000-000000000001';
UPDATE public.sessions SET status='in_progress'
 WHERE id='dc720000-0000-0000-0000-000000000001';

-- Lignes a lire (posees avec les droits du proprietaire) dans les cinq tables sans lien avec le controle.
INSERT INTO auth.users(id,email) VALUES
 ('dc700000-0000-0000-0000-000000000006','dc7-sanscap@test.invalid'),
 ('dc700000-0000-0000-0000-000000000007','dc7-guard@test.invalid'),
 ('dc700000-0000-0000-0000-000000000008','dc7-acct@test.invalid');
INSERT INTO public.profiles(id,immutable_id,role,household_id,first_name,last_name,account_status,gender)
VALUES
 ('dc700000-0000-0000-0000-000000000006','DC7-CTRL-00003','controller',NULL,'SansCapacite','DC7','active','male'),
 ('dc700000-0000-0000-0000-000000000007','DC7-GUARD-0001','guardian','dc740000-0000-0000-0000-000000000001','Tuteur','DC7','active','female'),
 ('dc700000-0000-0000-0000-000000000008','DC7-ACCT-00001','accountant',NULL,'Comptable','DC7','active','female');
INSERT INTO public.availability_slots(teacher_id,starts_at,ends_at)
VALUES ('dc700000-0000-0000-0000-000000000004',now()+interval '2 days',now()+interval '2 days 1 hour');
INSERT INTO public.offres_horaires(type_public,langue_code,fuseau_iana,jours,heure_locale,duree_minutes,etat)
VALUES ('enfant','francais','Europe/Paris',ARRAY[1]::smallint[],18,60,'brouillon');
INSERT INTO public.intentions_horaire(eleve_id,offre_id,fuseau_affiche,heure_affichee,jours_affiches,created_by)
SELECT 'dc700000-0000-0000-0000-000000000005',(SELECT id FROM public.offres_horaires WHERE etat='brouillon' LIMIT 1),'Europe/Paris',18,ARRAY[1]::smallint[],
        'dc700000-0000-0000-0000-000000000001';
INSERT INTO public.matching_requests(kind,subject_profile_id,reason,requested_by,requester_role)
VALUES ('capacity','dc700000-0000-0000-0000-000000000005','test',
        'dc700000-0000-0000-0000-000000000001','admin');
INSERT INTO public.teacher_student_assignments(teacher_id,student_id,weekday,hour_local)
VALUES ('dc700000-0000-0000-0000-000000000004','dc700000-0000-0000-0000-000000000005',1,9);
INSERT INTO public.weekly_availability(profile_id,weekday,hour_local)
VALUES ('dc700000-0000-0000-0000-000000000004',1,9);
INSERT INTO public.rule_overrides(profile_id,key,value,reason,set_by)
VALUES ('dc700000-0000-0000-0000-000000000004','max_students_per_teacher','3'::jsonb,'test',
        'dc700000-0000-0000-0000-000000000001');
INSERT INTO public.session_events(session_id,event_type)
SELECT 'dc720000-0000-0000-0000-000000000001'::uuid, e FROM (SELECT (enum_range(NULL::public.session_event_type))[1] e) x;
INSERT INTO public.session_recordings(session_id,object_key,duration_seconds,size_bytes,expires_at)
VALUES ('dc720000-0000-0000-0000-000000000001','k/dc7',10,10,now()+interval '1 day');
-- une seconde seance, hors de toute mission du controleur
INSERT INTO public.sessions(id,teacher_id,groupe_id,started_at,ended_at,status,session_type)
VALUES ('dc720000-0000-0000-0000-000000000002','dc700000-0000-0000-0000-000000000004',
        'dc710000-0000-0000-0000-000000000002',now()+interval '3 days',now()+interval '3 days 1 hour','planned','standard');
INSERT INTO public.session_participants(session_id,profile_id,role)
VALUES ('dc720000-0000-0000-0000-000000000002','dc700000-0000-0000-0000-000000000005','student');
INSERT INTO public.session_recordings(session_id,object_key,duration_seconds,size_bytes,expires_at)
VALUES ('dc720000-0000-0000-0000-000000000002','k/dc7b',10,10,now()+interval '1 day');

CREATE FUNCTION pg_temp.comme(p_uid uuid, p_role text, p_aal text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  RESET ROLE;
  PERFORM set_config('request.jwt.claim.sub', p_uid::text, true);
  PERFORM set_config('test.uid', p_uid::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub',p_uid,'aal',p_aal,
    'app_metadata', jsonb_build_object('role',p_role,'authorization_version',
      (SELECT authorization_version FROM public.profiles WHERE id=p_uid),
      'household_id',(SELECT household_id FROM public.profiles WHERE id=p_uid)))::text, true);
  PERFORM set_config('test.jwt', current_setting('request.jwt.claims'), true);
  SET LOCAL ROLE authenticated;
END $$;

CREATE FUNCTION pg_temp.n(p_table text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v bigint;
BEGIN EXECUTE format('SELECT count(*) FROM public.%I', p_table) INTO v; RETURN v; END $$;

CREATE FUNCTION pg_temp.attendu(p_who text, p_table text, p_voulu bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v bigint := pg_temp.n(p_table);
BEGIN
  IF v <> p_voulu THEN
    RAISE EXCEPTION 'DETTE-CONTROLLER: % lit % ligne(s) de % (attendu %)', p_who, v, p_table, p_voulu;
  END IF;
END $$;

-- Le controleur SANS capacite : zero ligne partout (c'etait le trou).
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000006','controller','aal2');
SELECT pg_temp.attendu('sans capacite', t, 0)
  FROM unnest(ARRAY['sessions','session_participants','session_events','session_recordings',
    'teacher_student_assignments','matching_requests','intentions_horaire','availability_slots','weekly_availability','rule_overrides','mes_seances_v']) t;
DO $$ BEGIN
  IF (SELECT count(*) FROM public.offres_horaires WHERE etat <> 'publiee') <> 0 THEN
    RAISE EXCEPTION 'DETTE-CONTROLLER: sans capacite, offres non publiees lues'; END IF;
END $$;

-- Le controleur avec capacite et mission, mais sans seconde etape : zero.
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000002','controller','aal1');
SELECT pg_temp.attendu('aal1', t, 0)
  FROM unnest(ARRAY['sessions','session_participants','session_events','session_recordings']) t;

-- Avec capacite, mission et aal2 : la seule seance de sa mission, rien d'autre.
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000002','controller','aal2');
SELECT pg_temp.attendu('controleur capable', 'sessions', 1);
SELECT pg_temp.attendu('controleur capable', 'mes_seances_v', 1);
SELECT pg_temp.attendu('controleur capable', 'weekly_availability', 0);
SELECT pg_temp.attendu('controleur capable', 'rule_overrides', 0);
SELECT pg_temp.attendu('controleur capable', 'session_recordings', 1);
SELECT pg_temp.attendu('controleur capable', 'session_participants', 1);
SELECT pg_temp.attendu('controleur capable', 'session_events', 1);
SELECT pg_temp.attendu('controleur capable', t, 0)
  FROM unnest(ARRAY['teacher_student_assignments','matching_requests','intentions_horaire','availability_slots']) t;
DO $$ BEGIN
  IF (SELECT count(*) FROM public.offres_horaires WHERE etat <> 'publiee') <> 0 THEN
    RAISE EXCEPTION 'DETTE-CONTROLLER: controleur capable lit des offres non publiees'; END IF;
END $$;

-- Un autre controleur, perimetre sur une autre classe : rien de cette seance.
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000003','controller','aal2');
SELECT pg_temp.attendu('autre perimetre', t, 0)
  FROM unnest(ARRAY['sessions','session_participants','session_events','session_recordings','mes_seances_v']) t;

-- Admin inchange : tout.
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000001','admin','aal2');
SELECT pg_temp.attendu('admin', 'matching_requests', 1);
SELECT pg_temp.attendu('admin', 'intentions_horaire', 1);
SELECT pg_temp.attendu('admin', 'teacher_student_assignments', 1);
SELECT pg_temp.attendu('admin', 'session_recordings', 2);
SELECT pg_temp.attendu('admin', 'mes_seances_v', 2);
SELECT pg_temp.attendu('admin', 'weekly_availability', 1);
SELECT pg_temp.attendu('admin', 'rule_overrides', 1);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.offres_horaires WHERE etat='brouillon') <> 1 THEN
    RAISE EXCEPTION 'DETTE-CONTROLLER: admin ne lit plus les brouillons d offres'; END IF;
END $$;

-- Comptable inchange : seances et affectations.
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000008','accountant','aal2');
SELECT pg_temp.attendu('comptable', 'sessions', 2);
SELECT pg_temp.attendu('comptable', 'teacher_student_assignments', 1);

-- Famille : voit les participants de ses enfants (inchange).
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000007','guardian','aal2');
DO $$ BEGIN
  IF (SELECT count(*) FROM public.session_participants) < 1 THEN
    RAISE EXCEPTION 'DETTE-CONTROLLER: la famille ne lit plus les participants'; END IF;
END $$;

-- Enseignant : ses seances et ses creneaux (inchange).
SELECT pg_temp.comme('dc700000-0000-0000-0000-000000000004','teacher','aal2');
SELECT pg_temp.attendu('enseignant', 'sessions', 2);
SELECT pg_temp.attendu('enseignant', 'availability_slots', 1);
SELECT pg_temp.attendu('enseignant', 'mes_seances_v', 2);
SELECT pg_temp.attendu('enseignant', 'weekly_availability', 1);

RESET ROLE;
ROLLBACK;
