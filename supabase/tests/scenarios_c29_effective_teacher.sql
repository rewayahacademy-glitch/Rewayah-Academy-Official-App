-- C-29 must exclude the effective replacement teacher, not the titular teacher.
-- Requires the canonical migrations including B-09 and C-29 control rules.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c29e0000-0000-0000-0000-000000000001', 'c29-effective-holder@test.invalid'),
  ('c29e0000-0000-0000-0000-000000000002', 'c29-effective-cover@test.invalid'),
  ('c29e0000-0000-0000-0000-000000000003', 'c29-effective-admin@test.invalid');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('c29e0000-0000-0000-0000-000000000001', 'C29-EFF-HOLDER', 'teacher', NULL, 'Holder', 'One', 'active', 'male'),
  ('c29e0000-0000-0000-0000-000000000002', 'C29-EFF-COVER', 'teacher', NULL, 'Cover', 'Two', 'active', 'male'),
  ('c29e0000-0000-0000-0000-000000000003', 'C29-EFF-ADMIN', 'admin', NULL, 'Admin', 'Three', 'active', 'female');
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES
  ('c29e0000-0000-0000-0000-000000000101',
   'c29e0000-0000-0000-0000-000000000001', 'enfant', 5, 'Effective Teacher', 1, 18, 'Europe/Paris', 'hommes');
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
VALUES
  ('c29e0000-0000-0000-0000-000000000201',
   'c29e0000-0000-0000-0000-000000000001', now() - interval '5 minutes',
   now() + interval '55 minutes', 'in_progress', 'standard',
   'c29e0000-0000-0000-0000-000000000101');

DO $test$
DECLARE v_effective uuid;
BEGIN
  v_effective := private.c29_enseignant_effectif_session(
    'c29e0000-0000-0000-0000-000000000201'
  );
  IF v_effective <> 'c29e0000-0000-0000-0000-000000000001' THEN
    RAISE EXCEPTION 'C29: titular must remain effective before B-09 replacement';
  END IF;

  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES
    ('c29e0000-0000-0000-0000-000000000201', 'absence_declaree',
     'c29e0000-0000-0000-0000-000000000001', NULL,
     'c29e0000-0000-0000-0000-000000000001', 'c29e0000-0000-0000-0000-000000000301');
  IF private.c29_enseignant_effectif_session(
       'c29e0000-0000-0000-0000-000000000201'
     ) <> 'c29e0000-0000-0000-0000-000000000001' THEN
    RAISE EXCEPTION 'C29: absence declaration alone must not change effective teacher';
  END IF;

  INSERT INTO public.remplacements_seance
    (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id,
     acteur_id, cle_idempotence)
  VALUES
    ('c29e0000-0000-0000-0000-000000000201', 'remplacement_pris',
     'c29e0000-0000-0000-0000-000000000001', 'c29e0000-0000-0000-0000-000000000002',
     'c29e0000-0000-0000-0000-000000000002', 'c29e0000-0000-0000-0000-000000000302');
  IF private.c29_enseignant_effectif_session(
       'c29e0000-0000-0000-0000-000000000201'
     ) <> 'c29e0000-0000-0000-0000-000000000002' THEN
    RAISE EXCEPTION 'C29: confirmed replacement must be the effective teacher';
  END IF;
END;
$test$;

ROLLBACK;
