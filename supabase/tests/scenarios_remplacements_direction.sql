-- Remplacements cote direction (20261102400000) : droits, R12 (libre a l'heure
-- exacte, genre souple sur choix explicite trace) et agregat par titulaire.
-- Rejeu : stub_auth.sql, toutes les migrations, puis ce fichier. Tout est
-- annule a la fin (ROLLBACK).
BEGIN;

INSERT INTO auth.users (id, email) VALUES
 ('d1200000-0000-0000-0000-000000000001','rd-titulaire@test.invalid'),
 ('d1200000-0000-0000-0000-000000000002','rd-libre@test.invalid'),
 ('d1200000-0000-0000-0000-000000000003','rd-occupe@test.invalid'),
 ('d1200000-0000-0000-0000-000000000004','rd-admin@test.invalid'),
 ('d1200000-0000-0000-0000-000000000005','rd-autre-genre@test.invalid'),
 ('d1200000-0000-0000-0000-000000000006','rd-admin-suspendu@test.invalid');
INSERT INTO public.profiles
 (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 ('d1200000-0000-0000-0000-000000000001','RD-TIT','teacher',NULL,'Titulaire','A','provisional_active','male'),
 ('d1200000-0000-0000-0000-000000000002','RD-LIB','teacher',NULL,'Libre','B','provisional_active','male'),
 ('d1200000-0000-0000-0000-000000000003','RD-OCC','teacher',NULL,'Occupe','C','provisional_active','male'),
 ('d1200000-0000-0000-0000-000000000004','RD-ADM','admin',NULL,'Direction','D','active','female'),
 ('d1200000-0000-0000-0000-000000000005','RD-AUT','teacher',NULL,'Autre','E','provisional_active','female'),
 ('d1200000-0000-0000-0000-000000000006','RD-ADS','admin',NULL,'Suspendue','F','disabled','female');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
 ('d1200000-0000-0000-0000-000000000001','approved'),
 ('d1200000-0000-0000-0000-000000000002','approved'),
 ('d1200000-0000-0000-0000-000000000003','approved'),
 ('d1200000-0000-0000-0000-000000000005','approved');
DO $fixture_contrats$
DECLARE v_teacher record; v_teacher_version text; v_notice_version text;
BEGIN
 SELECT version INTO v_teacher_version FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
 SELECT version INTO v_notice_version FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
 FOR v_teacher IN SELECT id FROM public.profiles WHERE role='teacher' AND account_status='provisional_active'
                    AND id::text LIKE 'd1200000-%' LOOP
  PERFORM set_config('request.jwt.claim.sub',v_teacher.id::text,true); PERFORM set_config('test.uid',v_teacher.id::text,true);
  PERFORM set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true); PERFORM set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
  PERFORM public.signer_contrat(v_teacher_version,'Fixture enseignant');
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version) VALUES(v_teacher.id,'recording_and_control_notice',v_notice_version) ON CONFLICT DO NOTHING;
  INSERT INTO public.contract_acceptances(profile_id,contract_kind,version)
  VALUES (v_teacher.id,'teacher_conduct_code',public.code_conduite_version_requise())
  ON CONFLICT(profile_id,contract_kind,version) DO NOTHING;
  UPDATE public.profiles SET account_status='active' WHERE id=v_teacher.id;
 END LOOP;
 PERFORM set_config('request.jwt.claim.sub','',true); PERFORM set_config('request.jwt.claims','',true);
 PERFORM set_config('test.uid','',true); PERFORM set_config('test.jwt','',true);
END
$fixture_contrats$;

