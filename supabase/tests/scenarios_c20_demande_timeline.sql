-- C-20: known timeline events, waiting-for-teacher reason, household RLS,
-- and append-only history. Run after stub_auth.sql and all migrations.
BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('c2000000-0000-0000-0000-000000000001', 'c20-guardian@example.test'),
  ('c2000000-0000-0000-0000-000000000002', 'c20-student@example.test'),
  ('c2000000-0000-0000-0000-000000000003', 'c20-teacher@example.test');
INSERT INTO public.households (id, timezone)
VALUES ('c20fffff-0000-0000-0000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status)
VALUES
  ('c2000000-0000-0000-0000-000000000001', 'C20GUARDIAN0001', 'guardian',
   'c20fffff-0000-0000-0000-000000000001', 'Tuteur', 'Test', 'active'),
  ('c2000000-0000-0000-0000-000000000002', 'C20STUDENT00001', 'student',
   'c20fffff-0000-0000-0000-000000000001', 'Eleve', 'Test', 'active'),
  ('c2000000-0000-0000-0000-000000000003', 'C20TEACHER0001', 'teacher',
   NULL, 'Enseignant', 'Test', 'provisional_active');
UPDATE public.households
   SET primary_guardian_id = 'c2000000-0000-0000-0000-000000000001'
 WHERE id = 'c20fffff-0000-0000-0000-000000000001';

INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local)
VALUES
  ('c20fffff-0000-0000-0000-000000000002', NULL, 'en_attente_enseignant',
   'enfant', 5, 'C20 attente', 1, 10);

INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours,
   heures_locales, source, etat, created_at)
VALUES
  ('c20fffff-0000-0000-0000-000000000003',
   'c2000000-0000-0000-0000-000000000002', 'enfant', 'francais',
   'Europe/Paris', ARRAY[1]::smallint[], ARRAY[10]::smallint[],
   'personnalisee', 'envoyee', '2026-10-11 08:00:00+00');

UPDATE public.demandes_horaires_famille
   SET etat = 'classe_validee',
       groupe_id = 'c20fffff-0000-0000-0000-000000000002'
 WHERE id = 'c20fffff-0000-0000-0000-000000000003';

INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('c20fffff-0000-0000-0000-000000000002',
        'c2000000-0000-0000-0000-000000000002');

INSERT INTO public.sessions
  (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES
  ('c20fffff-0000-0000-0000-000000000004',
   'c2000000-0000-0000-0000-000000000003',
   'c20fffff-0000-0000-0000-000000000002',
   '2026-10-18 09:00:00+00', '2026-10-18 10:00:00+00', 'planned');

DO $events$
DECLARE
  v_count integer;
  v_reason text;
  v_sent_at timestamptz;
BEGIN
  SELECT count(*) INTO v_count
    FROM public.demande_evenements
   WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003';
  SELECT motif_attente INTO v_reason
    FROM public.demande_evenements
   WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003'
     AND type = 'en_attente';
  SELECT survenu_le INTO v_sent_at
    FROM public.demande_evenements
   WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003'
     AND type = 'envoyee';
  IF v_count <> 5 OR v_reason <> 'aucun_enseignant_libre'
     OR v_sent_at <> '2026-10-11 08:00:00+00'::timestamptz THEN
    RAISE EXCEPTION 'C-20 expected sent/class/wait/member/session events; got count %, reason %, sent %',
      v_count, v_reason, v_sent_at;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.demande_evenements
     WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003'
       AND type = 'premiere_seance_prevue'
       AND survenu_le = '2026-10-18 09:00:00+00'::timestamptz
  ) THEN
    RAISE EXCEPTION 'C-20 first scheduled session event missing';
  END IF;

  BEGIN
    UPDATE public.demande_evenements
       SET motif_attente = NULL
     WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003'
       AND type = 'en_attente';
    RAISE EXCEPTION 'C-20 event update unexpectedly succeeded';
  EXCEPTION WHEN SQLSTATE '55000' THEN
    NULL;
  END;
END;
$events$;

SELECT set_config('test.uid', 'c2000000-0000-0000-0000-000000000001', true);
SELECT set_config('test.jwt',
  '{"app_metadata":{"role":"guardian","household_id":"c20fffff-0000-0000-0000-000000000001"}}',
  true);
SET LOCAL ROLE authenticated;
DO $rls$
DECLARE
  v_count integer;
  v_projection_at timestamp without time zone;
BEGIN
  SELECT count(*) INTO v_count FROM public.demande_evenements_foyer_v
   WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003';
  SELECT survenu_le_foyer INTO v_projection_at
    FROM public.demande_evenements_foyer_v
   WHERE demande_id = 'c20fffff-0000-0000-0000-000000000003'
     AND type = 'envoyee';
  IF v_count <> 5
     OR v_projection_at <> timestamp '2026-10-11 10:00:00'
     OR pg_typeof(v_projection_at) <> 'timestamp without time zone'::regtype
     OR has_table_privilege('authenticated', 'public.demande_evenements', 'INSERT')
     OR has_table_privilege('authenticated', 'public.demande_evenements', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.demande_evenements', 'DELETE') THEN
    RAISE EXCEPTION 'C-20 household wall-clock projection/family ACL failed, visible events=%, timestamp=%',
      v_count, v_projection_at;
  END IF;
END;
$rls$;

ROLLBACK;
