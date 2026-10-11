-- Exercise C-29's session trigger, candidate selection, active controller
-- capacity, and the three configured weighting levels.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c29w0000-0000-0000-0000-000000000001', 'c29w-admin@test.invalid'),
  ('c29w0000-0000-0000-0000-000000000002', 'c29w-controller@test.invalid'),
  ('c29w0000-0000-0000-0000-000000000003', 'c29w-recent@test.invalid'),
  ('c29w0000-0000-0000-0000-000000000004', 'c29w-concern@test.invalid');
INSERT INTO public.profiles
  (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES
  ('c29w0000-0000-0000-0000-000000000001', 'C29W-ADMIN', 'admin', 'Admin', 'Weights', 'active', 'female'),
  ('c29w0000-0000-0000-0000-000000000002', 'C29W-CONTROLLER', 'controller', 'Controller', 'Weights', 'active', 'female'),
  ('c29w0000-0000-0000-0000-000000000003', 'C29W-RECENT', 'teacher', 'Recent', 'Teacher', 'active', 'male'),
  ('c29w0000-0000-0000-0000-000000000004', 'C29W-CONCERN', 'teacher', 'Concern', 'Teacher', 'active', 'male');
INSERT INTO public.teacher_profiles (profile_id, kyc_status) VALUES
  ('c29w0000-0000-0000-0000-000000000003', 'approved'),
  ('c29w0000-0000-0000-0000-000000000004', 'approved');
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES
  ('c29w0000-0000-0000-0000-000000000101', 'c29w0000-0000-0000-0000-000000000003', 'enfant', 5, 'C29 recent weight', 1, 18, 'Europe/Paris', 'hommes'),
  ('c29w0000-0000-0000-0000-000000000102', 'c29w0000-0000-0000-0000-000000000004', 'enfant', 5, 'C29 concern weight', 1, 18, 'Europe/Paris', 'hommes');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES
  ('c29w0000-0000-0000-0000-000000000201', 'c29w0000-0000-0000-0000-000000000003', now() - interval '5 minutes', now() + interval '55 minutes', 'planned', 'standard', 'c29w0000-0000-0000-0000-000000000101'),
  ('c29w0000-0000-0000-0000-000000000202', 'c29w0000-0000-0000-0000-000000000004', now() - interval '5 minutes', now() + interval '55 minutes', 'planned', 'standard', 'c29w0000-0000-0000-0000-000000000102'),
  ('c29w0000-0000-0000-0000-000000000203', 'c29w0000-0000-0000-0000-000000000003', now() - interval '10 days', now() - interval '9 days', 'ended', 'standard', NULL);
INSERT INTO public.student_concern
  (categorie, groupe_id, student_id, teacher_id, internal_details)
VALUES
  ('pedagogique', 'c29w0000-0000-0000-0000-000000000102', 'c29w0000-0000-0000-0000-000000000001', 'c29w0000-0000-0000-0000-000000000004', 'Scenario concern weight');

INSERT INTO public.controle_regles
  (version, missions_par_semaine, ponderations, payload, cree_par, cle)
VALUES
  (1, 5,
   '{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"}',
   '{"scenario":"C29 assignment weights"}',
   'c29w0000-0000-0000-0000-000000000001',
   'c29w0000-0000-0000-0000-000000000301');
INSERT INTO private.controle_capacites
  (profile_id, approved_by, active_from, expires_at, scope_all_groups,
   scope_group_ids, scope_teacher_ids, grant_idempotency_key)
VALUES
  ('c29w0000-0000-0000-0000-000000000002',
   'c29w0000-0000-0000-0000-000000000001', now() - interval '1 minute', now() + interval '1 day',
   true, '{}', '{}', 'c29w0000-0000-0000-0000-000000000302');

UPDATE public.sessions SET status = 'in_progress'
WHERE id IN ('c29w0000-0000-0000-0000-000000000201',
             'c29w0000-0000-0000-0000-000000000202');

DO $test$
BEGIN
  IF (SELECT count(*) FROM private.controle_missions
      WHERE session_id IN ('c29w0000-0000-0000-0000-000000000201',
                           'c29w0000-0000-0000-0000-000000000202')
        AND controleur_id = 'c29w0000-0000-0000-0000-000000000002'
        AND version_regles = 1 AND critere = 'ponderation') <> 2 THEN
    RAISE EXCEPTION 'C29: trigger must assign both weighted candidate sessions to the active controller';
  END IF;
  IF (SELECT ponderations FROM public.controle_regles WHERE version=1) <>
      '{"enseignants_recents":"normal","classes_signalees":"fort","heures_de_pointe":"aucun"}'::jsonb THEN
    RAISE EXCEPTION 'C29: normal, strong, and disabled weighting levels were not retained';
  END IF;
END;
$test$;

ROLLBACK;