-- Classe d'hommes du titulaire ; classe de l'enseignant occupe, au meme
-- instant que la seance 201. Les seances d'essai tombent a 03:00 UTC : la
-- creation d'une classe genere ses propres seances (lundi 18 h, Paris), et
-- une seance d'essai posee a l'heure courante pouvait les chevaucher selon
-- l'heure du rejeu (sessions_no_teacher_overlap).
INSERT INTO public.groupes
 (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES
 ('d1200000-0000-0000-0000-000000000101','d1200000-0000-0000-0000-000000000001','enfant',5,'RD classe',1,18,'Europe/Paris','hommes'),
 ('d1200000-0000-0000-0000-000000000102','d1200000-0000-0000-0000-000000000003','enfant',5,'RD autre classe',1,18,'Europe/Paris','hommes');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES
 ('d1200000-0000-0000-0000-000000000201','d1200000-0000-0000-0000-000000000001',
  (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '2 days', (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '2 days 1 hour',
  'planned','standard','d1200000-0000-0000-0000-000000000101'),
 ('d1200000-0000-0000-0000-000000000202','d1200000-0000-0000-0000-000000000001',
  (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '3 days', (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '3 days 1 hour',
  'planned','standard','d1200000-0000-0000-0000-000000000101'),
 ('d1200000-0000-0000-0000-000000000203','d1200000-0000-0000-0000-000000000001',
  (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '4 days', (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '4 days 1 hour',
  'planned','standard','d1200000-0000-0000-0000-000000000101'),
 -- Chevauche la seance 201 d'une demi-heure : l'enseignant occupe n'est pas libre.
 ('d1200000-0000-0000-0000-000000000204','d1200000-0000-0000-0000-000000000003',
  (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '2 days 30 minutes', (date_trunc('day', clock_timestamp() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' + interval '3 hours') + interval '2 days 90 minutes',
  'planned','standard','d1200000-0000-0000-0000-000000000102');

-- Droits : anon n'a aucun EXECUTE ; authenticated oui.
DO $acl$
BEGIN
 IF has_function_privilege('anon','public.remplacants_possibles_seance(uuid)','EXECUTE')
    OR has_function_privilege('anon','public.remplacements_direction(timestamptz,timestamptz)','EXECUTE')
    OR has_function_privilege('anon','public.designer_remplacant_admin(uuid,uuid,uuid,boolean)','EXECUTE')
    OR has_function_privilege('agent_ro','public.remplacements_direction(timestamptz,timestamptz)','EXECUTE')
    OR has_function_privilege('service_role','public.remplacants_possibles_seance(uuid)','EXECUTE')
    OR NOT has_function_privilege('authenticated','public.remplacements_direction(timestamptz,timestamptz)','EXECUTE')
    OR NOT has_function_privilege('authenticated','public.remplacants_possibles_seance(uuid)','EXECUTE')
    OR NOT has_function_privilege('authenticated','public.designer_remplacant_admin(uuid,uuid,uuid,boolean)','EXECUTE')
    OR has_function_privilege('authenticated','private.remplacant_libre_a_l_heure(uuid,uuid)','EXECUTE') THEN
   RAISE EXCEPTION 'RD: droits EXECUTE incorrects';
 END IF;
END;
$acl$;

-- Le titulaire declare son absence a la seance 203 (restera sans remplacant).
SELECT set_config('request.jwt.claim.sub','d1200000-0000-0000-0000-000000000001',true);
SELECT set_config('test.uid','d1200000-0000-0000-0000-000000000001',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"teacher"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"teacher"}}',true);
SET LOCAL ROLE authenticated;
DO $enseignant$
BEGIN
 IF public.declarer_absence_seance('d1200000-0000-0000-0000-000000000203',
      'd1200000-0000-0000-0000-000000000301')->>'etat' <> 'absence_declaree' THEN
   RAISE EXCEPTION 'RD: absence non declaree';
 END IF;
 -- Un enseignant ne lit ni la liste ni l'agregat de la direction.
 BEGIN
   PERFORM public.remplacants_possibles_seance('d1200000-0000-0000-0000-000000000201');
   RAISE EXCEPTION 'RD: un enseignant a lu les remplacants possibles';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
   PERFORM public.remplacements_direction(now() - interval '1 day', now() + interval '30 days');
   RAISE EXCEPTION 'RD: un enseignant a lu l''agregat de la direction';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 BEGIN
   PERFORM public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000201',
     'd1200000-0000-0000-0000-000000000002','d1200000-0000-0000-0000-000000000302', false);
   RAISE EXCEPTION 'RD: un enseignant a designe un remplacant';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$enseignant$;
RESET ROLE;

-- Une direction suspendue n'entre pas.
SELECT set_config('request.jwt.claim.sub','d1200000-0000-0000-0000-000000000006',true);
SELECT set_config('test.uid','d1200000-0000-0000-0000-000000000006',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $suspendue$
BEGIN
 BEGIN
   PERFORM public.remplacements_direction(now() - interval '1 day', now() + interval '30 days');
   RAISE EXCEPTION 'RD: une direction suspendue a lu l''agregat';
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
END;
$suspendue$;
RESET ROLE;

-- La direction active.
SELECT set_config('request.jwt.claim.sub','d1200000-0000-0000-0000-000000000004',true);
SELECT set_config('test.uid','d1200000-0000-0000-0000-000000000004',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
SELECT set_config('test.jwt','{"app_metadata":{"role":"admin"}}',true);
SET LOCAL ROLE authenticated;
DO $direction$
DECLARE v jsonb; v_ligne jsonb; v_ids text[];
BEGIN
 -- R12 : la liste ne rend que les enseignants libres a l'heure exacte,
 -- jamais le titulaire ; le genre est dit, pas filtre.
 v := public.remplacants_possibles_seance('d1200000-0000-0000-0000-000000000201');
 SELECT array_agg(e->>'enseignant_id') INTO v_ids FROM jsonb_array_elements(v) e;
 IF NOT ('d1200000-0000-0000-0000-000000000002' = ANY(v_ids))
    OR NOT ('d1200000-0000-0000-0000-000000000005' = ANY(v_ids))
    OR 'd1200000-0000-0000-0000-000000000003' = ANY(v_ids)
    OR 'd1200000-0000-0000-0000-000000000001' = ANY(v_ids) THEN
   RAISE EXCEPTION 'RD: remplacants possibles incorrects : %', v;
 END IF;
 IF (SELECT (e->>'genre_compatible')::boolean FROM jsonb_array_elements(v) e
      WHERE e->>'enseignant_id' = 'd1200000-0000-0000-0000-000000000005')
    OR NOT (SELECT (e->>'genre_compatible')::boolean FROM jsonb_array_elements(v) e
      WHERE e->>'enseignant_id' = 'd1200000-0000-0000-0000-000000000002')
    OR v->0->>'enseignant_id' <> 'd1200000-0000-0000-0000-000000000002' THEN
   RAISE EXCEPTION 'RD: genre_compatible ou ordre incorrect : %', v;
 END IF;

 -- Occupe a l'heure exacte : refus strict, meme hors genre.
 BEGIN
   PERFORM public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000201',
     'd1200000-0000-0000-0000-000000000003','d1200000-0000-0000-0000-000000000401', true);
   RAISE EXCEPTION 'RD: un enseignant occupe a ete designe';
 EXCEPTION WHEN invalid_parameter_value THEN
   IF SQLERRM <> 'RemplacantOccupe' THEN RAISE; END IF;
 END;
 -- Alias a trois arguments : meme regle stricte.
 BEGIN
   PERFORM public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000201',
     'd1200000-0000-0000-0000-000000000003','d1200000-0000-0000-0000-000000000402');
   RAISE EXCEPTION 'RD: alias : un enseignant occupe a ete designe';
 EXCEPTION WHEN invalid_parameter_value THEN
   IF SQLERRM <> 'RemplacantOccupe' THEN RAISE; END IF;
 END;
 -- Autre genre sans choix explicite : refus.
 BEGIN
   PERFORM public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000201',
     'd1200000-0000-0000-0000-000000000005','d1200000-0000-0000-0000-000000000403', false);
   RAISE EXCEPTION 'RD: autre genre designe sans choix explicite';
 EXCEPTION WHEN invalid_parameter_value THEN
   IF SQLERRM <> 'RemplacantIncompatible' THEN RAISE; END IF;
 END;
 -- Autre genre avec choix explicite : accepte et trace.
 IF public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000201',
      'd1200000-0000-0000-0000-000000000005','d1200000-0000-0000-0000-000000000404', true)->>'etat' <> 'designe' THEN
   RAISE EXCEPTION 'RD: choix hors genre refuse';
 END IF;
 -- Rejeu idempotent.
 IF public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000201',
      'd1200000-0000-0000-0000-000000000005','d1200000-0000-0000-0000-000000000404', true)->>'etat' <> 'designe' THEN
   RAISE EXCEPTION 'RD: rejeu idempotent incorrect';
 END IF;
 -- Compatible et libre : seance 202.
 IF public.designer_remplacant_admin('d1200000-0000-0000-0000-000000000202',
      'd1200000-0000-0000-0000-000000000002','d1200000-0000-0000-0000-000000000405', false)->>'etat' <> 'designe' THEN
   RAISE EXCEPTION 'RD: designation compatible refusee';
 END IF;
 -- La remplacante de 201 est desormais occupee a cet instant : elle n'est
 -- plus proposee pour la seance 204, qui chevauche 201.
 IF (SELECT count(*) FROM jsonb_array_elements(public.remplacants_possibles_seance(
       'd1200000-0000-0000-0000-000000000204')) e
      WHERE e->>'enseignant_id' = 'd1200000-0000-0000-0000-000000000005') <> 0 THEN
   RAISE EXCEPTION 'RD: un enseignant deja remplacant a la meme heure reste propose';
 END IF;

 -- Periode invalide : refus.
 BEGIN
   PERFORM public.remplacements_direction(now(), now() + interval '100 days');
   RAISE EXCEPTION 'RD: periode de plus de 93 jours acceptee';
 EXCEPTION WHEN invalid_parameter_value THEN NULL;
 END;

 -- Agregat : une ligne pour le titulaire dans sa classe, trois seances,
 -- deux remplacees, une sans remplacant, une hors genre.
 v := public.remplacements_direction(now() - interval '1 day', now() + interval '30 days');
 SELECT e INTO v_ligne FROM jsonb_array_elements(v->'par_enseignant') e
  WHERE e->>'titulaire_id' = 'd1200000-0000-0000-0000-000000000001'
    AND e->>'groupe_id' = 'd1200000-0000-0000-0000-000000000101';
 IF v_ligne IS NULL OR (v_ligne->>'seances')::int <> 3 OR (v_ligne->>'remplacees')::int <> 2
    OR (v_ligne->>'sans_remplacant')::int <> 1 OR (v_ligne->>'hors_genre')::int <> 1
    OR v_ligne->>'titulaire' <> 'Titulaire A' OR v_ligne->>'classe' <> 'RD classe' THEN
   RAISE EXCEPTION 'RD: agregat incorrect : %', v_ligne;
 END IF;
 IF (SELECT e->>'etat' FROM jsonb_array_elements(v->'seances') e
      WHERE e->>'seance_id' = 'd1200000-0000-0000-0000-000000000203') <> 'absence_declaree'
    OR (SELECT e->>'remplacant' FROM jsonb_array_elements(v->'seances') e
      WHERE e->>'seance_id' = 'd1200000-0000-0000-0000-000000000201') <> 'Autre E'
    OR NOT (SELECT (e->>'hors_genre')::boolean FROM jsonb_array_elements(v->'seances') e
      WHERE e->>'seance_id' = 'd1200000-0000-0000-0000-000000000201') THEN
   RAISE EXCEPTION 'RD: etat des seances incorrect : %', v->'seances';
 END IF;
 -- Hors periode : rien.
 IF jsonb_array_length(public.remplacements_direction(now() + interval '10 days',
      now() + interval '20 days')->'par_enseignant') <> 0 THEN
   RAISE EXCEPTION 'RD: la periode n''est pas respectee';
 END IF;
END;
$direction$;
RESET ROLE;

-- Trace : la colonne et le journal disent le choix hors genre.
DO $trace$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.remplacements_seance
                 WHERE session_id = 'd1200000-0000-0000-0000-000000000201'
                   AND evenement = 'remplacement_designe_admin' AND choix_hors_genre)
    OR EXISTS (SELECT 1 FROM public.remplacements_seance
                 WHERE session_id = 'd1200000-0000-0000-0000-000000000202' AND choix_hors_genre) THEN
   RAISE EXCEPTION 'RD: choix hors genre mal trace';
 END IF;
END;
$trace$;

ROLLBACK;
